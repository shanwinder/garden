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

# One internal RNG instance per GodotRandomSource. Not exposed publicly.
var _rng: RandomNumberGenerator


func _init() -> void:
	_rng = RandomNumberGenerator.new()
	# randomize() seeds the generator from the OS entropy source, producing
	# non-deterministic session-level randomness appropriate for production use.
	_rng.randomize()


## Returns a uniformly distributed random float in [0.0, 1.0).
##
## Delegates to RandomNumberGenerator.randf() which returns values in
## [0.0, 1.0) per Godot 4 documentation.
func next_float() -> float:
	return _rng.randf()


## Returns a uniformly distributed random integer in [min_value, max_value]
## (both endpoints inclusive).
##
## Fails loudly if min_value > max_value rather than silently swapping bounds.
## Delegates to RandomNumberGenerator.randi_range() for the actual generation.
func range_int(min_value: int, max_value: int) -> int:
	assert(
		min_value <= max_value,
		(
			"GodotRandomSource.range_int: min_value (%d) must be <= max_value (%d)"
			% [min_value, max_value]
		)
	)
	return _rng.randi_range(min_value, max_value)
