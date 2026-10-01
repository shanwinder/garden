## plant_growth.gd
## Pure domain-rule namespace for deterministic plant growth stage calculation.
##
## Converts a valid PlantDefinition and elapsed seconds or PlantState runtime facts
## into a derived growth stage.
## Growth stage is derived data and is not persistent state.
##
## Architectural rules:
## - Belongs to the domain plants layer (src/domain/plants/).
## - Pure domain-rule namespace: extends RefCounted.
## - Stateless: no instance fields, no mutable state, no Node lifecycle, no Timer,
##   no _process, no signals.
## - Independent of GameClock, RandomSource, App, and filesystem.
## - Does not access system time; receives elapsed seconds or current time explicitly.
## - Negative elapsed seconds and rollback timestamps clamp to 0 (clock rollback safe).
## - O(1) evaluation time; no loop proportional to elapsed time.
## - Side-effect free: does not mutate PlantState or PlantDefinition or emit push_error().
class_name PlantGrowth
extends RefCounted

enum Stage {
	INVALID = -1,
	PLANTED = 0,
	SPROUT = 1,
	GROWING = 2,
	MATURE = 3,
}


## Derives the growth stage for a given [param definition] and [param elapsed_seconds].
## Pure query: side-effect free, deterministic, O(1) execution time.
## Returns Stage.INVALID if [param definition] is null or invalid.
## Clamps negative [param elapsed_seconds] to 0 without mutating state or emitting errors.
static func stage_for_elapsed_seconds(
	definition: PlantDefinition,
	elapsed_seconds: int
) -> Stage:
	if definition == null or not definition.is_valid():
		return Stage.INVALID

	var elapsed: int = elapsed_seconds
	if elapsed < 0:
		elapsed = 0

	if elapsed < definition.sprout_after_seconds:
		return Stage.PLANTED
	elif elapsed < definition.growing_after_seconds:
		return Stage.SPROUT
	elif elapsed < definition.mature_after_seconds:
		return Stage.GROWING
	else:
		return Stage.MATURE


## Derives the growth stage for a given [param state] and matching [param definition]
## at the explicit [param now_utc_seconds] timestamp.
## Pure query: side-effect free, deterministic, O(1) execution time.
## Returns Stage.INVALID if state or definition is null, invalid, or their definition IDs mismatch.
## If [param now_utc_seconds] <= state.get_planted_at(), elapsed is safely clamped to 0 without subtraction.
## Delegates threshold evaluation to [method stage_for_elapsed_seconds].
static func stage_for_state_at(
	state: PlantState,
	definition: PlantDefinition,
	now_utc_seconds: int
) -> Stage:
	if state == null or not state.is_valid():
		return Stage.INVALID

	if definition == null or not definition.is_valid():
		return Stage.INVALID

	if state.get_definition_id() != definition.id:
		return Stage.INVALID

	var planted_at: int = state.get_planted_at()
	var elapsed: int = 0
	if now_utc_seconds > planted_at:
		elapsed = now_utc_seconds - planted_at

	return stage_for_elapsed_seconds(definition, elapsed)
