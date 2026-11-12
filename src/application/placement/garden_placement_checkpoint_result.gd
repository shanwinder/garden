## garden_placement_checkpoint_result.gd
## Strongly-typed outcome of a garden item move + persistence checkpoint attempt.
class_name GardenPlacementCheckpointResult
extends RefCounted

enum Status {
	NOT_READY,
	MOVE_REJECTED,
	MOVED_SAVED,
	MOVED_SAVE_FAILED,
}

const NOT_READY: Status = Status.NOT_READY
const MOVE_REJECTED: Status = Status.MOVE_REJECTED
const MOVED_SAVED: Status = Status.MOVED_SAVED
const MOVED_SAVE_FAILED: Status = Status.MOVED_SAVE_FAILED

var _status: Status
var _placement_result: GardenPlacementResult = null


func _init(status: Status, placement_result: GardenPlacementResult = null) -> void:
	_status = status
	if _status == Status.NOT_READY:
		_placement_result = null
	else:
		_placement_result = placement_result


static func not_ready() -> GardenPlacementCheckpointResult:
	return GardenPlacementCheckpointResult.new(Status.NOT_READY, null)


static func move_rejected(placement_result: GardenPlacementResult) -> GardenPlacementCheckpointResult:
	return GardenPlacementCheckpointResult.new(Status.MOVE_REJECTED, placement_result)


static func moved_saved(placement_result: GardenPlacementResult) -> GardenPlacementCheckpointResult:
	return GardenPlacementCheckpointResult.new(Status.MOVED_SAVED, placement_result)


static func moved_save_failed(placement_result: GardenPlacementResult) -> GardenPlacementCheckpointResult:
	return GardenPlacementCheckpointResult.new(Status.MOVED_SAVE_FAILED, placement_result)


func get_status() -> Status:
	return _status


func get_placement_result() -> GardenPlacementResult:
	return _placement_result


func is_moved() -> bool:
	return _status == Status.MOVED_SAVED or _status == Status.MOVED_SAVE_FAILED


func is_saved() -> bool:
	return _status == Status.MOVED_SAVED
