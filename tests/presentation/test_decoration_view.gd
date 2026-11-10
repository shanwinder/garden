## test_decoration_view.gd
## Comprehensive unit tests for DecorationView presentation component.
class_name TestDecorationView
extends TestSuiteBase

const DECORATION_VIEW_SCENE_PATH: String = "res://scenes/garden/decoration_view.tscn"


func _init() -> void:
	suite_name = "TestDecorationView"


func run_tests() -> void:
	_test_scene_loads_and_unbound_defaults()
	_test_bind_all_eight_production_decorations()
	_test_trait_accent_colors_and_cosmetic_fallback()
	_test_unknown_definition_and_negative_price_safety()
	_test_defensive_trait_copy_and_queries()
	_test_selection_highlight_and_touch_signal()


func _instantiate_view() -> DecorationView:
	var scene: PackedScene = load(DECORATION_VIEW_SCENE_PATH) as PackedScene
	return scene.instantiate() as DecorationView


func _test_scene_loads_and_unbound_defaults() -> void:
	describe("DecorationView PackedScene loads with safe unbound defaults")
	var scene: PackedScene = load(DECORATION_VIEW_SCENE_PATH) as PackedScene
	assert_true(scene != null, "DecorationView PackedScene must load")
	var view: DecorationView = scene.instantiate() as DecorationView
	assert_true(view != null, "Instantiated scene must be DecorationView")
	assert_false(view.is_bound(), "Unbound DecorationView is_bound() is false")
	assert_false(view.is_known_decoration_definition(), "Unbound known definition is false")
	assert_eq(view.get_runtime_instance_id(), "", "Empty runtime ID initially")
	assert_eq(view.get_definition_id(), "", "Empty definition ID initially")
	assert_eq(view.get_placed_at(), -1, "placed_at is -1 initially")
	assert_eq(view.get_price(), 0, "price is 0 initially")
	assert_eq(view.get_trait_accent_color(), DecorationView.ACCENT_UNBOUND, "Unbound accent color")
	assert_eq(view.get_role_badge_text(), "[ของตกแต่ง]", "Role badge default text")
	assert_eq(view.get_trait_summary_badge_text(), "—", "Unbound trait badge placeholder")
	assert_eq(view.get_name_label_text(), "—", "Unbound name placeholder")
	assert_eq(view.get_instance_id_label_text(), "ID: —", "Unbound ID placeholder")
	assert_false(view.is_selected(), "Unselected initially")
	assert_false(view.is_selection_highlight_visible(), "Highlight hidden initially")
	assert_true(view.is_touch_button_enabled(), "TouchButton enabled")

	var emitted_ids: Array[String] = []
	view.decoration_selected.connect(func(id: String) -> void: emitted_ids.append(id))
	view.get_touch_button().pressed.emit()
	assert_eq(emitted_ids.size(), 0, "Pressing unbound TouchButton does not emit decoration_selected")
	view.free()


func _test_bind_all_eight_production_decorations() -> void:
	describe("All 8 production decoration definitions bind expected Thai display names and traits")
	var catalog: ContentCatalog = ContentCatalog.try_create(
		PlantContentLoader.new().load_production_definitions().get_definitions(),
		VisitorContentLoader.new().load_production_definitions().get_definitions(),
		DecorationContentLoader.new().load_production_definitions().get_definitions(),
		EventContentLoader.new().load_production_definitions().get_definitions()
	)
	assert_true(catalog != null, "Production ContentCatalog created")

	var expected_names: Dictionary = {
		"decoration.bench": "ม้านั่งไม้ในสวน",
		"decoration.clay_jar": "ตุ่มน้ำดินเผา",
		"decoration.garden_lamp": "โคมไฟในสวน",
		"decoration.plant_pot": "กระถางดินเผา",
		"decoration.small_pond": "บ่อน้ำเล็ก",
		"decoration.small_table": "โต๊ะไม้เล็ก",
		"decoration.watering_can": "บัวรดน้ำสังกะสี",
		"decoration.wooden_fence": "รั้วไม้ระแนง",
	}

	var index: int = 0
	for def_id: String in catalog.get_all_decoration_ids():
		index += 1
		var def: DecorationDefinition = catalog.get_decoration(def_id)
		var view: DecorationView = _instantiate_view()
		var inst_id: String = "decor-inst-%02d" % index
		view.bind_decoration_data(inst_id, def_id, 1700000000 + index, def.price, def.environmental_traits)

		assert_true(view.is_bound(), "%s bound" % def_id)
		assert_true(view.is_known_decoration_definition(), "%s known definition" % def_id)
		assert_eq(view.get_runtime_instance_id(), inst_id, "Runtime ID matches")
		assert_eq(view.get_definition_id(), def_id, "Definition ID matches")
		assert_eq(view.get_display_name(), expected_names[def_id], "Thai display name matches for %s" % def_id)
		assert_eq(view.get_name_label_text(), expected_names[def_id], "Label text matches for %s" % def_id)
		assert_eq(view.get_placed_at(), 1700000000 + index, "placed_at matches")
		assert_eq(view.get_price(), def.price, "price matches")
		assert_true(
			view.get_instance_id_label_text().contains(inst_id),
			"Subtitle contains instance ID for %s" % def_id
		)
		assert_true(
			view.get_instance_id_label_text().contains("%d เหรียญ" % def.price),
			"Subtitle contains price for %s" % def_id
		)
		view.free()


func _test_trait_accent_colors_and_cosmetic_fallback() -> void:
	describe("Trait-aware accent colors and cosmetic label fallback")
	var v_water: DecorationView = _instantiate_view()
	v_water.bind_decoration_data("d-water", "decoration.small_pond", 100, 40, ["water"])
	assert_eq(v_water.get_trait_accent_color(), DecorationView.ACCENT_WATER, "Water uses ACCENT_WATER")
	assert_eq(v_water.get_trait_summary_badge_text(), "แหล่งน้ำ", "Water badge shows แหล่งน้ำ")
	v_water.free()

	var v_light: DecorationView = _instantiate_view()
	v_light.bind_decoration_data("d-light", "decoration.garden_lamp", 100, 25, ["light"])
	assert_eq(v_light.get_trait_accent_color(), DecorationView.ACCENT_LIGHT, "Light uses ACCENT_LIGHT")
	assert_eq(v_light.get_trait_summary_badge_text(), "แสงไฟ", "Light badge shows แสงไฟ")
	v_light.free()

	var v_nature: DecorationView = _instantiate_view()
	v_nature.bind_decoration_data("d-bench", "decoration.bench", 100, 30, ["shade", "shelter"])
	assert_eq(v_nature.get_trait_accent_color(), DecorationView.ACCENT_NATURE, "Shade/shelter uses ACCENT_NATURE")
	assert_eq(v_nature.get_trait_summary_badge_text(), "ร่มเงา, ที่หลบพัก", "Bench badge lists traits")
	v_nature.free()

	var v_cosmetic: DecorationView = _instantiate_view()
	v_cosmetic.bind_decoration_data("d-can", "decoration.watering_can", 100, 10, [])
	assert_eq(v_cosmetic.get_trait_accent_color(), DecorationView.ACCENT_COSMETIC, "Cosmetic uses ACCENT_COSMETIC")
	assert_eq(v_cosmetic.get_trait_summary_badge_text(), "ตกแต่งสวยงาม", "Cosmetic badge shows ตกแต่งสวยงาม")
	assert_false(v_cosmetic.has_any_environmental_traits(), "Cosmetic has no traits")
	v_cosmetic.free()


func _test_unknown_definition_and_negative_price_safety() -> void:
	describe("Unknown definition ID falls back safely and negative price clamps to 0")
	var view: DecorationView = _instantiate_view()
	view.bind_decoration_data("d-unk", "decoration.mystery_stone", 500, -25, ["unknown_trait"])
	assert_true(view.is_bound(), "Valid runtime ID + non-negative placed_at is bound")
	assert_false(view.is_known_decoration_definition(), "Unknown definition returns false")
	assert_eq(view.get_display_name(), "decoration.mystery_stone", "Falls back to definition ID")
	assert_eq(view.get_price(), 0, "Negative price clamped to 0")
	assert_eq(view.get_traits_summary_text(), "unknown_trait", "Unknown trait falls back to raw ID")
	assert_eq(view.get_instance_id_label_text(), "ID: d-unk", "Zero price omits coin suffix")
	view.free()


func _test_defensive_trait_copy_and_queries() -> void:
	describe("get_environmental_traits returns defensive copy and trait membership queries match")
	var view: DecorationView = _instantiate_view()
	var source_traits: Array[String] = ["perch", "shade"]
	view.bind_decoration_data("d-table", "decoration.small_table", 200, 20, source_traits)
	source_traits.append("water")
	assert_eq(view.get_environmental_traits(), ["perch", "shade"], "Mutating input array does not mutate view")

	var copy: Array[String] = view.get_environmental_traits()
	copy.clear()
	assert_eq(view.get_environmental_trait_count(), 2, "Mutating returned copy does not mutate view")
	assert_true(view.has_any_environmental_traits(), "has_any_environmental_traits is true")
	assert_true(view.has_environmental_trait("perch"), "has_environmental_trait('perch') is true")
	assert_true(view.has_environmental_trait("shade"), "has_environmental_trait('shade') is true")
	assert_false(view.has_environmental_trait("water"), "has_environmental_trait('water') is false")
	assert_false(view.has_environmental_trait(""), "has_environmental_trait('') is false")
	view.free()


func _test_selection_highlight_and_touch_signal() -> void:
	describe("Selection state toggles SelectionHighlight and TouchButton emits decoration_selected")
	var view: DecorationView = _instantiate_view()
	view.bind_decoration_data("decor-inst-42", "decoration.clay_jar", 1234, 15, ["water"])

	view.set_selected(true)
	assert_true(view.is_selected(), "is_selected is true")
	assert_true(view.is_selection_highlight_visible(), "SelectionHighlight visible when selected")

	view.set_selected(false)
	assert_false(view.is_selected(), "is_selected is false")
	assert_false(view.is_selection_highlight_visible(), "SelectionHighlight hidden when unselected")

	var emitted: Array[String] = []
	view.decoration_selected.connect(func(id: String) -> void: emitted.append(id))
	view.get_touch_button().pressed.emit()
	assert_eq(emitted, ["decor-inst-42"], "TouchButton emits decoration_selected with exact runtime ID")
	view.free()
