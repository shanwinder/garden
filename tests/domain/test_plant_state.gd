## test_plant_state.gd
## Unit tests for Garden's PlantState domain runtime instance data object.
##
## Verifies:
## 1. Type contract: RefCounted, not Node, not Resource, separate instances.
## 2. Fact preservation: stores exact instance_id, definition_id, and planted_at without normalization.
## 3. Valid states: non-empty opaque instance_id, valid plant definition_id, planted_at >= 0.
## 4. Invalid instance_id: empty string returns false.
## 5. Invalid definition_id: empty, non-plant namespace, invalid syntax, resource paths return false.
## 6. Invalid planted_at: negative timestamps return false; 0 and large timestamps return true.
## 7. Read-only API: getters exist, no mutation setters exposed.
## 8. Independent instances: separate objects maintain distinct facts with no shared state.
## 9. Validation purity and idempotence: repeated is_valid() calls do not mutate fields or state.
## 10. ID uniqueness limitation: single-instance validation does not check global uniqueness.
## 11. Native method distinction: Garden runtime identity vs Godot engine Object identity.
class_name TestPlantState
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestPlantState"


func run_tests() -> void:
	_test_type_contract()
	_test_fact_preservation()
	_test_valid_states()
	_test_invalid_instance_id()
	_test_invalid_definition_id()
	_test_invalid_planted_at()
	_test_read_only_api()
	_test_independent_instances()
	_test_validation_purity_and_idempotence()
	_test_uniqueness_limitation_documented()
	_test_native_method_distinction()


func _test_type_contract() -> void:
	describe("PlantState satisfies RefCounted type contract and is not Node or Resource")
	var instance: PlantState = PlantState.new("test-instance-001", "plant.holy_basil", 1000)
	assert_true(instance != null, "PlantState instance should not be null")
	assert_true(instance is PlantState, "Instance must satisfy 'is PlantState'")
	assert_true(instance is RefCounted, "PlantState must extend RefCounted")
	var obj: Variant = instance
	assert_false(obj is Node, "PlantState must not be a Node")
	assert_false(obj is Resource, "PlantState must not be a Resource")

	var instance_2: PlantState = PlantState.new("test-instance-002", "plant.holy_basil", 1000)
	assert_true(instance_2 != null, "Second PlantState instance should not be null")
	assert_true(instance != instance_2, "Separate constructions must yield distinct instances")


func _test_fact_preservation() -> void:
	describe("Fact preservation: stores exact facts without mutation or normalization")
	var instance_id: String = "Example-ID_001"
	var definition_id: String = "plant.holy_basil"
	var planted_at: int = 123456789

	var state: PlantState = PlantState.new(instance_id, definition_id, planted_at)
	assert_eq(state.get_runtime_instance_id(), "Example-ID_001", "get_runtime_instance_id() must preserve exact mixed-case opaque ID")
	assert_eq(state.get_definition_id(), "plant.holy_basil", "get_definition_id() must match supplied definition_id")
	assert_eq(state.get_planted_at(), 123456789, "get_planted_at() must match supplied planted_at")


func _test_valid_states() -> void:
	describe("Valid PlantState instances return true")
	var valid_cases: Array[Dictionary] = [
		{
			"instance_id": "instance-a",
			"definition_id": "plant.holy_basil",
			"planted_at": 0,
		},
		{
			"instance_id": "instance-b",
			"definition_id": "plant.chili",
			"planted_at": 1,
		},
		{
			"instance_id": "anything-opaque-123",
			"definition_id": "plant.variant.holy_basil",
			"planted_at": 9223372036854775807,
		},
		{
			"instance_id": "UUID-like-550e8400-e29b-41d4-a716-446655440000",
			"definition_id": "plant.jasmine",
			"planted_at": 1700000000,
		},
	]

	for tc: Dictionary in valid_cases:
		var state: PlantState = PlantState.new(
			tc["instance_id"],
			tc["definition_id"],
			tc["planted_at"]
		)
		assert_true(
			state.is_valid(),
			"Valid state ('%s', '%s', %d) must return true"
			% [tc["instance_id"], tc["definition_id"], tc["planted_at"]]
		)


func _test_invalid_instance_id() -> void:
	describe("Empty instance_id returns false; opaque non-empty strings are accepted")
	var empty_id_state: PlantState = PlantState.new("", "plant.holy_basil", 1000)
	assert_false(empty_id_state.is_valid(), "Empty instance_id must return false")
	assert_eq(empty_id_state.get_runtime_instance_id(), "", "instance_id must remain empty string")

	var opaque_ids: Array[String] = [
		"1",
		"inst_001",
		"PLANT-001",
		"c2b6f1a8-8b9a-4e2a-9f5b-1c3d5e7f9a0b",
		"arbitrary opaque string with spaces",
	]
	for op_id: String in opaque_ids:
		var state: PlantState = PlantState.new(op_id, "plant.holy_basil", 1000)
		assert_true(state.is_valid(), "Opaque non-empty instance_id '%s' must return true" % op_id)


func _test_invalid_definition_id() -> void:
	describe("Invalid definition_id strings return false with valid instance_id and timestamp")
	var invalid_definition_ids: Array[String] = [
		"",
		"plant",
		"plant.",
		"plant..basil",
		"Plant.holy_basil",
		"plant._basil",
		"plant.123",
		"visitor.butterfly",
		"decoration.clay_jar",
		"res://plants/basil.tres",
	]

	for inv_id: String in invalid_definition_ids:
		var state: PlantState = PlantState.new("inst-001", inv_id, 1000)
		assert_false(
			state.is_valid(),
			"Invalid definition_id '%s' must return false" % inv_id
		)
		assert_eq(
			state.get_definition_id(),
			inv_id,
			"definition_id must not be mutated or normalized"
		)


func _test_invalid_planted_at() -> void:
	describe("Negative planted_at returns false; 0 and positive return true")
	var invalid_timestamps: Array[int] = [
		-1,
		-100,
		-9223372036854775807,
		-9223372036854775807 - 1,
	]

	for ts: int in invalid_timestamps:
		var state: PlantState = PlantState.new("inst-001", "plant.holy_basil", ts)
		assert_false(
			state.is_valid(),
			"Negative timestamp %d must return false" % ts
		)
		assert_eq(state.get_planted_at(), ts, "planted_at must remain %d" % ts)

	var zero_state: PlantState = PlantState.new("inst-001", "plant.holy_basil", 0)
	assert_true(zero_state.is_valid(), "planted_at = 0 must return true")


func _test_read_only_api() -> void:
	describe("Read-only API: getters exist and no mutation setters are exposed")
	var state: PlantState = PlantState.new("inst-001", "plant.holy_basil", 1000)

	assert_true(state.has_method("get_runtime_instance_id"), "get_runtime_instance_id must exist")
	assert_true(state.has_method("get_definition_id"), "get_definition_id must exist")
	assert_true(state.has_method("get_planted_at"), "get_planted_at must exist")
	assert_true(state.has_method("is_valid"), "is_valid must exist")

	assert_false(state.has_method("set_runtime_instance_id"), "set_runtime_instance_id must not exist")
	assert_false(state.has_method("set_instance_id"), "set_instance_id must not exist")
	assert_false(state.has_method("set_definition_id"), "set_definition_id must not exist")
	assert_false(state.has_method("set_planted_at"), "set_planted_at must not exist")
	assert_false(state.has_method("update"), "update must not exist")
	assert_false(state.has_method("patch"), "patch must not exist")


func _test_independent_instances() -> void:
	describe("Independent instances: separate objects maintain distinct facts without shared state")
	var state_1: PlantState = PlantState.new("inst-001", "plant.holy_basil", 100)
	var state_2: PlantState = PlantState.new("inst-002", "plant.chili", 200)

	assert_eq(state_1.get_runtime_instance_id(), "inst-001", "state_1 instance_id must be inst-001")
	assert_eq(state_1.get_definition_id(), "plant.holy_basil", "state_1 definition_id must be plant.holy_basil")
	assert_eq(state_1.get_planted_at(), 100, "state_1 planted_at must be 100")

	assert_eq(state_2.get_runtime_instance_id(), "inst-002", "state_2 instance_id must be inst-002")
	assert_eq(state_2.get_definition_id(), "plant.chili", "state_2 definition_id must be plant.chili")
	assert_eq(state_2.get_planted_at(), 200, "state_2 planted_at must be 200")


func _test_validation_purity_and_idempotence() -> void:
	describe("Validation purity: is_valid() is pure, idempotent, and performs no normalization or repair")
	var invalid_state: PlantState = PlantState.new("Example-ID", "Plant.holy_basil", 100)
	var valid_state: PlantState = PlantState.new("Example-ID", "plant.holy_basil", 100)

	for i: int in range(5):
		assert_false(
			invalid_state.is_valid(),
			"Repeated is_valid() call %d on invalid state must return false" % i
		)
		assert_true(
			valid_state.is_valid(),
			"Repeated is_valid() call %d on valid state must return true" % i
		)

	assert_eq(invalid_state.get_runtime_instance_id(), "Example-ID", "instance_id must remain unmutated")
	assert_eq(invalid_state.get_definition_id(), "Plant.holy_basil", "definition_id must not be lowercased or repaired")
	assert_eq(invalid_state.get_planted_at(), 100, "planted_at must remain unmutated")


func _test_uniqueness_limitation_documented() -> void:
	describe("Documented limitation: single PlantState validation does not check global ID uniqueness")
	var state_a: PlantState = PlantState.new("shared-id-001", "plant.holy_basil", 1000)
	var state_b: PlantState = PlantState.new("shared-id-001", "plant.chili", 2000)

	assert_true(state_a.is_valid(), "First instance with duplicate ID is individually valid")
	assert_true(state_b.is_valid(), "Second instance with same ID is individually valid")
	assert_ne(state_a, state_b, "Two distinct objects can hold identical instance_ids before collection insertion")


func _test_native_method_distinction() -> void:
	describe("Distinction between Godot Object.get_instance_id() int and Garden get_runtime_instance_id() String")
	var state: PlantState = PlantState.new("custom-runtime-id-123", "plant.holy_basil", 1000)
	assert_eq(state.get_runtime_instance_id(), "custom-runtime-id-123", "get_runtime_instance_id() returns Garden runtime entity ID")
	var engine_id: Variant = state.get_instance_id()
	assert_true(engine_id is int, "Object.get_instance_id() is native engine int ID, not Garden runtime ID")
	assert_ne(str(engine_id), state.get_runtime_instance_id(), "Engine ObjectID must not be used as Garden runtime instance ID")
