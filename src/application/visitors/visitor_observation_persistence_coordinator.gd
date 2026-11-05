## visitor_observation_persistence_coordinator.gd
## Application-layer coordinator for visitor observation, journal discovery recording,
## and immediate persistence checkpointing.
##
## Architectural rules:
## - Belongs to the application visitors layer (src/application/visitors/).
## - Pure application coordinator: extends RefCounted (not Node, Resource, Autoload, singleton).
## - Samples GameClock at most once (delegated via session.evaluate_visitor_now) and reuses
##   the snapshot timestamp for JournalDiscoveryService.record_discovery_at.
## - If no visitors are eligible or selection fails, performs zero state mutations and zero disk writes.
## - When a visitor is selected and recorded in JournalState, immediately checkpoints GameState via repository.save().
class_name VisitorObservationPersistenceCoordinator
extends RefCounted


static func try_observe_visitor_and_save(
	session: GameSession,
	catalog: ContentCatalog,
	game_clock: GameClock,
	random_source: RandomSource,
	repository: LocalSaveRepository
) -> VisitorObservationCheckpointResult:
	if (
		session == null
		or catalog == null
		or game_clock == null
		or random_source == null
		or repository == null
	):
		return VisitorObservationCheckpointResult.not_ready()

	var state: GameState = session.get_state()
	if state == null or state.get_plants() == null or state.get_journal() == null:
		return VisitorObservationCheckpointResult.not_ready()

	var now_utc_seconds: int = game_clock.utc_now_seconds()
	if now_utc_seconds < 0:
		return VisitorObservationCheckpointResult.observation_rejected()

	var selection_result: VisitorSelectionResult = session.evaluate_visitor_at(
		catalog,
		random_source,
		now_utc_seconds
	)

	if selection_result == null:
		return VisitorObservationCheckpointResult.observation_rejected()

	if selection_result.get_status() == VisitorSelectionResult.NO_ELIGIBLE_VISITORS:
		return VisitorObservationCheckpointResult.no_eligible_visitors(selection_result)

	if not selection_result.is_selected():
		return VisitorObservationCheckpointResult.observation_rejected(selection_result)

	var discovery_result: JournalDiscoveryResult = session.record_discovery_at(
		catalog,
		selection_result.get_selected_visitor_id(),
		now_utc_seconds
	)

	if discovery_result == null or not discovery_result.is_recorded():
		return VisitorObservationCheckpointResult.observation_rejected(
			selection_result,
			discovery_result
		)

	var save_ok: bool = repository.save(state)
	if save_ok:
		return VisitorObservationCheckpointResult.observed_saved(selection_result, discovery_result)
	return VisitorObservationCheckpointResult.observed_save_failed(selection_result, discovery_result)
