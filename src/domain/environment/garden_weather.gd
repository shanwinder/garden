## garden_weather.gd
## Canonical garden weather vocabulary and deterministic timestamp schedule.
##
## Establishes the three approved MVP weather states (GAME_DESIGN.md Section 14,
## DEFINITION_OF_DONE.md Section 27) and derives the current weather state in O(1)
## time from authoritative UTC timestamps without simulating intermediate ticks
## (ARCHITECTURE.md Section 18).
##
## Weather states:
## - "clear"  : Clear sky (ท้องฟ้าแจ่มใส)
## - "cloudy" : Cloudy sky (มีเมฆมาก)
## - "rain"   : Rain (ฝนตก)
##
## Schedule properties:
## - WEATHER_WINDOW_SECONDS = 7200 (2-hour windows, 12 windows per 24-hour day).
## - WEATHER_SCHEDULE_CYCLE has length 5 (coprime with 12 windows/day), ensuring
##   every time-of-day period experiences all three weather states across days.
##
## Architectural rules:
## - Belongs to the domain environment layer (src/domain/environment/).
## - Stateless pure value helper: extends RefCounted.
## - Does not depend on SceneTree, Node, Autoload, GameClock, RandomSource, or filesystem.
## - Negative timestamps clamp safely to 0 so clock rollback never corrupts state.
class_name GardenWeather
extends RefCounted

const CLEAR: String = "clear"
const CLOUDY: String = "cloudy"
const RAIN: String = "rain"

const WEATHER_WINDOW_SECONDS: int = 7200

const ALL_WEATHER_STATES: Array[String] = [
	CLEAR,
	CLOUDY,
	RAIN,
]

const WEATHER_SCHEDULE_CYCLE: Array[String] = [
	CLEAR,
	CLOUDY,
	RAIN,
	CLEAR,
	CLOUDY,
]


## Returns true if [param weather_id] is one of the canonical MVP weather states.
static func is_valid(weather_id: String) -> bool:
	if weather_id.is_empty():
		return false
	return ALL_WEATHER_STATES.has(weather_id)


## Returns true if [param weather_ids] contains only valid, unique canonical weather states.
## An empty list is valid (representing unrestricted / allowed in all weather states).
static func is_valid_weather_list(weather_ids: Array[String]) -> bool:
	var seen: Dictionary = {}
	for weather_id: String in weather_ids:
		if not is_valid(weather_id):
			return false
		if seen.has(weather_id):
			return false
		seen[weather_id] = true
	return true


## Returns a defensive copy of all canonical weather state IDs in ascending order.
static func get_all_weather_states() -> Array[String]:
	return ALL_WEATHER_STATES.duplicate()


## Returns the non-negative 2-hour weather window index for [param now_utc_seconds].
## Negative timestamps clamp safely to 0.
static func window_index_for_utc_seconds(now_utc_seconds: int) -> int:
	var clamped_utc: int = maxi(0, now_utc_seconds)
	return int(clamped_utc / WEATHER_WINDOW_SECONDS)


## Derives the active canonical weather state at [param now_utc_seconds] in O(1) time.
## Negative timestamps clamp safely to 0 ("clear").
static func weather_for_utc_seconds(now_utc_seconds: int) -> String:
	var window_idx: int = window_index_for_utc_seconds(now_utc_seconds)
	var cycle_idx: int = window_idx % WEATHER_SCHEDULE_CYCLE.size()
	return WEATHER_SCHEDULE_CYCLE[cycle_idx]


## Derives the canonical weather state for the next 2-hour window after [param now_utc_seconds]
## in O(1) time.
## Negative timestamps clamp safely to 0 (next window is window 1 -> "cloudy").
static func next_weather_for_utc_seconds(now_utc_seconds: int) -> String:
	var next_window_idx: int = window_index_for_utc_seconds(now_utc_seconds) + 1
	var cycle_idx: int = next_window_idx % WEATHER_SCHEDULE_CYCLE.size()
	return WEATHER_SCHEDULE_CYCLE[cycle_idx]


## Returns the positive number of seconds remaining (1..WEATHER_WINDOW_SECONDS) until the next
## 2-hour weather window transition from [param now_utc_seconds] in O(1) time.
## Negative timestamps clamp safely to 0 (returning WEATHER_WINDOW_SECONDS).
static func seconds_until_next_weather(now_utc_seconds: int) -> int:
	var clamped_utc: int = maxi(0, now_utc_seconds)
	var elapsed_in_window: int = clamped_utc % WEATHER_WINDOW_SECONDS
	return WEATHER_WINDOW_SECONDS - elapsed_in_window
