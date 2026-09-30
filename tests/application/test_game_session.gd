## test_game_session.gd
## Unit tests for Garden's GameSession application-layer state owner.
##
## Verifies:
## 1. GameSession can be constructed in isolation without SceneTree.
## 2. GameSession extends RefCounted and is neither Node nor Resource.
## 3. Fresh session owns exactly one non-null GameState.
## 4. get_state() returns a stable authoritative identity across repeated calls.
## 5. Separate GameSession instances own distinct GameState instances.
## 6. Injecting an existing GameState preserves exact object identity.
## 7. Explicitly passing null to constructor creates a fresh GameState instance.
class_name TestGameSession
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGameSession"


func run_tests() -> void:
	_test_construction()
	_test_type_contract()
	_test_fresh_session_owns_state()
	_test_stable_authoritative_identity()
	_test_separate_sessions_have_separate_states()
	_test_existing_state_injection()
	_test_null_initial_state_creates_fresh_state()


func _test_construction() -> void:
	describe("GameSession can be constructed in isolation")
	var session: GameSession = GameSession.new()
	assert_true(session != null, "GameSession instance should not be null")


func _test_type_contract() -> void:
	describe("GameSession satisfies type contract: RefCounted, not Node, not Resource")
	var session: GameSession = GameSession.new()
	assert_true(session is GameSession, "Instance must satisfy 'is GameSession'")
	assert_true(session is RefCounted, "GameSession must extend RefCounted")
	var obj: Variant = session
	assert_false(obj is Node, "GameSession must not be a Node")
	assert_false(obj is Resource, "GameSession must not be a Resource")


func _test_fresh_session_owns_state() -> void:
	describe("Fresh GameSession owns a non-null GameState instance")
	var session: GameSession = GameSession.new()
	assert_true(session.get_state() != null, "get_state() must not be null")
	assert_true(session.get_state() is GameState, "get_state() must return a GameState instance")


func _test_stable_authoritative_identity() -> void:
	describe("get_state() returns the exact same GameState instance on repeated calls")
	var session: GameSession = GameSession.new()
	var state_a: GameState = session.get_state()
	var state_b: GameState = session.get_state()
	assert_true(state_a != null, "First get_state() call returned null")
	assert_true(state_b != null, "Second get_state() call returned null")
	assert_eq(state_a, state_b, "Repeated get_state() calls must return identical instance")


func _test_separate_sessions_have_separate_states() -> void:
	describe("Separate fresh sessions own distinct GameState instances")
	var session_a: GameSession = GameSession.new()
	var session_b: GameSession = GameSession.new()
	assert_ne(session_a, session_b, "Separate GameSession instances must not be equal")
	assert_ne(
		session_a.get_state(),
		session_b.get_state(),
		"Separate sessions must own separate GameState instances"
	)


func _test_existing_state_injection() -> void:
	describe("Existing GameState injection preserves exact object identity")
	var existing: GameState = GameState.new()
	var session: GameSession = GameSession.new(existing)
	assert_eq(
		session.get_state(),
		existing,
		"Injected GameState must be returned by get_state() without copying"
	)


func _test_null_initial_state_creates_fresh_state() -> void:
	describe("Passing null as initial_state creates a fresh GameState")
	var session_null: GameSession = GameSession.new(null)
	assert_true(session_null.get_state() != null, "session with null initial_state must have state")
	assert_true(
		session_null.get_state() is GameState,
		"session with null initial_state must own a GameState"
	)
	var session_fresh: GameSession = GameSession.new()
	assert_ne(
		session_null.get_state(),
		session_fresh.get_state(),
		"session created with null should own a distinct fresh GameState"
	)
