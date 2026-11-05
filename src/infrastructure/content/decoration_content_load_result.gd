## decoration_content_load_result.gd
## Typed result contract for decoration content loading operations.
##
## Distinguishes successful (LOADED) and failed (LOAD_FAILED) content load outcomes.
## Adheres to an all-or-nothing policy: failures never expose partial successfully loaded content.
##
## Architectural rules:
## - Belongs to the infrastructure content layer (src/infrastructure/content/).
## - Lightweight typed result: extends RefCounted (not Node, Resource, Autoload, or singleton).
## - Immutable outcome container after construction; encapsulated return collections.
## - Does not depend on AppRoot, GameSession, GameState, LifecycleCoordinator, or LocalSaveRepository.
## - Avoids depending on ContentCatalog.
class_name DecorationContentLoadResult
extends RefCounted

enum Status {
	LOADED = 0,
	LOAD_FAILED = 1,
}

var _status: Status
var _definitions: Array[DecorationDefinition] = []
var _failed_path: String = ""
var _error_message: String = ""


func _init(
	status: Status,
	definitions: Array[DecorationDefinition] = [],
	failed_path: String = "",
	error_message: String = ""
) -> void:
	_status = status
	_definitions = definitions
	_failed_path = failed_path
	_error_message = error_message


## Creates a successful DecorationContentLoadResult retaining the loaded definitions.
static func create_loaded(definitions: Array[DecorationDefinition]) -> DecorationContentLoadResult:
	var defs_copy: Array[DecorationDefinition] = []
	defs_copy.assign(definitions)
	return DecorationContentLoadResult.new(Status.LOADED, defs_copy, "", "")


## Creates a failed DecorationContentLoadResult recording the offending path and diagnostics.
## Ensures definitions array is empty (all-or-nothing guarantee).
static func create_failed(failed_path: String, error_message: String = "") -> DecorationContentLoadResult:
	var empty_defs: Array[DecorationDefinition] = []
	return DecorationContentLoadResult.new(Status.LOAD_FAILED, empty_defs, failed_path, error_message)


## Returns the result status (LOADED or LOAD_FAILED).
func get_status() -> Status:
	return _status


## Returns true if all requested definitions loaded successfully.
func is_loaded() -> bool:
	return _status == Status.LOADED


## Returns a defensive copy of the loaded DecorationDefinition references.
## On LOAD_FAILED, returns an empty Array[DecorationDefinition].
func get_definitions() -> Array[DecorationDefinition]:
	var result: Array[DecorationDefinition] = []
	result.assign(_definitions)
	return result


## Returns the resource path that caused the failure, or empty string on success.
func get_failed_path() -> String:
	return _failed_path


## Returns diagnostic error message, or empty string on success.
func get_error_message() -> String:
	return _error_message
