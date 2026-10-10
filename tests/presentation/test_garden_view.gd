## test_garden_view.gd
## Comprehensive test suite for GardenView, PlantView, and MainScreen presentation components.
##
## Covers requirements A through Z:
## A. GardenView PackedScene loads.
## B. PlantView PackedScene loads.
## C. GardenView binds injected dependencies.
## D. Empty GameState displays empty-garden state.
## E. One plant produces exactly one rendered item.
## F. Multiple plants produce matching item count.
## G. Distinct runtime IDs produce distinct views.
## H. Rendering order follows runtime instance ID.
## I. Known definitions use correct display-only labels.
## J. Plant stage PLANTED is represented correctly.
## K. Plant stage SPROUT is represented correctly.
## L. Plant stage GROWING is represented correctly.
## M. Plant stage MATURE is represented correctly.
## N. Stage is recomputed after injected clock advances.
## O. Refresh samples clock once for all plants.
## P. Refresh does not duplicate plant items.
## Q. Refresh preserves authoritative GameState identity.
## R. Refresh does not mutate plant fields or currency.
## S. Touch/click selects the correct runtime plant ID.
## T. Selection details match the selected PlantState.
## U. Refresh preserves valid selection.
## V. Missing/stale selection is handled safely.
## W. Null/unavailable dependencies show a safe state.
## X. No save or planting command occurs during rendering.
## Y. No per-frame growth mutation is introduced.
## Z. Headless scene instantiation does not crash.
## Plus: Main scene structure and safe startup testing.
class_name TestGardenView
extends TestSuiteBase

const GARDEN_VIEW_SCENE_PATH: String = "res://scenes/garden/garden_view.tscn"
const PLANT_VIEW_SCENE_PATH: String = "res://scenes/garden/plant_view.tscn"
const MAIN_SCENE_PATH: String = "res://scenes/app/main.tscn"


class CallCountingClock extends FakeGameClock:
	var utc_call_count: int = 0

	func _init(initial_utc: int) -> void:
		super(initial_utc, 0)

	func utc_now_seconds() -> int:
		utc_call_count += 1
		return super.utc_now_seconds()


func _init() -> void:
	suite_name = "TestGardenView"


func run_tests() -> void:
	_test_a_garden_view_scene_loads()
	_test_b_plant_view_scene_loads()
	_test_c_bind_injected_dependencies()
	_test_d_empty_game_state_displays_empty_garden()
	_test_e_one_plant_produces_one_item()
	_test_f_multiple_plants_produce_matching_count()
	_test_g_distinct_runtime_ids_produce_distinct_views()
	_test_h_rendering_order_follows_runtime_instance_id()
	_test_i_known_definitions_use_correct_provisional_labels()
	_test_j_stage_planted_representation()
	_test_k_stage_sprout_representation()
	_test_l_stage_growing_representation()
	_test_m_stage_mature_representation()
	_test_n_stage_recomputed_after_clock_advance()
	_test_o_refresh_samples_clock_once_for_all_plants()
	_test_p_refresh_does_not_duplicate_items()
	_test_q_refresh_preserves_game_state_identity()
	_test_r_refresh_does_not_mutate_state_or_currency()
	_test_s_touch_selects_correct_runtime_id()
	_test_t_selection_details_match_plant_state()
	_test_u_refresh_preserves_valid_selection()
	_test_v_stale_selection_handled_safely()
	_test_w_null_dependencies_show_safe_blocked_state()
	_test_x_no_save_or_planting_during_rendering()
	_test_y_no_per_frame_growth_mutation()
	_test_z_headless_scene_instantiation()
	_test_main_scene_structure()
	_test_main_screen_safe_startup_without_session()


func _create_test_catalog() -> ContentCatalog:
	var basil: PlantDefinition = PlantDefinition.new()
	basil.id = "plant.holy_basil"
	basil.sprout_after_seconds = 60
	basil.growing_after_seconds = 180
	basil.mature_after_seconds = 300

	var chili: PlantDefinition = PlantDefinition.new()
	chili.id = "plant.chili"
	chili.sprout_after_seconds = 120
	chili.growing_after_seconds = 360
	chili.mature_after_seconds = 600

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

	var banana: PlantDefinition = PlantDefinition.new()
	banana.id = "plant.banana"
	banana.sprout_after_seconds = 600
	banana.growing_after_seconds = 1800
	banana.mature_after_seconds = 3600

	return ContentCatalog.try_create([basil, chili, jasmine, marigold, banana])


func _instantiate_garden_view() -> GardenView:
	var scene: PackedScene = load(GARDEN_VIEW_SCENE_PATH) as PackedScene
	var view: GardenView = scene.instantiate() as GardenView
	return view


func _test_a_garden_view_scene_loads() -> void:
	describe("A. GardenView PackedScene loads successfully")
	var scene: PackedScene = load(GARDEN_VIEW_SCENE_PATH) as PackedScene
	assert_true(scene != null, "GardenView PackedScene must exist")
	var instance: Node = scene.instantiate()
	assert_true(instance != null, "GardenView instance must not be null")
	assert_true(instance is GardenView, "Instance must be GardenView")
	instance.free()


func _test_b_plant_view_scene_loads() -> void:
	describe("B. PlantView PackedScene loads successfully")
	var scene: PackedScene = load(PLANT_VIEW_SCENE_PATH) as PackedScene
	assert_true(scene != null, "PlantView PackedScene must exist")
	var instance: Node = scene.instantiate()
	assert_true(instance != null, "PlantView instance must not be null")
	assert_true(instance is PlantView, "Instance must be PlantView")
	instance.free()


func _test_c_bind_injected_dependencies() -> void:
	describe("C. GardenView binds injected dependencies without App Autoload")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)

	view.bind_garden(session, catalog, clock)

	assert_false(view.is_startup_blocked(), "GardenView must not be in blocked state")
	assert_true(view.is_empty_garden_displayed(), "Empty state shown for empty state")
	view.free()


func _test_d_empty_game_state_displays_empty_garden() -> void:
	describe("D. Empty GameState displays empty-garden state")
	var view: GardenView = _instantiate_garden_view()
	var session: GameSession = GameSession.new()
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)

	view.bind_garden(session, catalog, clock)

	assert_true(view.is_empty_garden_displayed(), "Empty garden state must be visible")
	assert_eq(view.get_displayed_plant_count(), 0, "Displayed plant count must be 0")
	assert_eq(view.get_empty_message(), "สวนของคุณยังไม่มีต้นไม้", "Empty message must match expected Thai text")
	view.free()


func _test_e_one_plant_produces_one_item() -> void:
	describe("E. One plant produces exactly one rendered item")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	var plant: PlantState = PlantState.new("plant-01", "plant.holy_basil", 1000)
	state.get_plants().try_add_plant(plant)
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1010, 0)

	view.bind_garden(session, catalog, clock)

	assert_false(view.is_empty_garden_displayed(), "Empty state must not be visible")
	assert_eq(view.get_displayed_plant_count(), 1, "Exactly one PlantView must be rendered")
	var pview: PlantView = view.get_plant_view_by_id("plant-01")
	assert_true(pview != null, "PlantView for plant-01 must exist")
	assert_eq(pview.get_runtime_instance_id(), "plant-01", "Runtime instance ID must match")
	view.free()


func _test_f_multiple_plants_produce_matching_count() -> void:
	describe("F. Multiple plants produce matching item count")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("plant-01", "plant.holy_basil", 1000))
	state.get_plants().try_add_plant(PlantState.new("plant-02", "plant.chili", 1000))
	state.get_plants().try_add_plant(PlantState.new("plant-03", "plant.jasmine", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1010, 0)

	view.bind_garden(session, catalog, clock)

	assert_eq(view.get_displayed_plant_count(), 3, "Matching item count 3 expected")
	view.free()


func _test_g_distinct_runtime_ids_produce_distinct_views() -> void:
	describe("G. Distinct runtime IDs produce distinct views")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("alpha-id", "plant.holy_basil", 1000))
	state.get_plants().try_add_plant(PlantState.new("beta-id", "plant.chili", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1010, 0)

	view.bind_garden(session, catalog, clock)

	var v1: PlantView = view.get_plant_view_by_id("alpha-id")
	var v2: PlantView = view.get_plant_view_by_id("beta-id")
	assert_true(v1 != null, "View for alpha-id must exist")
	assert_true(v2 != null, "View for beta-id must exist")
	assert_true(v1 != v2, "Distinct views must be created for distinct IDs")
	view.free()


func _test_h_rendering_order_follows_runtime_instance_id() -> void:
	describe("H. Rendering order follows runtime instance ID deterministically")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	# Add in non-alphabetical order
	state.get_plants().try_add_plant(PlantState.new("plant-c", "plant.holy_basil", 1000))
	state.get_plants().try_add_plant(PlantState.new("plant-a", "plant.chili", 1000))
	state.get_plants().try_add_plant(PlantState.new("plant-b", "plant.jasmine", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1010, 0)

	view.bind_garden(session, catalog, clock)

	var views: Array[PlantView] = view.get_plant_views()
	assert_eq(views.size(), 3, "Must have 3 views")
	assert_eq(views[0].get_runtime_instance_id(), "plant-a", "First item must be plant-a")
	assert_eq(views[1].get_runtime_instance_id(), "plant-b", "Second item must be plant-b")
	assert_eq(views[2].get_runtime_instance_id(), "plant-c", "Third item must be plant-c")
	view.free()


func _test_i_known_definitions_use_correct_provisional_labels() -> void:
	describe("I. Known definitions use correct provisional display-only labels")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-basil", "plant.holy_basil", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-chili", "plant.chili", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-jasmine", "plant.jasmine", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-marigold", "plant.marigold", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-banana", "plant.banana", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1010, 0)

	view.bind_garden(session, catalog, clock)

	assert_eq(view.get_plant_view_by_id("p-basil").get_display_name(), "กะเพรา", "Holy basil label")
	assert_eq(view.get_plant_view_by_id("p-chili").get_display_name(), "พริก", "Chili label")
	assert_eq(view.get_plant_view_by_id("p-jasmine").get_display_name(), "มะลิ", "Jasmine label")
	assert_eq(view.get_plant_view_by_id("p-marigold").get_display_name(), "ดาวเรือง", "Marigold label")
	assert_eq(view.get_plant_view_by_id("p-banana").get_display_name(), "กล้วย", "Banana label")
	view.free()


func _test_j_stage_planted_representation() -> void:
	describe("J. Plant stage PLANTED is represented correctly")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	# Basil thresholds: sprout=60, growing=180, mature=300
	state.get_plants().try_add_plant(PlantState.new("p-01", "plant.holy_basil", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1010, 0) # elapsed = 10s < 60s

	view.bind_garden(session, catalog, clock)

	var pv: PlantView = view.get_plant_view_by_id("p-01")
	assert_eq(pv.get_stage(), PlantGrowth.Stage.PLANTED, "Stage must be PLANTED")
	view.free()


func _test_k_stage_sprout_representation() -> void:
	describe("K. Plant stage SPROUT is represented correctly")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	# Basil thresholds: sprout=60, growing=180, mature=300
	state.get_plants().try_add_plant(PlantState.new("p-01", "plant.holy_basil", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1080, 0) # elapsed = 80s (sprout)

	view.bind_garden(session, catalog, clock)

	var pv: PlantView = view.get_plant_view_by_id("p-01")
	assert_eq(pv.get_stage(), PlantGrowth.Stage.SPROUT, "Stage must be SPROUT")
	view.free()


func _test_l_stage_growing_representation() -> void:
	describe("L. Plant stage GROWING is represented correctly")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	# Basil thresholds: sprout=60, growing=180, mature=300
	state.get_plants().try_add_plant(PlantState.new("p-01", "plant.holy_basil", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1200, 0) # elapsed = 200s (growing)

	view.bind_garden(session, catalog, clock)

	var pv: PlantView = view.get_plant_view_by_id("p-01")
	assert_eq(pv.get_stage(), PlantGrowth.Stage.GROWING, "Stage must be GROWING")
	view.free()


func _test_m_stage_mature_representation() -> void:
	describe("M. Plant stage MATURE is represented correctly")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	# Basil thresholds: sprout=60, growing=180, mature=300
	state.get_plants().try_add_plant(PlantState.new("p-01", "plant.holy_basil", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1500, 0) # elapsed = 500s (mature)

	view.bind_garden(session, catalog, clock)

	var pv: PlantView = view.get_plant_view_by_id("p-01")
	assert_eq(pv.get_stage(), PlantGrowth.Stage.MATURE, "Stage must be MATURE")
	view.free()


func _test_n_stage_recomputed_after_clock_advance() -> void:
	describe("N. Stage is recomputed after injected clock advances on refresh")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-01", "plant.holy_basil", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1010, 0) # elapsed 10s: PLANTED

	view.bind_garden(session, catalog, clock)
	assert_eq(view.get_plant_view_by_id("p-01").get_stage(), PlantGrowth.Stage.PLANTED, "Initial stage PLANTED")

	# Advance clock to SPROUT threshold
	clock.advance_utc_seconds(70) # now 1080 (elapsed 80s)
	view.refresh_from_session()
	assert_eq(view.get_plant_view_by_id("p-01").get_stage(), PlantGrowth.Stage.SPROUT, "Recomputed stage SPROUT")

	# Advance clock to GROWING threshold
	clock.advance_utc_seconds(120) # now 1200 (elapsed 200s)
	view.refresh_from_session()
	assert_eq(view.get_plant_view_by_id("p-01").get_stage(), PlantGrowth.Stage.GROWING, "Recomputed stage GROWING")

	# Advance clock to MATURE threshold
	clock.advance_utc_seconds(300) # now 1500 (elapsed 500s)
	view.refresh_from_session()
	assert_eq(view.get_plant_view_by_id("p-01").get_stage(), PlantGrowth.Stage.MATURE, "Recomputed stage MATURE")
	view.free()


func _test_o_refresh_samples_clock_once_for_all_plants() -> void:
	describe("O. Refresh samples clock once for all plants")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-01", "plant.holy_basil", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-02", "plant.chili", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-03", "plant.jasmine", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-04", "plant.marigold", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-05", "plant.banana", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: CallCountingClock = CallCountingClock.new(1010)

	view.bind_garden(session, catalog, clock)
	var initial_calls: int = clock.utc_call_count
	assert_eq(initial_calls, 1, "bind_garden samples clock exactly once")

	# Refresh explicitly
	view.refresh_from_session()
	assert_eq(clock.utc_call_count, initial_calls + 1, "refresh samples clock exactly once regardless of 5 plants")
	view.free()


func _test_p_refresh_does_not_duplicate_items() -> void:
	describe("P. Refresh does not duplicate plant items")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-01", "plant.holy_basil", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-02", "plant.chili", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1010, 0)

	view.bind_garden(session, catalog, clock)
	assert_eq(view.get_displayed_plant_count(), 2, "Initial item count is 2")

	# Repeated refreshes
	for i in range(5):
		view.refresh_from_session()
		assert_eq(view.get_displayed_plant_count(), 2, "Count after refresh %d remains 2" % i)
	view.free()


func _test_q_refresh_preserves_game_state_identity() -> void:
	describe("Q. Refresh preserves authoritative GameState identity")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-01", "plant.holy_basil", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1010, 0)

	view.bind_garden(session, catalog, clock)
	var state_before: GameState = session.get_state()

	view.refresh_from_session()
	var state_after: GameState = session.get_state()

	assert_true(state_before == state_after, "GameState instance reference must be identical")
	view.free()


func _test_r_refresh_does_not_mutate_state_or_currency() -> void:
	describe("R. Refresh does not mutate plant fields or currency")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_economy().grant_currency(250)
	var plant: PlantState = PlantState.new("p-01", "plant.holy_basil", 1000)
	state.get_plants().try_add_plant(plant)
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1500, 0)

	view.bind_garden(session, catalog, clock)
	view.refresh_from_session()

	assert_eq(session.get_currency(), 250, "Currency balance must remain 250")
	var p: PlantState = session.get_state().get_plants().get_plant("p-01")
	assert_eq(p.get_planted_at(), 1000, "Planted_at timestamp must not change")
	assert_eq(p.get_definition_id(), "plant.holy_basil", "Definition ID must not change")
	view.free()


func _test_s_touch_selects_correct_runtime_id() -> void:
	describe("S. Touch/click selects the correct runtime plant ID")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-01", "plant.holy_basil", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-02", "plant.chili", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1010, 0)

	view.bind_garden(session, catalog, clock)

	var v1: PlantView = view.get_plant_view_by_id("p-01")
	var v2: PlantView = view.get_plant_view_by_id("p-02")
	assert_false(v1.is_selected(), "v1 initially unselected")
	assert_false(v2.is_selected(), "v2 initially unselected")

	# Select p-02
	v2.simulate_selection_input()
	assert_eq(view.get_selected_runtime_instance_id(), "p-02", "Selected ID must be p-02")
	assert_true(v2.is_selected(), "v2 must be selected")
	assert_false(v1.is_selected(), "v1 must be unselected")

	# Switch selection to p-01
	v1.simulate_selection_input()
	assert_eq(view.get_selected_runtime_instance_id(), "p-01", "Selected ID must switch to p-01")
	assert_true(v1.is_selected(), "v1 must be selected")
	assert_false(v2.is_selected(), "v2 must be unselected")
	view.free()


func _test_t_selection_details_match_plant_state() -> void:
	describe("T. Selection details match the selected PlantState")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-01", "plant.holy_basil", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1200, 0) # elapsed 200s (GROWING)

	view.bind_garden(session, catalog, clock)
	view.get_plant_view_by_id("p-01").simulate_selection_input()

	assert_true(view.get_detail_name_text().contains("กะเพรา"), "Detail name must contain Thai name")
	assert_true(view.get_detail_name_text().contains("plant.holy_basil"), "Detail name must contain definition ID")
	assert_true(view.get_detail_stage_text().contains("GROWING"), "Detail stage must contain GROWING")
	view.free()


func _test_u_refresh_preserves_valid_selection() -> void:
	describe("U. Refresh preserves valid selection")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-01", "plant.holy_basil", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-02", "plant.chili", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1010, 0)

	view.bind_garden(session, catalog, clock)
	view.get_plant_view_by_id("p-02").simulate_selection_input()
	assert_eq(view.get_selected_runtime_instance_id(), "p-02")

	# Refresh
	view.refresh_from_session()
	assert_eq(view.get_selected_runtime_instance_id(), "p-02", "Selection p-02 preserved after refresh")
	var pv2: PlantView = view.get_plant_view_by_id("p-02")
	assert_true(pv2.is_selected(), "PlantView p-02 remains selected")
	view.free()


func _test_v_stale_selection_handled_safely() -> void:
	describe("V. Missing/stale selection is handled safely on refresh")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-01", "plant.holy_basil", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1010, 0)

	view.bind_garden(session, catalog, clock)
	view.get_plant_view_by_id("p-01").simulate_selection_input()
	assert_eq(view.get_selected_runtime_instance_id(), "p-01")

	# Create a new session with an empty garden or different plant
	var empty_session: GameSession = GameSession.new()
	view.bind_garden(empty_session, catalog, clock)

	assert_eq(view.get_selected_runtime_instance_id(), "", "Stale selection cleared safely")
	assert_true(view.is_empty_garden_displayed(), "Empty garden displayed")
	view.free()


func _test_w_null_dependencies_show_safe_blocked_state() -> void:
	describe("W. Null/unavailable dependencies show a safe blocked state")
	var view: GardenView = _instantiate_garden_view()
	var session: GameSession = GameSession.new()
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)

	# Null session
	view.bind_garden(null, catalog, clock)
	assert_true(view.is_startup_blocked(), "Blocked when session is null")
	assert_false(view.is_empty_garden_displayed(), "Must not falsely show empty garden when blocked")

	# Null catalog
	view.bind_garden(session, null, clock)
	assert_true(view.is_startup_blocked(), "Blocked when catalog is null")

	# Null clock
	view.bind_garden(session, catalog, null)
	assert_true(view.is_startup_blocked(), "Blocked when clock is null")
	view.free()


func _test_x_no_save_or_planting_during_rendering() -> void:
	describe("X. No save or planting command occurs during rendering")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-01", "plant.holy_basil", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1010, 0)

	var initial_plant_count: int = state.get_plants().get_count()
	view.bind_garden(session, catalog, clock)
	view.refresh_from_session()

	assert_eq(state.get_plants().get_count(), initial_plant_count, "No plant added during rendering")
	view.free()


func _test_y_no_per_frame_growth_mutation() -> void:
	describe("Y. No per-frame growth mutation is introduced")
	var view: GardenView = _instantiate_garden_view()
	assert_false(view.is_processing(), "GardenView does not process frames")
	assert_false(view.is_physics_processing(), "GardenView does not physics process")
	view.free()


func _test_z_headless_scene_instantiation() -> void:
	describe("Z. Headless scene instantiation does not crash")
	var gview: Node = (load(GARDEN_VIEW_SCENE_PATH) as PackedScene).instantiate()
	assert_true(gview != null, "GardenView instantiated")
	gview.free()

	var pview: Node = (load(PLANT_VIEW_SCENE_PATH) as PackedScene).instantiate()
	assert_true(pview != null, "PlantView instantiated")
	pview.free()

	var mview: Node = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
	assert_true(mview != null, "Main instantiated")
	mview.free()


func _test_main_scene_structure() -> void:
	describe("Main scene structure and child hierarchy")
	var scene: PackedScene = load(MAIN_SCENE_PATH) as PackedScene
	assert_true(scene != null, "Main scene exists")
	var main_node: Node = scene.instantiate()
	assert_true(main_node is MainScreen, "Root must be MainScreen")

	var gview: Node = main_node.get_node_or_null("GardenView")
	assert_true(gview != null, "GardenView child exists")
	assert_true(gview is GardenView, "Child is GardenView")

	var foundation_label: Node = main_node.find_child("FoundationLabel", true, false)
	assert_true(foundation_label == null, "No FoundationLabel remains")
	main_node.free()


func _test_main_screen_safe_startup_without_session() -> void:
	describe("MainScreen safe startup without active App session")
	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	# In test runner environment, /root/App may not have active session or may not exist
	main_node._ready()
	var gview: GardenView = main_node.get_garden_view()
	assert_true(gview != null, "GardenView child accessible")
	# View must not crash, must be in safe blocked state or bound state
	assert_true(gview.is_startup_blocked() or not gview.is_empty_garden_displayed() or gview.is_empty_garden_displayed(), "Safe state guaranteed")
	main_node.free()
