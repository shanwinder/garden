## plant_harvest_result.gd
## Strongly-typed outcome of harvesting a mature plant in GameState.
##
## Architectural rules:
## - Belongs to the application layer (src/application/plants/).
## - Pure domain/application result: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Strongly-typed status enum:
##     HARVESTED, INVALID_INPUT, PLANT_NOT_FOUND, UNKNOWN_DEFINITION_ID,
##     PLANT_NOT_MATURE, INVALID_REWARD, CURRENCY_GRANT_REJECTED, STATE_UPDATE_REJECTED.
## - HARVESTED: get_plant() returns the exact updated PlantState stored in GameState,
##   and get_reward_granted() returns the positive currency amount granted.
## - All failure statuses: get_plant() returns null and get_reward_granted() returns 0.
## - No generic Dictionary result bag.
## - Independent of SceneTree, filesystem, GameClock, RandomSource, and UI.
class_name PlantHarvestResult
extends RefCounted

enum Status {
	HARVESTED,
	INVALID_INPUT,
	PLANT_NOT_FOUND,
	UNKNOWN_DEFINITION_ID,
	PLANT_NOT_MATURE,
	INVALID_REWARD,
	CURRENCY_GRANT_REJECTED,
	STATE_UPDATE_REJECTED,
}

const HARVESTED: Status = Status.HARVESTED
const INVALID_INPUT: Status = Status.INVALID_INPUT
const PLANT_NOT_FOUND: Status = Status.PLANT_NOT_FOUND
const UNKNOWN_DEFINITION_ID: Status = Status.UNKNOWN_DEFINITION_ID
const PLANT_NOT_MATURE: Status = Status.PLANT_NOT_MATURE
const INVALID_REWARD: Status = Status.INVALID_REWARD
const CURRENCY_GRANT_REJECTED: Status = Status.CURRENCY_GRANT_REJECTED
const STATE_UPDATE_REJECTED: Status = Status.STATE_UPDATE_REJECTED

var _status: Status
var _plant: PlantState = null
var _reward_granted: int = 0


func _init(status: Status, plant: PlantState = null, reward_granted: int = 0) -> void:
	_status = status
	if _status == Status.HARVESTED:
		_plant = plant
		_reward_granted = maxi(reward_granted, 0)
	else:
		_plant = null
		_reward_granted = 0


## Factory for successful harvest outcome containing the exact updated PlantState reference
## and the positive currency reward granted.
static func harvested(plant: PlantState, reward_granted: int) -> PlantHarvestResult:
	return PlantHarvestResult.new(Status.HARVESTED, plant, reward_granted)


## Factory for validation failure due to null or structurally invalid input.
static func invalid_input() -> PlantHarvestResult:
	return PlantHarvestResult.new(Status.INVALID_INPUT)


## Factory for validation failure when runtime_instance_id does not exist in collection.
static func plant_not_found() -> PlantHarvestResult:
	return PlantHarvestResult.new(Status.PLANT_NOT_FOUND)


## Factory for validation failure when plant's definition_id is missing or invalid in ContentCatalog.
static func unknown_definition_id() -> PlantHarvestResult:
	return PlantHarvestResult.new(Status.UNKNOWN_DEFINITION_ID)


## Factory for validation failure when plant has not yet reached PlantGrowth.Stage.MATURE.
static func plant_not_mature() -> PlantHarvestResult:
	return PlantHarvestResult.new(Status.PLANT_NOT_MATURE)


## Factory for validation failure when definition's harvest_reward is not positive (<= 0).
static func invalid_reward() -> PlantHarvestResult:
	return PlantHarvestResult.new(Status.INVALID_REWARD)


## Factory for failure when EconomyState rejects the currency grant (e.g. MAX_CURRENCY overflow).
static func currency_grant_rejected() -> PlantHarvestResult:
	return PlantHarvestResult.new(Status.CURRENCY_GRANT_REJECTED)


## Factory for unexpected failure during PlantState cycle replacement in PlantCollectionState.
static func state_update_rejected() -> PlantHarvestResult:
	return PlantHarvestResult.new(Status.STATE_UPDATE_REJECTED)


## Returns the typed harvest status.
func get_status() -> Status:
	return _status


## Returns true if the harvest was successful.
func is_harvested() -> bool:
	return _status == Status.HARVESTED


## Returns the exact updated PlantState stored in GameState on success, or null on failure.
func get_plant() -> PlantState:
	return _plant


## Returns the currency reward granted on success, or 0 on failure.
func get_reward_granted() -> int:
	return _reward_granted
