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
