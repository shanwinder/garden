## event_definition.gd
## Authored definition resource for ambient/special garden events.
##
## Establishes the static definition contract, eligibility requirements across
## environmental traits, plants, decorations, time-of-day periods, and weather states,
## plus relative selection weight for garden events (GAME_DESIGN.md Sections 12 & 24,
## ARCHITECTURE.md Sections 10, 11 & 16).
##
## Architectural rules:
## - Belongs to the domain events layer (src/domain/events/).
## - Authored content definition: extends Resource (not Node, Autoload, singleton, or manager).
## - Definition ID must conform to canonical StableContentId syntax and reside
##   in the "event." namespace.
## - Weight must be finite and strictly positive (> 0.0).
## - Required trait counts must map valid EnvironmentalTrait IDs to strictly positive integer counts (> 0).
## - Required plant IDs must be valid "plant." StableContentIds with no duplicates.
## - Required plant counts must map valid "plant." StableContentIds to strictly positive
##   integer counts (> 0); used by combination events such as "jasmine x3".
## - is_secret marks a rare combination event (GAME_DESIGN.md Section 12 "Secret combination
##   events") whose recipe must not be revealed by presentation clues.
## - Required decoration IDs must be valid "decoration." StableContentIds with no duplicates.
## - Allowed time periods must be valid GardenTimePeriod IDs with no duplicates (empty = any period).
## - Allowed weather states must be valid GardenWeather IDs with no duplicates (empty = any weather).
## - Minimum plant/decoration counts must be non-negative (>= 0).
## - Validation is deterministic and side-effect free (pure query, no mutation,
##   no normalization, no push_error, no clock or RNG access).
class_name EventDefinition
extends Resource

const EVENT_NAMESPACE_PREFIX: String = "event."

@export var id: String = ""
@export var name_key: String = ""
@export var description_key: String = ""
@export var weight: float = 0.0
@export var required_trait_counts: Dictionary = {}
@export var required_plant_ids: Array[String] = []
@export var required_decoration_ids: Array[String] = []
@export var allowed_time_periods: Array[String] = []
@export var allowed_weather_states: Array[String] = []
@export var min_total_plants: int = 0
@export var min_mature_plants: int = 0
@export var min_total_decorations: int = 0
@export var required_plant_counts: Dictionary = {}
@export var is_secret: bool = false


## Returns true if this event definition is structurally valid.
## Pure query: no mutation, no push_error, no clock/RNG/filesystem access.
func is_valid() -> bool:
	if not _is_valid_id(id):
		return false

	if not _is_valid_optional_key(name_key) or not _is_valid_optional_key(description_key):
		return false

	if not _is_valid_weight(weight):
		return false

	if min_total_plants < 0 or min_mature_plants < 0 or min_total_decorations < 0:
		return false

	if not _is_valid_required_trait_counts(required_trait_counts):
		return false

	if not _is_valid_required_plant_ids(required_plant_ids):
		return false

	if not _is_valid_required_plant_counts(required_plant_counts):
		return false

	if not _is_valid_required_decoration_ids(required_decoration_ids):
		return false

	if not GardenTimePeriod.is_valid_period_list(allowed_time_periods):
		return false

	if not GardenWeather.is_valid_weather_list(allowed_weather_states):
		return false

	return true


static func _is_valid_id(definition_id: String) -> bool:
	if not definition_id.begins_with(EVENT_NAMESPACE_PREFIX):
		return false
	return StableContentId.is_valid(definition_id)


static func _is_valid_weight(value: float) -> bool:
	return is_finite(value) and value > 0.0


static func _is_valid_required_trait_counts(traits_map: Dictionary) -> bool:
	for key: Variant in traits_map.keys():
		if typeof(key) != TYPE_STRING:
			return false
		var trait_id: String = key as String
		if not EnvironmentalTrait.is_valid(trait_id):
			return false
		var raw_count: Variant = traits_map[key]
		if typeof(raw_count) != TYPE_INT:
			return false
		var min_count: int = raw_count as int
		if min_count <= 0:
			return false
	return true


static func _is_valid_required_plant_ids(plant_ids: Array[String]) -> bool:
	var seen: Dictionary = {}
	for plant_id: String in plant_ids:
		if plant_id.is_empty():
			return false
		if not plant_id.begins_with(PlantDefinition.PLANT_NAMESPACE_PREFIX):
			return false
		if not StableContentId.is_valid(plant_id):
			return false
		if seen.has(plant_id):
			return false
		seen[plant_id] = true
	return true


static func _is_valid_required_plant_counts(counts_map: Dictionary) -> bool:
	for key: Variant in counts_map.keys():
		if typeof(key) != TYPE_STRING:
			return false
		var plant_id: String = key as String
		if not plant_id.begins_with(PlantDefinition.PLANT_NAMESPACE_PREFIX):
			return false
		if not StableContentId.is_valid(plant_id):
			return false
		var raw_count: Variant = counts_map[key]
		if typeof(raw_count) != TYPE_INT:
			return false
		if (raw_count as int) <= 0:
			return false
	return true


static func _is_valid_required_decoration_ids(decoration_ids: Array[String]) -> bool:
	var seen: Dictionary = {}
	for decor_id: String in decoration_ids:
		if decor_id.is_empty():
			return false
		if not decor_id.begins_with(DecorationDefinition.DECORATION_NAMESPACE_PREFIX):
			return false
		if not StableContentId.is_valid(decor_id):
			return false
		if seen.has(decor_id):
			return false
		seen[decor_id] = true
	return true


## Returns the explicit localization key for this event's name, or derives "<id>.name".
func get_effective_name_key() -> String:
	return name_key if not name_key.is_empty() else GardenLocalization.event_name_key(id)


## Returns the explicit localization key for this event's description, or derives "<id>.description".
func get_effective_description_key() -> String:
	return description_key if not description_key.is_empty() else GardenLocalization.event_description_key(id)


static func _is_valid_optional_key(key: String) -> bool:
	return key.is_empty() or GardenLocalization.is_valid_key(key)
