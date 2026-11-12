## garden_placement.gd
## Pure domain placement, cell occupancy, and zone query rules for Garden's
## Coarse Logical Grid + Zones model (ARCHITECTURE.md §19).
##
## Architectural rules:
## - Belongs to the domain placement layer (src/domain/placement/).
## - Pure domain class: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Deterministic, stateless, side-effect free; does not mutate GameState.
## - Never reads SceneTree, Screen/Viewport pixels, GameClock, or RandomSource.
class_name GardenPlacement
extends RefCounted

const KIND_NONE: String = ""
const KIND_PLANT: String = "plant"
const KIND_DECORATION: String = "decoration"


## Returns true if ([param zone_id], [param grid_x], [param grid_y]) is occupied by any plant
## or decoration in [param state] whose runtime_instance_id != [param ignore_instance_id].
static func is_cell_occupied(
	state: GameState,
	zone_id: String,
	grid_x: int,
	grid_y: int,
	ignore_instance_id: String = ""
) -> bool:
	if state == null or not GardenZone.is_valid_zone_id(zone_id):
		return false
	if grid_x < 0 or grid_y < 0:
		return false

	var plants: PlantCollectionState = state.get_plants()
	if plants != null:
		for plant: PlantState in plants.get_all_plants():
			if plant == null or not plant.is_valid():
				continue
			if not ignore_instance_id.is_empty() and plant.get_runtime_instance_id() == ignore_instance_id:
				continue
			if (
				plant.get_zone_id() == zone_id
				and plant.get_grid_x() == grid_x
				and plant.get_grid_y() == grid_y
			):
				return true

	var decorations: DecorationCollectionState = state.get_decorations()
	if decorations != null:
		for decor: DecorationState in decorations.get_all_decorations():
			if decor == null or not decor.is_valid():
				continue
			if not ignore_instance_id.is_empty() and decor.get_runtime_instance_id() == ignore_instance_id:
				continue
			if (
				decor.get_zone_id() == zone_id
				and decor.get_grid_x() == grid_x
				and decor.get_grid_y() == grid_y
			):
				return true

	return false


## Returns the deterministic occupant descriptor at ([param zone_id], [param grid_x], [param grid_y]).
## Keys: "kind" ("plant" | "decoration" | ""), "instance_id" (String), "definition_id" (String).
static func get_occupant_at(
	state: GameState,
	zone_id: String,
	grid_x: int,
	grid_y: int
) -> Dictionary:
	var plant: PlantState = get_plant_at_cell(state, zone_id, grid_x, grid_y)
	if plant != null:
		return {
			"kind": KIND_PLANT,
			"instance_id": plant.get_runtime_instance_id(),
			"definition_id": plant.get_definition_id(),
		}

	var decor: DecorationState = get_decoration_at_cell(state, zone_id, grid_x, grid_y)
	if decor != null:
		return {
			"kind": KIND_DECORATION,
			"instance_id": decor.get_runtime_instance_id(),
			"definition_id": decor.get_definition_id(),
		}

	return {
		"kind": KIND_NONE,
		"instance_id": "",
		"definition_id": "",
	}


## Returns the first PlantState in deterministic order at ([param zone_id], [param grid_x], [param grid_y]), or null.
static func get_plant_at_cell(
	state: GameState,
	zone_id: String,
	grid_x: int,
	grid_y: int
) -> PlantState:
	if state == null or state.get_plants() == null:
		return null
	if not GardenZone.is_valid_zone_id(zone_id) or grid_x < 0 or grid_y < 0:
		return null
	for plant: PlantState in state.get_plants().get_all_plants():
		if plant == null or not plant.is_valid():
			continue
		if (
			plant.get_zone_id() == zone_id
			and plant.get_grid_x() == grid_x
			and plant.get_grid_y() == grid_y
		):
			return plant
	return null


## Returns the first DecorationState in deterministic order at ([param zone_id], [param grid_x], [param grid_y]), or null.
static func get_decoration_at_cell(
	state: GameState,
	zone_id: String,
	grid_x: int,
	grid_y: int
) -> DecorationState:
	if state == null or state.get_decorations() == null:
		return null
	if not GardenZone.is_valid_zone_id(zone_id) or grid_x < 0 or grid_y < 0:
		return null
	for decor: DecorationState in state.get_decorations().get_all_decorations():
		if decor == null or not decor.is_valid():
			continue
		if (
			decor.get_zone_id() == zone_id
			and decor.get_grid_x() == grid_x
			and decor.get_grid_y() == grid_y
		):
			return decor
	return null


## Returns true if placing/moving an item at ([param zone_id], [param grid_x], [param grid_y])
## is valid, unlocked, within zone bounds, and unoccupied.
static func can_place_at(
	state: GameState,
	unlocked_zones: Array[String],
	zone_id: String,
	grid_x: int,
	grid_y: int,
	ignore_instance_id: String = ""
) -> bool:
	if state == null:
		return false
	if not GardenZone.is_valid_zone_id(zone_id):
		return false
	if not unlocked_zones.has(zone_id):
		return false
	if not GardenZone.is_within_bounds(zone_id, grid_x, grid_y):
		return false
	return not is_cell_occupied(state, zone_id, grid_x, grid_y, ignore_instance_id)


## Finds the first free cell across [param unlocked_zones] in deterministic row-major order,
## preferring [param preferred_zone_id] when valid and unlocked.
## Returns {"found": bool, "zone_id": String, "grid_x": int, "grid_y": int}.
static func find_first_free_cell(
	state: GameState,
	unlocked_zones: Array[String],
	preferred_zone_id: String = ""
) -> Dictionary:
	if state == null or unlocked_zones.is_empty():
		return {"found": false, "zone_id": "", "grid_x": -1, "grid_y": -1}

	var search_zones: Array[String] = []
	if not preferred_zone_id.is_empty() and GardenZone.is_valid_zone_id(preferred_zone_id) and unlocked_zones.has(preferred_zone_id):
		search_zones.append(preferred_zone_id)
	for zid: String in GardenZone.ALL_ZONE_IDS:
		if unlocked_zones.has(zid) and not search_zones.has(zid):
			search_zones.append(zid)

	var occupied: Dictionary = _build_occupied_cell_set(state)
	for zid: String in search_zones:
		var cells: Array[Vector2i] = GardenZone.get_all_cells_for_zone(zid)
		for cell: Vector2i in cells:
			var key: String = GardenZone.cell_key(zid, cell.x, cell.y)
			if not occupied.has(key):
				return {
					"found": true,
					"zone_id": zid,
					"grid_x": cell.x,
					"grid_y": cell.y,
				}

	return {"found": false, "zone_id": "", "grid_x": -1, "grid_y": -1}


## Returns the number of distinct occupied cells within [param zone_id]'s grid bounds.
static func get_occupied_cell_count(state: GameState, zone_id: String) -> int:
	if state == null or not GardenZone.is_valid_zone_id(zone_id):
		return 0
	var seen: Dictionary = {}
	var plants: PlantCollectionState = state.get_plants()
	if plants != null:
		for plant: PlantState in plants.get_all_plants():
			if plant != null and plant.is_valid() and plant.get_zone_id() == zone_id:
				if GardenZone.is_within_bounds(zone_id, plant.get_grid_x(), plant.get_grid_y()):
					seen[GardenZone.cell_key(zone_id, plant.get_grid_x(), plant.get_grid_y())] = true
	var decorations: DecorationCollectionState = state.get_decorations()
	if decorations != null:
		for decor: DecorationState in decorations.get_all_decorations():
			if decor != null and decor.is_valid() and decor.get_zone_id() == zone_id:
				if GardenZone.is_within_bounds(zone_id, decor.get_grid_x(), decor.get_grid_y()):
					seen[GardenZone.cell_key(zone_id, decor.get_grid_x(), decor.get_grid_y())] = true
	return seen.size()


## Returns the number of unoccupied cells within [param zone_id]'s grid bounds.
static func get_free_cell_count(state: GameState, zone_id: String) -> int:
	var total: int = GardenZone.get_cell_count(zone_id)
	if total <= 0:
		return 0
	return maxi(0, total - get_occupied_cell_count(state, zone_id))


## Returns all plants and decorations assigned to [param zone_id], sorted deterministically
## by (grid_y, grid_x, runtime_instance_id).
static func get_items_in_zone(state: GameState, zone_id: String) -> Dictionary:
	var zone_plants: Array[PlantState] = []
	var zone_decorations: Array[DecorationState] = []
	if state == null or not GardenZone.is_valid_zone_id(zone_id):
		return {"plants": zone_plants, "decorations": zone_decorations}

	if state.get_plants() != null:
		for plant: PlantState in state.get_plants().get_all_plants():
			if plant != null and plant.is_valid() and plant.get_zone_id() == zone_id:
				zone_plants.append(plant)
		zone_plants.sort_custom(func(a: PlantState, b: PlantState) -> bool:
			if a.get_grid_y() != b.get_grid_y():
				return a.get_grid_y() < b.get_grid_y()
			if a.get_grid_x() != b.get_grid_x():
				return a.get_grid_x() < b.get_grid_x()
			return a.get_runtime_instance_id() < b.get_runtime_instance_id()
		)

	if state.get_decorations() != null:
		for decor: DecorationState in state.get_decorations().get_all_decorations():
			if decor != null and decor.is_valid() and decor.get_zone_id() == zone_id:
				zone_decorations.append(decor)
		zone_decorations.sort_custom(func(a: DecorationState, b: DecorationState) -> bool:
			if a.get_grid_y() != b.get_grid_y():
				return a.get_grid_y() < b.get_grid_y()
			if a.get_grid_x() != b.get_grid_x():
				return a.get_grid_x() < b.get_grid_x()
			return a.get_runtime_instance_id() < b.get_runtime_instance_id()
		)

	return {"plants": zone_plants, "decorations": zone_decorations}


static func _build_occupied_cell_set(state: GameState) -> Dictionary:
	var occupied: Dictionary = {}
	if state == null:
		return occupied
	if state.get_plants() != null:
		for plant: PlantState in state.get_plants().get_all_plants():
			if plant != null and plant.is_valid():
				occupied[GardenZone.cell_key(plant.get_zone_id(), plant.get_grid_x(), plant.get_grid_y())] = true
	if state.get_decorations() != null:
		for decor: DecorationState in state.get_decorations().get_all_decorations():
			if decor != null and decor.is_valid():
				occupied[GardenZone.cell_key(decor.get_zone_id(), decor.get_grid_x(), decor.get_grid_y())] = true
	return occupied
