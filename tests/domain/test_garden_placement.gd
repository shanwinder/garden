## test_garden_placement.gd
## Unit tests for GardenPlacement domain rules (occupancy, bounds, occupant lookup,
## free cell resolution, and items-in-zone sorting).
class_name TestGardenPlacement
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGardenPlacement"


func run_tests() -> void:
	_test_type_contracts()
	_test_cell_occupancy_and_occupant_queries()
	_test_can_place_at_and_free_cell_search()
	_test_zone_items_sorting_and_counts()


func _test_type_contracts() -> void:
	describe("GardenPlacement extends RefCounted and is not Node or Resource")
	var obj: Variant = GardenPlacement.new()
	assert_true(obj is RefCounted, "GardenPlacement extends RefCounted")
	assert_false(obj is Node, "GardenPlacement is not a Node")
	assert_false(obj is Resource, "GardenPlacement is not a Resource")


func _test_cell_occupancy_and_occupant_queries() -> void:
	describe("Cell occupancy detection and typed occupant descriptor lookup")
	var state: GameState = GameState.new()
	var plant: PlantState = PlantState.new("p-1", "plant.holy_basil", 1000, GardenZone.ZONE_MAIN, 1, 2)
	var decor: DecorationState = DecorationState.new("d-1", "decoration.clay_jar", 1100, GardenZone.ZONE_MAIN, 3, 0)
	state.get_plants().try_add_plant(plant)
	state.get_decorations().try_add_decoration(decor)

	assert_true(GardenPlacement.is_cell_occupied(state, GardenZone.ZONE_MAIN, 1, 2), "Plant cell (1,2) is occupied")
	assert_true(GardenPlacement.is_cell_occupied(state, GardenZone.ZONE_MAIN, 3, 0), "Decor cell (3,0) is occupied")
	assert_false(GardenPlacement.is_cell_occupied(state, GardenZone.ZONE_MAIN, 0, 0), "Cell (0,0) is empty")
	assert_false(GardenPlacement.is_cell_occupied(state, GardenZone.ZONE_ADJACENT_1, 1, 2), "Different zone not occupied")

	# Ignore instance ID (for self-repositioning checks)
	assert_false(
		GardenPlacement.is_cell_occupied(state, GardenZone.ZONE_MAIN, 1, 2, "p-1"),
		"Cell (1,2) reports unoccupied when ignoring occupant p-1"
	)
	assert_true(
		GardenPlacement.is_cell_occupied(state, GardenZone.ZONE_MAIN, 1, 2, "p-other"),
		"Cell (1,2) still reports occupied when ignoring another ID"
	)

	# Occupant lookup
	var occ_plant: Dictionary = GardenPlacement.get_occupant_at(state, GardenZone.ZONE_MAIN, 1, 2)
	assert_eq(occ_plant.get("kind"), GardenPlacement.KIND_PLANT, "Kind is plant")
	assert_eq(occ_plant.get("instance_id"), "p-1", "Instance ID is p-1")
	assert_eq(occ_plant.get("definition_id"), "plant.holy_basil", "Definition ID is plant.holy_basil")

	var occ_decor: Dictionary = GardenPlacement.get_occupant_at(state, GardenZone.ZONE_MAIN, 3, 0)
	assert_eq(occ_decor.get("kind"), GardenPlacement.KIND_DECORATION, "Kind is decoration")
	assert_eq(occ_decor.get("instance_id"), "d-1", "Instance ID is d-1")
	assert_eq(occ_decor.get("definition_id"), "decoration.clay_jar", "Definition ID is decoration.clay_jar")

	var occ_none: Dictionary = GardenPlacement.get_occupant_at(state, GardenZone.ZONE_MAIN, 0, 0)
	assert_eq(occ_none.get("kind"), GardenPlacement.KIND_NONE, "Kind is none for empty cell")
	assert_eq(occ_none.get("instance_id"), "", "Empty instance ID")


func _test_can_place_at_and_free_cell_search() -> void:
	describe("can_place_at validation and deterministic first-free-cell resolution")
	var state: GameState = GameState.new()
	var unlocked: Array[String] = [GardenZone.ZONE_MAIN]

	assert_true(GardenPlacement.can_place_at(state, unlocked, GardenZone.ZONE_MAIN, 0, 0), "Can place in empty unlocked cell")
	assert_false(GardenPlacement.can_place_at(state, unlocked, GardenZone.ZONE_MAIN, 4, 0), "Cannot place out of grid width")
	assert_false(GardenPlacement.can_place_at(state, unlocked, GardenZone.ZONE_MAIN, 0, 4), "Cannot place out of grid height")
	assert_false(GardenPlacement.can_place_at(state, unlocked, GardenZone.ZONE_ADJACENT_1, 0, 0), "Cannot place in locked zone")

	# Occupy (0,0) and (1,0)
	state.get_plants().try_add_plant(PlantState.new("p-00", "plant.chili", 1000, GardenZone.ZONE_MAIN, 0, 0))
	state.get_plants().try_add_plant(PlantState.new("p-10", "plant.jasmine", 1000, GardenZone.ZONE_MAIN, 1, 0))

	assert_false(GardenPlacement.can_place_at(state, unlocked, GardenZone.ZONE_MAIN, 0, 0), "Cannot place in occupied cell (0,0)")

	var free: Dictionary = GardenPlacement.find_first_free_cell(state, unlocked)
	assert_true(free.get("found"), "Free cell found")
	assert_eq(free.get("zone_id"), GardenZone.ZONE_MAIN, "Found in zone.main")
	assert_eq(free.get("grid_x"), 2, "Row-major next X is 2")
	assert_eq(free.get("grid_y"), 0, "Row-major next Y is 0")


func _test_zone_items_sorting_and_counts() -> void:
	describe("Zone occupant count queries and deterministic spatial sorting")
	var state: GameState = GameState.new()
	assert_eq(GardenPlacement.get_occupied_cell_count(state, GardenZone.ZONE_MAIN), 0, "Initial occupied count is 0")
	assert_eq(GardenPlacement.get_free_cell_count(state, GardenZone.ZONE_MAIN), 16, "Initial free count is 16")

	# Insert out of spatial order
	state.get_plants().try_add_plant(PlantState.new("p-b", "plant.holy_basil", 1000, GardenZone.ZONE_MAIN, 2, 1))
	state.get_plants().try_add_plant(PlantState.new("p-a", "plant.chili", 1000, GardenZone.ZONE_MAIN, 0, 0))
	state.get_decorations().try_add_decoration(DecorationState.new("d-1", "decoration.bench", 1000, GardenZone.ZONE_MAIN, 1, 0))

	assert_eq(GardenPlacement.get_occupied_cell_count(state, GardenZone.ZONE_MAIN), 3, "Occupied count is 3")
	assert_eq(GardenPlacement.get_free_cell_count(state, GardenZone.ZONE_MAIN), 13, "Free count is 13")

	var items: Dictionary = GardenPlacement.get_items_in_zone(state, GardenZone.ZONE_MAIN)
	var plants: Array[PlantState] = items.get("plants") as Array[PlantState]
	assert_eq(plants.size(), 2, "2 plants in zone")
	assert_eq(plants[0].get_runtime_instance_id(), "p-a", "First plant is p-a at (0,0)")
	assert_eq(plants[1].get_runtime_instance_id(), "p-b", "Second plant is p-b at (2,1)")
