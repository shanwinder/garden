## game_session.gd
## Application-layer runtime coordinator and authoritative state owner.
##
## GameSession owns exactly one authoritative GameState instance during an
## active gameplay session and exposes application-layer operations.
##
## Architectural rules:
## - Belongs to the application layer.
## - Owns the canonical GameState instance; does not duplicate, serialize,
##   or replace it after construction.
## - Not a Node, Resource, Autoload, singleton, or manager class.
## - Does not expose a generic Variant/Dictionary state bag or direct
##   state-replacement API.
## - Does not store a second currency balance; delegates economy operations
##   directly to the authoritative GameState.get_economy().
## - Does not take infrastructure dependencies (GameClock, RandomSource,
##   PersistenceService, etc.) in Task 2.3.
class_name GameSession
extends RefCounted

var _state: GameState


func _init(initial_state: GameState = null) -> void:
	if initial_state == null:
		_state = GameState.new()
	else:
		_state = initial_state


## Returns the authoritative GameState instance owned by this session.
func get_state() -> GameState:
	return _state


## Convenience application query for current currency balance.
## Delegates directly to authoritative state; does not cache balance.
func get_currency() -> int:
	return _state.get_economy().get_currency()


## Application operation to grant currency to the active session.
## Delegates directly to authoritative state.
func grant_currency(amount: int) -> bool:
	return _state.get_economy().grant_currency(amount)


## Application operation to spend currency from the active session.
## Delegates directly to authoritative state.
func try_spend_currency(amount: int) -> bool:
	return _state.get_economy().try_spend_currency(amount)


## Application operation to register a planted plant into this session.
## Delegates directly to PlantRegistrationService; does not duplicate validation logic.
func try_register_plant(
	catalog: ContentCatalog,
	instance_id: String,
	definition_id: String,
	planted_at: int
) -> PlantRegistrationResult:
	return PlantRegistrationService.try_register_plant(
		_state,
		catalog,
		instance_id,
		definition_id,
		planted_at
	)


## Application operation to coordinate runtime identity, timestamp capture,
## and validated planting into this session.
## Delegates directly to PlantingCommandService; does not own clock, RNG, or catalog.
func try_plant_now(
	catalog: ContentCatalog,
	game_clock: GameClock,
	random_source: RandomSource,
	definition_id: String
) -> PlantRegistrationResult:
	return PlantingCommandService.try_plant_now(
		_state,
		catalog,
		game_clock,
		random_source,
		definition_id
	)


## Application operation to harvest a mature plant at an explicit UTC timestamp.
## Delegates directly to PlantHarvestService; does not duplicate validation logic.
func try_harvest_plant_at(
	catalog: ContentCatalog,
	runtime_instance_id: String,
	now_utc_seconds: int
) -> PlantHarvestResult:
	return PlantHarvestService.try_harvest_plant_at(
		_state,
		catalog,
		runtime_instance_id,
		now_utc_seconds
	)


## Application operation to capture current UTC timestamp and harvest a mature plant.
## Delegates directly to PlantHarvestService; does not own clock or catalog.
func try_harvest_now(
	catalog: ContentCatalog,
	game_clock: GameClock,
	runtime_instance_id: String
) -> PlantHarvestResult:
	return PlantHarvestService.try_harvest_now(
		_state,
		catalog,
		game_clock,
		runtime_instance_id
	)


## Pure application query to derive an immutable GardenSnapshot at [param now_utc_seconds].
func build_garden_snapshot(
	catalog: ContentCatalog,
	now_utc_seconds: int
) -> GardenSnapshot:
	return GardenSnapshotBuilder.build_snapshot(
		_state,
		catalog,
		now_utc_seconds
	)


## Application operation to evaluate visitor eligibility and select a visitor at [param now_utc_seconds].
## Delegates directly to VisitorSelectionService; does not mutate GameState.
func evaluate_visitor_at(
	catalog: ContentCatalog,
	random_source: RandomSource,
	now_utc_seconds: int
) -> VisitorSelectionResult:
	return VisitorSelectionService.evaluate_and_select_at(
		_state,
		catalog,
		random_source,
		now_utc_seconds
	)


## Application operation to sample current UTC timestamp once and select an eligible visitor.
## Delegates directly to VisitorSelectionService; does not mutate GameState.
func evaluate_visitor_now(
	catalog: ContentCatalog,
	game_clock: GameClock,
	random_source: RandomSource
) -> VisitorSelectionResult:
	return VisitorSelectionService.evaluate_and_select_now(
		_state,
		catalog,
		game_clock,
		random_source
	)


## Application operation to evaluate ambient/special event eligibility and select an event at [param now_utc_seconds].
## Delegates directly to EventSelectionService; does not mutate GameState.
func evaluate_event_at(
	catalog: ContentCatalog,
	random_source: RandomSource,
	now_utc_seconds: int
) -> EventSelectionResult:
	return EventSelectionService.evaluate_and_select_at(
		_state,
		catalog,
		random_source,
		now_utc_seconds
	)


## Application operation to sample current UTC timestamp once and select an eligible ambient/special event.
## Delegates directly to EventSelectionService; does not mutate GameState.
func evaluate_event_now(
	catalog: ContentCatalog,
	game_clock: GameClock,
	random_source: RandomSource
) -> EventSelectionResult:
	return EventSelectionService.evaluate_and_select_now(
		_state,
		catalog,
		game_clock,
		random_source
	)


## Application operation to record a discovery in the session's JournalState at an explicit UTC timestamp.
## Delegates directly to JournalDiscoveryService.
func record_discovery_at(
	catalog: ContentCatalog,
	definition_id: String,
	seen_at_utc_seconds: int
) -> JournalDiscoveryResult:
	return JournalDiscoveryService.record_discovery_at(
		_state,
		catalog,
		definition_id,
		seen_at_utc_seconds
	)


## Application operation to sample current UTC timestamp once and record a discovery in JournalState.
## Delegates directly to JournalDiscoveryService.
func record_discovery_now(
	catalog: ContentCatalog,
	game_clock: GameClock,
	definition_id: String
) -> JournalDiscoveryResult:
	return JournalDiscoveryService.record_discovery_now(
		_state,
		catalog,
		game_clock,
		definition_id
	)


## Application operation to purchase and place a decoration at an explicit UTC timestamp.
## Delegates directly to DecorationPurchaseService.
func try_purchase_decoration_at(
	catalog: ContentCatalog,
	instance_id: String,
	definition_id: String,
	placed_at: int
) -> DecorationPurchaseResult:
	return DecorationPurchaseService.try_purchase_and_place_at(
		_state,
		catalog,
		instance_id,
		definition_id,
		placed_at
	)


## Application operation to capture current UTC timestamp, generate runtime identity,
## and purchase/place a decoration into this session.
## Delegates directly to DecorationPurchaseService.
func try_purchase_decoration_now(
	catalog: ContentCatalog,
	game_clock: GameClock,
	random_source: RandomSource,
	definition_id: String
) -> DecorationPurchaseResult:
	return DecorationPurchaseService.try_purchase_and_place_now(
		_state,
		catalog,
		game_clock,
		random_source,
		definition_id
	)


## Pure application query to derive GardenProgressionSummary at [param now_utc_seconds].
func evaluate_progression_at(
	catalog: ContentCatalog,
	now_utc_seconds: int
) -> GardenProgressionSummary:
	var snapshot: GardenSnapshot = build_garden_snapshot(catalog, now_utc_seconds)
	var journal: JournalState = _state.get_journal() if _state != null else null
	var day_number: int = int(now_utc_seconds / 86400) if now_utc_seconds >= 0 else 0
	var currency: int = _state.get_economy().get_currency() if _state != null and _state.get_economy() != null else 0
	return GardenProgressionStage.evaluate(snapshot, journal, day_number, currency)


## Application query to sample current UTC timestamp once and derive GardenProgressionSummary.
func evaluate_progression_now(
	catalog: ContentCatalog,
	game_clock: GameClock
) -> GardenProgressionSummary:
	if catalog == null or game_clock == null:
		var currency: int = _state.get_economy().get_currency() if _state != null and _state.get_economy() != null else 0
		return GardenProgressionStage.evaluate(null, _state.get_journal() if _state != null else null, 0, currency)
	var now_utc_seconds: int = game_clock.utc_now_seconds()
	return evaluate_progression_at(catalog, now_utc_seconds)


## Pure application query to evaluate away/offline changes between [param previous_utc_seconds]
## and [param current_utc_seconds]. Delegates directly to GardenReturnEvaluator.
func evaluate_return_between(
	catalog: ContentCatalog,
	previous_utc_seconds: int,
	current_utc_seconds: int
) -> GardenReturnSummary:
	return GardenReturnEvaluator.evaluate_return_between(
		_state,
		catalog,
		previous_utc_seconds,
		current_utc_seconds
	)


## Application query to sample current UTC timestamp once and evaluate away/offline changes
## since [param previous_utc_seconds]. Delegates directly to GardenReturnEvaluator.
func evaluate_return_from_now(
	catalog: ContentCatalog,
	game_clock: GameClock,
	previous_utc_seconds: int
) -> GardenReturnSummary:
	return GardenReturnEvaluator.evaluate_return_from_now(
		_state,
		catalog,
		game_clock,
		previous_utc_seconds
	)
