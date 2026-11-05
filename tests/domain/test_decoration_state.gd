## test_decoration_state.gd
## Unit tests for Garden's DecorationState domain runtime instance data object.
class_name TestDecorationState
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestDecorationState"


func run_tests() -> void:
	_test_type_contract_and_facts()
	_test_valid_states()
	_test_invalid_instance_id_definition_id_and_placed_at()
	_test_read_only_api()


func _test_type_contract_and_facts() -> void:
	describe("DecorationState satisfies RefCounted type contract and preserves exact facts")
	var state: DecorationState = DecorationState.new("decor-001", "decoration.clay_jar", 1700000000)
	assert_true(state != null, "DecorationState instance must not be null")
	assert_true(state is DecorationState, "Must be DecorationState")
	assert_true(state is RefCounted, "Must extend RefCounted")
	var obj: Variant = state
	assert_false(obj is Node, "Must not be a Node")
	assert_false(obj is Resource, "Must not be a Resource")

	assert_eq(state.get_runtime_instance_id(), "decor-001", "Runtime instance ID preserved")
	assert_eq(state.get_definition_id(), "decoration.clay_jar", "Definition ID preserved")
	assert_eq(state.get_placed_at(), 1700000000, "Placed_at timestamp preserved")
	assert_true(state.is_valid(), "Valid state passes is_valid()")


func _test_valid_states() -> void:
	describe("DecorationState accepts 0 and max int64 timestamps and any valid decoration.* ID")
	var zero_ts: DecorationState = DecorationState.new("d-0", "decoration.small_pond", 0)
	assert_true(zero_ts.is_valid(), "placed_at == 0 is valid")

	var max_ts: DecorationState = DecorationState.new("d-max", "decoration.bench", 9223372036854775807)
	assert_true(max_ts.is_valid(), "placed_at == MAX_INT64 is valid")


func _test_invalid_instance_id_definition_id_and_placed_at() -> void:
	describe("DecorationState rejects empty instance_id, non-decoration definition_id, and negative placed_at")
	var empty_inst: DecorationState = DecorationState.new("", "decoration.clay_jar", 1000)
	assert_false(empty_inst.is_valid(), "Empty instance_id is invalid")

	var plant_ns: DecorationState = DecorationState.new("d-1", "plant.holy_basil", 1000)
	assert_false(plant_ns.is_valid(), "Plant namespace definition_id is invalid")

	var visitor_ns: DecorationState = DecorationState.new("d-1", "visitor.frog", 1000)
	assert_false(visitor_ns.is_valid(), "Visitor namespace definition_id is invalid")

	var neg_ts: DecorationState = DecorationState.new("d-1", "decoration.clay_jar", -1)
	assert_false(neg_ts.is_valid(), "Negative placed_at is invalid")


func _test_read_only_api() -> void:
	describe("DecorationState exposes read-only getters and no mutation setters")
	var state: DecorationState = DecorationState.new("d-1", "decoration.clay_jar", 1000)
	assert_true(state.has_method("get_runtime_instance_id"), "Has get_runtime_instance_id")
	assert_true(state.has_method("get_definition_id"), "Has get_definition_id")
	assert_true(state.has_method("get_placed_at"), "Has get_placed_at")
	assert_false(state.has_method("set_runtime_instance_id"), "No set_runtime_instance_id")
	assert_false(state.has_method("set_definition_id"), "No set_definition_id")
	assert_false(state.has_method("set_placed_at"), "No set_placed_at")
