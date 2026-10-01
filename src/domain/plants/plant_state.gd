## plant_state.gd
## Authoritative runtime instance data representing one planted plant owned by the player.
##
## Establishes the minimum authoritative runtime facts:
## - instance_id: opaque runtime instance identity
## - definition_id: reference to PlantDefinition identity
## - planted_at: authoritative integer seconds timestamp (UTC/Unix)
##
## Architectural rules:
## - Belongs to the domain plants layer (src/domain/plants/).
## - Lightweight authoritative runtime data: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Requires no SceneTree.
## - Does not copy PlantDefinition fields (definition data vs runtime instance data separation).
## - Does not store a PlantDefinition Resource reference.
## - Does not store derived data (growth stage, elapsed seconds, ready status).
## - Does not store placement or harvest state yet (reserved for future explicit contracts).
## - Stores externally supplied facts exactly; does not normalize, lowercase, trim, or repair.
## - Does not generate instance IDs; uniqueness belongs to the authoritative plant collection.
## - Independent of GameClock, RandomSource, App, filesystem, and SceneTree.
## - Read-only public fact queries; no public setters.
## - Validation is a pure query: deterministic, side-effect free, no push_error().
class_name PlantState
extends RefCounted

var _instance_id: String
var _definition_id: String
var _planted_at: int


func _init(instance_id: String, definition_id: String, planted_at: int) -> void:
	_instance_id = instance_id
	_definition_id = definition_id
	_planted_at = planted_at


func get_runtime_instance_id() -> String:
	return _instance_id


func get_definition_id() -> String:
	return _definition_id


func get_planted_at() -> int:
	return _planted_at


## Returns true if this PlantState represents structurally valid runtime facts.
##
## Requirements:
## - instance_id is non-empty
## - definition_id belongs to the plant namespace and satisfies StableContentId syntax
## - planted_at >= 0
##
## Pure query: deterministic, side-effect free, no push_error, no clock or RNG access.
## Note: This validation cannot verify global uniqueness of instance_id; collection-level
## uniqueness enforcement belongs to future authoritative plant collection operations.
func is_valid() -> bool:
	if _instance_id.is_empty():
		return false

	if not _definition_id.begins_with(PlantDefinition.PLANT_NAMESPACE_PREFIX):
		return false

	if not StableContentId.is_valid(_definition_id):
		return false

	if _planted_at < 0:
		return false

	return true
