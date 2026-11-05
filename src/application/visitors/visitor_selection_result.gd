## visitor_selection_result.gd
## Typed result contract for visitor eligibility evaluation and weighted selection.
##
## Architectural rules:
## - Belongs to the application visitors layer (src/application/visitors/).
## - Immutable result container: extends RefCounted (not Node, Resource, Autoload, or singleton).
## - Retains the evaluated GardenSnapshot, deterministic eligible visitor IDs,
##   and selected VisitorDefinition (when Status.SELECTED).
class_name VisitorSelectionResult
extends RefCounted

enum Status {
	SELECTED,
	NO_ELIGIBLE_VISITORS,
	INVALID_INPUT,
	SELECTION_FAILED,
}

const SELECTED: Status = Status.SELECTED
const NO_ELIGIBLE_VISITORS: Status = Status.NO_ELIGIBLE_VISITORS
const INVALID_INPUT: Status = Status.INVALID_INPUT
const SELECTION_FAILED: Status = Status.SELECTION_FAILED

var _status: Status
var _selected_visitor: VisitorDefinition = null
var _eligible_visitor_ids: Array[String] = []
var _snapshot: GardenSnapshot = null


func _init(
	status: Status,
	selected_visitor: VisitorDefinition = null,
	eligible_visitor_ids: Array[String] = [],
	snapshot: GardenSnapshot = null
) -> void:
	_status = status
	_selected_visitor = selected_visitor
	_eligible_visitor_ids = eligible_visitor_ids.duplicate()
	_snapshot = snapshot


static func selected(
	visitor: VisitorDefinition,
	eligible_ids: Array[String],
	snapshot: GardenSnapshot
) -> VisitorSelectionResult:
	return VisitorSelectionResult.new(Status.SELECTED, visitor, eligible_ids, snapshot)


static func no_eligible_visitors(snapshot: GardenSnapshot) -> VisitorSelectionResult:
	var empty_ids: Array[String] = []
	return VisitorSelectionResult.new(Status.NO_ELIGIBLE_VISITORS, null, empty_ids, snapshot)


static func invalid_input() -> VisitorSelectionResult:
	var empty_ids: Array[String] = []
	return VisitorSelectionResult.new(Status.INVALID_INPUT, null, empty_ids, null)


static func selection_failed(
	eligible_ids: Array[String],
	snapshot: GardenSnapshot
) -> VisitorSelectionResult:
	return VisitorSelectionResult.new(Status.SELECTION_FAILED, null, eligible_ids, snapshot)


func get_status() -> Status:
	return _status


func is_selected() -> bool:
	return _status == Status.SELECTED and _selected_visitor != null


func get_selected_visitor() -> VisitorDefinition:
	return _selected_visitor


func get_selected_visitor_id() -> String:
	if _selected_visitor == null:
		return ""
	return _selected_visitor.id


func get_eligible_visitor_ids() -> Array[String]:
	return _eligible_visitor_ids.duplicate()


func get_snapshot() -> GardenSnapshot:
	return _snapshot
