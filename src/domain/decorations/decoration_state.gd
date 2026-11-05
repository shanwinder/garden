## decoration_state.gd
## Authoritative runtime instance data representing one placed decoration owned by the player.
##
## Establishes the minimum authoritative runtime facts:
## - instance_id: opaque runtime instance identity
## - definition_id: reference to DecorationDefinition identity
## - placed_at: authoritative integer seconds timestamp (UTC/Unix)
##
## Architectural rules:
## - Belongs to the domain decorations layer (src/domain/decorations/).
## - Lightweight authoritative runtime data: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Requires no SceneTree.
## - Does not copy DecorationDefinition fields (definition data vs runtime instance data separation).
## - Does not store a DecorationDefinition Resource reference.
## - Stores externally supplied facts exactly; does not normalize, lowercase, trim, or repair.
## - Does not generate instance IDs; uniqueness belongs to the authoritative decoration collection.
## - Independent of GameClock, RandomSource, App, filesystem, and SceneTree.
## - Read-only public fact queries; no public setters.
## - Validation is a pure query: deterministic, side-effect free, no push_error().
class_name DecorationState
extends RefCounted

var _instance_id: String
var _definition_id: String
var _placed_at: int


func _init(instance_id: String, definition_id: String, placed_at: int) -> void:
	_instance_id = instance_id
	_definition_id = definition_id
	_placed_at = placed_at


func get_runtime_instance_id() -> String:
	return _instance_id


func get_definition_id() -> String:
	return _definition_id


func get_placed_at() -> int:
	return _placed_at


## Returns true if this DecorationState represents structurally valid runtime facts.
##
## Requirements:
## - instance_id is non-empty
## - definition_id belongs to the "decoration." namespace and satisfies StableContentId syntax
## - placed_at >= 0
##
## Pure query: deterministic, side-effect free, no push_error, no clock or RNG access.
func is_valid() -> bool:
	if _instance_id.is_empty():
		return false

	if not _definition_id.begins_with(DecorationDefinition.DECORATION_NAMESPACE_PREFIX):
		return false

	if not StableContentId.is_valid(_definition_id):
		return false

	if _placed_at < 0:
		return false

	return true
