## event_selection_result.gd
## Typed result contract for ambient/special event eligibility evaluation and weighted selection.
##
## Architectural rules:
## - Belongs to the application events layer (src/application/events/).
## - Immutable result container: extends RefCounted (not Node, Resource, Autoload, or singleton).
## - Retains the evaluated GardenSnapshot, deterministic eligible event IDs,
##   and selected EventDefinition (when Status.SELECTED).
class_name EventSelectionResult
extends RefCounted

enum Status {
	SELECTED,
	NO_ELIGIBLE_EVENTS,
	INVALID_INPUT,
	SELECTION_FAILED,
}

const SELECTED: Status = Status.SELECTED
const NO_ELIGIBLE_EVENTS: Status = Status.NO_ELIGIBLE_EVENTS
const INVALID_INPUT: Status = Status.INVALID_INPUT
const SELECTION_FAILED: Status = Status.SELECTION_FAILED

var _status: Status
var _selected_event: EventDefinition = null
var _eligible_event_ids: Array[String] = []
var _snapshot: GardenSnapshot = null


func _init(
	status: Status,
	selected_event: EventDefinition = null,
	eligible_event_ids: Array[String] = [],
	snapshot: GardenSnapshot = null
) -> void:
	_status = status
	_selected_event = selected_event
	_eligible_event_ids = eligible_event_ids.duplicate()
	_snapshot = snapshot


static func selected(
	event_def: EventDefinition,
	eligible_ids: Array[String],
	snapshot: GardenSnapshot
) -> EventSelectionResult:
	return EventSelectionResult.new(Status.SELECTED, event_def, eligible_ids, snapshot)


static func no_eligible_events(snapshot: GardenSnapshot) -> EventSelectionResult:
	var empty_ids: Array[String] = []
	return EventSelectionResult.new(Status.NO_ELIGIBLE_EVENTS, null, empty_ids, snapshot)


static func invalid_input() -> EventSelectionResult:
	var empty_ids: Array[String] = []
	return EventSelectionResult.new(Status.INVALID_INPUT, null, empty_ids, null)


static func selection_failed(
	eligible_ids: Array[String],
	snapshot: GardenSnapshot
) -> EventSelectionResult:
	return EventSelectionResult.new(Status.SELECTION_FAILED, null, eligible_ids, snapshot)


func get_status() -> Status:
	return _status


func is_selected() -> bool:
	return _status == Status.SELECTED and _selected_event != null


func get_selected_event() -> EventDefinition:
	return _selected_event


func get_selected_event_id() -> String:
	if _selected_event == null:
		return ""
	return _selected_event.id


func get_eligible_event_ids() -> Array[String]:
	return _eligible_event_ids.duplicate()


func get_snapshot() -> GardenSnapshot:
	return _snapshot
