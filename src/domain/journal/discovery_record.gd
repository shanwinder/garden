## discovery_record.gd
## Immutable domain value object representing a single discovered content entry in the Garden Journal.
##
## Establishes the persistent discovery facts for a content definition:
## - definition_id: canonical StableContentId in "plant." or "visitor." namespace
## - first_seen_at: authoritative integer UTC seconds timestamp (>= 0) when first discovered
## - times_seen: authoritative positive integer sighting count (>= 1)
##
## Architectural rules:
## - Belongs to the domain journal layer (src/domain/journal/).
## - Pure domain value object: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Immutable after construction: read-only getters, no public setters.
## - Stores only persistent discovery facts; does not store localized display names or descriptions.
## - Independent of SceneTree, GameClock, RandomSource, ContentCatalog, and filesystem.
## - Validation is a pure query: deterministic, side-effect free, no push_error().
class_name DiscoveryRecord
extends RefCounted

const PLANT_NAMESPACE_PREFIX: String = "plant."
const VISITOR_NAMESPACE_PREFIX: String = "visitor."
const MAX_INT64: int = 9223372036854775807

var _definition_id: String
var _first_seen_at: int
var _times_seen: int


func _init(definition_id: String, first_seen_at: int, times_seen: int = 1) -> void:
	_definition_id = definition_id
	_first_seen_at = first_seen_at
	_times_seen = times_seen


## Returns the canonical definition ID of the discovered content.
func get_definition_id() -> String:
	return _definition_id


## Returns the UTC seconds timestamp when this content was first discovered.
func get_first_seen_at() -> int:
	return _first_seen_at


## Returns the total number of times this content has been discovered/sighted.
func get_times_seen() -> int:
	return _times_seen


## Returns true if this record belongs to the "plant." namespace.
func is_plant_discovery() -> bool:
	return _definition_id.begins_with(PLANT_NAMESPACE_PREFIX)


## Returns true if this record belongs to the "visitor." namespace.
func is_visitor_discovery() -> bool:
	return _definition_id.begins_with(VISITOR_NAMESPACE_PREFIX)


## Returns true if [param definition_id] is a syntactically valid StableContentId
## in a discoverable namespace ("plant." or "visitor.").
static func is_supported_discovery_id(definition_id: String) -> bool:
	if definition_id.is_empty():
		return false
	if (
		not definition_id.begins_with(PLANT_NAMESPACE_PREFIX)
		and not definition_id.begins_with(VISITOR_NAMESPACE_PREFIX)
	):
		return false
	return StableContentId.is_valid(definition_id)


## Returns true if this DiscoveryRecord represents structurally valid persistent facts.
##
## Requirements:
## - definition_id satisfies is_supported_discovery_id()
## - first_seen_at >= 0
## - times_seen >= 1
func is_valid() -> bool:
	if not is_supported_discovery_id(_definition_id):
		return false

	if _first_seen_at < 0:
		return false

	if _times_seen < 1:
		return false

	return true


## Returns a new DiscoveryRecord with times_seen incremented by 1 while preserving
## the original first_seen_at timestamp (idempotent first-discovery timestamp).
## Returns null if this record is invalid, seen_at_utc < 0, or times_seen would overflow MAX_INT64.
func with_additional_sighting(seen_at_utc: int) -> DiscoveryRecord:
	if not is_valid():
		return null
	if seen_at_utc < 0:
		return null
	if _times_seen >= MAX_INT64:
		return null
	return DiscoveryRecord.new(_definition_id, _first_seen_at, _times_seen + 1)
