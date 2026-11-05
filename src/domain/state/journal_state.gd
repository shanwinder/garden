## journal_state.gd
## Authoritative domain state slice for Garden's discovery journal (สมุดบ้านสวน).
##
## JournalState owns all player DiscoveryRecord entries indexed by stable content definition ID.
## It is owned directly by GameState as a typed persistent state slice.
##
## Architectural rules:
## - Belongs to the domain state layer (src/domain/state/).
## - Pure domain object: extends RefCounted (not a Node, Resource, Autoload, singleton, or manager).
## - Constructable in isolation without SceneTree or engine lifecycle dependency.
## - Owned by GameState; non-global, non-singleton.
## - Encapsulates discovery storage; does not expose internal Dictionary reference.
## - Enforces definition_id uniqueness across all stored DiscoveryRecord objects.
## - First-time discovery is idempotent: recording a repeat sighting preserves first_seen_at
##   and increments times_seen by 1.
## - Enumerates records in deterministic ascending order of definition_id.
## - Independent of GameClock, RandomSource, App, FileAccess, ResourceLoader, and SceneTree.
class_name JournalState
extends RefCounted

var _records_by_definition_id: Dictionary[String, DiscoveryRecord] = {}


## Returns the total number of discovered content definitions in the journal.
func get_count() -> int:
	return _records_by_definition_id.size()


## Returns true if [param definition_id] has been discovered.
func has_discovered(definition_id: String) -> bool:
	if definition_id.is_empty():
		return false
	return _records_by_definition_id.has(definition_id)


## Returns the stored DiscoveryRecord for [param definition_id], or null if not discovered.
func get_record(definition_id: String) -> DiscoveryRecord:
	if definition_id.is_empty():
		return null
	return _records_by_definition_id.get(definition_id, null)


## Inserts an initial or decoded [param record] into the journal if its definition_id is not yet present.
##
## Validation:
## - [param record] must not be null and must satisfy is_valid().
## - [param record] definition_id must not already exist in the journal.
##
## Returns true on success, false without mutating state on rejection.
func try_put_record(record: DiscoveryRecord) -> bool:
	if record == null:
		return false

	if not record.is_valid():
		return false

	var def_id: String = record.get_definition_id()
	if _records_by_definition_id.has(def_id):
		return false

	_records_by_definition_id[def_id] = record
	return true


## Records a sighting of [param definition_id] at [param seen_at_utc].
##
## Behavior:
## - Validates that [param definition_id] is a supported discovery ID ("plant." or "visitor.")
##   and [param seen_at_utc] >= 0.
## - If [param definition_id] has not been discovered yet: stores a new DiscoveryRecord
##   with first_seen_at = seen_at_utc and times_seen = 1.
## - If [param definition_id] was already discovered: replaces the stored record with
##   an updated DiscoveryRecord preserving the original first_seen_at and incrementing times_seen by 1.
## - Returns true on success, false without mutating state on invalid input or int64 overflow.
func try_record_sighting(definition_id: String, seen_at_utc: int) -> bool:
	if not DiscoveryRecord.is_supported_discovery_id(definition_id):
		return false

	if seen_at_utc < 0:
		return false

	if not _records_by_definition_id.has(definition_id):
		var first_record: DiscoveryRecord = DiscoveryRecord.new(definition_id, seen_at_utc, 1)
		if not first_record.is_valid():
			return false
		_records_by_definition_id[definition_id] = first_record
		return true

	var existing: DiscoveryRecord = _records_by_definition_id[definition_id]
	var updated: DiscoveryRecord = existing.with_additional_sighting(seen_at_utc)
	if updated == null:
		return false

	_records_by_definition_id[definition_id] = updated
	return true


## Returns all DiscoveryRecord instances in deterministic ascending order of definition_id.
func get_all_records() -> Array[DiscoveryRecord]:
	var keys: Array = _records_by_definition_id.keys()
	keys.sort()
	var result: Array[DiscoveryRecord] = []
	for key: String in keys:
		result.append(_records_by_definition_id[key])
	return result


## Returns all discovered definition IDs in deterministic ascending order.
func get_discovered_ids() -> Array[String]:
	var keys: Array = _records_by_definition_id.keys()
	keys.sort()
	var result: Array[String] = []
	for key: String in keys:
		result.append(key)
	return result
