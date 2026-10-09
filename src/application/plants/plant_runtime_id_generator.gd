## plant_runtime_id_generator.gd
## Collision-resistant runtime plant instance ID generator.
##
## Generates opaque, collision-resistant runtime plant instance IDs and verifies
## uniqueness against the current authoritative PlantCollectionState.
##
## Architectural rules:
## - Belongs to the application layer (src/application/plants/).
## - Pure application service: extends RefCounted.
## - Not a Node, Resource, Autoload, singleton, or global mutable manager.
## - Does not own GameState or PlantCollectionState.
## - No file I/O or persistence dependencies.
## - No wall-clock or timestamp dependencies.
## - No mutable static counter or state.
## - No global RNG, randomize(), randi(), or Godot Object instance ID access.
## - Format: plant-inst-<32 lowercase hexadecimal characters> (43 characters total).
## - Consumes exactly 4 integer draws from random_source.range_int(0, 2147483647) per candidate attempt.
## - Maximum 8 generation attempts before returning an empty String.
## - Does not mutate PlantCollectionState or insert plants.
## - Null dependencies return empty String without consuming RNG.
class_name PlantRuntimeIdGenerator
extends RefCounted

## Approved prefix for all newly generated runtime plant instance IDs.
const ID_PREFIX: String = "plant-inst-"

## Maximum number of candidate generation attempts before failing.
const MAX_ATTEMPTS: int = 8

## Upper bound for integer RNG draws (inclusive signed 32-bit positive integer max).
const RNG_MAX_INT: int = 2147483647


## Generates a candidate ID that is guaranteed not to be in [param collection] currently.
##
## Returns:
## - Non-empty String: candidate runtime ID not in collection.
## - Empty String: if collection or random_source is null, or if candidate generation
##   is exhausted after 8 colliding attempts.
static func try_generate_unique_id(
	collection: PlantCollectionState,
	random_source: RandomSource
) -> String:
	if collection == null or random_source == null:
		return ""

	for attempt: int in range(MAX_ATTEMPTS):
		var d1: int = random_source.range_int(0, RNG_MAX_INT)
		var d2: int = random_source.range_int(0, RNG_MAX_INT)
		var d3: int = random_source.range_int(0, RNG_MAX_INT)
		var d4: int = random_source.range_int(0, RNG_MAX_INT)

		var candidate: String = "%s%08x%08x%08x%08x" % [ID_PREFIX, d1, d2, d3, d4]

		if not collection.has_runtime_instance_id(candidate):
			return candidate

	return ""
