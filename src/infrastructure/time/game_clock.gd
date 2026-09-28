## game_clock.gd
## Abstract clock contract for Garden's time infrastructure.
##
## GameClock defines the typed interface that all clock implementations must
## satisfy. Production code uses SystemGameClock; deterministic tests use
## FakeGameClock injected by the test harness.
##
## This type is NOT a Node. It must not enter the SceneTree, must not become
## an Autoload, and must not hold mutable game state. It is a pure
## infrastructure abstraction.
##
## Dependency direction:
##   AppRoot (composition root) constructs a concrete implementation and
##   exposes it as game_clock: GameClock. Application/domain code receives
##   the current time as an argument (now: int) rather than reading the clock
##   directly.
@abstract
class_name GameClock
extends RefCounted


## Returns the current UTC Unix epoch time as integer seconds.
##
## Implementations must return the wall-clock UTC time with no timezone offset
## applied. This value is suitable for persistent timestamps such as planted_at
## and last_harvest_at. It is NOT guaranteed to be monotonic: a device clock
## may move backward. Callers that compute elapsed time must clamp negative
## values to zero rather than allowing negative elapsed time to corrupt state.
@abstract
func utc_now_seconds() -> int;


## Returns a monotonic process-time measurement in integer milliseconds.
##
## This value is suitable for measuring elapsed runtime intervals within a
## single application session (e.g., UI animation timing, short-lived
## cooldowns). It is NOT a persistent wall-clock timestamp:
##   - it is not guaranteed to represent any particular calendar time;
##   - it must NOT be serialized as an authoritative cross-session timestamp;
##   - its zero point is undefined and may differ between sessions.
## Use utc_now_seconds() for all values that must survive process termination.
@abstract
func monotonic_milliseconds() -> int;
