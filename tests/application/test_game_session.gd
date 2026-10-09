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
## 12. Successful registration through GameSession mutates authoritative GameState.
## 13. GameSession state identity is preserved before and after registration without replacement.
## 14. Unknown definition and duplicate instance ID rejected with no currency or state mutation.
## 15. Independent GameSessions remain isolated.
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
	_test_register_plant_success()
	_test_register_plant_state_identity_preservation()
	_test_register_plant_rejections_and_atomicity()
	_test_register_plant_isolation_between_sessions()



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


func _create_test_catalog() -> ContentCatalog:
	var def: PlantDefinition = PlantDefinition.new()
	def.id = "plant.holy_basil"
	def.sprout_after_seconds = 60
	def.growing_after_seconds = 300
	def.mature_after_seconds = 900
	return ContentCatalog.try_create([def])


func _test_register_plant_success() -> void:
	describe("Successful plant registration through GameSession mutates authoritative GameState")
	var session: GameSession = GameSession.new()
	var catalog: ContentCatalog = _create_test_catalog()

	var result: PlantRegistrationResult = session.try_register_plant(
		catalog, "session-inst-1", "plant.holy_basil", 1000
	)

	assert_true(result.is_registered(), "Registration must succeed")
	assert_eq(result.get_status(), PlantRegistrationResult.REGISTERED, "Status must be REGISTERED")
	assert_true(result.get_plant() != null, "get_plant() must not be null")
	assert_eq(result.get_plant().get_runtime_instance_id(), "session-inst-1", "Instance ID must match")

	var state: GameState = session.get_state()
	assert_eq(state.get_plants().get_count(), 1, "Plant count must be 1")
	assert_true(state.get_plants().has_runtime_instance_id("session-inst-1"), "Collection must contain plant")
	assert_eq(state.get_plants().get_plant("session-inst-1"), result.get_plant(), "Stored plant must match returned reference")


func _test_register_plant_state_identity_preservation() -> void:
	describe("Registration through GameSession preserves exact GameState identity without replacement")
	var existing: GameState = GameState.new()
	var session: GameSession = GameSession.new(existing)
	var catalog: ContentCatalog = _create_test_catalog()

	var state_before: GameState = session.get_state()
	assert_eq(state_before, existing, "State before must match injected instance")

	var result: PlantRegistrationResult = session.try_register_plant(
		catalog, "session-inst-id", "plant.holy_basil", 1000
	)
	assert_true(result.is_registered(), "Registration must succeed")

	var state_after: GameState = session.get_state()
	assert_eq(state_after, existing, "State after must remain exact same injected instance")
	assert_eq(existing.get_plants().get_count(), 1, "Injected GameState reflects plant mutation directly")
	assert_eq(existing.get_plants().get_plant("session-inst-id"), result.get_plant(), "Stored plant in injected state matches")


func _test_register_plant_rejections_and_atomicity() -> void:
	describe("Failed registrations through GameSession are rejected and cause no mutation or currency change")
	var session: GameSession = GameSession.new()
	session.grant_currency(100)
	var catalog: ContentCatalog = _create_test_catalog()

	# Unknown definition rejected
	var res_unknown: PlantRegistrationResult = session.try_register_plant(
		catalog, "inst-1", "plant.unknown", 1000
	)
	assert_eq(res_unknown.get_status(), PlantRegistrationResult.UNKNOWN_DEFINITION_ID, "Unknown definition must return UNKNOWN_DEFINITION_ID")
	assert_false(res_unknown.is_registered(), "is_registered() must be false")
	assert_true(res_unknown.get_plant() == null, "get_plant() must be null")
	assert_eq(session.get_state().get_plants().get_count(), 0, "Plant count remains 0")
	assert_eq(session.get_currency(), 100, "Currency remains 100")

	# Register first valid plant
	var res_valid: PlantRegistrationResult = session.try_register_plant(
		catalog, "inst-1", "plant.holy_basil", 1000
	)
	assert_true(res_valid.is_registered(), "First registration must succeed")
	assert_eq(session.get_state().get_plants().get_count(), 1, "Plant count becomes 1")
	assert_eq(session.get_currency(), 100, "Currency remains 100")

	# Duplicate runtime instance ID rejected
	var res_dup: PlantRegistrationResult = session.try_register_plant(
		catalog, "inst-1", "plant.holy_basil", 2000
	)
	assert_eq(res_dup.get_status(), PlantRegistrationResult.DUPLICATE_INSTANCE_ID, "Duplicate ID must return DUPLICATE_INSTANCE_ID")
	assert_false(res_dup.is_registered(), "is_registered() must be false")
	assert_true(res_dup.get_plant() == null, "get_plant() must be null")
	assert_eq(session.get_state().get_plants().get_count(), 1, "Plant count remains 1")
	assert_eq(session.get_currency(), 100, "Currency remains 100")

	# Repeated failed commands cause no mutation
	for i: int in range(5):
		var res_fail: PlantRegistrationResult = session.try_register_plant(
			catalog, "inst-1", "plant.holy_basil", 3000
		)
		assert_false(res_fail.is_registered(), "Repeated duplicate must fail")
	assert_eq(session.get_state().get_plants().get_count(), 1, "Plant count unchanged after repeated failures")
	assert_eq(session.get_currency(), 100, "Currency unchanged after repeated failures")


func _test_register_plant_isolation_between_sessions() -> void:
	describe("Independent GameSessions remain completely isolated during plant registration")
	var session_a: GameSession = GameSession.new()
	var session_b: GameSession = GameSession.new()
	var catalog: ContentCatalog = _create_test_catalog()

	var res_a: PlantRegistrationResult = session_a.try_register_plant(
		catalog, "shared-id", "plant.holy_basil", 1000
	)
	assert_true(res_a.is_registered(), "Session A registration must succeed")

	# Session B should be able to use "shared-id" because its state is independent
	var res_b: PlantRegistrationResult = session_b.try_register_plant(
		catalog, "shared-id", "plant.holy_basil", 2000
	)
	assert_true(res_b.is_registered(), "Session B registration with same ID in distinct session must succeed")

	assert_eq(session_a.get_state().get_plants().get_count(), 1, "Session A count is 1")
	assert_eq(session_b.get_state().get_plants().get_count(), 1, "Session B count is 1")
	assert_ne(
		session_a.get_state().get_plants().get_plant("shared-id"),
		session_b.get_state().get_plants().get_plant("shared-id"),
		"Plant states in independent sessions must be separate instances"
	)
	assert_eq(session_a.get_state().get_plants().get_plant("shared-id").get_planted_at(), 1000, "Session A timestamp matches")
	assert_eq(session_b.get_state().get_plants().get_plant("shared-id").get_planted_at(), 2000, "Session B timestamp matches")
