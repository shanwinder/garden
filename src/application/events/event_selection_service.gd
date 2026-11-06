## event_selection_service.gd
## Application service coordinating GardenSnapshot derivation, ambient/special event eligibility
## filtering, and deterministic weighted event selection.
##
## Architectural rules:
## - Belongs to the application events layer (src/application/events/).
## - Stateless application service: extends RefCounted.
## - Receives GameState/GardenSnapshot, ContentCatalog, GameClock, and RandomSource explicitly.
## - Never accesses global App Autoload, SceneTree, or filesystem.
## - Prevalidates all inputs BEFORE sampling clock or consuming RandomSource.
## - Consumes zero random floats when no events are eligible (NO_ELIGIBLE_EVENTS).
## - Evaluates candidates in deterministic ascending definition ID order from ContentCatalog.
## - Uses RandomSource.choose_weighted_index(weights) for weighted selection.
class_name EventSelectionService
extends RefCounted


## Evaluates event eligibility against an already-constructed [param snapshot]
## and selects one eligible event using [param random_source].
static func evaluate_and_select_from_snapshot(
	snapshot: GardenSnapshot,
	catalog: ContentCatalog,
	random_source: RandomSource
) -> EventSelectionResult:
	if snapshot == null or catalog == null or random_source == null:
		return EventSelectionResult.invalid_input()

	var all_events: Array[EventDefinition] = catalog.get_all_events()
	var eligible_events: Array[EventDefinition] = EventEligibility.filter_eligible_events(
		all_events,
		snapshot
	)

	if eligible_events.is_empty():
		return EventSelectionResult.no_eligible_events(snapshot)

	var eligible_ids: Array[String] = []
	var weights: Array[float] = []
	for event_def: EventDefinition in eligible_events:
		eligible_ids.append(event_def.id)
		weights.append(event_def.weight)

	var chosen_index: int = random_source.choose_weighted_index(weights)
	if chosen_index < 0 or chosen_index >= eligible_events.size():
		return EventSelectionResult.selection_failed(eligible_ids, snapshot)

	var chosen_event: EventDefinition = eligible_events[chosen_index]
	return EventSelectionResult.selected(chosen_event, eligible_ids, snapshot)


## Derives a GardenSnapshot at [param now_utc_seconds] and selects an eligible event.
static func evaluate_and_select_at(
	state: GameState,
	catalog: ContentCatalog,
	random_source: RandomSource,
	now_utc_seconds: int
) -> EventSelectionResult:
	if state == null or catalog == null or random_source == null:
		return EventSelectionResult.invalid_input()

	if state.get_plants() == null or now_utc_seconds < 0:
		return EventSelectionResult.invalid_input()

	var snapshot: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(
		state,
		catalog,
		now_utc_seconds
	)
	return evaluate_and_select_from_snapshot(snapshot, catalog, random_source)


## Samples [param game_clock] once after prevalidating dependencies and selects an eligible event.
static func evaluate_and_select_now(
	state: GameState,
	catalog: ContentCatalog,
	game_clock: GameClock,
	random_source: RandomSource
) -> EventSelectionResult:
	if state == null or catalog == null or game_clock == null or random_source == null:
		return EventSelectionResult.invalid_input()

	if state.get_plants() == null:
		return EventSelectionResult.invalid_input()

	var now_utc_seconds: int = game_clock.utc_now_seconds()
	if now_utc_seconds < 0:
		return EventSelectionResult.invalid_input()

	return evaluate_and_select_at(state, catalog, random_source, now_utc_seconds)
