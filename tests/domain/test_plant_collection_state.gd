## test_plant_collection_state.gd
## Unit tests for Garden's PlantCollectionState domain state slice.
##
## Verifies:
## 1. Type contract: RefCounted, not Node, not Resource, separate instances.
## 2. Fresh collection: get_count() == 0.
## 3. Add and get: adding a valid PlantState increases count, stores exact reference, can be queried.
## 4. Missing and empty ID queries: has_runtime_instance_id returns false, get_plant returns null without mutating.
## 5. Duplicate same object: second add returns false, count remains 1, stored object unchanged.
## 6. Duplicate different object with same ID: second add returns false, original object preserved without replacement.
## 7. Multiple instances of same definition: distinct runtime instance IDs can share definition_id.
## 8. Invalid states: null, empty instance_id, invalid definition_id, negative planted_at are rejected.
## 9. Independent collections: separate PlantCollectionState instances do not share state.
class_name TestPlantCollectionState
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestPlantCollectionState"


func run_tests() -> void:
	_test_type_contract_and_fresh_state()
	_test_add_and_get()
	_test_missing_and_empty_id_queries()
	_test_duplicate_same_object()
	_test_duplicate_different_object_same_id()
	_test_same_definition_multiple_instances()
	_test_invalid_state_rejection()
	_test_independent_collections()


func _test_type_contract_and_fresh_state() -> void:
	describe("PlantCollectionState satisfies RefCounted type contract and starts empty")
	var collection: PlantCollectionState = PlantCollectionState.new()
	assert_true(collection != null, "PlantCollectionState instance should not be null")
	assert_true(collection is PlantCollectionState, "Instance must satisfy 'is PlantCollectionState'")
	assert_true(collection is RefCounted, "PlantCollectionState must extend RefCounted")
	var obj: Variant = collection
	assert_false(obj is Node, "PlantCollectionState must not be a Node")
	assert_false(obj is Resource, "PlantCollectionState must not be a Resource")

	assert_eq(collection.get_count(), 0, "Fresh collection count must be 0")

	var other: PlantCollectionState = PlantCollectionState.new()
	assert_true(other != null, "Second collection instance must not be null")
	assert_ne(collection, other, "Separate constructions must yield distinct instances")


func _test_add_and_get() -> void:
	describe("Valid PlantState can be added, queried, and retrieved by runtime instance ID")
	var collection: PlantCollectionState = PlantCollectionState.new()
	var state: PlantState = PlantState.new("plant-001", "plant.holy_basil", 1000)

	var success: bool = collection.try_add_plant(state)
	assert_true(success, "try_add_plant() with valid plant must return true")
	assert_eq(collection.get_count(), 1, "Collection count must be 1 after adding one plant")
	assert_true(
		collection.has_runtime_instance_id("plant-001"),
		"has_runtime_instance_id() must return true for stored plant"
	)
	assert_eq(
		collection.get_plant("plant-001"),
		state,
		"get_plant() must return the exact stored PlantState reference"
	)


func _test_missing_and_empty_id_queries() -> void:
	describe("Queries for missing or empty runtime instance IDs return false/null safely")
	var collection: PlantCollectionState = PlantCollectionState.new()

	assert_false(
		collection.has_runtime_instance_id("missing"),
		"has_runtime_instance_id('missing') on empty collection must return false"
	)
	assert_true(
		collection.get_plant("missing") == null,
		"get_plant('missing') on empty collection must return null"
	)
	assert_false(
		collection.has_runtime_instance_id(""),
		"has_runtime_instance_id('') on empty collection must return false"
	)
	assert_true(
		collection.get_plant("") == null,
		"get_plant('') on empty collection must return null"
	)
	assert_eq(collection.get_count(), 0, "Empty collection count must remain 0 after read queries")

	var state: PlantState = PlantState.new("plant-001", "plant.holy_basil", 1000)
	collection.try_add_plant(state)

	assert_false(
		collection.has_runtime_instance_id("nonexistent"),
		"has_runtime_instance_id('nonexistent') on populated collection must return false"
	)
	assert_true(
		collection.get_plant("nonexistent") == null,
		"get_plant('nonexistent') on populated collection must return null"
	)
	assert_false(
		collection.has_runtime_instance_id(""),
		"has_runtime_instance_id('') on populated collection must return false"
	)
	assert_true(
		collection.get_plant("") == null,
		"get_plant('') on populated collection must return null"
	)
	assert_eq(collection.get_count(), 1, "Collection count must remain 1 after read queries")


func _test_duplicate_same_object() -> void:
	describe("Adding the same PlantState object twice is rejected and preserves state")
	var collection: PlantCollectionState = PlantCollectionState.new()
	var state: PlantState = PlantState.new("plant-001", "plant.holy_basil", 1000)

	var first_add: bool = collection.try_add_plant(state)
	assert_true(first_add, "First add of PlantState must return true")
	assert_eq(collection.get_count(), 1, "Count must be 1 after first add")

	var second_add: bool = collection.try_add_plant(state)
	assert_false(second_add, "Second add of same PlantState must return false")
	assert_eq(collection.get_count(), 1, "Count must remain 1 after rejected second add")
	assert_eq(
		collection.get_plant("plant-001"),
		state,
		"Retrieved PlantState must remain the original object"
	)


func _test_duplicate_different_object_same_id() -> void:
	describe("Adding a different PlantState with an existing runtime instance ID is rejected without replacement")
	var collection: PlantCollectionState = PlantCollectionState.new()
	var state_a: PlantState = PlantState.new("plant-001", "plant.holy_basil", 1000)
	var state_b: PlantState = PlantState.new("plant-001", "plant.chili", 2000)

	assert_true(state_a.is_valid(), "state_a must be structurally valid")
	assert_true(state_b.is_valid(), "state_b must be structurally valid")

	var add_a: bool = collection.try_add_plant(state_a)
	assert_true(add_a, "Adding state_a must return true")

	var add_b: bool = collection.try_add_plant(state_b)
	assert_false(add_b, "Adding state_b with duplicate runtime instance ID must return false")

	assert_eq(collection.get_count(), 1, "Count must remain 1 after rejected duplicate add")
	assert_eq(
		collection.get_plant("plant-001"),
		state_a,
		"Original state_a must remain stored without replacement"
	)
	assert_ne(
		collection.get_plant("plant-001"),
		state_b,
		"Rejected state_b must not replace state_a"
	)


func _test_same_definition_multiple_instances() -> void:
	describe("Multiple PlantState instances sharing the same definition_id are all accepted")
	var collection: PlantCollectionState = PlantCollectionState.new()
	var state_1: PlantState = PlantState.new("plant-001", "plant.holy_basil", 1000)
	var state_2: PlantState = PlantState.new("plant-002", "plant.holy_basil", 1500)
	var state_3: PlantState = PlantState.new("plant-003", "plant.holy_basil", 2000)

	assert_true(collection.try_add_plant(state_1), "First instance of plant.holy_basil should succeed")
	assert_true(collection.try_add_plant(state_2), "Second instance of plant.holy_basil should succeed")
	assert_true(collection.try_add_plant(state_3), "Third instance of plant.holy_basil should succeed")

	assert_eq(collection.get_count(), 3, "Collection count must be 3")
	assert_eq(collection.get_plant("plant-001"), state_1, "ID plant-001 must return state_1")
	assert_eq(collection.get_plant("plant-002"), state_2, "ID plant-002 must return state_2")
	assert_eq(collection.get_plant("plant-003"), state_3, "ID plant-003 must return state_3")


func _test_invalid_state_rejection() -> void:
	describe("Null and structurally invalid PlantState objects are rejected with collection unchanged")
	var collection: PlantCollectionState = PlantCollectionState.new()

	# Null state
	var null_result: bool = collection.try_add_plant(null)
	assert_false(null_result, "try_add_plant(null) must return false")
	assert_eq(collection.get_count(), 0, "Collection count must remain 0 after null rejection")

	# Empty instance_id
	var invalid_id_state: PlantState = PlantState.new("", "plant.holy_basil", 1000)
	assert_false(invalid_id_state.is_valid(), "PlantState with empty instance_id must be invalid")
	var empty_id_result: bool = collection.try_add_plant(invalid_id_state)
	assert_false(empty_id_result, "try_add_plant with empty instance_id must return false")
	assert_eq(collection.get_count(), 0, "Collection count must remain 0")

	# Invalid definition_id namespace
	var invalid_def_state: PlantState = PlantState.new("plant-001", "visitor.butterfly", 1000)
	assert_false(invalid_def_state.is_valid(), "PlantState with visitor namespace must be invalid")
	var invalid_def_result: bool = collection.try_add_plant(invalid_def_state)
	assert_false(invalid_def_result, "try_add_plant with non-plant definition_id must return false")
	assert_eq(collection.get_count(), 0, "Collection count must remain 0")

	# Negative planted_at
	var negative_time_state: PlantState = PlantState.new("plant-001", "plant.holy_basil", -1)
	assert_false(negative_time_state.is_valid(), "PlantState with negative planted_at must be invalid")
	var negative_time_result: bool = collection.try_add_plant(negative_time_state)
	assert_false(negative_time_result, "try_add_plant with negative planted_at must return false")
	assert_eq(collection.get_count(), 0, "Collection count must remain 0")


func _test_independent_collections() -> void:
	describe("Separate PlantCollectionState instances are independent with no shared storage")
	var collection_a: PlantCollectionState = PlantCollectionState.new()
	var collection_b: PlantCollectionState = PlantCollectionState.new()

	var state: PlantState = PlantState.new("plant-001", "plant.holy_basil", 1000)
	collection_a.try_add_plant(state)

	assert_eq(collection_a.get_count(), 1, "collection_a count must be 1")
	assert_eq(collection_b.get_count(), 0, "collection_b count must be 0")
	assert_true(
		collection_a.has_runtime_instance_id("plant-001"),
		"collection_a must have plant-001"
	)
	assert_false(
		collection_b.has_runtime_instance_id("plant-001"),
		"collection_b must not have plant-001"
	)
	assert_true(
		collection_b.get_plant("plant-001") == null,
		"collection_b.get_plant('plant-001') must be null"
	)
