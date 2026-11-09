## ftue_step.gd
## Immutable domain value object representing a step in the First-Time User Experience (FTUE)
## sequence per GAME_DESIGN.md Section 21.
##
## Architectural rules:
## - Belongs to the domain progression layer (src/domain/progression/).
## - Pure domain value object: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Immutable after construction: read-only getters, no public setters.
## - Deterministic, stateless, and side-effect free.
## - Independent of SceneTree, GameClock, RandomSource, ContentCatalog, and filesystem.
class_name FtueStep
extends RefCounted

const STEP_SEE_GARDEN: String = "ftue.see_garden"
const STEP_WATCH_GROWTH: String = "ftue.watch_growth"
const STEP_HARVEST_PLANT: String = "ftue.harvest_plant"
const STEP_PLACE_DECORATION: String = "ftue.place_decoration"
const STEP_OBSERVE_VISITOR: String = "ftue.observe_visitor"
const STEP_CHECK_JOURNAL: String = "ftue.check_journal"
const STEP_COMPLETED: String = "ftue.completed"

const ALL_STEPS: Array[String] = [
	STEP_SEE_GARDEN,
	STEP_WATCH_GROWTH,
	STEP_HARVEST_PLANT,
	STEP_PLACE_DECORATION,
	STEP_OBSERVE_VISITOR,
	STEP_CHECK_JOURNAL,
	STEP_COMPLETED,
]

var _step_id: String
var _step_index: int
var _title: String
var _instruction: String


func _init(step_id: String, step_index: int, title: String, instruction: String) -> void:
	_step_id = step_id
	_step_index = step_index
	_title = title
	_instruction = instruction


## Returns true if [param step_id] is one of the canonical FTUE step identifiers.
static func is_valid_step_id(step_id: String) -> bool:
	return ALL_STEPS.has(step_id)


## Returns the canonical step index (0..6) for [param step_id], or -1 if invalid.
static func step_index_for_id(step_id: String) -> int:
	return ALL_STEPS.find(step_id)


## Returns the canonical FTUE step ID.
func get_step_id() -> String:
	return _step_id


## Returns the zero-based step index (0..6).
func get_step_index() -> int:
	return _step_index


## Returns the localized title of this FTUE step.
func get_title() -> String:
	return _title


## Returns the localized instruction / action hint for this FTUE step.
func get_instruction() -> String:
	return _instruction


## Returns true if the FTUE sequence has reached completion.
func is_completed() -> bool:
	return _step_id == STEP_COMPLETED


## Returns true if FTUE is actively guiding the player (not completed).
func is_active() -> bool:
	return not is_completed() and is_valid()


## Returns true if this FtueStep satisfies domain invariants.
func is_valid() -> bool:
	if not is_valid_step_id(_step_id):
		return false
	if _step_index != step_index_for_id(_step_id):
		return false
	if _title.is_empty():
		return false
	if _instruction.is_empty():
		return false
	return true
