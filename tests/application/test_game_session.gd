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
## 8. grant_currency() through GameSession mutates authoritative GameState.
## 9. try_spend_currency() through GameSession mutates authoritative GameState.
## 10. Insufficient spend through GameSession returns false and leaves balance unchanged.
## 11. Injected GameState economy mutations affect original instance without copying.
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
	_test_grant_currency_mutates_state()
	_test_spend_currency_mutates_state()
	_test_insufficient_spend()
	_test_injected_game_state_identity_preserves_mutation()


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


func _test_grant_currency_mutates_state() -> void:
	describe("grant_currency() through GameSession mutates authoritative GameState")
	var session: GameSession = GameSession.new()
	var result: bool = session.grant_currency(5)
	assert_true(result, "session.grant_currency(5) must return true")
	assert_eq(session.get_currency(), 5, "session.get_currency() must be 5")
	assert_eq(
		session.get_state().get_economy().get_currency(), 5,
		"authoritative state currency must be 5"
	)


func _test_spend_currency_mutates_state() -> void:
	describe("try_spend_currency() through GameSession mutates authoritative GameState")
	var session: GameSession = GameSession.new()
	session.grant_currency(10)
	var result: bool = session.try_spend_currency(4)
	assert_true(result, "session.try_spend_currency(4) must return true")
	assert_eq(session.get_currency(), 6, "session.get_currency() must be 6 after spend")
	assert_eq(
		session.get_state().get_economy().get_currency(), 6,
		"authoritative state currency must be 6 after spend"
	)


func _test_insufficient_spend() -> void:
	describe("Insufficient spend returns false and preserves balance unchanged")
	var session: GameSession = GameSession.new()
	session.grant_currency(3)
	var result: bool = session.try_spend_currency(4)
	assert_false(result, "session.try_spend_currency(4) with balance 3 must return false")
	assert_eq(session.get_currency(), 3, "session.get_currency() must remain 3")
	assert_eq(
		session.get_state().get_economy().get_currency(), 3,
		"authoritative balance must remain 3"
	)


func _test_injected_game_state_identity_preserves_mutation() -> void:
	describe("Injected GameState mutates directly without copying")
	var existing: GameState = GameState.new()
	var session: GameSession = GameSession.new(existing)
	var result: bool = session.grant_currency(7)
	assert_true(result, "session.grant_currency(7) must return true")
	assert_eq(
		existing.get_economy().get_currency(), 7,
		"injected GameState economy must reflect mutation directly"
	)
	assert_eq(session.get_currency(), 7, "session.get_currency() must be 7")
