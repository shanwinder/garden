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
var _visitors_by_id: Dictionary = {}
var _sorted_visitor_ids: Array[String] = []
var _decorations_by_id: Dictionary = {}
var _sorted_decoration_ids: Array[String] = []


## Private constructor. Use [method try_create] to instantiate.
func _init(
	plants_by_id: Dictionary,
	sorted_plant_ids: Array[String],
	visitors_by_id: Dictionary = {},
	sorted_visitor_ids: Array[String] = [],
	decorations_by_id: Dictionary = {},
	sorted_decoration_ids: Array[String] = []
) -> void:
	_plants_by_id = plants_by_id
	_sorted_plant_ids = sorted_plant_ids
	_visitors_by_id = visitors_by_id
	_sorted_visitor_ids = sorted_visitor_ids
	_decorations_by_id = decorations_by_id
	_sorted_decoration_ids = sorted_decoration_ids


## Validates and constructs a ContentCatalog from the supplied [param plant_definitions],
## optional [param visitor_definitions], and optional [param decoration_definitions].
##
## All-or-nothing validation rules:
## - Returns null if any entry in [param plant_definitions], [param visitor_definitions],
##   or [param decoration_definitions] is null.
## - Returns null if any entry has is_valid() == false.
## - Returns null if there are duplicate definition IDs within plants, visitors, or decorations.
## - Returns a valid ContentCatalog if inputs are empty or all entries are valid and unique.
##
## Does not mutate caller's Arrays. Preserves exact Resource references.
static func try_create(
	plant_definitions: Array[PlantDefinition],
	visitor_definitions: Array[VisitorDefinition] = [],
	decoration_definitions: Array[DecorationDefinition] = []
) -> ContentCatalog:
	var plants_map: Dictionary = {}
	var plant_ids: Array[String] = []

	for definition: PlantDefinition in plant_definitions:
		if definition == null:
			return null

		if not definition.is_valid():
			return null

		var def_id: String = definition.id
		if plants_map.has(def_id):
			return null

		plants_map[def_id] = definition
		plant_ids.append(def_id)

	var visitors_map: Dictionary = {}
	var visitor_ids: Array[String] = []

	for visitor_def: VisitorDefinition in visitor_definitions:
		if visitor_def == null:
			return null

		if not visitor_def.is_valid():
			return null

		var visitor_id: String = visitor_def.id
		if visitors_map.has(visitor_id):
			return null

		visitors_map[visitor_id] = visitor_def
		visitor_ids.append(visitor_id)

	var decorations_map: Dictionary = {}
	var decoration_ids: Array[String] = []

	for decoration_def: DecorationDefinition in decoration_definitions:
		if decoration_def == null:
			return null

		if not decoration_def.is_valid():
			return null

		var decoration_id: String = decoration_def.id
		if decorations_map.has(decoration_id):
			return null

		decorations_map[decoration_id] = decoration_def
		decoration_ids.append(decoration_id)

	plant_ids.sort()
	visitor_ids.sort()
	decoration_ids.sort()

	return ContentCatalog.new(
		plants_map,
		plant_ids,
		visitors_map,
		visitor_ids,
		decorations_map,
		decoration_ids
	)


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


## Returns a new Array containing all plant definition IDs in deterministic ascending order.
## Mutating the returned Array does not mutate the catalog.
func get_all_plant_ids() -> Array[String]:
	return _sorted_plant_ids.duplicate()


## Returns true if the catalog contains a visitor definition with the exact [param definition_id].
## Pure query: side-effect free, no ID normalization, no push_error on miss.
func has_visitor(definition_id: String) -> bool:
	return _visitors_by_id.has(definition_id)


## Returns the exact VisitorDefinition reference for [param definition_id], or null if not found.
## Pure query: side-effect free, no ID normalization, no push_error on miss.
func get_visitor(definition_id: String) -> VisitorDefinition:
	return _visitors_by_id.get(definition_id, null)


## Returns the total number of visitor definitions in the catalog.
func get_visitor_count() -> int:
	return _sorted_visitor_ids.size()


## Returns a new Array containing all VisitorDefinition references in deterministic ascending ID order.
## Mutating the returned Array does not mutate the catalog.
func get_all_visitors() -> Array[VisitorDefinition]:
	var result: Array[VisitorDefinition] = []
	result.resize(_sorted_visitor_ids.size())
	for i: int in range(_sorted_visitor_ids.size()):
		var def_id: String = _sorted_visitor_ids[i]
		result[i] = _visitors_by_id[def_id]
	return result


## Returns a new Array containing all visitor definition IDs in deterministic ascending order.
## Mutating the returned Array does not mutate the catalog.
func get_all_visitor_ids() -> Array[String]:
	return _sorted_visitor_ids.duplicate()


## Returns true if the catalog contains a decoration definition with the exact [param definition_id].
## Pure query: side-effect free, no ID normalization, no push_error on miss.
func has_decoration(definition_id: String) -> bool:
	return _decorations_by_id.has(definition_id)


## Returns the exact DecorationDefinition reference for [param definition_id], or null if not found.
## Pure query: side-effect free, no ID normalization, no push_error on miss.
func get_decoration(definition_id: String) -> DecorationDefinition:
	return _decorations_by_id.get(definition_id, null)


## Returns the total number of decoration definitions in the catalog.
func get_decoration_count() -> int:
	return _sorted_decoration_ids.size()


## Returns a new Array containing all DecorationDefinition references in deterministic ascending ID order.
## Mutating the returned Array does not mutate the catalog.
func get_all_decorations() -> Array[DecorationDefinition]:
	var result: Array[DecorationDefinition] = []
	result.resize(_sorted_decoration_ids.size())
	for i: int in range(_sorted_decoration_ids.size()):
		var def_id: String = _sorted_decoration_ids[i]
		result[i] = _decorations_by_id[def_id]
	return result


## Returns a new Array containing all decoration definition IDs in deterministic ascending order.
## Mutating the returned Array does not mutate the catalog.
func get_all_decoration_ids() -> Array[String]:
	return _sorted_decoration_ids.duplicate()
