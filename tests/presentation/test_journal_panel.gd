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
	describe("JournalPanel renders 8 decorations and 5 ambient events with placed counts and condition clues")
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
	assert_eq(panel.get_total_event_entry_count(), 5, "5 event definitions rendered")
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
