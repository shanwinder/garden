## planting_checkpoint_result.gd
## Strongly-typed outcome of a planting persistence checkpoint attempt.
##
## Architectural rules:
## - Belongs to the application layer (src/application/plants/).
## - Pure domain/application result: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Strongly-typed status enum: NOT_READY, PLANTING_REJECTED, REGISTERED_SAVED, REGISTERED_SAVE_FAILED.
## - Exposes:
##     get_status() -> Status
##     get_registration_result() -> PlantRegistrationResult
##     is_registered() -> bool
##     is_saved() -> bool
##     get_plant() -> PlantState
## - Semantics:
##     NOT_READY:
##       - no planting attempted
##       - no save attempted
##       - registration result null
##       - is_registered false
##       - is_saved false
##       - get_plant null
##     PLANTING_REJECTED:
##       - contains actual failed PlantRegistrationResult
##       - is_registered false
##       - is_saved false
##       - get_plant null
##       - no save attempted
##     REGISTERED_SAVED:
##       - contains actual successful PlantRegistrationResult
##       - is_registered true
##       - is_saved true
##       - get_plant returns exact registered PlantState
##       - repository.save() returned true
##     REGISTERED_SAVE_FAILED:
##       - contains actual successful PlantRegistrationResult
##       - is_registered true
##       - is_saved false
##       - get_plant returns exact registered PlantState
##       - repository.save() returned false
class_name PlantingCheckpointResult
extends RefCounted

enum Status {
	NOT_READY,
	PLANTING_REJECTED,
	REGISTERED_SAVED,
	REGISTERED_SAVE_FAILED,
}

const NOT_READY: Status = Status.NOT_READY
const PLANTING_REJECTED: Status = Status.PLANTING_REJECTED
const REGISTERED_SAVED: Status = Status.REGISTERED_SAVED
const REGISTERED_SAVE_FAILED: Status = Status.REGISTERED_SAVE_FAILED

var _status: Status
var _registration_result: PlantRegistrationResult = null


func _init(status: Status, registration_result: PlantRegistrationResult = null) -> void:
	_status = status
	if _status == Status.NOT_READY:
		_registration_result = null
	else:
		_registration_result = registration_result


## Factory for NOT_READY outcome when preconditions or dependencies are unmet.
static func not_ready() -> PlantingCheckpointResult:
	return PlantingCheckpointResult.new(Status.NOT_READY, null)


## Factory for PLANTING_REJECTED outcome containing the failed PlantRegistrationResult.
static func planting_rejected(registration_result: PlantRegistrationResult) -> PlantingCheckpointResult:
	return PlantingCheckpointResult.new(Status.PLANTING_REJECTED, registration_result)


## Factory for REGISTERED_SAVED outcome containing the successful PlantRegistrationResult.
static func registered_saved(registration_result: PlantRegistrationResult) -> PlantingCheckpointResult:
	return PlantingCheckpointResult.new(Status.REGISTERED_SAVED, registration_result)


## Factory for REGISTERED_SAVE_FAILED outcome containing the successful PlantRegistrationResult
## where repository.save() returned false. In-memory state remains mutated.
static func registered_save_failed(registration_result: PlantRegistrationResult) -> PlantingCheckpointResult:
	return PlantingCheckpointResult.new(Status.REGISTERED_SAVE_FAILED, registration_result)


## Returns the typed checkpoint status.
func get_status() -> Status:
	return _status


## Returns the underlying PlantRegistrationResult, or null if status is NOT_READY.
func get_registration_result() -> PlantRegistrationResult:
	return _registration_result


## Returns true if the plant was successfully registered in authoritative GameState.
func is_registered() -> bool:
	return _status == Status.REGISTERED_SAVED or _status == Status.REGISTERED_SAVE_FAILED


## Returns true if the persistence checkpoint confirmed durable write to disk.
func is_saved() -> bool:
	return _status == Status.REGISTERED_SAVED


## Returns the exact PlantState added to GameState if registered, or null otherwise.
func get_plant() -> PlantState:
	if not is_registered() or _registration_result == null:
		return null
	return _registration_result.get_plant()
