## test_lifecycle_coordinator.gd
## Unit test suite for Garden's LifecycleCoordinator.
##
## Verifies:
## 1. Type contract: RefCounted, not a Node, typed enum outcomes.
## 2. Initial state: active (not paused), no prior outcome.
## 3. Active session pause saves exact GameState instance once.
## 4. Null session pause skips save (SKIPPED_NO_ACTIVE_SESSION) without touching repository.
## 5. Duplicate pause suppression: multiple pauses without resume do not save again.
## 6. Resume resets transition gate: resume performs no save, but enables next pause to save.
## 7. Repeated resume calls are safe and idempotent.
## 8. Save failure returns FAILED and marks coordinator paused.
## 9. Failed save is not retried on duplicate pause during the same paused period.
## 10. Later pause after resume retries after a prior failure.
## 11. Coordinator retains and uses the exact injected LocalSaveRepository instance.
## 12. Coordinator never creates, replaces, or mutates the GameSession or GameState.
class_name TestLifecycleCoordinator
extends TestSuiteBase


## Lightweight test double repository tracking save calls and state arguments.
class MockSaveRepository extends LocalSaveRepository:
	var save_calls: int = 0
	var saved_states: Array[GameState] = []
	var should_succeed: bool = true

	func _init() -> void:
		super(
			"user://__mock_lifecycle_pri.json",
			"user://__mock_lifecycle_tmp.tmp",
			"user://__mock_lifecycle_bak.bak",
			"user://__mock_lifecycle_corrupt.corrupt"
		)

	func save(state: GameState) -> bool:
		save_calls += 1
		saved_states.append(state)
		return should_succeed


func _init() -> void:
	suite_name = "TestLifecycleCoordinator"


func run_tests() -> void:
	_test_type_contract()
	_test_initial_state_active_not_paused()
	_test_active_session_pause_saves_exact_state()
	_test_null_session_pause_skips_save()
	_test_duplicate_pause_suppression()
	_test_resume_resets_transition_gate()
	_test_repeated_resume_safe()
	_test_save_failure_returns_failed()
	_test_failed_save_not_retried_during_same_pause()
	_test_later_pause_after_resume_retries()
	_test_uses_injected_repository()
	_test_does_not_mutate_or_replace_session()


func _test_type_contract() -> void:
	describe("LifecycleCoordinator conforms to expected type contract")
	var repo: MockSaveRepository = MockSaveRepository.new()
	var coord: LifecycleCoordinator = LifecycleCoordinator.new(repo)

	assert_true(coord != null, "coordinator must not be null")
	assert_true(coord is RefCounted, "coordinator must extend RefCounted")
	var variant_coord: Variant = coord
	assert_false(variant_coord is Node, "coordinator must NOT be a Node")
	assert_true(coord is LifecycleCoordinator, "coordinator must be LifecycleCoordinator")

	assert_eq(
		LifecycleCoordinator.PauseSaveOutcome.SAVED,
		LifecycleCoordinator.SAVED,
		"SAVED constant must match enum"
	)
	assert_eq(
		LifecycleCoordinator.PauseSaveOutcome.SKIPPED_NO_ACTIVE_SESSION,
		LifecycleCoordinator.SKIPPED_NO_ACTIVE_SESSION,
		"SKIPPED_NO_ACTIVE_SESSION constant must match enum"
	)
	assert_eq(
		LifecycleCoordinator.PauseSaveOutcome.FAILED,
		LifecycleCoordinator.FAILED,
		"FAILED constant must match enum"
	)
	assert_eq(
		LifecycleCoordinator.PauseSaveOutcome.IGNORED_DUPLICATE_PAUSE,
		LifecycleCoordinator.IGNORED_DUPLICATE_PAUSE,
		"IGNORED_DUPLICATE_PAUSE constant must match enum"
	)


func _test_initial_state_active_not_paused() -> void:
	describe("LifecycleCoordinator starts in active (not paused) state")
	var repo: MockSaveRepository = MockSaveRepository.new()
	var coord: LifecycleCoordinator = LifecycleCoordinator.new(repo)

	assert_false(coord.is_application_paused(), "is_application_paused must initially be false")
	assert_eq(coord.get_last_pause_outcome(), null, "last_pause_outcome must initially be null")


func _test_active_session_pause_saves_exact_state() -> void:
	describe("Active session PAUSED saves exact GameState once and returns SAVED")
	var repo: MockSaveRepository = MockSaveRepository.new()
	var coord: LifecycleCoordinator = LifecycleCoordinator.new(repo)
	var session: GameSession = _create_sample_session(150, 2)
	var authoritative_state: GameState = session.get_state()

	var outcome: LifecycleCoordinator.PauseSaveOutcome = coord.on_application_paused(session)

	assert_eq(outcome, LifecycleCoordinator.SAVED, "outcome must be SAVED")
	assert_true(coord.is_application_paused(), "coordinator must be marked paused")
	assert_eq(coord.get_last_pause_outcome(), LifecycleCoordinator.SAVED, "recorded outcome must be SAVED")
	assert_eq(repo.save_calls, 1, "save must be called exactly once")
	assert_eq(repo.saved_states.size(), 1, "saved_states must contain one entry")
	assert_eq(
		repo.saved_states[0],
		authoritative_state,
		"saved state must be the exact authoritative GameState instance from session"
	)


func _test_null_session_pause_skips_save() -> void:
	describe("Null session PAUSED skips save and performs no filesystem write")
	var repo: MockSaveRepository = MockSaveRepository.new()
	var coord: LifecycleCoordinator = LifecycleCoordinator.new(repo)

	var outcome: LifecycleCoordinator.PauseSaveOutcome = coord.on_application_paused(null)

	assert_eq(outcome, LifecycleCoordinator.SKIPPED_NO_ACTIVE_SESSION, "outcome must be SKIPPED_NO_ACTIVE_SESSION")
	assert_true(coord.is_application_paused(), "coordinator must be marked paused")
	assert_eq(
		coord.get_last_pause_outcome(),
		LifecycleCoordinator.SKIPPED_NO_ACTIVE_SESSION,
		"recorded outcome must be SKIPPED_NO_ACTIVE_SESSION"
	)
	assert_eq(repo.save_calls, 0, "save must NOT be called when session is null")


func _test_duplicate_pause_suppression() -> void:
	describe("Duplicate PAUSED calls without resume are suppressed and do not save again")
	var repo: MockSaveRepository = MockSaveRepository.new()
	var coord: LifecycleCoordinator = LifecycleCoordinator.new(repo)
	var session: GameSession = _create_sample_session(200, 1)

	var first_outcome: LifecycleCoordinator.PauseSaveOutcome = coord.on_application_paused(session)
	assert_eq(first_outcome, LifecycleCoordinator.SAVED, "first pause must succeed")
	assert_eq(repo.save_calls, 1, "first pause must execute one save")

	var second_outcome: LifecycleCoordinator.PauseSaveOutcome = coord.on_application_paused(session)
	assert_eq(
		second_outcome,
		LifecycleCoordinator.IGNORED_DUPLICATE_PAUSE,
		"second duplicate pause must return IGNORED_DUPLICATE_PAUSE"
	)
	assert_eq(repo.save_calls, 1, "second pause must NOT call save again")

	var third_outcome: LifecycleCoordinator.PauseSaveOutcome = coord.on_application_paused(session)
	assert_eq(
		third_outcome,
		LifecycleCoordinator.IGNORED_DUPLICATE_PAUSE,
		"third duplicate pause must return IGNORED_DUPLICATE_PAUSE"
	)
	assert_eq(repo.save_calls, 1, "third pause must NOT call save again")
	assert_true(coord.is_application_paused(), "coordinator remains paused")


func _test_resume_resets_transition_gate() -> void:
	describe("on_application_resumed() resets transition gate without saving and enables next pause")
	var repo: MockSaveRepository = MockSaveRepository.new()
	var coord: LifecycleCoordinator = LifecycleCoordinator.new(repo)
	var session: GameSession = _create_sample_session(50, 1)

	coord.on_application_paused(session)
	assert_true(coord.is_application_paused(), "coordinator paused after first pause")
	assert_eq(repo.save_calls, 1, "first pause executed 1 save")

	# Resume transition.
	coord.on_application_resumed()
	assert_false(coord.is_application_paused(), "is_application_paused must be false after resume")
	assert_eq(repo.save_calls, 1, "resume itself must NOT trigger a save")

	# Second pause transition.
	var second_outcome: LifecycleCoordinator.PauseSaveOutcome = coord.on_application_paused(session)
	assert_eq(second_outcome, LifecycleCoordinator.SAVED, "second pause must succeed")
	assert_true(coord.is_application_paused(), "coordinator paused after second pause")
	assert_eq(repo.save_calls, 2, "second pause transition must execute second save")


func _test_repeated_resume_safe() -> void:
	describe("Calling resume repeatedly is safe and idempotent")
	var repo: MockSaveRepository = MockSaveRepository.new()
	var coord: LifecycleCoordinator = LifecycleCoordinator.new(repo)

	# Calling resume before any pause.
	coord.on_application_resumed()
	coord.on_application_resumed()
	assert_false(coord.is_application_paused(), "coordinator must remain not paused")
	assert_eq(repo.save_calls, 0, "no save must occur")

	# Pause then multiple resumes.
	var session: GameSession = _create_sample_session(10, 0)
	coord.on_application_paused(session)
	assert_true(coord.is_application_paused(), "paused")
	assert_eq(repo.save_calls, 1, "1 save called")

	coord.on_application_resumed()
	assert_false(coord.is_application_paused(), "unpaused after first resume")
	coord.on_application_resumed()
	assert_false(coord.is_application_paused(), "unpaused after second resume")
	assert_eq(repo.save_calls, 1, "repeated resume must not trigger saves")


func _test_save_failure_returns_failed() -> void:
	describe("Save failure returns FAILED and marks coordinator paused")
	var repo: MockSaveRepository = MockSaveRepository.new()
	repo.should_succeed = false
	var coord: LifecycleCoordinator = LifecycleCoordinator.new(repo)
	var session: GameSession = _create_sample_session(300, 1)

	var outcome: LifecycleCoordinator.PauseSaveOutcome = coord.on_application_paused(session)

	assert_eq(outcome, LifecycleCoordinator.FAILED, "outcome must be FAILED")
	assert_true(coord.is_application_paused(), "coordinator must still be marked paused")
	assert_eq(coord.get_last_pause_outcome(), LifecycleCoordinator.FAILED, "recorded outcome must be FAILED")
	assert_eq(repo.save_calls, 1, "save must be attempted once")


func _test_failed_save_not_retried_during_same_pause() -> void:
	describe("Failed save is not retried on duplicate pause during the same paused period")
	var repo: MockSaveRepository = MockSaveRepository.new()
	repo.should_succeed = false
	var coord: LifecycleCoordinator = LifecycleCoordinator.new(repo)
	var session: GameSession = _create_sample_session(300, 1)

	var first_outcome: LifecycleCoordinator.PauseSaveOutcome = coord.on_application_paused(session)
	assert_eq(first_outcome, LifecycleCoordinator.FAILED, "first pause returns FAILED")
	assert_eq(repo.save_calls, 1, "first pause calls save once")

	var second_outcome: LifecycleCoordinator.PauseSaveOutcome = coord.on_application_paused(session)
	assert_eq(
		second_outcome,
		LifecycleCoordinator.IGNORED_DUPLICATE_PAUSE,
		"duplicate pause after failure must return IGNORED_DUPLICATE_PAUSE"
	)
	assert_eq(repo.save_calls, 1, "duplicate pause must NOT retry save")


func _test_later_pause_after_resume_retries() -> void:
	describe("A subsequent pause transition after resume retries saving after prior failure")
	var repo: MockSaveRepository = MockSaveRepository.new()
	repo.should_succeed = false
	var coord: LifecycleCoordinator = LifecycleCoordinator.new(repo)
	var session: GameSession = _create_sample_session(300, 1)

	coord.on_application_paused(session)
	assert_eq(repo.save_calls, 1, "first failed attempt")

	coord.on_application_resumed()
	assert_false(coord.is_application_paused(), "active again")

	# Storage recovered.
	repo.should_succeed = true

	var second_outcome: LifecycleCoordinator.PauseSaveOutcome = coord.on_application_paused(session)
	assert_eq(second_outcome, LifecycleCoordinator.SAVED, "second pause after resume must succeed")
	assert_eq(repo.save_calls, 2, "second pause must execute second save attempt")


func _test_uses_injected_repository() -> void:
	describe("LifecycleCoordinator retains and uses exact injected repository")
	var repo: MockSaveRepository = MockSaveRepository.new()
	var coord: LifecycleCoordinator = LifecycleCoordinator.new(repo)

	assert_eq(coord.get_save_repository(), repo, "coordinator must hold exact injected repository instance")


func _test_does_not_mutate_or_replace_session() -> void:
	describe("Coordinator does not mutate or replace GameSession or GameState on pause")
	var repo: MockSaveRepository = MockSaveRepository.new()
	var coord: LifecycleCoordinator = LifecycleCoordinator.new(repo)
	var session: GameSession = _create_sample_session(500, 3)
	var state_before: GameState = session.get_state()
	var currency_before: int = session.get_currency()
	var plants_before: int = session.get_state().get_plants().get_count()

	coord.on_application_paused(session)

	assert_eq(session.get_state(), state_before, "GameState instance reference must be identical")
	assert_eq(session.get_currency(), currency_before, "currency must not be mutated by pause")
	assert_eq(
		session.get_state().get_plants().get_count(),
		plants_before,
		"plant count must not be mutated by pause"
	)


func _create_sample_session(currency: int, plant_count: int = 0) -> GameSession:
	var state: GameState = GameState.new()
	if currency > 0:
		state.get_economy().grant_currency(currency)
	for i in range(plant_count):
		var plant: PlantState = PlantState.new("coord_plant_%d" % i, "plant.holy_basil", 1700000000 + i)
		state.get_plants().try_add_plant(plant)
	return GameSession.new(state)
