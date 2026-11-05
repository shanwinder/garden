## journal_discovery_service.gd
## Stateless application service coordinating validated journal discovery recording.
##
## Architectural rules:
## - Belongs to the application journal layer (src/application/journal/).
## - Pure application service: extends RefCounted (not Node, Resource, Autoload, singleton).
## - Receives GameState, ContentCatalog, and GameClock explicitly.
## - Prevalidates dependencies, ID syntax, and catalog membership BEFORE sampling GameClock.
## - Distinguishes first-time discoveries (FIRST_DISCOVERY) from repeat sightings (REPEAT_SIGHTING).
## - Preserves first_seen_at on repeat sightings (idempotent first discovery).
class_name JournalDiscoveryService
extends RefCounted


## Validates [param definition_id] against [param catalog] and records a sighting in [param state]
## at [param seen_at_utc_seconds].
static func record_discovery_at(
	state: GameState,
	catalog: ContentCatalog,
	definition_id: String,
	seen_at_utc_seconds: int
) -> JournalDiscoveryResult:
	if state == null or catalog == null:
		return JournalDiscoveryResult.invalid_input()

	if seen_at_utc_seconds < 0:
		return JournalDiscoveryResult.invalid_input()

	var journal: JournalState = state.get_journal()
	if journal == null:
		return JournalDiscoveryResult.invalid_input()

	if not DiscoveryRecord.is_supported_discovery_id(definition_id):
		return JournalDiscoveryResult.invalid_input()

	if not _exists_in_catalog(catalog, definition_id):
		return JournalDiscoveryResult.unknown_definition_id()

	var was_already_discovered: bool = journal.has_discovered(definition_id)
	var recorded_ok: bool = journal.try_record_sighting(definition_id, seen_at_utc_seconds)
	if not recorded_ok:
		return JournalDiscoveryResult.state_update_rejected()

	var updated_record: DiscoveryRecord = journal.get_record(definition_id)
	if updated_record == null:
		return JournalDiscoveryResult.state_update_rejected()

	if was_already_discovered:
		return JournalDiscoveryResult.repeat_sighting(updated_record)
	return JournalDiscoveryResult.first_discovery(updated_record)


## Prevalidates dependencies and catalog membership before sampling [param game_clock] once
## and recording the discovery in [param state].
static func record_discovery_now(
	state: GameState,
	catalog: ContentCatalog,
	game_clock: GameClock,
	definition_id: String
) -> JournalDiscoveryResult:
	if state == null or catalog == null or game_clock == null:
		return JournalDiscoveryResult.invalid_input()

	if state.get_journal() == null:
		return JournalDiscoveryResult.invalid_input()

	if not DiscoveryRecord.is_supported_discovery_id(definition_id):
		return JournalDiscoveryResult.invalid_input()

	if not _exists_in_catalog(catalog, definition_id):
		return JournalDiscoveryResult.unknown_definition_id()

	var now_utc_seconds: int = game_clock.utc_now_seconds()
	if now_utc_seconds < 0:
		return JournalDiscoveryResult.invalid_input()

	return record_discovery_at(state, catalog, definition_id, now_utc_seconds)


static func _exists_in_catalog(catalog: ContentCatalog, definition_id: String) -> bool:
	if definition_id.begins_with(DiscoveryRecord.PLANT_NAMESPACE_PREFIX):
		return catalog.has_plant(definition_id)
	if definition_id.begins_with(DiscoveryRecord.VISITOR_NAMESPACE_PREFIX):
		return catalog.has_visitor(definition_id)
	return false
