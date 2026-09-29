## godot_random_source.gd
## Production randomness adapter backed by Godot's RandomNumberGenerator.
##
## GodotRandomSource is the infrastructure boundary for all randomness in the
## Garden production application. It encapsulates one RandomNumberGenerator
## instance and exposes the RandomSource contract.
##
## Session semantics:
##   randomize() is called once at construction for non-deterministic
##   session-level randomness. No seed persistence, replay, or daily seed
##   is implemented at this stage; those require future gameplay decisions.
##
## Rules enforced:
##   - The owned RandomNumberGenerator is not exposed publicly.
##   - Global helpers randf(), randi(), randi_range() are never used.
##   - This class is not a Node, not an Autoload, not a Manager.
class_name GodotRandomSource
extends RandomSource

# 2^32 as a float constant for converting a 32-bit unsigned integer to [0.0, 1.0).
# Godot's RandomNumberGenerator.randi() returns values in [0, 4294967295] (unsigned).
# Dividing by 4294967296.0 produces a half-open result:
#   minimum: float(0) / 4294967296.0 == 0.0
#   maximum: float(4294967295) / 4294967296.0 < 1.0  (~0.9999999997671694)
const _UINT32_DOMAIN_SIZE: float = 4294967296.0

# One internal RNG instance per GodotRandomSource. Not exposed publicly.
var _rng: RandomNumberGenerator


func _init() -> void:
	_rng = RandomNumberGenerator.new()
	# randomize() seeds the generator from the OS entropy source, producing
	# non-deterministic session-level randomness appropriate for production use.
	_rng.randomize()


## Returns a uniformly distributed random float in [0.0, 1.0).
##
## Implementation:
##   Uses _rng.randi() which returns a 32-bit unsigned integer [0, 4294967295].
##   Dividing by 4294967296.0 produces a true half-open uniform distribution:
##     minimum result: 0.0         (when randi() == 0)
##     maximum result: < 1.0       (when randi() == 4294967295, result ≈ 0.9999999998)
##
## Note: RandomNumberGenerator.randf() is NOT used here because the Godot 4.7
##   documentation states randf() returns values in [0.0, 1.0] INCLUSIVE, which
##   would violate the half-open [0.0, 1.0) contract required by RandomSource.
##   Using randi() / 2^32 is the correct way to guarantee strict half-open range.
func next_float() -> float:
	return float(_rng.randi()) / _UINT32_DOMAIN_SIZE


## Returns a uniformly distributed random integer in [min_value, max_value]
## (both endpoints inclusive).
##
## For VALID input (min_value <= max_value):
##   Delegates to _rng.randi_range() and returns a value in [min_value, max_value].
##
## For INVALID input (min_value > max_value):
##   Emits push_error() with a diagnostic message.
##   Does NOT call the underlying RNG (no random value is consumed).
##   Returns min_value as a deterministic failure sentinel.
##   The fallback min_value is NOT a valid random result; it signals
##   a programming error that must be fixed by the caller.
func range_int(min_value: int, max_value: int) -> int:
	if min_value > max_value:
		push_error(
			"GodotRandomSource.range_int: min_value (%d) must be <= max_value (%d). "
			% [min_value, max_value]
			+ "Returning min_value as a deterministic error sentinel (no RNG consumed)."
		)
		return min_value
	return _rng.randi_range(min_value, max_value)
