## environmental_trait.gd
## Canonical vocabulary and stateless validation primitive for environmental traits.
##
## Plants and decorations contribute environmental traits to the garden, which
## visitors and events query through GardenSnapshot.
##
## Architectural rules:
## - Belongs to the domain environment layer (src/domain/environment/).
## - Stateless validation primitive / namespace: extends RefCounted.
## - Contains no mutable state, no SceneTree/Node/Resource dependencies,
##   and no clock, RNG, or filesystem access.
## - Pure queries: returns false on invalid input without push_error or mutation.
class_name EnvironmentalTrait
extends RefCounted

const DENSE_VEGETATION: String = "dense_vegetation"
const FLOWER: String = "flower"
const FOOD: String = "food"
const FRUIT: String = "fruit"
const LIGHT: String = "light"
const PERCH: String = "perch"
const SHADE: String = "shade"
const SHELTER: String = "shelter"
const WATER: String = "water"

## Canonical list of all supported MVP environmental traits in deterministic ascending order.
const ALL_TRAITS: Array[String] = [
	DENSE_VEGETATION,
	FLOWER,
	FOOD,
	FRUIT,
	LIGHT,
	PERCH,
	SHADE,
	SHELTER,
	WATER,
]


## Returns true if [param trait_id] is a canonical known environmental trait.
## Pure query: exact match, no normalization, no push_error.
static func is_valid(trait_id: String) -> bool:
	if trait_id.is_empty():
		return false
	return ALL_TRAITS.has(trait_id)


## Returns true if every entry in [param traits] is a valid canonical environmental trait
## and the list contains no duplicate entries. An empty list is valid.
static func is_valid_trait_list(traits: Array[String]) -> bool:
	var seen: Dictionary = {}
	for trait_id: String in traits:
		if not is_valid(trait_id):
			return false
		if seen.has(trait_id):
			return false
		seen[trait_id] = true
	return true
