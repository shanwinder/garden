## app_root.gd
## Single application-level composition root for Garden.
##
## AppRoot is the single composition root for long-lived application and
## infrastructure services. It explicitly constructs one SystemGameClock,
## one GodotRandomSource, and one LocalSaveRepository, exposing each as a
## typed dependency.
##
## It bootstraps the active GameSession from persistent storage during startup
## (_ready), ensuring corruption safety: an invalid or errored save prevents
## session creation to avoid overwriting player data.
##
## Composition:
##   AppRoot
##   ├── game_clock:      GameClock           -> SystemGameClock
##   ├── random_source:   RandomSource        -> GodotRandomSource
##   ├── save_repository: LocalSaveRepository -> LocalSaveRepository
##   └── game_session:    GameSession         -> owns GameState (null until bootstrapped)
##
## Dependency direction:
##   AppRoot constructs infrastructure services and the active game session.
##   Application/domain code receives values from those services as arguments
##   rather than reading App.game_clock or App.random_source directly.
##
## Autoload rule:
##   Only one Autoload exists in this project: App -> res://src/application/app_root.gd.
##   GameClock, SystemGameClock, FakeGameClock, GodotRandomSource, FakeRandomSource,
##   LocalSaveRepository, GameSession, and GameState must not become Autoloads.
class_name AppRoot
extends Node

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

## The active gameplay session for this application instance.
## Constructed during startup bootstrap; null prior to bootstrap or if
## bootstrap encountered an error (INVALID_DATA or IO_ERROR).
## GameSession owns the canonical GameState.
var game_session: GameSession

## Tracks whether bootstrap_session() has been executed.
var _is_bootstrapped: bool = false

## Retains the outcome of the startup load operation.
var _startup_load_result: LocalSaveLoadResult = null


func _init(save_repository_override: LocalSaveRepository = null) -> void:
	game_clock = SystemGameClock.new()
	random_source = GodotRandomSource.new()
	if save_repository_override != null:
		save_repository = save_repository_override
	else:
		save_repository = LocalSaveRepository.new()
	game_session = null


func _ready() -> void:
	bootstrap_session()


## One-time bootstrap of the active GameSession from local persistence.
##
## Idempotent: repeated calls do nothing and return the existing load result.
## Read-only: never calls repository.save() or modifies files on disk.
##
## Returns the LocalSaveLoadResult produced during the initial bootstrap.
func bootstrap_session() -> LocalSaveLoadResult:
	if _is_bootstrapped:
		return _startup_load_result

	_is_bootstrapped = true
	_startup_load_result = save_repository.load()

	match _startup_load_result.get_status():
		LocalSaveLoadResult.LOADED_PRIMARY, LocalSaveLoadResult.LOADED_BACKUP:
			game_session = GameSession.new(_startup_load_result.get_state())
		LocalSaveLoadResult.NO_SAVE:
			game_session = GameSession.new()
		LocalSaveLoadResult.INVALID_DATA, LocalSaveLoadResult.IO_ERROR:
			game_session = null

	return _startup_load_result


## Returns true if session bootstrap has been attempted.
func is_session_bootstrapped() -> bool:
	return _is_bootstrapped


## Returns true if an active gameplay session was successfully established.
func has_active_session() -> bool:
	return game_session != null


## Returns the result of the startup load operation, or null if not yet bootstrapped.
func get_startup_load_result() -> LocalSaveLoadResult:
	return _startup_load_result
