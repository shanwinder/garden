## plant_save_content_validation_result.gd
## Strongly-typed outcome of validating saved GameState plant references against ContentCatalog.
##
## Architectural rules:
## - Belongs to src/application/content/
## - Extends RefCounted; no Node, Resource, singleton, Autoload, or filesystem dependency.
## - Strongly typed status contract: COMPATIBLE, UNKNOWN_PLANT_IDS, INVALID_INPUT.
## - Immutable after construction.
## - Returns defensive copies of unknown ID arrays.
class_name PlantSaveContentValidationResult
extends RefCounted

enum Status {
	COMPATIBLE,
	UNKNOWN_PLANT_IDS,
	INVALID_INPUT,
}

const COMPATIBLE: Status = Status.COMPATIBLE
const UNKNOWN_PLANT_IDS: Status = Status.UNKNOWN_PLANT_IDS
const INVALID_INPUT: Status = Status.INVALID_INPUT

var _status: Status
var _unknown_definition_ids: Array[String] = []


func _init(status: Status, unknown_definition_ids: Array[String] = []) -> void:
	_status = status
	if _status == Status.UNKNOWN_PLANT_IDS:
		var dedup: Dictionary = {}
		for id: String in unknown_definition_ids:
			dedup[id] = true
		var sorted_ids: Array[String] = []
		for key: String in dedup.keys():
			sorted_ids.append(key)
		sorted_ids.sort()
		_unknown_definition_ids = sorted_ids
	else:
		_unknown_definition_ids = []


## Factory for successful validation outcome where all plant IDs exist in catalog.
static func compatible() -> PlantSaveContentValidationResult:
	return PlantSaveContentValidationResult.new(Status.COMPATIBLE, [])


## Factory for validation outcome where unknown plant definition IDs were discovered.
static func unknown_plant_ids(unknown_ids: Array[String]) -> PlantSaveContentValidationResult:
	return PlantSaveContentValidationResult.new(Status.UNKNOWN_PLANT_IDS, unknown_ids)


## Factory for validation failure due to null or invalid input.
static func invalid_input() -> PlantSaveContentValidationResult:
	return PlantSaveContentValidationResult.new(Status.INVALID_INPUT, [])


## Returns the typed validation status.
func get_status() -> Status:
	return _status


## Returns true if the saved plant references are fully compatible with the catalog.
func is_compatible() -> bool:
	return _status == Status.COMPATIBLE


## Returns a defensive copy of sorted unique unknown plant definition IDs.
## Returns an empty array if status is COMPATIBLE or INVALID_INPUT.
func get_unknown_definition_ids() -> Array[String]:
	return _unknown_definition_ids.duplicate()
