## test_garden_placement_service.gd
## Unit and integration tests for GardenPlacementService and
## GardenPlacementPersistenceCoordinator.
class_name TestGardenPlacementService
extends TestSuiteBase

const TEST_PRIMARY: String = "user://__test_placement_primary.json"
const TEST_TEMP: String = "user://__test_placement.tmp"
const TEST_BACKUP: String = "user://__test_placement.bak"
const TEST_CORRUPT: String = "user://__test_placement.corrupt"


func _init() -> void:
	suite_name = "TestGardenPlacementService"


func run_tests() -> void:
	_cleanup()
	_test_move_plant_success()
	_test_move_decoration_success()
	_test_move_rejections()
	_test_persistence_coordinator_saves_to_disk()
	_cleanup()


func _cleanup() -> void:
	for p: String in [TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_CORRUPT]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


func _create_catalog() -> ContentCatalog:
	var defs: Array[PlantDefinition] = [
		PlantDefinition.new(),
		PlantDefinition.new(),
	]
	defs[0].id = "plant.holy_basil"
	defs[0].sprout_after_seconds = 60
	defs[0].growing_after_seconds = 300
	defs[0].mature_after_seconds = 600
	defs[0].harvest_reward = 10

	defs[1].id = "plant.chili"
	defs[1].sprout_after_seconds = 30
	defs[1].growing_after_seconds = 120
	defs[1].mature_after_seconds = 300
	defs[1].harvest_reward = 20

	var dec_defs: Array[DecorationDefinition] = [
		DecorationDefinition.new(),
		DecorationDefinition.new(),
	]
	dec_defs[0].id = "decoration.bench"
	dec_defs[0].price = 25
	dec_defs[1].id = "decoration.clay_jar"
	dec_defs[1].price = 15
	dec_defs[1].environmental_traits = ["water"]

	return ContentCatalog.try_create(defs, [], dec_defs, [])


func _test_move_plant_success() -> void:
	describe("GardenPlacementService moves a plant to an unoccupied cell in an unlocked zone")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)
	var plant: PlantState = PlantState.new("p-1", "plant.holy_basil", 500, GardenZone.ZONE_MAIN, 0, 0)
	state.get_plants().try_add_plant(plant)

	var res: GardenPlacementResult = GardenPlacementService.try_move_item_now(
		state, catalog, clock, "p-1", GardenZone.ZONE_MAIN, 2, 3
	)
	assert_true(res.is_moved(), "Move succeeded")
	assert_eq(res.get_status(), GardenPlacementResult.MOVED, "Status is MOVED")
	assert_eq(res.get_item_kind(), GardenPlacement.KIND_PLANT, "Item kind is plant")
	assert_eq(res.get_zone_id(), GardenZone.ZONE_MAIN, "Zone ID is zone.main")
	assert_eq(res.get_grid_x(), 2, "New X is 2")
	assert_eq(res.get_grid_y(), 3, "New Y is 3")

	var updated: PlantState = state.get_plants().get_plant("p-1")
	assert_eq(updated.get_grid_x(), 2, "State grid_x updated")
	assert_eq(updated.get_grid_y(), 3, "State grid_y updated")
	assert_eq(updated.get_planted_at(), 500, "Planted_at timestamp preserved")


func _test_move_decoration_success() -> void:
	describe("GardenPlacementService moves a decoration to an unoccupied cell")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)
	var decor: DecorationState = DecorationState.new("d-1", "decoration.bench", 800, GardenZone.ZONE_MAIN, 1, 1)
	state.get_decorations().try_add_decoration(decor)

	var res: GardenPlacementResult = GardenPlacementService.try_move_item_now(
		state, catalog, clock, "d-1", GardenZone.ZONE_MAIN, 3, 2
	)
	assert_true(res.is_moved(), "Decoration move succeeded")
	assert_eq(res.get_item_kind(), GardenPlacement.KIND_DECORATION, "Kind is decoration")
	var updated: DecorationState = state.get_decorations().get_decoration("d-1")
	assert_eq(updated.get_grid_x(), 3, "Decoration X updated")
	assert_eq(updated.get_grid_y(), 2, "Decoration Y updated")
	assert_eq(updated.get_placed_at(), 800, "Placed_at timestamp preserved")


func _test_move_rejections() -> void:
	describe("GardenPlacementService rejects unknown item, same cell, cell occupied, out-of-bounds, locked zone")
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)
	state.get_plants().try_add_plant(PlantState.new("p-1", "plant.holy_basil", 500, GardenZone.ZONE_MAIN, 0, 0))
	state.get_plants().try_add_plant(PlantState.new("p-2", "plant.chili", 500, GardenZone.ZONE_MAIN, 1, 0))

	# Unknown item
	var r_unk: GardenPlacementResult = GardenPlacementService.try_move_item_now(
		state, catalog, clock, "non-existent", GardenZone.ZONE_MAIN, 2, 2
	)
	assert_eq(r_unk.get_status(), GardenPlacementResult.ITEM_NOT_FOUND, "Unknown item returns ITEM_NOT_FOUND")

	# Same cell
	var r_same: GardenPlacementResult = GardenPlacementService.try_move_item_now(
		state, catalog, clock, "p-1", GardenZone.ZONE_MAIN, 0, 0
	)
	assert_eq(r_same.get_status(), GardenPlacementResult.SAME_CELL, "Targeting current cell returns SAME_CELL")

	# Cell occupied
	var r_occ: GardenPlacementResult = GardenPlacementService.try_move_item_now(
		state, catalog, clock, "p-1", GardenZone.ZONE_MAIN, 1, 0
	)
	assert_eq(r_occ.get_status(), GardenPlacementResult.CELL_OCCUPIED, "Moving to occupied cell returns CELL_OCCUPIED")

	# Out of bounds
	var r_oob: GardenPlacementResult = GardenPlacementService.try_move_item_now(
		state, catalog, clock, "p-1", GardenZone.ZONE_MAIN, 4, 0
	)
	assert_eq(r_oob.get_status(), GardenPlacementResult.INVALID_PLACEMENT, "Out of bounds returns INVALID_PLACEMENT")

	# Locked zone (Adjacent Zone 2 is locked when garden has 0 score)
	var r_lock: GardenPlacementResult = GardenPlacementService.try_move_item_now(
		state, catalog, clock, "p-1", GardenZone.ZONE_ADJACENT_1, 0, 0
	)
	assert_eq(r_lock.get_status(), GardenPlacementResult.ZONE_LOCKED, "Locked zone returns ZONE_LOCKED")


func _test_persistence_coordinator_saves_to_disk() -> void:
	describe("GardenPlacementPersistenceCoordinator saves updated placement to disk")
	_cleanup()
	var state: GameState = GameState.new()
	var catalog: ContentCatalog = _create_catalog()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)
	var repo: LocalSaveRepository = LocalSaveRepository.new(TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_CORRUPT)
	var session: GameSession = GameSession.new(state)
	state.get_plants().try_add_plant(PlantState.new("p-save", "plant.holy_basil", 1000, GardenZone.ZONE_MAIN, 0, 0))
	repo.save(state)

	var cp_res: GardenPlacementCheckpointResult = GardenPlacementPersistenceCoordinator.try_move_item_and_save(
		session, catalog, clock, repo, "p-save", GardenZone.ZONE_MAIN, 3, 3
	)
	assert_true(cp_res.is_moved(), "Coordinator moved item")
	assert_true(cp_res.is_saved(), "Coordinator saved state")

	# Read from disk via new repo load
	var loaded_res: LocalSaveLoadResult = repo.load()
	assert_true(loaded_res.is_loaded(), "Save reloaded from disk")
	var loaded_plant: PlantState = loaded_res.get_state().get_plants().get_plant("p-save")
	assert_eq(loaded_plant.get_grid_x(), 3, "Reloaded plant X is 3")
	assert_eq(loaded_plant.get_grid_y(), 3, "Reloaded plant Y is 3")
	_cleanup()
