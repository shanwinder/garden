## plant_save_content_validator.gd
## Pure application-level validator for saved plant definition references.
##
## Establishes a safe validation boundary between loaded persistent PlantState
## references and the approved ContentCatalog.
##
## Architectural rules:
## - Belongs to src/application/content/
## - Extends RefCounted (pure domain/application validator; not a Node, Resource, Autoload, or manager).
## - Consumes GameState and ContentCatalog; pure query, zero side-effects.
## - Does not mutate GameState, PlantState, PlantCollectionState, or ContentCatalog.
## - Independent of SceneTree, filesystem (FileAccess, DirAccess, ResourceLoader),
##   JSON, GameStateCodec, AppRoot, GameClock, and RandomSource.
## - Does not alter, rename, or drop unknown PlantState instances.
class_name PlantSaveContentValidator
extends RefCounted


## Validates that all plant definition IDs referenced in [param state] exist in [param catalog].
##
## Returns:
## - INVALID_INPUT if [param state] is null or [param catalog] is null.
## - COMPATIBLE if plant collection is empty or all referenced definition IDs exist in [param catalog].
## - UNKNOWN_PLANT_IDS containing deduplicated, ascending-sorted unknown IDs if any definition ID is missing.
static func validate(
	state: GameState,
	catalog: ContentCatalog
) -> PlantSaveContentValidationResult:
	if state == null or catalog == null:
		return PlantSaveContentValidationResult.invalid_input()

	var plant_collection: PlantCollectionState = state.get_plants()
	if plant_collection == null:
		return PlantSaveContentValidationResult.invalid_input()

	var journal: JournalState = state.get_journal()
	if journal == null:
		return PlantSaveContentValidationResult.invalid_input()

	var decoration_collection: DecorationCollectionState = state.get_decorations()
	if decoration_collection == null:
		return PlantSaveContentValidationResult.invalid_input()

	var plants: Array[PlantState] = plant_collection.get_all_plants()
	var records: Array[DiscoveryRecord] = journal.get_all_records()
	var decorations: Array[DecorationState] = decoration_collection.get_all_decorations()
	if plants.is_empty() and records.is_empty() and decorations.is_empty():
		return PlantSaveContentValidationResult.compatible()

	var unknown_ids_map: Dictionary = {}

	for plant: PlantState in plants:
		if plant == null:
			return PlantSaveContentValidationResult.invalid_input()
		var def_id: String = plant.get_definition_id()
		if not catalog.has_plant(def_id):
			unknown_ids_map[def_id] = true

	for record: DiscoveryRecord in records:
		if record == null:
			return PlantSaveContentValidationResult.invalid_input()
		var disc_id: String = record.get_definition_id()
		if record.is_plant_discovery():
			if not catalog.has_plant(disc_id):
				unknown_ids_map[disc_id] = true
		elif record.is_visitor_discovery():
			if not catalog.has_visitor(disc_id):
				unknown_ids_map[disc_id] = true
		else:
			unknown_ids_map[disc_id] = true

	for decoration: DecorationState in decorations:
		if decoration == null:
			return PlantSaveContentValidationResult.invalid_input()
		var decor_id: String = decoration.get_definition_id()
		if not catalog.has_decoration(decor_id):
			unknown_ids_map[decor_id] = true

	if unknown_ids_map.is_empty():
		return PlantSaveContentValidationResult.compatible()

	var unknown_ids: Array[String] = []
	for key: String in unknown_ids_map.keys():
		unknown_ids.append(key)
	unknown_ids.sort()

	return PlantSaveContentValidationResult.unknown_plant_ids(unknown_ids)
