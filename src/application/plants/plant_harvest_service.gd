## plant_harvest_service.gd
## Application service coordinating validated plant harvesting, currency reward grant,
## and deterministic growth cycle reset.
##
## Enforces plant existence, catalog membership, maturity at the evaluated UTC timestamp,
## positive harvest reward, and economy capacity BEFORE mutating authoritative GameState.
##
## Architectural rules:
## - Belongs to the application layer (src/application/plants/).
## - Pure application service: extends RefCounted.
## - Not a Node, Resource, Autoload, singleton, or global mutable manager.
## - Does not own GameState, GameClock, or ContentCatalog.
## - Receives all dependencies explicitly; no global App or SceneTree access.
## - Independent of SceneTree, FileAccess, ResourceLoader, LocalSaveRepository, RandomSource, and UI.
## - Validation order in try_harvest_plant_at is deterministic:
##   1. INVALID_INPUT if state == null, catalog == null, runtime_instance_id is empty,
##      now_utc_seconds < 0, state.get_plants() == null, or state.get_economy() == null.
##   2. PLANT_NOT_FOUND if collection does not contain a valid PlantState for runtime_instance_id.
##   3. UNKNOWN_DEFINITION_ID if catalog does not contain a valid PlantDefinition for definition_id.
##   4. PLANT_NOT_MATURE if PlantGrowth.stage_for_state_at != PlantGrowth.Stage.MATURE.
##   5. INVALID_REWARD if definition.harvest_reward <= 0.
##   6. CURRENCY_GRANT_REJECTED if granting harvest_reward would exceed EconomyState.MAX_CURRENCY.
##   7. Construct new PlantState(runtime_instance_id, definition_id, now_utc_seconds) and replace
##      in PlantCollectionState; if rejected -> STATE_UPDATE_REJECTED.
##   8. Grant harvest_reward to EconomyState; if rejected -> rollback PlantState and return CURRENCY_GRANT_REJECTED.
##   9. Otherwise -> HARVESTED(updated_plant, reward).
## - All-or-nothing failure policy: every failure leaves GameState completely untouched.
class_name PlantHarvestService
extends RefCounted


## Validates inputs and harvests a mature plant at an explicit [param now_utc_seconds] timestamp,
## granting its harvest_reward to EconomyState and resetting its cycle planted_at to [param now_utc_seconds].
static func try_harvest_plant_at(
	state: GameState,
	catalog: ContentCatalog,
	runtime_instance_id: String,
	now_utc_seconds: int
) -> PlantHarvestResult:
	# 1. Input structural validation precedence
	if state == null or catalog == null:
		return PlantHarvestResult.invalid_input()

	if runtime_instance_id.is_empty():
		return PlantHarvestResult.invalid_input()

	if now_utc_seconds < 0:
		return PlantHarvestResult.invalid_input()

	var plant_collection: PlantCollectionState = state.get_plants()
	var economy: EconomyState = state.get_economy()
	if plant_collection == null or economy == null:
		return PlantHarvestResult.invalid_input()

	# 2. Plant lookup validation
	var existing_plant: PlantState = plant_collection.get_plant(runtime_instance_id)
	if existing_plant == null or not existing_plant.is_valid():
		return PlantHarvestResult.plant_not_found()

	# 3. Catalog definition lookup validation
	var definition_id: String = existing_plant.get_definition_id()
	var definition: PlantDefinition = catalog.get_plant(definition_id)
	if definition == null or not definition.is_valid():
		return PlantHarvestResult.unknown_definition_id()

	# 4. Maturity stage validation at now_utc_seconds
	var stage: PlantGrowth.Stage = PlantGrowth.stage_for_state_at(
		existing_plant,
		definition,
		now_utc_seconds
	)
	if stage != PlantGrowth.Stage.MATURE:
		return PlantHarvestResult.plant_not_mature()

	# 5. Positive harvest reward validation
	var reward: int = definition.harvest_reward
	if reward <= 0:
		return PlantHarvestResult.invalid_reward()

	# 6. Economy overflow precheck
	if reward > EconomyState.MAX_CURRENCY - economy.get_currency():
		return PlantHarvestResult.currency_grant_rejected()

	# 7. Construct reset PlantState and replace in PlantCollectionState
	var updated_plant: PlantState = PlantState.new(
		runtime_instance_id,
		definition_id,
		now_utc_seconds
	)
	if not updated_plant.is_valid():
		return PlantHarvestResult.state_update_rejected()

	var replaced: bool = plant_collection.try_replace_existing_plant(updated_plant)
	if not replaced:
		return PlantHarvestResult.state_update_rejected()

	# 8. Grant currency to EconomyState (with atomic rollback safeguard)
	var granted: bool = economy.grant_currency(reward)
	if not granted:
		plant_collection.try_replace_existing_plant(existing_plant)
		return PlantHarvestResult.currency_grant_rejected()

	return PlantHarvestResult.harvested(updated_plant, reward)


## Prevalidates dependencies, plant existence, definition validity, reward, and economy capacity
## strictly BEFORE sampling [param game_clock] once, then delegates to try_harvest_plant_at.
static func try_harvest_now(
	state: GameState,
	catalog: ContentCatalog,
	game_clock: GameClock,
	runtime_instance_id: String
) -> PlantHarvestResult:
	# 1. Dependency and input prevalidation before sampling clock
	if state == null or catalog == null or game_clock == null:
		return PlantHarvestResult.invalid_input()

	if runtime_instance_id.is_empty():
		return PlantHarvestResult.invalid_input()

	var plant_collection: PlantCollectionState = state.get_plants()
	var economy: EconomyState = state.get_economy()
	if plant_collection == null or economy == null:
		return PlantHarvestResult.invalid_input()

	# 2. Plant lookup prevalidation
	var existing_plant: PlantState = plant_collection.get_plant(runtime_instance_id)
	if existing_plant == null or not existing_plant.is_valid():
		return PlantHarvestResult.plant_not_found()

	# 3. Catalog definition prevalidation
	var definition: PlantDefinition = catalog.get_plant(existing_plant.get_definition_id())
	if definition == null or not definition.is_valid():
		return PlantHarvestResult.unknown_definition_id()

	# 4. Timestamp capture (utc_now_seconds called exactly once per valid command)
	var now_utc_seconds: int = game_clock.utc_now_seconds()
	if now_utc_seconds < 0:
		return PlantHarvestResult.invalid_input()

	# 5. Delegate full maturity + reward + economy + state update validation
	return try_harvest_plant_at(
		state,
		catalog,
		runtime_instance_id,
		now_utc_seconds
	)
