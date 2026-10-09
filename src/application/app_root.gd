## app_root.gd
## Single application-level composition root for Garden.
##
## AppRoot is the single composition root for long-lived application and
## infrastructure services. It explicitly constructs one SystemGameClock,
## one GodotRandomSource, one LocalSaveRepository, and one PlantContentLoader,
## exposing each as a typed dependency.
##
## It bootstraps the production ContentCatalog and the active GameSession during startup
## (_ready). Startup follows strict dependency ordering:
##   1. PlantContentLoader loads the authored production plant manifest.
##   2. ContentCatalog validates definitions and guarantees production completeness.
##   3. Only if content loading and catalog validation succeed (READY), LocalSaveRepository loads state.
##   4. GameSession is constructed according to persistence status.
##
## This ensures corruption safety and protects against gameplay starting with an
## incomplete or invalid production catalog.
##
## Composition:
##   AppRoot
##   ├── game_clock:            GameClock            -> SystemGameClock
##   ├── random_source:         RandomSource         -> GodotRandomSource
##   ├── save_repository:       LocalSaveRepository  -> LocalSaveRepository
##   ├── plant_content_loader:  PlantContentLoader   -> PlantContentLoader
##   ├── lifecycle_coordinator: LifecycleCoordinator -> LifecycleCoordinator
##   ├── content_catalog:       ContentCatalog       -> ContentCatalog (null until bootstrapped)
##   └── game_session:          GameSession          -> owns GameState (null until bootstrapped)
##
## Dependency direction:
##   AppRoot constructs infrastructure services and the active game session.
##   Application/domain code receives values from those services as arguments
##   rather than reading App.game_clock or App.random_source directly.
##
## Autoload rule:
##   Only one Autoload exists in this project: App -> res://src/application/app_root.gd.
##   GameClock, SystemGameClock, FakeGameClock, GodotRandomSource, FakeRandomSource,
##   LocalSaveRepository, PlantContentLoader, ContentCatalog, LifecycleCoordinator,
##   GameSession, and GameState must not become Autoloads.
class_name AppRoot
extends Node

## Typed status contract for ContentCatalog startup bootstrap.
enum ContentBootstrapStatus {
	NOT_ATTEMPTED,
	READY,
	LOAD_FAILED,
	INVALID_DEFINITIONS,
}

const CONTENT_STATUS_NOT_ATTEMPTED: ContentBootstrapStatus = ContentBootstrapStatus.NOT_ATTEMPTED
const CONTENT_STATUS_READY: ContentBootstrapStatus = ContentBootstrapStatus.READY
const CONTENT_STATUS_LOAD_FAILED: ContentBootstrapStatus = ContentBootstrapStatus.LOAD_FAILED
const CONTENT_STATUS_INVALID_DEFINITIONS: ContentBootstrapStatus = ContentBootstrapStatus.INVALID_DEFINITIONS

## Exact five approved production plant definitions expected in the production catalog.
const EXPECTED_PRODUCTION_PLANT_IDS: Array[String] = [
	"plant.banana",
	"plant.chili",
	"plant.holy_basil",
	"plant.jasmine",
	"plant.marigold",
]

## The production clock for this application session.
## Constructed once at composition time; never replaced at runtime.
## Tests that require deterministic time should use FakeGameClock injected
## directly into the unit under test rather than replacing this value.
var game_clock: GameClock

## The production random source for this application session.
## Constructed once at composition time; never replaced at runtime.
## Tests that require deterministic randomness should use FakeRandomSource
## injected directly into the unit under test rather than replacing this value.
var random_source: RandomSource

## The persistence repository for local state storage.
## Constructed once at composition time or injected during testing.
var save_repository: LocalSaveRepository

## The loader adapter for authored plant definition resources.
## Constructed once at composition time or injected during testing.
var plant_content_loader: PlantContentLoader

## The coordinator for mobile pause/resume persistence checkpoints.
## Constructed once at composition time using save_repository; never replaced at runtime.
var lifecycle_coordinator: LifecycleCoordinator

## The validated in-memory catalog of production plant definitions.
## Constructed during startup bootstrap; null prior to bootstrap or if
## content bootstrap encountered an error.
var content_catalog: ContentCatalog = null

## The active gameplay session for this application instance.
## Constructed during startup bootstrap; null prior to bootstrap or if
## bootstrap encountered an error (INVALID_DATA, IO_ERROR, LOAD_FAILED, or INVALID_DEFINITIONS).
## GameSession owns the canonical GameState.
var game_session: GameSession

## Tracks whether bootstrap_session() has been executed.
var _is_bootstrapped: bool = false

## Retains the outcome of the content bootstrap operation.
var _content_bootstrap_status: ContentBootstrapStatus = ContentBootstrapStatus.NOT_ATTEMPTED

## Retains the diagnostic result of the plant content loader operation.
var _content_load_result: PlantContentLoadResult = null

## Retains the outcome of the startup load operation.
var _startup_load_result: LocalSaveLoadResult = null

## Retains the outcome of validating saved plant references against the content catalog.
var _saved_content_validation_result: PlantSaveContentValidationResult = null


func _init(
	save_repository_override: LocalSaveRepository = null,
	plant_content_loader_override: PlantContentLoader = null,
	game_clock_override: GameClock = null,
	random_source_override: RandomSource = null
) -> void:
	if game_clock_override != null:
		game_clock = game_clock_override
	else:
		game_clock = SystemGameClock.new()

	if random_source_override != null:
		random_source = random_source_override
	else:
		random_source = GodotRandomSource.new()

	if save_repository_override != null:
		save_repository = save_repository_override
	else:
		save_repository = LocalSaveRepository.new()
	if plant_content_loader_override != null:
		plant_content_loader = plant_content_loader_override
	else:
		plant_content_loader = PlantContentLoader.new()
	lifecycle_coordinator = LifecycleCoordinator.new(save_repository)
	content_catalog = null
	game_session = null
	_is_bootstrapped = false
	_content_bootstrap_status = ContentBootstrapStatus.NOT_ATTEMPTED
	_content_load_result = null
	_startup_load_result = null
	_saved_content_validation_result = null


func _ready() -> void:
	bootstrap_session()


## Centralized Godot lifecycle notification handler.
##
## Routes mobile pause and resume notifications to lifecycle_coordinator.
## Safely ignores early construction-time notifications if coordinator is null.
## Focus events (FOCUS_IN, FOCUS_OUT) are intentionally not handled here as
## they are not persistence checkpoint boundaries.
func _notification(what: int) -> void:
	if lifecycle_coordinator == null:
		return

	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			lifecycle_coordinator.on_application_paused(game_session)
		NOTIFICATION_APPLICATION_RESUMED:
			lifecycle_coordinator.on_application_resumed()


## One-time bootstrap of the production ContentCatalog and active GameSession.
##
## Startup order:
## 1. Load production plant definitions via plant_content_loader.
## 2. Construct and validate in-memory ContentCatalog.
## 3. Only if content is READY, load persistent GameState via save_repository.
## 4. Construct active GameSession according to save load status.
##
## Idempotent: repeated calls do nothing and return the existing load result.
## Read-only: never calls repository.save() or modifies files on disk.
##
## Returns the LocalSaveLoadResult if persistence was attempted, or null if content bootstrap failed.
func bootstrap_session() -> LocalSaveLoadResult:
	if _is_bootstrapped:
		return _startup_load_result

	_is_bootstrapped = true

	# Step 1: Attempt production content loading.
	_content_load_result = plant_content_loader.load_production_definitions()
	if not _content_load_result.is_loaded():
		_content_bootstrap_status = ContentBootstrapStatus.LOAD_FAILED
		content_catalog = null
		game_session = null
		_startup_load_result = null
		return null

	# Step 2: Construct and validate ContentCatalog with completeness guarantee.
	var definitions: Array[PlantDefinition] = _content_load_result.get_definitions()
	var catalog: ContentCatalog = ContentCatalog.try_create(definitions)
	if catalog == null or catalog.get_plant_count() != EXPECTED_PRODUCTION_PLANT_IDS.size():
		_content_bootstrap_status = ContentBootstrapStatus.INVALID_DEFINITIONS
		content_catalog = null
		game_session = null
		_startup_load_result = null
		return null

	for expected_id: String in EXPECTED_PRODUCTION_PLANT_IDS:
		if not catalog.has_plant(expected_id):
			_content_bootstrap_status = ContentBootstrapStatus.INVALID_DEFINITIONS
			content_catalog = null
			game_session = null
			_startup_load_result = null
			return null

	content_catalog = catalog
	_content_bootstrap_status = ContentBootstrapStatus.READY

	# Step 3: Load persistent GameState only after content is READY.
	_startup_load_result = save_repository.load()

	# Step 4: Construct GameSession according to persistence status and catalog validation.
	match _startup_load_result.get_status():
		LocalSaveLoadResult.LOADED_PRIMARY, LocalSaveLoadResult.LOADED_BACKUP:
			_saved_content_validation_result = PlantSaveContentValidator.validate(
				_startup_load_result.get_state(),
				content_catalog
			)
			if _saved_content_validation_result.is_compatible():
				game_session = GameSession.new(_startup_load_result.get_state())
			else:
				game_session = null
		LocalSaveLoadResult.NO_SAVE:
			_saved_content_validation_result = null
			game_session = GameSession.new()
		LocalSaveLoadResult.INVALID_DATA, LocalSaveLoadResult.IO_ERROR:
			_saved_content_validation_result = null
			game_session = null

	return _startup_load_result


## Returns true if session bootstrap has been attempted (regardless of whether an active session was created).
func is_session_bootstrapped() -> bool:
	return _is_bootstrapped


## Returns true if an active gameplay session was successfully established.
func has_active_session() -> bool:
	return game_session != null


## Returns the result of the startup persistence load operation, or null if not yet bootstrapped or if content failed.
func get_startup_load_result() -> LocalSaveLoadResult:
	return _startup_load_result


## Returns the current content bootstrap status.
func get_content_bootstrap_status() -> ContentBootstrapStatus:
	return _content_bootstrap_status


## Returns true if the ContentCatalog is loaded and ready.
func has_content_catalog() -> bool:
	return content_catalog != null


## Returns the production ContentCatalog, or null if not yet bootstrapped or if content bootstrap failed.
func get_content_catalog() -> ContentCatalog:
	return content_catalog


## Returns the diagnostic PlantContentLoadResult, or null if content loading was not attempted.
func get_content_load_result() -> PlantContentLoadResult:
	return _content_load_result


## Returns the result of validating saved plant references against the content catalog,
## or null if content loading failed, or if persistence was NO_SAVE, INVALID_DATA, or IO_ERROR.
func get_saved_content_validation_result() -> PlantSaveContentValidationResult:
	return _saved_content_validation_result


## Gameplay entry method to plant a plant and immediately checkpoint persistence.
##
## Preconditions:
## - bootstrap_session() already attempted
## - content status READY
## - content_catalog exists
## - game_session exists
## - save_repository exists
## - game_clock exists
## - random_source exists
##
## If not ready: returns PlantingCheckpointResult.not_ready() without mutating state or touching disk.
func try_plant_and_checkpoint(definition_id: String) -> PlantingCheckpointResult:
	if not _is_bootstrapped:
		return PlantingCheckpointResult.not_ready()

	if _content_bootstrap_status != ContentBootstrapStatus.READY:
		return PlantingCheckpointResult.not_ready()

	if content_catalog == null or game_session == null or save_repository == null or game_clock == null or random_source == null:
		return PlantingCheckpointResult.not_ready()

	return PlantingPersistenceCoordinator.try_plant_and_save(
		game_session,
		content_catalog,
		game_clock,
		random_source,
		save_repository,
		definition_id
	)
