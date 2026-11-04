## harvest_checkpoint_result.gd
## Strongly-typed outcome of a harvest persistence checkpoint attempt.
##
## Architectural rules:
## - Belongs to the application layer (src/application/plants/).
## - Pure domain/application result: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Strongly-typed status enum: NOT_READY, HARVEST_REJECTED, HARVESTED_SAVED, HARVESTED_SAVE_FAILED.
## - Exposes:
##     get_status() -> Status
##     get_harvest_result() -> PlantHarvestResult
##     is_harvested() -> bool
##     is_saved() -> bool
##     get_plant() -> PlantState
##     get_reward_granted() -> int
## - Semantics:
##     NOT_READY:
##       - no harvest attempted
##       - no save attempted
##       - harvest result null
##       - is_harvested false
##       - is_saved false
##       - get_plant null
##       - get_reward_granted 0
##     HARVEST_REJECTED:
##       - contains actual failed PlantHarvestResult
##       - is_harvested false
##       - is_saved false
##       - get_plant null
##       - get_reward_granted 0
##       - no save attempted
##     HARVESTED_SAVED:
##       - contains actual successful PlantHarvestResult
##       - is_harvested true
##       - is_saved true
##       - get_plant returns exact updated PlantState
##       - get_reward_granted returns positive granted currency
##       - repository.save() returned true
##     HARVESTED_SAVE_FAILED:
##       - contains actual successful PlantHarvestResult
##       - is_harvested true
##       - is_saved false
##       - get_plant returns exact updated PlantState
##       - get_reward_granted returns positive granted currency
##       - repository.save() returned false
class_name HarvestCheckpointResult
extends RefCounted

enum Status {
	NOT_READY,
	HARVEST_REJECTED,
	HARVESTED_SAVED,
	HARVESTED_SAVE_FAILED,
}

const NOT_READY: Status = Status.NOT_READY
const HARVEST_REJECTED: Status = Status.HARVEST_REJECTED
const HARVESTED_SAVED: Status = Status.HARVESTED_SAVED
const HARVESTED_SAVE_FAILED: Status = Status.HARVESTED_SAVE_FAILED

var _status: Status
var _harvest_result: PlantHarvestResult = null


func _init(status: Status, harvest_result: PlantHarvestResult = null) -> void:
	_status = status
	if _status == Status.NOT_READY:
		_harvest_result = null
	else:
		_harvest_result = harvest_result


## Factory for NOT_READY outcome when preconditions or dependencies are unmet.
static func not_ready() -> HarvestCheckpointResult:
	return HarvestCheckpointResult.new(Status.NOT_READY, null)


## Factory for HARVEST_REJECTED outcome containing the failed PlantHarvestResult.
static func harvest_rejected(harvest_result: PlantHarvestResult) -> HarvestCheckpointResult:
	return HarvestCheckpointResult.new(Status.HARVEST_REJECTED, harvest_result)


## Factory for HARVESTED_SAVED outcome containing the successful PlantHarvestResult.
static func harvested_saved(harvest_result: PlantHarvestResult) -> HarvestCheckpointResult:
	return HarvestCheckpointResult.new(Status.HARVESTED_SAVED, harvest_result)


## Factory for HARVESTED_SAVE_FAILED outcome containing the successful PlantHarvestResult
## where repository.save() returned false. In-memory state remains mutated.
static func harvested_save_failed(harvest_result: PlantHarvestResult) -> HarvestCheckpointResult:
	return HarvestCheckpointResult.new(Status.HARVESTED_SAVE_FAILED, harvest_result)


## Returns the typed checkpoint status.
func get_status() -> Status:
	return _status


## Returns the underlying PlantHarvestResult, or null if status is NOT_READY.
func get_harvest_result() -> PlantHarvestResult:
	return _harvest_result


## Returns true if the plant was successfully harvested in authoritative GameState.
func is_harvested() -> bool:
	return _status == Status.HARVESTED_SAVED or _status == Status.HARVESTED_SAVE_FAILED


## Returns true if the persistence checkpoint confirmed durable write to disk.
func is_saved() -> bool:
	return _status == Status.HARVESTED_SAVED


## Returns the exact updated PlantState in GameState if harvested, or null otherwise.
func get_plant() -> PlantState:
	if not is_harvested() or _harvest_result == null:
		return null
	return _harvest_result.get_plant()


## Returns the positive currency reward granted if harvested, or 0 otherwise.
func get_reward_granted() -> int:
	if not is_harvested() or _harvest_result == null:
		return 0
	return _harvest_result.get_reward_granted()
