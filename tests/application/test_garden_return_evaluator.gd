## test_garden_return_evaluator.gd
## Unit tests for GardenReturnEvaluator application service.
class_name TestGardenReturnEvaluator
extends TestSuiteBase


class CountingClock extends FakeGameClock:
	var read_count: int = 0

	func _init(initial_utc: int = 1700000000) -> void:
		super._init(initial_utc, 0)

	func utc_now_seconds() -> int:
		read_count += 1
		return super.utc_now_seconds()


func _init() -> void:
	suite_name = "TestGardenReturnEvaluator"


func run_tests() -> void:
	_test_type_contract()
	_test_null_and_negative_inputs_rejected_before_sampling_clock()
	_test_evaluate_return_between_tracks_growth_maturity_and_atmosphere()
	_test_clock_rollback_and_zero_elapsed_safety()
	_test_read_only_no_auto_discovery_or_economy_mutation()


func _create_production_catalog() -> ContentCatalog:
	var plants: Array[PlantDefinition] = PlantContentLoader.new().load_production_definitions().get_definitions()
	var visitors: Array[VisitorDefinition] = VisitorContentLoader.new().load_production_definitions().get_definitions()
	var decorations: Array[DecorationDefinition] = DecorationContentLoader.new().load_production_definitions().get_definitions()
	var events: Array[EventDefinition] = EventContentLoader.new().load_production_definitions().get_definitions()
	return ContentCatalog.try_create(plants, visitors, decorations, events)


func _test_type_contract() -> void:
	describe("GardenReturnEvaluator extends RefCounted and is not Node or Resource")
	var evaluator: Variant = GardenReturnEvaluator.new()
	assert_true(evaluator is GardenReturnEvaluator, "Must be GardenReturnEvaluator")
	assert_true(evaluator is RefCounted, "Must extend RefCounted")
	assert_false(evaluator is Node, "Must not be a Node")
	assert_false(evaluator is Resource, "Must not be a Resource")


func _test_null_and_negative_inputs_rejected_before_sampling_clock() -> void:
	describe("Null dependencies or negative timestamps return null without sampling GameClock")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_production_catalog()
	var clock: CountingClock = CountingClock.new(2000)

	assert_true(
		GardenReturnEvaluator.evaluate_return_between(null, catalog, 1000, 2000) == null,
		"Null state rejected"
	)
	assert_true(
		GardenReturnEvaluator.evaluate_return_between(state, null, 1000, 2000) == null,
		"Null catalog rejected"
	)
	assert_true(
		GardenReturnEvaluator.evaluate_return_between(state, catalog, -1, 2000) == null,
		"Negative previous timestamp rejected"
	)
	assert_true(
		GardenReturnEvaluator.evaluate_return_between(state, catalog, 1000, -1) == null,
		"Negative current timestamp rejected"
	)

	assert_true(
		GardenReturnEvaluator.evaluate_return_from_now(null, catalog, clock, 1000) == null,
		"Null state in evaluate_return_from_now rejected"
	)
	assert_true(
		GardenReturnEvaluator.evaluate_return_from_now(state, null, clock, 1000) == null,
		"Null catalog in evaluate_return_from_now rejected"
	)
	assert_true(
		GardenReturnEvaluator.evaluate_return_from_now(state, catalog, null, 1000) == null,
		"Null clock in evaluate_return_from_now rejected"
	)
	assert_true(
		GardenReturnEvaluator.evaluate_return_from_now(state, catalog, clock, -1) == null,
		"Negative previous timestamp in evaluate_return_from_now rejected"
	)
	assert_eq(clock.read_count, 0, "Zero clock reads on invalid inputs")


func _test_evaluate_return_between_tracks_growth_maturity_and_atmosphere() -> void:
	describe("evaluate_return_between accurately computes plant stage advancement, newly matured plants, and atmosphere transitions")
	var catalog: ContentCatalog = _create_production_catalog()
	var state: GameState = GameState.new()
	# holy_basil: sprout=60, growing=180, mature=600
	# chili:      sprout=120, growing=480, mature=1200
	PlantRegistrationService.try_register_plant(state, catalog, "inst-basil", "plant.holy_basil", 1000)
	PlantRegistrationService.try_register_plant(state, catalog, "inst-chili", "plant.chili", 1000)

	# Return at t = 1600 (+600s):
	# - inst-basil: PLANTED -> MATURE (advanced + newly matured + ready to harvest)
	# - inst-chili: PLANTED -> GROWING (advanced, not yet mature)
	var summary1: GardenReturnSummary = GardenReturnEvaluator.evaluate_return_between(
		state,
		catalog,
		1000,
		1600
	)
	assert_true(summary1 != null and summary1.is_valid(), "Summary 1 is valid")
	assert_eq(summary1.get_elapsed_seconds(), 600, "Elapsed is 600s")
	assert_eq(summary1.get_advanced_plant_ids(), ["inst-basil", "inst-chili"], "Both plants advanced")
	assert_eq(summary1.get_newly_matured_plant_ids(), ["inst-basil"], "Only basil newly matured")
	assert_eq(summary1.get_ready_to_harvest_count(), 1, "1 plant ready to harvest")
	assert_true(summary1.has_plant_growth_changes(), "Plant growth changes detected")
	assert_true(summary1.has_meaningful_changes(), "Meaningful changes detected")

	# Return from t = 1600 to t = 2200 (+600s):
	# - inst-basil was ALREADY MATURE at t = 1600 -> does not count as newly advanced, still ready to harvest
	# - inst-chili advances GROWING -> MATURE (advanced + newly matured + ready to harvest)
	var clock: CountingClock = CountingClock.new(2200)
	var summary2: GardenReturnSummary = GardenReturnEvaluator.evaluate_return_from_now(
		state,
		catalog,
		clock,
		1600
	)
	assert_eq(clock.read_count, 1, "Clock sampled once in evaluate_return_from_now")
	assert_true(summary2 != null and summary2.is_valid(), "Summary 2 is valid")
	assert_eq(summary2.get_advanced_plant_ids(), ["inst-chili"], "Only chili advanced between 1600 and 2200")
	assert_eq(summary2.get_newly_matured_plant_ids(), ["inst-chili"], "Chili newly matured between 1600 and 2200")
	assert_eq(summary2.get_ready_to_harvest_count(), 2, "Both basil and chili are ready to harvest at 2200")


func _test_clock_rollback_and_zero_elapsed_safety() -> void:
	describe("Clock rollback (current < previous) clamps elapsed to 0 and reports zero false growth changes")
	var catalog: ContentCatalog = _create_production_catalog()
	var state: GameState = GameState.new()
	PlantRegistrationService.try_register_plant(state, catalog, "inst-basil", "plant.holy_basil", 1000)

	var rollback: GardenReturnSummary = GardenReturnEvaluator.evaluate_return_between(
		state,
		catalog,
		2000,
		1200
	)
	assert_true(rollback != null and rollback.is_valid(), "Rollback summary is valid")
	assert_true(rollback.was_clock_rolled_back(), "was_clock_rolled_back() is true")
	assert_eq(rollback.get_elapsed_seconds(), 0, "Elapsed clamped to 0")
	assert_eq(rollback.get_advanced_plant_count(), 0, "Zero advanced plants on rollback")
	assert_eq(rollback.get_newly_matured_plant_count(), 0, "Zero newly matured plants on rollback")
	assert_false(rollback.has_meaningful_changes(), "No meaningful changes reported on rollback")


func _test_read_only_no_auto_discovery_or_economy_mutation() -> void:
	describe("GardenReturnEvaluator is strictly read-only and never auto-discovers visitors or alters coins")
	var catalog: ContentCatalog = _create_production_catalog()
	var state: GameState = GameState.new()
	PlantRegistrationService.try_register_plant(state, catalog, "inst-marigold", "plant.marigold", 1000)
	var initial_discoveries: int = state.get_journal().get_count()
	var initial_coins: int = state.get_economy().get_currency()

	# Advance 10 days (864,000s) in O(1) time
	var summary: GardenReturnSummary = GardenReturnEvaluator.evaluate_return_between(
		state,
		catalog,
		1000,
		865000
	)
	assert_true(summary != null and summary.is_valid(), "10-day absence summary valid")
	assert_eq(state.get_journal().get_count(), initial_discoveries, "No offline visitors auto-discovered")
	assert_false(state.get_journal().has_discovered("visitor.butterfly"), "Butterfly not auto-discovered")
	assert_eq(state.get_economy().get_currency(), initial_coins, "Coins untouched by return evaluation")
