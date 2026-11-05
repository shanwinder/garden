## test_decoration_picker.gd
## Comprehensive test suite for DecorationPicker presentation component.
class_name TestDecorationPicker
extends TestSuiteBase

const PICKER_SCENE_PATH: String = "res://scenes/garden/decoration_picker.tscn"


class SignalTracker extends RefCounted:
	var emitted_count: int = 0
	var received_ids: Array[String] = []

	func on_purchase_requested(def_id: String) -> void:
		emitted_count += 1
		received_ids.append(def_id)


func _init() -> void:
	suite_name = "TestDecorationPicker"


func run_tests() -> void:
	_test_scene_loads_and_contracts()
	_test_eight_production_decorations_and_order()
	_test_empty_or_null_catalog_safety()
	_test_confirmation_cancel_and_single_submit()


func _create_production_catalog() -> ContentCatalog:
	var p_res: PlantContentLoadResult = PlantContentLoader.new().load_production_definitions()
	var v_res: VisitorContentLoadResult = VisitorContentLoader.new().load_production_definitions()
	var d_res: DecorationContentLoadResult = DecorationContentLoader.new().load_production_definitions()
	return ContentCatalog.try_create(
		p_res.get_definitions(),
		v_res.get_definitions(),
		d_res.get_definitions()
	)


func _instantiate_picker() -> DecorationPicker:
	var scene: PackedScene = load(PICKER_SCENE_PATH) as PackedScene
	return scene.instantiate() as DecorationPicker


func _test_scene_loads_and_contracts() -> void:
	describe("DecorationPicker PackedScene loads and satisfies Control and signal contracts")
	var picker: DecorationPicker = _instantiate_picker()
	assert_true(picker != null, "Picker must instantiate")
	assert_true(picker is DecorationPicker, "Must be DecorationPicker")
	assert_true(picker is Control, "Must extend Control")
	assert_true(picker.has_signal("decoration_purchase_requested"), "Has decoration_purchase_requested signal")
	assert_true(picker.has_signal("picker_closed"), "Has picker_closed signal")
	picker.free()


func _test_eight_production_decorations_and_order() -> void:
	describe("DecorationPicker displays all 8 production decorations in deterministic ascending ID order with Thai names, prices, and traits")
	var picker: DecorationPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()

	picker.bind_catalog(catalog)
	var ids: Array[String] = picker.get_available_decoration_ids()
	assert_eq(ids.size(), 8, "8 decorations available")
	assert_eq(ids, AppRoot.EXPECTED_PRODUCTION_DECORATION_IDS, "Deterministic ascending ID order")

	var buttons: Array[Button] = picker.get_decoration_buttons()
	assert_eq(buttons.size(), 8, "8 buttons rendered")
	assert_true(buttons[0].text.contains("ม้านั่งไม้ในสวน"), "Index 0 is bench")
	assert_true(buttons[0].text.contains("25 เหรียญ"), "Bench price is 25 coins")
	assert_true(buttons[1].text.contains("ตุ่มน้ำดินเผา"), "Index 1 is clay_jar")
	assert_true(buttons[1].text.contains("15 เหรียญ"), "Clay jar price is 15 coins")
	assert_true(buttons[1].text.contains("แหล่งน้ำ"), "Clay jar shows water trait")
	assert_true(buttons[4].text.contains("บ่อน้ำเล็ก"), "Index 4 is small_pond")
	assert_true(buttons[4].text.contains("50 เหรียญ"), "Small pond price is 50 coins")
	picker.free()


func _test_empty_or_null_catalog_safety() -> void:
	describe("DecorationPicker safely handles null or empty catalog without emitting purchase requests")
	var picker: DecorationPicker = _instantiate_picker()
	var tracker: SignalTracker = SignalTracker.new()
	picker.decoration_purchase_requested.connect(tracker.on_purchase_requested)

	picker.bind_catalog(null)
	assert_eq(picker.get_available_decoration_ids().size(), 0, "Null catalog yields 0 decoration IDs")
	picker.select_decoration_definition("decoration.clay_jar")
	assert_false(picker.is_confirmation_active(), "Cannot select decoration with null catalog")
	picker.confirm_purchase()
	assert_eq(tracker.emitted_count, 0, "Zero requests emitted with null catalog")
	picker.free()


func _test_confirmation_cancel_and_single_submit() -> void:
	describe("DecorationPicker requires explicit confirmation, emits nothing on cancel, and prevents duplicate submit")
	var picker: DecorationPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	var tracker: SignalTracker = SignalTracker.new()
	picker.decoration_purchase_requested.connect(tracker.on_purchase_requested)

	picker.bind_catalog(catalog)
	picker.open_picker()

	# Selection alone does not emit
	picker.select_decoration_definition("decoration.clay_jar")
	assert_true(picker.is_confirmation_active(), "Confirmation active")
	assert_true(picker.get_confirm_prompt_text().contains("15 เหรียญ"), "Confirmation prompt shows 15 coins")
	assert_eq(tracker.emitted_count, 0, "Selection alone emits no signal")

	# Cancel closes confirmation and emits nothing
	picker.cancel_confirmation()
	assert_false(picker.is_confirmation_active(), "Confirmation closed after cancel")
	assert_eq(tracker.emitted_count, 0, "Cancel emits no signal")

	# Select and confirm emits once; second confirm in same dialog state is ignored
	picker.select_decoration_definition("decoration.clay_jar")
	picker.confirm_purchase()
	picker.confirm_purchase()
	assert_eq(tracker.emitted_count, 1, "Emits exactly once")
	assert_eq(tracker.received_ids, ["decoration.clay_jar"], "Emits decoration.clay_jar")
	picker.free()
