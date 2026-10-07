## content_catalog.gd
## Validated in-memory content catalog for PlantDefinition resources.
##
## Establishes the application-level boundary between authored static definition data
## and domain/application logic. Provides deterministic, validated lookup for
## PlantDefinition resources.
##
## Architectural rules:
## - Belongs to the application content layer (src/application/content/).
## - Lightweight in-memory catalog: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Consumes domain PlantDefinition objects; domain does not depend on ContentCatalog.
## - Task 6.1 scope: PlantDefinition only. No speculative categories or storage.
## - Factory-based construction (try_create): all-or-nothing validation.
## - Empty catalog is valid: try_create([]) returns a valid empty ContentCatalog.
## - Rejects null definitions, definitions where is_valid() is false, and duplicate definition IDs.
## - Exact definition IDs required; no lowercase, trim, or normalization.
## - Retains exact PlantDefinition Resource references (authored read-only data; no deep cloning).
## - Immutable and read-only after construction; no public mutation APIs.
## - Internal storage is private; encapsulated return collections (new Array per call).
## - Deterministic ascending definition-ID enumeration order for get_all_plants() and get_all_plant_ids().
## - Pure query API: side-effect free, deterministic, no error spam on lookup miss.
## - Independent of SceneTree, filesystem (ResourceLoader, DirAccess, FileAccess), GameClock, and RandomSource.
## - No runtime instance (PlantState) or growth calculation responsibility.
class_name ContentCatalog
extends RefCounted

var _plants_by_id: Dictionary = {}
var _sorted_plant_ids: Array[String] = []


## Private constructor. Use [method try_create] to instantiate.
func _init(plants_by_id: Dictionary, sorted_plant_ids: Array[String]) -> void:
	_plants_by_id = plants_by_id
	_sorted_plant_ids = sorted_plant_ids


## Validates and constructs a ContentCatalog from the supplied [param plant_definitions].
##
## All-or-nothing validation rules:
## - Returns null if any entry in [param plant_definitions] is null.
## - Returns null if any entry in [param plant_definitions] has is_valid() == false.
## - Returns null if there are duplicate definition IDs.
## - Returns a valid ContentCatalog if [param plant_definitions] is empty or all entries are valid and unique.
##
## Does not mutate caller's Array. Preserves exact PlantDefinition references.
static func try_create(plant_definitions: Array[PlantDefinition]) -> ContentCatalog:
	var plants_map: Dictionary = {}
	var ids: Array[String] = []

	for definition: PlantDefinition in plant_definitions:
		if definition == null:
			return null

		if not definition.is_valid():
			return null

		var def_id: String = definition.id
		if plants_map.has(def_id):
			return null

		plants_map[def_id] = definition
		ids.append(def_id)

	ids.sort()

	return ContentCatalog.new(plants_map, ids)


## Returns true if the catalog contains a plant definition with the exact [param definition_id].
## Pure query: side-effect free, no ID normalization, no push_error on miss.
func has_plant(definition_id: String) -> bool:
	return _plants_by_id.has(definition_id)


## Returns the exact PlantDefinition reference for [param definition_id], or null if not found.
## Pure query: side-effect free, no ID normalization, no push_error on miss.
func get_plant(definition_id: String) -> PlantDefinition:
	return _plants_by_id.get(definition_id, null)


## Returns the total number of plant definitions in the catalog.
func get_plant_count() -> int:
	return _sorted_plant_ids.size()


## Returns a new Array containing all PlantDefinition references in deterministic ascending ID order.
## Mutating the returned Array does not mutate the catalog.
func get_all_plants() -> Array[PlantDefinition]:
	var result: Array[PlantDefinition] = []
	result.resize(_sorted_plant_ids.size())
	for i: int in range(_sorted_plant_ids.size()):
		var def_id: String = _sorted_plant_ids[i]
		result[i] = _plants_by_id[def_id]
	return result


## Returns a new Array containing all definition IDs in deterministic ascending order.
## Mutating the returned Array does not mutate the catalog.
func get_all_plant_ids() -> Array[String]:
	return _sorted_plant_ids.duplicate()
