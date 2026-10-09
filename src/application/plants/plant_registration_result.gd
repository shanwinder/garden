## plant_registration_result.gd
## Strongly-typed outcome of registering a planted plant into GameState.
##
## Architectural rules:
## - Belongs to the application layer (src/application/plants/).
## - Pure domain/application result: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Strongly-typed status enum: REGISTERED, INVALID_INPUT, UNKNOWN_DEFINITION_ID, DUPLICATE_INSTANCE_ID, INSERTION_REJECTED.
## - REGISTERED: get_plant() returns the exact PlantState added to GameState.
## - All failure statuses: get_plant() returns null.
## - No generic Dictionary result bag.
## - Independent of SceneTree, filesystem, GameClock, RandomSource, and UI.
class_name PlantRegistrationResult
extends RefCounted

enum Status {
	REGISTERED,
	INVALID_INPUT,
	UNKNOWN_DEFINITION_ID,
	DUPLICATE_INSTANCE_ID,
	INSERTION_REJECTED,
}

const REGISTERED: Status = Status.REGISTERED
const INVALID_INPUT: Status = Status.INVALID_INPUT
const UNKNOWN_DEFINITION_ID: Status = Status.UNKNOWN_DEFINITION_ID
const DUPLICATE_INSTANCE_ID: Status = Status.DUPLICATE_INSTANCE_ID
const INSERTION_REJECTED: Status = Status.INSERTION_REJECTED

var _status: Status
var _plant: PlantState = null


func _init(status: Status, plant: PlantState = null) -> void:
	_status = status
	if _status == Status.REGISTERED:
		_plant = plant
	else:
		_plant = null


## Factory for successful registration outcome containing the exact stored PlantState reference.
static func registered(plant: PlantState) -> PlantRegistrationResult:
	return PlantRegistrationResult.new(Status.REGISTERED, plant)


## Factory for validation failure due to null or structurally invalid input.
static func invalid_input() -> PlantRegistrationResult:
	return PlantRegistrationResult.new(Status.INVALID_INPUT, null)


## Factory for validation failure due to definition ID not found in ContentCatalog.
static func unknown_definition_id() -> PlantRegistrationResult:
	return PlantRegistrationResult.new(Status.UNKNOWN_DEFINITION_ID, null)


## Factory for validation failure due to runtime instance ID already present in collection.
static func duplicate_instance_id() -> PlantRegistrationResult:
	return PlantRegistrationResult.new(Status.DUPLICATE_INSTANCE_ID, null)


## Factory for unexpected failure during domain collection insertion.
static func insertion_rejected() -> PlantRegistrationResult:
	return PlantRegistrationResult.new(Status.INSERTION_REJECTED, null)


## Returns the typed registration status.
func get_status() -> Status:
	return _status


## Returns true if the registration was successful.
func is_registered() -> bool:
	return _status == Status.REGISTERED


## Returns the exact PlantState stored in GameState on success, or null on failure.
func get_plant() -> PlantState:
	return _plant
