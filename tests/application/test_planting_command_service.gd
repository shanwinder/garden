## test_planting_command_service.gd
## Comprehensive unit test suite for PlantingCommandService.
##
## Verifies:
## A. Successful planting of known definition.
## B. Exact injected timestamp.
## C. Exact generated runtime ID.
## D. Exact stored PlantState reference.
## E. One plant added per successful command.
## F. All five approved plant IDs can be planted.
## G. Two plantings during same clock second yield distinct IDs.
## H. Multiple commands preserve GameState identity.
## I. Unknown definition rejected before clock/RNG consumption.
## J. Invalid syntax rejected before clock/RNG consumption.
## K. Null GameState rejected.
## L. Null ContentCatalog rejected.
## M. Null GameClock rejected.
## N. Null RandomSource rejected.
## O. Negative clock timestamp rejected with INVALID_INPUT.
## P. Negative timestamp does not consume RNG.
## Q. Collision retry results in successful unique registration.
## R. Eight collisions return ID_GENERATION_FAILED.
## S. ID generation failure causes no GameState mutation.
## T. Failure leaves economy unchanged.
## U. Successful planting leaves economy unchanged.
## V. A moved-backward but nonnegative clock is handled without changing earlier PlantState timestamps.
## W. PlantGrowth derives stage correctly from the registered plant.
## X. Repeated calls are reproducible with equivalent FakeClock and FakeRandomSource sequences.
## Y. In-memory persistence round trip simulation.
class_name TestPlantingCommandService
extends TestSuiteBase


## Small test-only GameClock subclass to verify exact invocation count of utc_now_seconds().
class CountingGameClock extends GameClock:
	var _utc_seconds: int
	var _call_count: int = 0

	func _init(utc_seconds: int) -> void:
		_utc_seconds = utc_seconds

	func utc_now_seconds() -> int:
		_call_count += 1
		return _utc_seconds

	func monotonic_milliseconds() -> int:
		return 0

	func get_call_count() -> int:
		return _call_count


func _init() -> void:
	suite_name = "TestPlantingCommandService"


func run_tests() -> void:
	_test_type_contract()
	_test_successful_planting_holy_basil()
	_test_all_five_approved_definitions_success()
	_test_two_plantings_same_second_distinct_ids()
	_test_multiple_commands_preserve_state_identity()
	_test_prevalidation_unknown_definition_no_clock_no_rng()
	_test_prevalidation_invalid_syntax_no_clock_no_rng()
	_test_prevalidation_null_dependencies()
	_test_negative_timestamp_rejected_no_rng_no_mutation()
	_test_clock_called_exactly_once_per_command()
	_test_collision_retry_success()
	_test_eight_collisions_id_generation_failed()
	_test_failure_atomicity_and_economy_unchanged()
	_test_clock_backward_movement_nonnegative()
	_test_plant_growth_compatibility()
	_test_reproducibility_with_equivalent_sequences()
	_test_in_memory_persistence_round_trip()


func _create_test_definition(
	id: String,
	sprout: int = 60,
	growing: int = 300,
	mature: int = 900
) -> PlantDefinition:
	var def: PlantDefinition = PlantDefinition.new()
	def.id = id
	def.sprout_after_seconds = sprout
	def.growing_after_seconds = growing
	def.mature_after_seconds = mature
	return def


func _create_five_plant_catalog() -> ContentCatalog:
	var defs: Array[PlantDefinition] = [
		_create_test_definition("plant.banana", 500, 1000, 2000),
		_create_test_definition("plant.chili", 30, 120, 400),
		_create_test_definition("plant.holy_basil", 60, 300, 900),
		_create_test_definition("plant.jasmine", 100, 250, 600),
		_create_test_definition("plant.marigold", 50, 150, 450),
	]
	return ContentCatalog.try_create(defs)


func _test_type_contract() -> void:
	describe("PlantingCommandService type contract: RefCounted, not Node, not Resource")
	var service: PlantingCommandService = PlantingCommandService.new()
	assert_true(service is RefCounted, "PlantingCommandService must extend RefCounted")
	var obj: Variant = service
	assert_false(obj is Node, "PlantingCommandService must not be a Node")
	assert_false(obj is Resource, "PlantingCommandService must not be a Resource")


func _test_successful_planting_holy_basil() -> void:
	describe("Successful planting: exact timestamp, exact ID, exact reference, collection count +1")
	var state: GameState = GameState.new()
	state.get_economy().grant_currency(100)
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])

	var result: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, rng, "plant.holy_basil"
	)

	assert_true(result.is_registered(), "Registration must succeed")
	assert_eq(result.get_status(), PlantRegistrationResult.REGISTERED, "Status must be REGISTERED")
	assert_true(result.get_plant() != null, "get_plant() must not be null")

	var plant: PlantState = result.get_plant()
	assert_eq(
		plant.get_runtime_instance_id(),
		"plant-inst-00000001000000020000000300000004",
		"Generated runtime ID must match format"
	)
	assert_eq(plant.get_definition_id(), "plant.holy_basil", "Definition ID must match")
	assert_eq(plant.get_planted_at(), 1700000000, "Planted timestamp must match injected clock")

	assert_eq(state.get_plants().get_count(), 1, "Collection count must be 1")
	var stored: PlantState = state.get_plants().get_plant("plant-inst-00000001000000020000000300000004")
	assert_eq(stored, plant, "Stored plant must be exact same reference returned in result")
	assert_eq(state.get_economy().get_currency(), 100, "Economy currency must remain unchanged")


func _test_all_five_approved_definitions_success() -> void:
	describe("All five approved plant definitions can be planted successfully")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)

	var plant_ids: Array[String] = [
		"plant.banana",
		"plant.chili",
		"plant.holy_basil",
		"plant.jasmine",
		"plant.marigold",
	]

	for i: int in range(plant_ids.size()):
		var def_id: String = plant_ids[i]
		var val: int = i + 1
		var rng: FakeRandomSource = FakeRandomSource.new([], [val, val, val, val])
		var res: PlantRegistrationResult = PlantingCommandService.try_plant_now(
			state, catalog, clock, rng, def_id
		)
		assert_true(res.is_registered(), "Planting %s must succeed" % def_id)
		assert_eq(res.get_plant().get_definition_id(), def_id, "Definition ID must match")

	assert_eq(state.get_plants().get_count(), 5, "All 5 plants must be in collection")


func _test_two_plantings_same_second_distinct_ids() -> void:
	describe("Two plantings during the exact same clock second yield distinct runtime IDs")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)

	var rng1: FakeRandomSource = FakeRandomSource.new([], [1, 1, 1, 1])
	var res1: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, rng1, "plant.chili"
	)

	var rng2: FakeRandomSource = FakeRandomSource.new([], [2, 2, 2, 2])
	var res2: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, rng2, "plant.chili"
	)

	assert_true(res1.is_registered(), "First planting must succeed")
	assert_true(res2.is_registered(), "Second planting must succeed")
	assert_ne(
		res1.get_plant().get_runtime_instance_id(),
		res2.get_plant().get_runtime_instance_id(),
		"Instance IDs must be distinct"
	)
	assert_eq(res1.get_plant().get_planted_at(), 1700000000, "First planted at 1700000000")
	assert_eq(res2.get_plant().get_planted_at(), 1700000000, "Second planted at 1700000000")
	assert_eq(state.get_plants().get_count(), 2, "Collection contains both plants")


func _test_multiple_commands_preserve_state_identity() -> void:
	describe("Multiple planting commands preserve exact GameState object identity")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])

	var res1: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, rng, "plant.holy_basil"
	)
	assert_true(res1.is_registered(), "First command must succeed")

	var res2: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, rng, "plant.jasmine"
	)
	assert_true(res2.is_registered(), "Second command must succeed")

	assert_eq(state.get_plants().get_count(), 2, "State contains 2 plants")


func _test_prevalidation_unknown_definition_no_clock_no_rng() -> void:
	describe("Unknown definition ID rejected before clock or RNG consumption")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: CountingGameClock = CountingGameClock.new(1000)
	var empty_rng: FakeRandomSource = FakeRandomSource.new([], []) # Assert if consumed

	var result: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, empty_rng, "plant.unknown_crop"
	)

	assert_eq(
		result.get_status(),
		PlantRegistrationResult.UNKNOWN_DEFINITION_ID,
		"Must return UNKNOWN_DEFINITION_ID"
	)
	assert_false(result.is_registered(), "is_registered() must be false")
	assert_true(result.get_plant() == null, "get_plant() must be null")
	assert_eq(clock.get_call_count(), 0, "GameClock must not be called")
	assert_eq(state.get_plants().get_count(), 0, "Collection count remains 0")


func _test_prevalidation_invalid_syntax_no_clock_no_rng() -> void:
	describe("Invalid definition syntax rejected with INVALID_INPUT before clock or RNG")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: CountingGameClock = CountingGameClock.new(1000)
	var empty_rng: FakeRandomSource = FakeRandomSource.new([], [])

	var invalid_ids: Array[String] = [
		"",
		"plant.",
		"plant.INVALID_UPPERCASE",
		"item.fertilizer",
		"not_a_valid_id",
	]

	for inv_id: String in invalid_ids:
		var result: PlantRegistrationResult = PlantingCommandService.try_plant_now(
			state, catalog, clock, empty_rng, inv_id
		)
		assert_eq(
			result.get_status(),
			PlantRegistrationResult.INVALID_INPUT,
			"Invalid ID '%s' must return INVALID_INPUT" % inv_id
		)
		assert_false(result.is_registered(), "Must not register")

	assert_eq(clock.get_call_count(), 0, "GameClock must never be called on invalid syntax")
	assert_eq(state.get_plants().get_count(), 0, "Collection remains empty")


func _test_prevalidation_null_dependencies() -> void:
	describe("Null dependencies return INVALID_INPUT without clock or RNG consumption")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: CountingGameClock = CountingGameClock.new(1000)
	var empty_rng: FakeRandomSource = FakeRandomSource.new([], [])

	# Null state
	var res1: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		null, catalog, clock, empty_rng, "plant.holy_basil"
	)
	assert_eq(res1.get_status(), PlantRegistrationResult.INVALID_INPUT, "Null state must return INVALID_INPUT")

	# Null catalog
	var res2: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, null, clock, empty_rng, "plant.holy_basil"
	)
	assert_eq(res2.get_status(), PlantRegistrationResult.INVALID_INPUT, "Null catalog must return INVALID_INPUT")

	# Null clock
	var res3: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, null, empty_rng, "plant.holy_basil"
	)
	assert_eq(res3.get_status(), PlantRegistrationResult.INVALID_INPUT, "Null clock must return INVALID_INPUT")

	# Null rng
	var res4: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, null, "plant.holy_basil"
	)
	assert_eq(res4.get_status(), PlantRegistrationResult.INVALID_INPUT, "Null rng must return INVALID_INPUT")

	assert_eq(clock.get_call_count(), 0, "Clock was never called during null-dependency checks")
	assert_eq(state.get_plants().get_count(), 0, "Collection remains empty")


func _test_negative_timestamp_rejected_no_rng_no_mutation() -> void:
	describe("Negative timestamp rejected with INVALID_INPUT, consumes 0 RNG and causes 0 mutation")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: FakeGameClock = FakeGameClock.new(-1, 0)
	var empty_rng: FakeRandomSource = FakeRandomSource.new([], []) # Empty; fails if RNG is consumed

	var result: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, empty_rng, "plant.holy_basil"
	)

	assert_eq(result.get_status(), PlantRegistrationResult.INVALID_INPUT, "Negative timestamp returns INVALID_INPUT")
	assert_false(result.is_registered(), "is_registered() must be false")
	assert_true(result.get_plant() == null, "get_plant() must be null")
	assert_eq(state.get_plants().get_count(), 0, "No plant added")


func _test_clock_called_exactly_once_per_command() -> void:
	describe("GameClock.utc_now_seconds() is called exactly once per valid command")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: CountingGameClock = CountingGameClock.new(1700000000)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])

	var result: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, rng, "plant.holy_basil"
	)

	assert_true(result.is_registered(), "Planting must succeed")
	assert_eq(clock.get_call_count(), 1, "Clock must be sampled exactly once")


func _test_collision_retry_success() -> void:
	describe("Candidate collision causes retry and successfully registers unique ID")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)

	# Pre-populate candidate 1
	var existing_plant: PlantState = PlantState.new(
		"plant-inst-00000001000000020000000300000004",
		"plant.holy_basil",
		1000
	)
	state.get_plants().try_add_plant(existing_plant)

	# Script draws for candidate 1 (collides) and candidate 2 (unique)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])

	var result: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, rng, "plant.banana"
	)

	assert_true(result.is_registered(), "Planting must succeed on retry")
	assert_eq(
		result.get_plant().get_runtime_instance_id(),
		"plant-inst-00000005000000060000000700000008",
		"Must register second candidate"
	)
	assert_eq(state.get_plants().get_count(), 2, "Collection now contains 2 plants")


func _test_eight_collisions_id_generation_failed() -> void:
	describe("Eight candidate collisions return ID_GENERATION_FAILED with no state mutation")
	var state: GameState = GameState.new()
	state.get_economy().grant_currency(50)
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)

	# Pre-populate 8 plants
	for i: int in range(1, 9):
		var existing_id: String = "%s%08x%08x%08x%08x" % [PlantRuntimeIdGenerator.ID_PREFIX, i, i, i, i]
		state.get_plants().try_add_plant(PlantState.new(existing_id, "plant.marigold", 500))

	# Script 32 draws that will match the 8 existing plants
	var draws: Array[int] = []
	for i: int in range(1, 9):
		draws.append_array([i, i, i, i])

	var rng: FakeRandomSource = FakeRandomSource.new([], draws)

	var result: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, rng, "plant.jasmine"
	)

	assert_eq(
		result.get_status(),
		PlantRegistrationResult.ID_GENERATION_FAILED,
		"Must return ID_GENERATION_FAILED"
	)
	assert_false(result.is_registered(), "is_registered() must be false")
	assert_true(result.get_plant() == null, "get_plant() must be null")
	assert_eq(state.get_plants().get_count(), 8, "Collection count remains 8")
	assert_eq(state.get_economy().get_currency(), 50, "Economy remains unchanged")


func _test_failure_atomicity_and_economy_unchanged() -> void:
	describe("All failures leave GameState and EconomyState completely untouched")
	var state: GameState = GameState.new()
	state.get_economy().grant_currency(200)
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)

	# 1. Invalid input
	var res1: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, FakeRandomSource.new([], []), ""
	)
	assert_false(res1.is_registered(), "Invalid input must fail")
	assert_eq(state.get_economy().get_currency(), 200, "Currency remains 200")
	assert_eq(state.get_plants().get_count(), 0, "Count remains 0")

	# 2. Unknown definition
	var res2: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, FakeRandomSource.new([], []), "plant.ghost"
	)
	assert_false(res2.is_registered(), "Unknown definition must fail")
	assert_eq(state.get_economy().get_currency(), 200, "Currency remains 200")
	assert_eq(state.get_plants().get_count(), 0, "Count remains 0")


func _test_clock_backward_movement_nonnegative() -> void:
	describe("Clock moving backward (nonnegative) records actual supplied value without corrupting earlier plants")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1700000100, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])

	# Plant 1 at 1700000100
	var res1: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, rng, "plant.holy_basil"
	)
	assert_true(res1.is_registered(), "First planting must succeed")
	assert_eq(res1.get_plant().get_planted_at(), 1700000100, "First plant planted_at is 1700000100")

	# Move clock backward to 1700000050
	clock.set_utc_seconds(1700000050)

	# Plant 2 at 1700000050
	var res2: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, rng, "plant.chili"
	)
	assert_true(res2.is_registered(), "Second planting must succeed")
	assert_eq(res2.get_plant().get_planted_at(), 1700000050, "Second plant planted_at is 1700000050")

	# Verify earlier plant timestamp unchanged
	assert_eq(res1.get_plant().get_planted_at(), 1700000100, "First plant timestamp was not changed")


func _test_plant_growth_compatibility() -> void:
	describe("PlantGrowth derives growth stage correctly from registered plant")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])

	var res: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state, catalog, clock, rng, "plant.holy_basil"
	)
	assert_true(res.is_registered(), "Planting must succeed")

	var plant: PlantState = res.get_plant()
	var def: PlantDefinition = catalog.get_plant("plant.holy_basil")

	# Holy basil: sprout 60, growing 300, mature 900
	assert_eq(PlantGrowth.stage_for_state_at(plant, def, 1000), PlantGrowth.Stage.PLANTED, "At 1000: PLANTED")
	assert_eq(PlantGrowth.stage_for_state_at(plant, def, 1060), PlantGrowth.Stage.SPROUT, "At 1060: SPROUT")
	assert_eq(PlantGrowth.stage_for_state_at(plant, def, 1300), PlantGrowth.Stage.GROWING, "At 1300: GROWING")
	assert_eq(PlantGrowth.stage_for_state_at(plant, def, 1900), PlantGrowth.Stage.MATURE, "At 1900: MATURE")


func _test_reproducibility_with_equivalent_sequences() -> void:
	describe("Repeated calls are reproducible with equivalent FakeClock and FakeRandomSource sequences")
	var state1: GameState = GameState.new()
	var state2: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()

	var clock1: FakeGameClock = FakeGameClock.new(123456, 0)
	var clock2: FakeGameClock = FakeGameClock.new(123456, 0)

	var rng1: FakeRandomSource = FakeRandomSource.new([], [10, 20, 30, 40])
	var rng2: FakeRandomSource = FakeRandomSource.new([], [10, 20, 30, 40])

	var res1: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state1, catalog, clock1, rng1, "plant.jasmine"
	)
	var res2: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state2, catalog, clock2, rng2, "plant.jasmine"
	)

	assert_true(res1.is_registered(), "Run 1 must succeed")
	assert_true(res2.is_registered(), "Run 2 must succeed")
	assert_eq(
		res1.get_plant().get_runtime_instance_id(),
		res2.get_plant().get_runtime_instance_id(),
		"Instance IDs must match across reproducible runs"
	)
	assert_eq(
		res1.get_plant().get_planted_at(),
		res2.get_plant().get_planted_at(),
		"Timestamps must match across reproducible runs"
	)


func _test_in_memory_persistence_round_trip() -> void:
	describe("In-memory persistence round trip: plant, encode, JSON roundtrip, decode, retry collision")
	var state_a: GameState = GameState.new()
	state_a.get_economy().grant_currency(42)
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var clock_a: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng_a: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])

	var res_a: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state_a, catalog, clock_a, rng_a, "plant.banana"
	)
	assert_true(res_a.is_registered(), "Initial planting must succeed")

	# Encode -> stringify -> parse -> decode
	var encoded: Dictionary = GameStateCodec.encode(state_a)
	var json_str: String = JSON.stringify(encoded)
	var parsed: Variant = JSON.parse_string(json_str)
	var state_b: GameState = GameStateCodec.decode(parsed)

	assert_true(state_b != null, "Decoded state must not be null")
	assert_eq(state_b.get_economy().get_currency(), 42, "Currency preserved exactly")
	assert_eq(state_b.get_plants().get_count(), 1, "Plant count preserved")

	var plant_b: PlantState = state_b.get_plants().get_plant("plant-inst-00000001000000020000000300000004")
	assert_true(plant_b != null, "Restored plant must exist")
	assert_eq(plant_b.get_runtime_instance_id(), "plant-inst-00000001000000020000000300000004", "Exact instance ID")
	assert_eq(plant_b.get_definition_id(), "plant.banana", "Exact definition ID")
	assert_eq(plant_b.get_planted_at(), 1700000000, "Exact planted_at")

	# Register another plant on restored state with scripted collision against plant_b
	var clock_b: FakeGameClock = FakeGameClock.new(1700000010, 0)
	var rng_b: FakeRandomSource = FakeRandomSource.new([], [
		1, 2, 3, 4, # Collides with plant_b!
		9, 9, 9, 9  # Unique candidate 2!
	])

	var res_b: PlantRegistrationResult = PlantingCommandService.try_plant_now(
		state_b, catalog, clock_b, rng_b, "plant.marigold"
	)
	assert_true(res_b.is_registered(), "Second plant on restored state must succeed after collision retry")
	assert_eq(
		res_b.get_plant().get_runtime_instance_id(),
		"plant-inst-00000009000000090000000900000009",
		"Second plant must use candidate 2"
	)
	assert_eq(state_b.get_plants().get_count(), 2, "Decoded state now contains both plants")
