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
	_test_planting_picker_available_on_valid_empty_garden()
	_test_planting_controls_blocked_without_active_session()
	_test_picker_signal_forwarded_by_garden_view()
	_test_feedback_registered_saved()
	_test_feedback_registered_save_failed()
	_test_feedback_planting_rejected()
	_test_feedback_not_ready()
	_test_refresh_after_registration_updates_count_no_duplicates()
	_test_selected_plant_preserved_after_planting_refresh()
	_test_refresh_remains_read_only_no_save_on_cancel()
	_test_integration_confirmed_planting_saves_once_and_renders()
	_test_integration_cancelling_causes_zero_saves()
	_test_integration_duplicate_confirmation_causes_no_duplicate_registration()
	_test_integration_failed_save_preserves_plant_with_warning()
	_test_integration_corrupt_save_blocks_controls()
	_test_integration_unbootstrapped_app_causes_no_writes()
	_test_integration_session_and_catalog_identity_unchanged()
	_test_main_screen_refreshes_on_app_session_resumed()
	_test_main_screen_ignores_spurious_or_duplicate_resume()
	_test_main_screen_rebind_and_disconnect_app_root_resume_signal()
	_test_currency_hud_reflects_authoritative_balance()
	_test_harvest_button_state_and_signal_emission()
	_test_harvest_feedback_rendering()
	_test_integration_harvest_button_grants_coins_resets_plant_and_saves()
	_test_environment_and_visitor_hud_and_observation()
	_test_decoration_hud_picker_and_purchase_flow()
	_test_atmosphere_hud_weather_time_events_and_background_tint()
	_test_progression_and_gentle_guidance_hud()
	_test_return_summary_and_resume_feedback()
	_test_ambient_event_observation_button_and_feedback()
	_test_selected_plant_growth_countdown_and_atmosphere_forecast()


func _create_test_catalog() -> ContentCatalog:
	var basil: PlantDefinition = PlantDefinition.new()
	basil.id = "plant.holy_basil"
	basil.sprout_after_seconds = 60
	basil.growing_after_seconds = 180
	basil.mature_after_seconds = 300
	basil.harvest_reward = 5

	var chili: PlantDefinition = PlantDefinition.new()
	chili.id = "plant.chili"
	chili.sprout_after_seconds = 120
	chili.growing_after_seconds = 360
	chili.mature_after_seconds = 600
	chili.harvest_reward = 10

	var jasmine: PlantDefinition = PlantDefinition.new()
	jasmine.id = "plant.jasmine"
	jasmine.sprout_after_seconds = 300
	jasmine.growing_after_seconds = 900
	jasmine.mature_after_seconds = 1800
	jasmine.harvest_reward = 25

	var marigold: PlantDefinition = PlantDefinition.new()
	marigold.id = "plant.marigold"
	marigold.sprout_after_seconds = 90
	marigold.growing_after_seconds = 240
	marigold.mature_after_seconds = 450
	marigold.harvest_reward = 20

	var banana: PlantDefinition = PlantDefinition.new()
	banana.id = "plant.banana"
	banana.sprout_after_seconds = 600
	banana.growing_after_seconds = 1800
	banana.mature_after_seconds = 3600
	banana.harvest_reward = 60

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


const TEST_PRIMARY_PATH: String = "user://__test_garden_pres_primary.json"
const TEST_TEMP_PATH: String = "user://__test_garden_pres.tmp"
const TEST_BACKUP_PATH: String = "user://__test_garden_pres.bak"
const TEST_CORRUPT_PATH: String = "user://__test_garden_pres.corrupt"


class FailingSaveRepo extends LocalSaveRepository:
	var save_call_count: int = 0

	func _init(p: String = TEST_PRIMARY_PATH, t: String = TEST_TEMP_PATH, b: String = TEST_BACKUP_PATH, c: String = TEST_CORRUPT_PATH) -> void:
		super._init(p, t, b, c)

	func save(_state: GameState) -> bool:
		save_call_count += 1
		return false


class CountingSaveRepo extends LocalSaveRepository:
	var save_call_count: int = 0

	func _init(p: String = TEST_PRIMARY_PATH, t: String = TEST_TEMP_PATH, b: String = TEST_BACKUP_PATH, c: String = TEST_CORRUPT_PATH) -> void:
		super._init(p, t, b, c)

	func save(state: GameState) -> bool:
		save_call_count += 1
		return super.save(state)


class GardenSignalTracker extends RefCounted:
	var emitted_count: int = 0
	var received_ids: Array[String] = []

	func on_planting_requested(def_id: String) -> void:
		emitted_count += 1
		received_ids.append(def_id)


func _cleanup_presentation_test_files() -> void:
	for p: String in [TEST_PRIMARY_PATH, TEST_TEMP_PATH, TEST_BACKUP_PATH, TEST_CORRUPT_PATH]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _test_main_screen_safe_startup_without_session() -> void:
	describe("MainScreen safe startup without active App session (meaningful verification)")
	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	var gview: GardenView = main_node.get_garden_view()
	assert_true(gview != null, "GardenView child accessible")

	# Explicitly verify missing/null AppRoot results in startup blocked and planting disabled
	main_node.bind_app_root(null)
	assert_true(gview.is_startup_blocked(), "GardenView must be in blocked state when AppRoot is null")
	assert_false(gview.is_planting_enabled(), "Planting interaction must be disabled when AppRoot is null")
	assert_eq(gview.get_blocked_message(), "ไม่พบบริการหลักของระบบ (AppRoot)", "Blocked message must indicate missing AppRoot")

	# Explicitly verify unbootstrapped/inactive session results in startup blocked and planting disabled
	var unbootstrapped_app: AppRoot = AppRoot.new()
	main_node.bind_app_root(unbootstrapped_app)
	assert_true(gview.is_startup_blocked(), "GardenView must be in blocked state when session is unbootstrapped")
	assert_false(gview.is_planting_enabled(), "Planting interaction must be disabled when session is unbootstrapped")
	unbootstrapped_app.free()

	main_node.free()


func _test_planting_picker_available_on_valid_empty_garden() -> void:
	describe("Planting picker visible and available on valid empty garden")
	var view: GardenView = _instantiate_garden_view()
	var session: GameSession = GameSession.new()
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)

	view.bind_garden(session, catalog, clock)

	assert_true(view.is_empty_garden_displayed(), "Empty garden displayed initially")
	assert_true(view.is_planting_enabled(), "Planting controls must be enabled")
	var picker: PlantingPicker = view.get_planting_picker()
	assert_true(picker != null, "PlantingPicker exists")
	assert_false(picker.is_picker_open(), "Picker closed by default")

	view.open_planting_picker()
	assert_true(picker.is_picker_open(), "Picker opened via view.open_planting_picker()")

	view.close_planting_picker()
	assert_false(picker.is_picker_open(), "Picker closed via view.close_planting_picker()")
	view.free()


func _test_planting_controls_blocked_without_active_session() -> void:
	describe("Planting controls blocked without active session")
	var view: GardenView = _instantiate_garden_view()
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)

	view.bind_garden(null, catalog, clock)

	assert_true(view.is_startup_blocked(), "Startup is blocked")
	assert_false(view.is_planting_enabled(), "Planting controls must be disabled")

	view.open_planting_picker()
	var picker: PlantingPicker = view.get_planting_picker()
	assert_false(picker.is_picker_open(), "Picker must not open when startup is blocked")
	view.free()


func _test_picker_signal_forwarded_by_garden_view() -> void:
	describe("Picker signal forwarded exactly once by GardenView")
	var view: GardenView = _instantiate_garden_view()
	var session: GameSession = GameSession.new()
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)

	view.bind_garden(session, catalog, clock)

	var tracker: GardenSignalTracker = GardenSignalTracker.new()
	view.planting_requested.connect(tracker.on_planting_requested)

	var picker: PlantingPicker = view.get_planting_picker()
	picker.open_picker()
	picker.select_plant_definition("plant.chili")
	picker.confirm_planting()

	assert_eq(tracker.emitted_count, 1, "GardenView forwarded planting request exactly once")
	assert_eq(tracker.received_ids[0], "plant.chili", "Forwarded definition ID must match")
	view.free()


func _test_feedback_registered_saved() -> void:
	describe("Result REGISTERED_SAVED shows success feedback")
	var view: GardenView = _instantiate_garden_view()
	var plant: PlantState = PlantState.new("inst-01", "plant.holy_basil", 1000)
	var reg_result: PlantRegistrationResult = PlantRegistrationResult.registered(plant)
	var result: PlantingCheckpointResult = PlantingCheckpointResult.registered_saved(reg_result)

	view.show_planting_result(result)

	assert_true(view.is_feedback_visible(), "Feedback area must be visible")
	assert_true(view.get_feedback_text().contains("เพิ่มต้นไม้และบันทึกเรียบร้อยแล้ว"), "Feedback shows success message")
	view.free()


func _test_feedback_registered_save_failed() -> void:
	describe("Result REGISTERED_SAVE_FAILED shows explicit unsaved warning")
	var view: GardenView = _instantiate_garden_view()
	var plant: PlantState = PlantState.new("inst-01", "plant.holy_basil", 1000)
	var reg_result: PlantRegistrationResult = PlantRegistrationResult.registered(plant)
	var result: PlantingCheckpointResult = PlantingCheckpointResult.registered_save_failed(reg_result)

	view.show_planting_result(result)

	assert_true(view.is_feedback_visible(), "Feedback area must be visible")
	assert_true(view.get_feedback_text().contains("เพิ่มต้นไม้แล้ว แต่ยังบันทึกไม่สำเร็จ"), "Feedback shows unsaved warning")
	assert_false(view.get_feedback_text().contains("เพิ่มต้นไม้และบันทึกเรียบร้อยแล้ว"), "Must never show false durable success")
	view.free()


func _test_feedback_planting_rejected() -> void:
	describe("Rejected result shows non-success feedback with failure diagnostic")
	var view: GardenView = _instantiate_garden_view()
	var reg_result: PlantRegistrationResult = PlantRegistrationResult.unknown_definition_id()
	var result: PlantingCheckpointResult = PlantingCheckpointResult.planting_rejected(reg_result)

	view.show_planting_result(result)

	assert_true(view.is_feedback_visible(), "Feedback area must be visible")
	assert_true(view.get_feedback_text().contains("ไม่สามารถเพิ่มต้นไม้ได้"), "Feedback shows rejection")
	assert_true(view.get_feedback_text().contains("UNKNOWN_DEFINITION_ID"), "Retains diagnostic status")
	view.free()


func _test_feedback_not_ready() -> void:
	describe("NOT_READY shows unavailable feedback without misleading success")
	var view: GardenView = _instantiate_garden_view()
	var result: PlantingCheckpointResult = PlantingCheckpointResult.not_ready()

	view.show_planting_result(result)

	assert_true(view.is_feedback_visible(), "Feedback area must be visible")
	assert_true(view.get_feedback_text().contains("ระบบยังไม่พร้อมสำหรับการปลูกต้นไม้"), "Feedback indicates system not ready")
	assert_false(view.get_feedback_text().contains("สำเร็จ"), "Must not claim success")
	view.free()


func _test_refresh_after_registration_updates_count_no_duplicates() -> void:
	describe("Refresh after registration updates plant count without duplicates")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)

	view.bind_garden(session, catalog, clock)
	assert_eq(view.get_displayed_plant_count(), 0, "Initial count 0")
	assert_true(view.is_empty_garden_displayed(), "Empty state visible")

	# Add plant directly to authoritative session
	state.get_plants().try_add_plant(PlantState.new("plant-01", "plant.holy_basil", 1000))
	view.refresh_from_session()

	assert_eq(view.get_displayed_plant_count(), 1, "Count is 1 after refresh")
	assert_false(view.is_empty_garden_displayed(), "Empty state hidden")

	# Second refresh must not duplicate
	view.refresh_from_session()
	assert_eq(view.get_displayed_plant_count(), 1, "Count remains 1 after second refresh")
	view.free()


func _test_selected_plant_preserved_after_planting_refresh() -> void:
	describe("Selected existing plant remains correct after planting and refresh")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("plant-01", "plant.holy_basil", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)

	view.bind_garden(session, catalog, clock)
	view.get_plant_view_by_id("plant-01").simulate_selection_input()
	assert_eq(view.get_selected_runtime_instance_id(), "plant-01", "plant-01 selected")

	# Add second plant and refresh
	state.get_plants().try_add_plant(PlantState.new("plant-02", "plant.chili", 1000))
	view.refresh_from_session()

	assert_eq(view.get_selected_runtime_instance_id(), "plant-01", "Selection preserved on plant-01")
	var pv: PlantView = view.get_plant_view_by_id("plant-01")
	assert_true(pv != null and pv.is_selected(), "PlantView plant-01 remains visually highlighted")
	view.free()


func _test_refresh_remains_read_only_no_save_on_cancel() -> void:
	describe("Refresh remains read-only and no automatic save occurs on cancel")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)

	view.bind_garden(session, catalog, clock)
	var picker: PlantingPicker = view.get_planting_picker()
	picker.open_picker()
	picker.select_plant_definition("plant.chili")
	picker.cancel_confirmation()
	view.refresh_from_session()

	assert_eq(state.get_plants().get_count(), 0, "No plant added")
	assert_eq(session.get_currency(), 0, "No currency change")
	view.free()


func _test_integration_confirmed_planting_saves_once_and_renders() -> void:
	describe("Integration: Confirmed planting saves once, adds PlantState, and renders in GardenView")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	var clock: FakeGameClock = FakeGameClock.new(2000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])
	var loader: PlantContentLoader = PlantContentLoader.new()
	var app: AppRoot = AppRoot.new(repo, loader, clock, rng)
	var _load_res: LocalSaveLoadResult = app.bootstrap_session()
	assert_true(app.has_active_session(), "App bootstrapped with active session")

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)

	var gview: GardenView = main_node.get_garden_view()
	assert_true(gview.is_empty_garden_displayed(), "Empty garden initially")

	# Confirm planting through picker
	var picker: PlantingPicker = gview.get_planting_picker()
	picker.open_picker()
	picker.select_plant_definition("plant.holy_basil")
	picker.confirm_planting()

	assert_eq(repo.save_call_count, 1, "Save called exactly once")
	assert_eq(app.game_session.get_state().get_plants().get_count(), 1, "Exactly 1 plant in GameState")
	assert_false(gview.is_empty_garden_displayed(), "Empty state disappeared")
	assert_eq(gview.get_displayed_plant_count(), 1, "One plant rendered in GardenView")

	var pview: PlantView = gview.get_plant_views()[0]
	assert_eq(pview.get_definition_id(), "plant.holy_basil", "Plant definition holy basil")
	assert_true(pview.get_runtime_instance_id().length() > 0, "Non-empty instance ID")
	assert_true(gview.get_feedback_text().contains("เพิ่มต้นไม้และบันทึกเรียบร้อยแล้ว"), "Success feedback displayed")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_integration_cancelling_causes_zero_saves() -> void:
	describe("Integration: Cancelling planting causes zero saves and leaves state unchanged")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	var clock: FakeGameClock = FakeGameClock.new(2000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)

	var gview: GardenView = main_node.get_garden_view()
	var picker: PlantingPicker = gview.get_planting_picker()
	picker.open_picker()
	picker.select_plant_definition("plant.chili")
	picker.cancel_confirmation()

	assert_eq(repo.save_call_count, 0, "Zero saves on cancel")
	assert_eq(app.game_session.get_state().get_plants().get_count(), 0, "Zero plants in GameState")
	assert_true(gview.is_empty_garden_displayed(), "Empty garden unchanged")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_integration_duplicate_confirmation_causes_no_duplicate_registration() -> void:
	describe("Integration: Duplicate confirmation cannot cause duplicate registration")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	var clock: FakeGameClock = FakeGameClock.new(2000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)

	var gview: GardenView = main_node.get_garden_view()
	var picker: PlantingPicker = gview.get_planting_picker()
	picker.open_picker()
	picker.select_plant_definition("plant.jasmine")
	picker.confirm_planting()
	assert_eq(repo.save_call_count, 1, "First confirmation saves once")
	assert_eq(app.game_session.get_state().get_plants().get_count(), 1, "One plant registered")

	# Immediate repeated confirm attempt without re-selecting
	picker.confirm_planting()
	assert_eq(repo.save_call_count, 1, "Still exactly 1 save call")
	assert_eq(app.game_session.get_state().get_plants().get_count(), 1, "Still exactly 1 plant registered")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_integration_failed_save_preserves_plant_with_warning() -> void:
	describe("Integration: Failed save preserves plant in memory with explicit unsaved warning")
	_cleanup_presentation_test_files()

	var repo: FailingSaveRepo = FailingSaveRepo.new()
	var clock: FakeGameClock = FakeGameClock.new(2000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)

	var gview: GardenView = main_node.get_garden_view()
	var picker: PlantingPicker = gview.get_planting_picker()
	picker.open_picker()
	picker.select_plant_definition("plant.marigold")
	picker.confirm_planting()

	assert_eq(repo.save_call_count, 1, "Save attempted once")
	assert_eq(app.game_session.get_state().get_plants().get_count(), 1, "Plant preserved in memory")
	assert_eq(gview.get_displayed_plant_count(), 1, "Plant rendered in GardenView")
	assert_true(gview.get_feedback_text().contains("เพิ่มต้นไม้แล้ว แต่ยังบันทึกไม่สำเร็จ"), "Shows explicit unsaved warning")
	assert_false(gview.get_feedback_text().contains("เพิ่มต้นไม้และบันทึกเรียบร้อยแล้ว"), "No false saved-success claim")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_integration_corrupt_save_blocks_controls() -> void:
	describe("Integration: Corrupt save at startup blocks planting controls")
	_cleanup_presentation_test_files()

	# Create corrupt save file
	var fa: FileAccess = FileAccess.open(TEST_PRIMARY_PATH, FileAccess.WRITE)
	assert_true(fa != null, "Corrupt test file created")
	fa.store_string("NOT_VALID_JSON{{{")
	fa.close()

	var repo: LocalSaveRepository = LocalSaveRepository.new(TEST_PRIMARY_PATH, TEST_TEMP_PATH, TEST_BACKUP_PATH, TEST_CORRUPT_PATH)
	var clock: FakeGameClock = FakeGameClock.new(2000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()
	assert_false(app.has_active_session(), "Session not active due to corrupt save")

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)

	var gview: GardenView = main_node.get_garden_view()
	assert_true(gview.is_startup_blocked(), "GardenView blocked")
	assert_false(gview.is_planting_enabled(), "Planting controls disabled")
	assert_eq(gview.get_blocked_message(), "ข้อมูลบันทึกเสียหาย ไม่สามารถเปิดสวนได้")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_integration_unbootstrapped_app_causes_no_writes() -> void:
	describe("Integration: Unbootstrapped app causes no writes")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	var clock: FakeGameClock = FakeGameClock.new(2000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)

	var gview: GardenView = main_node.get_garden_view()
	assert_true(gview.is_startup_blocked(), "Startup blocked")
	assert_false(gview.is_planting_enabled(), "Planting disabled")
	assert_eq(repo.save_call_count, 0, "Zero saves invoked")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_integration_session_and_catalog_identity_unchanged() -> void:
	describe("Integration: Existing session and catalog identity unchanged after planting")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	var clock: FakeGameClock = FakeGameClock.new(2000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var expected_session: GameSession = app.game_session
	var expected_catalog: ContentCatalog = app.get_content_catalog()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)

	var gview: GardenView = main_node.get_garden_view()
	var picker: PlantingPicker = gview.get_planting_picker()
	picker.open_picker()
	picker.select_plant_definition("plant.banana")
	picker.confirm_planting()

	assert_true(app.game_session == expected_session, "GameSession reference unchanged")
	assert_true(app.get_content_catalog() == expected_catalog, "ContentCatalog reference unchanged")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_main_screen_refreshes_on_app_session_resumed() -> void:
	describe("MainScreen refreshes GardenView once on AppRoot PAUSED -> RESUMED with single clock sample")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	var clock: CallCountingClock = CallCountingClock.new(1000)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)

	var gview: GardenView = main_node.get_garden_view()
	var picker: PlantingPicker = gview.get_planting_picker()

	# Plant holy_basil (sprout=60, growing=180, mature=600) and chili (sprout=120, growing=480, mature=1200) at t=1000.
	picker.open_picker()
	picker.select_plant_definition("plant.holy_basil")
	picker.confirm_planting()

	picker.open_picker()
	picker.select_plant_definition("plant.chili")
	picker.confirm_planting()

	assert_eq(gview.get_displayed_plant_count(), 2, "Two plants displayed")
	var basil_id: String = ""
	var chili_id: String = ""
	for pv: PlantView in gview.get_plant_views():
		if pv.get_definition_id() == "plant.holy_basil":
			basil_id = pv.get_runtime_instance_id()
		elif pv.get_definition_id() == "plant.chili":
			chili_id = pv.get_runtime_instance_id()

	gview.get_plant_view_by_id(basil_id).simulate_selection_input()
	assert_eq(gview.get_selected_runtime_instance_id(), basil_id, "Basil selected")
	assert_true(gview.get_detail_stage_text().contains("PLANTED"), "Basil initially PLANTED in details")

	# Pause application at t = 1000.
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var saves_after_pause: int = repo.save_call_count
	var clock_calls_before_resume: int = clock.utc_call_count

	# Advance clock while backgrounded by +200s (t = 1200) and resume.
	clock.advance_utc_seconds(200)
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	assert_eq(
		clock.utc_call_count,
		clock_calls_before_resume + 1,
		"Resume refresh must sample GameClock.utc_now_seconds() exactly once across all plants"
	)
	assert_eq(repo.save_call_count, saves_after_pause, "Resume must not perform any save")
	assert_eq(
		gview.get_plant_view_by_id(basil_id).get_stage(),
		PlantGrowth.Stage.GROWING,
		"Basil automatically advances to GROWING on resume"
	)
	assert_eq(
		gview.get_plant_view_by_id(chili_id).get_stage(),
		PlantGrowth.Stage.SPROUT,
		"Chili automatically advances to SPROUT on resume"
	)
	assert_eq(gview.get_selected_runtime_instance_id(), basil_id, "Selection on basil preserved across resume")
	assert_true(gview.get_detail_stage_text().contains("GROWING"), "Details panel stage updates to GROWING on resume")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_main_screen_ignores_spurious_or_duplicate_resume() -> void:
	describe("MainScreen does not refresh on spurious RESUMED when not paused or on duplicate RESUMED")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	var clock: CallCountingClock = CallCountingClock.new(1000)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)

	var calls_initial: int = clock.utc_call_count

	# Spurious resume before any pause.
	clock.advance_utc_seconds(100)
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(clock.utc_call_count, calls_initial, "Spurious RESUMED when not paused must not sample clock")

	# Pause -> first resume refreshes once -> duplicate resume is ignored.
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(clock.utc_call_count, calls_initial + 1, "First RESUMED after PAUSED refreshes once")

	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(clock.utc_call_count, calls_initial + 1, "Duplicate RESUMED without pause must not refresh again")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_main_screen_rebind_and_disconnect_app_root_resume_signal() -> void:
	describe("MainScreen rebinds session_resumed cleanly across bind_app_root and disconnects on _exit_tree")
	_cleanup_presentation_test_files()

	var repo_1: CountingSaveRepo = CountingSaveRepo.new()
	var clock_1: CallCountingClock = CallCountingClock.new(1000)
	var app_1: AppRoot = AppRoot.new(repo_1, PlantContentLoader.new(), clock_1, FakeRandomSource.new([], [1, 2]))
	app_1.bootstrap_session()

	var repo_2: CountingSaveRepo = CountingSaveRepo.new()
	var clock_2: CallCountingClock = CallCountingClock.new(5000)
	var app_2: AppRoot = AppRoot.new(repo_2, PlantContentLoader.new(), clock_2, FakeRandomSource.new([], [3, 4]))
	app_2.bootstrap_session()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app_1)

	# Rebind to app_2.
	main_node.bind_app_root(app_2)
	var clock_1_calls: int = clock_1.utc_call_count
	var clock_2_calls: int = clock_2.utc_call_count

	# Pause/resume on old app_1 must not trigger refresh on main_node.
	app_1._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app_1._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(clock_1.utc_call_count, clock_1_calls, "Disconnecting old AppRoot prevents refresh from app_1")
	assert_eq(clock_2.utc_call_count, clock_2_calls, "app_1 resume does not affect app_2 clock")

	# Pause/resume on new app_2 refreshes main_node once.
	app_2._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app_2._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(clock_2.utc_call_count, clock_2_calls + 1, "Bound app_2 resume refreshes MainScreen")

	# _exit_tree disconnects app_2 signal cleanly.
	main_node._exit_tree()
	app_2._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app_2._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(clock_2.utc_call_count, clock_2_calls + 1, "After _exit_tree, app_2 resume no longer calls MainScreen")

	main_node.free()
	app_1.free()
	app_2.free()
	_cleanup_presentation_test_files()


func _test_currency_hud_reflects_authoritative_balance() -> void:
	describe("GardenView currency HUD reflects authoritative GameSession currency without local cache")
	var view: GardenView = _instantiate_garden_view()
	var session: GameSession = GameSession.new()
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)

	view.bind_garden(session, catalog, clock)
	assert_eq(view.get_currency_text(), "เหรียญ: 0", "Initial currency HUD text is เหรียญ: 0")
	assert_true(view.get_currency_label() != null and view.get_currency_label().visible, "Currency HUD visible")

	session.grant_currency(35)
	view.refresh_from_session()
	assert_eq(view.get_currency_text(), "เหรียญ: 35", "Currency HUD updates to เหรียญ: 35 on refresh")

	view.show_blocked_startup("บล็อกทดสอบ")
	assert_false(view.get_currency_label().visible, "Currency HUD hidden when startup is blocked")
	view.free()


func _test_harvest_button_state_and_signal_emission() -> void:
	describe("HarvestButton is enabled only for selected MATURE plants and emits harvest_requested once")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("basil-1", "plant.holy_basil", 1000))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)

	var harvest_signals: Array[String] = []
	view.harvest_requested.connect(func(id: String) -> void: harvest_signals.append(id))

	view.bind_garden(session, catalog, clock)
	assert_false(view.is_harvest_button_enabled(), "HarvestButton disabled when no plant is selected")

	# Select basil-1 at PLANTED stage (t = 1000)
	view.get_plant_view_by_id("basil-1").simulate_selection_input()
	assert_eq(view.get_detail_reward_text(), "รางวัลเก็บเกี่ยว: 5 เหรียญ", "Reward label shows 5 coins")
	assert_false(view.is_harvest_button_enabled(), "HarvestButton disabled at PLANTED stage")
	assert_eq(view.get_harvest_button().text, "ยังไม่พร้อมเก็บเกี่ยว", "Disabled button label")

	# Advance to GROWING (t = 1200) -> still disabled
	clock.set_utc_seconds(1200)
	view.refresh_from_session()
	assert_false(view.is_harvest_button_enabled(), "HarvestButton disabled at GROWING stage")

	# Advance to MATURE (t = 1300 for test catalog basil mature_after_seconds=300) -> enabled
	clock.set_utc_seconds(1300)
	view.refresh_from_session()
	assert_true(view.is_harvest_button_enabled(), "HarvestButton enabled at MATURE stage")
	assert_eq(view.get_harvest_button().text, "เก็บเกี่ยว (+5 เหรียญ)", "Enabled button shows reward")

	# Press HarvestButton -> emits harvest_requested("basil-1") once
	view.get_harvest_button().pressed.emit()
	assert_eq(harvest_signals, ["basil-1"], "harvest_requested emitted once with basil-1")
	view.free()


func _test_harvest_feedback_rendering() -> void:
	describe("show_harvest_result renders Thai feedback for all HarvestCheckpointResult statuses")
	var view: GardenView = _instantiate_garden_view()
	var plant: PlantState = PlantState.new("basil-1", "plant.holy_basil", 1600)
	var harv_ok: PlantHarvestResult = PlantHarvestResult.harvested(plant, 5)

	view.show_harvest_result(HarvestCheckpointResult.harvested_saved(harv_ok))
	assert_true(view.is_feedback_visible(), "Feedback visible on HARVESTED_SAVED")
	assert_true(
		view.get_feedback_text().contains("เก็บเกี่ยวสำเร็จ (+5 เหรียญ) และบันทึกเรียบร้อยแล้ว"),
		"HARVESTED_SAVED feedback text"
	)

	view.show_harvest_result(HarvestCheckpointResult.harvested_save_failed(harv_ok))
	assert_true(
		view.get_feedback_text().contains("เก็บเกี่ยวสำเร็จ (+5 เหรียญ) แต่ยังบันทึกไม่สำเร็จ"),
		"HARVESTED_SAVE_FAILED feedback text"
	)

	view.show_harvest_result(HarvestCheckpointResult.harvest_rejected(PlantHarvestResult.plant_not_mature()))
	assert_true(
		view.get_feedback_text().contains("ไม่สามารถเก็บเกี่ยวได้ (PLANT_NOT_MATURE)"),
		"HARVEST_REJECTED feedback text"
	)

	view.show_harvest_result(HarvestCheckpointResult.not_ready())
	assert_true(
		view.get_feedback_text().contains("ระบบยังไม่พร้อมสำหรับการเก็บเกี่ยว"),
		"NOT_READY feedback text"
	)
	view.free()


func _test_integration_harvest_button_grants_coins_resets_plant_and_saves() -> void:
	describe("Integration: HarvestButton in MainScreen grants coins, resets plant to PLANTED, and saves once")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	var clock: FakeGameClock = FakeGameClock.new(2000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)
	var gview: GardenView = main_node.get_garden_view()

	# Plant holy_basil (mature=600, reward=5) at t = 2000
	var picker: PlantingPicker = gview.get_planting_picker()
	picker.open_picker()
	picker.select_plant_definition("plant.holy_basil")
	picker.confirm_planting()

	var basil_id: String = gview.get_plant_views()[0].get_runtime_instance_id()
	gview.get_plant_view_by_id(basil_id).simulate_selection_input()
	assert_eq(gview.get_currency_text(), "เหรียญ: 0", "0 coins initially")
	assert_false(gview.is_harvest_button_enabled(), "HarvestButton disabled at PLANTED")
	assert_eq(repo.save_call_count, 1, "1 save after planting")

	# Advance clock by +600s (t = 2600 -> MATURE) and refresh
	clock.advance_utc_seconds(600)
	gview.refresh_from_session()
	assert_true(gview.is_harvest_button_enabled(), "HarvestButton enabled at MATURE")

	# Press HarvestButton
	gview.get_harvest_button().pressed.emit()
	assert_eq(repo.save_call_count, 2, "Save called once on harvest")
	assert_eq(app.game_session.get_currency(), 5, "Authoritative currency is 5")
	assert_eq(gview.get_currency_text(), "เหรียญ: 5", "HUD updated to เหรียญ: 5")
	assert_eq(
		gview.get_plant_view_by_id(basil_id).get_stage(),
		PlantGrowth.Stage.PLANTED,
		"PlantView stage reset to PLANTED"
	)
	assert_eq(
		gview.get_plant_view_by_id(basil_id).get_planted_at(),
		2600,
		"PlantView planted_at reset to 2600"
	)
	assert_false(gview.is_harvest_button_enabled(), "HarvestButton disabled again after cycle reset")
	assert_true(
		gview.get_feedback_text().contains("เก็บเกี่ยวสำเร็จ (+5 เหรียญ) และบันทึกเรียบร้อยแล้ว"),
		"Harvest success feedback shown"
	)

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_environment_and_visitor_hud_and_observation() -> void:
	describe("GardenView displays environmental traits, eligible visitor status, and dispatches visitor observation")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	var clock: FakeGameClock = FakeGameClock.new(2000, 0)
	# Float 0.1 selects first visitor (butterfly), 0.8 selects second visitor (firefly) when jasmine is planted
	var rng: FakeRandomSource = FakeRandomSource.new([0.1, 0.8], [1, 2, 3, 4])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)
	var gview: GardenView = main_node.get_garden_view()

	# 1. Empty garden: no traits, no eligible visitors, observe button disabled, journal 0/10
	assert_eq(gview.get_environment_text(), "สภาพแวดล้อมสวน: ยังไม่มี", "Empty garden environment text")
	assert_true(
		gview.get_visitor_status_text().contains("ยังไม่มีผู้มาเยือน"),
		"Empty garden visitor status text"
	)
	assert_false(gview.is_observe_visitor_button_enabled(), "ObserveVisitorButton disabled on empty garden")
	assert_true(gview.is_journal_button_enabled(), "JournalButton enabled on active session")
	assert_eq(
		gview.get_journal_status_text(),
		"สมุดบ้านสวน: ค้นพบแล้ว 0 / 10 รายการ (พืช 0/5, ผู้มาเยือน 0/5)",
		"Empty garden journal status"
	)

	# 2. Plant jasmine ("dense_vegetation", "flower" -> butterfly and firefly eligible, journal 1/10)
	var picker: PlantingPicker = gview.get_planting_picker()
	picker.open_picker()
	picker.select_plant_definition("plant.jasmine")
	picker.confirm_planting()

	assert_true(gview.get_environment_text().contains("ดอกไม้"), "Environment HUD shows flower trait")
	assert_true(gview.get_environment_text().contains("พุ่มไม้หนา"), "Environment HUD shows dense_vegetation trait")
	assert_true(
		gview.get_visitor_status_text().contains("ผู้มาเยือนที่อาจพบ: ผีเสื้อบ้านสวน, หิ่งห้อย"),
		"Visitor status shows 2 eligible visitors"
	)
	assert_true(gview.is_observe_visitor_button_enabled(), "ObserveVisitorButton enabled when visitors eligible")
	assert_eq(
		gview.get_journal_status_text(),
		"สมุดบ้านสวน: ค้นพบแล้ว 1 / 10 รายการ (พืช 1/5, ผู้มาเยือน 0/5)",
		"Planting jasmine records 1 discovery"
	)

	# 3. Press ObserveVisitorButton -> roll 0.1 selects visitor.butterfly (ผีเสื้อ), records discovery, and saves once
	var saves_before_observe: int = repo.save_call_count
	gview.get_observe_visitor_button().pressed.emit()
	assert_eq(repo.save_call_count, saves_before_observe + 1, "Observing eligible visitor records discovery and saves once")
	assert_true(gview.get_visitor_status_text().contains("ผีเสื้อ"), "Visitor status shows butterfly")
	assert_true(gview.get_feedback_text().contains("พบผู้มาเยือนในสวน: ผีเสื้อ"), "Feedback shows butterfly visit")
	assert_eq(
		gview.get_journal_status_text(),
		"สมุดบ้านสวน: ค้นพบแล้ว 2 / 10 รายการ (พืช 1/5, ผู้มาเยือน 1/5)",
		"Observing butterfly updates journal to 2/10"
	)

	# 4. Press ObserveVisitorButton again -> roll 0.8 selects visitor.firefly (หิ่งห้อย), records discovery, and saves once
	gview.get_observe_visitor_button().pressed.emit()
	assert_eq(repo.save_call_count, saves_before_observe + 2, "Observing second visitor records discovery and saves")
	assert_true(gview.get_visitor_status_text().contains("หิ่งห้อย"), "Visitor status shows firefly")
	assert_true(gview.get_feedback_text().contains("พบผู้มาเยือนในสวน: หิ่งห้อย"), "Feedback shows firefly visit")
	assert_eq(
		gview.get_journal_status_text(),
		"สมุดบ้านสวน: ค้นพบแล้ว 3 / 10 รายการ (พืช 1/5, ผู้มาเยือน 2/5)",
		"Observing firefly updates journal to 3/10"
	)

	# 5. Open and close JournalPanel via JournalButton
	assert_false(gview.get_journal_panel().is_journal_open(), "JournalPanel closed initially")
	gview.get_journal_button().pressed.emit()
	assert_true(gview.get_journal_panel().is_journal_open(), "JournalButton opens JournalPanel")
	assert_eq(gview.get_journal_panel().get_discovered_entry_count(), 3, "JournalPanel displays 3 discovered entries")
	gview.get_journal_panel().get_close_button().pressed.emit()
	assert_false(gview.get_journal_panel().is_journal_open(), "CloseButton closes JournalPanel")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_decoration_hud_picker_and_purchase_flow() -> void:
	describe("GardenView displays decoration status, opens DecorationPicker, and dispatches decoration purchases")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	var clock: FakeGameClock = FakeGameClock.new(2000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([0.05], [1, 2, 3, 4, 5, 6, 7, 8])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)
	var gview: GardenView = main_node.get_garden_view()

	assert_eq(gview.get_decoration_status_text(), "ของตกแต่งในสวน: ยังไม่มี", "Empty garden decoration status")
	assert_true(gview.is_decorating_enabled(), "Decorating enabled on active session")
	assert_false(gview.get_decoration_picker().is_picker_open(), "DecorationPicker closed initially")

	# Open DecorationPicker via DecorateButton and attempt purchase with 0 coins -> rejected with feedback
	gview.get_decorate_button().pressed.emit()
	assert_true(gview.get_decoration_picker().is_picker_open(), "DecorateButton opens DecorationPicker")
	assert_eq(gview.get_decoration_picker().get_available_decoration_ids().size(), 8, "8 decorations available")
	gview.get_decoration_picker().select_decoration_definition("decoration.clay_jar")
	gview.get_decoration_picker().confirm_purchase()
	assert_eq(repo.save_call_count, 0, "Rejected purchase with 0 coins does not save")
	assert_true(
		gview.get_feedback_text().contains("เหรียญไม่เพียงพอสำหรับการซื้อของตกแต่ง"),
		"Insufficient currency feedback displayed"
	)

	# Grant 20 coins and purchase decoration.clay_jar (price 15, trait "water")
	app.game_session.grant_currency(20)
	gview.refresh_from_session()
	var saves_before: int = repo.save_call_count
	gview.get_decorate_button().pressed.emit()
	gview.get_decoration_picker().select_decoration_definition("decoration.clay_jar")
	gview.get_decoration_picker().confirm_purchase()

	assert_eq(repo.save_call_count, saves_before + 1, "Purchasing decoration saves once")
	assert_eq(gview.get_currency_text(), "เหรียญ: 5", "HUD updated to 5 coins")
	assert_eq(
		gview.get_decoration_status_text(),
		"ของตกแต่งในสวน (1 ชิ้น): ตุ่มน้ำดินเผา (1)",
		"Decoration status shows clay jar"
	)
	assert_true(gview.get_environment_text().contains("แหล่งน้ำ"), "Environment HUD shows water trait from clay jar")
	assert_true(
		gview.get_feedback_text().contains("ซื้อและวางของตกแต่งสำเร็จ (-15 เหรียญ) และบันทึกเรียบร้อยแล้ว"),
		"Decoration purchase feedback displayed"
	)

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_atmosphere_hud_weather_time_events_and_background_tint() -> void:
	describe("GardenView displays Thai time period, weather state, active ambient events, and background tint")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	# t = 21600 -> hour 6 (morning), window 3 (clear)
	var clock: FakeGameClock = FakeGameClock.new(21600, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)
	var gview: GardenView = main_node.get_garden_view()

	# 1. Empty garden at morning + clear: calm (สงบเงียบ), morning background tint
	assert_eq(gview.get_current_time_period(), "morning", "Time period is morning at 21600s")
	assert_eq(gview.get_current_weather_state(), "clear", "Weather state is clear at 21600s")
	assert_eq(gview.get_eligible_event_ids().size(), 0, "No eligible events on empty garden")
	assert_eq(
		gview.get_atmosphere_text(),
		"บรรยากาศสวน: ยามเช้า | สภาพอากาศ: ท้องฟ้าแจ่มใส | เหตุการณ์ในสวน: สงบเงียบ",
		"Empty garden atmosphere text at morning clear"
	)
	var morning_clear_color: Color = gview.get_background_color()

	# 2. Plant Jasmine ("flower") -> triggers event.morning_butterflies (ฝูงผีเสื้อยามเช้า)
	gview.get_planting_picker().open_picker()
	gview.get_planting_picker().select_plant_definition("plant.jasmine")
	gview.get_planting_picker().confirm_planting()

	assert_eq(gview.get_eligible_event_ids(), ["event.morning_butterflies"], "Morning butterflies active")
	assert_eq(
		gview.get_atmosphere_text(),
		"บรรยากาศสวน: ยามเช้า | สภาพอากาศ: ท้องฟ้าแจ่มใส | เหตุการณ์ในสวน: ฝูงผีเสื้อยามเช้า",
		"Atmosphere HUD shows morning butterflies"
	)

	# 3. Advance clock to t = 14400 (hour 4 = night, window 2 = rain) -> background tint changes, morning butterflies inactive
	clock.set_utc_seconds(14400)
	gview.refresh_from_session()
	assert_eq(gview.get_current_time_period(), "night", "Time period is night at 14400s")
	assert_eq(gview.get_current_weather_state(), "rain", "Weather state is rain at 14400s")
	assert_eq(gview.get_eligible_event_ids().size(), 0, "Morning butterflies inactive at night rain")
	assert_eq(
		gview.get_atmosphere_text(),
		"บรรยากาศสวน: ยามค่ำคืน | สภาพอากาศ: ฝนตก | เหตุการณ์ในสวน: สงบเงียบ",
		"Atmosphere HUD updates to night rain calm"
	)
	var night_rain_color: Color = gview.get_background_color()
	assert_ne(morning_clear_color, night_rain_color, "Background tint shifts between morning clear and night rain")

	# 4. Blocked state hides AtmosphereLabel and resets background color
	gview.show_blocked_startup("ทดสอบบล็อก")
	assert_eq(gview.get_current_time_period(), "", "Blocked state clears snapshot time period")
	assert_eq(gview.get_current_weather_state(), "", "Blocked state clears snapshot weather state")
	assert_eq(gview.get_eligible_event_ids().size(), 0, "Blocked state clears eligible events")
	assert_eq(gview.get_background_color(), GardenView.DEFAULT_BACKGROUND_COLOR, "Blocked state resets background color")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_progression_and_gentle_guidance_hud() -> void:
	describe("GardenView displays progression stage, establishment score, and optional gentle guidance without extra clock sampling")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	var clock: CallCountingClock = CallCountingClock.new(2000)
	var rng: FakeRandomSource = FakeRandomSource.new([0.1], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)
	var gview: GardenView = main_node.get_garden_view()

	# 1. Empty garden -> starting_garden (0 pts), guidance.plant_first
	assert_eq(gview.get_current_progression_stage_id(), GardenProgressionStage.STAGE_STARTING_GARDEN, "Initial stage is starting_garden")
	assert_eq(gview.get_current_establishment_score(), 0, "Initial score is 0")
	assert_eq(gview.get_next_progression_stage_id(), GardenProgressionStage.STAGE_GROWING_GARDEN, "Next stage is growing_garden")
	assert_eq(gview.get_points_to_next_progression_stage(), 10, "10 points needed for growing_garden")
	assert_eq(gview.get_current_guidance_id(), GardenProgressionStage.GUIDANCE_PLANT_FIRST, "Initial guidance is plant_first")
	assert_eq(
		gview.get_progression_text(),
		"ระดับสวน: สวนเริ่มต้น (0 แต้ม, อีก 10 แต้มสู่สวนกำลังเติบโต) | วันนี้ทำอะไรดี: ลองปลูกต้นไม้ต้นแรกในสวน",
		"Empty garden progression HUD text"
	)
	assert_true(gview.has_daily_guidance(), "Daily guidance is active on valid session")
	assert_eq(gview.get_daily_guidance_count(), 3, "Daily guidance has 3 suggestions")
	assert_eq(gview.get_daily_guidance_ids().size(), 3, "get_daily_guidance_ids returns 3 items")
	assert_eq(gview.get_daily_guidance_display_texts().size(), 3, "get_daily_guidance_display_texts returns 3 items")
	assert_true(gview.get_daily_guidance_label().visible, "DailyGuidanceLabel visible on active session")
	assert_true(gview.get_daily_guidance_text().begins_with("กิจกรรมแนะนำวันนี้: "), "Daily guidance text begins with prefix")
	assert_true(gview.get_daily_guidance_item(0) != null, "Daily guidance item 0 is present")
	assert_true(gview.get_daily_guidance_item(3) == null, "Daily guidance item index out of bounds is null")

	# Verify refresh_from_session still samples clock only once even with progression evaluation
	var calls_before: int = clock.utc_call_count
	gview.refresh_from_session()
	assert_eq(clock.utc_call_count, calls_before + 1, "Refresh samples clock once including progression evaluation")

	# 2. Plant jasmine -> growing_garden (14 pts), guidance.observe_visitor
	gview.get_planting_picker().open_picker()
	gview.get_planting_picker().select_plant_definition("plant.jasmine")
	gview.get_planting_picker().confirm_planting()

	assert_eq(gview.get_current_progression_stage_id(), GardenProgressionStage.STAGE_GROWING_GARDEN, "Stage updates to growing_garden")
	assert_eq(gview.get_current_establishment_score(), 14, "Score updates to 14")
	assert_eq(gview.get_next_progression_stage_id(), GardenProgressionStage.STAGE_SHADY_GARDEN, "Next stage is shady_garden")
	assert_eq(gview.get_points_to_next_progression_stage(), 11, "11 points needed for shady_garden")
	assert_eq(gview.get_current_guidance_id(), GardenProgressionStage.GUIDANCE_OBSERVE_VISITOR, "Guidance updates to observe_visitor")
	assert_eq(
		gview.get_progression_text(),
		"ระดับสวน: สวนกำลังเติบโต (14 แต้ม, อีก 11 แต้มสู่สวนร่มรื่น) | วันนี้ทำอะไรดี: ลองสำรวจผู้มาเยือนที่แวะมาในสวน",
		"Growing garden progression HUD text"
	)

	# 3. Observe visitor -> discovers butterfly (+5 pts -> 19 pts), guidance.place_decoration
	gview.get_observe_visitor_button().pressed.emit()
	assert_eq(gview.get_current_establishment_score(), 19, "Score updates to 19 after visitor discovery")
	assert_eq(gview.get_points_to_next_progression_stage(), 6, "6 points needed for shady_garden")
	assert_eq(gview.get_current_guidance_id(), GardenProgressionStage.GUIDANCE_PLACE_DECORATION, "Guidance updates to place_decoration")
	assert_eq(
		gview.get_progression_text(),
		"ระดับสวน: สวนกำลังเติบโต (19 แต้ม, อีก 6 แต้มสู่สวนร่มรื่น) | วันนี้ทำอะไรดี: ลองเก็บเกี่ยวเหรียญและวางของตกแต่งชิ้นแรก",
		"Progression HUD suggests placing decoration"
	)

	# 4. Blocked state clears progression summary and hides ProgressionLabel
	gview.show_blocked_startup("ทดสอบบล็อก")
	assert_eq(gview.get_current_progression_stage_id(), "", "Blocked state clears progression stage ID")
	assert_eq(gview.get_current_establishment_score(), 0, "Blocked state clears establishment score")
	assert_eq(gview.get_next_progression_stage_id(), "", "Blocked state clears next progression stage ID")
	assert_eq(gview.get_points_to_next_progression_stage(), 0, "Blocked state clears points to next stage")
	assert_eq(gview.get_current_guidance_id(), "", "Blocked state clears guidance ID")
	assert_true(gview.get_last_progression_summary() == null, "Blocked state clears progression summary")
	assert_false(gview.get_progression_label().visible, "ProgressionLabel hidden when startup is blocked")
	assert_false(gview.has_daily_guidance(), "Blocked state clears daily guidance")
	assert_eq(gview.get_daily_guidance_count(), 0, "Blocked state has 0 daily guidance")
	assert_false(gview.get_daily_guidance_label().visible, "DailyGuidanceLabel hidden when startup is blocked")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_return_summary_and_resume_feedback() -> void:
	describe("GardenView tracks away-time GardenReturnSummary on refresh and MainScreen shows calm return feedback on resume")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	var clock: CallCountingClock = CallCountingClock.new(1000) # night, clear
	var rng: FakeRandomSource = FakeRandomSource.new([0.1], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)
	var gview: GardenView = main_node.get_garden_view()

	# First refresh after bind_garden records baseline timestamp without a return summary
	assert_true(gview.has_refresh_timestamp(), "Baseline refresh timestamp recorded")
	assert_eq(gview.get_last_refresh_utc_seconds(), 1000, "Baseline timestamp is 1000")
	assert_true(gview.get_last_return_summary() == null, "Initial refresh has no prior timestamp for return summary")

	# Plant holy_basil at t = 1000 (sprout=60, growing=180, mature=600 in production catalog)
	gview.get_planting_picker().open_picker()
	gview.get_planting_picker().select_plant_definition("plant.holy_basil")
	gview.get_planting_picker().confirm_planting()

	# Simulate pause -> advance +180s (t = 1180 -> GROWING) -> resume
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	clock.set_utc_seconds(1180)
	var clock_calls_before_resume_1: int = clock.utc_call_count
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(clock.utc_call_count, clock_calls_before_resume_1 + 1, "Resume still samples clock exactly once")

	var sum1: GardenReturnSummary = gview.get_last_return_summary()
	assert_true(sum1 != null and sum1.is_valid(), "Return summary computed on resume")
	assert_eq(sum1.get_elapsed_seconds(), 180, "Elapsed 180s")
	assert_eq(sum1.get_advanced_plant_count(), 1, "1 plant advanced to GROWING")
	assert_eq(sum1.get_newly_matured_plant_count(), 0, "0 newly matured")
	assert_true(sum1.has_meaningful_changes(), "Plant growth is a meaningful change")
	assert_true(gview.is_feedback_visible(), "Feedback visible on resume with meaningful changes")
	assert_eq(
		gview.get_feedback_text(),
		"ต้นไม้ในสวนเติบโตขึ้นระหว่างที่คุณไม่อยู่ (1 ต้น)",
		"Return feedback reports 1 plant grew"
	)

	# Simulate pause -> advance to t = 21600 (morning, clear; basil MATURE) -> resume
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	clock.set_utc_seconds(21600)
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	var sum2: GardenReturnSummary = gview.get_last_return_summary()
	assert_true(sum2 != null and sum2.is_valid(), "Return summary 2 valid")
	assert_eq(sum2.get_newly_matured_plant_count(), 1, "1 plant newly matured")
	assert_eq(sum2.get_ready_to_harvest_count(), 1, "1 plant ready to harvest")
	assert_true(sum2.has_time_period_changed(), "Time period changed night -> morning")
	assert_eq(
		gview.get_feedback_text(),
		"ต้นไม้ในสวนเติบโตขึ้นระหว่างที่คุณไม่อยู่ (เติบโต 1 ต้น, พร้อมเก็บเกี่ยว 1 ต้น)",
		"Return feedback reports newly matured plant and ready count"
	)

	# Simulate pause -> advance to t = 43200 (day, cloudy; basil already MATURE so atmosphere-only change) -> resume
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	clock.set_utc_seconds(43200)
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	var sum3: GardenReturnSummary = gview.get_last_return_summary()
	assert_true(sum3 != null and sum3.is_valid(), "Return summary 3 valid")
	assert_false(sum3.has_plant_growth_changes(), "No new plant stage changes at t=43200")
	assert_true(sum3.has_atmosphere_changes(), "Atmosphere changed morning/clear -> day/cloudy")
	assert_eq(
		gview.get_feedback_text(),
		"บรรยากาศในสวนเปลี่ยนไประหว่างที่คุณไม่อยู่ (กลางวัน, มีเมฆมาก)",
		"Return feedback reports atmosphere-only change"
	)

	# Simulate pause -> clock rollback to t = 20000 -> resume (must not overwrite feedback or report false growth)
	var prev_feedback: String = gview.get_feedback_text()
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	clock.set_utc_seconds(20000)
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	var sum_rb: GardenReturnSummary = gview.get_last_return_summary()
	assert_true(sum_rb != null and sum_rb.was_clock_rolled_back(), "Clock rollback detected")
	assert_false(sum_rb.has_meaningful_changes(), "Clock rollback suppresses meaningful changes")
	assert_eq(gview.get_feedback_text(), prev_feedback, "No false return feedback shown on clock rollback")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_ambient_event_observation_button_and_feedback() -> void:
	describe("ObserveEventButton enables only when ambient events are eligible, dispatches evaluate_event_now with zero disk writes, and updates JournalPanel")
	_cleanup_presentation_test_files()

	var repo: CountingSaveRepo = CountingSaveRepo.new()
	# t = 21600 -> hour 6 (morning), window 3 (clear)
	var clock: FakeGameClock = FakeGameClock.new(21600, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([0.1, 0.8], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_node: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
	main_node._ready()
	main_node.bind_app_root(app)
	var gview: GardenView = main_node.get_garden_view()

	# 1. Empty garden: ObserveEventButton exists and is disabled
	assert_true(gview.get_observe_event_button() != null, "ObserveEventButton exists")
	assert_false(gview.is_observe_event_button_enabled(), "ObserveEventButton disabled on empty garden")
	assert_eq(gview.get_current_event_id(), "", "No active event ID initially")
	assert_eq(gview.get_journal_panel().get_total_decoration_entry_count(), 8, "JournalPanel has 8 decorations")
	assert_eq(gview.get_journal_panel().get_total_event_entry_count(), 6, "JournalPanel has 6 events (5 ambient + 1 secret)")
	assert_eq(gview.get_journal_panel().get_active_event_entry_count(), 0, "JournalPanel has 0 active events on empty garden")

	# 2. Plant Jasmine -> morning_butterflies becomes eligible, ObserveEventButton enabled, JournalPanel updates
	gview.get_planting_picker().open_picker()
	gview.get_planting_picker().select_plant_definition("plant.jasmine")
	gview.get_planting_picker().confirm_planting()

	assert_true(gview.is_observe_event_button_enabled(), "ObserveEventButton enabled when morning_butterflies eligible")
	assert_eq(gview.get_journal_panel().get_active_event_entry_count(), 1, "JournalPanel shows 1 active event")
	assert_true(
		gview.get_journal_panel().get_entry_text_for_id("event.morning_butterflies").contains("[เกิดขึ้นได้ในสวน]"),
		"JournalPanel marks morning_butterflies as active"
	)

	# 3. Press ObserveEventButton -> selects event.morning_butterflies, shows Thai flavor description, zero disk writes
	var saves_before_event: int = repo.save_call_count
	gview.get_observe_event_button().pressed.emit()
	assert_eq(repo.save_call_count, saves_before_event, "Observing ambient event performs zero disk writes")
	assert_eq(gview.get_current_event_id(), "event.morning_butterflies", "Current event ID set to morning_butterflies")
	assert_true(
		gview.get_last_event_selection_result() != null and gview.get_last_event_selection_result().is_selected(),
		"Last EventSelectionResult is SELECTED"
	)
	assert_true(
		gview.get_feedback_text().contains("ชมเหตุการณ์ในสวน: ฝูงผีเสื้อยามเช้า (event.morning_butterflies)"),
		"Feedback displays event title and ID"
	)
	assert_true(
		gview.get_feedback_text().contains("ฝูงผีเสื้อโบยบินวนเวียนตอมดอกไม้ในแสงแดดอ่อน"),
		"Feedback displays event flavor description"
	)

	# 4. Shift time to t = 14400 (night, rain) -> morning_butterflies no longer eligible, button disabled, current_event_id cleared
	clock.set_utc_seconds(14400)
	gview.refresh_from_session()
	assert_false(gview.is_observe_event_button_enabled(), "ObserveEventButton disabled when no events eligible at night rain")
	assert_eq(gview.get_current_event_id(), "", "Current event ID cleared when no longer eligible")
	assert_eq(gview.get_journal_panel().get_active_event_entry_count(), 0, "JournalPanel active event count returns to 0")

	# 5. Direct show_event_result for NO_ELIGIBLE_EVENTS and INVALID_INPUT
	gview.show_event_result(EventSelectionResult.no_eligible_events(gview.get_last_garden_snapshot()))
	assert_eq(gview.get_feedback_text(), "ยังไม่มีเหตุการณ์พิเศษที่เกิดขึ้นในสวนขณะนี้", "NO_ELIGIBLE_EVENTS feedback")
	gview.show_event_result(EventSelectionResult.invalid_input())
	assert_eq(gview.get_feedback_text(), "ระบบยังไม่พร้อมสำหรับการชมเหตุการณ์ในสวน", "INVALID_INPUT feedback")

	# 6. Blocked state disables ObserveEventButton
	gview.show_blocked_startup("ทดสอบบล็อก")
	assert_false(gview.is_observe_event_button_enabled(), "ObserveEventButton disabled when blocked")

	main_node.free()
	app.free()
	_cleanup_presentation_test_files()


func _test_selected_plant_growth_countdown_and_atmosphere_forecast() -> void:
	describe("GardenView computes deterministic plant growth countdowns and atmosphere transition forecasts from a single clock sample")
	var view: GardenView = _instantiate_garden_view()
	var state: GameState = GameState.new()
	# Basil in test catalog: sprout=60, growing=180, mature=300
	state.get_plants().try_add_plant(PlantState.new("basil-cd", "plant.holy_basil", 21600))
	var session: GameSession = GameSession.new(state)
	var catalog: ContentCatalog = _create_test_catalog()
	catalog.get_plant("plant.holy_basil").environmental_traits = ["dense_vegetation", "food"]
	var clock: CallCountingClock = CallCountingClock.new(21610) # elapsed = 10s (PLANTED); morning (21600..39599), window 3 (21600..28799)

	view.bind_garden(session, catalog, clock)

	# 1. Before selection: plant countdown queries return -1, atmosphere forecast is populated
	assert_eq(view.get_selected_plant_definition_id(), "", "No plant selected -> empty definition ID")
	assert_eq(view.get_selected_plant_stage(), PlantGrowth.Stage.INVALID, "No plant selected -> INVALID stage")
	assert_eq(view.get_selected_plant_seconds_until_next_stage(), -1, "No plant selected -> -1s until next stage")
	assert_eq(view.get_selected_plant_seconds_until_mature(), -1, "No plant selected -> -1s until mature")
	assert_eq(view.get_selected_plant_traits(), [], "No plant selected -> empty traits")
	assert_eq(view.get_selected_plant_harvest_reward(), 0, "No plant selected -> 0 harvest reward")
	assert_eq(view.get_selected_plant_planted_at(), -1, "No plant selected -> -1 planted_at")
	assert_eq(view.get_growing_plant_ids(), ["basil-cd"], "PLANTED basil is included in growing_plant_ids")
	assert_eq(view.get_growing_plant_count(), 1, "1 growing plant at PLANTED")
	assert_eq(view.get_minimum_seconds_until_next_stage_transition(), 50, "Minimum seconds until next stage transition is 50s at PLANTED")
	assert_eq(view.get_minimum_seconds_until_next_harvest(), 290, "Minimum seconds until next harvest is 290s at PLANTED")
	assert_eq(view.get_present_plant_definition_ids(), ["plant.holy_basil"], "Present plant definition IDs include basil")
	assert_eq(view.get_planted_count_for_id("plant.holy_basil"), 1, "Planted count for basil is 1")
	assert_eq(view.get_plant_ids_for_definition_id("plant.holy_basil"), ["basil-cd"], "Plant IDs for plant.holy_basil")
	assert_eq(view.get_plant_ids_for_definition_id("plant.jasmine"), [], "No plant IDs for unplanted jasmine")
	assert_eq(view.get_distinct_planted_species_count(), 1, "1 distinct planted species")
	assert_eq(view.get_distinct_placed_decoration_species_count(), 0, "0 distinct placed decoration species")
	assert_eq(view.get_discovered_entry_count_in_garden(), 0, "0 discovered entries before journal sighting")
	assert_eq(view.get_undiscovered_entry_count_in_garden(), 5, "5 undiscovered entries in test catalog before sighting")
	assert_false(view.is_all_journal_entries_discovered_in_garden(), "Not all journal entries discovered in garden")
	assert_false(view.is_at_max_progression_stage(), "Not at max progression stage")
	assert_eq(view.get_plant_ids_with_environmental_trait("dense_vegetation"), ["basil-cd"], "Plant IDs with dense_vegetation trait")
	assert_eq(view.get_plant_count_with_environmental_trait("dense_vegetation"), 1, "1 plant with dense_vegetation trait")
	assert_eq(view.get_plant_ids_with_environmental_trait("flower"), [], "0 plants with flower trait")
	assert_eq(view.get_plant_count_with_environmental_trait("flower"), 0, "0 plant count with flower trait")
	assert_eq(view.get_eligible_visitor_count(), 0, "0 eligible visitors in test catalog")
	assert_eq(view.get_eligible_event_count(), 0, "0 eligible events in test catalog")
	assert_false(view.has_selected_plant(), "No plant selected initially")
	assert_false(view.is_selected_plant_ready_to_harvest(), "Selected plant not ready to harvest initially")
	assert_true(view.has_active_environmental_trait("dense_vegetation"), "Has active dense_vegetation trait")
	assert_false(view.has_active_environmental_trait("flower"), "Does not have active flower trait")
	assert_eq(view.get_active_environmental_trait_count(), 2, "2 active environmental traits (dense_vegetation, food)")
	assert_true(view.is_plant_definition_present_in_garden("plant.holy_basil"), "plant.holy_basil is present in garden")
	assert_false(view.is_plant_definition_present_in_garden("plant.jasmine"), "plant.jasmine is not present in garden")
	assert_false(view.is_decoration_definition_present_in_garden("decoration.bench"), "decoration.bench is not present in garden")
	assert_false(view.is_visitor_currently_eligible("visitor.butterfly"), "visitor.butterfly is not eligible in test catalog")
	assert_false(view.is_event_currently_eligible("event.morning_butterflies"), "event.morning_butterflies is not eligible in test catalog")
	assert_true(view.has_any_planted_plants_in_garden(), "Has planted plants in garden")
	assert_true(view.has_any_growing_plants_in_garden(), "Has growing plants in garden at PLANTED")
	assert_false(view.has_any_ready_to_harvest_plants_in_garden(), "No ready to harvest plants at PLANTED")
	assert_false(view.has_any_placed_decorations_in_garden(), "No placed decorations in garden")
	assert_true(view.has_any_active_environmental_traits_in_garden(), "Has active environmental traits in garden")
	assert_false(view.has_any_eligible_visitors_in_garden(), "No eligible visitors in test catalog")
	assert_false(view.has_any_eligible_events_in_garden(), "No eligible events in test catalog")
	assert_false(view.has_selected_plant_environmental_trait("dense_vegetation"), "No selected plant -> false for trait check")
	assert_false(view.is_selected_plant_growing(), "No selected plant -> false for is_selected_plant_growing()")
	assert_eq(view.get_selected_plant_trait_count(), 0, "No selected plant -> 0 trait count")
	assert_false(view.has_selected_plant_any_environmental_traits(), "No selected plant -> false for has_selected_plant_any_environmental_traits()")
	assert_false(view.is_all_planted_plants_ready_to_harvest_in_garden(), "Not all planted plants ready to harvest at PLANTED")
	assert_false(view.has_any_discovered_entries_in_garden(), "No discovered entries in garden before sighting")
	assert_true(view.has_any_undiscovered_entries_in_garden(), "Has undiscovered entries in garden before sighting")
	assert_false(view.has_active_visitor_in_garden(), "No active visitor in garden initially")
	assert_false(view.has_active_event_in_garden(), "No active event in garden initially")
	assert_true(view.has_bound_session(), "GameSession is bound in garden")
	assert_true(view.has_bound_catalog(), "ContentCatalog is bound in garden")
	assert_true(view.has_bound_clock(), "GameClock is bound in garden")
	assert_true(view.has_last_garden_snapshot(), "GardenSnapshot is present after refresh")
	assert_true(view.has_last_progression_summary(), "GardenProgressionSummary is present after refresh")
	assert_false(view.has_last_return_summary(), "GardenReturnSummary is absent before show_return_summary")
	assert_false(view.is_planting_picker_open_in_garden(), "PlantingPicker is closed initially")
	assert_false(view.is_decoration_picker_open_in_garden(), "DecorationPicker is closed initially")
	assert_false(view.is_journal_open_in_garden(), "JournalPanel is closed initially")
	assert_false(view.is_any_modal_open_in_garden(), "No modal is open initially")
	assert_false(view.has_last_planting_checkpoint_result(), "No planting checkpoint result initially")
	assert_false(view.has_last_harvest_checkpoint_result(), "No harvest checkpoint result initially")
	assert_false(view.has_last_visitor_selection_result(), "No visitor selection result initially")
	assert_false(view.has_last_visitor_observation_checkpoint_result(), "No visitor observation checkpoint result initially")
	assert_false(view.has_last_event_selection_result(), "No event selection result initially")
	assert_false(view.has_last_decoration_purchase_checkpoint_result(), "No decoration purchase checkpoint result initially")
	assert_eq(view.get_selected_plant_display_name(), "", "No selected plant display name initially")
	assert_eq(view.get_current_visitor_display_name(), "", "No active visitor display name initially")
	assert_eq(view.get_current_event_display_name(), "", "No active event display name initially")
	assert_eq(view.get_current_event_description(), "", "No active event description initially")
	assert_eq(view.get_current_time_period_display_name(), "ยามเช้า", "Current time period display name at 21610s is ยามเช้า")
	assert_eq(view.get_current_weather_display_name(), "ท้องฟ้าแจ่มใส", "Current weather display name at 21610s is ท้องฟ้าแจ่มใส")
	assert_eq(view.get_next_time_period_display_name(), "กลางวัน", "Next time period display name at 21610s is กลางวัน")
	assert_eq(view.get_next_weather_display_name(), "มีเมฆมาก", "Next weather display name at 21610s is มีเมฆมาก")
	assert_eq(view.get_current_progression_stage_display_name(), "สวนเริ่มต้น", "Current progression stage display name is สวนเริ่มต้น")
	assert_eq(view.get_next_progression_stage_display_name(), "สวนกำลังเติบโต", "Next progression stage display name is สวนกำลังเติบโต")
	assert_eq(view.get_current_guidance_display_name(), "ลองสำรวจผู้มาเยือนที่แวะมาในสวน", "Current guidance display name matches guidance.observe_visitor")
	assert_false(view.is_selected_plant_planted_stage(), "No selected plant -> is_selected_plant_planted_stage() is false")
	assert_false(view.is_selected_plant_sprout_stage(), "No selected plant -> is_selected_plant_sprout_stage() is false")
	assert_false(view.is_selected_plant_growing_phase_stage(), "No selected plant -> is_selected_plant_growing_phase_stage() is false")
	assert_false(view.is_selected_plant_mature_stage(), "No selected plant -> is_selected_plant_mature_stage() is false")
	assert_eq(view.get_trait_display_name_for_id("dense_vegetation"), "พุ่มไม้หนาแน่น", "GardenView trait display name for dense_vegetation")
	assert_eq(view.get_trait_display_name_for_id(""), "", "GardenView trait display name for empty string is empty")
	assert_eq(view.get_visitor_display_name_for_id("visitor.butterfly"), "ผีเสื้อบ้านสวน", "GardenView visitor display name for butterfly")
	assert_eq(view.get_visitor_display_name_for_id(""), "", "GardenView visitor display name for empty string is empty")
	assert_eq(view.get_event_display_name_for_id("event.morning_butterflies"), "ฝูงผีเสื้อยามเช้า", "GardenView event display name for morning_butterflies")
	assert_eq(view.get_event_display_name_for_id(""), "", "GardenView event display name for empty string is empty")
	assert_eq(
		view.get_event_description_for_id("event.morning_butterflies"),
		"ฝูงผีเสื้อโบยบินวนเวียนตอมดอกไม้ในแสงแดดอ่อน",
		"GardenView event description for morning_butterflies"
	)
	assert_eq(view.get_event_description_for_id("event.unknown"), "", "GardenView event description for unknown event is empty")
	assert_eq(view.get_time_period_display_name_for_id("morning"), "ยามเช้า", "GardenView time period display name for morning")
	assert_eq(view.get_weather_display_name_for_id("clear"), "ท้องฟ้าแจ่มใส", "GardenView weather display name for clear")
	assert_eq(view.get_progression_stage_display_name_for_id("starting_garden"), "สวนเริ่มต้น", "GardenView progression stage display name for starting_garden")
	assert_eq(view.get_guidance_display_name_for_id("guidance.plant_first"), "ลองปลูกต้นไม้ต้นแรกในสวน", "GardenView guidance display name for guidance.plant_first")
	assert_eq(
		view.get_active_environmental_trait_display_names(),
		["พุ่มไม้หนาแน่น", "พืชอาหาร"],
		"Active environmental trait display names in garden"
	)
	assert_eq(view.get_selected_plant_trait_display_names(), [], "No selected plant -> empty selected plant trait display names")
	assert_eq(view.get_eligible_visitor_display_names(), [], "No eligible visitors for basil alone -> empty eligible visitor display names")
	assert_eq(view.get_eligible_event_display_names(), [], "No eligible events for basil alone -> empty eligible event display names")
	assert_eq(view.get_present_plant_display_names(), ["กะเพรา"], "Present plant display names in garden return [กะเพรา]")
	assert_eq(view.get_present_decoration_display_names(), [], "No placed decorations -> empty present decoration display names")
	assert_eq(view.get_plant_display_name_for_id("plant.holy_basil"), "กะเพรา", "GardenView plant display name for holy_basil")
	assert_eq(view.get_plant_display_name_for_id(""), "", "GardenView plant display name for empty string is empty")
	assert_eq(view.get_decoration_display_name_for_id("decoration.bench"), "ม้านั่งไม้ในสวน", "GardenView decoration display name for bench")
	assert_eq(view.get_decoration_display_name_for_id(""), "", "GardenView decoration display name for empty string is empty")
	assert_eq(view.get_selected_plant_stage_display_name(), "", "No selected plant -> empty selected plant stage display name")
	assert_true(view.is_known_visitor_id("visitor.butterfly"), "visitor.butterfly is a known visitor ID")
	assert_false(view.is_known_visitor_id("visitor.unknown"), "visitor.unknown is not a known visitor ID")
	assert_true(view.is_known_event_id("event.morning_butterflies"), "event.morning_butterflies is a known event ID")
	assert_false(view.is_known_event_id("event.unknown"), "event.unknown is not a known event ID")
	assert_true(view.is_known_environmental_trait("dense_vegetation"), "dense_vegetation is a known environmental trait in GardenView")
	assert_false(view.is_known_environmental_trait("unknown_trait"), "unknown_trait is not a known environmental trait in GardenView")
	assert_true(view.is_known_time_period_id("morning"), "morning is a known time period ID")
	assert_false(view.is_known_time_period_id("unknown_period"), "unknown_period is not a known time period ID")
	assert_true(view.is_known_weather_state_id("clear"), "clear is a known weather state ID")
	assert_false(view.is_known_weather_state_id("unknown_weather"), "unknown_weather is not a known weather state ID")
	assert_true(view.is_known_progression_stage_id("starting_garden"), "starting_garden is a known progression stage ID")
	assert_false(view.is_known_progression_stage_id("unknown_stage"), "unknown_stage is not a known progression stage ID")
	assert_true(view.is_known_guidance_id("guidance.plant_first"), "guidance.plant_first is a known guidance ID")
	assert_false(view.is_known_guidance_id("guidance.unknown"), "guidance.unknown is not a known guidance ID")
	assert_true(view.is_known_plant_definition_id("plant.holy_basil"), "plant.holy_basil is a known plant definition ID in GardenView")
	assert_false(view.is_known_plant_definition_id("plant.unknown"), "plant.unknown is not a known plant definition ID in GardenView")
	assert_true(view.is_known_decoration_definition_id("decoration.bench"), "decoration.bench is a known decoration definition ID in GardenView")
	assert_false(view.is_known_decoration_definition_id("decoration.unknown"), "decoration.unknown is not a known decoration definition ID in GardenView")
	assert_true(view.has_plant_in_garden_catalog("plant.holy_basil"), "plant.holy_basil exists in garden catalog")
	assert_false(view.has_plant_in_garden_catalog("plant.unknown"), "plant.unknown does not exist in garden catalog")
	assert_false(view.has_visitor_in_garden_catalog("visitor.unknown"), "visitor.unknown does not exist in garden catalog")
	assert_false(view.has_decoration_in_garden_catalog("decoration.unknown"), "decoration.unknown does not exist in garden catalog")
	assert_false(view.has_event_in_garden_catalog("event.unknown"), "event.unknown does not exist in garden catalog")
	assert_eq(view.get_selected_plant_stage_accent_color(), PlantView.STAGE_ACCENT_INVALID, "No selected plant -> STAGE_ACCENT_INVALID")
	assert_false(view.has_selected_plant_countdown_to_mature(), "No selected plant -> false for has_selected_plant_countdown_to_mature()")
	assert_false(view.has_selected_plant_countdown_to_next_stage(), "No selected plant -> false for has_selected_plant_countdown_to_next_stage()")
	assert_false(view.has_selected_plant_harvest_reward(), "No selected plant -> false for has_selected_plant_harvest_reward()")
	assert_eq(view.get_total_catalog_plant_count_in_garden(), 5, "5 plant definitions in test garden catalog")
	assert_eq(view.get_total_catalog_visitor_count_in_garden(), 0, "0 visitor definitions in plant-only test catalog")
	assert_eq(view.get_total_catalog_decoration_count_in_garden(), 0, "0 decoration definitions in plant-only test catalog")
	assert_eq(view.get_total_catalog_event_count_in_garden(), 0, "0 event definitions in plant-only test catalog")
	assert_eq(
		view.get_all_catalog_plant_ids_in_garden(),
		["plant.banana", "plant.chili", "plant.holy_basil", "plant.jasmine", "plant.marigold"],
		"All catalog plant IDs in garden"
	)
	assert_eq(view.get_all_catalog_visitor_ids_in_garden(), [], "Empty catalog visitor IDs in plant-only test catalog")
	assert_eq(view.get_all_catalog_decoration_ids_in_garden(), [], "Empty catalog decoration IDs in plant-only test catalog")
	assert_eq(view.get_all_catalog_event_ids_in_garden(), [], "Empty catalog event IDs in plant-only test catalog")
	assert_false(view.is_all_catalog_plant_species_present_in_garden(), "Only 1 of 5 plant species present in garden")
	assert_false(view.is_all_catalog_decoration_species_present_in_garden(), "0 catalog decorations -> false for is_all_catalog_decoration_species_present_in_garden()")
	assert_eq(
		view.get_all_catalog_plant_display_names_in_garden(),
		["กล้วย", "พริก", "กะเพรา", "มะลิ", "ดาวเรือง"],
		"All catalog plant display names in garden"
	)
	assert_eq(view.get_all_catalog_visitor_display_names_in_garden(), [], "Empty catalog visitor display names in plant-only test catalog")
	assert_eq(view.get_all_catalog_decoration_display_names_in_garden(), [], "Empty catalog decoration display names in plant-only test catalog")
	assert_eq(view.get_all_catalog_event_display_names_in_garden(), [], "Empty catalog event display names in plant-only test catalog")
	assert_eq(
		view.get_unplanted_catalog_plant_ids_in_garden(),
		["plant.banana", "plant.chili", "plant.jasmine", "plant.marigold"],
		"Unplanted catalog plant IDs in garden"
	)
	assert_eq(view.get_unplaced_catalog_decoration_ids_in_garden(), [], "Empty unplaced catalog decoration IDs in plant-only test catalog")
	assert_eq(view.get_unplanted_catalog_plant_count_in_garden(), 4, "4 unplanted catalog plant species in garden")
	assert_eq(view.get_unplaced_catalog_decoration_count_in_garden(), 0, "0 unplaced catalog decoration species in plant-only test catalog")
	assert_true(view.has_any_unplanted_catalog_plants_in_garden(), "Has unplanted catalog plants in garden (4/5)")
	assert_false(view.has_any_unplaced_catalog_decorations_in_garden(), "No unplaced catalog decorations in plant-only test catalog")
	assert_eq(
		view.get_unplanted_catalog_plant_display_names_in_garden(),
		["กล้วย", "พริก", "มะลิ", "ดาวเรือง"],
		"Unplanted catalog plant display names in garden"
	)
	assert_eq(view.get_unplaced_catalog_decoration_display_names_in_garden(), [], "Empty unplaced catalog decoration display names in plant-only test catalog")
	assert_eq(view.get_ineligible_catalog_visitor_ids_in_garden(), [], "Empty ineligible catalog visitor IDs in plant-only test catalog")
	assert_eq(view.get_ineligible_catalog_event_ids_in_garden(), [], "Empty ineligible catalog event IDs in plant-only test catalog")
	assert_eq(view.get_ineligible_catalog_visitor_count_in_garden(), 0, "0 ineligible catalog visitors in plant-only test catalog")
	assert_eq(view.get_ineligible_catalog_event_count_in_garden(), 0, "0 ineligible catalog events in plant-only test catalog")
	assert_false(view.has_any_ineligible_catalog_visitors_in_garden(), "No ineligible catalog visitors in plant-only test catalog")
	assert_false(view.has_any_ineligible_catalog_events_in_garden(), "No ineligible catalog events in plant-only test catalog")
	assert_eq(view.get_ineligible_catalog_visitor_display_names_in_garden(), [], "Empty ineligible catalog visitor display names in plant-only test catalog")
	assert_eq(view.get_ineligible_catalog_event_display_names_in_garden(), [], "Empty ineligible catalog event display names in plant-only test catalog")
	view.open_planting_picker()
	assert_true(view.is_planting_picker_open_in_garden(), "PlantingPicker is open after open_planting_picker()")
	assert_true(view.is_any_modal_open_in_garden(), "is_any_modal_open_in_garden() is true when PlantingPicker is open")
	view.close_planting_picker()
	assert_false(view.is_planting_picker_open_in_garden(), "PlantingPicker is closed after close_planting_picker()")
	assert_false(view.is_any_modal_open_in_garden(), "is_any_modal_open_in_garden() is false after closing PlantingPicker")
	view.open_decoration_picker()
	assert_true(view.is_decoration_picker_open_in_garden(), "DecorationPicker is open after open_decoration_picker()")
	assert_true(view.is_any_modal_open_in_garden(), "is_any_modal_open_in_garden() is true when DecorationPicker is open")
	view.close_decoration_picker()
	assert_false(view.is_decoration_picker_open_in_garden(), "DecorationPicker is closed after close_decoration_picker()")
	view.open_journal_panel()
	assert_true(view.is_journal_open_in_garden(), "JournalPanel is open after open_journal_panel()")
	assert_true(view.is_any_modal_open_in_garden(), "is_any_modal_open_in_garden() is true when JournalPanel is open")
	view.close_journal_panel()
	assert_false(view.is_journal_open_in_garden(), "JournalPanel is closed after close_journal_panel()")
	assert_eq(view.get_plant_ids_for_stage(PlantGrowth.Stage.PLANTED), ["basil-cd"], "Plant IDs for PLANTED stage")
	assert_eq(view.get_plant_count_for_stage(PlantGrowth.Stage.PLANTED), 1, "1 plant at PLANTED stage")
	assert_eq(view.get_plant_count_for_stage(PlantGrowth.Stage.MATURE), 0, "0 plants at MATURE stage")
	assert_eq(view.get_active_environmental_traits(), ["dense_vegetation", "food"], "Active environmental traits include dense_vegetation and food")
	assert_eq(view.get_environmental_trait_count("dense_vegetation"), 1, "Trait count for dense_vegetation is 1")
	assert_eq(view.get_present_decoration_definition_ids(), [], "No placed decorations in garden")
	assert_eq(view.get_placed_decoration_count_for_id("decoration.bench"), 0, "0 benches placed")
	assert_eq(view.get_ready_to_harvest_plant_ids(), [], "No mature plants -> empty ready IDs")
	assert_eq(view.get_total_pending_harvest_reward(), 0, "No mature plants -> 0 pending harvest reward")
	assert_eq(view.get_planting_picker().get_planted_count_for_id("plant.holy_basil"), 1, "PlantingPicker receives basil planted count = 1")
	assert_false(view.get_planting_picker().is_plant_discovered("plant.holy_basil"), "Basil added directly to PlantCollectionState without journal sighting is undiscovered")
	state.get_journal().try_record_sighting("plant.holy_basil", 21600)
	view.refresh_from_session()
	assert_eq(view.get_discovered_entry_count_in_garden(), 1, "1 discovered entry in garden after basil sighting")
	assert_true(view.has_any_discovered_entries_in_garden(), "Has discovered entries in garden after basil sighting")
	assert_true(view.has_any_undiscovered_entries_in_garden(), "Still has undiscovered entries in garden (4/5)")
	assert_true(view.get_planting_picker().is_plant_discovered("plant.holy_basil"), "PlantingPicker reflects journal discovery after refresh")
	assert_false(view.get_planting_picker().is_plant_discovered("plant.jasmine"), "Unplanted jasmine remains undiscovered in PlantingPicker")
	assert_eq(view.get_decoration_picker().get_available_currency(), 0, "DecorationPicker receives initial currency = 0")
	assert_eq(view.get_next_time_period(), "day", "At 21610s (morning): next time period is day")
	assert_eq(view.get_seconds_until_next_time_period(), 17990, "At 21610s: 17990s until day (39600s)")
	assert_eq(view.get_next_weather_state(), "cloudy", "At 21610s (window 3 clear): next weather is cloudy")
	assert_eq(view.get_seconds_until_next_weather_state(), 7190, "At 21610s: 7190s until next weather window (28800s)")

	# 2. Select basil-cd at t = 21610 (elapsed = 10s, PLANTED)
	var pv_planted: PlantView = view.get_plant_view_by_id("basil-cd")
	assert_eq(pv_planted.get_name_label_text(), "กะเพรา", "PlantView name label text is กะเพรา")
	assert_eq(pv_planted.get_harvest_reward(), 5, "PlantView receives harvest_reward = 5")
	assert_eq(pv_planted.get_seconds_until_next_stage(), 50, "PlantView receives seconds_until_next_stage = 50")
	assert_eq(pv_planted.get_seconds_until_mature(), 290, "PlantView receives seconds_until_mature = 290")
	assert_true(pv_planted.is_growing_stage(), "PlantView is_growing_stage() is true at PLANTED")
	assert_true(pv_planted.is_planted_stage(), "PlantView is_planted_stage() is true at PLANTED")
	assert_false(pv_planted.is_sprout_stage(), "PlantView is_sprout_stage() is false at PLANTED")
	assert_false(pv_planted.is_growing_phase_stage(), "PlantView is_growing_phase_stage() is false at PLANTED")
	assert_false(pv_planted.is_mature_stage(), "PlantView is_mature_stage() is false at PLANTED")
	assert_true(pv_planted.is_valid_stage(), "PlantView is_valid_stage() is true at PLANTED")
	assert_eq(pv_planted.get_environmental_traits(), ["dense_vegetation", "food"], "PlantView receives environmental traits")
	assert_eq(pv_planted.get_environmental_trait_count(), 2, "PlantView has 2 environmental traits")
	assert_true(pv_planted.has_any_environmental_traits(), "PlantView has_any_environmental_traits() is true")
	assert_true(pv_planted.has_harvest_reward(), "PlantView has_harvest_reward() is true")
	assert_true(pv_planted.has_countdown_to_mature(), "PlantView has_countdown_to_mature() is true at PLANTED")
	assert_true(pv_planted.has_countdown_to_next_stage(), "PlantView has_countdown_to_next_stage() is true at PLANTED")
	assert_true(pv_planted.has_runtime_instance_id(), "PlantView has_runtime_instance_id() is true")
	assert_true(pv_planted.has_definition_id(), "PlantView has_definition_id() is true")
	assert_true(pv_planted.has_display_name(), "PlantView has_display_name() is true")
	assert_true(pv_planted.is_bound(), "PlantView is_bound() is true")
	assert_false(pv_planted.is_invalid_stage(), "PlantView is_invalid_stage() is false at PLANTED")
	assert_true(pv_planted.has_planted_timestamp(), "PlantView has_planted_timestamp() is true when planted_at > 0")
	assert_true(pv_planted.is_known_plant_definition(), "PlantView is_known_plant_definition() is true for holy_basil")
	assert_false(pv_planted.is_selection_highlight_visible(), "PlantView selection highlight is hidden before selection")
	assert_true(pv_planted.is_known_environmental_trait("dense_vegetation"), "dense_vegetation is a known environmental trait")
	assert_false(pv_planted.is_known_environmental_trait("unknown_trait"), "unknown_trait is not a known environmental trait")
	assert_true(pv_planted.is_touch_button_enabled(), "PlantView touch button is enabled")
	assert_true(pv_planted.has_instance_id_label_text(), "PlantView has non-empty instance ID label text")
	assert_true(pv_planted.has_traits_summary_text(), "PlantView has non-empty traits summary text")
	assert_true(pv_planted.has_name_label_text(), "PlantView has non-empty name label text")
	assert_true(pv_planted.has_stage_label_text(), "PlantView has non-empty stage label text")
	assert_true(pv_planted.has_stage_badge_text(), "PlantView has non-empty stage badge text")
	assert_eq(pv_planted.get_trait_display_name_for_id("dense_vegetation"), "พุ่มไม้หนาแน่น", "PlantView trait display name for dense_vegetation")
	assert_eq(pv_planted.get_trait_display_name_for_id(""), "", "PlantView trait display name for empty string is empty")
	assert_eq(pv_planted.get_plant_display_name_for_id("plant.holy_basil"), "กะเพรา", "PlantView plant display name for holy_basil")
	assert_eq(pv_planted.get_plant_display_name_for_id(""), "", "PlantView plant display name for empty string is empty")
	assert_true(pv_planted.is_known_plant_definition_id("plant.holy_basil"), "PlantView is_known_plant_definition_id(plant.holy_basil) is true")
	assert_false(pv_planted.is_known_plant_definition_id("plant.unknown"), "PlantView is_known_plant_definition_id(plant.unknown) is false")
	assert_eq(
		pv_planted.get_bound_trait_display_names(),
		["พุ่มไม้หนาแน่น", "พืชอาหาร"],
		"PlantView bound trait display names return [พุ่มไม้หนาแน่น, พืชอาหาร]"
	)
	assert_eq(pv_planted.get_stage_display_name(), "เพาะเมล็ด", "PlantView stage display name at PLANTED is เพาะเมล็ด")
	assert_eq(pv_planted.get_stage_display_name_for_stage(PlantGrowth.Stage.GROWING), "กำลังโต", "PlantView stage display name for GROWING is กำลังโต")
	assert_eq(pv_planted.get_stage_accent_color_for_stage(PlantGrowth.Stage.MATURE), PlantView.STAGE_ACCENT_MATURE, "PlantView stage accent color for MATURE")
	assert_true(pv_planted.has_known_environmental_trait(), "PlantView has_known_environmental_trait() is true for basil")
	assert_true(pv_planted.is_all_bound_traits_known(), "PlantView is_all_bound_traits_known() is true for basil")
	assert_eq(pv_planted.get_known_bound_trait_ids(), ["dense_vegetation", "food"], "PlantView known bound trait IDs")
	assert_eq(pv_planted.get_unknown_bound_trait_ids(), [], "PlantView unknown bound trait IDs is empty")
	assert_eq(pv_planted.get_known_bound_trait_count(), 2, "PlantView known bound trait count is 2")
	assert_eq(pv_planted.get_unknown_bound_trait_count(), 0, "PlantView unknown bound trait count is 0")
	assert_false(pv_planted.has_unknown_environmental_trait(), "PlantView has_unknown_environmental_trait() is false for basil")
	assert_eq(
		pv_planted.get_known_bound_trait_display_names(),
		["พุ่มไม้หนาแน่น", "พืชอาหาร"],
		"PlantView known bound trait display names"
	)
	assert_true(pv_planted.is_stage_valid_for_stage(PlantGrowth.Stage.PLANTED), "is_stage_valid_for_stage(PLANTED) is true")
	assert_true(pv_planted.is_stage_valid_for_stage(PlantGrowth.Stage.MATURE), "is_stage_valid_for_stage(MATURE) is true")
	assert_false(pv_planted.is_stage_valid_for_stage(PlantGrowth.Stage.INVALID), "is_stage_valid_for_stage(INVALID) is false")
	assert_true(pv_planted.is_stage_mature_for_stage(PlantGrowth.Stage.MATURE), "is_stage_mature_for_stage(MATURE) is true")
	assert_false(pv_planted.is_stage_mature_for_stage(PlantGrowth.Stage.PLANTED), "is_stage_mature_for_stage(PLANTED) is false")
	assert_eq(pv_planted.get_unknown_bound_trait_display_names(), [], "PlantView unknown bound trait display names is empty")
	assert_true(pv_planted.is_stage_planted_for_stage(PlantGrowth.Stage.PLANTED), "is_stage_planted_for_stage(PLANTED) is true")
	assert_false(pv_planted.is_stage_planted_for_stage(PlantGrowth.Stage.SPROUT), "is_stage_planted_for_stage(SPROUT) is false")
	assert_true(pv_planted.is_stage_sprout_for_stage(PlantGrowth.Stage.SPROUT), "is_stage_sprout_for_stage(SPROUT) is true")
	assert_false(pv_planted.is_stage_sprout_for_stage(PlantGrowth.Stage.PLANTED), "is_stage_sprout_for_stage(PLANTED) is false")
	assert_true(pv_planted.is_stage_growing_phase_for_stage(PlantGrowth.Stage.GROWING), "is_stage_growing_phase_for_stage(GROWING) is true")
	assert_false(pv_planted.is_stage_growing_phase_for_stage(PlantGrowth.Stage.PLANTED), "is_stage_growing_phase_for_stage(PLANTED) is false")
	assert_true(pv_planted.is_stage_invalid_for_stage(PlantGrowth.Stage.INVALID), "is_stage_invalid_for_stage(INVALID) is true")
	assert_false(pv_planted.is_stage_invalid_for_stage(PlantGrowth.Stage.PLANTED), "is_stage_invalid_for_stage(PLANTED) is false")
	assert_true(pv_planted.has_known_plant_display_name_for_id("plant.holy_basil"), "has_known_plant_display_name_for_id(plant.holy_basil) is true")
	assert_false(pv_planted.has_known_plant_display_name_for_id("plant.unknown"), "has_known_plant_display_name_for_id(plant.unknown) is false")
	assert_true(pv_planted.has_known_trait_display_name_for_id("dense_vegetation"), "has_known_trait_display_name_for_id(dense_vegetation) is true")
	assert_false(pv_planted.has_known_trait_display_name_for_id("unknown_trait"), "has_known_trait_display_name_for_id(unknown_trait) is false")
	assert_eq(
		pv_planted.get_known_trait_ids_in_dictionary(),
		["dense_vegetation", "flower", "food", "fruit", "light", "perch", "shade", "shelter", "water"],
		"PlantView known trait IDs in dictionary"
	)
	assert_eq(
		pv_planted.get_known_plant_definition_ids_in_dictionary(),
		["plant.banana", "plant.chili", "plant.holy_basil", "plant.jasmine", "plant.marigold"],
		"PlantView known plant definition IDs in dictionary"
	)
	assert_eq(pv_planted.get_known_trait_count_in_dictionary(), 9, "9 known environmental traits in dictionary")
	assert_eq(pv_planted.get_known_plant_definition_count_in_dictionary(), 5, "5 known plant definitions in dictionary")
	assert_true(pv_planted.is_stage_growing_for_stage(PlantGrowth.Stage.PLANTED), "is_stage_growing_for_stage(PLANTED) is true")
	assert_true(pv_planted.is_stage_growing_for_stage(PlantGrowth.Stage.SPROUT), "is_stage_growing_for_stage(SPROUT) is true")
	assert_true(pv_planted.is_stage_growing_for_stage(PlantGrowth.Stage.GROWING), "is_stage_growing_for_stage(GROWING) is true")
	assert_false(pv_planted.is_stage_growing_for_stage(PlantGrowth.Stage.MATURE), "is_stage_growing_for_stage(MATURE) is false")
	assert_false(pv_planted.is_stage_growing_for_stage(PlantGrowth.Stage.INVALID), "is_stage_growing_for_stage(INVALID) is false")
	assert_true(pv_planted.has_environmental_trait("dense_vegetation"), "PlantView has dense_vegetation trait")
	assert_false(pv_planted.has_environmental_trait("flower"), "PlantView does not have flower trait")
	assert_eq(pv_planted.get_traits_summary_text(), "พุ่มไม้หนาแน่น, พืชอาหาร", "PlantView formats localized Thai traits summary")
	assert_true(pv_planted.get_instance_id_label_text().contains("คุณสมบัติ: พุ่มไม้หนาแน่น, พืชอาหาร"), "PlantView card subtitle displays traits")
	assert_eq(pv_planted.get_stage_accent_color(), PlantView.STAGE_ACCENT_PLANTED, "PlantView accent color at PLANTED")
	assert_false(pv_planted.is_ready_to_harvest(), "PlantView not ready to harvest at PLANTED")
	assert_eq(pv_planted.get_stage_badge_text(), "[เมล็ด • อีก 290s]", "PlantView badge shows remaining seconds at PLANTED")
	assert_eq(view.get_ready_to_harvest_plant_count(), 0, "0 plants ready to harvest at PLANTED")
	pv_planted.simulate_selection_input()
	assert_true(pv_planted.is_selection_highlight_visible(), "PlantView selection highlight is visible after selection")
	assert_true(view.has_selected_plant(), "Plant is selected after simulate_selection_input")
	assert_false(view.is_selected_plant_ready_to_harvest(), "Selected PLANTED basil is not ready to harvest")
	assert_true(view.has_selected_plant_environmental_trait("dense_vegetation"), "Selected basil has dense_vegetation trait")
	assert_false(view.has_selected_plant_environmental_trait("flower"), "Selected basil does not have flower trait")
	assert_true(view.is_selected_plant_growing(), "Selected PLANTED basil is growing")
	assert_eq(view.get_selected_plant_trait_count(), 2, "Selected basil has 2 environmental traits")
	assert_true(view.has_selected_plant_any_environmental_traits(), "Selected basil has_selected_plant_any_environmental_traits() is true")
	assert_eq(view.get_selected_plant_definition_id(), "plant.holy_basil", "Selected basil exposes definition ID")
	assert_eq(view.get_selected_plant_display_name(), "กะเพรา", "Selected basil exposes localized display name กะเพรา")
	assert_eq(view.get_selected_plant_stage(), PlantGrowth.Stage.PLANTED, "Selected basil stage is PLANTED")
	assert_eq(view.get_selected_plant_stage_display_name(), "เพาะเมล็ด", "Selected basil stage display name at PLANTED is เพาะเมล็ด")
	assert_eq(view.get_selected_plant_stage_accent_color(), PlantView.STAGE_ACCENT_PLANTED, "Selected basil stage accent color at PLANTED")
	assert_true(view.has_selected_plant_countdown_to_mature(), "Selected PLANTED basil has countdown to mature")
	assert_true(view.has_selected_plant_countdown_to_next_stage(), "Selected PLANTED basil has countdown to next stage")
	assert_true(view.has_selected_plant_harvest_reward(), "Selected basil has positive harvest reward")
	assert_true(view.is_selected_plant_planted_stage(), "Selected basil is at PLANTED stage")
	assert_false(view.is_selected_plant_sprout_stage(), "Selected basil is not at SPROUT stage")
	assert_false(view.is_selected_plant_growing_phase_stage(), "Selected basil is not at GROWING stage")
	assert_false(view.is_selected_plant_mature_stage(), "Selected basil is not at MATURE stage")
	assert_eq(view.get_selected_plant_seconds_until_next_stage(), 50, "At 10s elapsed: 50s until SPROUT (60s)")
	assert_eq(view.get_selected_plant_seconds_until_mature(), 290, "At 10s elapsed: 290s until MATURE (300s)")
	assert_eq(view.get_selected_plant_traits(), ["dense_vegetation", "food"], "Selected basil exposes traits")
	assert_eq(
		view.get_selected_plant_trait_display_names(),
		["พุ่มไม้หนาแน่น", "พืชอาหาร"],
		"Selected basil exposes localized trait display names"
	)
	assert_eq(view.get_selected_plant_harvest_reward(), 5, "Selected basil exposes harvest_reward = 5")
	assert_eq(view.get_selected_plant_planted_at(), 21600, "Selected basil exposes planted_at = 21600")
	assert_true(view.get_detail_id_text().contains("basil-cd"), "DetailIdLabel shows basil-cd")
	assert_true(view.get_detail_planted_at_text().contains("21600"), "DetailPlantedAtLabel shows 21600")
	assert_true(view.get_detail_name_text().contains("พุ่มไม้หนาแน่น"), "DetailNameLabel shows trait display name")
	assert_true(
		view.get_detail_stage_text().contains("โตเต็มที่ในอีก 290 วินาที (ระยะถัดไปในอีก 50 วินาที)"),
		"DetailStageLabel shows remaining seconds to mature and next stage"
	)

	# 3. Advance clock to t = 21700 (elapsed = 100s, SPROUT) and refresh (samples clock once)
	clock.set_utc_seconds(21700)
	var calls_before: int = clock.utc_call_count
	view.refresh_from_session()
	assert_eq(clock.utc_call_count, calls_before + 1, "Refresh samples clock once")
	assert_eq(view.get_selected_plant_seconds_until_next_stage(), 80, "At 100s elapsed: 80s until GROWING (180s)")
	assert_eq(view.get_selected_plant_seconds_until_mature(), 200, "At 100s elapsed: 200s until MATURE (300s)")
	assert_eq(view.get_plant_view_by_id("basil-cd").get_stage_badge_text(), "[ต้นกล้า • อีก 200s]", "PlantView badge updates to SPROUT countdown")
	assert_true(view.get_plant_view_by_id("basil-cd").is_sprout_stage(), "PlantView is_sprout_stage() is true at SPROUT")
	assert_eq(view.get_plant_view_by_id("basil-cd").get_stage_display_name(), "ต้นกล้า", "PlantView stage display name at SPROUT is ต้นกล้า")
	assert_false(view.get_plant_view_by_id("basil-cd").is_planted_stage(), "PlantView is_planted_stage() is false at SPROUT")
	assert_true(view.is_selected_plant_sprout_stage(), "Selected basil is_selected_plant_sprout_stage() is true at SPROUT")
	assert_false(view.is_selected_plant_planted_stage(), "Selected basil is_selected_plant_planted_stage() is false at SPROUT")
	assert_eq(view.get_plant_view_by_id("basil-cd").get_stage_accent_color(), PlantView.STAGE_ACCENT_SPROUT, "PlantView accent color updates to SPROUT")
	assert_eq(view.get_growing_plant_ids(), ["basil-cd"], "SPROUT basil remains in growing_plant_ids")
	assert_true(
		view.get_detail_stage_text().contains("โตเต็มที่ในอีก 200 วินาที (ระยะถัดไปในอีก 80 วินาที)"),
		"DetailStageLabel updates remaining seconds on refresh"
	)

	# 4. Advance clock to t = 21900 (elapsed = 300s, MATURE) and refresh
	clock.set_utc_seconds(21900)
	view.refresh_from_session()
	assert_eq(view.get_selected_plant_stage(), PlantGrowth.Stage.MATURE, "Selected basil stage updates to MATURE")
	assert_eq(view.get_selected_plant_seconds_until_next_stage(), 0, "At MATURE: 0s until next stage")
	assert_eq(view.get_selected_plant_seconds_until_mature(), 0, "At MATURE: 0s until mature")
	var pv_mature: PlantView = view.get_plant_view_by_id("basil-cd")
	assert_true(pv_mature.is_ready_to_harvest(), "PlantView is_ready_to_harvest() is true at MATURE")
	assert_true(pv_mature.is_mature_stage(), "PlantView is_mature_stage() is true at MATURE")
	assert_eq(pv_mature.get_stage_display_name(), "โตเต็มที่", "PlantView stage display name at MATURE is โตเต็มที่")
	assert_false(pv_mature.is_planted_stage(), "PlantView is_planted_stage() is false at MATURE")
	assert_false(pv_mature.is_sprout_stage(), "PlantView is_sprout_stage() is false at MATURE")
	assert_false(pv_mature.is_growing_phase_stage(), "PlantView is_growing_phase_stage() is false at MATURE")
	assert_false(pv_mature.is_growing_stage(), "PlantView is_growing_stage() is false at MATURE")
	assert_false(pv_mature.has_countdown_to_mature(), "PlantView has_countdown_to_mature() is false at MATURE")
	assert_false(pv_mature.has_countdown_to_next_stage(), "PlantView has_countdown_to_next_stage() is false at MATURE")
	assert_true(view.is_selected_plant_ready_to_harvest(), "Selected MATURE basil is ready to harvest")
	assert_false(view.is_selected_plant_growing(), "Selected MATURE basil is no longer growing")
	assert_eq(view.get_selected_plant_stage_accent_color(), PlantView.STAGE_ACCENT_MATURE, "Selected basil stage accent color at MATURE")
	assert_false(view.has_selected_plant_countdown_to_mature(), "Selected MATURE basil has no countdown to mature")
	assert_false(view.has_selected_plant_countdown_to_next_stage(), "Selected MATURE basil has no countdown to next stage")
	assert_true(view.has_selected_plant_harvest_reward(), "Selected MATURE basil still has positive harvest reward")
	assert_true(view.is_selected_plant_mature_stage(), "Selected MATURE basil is_selected_plant_mature_stage() is true")
	assert_false(view.is_selected_plant_sprout_stage(), "Selected MATURE basil is_selected_plant_sprout_stage() is false")
	assert_false(view.has_any_growing_plants_in_garden(), "No growing plants remaining at MATURE")
	assert_true(view.has_any_ready_to_harvest_plants_in_garden(), "Has ready to harvest plants at MATURE")
	assert_true(view.is_all_planted_plants_ready_to_harvest_in_garden(), "All planted plants ready to harvest at MATURE")
	assert_eq(pv_mature.get_seconds_until_next_stage(), 0, "PlantView seconds_until_next_stage is 0 at MATURE")
	assert_eq(pv_mature.get_stage_accent_color(), PlantView.STAGE_ACCENT_MATURE, "PlantView accent color updates to MATURE")
	assert_eq(pv_mature.get_stage_label_text(), "โตเต็มที่ (+5 เหรียญ)", "PlantView stage label shows harvest reward at MATURE")
	assert_eq(pv_mature.get_stage_badge_text(), "[พร้อมเก็บ +5]", "PlantView stage badge shows ready to harvest at MATURE")
	assert_eq(view.get_growing_plant_ids(), [], "MATURE basil is no longer in growing_plant_ids")
	assert_eq(view.get_growing_plant_count(), 0, "0 growing plants at MATURE")
	assert_eq(view.get_minimum_seconds_until_next_stage_transition(), -1, "No growing plants remaining -> -1 min seconds until next stage")
	assert_eq(view.get_minimum_seconds_until_next_harvest(), -1, "No growing plants remaining -> -1 min seconds until next harvest")
	assert_eq(view.get_plant_ids_for_stage(PlantGrowth.Stage.MATURE), ["basil-cd"], "Plant IDs for MATURE stage")
	assert_eq(view.get_plant_count_for_stage(PlantGrowth.Stage.MATURE), 1, "1 plant at MATURE stage")
	assert_eq(view.get_ready_to_harvest_plant_count(), 1, "1 plant ready to harvest at MATURE")
	assert_eq(view.get_ready_to_harvest_plant_ids(), ["basil-cd"], "Ready to harvest plant IDs returns [basil-cd]")
	assert_eq(view.get_total_pending_harvest_reward(), 5, "Total pending harvest reward is 5 coins")
	assert_true(
		view.get_detail_stage_text().contains("พร้อมเก็บเกี่ยวแล้ว"),
		"DetailStageLabel shows ready to harvest at MATURE"
	)

	# 5. Blocked state resets countdowns and atmosphere forecasts
	view.show_blocked_startup("ทดสอบบล็อก")
	assert_eq(view.get_selected_plant_definition_id(), "", "Blocked clears selected plant definition ID")
	assert_eq(view.get_selected_plant_stage(), PlantGrowth.Stage.INVALID, "Blocked resets selected plant stage to INVALID")
	assert_eq(view.get_selected_plant_harvest_reward(), 0, "Blocked resets selected plant harvest reward to 0")
	assert_eq(view.get_selected_plant_planted_at(), -1, "Blocked resets selected plant planted_at to -1")
	assert_eq(view.get_growing_plant_ids(), [], "Blocked clears growing plant IDs")
	assert_eq(view.get_growing_plant_count(), 0, "Blocked resets growing plant count to 0")
	assert_eq(view.get_minimum_seconds_until_next_stage_transition(), -1, "Blocked resets minimum seconds until next stage to -1")
	assert_eq(view.get_minimum_seconds_until_next_harvest(), -1, "Blocked resets minimum seconds until next harvest to -1")
	assert_eq(view.get_present_plant_definition_ids(), [], "Blocked clears present plant definition IDs")
	assert_eq(view.get_planted_count_for_id("plant.holy_basil"), 0, "Blocked resets planted count to 0")
	assert_eq(view.get_plant_ids_for_definition_id("plant.holy_basil"), [], "Blocked clears plant IDs for definition ID")
	assert_eq(view.get_distinct_planted_species_count(), 0, "Blocked resets distinct planted species count to 0")
	assert_eq(view.get_distinct_placed_decoration_species_count(), 0, "Blocked resets distinct placed decoration species count to 0")
	assert_eq(view.get_discovered_entry_count_in_garden(), 0, "Blocked resets discovered entry count in garden to 0")
	assert_eq(view.get_undiscovered_entry_count_in_garden(), 0, "Blocked resets undiscovered entry count in garden to 0")
	assert_false(view.is_all_journal_entries_discovered_in_garden(), "Blocked resets all journal entries discovered flag to false")
	assert_false(view.is_at_max_progression_stage(), "Blocked resets max progression stage flag to false")
	assert_eq(view.get_plant_ids_with_environmental_trait("dense_vegetation"), [], "Blocked clears plant IDs with environmental trait")
	assert_eq(view.get_plant_count_with_environmental_trait("dense_vegetation"), 0, "Blocked resets plant count with environmental trait to 0")
	assert_eq(view.get_eligible_visitor_count(), 0, "Blocked resets eligible visitor count to 0")
	assert_eq(view.get_eligible_event_count(), 0, "Blocked resets eligible event count to 0")
	assert_false(view.has_selected_plant(), "Blocked clears has_selected_plant()")
	assert_false(view.is_selected_plant_ready_to_harvest(), "Blocked resets is_selected_plant_ready_to_harvest()")
	assert_false(view.has_active_environmental_trait("dense_vegetation"), "Blocked resets has_active_environmental_trait()")
	assert_eq(view.get_active_environmental_trait_count(), 0, "Blocked resets active environmental trait count to 0")
	assert_false(view.is_plant_definition_present_in_garden("plant.holy_basil"), "Blocked resets is_plant_definition_present_in_garden()")
	assert_false(view.is_decoration_definition_present_in_garden("decoration.bench"), "Blocked resets is_decoration_definition_present_in_garden()")
	assert_false(view.is_visitor_currently_eligible("visitor.butterfly"), "Blocked resets is_visitor_currently_eligible()")
	assert_false(view.is_event_currently_eligible("event.morning_butterflies"), "Blocked resets is_event_currently_eligible()")
	assert_false(view.has_any_planted_plants_in_garden(), "Blocked resets has_any_planted_plants_in_garden()")
	assert_false(view.has_any_growing_plants_in_garden(), "Blocked resets has_any_growing_plants_in_garden()")
	assert_false(view.has_any_ready_to_harvest_plants_in_garden(), "Blocked resets has_any_ready_to_harvest_plants_in_garden()")
	assert_false(view.has_any_placed_decorations_in_garden(), "Blocked resets has_any_placed_decorations_in_garden()")
	assert_false(view.has_any_active_environmental_traits_in_garden(), "Blocked resets has_any_active_environmental_traits_in_garden()")
	assert_false(view.has_any_eligible_visitors_in_garden(), "Blocked resets has_any_eligible_visitors_in_garden()")
	assert_false(view.has_any_eligible_events_in_garden(), "Blocked resets has_any_eligible_events_in_garden()")
	assert_false(view.has_selected_plant_environmental_trait("dense_vegetation"), "Blocked resets has_selected_plant_environmental_trait()")
	assert_false(view.is_selected_plant_growing(), "Blocked resets is_selected_plant_growing()")
	assert_eq(view.get_selected_plant_trait_count(), 0, "Blocked resets get_selected_plant_trait_count()")
	assert_false(view.has_selected_plant_any_environmental_traits(), "Blocked resets has_selected_plant_any_environmental_traits()")
	assert_false(view.is_all_planted_plants_ready_to_harvest_in_garden(), "Blocked resets is_all_planted_plants_ready_to_harvest_in_garden()")
	assert_false(view.has_any_discovered_entries_in_garden(), "Blocked resets has_any_discovered_entries_in_garden()")
	assert_false(view.has_any_undiscovered_entries_in_garden(), "Blocked resets has_any_undiscovered_entries_in_garden()")
	assert_false(view.has_active_visitor_in_garden(), "Blocked resets has_active_visitor_in_garden()")
	assert_false(view.has_active_event_in_garden(), "Blocked resets has_active_event_in_garden()")
	assert_false(view.has_bound_session(), "Blocked resets has_bound_session()")
	assert_false(view.has_bound_catalog(), "Blocked resets has_bound_catalog()")
	assert_false(view.has_bound_clock(), "Blocked resets has_bound_clock()")
	assert_false(view.has_last_garden_snapshot(), "Blocked resets has_last_garden_snapshot()")
	assert_false(view.has_last_progression_summary(), "Blocked resets has_last_progression_summary()")
	assert_false(view.has_last_return_summary(), "Blocked resets has_last_return_summary()")
	assert_false(view.is_planting_picker_open_in_garden(), "Blocked resets is_planting_picker_open_in_garden()")
	assert_false(view.is_decoration_picker_open_in_garden(), "Blocked resets is_decoration_picker_open_in_garden()")
	assert_false(view.is_journal_open_in_garden(), "Blocked resets is_journal_open_in_garden()")
	assert_false(view.is_any_modal_open_in_garden(), "Blocked resets is_any_modal_open_in_garden()")
	assert_false(view.has_last_planting_checkpoint_result(), "Blocked resets has_last_planting_checkpoint_result()")
	assert_false(view.has_last_harvest_checkpoint_result(), "Blocked resets has_last_harvest_checkpoint_result()")
	assert_false(view.has_last_visitor_selection_result(), "Blocked resets has_last_visitor_selection_result()")
	assert_false(view.has_last_visitor_observation_checkpoint_result(), "Blocked resets has_last_visitor_observation_checkpoint_result()")
	assert_false(view.has_last_event_selection_result(), "Blocked resets has_last_event_selection_result()")
	assert_false(view.has_last_decoration_purchase_checkpoint_result(), "Blocked resets has_last_decoration_purchase_checkpoint_result()")
	assert_eq(view.get_selected_plant_display_name(), "", "Blocked clears get_selected_plant_display_name()")
	assert_eq(view.get_current_visitor_display_name(), "", "Blocked clears get_current_visitor_display_name()")
	assert_eq(view.get_current_event_display_name(), "", "Blocked clears get_current_event_display_name()")
	assert_eq(view.get_current_event_description(), "", "Blocked clears get_current_event_description()")
	assert_eq(view.get_current_time_period_display_name(), "", "Blocked clears get_current_time_period_display_name()")
	assert_eq(view.get_current_weather_display_name(), "", "Blocked clears get_current_weather_display_name()")
	assert_eq(view.get_next_time_period_display_name(), "", "Blocked clears get_next_time_period_display_name()")
	assert_eq(view.get_next_weather_display_name(), "", "Blocked clears get_next_weather_display_name()")
	assert_eq(view.get_current_progression_stage_display_name(), "", "Blocked clears get_current_progression_stage_display_name()")
	assert_eq(view.get_next_progression_stage_display_name(), "", "Blocked clears get_next_progression_stage_display_name()")
	assert_eq(view.get_current_guidance_display_name(), "", "Blocked clears get_current_guidance_display_name()")
	assert_false(view.is_selected_plant_planted_stage(), "Blocked resets is_selected_plant_planted_stage()")
	assert_false(view.is_selected_plant_sprout_stage(), "Blocked resets is_selected_plant_sprout_stage()")
	assert_false(view.is_selected_plant_growing_phase_stage(), "Blocked resets is_selected_plant_growing_phase_stage()")
	assert_false(view.is_selected_plant_mature_stage(), "Blocked resets is_selected_plant_mature_stage()")
	assert_eq(view.get_active_environmental_trait_display_names(), [], "Blocked clears get_active_environmental_trait_display_names()")
	assert_eq(view.get_selected_plant_trait_display_names(), [], "Blocked clears get_selected_plant_trait_display_names()")
	assert_eq(view.get_eligible_visitor_display_names(), [], "Blocked clears get_eligible_visitor_display_names()")
	assert_eq(view.get_eligible_event_display_names(), [], "Blocked clears get_eligible_event_display_names()")
	assert_eq(view.get_present_plant_display_names(), [], "Blocked clears get_present_plant_display_names()")
	assert_eq(view.get_present_decoration_display_names(), [], "Blocked clears get_present_decoration_display_names()")
	assert_eq(view.get_selected_plant_stage_display_name(), "", "Blocked clears get_selected_plant_stage_display_name()")
	assert_false(view.has_plant_in_garden_catalog("plant.holy_basil"), "Blocked resets has_plant_in_garden_catalog()")
	assert_false(view.has_visitor_in_garden_catalog("visitor.butterfly"), "Blocked resets has_visitor_in_garden_catalog()")
	assert_false(view.has_decoration_in_garden_catalog("decoration.bench"), "Blocked resets has_decoration_in_garden_catalog()")
	assert_false(view.has_event_in_garden_catalog("event.morning_butterflies"), "Blocked resets has_event_in_garden_catalog()")
	assert_eq(view.get_selected_plant_stage_accent_color(), PlantView.STAGE_ACCENT_INVALID, "Blocked resets get_selected_plant_stage_accent_color()")
	assert_false(view.has_selected_plant_countdown_to_mature(), "Blocked resets has_selected_plant_countdown_to_mature()")
	assert_false(view.has_selected_plant_countdown_to_next_stage(), "Blocked resets has_selected_plant_countdown_to_next_stage()")
	assert_false(view.has_selected_plant_harvest_reward(), "Blocked resets has_selected_plant_harvest_reward()")
	assert_eq(view.get_total_catalog_plant_count_in_garden(), 0, "Blocked resets get_total_catalog_plant_count_in_garden()")
	assert_eq(view.get_total_catalog_visitor_count_in_garden(), 0, "Blocked resets get_total_catalog_visitor_count_in_garden()")
	assert_eq(view.get_total_catalog_decoration_count_in_garden(), 0, "Blocked resets get_total_catalog_decoration_count_in_garden()")
	assert_eq(view.get_total_catalog_event_count_in_garden(), 0, "Blocked resets get_total_catalog_event_count_in_garden()")
	assert_eq(view.get_all_catalog_plant_ids_in_garden(), [], "Blocked clears get_all_catalog_plant_ids_in_garden()")
	assert_eq(view.get_all_catalog_visitor_ids_in_garden(), [], "Blocked clears get_all_catalog_visitor_ids_in_garden()")
	assert_eq(view.get_all_catalog_decoration_ids_in_garden(), [], "Blocked clears get_all_catalog_decoration_ids_in_garden()")
	assert_eq(view.get_all_catalog_event_ids_in_garden(), [], "Blocked clears get_all_catalog_event_ids_in_garden()")
	assert_false(view.is_all_catalog_plant_species_present_in_garden(), "Blocked resets is_all_catalog_plant_species_present_in_garden()")
	assert_false(view.is_all_catalog_decoration_species_present_in_garden(), "Blocked resets is_all_catalog_decoration_species_present_in_garden()")
	assert_eq(view.get_all_catalog_plant_display_names_in_garden(), [], "Blocked clears get_all_catalog_plant_display_names_in_garden()")
	assert_eq(view.get_all_catalog_visitor_display_names_in_garden(), [], "Blocked clears get_all_catalog_visitor_display_names_in_garden()")
	assert_eq(view.get_all_catalog_decoration_display_names_in_garden(), [], "Blocked clears get_all_catalog_decoration_display_names_in_garden()")
	assert_eq(view.get_all_catalog_event_display_names_in_garden(), [], "Blocked clears get_all_catalog_event_display_names_in_garden()")
	assert_eq(view.get_unplanted_catalog_plant_ids_in_garden(), [], "Blocked clears get_unplanted_catalog_plant_ids_in_garden()")
	assert_eq(view.get_unplaced_catalog_decoration_ids_in_garden(), [], "Blocked clears get_unplaced_catalog_decoration_ids_in_garden()")
	assert_eq(view.get_unplanted_catalog_plant_count_in_garden(), 0, "Blocked resets get_unplanted_catalog_plant_count_in_garden()")
	assert_eq(view.get_unplaced_catalog_decoration_count_in_garden(), 0, "Blocked resets get_unplaced_catalog_decoration_count_in_garden()")
	assert_false(view.has_any_unplanted_catalog_plants_in_garden(), "Blocked resets has_any_unplanted_catalog_plants_in_garden()")
	assert_false(view.has_any_unplaced_catalog_decorations_in_garden(), "Blocked resets has_any_unplaced_catalog_decorations_in_garden()")
	assert_eq(view.get_unplanted_catalog_plant_display_names_in_garden(), [], "Blocked clears get_unplanted_catalog_plant_display_names_in_garden()")
	assert_eq(view.get_unplaced_catalog_decoration_display_names_in_garden(), [], "Blocked clears get_unplaced_catalog_decoration_display_names_in_garden()")
	assert_eq(view.get_ineligible_catalog_visitor_ids_in_garden(), [], "Blocked clears get_ineligible_catalog_visitor_ids_in_garden()")
	assert_eq(view.get_ineligible_catalog_event_ids_in_garden(), [], "Blocked clears get_ineligible_catalog_event_ids_in_garden()")
	assert_eq(view.get_ineligible_catalog_visitor_count_in_garden(), 0, "Blocked resets get_ineligible_catalog_visitor_count_in_garden()")
	assert_eq(view.get_ineligible_catalog_event_count_in_garden(), 0, "Blocked resets get_ineligible_catalog_event_count_in_garden()")
	assert_false(view.has_any_ineligible_catalog_visitors_in_garden(), "Blocked resets has_any_ineligible_catalog_visitors_in_garden()")
	assert_false(view.has_any_ineligible_catalog_events_in_garden(), "Blocked resets has_any_ineligible_catalog_events_in_garden()")
	assert_eq(view.get_ineligible_catalog_visitor_display_names_in_garden(), [], "Blocked clears get_ineligible_catalog_visitor_display_names_in_garden()")
	assert_eq(view.get_ineligible_catalog_event_display_names_in_garden(), [], "Blocked clears get_ineligible_catalog_event_display_names_in_garden()")
	assert_eq(view.get_plant_ids_for_stage(PlantGrowth.Stage.MATURE), [], "Blocked clears plant IDs for stage")
	assert_eq(view.get_plant_count_for_stage(PlantGrowth.Stage.MATURE), 0, "Blocked resets plant count for stage to 0")
	assert_eq(view.get_active_environmental_traits(), [], "Blocked clears active environmental traits")
	assert_eq(view.get_environmental_trait_count("dense_vegetation"), 0, "Blocked resets environmental trait count to 0")
	assert_eq(view.get_present_decoration_definition_ids(), [], "Blocked clears present decoration IDs")
	assert_eq(view.get_placed_decoration_count_for_id("decoration.bench"), 0, "Blocked resets placed decoration count to 0")
	assert_eq(view.get_ready_to_harvest_plant_count(), 0, "Blocked resets ready to harvest count to 0")
	assert_eq(view.get_ready_to_harvest_plant_ids(), [], "Blocked clears ready to harvest plant IDs")
	assert_eq(view.get_total_pending_harvest_reward(), 0, "Blocked resets total pending harvest reward to 0")
	assert_eq(view.get_selected_plant_seconds_until_next_stage(), -1, "Blocked resets next stage countdown")
	assert_eq(view.get_selected_plant_seconds_until_mature(), -1, "Blocked resets mature countdown")
	assert_eq(view.get_next_time_period(), "", "Blocked clears next time period")
	assert_eq(view.get_seconds_until_next_time_period(), 0, "Blocked resets time period countdown")
	assert_eq(view.get_next_weather_state(), "", "Blocked clears next weather state")
	assert_eq(view.get_seconds_until_next_weather_state(), 0, "Blocked resets weather countdown")

	view.free()
