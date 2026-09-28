## random_source.gd
## Abstract randomness contract for Garden's infrastructure layer.
##
## RandomSource defines the typed interface that all randomness implementations
## must satisfy. Production code uses GodotRandomSource; deterministic tests
## use FakeRandomSource injected by the test harness.
##
## This type is NOT a Node. It must not enter the SceneTree, must not become
## an Autoload, and must not hold mutable game state beyond the RNG itself.
## It is a pure infrastructure abstraction.
##
## Dependency direction:
##   AppRoot (composition root) constructs a concrete implementation and
##   exposes it as random_source: RandomSource. Application/domain code
##   receives random values as arguments rather than calling App.random_source
##   directly throughout domain logic.
##
## Weighted selection:
##   choose_weighted_index() is implemented once here using next_float() so
##   every concrete RandomSource shares the exact same weighted-selection rules.
##   Do NOT duplicate the cumulative-weight algorithm in subclasses.
@abstract
class_name RandomSource
extends RefCounted


## Returns a uniformly distributed random float in the half-open interval
## [0.0, 1.0).
##
## Contract:
##   0.0 <= result < 1.0
##
## Must not require SceneTree ownership.
## Must not read or modify global mutable gameplay state.
@abstract
func next_float() -> float;


## Returns a uniformly distributed random integer in the inclusive range
## [min_value, max_value].
##
## Contract:
##   min_value <= max_value  (reversed ranges must fail loudly)
##   min_value <= result <= max_value
##
## Invalid reversed ranges must assert/push_error rather than silently
## swapping the bounds.
@abstract
func range_int(_min_value: int, _max_value: int) -> int;


## Returns the index of a randomly selected entry, weighted proportionally.
##
## Contract:
##   - weights must not be empty
##   - every weight must be >= 0.0
##   - total weight must be > 0.0  (not all-zero)
##   - zero-weight entries can never be selected
##   - result is a valid index in [0, weights.size() - 1]
##   - selection probability is proportional to weight
##   - caller's array is never mutated
##
## Algorithm: conventional cumulative-weight walk using next_float().
## Because this is implemented once in the base class every concrete
## RandomSource automatically shares identical weighted-selection semantics.
func choose_weighted_index(weights: Array[float]) -> int:
	assert(
		not weights.is_empty(),
		"RandomSource.choose_weighted_index: weights array must not be empty"
	)

	# Validate all weights and compute total.
	var total: float = 0.0
	for w: float in weights:
		assert(
			w >= 0.0,
			"RandomSource.choose_weighted_index: all weights must be >= 0.0, got %s" % w
		)
		total += w

	assert(
		total > 0.0,
		"RandomSource.choose_weighted_index: total weight must be > 0.0 (not all-zero)"
	)

	# Scaled roll: a value in [0.0, total).
	var roll: float = next_float() * total

	# Cumulative walk: return first index where roll < cumulative sum.
	var cumulative: float = 0.0
	var last_positive_index: int = -1

	for i: int in range(weights.size()):
		var w: float = weights[i]
		if w <= 0.0:
			# Skip zero-weight entries; they cannot be selected.
			continue
		last_positive_index = i
		cumulative += w
		if roll < cumulative:
			return i

	# Floating-point robustness fallback: if roll landed exactly on the
	# boundary of the final positive-weight interval (e.g. next_float()
	# returned a value very close to 1.0), return the last positive index.
	# This situation should be rare; the assert above guarantees at least
	# one positive-weight entry exists.
	assert(
		last_positive_index >= 0,
		"RandomSource.choose_weighted_index: internal error — no positive weight found"
	)
	return last_positive_index
