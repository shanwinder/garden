## test_app_root.gd
## Structural and bootstrap persistence test suite for Garden's AppRoot.
##
## Verifies:
## 1. AppRoot can be instantiated as the expected Node-based composition root.
## 2. AppRoot._init() is I/O-free and performs no disk access or premature bootstrap.
## 3. AppRoot bootstraps GameSession from LocalSaveRepository safely:
##    - NO_SAVE: creates fresh in-memory session; no disk write.
##    - LOADED_PRIMARY: creates session from exact loaded GameState reference.
##    - LOADED_BACKUP: creates session from recovered backup state; no primary repair/write.
##    - Missing PRIMARY with valid BACKUP recovers correctly without creating PRIMARY.
##    - INVALID_DATA: blocks session creation (game_session == null); prevents corrupt overwrite.
##    - IO_ERROR: blocks session creation (game_session == null); never treated as NO_SAVE.
##    - PRIMARY wins over BACKUP when both are valid.
##    - Repeated bootstrap calls are idempotent (no second load or state replacement).
##    - Separate AppRoot instances maintain isolated authoritative state.
##    - _ready() invokes the one-time bootstrap path.
## 4. Project has the expected Autoload registration: App -> res://src/application/app_root.gd.
## 5. There is currently only the intended application Autoload.
class_name TestAppRoot
extends TestSuiteBase

const TEST_PRIMARY: String = "user://__garden_test_app_root_primary.json"
const TEST_TEMP: String = "user://__garden_test_app_root.tmp"
const TEST_BACKUP: String = "user://__garden_test_app_root.bak"
const TEST_CORRUPT: String = "user://__garden_test_app_root.corrupt"


func _init() -> void:
	suite_name = "TestAppRoot"


func setup() -> void:
	_cleanup_test_files()


func teardown() -> void:
	_cleanup_test_files()


func run_tests() -> void:
	_test_instantiation()
	_test_construction_io_free()
	_test_no_save_bootstrap()
	_test_primary_startup()
	_test_backup_recovery_startup()
	_test_missing_primary_recovery()
	_test_invalid_data_blocks_session()
	_test_io_error_blocks_session()
	_test_primary_wins_over_backup()
	_test_idempotent_bootstrap()
	_test_separate_roots_do_not_share_state()
	_test_ready_integration()
	_test_autoload_registration()
	_test_no_unapproved_autoloads()


func _test_instantiation() -> void:
	describe("AppRoot instantiates as a Node-based composition root")
	var root: AppRoot = AppRoot.new()
	assert_true(root != null, "AppRoot instance should not be null")
	assert_true(root is Node, "AppRoot must extend Node")
	assert_true(root is AppRoot, "Instance must be of type AppRoot")
	assert_true(root.game_clock != null, "game_clock must not be null")
	assert_true(root.random_source != null, "random_source must not be null")
	assert_true(root.save_repository != null, "save_repository must not be null")
	assert_eq(root.game_session, null, "game_session must be null before bootstrap")
	assert_false(root.is_session_bootstrapped(), "is_session_bootstrapped must be false before bootstrap")
	assert_false(root.has_active_session(), "has_active_session must be false before bootstrap")
	assert_eq(root.get_startup_load_result(), null, "get_startup_load_result must be null before bootstrap")
	root.free()


func _test_construction_io_free() -> void:
	describe("AppRoot construction performs no I/O and creates no save files")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()
	var root: AppRoot = AppRoot.new(repo)
	assert_eq(root.game_session, null, "game_session must be null upon construction")
	assert_false(root.is_session_bootstrapped(), "is_session_bootstrapped must be false")
	assert_false(root.has_active_session(), "has_active_session must be false")
	assert_eq(root.get_startup_load_result(), null, "startup load result must be null")
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "construction must not create PRIMARY")
	assert_false(FileAccess.file_exists(TEST_TEMP), "construction must not create TEMP")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "construction must not create BACKUP")
	assert_false(FileAccess.file_exists(TEST_CORRUPT), "construction must not create CORRUPT")
	root.free()


func _test_no_save_bootstrap() -> void:
	describe("Bootstrap with NO_SAVE creates fresh in-memory session without writing files")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()
	var root: AppRoot = AppRoot.new(repo)
	var result: LocalSaveLoadResult = root.bootstrap_session()

	assert_true(result != null, "bootstrap result must not be null")
	assert_eq(result.get_status(), LocalSaveLoadResult.NO_SAVE, "status must be NO_SAVE")
	assert_true(root.is_session_bootstrapped(), "session must be marked bootstrapped")
	assert_true(root.has_active_session(), "has_active_session must be true")
	assert_true(root.game_session != null, "game_session must be non-null")
	assert_eq(root.game_session.get_currency(), 0, "fresh session currency must be 0")
	assert_eq(root.game_session.get_state().get_plants().get_count(), 0, "fresh session plant count must be 0")
	assert_eq(root.get_startup_load_result(), result, "get_startup_load_result must return bootstrap result")

	assert_false(FileAccess.file_exists(TEST_PRIMARY), "NO_SAVE bootstrap must not create PRIMARY")
	assert_false(FileAccess.file_exists(TEST_TEMP), "NO_SAVE bootstrap must not create TEMP")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "NO_SAVE bootstrap must not create BACKUP")
	assert_false(FileAccess.file_exists(TEST_CORRUPT), "NO_SAVE bootstrap must not create CORRUPT")
	root.free()


func _test_primary_startup() -> void:
	describe("Bootstrap with valid PRIMARY loads exact GameState object reference")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()
	var initial_state: GameState = _create_sample_state(150, 2)
	assert_true(repo.save(initial_state), "setup save must succeed")

	var root: AppRoot = AppRoot.new(_create_test_repo())
	var result: LocalSaveLoadResult = root.bootstrap_session()

	assert_eq(result.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "status must be LOADED_PRIMARY")
	assert_true(root.has_active_session(), "has_active_session must be true")
	assert_true(root.game_session != null, "game_session must not be null")
	assert_eq(root.game_session.get_currency(), 150, "currency must match persisted state")
	assert_eq(root.game_session.get_state().get_plants().get_count(), 2, "plant count must match persisted state")
	assert_eq(
		root.game_session.get_state(),
		result.get_state(),
		"GameSession.get_state() must be the exact GameState instance from load result"
	)
	root.free()


func _test_backup_recovery_startup() -> void:
	describe("Bootstrap with corrupt PRIMARY recovers from BACKUP without repairing disk")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()
	var state_a: GameState = _create_sample_state(100, 1)
	var state_b: GameState = _create_sample_state(200, 2)

	assert_true(repo.save(state_a), "first save must succeed")
	assert_true(repo.save(state_b), "second save must succeed (rotates state_a to BACKUP)")

	# Corrupt PRIMARY.
	var corrupt_bytes: String = "{invalid json content for primary}"
	_write_raw_file(TEST_PRIMARY, corrupt_bytes)
	var backup_bytes: String = _read_raw_file(TEST_BACKUP)

	var root: AppRoot = AppRoot.new(_create_test_repo())
	var result: LocalSaveLoadResult = root.bootstrap_session()

	assert_eq(result.get_status(), LocalSaveLoadResult.LOADED_BACKUP, "status must be LOADED_BACKUP")
	assert_true(root.has_active_session(), "has_active_session must be true")
	assert_true(root.game_session != null, "game_session must be created from backup")
	assert_eq(root.game_session.get_currency(), 100, "session must contain recovered state_a currency")
	assert_eq(root.game_session.get_state().get_plants().get_count(), 1, "session must contain recovered state_a plants")
	assert_eq(root.game_session.get_state(), result.get_state(), "session must use exact state from backup result")

	# Verify disk files remain untouched (read-only bootstrap, no repair).
	assert_eq(_read_raw_file(TEST_PRIMARY), corrupt_bytes, "corrupt PRIMARY bytes must remain unchanged")
	assert_eq(_read_raw_file(TEST_BACKUP), backup_bytes, "BACKUP bytes must remain unchanged")
	assert_false(FileAccess.file_exists(TEST_TEMP), "no TEMP file should exist after bootstrap")
	root.free()


func _test_missing_primary_recovery() -> void:
	describe("Bootstrap with missing PRIMARY recovers from valid BACKUP without creating PRIMARY")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()
	var state_a: GameState = _create_sample_state(75, 1)
	var state_b: GameState = _create_sample_state(150, 2)

	assert_true(repo.save(state_a), "first save must succeed")
	assert_true(repo.save(state_b), "second save must succeed")

	# Remove PRIMARY so only BACKUP remains.
	var rem_err: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PRIMARY))
	assert_eq(rem_err, OK, "removal of PRIMARY must succeed")
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must not exist")
	assert_true(FileAccess.file_exists(TEST_BACKUP), "BACKUP must exist")

	var root: AppRoot = AppRoot.new(_create_test_repo())
	var result: LocalSaveLoadResult = root.bootstrap_session()

	assert_eq(result.get_status(), LocalSaveLoadResult.LOADED_BACKUP, "status must be LOADED_BACKUP")
	assert_true(root.has_active_session(), "has_active_session must be true")
	assert_true(root.game_session != null, "game_session must be created")
	assert_eq(root.game_session.get_currency(), 75, "currency must match recovered state")
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY must not be created during bootstrap")
	root.free()


func _test_invalid_data_blocks_session() -> void:
	describe("INVALID_DATA blocks session creation to prevent overwriting recoverable data")
	_cleanup_test_files()
	_write_raw_file(TEST_PRIMARY, "{\"malformed\": true, invalid")
	_write_raw_file(TEST_BACKUP, "{\"not\": \"valid save\"}")

	var pri_bytes: String = _read_raw_file(TEST_PRIMARY)
	var bak_bytes: String = _read_raw_file(TEST_BACKUP)

	var root: AppRoot = AppRoot.new(_create_test_repo())
	var result: LocalSaveLoadResult = root.bootstrap_session()

	assert_eq(result.get_status(), LocalSaveLoadResult.INVALID_DATA, "status must be INVALID_DATA")
	assert_eq(root.game_session, null, "game_session MUST remain null on INVALID_DATA")
	assert_false(root.has_active_session(), "has_active_session must be false on INVALID_DATA")
	assert_true(root.is_session_bootstrapped(), "is_session_bootstrapped must be true")
	assert_eq(root.get_startup_load_result(), result, "get_startup_load_result must preserve result")

	# Anti-data-loss verification: input files untouched, no temp or corrupt created.
	assert_eq(_read_raw_file(TEST_PRIMARY), pri_bytes, "PRIMARY bytes must remain untouched")
	assert_eq(_read_raw_file(TEST_BACKUP), bak_bytes, "BACKUP bytes must remain untouched")
	assert_false(FileAccess.file_exists(TEST_TEMP), "no TEMP file must be created")
	assert_false(FileAccess.file_exists(TEST_CORRUPT), "no CORRUPT quarantine file must be created by bootstrap")
	root.free()


func _test_io_error_blocks_session() -> void:
	describe("IO_ERROR blocks session creation and is not treated as NO_SAVE")
	var invalid_repo: LocalSaveRepository = LocalSaveRepository.new("", "", "", "")
	var root: AppRoot = AppRoot.new(invalid_repo)
	var result: LocalSaveLoadResult = root.bootstrap_session()

	assert_eq(result.get_status(), LocalSaveLoadResult.IO_ERROR, "status must be IO_ERROR")
	assert_eq(root.game_session, null, "game_session MUST remain null on IO_ERROR")
	assert_false(root.has_active_session(), "has_active_session must be false on IO_ERROR")
	assert_true(root.is_session_bootstrapped(), "is_session_bootstrapped must be true")
	assert_eq(root.get_startup_load_result(), result, "get_startup_load_result must preserve result")
	root.free()


func _test_primary_wins_over_backup() -> void:
	describe("PRIMARY takes precedence over BACKUP when both are valid")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()
	var state_a: GameState = _create_sample_state(100, 1)
	var state_b: GameState = _create_sample_state(250, 3)

	assert_true(repo.save(state_a), "first save must succeed")
	assert_true(repo.save(state_b), "second save must succeed (PRIMARY=state_b, BACKUP=state_a)")

	var root: AppRoot = AppRoot.new(_create_test_repo())
	var result: LocalSaveLoadResult = root.bootstrap_session()

	assert_eq(result.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "PRIMARY must be loaded when valid")
	assert_eq(root.game_session.get_currency(), 250, "session currency must be state_b (250)")
	assert_eq(root.game_session.get_state().get_plants().get_count(), 3, "session plant count must be state_b (3)")
	root.free()


func _test_idempotent_bootstrap() -> void:
	describe("bootstrap_session() is idempotent and does not reload disk or replace session")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()
	var state_a: GameState = _create_sample_state(100, 1)
	assert_true(repo.save(state_a), "initial save must succeed")

	var root: AppRoot = AppRoot.new(repo)
	var res1: LocalSaveLoadResult = root.bootstrap_session()
	var sess1: GameSession = root.game_session
	var state1: GameState = sess1.get_state()

	# Alter disk state after first bootstrap.
	var state_b: GameState = _create_sample_state(999, 5)
	assert_true(repo.save(state_b), "disk save to state_b must succeed")

	# Second bootstrap call on the same AppRoot.
	var res2: LocalSaveLoadResult = root.bootstrap_session()

	assert_eq(res1, res2, "repeated bootstrap must return identical result instance")
	assert_eq(root.game_session, sess1, "repeated bootstrap must preserve identical GameSession instance")
	assert_eq(root.game_session.get_state(), state1, "repeated bootstrap must preserve identical GameState instance")
	assert_eq(root.game_session.get_currency(), 100, "session state must remain state_a (100) not reloaded state_b")
	root.free()


func _test_separate_roots_do_not_share_state() -> void:
	describe("Separate AppRoot instances do not share GameSession, GameState, or startup result")
	_cleanup_test_files()
	var repo_a: LocalSaveRepository = _create_test_repo()
	var state: GameState = _create_sample_state(50, 1)
	assert_true(repo_a.save(state), "save must succeed")

	var root_a: AppRoot = AppRoot.new(repo_a)
	var root_b: AppRoot = AppRoot.new(_create_test_repo())

	root_a.bootstrap_session()
	root_b.bootstrap_session()

	assert_ne(root_a.game_session, root_b.game_session, "Separate AppRoot instances must not share GameSession")
	assert_ne(
		root_a.game_session.get_state(),
		root_b.game_session.get_state(),
		"Separate AppRoot instances must not share GameState"
	)
	assert_ne(
		root_a.get_startup_load_result(),
		root_b.get_startup_load_result(),
		"Separate AppRoot instances must not share startup result"
	)
	assert_ne(root_a.save_repository, root_b.save_repository, "Separate AppRoot instances have distinct repositories")
	root_a.free()
	root_b.free()


func _test_ready_integration() -> void:
	describe("AppRoot._ready() invokes bootstrap_session() exactly once")
	_cleanup_test_files()
	var repo: LocalSaveRepository = _create_test_repo()
	var initial_state: GameState = _create_sample_state(120, 1)
	assert_true(repo.save(initial_state), "save must succeed")

	var root: AppRoot = AppRoot.new(repo)
	assert_false(root.is_session_bootstrapped(), "must not be bootstrapped before _ready")
	assert_eq(root.game_session, null, "game_session must be null before _ready")

	root._ready()

	assert_true(root.is_session_bootstrapped(), "must be bootstrapped after _ready")
	assert_true(root.has_active_session(), "has_active_session must be true after _ready")
	assert_true(root.game_session != null, "game_session must be non-null after _ready")
	assert_eq(root.game_session.get_currency(), 120, "currency must match persisted state after _ready")
	root.free()


func _test_autoload_registration() -> void:
	describe("Project registers App autoload pointing to res://src/application/app_root.gd")
	assert_true(
		ProjectSettings.has_setting("autoload/App"),
		"ProjectSettings must have 'autoload/App'"
	)
	var setting_value: String = str(ProjectSettings.get_setting("autoload/App"))
	# Godot 4 prefixes autoload paths with '*' when registered as a global singleton.
	var clean_path: String = setting_value.trim_prefix("*")
	assert_eq(
		clean_path,
		"res://src/application/app_root.gd",
		"Autoload 'App' must point to res://src/application/app_root.gd"
	)
	assert_true(
		setting_value.begins_with("*"),
		"Autoload 'App' must be configured as a singleton ('*' prefix)"
	)


func _test_no_unapproved_autoloads() -> void:
	describe("Project has only the single approved application Autoload")
	var autoload_names: Array[String] = []
	for prop: Dictionary in ProjectSettings.get_property_list():
		var prop_name: String = prop.get("name", "")
		if prop_name.begins_with("autoload/"):
			autoload_names.append(prop_name.trim_prefix("autoload/"))

	assert_eq(autoload_names.size(), 1, "There should be exactly 1 autoload configured")
	assert_true("App" in autoload_names, "The configured autoload must be 'App'")


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
		var plant: PlantState = PlantState.new("plant_%d" % i, "plant.holy_basil", 1700000000 + i)
		state.get_plants().try_add_plant(plant)
	return state
