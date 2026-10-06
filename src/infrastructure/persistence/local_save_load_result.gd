## local_save_load_result.gd
## Strongly-typed outcome of a LocalSaveRepository load operation.
##
## Architectural rules:
## - Belongs to src/infrastructure/persistence/
## - Extends RefCounted; no Node, Resource, singleton, Autoload.
## - Small, typed status contract: LOADED_PRIMARY, LOADED_BACKUP, NO_SAVE, INVALID_DATA, IO_ERROR.
## - Not a generic Dictionary result bag.
## - Immutable after construction.
class_name LocalSaveLoadResult
extends RefCounted

enum Status {
	LOADED_PRIMARY,
	LOADED_BACKUP,
	NO_SAVE,
	INVALID_DATA,
	IO_ERROR,
}

const LOADED_PRIMARY: Status = Status.LOADED_PRIMARY
const LOADED_BACKUP: Status = Status.LOADED_BACKUP
const NO_SAVE: Status = Status.NO_SAVE
const INVALID_DATA: Status = Status.INVALID_DATA
const IO_ERROR: Status = Status.IO_ERROR

var _status: Status
var _state: GameState


func _init(status: Status, state: GameState = null) -> void:
	_status = status
	if _status == Status.LOADED_PRIMARY or _status == Status.LOADED_BACKUP:
		assert(state != null, "LocalSaveLoadResult: state must not be null for loaded status")
		_state = state
	else:
		_state = null


## Factory for successful load from primary save.
static func loaded_primary(state: GameState) -> LocalSaveLoadResult:
	return LocalSaveLoadResult.new(Status.LOADED_PRIMARY, state)


## Factory for successful load from last-known-good backup.
static func loaded_backup(state: GameState) -> LocalSaveLoadResult:
	return LocalSaveLoadResult.new(Status.LOADED_BACKUP, state)


## Factory when no save file exists (clean first run).
static func no_save() -> LocalSaveLoadResult:
	return LocalSaveLoadResult.new(Status.NO_SAVE, null)


## Factory when save candidate exists but contains malformed/corrupted data.
static func invalid_data() -> LocalSaveLoadResult:
	return LocalSaveLoadResult.new(Status.INVALID_DATA, null)


## Factory when an unrecoverable filesystem I/O error occurred.
static func io_error() -> LocalSaveLoadResult:
	return LocalSaveLoadResult.new(Status.IO_ERROR, null)


## Returns the load status.
func get_status() -> Status:
	return _status


## Returns the decoded GameState, or null if no valid state was loaded.
func get_state() -> GameState:
	return _state


## Returns true if a valid state was successfully loaded (either primary or backup).
func is_loaded() -> bool:
	return _status == Status.LOADED_PRIMARY or _status == Status.LOADED_BACKUP


## Returns true if recovery load from backup was used.
func loaded_from_backup() -> bool:
	return _status == Status.LOADED_BACKUP
