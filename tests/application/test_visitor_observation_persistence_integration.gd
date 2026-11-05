## test_visitor_observation_persistence_integration.gd
## End-to-end integration tests for VisitorObservationPersistenceCoordinator and
## VisitorObservationCheckpointResult with AppRoot, GameSession, LocalSaveRepository,
## and Save Schema V2.
class_name TestVisitorObservationPersistenceIntegration
extends TestSuiteBase

const TEST_PRIMARY: String = "user://__garden_test_visitor_obs_primary.json"
const TEST_TEMP: String = "user://__garden_test_visitor_obs.tmp"
const TEST_BACKUP: String = "user://__garden_test_visitor_obs.bak"
const TEST_CORRUPT: String = "user://__garden_test_visitor_obs.corrupt"


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


class CountingClock extends GameClock:
	var current_utc: int = 1700000000
	var read_count: int = 0

	func _init(initial_utc: int = 1700000000) -> void:
		current_utc = initial_utc

	func utc_now_seconds() -> int:
		read_count += 1
		return current_utc

	func monotonic_milliseconds() -> int:
		return 0


func _init() -> void:
	suite_name = "TestVisitorObservationPersistenceIntegration"


func setup() -> void:
	_cleanup_test_files()


func teardown() -> void:
	_cleanup_test_files()


func run_tests() -> void:
	_test_type_contracts()
	_test_null_and_unbootstrapped_preconditions()
	_test_no_eligible_visitors_performs_zero_saves_and_zero_rng_draws()
	_test_observe_visitor_records_discovery_samples_clock_once_and_persists_v2()
	_test_controlled_save_failure_preserves_in_memory_discovery()
	_test_file_hygiene()


func _cleanup_test_files() -> void:
	for path: String in [TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_CORRUPT]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _create_production_catalog() -> ContentCatalog:
	var plants: Array[PlantDefinition] = PlantContentLoader.new().load_production_definitions().get_definitions()
	var visitors: Array[VisitorDefinition] = VisitorContentLoader.new().load_production_definitions().get_definitions()
	return ContentCatalog.try_create(plants, visitors)


func _test_type_contracts() -> void:
	describe("VisitorObservationPersistenceCoordinator and VisitorObservationCheckpointResult satisfy RefCounted contract")
	var coordinator: Variant = VisitorObservationPersistenceCoordinator.new()
	assert_true(coordinator is RefCounted, "Coordinator must extend RefCounted")
	assert_false(coordinator is Node, "Coordinator must not extend Node")
	assert_false(coordinator is Resource, "Coordinator must not extend Resource")

	var result: Variant = VisitorObservationCheckpointResult.not_ready()
	assert_true(result is RefCounted, "Result must extend RefCounted")
	assert_false(result is Node, "Result must not extend Node")
	assert_false(result is Resource, "Result must not extend Resource")


func _test_null_and_unbootstrapped_preconditions() -> void:
	describe("Null dependencies or unbootstrapped AppRoot return NOT_READY without saving")
	_cleanup_test_files()
	var session: GameSession = GameSession.new()
	var catalog: ContentCatalog = _create_production_catalog()
	var clock: CountingClock = CountingClock.new(1000)
	var rng: FakeRandomSource = FakeRandomSource.new([0.1], [])
	var repo: CountingSaveRepository = CountingSaveRepository.new()

	assert_eq(
		VisitorObservationPersistenceCoordinator.try_observe_visitor_and_save(null, catalog, clock, rng, repo).get_status(),
		VisitorObservationCheckpointResult.NOT_READY,
		"Null session -> NOT_READY"
	)
	assert_eq(
		VisitorObservationPersistenceCoordinator.try_observe_visitor_and_save(session, null, clock, rng, repo).get_status(),
		VisitorObservationCheckpointResult.NOT_READY,
		"Null catalog -> NOT_READY"
	)
	assert_eq(
		VisitorObservationPersistenceCoordinator.try_observe_visitor_and_save(session, catalog, null, rng, repo).get_status(),
		VisitorObservationCheckpointResult.NOT_READY,
		"Null clock -> NOT_READY"
	)
	assert_eq(
		VisitorObservationPersistenceCoordinator.try_observe_visitor_and_save(session, catalog, clock, null, repo).get_status(),
		VisitorObservationCheckpointResult.NOT_READY,
		"Null rng -> NOT_READY"
	)
	assert_eq(
		VisitorObservationPersistenceCoordinator.try_observe_visitor_and_save(session, catalog, clock, rng, null).get_status(),
		VisitorObservationCheckpointResult.NOT_READY,
		"Null repo -> NOT_READY"
	)
	assert_eq(repo.save_call_count, 0, "Zero saves on null dependencies")

	var root_unboot: AppRoot = AppRoot.new(repo)
	var unboot_res: VisitorObservationCheckpointResult = root_unboot.try_observe_visitor_and_checkpoint()
	assert_eq(unboot_res.get_status(), VisitorObservationCheckpointResult.NOT_READY, "Unbootstrapped AppRoot -> NOT_READY")
	assert_eq(repo.save_call_count, 0, "Zero saves on unbootstrapped AppRoot")
	root_unboot.free()


func _test_no_eligible_visitors_performs_zero_saves_and_zero_rng_draws() -> void:
	describe("Empty garden returns NO_ELIGIBLE_VISITORS with zero RNG draws, zero journal mutations, and zero saves")
	_cleanup_test_files()
	var repo: CountingSaveRepository = CountingSaveRepository.new()
	var clock: CountingClock = CountingClock.new(2000)
	var rng: FakeRandomSource = FakeRandomSource.new([], [])
	var root: AppRoot = AppRoot.new(repo, null, clock, rng)
	root.bootstrap_session()

	var obs_res: VisitorObservationCheckpointResult = root.try_observe_visitor_and_checkpoint()
	assert_eq(
		obs_res.get_status(),
		VisitorObservationCheckpointResult.NO_ELIGIBLE_VISITORS,
		"Empty garden -> NO_ELIGIBLE_VISITORS"
	)
	assert_false(obs_res.is_observed(), "is_observed() false")
	assert_false(obs_res.is_saved(), "is_saved() false")
	assert_eq(root.game_session.get_state().get_journal().get_count(), 0, "Journal remains empty")
	assert_eq(repo.save_call_count, 0, "Zero saves when no visitors are eligible")
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY not created on NO_ELIGIBLE_VISITORS")
	root.free()


func _test_observe_visitor_records_discovery_samples_clock_once_and_persists_v2() -> void:
	describe("Observing eligible visitor samples clock once, records FIRST_DISCOVERY then REPEAT_SIGHTING, and persists V2 across restart")
	_cleanup_test_files()
	var repo1: CountingSaveRepository = CountingSaveRepository.new()
	var clock1: CountingClock = CountingClock.new(1000)
	var rng1: FakeRandomSource = FakeRandomSource.new([0.1, 0.1], [1, 2, 3, 4])
	var root1: AppRoot = AppRoot.new(repo1, null, clock1, rng1)
	root1.bootstrap_session()

	# Plant marigold (flower trait -> visitor.butterfly eligible)
	var plant_res: PlantingCheckpointResult = root1.try_plant_and_checkpoint("plant.marigold")
	assert_true(plant_res.is_saved(), "Marigold planted and saved")
	assert_eq(repo1.save_call_count, 1, "1 save after planting")
	assert_eq(clock1.read_count, 1, "Clock sampled once during planting")

	# First visitor observation at t = 1500
	clock1.current_utc = 1500
	var clock_reads_before: int = clock1.read_count
	var obs1: VisitorObservationCheckpointResult = root1.try_observe_visitor_and_checkpoint()
	assert_eq(clock1.read_count, clock_reads_before + 1, "GameClock sampled exactly once during visitor observation")
	assert_eq(obs1.get_status(), VisitorObservationCheckpointResult.OBSERVED_SAVED, "Status OBSERVED_SAVED")
	assert_true(obs1.is_observed(), "is_observed() true")
	assert_true(obs1.is_saved(), "is_saved() true")
	assert_true(obs1.is_first_discovery(), "First sighting is FIRST_DISCOVERY")
	assert_eq(obs1.get_selected_visitor_id(), "visitor.butterfly", "Selected visitor is visitor.butterfly")
	assert_true(obs1.get_discovery_record() != null, "DiscoveryRecord returned")
	if obs1.get_discovery_record() != null:
		assert_eq(obs1.get_discovery_record().get_first_seen_at(), 1500, "first_seen_at is 1500")
		assert_eq(obs1.get_discovery_record().get_times_seen(), 1, "times_seen is 1")
	assert_eq(repo1.save_call_count, 2, "Save called on first visitor observation")

	# Second visitor observation at t = 2200
	clock1.current_utc = 2200
	var obs2: VisitorObservationCheckpointResult = root1.try_observe_visitor_and_checkpoint()
	assert_eq(obs2.get_status(), VisitorObservationCheckpointResult.OBSERVED_SAVED, "Second observation OBSERVED_SAVED")
	assert_false(obs2.is_first_discovery(), "Second sighting is REPEAT_SIGHTING, not first discovery")
	if obs2.get_discovery_record() != null:
		assert_eq(obs2.get_discovery_record().get_first_seen_at(), 1500, "first_seen_at preserved at 1500")
		assert_eq(obs2.get_discovery_record().get_times_seen(), 2, "times_seen incremented to 2")
	assert_eq(repo1.save_call_count, 3, "Save called on repeat visitor observation")
	root1.free()

	# Restart into AppRoot 2 and verify Schema V2 recovery
	var repo2: CountingSaveRepository = CountingSaveRepository.new()
	var root2: AppRoot = AppRoot.new(repo2)
	var load_res2: LocalSaveLoadResult = root2.bootstrap_session()
	assert_eq(load_res2.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "Loaded PRIMARY on restart")
	var journal2: JournalState = root2.game_session.get_state().get_journal()
	assert_eq(journal2.get_count(), 2, "Recovered 2 discoveries (plant.marigold + visitor.butterfly)")
	assert_true(journal2.has_discovered("plant.marigold"), "plant.marigold discovered")
	assert_true(journal2.has_discovered("visitor.butterfly"), "visitor.butterfly discovered")
	var butterfly_rec: DiscoveryRecord = journal2.get_record("visitor.butterfly")
	assert_true(butterfly_rec != null, "Butterfly record recovered")
	if butterfly_rec != null:
		assert_eq(butterfly_rec.get_first_seen_at(), 1500, "Recovered butterfly first_seen_at = 1500")
		assert_eq(butterfly_rec.get_times_seen(), 2, "Recovered butterfly times_seen = 2")
	root2.free()


func _test_controlled_save_failure_preserves_in_memory_discovery() -> void:
	describe("Controlled save failure returns OBSERVED_SAVE_FAILED while keeping discovery in memory")
	_cleanup_test_files()
	var catalog: ContentCatalog = _create_production_catalog()
	var session: GameSession = GameSession.new()
	session.try_register_plant(catalog, "marigold-1", "plant.marigold", 1000)

	var clock: CountingClock = CountingClock.new(1800)
	var rng: FakeRandomSource = FakeRandomSource.new([0.1], [])
	var failing_repo: FailingSaveRepository = FailingSaveRepository.new()

	var res: VisitorObservationCheckpointResult = VisitorObservationPersistenceCoordinator.try_observe_visitor_and_save(
		session,
		catalog,
		clock,
		rng,
		failing_repo
	)
	assert_eq(res.get_status(), VisitorObservationCheckpointResult.OBSERVED_SAVE_FAILED, "Status OBSERVED_SAVE_FAILED")
	assert_true(res.is_observed(), "is_observed() true")
	assert_false(res.is_saved(), "is_saved() false")
	assert_eq(failing_repo.save_call_count, 1, "Save attempted once")
	assert_true(
		session.get_state().get_journal().has_discovered("visitor.butterfly"),
		"Discovery remains recorded in memory even when save fails"
	)


func _test_file_hygiene() -> void:
	describe("Test file cleanup hygiene")
	_cleanup_test_files()
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "TEST_PRIMARY cleaned up")
	assert_false(FileAccess.file_exists(TEST_TEMP), "TEST_TEMP cleaned up")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "TEST_BACKUP cleaned up")
	assert_false(FileAccess.file_exists(TEST_CORRUPT), "TEST_CORRUPT cleaned up")
