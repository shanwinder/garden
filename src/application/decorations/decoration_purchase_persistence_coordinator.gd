## decoration_purchase_persistence_coordinator.gd
## Application-layer coordinator for decoration purchase and immediate persistence checkpoint.
##
## Architectural rules:
## - Belongs to the application layer (src/application/decorations/).
## - Pure application coordinator: extends RefCounted (not Node, Resource, Autoload, singleton).
## - Does NOT own a second GameState.
## - Delegates logical purchase validation and execution to GameSession.try_purchase_decoration_now().
## - Attempts repository.save(session.get_state()) strictly AFTER logical purchase succeeds.
## - Never touches disk when purchase is rejected (such as INSUFFICIENT_CURRENCY).
class_name DecorationPurchasePersistenceCoordinator
extends RefCounted


## Validates dependencies, performs logical decoration purchase via session.try_purchase_decoration_now(),
## and if purchased, triggers an immediate persistence checkpoint via repository.save().
static func try_purchase_decoration_and_save(
	session: GameSession,
	catalog: ContentCatalog,
	game_clock: GameClock,
	random_source: RandomSource,
	repository: LocalSaveRepository,
	definition_id: String,
	zone_id: String = "",
	grid_x: int = -1,
	grid_y: int = -1
) -> DecorationPurchaseCheckpointResult:
	if (
		session == null
		or catalog == null
		or game_clock == null
		or random_source == null
		or repository == null
	):
		return DecorationPurchaseCheckpointResult.not_ready()

	if session.get_state() == null:
		return DecorationPurchaseCheckpointResult.not_ready()

	var purchase_result: DecorationPurchaseResult = session.try_purchase_decoration_now(
		catalog,
		game_clock,
		random_source,
		definition_id,
		zone_id,
		grid_x,
		grid_y
	)

	if not purchase_result.is_purchased():
		return DecorationPurchaseCheckpointResult.purchase_rejected(purchase_result)

	var save_success: bool = repository.save(session.get_state())
	if save_success:
		return DecorationPurchaseCheckpointResult.purchased_saved(purchase_result)
	else:
		return DecorationPurchaseCheckpointResult.purchased_save_failed(purchase_result)
