## visitor_observation_checkpoint_result.gd
## Strongly-typed outcome of observing an eligible visitor, recording its discovery in the
## Garden Journal, and immediately checkpointing persistence.
##
## Architectural rules:
## - Belongs to the application visitors layer (src/application/visitors/).
## - Extends RefCounted; no Node, Resource, Autoload, singleton, or filesystem dependency.
## - Immutable after construction.
class_name VisitorObservationCheckpointResult
extends RefCounted

enum Status {
	OBSERVED_SAVED,
	OBSERVED_SAVE_FAILED,
	NO_ELIGIBLE_VISITORS,
	OBSERVATION_REJECTED,
	NOT_READY,
}

const OBSERVED_SAVED: Status = Status.OBSERVED_SAVED
const OBSERVED_SAVE_FAILED: Status = Status.OBSERVED_SAVE_FAILED
const NO_ELIGIBLE_VISITORS: Status = Status.NO_ELIGIBLE_VISITORS
const OBSERVATION_REJECTED: Status = Status.OBSERVATION_REJECTED
const NOT_READY: Status = Status.NOT_READY

var _status: Status
var _selection_result: VisitorSelectionResult = null
var _discovery_result: JournalDiscoveryResult = null
var _is_saved: bool = false


func _init(
	status: Status,
	selection_result: VisitorSelectionResult = null,
	discovery_result: JournalDiscoveryResult = null,
	saved: bool = false
) -> void:
	_status = status
	_selection_result = selection_result
	_discovery_result = discovery_result
	_is_saved = saved


static func observed_saved(
	selection_result: VisitorSelectionResult,
	discovery_result: JournalDiscoveryResult
) -> VisitorObservationCheckpointResult:
	if (
		selection_result == null
		or not selection_result.is_selected()
		or discovery_result == null
		or not discovery_result.is_recorded()
	):
		return VisitorObservationCheckpointResult.new(
			Status.OBSERVATION_REJECTED,
			selection_result,
			discovery_result,
			false
		)
	return VisitorObservationCheckpointResult.new(
		Status.OBSERVED_SAVED,
		selection_result,
		discovery_result,
		true
	)


static func observed_save_failed(
	selection_result: VisitorSelectionResult,
	discovery_result: JournalDiscoveryResult
) -> VisitorObservationCheckpointResult:
	if (
		selection_result == null
		or not selection_result.is_selected()
		or discovery_result == null
		or not discovery_result.is_recorded()
	):
		return VisitorObservationCheckpointResult.new(
			Status.OBSERVATION_REJECTED,
			selection_result,
			discovery_result,
			false
		)
	return VisitorObservationCheckpointResult.new(
		Status.OBSERVED_SAVE_FAILED,
		selection_result,
		discovery_result,
		false
	)


static func no_eligible_visitors(
	selection_result: VisitorSelectionResult
) -> VisitorObservationCheckpointResult:
	return VisitorObservationCheckpointResult.new(
		Status.NO_ELIGIBLE_VISITORS,
		selection_result,
		null,
		false
	)


static func observation_rejected(
	selection_result: VisitorSelectionResult = null,
	discovery_result: JournalDiscoveryResult = null
) -> VisitorObservationCheckpointResult:
	return VisitorObservationCheckpointResult.new(
		Status.OBSERVATION_REJECTED,
		selection_result,
		discovery_result,
		false
	)


static func not_ready() -> VisitorObservationCheckpointResult:
	return VisitorObservationCheckpointResult.new(Status.NOT_READY, null, null, false)


func get_status() -> Status:
	return _status


func is_observed() -> bool:
	return _status == Status.OBSERVED_SAVED or _status == Status.OBSERVED_SAVE_FAILED


func is_saved() -> bool:
	return _is_saved


func is_first_discovery() -> bool:
	return (
		is_observed()
		and _discovery_result != null
		and _discovery_result.is_first_discovery()
	)


func get_selection_result() -> VisitorSelectionResult:
	return _selection_result


func get_discovery_result() -> JournalDiscoveryResult:
	return _discovery_result


func get_selected_visitor_id() -> String:
	return _selection_result.get_selected_visitor_id() if _selection_result != null else ""


func get_discovery_record() -> DiscoveryRecord:
	return _discovery_result.get_record() if _discovery_result != null else null
