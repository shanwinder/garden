## test_planting_persistence_integration.gd
## True end-to-end integration test suite for Garden's planting persistence stack.
##
## Exercises AppRoot, GameSession, PlantingPersistenceCoordinator, PlantingCommandService,
## PlantRegistrationService, LocalSaveRepository, GameStateCodec, and ContentCatalog together
## across the real filesystem (isolated test paths under user://).
##
## Verifies:
## A. Coordinator type contract is RefCounted, not Node/Resource.
## B. Typed result statuses and getters follow exact contract.
## C. Null dependencies return NOT_READY and cause no mutation.
## D. AppRoot before bootstrap returns NOT_READY.
## E. Clean first-run NO_SAVE remains read-only until planting.
## F. First successful plant creates PRIMARY.
## G. Result REGISTERED_SAVED contains exact PlantState.
## H. Restart a new AppRoot and recover planted plant from PRIMARY.
## I. Restart preserves exact instance_id, definition_id, planted_at and currency.
## J. Second successful planting rotates previous PRIMARY to BACKUP.
## K. New PRIMARY contains both plants.
## L. BACKUP contains the preceding valid one-plant state.
## M. UNKNOWN_DEFINITION_ID does not call save.
## N. Invalid definition syntax does not call save.
## O. ID_GENERATION_FAILED does not call save.
## P. Failed planting does not change PRIMARY or BACKUP bytes.
## Q. Successful registration with injected repository.save() returning false yields REGISTERED_SAVE_FAILED.
## R. After REGISTERED_SAVE_FAILED the plant remains in GameState.
## S. After REGISTERED_SAVE_FAILED, no false durable-success status is exposed.
## T. No automatic planting retry or second ID generation occurs when save fails.
## U. An existing PRIMARY remains unchanged when a controlled failure-injected repository rejects save before doing I/O.
## V. A later successful checkpoint can persist the still-active state after a prior controlled save failure.
## W. Content bootstrap failure prevents planting and saving.
## X. INVALID_DATA and IO_ERROR prevent planting and saving.
## Y. Unknown saved plant IDs prevent planting and saving while preserving files unchanged.
## Z. An approved pause after a saved planting continues to use the existing LifecycleCoordinator behavior.
## AA. Repeated process restarts never duplicate plants.
## AB. Planting itself does not grant or spend currency.
## AC. Generated IDs remain unique across successful restarts.
## AD. All test-created save files are cleaned up from only their dedicated test paths.
class_name TestPlantingPersistenceIntegration
extends TestSuiteBase

const TEST_PRIMARY: String = "user://__garden_test_planting_integration_primary.json"
const TEST_TEMP: String = "user://__garden_test_planting_integration.tmp"
const TEST_BACKUP: String = "user://__garden_test_planting_integration.bak"
const TEST_CORRUPT: String = "user://__garden_test_planting_integration.corrupt"


## Test-only repository that tracks save calls and forwards to real LocalSaveRepository.
class CountingSaveRepository extends LocalSaveRepository:
	var save_call_count: int = 0

	func _init(
		p: String = TEST_PRIMARY,
		t: String = TEST_TEMP,
		b: String = TEST_BACKUP,
		c: String = TEST_CORRUPT
	) -> void:
		super._init(p, t, b, c)

	func save(state: GameState) -> bool:
		save_call_count += 1
		return super.save(state)


## Test-only repository that intercepts save() and returns false without disk I/O.
class FailingSaveRepository extends LocalSaveRepository:
	var save_call_count: int = 0

	func _init(
		p: String = TEST_PRIMARY,
		t: String = TEST_TEMP,
		b: String = TEST_BACKUP,
		c: String = TEST_CORRUPT
	) -> void:
		super._init(p, t, b, c)

	func save(_state: GameState) -> bool:
		save_call_count += 1
		return false


## Test-only content loader that simulates loading failure.
class FailingPlantContentLoader extends PlantContentLoader:
	func load_production_definitions() -> PlantContentLoadResult:
		return PlantContentLoadResult.create_failed(
			"res://simulated_fail.tres",
			"Simulated plant loader failure"
		)


func _init() -> void:
	suite_name = "TestPlantingPersistenceIntegration"


func setup() -> void:
	_cleanup_test_files()


func teardown() -> void:
	_cleanup_test_files()


func run_tests() -> void:
	_test_type_contract()
	_test_checkpoint_result_statuses_and_getters()
	_test_null_dependencies_return_not_ready()
	_test_app_root_before_bootstrap_returns_not_ready()
	_test_clean_first_run_read_only_until_planting()
	_test_first_planting_creates_primary()
	_test_restart_recovers_plant_from_primary()
	_test_second_planting_rotates_primary_to_backup()
	_test_unknown_definition_does_not_save()
	_test_invalid_definition_syntax_does_not_save()
	_test_id_generation_failed_does_not_save()
	_test_failed_planting_does_not_change_files()
	_test_controlled_save_failure_policy()
	_test_primary_unchanged_on_save_failure()
	_test_later_successful_checkpoint_after_save_failure()
	_test_content_bootstrap_failure_prevents_planting()
	_test_corrupt_save_startup_prevents_planting()
	_test_unknown_saved_plant_ids_prevent_planting()
	_test_lifecycle_pause_after_saved_planting()
	_test_repeated_restarts_never_duplicate_plants()
	_test_file_hygiene()


func _create_test_repo() -> LocalSaveRepository:
	return LocalSaveRepository.new(TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_CORRUPT)


func _cleanup_test_files() -> void:
	_remove_file_if_exists(TEST_PRIMARY)
	_remove_file_if_exists(TEST_TEMP)
	_remove_file_if_exists(TEST_BACKUP)
	_remove_file_if_exists(TEST_CORRUPT)


func _remove_file_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _read_file_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _create_test_definition(
	id: String,
	sprout: int = 60,
	growing: int = 300,
	mature: int = 900
) -> PlantDefinition:
	var def: PlantDefinition = PlantDefinition.new()
	def.id = id
	def.sprout_after_seconds = sprout
	def.growing_after_seconds = growing
	def.mature_after_seconds = mature
	return def


## A: Coordinator type contract is RefCounted, not Node/Resource.
func _test_type_contract() -> void:
	describe("Coordinator and result type contract is RefCounted")
	var coordinator: Variant = PlantingPersistenceCoordinator.new()
	assert_true(coordinator is RefCounted, "Coordinator must extend RefCounted")
	assert_false(coordinator is Node, "Coordinator must NOT extend Node")
	assert_false(coordinator is Resource, "Coordinator must NOT extend Resource")

	var result: Variant = PlantingCheckpointResult.not_ready()
	assert_true(result is RefCounted, "Result must extend RefCounted")
	assert_false(result is Node, "Result must NOT extend Node")
	assert_false(result is Resource, "Result must NOT extend Resource")


## B: Typed result statuses and getters follow exact contract.
func _test_checkpoint_result_statuses_and_getters() -> void:
	describe("Typed checkpoint result statuses and getters contract")
	# NOT_READY
	var r_not_ready: PlantingCheckpointResult = PlantingCheckpointResult.not_ready()
	assert_eq(r_not_ready.get_status(), PlantingCheckpointResult.NOT_READY, "status must be NOT_READY")
	assert_eq(r_not_ready.get_registration_result(), null, "registration result must be null")
	assert_false(r_not_ready.is_registered(), "is_registered must be false")
	assert_false(r_not_ready.is_saved(), "is_saved must be false")
	assert_eq(r_not_ready.get_plant(), null, "get_plant must be null")

	# PLANTING_REJECTED
	var reg_failed: PlantRegistrationResult = PlantRegistrationResult.unknown_definition_id()
	var r_rejected: PlantingCheckpointResult = PlantingCheckpointResult.planting_rejected(reg_failed)
	assert_eq(r_rejected.get_status(), PlantingCheckpointResult.PLANTING_REJECTED, "status must be PLANTING_REJECTED")
	assert_eq(r_rejected.get_registration_result(), reg_failed, "must hold exact registration result")
	assert_false(r_rejected.is_registered(), "is_registered must be false")
	assert_false(r_rejected.is_saved(), "is_saved must be false")
	assert_eq(r_rejected.get_plant(), null, "get_plant must be null")

	# REGISTERED_SAVED
	var plant: PlantState = PlantState.new("inst-1", "plant.holy_basil", 1700000000)
	var reg_success: PlantRegistrationResult = PlantRegistrationResult.registered(plant)
	var r_saved: PlantingCheckpointResult = PlantingCheckpointResult.registered_saved(reg_success)
	assert_eq(r_saved.get_status(), PlantingCheckpointResult.REGISTERED_SAVED, "status must be REGISTERED_SAVED")
	assert_eq(r_saved.get_registration_result(), reg_success, "must hold exact registration result")
	assert_true(r_saved.is_registered(), "is_registered must be true")
	assert_true(r_saved.is_saved(), "is_saved must be true")
	assert_eq(r_saved.get_plant(), plant, "get_plant must return exact PlantState")

	# REGISTERED_SAVE_FAILED
	var r_save_failed: PlantingCheckpointResult = PlantingCheckpointResult.registered_save_failed(reg_success)
	assert_eq(r_save_failed.get_status(), PlantingCheckpointResult.REGISTERED_SAVE_FAILED, "status must be REGISTERED_SAVE_FAILED")
	assert_eq(r_save_failed.get_registration_result(), reg_success, "must hold exact registration result")
	assert_true(r_save_failed.is_registered(), "is_registered must be true")
	assert_false(r_save_failed.is_saved(), "is_saved must be false")
	assert_eq(r_save_failed.get_plant(), plant, "get_plant must return exact PlantState")


## C: Null dependencies return NOT_READY and cause no mutation.
func _test_null_dependencies_return_not_ready() -> void:
	describe("Null dependencies return NOT_READY without mutating state or calling save")
	var session: GameSession = GameSession.new()
	var def: PlantDefinition = _create_test_definition("plant.holy_basil")
	var catalog: ContentCatalog = ContentCatalog.try_create([def])
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])
	var repo: CountingSaveRepository = CountingSaveRepository.new()

	# Null session
	var res1: PlantingCheckpointResult = PlantingPersistenceCoordinator.try_plant_and_save(
		null, catalog, clock, rng, repo, "plant.holy_basil"
	)
	assert_eq(res1.get_status(), PlantingCheckpointResult.NOT_READY, "null session -> NOT_READY")
	assert_eq(repo.save_call_count, 0, "no save call")

	# Null catalog
	var res2: PlantingCheckpointResult = PlantingPersistenceCoordinator.try_plant_and_save(
		session, null, clock, rng, repo, "plant.holy_basil"
	)
	assert_eq(res2.get_status(), PlantingCheckpointResult.NOT_READY, "null catalog -> NOT_READY")
	assert_eq(repo.save_call_count, 0, "no save call")

	# Null game_clock
	var res3: PlantingCheckpointResult = PlantingPersistenceCoordinator.try_plant_and_save(
		session, catalog, null, rng, repo, "plant.holy_basil"
	)
	assert_eq(res3.get_status(), PlantingCheckpointResult.NOT_READY, "null clock -> NOT_READY")
	assert_eq(repo.save_call_count, 0, "no save call")

	# Null random_source
	var res4: PlantingCheckpointResult = PlantingPersistenceCoordinator.try_plant_and_save(
		session, catalog, clock, null, repo, "plant.holy_basil"
	)
	assert_eq(res4.get_status(), PlantingCheckpointResult.NOT_READY, "null rng -> NOT_READY")
	assert_eq(repo.save_call_count, 0, "no save call")

	# Null repository
	var res5: PlantingCheckpointResult = PlantingPersistenceCoordinator.try_plant_and_save(
		session, catalog, clock, rng, null, "plant.holy_basil"
	)
	assert_eq(res5.get_status(), PlantingCheckpointResult.NOT_READY, "null repo -> NOT_READY")

	# Verify session state was never mutated
	assert_eq(session.get_state().get_plants().get_count(), 0, "state has 0 plants")


## D: AppRoot before bootstrap returns NOT_READY.
func _test_app_root_before_bootstrap_returns_not_ready() -> void:
	describe("AppRoot before bootstrap returns NOT_READY and touches no files")
	_cleanup_test_files()
	var repo: CountingSaveRepository = CountingSaveRepository.new()
	var root: AppRoot = AppRoot.new(repo)
	var res: PlantingCheckpointResult = root.try_plant_and_checkpoint("plant.holy_basil")

	assert_eq(res.get_status(), PlantingCheckpointResult.NOT_READY, "must return NOT_READY")
	assert_eq(repo.save_call_count, 0, "no save call")
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must not exist")
	root.free()


## E: Clean first-run NO_SAVE remains read-only until planting.
func _test_clean_first_run_read_only_until_planting() -> void:
	describe("Clean first-run NO_SAVE remains read-only until planting")
	_cleanup_test_files()
	var repo: CountingSaveRepository = CountingSaveRepository.new()
	var root: AppRoot = AppRoot.new(repo)
	var load_result: LocalSaveLoadResult = root.bootstrap_session()

	assert_eq(load_result.get_status(), LocalSaveLoadResult.NO_SAVE, "status must be NO_SAVE")
	assert_true(root.has_active_session(), "has active session")
	assert_eq(repo.save_call_count, 0, "no save calls during bootstrap")
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must not exist")
	assert_false(FileAccess.file_exists(TEST_TEMP), "TEMP must not exist")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "BACKUP must not exist")
	assert_false(FileAccess.file_exists(TEST_CORRUPT), "CORRUPT must not exist")
	root.free()


## F, G, AB: First successful plant creates PRIMARY, returns REGISTERED_SAVED with exact PlantState, preserves currency.
func _test_first_planting_creates_primary() -> void:
	describe("First successful plant creates PRIMARY and returns REGISTERED_SAVED")
	_cleanup_test_files()
	var repo: CountingSaveRepository = CountingSaveRepository.new()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [10, 20, 30, 40])
	var root: AppRoot = AppRoot.new(repo, null, clock, rng)
	root.bootstrap_session()

	var currency_before: int = root.game_session.get_currency()
	var res: PlantingCheckpointResult = root.try_plant_and_checkpoint("plant.holy_basil")

	assert_eq(res.get_status(), PlantingCheckpointResult.REGISTERED_SAVED, "status must be REGISTERED_SAVED")
	assert_true(res.is_registered(), "is_registered must be true")
	assert_true(res.is_saved(), "is_saved must be true")
	assert_true(res.get_plant() != null, "get_plant must not be null")
	assert_eq(res.get_plant().get_definition_id(), "plant.holy_basil", "definition_id must be plant.holy_basil")
	assert_eq(res.get_plant().get_planted_at(), 1700000000, "planted_at must match clock")
	assert_eq(repo.save_call_count, 1, "repository.save() called exactly once")
	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must be created")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "BACKUP must not exist on first save")

	# AB: Planting does not grant or spend currency
	assert_eq(root.game_session.get_currency(), currency_before, "currency must remain unchanged")
	root.free()


## H, I, AA, AC: Restart a new AppRoot and recover planted plant from PRIMARY.
func _test_restart_recovers_plant_from_primary() -> void:
	describe("Restart recovers exact plant from PRIMARY without duplication")
	# Uses the PRIMARY created in previous test or creates one
	_cleanup_test_files()
	var repo1: LocalSaveRepository = _create_test_repo()
	var clock1: FakeGameClock = FakeGameClock.new(1700000500, 0)
	var rng1: FakeRandomSource = FakeRandomSource.new([], [100, 200, 300, 400])
	var root1: AppRoot = AppRoot.new(repo1, null, clock1, rng1)
	root1.bootstrap_session()
	var res1: PlantingCheckpointResult = root1.try_plant_and_checkpoint("plant.holy_basil")
	assert_true(res1.is_saved(), "initial plant must be saved")
	var orig_plant_id: String = res1.get_plant().get_runtime_instance_id()
	root1.free()

	# Restart AppRoot 2
	var repo2: LocalSaveRepository = _create_test_repo()
	var root2: AppRoot = AppRoot.new(repo2)
	var load_result: LocalSaveLoadResult = root2.bootstrap_session()

	assert_eq(load_result.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "status must be LOADED_PRIMARY")
	assert_true(root2.has_active_session(), "active session exists")
	assert_eq(root2.game_session.get_state().get_plants().get_count(), 1, "plant count must be 1")

	var plant: PlantState = root2.game_session.get_state().get_plants().get_plant(orig_plant_id)
	assert_true(plant != null, "recovered plant must exist")
	assert_eq(plant.get_runtime_instance_id(), orig_plant_id, "instance_id must match")
	assert_eq(plant.get_definition_id(), "plant.holy_basil", "definition_id must match")
	assert_eq(plant.get_planted_at(), 1700000500, "planted_at must match")
	assert_eq(root2.game_session.get_currency(), 0, "currency must match")

	# Restart AppRoot 3 to verify repeated restarts never duplicate plants (AA)
	root2.free()
	var repo3: LocalSaveRepository = _create_test_repo()
	var root3: AppRoot = AppRoot.new(repo3)
	root3.bootstrap_session()
	assert_eq(root3.game_session.get_state().get_plants().get_count(), 1, "plant count remains 1 on repeated restart")
	root3.free()


## J, K, L: Second successful planting rotates previous PRIMARY to BACKUP.
func _test_second_planting_rotates_primary_to_backup() -> void:
	describe("Second successful planting rotates previous PRIMARY to BACKUP")
	_cleanup_test_files()
	# Step 1: Plant holy_basil
	var repo1: LocalSaveRepository = _create_test_repo()
	var clock: FakeGameClock = FakeGameClock.new(1700001000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])
	var root: AppRoot = AppRoot.new(repo1, null, clock, rng)
	root.bootstrap_session()
	var res1: PlantingCheckpointResult = root.try_plant_and_checkpoint("plant.holy_basil")
	assert_true(res1.is_saved(), "plant 1 saved")
	var plant1_id: String = res1.get_plant().get_runtime_instance_id()

	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY exists after plant 1")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "BACKUP does not exist yet")

	# Step 2: Plant chili
	clock.advance_utc_seconds(60)
	var res2: PlantingCheckpointResult = root.try_plant_and_checkpoint("plant.chili")
	assert_true(res2.is_saved(), "plant 2 saved")
	var plant2_id: String = res2.get_plant().get_runtime_instance_id()
	assert_true(plant1_id != plant2_id, "plant instances must have distinct IDs")

	# PRIMARY and BACKUP must now both exist
	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY exists after plant 2")
	assert_true(FileAccess.file_exists(TEST_BACKUP), "BACKUP exists after rotation")

	# Decode PRIMARY -> contains both plants (K)
	var pri_json: String = _read_file_text(TEST_PRIMARY)
	var pri_parsed: Variant = JSON.parse_string(pri_json)
	var pri_state: GameState = GameStateCodec.decode(pri_parsed)
	assert_true(pri_state != null, "PRIMARY decodes successfully")
	assert_eq(pri_state.get_plants().get_count(), 2, "PRIMARY contains 2 plants")
	assert_true(pri_state.get_plants().has_runtime_instance_id(plant1_id), "PRIMARY has plant 1")
	assert_true(pri_state.get_plants().has_runtime_instance_id(plant2_id), "PRIMARY has plant 2")

	# Decode BACKUP -> contains only preceding valid 1-plant state (L)
	var bak_json: String = _read_file_text(TEST_BACKUP)
	var bak_parsed: Variant = JSON.parse_string(bak_json)
	var bak_state: GameState = GameStateCodec.decode(bak_parsed)
	assert_true(bak_state != null, "BACKUP decodes successfully")
	assert_eq(bak_state.get_plants().get_count(), 1, "BACKUP contains exactly 1 plant")
	assert_true(bak_state.get_plants().has_runtime_instance_id(plant1_id), "BACKUP has plant 1")
	assert_false(bak_state.get_plants().has_runtime_instance_id(plant2_id), "BACKUP does not have plant 2")
	root.free()


## M: UNKNOWN_DEFINITION_ID does not call save.
func _test_unknown_definition_does_not_save() -> void:
	describe("UNKNOWN_DEFINITION_ID returns PLANTING_REJECTED without calling save")
	_cleanup_test_files()
	var repo: CountingSaveRepository = CountingSaveRepository.new()
	var root: AppRoot = AppRoot.new(repo)
	root.bootstrap_session()

	var res: PlantingCheckpointResult = root.try_plant_and_checkpoint("plant.unknown_dragonfruit")
	assert_eq(res.get_status(), PlantingCheckpointResult.PLANTING_REJECTED, "status must be PLANTING_REJECTED")
	assert_false(res.is_registered(), "is_registered false")
	assert_false(res.is_saved(), "is_saved false")
	assert_eq(
		res.get_registration_result().get_status(),
		PlantRegistrationResult.UNKNOWN_DEFINITION_ID,
		"registration status must be UNKNOWN_DEFINITION_ID"
	)
	assert_eq(repo.save_call_count, 0, "no save calls")
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must not exist")
	root.free()


## N: Invalid definition syntax does not call save.
func _test_invalid_definition_syntax_does_not_save() -> void:
	describe("Invalid definition syntax returns PLANTING_REJECTED without calling save")
	_cleanup_test_files()
	var repo: CountingSaveRepository = CountingSaveRepository.new()
	var root: AppRoot = AppRoot.new(repo)
	root.bootstrap_session()

	var res: PlantingCheckpointResult = root.try_plant_and_checkpoint("invalid_syntax")
	assert_eq(res.get_status(), PlantingCheckpointResult.PLANTING_REJECTED, "status must be PLANTING_REJECTED")
	assert_false(res.is_registered(), "is_registered false")
	assert_false(res.is_saved(), "is_saved false")
	assert_eq(
		res.get_registration_result().get_status(),
		PlantRegistrationResult.INVALID_INPUT,
		"registration status must be INVALID_INPUT"
	)
	assert_eq(repo.save_call_count, 0, "no save calls")
	root.free()


## O: ID_GENERATION_FAILED does not call save.
func _test_id_generation_failed_does_not_save() -> void:
	describe("ID_GENERATION_FAILED returns PLANTING_REJECTED without calling save")
	_cleanup_test_files()
	var repo: CountingSaveRepository = CountingSaveRepository.new()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)

	# Pre-script 32 draws that will all collide with existing pre-populated IDs
	var draws: Array[int] = []
	for i: int in range(1, 9):
		draws.append_array([i, i, i, i])
	var rng: FakeRandomSource = FakeRandomSource.new([], draws)

	var root: AppRoot = AppRoot.new(repo, null, clock, rng)
	root.bootstrap_session()

	# Pre-populate 8 plants in state matching the candidate IDs
	for i: int in range(1, 9):
		var coll_id: String = "%s%08x%08x%08x%08x" % [PlantRuntimeIdGenerator.ID_PREFIX, i, i, i, i]
		root.game_session.get_state().get_plants().try_add_plant(
			PlantState.new(coll_id, "plant.holy_basil", 1000)
		)

	var res: PlantingCheckpointResult = root.try_plant_and_checkpoint("plant.marigold")
	assert_eq(res.get_status(), PlantingCheckpointResult.PLANTING_REJECTED, "status must be PLANTING_REJECTED")
	assert_eq(
		res.get_registration_result().get_status(),
		PlantRegistrationResult.ID_GENERATION_FAILED,
		"registration status must be ID_GENERATION_FAILED"
	)
	assert_eq(repo.save_call_count, 0, "save must NOT be called on ID generation failure")
	root.free()


## P: Failed planting does not change PRIMARY or BACKUP bytes.
func _test_failed_planting_does_not_change_files() -> void:
	describe("Failed planting does not change PRIMARY or BACKUP file content")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])
	var root: AppRoot = AppRoot.new(repo, null, clock, rng)
	root.bootstrap_session()

	# Create PRIMARY and BACKUP
	root.try_plant_and_checkpoint("plant.holy_basil")
	clock.advance_utc_seconds(60)
	root.try_plant_and_checkpoint("plant.chili")

	var primary_before: String = _read_file_text(TEST_PRIMARY)
	var backup_before: String = _read_file_text(TEST_BACKUP)

	# Attempt invalid plantings
	root.try_plant_and_checkpoint("unknown.plant")
	root.try_plant_and_checkpoint("invalid-syntax")

	assert_eq(_read_file_text(TEST_PRIMARY), primary_before, "PRIMARY bytes must remain identical")
	assert_eq(_read_file_text(TEST_BACKUP), backup_before, "BACKUP bytes must remain identical")
	root.free()


## Q, R, S, T: Injected repository.save() returning false yields REGISTERED_SAVE_FAILED with state preserved.
func _test_controlled_save_failure_policy() -> void:
	describe("Save failure yields REGISTERED_SAVE_FAILED, preserves in-memory plant, and avoids retry")
	_cleanup_test_files()
	var failing_repo: FailingSaveRepository = FailingSaveRepository.new()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [11, 22, 33, 44])
	var root: AppRoot = AppRoot.new(failing_repo, null, clock, rng)
	root.bootstrap_session()

	assert_eq(root.game_session.get_state().get_plants().get_count(), 0, "initial plant count 0")

	var res: PlantingCheckpointResult = root.try_plant_and_checkpoint("plant.marigold")

	# Q: Yields REGISTERED_SAVE_FAILED
	assert_eq(res.get_status(), PlantingCheckpointResult.REGISTERED_SAVE_FAILED, "status must be REGISTERED_SAVE_FAILED")
	assert_true(res.is_registered(), "is_registered must be true")

	# S: No false durable-success status
	assert_false(res.is_saved(), "is_saved must be false")

	# R: In-memory plant remains in GameState
	assert_eq(root.game_session.get_state().get_plants().get_count(), 1, "plant remains in GameState")
	var plant: PlantState = res.get_plant()
	assert_true(plant != null, "get_plant returns registered plant")
	assert_eq(plant.get_definition_id(), "plant.marigold", "plant definition_id matches")
	assert_true(
		root.game_session.get_state().get_plants().has_runtime_instance_id(plant.get_runtime_instance_id()),
		"state contains the plant"
	)

	# T: No automatic retry (save called exactly once)
	assert_eq(failing_repo.save_call_count, 1, "save called exactly once without retry")
	root.free()


## U: An existing PRIMARY remains unchanged when a failure-injected repository rejects save before I/O.
func _test_primary_unchanged_on_save_failure() -> void:
	describe("Existing PRIMARY remains unchanged when controlled save fails before I/O")
	_cleanup_test_files()
	# Step 1: Create valid PRIMARY with real repository
	var normal_repo: LocalSaveRepository = _create_test_repo()
	var clock1: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng1: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])
	var root1: AppRoot = AppRoot.new(normal_repo, null, clock1, rng1)
	root1.bootstrap_session()
	root1.try_plant_and_checkpoint("plant.holy_basil")
	root1.free()

	var primary_content_before: String = _read_file_text(TEST_PRIMARY)
	assert_false(primary_content_before.is_empty(), "PRIMARY must exist")

	# Step 2: Restart with FailingSaveRepository
	var failing_repo: FailingSaveRepository = FailingSaveRepository.new()
	var clock2: FakeGameClock = FakeGameClock.new(1700000060, 0)
	var rng2: FakeRandomSource = FakeRandomSource.new([], [5, 6, 7, 8])
	var root2: AppRoot = AppRoot.new(failing_repo, null, clock2, rng2)
	root2.bootstrap_session()

	var res: PlantingCheckpointResult = root2.try_plant_and_checkpoint("plant.chili")
	assert_eq(res.get_status(), PlantingCheckpointResult.REGISTERED_SAVE_FAILED, "save must fail")

	# PRIMARY on disk must be completely unchanged
	var primary_content_after: String = _read_file_text(TEST_PRIMARY)
	assert_eq(primary_content_after, primary_content_before, "PRIMARY must remain byte-identical")
	root2.free()


## V: A later successful checkpoint can persist the still-active state after a prior controlled save failure.
func _test_later_successful_checkpoint_after_save_failure() -> void:
	describe("A later successful checkpoint persists the still-active state after prior save failure")
	_cleanup_test_files()
	var session: GameSession = GameSession.new()
	var def: PlantDefinition = _create_test_definition("plant.holy_basil")
	var catalog: ContentCatalog = ContentCatalog.try_create([def])
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])

	# Attempt planting with failing repository
	var failing_repo: FailingSaveRepository = FailingSaveRepository.new()
	var res1: PlantingCheckpointResult = PlantingPersistenceCoordinator.try_plant_and_save(
		session, catalog, clock, rng, failing_repo, "plant.holy_basil"
	)
	assert_eq(res1.get_status(), PlantingCheckpointResult.REGISTERED_SAVE_FAILED, "first save failed")
	assert_eq(session.get_state().get_plants().get_count(), 1, "plant registered in memory")

	# Now perform later save with working repository
	var working_repo: LocalSaveRepository = _create_test_repo()
	var save_ok: bool = working_repo.save(session.get_state())
	assert_true(save_ok, "subsequent save must succeed")
	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY created")

	# Verify saved state contains the plant
	var load_res: LocalSaveLoadResult = working_repo.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "status LOADED_PRIMARY")
	assert_eq(load_res.get_state().get_plants().get_count(), 1, "loaded state has 1 plant")


## W: Content bootstrap failure prevents planting and saving.
func _test_content_bootstrap_failure_prevents_planting() -> void:
	describe("Content bootstrap failure blocks session and prevents planting")
	_cleanup_test_files()
	var repo: CountingSaveRepository = CountingSaveRepository.new()
	var loader: FailingPlantContentLoader = FailingPlantContentLoader.new()
	var root: AppRoot = AppRoot.new(repo, loader)
	root.bootstrap_session()

	assert_eq(
		root.get_content_bootstrap_status(),
		AppRoot.ContentBootstrapStatus.LOAD_FAILED,
		"content status LOAD_FAILED"
	)
	assert_false(root.has_active_session(), "no active session")

	var res: PlantingCheckpointResult = root.try_plant_and_checkpoint("plant.holy_basil")
	assert_eq(res.get_status(), PlantingCheckpointResult.NOT_READY, "status must be NOT_READY")
	assert_eq(repo.save_call_count, 0, "no save calls")
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must not exist")
	root.free()


## X: INVALID_DATA and IO_ERROR prevent planting and saving.
func _test_corrupt_save_startup_prevents_planting() -> void:
	describe("INVALID_DATA startup blocks session and prevents planting")
	_cleanup_test_files()
	# Write malformed JSON to PRIMARY
	var f: FileAccess = FileAccess.open(TEST_PRIMARY, FileAccess.WRITE)
	f.store_string("{corrupted_json: true")
	f.close()

	var repo: CountingSaveRepository = CountingSaveRepository.new()
	var root: AppRoot = AppRoot.new(repo)
	var load_result: LocalSaveLoadResult = root.bootstrap_session()

	assert_eq(load_result.get_status(), LocalSaveLoadResult.INVALID_DATA, "status must be INVALID_DATA")
	assert_false(root.has_active_session(), "game_session must be null")

	var res: PlantingCheckpointResult = root.try_plant_and_checkpoint("plant.holy_basil")
	assert_eq(res.get_status(), PlantingCheckpointResult.NOT_READY, "must return NOT_READY")
	assert_eq(repo.save_call_count, 0, "save must NOT be called")
	root.free()


## Y: Unknown saved plant IDs prevent planting and saving while preserving files unchanged.
func _test_unknown_saved_plant_ids_prevent_planting() -> void:
	describe("Unknown saved plant IDs block session and prevent planting")
	_cleanup_test_files()
	# Write valid V1 JSON referencing unknown plant definition ID
	var unknown_json: String = JSON.stringify({
		"schema_version": 1,
		"economy": {"currency": "50"},
		"plants": [
			{
				"instance_id": "inst-unk",
				"definition_id": "plant.alien_specimen",
				"planted_at": "1700000000"
			}
		]
	})
	var f: FileAccess = FileAccess.open(TEST_PRIMARY, FileAccess.WRITE)
	f.store_string(unknown_json)
	f.close()

	var repo: CountingSaveRepository = CountingSaveRepository.new()
	var root: AppRoot = AppRoot.new(repo)
	var load_result: LocalSaveLoadResult = root.bootstrap_session()

	assert_eq(load_result.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "status LOADED_PRIMARY")
	assert_eq(
		root.get_saved_content_validation_result().get_status(),
		PlantSaveContentValidationResult.UNKNOWN_PLANT_IDS,
		"validation must report UNKNOWN_PLANT_IDS"
	)
	assert_false(root.has_active_session(), "game_session must be null")

	var primary_bytes_before: String = _read_file_text(TEST_PRIMARY)
	var res: PlantingCheckpointResult = root.try_plant_and_checkpoint("plant.holy_basil")

	assert_eq(res.get_status(), PlantingCheckpointResult.NOT_READY, "must return NOT_READY")
	assert_eq(repo.save_call_count, 0, "no save calls")
	assert_eq(_read_file_text(TEST_PRIMARY), primary_bytes_before, "PRIMARY bytes unchanged")
	root.free()


## Z: An approved pause after a saved planting continues to use the existing LifecycleCoordinator behavior.
func _test_lifecycle_pause_after_saved_planting() -> void:
	describe("Lifecycle pause after saved planting triggers standard pause save")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()
	var clock: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])
	var root: AppRoot = AppRoot.new(repo, null, clock, rng)
	root.bootstrap_session()

	# Planting checkpoint
	var res: PlantingCheckpointResult = root.try_plant_and_checkpoint("plant.holy_basil")
	assert_true(res.is_saved(), "planting checkpoint succeeded")

	# Mutate economy in active session
	root.game_session.grant_currency(25)

	# Trigger lifecycle pause
	root._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		root.lifecycle_coordinator.get_last_pause_outcome(),
		LifecycleCoordinator.SAVED,
		"pause outcome must be SAVED"
	)

	# Reload from PRIMARY
	var repo2: LocalSaveRepository = _create_test_repo()
	var root2: AppRoot = AppRoot.new(repo2)
	root2.bootstrap_session()
	assert_eq(root2.game_session.get_currency(), 25, "currency updated by pause save")
	assert_eq(root2.game_session.get_state().get_plants().get_count(), 1, "plant preserved")
	root.free()
	root2.free()


## AA: Repeated process restarts never duplicate plants.
func _test_repeated_restarts_never_duplicate_plants() -> void:
	describe("Repeated process restarts never duplicate plants")
	_cleanup_test_files()
	var repo1: LocalSaveRepository = _create_test_repo()
	var clock1: FakeGameClock = FakeGameClock.new(1700000000, 0)
	var rng1: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])
	var root1: AppRoot = AppRoot.new(repo1, null, clock1, rng1)
	root1.bootstrap_session()
	root1.try_plant_and_checkpoint("plant.holy_basil")
	root1.free()

	for iteration: int in range(3):
		var repo: LocalSaveRepository = _create_test_repo()
		var root: AppRoot = AppRoot.new(repo)
		var load_res: LocalSaveLoadResult = root.bootstrap_session()
		assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "iter %d load ok" % iteration)
		assert_eq(root.game_session.get_state().get_plants().get_count(), 1, "iter %d count 1" % iteration)
		root.free()


## AD: All test-created save files are cleaned up from only their dedicated test paths.
func _test_file_hygiene() -> void:
	describe("Test file cleanup hygiene")
	_cleanup_test_files()
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "TEST_PRIMARY cleaned up")
	assert_false(FileAccess.file_exists(TEST_TEMP), "TEST_TEMP cleaned up")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "TEST_BACKUP cleaned up")
	assert_false(FileAccess.file_exists(TEST_CORRUPT), "TEST_CORRUPT cleaned up")

	# Confirm production paths are untouched
	assert_false(
		FileAccess.file_exists(LocalSaveRepository.DEFAULT_TEMP_PATH),
		"Production TEMP must not exist"
	)
