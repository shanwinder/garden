## decoration_collection_state.gd
## Authoritative domain state slice for Garden's placed decoration collection.
##
## DecorationCollectionState owns all player DecorationState runtime instances.
## It is owned directly by GameState as a typed persistent state slice.
##
## Architectural rules:
## - Belongs to the domain state layer (src/domain/state/).
## - Pure domain object: extends RefCounted (not a Node, Resource, Autoload, singleton, or manager).
## - Constructable in isolation without SceneTree or engine lifecycle dependency.
## - Owned by GameState; non-global, non-singleton.
## - Encapsulates decoration storage; does not expose internal Dictionary or mutable collection reference.
## - Enforces runtime instance-ID uniqueness across all stored DecorationState objects.
## - Identity is Garden runtime instance_id (state.get_runtime_instance_id()), never Godot engine ObjectID.
## - Preserves exact DecorationState references without cloning or modifying them.
## - Independent of GameClock, RandomSource, App, FileAccess, ResourceLoader, and SceneTree.
class_name DecorationCollectionState
extends RefCounted

var _decorations_by_runtime_instance_id: Dictionary[String, DecorationState] = {}


## Returns the number of DecorationState instances in the collection.
func get_count() -> int:
	return _decorations_by_runtime_instance_id.size()


## Returns true if a DecorationState with the given [param runtime_instance_id] exists in the collection.
## Empty or missing IDs return false without emitting errors.
func has_runtime_instance_id(runtime_instance_id: String) -> bool:
	if runtime_instance_id.is_empty():
		return false
	return _decorations_by_runtime_instance_id.has(runtime_instance_id)


## Returns the stored DecorationState corresponding to [param runtime_instance_id], or null if not found.
## Empty or missing IDs return null without emitting errors.
func get_decoration(runtime_instance_id: String) -> DecorationState:
	if runtime_instance_id.is_empty():
		return null
	return _decorations_by_runtime_instance_id.get(runtime_instance_id, null)


## Attempts to add [param state] to the collection.
##
## Validation:
## - [param state] must not be null.
## - [param state] must satisfy is_valid().
## - [param state] runtime instance ID must not already exist in the collection.
##
## Returns true and stores the exact DecorationState reference on success.
## Returns false without modifying the collection on rejection.
## Does not emit push_error() as rejection is a normal validation outcome.
func try_add_decoration(state: DecorationState) -> bool:
	if state == null:
		return false

	if not state.is_valid():
		return false

	var instance_id: String = state.get_runtime_instance_id()
	if _decorations_by_runtime_instance_id.has(instance_id):
		return false

	_decorations_by_runtime_instance_id[instance_id] = state
	return true


## Returns all DecorationState instances in the collection in deterministic ascending order
## of runtime instance ID.
##
## Architectural and persistence contract:
## - Returns a new Array[DecorationState] instance; mutating the returned array does not mutate collection membership.
## - Contains the exact stored DecorationState references (does not clone DecorationState).
## - Empty collection returns an empty Array[DecorationState].
## - Order is deterministic: sorted by runtime instance ID ascending.
## - Does not expose internal storage Dictionary.
func get_all_decorations() -> Array[DecorationState]:
	var keys: Array = _decorations_by_runtime_instance_id.keys()
	keys.sort()
	var result: Array[DecorationState] = []
	for key: String in keys:
		result.append(_decorations_by_runtime_instance_id[key])
	return result
