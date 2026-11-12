## test_garden_zone.gd
## Unit tests for GardenZone domain rules (Coarse Logical Grid dimensions,
## bounds validation, and First Expansion Adjacent Zone 2 unlock criteria).
class_name TestGardenZone
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGardenZone"


func run_tests() -> void:
	_test_type_contracts()
	_test_zone_ids_and_dimensions()
	_test_bounds_and_cell_enumeration()
	_test_first_expansion_unlock_rules()


func _test_type_contracts() -> void:
	describe("GardenZone extends RefCounted and is not Node or Resource")
	var obj: Variant = GardenZone.new()
	assert_true(obj is RefCounted, "GardenZone extends RefCounted")
	assert_false(obj is Node, "GardenZone is not a Node")
	assert_false(obj is Resource, "GardenZone is not a Resource")


func _test_zone_ids_and_dimensions() -> void:
	describe("Canonical zone IDs and coarse grid dimensions")
	assert_true(GardenZone.is_valid_zone_id(GardenZone.ZONE_MAIN), "zone.main is valid")
	assert_true(GardenZone.is_valid_zone_id(GardenZone.ZONE_ADJACENT_1), "zone.adjacent_1 is valid")
	assert_false(GardenZone.is_valid_zone_id(""), "Empty zone ID invalid")
	assert_false(GardenZone.is_valid_zone_id("zone.unknown"), "Unknown zone ID invalid")

	assert_eq(GardenZone.get_grid_width(GardenZone.ZONE_MAIN), 4, "Main zone width is 4")
	assert_eq(GardenZone.get_grid_height(GardenZone.ZONE_MAIN), 4, "Main zone height is 4")
	assert_eq(GardenZone.get_cell_count(GardenZone.ZONE_MAIN), 16, "Main zone has 16 cells")

	assert_eq(GardenZone.get_grid_width(GardenZone.ZONE_ADJACENT_1), 4, "Adjacent zone width is 4")
	assert_eq(GardenZone.get_grid_height(GardenZone.ZONE_ADJACENT_1), 3, "Adjacent zone height is 3")
	assert_eq(GardenZone.get_cell_count(GardenZone.ZONE_ADJACENT_1), 12, "Adjacent zone has 12 cells")

	assert_eq(GardenZone.get_cell_count("zone.invalid"), 0, "Invalid zone has 0 cells")


func _test_bounds_and_cell_enumeration() -> void:
	describe("Bounds checking and deterministic row-major cell enumeration")
	assert_true(GardenZone.is_within_bounds(GardenZone.ZONE_MAIN, 0, 0), "(0,0) in zone.main")
	assert_true(GardenZone.is_within_bounds(GardenZone.ZONE_MAIN, 3, 3), "(3,3) in zone.main")
	assert_false(GardenZone.is_within_bounds(GardenZone.ZONE_MAIN, -1, 0), "(-1,0) out of bounds")
	assert_false(GardenZone.is_within_bounds(GardenZone.ZONE_MAIN, 4, 0), "(4,0) out of bounds")
	assert_false(GardenZone.is_within_bounds(GardenZone.ZONE_MAIN, 0, 4), "(0,4) out of bounds")
	assert_false(GardenZone.is_within_bounds(GardenZone.ZONE_ADJACENT_1, 0, 2) == false, "(0,2) in zone.adjacent_1")
	assert_false(GardenZone.is_within_bounds(GardenZone.ZONE_ADJACENT_1, 0, 3), "(0,3) out of bounds in zone.adjacent_1")

	var main_cells: Array[Vector2i] = GardenZone.get_all_cells_for_zone(GardenZone.ZONE_MAIN)
	assert_eq(main_cells.size(), 16, "16 cells returned for zone.main")
	assert_eq(main_cells[0], Vector2i(0, 0), "First cell is (0,0)")
	assert_eq(main_cells[1], Vector2i(1, 0), "Second cell is (1,0) (row-major)")
	assert_eq(main_cells[4], Vector2i(0, 1), "Fifth cell wraps to (0,1)")
	assert_eq(main_cells[15], Vector2i(3, 3), "Last cell is (3,3)")


func _test_first_expansion_unlock_rules() -> void:
	describe("Adjacent Zone 2 unlocks automatically at Living Garden (45+ pts) or Day 7 milestone without coin grinding")
	var empty_snapshot: GardenSnapshot = GardenSnapshot.new({}, {}, 0, 0, {}, 0)
	var empty_journal: JournalState = JournalState.new()

	assert_true(GardenZone.is_zone_unlocked(GardenZone.ZONE_MAIN, empty_snapshot, empty_journal), "zone.main always unlocked")
	assert_false(GardenZone.is_zone_unlocked(GardenZone.ZONE_ADJACENT_1, empty_snapshot, empty_journal), "zone.adjacent_1 starts locked")
	assert_eq(GardenZone.get_unlocked_zone_ids(empty_snapshot, empty_journal), [GardenZone.ZONE_MAIN], "Only zone.main unlocked initially")

	# Unlock path A: Score >= 45 pts (Living Garden)
	# 3 mature plants (3*3 + 3*2 = 15) + 2 decorations (8) + 4 traits (12) + 2 discoveries (10) = 45 pts
	var living_snapshot: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1, "food": 1, "shade": 1, "water": 1},
		{"plant.holy_basil": 3},
		3,
		3,
		{"decoration.clay_jar": 2},
		2
	)
	var j_two: JournalState = JournalState.new()
	j_two.try_put_record(DiscoveryRecord.new("plant.holy_basil", 100, 1))
	j_two.try_put_record(DiscoveryRecord.new("visitor.butterfly", 200, 1))
	assert_eq(GardenProgressionStage.compute_score(living_snapshot, j_two), 45, "Score reaches exactly 45")
	assert_true(GardenZone.is_zone_unlocked(GardenZone.ZONE_ADJACENT_1, living_snapshot, j_two), "zone.adjacent_1 unlocks at 45 pts")
	assert_eq(
		GardenZone.get_unlocked_zone_ids(living_snapshot, j_two),
		[GardenZone.ZONE_MAIN, GardenZone.ZONE_ADJACENT_1],
		"Both zones unlocked at Living Garden"
	)

	# Unlock path B: Day 7 First Expansion milestone (8+ journal discoveries) even with empty snapshot
	var j_eight: JournalState = JournalState.new()
	var disc_ids: Array[String] = [
		"plant.holy_basil", "plant.chili", "plant.jasmine", "plant.marigold",
		"plant.banana", "visitor.butterfly", "visitor.bird", "visitor.cat",
	]
	for i: int in range(disc_ids.size()):
		j_eight.try_put_record(DiscoveryRecord.new(disc_ids[i], 100 + i, 1))
	assert_true(
		GardenZone.is_zone_unlocked(GardenZone.ZONE_ADJACENT_1, empty_snapshot, j_eight),
		"zone.adjacent_1 unlocks via Day 7 discovery milestone (8+ discoveries)"
	)
