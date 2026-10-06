## test_persistence_lifecycle_integration.gd
## True end-to-end integration test suite for Garden's persistence and lifecycle stack.
##
## Exercises real AppRoot, GameSession, LifecycleCoordinator, LocalSaveRepository,
## and GameStateCodec together across the real filesystem (isolated test paths under user://).
##
## Verifies:
## 1. Clean first run -> authoritative mutation -> pause checkpoint -> restart -> state reload.
## 2. Two lifecycle checkpoints creating primary and rotated backup, without duplicate pause processing.
## 3. Corrupt primary recovery to backup -> authoritative mutation -> new checkpoint -> restart.
## 4. Invalid data blocks session creation and prevents overwriting recoverable save files on pause.
## 5. Int64 wire fidelity (MAX_CURRENCY, MAX_INT64) survives the complete stack round trip.
## 6. Duplicate pause suppression affects real persisted filesystem state.
## 7. Isolated test file hygiene: leaves no integration test files behind.
class_name TestPersistenceLifecycleIntegration
extends TestSuiteBase

const TEST_PRIMARY: String = "user://__garden_test_integration_primary.json"
const TEST_TEMP: String = "user://__garden_test_integration.tmp"
const TEST_BACKUP: String = "user://__garden_test_integration.bak"
const TEST_CORRUPT: String = "user://__garden_test_integration.corrupt"


func _init() -> void:
	suite_name = "TestPersistenceLifecycleIntegration"


func setup() -> void:
	_cleanup_test_files()


func teardown() -> void:
	_cleanup_test_files()


func run_tests() -> void:
	test_clean_first_run_to_restart()
	test_two_lifecycle_checkpoints()
	test_corrupt_primary_recovery_to_new_checkpoint()
	test_invalid_data_never_becomes_empty_save()
	test_int64_fidelity_through_full_stack()
	test_duplicate_pause_across_real_filesystem()
	test_file_hygiene()


## Test A: Clean first run -> authoritative mutation -> pause checkpoint -> process restart.
func test_clean_first_run_to_restart() -> void:
	describe("Clean first run -> pause checkpoint -> restart recovers exact persisted state")
	_cleanup_test_files()

	# 1-4: Construct AppRoot A and bootstrap from clean state.
	var repo_a: LocalSaveRepository = _create_test_repo()
	var root_a: AppRoot = AppRoot.new(repo_a)
	var load_result_a: LocalSaveLoadResult = root_a.bootstrap_session()

	assert_true(load_result_a != null, "bootstrap result must not be null")
	assert_eq(load_result_a.get_status(), LocalSaveLoadResult.NO_SAVE, "status must be NO_SAVE")
	assert_true(root_a.has_active_session(), "AppRoot A must have active session")
	assert_true(root_a.game_session != null, "game_session must not be null")
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "NO_SAVE bootstrap must not create PRIMARY")
	assert_false(FileAccess.file_exists(TEST_TEMP), "NO_SAVE bootstrap must not create TEMP")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "NO_SAVE bootstrap must not create BACKUP")
	assert_false(FileAccess.file_exists(TEST_CORRUPT), "NO_SAVE bootstrap must not create CORRUPT")

	# 5: Mutate authoritative session.
	var grant_ok: bool = root_a.game_session.grant_currency(120)
	assert_true(grant_ok, "grant_currency must succeed")

	var plant_alpha: PlantState = PlantState.new("plant-inst-alpha", "plant.holy_basil", 1700000100)
	assert_true(plant_alpha.is_valid(), "PlantState must be valid")
	var add_ok: bool = root_a.game_session.get_state().get_plants().try_add_plant(plant_alpha)
	assert_true(add_ok, "adding plant to authoritative state must succeed")

	var old_session_id: int = root_a.game_session.get_instance_id()
	var old_state_id: int = root_a.game_session.get_state().get_instance_id()

	# 6: Send NOTIFICATION_APPLICATION_PAUSED.
	root_a._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		root_a.lifecycle_coordinator.get_last_pause_outcome(),
		LifecycleCoordinator.SAVED,
		"pause checkpoint outcome must be SAVED"
	)
	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY save file must be created on pause")

	# 7: Destroy AppRoot A and repository A references.
	root_a.free()
	root_a = null
	repo_a = null

	# 8-10: Construct repository B and fresh AppRoot B, then bootstrap.
	var repo_b: LocalSaveRepository = _create_test_repo()
	var root_b: AppRoot = AppRoot.new(repo_b)
	var load_result_b: LocalSaveLoadResult = root_b.bootstrap_session()

	assert_true(load_result_b != null, "bootstrap result must not be null")
	assert_eq(
		load_result_b.get_status(),
		LocalSaveLoadResult.LOADED_PRIMARY,
		"status must be LOADED_PRIMARY"
	)
	assert_true(root_b.has_active_session(), "AppRoot B must have active session")
	assert_true(root_b.game_session != null, "game_session must be non-null")
	assert_eq(root_b.game_session.get_currency(), 120, "currency must be preserved exactly")

	var plants: PlantCollectionState = root_b.game_session.get_state().get_plants()
	assert_eq(plants.get_count(), 1, "plant count must be 1")
	var loaded_plant: PlantState = plants.get_plant("plant-inst-alpha")
	assert_true(loaded_plant != null, "plant-inst-alpha must be present in reloaded state")
	assert_eq(loaded_plant.get_runtime_instance_id(), "plant-inst-alpha", "instance_id preserved")
	assert_eq(loaded_plant.get_definition_id(), "plant.holy_basil", "definition_id preserved")
	assert_eq(loaded_plant.get_planted_at(), 1700000100, "planted_at preserved")

	# Verify AppRoot B owns a new runtime GameSession/GameState reconstructed from disk.
	assert_ne(
		root_b.game_session.get_instance_id(),
		old_session_id,
		"AppRoot B must own a new GameSession instance"
	)
	assert_ne(
		root_b.game_session.get_state().get_instance_id(),
		old_state_id,
		"AppRoot B must own a new GameState instance"
	)

	root_b.free()
	_cleanup_test_files()


## Test B: Two lifecycle checkpoints produce valid PRIMARY and BACKUP rotation.
func test_two_lifecycle_checkpoints() -> void:
	describe("Two lifecycle checkpoints rotate valid PRIMARY to BACKUP without duplicate saves")
	_cleanup_test_files()

	var repo_a: LocalSaveRepository = _create_test_repo()
	var root_a: AppRoot = AppRoot.new(repo_a)
	root_a.bootstrap_session()

	# Mutate to state A.
	assert_true(root_a.game_session.grant_currency(100), "grant state A currency")
	var plant_1: PlantState = PlantState.new("plant-inst-1", "plant.holy_basil", 1700000001)
	assert_true(root_a.game_session.get_state().get_plants().try_add_plant(plant_1), "add plant 1")

	# First PAUSED checkpoint -> PRIMARY A.
	root_a._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		root_a.lifecycle_coordinator.get_last_pause_outcome(),
		LifecycleCoordinator.SAVED,
		"first pause must save"
	)
	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must exist after first pause")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "BACKUP must not exist on first save")

	# RESUMED reset gate.
	root_a._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_false(root_a.lifecycle_coordinator.is_application_paused(), "must not be paused after resume")

	# Mutate to state B.
	assert_true(root_a.game_session.grant_currency(150), "grant state B currency (total 250)")
	var plant_2: PlantState = PlantState.new("plant-inst-2", "plant.holy_basil", 1700000002)
	assert_true(root_a.game_session.get_state().get_plants().try_add_plant(plant_2), "add plant 2")

	# Second PAUSED checkpoint -> PRIMARY B, BACKUP A.
	root_a._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		root_a.lifecycle_coordinator.get_last_pause_outcome(),
		LifecycleCoordinator.SAVED,
		"second pause must save"
	)
	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must exist after second pause")
	assert_true(FileAccess.file_exists(TEST_BACKUP), "BACKUP must exist after second pause")

	# Duplicate PAUSED without RESUMED -> ignored.
	root_a._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		root_a.lifecycle_coordinator.get_last_pause_outcome(),
		LifecycleCoordinator.IGNORED_DUPLICATE_PAUSE,
		"duplicate pause must be ignored"
	)

	root_a.free()
	root_a = null

	# Fresh AppRoot B restart.
	var repo_b: LocalSaveRepository = _create_test_repo()
	var root_b: AppRoot = AppRoot.new(repo_b)
	var load_result_b: LocalSaveLoadResult = root_b.bootstrap_session()

	assert_eq(
		load_result_b.get_status(),
		LocalSaveLoadResult.LOADED_PRIMARY,
		"status must be LOADED_PRIMARY"
	)
	assert_eq(root_b.game_session.get_currency(), 250, "PRIMARY must reflect state B currency")
	assert_eq(
		root_b.game_session.get_state().get_plants().get_count(),
		2,
		"PRIMARY must reflect state B plant count"
	)

	# Verify BACKUP file contains state A.
	var backup_cand: LocalSaveRepository.CandidateReadResult = repo_b._read_and_validate(TEST_BACKUP)
	assert_true(backup_cand.is_valid(), "BACKUP must be valid decode")
	assert_eq(backup_cand.state.get_economy().get_currency(), 100, "BACKUP must reflect state A currency")
	assert_eq(backup_cand.state.get_plants().get_count(), 1, "BACKUP must reflect state A plant count")
	assert_true(
		backup_cand.state.get_plants().has_runtime_instance_id("plant-inst-1"),
		"BACKUP must contain plant-inst-1"
	)

	root_b.free()
	_cleanup_test_files()


## Test C: Corrupt primary recovery to backup -> mutate -> checkpoint -> restart.
func test_corrupt_primary_recovery_to_new_checkpoint() -> void:
	describe("Corrupt PRIMARY recovers from BACKUP, checkpoints to state C, quarantining corrupt PRIMARY")
	_cleanup_test_files()

	var repo_setup: LocalSaveRepository = _create_test_repo()

	# Create valid state A in BACKUP and valid state B in PRIMARY.
	var state_a: GameState = GameState.new()
	state_a.get_economy().grant_currency(100)
	state_a.get_plants().try_add_plant(PlantState.new("plant-a", "plant.holy_basil", 1700000001))
	assert_true(repo_setup.save(state_a), "save state A")

	var state_b: GameState = GameState.new()
	state_b.get_economy().grant_currency(200)
	state_b.get_plants().try_add_plant(PlantState.new("plant-b", "plant.holy_basil", 1700000002))
	assert_true(repo_setup.save(state_b), "save state B (rotates A to BACKUP)")

	# Corrupt PRIMARY bytes.
	var corrupt_payload: String = "{\n  \"schema_version\": 1,\n  \"corrupted\": true\n"
	_write_raw_file(TEST_PRIMARY, corrupt_payload)

	# Fresh AppRoot A startup: must recover from BACKUP (state A).
	var repo_a: LocalSaveRepository = _create_test_repo()
	var root_a: AppRoot = AppRoot.new(repo_a)
	var load_result_a: LocalSaveLoadResult = root_a.bootstrap_session()

	assert_eq(
		load_result_a.get_status(),
		LocalSaveLoadResult.LOADED_BACKUP,
		"startup must recover from BACKUP"
	)
	assert_true(root_a.has_active_session(), "must have active session from backup")
	assert_eq(root_a.game_session.get_currency(), 100, "recovered currency must be state A (100)")
	assert_eq(root_a.game_session.get_state().get_plants().get_count(), 1, "plant count must be 1")

	# Mutate recovered session to state C.
	assert_true(root_a.game_session.grant_currency(50), "grant currency (now 150)")
	var plant_c: PlantState = PlantState.new("plant-c", "plant.holy_basil", 1700000003)
	assert_true(root_a.game_session.get_state().get_plants().try_add_plant(plant_c), "add plant c")

	# Send PAUSED checkpoint.
	root_a._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		root_a.lifecycle_coordinator.get_last_pause_outcome(),
		LifecycleCoordinator.SAVED,
		"pause checkpoint must succeed"
	)

	# Verify on-disk files:
	# - PRIMARY: state C
	# - BACKUP: state A (preserved)
	# - CORRUPT: previous corrupt PRIMARY payload
	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must exist")
	assert_true(FileAccess.file_exists(TEST_BACKUP), "BACKUP must exist")
	assert_true(FileAccess.file_exists(TEST_CORRUPT), "CORRUPT must exist")

	var corrupt_text: String = _read_raw_file(TEST_CORRUPT)
	assert_eq(corrupt_text, corrupt_payload, "CORRUPT file must contain quarantined corrupted payload")

	var primary_cand: LocalSaveRepository.CandidateReadResult = repo_a._read_and_validate(TEST_PRIMARY)
	assert_true(primary_cand.is_valid(), "PRIMARY must be valid")
	assert_eq(primary_cand.state.get_economy().get_currency(), 150, "PRIMARY must have state C currency (150)")
	assert_eq(primary_cand.state.get_plants().get_count(), 2, "PRIMARY must have 2 plants")

	var backup_cand: LocalSaveRepository.CandidateReadResult = repo_a._read_and_validate(TEST_BACKUP)
	assert_true(backup_cand.is_valid(), "BACKUP must remain valid")
	assert_eq(backup_cand.state.get_economy().get_currency(), 100, "BACKUP must remain state A currency (100)")

	root_a.free()
	root_a = null

	# Fresh AppRoot B restart: must load state C from PRIMARY.
	var repo_b: LocalSaveRepository = _create_test_repo()
	var root_b: AppRoot = AppRoot.new(repo_b)
	var load_result_b: LocalSaveLoadResult = root_b.bootstrap_session()

	assert_eq(
		load_result_b.get_status(),
		LocalSaveLoadResult.LOADED_PRIMARY,
		"restart must load state C from PRIMARY"
	)
	assert_eq(root_b.game_session.get_currency(), 150, "currency must be 150")
	assert_eq(root_b.game_session.get_state().get_plants().get_count(), 2, "plants count must be 2")

	root_b.free()
	_cleanup_test_files()


## Test D: INVALID_DATA never creates empty save or overwrites corrupted files on pause.
func test_invalid_data_never_becomes_empty_save() -> void:
	describe("INVALID_DATA startup blocks session and prevents overwriting candidate files on pause")
	_cleanup_test_files()

	var corrupt_primary: String = "{\n  \"invalid\": \"primary_data\"\n}"
	var corrupt_backup: String = "{\n  \"invalid\": \"backup_data\"\n}"
	_write_raw_file(TEST_PRIMARY, corrupt_primary)
	_write_raw_file(TEST_BACKUP, corrupt_backup)

	# Bootstrap AppRoot A.
	var repo_a: LocalSaveRepository = _create_test_repo()
	var root_a: AppRoot = AppRoot.new(repo_a)
	var load_result_a: LocalSaveLoadResult = root_a.bootstrap_session()

	assert_eq(
		load_result_a.get_status(),
		LocalSaveLoadResult.INVALID_DATA,
		"status must be INVALID_DATA"
	)
	assert_eq(root_a.game_session, null, "game_session must be null")
	assert_false(root_a.has_active_session(), "has_active_session must be false")

	# Trigger pause -> resume -> pause.
	root_a._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		root_a.lifecycle_coordinator.get_last_pause_outcome(),
		LifecycleCoordinator.SKIPPED_NO_ACTIVE_SESSION,
		"pause must skip saving when session is null"
	)

	root_a._notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	root_a._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		root_a.lifecycle_coordinator.get_last_pause_outcome(),
		LifecycleCoordinator.SKIPPED_NO_ACTIVE_SESSION,
		"subsequent pause must also skip saving"
	)

	# Verify on-disk files are byte-for-byte untouched.
	assert_eq(
		_read_raw_file(TEST_PRIMARY),
		corrupt_primary,
		"PRIMARY bytes must remain untouched"
	)
	assert_eq(
		_read_raw_file(TEST_BACKUP),
		corrupt_backup,
		"BACKUP bytes must remain untouched"
	)
	assert_false(FileAccess.file_exists(TEST_TEMP), "no TEMP file must be created")

	root_a.free()
	root_a = null

	# Fresh AppRoot B restart: must still be INVALID_DATA with unchanged files.
	var repo_b: LocalSaveRepository = _create_test_repo()
	var root_b: AppRoot = AppRoot.new(repo_b)
	var load_result_b: LocalSaveLoadResult = root_b.bootstrap_session()

	assert_eq(
		load_result_b.get_status(),
		LocalSaveLoadResult.INVALID_DATA,
		"restart must still yield INVALID_DATA"
	)
	assert_eq(root_b.game_session, null, "restart session must be null")
	assert_eq(_read_raw_file(TEST_PRIMARY), corrupt_primary, "PRIMARY bytes still untouched")
	assert_eq(_read_raw_file(TEST_BACKUP), corrupt_backup, "BACKUP bytes still untouched")

	root_b.free()
	_cleanup_test_files()


## Test E: Full int64 fidelity survives the complete AppRoot -> lifecycle -> filesystem -> reload stack.
func test_int64_fidelity_through_full_stack() -> void:
	describe("Full int64 fidelity (MAX_CURRENCY, MAX_INT64) survives entire integration round trip")
	_cleanup_test_files()

	var repo_a: LocalSaveRepository = _create_test_repo()
	var root_a: AppRoot = AppRoot.new(repo_a)
	root_a.bootstrap_session()

	# Set MAX_CURRENCY and MAX_INT64 planted_at.
	var max_currency: int = EconomyState.MAX_CURRENCY # 9223372036854775807
	var max_int64: int = 9223372036854775807
	assert_true(root_a.game_session.grant_currency(max_currency), "grant max currency")

	var plant_max: PlantState = PlantState.new("plant-inst-max-int64", "plant.holy_basil", max_int64)
	assert_true(plant_max.is_valid(), "plant with max_int64 planted_at must be valid")
	assert_true(
		root_a.game_session.get_state().get_plants().try_add_plant(plant_max),
		"add plant to authoritative state"
	)

	# Save via pause checkpoint.
	root_a._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		root_a.lifecycle_coordinator.get_last_pause_outcome(),
		LifecycleCoordinator.SAVED,
		"save must succeed"
	)

	# Inspect raw JSON file to verify canonical string wire encoding.
	var raw_primary: String = _read_raw_file(TEST_PRIMARY)
	assert_true(
		raw_primary.contains("\"currency\":\"9223372036854775807\"") or raw_primary.contains("\"currency\": \"9223372036854775807\""),
		"currency must be encoded as string on the wire"
	)
	assert_true(
		raw_primary.contains("\"planted_at\":\"9223372036854775807\"") or raw_primary.contains("\"planted_at\": \"9223372036854775807\""),
		"planted_at must be encoded as string on the wire"
	)

	root_a.free()
	root_a = null

	# Fresh AppRoot B restart: reload and assert exact int64 values without tolerance.
	var repo_b: LocalSaveRepository = _create_test_repo()
	var root_b: AppRoot = AppRoot.new(repo_b)
	var load_result_b: LocalSaveLoadResult = root_b.bootstrap_session()

	assert_eq(
		load_result_b.get_status(),
		LocalSaveLoadResult.LOADED_PRIMARY,
		"reload must succeed from PRIMARY"
	)
	assert_true(root_b.has_active_session(), "must have active session")
	assert_eq(
		root_b.game_session.get_currency(),
		max_currency,
		"currency must EXACTLY equal MAX_CURRENCY (9223372036854775807)"
	)

	var reloaded_plant: PlantState = root_b.game_session.get_state().get_plants().get_plant("plant-inst-max-int64")
	assert_true(reloaded_plant != null, "plant must be retrieved")
	assert_eq(
		reloaded_plant.get_planted_at(),
		max_int64,
		"planted_at must EXACTLY equal 9223372036854775807"
	)

	root_b.free()
	_cleanup_test_files()


## Test F: Duplicate pause suppression affects real filesystem state.
func test_duplicate_pause_across_real_filesystem() -> void:
	describe("Duplicate pause suppression prevents writing in-memory mutations to disk until resume")
	_cleanup_test_files()

	var repo: LocalSaveRepository = _create_test_repo()
	var root: AppRoot = AppRoot.new(repo)
	root.bootstrap_session()

	# State A: 100 currency.
	assert_true(root.game_session.grant_currency(100), "grant 100 currency")

	# First PAUSED checkpoint -> writes state A to PRIMARY.
	root._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		root.lifecycle_coordinator.get_last_pause_outcome(),
		LifecycleCoordinator.SAVED,
		"first pause must save"
	)

	var cand_a: LocalSaveRepository.CandidateReadResult = repo._read_and_validate(TEST_PRIMARY)
	assert_true(cand_a.is_valid(), "PRIMARY must be valid")
	assert_eq(cand_a.state.get_economy().get_currency(), 100, "PRIMARY must have 100 currency")

	# Mutate in-memory state while still paused (e.g. background logic or unblocked event).
	assert_true(root.game_session.grant_currency(50), "grant 50 currency in memory (now 150)")
	assert_eq(root.game_session.get_currency(), 150, "in-memory currency is 150")

	# Send duplicate PAUSED notification without preceding RESUMED.
	root._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		root.lifecycle_coordinator.get_last_pause_outcome(),
		LifecycleCoordinator.IGNORED_DUPLICATE_PAUSE,
		"duplicate pause must be ignored"
	)

	# Verify PRIMARY on disk remains state A (100 currency), NOT 150.
	var cand_dup: LocalSaveRepository.CandidateReadResult = repo._read_and_validate(TEST_PRIMARY)
	assert_true(cand_dup.is_valid(), "PRIMARY must remain valid")
	assert_eq(
		cand_dup.state.get_economy().get_currency(),
		100,
		"PRIMARY on disk must still contain state A (100 currency)"
	)

	# Now send RESUMED, then new PAUSED.
	root._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	root._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		root.lifecycle_coordinator.get_last_pause_outcome(),
		LifecycleCoordinator.SAVED,
		"pause after resume must save state B"
	)

	# Verify on-disk PRIMARY is state B (150 currency) and BACKUP is state A (100 currency).
	var cand_b: LocalSaveRepository.CandidateReadResult = repo._read_and_validate(TEST_PRIMARY)
	assert_true(cand_b.is_valid(), "PRIMARY must be valid state B")
	assert_eq(cand_b.state.get_economy().get_currency(), 150, "PRIMARY on disk is now state B (150 currency)")

	var cand_bak: LocalSaveRepository.CandidateReadResult = repo._read_and_validate(TEST_BACKUP)
	assert_true(cand_bak.is_valid(), "BACKUP must be valid state A")
	assert_eq(cand_bak.state.get_economy().get_currency(), 100, "BACKUP on disk is state A (100 currency)")

	root.free()
	_cleanup_test_files()


## Test G: Hygiene check verifying test files are completely removed.
func test_file_hygiene() -> void:
	describe("Integration test suite leaves no temporary or save files behind")
	_cleanup_test_files()
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "TEST_PRIMARY must not exist")
	assert_false(FileAccess.file_exists(TEST_TEMP), "TEST_TEMP must not exist")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "TEST_BACKUP must not exist")
	assert_false(FileAccess.file_exists(TEST_CORRUPT), "TEST_CORRUPT must not exist")


func _create_test_repo() -> LocalSaveRepository:
	return LocalSaveRepository.new(TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_CORRUPT)


func _cleanup_test_files() -> void:
	for path: String in [TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_CORRUPT]:
		if FileAccess.file_exists(path):
			var global_path: String = ProjectSettings.globalize_path(path)
			DirAccess.remove_absolute(global_path)


func _write_raw_file(path: String, content: String) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(content)
		f.flush()
		f.close()


func _read_raw_file(path: String) -> String:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var txt: String = f.get_as_text()
	f.close()
	return txt
