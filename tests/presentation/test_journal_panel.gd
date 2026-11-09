## test_journal_panel.gd
## Comprehensive test suite for JournalPanel presentation component.
class_name TestJournalPanel
extends TestSuiteBase

const JOURNAL_SCENE_PATH: String = "res://scenes/garden/journal_panel.tscn"


func _init() -> void:
	suite_name = "TestJournalPanel"


func run_tests() -> void:
	_test_scene_loads_and_type_contract()
	_test_empty_journal_renders_mystery_placeholders_and_clues()
	_test_partial_and_full_discoveries_render_names_timestamps_and_counts()
	_test_open_close_and_enabled_state_controls()
	_test_null_catalog_and_null_journal_handling()
	_test_read_only_presentation_boundary()
	_test_decorations_and_ambient_events_sections_rendering()
	_test_secret_combination_event_hides_recipe()


func _create_production_catalog() -> ContentCatalog:
	var plants: Array[PlantDefinition] = PlantContentLoader.new().load_production_definitions().get_definitions()
	var visitors: Array[VisitorDefinition] = VisitorContentLoader.new().load_production_definitions().get_definitions()
	return ContentCatalog.try_create(plants, visitors)


func _instantiate_journal() -> JournalPanel:
	var scene: PackedScene = load(JOURNAL_SCENE_PATH) as PackedScene
	var panel: JournalPanel = scene.instantiate() as JournalPanel
	panel._ready()
	return panel


func _test_scene_loads_and_type_contract() -> void:
	describe("JournalPanel PackedScene loads cleanly and satisfies Control and signal contracts")
	var scene: PackedScene = load(JOURNAL_SCENE_PATH) as PackedScene
	assert_true(scene != null, "JournalPanel scene must load")
	var panel: JournalPanel = _instantiate_journal()
	assert_true(panel != null, "JournalPanel must instantiate")
	assert_true(panel is JournalPanel, "Must be JournalPanel")
	assert_true(panel is Control, "Must extend Control")
	assert_true(panel.has_signal("journal_closed"), "Must declare journal_closed signal")
	assert_true(panel.get_close_button() != null, "CloseButton must exist")
	panel.free()


func _test_empty_journal_renders_mystery_placeholders_and_clues() -> void:
	describe("Empty JournalState renders 0/10 summary and [???] mystery placeholders with habitat clues")
	var panel: JournalPanel = _instantiate_journal()
	var catalog: ContentCatalog = _create_production_catalog()
	var journal: JournalState = JournalState.new()

	panel.bind_journal(journal, catalog)

	assert_eq(panel.get_total_catalog_entry_count(), 10, "Total catalog entries is 10 (5 plants + 5 visitors)")
	assert_eq(panel.get_discovered_entry_count(), 0, "0 discovered entries")
	assert_eq(
		panel.get_summary_text(),
		"ค้นพบแล้ว 0 / 10 รายการ (พืช 0/5, ผู้มาเยือน 0/5)",
		"Summary text shows 0 / 10"
	)

	for plant_id: String in catalog.get_all_plant_ids():
		assert_true(panel.has_displayed_entry_for_id(plant_id), "Entry displayed for %s" % plant_id)
		var p_text: String = panel.get_entry_text_for_id(plant_id)
		assert_true(p_text.contains("[???] พันธุ์ไม้ปริศนา"), "Undiscovered plant %s shows [???] placeholder" % plant_id)
		assert_true(p_text.contains("คุณสมบัติ:"), "Undiscovered plant %s shows environmental trait clue" % plant_id)

	var jasmine_clue: String = panel.get_entry_text_for_id("plant.jasmine")
	assert_true(jasmine_clue.contains("ดอกไม้"), "Undiscovered jasmine clue includes ดอกไม้")

	for visitor_id: String in catalog.get_all_visitor_ids():
		assert_true(panel.has_displayed_entry_for_id(visitor_id), "Entry displayed for %s" % visitor_id)
		var v_text: String = panel.get_entry_text_for_id(visitor_id)
		assert_true(v_text.contains("[???] ผู้มาเยือนปริศนา"), "Undiscovered visitor %s shows [???] placeholder" % visitor_id)
		assert_true(v_text.contains("คำใบ้สภาพแวดล้อมที่ชอบ:"), "Undiscovered visitor %s shows habitat clue" % visitor_id)

	# Verify specific clue for butterfly (flower (1))
	var butterfly_clue: String = panel.get_entry_text_for_id("visitor.butterfly")
	assert_true(butterfly_clue.contains("ดอกไม้ (1)"), "Butterfly clue includes ดอกไม้ (1)")

	panel.free()


func _test_partial_and_full_discoveries_render_names_timestamps_and_counts() -> void:
	describe("Discovered entries render localized Thai names, first_seen_at, times_seen, and leave undiscovered as [???]")
	var panel: JournalPanel = _instantiate_journal()
	var catalog: ContentCatalog = _create_production_catalog()
	var journal: JournalState = JournalState.new()

	assert_true(journal.try_record_sighting("plant.holy_basil", 1000), "Discover holy_basil at 1000")
	assert_true(journal.try_record_sighting("plant.holy_basil", 1500), "Repeat holy_basil at 1500")
	assert_true(journal.try_record_sighting("visitor.butterfly", 2000), "Discover butterfly at 2000")

	panel.bind_journal(journal, catalog)

	assert_eq(panel.get_discovered_entry_count(), 2, "2 discovered entries")
	assert_true(panel.is_entry_discovered_in_journal("plant.holy_basil"), "Basil is discovered in journal")
	assert_false(panel.is_entry_discovered_in_journal("plant.jasmine"), "Jasmine is not discovered in journal")
	assert_eq(panel.get_times_seen_for_id("plant.holy_basil"), 2, "Basil times_seen query returns 2")
	assert_eq(panel.get_first_seen_at_for_id("plant.holy_basil"), 1000, "Basil first_seen_at query returns 1000")
	assert_eq(panel.get_times_seen_for_id("plant.jasmine"), 0, "Undiscovered jasmine times_seen query returns 0")
	assert_eq(panel.get_first_seen_at_for_id("plant.jasmine"), -1, "Undiscovered jasmine first_seen_at query returns -1")
	assert_eq(
		panel.get_summary_text(),
		"ค้นพบแล้ว 2 / 10 รายการ (พืช 1/5, ผู้มาเยือน 1/5)",
		"Summary text shows 2 / 10 (1/5 plants, 1/5 visitors)"
	)

	var basil_text: String = panel.get_entry_text_for_id("plant.holy_basil")
	assert_true(basil_text.contains("[ค้นพบแล้ว] กะเพรา (plant.holy_basil)"), "Discovered basil shows Thai name and ID")
	assert_true(basil_text.contains("พบครั้งแรกเมื่อ: 1000"), "Discovered basil shows first_seen_at = 1000")
	assert_true(basil_text.contains("จำนวนครั้งที่ปลูก/พบ: 2 ครั้ง"), "Discovered basil shows times_seen = 2")
	assert_true(basil_text.contains("โตเต็มที่ใน: 600 วินาที"), "Discovered basil shows mature duration 600s")
	assert_true(basil_text.contains("รางวัลเก็บเกี่ยว: 5 เหรียญ"), "Discovered basil shows harvest reward 5 coins")
	assert_true(basil_text.contains("คุณสมบัติ: พุ่มไม้หนาแน่น, พืชอาหาร"), "Discovered basil shows environmental traits")

	var butterfly_text: String = panel.get_entry_text_for_id("visitor.butterfly")
	assert_true(butterfly_text.contains("[ค้นพบแล้ว] ผีเสื้อบ้านสวน (visitor.butterfly)"), "Discovered butterfly shows Thai name and ID")
	assert_true(butterfly_text.contains("พบครั้งแรกเมื่อ: 2000"), "Discovered butterfly shows first_seen_at = 2000")
	assert_true(butterfly_text.contains("จำนวนครั้งที่พบ: 1 ครั้ง"), "Discovered butterfly shows times_seen = 1")

	var jasmine_text: String = panel.get_entry_text_for_id("plant.jasmine")
	assert_true(jasmine_text.contains("[???] พันธุ์ไม้ปริศนา"), "Undiscovered jasmine remains [???]")

	panel.free()


func _test_open_close_and_enabled_state_controls() -> void:
	describe("open_journal, close_journal, CloseButton, and set_journal_enabled control visibility and emit signal")
	var panel: JournalPanel = _instantiate_journal()
	panel.visible = false

	var closed_count: Array[int] = [0]
	panel.journal_closed.connect(func() -> void: closed_count[0] += 1)

	panel.open_journal()
	assert_true(panel.is_journal_open(), "Journal opens when enabled")

	panel.get_close_button().pressed.emit()
	assert_false(panel.is_journal_open(), "CloseButton closes journal")
	assert_eq(closed_count[0], 1, "journal_closed emitted once")

	panel.set_journal_enabled(false)
	assert_false(panel.is_journal_enabled(), "Journal disabled")
	assert_true(panel.get_close_button().disabled, "CloseButton disabled when journal disabled")
	panel.open_journal()
	assert_false(panel.is_journal_open(), "Cannot open journal when disabled")

	panel.set_journal_enabled(true)
	panel.open_journal()
	assert_true(panel.is_journal_open(), "Can open journal after re-enabling")
	panel.free()


func _test_null_catalog_and_null_journal_handling() -> void:
	describe("bind_journal handles null JournalState or null ContentCatalog safely")
	var panel: JournalPanel = _instantiate_journal()
	var catalog: ContentCatalog = _create_production_catalog()

	panel.bind_journal(null, null)
	assert_eq(panel.get_total_catalog_entry_count(), 0, "Null catalog -> 0 total entries")
	assert_eq(panel.get_summary_text(), "ค้นพบแล้ว 0 / 0 รายการ", "Null catalog summary text")

	panel.bind_journal(null, catalog)
	assert_eq(panel.get_total_catalog_entry_count(), 10, "Null journal with valid catalog -> 10 total entries")
	assert_eq(panel.get_discovered_entry_count(), 0, "Null journal -> 0 discovered entries")
	panel.free()


func _test_read_only_presentation_boundary() -> void:
	describe("JournalPanel does not mutate JournalState or access persistence/clock/RNG")
	var panel: JournalPanel = _instantiate_journal()
	var catalog: ContentCatalog = _create_production_catalog()
	var journal: JournalState = JournalState.new()
	journal.try_record_sighting("plant.banana", 500)

	panel.bind_journal(journal, catalog)
	assert_eq(journal.get_count(), 1, "JournalState count unmutated by bind_journal")
	assert_eq(journal.get_record("plant.banana").get_times_seen(), 1, "DiscoveryRecord times_seen unmutated")
	assert_true(panel.get("save_repository") == null, "No save_repository property")
	assert_true(panel.get("game_clock") == null, "No game_clock property")
	assert_true(panel.get("random_source") == null, "No random_source property")
	panel.free()


func _create_full_production_catalog() -> ContentCatalog:
	var plants: Array[PlantDefinition] = PlantContentLoader.new().load_production_definitions().get_definitions()
	var visitors: Array[VisitorDefinition] = VisitorContentLoader.new().load_production_definitions().get_definitions()
	var decorations: Array[DecorationDefinition] = DecorationContentLoader.new().load_production_definitions().get_definitions()
	var events: Array[EventDefinition] = EventContentLoader.new().load_production_definitions().get_definitions()
	return ContentCatalog.try_create(plants, visitors, decorations, events)


func _test_decorations_and_ambient_events_sections_rendering() -> void:
	describe("JournalPanel renders 8 decorations and 6 events (5 ambient + 1 secret) with placed counts and condition clues")
	var panel: JournalPanel = _instantiate_journal()
	var catalog: ContentCatalog = _create_full_production_catalog()
	var state: GameState = GameState.new()

	# 1. Empty garden at t = 21600 (morning, clear): 0 placed decorations, 0 active events
	var empty_snapshot: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, 21600)
	panel.bind_journal(state.get_journal(), catalog, state.get_decorations(), empty_snapshot)

	assert_eq(panel.get_total_catalog_entry_count(), 10, "Discoverable catalog count remains 10")
	assert_eq(panel.get_eligible_visitor_entry_count(), 0, "0 eligible visitors on empty garden")
	assert_false(panel.is_visitor_eligible_in_journal("visitor.butterfly"), "Butterfly not eligible on empty garden")
	assert_eq(panel.get_total_decoration_entry_count(), 8, "8 decoration definitions rendered")
	assert_eq(panel.get_placed_decoration_entry_count(), 0, "0 placed decorations initially")
	assert_eq(panel.get_total_event_entry_count(), 6, "6 event definitions rendered")
	assert_eq(panel.get_active_event_entry_count(), 0, "0 active events on empty garden")

	for decor_id: String in catalog.get_all_decoration_ids():
		assert_true(panel.has_displayed_entry_for_id(decor_id), "Decoration entry rendered for %s" % decor_id)
		assert_true(
			panel.get_entry_text_for_id(decor_id).contains("[ยังไม่ได้จัดวาง]"),
			"Unplaced decoration %s shows [ยังไม่ได้จัดวาง]" % decor_id
		)

	for event_id: String in catalog.get_all_event_ids():
		assert_true(panel.has_displayed_entry_for_id(event_id), "Event entry rendered for %s" % event_id)
		var ev_text: String = panel.get_entry_text_for_id(event_id)
		if catalog.get_event(event_id).is_secret:
			continue
		assert_true(ev_text.contains("[???] เหตุการณ์พิเศษปริศนา"), "Inactive event %s shows [???] placeholder" % event_id)
		assert_true(ev_text.contains("คำใบ้เงื่อนไข:"), "Inactive event %s shows condition clue" % event_id)

	# 2. Place bench (2 instances) and clay_jar (1 instance), plant jasmine (discovered); evaluate at t = 21600 (morning, clear)
	state.get_plants().try_add_plant(PlantState.new("jas-1", "plant.jasmine", 21600))
	state.get_journal().try_record_sighting("plant.jasmine", 21600)
	state.get_decorations().try_add_decoration(DecorationState.new("dec-1", "decoration.bench", 21600))
	state.get_decorations().try_add_decoration(DecorationState.new("dec-2", "decoration.bench", 21600))
	state.get_decorations().try_add_decoration(DecorationState.new("dec-3", "decoration.clay_jar", 21600))
	var populated_snapshot: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, 21600)

	panel.bind_journal(state.get_journal(), catalog, state.get_decorations(), populated_snapshot)

	assert_eq(panel.get_planted_count_for_plant_id("plant.jasmine"), 1, "Jasmine planted count is 1 in JournalPanel")
	assert_eq(panel.get_currently_planted_plant_ids_in_journal(), ["plant.jasmine"], "Currently planted plant IDs in journal")
	assert_eq(panel.get_currently_planted_plant_entry_count(), 1, "1 distinct plant species currently planted in journal")
	assert_eq(
		panel.get_unplanted_plant_ids_in_journal(),
		["plant.banana", "plant.chili", "plant.holy_basil", "plant.marigold"],
		"Unplanted plant IDs in journal"
	)
	assert_eq(panel.get_undiscovered_entry_count(), 9, "9 undiscovered entries out of 10 after discovering jasmine")
	assert_eq(panel.get_undiscovered_plant_entry_count(), 4, "4 undiscovered plants in journal")
	assert_eq(panel.get_undiscovered_visitor_entry_count(), 5, "5 undiscovered visitors in journal")
	assert_eq(panel.get_unplanted_plant_entry_count(), 4, "4 unplanted plant species in journal")
	assert_eq(panel.get_total_sighting_count_in_journal(), 1, "Total sighting count is 1 after discovering jasmine once")
	assert_eq(panel.get_total_plant_sighting_count_in_journal(), 1, "Total plant sighting count is 1")
	assert_eq(panel.get_total_visitor_sighting_count_in_journal(), 0, "Total visitor sighting count is 0")
	assert_false(panel.is_all_entries_discovered_in_journal(), "Not all entries discovered yet")
	assert_eq(panel.get_ineligible_visitor_entry_count(), 1, "1 ineligible visitor (bird) in populated_snapshot")
	assert_eq(panel.get_unplaced_decoration_entry_count(), 6, "6 unplaced decoration species in populated_snapshot")
	assert_eq(panel.get_inactive_event_entry_count(), 4, "4 inactive events in populated_snapshot")
	assert_true(
		panel.get_entry_text_for_id("plant.jasmine").contains("กำลังปลูกในสวน: 1 ต้น"),
		"Discovered jasmine shows live planted count = 1 when snapshot is bound"
	)

	# With jasmine (dense_vegetation, flower) + bench (shade, shelter) + clay_jar (water):
	# butterfly, cat, firefly, and frog are eligible in populated_snapshot (bird requires perch + shade)
	assert_eq(panel.get_eligible_visitor_entry_count(), 4, "4 visitors eligible in populated_snapshot")
	assert_true(panel.is_visitor_eligible_in_journal("visitor.butterfly"), "Butterfly eligible in journal")
	assert_false(panel.is_visitor_eligible_in_journal("visitor.bird"), "Bird not eligible without perch")
	assert_true(
		panel.get_entry_text_for_id("visitor.butterfly").contains("สภาพแวดล้อมพร้อมแล้ว ลองสำรวจผู้มาเยือนในสวน"),
		"Undiscovered eligible visitor shows habitat readiness hint"
	)
	assert_false(
		panel.get_entry_text_for_id("visitor.bird").contains("สภาพแวดล้อมพร้อมแล้ว"),
		"Undiscovered ineligible visitor does not show readiness hint"
	)

	# Discover butterfly and bird, then rebind to verify discovered visitor live habitat status
	state.get_journal().try_record_sighting("visitor.butterfly", 21610)
	state.get_journal().try_record_sighting("visitor.bird", 21610)
	panel.bind_journal(state.get_journal(), catalog, state.get_decorations(), populated_snapshot)
	assert_eq(panel.get_discovered_plant_entry_count(), 1, "1 discovered plant in journal")
	assert_eq(panel.get_discovered_visitor_entry_count(), 2, "2 discovered visitors in journal")
	assert_eq(panel.get_total_plant_entry_count(), 5, "5 total catalog plants in journal")
	assert_eq(panel.get_total_visitor_entry_count(), 5, "5 total catalog visitors in journal")
	assert_false(panel.is_all_plants_discovered_in_journal(), "Not all plants discovered (1/5)")
	assert_false(panel.is_all_visitors_discovered_in_journal(), "Not all visitors discovered (2/5)")
	assert_false(panel.is_all_decorations_placed_in_journal(), "Not all decorations placed (2/8)")
	assert_false(panel.is_all_events_active_in_journal(), "Not all events active (2/6)")
	assert_true(panel.has_any_discovered_entries_in_journal(), "Has discovered entries in journal")
	assert_true(panel.has_any_discovered_plants_in_journal(), "Has discovered plants in journal")
	assert_true(panel.has_any_discovered_visitors_in_journal(), "Has discovered visitors in journal")
	assert_true(panel.has_any_eligible_visitors_in_journal(), "Has eligible visitors in journal")
	assert_true(panel.has_any_placed_decorations_in_journal(), "Has placed decorations in journal")
	assert_true(panel.has_any_active_events_in_journal(), "Has active events in journal")
	assert_false(panel.is_all_visitors_eligible_in_journal(), "Not all visitors eligible in journal (4/5)")
	assert_true(panel.has_any_undiscovered_entries_in_journal(), "Has undiscovered entries in journal")
	assert_true(panel.has_any_undiscovered_plants_in_journal(), "Has undiscovered plants in journal (4/5)")
	assert_true(panel.has_any_undiscovered_visitors_in_journal(), "Has undiscovered visitors in journal (3/5)")
	assert_true(panel.has_any_ineligible_visitors_in_journal(), "Has ineligible visitors in journal (1/5)")
	assert_true(panel.has_any_unplaced_decorations_in_journal(), "Has unplaced decorations in journal (6/8)")
	assert_true(panel.has_any_inactive_events_in_journal(), "Has inactive events in journal (4/6)")
	assert_true(panel.has_any_currently_planted_plants_in_journal(), "Has currently planted plants in journal (1/5)")
	assert_true(panel.has_any_unplanted_plants_in_journal(), "Has unplanted plants in journal (4/5)")
	assert_false(panel.is_all_planted_species_present_in_journal(), "Not all plant species currently planted in journal (1/5)")
	assert_true(panel.has_bound_journal(), "JournalState is bound to panel")
	assert_true(panel.has_bound_catalog(), "ContentCatalog is bound to panel")
	assert_true(panel.has_bound_decorations(), "DecorationCollectionState is bound to panel")
	assert_true(panel.has_bound_snapshot(), "GardenSnapshot is bound to panel")
	assert_true(panel.has_plant_in_journal_catalog("plant.jasmine"), "Jasmine exists in journal plant catalog")
	assert_false(panel.has_plant_in_journal_catalog("plant.unknown"), "Unknown plant does not exist in journal plant catalog")
	assert_true(panel.has_visitor_in_journal_catalog("visitor.butterfly"), "Butterfly exists in journal visitor catalog")
	assert_false(panel.has_visitor_in_journal_catalog("visitor.unknown"), "Unknown visitor does not exist in journal visitor catalog")
	assert_true(panel.has_decoration_in_journal_catalog("decoration.bench"), "Bench exists in journal decoration catalog")
	assert_false(panel.has_decoration_in_journal_catalog("decoration.unknown"), "Unknown decoration does not exist in journal decoration catalog")
	assert_true(panel.has_event_in_journal_catalog("event.morning_butterflies"), "Morning butterflies exists in journal event catalog")
	assert_false(panel.has_event_in_journal_catalog("event.unknown"), "Unknown event does not exist in journal event catalog")
	assert_eq(
		panel.get_all_plant_ids_in_journal(),
		["plant.banana", "plant.chili", "plant.holy_basil", "plant.jasmine", "plant.marigold"],
		"All plant IDs in journal catalog"
	)
	assert_eq(
		panel.get_all_visitor_ids_in_journal(),
		["visitor.bird", "visitor.butterfly", "visitor.cat", "visitor.firefly", "visitor.frog"],
		"All visitor IDs in journal catalog"
	)
	assert_eq(panel.get_all_decoration_ids_in_journal().size(), 8, "8 total decoration IDs in journal catalog")
	assert_eq(panel.get_all_event_ids_in_journal().size(), 6, "6 total event IDs in journal catalog")
	assert_eq(panel.get_total_planted_plant_instance_count_in_journal(), 1, "1 total planted plant instance in journal")
	assert_eq(panel.get_total_placed_decoration_instance_count_in_journal(), 3, "3 total placed decoration instances in journal")
	assert_true(panel.is_decoration_placed_in_journal("decoration.bench"), "Bench is placed in journal")
	assert_false(panel.is_decoration_placed_in_journal("decoration.small_pond"), "Small pond is not placed in journal")
	assert_true(panel.is_plant_currently_planted_in_journal("plant.jasmine"), "Jasmine is currently planted in journal")
	assert_false(panel.is_plant_currently_planted_in_journal("plant.banana"), "Banana is not currently planted in journal")
	assert_eq(panel.get_plant_display_name_in_journal("plant.jasmine"), "มะลิ", "Plant display name in journal for jasmine")
	assert_eq(panel.get_plant_display_name_in_journal("plant.unknown"), "", "Unknown plant display name in journal is empty")
	assert_eq(panel.get_visitor_display_name_in_journal("visitor.butterfly"), "ผีเสื้อบ้านสวน", "Visitor display name in journal for butterfly")
	assert_eq(panel.get_visitor_display_name_in_journal("visitor.unknown"), "", "Unknown visitor display name in journal is empty")
	assert_eq(panel.get_decoration_display_name_in_journal("decoration.bench"), "ม้านั่งไม้ในสวน", "Decoration display name in journal for bench")
	assert_eq(panel.get_decoration_display_name_in_journal("decoration.unknown"), "", "Unknown decoration display name in journal is empty")
	assert_eq(panel.get_event_display_name_in_journal("event.cat_sleeping_bench"), "แมวนอนหลับบนม้านั่ง", "Event display name in journal for cat_sleeping_bench")
	assert_eq(panel.get_event_display_name_in_journal("event.unknown"), "", "Unknown event display name in journal is empty")
	assert_eq(
		panel.get_event_description_in_journal("event.cat_sleeping_bench"),
		"แมวข้างบ้านขดตัวนอนหลับอย่างสบายใจอยู่บนม้านั่งไม้",
		"Event description in journal for cat_sleeping_bench"
	)
	assert_eq(panel.get_event_description_in_journal("event.unknown"), "", "Unknown event description in journal is empty")
	assert_true(panel.has_summary_text(), "Journal panel has non-empty summary text")
	assert_eq(panel.get_displayed_entry_count(), 24, "24 total displayed entries across plants (5), visitors (5), decorations (8), and events (6)")
	assert_true(panel.has_any_displayed_entries(), "Journal panel has displayed entries")
	assert_eq(panel.get_plant_traits_summary_in_journal("plant.jasmine"), "พุ่มไม้หนาแน่น, ดอกไม้", "Plant traits summary in journal for jasmine")
	assert_eq(panel.get_plant_traits_summary_in_journal("plant.unknown"), "", "Unknown plant traits summary in journal is empty")
	assert_eq(panel.get_decoration_traits_summary_in_journal("decoration.clay_jar"), "แหล่งน้ำ", "Decoration traits summary in journal for clay_jar")
	assert_eq(panel.get_decoration_traits_summary_in_journal("decoration.watering_can"), "ตกแต่งสวยงาม", "Decoration traits summary in journal for traitless watering_can")
	assert_eq(panel.get_decoration_traits_summary_in_journal("decoration.unknown"), "", "Unknown decoration traits summary in journal is empty")
	assert_true(panel.get_visitor_clue_in_journal("visitor.butterfly").contains("ดอกไม้"), "Visitor clue in journal for butterfly includes ดอกไม้")
	assert_eq(panel.get_visitor_clue_in_journal("visitor.unknown"), "", "Unknown visitor clue in journal is empty")
	assert_true(panel.get_event_clue_in_journal("event.cat_sleeping_bench").contains("ม้านั่งไม้ในสวน"), "Event clue in journal for cat_sleeping_bench includes ม้านั่งไม้ในสวน")
	assert_eq(panel.get_event_clue_in_journal("event.unknown"), "", "Unknown event clue in journal is empty")
	assert_eq(panel.get_decoration_price_in_journal("decoration.clay_jar"), 15, "Decoration price in journal for clay_jar is 15")
	assert_eq(panel.get_decoration_price_in_journal("decoration.unknown"), -1, "Unknown decoration price in journal is -1")
	assert_eq(panel.get_plant_harvest_reward_in_journal("plant.jasmine"), 25, "Plant harvest reward in journal for jasmine is 25")
	assert_eq(panel.get_plant_harvest_reward_in_journal("plant.unknown"), 0, "Unknown plant harvest reward in journal is 0")
	assert_eq(panel.get_plant_mature_after_seconds_in_journal("plant.jasmine"), 3600, "Plant mature_after_seconds in journal for jasmine is 3600")
	assert_eq(panel.get_plant_mature_after_seconds_in_journal("plant.unknown"), 0, "Unknown plant mature_after_seconds in journal is 0")
	assert_eq(panel.get_plant_sprout_after_seconds_in_journal("plant.jasmine"), 300, "Plant sprout_after_seconds in journal for jasmine is 300")
	assert_eq(panel.get_plant_sprout_after_seconds_in_journal("plant.unknown"), 0, "Unknown plant sprout_after_seconds in journal is 0")
	assert_eq(panel.get_plant_growing_after_seconds_in_journal("plant.jasmine"), 1200, "Plant growing_after_seconds in journal for jasmine is 1200")
	assert_eq(panel.get_plant_growing_after_seconds_in_journal("plant.unknown"), 0, "Unknown plant growing_after_seconds in journal is 0")
	assert_eq(panel.get_plant_traits_in_journal("plant.jasmine"), ["dense_vegetation", "flower"], "Plant traits in journal for jasmine")
	assert_eq(panel.get_plant_traits_in_journal("plant.unknown"), [], "Unknown plant traits in journal is []")
	assert_eq(panel.get_decoration_traits_in_journal("decoration.bench"), ["shade", "shelter"], "Decoration traits in journal for bench")
	assert_eq(panel.get_decoration_traits_in_journal("decoration.unknown"), [], "Unknown decoration traits in journal is []")
	assert_eq(
		panel.get_plant_trait_display_names_in_journal("plant.jasmine"),
		["พุ่มไม้หนาแน่น", "ดอกไม้"],
		"Plant trait display names in journal for jasmine"
	)
	assert_eq(panel.get_plant_trait_display_names_in_journal("plant.unknown"), [], "Unknown plant trait display names in journal is []")
	assert_eq(
		panel.get_decoration_trait_display_names_in_journal("decoration.bench"),
		["ร่มเงา", "ที่หลบพัก"],
		"Decoration trait display names in journal for bench"
	)
	assert_eq(panel.get_decoration_trait_display_names_in_journal("decoration.unknown"), [], "Unknown decoration trait display names in journal is []")
	assert_true(panel.has_plant_trait_in_journal("plant.jasmine", "flower"), "Jasmine has flower trait in journal")
	assert_false(panel.has_plant_trait_in_journal("plant.jasmine", "water"), "Jasmine does not have water trait in journal")
	assert_true(panel.has_decoration_trait_in_journal("decoration.bench", "shade"), "Bench has shade trait in journal")
	assert_false(panel.has_decoration_trait_in_journal("decoration.bench", "water"), "Bench does not have water trait in journal")
	assert_eq(panel.get_plant_trait_count_in_journal("plant.jasmine"), 2, "Plant trait count in journal for jasmine is 2")
	assert_eq(panel.get_plant_trait_count_in_journal("plant.unknown"), 0, "Plant trait count in journal for unknown is 0")
	assert_eq(panel.get_decoration_trait_count_in_journal("decoration.bench"), 2, "Decoration trait count in journal for bench is 2")
	assert_eq(panel.get_decoration_trait_count_in_journal("decoration.watering_can"), 0, "Decoration trait count in journal for watering_can is 0")
	assert_true(panel.has_plant_any_traits_in_journal("plant.jasmine"), "has_plant_any_traits_in_journal(plant.jasmine) is true")
	assert_false(panel.has_plant_any_traits_in_journal("plant.unknown"), "has_plant_any_traits_in_journal(plant.unknown) is false")
	assert_true(panel.has_decoration_any_traits_in_journal("decoration.bench"), "has_decoration_any_traits_in_journal(decoration.bench) is true")
	assert_false(panel.has_decoration_any_traits_in_journal("decoration.watering_can"), "has_decoration_any_traits_in_journal(decoration.watering_can) is false")
	assert_eq(
		panel.get_all_plant_display_names_in_journal(),
		["กล้วย", "พริก", "กะเพรา", "มะลิ", "ดาวเรือง"],
		"All plant display names in journal in catalog order"
	)
	assert_eq(
		panel.get_all_visitor_display_names_in_journal(),
		["นกกระจอกบ้านสวน", "ผีเสื้อบ้านสวน", "แมวข้างบ้าน", "หิ่งห้อย", "กบในสวน"],
		"All visitor display names in journal in catalog order"
	)
	assert_eq(panel.get_all_decoration_display_names_in_journal().size(), 8, "8 all decoration display names in journal")
	assert_eq(panel.get_all_event_display_names_in_journal().size(), 6, "6 all event display names in journal")
	assert_eq(panel.get_discovered_plant_display_names_in_journal(), ["มะลิ"], "Discovered plant display names in journal")
	assert_eq(
		panel.get_discovered_visitor_display_names_in_journal(),
		["นกกระจอกบ้านสวน", "ผีเสื้อบ้านสวน"],
		"Discovered visitor display names in journal"
	)
	assert_eq(
		panel.get_placed_decoration_display_names_in_journal(),
		["ม้านั่งไม้ในสวน", "ตุ่มน้ำดินเผา"],
		"Placed decoration display names in journal"
	)
	assert_eq(
		panel.get_active_event_display_names_in_journal(),
		["แมวนอนหลับบนม้านั่ง", "ฝูงผีเสื้อยามเช้า"],
		"Active event display names in journal"
	)
	assert_eq(panel.get_discovered_plant_ids_in_journal(), ["plant.jasmine"], "Discovered plant IDs in journal")
	assert_eq(
		panel.get_undiscovered_plant_ids_in_journal(),
		["plant.banana", "plant.chili", "plant.holy_basil", "plant.marigold"],
		"Undiscovered plant IDs in journal"
	)
	assert_eq(
		panel.get_discovered_visitor_ids_in_journal(),
		["visitor.bird", "visitor.butterfly"],
		"Discovered visitor IDs in journal"
	)
	assert_eq(
		panel.get_undiscovered_visitor_ids_in_journal(),
		["visitor.cat", "visitor.firefly", "visitor.frog"],
		"Undiscovered visitor IDs in journal"
	)
	assert_eq(
		panel.get_eligible_visitor_ids_in_journal(),
		["visitor.butterfly", "visitor.cat", "visitor.firefly", "visitor.frog"],
		"Eligible visitor IDs in journal"
	)
	assert_eq(
		panel.get_ineligible_visitor_ids_in_journal(),
		["visitor.bird"],
		"Ineligible visitor IDs in journal"
	)
	assert_eq(
		panel.get_placed_decoration_ids_in_journal(),
		["decoration.bench", "decoration.clay_jar"],
		"Placed decoration IDs in journal"
	)
	assert_eq(
		panel.get_unplaced_decoration_ids_in_journal(),
		[
			"decoration.garden_lamp",
			"decoration.plant_pot",
			"decoration.small_pond",
			"decoration.small_table",
			"decoration.watering_can",
			"decoration.wooden_fence",
		],
		"Unplaced decoration IDs in journal"
	)
	assert_eq(
		panel.get_active_event_ids_in_journal(),
		["event.cat_sleeping_bench", "event.morning_butterflies"],
		"Active event IDs in journal"
	)
	assert_eq(
		panel.get_inactive_event_ids_in_journal(),
		["event.bird_shade_song", "event.cat_jasmine_night_rest", "event.firefly_night_glow", "event.frog_rain_chorus"],
		"Inactive event IDs in journal"
	)
	assert_eq(
		panel.get_undiscovered_plant_display_names_in_journal(),
		["กล้วย", "พริก", "กะเพรา", "ดาวเรือง"],
		"Undiscovered plant display names in journal"
	)
	assert_eq(
		panel.get_undiscovered_visitor_display_names_in_journal(),
		["แมวข้างบ้าน", "หิ่งห้อย", "กบในสวน"],
		"Undiscovered visitor display names in journal"
	)
	assert_eq(
		panel.get_eligible_visitor_display_names_in_journal(),
		["ผีเสื้อบ้านสวน", "แมวข้างบ้าน", "หิ่งห้อย", "กบในสวน"],
		"Eligible visitor display names in journal"
	)
	assert_eq(
		panel.get_ineligible_visitor_display_names_in_journal(),
		["นกกระจอกบ้านสวน"],
		"Ineligible visitor display names in journal"
	)
	assert_eq(
		panel.get_unplaced_decoration_display_names_in_journal(),
		[
			"โคมไฟในสวน",
			"กระถางดินเผา",
			"บ่อน้ำเล็ก",
			"โต๊ะไม้เล็ก",
			"บัวรดน้ำสังกะสี",
			"รั้วไม้ระแนง",
		],
		"Unplaced decoration display names in journal"
	)
	assert_eq(
		panel.get_inactive_event_display_names_in_journal(),
		["นกร้องเพลงใต้ร่มไม้", "แมวพักใต้กลิ่นมะลิยามค่ำ", "หิ่งห้อยเรืองแสงยามค่ำ", "กบร้องเพลงกลางสายฝน"],
		"Inactive event display names in journal"
	)
	assert_eq(
		panel.get_currently_planted_plant_display_names_in_journal(),
		["มะลิ"],
		"Currently planted plant display names in journal"
	)
	assert_eq(
		panel.get_unplanted_plant_display_names_in_journal(),
		["กล้วย", "พริก", "กะเพรา", "ดาวเรือง"],
		"Unplanted plant display names in journal"
	)
	assert_eq(
		panel.get_plant_ids_with_trait_in_journal("flower"),
		["plant.jasmine", "plant.marigold"],
		"Plant IDs with flower trait in journal"
	)
	assert_eq(panel.get_plant_ids_with_trait_in_journal("unknown_trait"), [], "Unknown trait returns empty plant IDs in journal")
	assert_eq(
		panel.get_decoration_ids_with_trait_in_journal("water"),
		["decoration.clay_jar", "decoration.small_pond"],
		"Decoration IDs with water trait in journal"
	)
	assert_eq(panel.get_decoration_ids_with_trait_in_journal("unknown_trait"), [], "Unknown trait returns empty decoration IDs in journal")
	assert_eq(panel.get_plant_count_with_trait_in_journal("flower"), 2, "2 plants with flower trait in journal")
	assert_eq(panel.get_plant_count_with_trait_in_journal("unknown_trait"), 0, "0 plants with unknown trait in journal")
	assert_eq(panel.get_decoration_count_with_trait_in_journal("water"), 2, "2 decorations with water trait in journal")
	assert_eq(panel.get_decoration_count_with_trait_in_journal("unknown_trait"), 0, "0 decorations with unknown trait in journal")
	assert_true(panel.has_any_plants_with_trait_in_journal("flower"), "has_any_plants_with_trait_in_journal(flower) is true")
	assert_false(panel.has_any_plants_with_trait_in_journal("unknown_trait"), "has_any_plants_with_trait_in_journal(unknown_trait) is false")
	assert_true(panel.has_any_decorations_with_trait_in_journal("water"), "has_any_decorations_with_trait_in_journal(water) is true")
	assert_false(panel.has_any_decorations_with_trait_in_journal("unknown_trait"), "has_any_decorations_with_trait_in_journal(unknown_trait) is false")
	assert_eq(
		panel.get_plant_display_names_with_trait_in_journal("flower"),
		["มะลิ", "ดาวเรือง"],
		"Plant display names with flower trait in journal"
	)
	assert_eq(panel.get_plant_display_names_with_trait_in_journal("unknown_trait"), [], "Unknown trait returns empty plant display names in journal")
	assert_eq(
		panel.get_decoration_display_names_with_trait_in_journal("water"),
		["ตุ่มน้ำดินเผา", "บ่อน้ำเล็ก"],
		"Decoration display names with water trait in journal"
	)
	assert_eq(panel.get_decoration_display_names_with_trait_in_journal("unknown_trait"), [], "Unknown trait returns empty decoration display names in journal")
	assert_true(panel.has_plant_display_name_in_journal("plant.jasmine"), "has_plant_display_name_in_journal(plant.jasmine) is true")
	assert_false(panel.has_plant_display_name_in_journal("plant.unknown"), "has_plant_display_name_in_journal(plant.unknown) is false")
	assert_true(panel.has_visitor_display_name_in_journal("visitor.butterfly"), "has_visitor_display_name_in_journal(visitor.butterfly) is true")
	assert_false(panel.has_visitor_display_name_in_journal("visitor.unknown"), "has_visitor_display_name_in_journal(visitor.unknown) is false")
	assert_true(panel.has_decoration_display_name_in_journal("decoration.bench"), "has_decoration_display_name_in_journal(decoration.bench) is true")
	assert_false(panel.has_decoration_display_name_in_journal("decoration.unknown"), "has_decoration_display_name_in_journal(decoration.unknown) is false")
	assert_true(panel.has_event_display_name_in_journal("event.cat_sleeping_bench"), "has_event_display_name_in_journal(event.cat_sleeping_bench) is true")
	assert_false(panel.has_event_display_name_in_journal("event.unknown"), "has_event_display_name_in_journal(event.unknown) is false")
	assert_true(panel.has_event_description_in_journal("event.cat_sleeping_bench"), "has_event_description_in_journal(event.cat_sleeping_bench) is true")
	assert_false(panel.has_event_description_in_journal("event.unknown"), "has_event_description_in_journal(event.unknown) is false")
	assert_true(panel.has_plant_traits_summary_in_journal("plant.jasmine"), "has_plant_traits_summary_in_journal(plant.jasmine) is true")
	assert_false(panel.has_plant_traits_summary_in_journal("plant.unknown"), "has_plant_traits_summary_in_journal(plant.unknown) is false")
	assert_true(panel.has_decoration_traits_summary_in_journal("decoration.bench"), "has_decoration_traits_summary_in_journal(decoration.bench) is true")
	assert_false(panel.has_decoration_traits_summary_in_journal("decoration.unknown"), "has_decoration_traits_summary_in_journal(decoration.unknown) is false")
	assert_true(panel.has_visitor_clue_in_journal("visitor.butterfly"), "has_visitor_clue_in_journal(visitor.butterfly) is true")
	assert_false(panel.has_visitor_clue_in_journal("visitor.unknown"), "has_visitor_clue_in_journal(visitor.unknown) is false")
	assert_true(panel.has_event_clue_in_journal("event.frog_rain_chorus"), "has_event_clue_in_journal(event.frog_rain_chorus) is true")
	assert_false(panel.has_event_clue_in_journal("event.unknown"), "has_event_clue_in_journal(event.unknown) is false")
	assert_true(panel.has_decoration_positive_price_in_journal("decoration.bench"), "has_decoration_positive_price_in_journal(decoration.bench) is true")
	assert_false(panel.has_decoration_positive_price_in_journal("decoration.unknown"), "has_decoration_positive_price_in_journal(decoration.unknown) is false")
	assert_true(panel.has_plant_positive_harvest_reward_in_journal("plant.jasmine"), "has_plant_positive_harvest_reward_in_journal(plant.jasmine) is true")
	assert_false(panel.has_plant_positive_harvest_reward_in_journal("plant.unknown"), "has_plant_positive_harvest_reward_in_journal(plant.unknown) is false")
	assert_true(panel.has_plant_positive_mature_duration_in_journal("plant.jasmine"), "has_plant_positive_mature_duration_in_journal(plant.jasmine) is true")
	assert_false(panel.has_plant_positive_mature_duration_in_journal("plant.unknown"), "has_plant_positive_mature_duration_in_journal(plant.unknown) is false")
	assert_true(
		panel.get_summary_text().contains("ของตกแต่ง 2/8 | เหตุการณ์ 2/6"),
		"Journal summary text includes placed decorations and active events"
	)
	assert_eq(panel.get_placed_count_for_decoration_id("decoration.bench"), 2, "Bench placed count query returns 2")
	assert_eq(panel.get_placed_count_for_decoration_id("decoration.small_pond"), 0, "Unplaced small_pond count query returns 0")
	assert_true(panel.is_event_active_in_journal("event.cat_sleeping_bench"), "Cat sleeping on bench active in journal")
	assert_false(panel.is_event_active_in_journal("event.frog_rain_chorus"), "Frog rain chorus inactive at clear weather in journal")
	assert_true(
		panel.get_entry_text_for_id("visitor.butterfly").contains("สถานะในสวน: มีโอกาสพบในขณะนี้"),
		"Discovered eligible visitor shows มีโอกาสพบในขณะนี้"
	)
	assert_true(
		panel.get_entry_text_for_id("visitor.bird").contains("สถานะในสวน: ยังไม่ตรงเงื่อนไขในขณะนี้"),
		"Discovered ineligible visitor shows ยังไม่ตรงเงื่อนไขในขณะนี้"
	)

	assert_eq(panel.get_placed_decoration_entry_count(), 2, "2 distinct decoration types placed (bench + clay_jar)")
	var bench_text: String = panel.get_entry_text_for_id("decoration.bench")
	assert_true(bench_text.contains("[จัดวางแล้ว] ม้านั่งไม้ในสวน (decoration.bench)"), "Bench marked as placed")
	assert_true(bench_text.contains("จำนวนที่วางในสวน: 2 ชิ้น"), "Bench shows count = 2")
	assert_true(bench_text.contains("ร่มเงา, ที่หลบพัก"), "Bench shows environmental traits")

	var jar_text: String = panel.get_entry_text_for_id("decoration.clay_jar")
	assert_true(jar_text.contains("[จัดวางแล้ว] ตุ่มน้ำดินเผา (decoration.clay_jar)"), "Clay jar marked as placed")
	assert_true(jar_text.contains("จำนวนที่วางในสวน: 1 ชิ้น"), "Clay jar shows count = 1")
	assert_true(jar_text.contains("แหล่งน้ำ"), "Clay jar shows water trait")

	# At morning + clear with jasmine + bench: morning_butterflies and cat_sleeping_bench are eligible
	assert_eq(panel.get_active_event_entry_count(), 2, "2 active events (morning_butterflies + cat_sleeping_bench)")
	var cat_ev_text: String = panel.get_entry_text_for_id("event.cat_sleeping_bench")
	assert_true(
		cat_ev_text.contains("[เกิดขึ้นได้ในสวน] แมวนอนหลับบนม้านั่ง (event.cat_sleeping_bench)"),
		"Active cat_sleeping_bench shows [เกิดขึ้นได้ในสวน]"
	)
	assert_true(
		cat_ev_text.contains("แมวข้างบ้านขดตัวนอนหลับอย่างสบายใจอยู่บนม้านั่งไม้"),
		"Active cat_sleeping_bench shows flavor description"
	)

	var frog_ev_text: String = panel.get_entry_text_for_id("event.frog_rain_chorus")
	assert_true(
		frog_ev_text.contains("[???] เหตุการณ์พิเศษปริศนา"),
		"Inactive frog_rain_chorus at clear weather remains [???]"
	)
	assert_true(
		frog_ev_text.contains("สภาพอากาศ: ฝนตก"),
		"Frog rain chorus clue includes rain requirement"
	)

	panel.free()


func _test_secret_combination_event_hides_recipe() -> void:
	describe("JournalPanel keeps the secret combination event unnamed and recipe-free until its combination is present")
	var panel: JournalPanel = _instantiate_journal()
	var catalog: ContentCatalog = _create_full_production_catalog()
	var secret_id: String = "event.cat_jasmine_night_rest"
	var secret_name: String = GardenView.PROVISIONAL_EVENT_DISPLAY_NAMES[secret_id]
	var jasmine_name: String = PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES["plant.jasmine"]
	var bench_name: String = DecorationPicker.PROVISIONAL_DECORATION_DISPLAY_NAMES["decoration.bench"]
	var night_utc: int = 3600

	# 1. Bench + 2 jasmine at night: secret is inactive and must not reveal name, ID, or recipe.
	var state: GameState = GameState.new()
	state.get_decorations().try_add_decoration(DecorationState.new("dec-1", "decoration.bench", 100))
	state.get_plants().try_add_plant(PlantState.new("jas-1", "plant.jasmine", 100))
	state.get_plants().try_add_plant(PlantState.new("jas-2", "plant.jasmine", 100))
	var partial_snapshot: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, night_utc)
	panel.bind_journal(state.get_journal(), catalog, state.get_decorations(), partial_snapshot)

	assert_false(panel.is_event_active_in_journal(secret_id), "Secret inactive with only 2 jasmine")
	var hidden_text: String = panel.get_entry_text_for_id(secret_id)
	assert_true(hidden_text.contains("[???] เหตุการณ์ลับปริศนา"), "Inactive secret shows secret placeholder")
	assert_true(hidden_text.contains(JournalPanel.SECRET_EVENT_CLUE_TEXT), "Inactive secret shows experimentation hint")
	assert_false(hidden_text.contains(secret_name), "Inactive secret hides its display name")
	assert_false(hidden_text.contains(secret_id), "Inactive secret hides its definition ID")
	assert_false(hidden_text.contains(jasmine_name), "Inactive secret hides required plant")
	assert_false(hidden_text.contains(bench_name), "Inactive secret hides required decoration")
	assert_eq(panel.get_event_clue_in_journal(secret_id), JournalPanel.SECRET_EVENT_CLUE_TEXT, "Clue query returns the secret hint, not the recipe")
	assert_true(
		panel.get_event_clue_in_journal("event.cat_sleeping_bench").contains(bench_name),
		"Non-secret event clue still lists its conditions"
	)

	# 2. Third jasmine completes the combination: the event becomes active and named, recipe stays hidden.
	state.get_plants().try_add_plant(PlantState.new("jas-3", "plant.jasmine", 100))
	var full_snapshot: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, night_utc)
	panel.bind_journal(state.get_journal(), catalog, state.get_decorations(), full_snapshot)

	assert_true(panel.is_event_active_in_journal(secret_id), "Secret active with 3 jasmine + bench at night")
	var active_text: String = panel.get_entry_text_for_id(secret_id)
	assert_true(active_text.contains("[เกิดขึ้นได้ในสวน]"), "Active secret shows active marker")
	assert_true(active_text.contains(secret_name), "Active secret shows its display name")
	assert_true(active_text.contains(GardenView.PROVISIONAL_EVENT_DESCRIPTIONS[secret_id]), "Active secret shows its description")
	assert_false(active_text.contains(jasmine_name + " x3"), "Active secret still hides the exact recipe")
	panel.free()
