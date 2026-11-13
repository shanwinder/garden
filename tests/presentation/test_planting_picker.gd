## test_planting_picker.gd
## Comprehensive test suite for PlantingPicker presentation component.
##
## Covers requirements A through R:
## A. Picker scene loads.
## B. Type and scene contracts.
## C. Catalog binding succeeds.
## D. Five production IDs can be displayed.
## E. Deterministic ID order.
## F. Correct Thai display labels.
## G. Empty/null catalog cannot issue planting.
## H. Plant type selection alone emits no request.
## I. Cancel emits no request.
## J. Confirm emits exactly one correct ID.
## K. Repeated confirm from the same dialog state cannot emit multiple requests.
## L. Wrong/unknown ID cannot be submitted.
## M. Repeated catalog binding does not duplicate signals.
## N. Picker can be used again for a fresh confirmation.
## O. No GameState mutation.
## P. No save/clock/RNG access.
## Q. Touch controls are enabled only when ready.
## R. No scene-load errors.
class_name TestPlantingPicker
extends TestSuiteBase

const PICKER_SCENE_PATH: String = "res://scenes/garden/planting_picker.tscn"


class SignalTracker extends RefCounted:
	var emitted_count: int = 0
	var received_ids: Array[String] = []

	func on_planting_requested(def_id: String) -> void:
		emitted_count += 1
		received_ids.append(def_id)


func _init() -> void:
	suite_name = "TestPlantingPicker"


func run_tests() -> void:
	_test_a_picker_scene_loads()
	_test_b_type_and_scene_contracts()
	_test_c_catalog_binding_succeeds()
	_test_d_five_production_ids_displayed()
	_test_e_deterministic_id_order()
	_test_f_correct_thai_display_labels()
	_test_g_empty_null_catalog_cannot_issue_planting()
	_test_h_plant_type_selection_alone_emits_no_request()
	_test_i_cancel_emits_no_request()
	_test_j_confirm_emits_exactly_one_correct_id()
	_test_k_repeated_confirm_from_same_dialog_cannot_emit_multiple()
	_test_l_wrong_unknown_id_cannot_be_submitted()
	_test_m_repeated_catalog_binding_does_not_duplicate_signals()
	_test_n_picker_can_be_used_again_for_fresh_confirmation()
	_test_o_no_gamestate_mutation()
	_test_p_no_save_clock_rng_access()
	_test_q_touch_controls_enabled_only_when_ready()
	_test_r_no_scene_load_errors()
	_test_s_rich_metadata_and_garden_context()
	_test_t_target_placement_note_and_full_garden()


func _create_production_catalog() -> ContentCatalog:
	var banana: PlantDefinition = PlantDefinition.new()
	banana.id = "plant.banana"
	banana.sprout_after_seconds = 600
	banana.growing_after_seconds = 1800
	banana.mature_after_seconds = 3600

	var chili: PlantDefinition = PlantDefinition.new()
	chili.id = "plant.chili"
	chili.sprout_after_seconds = 120
	chili.growing_after_seconds = 360
	chili.mature_after_seconds = 600

	var basil: PlantDefinition = PlantDefinition.new()
	basil.id = "plant.holy_basil"
	basil.sprout_after_seconds = 60
	basil.growing_after_seconds = 180
	basil.mature_after_seconds = 300

	var jasmine: PlantDefinition = PlantDefinition.new()
	jasmine.id = "plant.jasmine"
	jasmine.sprout_after_seconds = 300
	jasmine.growing_after_seconds = 900
	jasmine.mature_after_seconds = 1800

	var marigold: PlantDefinition = PlantDefinition.new()
	marigold.id = "plant.marigold"
	marigold.sprout_after_seconds = 90
	marigold.growing_after_seconds = 240
	marigold.mature_after_seconds = 450

	return ContentCatalog.try_create([banana, chili, basil, jasmine, marigold])


func _instantiate_picker() -> PlantingPicker:
	var scene: PackedScene = load(PICKER_SCENE_PATH) as PackedScene
	var picker: PlantingPicker = scene.instantiate() as PlantingPicker
	return picker


func _test_a_picker_scene_loads() -> void:
	describe("A. PlantingPicker PackedScene loads successfully")
	var scene: PackedScene = load(PICKER_SCENE_PATH) as PackedScene
	assert_true(scene != null, "PlantingPicker scene must load")
	var picker: Node = scene.instantiate()
	assert_true(picker != null, "PlantingPicker must instantiate")
	picker.free()


func _test_b_type_and_scene_contracts() -> void:
	describe("B. Type and scene contracts")
	var picker: PlantingPicker = _instantiate_picker()
	assert_true(picker is PlantingPicker, "Must be an instance of PlantingPicker")
	assert_true(picker is Control, "Must extend Control")
	assert_true(picker.has_signal("planting_requested"), "Must declare planting_requested signal")
	assert_true(picker.has_signal("picker_closed"), "Must declare picker_closed signal")
	picker.free()


func _test_c_catalog_binding_succeeds() -> void:
	describe("C. Catalog binding succeeds")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	var ids: Array[String] = picker.get_available_plant_ids()
	assert_eq(ids.size(), 5, "Catalog binding must populate 5 entries")
	picker.free()


func _test_d_five_production_ids_displayed() -> void:
	describe("D. Five production IDs can be displayed")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	var buttons: Array[Button] = picker.get_plant_buttons()
	assert_eq(buttons.size(), 5, "Must render exactly 5 selection buttons")
	picker.free()


func _test_e_deterministic_id_order() -> void:
	describe("E. Deterministic ID order matching catalog order")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	var expected_ids: Array[String] = [
		"plant.banana",
		"plant.chili",
		"plant.holy_basil",
		"plant.jasmine",
		"plant.marigold",
	]
	var ids: Array[String] = picker.get_available_plant_ids()
	assert_eq(ids, expected_ids, "Available IDs must match deterministic catalog order")
	picker.free()


func _test_f_correct_thai_display_labels() -> void:
	describe("F. Correct Thai display labels for the five plants")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	var buttons: Array[Button] = picker.get_plant_buttons()
	assert_true(buttons[0].text.contains("กล้วย"), "First button must contain กล้วย")
	assert_true(buttons[1].text.contains("พริก"), "Second button must contain พริก")
	assert_true(buttons[2].text.contains("กะเพรา"), "Third button must contain กะเพรา")
	assert_true(buttons[3].text.contains("มะลิ"), "Fourth button must contain มะลิ")
	assert_true(buttons[4].text.contains("ดาวเรือง"), "Fifth button must contain ดาวเรือง")
	var note_label: Label = picker.find_child("NoteLabel", true, false) as Label
	var confirm_notice: Label = picker.find_child("ConfirmNoticeLabel", true, false) as Label
	assert_true(note_label != null and not note_label.text.contains("ยังไม่รองรับ"), "Picker note reflects cell placement support")
	assert_true(confirm_notice != null and not confirm_notice.text.contains("ยังไม่กำหนดตำแหน่ง"), "Confirm notice no longer says unpositioned")
	picker.free()


func _test_g_empty_null_catalog_cannot_issue_planting() -> void:
	describe("G. Empty or null catalog cannot issue planting")
	var picker: PlantingPicker = _instantiate_picker()
	var tracker: SignalTracker = SignalTracker.new()
	picker.planting_requested.connect(tracker.on_planting_requested)

	# Null catalog
	picker.bind_catalog(null)
	assert_eq(picker.get_available_plant_ids().size(), 0, "Null catalog gives empty ID list")
	picker.select_plant_definition("plant.holy_basil")
	assert_false(picker.is_confirmation_active(), "Cannot select plant with null catalog")
	picker.confirm_planting()
	assert_eq(tracker.emitted_count, 0, "No request emitted with null catalog")

	# Empty catalog
	var empty_cat: ContentCatalog = ContentCatalog.try_create([])
	picker.bind_catalog(empty_cat)
	assert_eq(picker.get_available_plant_ids().size(), 0, "Empty catalog gives empty ID list")
	picker.select_plant_definition("plant.holy_basil")
	assert_false(picker.is_confirmation_active(), "Cannot select plant with empty catalog")
	picker.confirm_planting()
	assert_eq(tracker.emitted_count, 0, "No request emitted with empty catalog")
	picker.free()


func _test_h_plant_type_selection_alone_emits_no_request() -> void:
	describe("H. Plant type selection alone emits no request")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	var tracker: SignalTracker = SignalTracker.new()
	picker.planting_requested.connect(tracker.on_planting_requested)

	picker.select_plant_definition("plant.holy_basil")

	assert_true(picker.is_confirmation_active(), "Confirmation prompt must become active")
	assert_eq(picker.get_pending_definition_id(), "plant.holy_basil", "Pending definition ID recorded")
	assert_eq(tracker.emitted_count, 0, "Selecting alone must emit zero planting requests")
	picker.free()


func _test_i_cancel_emits_no_request() -> void:
	describe("I. Cancel emits no request and clears pending selection")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	var tracker: SignalTracker = SignalTracker.new()
	picker.planting_requested.connect(tracker.on_planting_requested)

	picker.select_plant_definition("plant.chili")
	assert_true(picker.is_confirmation_active(), "Confirmation active before cancel")

	picker.cancel_confirmation()
	assert_false(picker.is_confirmation_active(), "Confirmation inactive after cancel")
	assert_eq(picker.get_pending_definition_id(), "", "Pending ID cleared after cancel")
	assert_eq(tracker.emitted_count, 0, "Cancel must emit zero planting requests")
	picker.free()


func _test_j_confirm_emits_exactly_one_correct_id() -> void:
	describe("J. Confirm emits exactly one correct ID")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	var tracker: SignalTracker = SignalTracker.new()
	picker.planting_requested.connect(tracker.on_planting_requested)

	picker.select_plant_definition("plant.jasmine")
	picker.confirm_planting()

	assert_eq(tracker.emitted_count, 1, "Must emit exactly one request")
	assert_eq(tracker.received_ids[0], "plant.jasmine", "Emitted ID must be plant.jasmine")
	assert_false(picker.is_confirmation_active(), "Confirmation overlay must be closed")
	assert_eq(picker.get_pending_definition_id(), "", "Pending ID cleared")
	picker.free()


func _test_k_repeated_confirm_from_same_dialog_cannot_emit_multiple() -> void:
	describe("K. Repeated confirm from the same dialog state cannot emit multiple requests")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	var tracker: SignalTracker = SignalTracker.new()
	picker.planting_requested.connect(tracker.on_planting_requested)

	picker.select_plant_definition("plant.marigold")
	picker.confirm_planting()
	assert_eq(tracker.emitted_count, 1, "First confirm succeeds")

	# Second confirm without re-selecting
	picker.confirm_planting()
	assert_eq(tracker.emitted_count, 1, "Second confirm must not emit another request")
	picker.free()


func _test_l_wrong_unknown_id_cannot_be_submitted() -> void:
	describe("L. Wrong or unknown ID cannot be submitted")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	var tracker: SignalTracker = SignalTracker.new()
	picker.planting_requested.connect(tracker.on_planting_requested)

	picker.select_plant_definition("plant.non_existent")
	assert_false(picker.is_confirmation_active(), "Unknown ID must not activate confirmation")
	assert_eq(picker.get_pending_definition_id(), "", "Unknown ID must not become pending")

	picker.confirm_planting()
	assert_eq(tracker.emitted_count, 0, "No request emitted for unknown ID")
	picker.free()


func _test_m_repeated_catalog_binding_does_not_duplicate_signals() -> void:
	describe("M. Repeated catalog binding does not duplicate signals")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()

	# Bind multiple times
	picker.bind_catalog(catalog)
	picker.bind_catalog(catalog)
	picker.bind_catalog(catalog)

	var tracker: SignalTracker = SignalTracker.new()
	picker.planting_requested.connect(tracker.on_planting_requested)

	picker.select_plant_definition("plant.holy_basil")
	picker.confirm_planting()

	assert_eq(tracker.emitted_count, 1, "Must emit exactly one request despite repeated binds")
	assert_eq(picker.get_plant_buttons().size(), 5, "Must still have exactly 5 buttons")
	picker.free()


func _test_n_picker_can_be_used_again_for_fresh_confirmation() -> void:
	describe("N. Picker can be used again for a fresh confirmation")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	var tracker: SignalTracker = SignalTracker.new()
	picker.planting_requested.connect(tracker.on_planting_requested)

	# First flow
	picker.open_picker()
	picker.select_plant_definition("plant.banana")
	picker.confirm_planting()
	assert_eq(tracker.emitted_count, 1)
	assert_eq(tracker.received_ids[0], "plant.banana")

	# Second separate intentional flow
	picker.open_picker()
	picker.select_plant_definition("plant.banana")
	picker.confirm_planting()
	assert_eq(tracker.emitted_count, 2)
	assert_eq(tracker.received_ids[1], "plant.banana")
	picker.free()


func _test_o_no_gamestate_mutation() -> void:
	describe("O. Picker maintains no GameState mutation capability")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	assert_false(picker.has_method("get_state"), "Picker must not have get_state")
	assert_false(picker.has_method("set_state"), "Picker must not have set_state")
	assert_false(picker.has_method("save"), "Picker must not have save method")
	picker.free()


func _test_p_no_save_clock_rng_access() -> void:
	describe("P. Picker does not access save repository, clock, or RNG")
	var picker: PlantingPicker = _instantiate_picker()
	assert_true(picker.get("save_repository") == null, "No save repository property")
	assert_true(picker.get("game_clock") == null, "No game clock property")
	assert_true(picker.get("random_source") == null, "No random source property")
	picker.free()


func _test_q_touch_controls_enabled_only_when_ready() -> void:
	describe("Q. Touch controls are enabled only when ready")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	assert_true(picker.is_picker_enabled(), "Default state is enabled")

	picker.set_picker_enabled(false)
	assert_false(picker.is_picker_enabled(), "State is disabled")
	for btn: Button in picker.get_plant_buttons():
		assert_true(btn.disabled, "Plant buttons disabled when picker disabled")

	var tracker: SignalTracker = SignalTracker.new()
	picker.planting_requested.connect(tracker.on_planting_requested)
	picker.select_plant_definition("plant.holy_basil")
	assert_false(picker.is_confirmation_active(), "Cannot select when disabled")
	picker.confirm_planting()
	assert_eq(tracker.emitted_count, 0, "Cannot confirm when disabled")
	picker.free()


func _test_r_no_scene_load_errors() -> void:
	describe("R. Scene loads without script errors or missing references")
	var scene: PackedScene = load(PICKER_SCENE_PATH) as PackedScene
	assert_true(scene != null, "Scene loads cleanly")
	var instance: PlantingPicker = scene.instantiate() as PlantingPicker
	assert_true(instance != null, "Instance is valid")
	instance._ready()
	assert_false(instance.is_confirmation_active(), "Confirmation overlay hidden by default")
	instance.free()


func _test_s_rich_metadata_and_garden_context() -> void:
	describe("S. PlantingPicker displays growth duration, reward, traits, and planted count from GardenSnapshot")
	var picker: PlantingPicker = _instantiate_picker()
	var p_res: PlantContentLoadResult = PlantContentLoader.new().load_production_definitions()
	var catalog: ContentCatalog = ContentCatalog.try_create(p_res.get_definitions())
	picker.bind_catalog(catalog)

	assert_eq(picker.get_planted_count_for_id("plant.jasmine"), 0, "Before snapshot context: planted count is 0")
	var jasmine_text_before: String = picker.get_plant_option_text_for_id("plant.jasmine")
	assert_true(jasmine_text_before.contains("มะลิ"), "Jasmine option contains Thai name")
	assert_true(jasmine_text_before.contains("โตเต็มที่ 3600 วินาที"), "Jasmine option contains mature duration")
	assert_true(jasmine_text_before.contains("รางวัล +25 เหรียญ"), "Jasmine option contains harvest reward")
	assert_true(jasmine_text_before.contains("ดอกไม้"), "Jasmine option contains flower trait")

	var snapshot: GardenSnapshot = GardenSnapshot.new(
		{"dense_vegetation": 2, "flower": 2},
		{"plant.jasmine": 2},
		2,
		1
	)
	var journal: JournalState = JournalState.new()
	journal.try_record_sighting("plant.jasmine", 1000)
	picker.update_garden_context(snapshot, journal)
	assert_eq(picker.get_planted_count_for_id("plant.jasmine"), 2, "After snapshot context: jasmine planted count is 2")
	assert_eq(picker.get_planted_count_for_id("plant.banana"), 0, "Unplanted banana count is 0")
	assert_true(picker.is_plant_discovered("plant.jasmine"), "Jasmine is marked discovered in picker")
	assert_false(picker.is_plant_discovered("plant.banana"), "Banana is not yet discovered in picker")
	assert_eq(
		picker.get_undiscovered_plant_ids(),
		["plant.banana", "plant.chili", "plant.holy_basil", "plant.marigold"],
		"Undiscovered plant IDs returned in deterministic catalog order"
	)
	assert_eq(
		picker.get_discovered_plant_ids(),
		["plant.jasmine"],
		"Discovered plant IDs returned in deterministic catalog order"
	)
	assert_eq(
		picker.get_plant_traits_for_id("plant.jasmine"),
		["dense_vegetation", "flower"],
		"Plant traits query returns jasmine traits"
	)
	assert_true(
		picker.get_plant_option_text_for_id("plant.jasmine").contains("ปลูกแล้ว 2 ต้น"),
		"Jasmine button text updated in-place with planted count"
	)
	assert_true(
		picker.get_plant_option_text_for_id("plant.jasmine").contains("[ค้นพบแล้ว]"),
		"Discovered jasmine button shows [ค้นพบแล้ว] badge"
	)
	assert_true(
		picker.get_plant_option_text_for_id("plant.banana").contains("[พันธุ์ใหม่]"),
		"Undiscovered banana button shows [พันธุ์ใหม่] badge"
	)
	picker.select_plant_definition("plant.jasmine")
	assert_eq(picker.get_sprout_after_seconds_for_id("plant.jasmine"), 300, "Jasmine sprout duration query returns 300")
	assert_eq(picker.get_growing_after_seconds_for_id("plant.jasmine"), 1200, "Jasmine growing duration query returns 1200")
	assert_eq(picker.get_mature_after_seconds_for_id("plant.jasmine"), 3600, "Jasmine mature duration query returns 3600")
	assert_eq(picker.get_harvest_reward_for_id("plant.jasmine"), 25, "Jasmine harvest reward query returns 25")
	assert_eq(picker.get_sprout_after_seconds_for_id("plant.unknown"), 0, "Unknown plant sprout duration query returns 0")
	assert_eq(picker.get_growing_after_seconds_for_id("plant.unknown"), 0, "Unknown plant growing duration query returns 0")
	assert_eq(picker.get_mature_after_seconds_for_id("plant.unknown"), 0, "Unknown plant mature duration query returns 0")
	assert_eq(picker.get_harvest_reward_for_id("plant.unknown"), 0, "Unknown plant harvest reward query returns 0")
	assert_eq(picker.get_planted_plant_ids(), ["plant.jasmine"], "Planted plant IDs query returns [plant.jasmine]")
	assert_eq(picker.get_planted_species_count(), 1, "Planted species count query returns 1")
	assert_eq(picker.get_unplanted_species_count(), 4, "Unplanted species count query returns 4")
	assert_eq(picker.get_discovered_plant_count(), 1, "Discovered plant count query returns 1")
	assert_eq(picker.get_undiscovered_plant_count(), 4, "Undiscovered plant count query returns 4")
	assert_eq(picker.get_total_planted_instance_count(), 2, "Total planted instance count query returns 2")
	assert_true(picker.has_plant_trait("plant.jasmine", "flower"), "Jasmine has flower trait")
	assert_false(picker.has_plant_trait("plant.jasmine", "fruit"), "Jasmine does not have fruit trait")
	assert_false(picker.has_plant_trait("plant.unknown", "flower"), "Unknown plant does not have flower trait")
	assert_eq(
		picker.get_plant_ids_with_trait("flower"),
		["plant.jasmine", "plant.marigold"],
		"Plants with flower trait returned in catalog order"
	)
	assert_eq(
		picker.get_plant_count_with_trait("flower"),
		2,
		"2 plants with flower trait in catalog"
	)
	assert_eq(
		picker.get_plant_ids_with_trait("non_existent_trait"),
		[],
		"Plants with unknown trait returns empty array"
	)
	assert_eq(
		picker.get_plant_count_with_trait("non_existent_trait"),
		0,
		"0 plants with unknown trait"
	)
	assert_eq(picker.get_total_catalog_plant_count(), 5, "Total catalog plant count is 5")
	assert_false(picker.is_all_plants_discovered(), "Not all plants discovered (1/5)")
	assert_false(picker.is_all_plant_species_planted(), "Not all plant species planted (1/5)")
	assert_eq(picker.get_plant_display_name_for_id("plant.jasmine"), "มะลิ", "Display name query for jasmine returns มะลิ")
	assert_eq(picker.get_plant_display_name_for_id("plant.unknown"), "", "Display name query for unknown plant returns empty string")
	assert_eq(picker.get_plant_trait_count_for_id("plant.jasmine"), 2, "Jasmine trait count is 2")
	assert_eq(picker.get_plant_trait_count_for_id("plant.unknown"), 0, "Unknown plant trait count is 0")
	assert_true(picker.has_any_planted_plants(), "Has planted plants when jasmine is planted")
	assert_true(picker.has_any_discovered_plants(), "Has discovered plants when jasmine is discovered")
	assert_true(picker.has_plant_in_catalog("plant.jasmine"), "Jasmine exists in bound catalog")
	assert_false(picker.has_plant_in_catalog("plant.unknown"), "Unknown plant does not exist in bound catalog")
	assert_true(picker.has_any_undiscovered_plants(), "Has undiscovered plants when 4/5 are undiscovered")
	assert_true(picker.has_any_unplanted_plants(), "Has unplanted plants when 4/5 are unplanted")
	assert_true(picker.has_bound_catalog(), "Catalog is bound to picker")
	assert_true(picker.has_bound_snapshot(), "Snapshot is bound to picker")
	assert_true(picker.has_bound_journal(), "Journal is bound to picker")
	assert_true(picker.has_pending_selection(), "Pending selection is active after select_plant_definition")
	assert_true(picker.is_pending_plant_discovered(), "Pending jasmine is discovered")
	assert_true(picker.is_pending_plant_currently_planted(), "Pending jasmine is currently planted")
	assert_eq(picker.get_pending_plant_planted_count(), 2, "Pending jasmine planted count is 2")
	assert_eq(picker.get_pending_plant_harvest_reward(), 25, "Pending jasmine harvest reward is 25")
	assert_eq(picker.get_pending_plant_mature_after_seconds(), 3600, "Pending jasmine mature duration is 3600")
	assert_eq(picker.get_pending_plant_display_name(), "มะลิ", "Pending jasmine display name is มะลิ")
	assert_eq(picker.get_pending_plant_traits(), ["dense_vegetation", "flower"], "Pending jasmine traits match catalog")
	assert_eq(picker.get_pending_plant_trait_count(), 2, "Pending jasmine trait count is 2")
	assert_true(picker.has_pending_plant_any_traits(), "Pending jasmine has_pending_plant_any_traits() is true")
	assert_eq(
		picker.get_pending_plant_sprout_after_seconds(),
		picker.get_sprout_after_seconds_for_id("plant.jasmine"),
		"Pending jasmine sprout duration matches catalog"
	)
	assert_eq(
		picker.get_pending_plant_growing_after_seconds(),
		picker.get_growing_after_seconds_for_id("plant.jasmine"),
		"Pending jasmine growing duration matches catalog"
	)
	assert_true(picker.has_pending_plant_trait("flower"), "Pending jasmine has flower trait")
	assert_false(picker.has_pending_plant_trait("fruit"), "Pending jasmine does not have fruit trait")
	assert_eq(
		picker.get_pending_plant_option_text(),
		picker.get_plant_option_text_for_id("plant.jasmine"),
		"Pending jasmine option text matches option text for ID"
	)
	assert_eq(picker.get_plant_button_count(), 5, "Picker renders 5 plant option buttons")
	assert_true(picker.has_confirm_prompt_text(), "Confirmation prompt has non-empty text")
	assert_eq(
		picker.get_plant_traits_summary_for_id("plant.jasmine"),
		"พุ่มไม้หนาแน่น, ดอกไม้",
		"Traits summary for jasmine returns พุ่มไม้หนาแน่น, ดอกไม้"
	)
	assert_eq(picker.get_plant_traits_summary_for_id("plant.unknown"), "", "Traits summary for unknown plant returns empty string")
	assert_eq(
		picker.get_pending_plant_traits_summary(),
		"พุ่มไม้หนาแน่น, ดอกไม้",
		"Pending jasmine traits summary returns พุ่มไม้หนาแน่น, ดอกไม้"
	)
	assert_true(picker.is_known_plant_definition("plant.jasmine"), "jasmine is a known plant definition")
	assert_false(picker.is_known_plant_definition("plant.unknown"), "unknown is not a known plant definition")
	assert_true(picker.is_known_environmental_trait("flower"), "flower is a known environmental trait")
	assert_false(picker.is_known_environmental_trait("unknown_trait"), "unknown_trait is not a known environmental trait")
	assert_eq(picker.get_trait_display_name_for_id("flower"), "ดอกไม้", "Trait display name for flower is ดอกไม้")
	assert_eq(picker.get_trait_display_name_for_id(""), "", "Trait display name for empty string is empty")
	assert_eq(
		picker.get_plant_trait_display_names_for_id("plant.jasmine"),
		["พุ่มไม้หนาแน่น", "ดอกไม้"],
		"Plant trait display names for jasmine return [พุ่มไม้หนาแน่น, ดอกไม้]"
	)
	assert_eq(picker.get_plant_trait_display_names_for_id("plant.unknown"), [], "Plant trait display names for unknown return []")
	assert_eq(
		picker.get_pending_plant_trait_display_names(),
		["พุ่มไม้หนาแน่น", "ดอกไม้"],
		"Pending jasmine trait display names return [พุ่มไม้หนาแน่น, ดอกไม้]"
	)
	assert_true(picker.has_plant_any_traits("plant.jasmine"), "has_plant_any_traits(plant.jasmine) is true")
	assert_false(picker.has_plant_any_traits("plant.unknown"), "has_plant_any_traits(plant.unknown) is false")
	assert_eq(
		picker.get_available_plant_display_names(),
		["กล้วย", "พริก", "กะเพรา", "มะลิ", "ดาวเรือง"],
		"Available plant display names in catalog order"
	)
	assert_eq(
		picker.get_planted_plant_display_names(),
		["มะลิ"],
		"Planted plant display names return [มะลิ]"
	)
	assert_eq(
		picker.get_unplanted_plant_display_names(),
		["กล้วย", "พริก", "กะเพรา", "ดาวเรือง"],
		"Unplanted plant display names in catalog order"
	)
	assert_eq(
		picker.get_discovered_plant_display_names(),
		["มะลิ"],
		"Discovered plant display names return [มะลิ]"
	)
	assert_eq(
		picker.get_undiscovered_plant_display_names(),
		["กล้วย", "พริก", "กะเพรา", "ดาวเรือง"],
		"Undiscovered plant display names in catalog order"
	)
	assert_true(picker.is_pending_plant_known_definition(), "Pending jasmine is a known plant definition")
	assert_eq(
		picker.get_plant_display_names_with_trait("flower"),
		["มะลิ", "ดาวเรือง"],
		"Plant display names with flower trait in catalog order"
	)
	assert_eq(
		picker.get_plant_display_names_with_trait("non_existent_trait"),
		[],
		"Plant display names with unknown trait returns empty array"
	)
	assert_true(picker.has_any_plants_with_trait("flower"), "has_any_plants_with_trait(flower) is true")
	assert_false(picker.has_any_plants_with_trait("non_existent_trait"), "has_any_plants_with_trait(non_existent_trait) is false")
	assert_true(picker.is_pending_plant_in_catalog(), "Pending jasmine is in catalog")
	assert_true(picker.has_pending_plant_harvest_reward(), "Pending jasmine has positive harvest reward")
	assert_true(picker.has_pending_plant_mature_duration(), "Pending jasmine has positive mature duration")
	assert_false(picker.is_pending_plant_undiscovered(), "Pending jasmine is not undiscovered")
	assert_false(picker.is_pending_plant_unplanted(), "Pending jasmine is not unplanted")
	assert_true(picker.has_pending_plant_sprout_duration(), "Pending jasmine has positive sprout duration")
	assert_true(picker.has_pending_plant_growing_duration(), "Pending jasmine has positive growing duration")
	assert_true(picker.has_pending_plant_traits_summary(), "Pending jasmine has non-empty traits summary")
	assert_true(picker.has_pending_plant_option_text(), "Pending jasmine has non-empty option text")
	assert_true(picker.has_pending_plant_display_name(), "Pending jasmine has non-empty display name")
	assert_true(picker.has_plant_option_text_for_id("plant.jasmine"), "Jasmine has non-empty option text for ID")
	assert_false(picker.has_plant_option_text_for_id("plant.unknown"), "Unknown plant has no option text for ID")
	assert_true(picker.has_plant_display_name_for_id("plant.jasmine"), "Jasmine has non-empty display name for ID")
	assert_false(picker.has_plant_display_name_for_id("plant.unknown"), "Unknown plant has no display name for ID")
	assert_true(picker.has_plant_traits_summary_for_id("plant.jasmine"), "Jasmine has non-empty traits summary for ID")
	assert_false(picker.has_plant_traits_summary_for_id("plant.unknown"), "Unknown plant has no traits summary for ID")
	assert_true(picker.has_plant_positive_harvest_reward_for_id("plant.jasmine"), "Jasmine has positive harvest reward for ID")
	assert_false(picker.has_plant_positive_harvest_reward_for_id("plant.unknown"), "Unknown plant has no positive harvest reward for ID")
	assert_true(picker.has_plant_positive_mature_duration_for_id("plant.jasmine"), "Jasmine has positive mature duration for ID")
	assert_false(picker.has_plant_positive_mature_duration_for_id("plant.unknown"), "Unknown plant has no positive mature duration for ID")
	assert_true(picker.has_plant_positive_sprout_duration_for_id("plant.jasmine"), "Jasmine has positive sprout duration for ID")
	assert_false(picker.has_plant_positive_sprout_duration_for_id("plant.unknown"), "Unknown plant has no positive sprout duration for ID")
	assert_true(picker.has_plant_positive_growing_duration_for_id("plant.jasmine"), "Jasmine has positive growing duration for ID")
	assert_false(picker.has_plant_positive_growing_duration_for_id("plant.unknown"), "Unknown plant has no positive growing duration for ID")
	assert_false(picker.is_plant_undiscovered("plant.jasmine"), "Discovered jasmine is not undiscovered")
	assert_true(picker.is_plant_undiscovered("plant.banana"), "Undiscovered banana is_plant_undiscovered() is true")
	assert_false(picker.is_plant_undiscovered("plant.unknown"), "Unknown plant is_plant_undiscovered() is false")
	assert_false(picker.is_plant_unplanted("plant.jasmine"), "Planted jasmine is not unplanted")
	assert_true(picker.is_plant_unplanted("plant.banana"), "Unplanted banana is_plant_unplanted() is true")
	assert_false(picker.is_plant_unplanted("plant.unknown"), "Unknown plant is_plant_unplanted() is false")
	assert_eq(
		picker.get_unplanted_plant_ids(),
		["plant.banana", "plant.chili", "plant.holy_basil", "plant.marigold"],
		"Unplanted plant IDs query returns remaining 4 plants in catalog order"
	)
	assert_true(picker.is_plant_currently_planted("plant.jasmine"), "Jasmine is currently planted")
	assert_false(picker.is_plant_currently_planted("plant.banana"), "Banana is not currently planted")
	assert_true(
		picker.get_confirm_prompt_text().contains("โตเต็มที่ 3600 วินาที | รางวัล +25 เหรียญ"),
		"Confirmation prompt includes mature duration and harvest reward"
	)
	assert_true(
		picker.get_confirm_prompt_text().contains("คุณสมบัติ: พุ่มไม้หนาแน่น, ดอกไม้"),
		"Confirmation prompt includes environmental traits summary"
	)
	assert_true(
		picker.get_confirm_prompt_text().contains("ปลูกแล้ว 2 ต้น"),
		"Confirmation prompt includes live planted count from snapshot"
	)
	assert_true(
		picker.get_confirm_prompt_text().contains("[ค้นพบแล้ว]"),
		"Confirmation prompt includes [ค้นพบแล้ว] badge for discovered plant"
	)

	picker.select_plant_definition("plant.banana")
	assert_false(picker.is_pending_plant_discovered(), "Pending banana is not discovered")
	assert_true(picker.is_pending_plant_undiscovered(), "Pending banana is undiscovered")
	assert_false(picker.is_pending_plant_currently_planted(), "Pending banana is not currently planted")
	assert_true(picker.is_pending_plant_unplanted(), "Pending banana is unplanted")
	assert_eq(picker.get_pending_plant_planted_count(), 0, "Pending banana planted count is 0")
	assert_eq(
		picker.get_pending_plant_harvest_reward(),
		picker.get_harvest_reward_for_id("plant.banana"),
		"Pending banana harvest reward matches catalog"
	)
	assert_eq(
		picker.get_pending_plant_mature_after_seconds(),
		picker.get_mature_after_seconds_for_id("plant.banana"),
		"Pending banana mature duration matches catalog"
	)
	assert_true(
		picker.get_confirm_prompt_text().contains("ปลูกแล้ว 0 ต้น"),
		"Confirmation prompt includes 0 planted count for unplanted banana"
	)
	assert_true(
		picker.get_confirm_prompt_text().contains("[พันธุ์ใหม่]"),
		"Confirmation prompt includes [พันธุ์ใหม่] badge for undiscovered banana"
	)
	picker.cancel_confirmation()
	assert_false(picker.has_pending_selection(), "No pending selection after cancel_confirmation")
	assert_false(picker.is_pending_plant_discovered(), "is_pending_plant_discovered() is false when none pending")
	assert_false(picker.is_pending_plant_currently_planted(), "is_pending_plant_currently_planted() is false when none pending")
	assert_eq(picker.get_pending_plant_planted_count(), 0, "get_pending_plant_planted_count() is 0 when none pending")
	assert_eq(picker.get_pending_plant_harvest_reward(), 0, "get_pending_plant_harvest_reward() is 0 when none pending")
	assert_eq(picker.get_pending_plant_display_name(), "", "get_pending_plant_display_name() is empty when none pending")
	assert_eq(picker.get_pending_plant_traits(), [], "get_pending_plant_traits() is empty when none pending")
	assert_eq(picker.get_pending_plant_trait_count(), 0, "get_pending_plant_trait_count() is 0 when none pending")
	assert_false(picker.has_pending_plant_any_traits(), "has_pending_plant_any_traits() is false when none pending")
	assert_eq(picker.get_pending_plant_sprout_after_seconds(), 0, "get_pending_plant_sprout_after_seconds() is 0 when none pending")
	assert_eq(picker.get_pending_plant_growing_after_seconds(), 0, "get_pending_plant_growing_after_seconds() is 0 when none pending")
	assert_eq(picker.get_pending_plant_mature_after_seconds(), 0, "get_pending_plant_mature_after_seconds() is 0 when none pending")
	assert_false(picker.has_pending_plant_trait("flower"), "has_pending_plant_trait() is false when none pending")
	assert_eq(picker.get_pending_plant_option_text(), "", "get_pending_plant_option_text() is empty when none pending")
	assert_eq(picker.get_pending_plant_traits_summary(), "", "get_pending_plant_traits_summary() is empty when none pending")
	assert_eq(picker.get_pending_plant_trait_display_names(), [], "get_pending_plant_trait_display_names() is empty when none pending")
	assert_false(picker.is_pending_plant_known_definition(), "is_pending_plant_known_definition() is false when none pending")
	assert_false(picker.is_pending_plant_in_catalog(), "is_pending_plant_in_catalog() is false when none pending")
	assert_false(picker.has_pending_plant_harvest_reward(), "has_pending_plant_harvest_reward() is false when none pending")
	assert_false(picker.has_pending_plant_mature_duration(), "has_pending_plant_mature_duration() is false when none pending")
	assert_false(picker.is_pending_plant_undiscovered(), "is_pending_plant_undiscovered() is false when none pending")
	assert_false(picker.is_pending_plant_unplanted(), "is_pending_plant_unplanted() is false when none pending")
	assert_false(picker.has_pending_plant_sprout_duration(), "has_pending_plant_sprout_duration() is false when none pending")
	assert_false(picker.has_pending_plant_growing_duration(), "has_pending_plant_growing_duration() is false when none pending")
	assert_false(picker.has_pending_plant_traits_summary(), "has_pending_plant_traits_summary() is false when none pending")
	assert_false(picker.has_pending_plant_option_text(), "has_pending_plant_option_text() is false when none pending")
	assert_false(picker.has_pending_plant_display_name(), "has_pending_plant_display_name() is false when none pending")
	picker.free()


func _test_t_target_placement_note_and_full_garden() -> void:
	describe("T. PlantingPicker surfaces targeted cell note, confirmation suffix, locale updates, and full-garden warning")
	var picker: PlantingPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	assert_false(picker.has_target_placement(), "No target placement initially")
	assert_true(picker.has_free_placement_slot(), "Has free placement slot initially")
	assert_eq(
		picker.get_note_text(),
		GardenLocalization.translate("ui.planting_picker.note", "th"),
		"Default note shown when no target cell is selected"
	)

	picker.update_garden_context(null, null, GardenZone.ZONE_ADJACENT_1, 2, 1, true)
	assert_true(picker.has_target_placement(), "Target placement recorded after context update")
	assert_eq(
		picker.get_target_placement(),
		{"zone_id": GardenZone.ZONE_ADJACENT_1, "grid_x": 2, "grid_y": 1},
		"get_target_placement returns targeted zone and grid coords"
	)
	assert_true(
		picker.get_note_text().contains("มุมสวนข้างบ้าน") and picker.get_note_text().contains("(2, 1)"),
		"Targeted Thai note displays zone name and coordinates"
	)

	picker.select_plant_definition("plant.jasmine")
	assert_true(
		picker.get_confirm_prompt_text().contains("มุมสวนข้างบ้าน") and picker.get_confirm_prompt_text().contains("(2, 1)"),
		"Confirmation prompt includes target zone and coordinates"
	)

	picker.set_locale("en")
	assert_true(
		picker.get_note_text().contains("Adjacent Zone") and picker.get_note_text().contains("(2, 1)"),
		"Targeted note translates live to English"
	)
	assert_true(
		picker.get_confirm_prompt_text().contains("Adjacent Zone") and picker.get_confirm_prompt_text().contains("(2, 1)"),
		"Pending confirmation prompt translates live to English with target cell"
	)

	picker.cancel_confirmation()
	picker.update_garden_context(null, null, "", -1, -1, false)
	assert_false(picker.has_target_placement(), "Target cleared when context clears target cell")
	assert_false(picker.has_free_placement_slot(), "has_free_placement_slot reflects full unlocked zones")
	assert_eq(
		picker.get_note_text(),
		GardenLocalization.translate("ui.planting_picker.note_full", "en"),
		"Full-garden note displays clearly when no empty cells remain"
	)

	picker.bind_catalog(catalog)
	assert_false(picker.has_target_placement(), "Rebinding catalog resets target placement")
	assert_true(picker.has_free_placement_slot(), "Rebinding catalog resets free slot assumption")
	picker.free()
