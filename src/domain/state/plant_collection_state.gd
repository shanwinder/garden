## plant_collection_state.gd
## Authoritative domain state slice for Garden's plant collection.
##
## PlantCollectionState owns all player PlantState runtime instances.
## It is owned directly by GameState as a typed persistent state slice.
##
## Architectural rules:
## - Belongs to the domain state layer (src/domain/state/).
## - Pure domain object: extends RefCounted (not a Node, Resource, Autoload, singleton, or manager).
## - Constructable in isolation without SceneTree or engine lifecycle dependency.
## - Owned by GameState; non-global, non-singleton.
## - Encapsulates plant storage; does not expose internal Dictionary or mutable collection reference.
## - Enforces runtime instance-ID uniqueness across all stored PlantState objects.
## - Identity is Garden runtime instance_id (state.get_runtime_instance_id()), never Godot engine ObjectID.
## - Preserves exact PlantState references without cloning or modifying them.
## - Does not generate IDs, create plants, remove plants, or replace plants.
## - Stores runtime state facts only; does not calculate, derive, or cache growth stages or timestamps.
## - Independent of GameClock, RandomSource, App, FileAccess, ResourceLoader, and SceneTree.
class_name PlantCollectionState
extends RefCounted

var _plants_by_runtime_instance_id: Dictionary[String, PlantState] = {}


## Returns the number of PlantState instances in the collection.
func get_count() -> int:
	return _plants_by_runtime_instance_id.size()


## Returns true if a PlantState with the given [param runtime_instance_id] exists in the collection.
## Empty or missing IDs return false without emitting errors.
func has_runtime_instance_id(runtime_instance_id: String) -> bool:
	if runtime_instance_id.is_empty():
		return false
	return _plants_by_runtime_instance_id.has(runtime_instance_id)


## Returns the stored PlantState corresponding to [param runtime_instance_id], or null if not found.
## Empty or missing IDs return null without emitting errors.
func get_plant(runtime_instance_id: String) -> PlantState:
	if runtime_instance_id.is_empty():
		return null
	return _plants_by_runtime_instance_id.get(runtime_instance_id, null)


## Attempts to add [param state] to the collection.
##
## Validation:
## - [param state] must not be null.
## - [param state] must satisfy is_valid().
## - [param state] runtime instance ID must not already exist in the collection.
##
## Returns true and stores the exact PlantState reference on success.
## Returns false without modifying the collection on rejection.
## Does not emit push_error() as rejection is a normal validation outcome.
func try_add_plant(state: PlantState) -> bool:
	if state == null:
		return false

	if not state.is_valid():
		return false

	var instance_id: String = state.get_runtime_instance_id()
	if _plants_by_runtime_instance_id.has(instance_id):
		return false

	_plants_by_runtime_instance_id[instance_id] = state
	return true


## Returns all PlantState instances in the collection in deterministic ascending order
## of runtime instance ID.
##
## Architectural and persistence contract:
## - Returns a new Array[PlantState] instance; mutating the returned array does not mutate collection membership.
## - Contains the exact stored PlantState references (does not clone PlantState).
## - Empty collection returns an empty Array[PlantState].
## - Order is deterministic: sorted by runtime instance ID ascending.
## - Does not expose internal storage Dictionary.
## - No dependencies on SceneTree, FileAccess, GameClock, or RandomSource.
func get_all_plants() -> Array[PlantState]:
	var keys: Array = _plants_by_runtime_instance_id.keys()
	keys.sort()
	var result: Array[PlantState] = []
	for key: String in keys:
		result.append(_plants_by_runtime_instance_id[key])
	return result
