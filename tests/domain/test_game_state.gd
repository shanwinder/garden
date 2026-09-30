## test_game_state.gd
## Unit tests for Garden's GameState domain root.
##
## Verifies:
## 1. GameState can be constructed without a SceneTree.
## 2. GameState satisfies its own type contract.
## 3. GameState extends RefCounted and is neither Node nor Resource.
## 4. Distinct constructions produce distinct instances (no singleton or static instance).
## 5. GameState owns a typed EconomyState slice with unique instance identity and initial balance 0.
class_name TestGameState
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGameState"


func run_tests() -> void:
	_test_construction()
	_test_type_identity()
	_test_ref_counted_and_not_node_or_resource()
	_test_separate_instances()
	_test_economy_ownership()


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


func _test_economy_ownership() -> void:
	describe("GameState owns exactly one EconomyState slice with distinct instance per GameState")
	var state: GameState = GameState.new()
	assert_true(state.get_economy() != null, "fresh GameState.get_economy() must not be null")
	assert_true(state.get_economy() is EconomyState, "get_economy() must return an EconomyState")
	assert_eq(
		state.get_economy().get_currency(), 0,
		"fresh GameState economy currency balance must be 0"
	)
	assert_eq(
		state.get_economy(),
		state.get_economy(),
		"repeated get_economy() calls must return the same instance"
	)
	var other: GameState = GameState.new()
	assert_ne(
		state.get_economy(),
		other.get_economy(),
		"separate GameState instances must own distinct EconomyState instances"
	)
