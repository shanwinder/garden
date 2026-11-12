## garden_placement_result.gd
## Strongly-typed outcome of moving an existing plant or decoration within
## Garden's Coarse Logical Grid + Zones placement model.
##
## Architectural rules:
## - Belongs to the application placement layer (src/application/placement/).
## - Pure application result: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Immutable after construction; read-only getters.
class_name GardenPlacementResult
extends RefCounted

enum Status {
	MOVED,
	INVALID_INPUT,
	ITEM_NOT_FOUND,
	INVALID_PLACEMENT,
	ZONE_LOCKED,
	CELL_OCCUPIED,
	SAME_CELL,
	STATE_UPDATE_REJECTED,
}

const MOVED: Status = Status.MOVED
const INVALID_INPUT: Status = Status.INVALID_INPUT
const ITEM_NOT_FOUND: Status = Status.ITEM_NOT_FOUND
const INVALID_PLACEMENT: Status = Status.INVALID_PLACEMENT
const ZONE_LOCKED: Status = Status.ZONE_LOCKED
const CELL_OCCUPIED: Status = Status.CELL_OCCUPIED
const SAME_CELL: Status = Status.SAME_CELL
const STATE_UPDATE_REJECTED: Status = Status.STATE_UPDATE_REJECTED

var _status: Status
var _item_kind: String = GardenPlacement.KIND_NONE
var _runtime_instance_id: String = ""
var _definition_id: String = ""
var _zone_id: String = ""
var _grid_x: int = -1
var _grid_y: int = -1


func _init(
	status: Status,
	item_kind: String = GardenPlacement.KIND_NONE,
	runtime_instance_id: String = "",
	definition_id: String = "",
	zone_id: String = "",
	grid_x: int = -1,
	grid_y: int = -1
) -> void:
	_status = status
	if _status == Status.MOVED:
		_item_kind = item_kind
		_runtime_instance_id = runtime_instance_id
		_definition_id = definition_id
		_zone_id = zone_id
		_grid_x = grid_x
		_grid_y = grid_y
	else:
		_item_kind = GardenPlacement.KIND_NONE
		_runtime_instance_id = ""
		_definition_id = ""
		_zone_id = ""
		_grid_x = -1
		_grid_y = -1


static func moved(
	item_kind: String,
	runtime_instance_id: String,
	definition_id: String,
	zone_id: String,
	grid_x: int,
	grid_y: int
) -> GardenPlacementResult:
	return GardenPlacementResult.new(
		Status.MOVED,
		item_kind,
		runtime_instance_id,
		definition_id,
		zone_id,
		grid_x,
		grid_y
	)


static func invalid_input() -> GardenPlacementResult:
	return GardenPlacementResult.new(Status.INVALID_INPUT)


static func item_not_found() -> GardenPlacementResult:
	return GardenPlacementResult.new(Status.ITEM_NOT_FOUND)


static func invalid_placement() -> GardenPlacementResult:
	return GardenPlacementResult.new(Status.INVALID_PLACEMENT)


static func zone_locked() -> GardenPlacementResult:
	return GardenPlacementResult.new(Status.ZONE_LOCKED)


static func cell_occupied() -> GardenPlacementResult:
	return GardenPlacementResult.new(Status.CELL_OCCUPIED)


static func same_cell() -> GardenPlacementResult:
	return GardenPlacementResult.new(Status.SAME_CELL)


static func state_update_rejected() -> GardenPlacementResult:
	return GardenPlacementResult.new(Status.STATE_UPDATE_REJECTED)


func get_status() -> Status:
	return _status


func is_moved() -> bool:
	return _status == Status.MOVED


func get_item_kind() -> String:
	return _item_kind


func get_runtime_instance_id() -> String:
	return _runtime_instance_id


func get_definition_id() -> String:
	return _definition_id


func get_zone_id() -> String:
	return _zone_id


func get_grid_x() -> int:
	return _grid_x


func get_grid_y() -> int:
	return _grid_y
