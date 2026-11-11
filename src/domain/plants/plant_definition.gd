## plant_definition.gd
## Authored definition resource for plant types.
##
## Establishes the static definition contract and deterministic growth thresholds
## for plant types. PlantDefinition represents what a plant type is (definition data),
## as distinct from a player's runtime planted instance (runtime instance data).
##
## Architectural rules:
## - Belongs to the domain plants layer (src/domain/plants/).
## - Authored content definition: extends Resource (not Node, Autoload, singleton, or manager).
## - Does not represent runtime plant instance state (no instance_id, planted_at, etc.).
## - Not owned by GameState or AppRoot; referenced by definition_id.
## - Growth thresholds are cumulative elapsed-time seconds from planted_at.
## - Definition ID must conform to canonical StableContentId syntax and reside
##   in the "plant." namespace.
## - Validation is deterministic and side-effect free (pure query, no mutation,
##   no normalization, no push_error, no clock or RNG access).
class_name PlantDefinition
extends Resource

const PLANT_NAMESPACE_PREFIX: String = "plant."

@export var id: String = ""
@export var name_key: String = ""
@export var description_key: String = ""
@export var sprout_after_seconds: int = 0
@export var growing_after_seconds: int = 0
@export var mature_after_seconds: int = 0
@export var harvest_reward: int = 0
@export var environmental_traits: Array[String] = []


## Returns true if this definition is structurally valid.
## Pure query: no mutation, no push_error, no clock/RNG/filesystem access.
func is_valid() -> bool:
	if not _is_valid_id(id):
		return false

	if not _is_valid_optional_key(name_key) or not _is_valid_optional_key(description_key):
		return false

	if not _is_valid_growth_thresholds(
		sprout_after_seconds, growing_after_seconds, mature_after_seconds
	):
		return false

	if not _is_valid_harvest_reward(harvest_reward):
		return false

	if not EnvironmentalTrait.is_valid_trait_list(environmental_traits):
		return false

	return true


## Returns the explicit localization key for this plant's name, or derives "<id>.name".
func get_effective_name_key() -> String:
	return name_key if not name_key.is_empty() else GardenLocalization.plant_name_key(id)


## Returns the explicit localization key for this plant's description, or derives "<id>.description".
func get_effective_description_key() -> String:
	return description_key if not description_key.is_empty() else GardenLocalization.plant_description_key(id)


## Returns true if this plant definition includes the exact [param trait_id].
func has_environmental_trait(trait_id: String) -> bool:
	if trait_id.is_empty():
		return false
	return environmental_traits.has(trait_id)


## Returns a defensive copy of this plant definition's environmental traits.
func get_environmental_traits() -> Array[String]:
	return environmental_traits.duplicate()


static func _is_valid_id(definition_id: String) -> bool:
	if not definition_id.begins_with(PLANT_NAMESPACE_PREFIX):
		return false

	return StableContentId.is_valid(definition_id)


static func _is_valid_growth_thresholds(sprout: int, growing: int, mature: int) -> bool:
	if sprout <= 0:
		return false

	if growing <= sprout:
		return false

	if mature <= growing:
		return false

	return true


static func _is_valid_harvest_reward(reward: int) -> bool:
	return reward >= 0


static func _is_valid_optional_key(key: String) -> bool:
	return key.is_empty() or GardenLocalization.is_valid_key(key)
