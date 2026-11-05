## visitor_selection_service.gd
## Application service coordinating GardenSnapshot derivation, visitor eligibility
## filtering, and deterministic weighted visitor selection.
##
## Architectural rules:
## - Belongs to the application visitors layer (src/application/visitors/).
## - Stateless application service: extends RefCounted.
## - Receives GameState/GardenSnapshot, ContentCatalog, GameClock, and RandomSource explicitly.
## - Never accesses global App Autoload, SceneTree, or filesystem.
## - Prevalidates all inputs BEFORE sampling clock or consuming RandomSource.
## - Consumes zero random floats when no visitors are eligible (NO_ELIGIBLE_VISITORS).
## - Evaluates candidates in deterministic ascending definition ID order from ContentCatalog.
## - Uses RandomSource.choose_weighted_index(weights) for weighted selection.
class_name VisitorSelectionService
extends RefCounted


## Evaluates visitor eligibility against an already-constructed [param snapshot]
## and selects one eligible visitor using [param random_source].
static func evaluate_and_select_from_snapshot(
	snapshot: GardenSnapshot,
	catalog: ContentCatalog,
	random_source: RandomSource
) -> VisitorSelectionResult:
	if snapshot == null or catalog == null or random_source == null:
		return VisitorSelectionResult.invalid_input()

	var all_visitors: Array[VisitorDefinition] = catalog.get_all_visitors()
	var eligible_visitors: Array[VisitorDefinition] = VisitorEligibility.filter_eligible_visitors(
		all_visitors,
		snapshot
	)

	if eligible_visitors.is_empty():
		return VisitorSelectionResult.no_eligible_visitors(snapshot)

	var eligible_ids: Array[String] = []
	var weights: Array[float] = []
	for visitor: VisitorDefinition in eligible_visitors:
		eligible_ids.append(visitor.id)
		weights.append(visitor.weight)

	var chosen_index: int = random_source.choose_weighted_index(weights)
	if chosen_index < 0 or chosen_index >= eligible_visitors.size():
		return VisitorSelectionResult.selection_failed(eligible_ids, snapshot)

	var chosen_visitor: VisitorDefinition = eligible_visitors[chosen_index]
	return VisitorSelectionResult.selected(chosen_visitor, eligible_ids, snapshot)


## Derives a GardenSnapshot at [param now_utc_seconds] and selects an eligible visitor.
static func evaluate_and_select_at(
	state: GameState,
	catalog: ContentCatalog,
	random_source: RandomSource,
	now_utc_seconds: int
) -> VisitorSelectionResult:
	if state == null or catalog == null or random_source == null:
		return VisitorSelectionResult.invalid_input()

	if state.get_plants() == null or now_utc_seconds < 0:
		return VisitorSelectionResult.invalid_input()

	var snapshot: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(
		state,
		catalog,
		now_utc_seconds
	)
	return evaluate_and_select_from_snapshot(snapshot, catalog, random_source)


## Samples [param game_clock] once after prevalidating dependencies and selects an eligible visitor.
static func evaluate_and_select_now(
	state: GameState,
	catalog: ContentCatalog,
	game_clock: GameClock,
	random_source: RandomSource
) -> VisitorSelectionResult:
	if state == null or catalog == null or game_clock == null or random_source == null:
		return VisitorSelectionResult.invalid_input()

	if state.get_plants() == null:
		return VisitorSelectionResult.invalid_input()

	var now_utc_seconds: int = game_clock.utc_now_seconds()
	if now_utc_seconds < 0:
		return VisitorSelectionResult.invalid_input()

	return evaluate_and_select_at(state, catalog, random_source, now_utc_seconds)
