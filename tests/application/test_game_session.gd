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
	_test_try_plant_now_success()
	_test_try_plant_now_state_identity_preservation()
	_test_try_plant_now_rejections_and_atomicity()
	_test_try_plant_now_id_generation_failure_propagation()
	_test_try_plant_now_session_isolation()
	_test_try_plant_now_persistence_round_trip()
	_test_try_harvest_delegation_and_atomicity()
	_test_snapshot_and_visitor_evaluation_delegation()
	_test_record_discovery_delegation()
	_test_try_purchase_decoration_delegation()
	_test_evaluate_event_delegation()
	_test_evaluate_progression_delegation()
	_test_evaluate_return_delegation()



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
	def.harvest_reward = 5
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


func _test_try_plant_now_success() -> void:
	describe("try_plant_now delegates to PlantingCommandService and mutates session state")
	var session: GameSession = GameSession.new()
	session.grant_currency(50)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])

	var result: PlantRegistrationResult = session.try_plant_now(
		catalog, clock, rng, "plant.holy_basil"
	)

	assert_true(result.is_registered(), "Registration must succeed")
	assert_eq(result.get_status(), PlantRegistrationResult.REGISTERED, "Status must be REGISTERED")
	assert_true(result.get_plant() != null, "get_plant() must not be null")
	assert_eq(
		result.get_plant().get_runtime_instance_id(),
		"plant-inst-00000001000000020000000300000004",
		"Generated ID must match format"
	)
	assert_eq(result.get_plant().get_planted_at(), 1700000000, "Planted_at must match clock")

	var state: GameState = session.get_state()
	assert_eq(state.get_plants().get_count(), 1, "Collection count is 1")
	var stored: PlantState = state.get_plants().get_plant("plant-inst-00000001000000020000000300000004")
	assert_eq(stored, result.get_plant(), "Stored plant must be exact returned object reference")
	assert_eq(session.get_currency(), 50, "Currency remains unmutated")


func _test_try_plant_now_state_identity_preservation() -> void:
	describe("try_plant_now preserves exact injected GameState object identity")
	var existing: GameState = GameState.new()
	var session: GameSession = GameSession.new(existing)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])

	var state_before: GameState = session.get_state()
	assert_eq(state_before, existing, "State before must match injected instance")

	var result: PlantRegistrationResult = session.try_plant_now(
		catalog, clock, rng, "plant.holy_basil"
	)
	assert_true(result.is_registered(), "Registration must succeed")

	var state_after: GameState = session.get_state()
	assert_eq(state_after, existing, "State after must remain exact same injected instance")
	assert_eq(existing.get_plants().get_count(), 1, "Injected GameState reflects planting directly")


func _test_try_plant_now_rejections_and_atomicity() -> void:
	describe("try_plant_now rejections leave state and economy completely unmutated")
	var session: GameSession = GameSession.new()
	session.grant_currency(100)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var empty_rng: FakeRandomSource = FakeRandomSource.new([], [])

	# Unknown definition rejected
	var res_unknown: PlantRegistrationResult = session.try_plant_now(
		catalog, clock, empty_rng, "plant.unknown"
	)
	assert_eq(
		res_unknown.get_status(),
		PlantRegistrationResult.UNKNOWN_DEFINITION_ID,
		"Must return UNKNOWN_DEFINITION_ID"
	)
	assert_false(res_unknown.is_registered(), "is_registered() must be false")
	assert_true(res_unknown.get_plant() == null, "get_plant() must be null")
	assert_eq(session.get_state().get_plants().get_count(), 0, "No plants added")
	assert_eq(session.get_currency(), 100, "Currency remains 100")

	# Structurally invalid syntax rejected
	var res_syntax: PlantRegistrationResult = session.try_plant_now(
		catalog, clock, empty_rng, "invalid_syntax"
	)
	assert_eq(
		res_syntax.get_status(),
		PlantRegistrationResult.INVALID_INPUT,
		"Must return INVALID_INPUT"
	)
	assert_false(res_syntax.is_registered(), "is_registered() must be false")
	assert_eq(session.get_state().get_plants().get_count(), 0, "No plants added")
	assert_eq(session.get_currency(), 100, "Currency remains 100")


func _test_try_plant_now_id_generation_failure_propagation() -> void:
	describe("try_plant_now propagates ID_GENERATION_FAILED without state or currency mutation")
	var session: GameSession = GameSession.new()
	session.grant_currency(75)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)

	# Pre-populate 8 plants
	for i: int in range(1, 9):
		var existing_id: String = "%s%08x%08x%08x%08x" % [PlantRuntimeIdGenerator.ID_PREFIX, i, i, i, i]
		session.get_state().get_plants().try_add_plant(PlantState.new(existing_id, "plant.holy_basil", 500))

	# Script 32 colliding draws
	var draws: Array[int] = []
	for i: int in range(1, 9):
		draws.append_array([i, i, i, i])

	var rng: FakeRandomSource = FakeRandomSource.new([], draws)
	var result: PlantRegistrationResult = session.try_plant_now(
		catalog, clock, rng, "plant.holy_basil"
	)

	assert_eq(
		result.get_status(),
		PlantRegistrationResult.ID_GENERATION_FAILED,
		"Status must be ID_GENERATION_FAILED"
	)
	assert_false(result.is_registered(), "is_registered() must be false")
	assert_true(result.get_plant() == null, "get_plant() must be null")
	assert_eq(session.get_state().get_plants().get_count(), 8, "Collection count remains 8")
	assert_eq(session.get_currency(), 75, "Currency remains 75")


func _test_try_plant_now_session_isolation() -> void:
	describe("Distinct GameSessions remain isolated during try_plant_now calls")
	var session_a: GameSession = GameSession.new()
	var session_b: GameSession = GameSession.new()
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)

	var rng_a: FakeRandomSource = FakeRandomSource.new([], [1, 1, 1, 1])
	var rng_b: FakeRandomSource = FakeRandomSource.new([], [2, 2, 2, 2])

	var res_a: PlantRegistrationResult = session_a.try_plant_now(catalog, clock, rng_a, "plant.holy_basil")
	var res_b: PlantRegistrationResult = session_b.try_plant_now(catalog, clock, rng_b, "plant.holy_basil")

	assert_true(res_a.is_registered(), "Session A planting must succeed")
	assert_true(res_b.is_registered(), "Session B planting must succeed")
	assert_eq(session_a.get_state().get_plants().get_count(), 1, "Session A count is 1")
	assert_eq(session_b.get_state().get_plants().get_count(), 1, "Session B count is 1")
	assert_ne(
		session_a.get_state().get_plants().get_all_plants()[0],
		session_b.get_state().get_plants().get_all_plants()[0],
		"Stored plants must be distinct instances"
	)


func _test_try_plant_now_persistence_round_trip() -> void:
	describe("In-memory persistence round trip through GameSession and restored state planting")
	var session_a: GameSession = GameSession.new()
	session_a.grant_currency(123)
	var catalog: ContentCatalog = _create_test_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng_a: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])

	var res_a: PlantRegistrationResult = session_a.try_plant_now(catalog, clock, rng_a, "plant.holy_basil")
	assert_true(res_a.is_registered(), "Session A planting must succeed")

	# Save/encode -> JSON stringify -> parse -> decode
	var encoded: Dictionary = GameStateCodec.encode(session_a.get_state())
	var json_str: String = JSON.stringify(encoded)
	var parsed: Variant = JSON.parse_string(json_str)
	var decoded_state: GameState = GameStateCodec.decode(parsed)

	assert_true(decoded_state != null, "Decoded state must not be null")
	assert_eq(decoded_state.get_economy().get_currency(), 123, "Exact currency preserved")
	assert_eq(decoded_state.get_plants().get_count(), 1, "Exact plant count preserved")

	var restored_plant: PlantState = decoded_state.get_plants().get_plant(
		"plant-inst-00000001000000020000000300000004"
	)
	assert_true(restored_plant != null, "Restored plant must exist")
	assert_eq(
		restored_plant.get_runtime_instance_id(),
		"plant-inst-00000001000000020000000300000004",
		"Instance ID exact"
	)
	assert_eq(restored_plant.get_definition_id(), "plant.holy_basil", "Definition ID exact")
	assert_eq(restored_plant.get_planted_at(), 1700000000, "Planted_at exact")

	# Construct Session B from decoded GameState
	var session_b: GameSession = GameSession.new(decoded_state)
	assert_eq(session_b.get_currency(), 123, "Session B currency matches")

	# Script collision against restored plant ID, followed by unique candidate 2
	var rng_b: FakeRandomSource = FakeRandomSource.new([], [
		1, 2, 3, 4, # Collides with restored plant!
		5, 6, 7, 8  # Unique candidate 2!
	])
	var clock_b: FakeGameClock = FakeGameClock.new(1700000500, 0)

	var res_b: PlantRegistrationResult = session_b.try_plant_now(catalog, clock_b, rng_b, "plant.holy_basil")
	assert_true(res_b.is_registered(), "Session B planting must succeed after collision retry")
	assert_eq(
		res_b.get_plant().get_runtime_instance_id(),
		"plant-inst-00000005000000060000000700000008",
		"Candidate 2 instance ID"
	)
	assert_eq(session_b.get_state().get_plants().get_count(), 2, "Session B now contains 2 plants")
	assert_eq(session_b.get_currency(), 123, "Session B currency remains 123")


func _test_try_harvest_delegation_and_atomicity() -> void:
	describe("GameSession try_harvest_plant_at and try_harvest_now delegate to PlantHarvestService")
	var session: GameSession = GameSession.new()
	var catalog: ContentCatalog = _create_test_catalog()
	var state_ref: GameState = session.get_state()

	session.try_register_plant(catalog, "session-basil-1", "plant.holy_basil", 1000)

	# Reject before maturity (mature_after_seconds = 900 in _create_test_catalog)
	var r_early: PlantHarvestResult = session.try_harvest_plant_at(catalog, "session-basil-1", 1500)
	assert_eq(r_early.get_status(), PlantHarvestResult.PLANT_NOT_MATURE, "Not mature at 1500")
	assert_eq(session.get_currency(), 0, "Currency remains 0")

	# Harvest via try_harvest_now at t = 1900
	var clock: FakeGameClock = FakeGameClock.new(1900, 0)
	var r_ok: PlantHarvestResult = session.try_harvest_now(catalog, clock, "session-basil-1")
	assert_true(r_ok.is_harvested(), "Harvest succeeds at 1900")
	assert_eq(r_ok.get_reward_granted(), 5, "Reward 5 granted")
	assert_eq(session.get_currency(), 5, "Session currency is 5")
	assert_eq(session.get_state(), state_ref, "GameState identity preserved")
	assert_eq(
		session.get_state().get_plants().get_plant("session-basil-1").get_planted_at(),
		1900,
		"Planted_at reset to 1900"
	)


func _test_snapshot_and_visitor_evaluation_delegation() -> void:
	describe("GameSession build_garden_snapshot, evaluate_visitor_at, and evaluate_visitor_now delegate deterministically")
	var plants: Array[PlantDefinition] = PlantContentLoader.new().load_production_definitions().get_definitions()
	var visitors: Array[VisitorDefinition] = VisitorContentLoader.new().load_production_definitions().get_definitions()
	var catalog: ContentCatalog = ContentCatalog.try_create(plants, visitors)

	var session: GameSession = GameSession.new()
	session.try_register_plant(catalog, "jasmine-1", "plant.jasmine", 1000)

	var snapshot: GardenSnapshot = session.build_garden_snapshot(catalog, 1000)
	assert_true(snapshot != null, "Snapshot built via GameSession")
	assert_eq(snapshot.get_active_traits(), ["dense_vegetation", "flower"], "Snapshot reflects jasmine traits")

	var rng_at: FakeRandomSource = FakeRandomSource.new([0.1], [])
	var res_at: VisitorSelectionResult = session.evaluate_visitor_at(catalog, rng_at, 1000)
	assert_true(res_at.is_selected(), "evaluate_visitor_at selects visitor")
	assert_eq(res_at.get_selected_visitor_id(), "visitor.butterfly", "Roll 0.1 selects visitor.butterfly")

	var clock: FakeGameClock = FakeGameClock.new(1000, 0)
	var rng_now: FakeRandomSource = FakeRandomSource.new([0.8], [])
	var res_now: VisitorSelectionResult = session.evaluate_visitor_now(catalog, clock, rng_now)
	assert_true(res_now.is_selected(), "evaluate_visitor_now selects visitor")
	assert_eq(res_now.get_selected_visitor_id(), "visitor.firefly", "Roll 0.8 selects visitor.firefly")


func _test_record_discovery_delegation() -> void:
	describe("GameSession record_discovery_at and record_discovery_now delegate to JournalDiscoveryService")
	var plants: Array[PlantDefinition] = PlantContentLoader.new().load_production_definitions().get_definitions()
	var visitors: Array[VisitorDefinition] = VisitorContentLoader.new().load_production_definitions().get_definitions()
	var catalog: ContentCatalog = ContentCatalog.try_create(plants, visitors)
	var session: GameSession = GameSession.new()

	var first: JournalDiscoveryResult = session.record_discovery_at(catalog, "visitor.butterfly", 1200)
	assert_true(first.is_recorded(), "First discovery recorded via session")
	assert_true(first.is_first_discovery(), "Reported as first discovery")

	var clock: FakeGameClock = FakeGameClock.new(1800, 0)
	var second: JournalDiscoveryResult = session.record_discovery_now(catalog, clock, "visitor.butterfly")
	assert_true(second.is_recorded(), "Repeat sighting recorded via session")
	assert_true(second.is_repeat_sighting(), "Reported as repeat sighting")
	assert_eq(second.get_record().get_first_seen_at(), 1200, "first_seen_at preserved at 1200")
	assert_eq(second.get_record().get_times_seen(), 2, "times_seen incremented to 2")


func _test_try_purchase_decoration_delegation() -> void:
	describe("GameSession try_purchase_decoration_at and try_purchase_decoration_now delegate to DecorationPurchaseService")
	var plants: Array[PlantDefinition] = PlantContentLoader.new().load_production_definitions().get_definitions()
	var visitors: Array[VisitorDefinition] = VisitorContentLoader.new().load_production_definitions().get_definitions()
	var decors: Array[DecorationDefinition] = DecorationContentLoader.new().load_production_definitions().get_definitions()
	var catalog: ContentCatalog = ContentCatalog.try_create(plants, visitors, decors)

	var session: GameSession = GameSession.new()
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])

	# Insufficient funds rejected without mutating state
	var r_poor: DecorationPurchaseResult = session.try_purchase_decoration_at(
		catalog, "dec-1", "decoration.clay_jar", 1000
	)
	assert_eq(r_poor.get_status(), DecorationPurchaseResult.INSUFFICIENT_CURRENCY, "Insufficient currency rejected")
	assert_eq(session.get_state().get_decorations().get_count(), 0, "0 decorations")

	# Grant 50 coins and purchase clay_jar (price 15) and bench (price 25)
	session.grant_currency(50)
	var r_jar: DecorationPurchaseResult = session.try_purchase_decoration_at(
		catalog, "dec-1", "decoration.clay_jar", 1000
	)
	assert_true(r_jar.is_purchased(), "Clay jar purchased")
	assert_eq(r_jar.get_price_spent(), 15, "Spent 15")
	assert_eq(session.get_currency(), 35, "Balance is 35")

	var clock: FakeGameClock = FakeGameClock.new(2000, 0)
	var r_bench: DecorationPurchaseResult = session.try_purchase_decoration_now(
		catalog, clock, rng, "decoration.bench"
	)
	assert_true(r_bench.is_purchased(), "Bench purchased via try_purchase_decoration_now")
	assert_eq(r_bench.get_price_spent(), 25, "Spent 25")
	assert_eq(session.get_currency(), 10, "Balance is 10")
	assert_eq(session.get_state().get_decorations().get_count(), 2, "2 decorations placed")


func _test_evaluate_event_delegation() -> void:
	describe("GameSession evaluate_event_at and evaluate_event_now delegate to EventSelectionService")
	var plants: Array[PlantDefinition] = PlantContentLoader.new().load_production_definitions().get_definitions()
	var visitors: Array[VisitorDefinition] = VisitorContentLoader.new().load_production_definitions().get_definitions()
	var decors: Array[DecorationDefinition] = DecorationContentLoader.new().load_production_definitions().get_definitions()
	var events: Array[EventDefinition] = EventContentLoader.new().load_production_definitions().get_definitions()
	var catalog: ContentCatalog = ContentCatalog.try_create(plants, visitors, decors, events)

	var session: GameSession = GameSession.new()
	session.try_register_plant(catalog, "jasmine-1", "plant.jasmine", 1000)

	# t = 21600 -> morning + clear -> event.morning_butterflies
	var rng_at: FakeRandomSource = FakeRandomSource.new([0.1], [])
	var res_at: EventSelectionResult = session.evaluate_event_at(catalog, rng_at, 21600)
	assert_true(res_at.is_selected(), "evaluate_event_at selects morning butterflies")
	assert_eq(res_at.get_selected_event_id(), "event.morning_butterflies", "Selected event.morning_butterflies")

	var clock: FakeGameClock = FakeGameClock.new(21600, 0)
	var rng_now: FakeRandomSource = FakeRandomSource.new([0.9], [])
	var res_now: EventSelectionResult = session.evaluate_event_now(catalog, clock, rng_now)
	assert_true(res_now.is_selected(), "evaluate_event_now selects morning butterflies")
	assert_eq(res_now.get_selected_event_id(), "event.morning_butterflies", "Selected event.morning_butterflies")


func _test_evaluate_progression_delegation() -> void:
	describe("GameSession evaluate_progression_at and evaluate_progression_now delegate to GardenProgressionStage")
	var plants: Array[PlantDefinition] = PlantContentLoader.new().load_production_definitions().get_definitions()
	var visitors: Array[VisitorDefinition] = VisitorContentLoader.new().load_production_definitions().get_definitions()
	var decors: Array[DecorationDefinition] = DecorationContentLoader.new().load_production_definitions().get_definitions()
	var events: Array[EventDefinition] = EventContentLoader.new().load_production_definitions().get_definitions()
	var catalog: ContentCatalog = ContentCatalog.try_create(plants, visitors, decors, events)

	var session: GameSession = GameSession.new()

	# Empty garden -> starting_garden (0 pts), guidance.plant_first
	var sum_empty: GardenProgressionSummary = session.evaluate_progression_at(catalog, 1000)
	assert_true(sum_empty != null and sum_empty.is_valid(), "Empty session progression summary is valid")
	assert_eq(sum_empty.get_stage_id(), GardenProgressionStage.STAGE_STARTING_GARDEN, "Empty stage is starting_garden")
	assert_eq(sum_empty.get_establishment_score(), 0, "Empty establishment score is 0")
	assert_eq(sum_empty.get_guidance_id(), GardenProgressionStage.GUIDANCE_PLANT_FIRST, "Empty guidance is plant_first")
	assert_true(sum_empty.has_daily_guidance(), "Empty progression summary has daily guidance")
	assert_eq(sum_empty.get_daily_guidance_count(), 3, "Empty progression summary has 3 daily guidance suggestions")

	# Plant jasmine ("flower", "dense_vegetation") -> try_register_plant records discovery automatically:
	# score = 3 (plant) + 6 (2 traits) + 5 (1 journal discovery) = 14 -> growing_garden
	session.try_register_plant(catalog, "jasmine-1", "plant.jasmine", 1000)
	var clock: FakeGameClock = FakeGameClock.new(4600, 0) # +3600s -> jasmine is MATURE (+2 pts -> score 16)
	var sum_now: GardenProgressionSummary = session.evaluate_progression_now(catalog, clock)
	assert_true(sum_now != null and sum_now.is_valid(), "evaluate_progression_now returns valid summary")
	assert_eq(sum_now.get_stage_id(), GardenProgressionStage.STAGE_GROWING_GARDEN, "Stage is growing_garden")
	assert_eq(sum_now.get_establishment_score(), 16, "Score is 16 (1 plant=3, 1 mature=2, 2 traits=6, 1 journal=5)")
	assert_eq(
		sum_now.get_guidance_id(),
		GardenProgressionStage.GUIDANCE_OBSERVE_VISITOR,
		"Guidance suggests observing eligible visitors before any visitor is discovered"
	)
	assert_true(sum_now.has_daily_guidance(), "sum_now has daily guidance")
	assert_eq(sum_now.get_daily_guidance_count(), 3, "sum_now contains 3 daily guidance suggestions")


func _test_evaluate_return_delegation() -> void:
	describe("GameSession evaluate_return_between and evaluate_return_from_now delegate to GardenReturnEvaluator")
	var plants: Array[PlantDefinition] = PlantContentLoader.new().load_production_definitions().get_definitions()
	var visitors: Array[VisitorDefinition] = VisitorContentLoader.new().load_production_definitions().get_definitions()
	var decors: Array[DecorationDefinition] = DecorationContentLoader.new().load_production_definitions().get_definitions()
	var events: Array[EventDefinition] = EventContentLoader.new().load_production_definitions().get_definitions()
	var catalog: ContentCatalog = ContentCatalog.try_create(plants, visitors, decors, events)

	var session: GameSession = GameSession.new()
	session.try_register_plant(catalog, "basil-1", "plant.holy_basil", 1000)

	# Between t=1000 (PLANTED) and t=1600 (MATURE)
	var sum_between: GardenReturnSummary = session.evaluate_return_between(catalog, 1000, 1600)
	assert_true(sum_between != null and sum_between.is_valid(), "evaluate_return_between returns valid summary")
	assert_eq(sum_between.get_elapsed_seconds(), 600, "Elapsed is 600s")
	assert_eq(sum_between.get_advanced_plant_ids(), ["basil-1"], "basil-1 advanced")
	assert_eq(sum_between.get_newly_matured_plant_ids(), ["basil-1"], "basil-1 newly matured")
	assert_eq(sum_between.get_ready_to_harvest_count(), 1, "1 plant ready to harvest")
	assert_true(sum_between.has_meaningful_changes(), "Has meaningful changes")

	# From now with FakeGameClock at t=14400 (rain, night -> morning at 21600)
	var clock: FakeGameClock = FakeGameClock.new(21600, 0)
	var sum_now: GardenReturnSummary = session.evaluate_return_from_now(catalog, clock, 1000)
	assert_true(sum_now != null and sum_now.is_valid(), "evaluate_return_from_now returns valid summary")
	assert_eq(sum_now.get_current_utc_seconds(), 21600, "current_utc_seconds is 21600")
	assert_eq(sum_now.get_previous_time_period(), GardenTimePeriod.NIGHT, "Previous period is night")
	assert_eq(sum_now.get_current_time_period(), GardenTimePeriod.MORNING, "Current period is morning")
	assert_true(sum_now.has_time_period_changed(), "Time period changed")
	assert_eq(session.get_state().get_journal().get_count(), 1, "No offline visitor discovery added")
