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
	_test_shop_context_placed_counts_and_affordability()
	_test_target_placement_note_and_full_garden()


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


func _test_shop_context_placed_counts_and_affordability() -> void:
	describe("DecorationPicker displays placed counts and affordability from update_shop_context without owning purchase rules")
	var picker: DecorationPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	assert_eq(picker.get_available_currency(), -1, "No currency context initially (-1)")
	assert_eq(picker.get_placed_count_for_id("decoration.clay_jar"), 0, "Placed count is 0 initially")
	assert_true(picker.can_afford_decoration("decoration.small_pond"), "Default can_afford is true without currency context")

	var snapshot: GardenSnapshot = GardenSnapshot.new(
		{"water": 1},
		{},
		0,
		0,
		{"decoration.clay_jar": 1},
		1
	)
	picker.update_shop_context(20, snapshot)

	assert_eq(picker.get_available_currency(), 20, "Available currency is 20")
	assert_eq(picker.get_placed_count_for_id("decoration.clay_jar"), 1, "Clay jar placed count is 1")
	assert_true(picker.can_afford_decoration("decoration.clay_jar"), "Clay jar (15 coins) is affordable with 20 coins")
	assert_false(picker.can_afford_decoration("decoration.small_pond"), "Small pond (50 coins) is not affordable with 20 coins")

	var jar_text: String = picker.get_decoration_option_text_for_id("decoration.clay_jar")
	var pond_text: String = picker.get_decoration_option_text_for_id("decoration.small_pond")
	assert_true(jar_text.contains("วางแล้ว 1 ชิ้น"), "Clay jar option shows 1 placed")
	assert_true(jar_text.contains("[จัดวางแล้ว]"), "Clay jar option shows [จัดวางแล้ว] badge")
	assert_false(jar_text.contains("[เหรียญไม่พอ]"), "Clay jar option does not show insufficient coins")
	assert_true(pond_text.contains("วางแล้ว 0 ชิ้น"), "Small pond option shows 0 placed")
	assert_true(pond_text.contains("[ของตกแต่งใหม่]"), "Small pond option shows [ของตกแต่งใหม่] badge")
	assert_true(pond_text.contains("[เหรียญไม่พอ]"), "Small pond option shows insufficient coins indicator")
	assert_true(picker.is_decoration_placed("decoration.clay_jar"), "Clay jar is marked placed")
	assert_false(picker.is_decoration_placed("decoration.small_pond"), "Small pond is not marked placed")
	assert_eq(picker.get_placed_decoration_ids(), ["decoration.clay_jar"], "Placed decoration IDs query returns [decoration.clay_jar]")
	assert_eq(picker.get_unplaced_decoration_ids().size(), 7, "7 unplaced decorations remaining")
	assert_false(picker.get_unplaced_decoration_ids().has("decoration.clay_jar"), "Unplaced IDs exclude clay_jar")
	assert_eq(
		picker.get_affordable_decoration_ids(),
		[
			"decoration.clay_jar",
			"decoration.plant_pot",
			"decoration.small_table",
			"decoration.watering_can",
			"decoration.wooden_fence",
		],
		"Affordable decorations at 20 coins exclude bench (25), garden_lamp (30), and small_pond (50)"
	)

	picker.select_decoration_definition("decoration.clay_jar")
	assert_eq(picker.get_price_for_id("decoration.clay_jar"), 15, "Clay jar price query returns 15")
	assert_eq(picker.get_price_for_id("decoration.small_pond"), 50, "Small pond price query returns 50")
	assert_eq(picker.get_price_for_id("decoration.unknown"), -1, "Unknown decoration price query returns -1")
	assert_eq(picker.get_placed_decoration_species_count(), 1, "1 distinct decoration species placed")
	assert_eq(picker.get_unplaced_decoration_species_count(), 7, "7 distinct decoration species unplaced")
	assert_eq(picker.get_total_placed_decoration_count(), 1, "1 total placed decoration instance")
	assert_eq(picker.get_affordable_decoration_count(), 5, "5 affordable decorations at 20 coins")
	assert_eq(picker.get_unaffordable_decoration_count(), 3, "3 unaffordable decorations at 20 coins")
	assert_eq(picker.get_coins_needed_for_id("decoration.clay_jar"), 0, "0 additional coins needed for affordable clay_jar")
	assert_eq(picker.get_coins_needed_for_id("decoration.small_pond"), 30, "30 additional coins needed for 50-coin small_pond at 20 coins")
	assert_eq(picker.get_coins_needed_for_id("decoration.unknown"), -1, "Unknown decoration coins needed returns -1")
	assert_true(picker.has_decoration_trait("decoration.clay_jar", "water"), "Clay jar has water trait")
	assert_false(picker.has_decoration_trait("decoration.clay_jar", "shade"), "Clay jar does not have shade trait")
	assert_false(picker.has_decoration_trait("decoration.unknown", "water"), "Unknown decoration does not have water trait")
	assert_eq(
		picker.get_decoration_ids_with_trait("water"),
		["decoration.clay_jar", "decoration.small_pond"],
		"Decorations with water trait returned in catalog order"
	)
	assert_eq(
		picker.get_decoration_count_with_trait("water"),
		2,
		"2 decorations with water trait in catalog"
	)
	assert_eq(
		picker.get_decoration_ids_with_trait("non_existent_trait"),
		[],
		"Decorations with unknown trait returns empty array"
	)
	assert_eq(
		picker.get_decoration_count_with_trait("non_existent_trait"),
		0,
		"0 decorations with unknown trait"
	)
	assert_eq(picker.get_total_catalog_decoration_count(), 8, "Total catalog decoration count is 8")
	assert_false(picker.is_all_decoration_species_placed(), "Not all decoration species placed (1/8)")
	assert_false(picker.is_all_decorations_affordable(), "Not all decorations affordable at 20 coins (5/8)")
	assert_eq(picker.get_decoration_display_name_for_id("decoration.clay_jar"), "ตุ่มน้ำดินเผา", "Display name query for clay_jar returns ตุ่มน้ำดินเผา")
	assert_eq(picker.get_decoration_display_name_for_id("decoration.unknown"), "", "Display name query for unknown decoration returns empty string")
	assert_eq(picker.get_decoration_trait_count_for_id("decoration.clay_jar"), 1, "Clay jar trait count is 1")
	assert_eq(picker.get_decoration_trait_count_for_id("decoration.watering_can"), 0, "Watering can trait count is 0")
	assert_true(picker.has_any_placed_decorations(), "Has placed decorations when clay_jar is placed")
	assert_true(picker.has_any_affordable_decorations(), "Has affordable decorations at 20 coins")
	assert_true(picker.has_currency_context(), "Has currency context after update_garden_context")
	assert_true(picker.has_decoration_in_catalog("decoration.clay_jar"), "Clay jar exists in bound catalog")
	assert_false(picker.has_decoration_in_catalog("decoration.unknown"), "Unknown decoration does not exist in bound catalog")
	assert_true(picker.has_any_unplaced_decorations(), "Has unplaced decorations when 7/8 are unplaced")
	assert_true(picker.has_any_unaffordable_decorations(), "Has unaffordable decorations at 20 coins (3/8)")
	assert_true(picker.has_bound_catalog(), "Catalog is bound to picker")
	assert_true(picker.has_bound_snapshot(), "Snapshot is bound to picker")
	assert_true(picker.has_pending_selection(), "Pending selection is active after select_decoration_definition")
	assert_true(picker.is_pending_decoration_placed(), "Pending clay_jar is placed")
	assert_true(picker.can_afford_pending_decoration(), "Pending clay_jar is affordable at 20 coins")
	assert_eq(picker.get_pending_decoration_price(), 15, "Pending clay_jar price is 15")
	assert_eq(picker.get_pending_decoration_placed_count(), 1, "Pending clay_jar placed count is 1")
	assert_eq(picker.get_pending_decoration_coins_needed(), 0, "Pending clay_jar coins needed is 0")
	assert_eq(picker.get_pending_decoration_display_name(), "ตุ่มน้ำดินเผา", "Pending clay_jar display name is ตุ่มน้ำดินเผา")
	assert_eq(picker.get_pending_decoration_traits(), ["water"], "Pending clay_jar traits match catalog")
	assert_eq(picker.get_pending_decoration_trait_count(), 1, "Pending clay_jar trait count is 1")
	assert_true(picker.has_pending_decoration_any_traits(), "Pending clay_jar has_pending_decoration_any_traits() is true")
	assert_true(picker.has_pending_decoration_trait("water"), "Pending clay_jar has water trait")
	assert_false(picker.has_pending_decoration_trait("light"), "Pending clay_jar does not have light trait")
	assert_eq(
		picker.get_pending_decoration_option_text(),
		picker.get_decoration_option_text_for_id("decoration.clay_jar"),
		"Pending clay_jar option text matches option text for ID"
	)
	assert_eq(picker.get_decoration_button_count(), 8, "Picker renders 8 decoration option buttons")
	assert_true(picker.has_confirm_prompt_text(), "Confirmation prompt has non-empty text")
	assert_eq(
		picker.get_decoration_traits_summary_for_id("decoration.clay_jar"),
		"แหล่งน้ำ",
		"Traits summary for clay_jar returns แหล่งน้ำ"
	)
	assert_eq(
		picker.get_decoration_traits_summary_for_id("decoration.watering_can"),
		"ตกแต่งสวยงาม",
		"Traits summary for traitless watering_can returns ตกแต่งสวยงาม"
	)
	assert_eq(picker.get_decoration_traits_summary_for_id("decoration.unknown"), "", "Traits summary for unknown decoration returns empty string")
	assert_eq(
		picker.get_pending_decoration_traits_summary(),
		"แหล่งน้ำ",
		"Pending clay_jar traits summary returns แหล่งน้ำ"
	)
	assert_true(picker.is_known_decoration_definition("decoration.clay_jar"), "clay_jar is a known decoration definition")
	assert_false(picker.is_known_decoration_definition("decoration.unknown"), "unknown is not a known decoration definition")
	assert_true(picker.is_known_environmental_trait("water"), "water is a known environmental trait")
	assert_false(picker.is_known_environmental_trait("unknown_trait"), "unknown_trait is not a known environmental trait")
	assert_eq(picker.get_trait_display_name_for_id("water"), "แหล่งน้ำ", "Trait display name for water is แหล่งน้ำ")
	assert_eq(picker.get_trait_display_name_for_id(""), "", "Trait display name for empty string is empty")
	assert_eq(
		picker.get_decoration_trait_display_names_for_id("decoration.clay_jar"),
		["แหล่งน้ำ"],
		"Decoration trait display names for clay_jar return [แหล่งน้ำ]"
	)
	assert_eq(
		picker.get_decoration_trait_display_names_for_id("decoration.watering_can"),
		[],
		"Decoration trait display names for traitless watering_can return []"
	)
	assert_eq(
		picker.get_pending_decoration_trait_display_names(),
		["แหล่งน้ำ"],
		"Pending clay_jar trait display names return [แหล่งน้ำ]"
	)
	assert_true(picker.has_decoration_any_traits("decoration.clay_jar"), "has_decoration_any_traits(decoration.clay_jar) is true")
	assert_false(picker.has_decoration_any_traits("decoration.watering_can"), "has_decoration_any_traits(decoration.watering_can) is false")
	assert_eq(picker.get_available_decoration_display_names().size(), 8, "8 available decoration display names")
	assert_eq(
		picker.get_placed_decoration_display_names(),
		["ตุ่มน้ำดินเผา"],
		"Placed decoration display names return [ตุ่มน้ำดินเผา]"
	)
	assert_eq(picker.get_unplaced_decoration_display_names().size(), 7, "7 unplaced decoration display names")
	assert_eq(picker.get_affordable_decoration_display_names().size(), 5, "5 affordable decoration display names at 20 coins")
	assert_eq(
		picker.get_unaffordable_decoration_display_names(),
		["ม้านั่งไม้ในสวน", "โคมไฟในสวน", "บ่อน้ำเล็ก"],
		"Unaffordable decoration display names at 20 coins"
	)
	assert_true(picker.is_pending_decoration_known_definition(), "Pending clay_jar is a known decoration definition")
	assert_eq(
		picker.get_decoration_display_names_with_trait("water"),
		["ตุ่มน้ำดินเผา", "บ่อน้ำเล็ก"],
		"Decoration display names with water trait in catalog order"
	)
	assert_eq(
		picker.get_decoration_display_names_with_trait("non_existent_trait"),
		[],
		"Decoration display names with unknown trait returns empty array"
	)
	assert_true(picker.has_any_decorations_with_trait("water"), "has_any_decorations_with_trait(water) is true")
	assert_false(picker.has_any_decorations_with_trait("non_existent_trait"), "has_any_decorations_with_trait(non_existent_trait) is false")
	assert_true(picker.is_pending_decoration_in_catalog(), "Pending clay_jar is in catalog")
	assert_true(picker.has_pending_decoration_positive_price(), "Pending clay_jar has positive price")
	assert_false(picker.is_pending_decoration_unaffordable(), "Pending clay_jar is not unaffordable at 20 coins")
	assert_false(picker.is_pending_decoration_unplaced(), "Pending clay_jar is not unplaced")
	assert_false(picker.has_pending_decoration_coins_needed(), "Pending clay_jar needs no additional coins")
	assert_true(picker.has_pending_decoration_traits_summary(), "Pending clay_jar has non-empty traits summary")
	assert_true(picker.has_pending_decoration_option_text(), "Pending clay_jar has non-empty option text")
	assert_true(picker.has_pending_decoration_display_name(), "Pending clay_jar has non-empty display name")
	assert_true(picker.has_decoration_option_text_for_id("decoration.clay_jar"), "Clay jar has non-empty option text for ID")
	assert_false(picker.has_decoration_option_text_for_id("decoration.unknown"), "Unknown decoration has no option text for ID")
	assert_true(picker.has_decoration_display_name_for_id("decoration.clay_jar"), "Clay jar has non-empty display name for ID")
	assert_false(picker.has_decoration_display_name_for_id("decoration.unknown"), "Unknown decoration has no display name for ID")
	assert_true(picker.has_decoration_traits_summary_for_id("decoration.clay_jar"), "Clay jar has non-empty traits summary for ID")
	assert_false(picker.has_decoration_traits_summary_for_id("decoration.unknown"), "Unknown decoration has no traits summary for ID")
	assert_true(picker.has_decoration_positive_price_for_id("decoration.clay_jar"), "Clay jar has positive price for ID")
	assert_false(picker.has_decoration_positive_price_for_id("decoration.unknown"), "Unknown decoration has no positive price for ID")
	assert_false(picker.has_decoration_coins_needed_for_id("decoration.clay_jar"), "Clay jar needs no additional coins at 20 coins")
	assert_true(picker.has_decoration_coins_needed_for_id("decoration.small_pond"), "Small pond needs additional coins at 20 coins")
	assert_false(picker.has_decoration_coins_needed_for_id("decoration.unknown"), "Unknown decoration needs no additional coins")
	assert_false(picker.is_decoration_unplaced("decoration.clay_jar"), "Placed clay_jar is not unplaced")
	assert_true(picker.is_decoration_unplaced("decoration.small_pond"), "Unplaced small_pond is_decoration_unplaced() is true")
	assert_false(picker.is_decoration_unplaced("decoration.unknown"), "Unknown decoration is_decoration_unplaced() is false")
	assert_false(picker.is_decoration_unaffordable("decoration.clay_jar"), "Affordable clay_jar is not unaffordable")
	assert_true(picker.is_decoration_unaffordable("decoration.small_pond"), "Unaffordable small_pond is_decoration_unaffordable() is true")
	assert_false(picker.is_decoration_unaffordable("decoration.unknown"), "Unknown decoration is_decoration_unaffordable() is false")
	assert_true(picker.has_available_decorations(), "Picker has available decorations in bound catalog")
	assert_true(picker.has_rendered_decoration_buttons(), "Picker has rendered decoration option buttons")
	assert_true(picker.has_positive_available_currency(), "Picker has positive available currency at 20 coins")
	assert_eq(
		picker.get_unaffordable_decoration_ids(),
		[
			"decoration.bench",
			"decoration.garden_lamp",
			"decoration.small_pond",
		],
		"Unaffordable decorations at 20 coins return bench, garden_lamp, and small_pond"
	)
	assert_eq(picker.get_decoration_traits_for_id("decoration.clay_jar"), ["water"], "Clay jar traits query returns [water]")
	assert_eq(picker.get_decoration_traits_for_id("decoration.watering_can"), [], "Watering can traits query returns []")
	assert_true(
		picker.get_confirm_prompt_text().contains("เหรียญที่มี: 20 เหรียญ"),
		"Confirmation prompt includes available currency balance"
	)
	assert_true(
		picker.get_confirm_prompt_text().contains("คุณสมบัติ: แหล่งน้ำ"),
		"Confirmation prompt includes environmental trait summary"
	)
	assert_true(
		picker.get_confirm_prompt_text().contains("วางแล้ว 1 ชิ้น"),
		"Confirmation prompt includes placed count from snapshot"
	)
	assert_true(
		picker.get_confirm_prompt_text().contains("[จัดวางแล้ว]"),
		"Confirmation prompt includes [จัดวางแล้ว] badge for placed decoration"
	)
	assert_false(
		picker.get_confirm_prompt_text().contains("[เหรียญไม่พอ]"),
		"Affordable decoration confirmation prompt does not show [เหรียญไม่พอ]"
	)

	picker.select_decoration_definition("decoration.small_pond")
	assert_false(picker.is_pending_decoration_placed(), "Pending small_pond is not placed")
	assert_true(picker.is_pending_decoration_unplaced(), "Pending small_pond is unplaced")
	assert_false(picker.can_afford_pending_decoration(), "Pending small_pond is not affordable at 20 coins")
	assert_true(picker.is_pending_decoration_unaffordable(), "Pending small_pond is unaffordable at 20 coins")
	assert_true(picker.has_pending_decoration_coins_needed(), "Pending small_pond requires additional coins")
	assert_eq(picker.get_pending_decoration_price(), 50, "Pending small_pond price is 50")
	assert_eq(picker.get_pending_decoration_placed_count(), 0, "Pending small_pond placed count is 0")
	assert_eq(picker.get_pending_decoration_coins_needed(), 30, "Pending small_pond needs 30 additional coins")
	assert_true(
		picker.get_confirm_prompt_text().contains("วางแล้ว 0 ชิ้น"),
		"Confirmation prompt includes 0 placed count for unplaced small pond"
	)
	assert_true(
		picker.get_confirm_prompt_text().contains("[ของตกแต่งใหม่]"),
		"Confirmation prompt includes [ของตกแต่งใหม่] badge for unplaced decoration"
	)
	assert_true(
		picker.get_confirm_prompt_text().contains("[เหรียญไม่พอ]"),
		"Unaffordable decoration confirmation prompt includes [เหรียญไม่พอ]"
	)
	picker.cancel_confirmation()
	assert_false(picker.has_pending_selection(), "No pending selection after cancel_confirmation")
	assert_false(picker.is_pending_decoration_placed(), "is_pending_decoration_placed() is false when none pending")
	assert_false(picker.can_afford_pending_decoration(), "can_afford_pending_decoration() is false when none pending")
	assert_eq(picker.get_pending_decoration_price(), -1, "get_pending_decoration_price() is -1 when none pending")
	assert_eq(picker.get_pending_decoration_placed_count(), 0, "get_pending_decoration_placed_count() is 0 when none pending")
	assert_eq(picker.get_pending_decoration_coins_needed(), -1, "get_pending_decoration_coins_needed() is -1 when none pending")
	assert_eq(picker.get_pending_decoration_traits_summary(), "", "get_pending_decoration_traits_summary() is empty when none pending")
	assert_eq(picker.get_pending_decoration_trait_display_names(), [], "get_pending_decoration_trait_display_names() is empty when none pending")
	assert_false(picker.is_pending_decoration_known_definition(), "is_pending_decoration_known_definition() is false when none pending")
	assert_false(picker.is_pending_decoration_in_catalog(), "is_pending_decoration_in_catalog() is false when none pending")
	assert_false(picker.has_pending_decoration_positive_price(), "has_pending_decoration_positive_price() is false when none pending")
	assert_false(picker.is_pending_decoration_unaffordable(), "is_pending_decoration_unaffordable() is false when none pending")
	assert_false(picker.is_pending_decoration_unplaced(), "is_pending_decoration_unplaced() is false when none pending")
	assert_false(picker.has_pending_decoration_coins_needed(), "has_pending_decoration_coins_needed() is false when none pending")
	assert_false(picker.has_pending_decoration_traits_summary(), "has_pending_decoration_traits_summary() is false when none pending")
	assert_false(picker.has_pending_decoration_option_text(), "has_pending_decoration_option_text() is false when none pending")
	assert_false(picker.has_pending_decoration_display_name(), "has_pending_decoration_display_name() is false when none pending")
	picker.free()


func _test_target_placement_note_and_full_garden() -> void:
	describe("DecorationPicker surfaces targeted cell note, confirmation suffix, locale updates, and full-garden warning")
	var picker: DecorationPicker = _instantiate_picker()
	var catalog: ContentCatalog = _create_production_catalog()
	picker.bind_catalog(catalog)

	assert_false(picker.has_target_placement(), "No target placement initially")
	assert_true(picker.has_free_placement_slot(), "Has free placement slot initially")
	assert_eq(
		picker.get_note_text(),
		GardenLocalization.translate("ui.decoration_picker.note", "th"),
		"Default note shown when no target cell is selected"
	)

	picker.update_shop_context(80, null, GardenZone.ZONE_ADJACENT_1, 1, 2, true)
	assert_true(picker.has_target_placement(), "Target placement recorded after shop context update")
	assert_eq(
		picker.get_target_placement(),
		{"zone_id": GardenZone.ZONE_ADJACENT_1, "grid_x": 1, "grid_y": 2},
		"get_target_placement returns targeted zone and grid coords"
	)
	assert_true(
		picker.get_note_text().contains("มุมสวนข้างบ้าน") and picker.get_note_text().contains("(1, 2)"),
		"Targeted Thai note displays zone name and coordinates"
	)

	picker.select_decoration_definition("decoration.clay_jar")
	assert_true(
		picker.get_confirm_prompt_text().contains("มุมสวนข้างบ้าน") and picker.get_confirm_prompt_text().contains("(1, 2)"),
		"Confirmation prompt includes target zone and coordinates"
	)

	picker.set_locale("en")
	assert_true(
		picker.get_note_text().contains("Adjacent Zone") and picker.get_note_text().contains("(1, 2)"),
		"Targeted note translates live to English"
	)
	assert_true(
		picker.get_confirm_prompt_text().contains("Adjacent Zone") and picker.get_confirm_prompt_text().contains("(1, 2)"),
		"Pending confirmation prompt translates live to English with target cell"
	)

	picker.cancel_confirmation()
	picker.update_shop_context(80, null, "", -1, -1, false)
	assert_false(picker.has_target_placement(), "Target cleared when shop context clears target cell")
	assert_false(picker.has_free_placement_slot(), "has_free_placement_slot reflects full unlocked zones")
	assert_eq(
		picker.get_note_text(),
		GardenLocalization.translate("ui.decoration_picker.note_full", "en"),
		"Full-garden note displays clearly when no empty cells remain"
	)

	picker.bind_catalog(catalog)
	assert_false(picker.has_target_placement(), "Rebinding catalog resets target placement")
	assert_true(picker.has_free_placement_slot(), "Rebinding catalog resets free slot assumption")
	picker.free()
