## test_plant_registration_service.gd
## Comprehensive unit tests for PlantRegistrationService and PlantRegistrationResult.
##
## Verifies:
## 1. Type contracts: RefCounted, not Node, not Resource.
## 2. Success cases:
##    - Registration of plant.holy_basil.
##    - All five approved plant definitions register with unique IDs.
##    - Result status is REGISTERED, is_registered() is true.
##    - Exact PlantState reference stored in GameState collection.
##    - Exact instance_id, definition_id, and planted_at preserved.
##    - Collection count increments by exactly 1.
##    - Multiple instances sharing the same definition succeed.
##    - Multiple distinct definitions succeed.
##    - Deterministic ascending instance_id ordering preserved in get_all_plants().
##    - Economy state remains unmutated.
##    - Stored PlantState satisfies is_valid().
##    - PlantGrowth correctly derives growth stages from registered plant.
## 3. Failure cases:
##    - Null GameState.
##    - Null ContentCatalog.
##    - Empty instance_id.
##    - Negative planted_at.
##    - Empty definition_id.
##    - Malformed definition_id syntax.
##    - Non-plant namespace IDs.
##    - Structurally valid but unknown definition_id.
##    - Wrong-case definition ID (no normalization).
##    - Duplicate runtime instance ID with same definition.
##    - Duplicate runtime instance ID with different definition.
##    - Duplicate runtime instance ID with different planted_at.
##    - Every failure returns null plant, is_registered() false, leaves collection and economy untouched.
## 4. Validation precedence:
##    - Null state + unknown definition -> INVALID_INPUT.
##    - Malformed syntax + duplicate instance ID -> INVALID_INPUT.
##    - Valid unknown definition + duplicate instance ID -> UNKNOWN_DEFINITION_ID.
##    - Known definition + duplicate instance ID -> DUPLICATE_INSTANCE_ID.
## 5. Persistence round-trip:
##    - Valid registration -> GameStateCodec.encode -> JSON -> GameStateCodec.decode preserves exact facts.
class_name TestPlantRegistrationService
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestPlantRegistrationService"


func run_tests() -> void:
	_test_type_contracts()
	_test_register_holy_basil_success()
	_test_all_five_approved_definitions_success()
	_test_exact_facts_and_reference_preservation()
	_test_multiple_plants_same_and_different_definitions()
	_test_collection_ordering_and_economy_unchanged()
	_test_plant_growth_compatibility()
	_test_failure_null_dependencies()
	_test_failure_invalid_input_parameters()
	_test_failure_unknown_definition_id()
	_test_failure_duplicate_instance_id()
	_test_validation_precedence()
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


func _test_type_contracts() -> void:
	describe("PlantRegistrationService and PlantRegistrationResult type contracts")
	var service: PlantRegistrationService = PlantRegistrationService.new()
	assert_true(service is RefCounted, "PlantRegistrationService must extend RefCounted")
	var s_obj: Variant = service
	assert_false(s_obj is Node, "PlantRegistrationService must not be a Node")
	assert_false(s_obj is Resource, "PlantRegistrationService must not be a Resource")

	var result: PlantRegistrationResult = PlantRegistrationResult.invalid_input()
	assert_true(result is RefCounted, "PlantRegistrationResult must extend RefCounted")
	var r_obj: Variant = result
	assert_false(r_obj is Node, "PlantRegistrationResult must not be a Node")
	assert_false(r_obj is Resource, "PlantRegistrationResult must not be a Resource")

	assert_eq(result.get_status(), PlantRegistrationResult.INVALID_INPUT, "invalid_input status must match")
	assert_false(result.is_registered(), "invalid_input is_registered() must be false")
	assert_true(result.get_plant() == null, "invalid_input get_plant() must be null")


func _test_register_holy_basil_success() -> void:
	describe("Successful registration of plant.holy_basil")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()

	var result: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state,
		catalog,
		"plant-inst-001",
		"plant.holy_basil",
		1700000000
	)

	assert_true(result != null, "Result must not be null")
	assert_eq(result.get_status(), PlantRegistrationResult.REGISTERED, "Status must be REGISTERED")
	assert_true(result.is_registered(), "is_registered() must be true")

	var plant: PlantState = result.get_plant()
	assert_true(plant != null, "get_plant() must return a non-null PlantState")
	assert_eq(plant.get_runtime_instance_id(), "plant-inst-001", "instance_id must match")
	assert_eq(plant.get_definition_id(), "plant.holy_basil", "definition_id must match")
	assert_eq(plant.get_planted_at(), 1700000000, "planted_at must match")
	assert_true(plant.is_valid(), "PlantState must be valid")

	assert_eq(state.get_plants().get_count(), 1, "Plant count must be 1")
	assert_true(state.get_plants().has_runtime_instance_id("plant-inst-001"), "Collection must contain instance_id")
	assert_eq(state.get_plants().get_plant("plant-inst-001"), plant, "Stored plant must be exact reference")


func _test_all_five_approved_definitions_success() -> void:
	describe("All five approved plant definitions register successfully with unique IDs")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()
	var approved_ids: Array[String] = [
		"plant.banana",
		"plant.chili",
		"plant.holy_basil",
		"plant.jasmine",
		"plant.marigold",
	]

	for i: int in range(approved_ids.size()):
		var def_id: String = approved_ids[i]
		var inst_id: String = "plant-inst-%03d" % (i + 1)
		var planted_at: int = 1000 + (i * 100)

		var res: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
			state,
			catalog,
			inst_id,
			def_id,
			planted_at
		)

		assert_true(res.is_registered(), "Registration for %s must succeed" % def_id)
		assert_eq(res.get_status(), PlantRegistrationResult.REGISTERED, "Status must be REGISTERED for %s" % def_id)
		assert_eq(res.get_plant().get_definition_id(), def_id, "Definition ID must match for %s" % def_id)

	assert_eq(state.get_plants().get_count(), 5, "Total plant count must be 5")


func _test_exact_facts_and_reference_preservation() -> void:
	describe("Exact facts and object reference preservation without mutation or cloning")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()

	var exact_inst_id: String = "Exact_Instance_ID-999"
	var exact_def_id: String = "plant.holy_basil"
	var exact_planted_at: int = 1234567890123

	var result: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state,
		catalog,
		exact_inst_id,
		exact_def_id,
		exact_planted_at
	)

	assert_true(result.is_registered(), "Registration must succeed")
	var returned_plant: PlantState = result.get_plant()
	var stored_plant: PlantState = state.get_plants().get_plant(exact_inst_id)

	assert_true(returned_plant == stored_plant, "Returned PlantState must be identical object reference to stored plant")
	assert_eq(stored_plant.get_runtime_instance_id(), exact_inst_id, "Exact instance_id string preserved")
	assert_eq(stored_plant.get_definition_id(), exact_def_id, "Exact definition_id string preserved")
	assert_eq(stored_plant.get_planted_at(), exact_planted_at, "Exact planted_at integer preserved")


func _test_multiple_plants_same_and_different_definitions() -> void:
	describe("Multiple plants sharing definition and multiple distinct definitions")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()

	# Two distinct instances with same definition
	var r1: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state, catalog, "basil-1", "plant.holy_basil", 100
	)
	var r2: PlantRegistrationResult = PlantRegistrationResult.insertion_rejected()
	r2 = PlantRegistrationService.try_register_plant(
		state, catalog, "basil-2", "plant.holy_basil", 200
	)

	assert_true(r1.is_registered(), "First basil must register")
	assert_true(r2.is_registered(), "Second basil must register")
	assert_eq(state.get_plants().get_count(), 2, "Count must be 2")

	# Third instance with different definition
	var r3: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state, catalog, "chili-1", "plant.chili", 300
	)
	assert_true(r3.is_registered(), "Chili must register")
	assert_eq(state.get_plants().get_count(), 3, "Count must be 3")


func _test_collection_ordering_and_economy_unchanged() -> void:
	describe("Deterministic collection ordering intact and economy unmutated")
	var state: GameState = GameState.new()
	state.get_economy().grant_currency(150)
	var catalog: ContentCatalog = _create_five_plant_catalog()

	# Insert out of order
	PlantRegistrationService.try_register_plant(state, catalog, "plant-c", "plant.marigold", 30)
	PlantRegistrationService.try_register_plant(state, catalog, "plant-a", "plant.holy_basil", 10)
	PlantRegistrationService.try_register_plant(state, catalog, "plant-b", "plant.chili", 20)

	assert_eq(state.get_plants().get_count(), 3, "Count must be 3")
	assert_eq(state.get_economy().get_currency(), 150, "Economy currency must remain exactly 150")

	var all_plants: Array[PlantState] = state.get_plants().get_all_plants()
	assert_eq(all_plants.size(), 3, "All plants size must be 3")
	assert_eq(all_plants[0].get_runtime_instance_id(), "plant-a", "Index 0 must be plant-a")
	assert_eq(all_plants[1].get_runtime_instance_id(), "plant-b", "Index 1 must be plant-b")
	assert_eq(all_plants[2].get_runtime_instance_id(), "plant-c", "Index 2 must be plant-c")


func _test_plant_growth_compatibility() -> void:
	describe("PlantGrowth can derive growth stage from newly registered PlantState and matching PlantDefinition")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()

	var result: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state,
		catalog,
		"plant-holy-01",
		"plant.holy_basil",
		1000
	)
	assert_true(result.is_registered(), "Registration must succeed")

	var plant: PlantState = result.get_plant()
	var definition: PlantDefinition = catalog.get_plant("plant.holy_basil")
	assert_true(definition != null, "Definition must exist in catalog")

	# Holy basil thresholds: sprout = 60, growing = 300, mature = 900
	# At planted time: 1000 -> elapsed = 0 -> PLANTED
	var stage_0: PlantGrowth.Stage = PlantGrowth.stage_for_state_at(plant, definition, 1000)
	assert_eq(stage_0, PlantGrowth.Stage.PLANTED, "At now=1000, stage must be PLANTED")

	# At 1060 -> elapsed = 60 -> SPROUT
	var stage_sprout: PlantGrowth.Stage = PlantGrowth.stage_for_state_at(plant, definition, 1060)
	assert_eq(stage_sprout, PlantGrowth.Stage.SPROUT, "At now=1060, stage must be SPROUT")

	# At 1300 -> elapsed = 300 -> GROWING
	var stage_growing: PlantGrowth.Stage = PlantGrowth.stage_for_state_at(plant, definition, 1300)
	assert_eq(stage_growing, PlantGrowth.Stage.GROWING, "At now=1300, stage must be GROWING")

	# At 1900 -> elapsed = 900 -> MATURE
	var stage_mature: PlantGrowth.Stage = PlantGrowth.stage_for_state_at(plant, definition, 1900)
	assert_eq(stage_mature, PlantGrowth.Stage.MATURE, "At now=1900, stage must be MATURE")


func _test_failure_null_dependencies() -> void:
	describe("Rejects null GameState or null ContentCatalog with INVALID_INPUT")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()

	# Null GameState
	var res_null_state: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		null, catalog, "inst-1", "plant.holy_basil", 1000
	)
	assert_eq(res_null_state.get_status(), PlantRegistrationResult.INVALID_INPUT, "Null state must return INVALID_INPUT")
	assert_false(res_null_state.is_registered(), "is_registered() must be false")
	assert_true(res_null_state.get_plant() == null, "get_plant() must be null")

	# Null ContentCatalog
	var res_null_cat: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state, null, "inst-1", "plant.holy_basil", 1000
	)
	assert_eq(res_null_cat.get_status(), PlantRegistrationResult.INVALID_INPUT, "Null catalog must return INVALID_INPUT")
	assert_false(res_null_cat.is_registered(), "is_registered() must be false")
	assert_true(res_null_cat.get_plant() == null, "get_plant() must be null")
	assert_eq(state.get_plants().get_count(), 0, "Plant collection must remain empty")


func _test_failure_invalid_input_parameters() -> void:
	describe("Rejects empty instance_id, negative planted_at, and malformed definition_id with INVALID_INPUT")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()

	# Empty instance_id
	var r_empty_inst: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state, catalog, "", "plant.holy_basil", 1000
	)
	assert_eq(r_empty_inst.get_status(), PlantRegistrationResult.INVALID_INPUT, "Empty instance_id must return INVALID_INPUT")
	assert_false(r_empty_inst.is_registered(), "is_registered must be false")
	assert_true(r_empty_inst.get_plant() == null, "get_plant must be null")

	# Negative planted_at
	var negative_times: Array[int] = [-1, -100, -9223372036854775807]
	for neg_t: int in negative_times:
		var r_neg: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
			state, catalog, "inst-1", "plant.holy_basil", neg_t
		)
		assert_eq(r_neg.get_status(), PlantRegistrationResult.INVALID_INPUT, "Negative timestamp %d must return INVALID_INPUT" % neg_t)
		assert_false(r_neg.is_registered(), "is_registered must be false")
		assert_true(r_neg.get_plant() == null, "get_plant must be null")

	# Empty definition_id
	var r_empty_def: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state, catalog, "inst-1", "", 1000
	)
	assert_eq(r_empty_def.get_status(), PlantRegistrationResult.INVALID_INPUT, "Empty definition_id must return INVALID_INPUT")

	# Malformed definition_id syntax
	var malformed_ids: Array[String] = [
		"plant",
		"plant.",
		"plant..basil",
		"plant._basil",
		"plant.holy basil",
		"plant.123",
		"res://plants/holy_basil.tres",
	]
	for bad_id: String in malformed_ids:
		var r_bad: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
			state, catalog, "inst-1", bad_id, 1000
		)
		assert_eq(r_bad.get_status(), PlantRegistrationResult.INVALID_INPUT, "Malformed ID '%s' must return INVALID_INPUT" % bad_id)

	# Non-plant namespaces
	var non_plant_ids: Array[String] = [
		"visitor.butterfly",
		"decoration.clay_jar",
		"event.cat_sleeping",
	]
	for np_id: String in non_plant_ids:
		var r_np: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
			state, catalog, "inst-1", np_id, 1000
		)
		assert_eq(r_np.get_status(), PlantRegistrationResult.INVALID_INPUT, "Non-plant namespace '%s' must return INVALID_INPUT" % np_id)

	# Wrong-case definition ID (no silent normalization)
	var wrong_case_ids: Array[String] = [
		"Plant.holy_basil",
		"plant.Holy_Basil",
		"plant.HOLY_BASIL",
	]
	for wc_id: String in wrong_case_ids:
		var r_wc: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
			state, catalog, "inst-1", wc_id, 1000
		)
		assert_eq(r_wc.get_status(), PlantRegistrationResult.INVALID_INPUT, "Wrong-case ID '%s' must return INVALID_INPUT" % wc_id)

	assert_eq(state.get_plants().get_count(), 0, "Collection count must remain 0 after all rejections")


func _test_failure_unknown_definition_id() -> void:
	describe("Rejects structurally valid but unknown definition_id with UNKNOWN_DEFINITION_ID")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()

	var unknown_ids: Array[String] = [
		"plant.some_future_plant",
		"plant.papaya",
		"plant.mango",
		"plant.unknown_crop",
	]

	for unk_id: String in unknown_ids:
		var res: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
			state, catalog, "inst-1", unk_id, 1000
		)
		assert_eq(res.get_status(), PlantRegistrationResult.UNKNOWN_DEFINITION_ID, "Unknown ID '%s' must return UNKNOWN_DEFINITION_ID" % unk_id)
		assert_false(res.is_registered(), "is_registered must be false")
		assert_true(res.get_plant() == null, "get_plant must be null")

	assert_eq(state.get_plants().get_count(), 0, "Plant collection must remain unchanged")


func _test_failure_duplicate_instance_id() -> void:
	describe("Rejects duplicate runtime instance IDs with DUPLICATE_INSTANCE_ID")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()

	var first_res: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state, catalog, "inst-shared", "plant.holy_basil", 1000
	)
	assert_true(first_res.is_registered(), "First registration must succeed")
	assert_eq(state.get_plants().get_count(), 1, "Count must be 1")

	# Duplicate ID with same definition and same timestamp
	var dup_same: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state, catalog, "inst-shared", "plant.holy_basil", 1000
	)
	assert_eq(dup_same.get_status(), PlantRegistrationResult.DUPLICATE_INSTANCE_ID, "Duplicate ID must return DUPLICATE_INSTANCE_ID")
	assert_false(dup_same.is_registered(), "is_registered must be false")
	assert_true(dup_same.get_plant() == null, "get_plant must be null")

	# Duplicate ID with different definition
	var dup_diff_def: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state, catalog, "inst-shared", "plant.chili", 1000
	)
	assert_eq(dup_diff_def.get_status(), PlantRegistrationResult.DUPLICATE_INSTANCE_ID, "Duplicate ID with different def must return DUPLICATE_INSTANCE_ID")
	assert_false(dup_diff_def.is_registered(), "is_registered must be false")
	assert_true(dup_diff_def.get_plant() == null, "get_plant must be null")

	# Duplicate ID with different timestamp
	var dup_diff_time: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state, catalog, "inst-shared", "plant.holy_basil", 9999
	)
	assert_eq(dup_diff_time.get_status(), PlantRegistrationResult.DUPLICATE_INSTANCE_ID, "Duplicate ID with different time must return DUPLICATE_INSTANCE_ID")
	assert_false(dup_diff_time.is_registered(), "is_registered must be false")
	assert_true(dup_diff_time.get_plant() == null, "get_plant must be null")

	# State preserved
	assert_eq(state.get_plants().get_count(), 1, "Count must remain 1")
	assert_eq(state.get_plants().get_plant("inst-shared").get_definition_id(), "plant.holy_basil", "Original definition preserved")
	assert_eq(state.get_plants().get_plant("inst-shared").get_planted_at(), 1000, "Original timestamp preserved")


func _test_validation_precedence() -> void:
	describe("Strict validation precedence: INVALID_INPUT > UNKNOWN_DEFINITION_ID > DUPLICATE_INSTANCE_ID")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_five_plant_catalog()

	# Register an existing plant first
	PlantRegistrationService.try_register_plant(state, catalog, "existing-id", "plant.holy_basil", 1000)

	# 1. Null GameState and unknown definition -> INVALID_INPUT
	var r1: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		null, catalog, "any-id", "plant.unknown", 1000
	)
	assert_eq(r1.get_status(), PlantRegistrationResult.INVALID_INPUT, "Null state + unknown def must be INVALID_INPUT")

	# 2. Invalid definition syntax and duplicate runtime ID -> INVALID_INPUT
	var r2: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state, catalog, "existing-id", "invalid..syntax", 1000
	)
	assert_eq(r2.get_status(), PlantRegistrationResult.INVALID_INPUT, "Invalid syntax + duplicate ID must be INVALID_INPUT")

	# 3. Valid unknown definition and duplicate runtime ID -> UNKNOWN_DEFINITION_ID
	var r3: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state, catalog, "existing-id", "plant.valid_but_unknown", 1000
	)
	assert_eq(r3.get_status(), PlantRegistrationResult.UNKNOWN_DEFINITION_ID, "Valid unknown def + duplicate ID must be UNKNOWN_DEFINITION_ID")

	# 4. Known definition and duplicate runtime ID -> DUPLICATE_INSTANCE_ID
	var r4: PlantRegistrationResult = PlantRegistrationService.try_register_plant(
		state, catalog, "existing-id", "plant.holy_basil", 1000
	)
	assert_eq(r4.get_status(), PlantRegistrationResult.DUPLICATE_INSTANCE_ID, "Known def + duplicate ID must be DUPLICATE_INSTANCE_ID")


func _test_in_memory_persistence_round_trip() -> void:
	describe("In-memory persistence round trip: GameSession -> registration -> encode -> JSON -> decode")
	var session: GameSession = GameSession.new()
	session.grant_currency(250)
	var catalog: ContentCatalog = _create_five_plant_catalog()

	var reg_res: PlantRegistrationResult = session.try_register_plant(
		catalog,
		"plant-persistence-001",
		"plant.holy_basil",
		1700000000
	)
	assert_true(reg_res.is_registered(), "Registration via GameSession must succeed")

	# Encode to V1 snapshot dictionary
	var encoded_snapshot: Dictionary = GameStateCodec.encode(session.get_state())
	assert_eq(encoded_snapshot[GameStateCodec.KEY_SCHEMA_VERSION], 1, "Schema version must be 1")

	# JSON serialization round trip (Stringify then parse)
	var json_string: String = JSON.stringify(encoded_snapshot)
	var parsed_snapshot: Variant = JSON.parse_string(json_string)
	assert_true(parsed_snapshot != null, "JSON parse must succeed")

	# Decode back to GameState
	var decoded_state: GameState = GameStateCodec.decode(parsed_snapshot)
	assert_true(decoded_state != null, "Decoded state must not be null")

	# Verify state fidelity
	assert_eq(decoded_state.get_economy().get_currency(), 250, "Currency must survive round trip")
	assert_eq(decoded_state.get_plants().get_count(), 1, "Plant count must survive round trip")
	assert_true(
		decoded_state.get_plants().has_runtime_instance_id("plant-persistence-001"),
		"Instance ID must survive round trip"
	)

	var decoded_plant: PlantState = decoded_state.get_plants().get_plant("plant-persistence-001")
	assert_true(decoded_plant != null, "Plant must be retrievable from decoded state")
	assert_eq(decoded_plant.get_runtime_instance_id(), "plant-persistence-001", "instance_id must match exactly")
	assert_eq(decoded_plant.get_definition_id(), "plant.holy_basil", "definition_id must match exactly")
	assert_eq(decoded_plant.get_planted_at(), 1700000000, "planted_at must match exactly")
	assert_true(decoded_plant.is_valid(), "Decoded PlantState must be valid")
