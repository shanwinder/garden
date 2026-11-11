## discovery_pacing_milestone.gd
## Immutable domain value object representing one of the Suggested First Seven Days
## of Discovery pacing milestones per GAME_DESIGN.md Section 22.
##
## Architectural rules:
## - Belongs to the domain progression layer (src/domain/progression/).
## - Pure domain value object: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Immutable after construction: read-only getters, no public setters.
## - Deterministic, stateless, and side-effect free.
## - Pacing target only; not a mandatory login lock or streak requirement.
class_name DiscoveryPacingMilestone
extends RefCounted

const MILESTONE_DAY_1_EARLY_PHASE: String = "pacing.day_1_early_phase"
const MILESTONE_DAY_2_EARLY_RETURN: String = "pacing.day_2_early_return"
const MILESTONE_DAY_3_DEVELOPING_GARDEN: String = "pacing.day_3_developing_garden"
const MILESTONE_DAY_4_WEATHER_DISCOVERY: String = "pacing.day_4_weather_discovery"
const MILESTONE_DAY_5_WATER_HABITAT: String = "pacing.day_5_water_habitat"
const MILESTONE_DAY_6_NIGHT_DISCOVERY: String = "pacing.day_6_night_discovery"
const MILESTONE_DAY_7_FIRST_EXPANSION: String = "pacing.day_7_first_expansion"

const ALL_MILESTONES: Array[String] = [
	MILESTONE_DAY_1_EARLY_PHASE,
	MILESTONE_DAY_2_EARLY_RETURN,
	MILESTONE_DAY_3_DEVELOPING_GARDEN,
	MILESTONE_DAY_4_WEATHER_DISCOVERY,
	MILESTONE_DAY_5_WATER_HABITAT,
	MILESTONE_DAY_6_NIGHT_DISCOVERY,
	MILESTONE_DAY_7_FIRST_EXPANSION,
]

var _milestone_id: String
var _day_index: int
var _theme: String
var _title: String
var _description: String
var _recommended_focus: String
var _is_achieved: bool


func _init(
	milestone_id: String,
	day_index: int,
	theme: String,
	title: String,
	description: String,
	recommended_focus: String,
	is_achieved: bool = false
) -> void:
	_milestone_id = milestone_id
	_day_index = day_index
	_theme = theme
	_title = title
	_description = description
	_recommended_focus = recommended_focus
	_is_achieved = is_achieved


## Returns true if [param milestone_id] is one of the 7 canonical pacing milestones.
static func is_valid_milestone_id(milestone_id: String) -> bool:
	return ALL_MILESTONES.has(milestone_id)


## Returns the 1-based day index (1..7) for [param milestone_id], or -1 if invalid.
static func day_index_for_id(milestone_id: String) -> int:
	var idx: int = ALL_MILESTONES.find(milestone_id)
	return (idx + 1) if idx >= 0 else -1


## Returns the canonical milestone ID.
func get_milestone_id() -> String:
	return _milestone_id


## Returns the 1-based day index (1..7).
func get_day_index() -> int:
	return _day_index


## Returns the short English theme key.
func get_theme() -> String:
	return _theme


## Returns the localized Thai milestone title.
func get_title() -> String:
	return _title


## Returns the localized Thai milestone description.
func get_description() -> String:
	return _description


## Returns the localized recommended discovery focus.
func get_recommended_focus() -> String:
	return _recommended_focus


## Returns the stable localization key for this milestone's title.
func get_title_key() -> String:
	return GardenLocalization.pacing_title_key(_milestone_id)


## Returns the stable localization key for this milestone's description.
func get_description_key() -> String:
	return GardenLocalization.pacing_description_key(_milestone_id)


## Returns the stable localization key for this milestone's recommended focus.
func get_recommended_focus_key() -> String:
	return GardenLocalization.pacing_focus_key(_milestone_id)


## Returns true if the garden has fulfilled this milestone's discovery criteria.
func is_achieved() -> bool:
	return _is_achieved


## Returns true if all fields conform to canonical domain invariants.
func is_valid() -> bool:
	if not is_valid_milestone_id(_milestone_id):
		return false
	if _day_index != day_index_for_id(_milestone_id):
		return false
	if _theme.is_empty() or _title.is_empty() or _description.is_empty() or _recommended_focus.is_empty():
		return false
	return true
