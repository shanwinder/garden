## test_plant_harvest_service.gd
## Unit tests for PlantHarvestResult and PlantHarvestService.
##
## Verifies:
## 1. Type contracts: RefCounted, not Node, not Resource.
## 2. PlantHarvestResult factory methods and getters for all statuses.
## 3. Successful harvest at exact MATURE boundary and after MATURE boundary:
##    - Grants exact harvest_reward to EconomyState.
##    - Resets PlantState planted_at to now_utc_seconds while preserving runtime_instance_id and definition_id.
##    - Preserves PlantCollectionState count and unrelated plants.
##    - Derived stage at now_utc_seconds immediately resets to PLANTED.
##    - Immediate second harvest at the same timestamp is rejected as PLANT_NOT_MATURE.
##    - Subsequent growth cycle matures again at now_utc_seconds + mature_after_seconds and can be harvested again.
## 4. Rejections leave GameState (both EconomyState and PlantCollectionState) untouched:
##    - INVALID_INPUT (null state, null catalog, empty runtime_instance_id, negative timestamp, null clock).
##    - PLANT_NOT_FOUND (missing runtime_instance_id).
##    - UNKNOWN_DEFINITION_ID (definition missing from catalog).
##    - PLANT_NOT_MATURE (PLANTED, SPROUT, GROWING, mature_after_seconds - 1).
##    - INVALID_REWARD (harvest_reward == 0).
##    - CURRENCY_GRANT_REJECTED (EconomyState.MAX_CURRENCY overflow atomicity).
## 5. try_harvest_now prevalidation samples GameClock.utc_now_seconds() 0 times on prevalidation failures
##    and exactly once on valid command execution.
class_name TestPlantHarvestService
extends TestSuiteBase


class CallCountingClock extends FakeGameClock:
	var utc_call_count: int = 0

	func _init(initial_utc: int) -> void:
		super(initial_utc, 0)

	func utc_now_seconds() -> int:
		utc_call_count += 1
		return super.utc_now_seconds()


func _init() -> void:
	suite_name = "TestPlantHarvestService"


func run_tests() -> void:
	_test_type_contracts()
	_test_result_factories_and_getters()
	_test_harvest_success_and_cycle_reset()
	_test_multi_cycle_harvest_accumulation()
	_test_not_mature_rejections_and_atomicity()
	_test_invalid_input_and_missing_plant_rejections()
	_test_unknown_definition_and_zero_reward_rejections()
	_test_currency_overflow_rejection_atomicity()
	_test_try_harvest_now_clock_sampling_contract()


func _create_catalog_with_rewards() -> ContentCatalog:
	var basil: PlantDefinition = PlantDefinition.new()
	basil.id = "plant.holy_basil"
	basil.sprout_after_seconds = 60
	basil.growing_after_seconds = 180
	basil.mature_after_seconds = 600
	basil.harvest_reward = 5

	var chili: PlantDefinition = PlantDefinition.new()
	chili.id = "plant.chili"
	chili.sprout_after_seconds = 120
	chili.growing_after_seconds = 480
	chili.mature_after_seconds = 1200
	chili.harvest_reward = 10

	return ContentCatalog.try_create([basil, chili])


func _test_type_contracts() -> void:
	describe("PlantHarvestService and PlantHarvestResult satisfy RefCounted contracts")
	var service: Variant = PlantHarvestService.new()
	assert_true(service is RefCounted, "PlantHarvestService must extend RefCounted")
	assert_false(service is Node, "PlantHarvestService must not be a Node")
	assert_false(service is Resource, "PlantHarvestService must not be a Resource")

	var result: Variant = PlantHarvestResult.invalid_input()
	assert_true(result is RefCounted, "PlantHarvestResult must extend RefCounted")
	assert_false(result is Node, "PlantHarvestResult must not be a Node")
	assert_false(result is Resource, "PlantHarvestResult must not be a Resource")


func _test_result_factories_and_getters() -> void:
	describe("PlantHarvestResult factories enforce status, plant, and reward invariants")
	var plant: PlantState = PlantState.new("inst-1", "plant.holy_basil", 1600)
	var ok: PlantHarvestResult = PlantHarvestResult.harvested(plant, 5)
	assert_eq(ok.get_status(), PlantHarvestResult.HARVESTED, "HARVESTED status")
	assert_true(ok.is_harvested(), "is_harvested() true on HARVESTED")
	assert_eq(ok.get_plant(), plant, "get_plant() returns exact PlantState")
	assert_eq(ok.get_reward_granted(), 5, "get_reward_granted() returns 5")

	var failures: Array[Dictionary] = [
		{"res": PlantHarvestResult.invalid_input(), "expected": PlantHarvestResult.INVALID_INPUT},
		{"res": PlantHarvestResult.plant_not_found(), "expected": PlantHarvestResult.PLANT_NOT_FOUND},
		{"res": PlantHarvestResult.unknown_definition_id(), "expected": PlantHarvestResult.UNKNOWN_DEFINITION_ID},
		{"res": PlantHarvestResult.plant_not_mature(), "expected": PlantHarvestResult.PLANT_NOT_MATURE},
		{"res": PlantHarvestResult.invalid_reward(), "expected": PlantHarvestResult.INVALID_REWARD},
		{"res": PlantHarvestResult.currency_grant_rejected(), "expected": PlantHarvestResult.CURRENCY_GRANT_REJECTED},
		{"res": PlantHarvestResult.state_update_rejected(), "expected": PlantHarvestResult.STATE_UPDATE_REJECTED},
	]
	for entry: Dictionary in failures:
		var r: PlantHarvestResult = entry["res"]
		var expected_status: PlantHarvestResult.Status = entry["expected"]
		assert_eq(r.get_status(), expected_status, "Failure status matches")
		assert_false(r.is_harvested(), "is_harvested() must be false on failure")
		assert_true(r.get_plant() == null, "get_plant() must be null on failure")
		assert_eq(r.get_reward_granted(), 0, "get_reward_granted() must be 0 on failure")


func _test_harvest_success_and_cycle_reset() -> void:
	describe("Harvesting a MATURE plant grants reward and resets planted_at to now_utc_seconds")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_catalog_with_rewards()
	var basil_orig: PlantState = PlantState.new("basil-1", "plant.holy_basil", 1000)
	var chili_orig: PlantState = PlantState.new("chili-1", "plant.chili", 1000)
	state.get_plants().try_add_plant(basil_orig)
	state.get_plants().try_add_plant(chili_orig)

	# At t = 1600 (exact mature boundary for holy_basil: 1000 + 600 = 1600)
	var res: PlantHarvestResult = PlantHarvestService.try_harvest_plant_at(
		state,
		catalog,
		"basil-1",
		1600
	)
	assert_true(res.is_harvested(), "Harvest at exact MATURE boundary must succeed")
	assert_eq(res.get_status(), PlantHarvestResult.HARVESTED, "Status must be HARVESTED")
	assert_eq(res.get_reward_granted(), 5, "Reward granted must be 5")
	assert_eq(state.get_economy().get_currency(), 5, "Economy currency must be 5")
	assert_eq(state.get_plants().get_count(), 2, "Collection count remains 2")

	var basil_after: PlantState = state.get_plants().get_plant("basil-1")
	assert_eq(res.get_plant(), basil_after, "Result plant matches stored PlantState reference")
	assert_eq(basil_after.get_runtime_instance_id(), "basil-1", "runtime_instance_id preserved")
	assert_eq(basil_after.get_definition_id(), "plant.holy_basil", "definition_id preserved")
	assert_eq(basil_after.get_planted_at(), 1600, "planted_at reset to harvest timestamp 1600")
	assert_eq(state.get_plants().get_plant("chili-1"), chili_orig, "Unrelated chili-1 untouched")

	# Derived stage at t = 1600 is now PLANTED again
	var basil_def: PlantDefinition = catalog.get_plant("plant.holy_basil")
	assert_eq(
		PlantGrowth.stage_for_state_at(basil_after, basil_def, 1600),
		PlantGrowth.Stage.PLANTED,
		"Reset plant stage at t = 1600 is PLANTED"
	)

	# Immediate second harvest at t = 1600 must be rejected as PLANT_NOT_MATURE
	var res_second: PlantHarvestResult = PlantHarvestService.try_harvest_plant_at(
		state,
		catalog,
		"basil-1",
		1600
	)
	assert_eq(res_second.get_status(), PlantHarvestResult.PLANT_NOT_MATURE, "Immediate repeat harvest rejected")
	assert_eq(state.get_economy().get_currency(), 5, "Currency remains 5 after rejected repeat harvest")


func _test_multi_cycle_harvest_accumulation() -> void:
	describe("Plant can be harvested across multiple full growth cycles and accumulates currency")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_catalog_with_rewards()
	state.get_plants().try_add_plant(PlantState.new("basil-1", "plant.holy_basil", 1000))

	# Cycle 1 harvest at t = 1700 (elapsed 700 >= 600)
	var r1: PlantHarvestResult = PlantHarvestService.try_harvest_plant_at(state, catalog, "basil-1", 1700)
	assert_true(r1.is_harvested(), "Cycle 1 harvest succeeds")
	assert_eq(state.get_economy().get_currency(), 5, "Currency is 5 after cycle 1")
	assert_eq(state.get_plants().get_plant("basil-1").get_planted_at(), 1700, "Cycle 2 starts at 1700")

	# Not yet mature at t = 2299 (elapsed 599 < 600)
	var r_early: PlantHarvestResult = PlantHarvestService.try_harvest_plant_at(state, catalog, "basil-1", 2299)
	assert_eq(r_early.get_status(), PlantHarvestResult.PLANT_NOT_MATURE, "Not mature at +599s")
	assert_eq(state.get_economy().get_currency(), 5, "Currency unchanged")

	# Cycle 2 harvest at t = 2300 (elapsed 600 >= 600)
	var r2: PlantHarvestResult = PlantHarvestService.try_harvest_plant_at(state, catalog, "basil-1", 2300)
	assert_true(r2.is_harvested(), "Cycle 2 harvest succeeds at +600s")
	assert_eq(state.get_economy().get_currency(), 10, "Currency accumulates to 10 after cycle 2")
	assert_eq(state.get_plants().get_plant("basil-1").get_planted_at(), 2300, "Cycle 3 starts at 2300")


func _test_not_mature_rejections_and_atomicity() -> void:
	describe("Harvesting at PLANTED, SPROUT, or GROWING returns PLANT_NOT_MATURE with zero mutation")
	var state: GameState = GameState.new()
	state.get_economy().grant_currency(20)
	var catalog: ContentCatalog = _create_catalog_with_rewards()
	var orig_plant: PlantState = PlantState.new("basil-1", "plant.holy_basil", 1000)
	state.get_plants().try_add_plant(orig_plant)

	# Test timestamps: 1000 (PLANTED), 1059 (PLANTED), 1060 (SPROUT), 1180 (GROWING), 1599 (GROWING)
	for ts: int in [1000, 1059, 1060, 1180, 1599]:
		var res: PlantHarvestResult = PlantHarvestService.try_harvest_plant_at(state, catalog, "basil-1", ts)
		assert_eq(res.get_status(), PlantHarvestResult.PLANT_NOT_MATURE, "Must reject at t = %d" % ts)
		assert_false(res.is_harvested(), "is_harvested() false at t = %d" % ts)
		assert_eq(state.get_economy().get_currency(), 20, "Currency remains 20 at t = %d" % ts)
		assert_eq(state.get_plants().get_plant("basil-1"), orig_plant, "Original PlantState preserved at t = %d" % ts)


func _test_invalid_input_and_missing_plant_rejections() -> void:
	describe("Invalid inputs and missing plant IDs are rejected with zero mutation")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_catalog_with_rewards()
	var orig_plant: PlantState = PlantState.new("basil-1", "plant.holy_basil", 1000)
	state.get_plants().try_add_plant(orig_plant)

	assert_eq(
		PlantHarvestService.try_harvest_plant_at(null, catalog, "basil-1", 2000).get_status(),
		PlantHarvestResult.INVALID_INPUT,
		"Null state -> INVALID_INPUT"
	)
	assert_eq(
		PlantHarvestService.try_harvest_plant_at(state, null, "basil-1", 2000).get_status(),
		PlantHarvestResult.INVALID_INPUT,
		"Null catalog -> INVALID_INPUT"
	)
	assert_eq(
		PlantHarvestService.try_harvest_plant_at(state, catalog, "", 2000).get_status(),
		PlantHarvestResult.INVALID_INPUT,
		"Empty runtime_instance_id -> INVALID_INPUT"
	)
	assert_eq(
		PlantHarvestService.try_harvest_plant_at(state, catalog, "basil-1", -1).get_status(),
		PlantHarvestResult.INVALID_INPUT,
		"Negative timestamp -> INVALID_INPUT"
	)
	assert_eq(
		PlantHarvestService.try_harvest_plant_at(state, catalog, "missing-id", 2000).get_status(),
		PlantHarvestResult.PLANT_NOT_FOUND,
		"Missing runtime_instance_id -> PLANT_NOT_FOUND"
	)
	assert_eq(state.get_economy().get_currency(), 0, "Economy remains 0")
	assert_eq(state.get_plants().get_plant("basil-1"), orig_plant, "Plant preserved")


func _test_unknown_definition_and_zero_reward_rejections() -> void:
	describe("Unknown definition ID and zero harvest_reward definitions are rejected safely")
	var state: GameState = GameState.new()
	var basil_zero_reward: PlantDefinition = PlantDefinition.new()
	basil_zero_reward.id = "plant.holy_basil"
	basil_zero_reward.sprout_after_seconds = 60
	basil_zero_reward.growing_after_seconds = 180
	basil_zero_reward.mature_after_seconds = 600
	basil_zero_reward.harvest_reward = 0
	var catalog: ContentCatalog = ContentCatalog.try_create([basil_zero_reward])

	var basil_plant: PlantState = PlantState.new("basil-1", "plant.holy_basil", 1000)
	var unknown_plant: PlantState = PlantState.new("unk-1", "plant.jasmine", 1000)
	state.get_plants().try_add_plant(basil_plant)
	state.get_plants().try_add_plant(unknown_plant)

	# Unknown definition in catalog -> UNKNOWN_DEFINITION_ID
	var res_unk: PlantHarvestResult = PlantHarvestService.try_harvest_plant_at(state, catalog, "unk-1", 5000)
	assert_eq(res_unk.get_status(), PlantHarvestResult.UNKNOWN_DEFINITION_ID, "Missing definition -> UNKNOWN_DEFINITION_ID")

	# Zero reward on mature plant -> INVALID_REWARD
	var res_zero: PlantHarvestResult = PlantHarvestService.try_harvest_plant_at(state, catalog, "basil-1", 2000)
	assert_eq(res_zero.get_status(), PlantHarvestResult.INVALID_REWARD, "Zero harvest_reward -> INVALID_REWARD")
	assert_eq(state.get_economy().get_currency(), 0, "Currency remains 0")
	assert_eq(state.get_plants().get_plant("basil-1"), basil_plant, "Original basil_plant reference preserved")


func _test_currency_overflow_rejection_atomicity() -> void:
	describe("Economy overflow returns CURRENCY_GRANT_REJECTED without resetting plant cycle")
	var state: GameState = GameState.new()
	state.get_economy().grant_currency(EconomyState.MAX_CURRENCY - 2)
	var catalog: ContentCatalog = _create_catalog_with_rewards()
	var orig_plant: PlantState = PlantState.new("basil-1", "plant.holy_basil", 1000)
	state.get_plants().try_add_plant(orig_plant)

	# Reward is 5, which would exceed MAX_CURRENCY - 2
	var res: PlantHarvestResult = PlantHarvestService.try_harvest_plant_at(state, catalog, "basil-1", 2000)
	assert_eq(res.get_status(), PlantHarvestResult.CURRENCY_GRANT_REJECTED, "Overflow -> CURRENCY_GRANT_REJECTED")
	assert_false(res.is_harvested(), "is_harvested() false")
	assert_eq(
		state.get_economy().get_currency(),
		EconomyState.MAX_CURRENCY - 2,
		"Currency remains at MAX_CURRENCY - 2"
	)
	assert_eq(
		state.get_plants().get_plant("basil-1"),
		orig_plant,
		"PlantState is NOT reset when currency grant is rejected"
	)


func _test_try_harvest_now_clock_sampling_contract() -> void:
	describe("try_harvest_now prevalidates before sampling clock and samples clock once on valid command")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_catalog_with_rewards()
	var orig_plant: PlantState = PlantState.new("basil-1", "plant.holy_basil", 1000)
	var unknown_plant: PlantState = PlantState.new("unk-1", "plant.jasmine", 1000)
	state.get_plants().try_add_plant(orig_plant)
	state.get_plants().try_add_plant(unknown_plant)

	var clock: CallCountingClock = CallCountingClock.new(1600)

	# Prevalidation failures must NOT sample clock
	assert_eq(
		PlantHarvestService.try_harvest_now(null, catalog, clock, "basil-1").get_status(),
		PlantHarvestResult.INVALID_INPUT,
		"Null state -> INVALID_INPUT"
	)
	assert_eq(
		PlantHarvestService.try_harvest_now(state, catalog, null, "basil-1").get_status(),
		PlantHarvestResult.INVALID_INPUT,
		"Null clock -> INVALID_INPUT"
	)
	assert_eq(
		PlantHarvestService.try_harvest_now(state, catalog, clock, "").get_status(),
		PlantHarvestResult.INVALID_INPUT,
		"Empty ID -> INVALID_INPUT"
	)
	assert_eq(
		PlantHarvestService.try_harvest_now(state, catalog, clock, "missing-id").get_status(),
		PlantHarvestResult.PLANT_NOT_FOUND,
		"Missing plant -> PLANT_NOT_FOUND"
	)
	assert_eq(
		PlantHarvestService.try_harvest_now(state, catalog, clock, "unk-1").get_status(),
		PlantHarvestResult.UNKNOWN_DEFINITION_ID,
		"Unknown definition -> UNKNOWN_DEFINITION_ID"
	)
	assert_eq(clock.utc_call_count, 0, "Clock must not be sampled on any prevalidation failure")

	# Valid harvest command samples clock exactly once
	var res_ok: PlantHarvestResult = PlantHarvestService.try_harvest_now(state, catalog, clock, "basil-1")
	assert_true(res_ok.is_harvested(), "Valid harvest succeeds")
	assert_eq(clock.utc_call_count, 1, "Clock sampled exactly once")
	assert_eq(state.get_economy().get_currency(), 5, "Reward 5 granted")
	assert_eq(state.get_plants().get_plant("basil-1").get_planted_at(), 1600, "planted_at updated to clock timestamp")
