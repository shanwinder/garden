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
