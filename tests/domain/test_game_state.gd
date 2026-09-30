## test_game_state.gd
## Unit tests for Garden's GameState domain root.
##
## Verifies:
## 1. GameState can be constructed without a SceneTree.
## 2. GameState satisfies its own type contract.
## 3. GameState extends RefCounted and is neither Node nor Resource.
## 4. Distinct constructions produce distinct instances (no singleton or static instance).
class_name TestGameState
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGameState"


func run_tests() -> void:
	_test_construction()
	_test_type_identity()
	_test_ref_counted_and_not_node_or_resource()
	_test_separate_instances()


func _test_construction() -> void:
	describe("GameState can be constructed in isolation")
	var state: GameState = GameState.new()
	assert_true(state != null, "GameState instance should not be null")


func _test_type_identity() -> void:
	describe("GameState satisfies its own type identity")
	var state: GameState = GameState.new()
	assert_true(state is GameState, "Instance must satisfy 'is GameState'")


func _test_ref_counted_and_not_node_or_resource() -> void:
	describe("GameState extends RefCounted and is neither Node nor Resource")
	var state: GameState = GameState.new()
	assert_true(state is RefCounted, "GameState must extend RefCounted")
	var obj: Variant = state
	assert_false(obj is Node, "GameState must not be a Node")
	assert_false(obj is Resource, "GameState must not be a Resource")


func _test_separate_instances() -> void:
	describe("Separate constructions yield distinct instances (not a singleton)")
	var a: GameState = GameState.new()
	var b: GameState = GameState.new()
	assert_true(a != null, "Instance 'a' must not be null")
	assert_true(b != null, "Instance 'b' must not be null")
	assert_ne(a, b, "Separate GameState instances must not be identical")
