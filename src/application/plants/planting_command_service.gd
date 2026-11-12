## planting_command_service.gd
## Application service coordinating timestamp capture, runtime ID generation,
## and validated planting delegation.
##
## Architectural rules:
## - Belongs to the application layer (src/application/plants/).
## - Pure application service: extends RefCounted.
## - Not a Node, Resource, Autoload, singleton, or global mutable manager.
## - Does not own GameState, GameClock, RandomSource, or ContentCatalog.
## - Receives all dependencies explicitly; no global App or SceneTree access.
## - Does not access filesystem or persist state.
## - Prevalidation happens strictly BEFORE sampling clock or consuming RNG:
##   1. Require state != null. (INVALID_INPUT)
##   2. Require catalog != null. (INVALID_INPUT)
##   3. Require game_clock != null. (INVALID_INPUT)
##   4. Require random_source != null. (INVALID_INPUT)
##   5. Require state.get_plants() != null. (INVALID_INPUT)
##   6. Validate plant definition ID syntax and plant namespace. (INVALID_INPUT)
##   7. Verify catalog.has_plant(definition_id). (UNKNOWN_DEFINITION_ID)
## - Timestamp capture:
##   - Calls game_clock.utc_now_seconds() exactly once.
##   - If timestamp < 0: returns INVALID_INPUT (no RNG consumed).
## - ID generation:
##   - Calls PlantRuntimeIdGenerator.try_generate_unique_id().
##   - If candidate generation fails (empty string): returns ID_GENERATION_FAILED.
## - Authoritative insertion:
##   - Delegates to PlantRegistrationService.try_register_plant().
##   - Does not call PlantCollectionState.try_add_plant() directly.
class_name PlantingCommandService
extends RefCounted


## Validates dependencies, captures current UTC timestamp, resolves or validates
## Coarse Logical Grid + Zones placement, generates a unique runtime instance ID,
## and delegates registration to PlantRegistrationService.
static func try_plant_now(
	state: GameState,
	catalog: ContentCatalog,
	game_clock: GameClock,
	random_source: RandomSource,
	definition_id: String,
	zone_id: String = "",
	grid_x: int = -1,
	grid_y: int = -1
) -> PlantRegistrationResult:
	# 1-5. Dependency presence validation
	if state == null or catalog == null or game_clock == null or random_source == null:
		return PlantRegistrationResult.invalid_input()

	var plant_collection: PlantCollectionState = state.get_plants()
	if plant_collection == null:
		return PlantRegistrationResult.invalid_input()

	# 6. Plant definition ID structural syntax and namespace check
	if not _is_structurally_valid_plant_definition_id(definition_id):
		return PlantRegistrationResult.invalid_input()

	# 7. Catalog membership validation
	if not catalog.has_plant(definition_id):
		return PlantRegistrationResult.unknown_definition_id()

	# 8. Explicit placement structural check (before sampling clock or RNG)
	var is_auto_place: bool = zone_id.is_empty() and grid_x == -1 and grid_y == -1
	if not is_auto_place:
		if not GardenZone.is_valid_zone_id(zone_id) or not GardenZone.is_within_bounds(zone_id, grid_x, grid_y):
			return PlantRegistrationResult.invalid_placement()

	# 9. Timestamp capture (utc_now_seconds called exactly once per valid command)
	var planted_at: int = game_clock.utc_now_seconds()
	if planted_at < 0:
		return PlantRegistrationResult.invalid_input()

	# 10. Resolve unlocked zones and validate/assign grid cell before consuming RNG
	var snapshot: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, planted_at)
	var unlocked_zones: Array[String] = GardenZone.get_unlocked_zone_ids(snapshot, state.get_journal())
	var target_zone_id: String = zone_id
	var target_grid_x: int = grid_x
	var target_grid_y: int = grid_y

	if is_auto_place:
		var free_cell: Dictionary = GardenPlacement.find_first_free_cell(state, unlocked_zones)
		if not (free_cell.get("found", false) as bool):
			return PlantRegistrationResult.garden_full()
		target_zone_id = free_cell["zone_id"] as String
		target_grid_x = free_cell["grid_x"] as int
		target_grid_y = free_cell["grid_y"] as int
	else:
		if not unlocked_zones.has(target_zone_id):
			return PlantRegistrationResult.zone_locked()
		if GardenPlacement.is_cell_occupied(state, target_zone_id, target_grid_x, target_grid_y):
			return PlantRegistrationResult.cell_occupied()

	# 11. Runtime ID generation (consumes RNG only after all preconditions & placement checks pass)
	var instance_id: String = PlantRuntimeIdGenerator.try_generate_unique_id(
		plant_collection,
		random_source
	)
	if instance_id.is_empty():
		return PlantRegistrationResult.id_generation_failed()

	# 12. Authoritative registration delegation
	return PlantRegistrationService.try_register_plant(
		state,
		catalog,
		instance_id,
		definition_id,
		planted_at,
		target_zone_id,
		target_grid_x,
		target_grid_y
	)


static func _is_structurally_valid_plant_definition_id(def_id: String) -> bool:
	if def_id.is_empty():
		return false
	if not def_id.begins_with(PlantDefinition.PLANT_NAMESPACE_PREFIX):
		return false
	return StableContentId.is_valid(def_id)
