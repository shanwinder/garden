## garden_progression_summary.gd
## Immutable domain value object representing the derived establishment stage,
## score, next-stage progress, gentle guidance, and daily guidance suggestions for a garden snapshot.
##
## Architectural rules:
## - Belongs to the domain progression layer (src/domain/progression/).
## - Pure domain value object: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Immutable after construction: read-only getters, no public setters.
## - Independent of SceneTree, GameClock, RandomSource, ContentCatalog, and filesystem.
class_name GardenProgressionSummary
extends RefCounted

var _stage_id: String
var _stage_index: int
var _establishment_score: int
var _next_stage_id: String
var _next_stage_threshold: int
var _points_to_next_stage: int
var _guidance_id: String
var _daily_guidance_items: Array[DailyGuidanceItem]
var _ftue_step: FtueStep = null


func _init(
	stage_id: String,
	stage_index: int,
	establishment_score: int,
	next_stage_id: String,
	next_stage_threshold: int,
	points_to_next_stage: int,
	guidance_id: String,
	daily_guidance_items: Array[DailyGuidanceItem] = [],
	ftue_step: FtueStep = null
) -> void:
	_stage_id = stage_id
	_stage_index = stage_index
	_establishment_score = maxi(0, establishment_score)
	_next_stage_id = next_stage_id
	_next_stage_threshold = maxi(0, next_stage_threshold)
	_points_to_next_stage = maxi(0, points_to_next_stage)
	_guidance_id = guidance_id
	_daily_guidance_items = []
	for item: DailyGuidanceItem in daily_guidance_items:
		if item != null and item.is_valid():
			_daily_guidance_items.append(item)
	if ftue_step != null and ftue_step.is_valid():
		_ftue_step = ftue_step
	else:
		_ftue_step = null


## Returns the canonical garden progression stage ID.
func get_stage_id() -> String:
	return _stage_id


## Returns the zero-based progression stage index (0..4).
func get_stage_index() -> int:
	return _stage_index


## Returns the non-negative establishment score derived from garden state.
func get_establishment_score() -> int:
	return _establishment_score


## Returns the canonical ID of the next progression stage, or "" if at max stage.
func get_next_stage_id() -> String:
	return _next_stage_id


## Returns the score threshold of the next progression stage, or 0 if at max stage.
func get_next_stage_threshold() -> int:
	return _next_stage_threshold


## Returns the remaining establishment points needed to reach the next stage, or 0 if at max stage.
func get_points_to_next_stage() -> int:
	return _points_to_next_stage


## Returns true if the garden has reached the highest establishment stage ("happy_garden_home").
func is_max_stage() -> bool:
	return _next_stage_id.is_empty()


## Returns the canonical gentle guidance ID ("What could we do today? / วันนี้ทำอะไรดี").
func get_guidance_id() -> String:
	return _guidance_id


## Returns a duplicated array of the three daily guidance suggestion items.
func get_daily_guidance_items() -> Array[DailyGuidanceItem]:
	return _daily_guidance_items.duplicate()


## Returns array of canonical IDs for the daily guidance items.
func get_daily_guidance_ids() -> Array[String]:
	var ids: Array[String] = []
	for item: DailyGuidanceItem in _daily_guidance_items:
		ids.append(item.get_id())
	return ids


## Returns the count of daily guidance suggestion items.
func get_daily_guidance_count() -> int:
	return _daily_guidance_items.size()


## Returns true if daily guidance suggestions are present.
func has_daily_guidance() -> bool:
	return not _daily_guidance_items.is_empty()


## Returns the FtueStep value object, or null if not set.
func get_ftue_step() -> FtueStep:
	return _ftue_step


## Returns true if an FTUE step is attached.
func has_ftue_step() -> bool:
	return _ftue_step != null and _ftue_step.is_valid()


## Returns the canonical FTUE step ID, or empty string if not attached.
func get_ftue_step_id() -> String:
	return _ftue_step.get_step_id() if _ftue_step != null else ""


## Returns the zero-based FTUE step index (0..6), or -1 if not attached.
func get_ftue_step_index() -> int:
	return _ftue_step.get_step_index() if _ftue_step != null else -1


## Returns the localized FTUE title, or empty string if not attached.
func get_ftue_title() -> String:
	return _ftue_step.get_title() if _ftue_step != null else ""


## Returns the localized FTUE action instruction, or empty string if not attached.
func get_ftue_instruction() -> String:
	return _ftue_step.get_instruction() if _ftue_step != null else ""


## Returns true if FTUE is active (not completed).
func is_ftue_active() -> bool:
	return _ftue_step != null and _ftue_step.is_active()


## Returns true if FTUE has reached completion.
func is_ftue_completed() -> bool:
	return _ftue_step != null and _ftue_step.is_completed()


## Returns true if all fields satisfy domain invariants.
func is_valid() -> bool:
	if not GardenProgressionStage.is_valid_stage(_stage_id):
		return false
	if _stage_index != GardenProgressionStage.stage_index(_stage_id):
		return false
	if _establishment_score < 0:
		return false
	if not _next_stage_id.is_empty() and not GardenProgressionStage.is_valid_stage(_next_stage_id):
		return false
	if _next_stage_threshold < 0 or _points_to_next_stage < 0:
		return false
	if not GardenProgressionStage.is_valid_guidance_id(_guidance_id):
		return false
	for item: DailyGuidanceItem in _daily_guidance_items:
		if item == null or not item.is_valid():
			return false
	if _ftue_step != null and not _ftue_step.is_valid():
		return false
	return true
