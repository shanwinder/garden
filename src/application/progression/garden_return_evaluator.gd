## garden_return_evaluator.gd
## Stateless application service for computing away/offline progression summaries.
##
## Evaluates what changed in the garden between a previous UTC timestamp and a current
## UTC timestamp per GAME_DESIGN.md Sections 7 & 19 and ARCHITECTURE.md Sections 13, 14, 25 & 26.
##
## Architectural rules:
## - Belongs to the application progression layer (src/application/progression/).
## - Pure stateless application service: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Receives GameState, ContentCatalog, and GameClock explicitly.
## - Prevalidates all inputs BEFORE sampling GameClock.utc_now_seconds().
## - Samples GameClock at most once per evaluate_return_from_now() call.
## - Clamps negative elapsed time (clock rollback) to 0 without corrupting or mutating state.
## - O(N) in placed plants and O(1) in elapsed time (no per-second simulation loops).
## - Read-only: never mutates GameState, PlantCollectionState, EconomyState, or JournalState
##   (offline visitors are never automatically recorded as player discoveries).
class_name GardenReturnEvaluator
extends RefCounted


## Evaluates garden progression and atmospheric changes between [param previous_utc_seconds]
## and [param current_utc_seconds].
##
## Returns null if [param state] or [param catalog] is null, [param state.get_plants()] is null,
## or either timestamp is negative (< 0).
static func evaluate_return_between(
	state: GameState,
	catalog: ContentCatalog,
	previous_utc_seconds: int,
	current_utc_seconds: int
) -> GardenReturnSummary:
	if state == null or catalog == null:
		return null

	var plant_collection: PlantCollectionState = state.get_plants()
	if plant_collection == null:
		return null

	if previous_utc_seconds < 0 or current_utc_seconds < 0:
		return null

	var clock_rolled_back: bool = current_utc_seconds < previous_utc_seconds
	var elapsed_seconds: int = maxi(0, current_utc_seconds - previous_utc_seconds)

	var previous_time_period: String = GardenTimePeriod.period_for_utc_seconds(previous_utc_seconds)
	var current_time_period: String = GardenTimePeriod.period_for_utc_seconds(current_utc_seconds)
	var previous_weather_state: String = GardenWeather.weather_for_utc_seconds(previous_utc_seconds)
	var current_weather_state: String = GardenWeather.weather_for_utc_seconds(current_utc_seconds)

	var advanced_plant_ids: Array[String] = []
	var newly_matured_plant_ids: Array[String] = []
	var ready_to_harvest_count: int = 0

	var all_plants: Array[PlantState] = plant_collection.get_all_plants()
	for plant: PlantState in all_plants:
		if plant == null or not plant.is_valid():
			continue

		var def_id: String = plant.get_definition_id()
		if not catalog.has_plant(def_id):
			continue

		var definition: PlantDefinition = catalog.get_plant(def_id)
		if definition == null or not definition.is_valid():
			continue

		var current_stage: PlantGrowth.Stage = PlantGrowth.stage_for_state_at(
			plant,
			definition,
			current_utc_seconds
		)
		if current_stage == PlantGrowth.Stage.MATURE and definition.harvest_reward > 0:
			ready_to_harvest_count += 1

		if not clock_rolled_back and elapsed_seconds > 0:
			var previous_stage: PlantGrowth.Stage = PlantGrowth.stage_for_state_at(
				plant,
				definition,
				previous_utc_seconds
			)
			if (
				previous_stage != PlantGrowth.Stage.INVALID
				and current_stage != PlantGrowth.Stage.INVALID
				and int(current_stage) > int(previous_stage)
			):
				var instance_id: String = plant.get_runtime_instance_id()
				advanced_plant_ids.append(instance_id)
				if current_stage == PlantGrowth.Stage.MATURE and previous_stage != PlantGrowth.Stage.MATURE:
					newly_matured_plant_ids.append(instance_id)

	return GardenReturnSummary.new(
		previous_utc_seconds,
		current_utc_seconds,
		elapsed_seconds,
		clock_rolled_back,
		advanced_plant_ids,
		newly_matured_plant_ids,
		ready_to_harvest_count,
		previous_time_period,
		current_time_period,
		previous_weather_state,
		current_weather_state
	)


## Prevalidates inputs, samples [param game_clock] once, and evaluates changes since
## [param previous_utc_seconds].
static func evaluate_return_from_now(
	state: GameState,
	catalog: ContentCatalog,
	game_clock: GameClock,
	previous_utc_seconds: int
) -> GardenReturnSummary:
	if state == null or catalog == null or game_clock == null:
		return null

	if state.get_plants() == null:
		return null

	if previous_utc_seconds < 0:
		return null

	var now_utc_seconds: int = game_clock.utc_now_seconds()
	if now_utc_seconds < 0:
		return null

	return evaluate_return_between(
		state,
		catalog,
		previous_utc_seconds,
		now_utc_seconds
	)
