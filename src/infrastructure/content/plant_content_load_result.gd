## plant_content_load_result.gd
## Typed result contract for plant content loading operations.
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
class_name PlantContentLoadResult
extends RefCounted

enum Status {
	LOADED = 0,
	LOAD_FAILED = 1,
}

var _status: Status
var _definitions: Array[PlantDefinition] = []
var _failed_path: String = ""
var _error_message: String = ""


func _init(
	status: Status,
	definitions: Array[PlantDefinition] = [],
	failed_path: String = "",
	error_message: String = ""
) -> void:
	_status = status
	_definitions = definitions
	_failed_path = failed_path
	_error_message = error_message


## Creates a successful PlantContentLoadResult retaining the loaded definitions.
static func create_loaded(definitions: Array[PlantDefinition]) -> PlantContentLoadResult:
	var defs_copy: Array[PlantDefinition] = []
	defs_copy.assign(definitions)
	return PlantContentLoadResult.new(Status.LOADED, defs_copy, "", "")


## Creates a failed PlantContentLoadResult recording the offending path and diagnostics.
## Ensures definitions array is empty (all-or-nothing guarantee).
static func create_failed(failed_path: String, error_message: String = "") -> PlantContentLoadResult:
	var empty_defs: Array[PlantDefinition] = []
	return PlantContentLoadResult.new(Status.LOAD_FAILED, empty_defs, failed_path, error_message)


## Returns the result status (LOADED or LOAD_FAILED).
func get_status() -> Status:
	return _status


## Returns true if all requested definitions loaded successfully.
func is_loaded() -> bool:
	return _status == Status.LOADED


## Returns a defensive copy of the loaded PlantDefinition references.
## On LOAD_FAILED, returns an empty Array[PlantDefinition].
func get_definitions() -> Array[PlantDefinition]:
	var result: Array[PlantDefinition] = []
	result.assign(_definitions)
	return result


## Returns the resource path that caused the failure, or empty string on success.
func get_failed_path() -> String:
	return _failed_path


## Returns diagnostic error message, or empty string on success.
func get_error_message() -> String:
	return _error_message
