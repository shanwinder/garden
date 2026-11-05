## test_decoration_purchase_service.gd
## Unit tests for DecorationPurchaseService, DecorationPurchaseResult, and DecorationRuntimeIdGenerator.
class_name TestDecorationPurchaseService
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestDecorationPurchaseService"


func run_tests() -> void:
	_test_type_contracts()
	_test_successful_purchase_and_placement()
	_test_insufficient_currency_and_invalid_inputs()
	_test_id_collision_retry_and_exhaustion()


func _create_catalog() -> ContentCatalog:
	var p_res: PlantContentLoadResult = PlantContentLoader.new().load_production_definitions()
	var v_res: VisitorContentLoadResult = VisitorContentLoader.new().load_production_definitions()
	var d_res: DecorationContentLoadResult = DecorationContentLoader.new().load_production_definitions()
	return ContentCatalog.try_create(
		p_res.get_definitions(),
		v_res.get_definitions(),
		d_res.get_definitions()
	)


func _test_type_contracts() -> void:
	describe("DecorationPurchaseService, DecorationPurchaseResult, and DecorationRuntimeIdGenerator satisfy RefCounted contracts")
	var svc: DecorationPurchaseService = DecorationPurchaseService.new()
	assert_true(svc is DecorationPurchaseService and svc is RefCounted, "Service is RefCounted")
	var gen: DecorationRuntimeIdGenerator = DecorationRuntimeIdGenerator.new()
	assert_true(gen is DecorationRuntimeIdGenerator and gen is RefCounted, "Generator is RefCounted")
	var res: DecorationPurchaseResult = DecorationPurchaseResult.invalid_input()
	assert_true(res is DecorationPurchaseResult and res is RefCounted, "Result is RefCounted")


func _test_successful_purchase_and_placement() -> void:
	describe("try_purchase_and_place_now deducts exact price and registers DecorationState")
	var catalog: ContentCatalog = _create_catalog()
	var state: GameState = GameState.new()
	state.get_economy().grant_currency(40)
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])

	var res: DecorationPurchaseResult = DecorationPurchaseService.try_purchase_and_place_now(
		state, catalog, clock, rng, "decoration.clay_jar"
	)
	assert_true(res.is_purchased(), "Purchase succeeds")
	assert_eq(res.get_status(), DecorationPurchaseResult.PURCHASED, "Status is PURCHASED")
	assert_eq(res.get_price_spent(), 15, "Spent 15 coins")
	assert_eq(state.get_economy().get_currency(), 25, "Balance reduced to 25")
	assert_eq(state.get_decorations().get_count(), 1, "1 decoration in state")
	assert_eq(
		res.get_decoration().get_runtime_instance_id(),
		"decor-inst-00000001000000020000000300000004",
		"Generated runtime instance ID matches format"
	)
	assert_eq(res.get_decoration().get_definition_id(), "decoration.clay_jar", "Definition ID matches")
	assert_eq(res.get_decoration().get_placed_at(), 1700000000, "Placed_at matches")


func _test_insufficient_currency_and_invalid_inputs() -> void:
	describe("DecorationPurchaseService rejects insufficient currency, unknown IDs, and invalid inputs without state mutation")
	var catalog: ContentCatalog = _create_catalog()
	var state: GameState = GameState.new()
	state.get_economy().grant_currency(14) # 1 coin short for clay_jar (15)
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])

	var r_poor: DecorationPurchaseResult = DecorationPurchaseService.try_purchase_and_place_now(
		state, catalog, clock, rng, "decoration.clay_jar"
	)
	assert_eq(r_poor.get_status(), DecorationPurchaseResult.INSUFFICIENT_CURRENCY, "INSUFFICIENT_CURRENCY")
	assert_false(r_poor.is_purchased(), "Not purchased")
	assert_eq(state.get_economy().get_currency(), 14, "Balance unchanged at 14")
	assert_eq(state.get_decorations().get_count(), 0, "0 decorations")

	var r_unk: DecorationPurchaseResult = DecorationPurchaseService.try_purchase_and_place_at(
		state, catalog, "dec-1", "decoration.unknown_fountain", 1000
	)
	assert_eq(r_unk.get_status(), DecorationPurchaseResult.UNKNOWN_DEFINITION_ID, "UNKNOWN_DEFINITION_ID")

	var r_ns: DecorationPurchaseResult = DecorationPurchaseService.try_purchase_and_place_at(
		state, catalog, "dec-1", "plant.holy_basil", 1000
	)
	assert_eq(r_ns.get_status(), DecorationPurchaseResult.INVALID_INPUT, "Plant namespace rejected as INVALID_INPUT")

	var r_neg_ts: DecorationPurchaseResult = DecorationPurchaseService.try_purchase_and_place_at(
		state, catalog, "dec-1", "decoration.clay_jar", -1
	)
	assert_eq(r_neg_ts.get_status(), DecorationPurchaseResult.INVALID_INPUT, "Negative timestamp rejected")


func _test_id_collision_retry_and_exhaustion() -> void:
	describe("DecorationRuntimeIdGenerator retries on collision and returns ID_GENERATION_FAILED after 8 collisions without charging coins")
	var catalog: ContentCatalog = _create_catalog()
	var state: GameState = GameState.new()
	state.get_economy().grant_currency(100)
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)

	# Pre-populate 8 colliding decoration runtime IDs
	var draws: Array[int] = []
	for i: int in range(1, 9):
		var existing_id: String = "%s%08x%08x%08x%08x" % [DecorationRuntimeIdGenerator.ID_PREFIX, i, i, i, i]
		state.get_decorations().try_add_decoration(
			DecorationState.new(existing_id, "decoration.plant_pot", 500)
		)
		draws.append_array([i, i, i, i])

	var rng_fail: FakeRandomSource = FakeRandomSource.new([], draws)
	var res_fail: DecorationPurchaseResult = DecorationPurchaseService.try_purchase_and_place_now(
		state, catalog, clock, rng_fail, "decoration.clay_jar"
	)
	assert_eq(res_fail.get_status(), DecorationPurchaseResult.ID_GENERATION_FAILED, "ID_GENERATION_FAILED after 8 collisions")
	assert_eq(state.get_economy().get_currency(), 100, "Coins not deducted when ID generation fails")
	assert_eq(state.get_decorations().get_count(), 8, "Count remains 8")
