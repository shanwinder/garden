## test_decoration_collection_state.gd
## Unit tests for Garden's DecorationCollectionState domain state slice.
class_name TestDecorationCollectionState
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestDecorationCollectionState"


func run_tests() -> void:
	_test_type_contract_and_empty_state()
	_test_add_get_and_multiple_same_definition()
	_test_duplicate_and_invalid_rejection()
	_test_deterministic_sorting_and_defensive_copy()


func _test_type_contract_and_empty_state() -> void:
	describe("DecorationCollectionState satisfies RefCounted contract and starts empty")
	var col: DecorationCollectionState = DecorationCollectionState.new()
	assert_true(col != null, "Collection must not be null")
	assert_true(col is DecorationCollectionState, "Must be DecorationCollectionState")
	assert_true(col is RefCounted, "Must extend RefCounted")
	var obj: Variant = col
	assert_false(obj is Node, "Must not be a Node")
	assert_false(obj is Resource, "Must not be a Resource")
	assert_eq(col.get_count(), 0, "Starts with count 0")
	assert_false(col.has_runtime_instance_id("d-1"), "Does not have d-1")
	assert_eq(col.get_decoration("d-1"), null, "get_decoration('d-1') returns null")


func _test_add_get_and_multiple_same_definition() -> void:
	describe("DecorationCollectionState stores unique runtime instances and allows multiple instances of the same definition")
	var col: DecorationCollectionState = DecorationCollectionState.new()
	var d1: DecorationState = DecorationState.new("dec-1", "decoration.clay_jar", 1000)
	var d2: DecorationState = DecorationState.new("dec-2", "decoration.clay_jar", 2000)

	assert_true(col.try_add_decoration(d1), "Adding d1 succeeds")
	assert_true(col.try_add_decoration(d2), "Adding second clay_jar with distinct instance ID succeeds")
	assert_eq(col.get_count(), 2, "Count is 2")
	assert_eq(col.get_decoration("dec-1"), d1, "Exact d1 reference returned")
	assert_eq(col.get_decoration("dec-2"), d2, "Exact d2 reference returned")


func _test_duplicate_and_invalid_rejection() -> void:
	describe("DecorationCollectionState rejects null, invalid DecorationState, and duplicate runtime instance IDs")
	var col: DecorationCollectionState = DecorationCollectionState.new()
	var d1: DecorationState = DecorationState.new("dec-1", "decoration.clay_jar", 1000)
	var d1_dup: DecorationState = DecorationState.new("dec-1", "decoration.bench", 2000)
	var invalid_dec: DecorationState = DecorationState.new("", "decoration.clay_jar", 1000)

	assert_false(col.try_add_decoration(null), "Null rejected")
	assert_false(col.try_add_decoration(invalid_dec), "Invalid decoration rejected")
	assert_true(col.try_add_decoration(d1), "Valid d1 added")
	assert_false(col.try_add_decoration(d1_dup), "Duplicate runtime instance ID rejected")
	assert_eq(col.get_count(), 1, "Count remains 1")
	assert_eq(col.get_decoration("dec-1"), d1, "Original d1 preserved without replacement")


func _test_deterministic_sorting_and_defensive_copy() -> void:
	describe("get_all_decorations returns deterministic ascending runtime instance ID order and defensive copy")
	var col: DecorationCollectionState = DecorationCollectionState.new()
	col.try_add_decoration(DecorationState.new("z-99", "decoration.small_pond", 3000))
	col.try_add_decoration(DecorationState.new("a-01", "decoration.clay_jar", 1000))
	col.try_add_decoration(DecorationState.new("m-50", "decoration.bench", 2000))

	var all_decs: Array[DecorationState] = col.get_all_decorations()
	assert_eq(all_decs.size(), 3, "3 decorations returned")
	assert_eq(all_decs[0].get_runtime_instance_id(), "a-01", "Index 0 is a-01")
	assert_eq(all_decs[1].get_runtime_instance_id(), "m-50", "Index 1 is m-50")
	assert_eq(all_decs[2].get_runtime_instance_id(), "z-99", "Index 2 is z-99")

	all_decs.clear()
	assert_eq(col.get_count(), 3, "Mutating returned array does not alter collection")
