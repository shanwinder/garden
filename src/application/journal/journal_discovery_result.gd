## journal_discovery_result.gd
## Strongly-typed outcome of a journal discovery recording operation.
##
## Architectural rules:
## - Belongs to the application journal layer (src/application/journal/).
## - Extends RefCounted; no Node, Resource, Autoload, singleton, or filesystem dependency.
## - Immutable after construction.
class_name JournalDiscoveryResult
extends RefCounted

enum Status {
	FIRST_DISCOVERY,
	REPEAT_SIGHTING,
	INVALID_INPUT,
	UNKNOWN_DEFINITION_ID,
	STATE_UPDATE_REJECTED,
}

const FIRST_DISCOVERY: Status = Status.FIRST_DISCOVERY
const REPEAT_SIGHTING: Status = Status.REPEAT_SIGHTING
const INVALID_INPUT: Status = Status.INVALID_INPUT
const UNKNOWN_DEFINITION_ID: Status = Status.UNKNOWN_DEFINITION_ID
const STATE_UPDATE_REJECTED: Status = Status.STATE_UPDATE_REJECTED

var _status: Status
var _record: DiscoveryRecord = null


func _init(status: Status, record: DiscoveryRecord = null) -> void:
	_status = status
	if (
		(status == Status.FIRST_DISCOVERY or status == Status.REPEAT_SIGHTING)
		and record != null
		and record.is_valid()
	):
		_record = record
	else:
		_record = null


static func first_discovery(record: DiscoveryRecord) -> JournalDiscoveryResult:
	if record == null or not record.is_valid():
		return JournalDiscoveryResult.new(Status.STATE_UPDATE_REJECTED, null)
	return JournalDiscoveryResult.new(Status.FIRST_DISCOVERY, record)


static func repeat_sighting(record: DiscoveryRecord) -> JournalDiscoveryResult:
	if record == null or not record.is_valid():
		return JournalDiscoveryResult.new(Status.STATE_UPDATE_REJECTED, null)
	return JournalDiscoveryResult.new(Status.REPEAT_SIGHTING, record)


static func invalid_input() -> JournalDiscoveryResult:
	return JournalDiscoveryResult.new(Status.INVALID_INPUT, null)


static func unknown_definition_id() -> JournalDiscoveryResult:
	return JournalDiscoveryResult.new(Status.UNKNOWN_DEFINITION_ID, null)


static func state_update_rejected() -> JournalDiscoveryResult:
	return JournalDiscoveryResult.new(Status.STATE_UPDATE_REJECTED, null)


func get_status() -> Status:
	return _status


func is_recorded() -> bool:
	return (
		(_status == Status.FIRST_DISCOVERY or _status == Status.REPEAT_SIGHTING)
		and _record != null
	)


func is_first_discovery() -> bool:
	return _status == Status.FIRST_DISCOVERY and _record != null


func is_repeat_sighting() -> bool:
	return _status == Status.REPEAT_SIGHTING and _record != null


func get_record() -> DiscoveryRecord:
	return _record


func get_definition_id() -> String:
	return _record.get_definition_id() if _record != null else ""
