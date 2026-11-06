## garden_return_summary.gd
## Immutable domain value object summarizing changes in the garden across an away/offline interval.
##
## Captures deterministic facts derived between a departure timestamp (previous_utc_seconds)
## and a return timestamp (current_utc_seconds) per GAME_DESIGN.md Sections 7 & 19 and
## ARCHITECTURE.md Sections 13, 14, 25 & 26:
## - previous_utc_seconds: UTC timestamp before the away interval (>= 0)
## - current_utc_seconds: UTC timestamp upon return (>= 0)
## - elapsed_seconds: non-negative elapsed seconds (clamped to 0 on clock rollback)
## - clock_rolled_back: true when current_utc_seconds < previous_utc_seconds
## - advanced_plant_ids: ascending runtime_instance_ids of plants that advanced at least one growth stage
## - newly_matured_plant_ids: ascending runtime_instance_ids of plants that newly reached MATURE stage
## - ready_to_harvest_count: total mature harvestable plants at current_utc_seconds (>= 0)
## - previous_time_period / current_time_period: canonical GardenTimePeriod IDs
## - previous_weather_state / current_weather_state: canonical GardenWeather IDs
##
## Architectural rules:
## - Belongs to the domain progression layer (src/domain/progression/).
## - Pure immutable value object: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Deterministic, stateless validation, side-effect free, no push_error().
class_name GardenReturnSummary
extends RefCounted

var _previous_utc_seconds: int
var _current_utc_seconds: int
var _elapsed_seconds: int
var _clock_rolled_back: bool
var _advanced_plant_ids: Array[String]
var _newly_matured_plant_ids: Array[String]
var _ready_to_harvest_count: int
var _previous_time_period: String
var _current_time_period: String
var _previous_weather_state: String
var _current_weather_state: String


func _init(
	previous_utc_seconds: int,
	current_utc_seconds: int,
	elapsed_seconds: int,
	clock_rolled_back: bool,
	advanced_plant_ids: Array[String],
	newly_matured_plant_ids: Array[String],
	ready_to_harvest_count: int,
	previous_time_period: String,
	current_time_period: String,
	previous_weather_state: String,
	current_weather_state: String
) -> void:
	_previous_utc_seconds = previous_utc_seconds
	_current_utc_seconds = current_utc_seconds
	_elapsed_seconds = elapsed_seconds
	_clock_rolled_back = clock_rolled_back
	_advanced_plant_ids = advanced_plant_ids.duplicate()
	_newly_matured_plant_ids = newly_matured_plant_ids.duplicate()
	_ready_to_harvest_count = ready_to_harvest_count
	_previous_time_period = previous_time_period
	_current_time_period = current_time_period
	_previous_weather_state = previous_weather_state
	_current_weather_state = current_weather_state


func get_previous_utc_seconds() -> int:
	return _previous_utc_seconds


func get_current_utc_seconds() -> int:
	return _current_utc_seconds


func get_elapsed_seconds() -> int:
	return _elapsed_seconds


func was_clock_rolled_back() -> bool:
	return _clock_rolled_back


func get_advanced_plant_ids() -> Array[String]:
	return _advanced_plant_ids.duplicate()


func get_advanced_plant_count() -> int:
	return _advanced_plant_ids.size()


func get_newly_matured_plant_ids() -> Array[String]:
	return _newly_matured_plant_ids.duplicate()


func get_newly_matured_plant_count() -> int:
	return _newly_matured_plant_ids.size()


func get_ready_to_harvest_count() -> int:
	return _ready_to_harvest_count


func get_previous_time_period() -> String:
	return _previous_time_period


func get_current_time_period() -> String:
	return _current_time_period


func has_time_period_changed() -> bool:
	return (
		not _clock_rolled_back
		and _elapsed_seconds > 0
		and _previous_time_period != _current_time_period
	)


func get_previous_weather_state() -> String:
	return _previous_weather_state


func get_current_weather_state() -> String:
	return _current_weather_state


func has_weather_changed() -> bool:
	return (
		not _clock_rolled_back
		and _elapsed_seconds > 0
		and _previous_weather_state != _current_weather_state
	)


func has_plant_growth_changes() -> bool:
	return not _advanced_plant_ids.is_empty()


func has_atmosphere_changes() -> bool:
	return has_time_period_changed() or has_weather_changed()


func has_meaningful_changes() -> bool:
	return (
		not _clock_rolled_back
		and _elapsed_seconds > 0
		and (has_plant_growth_changes() or has_atmosphere_changes())
	)


## Returns true if this GardenReturnSummary satisfies all domain invariants.
func is_valid() -> bool:
	if _previous_utc_seconds < 0 or _current_utc_seconds < 0:
		return false

	var expected_rollback: bool = _current_utc_seconds < _previous_utc_seconds
	if _clock_rolled_back != expected_rollback:
		return false

	var expected_elapsed: int = maxi(0, _current_utc_seconds - _previous_utc_seconds)
	if _elapsed_seconds != expected_elapsed:
		return false

	if _ready_to_harvest_count < 0:
		return false

	if not GardenTimePeriod.is_valid(_previous_time_period):
		return false

	if not GardenTimePeriod.is_valid(_current_time_period):
		return false

	if not GardenWeather.is_valid(_previous_weather_state):
		return false

	if not GardenWeather.is_valid(_current_weather_state):
		return false

	if _clock_rolled_back or _elapsed_seconds == 0:
		if not _advanced_plant_ids.is_empty() or not _newly_matured_plant_ids.is_empty():
			return false

	if not _is_strictly_sorted_non_empty_ids(_advanced_plant_ids):
		return false

	if not _is_strictly_sorted_non_empty_ids(_newly_matured_plant_ids):
		return false

	for mature_id: String in _newly_matured_plant_ids:
		if not _advanced_plant_ids.has(mature_id):
			return false

	return true


static func _is_strictly_sorted_non_empty_ids(ids: Array[String]) -> bool:
	var prev: String = ""
	for i: int in range(ids.size()):
		var current: String = ids[i]
		if current.is_empty():
			return false
		if i > 0 and current <= prev:
			return false
		prev = current
	return true
