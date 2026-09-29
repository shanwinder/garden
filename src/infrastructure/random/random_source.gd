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
## Contract (valid input):
##   min_value <= max_value
##   min_value <= result <= max_value
##
## Contract (invalid reversed input):
##   Emits push_error() with a diagnostic message.
##   Returns a deterministic failure sentinel without consuming a random value.
##   Concrete classes must document their specific sentinel value.
@abstract
func range_int(_min_value: int, _max_value: int) -> int;


## Returns the index of a randomly selected entry, weighted proportionally.
##
## Contract (valid input):
##   - weights must not be empty
##   - every weight must be finite and >= 0.0
##   - total weight must be finite and > 0.0 (not all-zero)
##   - zero-weight entries can never be selected
##   - result is a valid index in [0, weights.size() - 1]
##   - selection probability is proportional to weight
##   - caller's array is never mutated
##
## Contract (invalid input):
##   Any of the following conditions is invalid:
##     - empty weights array
##     - any non-finite weight (NAN, INF, -INF)
##     - any negative weight
##     - total weight is zero or non-finite
##   On any invalid condition:
##     - push_error() is called with a diagnostic message
##     - returns -1 as an invalid-index sentinel
##     - next_float() is NOT called (no random value is consumed)
##   Callers must treat a result of -1 as a programming error sentinel
##   and must not use it as a valid selection index.
##
## Algorithm: conventional cumulative-weight walk using next_float().
## Because this is implemented once in the base class every concrete
## RandomSource automatically shares identical weighted-selection semantics.
func choose_weighted_index(weights: Array[float]) -> int:
	# ── Validation (runs in both debug and release builds) ─────────────────
	# Empty array.
	if weights.is_empty():
		push_error(
			"RandomSource.choose_weighted_index: weights array must not be empty. "
			+ "Returning -1 as an invalid-index sentinel (no RNG consumed)."
		)
		return -1

	# Validate all weights and accumulate total.
	var total: float = 0.0
	for w: float in weights:
		if not is_finite(w) or w < 0.0:
			push_error(
				"RandomSource.choose_weighted_index: each weight must be finite and "
				+ ">= 0.0, got %s. Returning -1 (no RNG consumed)." % w
			)
			return -1
		total += w

	# Total must be finite and positive (not all-zero, not corrupted by INF).
	if not is_finite(total) or total <= 0.0:
		push_error(
			"RandomSource.choose_weighted_index: total weight must be finite and "
			+ "> 0.0 (not all-zero), got %s. Returning -1 (no RNG consumed)." % total
		)
		return -1

	# ── Selection (only reached with fully validated weights) ───────────────
	# Scaled roll: next_float() is in [0.0, 1.0), so roll is in [0.0, total).
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

	# Floating-point robustness fallback.
	# Validation above guarantees at least one positive-weight entry exists,
	# so last_positive_index is always a valid index here.
	# This path is reached only if floating-point accumulation causes the
	# final cumulative to fall marginally short of total, which is extremely
	# rare but theoretically possible with many small weights.
	# With the corrected next_float() producing values in [0.0, 1.0),
	# roll is strictly < total, so this path is a robustness guard only.
	return last_positive_index
