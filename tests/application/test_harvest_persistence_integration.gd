## test_harvest_persistence_integration.gd
## End-to-end integration test suite for Garden's harvest persistence stack.
##
## Exercises AppRoot, GameSession, HarvestPersistenceCoordinator, PlantHarvestService,
## LocalSaveRepository, GameStateCodec (Save Schema V1), and ContentCatalog together
## across isolated test paths under user://.
class_name TestHarvestPersistenceIntegration
extends TestSuiteBase

const TEST_PRIMARY: String = "user://__garden_test_harvest_integration_primary.json"
const TEST_TEMP: String = "user://__garden_test_harvest_integration.tmp"
const TEST_BACKUP: String = "user://__garden_test_harvest_integration.bak"
const TEST_CORRUPT: String = "user://__garden_test_harvest_integration.corrupt"


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


func _init() -> void:
	suite_name = "TestHarvestPersistenceIntegration"


func setup() -> void:
	_cleanup_test_files()


func teardown() -> void:
	_cleanup_test_files()


func run_tests() -> void:
	_test_type_contract()
	_test_checkpoint_result_statuses_and_getters()
	_test_null_dependencies_return_not_ready()
	_test_app_root_preconditions_return_not_ready()
	_test_harvest_saves_v1_and_recovers_after_restart()
	_test_rejected_harvest_does_not_save_or_modify_files()
	_test_controlled_save_failure_preserves_in_memory_harvest_and_recovers_on_pause()
	_test_file_hygiene()


func _cleanup_test_files() -> void:
	for path: String in [TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_CORRUPT]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _read_file_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _test_type_contract() -> void:
	describe("HarvestPersistenceCoordinator and HarvestCheckpointResult satisfy RefCounted contract")
	var coordinator: Variant = HarvestPersistenceCoordinator.new()
	assert_true(coordinator is RefCounted, "Coordinator must extend RefCounted")
	assert_false(coordinator is Node, "Coordinator must not extend Node")
	assert_false(coordinator is Resource, "Coordinator must not extend Resource")

	var result: Variant = HarvestCheckpointResult.not_ready()
	assert_true(result is RefCounted, "Result must extend RefCounted")
	assert_false(result is Node, "Result must not extend Node")
	assert_false(result is Resource, "Result must not extend Resource")


func _test_checkpoint_result_statuses_and_getters() -> void:
	describe("HarvestCheckpointResult statuses and getters contract")
	var r_not_ready: HarvestCheckpointResult = HarvestCheckpointResult.not_ready()
	assert_eq(r_not_ready.get_status(), HarvestCheckpointResult.NOT_READY, "NOT_READY status")
	assert_eq(r_not_ready.get_harvest_result(), null, "harvest_result null on NOT_READY")
	assert_false(r_not_ready.is_harvested(), "is_harvested false")
	assert_false(r_not_ready.is_saved(), "is_saved false")
	assert_eq(r_not_ready.get_plant(), null, "get_plant null")
	assert_eq(r_not_ready.get_reward_granted(), 0, "get_reward_granted 0")

	var rejected_inner: PlantHarvestResult = PlantHarvestResult.plant_not_mature()
	var r_rejected: HarvestCheckpointResult = HarvestCheckpointResult.harvest_rejected(rejected_inner)
	assert_eq(r_rejected.get_status(), HarvestCheckpointResult.HARVEST_REJECTED, "HARVEST_REJECTED status")
	assert_eq(r_rejected.get_harvest_result(), rejected_inner, "holds exact failed PlantHarvestResult")
	assert_false(r_rejected.is_harvested(), "is_harvested false")
	assert_false(r_rejected.is_saved(), "is_saved false")
	assert_eq(r_rejected.get_plant(), null, "get_plant null")
	assert_eq(r_rejected.get_reward_granted(), 0, "get_reward_granted 0")

	var plant: PlantState = PlantState.new("inst-1", "plant.holy_basil", 1600)
	var ok_inner: PlantHarvestResult = PlantHarvestResult.harvested(plant, 5)
	var r_saved: HarvestCheckpointResult = HarvestCheckpointResult.harvested_saved(ok_inner)
	assert_eq(r_saved.get_status(), HarvestCheckpointResult.HARVESTED_SAVED, "HARVESTED_SAVED status")
	assert_eq(r_saved.get_harvest_result(), ok_inner, "holds exact PlantHarvestResult")
	assert_true(r_saved.is_harvested(), "is_harvested true")
	assert_true(r_saved.is_saved(), "is_saved true")
	assert_eq(r_saved.get_plant(), plant, "get_plant returns updated PlantState")
	assert_eq(r_saved.get_reward_granted(), 5, "get_reward_granted returns 5")

	var r_save_failed: HarvestCheckpointResult = HarvestCheckpointResult.harvested_save_failed(ok_inner)
	assert_eq(r_save_failed.get_status(), HarvestCheckpointResult.HARVESTED_SAVE_FAILED, "HARVESTED_SAVE_FAILED status")
	assert_true(r_save_failed.is_harvested(), "is_harvested true")
	assert_false(r_save_failed.is_saved(), "is_saved false")
	assert_eq(r_save_failed.get_plant(), plant, "get_plant returns updated PlantState")
	assert_eq(r_save_failed.get_reward_granted(), 5, "get_reward_granted returns 5")


func _test_null_dependencies_return_not_ready() -> void:
	describe("Null dependencies return NOT_READY without mutating state or calling save")
	var session: GameSession = GameSession.new()
	var loader: PlantContentLoader = PlantContentLoader.new()
	var catalog: ContentCatalog = ContentCatalog.try_create(loader.load_production_definitions().get_definitions())
	var clock: FakeGameClock = FakeGameClock.new(2000, 0)
	var repo: CountingSaveRepository = CountingSaveRepository.new()

	assert_eq(
		HarvestPersistenceCoordinator.try_harvest_and_save(null, catalog, clock, repo, "inst-1").get_status(),
		HarvestCheckpointResult.NOT_READY,
		"null session -> NOT_READY"
	)
	assert_eq(
		HarvestPersistenceCoordinator.try_harvest_and_save(session, null, clock, repo, "inst-1").get_status(),
		HarvestCheckpointResult.NOT_READY,
		"null catalog -> NOT_READY"
	)
	assert_eq(
		HarvestPersistenceCoordinator.try_harvest_and_save(session, catalog, null, repo, "inst-1").get_status(),
		HarvestCheckpointResult.NOT_READY,
		"null clock -> NOT_READY"
	)
	assert_eq(
		HarvestPersistenceCoordinator.try_harvest_and_save(session, catalog, clock, null, "inst-1").get_status(),
		HarvestCheckpointResult.NOT_READY,
		"null repo -> NOT_READY"
	)
	assert_eq(repo.save_call_count, 0, "no save calls")


func _test_app_root_preconditions_return_not_ready() -> void:
	describe("AppRoot before bootstrap or with blocked session returns NOT_READY")
	_cleanup_test_files()
	var repo: CountingSaveRepository = CountingSaveRepository.new()
	var root: AppRoot = AppRoot.new(repo)
	var res: HarvestCheckpointResult = root.try_harvest_and_checkpoint("inst-1")
	assert_eq(res.get_status(), HarvestCheckpointResult.NOT_READY, "unbootstrapped -> NOT_READY")
	assert_eq(repo.save_call_count, 0, "zero saves")
	root.free()


func _test_harvest_saves_v1_and_recovers_after_restart() -> void:
	describe("Harvesting mature plant saves V1 state, rotates backup, and recovers across restart")
	_cleanup_test_files()
	var repo1: CountingSaveRepository = CountingSaveRepository.new()
	var clock1: FakeGameClock = FakeGameClock.new(1000, 0)
	var rng1: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])
	var root1: AppRoot = AppRoot.new(repo1, null, clock1, rng1)
	root1.bootstrap_session()

	# Plant holy_basil at t = 1000
	var plant_res: PlantingCheckpointResult = root1.try_plant_and_checkpoint("plant.holy_basil")
	assert_true(plant_res.is_saved(), "initial plant saved to PRIMARY")
	var basil_id: String = plant_res.get_plant().get_runtime_instance_id()
	assert_eq(repo1.save_call_count, 1, "1 save after planting")

	# Advance clock to t = 1600 (+600s -> MATURE) and harvest
	clock1.advance_utc_seconds(600)
	var harv_res: HarvestCheckpointResult = root1.try_harvest_and_checkpoint(basil_id)
	assert_eq(harv_res.get_status(), HarvestCheckpointResult.HARVESTED_SAVED, "status HARVESTED_SAVED")
	assert_true(harv_res.is_harvested(), "is_harvested true")
	assert_true(harv_res.is_saved(), "is_saved true")
	assert_eq(harv_res.get_reward_granted(), 5, "granted 5 coins")
	assert_eq(root1.game_session.get_currency(), 5, "session currency is 5")
	assert_eq(harv_res.get_plant().get_planted_at(), 1600, "plant cycle reset to 1600")
	assert_eq(repo1.save_call_count, 2, "2 saves total (1 plant + 1 harvest)")
	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY exists")
	assert_true(FileAccess.file_exists(TEST_BACKUP), "BACKUP exists after rotation")

	# Verify BACKUP holds pre-harvest state (currency 0, planted_at 1000)
	var bak_state: GameState = GameStateCodec.decode(JSON.parse_string(_read_file_text(TEST_BACKUP)))
	assert_true(bak_state != null, "BACKUP decodes under V1")
	assert_eq(bak_state.get_economy().get_currency(), 0, "BACKUP currency is 0")
	assert_eq(bak_state.get_plants().get_plant(basil_id).get_planted_at(), 1000, "BACKUP planted_at is 1000")

	root1.free()

	# Restart into AppRoot 2 at t = 1650
	var repo2: CountingSaveRepository = CountingSaveRepository.new()
	var clock2: FakeGameClock = FakeGameClock.new(1650, 0)
	var root2: AppRoot = AppRoot.new(repo2, null, clock2)
	var load_res2: LocalSaveLoadResult = root2.bootstrap_session()
	assert_eq(load_res2.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "loaded from PRIMARY")
	assert_eq(root2.game_session.get_currency(), 5, "recovered currency is 5")
	assert_eq(root2.game_session.get_state().get_plants().get_count(), 1, "recovered 1 plant")
	var recovered_plant: PlantState = root2.game_session.get_state().get_plants().get_plant(basil_id)
	assert_true(recovered_plant != null, "recovered basil exists")
	assert_eq(recovered_plant.get_planted_at(), 1600, "recovered planted_at is 1600")
	root2.free()


func _test_rejected_harvest_does_not_save_or_modify_files() -> void:
	describe("Rejected harvest returns HARVEST_REJECTED without calling save or modifying files")
	_cleanup_test_files()
	var repo: CountingSaveRepository = CountingSaveRepository.new()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])
	var root: AppRoot = AppRoot.new(repo, null, clock, rng)
	root.bootstrap_session()

	var plant_res: PlantingCheckpointResult = root.try_plant_and_checkpoint("plant.holy_basil")
	var basil_id: String = plant_res.get_plant().get_runtime_instance_id()
	var primary_before: String = _read_file_text(TEST_PRIMARY)
	assert_eq(repo.save_call_count, 1, "1 save from planting")

	# Attempt harvest at t = 1200 (GROWING, not MATURE)
	clock.advance_utc_seconds(200)
	var harv_res: HarvestCheckpointResult = root.try_harvest_and_checkpoint(basil_id)
	assert_eq(harv_res.get_status(), HarvestCheckpointResult.HARVEST_REJECTED, "status HARVEST_REJECTED")
	assert_eq(
		harv_res.get_harvest_result().get_status(),
		PlantHarvestResult.PLANT_NOT_MATURE,
		"reason PLANT_NOT_MATURE"
	)
	assert_eq(repo.save_call_count, 1, "no save call on rejected harvest")
	assert_eq(_read_file_text(TEST_PRIMARY), primary_before, "PRIMARY bytes unchanged")
	root.free()


func _test_controlled_save_failure_preserves_in_memory_harvest_and_recovers_on_pause() -> void:
	describe("Save failure returns HARVESTED_SAVE_FAILED, keeps coins and reset plant in memory, and saves on later checkpoint")
	_cleanup_test_files()
	var session: GameSession = GameSession.new()
	var loader: PlantContentLoader = PlantContentLoader.new()
	var catalog: ContentCatalog = ContentCatalog.try_create(loader.load_production_definitions().get_definitions())
	var clock: FakeGameClock = FakeGameClock.new(1600, 0)
	session.try_register_plant(catalog, "basil-1", "plant.holy_basil", 1000)

	var failing_repo: FailingSaveRepository = FailingSaveRepository.new()
	var res: HarvestCheckpointResult = HarvestPersistenceCoordinator.try_harvest_and_save(
		session,
		catalog,
		clock,
		failing_repo,
		"basil-1"
	)
	assert_eq(res.get_status(), HarvestCheckpointResult.HARVESTED_SAVE_FAILED, "status HARVESTED_SAVE_FAILED")
	assert_true(res.is_harvested(), "is_harvested true")
	assert_false(res.is_saved(), "is_saved false")
	assert_eq(failing_repo.save_call_count, 1, "save attempted once")
	assert_eq(session.get_currency(), 5, "in-memory currency is 5")
	assert_eq(session.get_state().get_plants().get_plant("basil-1").get_planted_at(), 1600, "in-memory planted_at is 1600")

	# Later save with working repository persists state
	var working_repo: CountingSaveRepository = CountingSaveRepository.new()
	assert_true(working_repo.save(session.get_state()), "later save succeeds")
	var loaded: LocalSaveLoadResult = working_repo.load()
	assert_eq(loaded.get_state().get_economy().get_currency(), 5, "persisted currency 5")
	assert_eq(loaded.get_state().get_plants().get_plant("basil-1").get_planted_at(), 1600, "persisted planted_at 1600")


func _test_file_hygiene() -> void:
	describe("Test file cleanup hygiene")
	_cleanup_test_files()
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "TEST_PRIMARY cleaned up")
	assert_false(FileAccess.file_exists(TEST_TEMP), "TEST_TEMP cleaned up")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "TEST_BACKUP cleaned up")
	assert_false(FileAccess.file_exists(TEST_CORRUPT), "TEST_CORRUPT cleaned up")
