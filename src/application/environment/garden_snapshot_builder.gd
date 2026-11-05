## garden_snapshot_builder.gd
## Stateless application builder for deriving GardenSnapshot from authoritative state and catalog.
##
## Architectural rules:
## - Belongs to the application environment layer (src/application/environment/).
## - Stateless pure builder: extends RefCounted.
## - Does not mutate GameState, PlantCollectionState, or ContentCatalog.
## - Receives now_utc_seconds explicitly; does not access SystemGameClock or RandomSource.
## - Aggregates environmental traits from planted instances whose definitions exist in ContentCatalog.
## - Computes mature plant count via PlantGrowth.stage_for_state_at(...).
class_name GardenSnapshotBuilder
extends RefCounted


## Builds an immutable GardenSnapshot from [param state] and [param catalog] at [param now_utc_seconds].
static func build_snapshot(
	state: GameState,
	catalog: ContentCatalog,
	now_utc_seconds: int
) -> GardenSnapshot:
	if state == null or catalog == null or state.get_plants() == null:
		return GardenSnapshot.new()

	var trait_counts: Dictionary = {}
	var plant_counts_by_id: Dictionary = {}
	var total_plant_count: int = 0
	var mature_plant_count: int = 0
	var decoration_counts_by_id: Dictionary = {}
	var total_decoration_count: int = 0

	var plants: Array[PlantState] = state.get_plants().get_all_plants()
	for plant_state: PlantState in plants:
		if plant_state == null or not plant_state.is_valid():
			continue

		var def_id: String = plant_state.get_definition_id()
		var definition: PlantDefinition = catalog.get_plant(def_id)
		if definition == null or not definition.is_valid():
			continue

		total_plant_count += 1
		var current_def_count: int = plant_counts_by_id.get(def_id, 0) as int
		plant_counts_by_id[def_id] = current_def_count + 1

		for trait_id: String in definition.environmental_traits:
			if EnvironmentalTrait.is_valid(trait_id):
				var current_trait_count: int = trait_counts.get(trait_id, 0) as int
				trait_counts[trait_id] = current_trait_count + 1

		if now_utc_seconds >= 0:
			var stage: PlantGrowth.Stage = PlantGrowth.stage_for_state_at(
				plant_state,
				definition,
				now_utc_seconds
			)
			if stage == PlantGrowth.Stage.MATURE:
				mature_plant_count += 1

	var decorations_collection: DecorationCollectionState = state.get_decorations()
	if decorations_collection != null:
		var decorations: Array[DecorationState] = decorations_collection.get_all_decorations()
		for decoration_state: DecorationState in decorations:
			if decoration_state == null or not decoration_state.is_valid():
				continue

			var decor_def_id: String = decoration_state.get_definition_id()
			var decor_def: DecorationDefinition = catalog.get_decoration(decor_def_id)
			if decor_def == null or not decor_def.is_valid():
				continue

			total_decoration_count += 1
			var current_decor_count: int = decoration_counts_by_id.get(decor_def_id, 0) as int
			decoration_counts_by_id[decor_def_id] = current_decor_count + 1

			for trait_id: String in decor_def.environmental_traits:
				if EnvironmentalTrait.is_valid(trait_id):
					var current_trait_count: int = trait_counts.get(trait_id, 0) as int
					trait_counts[trait_id] = current_trait_count + 1

	return GardenSnapshot.new(
		trait_counts,
		plant_counts_by_id,
		total_plant_count,
		mature_plant_count,
		decoration_counts_by_id,
		total_decoration_count
	)
