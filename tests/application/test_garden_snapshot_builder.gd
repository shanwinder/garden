## test_garden_snapshot_builder.gd
## Unit tests for GardenSnapshotBuilder application service.
class_name TestGardenSnapshotBuilder
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGardenSnapshotBuilder"


func run_tests() -> void:
	_test_null_inputs_and_empty_garden()
	_test_trait_accumulation_and_plant_counts()
	_test_maturity_count_across_time_and_clock_rollback()


func _create_production_catalog() -> ContentCatalog:
	var p_res: PlantContentLoadResult = PlantContentLoader.new().load_production_definitions()
	var v_res: VisitorContentLoadResult = VisitorContentLoader.new().load_production_definitions()
	return ContentCatalog.try_create(p_res.get_definitions(), v_res.get_definitions())


func _test_null_inputs_and_empty_garden() -> void:
	describe("GardenSnapshotBuilder returns empty snapshot for null inputs or empty GameState")
	var catalog: ContentCatalog = _create_production_catalog()
	var empty_state: GameState = GameState.new()

	var snap_null_state: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(null, catalog, 1000)
	assert_true(snap_null_state.is_empty_garden(), "Null state yields empty snapshot")

	var snap_null_cat: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(empty_state, null, 1000)
	assert_true(snap_null_cat.is_empty_garden(), "Null catalog yields empty snapshot")

	var snap_empty: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(empty_state, catalog, 1000)
	assert_true(snap_empty.is_empty_garden(), "Empty state yields empty snapshot")
	assert_eq(snap_empty.get_total_plant_count(), 0, "Total plant count is 0")
	assert_eq(snap_empty.get_mature_plant_count(), 0, "Mature plant count is 0")
	assert_eq(snap_empty.get_active_traits().size(), 0, "No active traits")


func _test_trait_accumulation_and_plant_counts() -> void:
	describe("GardenSnapshotBuilder accumulates environmental traits and plant counts across multiple plants")
	var catalog: ContentCatalog = _create_production_catalog()
	var state: GameState = GameState.new()

	# Plant 2 jasmine (dense_vegetation, flower), 1 marigold (flower), 1 banana (fruit, perch, shade, shelter)
	state.get_plants().try_add_plant(PlantState.new("p-1", "plant.jasmine", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-2", "plant.jasmine", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-3", "plant.marigold", 1000))
	state.get_plants().try_add_plant(PlantState.new("p-4", "plant.banana", 1000))

	var snap: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, 1000)
	assert_eq(snap.get_total_plant_count(), 4, "Total plants = 4")
	assert_eq(snap.get_mature_plant_count(), 0, "0 mature at t = 1000")

	assert_eq(snap.get_plant_count_for_definition("plant.jasmine"), 2, "2 jasmine")
	assert_eq(snap.get_plant_count_for_definition("plant.marigold"), 1, "1 marigold")
	assert_eq(snap.get_plant_count_for_definition("plant.banana"), 1, "1 banana")
	assert_eq(snap.get_plant_count_for_definition("plant.chili"), 0, "0 chili")

	# Trait totals: flower = 2 (jasmine) + 1 (marigold) = 3; dense_vegetation = 2; fruit/perch/shade/shelter = 1
	assert_eq(snap.get_trait_count("flower"), 3, "flower count = 3")
	assert_eq(snap.get_trait_count("dense_vegetation"), 2, "dense_vegetation count = 2")
	assert_eq(snap.get_trait_count("fruit"), 1, "fruit count = 1")
	assert_eq(snap.get_trait_count("perch"), 1, "perch count = 1")
	assert_eq(snap.get_trait_count("shade"), 1, "shade count = 1")
	assert_eq(snap.get_trait_count("shelter"), 1, "shelter count = 1")
	assert_eq(snap.get_trait_count("water"), 0, "water count = 0")


func _test_maturity_count_across_time_and_clock_rollback() -> void:
	describe("GardenSnapshotBuilder tracks mature plant count across time and clamps clock rollback")
	var catalog: ContentCatalog = _create_production_catalog()
	var state: GameState = GameState.new()

	# Holy basil matures at +600s; chili matures at +1200s
	state.get_plants().try_add_plant(PlantState.new("basil-1", "plant.holy_basil", 1000))
	state.get_plants().try_add_plant(PlantState.new("chili-1", "plant.chili", 1000))

	# At t = 1599 (+599s): neither mature
	var snap_599: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, 1599)
	assert_eq(snap_599.get_total_plant_count(), 2, "2 total plants")
	assert_eq(snap_599.get_mature_plant_count(), 0, "0 mature at +599s")

	# At t = 1600 (+600s): basil mature, chili growing
	var snap_600: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, 1600)
	assert_eq(snap_600.get_mature_plant_count(), 1, "1 mature at +600s")

	# At t = 2200 (+1200s): both mature
	var snap_1200: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, 2200)
	assert_eq(snap_1200.get_mature_plant_count(), 2, "2 mature at +1200s")

	# Clock rollback before planted_at (t = 500 < 1000): clamped to PLANTED (0 mature), traits intact
	var snap_rollback: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, 500)
	assert_eq(snap_rollback.get_total_plant_count(), 2, "Total plants still 2 on rollback")
	assert_eq(snap_rollback.get_mature_plant_count(), 0, "Mature count clamped to 0 on rollback")
	assert_eq(snap_rollback.get_trait_count("food"), 2, "Trait counts remain intact on rollback")
