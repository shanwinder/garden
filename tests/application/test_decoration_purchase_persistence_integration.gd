## test_decoration_purchase_persistence_integration.gd
## Integration tests for DecorationPurchasePersistenceCoordinator and DecorationPurchaseCheckpointResult.
class_name TestDecorationPurchasePersistenceIntegration
extends TestSuiteBase

const TEST_PRIMARY: String = "user://__garden_test_decor_purchase_primary.json"
const TEST_TEMP: String = "user://__garden_test_decor_purchase.tmp"
const TEST_BACKUP: String = "user://__garden_test_decor_purchase.bak"
const TEST_CORRUPT: String = "user://__garden_test_decor_purchase.corrupt"


class SpySaveRepo extends LocalSaveRepository:
	var save_call_count: int = 0
	var should_fail_save: bool = false

	func _init() -> void:
		super(TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_CORRUPT)

	func save(state: GameState) -> bool:
		save_call_count += 1
		if should_fail_save:
			return false
		return super.save(state)


func _init() -> void:
	suite_name = "TestDecorationPurchasePersistenceIntegration"


func setup() -> void:
	_cleanup_test_files()


func teardown() -> void:
	_cleanup_test_files()


func _cleanup_test_files() -> void:
	for path: String in [TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_CORRUPT]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func run_tests() -> void:
	_test_purchased_saved_round_trip()
	_test_purchased_save_failed_preserves_in_memory_state()
	_test_purchase_rejected_causes_zero_saves()


func _create_catalog() -> ContentCatalog:
	var p_res: PlantContentLoadResult = PlantContentLoader.new().load_production_definitions()
	var v_res: VisitorContentLoadResult = VisitorContentLoader.new().load_production_definitions()
	var d_res: DecorationContentLoadResult = DecorationContentLoader.new().load_production_definitions()
	return ContentCatalog.try_create(
		p_res.get_definitions(),
		v_res.get_definitions(),
		d_res.get_definitions()
	)


func _test_purchased_saved_round_trip() -> void:
	describe("DecorationPurchasePersistenceCoordinator saves Schema V3 checkpoint on successful purchase")
	_cleanup_test_files()
	var repo: SpySaveRepo = SpySaveRepo.new()
	var catalog: ContentCatalog = _create_catalog()
	var session: GameSession = GameSession.new()
	session.grant_currency(60)
	var clock: FakeGameClock = FakeGameClock.new(2500, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [10, 20, 30, 40])

	var res: DecorationPurchaseCheckpointResult = DecorationPurchasePersistenceCoordinator.try_purchase_decoration_and_save(
		session, catalog, clock, rng, repo, "decoration.small_pond"
	)
	assert_eq(res.get_status(), DecorationPurchaseCheckpointResult.PURCHASED_SAVED, "Status PURCHASED_SAVED")
	assert_true(res.is_purchased(), "is_purchased true")
	assert_true(res.is_saved(), "is_saved true")
	assert_eq(res.get_price_spent(), 50, "Price spent 50")
	assert_eq(session.get_currency(), 10, "Session currency reduced to 10")
	assert_eq(repo.save_call_count, 1, "Saved exactly once")

	var loaded: LocalSaveLoadResult = repo.load()
	assert_eq(loaded.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "Reloaded from PRIMARY")
	assert_eq(loaded.get_state().get_economy().get_currency(), 10, "Reloaded currency is 10")
	assert_eq(loaded.get_state().get_decorations().get_count(), 1, "Reloaded decoration count is 1")
	_cleanup_test_files()


func _test_purchased_save_failed_preserves_in_memory_state() -> void:
	describe("Transient save failure reports PURCHASED_SAVE_FAILED while keeping decoration in memory")
	_cleanup_test_files()
	var repo: SpySaveRepo = SpySaveRepo.new()
	repo.should_fail_save = true
	var catalog: ContentCatalog = _create_catalog()
	var session: GameSession = GameSession.new()
	session.grant_currency(20)
	var clock: FakeGameClock = FakeGameClock.new(2500, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])

	var res: DecorationPurchaseCheckpointResult = DecorationPurchasePersistenceCoordinator.try_purchase_decoration_and_save(
		session, catalog, clock, rng, repo, "decoration.clay_jar"
	)
	assert_eq(res.get_status(), DecorationPurchaseCheckpointResult.PURCHASED_SAVE_FAILED, "Status PURCHASED_SAVE_FAILED")
	assert_true(res.is_purchased(), "is_purchased true")
	assert_false(res.is_saved(), "is_saved false")
	assert_eq(session.get_currency(), 5, "In-memory currency is 5")
	assert_eq(session.get_state().get_decorations().get_count(), 1, "In-memory decoration count is 1")
	_cleanup_test_files()


func _test_purchase_rejected_causes_zero_saves() -> void:
	describe("Rejected decoration purchases return PURCHASE_REJECTED and never touch SaveRepository")
	_cleanup_test_files()
	var repo: SpySaveRepo = SpySaveRepo.new()
	var catalog: ContentCatalog = _create_catalog()
	var session: GameSession = GameSession.new()
	session.grant_currency(5)
	var clock: FakeGameClock = FakeGameClock.new(2500, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])

	var res: DecorationPurchaseCheckpointResult = DecorationPurchasePersistenceCoordinator.try_purchase_decoration_and_save(
		session, catalog, clock, rng, repo, "decoration.clay_jar"
	)
	assert_eq(res.get_status(), DecorationPurchaseCheckpointResult.PURCHASE_REJECTED, "Status PURCHASE_REJECTED")
	assert_false(res.is_purchased(), "is_purchased false")
	assert_false(res.is_saved(), "is_saved false")
	assert_eq(repo.save_call_count, 0, "Zero save calls on rejected purchase")
	_cleanup_test_files()
