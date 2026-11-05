## garden_snapshot.gd
## Immutable domain query model summarizing current garden environmental conditions.
##
## Visitor and event eligibility rules query GardenSnapshot rather than inspecting
## presentation scene nodes or mutating authoritative GameState.
##
## Architectural rules:
## - Belongs to the domain environment layer (src/domain/environment/).
## - Immutable value/query object: extends RefCounted.
## - Does not depend on SceneTree, Node, Autoload, GameClock, RandomSource, or filesystem.
## - Defensively copies input dictionaries at construction so caller mutations
##   after construction cannot alter the snapshot.
## - Returns defensive copies for all array queries.
class_name GardenSnapshot
extends RefCounted

var _trait_counts: Dictionary = {}
var _sorted_active_traits: Array[String] = []
var _plant_counts_by_id: Dictionary = {}
var _sorted_plant_ids: Array[String] = []
var _total_plant_count: int = 0
var _mature_plant_count: int = 0


func _init(
	trait_counts: Dictionary = {},
	plant_counts_by_id: Dictionary = {},
	total_plant_count: int = 0,
	mature_plant_count: int = 0
) -> void:
	_trait_counts = {}
	_sorted_active_traits = []
	for key: Variant in trait_counts.keys():
		if typeof(key) == TYPE_STRING:
			var trait_id: String = key as String
			var raw_count: Variant = trait_counts[key]
			if EnvironmentalTrait.is_valid(trait_id) and typeof(raw_count) == TYPE_INT:
				var count: int = raw_count as int
				if count > 0:
					_trait_counts[trait_id] = count
					_sorted_active_traits.append(trait_id)
	_sorted_active_traits.sort()

	_plant_counts_by_id = {}
	_sorted_plant_ids = []
	for key: Variant in plant_counts_by_id.keys():
		if typeof(key) == TYPE_STRING:
			var def_id: String = key as String
			var raw_count: Variant = plant_counts_by_id[key]
			if not def_id.is_empty() and typeof(raw_count) == TYPE_INT:
				var count: int = raw_count as int
				if count > 0:
					_plant_counts_by_id[def_id] = count
					_sorted_plant_ids.append(def_id)
	_sorted_plant_ids.sort()

	_total_plant_count = maxi(0, total_plant_count)
	_mature_plant_count = clampi(mature_plant_count, 0, _total_plant_count)


## Returns the total count for [param trait_id], or 0 if absent or unknown.
func get_trait_count(trait_id: String) -> int:
	if not _trait_counts.has(trait_id):
		return 0
	return _trait_counts[trait_id] as int


## Returns true if [param min_count] > 0 and get_trait_count(trait_id) >= min_count.
func has_trait(trait_id: String, min_count: int = 1) -> bool:
	if min_count <= 0:
		return false
	return get_trait_count(trait_id) >= min_count


## Returns a new sorted Array[String] of all environmental traits with count > 0.
func get_active_traits() -> Array[String]:
	return _sorted_active_traits.duplicate()


## Returns the number of planted instances for [param definition_id], or 0 if none.
func get_plant_count_for_definition(definition_id: String) -> int:
	if not _plant_counts_by_id.has(definition_id):
		return 0
	return _plant_counts_by_id[definition_id] as int


## Returns a new sorted Array[String] of all plant definition IDs present in the snapshot.
func get_present_plant_definition_ids() -> Array[String]:
	return _sorted_plant_ids.duplicate()


## Returns the total number of valid plants in the garden snapshot.
func get_total_plant_count() -> int:
	return _total_plant_count


## Returns the number of mature plants in the garden snapshot.
func get_mature_plant_count() -> int:
	return _mature_plant_count


## Returns true if the garden contains zero plants.
func is_empty_garden() -> bool:
	return _total_plant_count == 0
