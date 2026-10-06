## test_local_save_repository.gd
## Comprehensive unit tests for LocalSaveRepository and LocalSaveLoadResult.
##
## Architectural rules:
## - Native GDScript headless test suite extending TestSuiteBase.
## - Tests must use isolated test-only paths under user://; never touch production save.
## - Tests all states, rotations, recovery fallbacks, stale temp, and error boundaries.
class_name TestLocalSaveRepository
extends TestSuiteBase

const TEST_PRIMARY: String = "user://__garden_test_save_primary.json"
const TEST_TEMP: String = "user://__garden_test_save.tmp"
const TEST_BACKUP: String = "user://__garden_test_save.bak"
const TEST_CORRUPT: String = "user://__garden_test_save.corrupt"
const TEST_INVALID_TEMP_DIR: String = "user://__nonexistent_dir_pers_test/test.tmp"


## Test mock to simulate atomic promotion failure and verify rollback behavior.
class RollbackSimulationRepo extends LocalSaveRepository:
	var fail_temp_to_primary: bool = false

	func _rename_file(from_path: String, to_path: String) -> Error:
		if fail_temp_to_primary and from_path == _temp_path and to_path == _primary_path:
			return FAILED
		return super._rename_file(from_path, to_path)


func _init() -> void:
	suite_name = "TestLocalSaveRepository"


func setup() -> void:
	_cleanup_test_files()


func teardown() -> void:
	_cleanup_test_files()


func run_tests() -> void:
	test_load_result_typed_contract()
	test_default_production_paths()
	test_path_injection_and_validation()
	test_save_rejects_null_state()
	test_first_save_creates_primary_without_backup()
	test_process_restart_simulation()
	test_backup_rotation_on_second_save()
	test_primary_wins_over_backup_when_both_valid()
	test_primary_corruption_recovery_malformed_json()
	test_primary_corruption_recovery_codec_invalid()
	test_missing_primary_recovery()
	test_both_invalid_returns_invalid_data()
	test_no_save_when_clean()
	test_stale_temp_ignored_on_load_when_no_save()
	test_stale_temp_ignored_on_load_when_primary_exists()
	test_stale_temp_replaced_on_new_save()
	test_corrupt_quarantine_ignored_on_load()
	test_invalid_primary_save_protection_missing_backup()
	test_invalid_primary_save_protection_invalid_backup()
	test_invalid_primary_with_valid_backup_quarantines_and_saves()
	test_invalid_primary_replaces_older_corrupt_quarantine()
	test_temp_write_failure_preserves_primary()
	test_promotion_failure_rollback_valid_primary()
	test_promotion_failure_rollback_invalid_primary()


# ── Tests ────────────────────────────────────────────────────────────────────

func test_load_result_typed_contract() -> void:
	describe("LocalSaveLoadResult typed contract")
	var state: GameState = _create_sample_state(100, 1)

	# LOADED_PRIMARY
	var res_primary: LocalSaveLoadResult = LocalSaveLoadResult.loaded_primary(state)
	assert_eq(res_primary.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "status must be LOADED_PRIMARY")
	assert_true(res_primary.is_loaded(), "is_loaded must be true for LOADED_PRIMARY")
	assert_false(res_primary.loaded_from_backup(), "loaded_from_backup must be false for LOADED_PRIMARY")
	assert_eq(res_primary.get_state(), state, "state must equal input state")

	# LOADED_BACKUP
	var res_backup: LocalSaveLoadResult = LocalSaveLoadResult.loaded_backup(state)
	assert_eq(res_backup.get_status(), LocalSaveLoadResult.LOADED_BACKUP, "status must be LOADED_BACKUP")
	assert_true(res_backup.is_loaded(), "is_loaded must be true for LOADED_BACKUP")
	assert_true(res_backup.loaded_from_backup(), "loaded_from_backup must be true for LOADED_BACKUP")
	assert_eq(res_backup.get_state(), state, "state must equal input state")

	# NO_SAVE
	var res_no_save: LocalSaveLoadResult = LocalSaveLoadResult.no_save()
	assert_eq(res_no_save.get_status(), LocalSaveLoadResult.NO_SAVE, "status must be NO_SAVE")
	assert_false(res_no_save.is_loaded(), "is_loaded must be false for NO_SAVE")
	assert_false(res_no_save.loaded_from_backup(), "loaded_from_backup must be false for NO_SAVE")
	assert_eq(res_no_save.get_state(), null, "state must be null for NO_SAVE")

	# INVALID_DATA
	var res_invalid: LocalSaveLoadResult = LocalSaveLoadResult.invalid_data()
	assert_eq(res_invalid.get_status(), LocalSaveLoadResult.INVALID_DATA, "status must be INVALID_DATA")
	assert_false(res_invalid.is_loaded(), "is_loaded must be false for INVALID_DATA")
	assert_false(res_invalid.loaded_from_backup(), "loaded_from_backup must be false for INVALID_DATA")
	assert_eq(res_invalid.get_state(), null, "state must be null for INVALID_DATA")

	# IO_ERROR
	var res_io_err: LocalSaveLoadResult = LocalSaveLoadResult.io_error()
	assert_eq(res_io_err.get_status(), LocalSaveLoadResult.IO_ERROR, "status must be IO_ERROR")
	assert_false(res_io_err.is_loaded(), "is_loaded must be false for IO_ERROR")
	assert_false(res_io_err.loaded_from_backup(), "loaded_from_backup must be false for IO_ERROR")
	assert_eq(res_io_err.get_state(), null, "state must be null for IO_ERROR")


func test_default_production_paths() -> void:
	describe("LocalSaveRepository default production paths")
	var repo: LocalSaveRepository = LocalSaveRepository.new()
	assert_eq(repo.get_primary_path(), "user://garden_save.json", "default primary path must match contract")
	assert_eq(repo.get_temp_path(), "user://garden_save.tmp", "default temp path must match contract")
	assert_eq(repo.get_backup_path(), "user://garden_save.bak", "default backup path must match contract")
	assert_eq(repo.get_corrupt_path(), "user://garden_save.corrupt", "default corrupt path must match contract")
	assert_true(repo.is_valid_configuration(), "default configuration must be valid")


func test_path_injection_and_validation() -> void:
	describe("LocalSaveRepository path injection and collision safety")
	_cleanup_test_files()

	var repo_valid: LocalSaveRepository = _create_test_repo()
	assert_true(repo_valid.is_valid_configuration(), "injected test paths must be valid")

	# Empty paths
	assert_false(LocalSaveRepository.new("", TEST_TEMP, TEST_BACKUP, TEST_CORRUPT).is_valid_configuration())
	assert_false(LocalSaveRepository.new(TEST_PRIMARY, "", TEST_BACKUP, TEST_CORRUPT).is_valid_configuration())
	assert_false(LocalSaveRepository.new(TEST_PRIMARY, TEST_TEMP, "", TEST_CORRUPT).is_valid_configuration())
	assert_false(LocalSaveRepository.new(TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, "").is_valid_configuration())

	# Path collisions
	assert_false(LocalSaveRepository.new(TEST_PRIMARY, TEST_PRIMARY, TEST_BACKUP, TEST_CORRUPT).is_valid_configuration())
	assert_false(LocalSaveRepository.new(TEST_PRIMARY, TEST_TEMP, TEST_PRIMARY, TEST_CORRUPT).is_valid_configuration())
	assert_false(LocalSaveRepository.new(TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_PRIMARY).is_valid_configuration())
	assert_false(LocalSaveRepository.new(TEST_PRIMARY, TEST_TEMP, TEST_TEMP, TEST_CORRUPT).is_valid_configuration())
	assert_false(LocalSaveRepository.new(TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_TEMP).is_valid_configuration())
	assert_false(LocalSaveRepository.new(TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_BACKUP).is_valid_configuration())

	# Globalized alias collision
	var global_primary: String = ProjectSettings.globalize_path(TEST_PRIMARY)
	assert_false(LocalSaveRepository.new(TEST_PRIMARY, global_primary, TEST_BACKUP, TEST_CORRUPT).is_valid_configuration())

	# Refuse save/load safely on invalid configuration
	var repo_invalid: LocalSaveRepository = LocalSaveRepository.new(TEST_PRIMARY, TEST_PRIMARY, TEST_BACKUP, TEST_CORRUPT)
	var state: GameState = _create_sample_state(100)
	assert_false(repo_invalid.save(state), "save must return false on invalid config")
	var load_res: LocalSaveLoadResult = repo_invalid.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.IO_ERROR, "load must return IO_ERROR on invalid config")


func test_save_rejects_null_state() -> void:
	describe("LocalSaveRepository save rejects null state")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()
	assert_false(repo.save(null), "save(null) must return false")


func test_first_save_creates_primary_without_backup() -> void:
	describe("LocalSaveRepository first save creates primary without backup")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()
	var state: GameState = _create_sample_state(150, 1)

	var ok: bool = repo.save(state)
	assert_true(ok, "first save must succeed")
	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must exist after first save")
	assert_false(FileAccess.file_exists(TEST_TEMP), "TEMP must not remain after first save")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "BACKUP must not be created on first save")
	assert_false(FileAccess.file_exists(TEST_CORRUPT), "CORRUPT must not exist")

	var load_res: LocalSaveLoadResult = repo.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "load must return LOADED_PRIMARY")
	assert_false(load_res.loaded_from_backup(), "loaded_from_backup must be false")
	assert_eq(load_res.get_state().get_economy().get_currency(), 150, "currency must match")
	assert_eq(load_res.get_state().get_plants().get_count(), 1, "plant count must match")


func test_process_restart_simulation() -> void:
	describe("LocalSaveRepository process restart simulation")
	_cleanup_test_files()

	var repo_a: LocalSaveRepository = _create_test_repo()
	var state: GameState = _create_sample_state(200, 2)
	assert_true(repo_a.save(state), "repo_a save must succeed")

	# Discard repo_a instance and create fresh repo_b instance
	repo_a = null
	var repo_b: LocalSaveRepository = _create_test_repo()

	var load_res: LocalSaveLoadResult = repo_b.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "repo_b must load PRIMARY")
	assert_eq(load_res.get_state().get_economy().get_currency(), 200, "currency must survive restart")
	assert_eq(load_res.get_state().get_plants().get_count(), 2, "plants must survive restart")


func test_backup_rotation_on_second_save() -> void:
	describe("LocalSaveRepository backup rotation on second save")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	var state_a: GameState = _create_sample_state(100, 1)
	assert_true(repo.save(state_a), "first save (state_a) must succeed")

	var state_b: GameState = _create_sample_state(500, 2)
	assert_true(repo.save(state_b), "second save (state_b) must succeed")

	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must exist")
	assert_true(FileAccess.file_exists(TEST_BACKUP), "BACKUP must exist after second save")
	assert_false(FileAccess.file_exists(TEST_TEMP), "TEMP must not remain")

	# Verify actual decoded contents of both files directly
	var primary_json: String = _read_raw_file(TEST_PRIMARY)
	var backup_json: String = _read_raw_file(TEST_BACKUP)

	var p_dict: Variant = JSON.parse_string(primary_json)
	var b_dict: Variant = JSON.parse_string(backup_json)

	var state_from_p: GameState = GameStateCodec.decode(p_dict)
	var state_from_b: GameState = GameStateCodec.decode(b_dict)

	assert_eq(state_from_p.get_economy().get_currency(), 500, "PRIMARY must contain state_b (500)")
	assert_eq(state_from_b.get_economy().get_currency(), 100, "BACKUP must contain state_a (100)")

	# Verify fresh repo loads PRIMARY (state_b)
	var repo_fresh: LocalSaveRepository = _create_test_repo()
	var load_res: LocalSaveLoadResult = repo_fresh.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "load must return LOADED_PRIMARY")
	assert_eq(load_res.get_state().get_economy().get_currency(), 500, "load must yield state_b")


func test_primary_wins_over_backup_when_both_valid() -> void:
	describe("LocalSaveRepository primary wins over backup when both valid")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	var state_a: GameState = _create_sample_state(100)
	var state_b: GameState = _create_sample_state(500)
	repo.save(state_a)
	repo.save(state_b)

	var load_res: LocalSaveLoadResult = repo.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "PRIMARY must win over BACKUP")
	assert_false(load_res.loaded_from_backup(), "loaded_from_backup must be false")
	assert_eq(load_res.get_state().get_economy().get_currency(), 500, "state_b currency must be loaded")


func test_primary_corruption_recovery_malformed_json() -> void:
	describe("LocalSaveRepository primary corruption recovery (malformed JSON)")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	var state_a: GameState = _create_sample_state(100)
	var state_b: GameState = _create_sample_state(500)
	repo.save(state_a)
	repo.save(state_b)

	# Overwrite PRIMARY with malformed JSON text
	var corrupt_bytes: String = "{ incomplete malformed json data ... [!@#$"
	_write_raw_file(TEST_PRIMARY, corrupt_bytes)

	var load_res: LocalSaveLoadResult = repo.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_BACKUP, "corrupt PRIMARY must recover from BACKUP")
	assert_true(load_res.loaded_from_backup(), "loaded_from_backup must be true")
	assert_eq(load_res.get_state().get_economy().get_currency(), 100, "BACKUP state_a (100) must be recovered")

	# Verify load() did not mutate or auto-repair PRIMARY
	var p_content: String = _read_raw_file(TEST_PRIMARY)
	assert_eq(p_content, corrupt_bytes, "PRIMARY must remain unchanged and not auto-repaired by load")


func test_primary_corruption_recovery_codec_invalid() -> void:
	describe("LocalSaveRepository primary corruption recovery (codec-invalid data)")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	var state_a: GameState = _create_sample_state(100)
	var state_b: GameState = _create_sample_state(500)
	repo.save(state_a)
	repo.save(state_b)

	# Overwrite PRIMARY with valid JSON that violates GameStateCodec V1 schema
	var invalid_schema_json: String = '{"schema_version": 999, "economy": {"currency": "500"}, "plants": []}'
	_write_raw_file(TEST_PRIMARY, invalid_schema_json)

	var load_res: LocalSaveLoadResult = repo.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_BACKUP, "codec-invalid PRIMARY must recover from BACKUP")
	assert_true(load_res.loaded_from_backup(), "loaded_from_backup must be true")
	assert_eq(load_res.get_state().get_economy().get_currency(), 100, "BACKUP state_a must be recovered")
	assert_eq(_read_raw_file(TEST_PRIMARY), invalid_schema_json, "PRIMARY must remain untouched")


func test_missing_primary_recovery() -> void:
	describe("LocalSaveRepository missing primary recovery from backup")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	var state_a: GameState = _create_sample_state(100)
	var state_b: GameState = _create_sample_state(500)
	repo.save(state_a)
	repo.save(state_b)

	# Delete PRIMARY
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PRIMARY))
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must be removed")
	assert_true(FileAccess.file_exists(TEST_BACKUP), "BACKUP must be present")

	var load_res: LocalSaveLoadResult = repo.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_BACKUP, "missing PRIMARY must recover from BACKUP")
	assert_true(load_res.loaded_from_backup(), "loaded_from_backup must be true")
	assert_eq(load_res.get_state().get_economy().get_currency(), 100, "recovered state must match state_a")


func test_both_invalid_returns_invalid_data() -> void:
	describe("LocalSaveRepository both primary and backup invalid returns INVALID_DATA")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	_write_raw_file(TEST_PRIMARY, "{ invalid primary }")
	_write_raw_file(TEST_BACKUP, "{ invalid backup }")

	var load_res: LocalSaveLoadResult = repo.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.INVALID_DATA, "both invalid must return INVALID_DATA")
	assert_false(load_res.is_loaded(), "is_loaded must be false")
	assert_eq(load_res.get_state(), null, "state must be null")


func test_no_save_when_clean() -> void:
	describe("LocalSaveRepository no save on clean storage")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	var load_res: LocalSaveLoadResult = repo.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.NO_SAVE, "clean repo must return NO_SAVE")
	assert_false(load_res.is_loaded(), "is_loaded must be false")
	assert_eq(load_res.get_state(), null, "state must be null")


func test_stale_temp_ignored_on_load_when_no_save() -> void:
	describe("LocalSaveRepository stale temp ignored on load when no save")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	var state: GameState = _create_sample_state(100)
	var valid_json: String = JSON.stringify(GameStateCodec.encode(state))
	_write_raw_file(TEST_TEMP, valid_json)

	var load_res: LocalSaveLoadResult = repo.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.NO_SAVE, "stale temp must not be loaded when primary/backup absent")
	assert_false(load_res.is_loaded(), "is_loaded must be false")


func test_stale_temp_ignored_on_load_when_primary_exists() -> void:
	describe("LocalSaveRepository stale temp ignored on load when primary exists")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	var state_a: GameState = _create_sample_state(100)
	repo.save(state_a)

	var state_temp: GameState = _create_sample_state(999)
	var temp_json: String = JSON.stringify(GameStateCodec.encode(state_temp))
	_write_raw_file(TEST_TEMP, temp_json)

	var load_res: LocalSaveLoadResult = repo.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "PRIMARY must win over stale TEMP")
	assert_eq(load_res.get_state().get_economy().get_currency(), 100, "PRIMARY currency must be loaded")


func test_stale_temp_replaced_on_new_save() -> void:
	describe("LocalSaveRepository stale temp cleaned up and replaced on new save")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	_write_raw_file(TEST_TEMP, "stale old temp data")

	var state: GameState = _create_sample_state(250)
	assert_true(repo.save(state), "save must succeed despite pre-existing stale temp")
	assert_false(FileAccess.file_exists(TEST_TEMP), "TEMP must be promoted/removed")
	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must exist")

	var load_res: LocalSaveLoadResult = repo.load()
	assert_eq(load_res.get_state().get_economy().get_currency(), 250, "PRIMARY must have saved currency")


func test_corrupt_quarantine_ignored_on_load() -> void:
	describe("LocalSaveRepository corrupt quarantine ignored on load")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	var state: GameState = _create_sample_state(500)
	var valid_json: String = JSON.stringify(GameStateCodec.encode(state))
	_write_raw_file(TEST_CORRUPT, valid_json)

	var load_res: LocalSaveLoadResult = repo.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.NO_SAVE, "corrupt file must never be loaded as save")


func test_invalid_primary_save_protection_missing_backup() -> void:
	describe("LocalSaveRepository invalid primary save protection (missing backup)")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	var corrupt_bytes: String = "{ corrupted primary with unique unrecoverable data }"
	_write_raw_file(TEST_PRIMARY, corrupt_bytes)
	assert_false(FileAccess.file_exists(TEST_BACKUP), "BACKUP must not exist")

	var new_state: GameState = _create_sample_state(777)
	var ok: bool = repo.save(new_state)
	assert_false(ok, "save must be aborted when PRIMARY is invalid and BACKUP is missing")
	assert_eq(_read_raw_file(TEST_PRIMARY), corrupt_bytes, "PRIMARY bytes must remain untouched")
	assert_false(FileAccess.file_exists(TEST_TEMP), "TEMP must be cleaned up best-effort")


func test_invalid_primary_save_protection_invalid_backup() -> void:
	describe("LocalSaveRepository invalid primary save protection (invalid backup)")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	var p_bytes: String = "{ corrupted primary }"
	var b_bytes: String = "{ corrupted backup }"
	_write_raw_file(TEST_PRIMARY, p_bytes)
	_write_raw_file(TEST_BACKUP, b_bytes)

	var new_state: GameState = _create_sample_state(777)
	var ok: bool = repo.save(new_state)
	assert_false(ok, "save must be aborted when both PRIMARY and BACKUP are invalid")
	assert_eq(_read_raw_file(TEST_PRIMARY), p_bytes, "PRIMARY bytes must remain untouched")
	assert_eq(_read_raw_file(TEST_BACKUP), b_bytes, "BACKUP bytes must remain untouched")


func test_invalid_primary_with_valid_backup_quarantines_and_saves() -> void:
	describe("LocalSaveRepository invalid primary with valid backup quarantines to corrupt and saves")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	var state_a: GameState = _create_sample_state(100)
	var state_b: GameState = _create_sample_state(500)
	repo.save(state_a)
	repo.save(state_b)

	var corrupt_primary_bytes: String = "{ corrupt primary bytes }"
	_write_raw_file(TEST_PRIMARY, corrupt_primary_bytes)

	var state_c: GameState = _create_sample_state(888)
	var ok: bool = repo.save(state_c)
	assert_true(ok, "save must succeed when BACKUP is valid")

	# PRIMARY now contains state_c
	var primary_dict: Variant = JSON.parse_string(_read_raw_file(TEST_PRIMARY))
	var decoded_primary: GameState = GameStateCodec.decode(primary_dict)
	assert_eq(decoded_primary.get_economy().get_currency(), 888, "PRIMARY must contain state_c")

	# BACKUP still contains state_a
	var backup_dict: Variant = JSON.parse_string(_read_raw_file(TEST_BACKUP))
	var decoded_backup: GameState = GameStateCodec.decode(backup_dict)
	assert_eq(decoded_backup.get_economy().get_currency(), 100, "BACKUP must be preserved unchanged")

	# CORRUPT contains former invalid primary bytes
	assert_eq(_read_raw_file(TEST_CORRUPT), corrupt_primary_bytes, "CORRUPT must contain former invalid primary bytes")

	# Load yields state_c from PRIMARY
	var load_res: LocalSaveLoadResult = repo.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "load must yield LOADED_PRIMARY")
	assert_eq(load_res.get_state().get_economy().get_currency(), 888, "state_c currency must be loaded")


func test_invalid_primary_replaces_older_corrupt_quarantine() -> void:
	describe("LocalSaveRepository invalid primary replaces older corrupt quarantine")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()

	var state_a: GameState = _create_sample_state(100)
	repo.save(state_a) # PRIMARY = 100

	# Pre-existing older corrupt file
	_write_raw_file(TEST_CORRUPT, "old corrupt bytes from earlier")

	# Rotate so BACKUP = 100
	var state_b: GameState = _create_sample_state(200)
	repo.save(state_b) # PRIMARY = 200, BACKUP = 100

	# Break PRIMARY
	var new_corrupt_bytes: String = "brand new corrupt bytes"
	_write_raw_file(TEST_PRIMARY, new_corrupt_bytes)

	var state_c: GameState = _create_sample_state(300)
	assert_true(repo.save(state_c), "save must succeed")
	assert_eq(_read_raw_file(TEST_CORRUPT), new_corrupt_bytes, "CORRUPT must be replaced by new corrupt bytes")


func test_temp_write_failure_preserves_primary() -> void:
	describe("LocalSaveRepository temp write failure preserves existing primary")
	_cleanup_test_files()
	var repo_standard: LocalSaveRepository = _create_test_repo()

	var state_a: GameState = _create_sample_state(100)
	assert_true(repo_standard.save(state_a), "first save must succeed")

	# Create repo with uncreatable temp path
	var repo_bad_temp: LocalSaveRepository = LocalSaveRepository.new(
		TEST_PRIMARY,
		TEST_INVALID_TEMP_DIR,
		TEST_BACKUP,
		TEST_CORRUPT
	)

	var state_b: GameState = _create_sample_state(500)
	var ok: bool = repo_bad_temp.save(state_b)
	assert_false(ok, "save must fail when TEMP cannot be opened/written")

	# Existing PRIMARY remains valid and unchanged
	var load_res: LocalSaveLoadResult = repo_standard.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "PRIMARY must remain valid")
	assert_eq(load_res.get_state().get_economy().get_currency(), 100, "PRIMARY currency must remain 100")


func test_promotion_failure_rollback_valid_primary() -> void:
	describe("LocalSaveRepository promotion failure rollback (valid primary)")
	_cleanup_test_files()

	var repo_sim: RollbackSimulationRepo = RollbackSimulationRepo.new(
		TEST_PRIMARY,
		TEST_TEMP,
		TEST_BACKUP,
		TEST_CORRUPT
	)

	var state_a: GameState = _create_sample_state(100)
	assert_true(repo_sim.save(state_a), "first save must succeed")

	# Simulate promotion failure during second save: PRIMARY->BACKUP succeeds, TEMP->PRIMARY fails
	repo_sim.fail_temp_to_primary = true

	var state_b: GameState = _create_sample_state(500)
	var ok: bool = repo_sim.save(state_b)
	assert_false(ok, "save must return false when promotion fails")

	# Rollback must restore state_a to PRIMARY
	var repo_fresh: LocalSaveRepository = _create_test_repo()
	var load_res: LocalSaveLoadResult = repo_fresh.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "PRIMARY must be restored by rollback")
	assert_eq(load_res.get_state().get_economy().get_currency(), 100, "PRIMARY must retain state_a (100)")


func test_promotion_failure_rollback_invalid_primary() -> void:
	describe("LocalSaveRepository promotion failure rollback (invalid primary)")
	_cleanup_test_files()

	var repo: LocalSaveRepository = _create_test_repo()
	var state_a: GameState = _create_sample_state(100)
	var state_b: GameState = _create_sample_state(500)
	repo.save(state_a)
	repo.save(state_b)

	var corrupt_bytes: String = "{ corrupt primary to preserve }"
	_write_raw_file(TEST_PRIMARY, corrupt_bytes)

	var repo_sim: RollbackSimulationRepo = RollbackSimulationRepo.new(
		TEST_PRIMARY,
		TEST_TEMP,
		TEST_BACKUP,
		TEST_CORRUPT
	)
	repo_sim.fail_temp_to_primary = true

	var state_c: GameState = _create_sample_state(888)
	var ok: bool = repo_sim.save(state_c)
	assert_false(ok, "save must fail when promotion fails")

	# Rollback must restore corrupt_bytes to PRIMARY, leaving BACKUP intact
	assert_eq(_read_raw_file(TEST_PRIMARY), corrupt_bytes, "PRIMARY must be restored to corrupt bytes by rollback")

	# BACKUP still valid and load recovers it
	var load_res: LocalSaveLoadResult = repo.load()
	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_BACKUP, "BACKUP must remain intact and loadable")
	assert_eq(load_res.get_state().get_economy().get_currency(), 100, "state_a must be recovered from BACKUP")


# ── Internal helpers ─────────────────────────────────────────────────────────

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


func _create_sample_state(currency: int, plant_count: int = 0) -> GameState:
	var state: GameState = GameState.new()
	if currency > 0:
		state.get_economy().grant_currency(currency)
	for i in range(plant_count):
		var plant: PlantState = PlantState.new("plant_inst_%d" % i, "plant.holy_basil", 1700000000 + i)
		state.get_plants().try_add_plant(plant)
	return state
