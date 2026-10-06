## local_save_repository.gd
## Local filesystem persistence repository for GameState.
##
## Architectural rules:
## - Belongs to the infrastructure persistence layer (src/infrastructure/persistence/).
## - Pure repository: extends RefCounted; no Node, Resource, singleton, Autoload, SceneTree, UI.
## - Depends on GameStateCodec, LocalSaveLoadResult, FileAccess, DirAccess, ProjectSettings, JSON.
## - Safe-write principle: writes to TEMP first, validates thoroughly, then rotates.
## - Never directly truncates primary save.
## - Keeps one last-known-good backup.
## - Conservative quarantine of corrupt saves when valid backup exists.
## - Load is read-only and never silently creates or repairs saves.
## - Path injection allows isolated test execution without touching production saves.
class_name LocalSaveRepository
extends RefCounted

## Stable production path defaults.
const DEFAULT_PRIMARY_PATH: String = "user://garden_save.json"
const DEFAULT_TEMP_PATH: String = "user://garden_save.tmp"
const DEFAULT_BACKUP_PATH: String = "user://garden_save.bak"
const DEFAULT_CORRUPT_PATH: String = "user://garden_save.corrupt"

var _primary_path: String
var _temp_path: String
var _backup_path: String
var _corrupt_path: String


## Internal helper class for candidate read/validation results.
class CandidateReadResult extends RefCounted:
	var exists: bool = false
	var is_io_error: bool = false
	var is_invalid_data: bool = false
	var state: GameState = null

	func is_valid() -> bool:
		return state != null


func _init(
	primary_path: String = DEFAULT_PRIMARY_PATH,
	temp_path: String = DEFAULT_TEMP_PATH,
	backup_path: String = DEFAULT_BACKUP_PATH,
	corrupt_path: String = DEFAULT_CORRUPT_PATH
) -> void:
	_primary_path = primary_path
	_temp_path = temp_path
	_backup_path = backup_path
	_corrupt_path = corrupt_path


## Returns true if all four configured paths are non-empty and distinct.
func is_valid_configuration() -> bool:
	if _primary_path.is_empty() or _temp_path.is_empty() or _backup_path.is_empty() or _corrupt_path.is_empty():
		return false

	# Verify distinct raw paths.
	if (
		_primary_path == _temp_path
		or _primary_path == _backup_path
		or _primary_path == _corrupt_path
		or _temp_path == _backup_path
		or _temp_path == _corrupt_path
		or _backup_path == _corrupt_path
	):
		return false

	# Verify distinct globalized filesystem paths to prevent aliasing.
	var g_primary: String = ProjectSettings.globalize_path(_primary_path)
	var g_temp: String = ProjectSettings.globalize_path(_temp_path)
	var g_backup: String = ProjectSettings.globalize_path(_backup_path)
	var g_corrupt: String = ProjectSettings.globalize_path(_corrupt_path)

	if (
		g_primary == g_temp
		or g_primary == g_backup
		or g_primary == g_corrupt
		or g_temp == g_backup
		or g_temp == g_corrupt
		or g_backup == g_corrupt
	):
		return false

	return true


## Returns configured primary save path.
func get_primary_path() -> String:
	return _primary_path


## Returns configured temporary save path.
func get_temp_path() -> String:
	return _temp_path


## Returns configured backup save path.
func get_backup_path() -> String:
	return _backup_path


## Returns configured corrupt quarantine save path.
func get_corrupt_path() -> String:
	return _corrupt_path


## Safely persists [param state] to local storage.
##
## Guarantees:
## - Rejects null state or invalid repository path configuration.
## - Encodes using GameStateCodec without modifying V1 schema or fields.
## - Writes to TEMP first, flushes, closes, and re-validates through GameStateCodec.decode().
## - Never directly truncates PRIMARY.
## - On first save (no PRIMARY): promotes TEMP -> PRIMARY.
## - On rotation (valid PRIMARY): rotates PRIMARY -> BACKUP, then promotes TEMP -> PRIMARY.
## - On rotation failure: attempts rollback BACKUP -> PRIMARY.
## - If PRIMARY is invalid but BACKUP is valid: moves PRIMARY -> CORRUPT, then promotes TEMP -> PRIMARY.
## - If PRIMARY is invalid and BACKUP is missing/invalid: aborts save to preserve potentially recoverable data.
## - Returns true on success, false on any failure.
func save(state: GameState) -> bool:
	if not is_valid_configuration():
		return false

	if state == null:
		return false

	var snapshot: Dictionary = GameStateCodec.encode(state)
	if snapshot.is_empty():
		return false

	var json_text: String = JSON.stringify(snapshot)

	# Stale TEMP policy: remove existing TEMP if present.
	if FileAccess.file_exists(_temp_path):
		var rem_temp_err: Error = _remove_file(_temp_path)
		if rem_temp_err != OK:
			return false

	# Write TEMP transaction.
	var temp_file: FileAccess = FileAccess.open(_temp_path, FileAccess.WRITE)
	if temp_file == null:
		return false

	temp_file.store_string(json_text)
	temp_file.flush()
	temp_file.close()

	# Verify TEMP before touching PRIMARY or BACKUP.
	var temp_cand: CandidateReadResult = _read_and_validate(_temp_path)
	if not temp_cand.is_valid():
		_remove_file_best_effort(_temp_path)
		return false

	var primary_exists: bool = FileAccess.file_exists(_primary_path)

	# Case 1: First save (PRIMARY does not exist).
	if not primary_exists:
		var err_first: Error = _rename_file(_temp_path, _primary_path)
		if err_first != OK:
			_remove_file_best_effort(_temp_path)
			return false
		return true

	# Case 2: PRIMARY exists. Validate it before rotation.
	var primary_cand: CandidateReadResult = _read_and_validate(_primary_path)

	if primary_cand.is_valid():
		# PRIMARY is valid. Rotate PRIMARY -> BACKUP, then TEMP -> PRIMARY.
		if FileAccess.file_exists(_backup_path):
			var rem_bak_err: Error = _remove_file(_backup_path)
			if rem_bak_err != OK:
				_remove_file_best_effort(_temp_path)
				return false

		var err_pri_to_bak: Error = _rename_file(_primary_path, _backup_path)
		if err_pri_to_bak != OK:
			_remove_file_best_effort(_temp_path)
			return false

		var err_tmp_to_pri: Error = _rename_file(_temp_path, _primary_path)
		if err_tmp_to_pri != OK:
			# Rollback: restore BACKUP -> PRIMARY.
			_rename_file(_backup_path, _primary_path)
			_remove_file_best_effort(_temp_path)
			return false

		return true

	# Case 3: PRIMARY exists but is invalid/corrupt.
	# Conservative policy: inspect BACKUP before touching PRIMARY.
	var backup_cand: CandidateReadResult = _read_and_validate(_backup_path)
	if not backup_cand.is_valid():
		# BACKUP is missing or invalid. Abort to preserve potentially recoverable PRIMARY.
		_remove_file_best_effort(_temp_path)
		return false

	# Valid BACKUP exists. Quarantine invalid PRIMARY -> CORRUPT, then promote TEMP -> PRIMARY.
	if FileAccess.file_exists(_corrupt_path):
		var rem_corrupt_err: Error = _remove_file(_corrupt_path)
		if rem_corrupt_err != OK:
			_remove_file_best_effort(_temp_path)
			return false

	var err_pri_to_corrupt: Error = _rename_file(_primary_path, _corrupt_path)
	if err_pri_to_corrupt != OK:
		_remove_file_best_effort(_temp_path)
		return false

	var err_tmp_to_pri_corrupt: Error = _rename_file(_temp_path, _primary_path)
	if err_tmp_to_pri_corrupt != OK:
		# Rollback: restore CORRUPT -> PRIMARY.
		_rename_file(_corrupt_path, _primary_path)
		_remove_file_best_effort(_temp_path)
		return false

	return true


## Loads GameState from local storage.
##
## Guarantees:
## - Read-only: never creates, modifies, or repairs files on disk.
## - Evaluates PRIMARY first; if valid, returns LOADED_PRIMARY with GameState.
## - If PRIMARY is missing, invalid, or unreadable, attempts BACKUP.
## - If BACKUP is valid, returns LOADED_BACKUP with GameState.
## - If neither exists, returns NO_SAVE with null state.
## - If candidates exist but contain corrupt/unparseable data, returns INVALID_DATA with null state.
## - If candidates cannot be read due to filesystem I/O, returns IO_ERROR with null state.
## - Never loads from TEMP or CORRUPT quarantine files.
func load() -> LocalSaveLoadResult:
	if not is_valid_configuration():
		return LocalSaveLoadResult.io_error()

	var primary_cand: CandidateReadResult = _read_and_validate(_primary_path)
	if primary_cand.is_valid():
		return LocalSaveLoadResult.loaded_primary(primary_cand.state)

	var backup_cand: CandidateReadResult = _read_and_validate(_backup_path)
	if backup_cand.is_valid():
		return LocalSaveLoadResult.loaded_backup(backup_cand.state)

	# Neither PRIMARY nor BACKUP yielded a valid state.
	if not primary_cand.exists and not backup_cand.exists:
		return LocalSaveLoadResult.no_save()

	if primary_cand.is_io_error or backup_cand.is_io_error:
		return LocalSaveLoadResult.io_error()

	if primary_cand.is_invalid_data or backup_cand.is_invalid_data:
		return LocalSaveLoadResult.invalid_data()

	return LocalSaveLoadResult.io_error()


## Reads and validates the save file at [param path].
func _read_and_validate(path: String) -> CandidateReadResult:
	var result: CandidateReadResult = CandidateReadResult.new()
	if not FileAccess.file_exists(path):
		result.exists = false
		return result

	result.exists = true
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		result.is_io_error = true
		return result

	var text: String = file.get_as_text()
	var read_err: Error = file.get_error()
	file.close()

	if read_err != OK:
		result.is_io_error = true
		return result

	var json: JSON = JSON.new()
	var parse_err: Error = json.parse(text)
	if parse_err != OK:
		result.is_invalid_data = true
		return result

	var decoded: GameState = GameStateCodec.decode(json.data)
	if decoded == null:
		result.is_invalid_data = true
		return result

	result.state = decoded
	return result


## Removes file at [param path]. Returns OK if file does not exist or was successfully removed.
func _remove_file(path: String) -> Error:
	if not FileAccess.file_exists(path):
		return OK
	var global_path: String = ProjectSettings.globalize_path(path)
	return DirAccess.remove_absolute(global_path)


## Best-effort removal of [param path].
func _remove_file_best_effort(path: String) -> void:
	if FileAccess.file_exists(path):
		var global_path: String = ProjectSettings.globalize_path(path)
		DirAccess.remove_absolute(global_path)


## Safely renames [param from_path] to [param to_path] using globalized filesystem paths.
## Removes [param to_path] first if it exists to ensure cross-platform compatibility.
func _rename_file(from_path: String, to_path: String) -> Error:
	if FileAccess.file_exists(to_path):
		var rem_err: Error = _remove_file(to_path)
		if rem_err != OK:
			return rem_err
	var global_from: String = ProjectSettings.globalize_path(from_path)
	var global_to: String = ProjectSettings.globalize_path(to_path)
	return DirAccess.rename_absolute(global_from, global_to)
