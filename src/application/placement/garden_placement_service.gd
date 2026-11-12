## garden_placement_service.gd
## Application service coordinating validated repositioning of existing planted plants
## and placed decorations across Garden's Coarse Logical Grid + Zones.
##
## Architectural rules:
## - Belongs to the application placement layer (src/application/placement/).
## - Pure application service: extends RefCounted.
## - Receives all dependencies explicitly; never reads global App, SceneTree, or filesystem.
## - Validates item existence, zone bounds, zone unlock eligibility, and cell occupancy
##   BEFORE mutating authoritative GameState.
## - Preserves planted_at / placed_at timestamps, runtime_instance_id, and definition_id.
class_name GardenPlacementService
extends RefCounted


## Validates and moves an existing plant or decoration identified by [param runtime_instance_id]
## to ([param target_zone_id], [param target_grid_x], [param target_grid_y]) at [param now_utc_seconds].
static func try_move_item_at(
	state: GameState,
	catalog: ContentCatalog,
	runtime_instance_id: String,
	target_zone_id: String,
	target_grid_x: int,
	target_grid_y: int,
	now_utc_seconds: int
) -> GardenPlacementResult:
	if state == null or catalog == null:
		return GardenPlacementResult.invalid_input()

	if runtime_instance_id.is_empty() or now_utc_seconds < 0:
		return GardenPlacementResult.invalid_input()

	if state.get_plants() == null or state.get_decorations() == null:
		return GardenPlacementResult.invalid_input()

	if (
		not GardenZone.is_valid_zone_id(target_zone_id)
		or not GardenZone.is_within_bounds(target_zone_id, target_grid_x, target_grid_y)
	):
		return GardenPlacementResult.invalid_placement()

	var existing_plant: PlantState = state.get_plants().get_plant(runtime_instance_id)
	var existing_decor: DecorationState = state.get_decorations().get_decoration(runtime_instance_id)

	if existing_plant == null and existing_decor == null:
		return GardenPlacementResult.item_not_found()

	var snapshot: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, now_utc_seconds)
	var unlocked_zones: Array[String] = GardenZone.get_unlocked_zone_ids(snapshot, state.get_journal())
	if not unlocked_zones.has(target_zone_id):
		return GardenPlacementResult.zone_locked()

	if existing_plant != null:
		if not existing_plant.is_valid():
			return GardenPlacementResult.item_not_found()
		if (
			existing_plant.get_zone_id() == target_zone_id
			and existing_plant.get_grid_x() == target_grid_x
			and existing_plant.get_grid_y() == target_grid_y
		):
			return GardenPlacementResult.same_cell()
		if GardenPlacement.is_cell_occupied(
			state,
			target_zone_id,
			target_grid_x,
			target_grid_y,
			runtime_instance_id
		):
			return GardenPlacementResult.cell_occupied()

		var moved_plant: PlantState = PlantState.new(
			runtime_instance_id,
			existing_plant.get_definition_id(),
			existing_plant.get_planted_at(),
			target_zone_id,
			target_grid_x,
			target_grid_y
		)
		if not moved_plant.is_valid():
			return GardenPlacementResult.state_update_rejected()
		if not state.get_plants().try_replace_existing_plant(moved_plant):
			return GardenPlacementResult.state_update_rejected()
		return GardenPlacementResult.moved(
			GardenPlacement.KIND_PLANT,
			runtime_instance_id,
			moved_plant.get_definition_id(),
			target_zone_id,
			target_grid_x,
			target_grid_y
		)

	if not existing_decor.is_valid():
		return GardenPlacementResult.item_not_found()
	if (
		existing_decor.get_zone_id() == target_zone_id
		and existing_decor.get_grid_x() == target_grid_x
		and existing_decor.get_grid_y() == target_grid_y
	):
		return GardenPlacementResult.same_cell()
	if GardenPlacement.is_cell_occupied(
		state,
		target_zone_id,
		target_grid_x,
		target_grid_y,
		runtime_instance_id
	):
		return GardenPlacementResult.cell_occupied()

	var moved_decor: DecorationState = DecorationState.new(
		runtime_instance_id,
		existing_decor.get_definition_id(),
		existing_decor.get_placed_at(),
		target_zone_id,
		target_grid_x,
		target_grid_y
	)
	if not moved_decor.is_valid():
		return GardenPlacementResult.state_update_rejected()
	if not state.get_decorations().try_replace_existing_decoration(moved_decor):
		return GardenPlacementResult.state_update_rejected()
	return GardenPlacementResult.moved(
		GardenPlacement.KIND_DECORATION,
		runtime_instance_id,
		moved_decor.get_definition_id(),
		target_zone_id,
		target_grid_x,
		target_grid_y
	)


## Prevalidates dependencies, structural bounds, and item existence BEFORE sampling [param game_clock]
## once, then delegates to [method try_move_item_at].
static func try_move_item_now(
	state: GameState,
	catalog: ContentCatalog,
	game_clock: GameClock,
	runtime_instance_id: String,
	target_zone_id: String,
	target_grid_x: int,
	target_grid_y: int
) -> GardenPlacementResult:
	if state == null or catalog == null or game_clock == null:
		return GardenPlacementResult.invalid_input()

	if runtime_instance_id.is_empty():
		return GardenPlacementResult.invalid_input()

	if state.get_plants() == null or state.get_decorations() == null:
		return GardenPlacementResult.invalid_input()

	if (
		not GardenZone.is_valid_zone_id(target_zone_id)
		or not GardenZone.is_within_bounds(target_zone_id, target_grid_x, target_grid_y)
	):
		return GardenPlacementResult.invalid_placement()

	var existing_plant: PlantState = state.get_plants().get_plant(runtime_instance_id)
	var existing_decor: DecorationState = state.get_decorations().get_decoration(runtime_instance_id)
	if existing_plant == null and existing_decor == null:
		return GardenPlacementResult.item_not_found()

	var now_utc_seconds: int = game_clock.utc_now_seconds()
	if now_utc_seconds < 0:
		return GardenPlacementResult.invalid_input()

	return try_move_item_at(
		state,
		catalog,
		runtime_instance_id,
		target_zone_id,
		target_grid_x,
		target_grid_y,
		now_utc_seconds
	)
