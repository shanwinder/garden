## daily_guidance_item.gd
## Immutable domain value object representing a single lightweight daily suggestion.
##
## Captures an optional, non-punitive daily activity suggestion per GAME_DESIGN.md Section 20
## ("What could we do today? / วันนี้ทำอะไรดี") and ARCHITECTURE.md:
## - id: stable identifier in "daily_guidance." namespace
## - category: functional category ("harvest", "planting", "visitor", "event", "decoration", "environment", "journal")
## - target_count: positive integer suggestion magnitude (>= 1)
## - display_text: friendly localized Thai suggestion text
##
## Architectural rules:
## - Belongs to the domain progression layer (src/domain/progression/).
## - Pure domain value object: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Immutable after construction: read-only getters, no public setters.
## - Independent of SceneTree, GameClock, RandomSource, ContentCatalog, and filesystem.
## - Deterministic and side-effect free.
class_name DailyGuidanceItem
extends RefCounted

const GUIDANCE_NAMESPACE_PREFIX: String = "daily_guidance."

var _id: String
var _category: String
var _target_count: int
var _display_text: String


func _init(
	id: String,
	category: String,
	target_count: int,
	display_text: String
) -> void:
	_id = id
	_category = category
	_target_count = maxi(1, target_count)
	_display_text = display_text


## Returns the canonical identifier of this daily suggestion.
func get_id() -> String:
	return _id


## Returns the functional category of this suggestion.
func get_category() -> String:
	return _category


## Returns the positive target count for this suggestion (e.g. 3 harvests, 1 flower).
func get_target_count() -> int:
	return _target_count


## Returns the localized Thai presentation text.
func get_display_text() -> String:
	return _display_text


## Returns true if all fields satisfy domain invariants.
func is_valid() -> bool:
	if not _id.begins_with(GUIDANCE_NAMESPACE_PREFIX):
		return false
	if _category.is_empty():
		return false
	if _target_count < 1:
		return false
	if _display_text.is_empty():
		return false
	return true
