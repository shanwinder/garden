## garden_time_period.gd
## Canonical time-of-day period vocabulary and deterministic timestamp derivation.
##
## Establishes the four approved time-of-day periods (GAME_DESIGN.md Section 13)
## and derives the active period deterministically from UTC timestamps without
## accessing wall-clock APIs directly.
##
## Time periods:
## - "morning" : 06:00 - 10:59 (hours 6..10)
## - "day"     : 11:00 - 16:59 (hours 11..16)
## - "evening" : 17:00 - 19:59 (hours 17..19)
## - "night"   : 20:00 - 05:59 (hours 20..23 and 0..5)
##
## Architectural rules:
## - Belongs to the domain environment layer (src/domain/environment/).
## - Stateless pure value helper: extends RefCounted.
## - Does not depend on SceneTree, Node, Autoload, GameClock, RandomSource, or filesystem.
## - Negative timestamps clamp safely to 0 so clock rollback never corrupts state.
class_name GardenTimePeriod
extends RefCounted

const MORNING: String = "morning"
const DAY: String = "day"
const EVENING: String = "evening"
const NIGHT: String = "night"

const SECONDS_PER_HOUR: int = 3600
const SECONDS_PER_DAY: int = 86400

const ALL_PERIODS: Array[String] = [
	DAY,
	EVENING,
	MORNING,
	NIGHT,
]


## Returns true if [param period_id] is one of the canonical time periods.
static func is_valid(period_id: String) -> bool:
	if period_id.is_empty():
		return false
	return ALL_PERIODS.has(period_id)


## Returns true if [param period_ids] contains only valid, unique canonical time periods.
## An empty list is valid (representing unrestricted / allowed in all periods).
static func is_valid_period_list(period_ids: Array[String]) -> bool:
	var seen: Dictionary = {}
	for period_id: String in period_ids:
		if not is_valid(period_id):
			return false
		if seen.has(period_id):
			return false
		seen[period_id] = true
	return true


## Returns a defensive copy of all canonical time period IDs in ascending order.
static func get_all_periods() -> Array[String]:
	return ALL_PERIODS.duplicate()


## Derives the hour of day (0..23) from [param now_utc_seconds] and optional [param utc_offset_seconds].
## Negative [param now_utc_seconds] values are clamped to 0.
static func hour_of_day_for_utc_seconds(
	now_utc_seconds: int,
	utc_offset_seconds: int = 0
) -> int:
	var clamped_utc: int = maxi(0, now_utc_seconds)
	var adjusted_seconds: int = clamped_utc + utc_offset_seconds
	var seconds_into_day: int = posmod(adjusted_seconds, SECONDS_PER_DAY)
	return int(seconds_into_day / SECONDS_PER_HOUR)


## Maps an integer [param hour] to its canonical time-of-day period.
static func period_for_hour(hour: int) -> String:
	var normalized_hour: int = posmod(hour, 24)
	if normalized_hour >= 6 and normalized_hour <= 10:
		return MORNING
	if normalized_hour >= 11 and normalized_hour <= 16:
		return DAY
	if normalized_hour >= 17 and normalized_hour <= 19:
		return EVENING
	return NIGHT


## Derives the canonical time-of-day period from [param now_utc_seconds] and optional [param utc_offset_seconds].
## Negative [param now_utc_seconds] values are clamped to 0.
static func period_for_utc_seconds(
	now_utc_seconds: int,
	utc_offset_seconds: int = 0
) -> String:
	return period_for_hour(hour_of_day_for_utc_seconds(now_utc_seconds, utc_offset_seconds))


## Returns true if [param period_id] is a daytime period ("morning" or "day").
static func is_daytime(period_id: String) -> bool:
	return period_id == MORNING or period_id == DAY


## Returns true if [param period_id] is the nighttime period ("night").
static func is_nighttime(period_id: String) -> bool:
	return period_id == NIGHT


## Returns the next chronological canonical time-of-day period after [param period_id],
## or empty string if [param period_id] is invalid.
static func next_period_for_period(period_id: String) -> String:
	match period_id:
		MORNING:
			return DAY
		DAY:
			return EVENING
		EVENING:
			return NIGHT
		NIGHT:
			return MORNING
		_:
			return ""


## Derives the next chronological canonical time-of-day period from [param now_utc_seconds]
## and optional [param utc_offset_seconds] in O(1) time.
## Negative [param now_utc_seconds] values are clamped to 0.
static func next_period_for_utc_seconds(
	now_utc_seconds: int,
	utc_offset_seconds: int = 0
) -> String:
	return next_period_for_period(period_for_utc_seconds(now_utc_seconds, utc_offset_seconds))


## Returns the positive number of seconds remaining until the next time-of-day period boundary
## from [param now_utc_seconds] and optional [param utc_offset_seconds] in O(1) time.
## Negative [param now_utc_seconds] values are clamped to 0.
static func seconds_until_next_period(
	now_utc_seconds: int,
	utc_offset_seconds: int = 0
) -> int:
	var clamped_utc: int = maxi(0, now_utc_seconds)
	var adjusted_seconds: int = clamped_utc + utc_offset_seconds
	var seconds_into_day: int = posmod(adjusted_seconds, SECONDS_PER_DAY)

	var morning_start: int = 6 * SECONDS_PER_HOUR
	var day_start: int = 11 * SECONDS_PER_HOUR
	var evening_start: int = 17 * SECONDS_PER_HOUR
	var night_start: int = 20 * SECONDS_PER_HOUR

	if seconds_into_day < morning_start:
		return morning_start - seconds_into_day
	if seconds_into_day < day_start:
		return day_start - seconds_into_day
	if seconds_into_day < evening_start:
		return evening_start - seconds_into_day
	if seconds_into_day < night_start:
		return night_start - seconds_into_day
	return (SECONDS_PER_DAY - seconds_into_day) + morning_start
