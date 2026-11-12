## garden_placement_persistence_coordinator.gd
## Application-layer coordinator for garden item repositioning and immediate persistence checkpoint.
class_name GardenPlacementPersistenceCoordinator
extends RefCounted


static func try_move_item_and_save(
	session: GameSession,
	catalog: ContentCatalog,
	game_clock: GameClock,
	repository: LocalSaveRepository,
	runtime_instance_id: String,
	target_zone_id: String,
	target_grid_x: int,
	target_grid_y: int
) -> GardenPlacementCheckpointResult:
	if (
		session == null
		or catalog == null
		or game_clock == null
		or repository == null
	):
		return GardenPlacementCheckpointResult.not_ready()

	if session.get_state() == null:
		return GardenPlacementCheckpointResult.not_ready()

	var move_result: GardenPlacementResult = session.try_move_item_now(
		catalog,
		game_clock,
		runtime_instance_id,
		target_zone_id,
		target_grid_x,
		target_grid_y
	)

	if not move_result.is_moved():
		return GardenPlacementCheckpointResult.move_rejected(move_result)

	var save_success: bool = repository.save(session.get_state())
	if save_success:
		return GardenPlacementCheckpointResult.moved_saved(move_result)
	else:
		return GardenPlacementCheckpointResult.moved_save_failed(move_result)
