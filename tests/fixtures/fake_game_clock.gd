## fake_game_clock.gd
## Deterministic test double for GameClock.
##
## FakeGameClock implements the GameClock contract with fully controllable,
## in-memory state. It exists ONLY for deterministic tests and must never be
## used in production code or registered as an Autoload.
##
## API surface is intentionally minimal: only what test scenarios require.
## No scheduling, callbacks, timers, pause logic, calendars, time zones, or
## event queues are provided.
##
## Typical test usage:
##   var clock := FakeGameClock.new(1_000_000, 0)
##   assert clock.utc_now_seconds() == 1_000_000
##   clock.advance_utc_seconds(60)
##   assert clock.utc_now_seconds() == 1_000_060
##   clock.set_utc_seconds(999_999)   # simulate rollback
##   assert clock.utc_now_seconds() == 999_999
class_name FakeGameClock
extends GameClock


var _utc_seconds: int
var _monotonic_ms: int


## Constructs a FakeGameClock with explicit initial values.
##
## Parameters:
##   initial_utc_seconds    — the UTC epoch value utc_now_seconds() will return
##   initial_monotonic_ms   — the value monotonic_milliseconds() will return
func _init(initial_utc_seconds: int, initial_monotonic_ms: int) -> void:
	_utc_seconds = initial_utc_seconds
	_monotonic_ms = initial_monotonic_ms


## Returns the current controlled UTC seconds value.
func utc_now_seconds() -> int:
	return _utc_seconds


## Returns the current controlled monotonic milliseconds value.
func monotonic_milliseconds() -> int:
	return _monotonic_ms


## Moves UTC time forward by the given number of seconds.
## delta must be non-negative; use set_utc_seconds() for backward movement.
func advance_utc_seconds(delta: int) -> void:
	assert(
		delta >= 0,
		"advance_utc_seconds delta must be non-negative; use set_utc_seconds() for rollback"
	)
	_utc_seconds += delta


## Moves monotonic time forward by the given number of milliseconds.
## delta must be non-negative; monotonic time does not move backward.
func advance_monotonic_ms(delta: int) -> void:
	assert(
		delta >= 0,
		"advance_monotonic_ms delta must be non-negative; monotonic time cannot move backward"
	)
	_monotonic_ms += delta


## Sets the UTC seconds to an explicit value.
##
## Accepts any integer, including values lower than the current one, so that
## tests can simulate device-clock rollback scenarios deterministically.
func set_utc_seconds(value: int) -> void:
	_utc_seconds = value
