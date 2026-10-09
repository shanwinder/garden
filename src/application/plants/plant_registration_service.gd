## plant_registration_service.gd
## Application service coordinating validated plant registration.
##
## Enforces content compatibility and runtime instance uniqueness BEFORE
## mutating the authoritative GameState plant collection.
##
## Architectural rules:
## - Belongs to the application layer (src/application/plants/).
## - Pure application service: extends RefCounted.
## - Not a Node, Resource, Autoload, singleton, or global mutable manager.
## - Does not own a second GameState.
## - Receives all dependencies explicitly; does not look up AppRoot, SceneTree, singletons.
## - Independent of SceneTree, FileAccess, ResourceLoader, LocalSaveRepository, GameClock, RandomSource, and UI.
## - Does not generate IDs or timestamps.
## - Validation order is deterministic:
##   1. INVALID_INPUT if state == null, catalog == null, instance_id is empty,
##      planted_at < 0, or definition_id is syntactically invalid / not in "plant." namespace.
##   2. UNKNOWN_DEFINITION_ID if catalog does not contain definition_id.
##   3. DUPLICATE_INSTANCE_ID if collection already contains instance_id.
##   4. Construct PlantState, verify is_valid(), and try_add_plant(). If failed -> INSERTION_REJECTED.
##   5. Otherwise -> REGISTERED.
## - All-or-nothing failure policy: every failure leaves GameState completely untouched.
## - Exact string comparisons: no trimming, lowercase, uppercase, prefixing, or alias generation.
class_name PlantRegistrationService
extends RefCounted


## Validates inputs and registers a new PlantState into the authoritative [param state].
static func try_register_plant(
	state: GameState,
	catalog: ContentCatalog,
	instance_id: String,
	definition_id: String,
	planted_at: int
) -> PlantRegistrationResult:
	# 1. Input structural validation precedence
	if state == null or catalog == null:
		return PlantRegistrationResult.invalid_input()

	if instance_id.is_empty():
		return PlantRegistrationResult.invalid_input()

	if planted_at < 0:
		return PlantRegistrationResult.invalid_input()

	if not _is_structurally_valid_plant_definition_id(definition_id):
		return PlantRegistrationResult.invalid_input()

	var plant_collection: PlantCollectionState = state.get_plants()
	if plant_collection == null:
		return PlantRegistrationResult.invalid_input()

	# 2. Catalog membership validation
	if not catalog.has_plant(definition_id):
		return PlantRegistrationResult.unknown_definition_id()

	# 3. Runtime instance uniqueness validation
	if plant_collection.has_runtime_instance_id(instance_id):
		return PlantRegistrationResult.duplicate_instance_id()

	# 4. PlantState construction and authoritative collection insertion
	var plant: PlantState = PlantState.new(instance_id, definition_id, planted_at)
	if not plant.is_valid():
		return PlantRegistrationResult.insertion_rejected()

	var inserted: bool = plant_collection.try_add_plant(plant)
	if not inserted:
		return PlantRegistrationResult.insertion_rejected()

	return PlantRegistrationResult.registered(plant)


static func _is_structurally_valid_plant_definition_id(def_id: String) -> bool:
	if def_id.is_empty():
		return false
	if not def_id.begins_with(PlantDefinition.PLANT_NAMESPACE_PREFIX):
		return false
	return StableContentId.is_valid(def_id)
