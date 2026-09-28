## system_game_clock.gd
## Production implementation of the GameClock contract.
##
## SystemGameClock delegates directly to Godot's Time singleton for both
## wall-clock and monotonic measurements. It applies no caching, clamping,
## anti-cheat logic, or timezone conversion.
##
## Clock rollback semantics:
##   If the device wall clock moves backward, utc_now_seconds() will return a
##   lower value than a previous call. This is intentional: SystemGameClock
##   exposes reality. Callers that compute elapsed time are responsible for
##   clamping negative values:
##       elapsed = max(0, now - previous_timestamp)
##   Do not attempt to "fix" rollback here.
##
## This type is NOT a Node and must not enter the SceneTree.
## It must not become an Autoload.
## It is owned by AppRoot (the composition root).
class_name SystemGameClock
extends GameClock


## Returns the current UTC Unix epoch time as integer seconds.
##
## Uses Time.get_unix_time_from_system() which returns a float. The value is
## truncated to int (floor toward zero) to produce a stable integer seconds
## representation. No timezone offset is applied; the result is UTC/Unix time.
func utc_now_seconds() -> int:
	return int(Time.get_unix_time_from_system())


## Returns a monotonic process-time measurement in integer milliseconds.
##
## Uses Time.get_ticks_msec() which returns a monotonically increasing count
## of milliseconds since the engine started. This value:
##   - does NOT move backward;
##   - is suitable for measuring elapsed runtime intervals;
##   - is NOT a persistent wall-clock timestamp;
##   - must NOT be serialized as a cross-session authoritative time value.
func monotonic_milliseconds() -> int:
	return Time.get_ticks_msec()
