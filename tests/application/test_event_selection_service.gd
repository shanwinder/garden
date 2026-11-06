## test_event_selection_service.gd
## Deterministic unit tests for EventSelectionService and EventSelectionResult.
class_name TestEventSelectionService
extends TestSuiteBase


class CountingClock extends FakeGameClock:
	var utc_calls: int = 0

	func _init(initial_utc: int) -> void:
		super(initial_utc, 0)

	func utc_now_seconds() -> int:
		utc_calls += 1
		return super.utc_now_seconds()


func _init() -> void:
	suite_name = "TestEventSelectionService"


func run_tests() -> void:
	_test_prevalidation_rejects_invalid_inputs_without_clock_or_rng()
	_test_empty_garden_or_no_matches_consumes_zero_rng()
	_test_single_eligible_event_selected_deterministically()
	_test_multiple_eligible_events_weighted_selection_deterministic()


func _create_production_catalog() -> ContentCatalog:
	var p_res: PlantContentLoadResult = PlantContentLoader.new().load_production_definitions()
	var v_res: VisitorContentLoadResult = VisitorContentLoader.new().load_production_definitions()
	var d_res: DecorationContentLoadResult = DecorationContentLoader.new().load_production_definitions()
	var e_res: EventContentLoadResult = EventContentLoader.new().load_production_definitions()
	return ContentCatalog.try_create(
		p_res.get_definitions(),
		v_res.get_definitions(),
		d_res.get_definitions(),
		e_res.get_definitions()
	)


func _test_prevalidation_rejects_invalid_inputs_without_clock_or_rng() -> void:
	describe("Prevalidation rejects null dependencies or negative time without sampling clock or consuming RNG")
	var catalog: ContentCatalog = _create_production_catalog()
	var state: GameState = GameState.new()
	var clock: CountingClock = CountingClock.new(21600)
	var rng: FakeRandomSource = FakeRandomSource.new([], [])

	var r1: EventSelectionResult = EventSelectionService.evaluate_and_select_now(null, catalog, clock, rng)
	assert_eq(r1.get_status(), EventSelectionResult.INVALID_INPUT, "Null state rejected")
	assert_eq(clock.utc_calls, 0, "Clock not sampled on null state")

	var r2: EventSelectionResult = EventSelectionService.evaluate_and_select_now(state, null, clock, rng)
	assert_eq(r2.get_status(), EventSelectionResult.INVALID_INPUT, "Null catalog rejected")
	assert_eq(clock.utc_calls, 0, "Clock not sampled on null catalog")

	var r3: EventSelectionResult = EventSelectionService.evaluate_and_select_now(state, catalog, null, rng)
	assert_eq(r3.get_status(), EventSelectionResult.INVALID_INPUT, "Null clock rejected")

	var r4: EventSelectionResult = EventSelectionService.evaluate_and_select_now(state, catalog, clock, null)
	assert_eq(r4.get_status(), EventSelectionResult.INVALID_INPUT, "Null rng rejected")
	assert_eq(clock.utc_calls, 0, "Clock not sampled on null rng")

	var r5: EventSelectionResult = EventSelectionService.evaluate_and_select_at(state, catalog, rng, -1)
	assert_eq(r5.get_status(), EventSelectionResult.INVALID_INPUT, "Negative timestamp rejected")


func _test_empty_garden_or_no_matches_consumes_zero_rng() -> void:
	describe("NO_ELIGIBLE_EVENTS returns snapshot and consumes zero random floats")
	var catalog: ContentCatalog = _create_production_catalog()
	var empty_state: GameState = GameState.new()
	var clock: CountingClock = CountingClock.new(21600)
	var rng: FakeRandomSource = FakeRandomSource.new([], [])

	var result: EventSelectionResult = EventSelectionService.evaluate_and_select_now(
		empty_state,
		catalog,
		clock,
		rng
	)
	assert_eq(result.get_status(), EventSelectionResult.NO_ELIGIBLE_EVENTS, "Empty garden has no eligible events")
	assert_false(result.is_selected(), "is_selected() is false")
	assert_eq(result.get_selected_event(), null, "Selected event is null")
	assert_eq(result.get_selected_event_id(), "", "Selected event ID is empty")
	assert_eq(result.get_eligible_event_ids().size(), 0, "Eligible IDs empty")
	assert_true(result.get_snapshot() != null and result.get_snapshot().is_empty_garden(), "Snapshot retained")
	assert_eq(clock.utc_calls, 1, "Clock sampled exactly once")


func _test_single_eligible_event_selected_deterministically() -> void:
	describe("Single eligible ambient event is selected deterministically")
	var catalog: ContentCatalog = _create_production_catalog()
	var state: GameState = GameState.new()
	# Small pond + Rain at t=14400 (window 2 = rain, hour 4 = night) -> only event.frog_rain_chorus
	state.get_decorations().try_add_decoration(DecorationState.new("pond-1", "decoration.small_pond", 1000))

	var rng: FakeRandomSource = FakeRandomSource.new([0.0, 0.99], [])
	var res1: EventSelectionResult = EventSelectionService.evaluate_and_select_at(state, catalog, rng, 14400)
	assert_true(res1.is_selected(), "Selected on roll 0.0")
	assert_eq(res1.get_selected_event_id(), "event.frog_rain_chorus", "Frog rain chorus selected")
	assert_eq(res1.get_eligible_event_ids(), ["event.frog_rain_chorus"], "Only frog_rain_chorus eligible")

	var res2: EventSelectionResult = EventSelectionService.evaluate_and_select_at(state, catalog, rng, 14400)
	assert_true(res2.is_selected(), "Selected on roll 0.99")
	assert_eq(res2.get_selected_event_id(), "event.frog_rain_chorus", "Frog rain chorus selected at upper bound")


func _test_multiple_eligible_events_weighted_selection_deterministic() -> void:
	describe("Multiple eligible ambient events are selected deterministically by cumulative weight")
	var catalog: ContentCatalog = _create_production_catalog()
	var state: GameState = GameState.new()
	# Mature banana (perch, shade) + Bench (decoration.bench) at t=43200 (hour 12 = day, window 6 = cloudy):
	# Eligible events in ascending ID order:
	#   0: event.bird_shade_song    (weight = 25.0) -> [0.0, 25.0), normalized [0.0, 0.5555...)
	#   1: event.cat_sleeping_bench (weight = 20.0) -> [25.0, 45.0), normalized [0.5555..., 1.0)
	state.get_plants().try_add_plant(PlantState.new("banana-1", "plant.banana", 0))
	state.get_decorations().try_add_decoration(DecorationState.new("bench-1", "decoration.bench", 0))

	var rng: FakeRandomSource = FakeRandomSource.new([0.0, 0.50, 0.60, 0.99], [])

	var r_low: EventSelectionResult = EventSelectionService.evaluate_and_select_at(state, catalog, rng, 43200)
	assert_eq(
		r_low.get_eligible_event_ids(),
		["event.bird_shade_song", "event.cat_sleeping_bench"],
		"Exact 2 eligible events"
	)
	assert_eq(r_low.get_selected_event_id(), "event.bird_shade_song", "Roll 0.0 selects bird_shade_song")

	var r_mid: EventSelectionResult = EventSelectionService.evaluate_and_select_at(state, catalog, rng, 43200)
	assert_eq(r_mid.get_selected_event_id(), "event.bird_shade_song", "Roll 0.50 selects bird_shade_song")

	var r_threshold: EventSelectionResult = EventSelectionService.evaluate_and_select_at(state, catalog, rng, 43200)
	assert_eq(r_threshold.get_selected_event_id(), "event.cat_sleeping_bench", "Roll 0.60 selects cat_sleeping_bench")

	var r_high: EventSelectionResult = EventSelectionService.evaluate_and_select_at(state, catalog, rng, 43200)
	assert_eq(r_high.get_selected_event_id(), "event.cat_sleeping_bench", "Roll 0.99 selects cat_sleeping_bench")
