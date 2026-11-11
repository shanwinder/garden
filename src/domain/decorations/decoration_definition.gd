## decoration_definition.gd
## Authored definition resource for placeable garden decoration types.
##
## Establishes the static definition contract, coin price, and environmental trait
## contributions for decoration types. DecorationDefinition represents what a decoration
## type is (definition data), as distinct from a player's runtime placed instance
## (DecorationState).
##
## Architectural rules:
## - Belongs to the domain decorations layer (src/domain/decorations/).
## - Authored content definition: extends Resource (not Node, Autoload, singleton, or manager).
## - Does not represent runtime decoration instance state (no instance_id, placed_at, etc.).
## - Not owned by GameState or AppRoot; referenced by definition_id.
## - Definition ID must conform to canonical StableContentId syntax and reside
##   in the "decoration." namespace.
## - Price must be a non-negative integer (>= 0).
## - Environmental traits must satisfy EnvironmentalTrait.is_valid_trait_list().
## - Validation is deterministic and side-effect free (pure query, no mutation,
##   no normalization, no push_error, no clock or RNG access).
class_name DecorationDefinition
extends Resource

const DECORATION_NAMESPACE_PREFIX: String = "decoration."

@export var id: String = ""
@export var name_key: String = ""
@export var description_key: String = ""
@export var price: int = 0
@export var environmental_traits: Array[String] = []


## Returns true if this decoration definition is structurally valid.
## Pure query: no mutation, no push_error, no clock/RNG/filesystem access.
func is_valid() -> bool:
	if not _is_valid_id(id):
		return false

	if not _is_valid_optional_key(name_key) or not _is_valid_optional_key(description_key):
		return false

	if not _is_valid_price(price):
		return false

	if not EnvironmentalTrait.is_valid_trait_list(environmental_traits):
		return false

	return true


## Returns the explicit localization key for this decoration's name, or derives "<id>.name".
func get_effective_name_key() -> String:
	return name_key if not name_key.is_empty() else GardenLocalization.decoration_name_key(id)


## Returns the explicit localization key for this decoration's description, or derives "<id>.description".
func get_effective_description_key() -> String:
	return description_key if not description_key.is_empty() else GardenLocalization.decoration_description_key(id)


## Returns true if this decoration definition includes the exact [param trait_id].
func has_environmental_trait(trait_id: String) -> bool:
	if trait_id.is_empty():
		return false
	return environmental_traits.has(trait_id)


## Returns a defensive copy of this decoration definition's environmental traits.
func get_environmental_traits() -> Array[String]:
	return environmental_traits.duplicate()


static func _is_valid_id(definition_id: String) -> bool:
	if not definition_id.begins_with(DECORATION_NAMESPACE_PREFIX):
		return false

	return StableContentId.is_valid(definition_id)


static func _is_valid_price(value: int) -> bool:
	return value >= 0


static func _is_valid_optional_key(key: String) -> bool:
	return key.is_empty() or GardenLocalization.is_valid_key(key)
