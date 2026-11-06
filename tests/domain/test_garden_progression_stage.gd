## test_garden_progression_stage.gd
## Unit tests for GardenProgressionStage and GardenProgressionSummary domain contracts.
class_name TestGardenProgressionStage
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGardenProgressionStage"


func run_tests() -> void:
	_test_type_contracts()
	_test_stage_and_guidance_vocabulary()
	_test_stage_for_score_thresholds_and_boundaries()
	_test_compute_score_and_evaluate_progression()
	_test_gentle_guidance_selection_progression()
	_test_null_inputs_handled_safely()


func _test_type_contracts() -> void:
	describe("GardenProgressionStage and GardenProgressionSummary extend RefCounted and are not Node or Resource")
	var stage_helper: Variant = GardenProgressionStage.new()
	assert_true(stage_helper is GardenProgressionStage, "Must be GardenProgressionStage")
	assert_true(stage_helper is RefCounted, "Must extend RefCounted")
	assert_false(stage_helper is Node, "Must not be a Node")
	assert_false(stage_helper is Resource, "Must not be a Resource")

	var summary: Variant = GardenProgressionStage.evaluate(null, null)
	assert_true(summary is GardenProgressionSummary, "Must be GardenProgressionSummary")
	assert_true(summary is RefCounted, "Must extend RefCounted")
	assert_false(summary is Node, "Must not be a Node")
	assert_false(summary is Resource, "Must not be a Resource")
	assert_true((summary as GardenProgressionSummary).is_valid(), "Evaluated summary is valid")


func _test_stage_and_guidance_vocabulary() -> void:
	describe("Canonical 5 progression stages and 6 guidance IDs validate accurately")
	var expected_stages: Array[String] = [
		"starting_garden",
		"growing_garden",
		"shady_garden",
		"living_garden",
		"happy_garden_home",
	]
	assert_eq(GardenProgressionStage.ALL_STAGES, expected_stages, "ALL_STAGES order matches")

	for i: int in range(expected_stages.size()):
		var stage_id: String = expected_stages[i]
		assert_true(GardenProgressionStage.is_valid_stage(stage_id), "Valid stage: %s" % stage_id)
		assert_eq(GardenProgressionStage.stage_index(stage_id), i, "Stage index for %s is %d" % [stage_id, i])

	assert_false(GardenProgressionStage.is_valid_stage(""), "Empty stage rejected")
	assert_false(GardenProgressionStage.is_valid_stage("unknown_stage"), "Unknown stage rejected")
	assert_eq(GardenProgressionStage.stage_index("unknown_stage"), -1, "Unknown stage index is -1")
	assert_eq(GardenProgressionStage.next_stage_after("starting_garden"), "growing_garden", "Next after starting")
	assert_eq(GardenProgressionStage.next_stage_after("happy_garden_home"), "", "No next stage after max")
	assert_eq(GardenProgressionStage.next_stage_after("invalid"), "", "Invalid stage has empty next stage")

	for gid: String in GardenProgressionStage.ALL_GUIDANCE_IDS:
		assert_true(GardenProgressionStage.is_valid_guidance_id(gid), "Valid guidance ID: %s" % gid)
	assert_false(GardenProgressionStage.is_valid_guidance_id(""), "Empty guidance rejected")
	assert_false(GardenProgressionStage.is_valid_guidance_id("guidance.unknown"), "Unknown guidance rejected")


func _test_stage_for_score_thresholds_and_boundaries() -> void:
	describe("stage_for_score maps exact threshold boundaries and clamps negative scores to starting_garden")
	assert_eq(GardenProgressionStage.stage_for_score(-50), "starting_garden", "Negative score clamped to starting_garden")
	assert_eq(GardenProgressionStage.stage_for_score(0), "starting_garden", "0 -> starting_garden")
	assert_eq(GardenProgressionStage.stage_for_score(9), "starting_garden", "9 -> starting_garden")
	assert_eq(GardenProgressionStage.stage_for_score(10), "growing_garden", "10 -> growing_garden")
	assert_eq(GardenProgressionStage.stage_for_score(24), "growing_garden", "24 -> growing_garden")
	assert_eq(GardenProgressionStage.stage_for_score(25), "shady_garden", "25 -> shady_garden")
	assert_eq(GardenProgressionStage.stage_for_score(44), "shady_garden", "44 -> shady_garden")
	assert_eq(GardenProgressionStage.stage_for_score(45), "living_garden", "45 -> living_garden")
	assert_eq(GardenProgressionStage.stage_for_score(69), "living_garden", "69 -> living_garden")
	assert_eq(GardenProgressionStage.stage_for_score(70), "happy_garden_home", "70 -> happy_garden_home")
	assert_eq(GardenProgressionStage.stage_for_score(250), "happy_garden_home", "250 -> happy_garden_home")


func _test_compute_score_and_evaluate_progression() -> void:
	describe("compute_score and evaluate derive exact establishment score, stage, and remaining points")
	# 1. Empty snapshot + empty journal -> 0 pts (starting_garden, next = growing_garden at 10)
	var empty_snap: GardenSnapshot = GardenSnapshot.new({}, {}, 0, 0)
	var journal: JournalState = JournalState.new()
	var s0: GardenProgressionSummary = GardenProgressionStage.evaluate(empty_snap, journal)
	assert_eq(s0.get_establishment_score(), 0, "Empty garden score is 0")
	assert_eq(s0.get_stage_id(), "starting_garden", "Empty garden stage is starting_garden")
	assert_eq(s0.get_stage_index(), 0, "Stage index is 0")
	assert_eq(s0.get_next_stage_id(), "growing_garden", "Next stage is growing_garden")
	assert_eq(s0.get_next_stage_threshold(), 10, "Next threshold is 10")
	assert_eq(s0.get_points_to_next_stage(), 10, "10 points needed for growing_garden")
	assert_false(s0.is_max_stage(), "Not max stage")

	# 2. 1 planted plant (3) + 1 active trait (3) + 1 discovery (5) = 11 pts -> growing_garden
	journal.try_record_sighting("plant.marigold", 1000)
	var snap_1: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1},
		{"plant.marigold": 1},
		1,
		0
	)
	var s1: GardenProgressionSummary = GardenProgressionStage.evaluate(snap_1, journal)
	assert_eq(s1.get_establishment_score(), 11, "1 plant + 1 trait + 1 discovery = 11 pts")
	assert_eq(s1.get_stage_id(), "growing_garden", "11 pts -> growing_garden")
	assert_eq(s1.get_stage_index(), 1, "Stage index is 1")
	assert_eq(s1.get_next_stage_id(), "shady_garden", "Next stage is shady_garden")
	assert_eq(s1.get_next_stage_threshold(), 25, "Next threshold is 25")
	assert_eq(s1.get_points_to_next_stage(), 14, "14 points needed for shady_garden")

	# 3. Established garden reaching happy_garden_home (>= 70 pts):
	#    5 plants (15) + 3 mature (6) + 3 decorations (12) + 6 traits (18) + 5 discoveries (25) = 76 pts
	journal.try_record_sighting("plant.banana", 1100)
	journal.try_record_sighting("plant.jasmine", 1200)
	journal.try_record_sighting("visitor.butterfly", 1300)
	journal.try_record_sighting("visitor.frog", 1400)
	var snap_max: GardenSnapshot = GardenSnapshot.new(
		{"flower": 2, "fruit": 1, "perch": 1, "shade": 2, "shelter": 1, "water": 1},
		{"plant.banana": 1, "plant.jasmine": 2, "plant.marigold": 2},
		5,
		3,
		{"decoration.bench": 1, "decoration.clay_jar": 1, "decoration.small_pond": 1},
		3
	)
	var s_max: GardenProgressionSummary = GardenProgressionStage.evaluate(snap_max, journal)
	assert_eq(s_max.get_establishment_score(), 76, "Score is 76 pts")
	assert_eq(s_max.get_stage_id(), "happy_garden_home", "76 pts -> happy_garden_home")
	assert_eq(s_max.get_stage_index(), 4, "Stage index is 4")
	assert_eq(s_max.get_next_stage_id(), "", "Max stage has empty next_stage_id")
	assert_eq(s_max.get_next_stage_threshold(), 0, "Max stage has 0 next threshold")
	assert_eq(s_max.get_points_to_next_stage(), 0, "Max stage has 0 points remaining")
	assert_true(s_max.is_max_stage(), "is_max_stage() is true")


func _test_gentle_guidance_selection_progression() -> void:
	describe("select_guidance advances through all 6 low-pressure suggestions as the player builds the garden")
	var journal: JournalState = JournalState.new()

	# Step 1: 0 plants -> guidance.plant_first
	var snap_empty: GardenSnapshot = GardenSnapshot.new({}, {}, 0, 0)
	assert_eq(
		GardenProgressionStage.select_guidance(snap_empty, journal),
		GardenProgressionStage.GUIDANCE_PLANT_FIRST,
		"Empty garden suggests planting first plant"
	)

	# Step 2: 1 plant, 0 visitor discoveries -> guidance.observe_visitor
	journal.try_record_sighting("plant.holy_basil", 100)
	var snap_planted: GardenSnapshot = GardenSnapshot.new(
		{"dense_vegetation": 1, "food": 1},
		{"plant.holy_basil": 1},
		1,
		0
	)
	assert_eq(
		GardenProgressionStage.select_guidance(snap_planted, journal),
		GardenProgressionStage.GUIDANCE_OBSERVE_VISITOR,
		"Planted garden with no visitor sighting suggests observing a visitor"
	)

	# Step 3: Visitor discovered, 0 decorations -> guidance.place_decoration
	journal.try_record_sighting("visitor.firefly", 200)
	assert_eq(
		GardenProgressionStage.select_guidance(snap_planted, journal),
		GardenProgressionStage.GUIDANCE_PLACE_DECORATION,
		"After first visitor sighting, suggests placing a decoration"
	)

	# Step 4: Decoration placed without water trait -> guidance.create_water_habitat
	var snap_bench: GardenSnapshot = GardenSnapshot.new(
		{"dense_vegetation": 1, "food": 1, "shade": 1, "shelter": 1},
		{"plant.holy_basil": 1},
		1,
		0,
		{"decoration.bench": 1},
		1
	)
	assert_eq(
		GardenProgressionStage.select_guidance(snap_bench, journal),
		GardenProgressionStage.GUIDANCE_CREATE_WATER_HABITAT,
		"Decoration without water trait suggests creating water habitat"
	)

	# Step 5: Water trait active, < 10 discoveries -> guidance.discover_more
	var snap_water: GardenSnapshot = GardenSnapshot.new(
		{"dense_vegetation": 1, "food": 1, "water": 1},
		{"plant.holy_basil": 1},
		1,
		0,
		{"decoration.clay_jar": 1},
		1
	)
	assert_eq(
		GardenProgressionStage.select_guidance(snap_water, journal),
		GardenProgressionStage.GUIDANCE_DISCOVER_MORE,
		"Water habitat with partial journal suggests discovering more entries"
	)

	# Step 6: All 10 MVP journal entries discovered -> guidance.enjoy_garden
	for pid: String in ["plant.banana", "plant.chili", "plant.holy_basil", "plant.jasmine", "plant.marigold"]:
		journal.try_record_sighting(pid, 500)
	for vid: String in ["visitor.bird", "visitor.butterfly", "visitor.cat", "visitor.firefly", "visitor.frog"]:
		journal.try_record_sighting(vid, 500)
	assert_eq(
		GardenProgressionStage.select_guidance(snap_water, journal),
		GardenProgressionStage.GUIDANCE_ENJOY_GARDEN,
		"Complete journal + water habitat suggests enjoying the garden"
	)


func _test_null_inputs_handled_safely() -> void:
	describe("Null snapshot and null journal are handled safely without crashing")
	assert_eq(GardenProgressionStage.compute_score(null, null), 0, "Null inputs score 0")
	var summary: GardenProgressionSummary = GardenProgressionStage.evaluate(null, null)
	assert_true(summary != null and summary.is_valid(), "Null inputs produce valid starting summary")
	assert_eq(summary.get_stage_id(), "starting_garden", "Null inputs -> starting_garden")
	assert_eq(summary.get_guidance_id(), "guidance.plant_first", "Null inputs -> guidance.plant_first")
