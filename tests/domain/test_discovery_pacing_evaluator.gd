## test_discovery_pacing_evaluator.gd
## Unit tests for DiscoveryPacingEvaluator domain rule service (GAME_DESIGN.md Section 22).
class_name TestDiscoveryPacingEvaluator
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestDiscoveryPacingEvaluator"


func run_tests() -> void:
	_test_evaluator_contract()
	_test_day_1_early_phase_evaluation()
	_test_day_2_early_return_evaluation()
	_test_day_3_developing_garden_evaluation()
	_test_day_4_weather_discovery_evaluation()
	_test_day_5_water_habitat_evaluation()
	_test_day_6_night_discovery_evaluation()
	_test_day_7_first_expansion_evaluation()
	_test_evaluate_active_milestone_progression()
	_test_null_and_edge_case_safety()


func _test_evaluator_contract() -> void:
	describe("DiscoveryPacingEvaluator extends RefCounted and is pure domain evaluator")
	var evaluator: Variant = DiscoveryPacingEvaluator.new()
	assert_true(evaluator is RefCounted, "Must extend RefCounted")
	assert_false(evaluator is Node, "Must not extend Node")
	assert_false(evaluator is Resource, "Must not extend Resource")

	var m: DiscoveryPacingMilestone = DiscoveryPacingEvaluator.create_milestone(
		DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE,
		false
	)
	assert_true(m != null and m.is_valid(), "create_milestone creates valid milestone")
	assert_eq(m.get_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE, "Correct milestone ID")
	assert_false(m.is_achieved(), "Not achieved")

	var invalid_m: DiscoveryPacingMilestone = DiscoveryPacingEvaluator.create_milestone("unknown.id")
	assert_true(invalid_m == null, "Invalid ID returns null")


func _test_day_1_early_phase_evaluation() -> void:
	describe("Day 1 (Early Phase): evaluated from plants or initial discoveries")
	var snap_empty: GardenSnapshot = GardenSnapshot.new({}, {}, 0, 0)
	var journal_empty: JournalState = JournalState.new()
	assert_false(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE,
			snap_empty,
			journal_empty
		),
		"Empty garden does not achieve Day 1 yet"
	)

	# Plant a fast herb / plant
	var snap_planted: GardenSnapshot = GardenSnapshot.new(
		{"herb": 1},
		{"plant.holy_basil": 1},
		1,
		0
	)
	assert_true(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE,
			snap_planted,
			journal_empty
		),
		"Garden with 1 plant achieves Day 1"
	)

	# Or butterfly discovered in journal
	journal_empty.try_record_sighting("visitor.butterfly", 1000)
	assert_true(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE,
			snap_empty,
			journal_empty
		),
		"Butterfly discovery achieves Day 1"
	)


func _test_day_2_early_return_evaluation() -> void:
	describe("Day 2 (Early Return): water-related trait, bird activity, or 2+ journal entries")
	var snap_empty: GardenSnapshot = GardenSnapshot.new({}, {}, 0, 0)
	var journal: JournalState = JournalState.new()
	assert_false(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_2_EARLY_RETURN,
			snap_empty,
			journal
		),
		"Empty garden does not achieve Day 2"
	)

	# Water trait present
	var snap_water: GardenSnapshot = GardenSnapshot.new(
		{"water": 1},
		{"decoration.clay_jar": 1},
		0,
		0
	)
	assert_true(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_2_EARLY_RETURN,
			snap_water,
			journal
		),
		"Water trait achieves Day 2"
	)

	# Or bird discovery in journal
	journal.try_record_sighting("visitor.bird", 2000)
	assert_true(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_2_EARLY_RETURN,
			snap_empty,
			journal
		),
		"Bird discovery achieves Day 2"
	)


func _test_day_3_developing_garden_evaluation() -> void:
	describe("Day 3 (Developing Garden): resting decoration (bench), cat visitor, or 2+ decorations")
	var snap_empty: GardenSnapshot = GardenSnapshot.new({}, {}, 0, 0)
	var journal: JournalState = JournalState.new()
	assert_false(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_3_DEVELOPING_GARDEN,
			snap_empty,
			journal
		),
		"Empty garden does not achieve Day 3"
	)

	# Resting spot trait (bench)
	var snap_bench: GardenSnapshot = GardenSnapshot.new(
		{EnvironmentalTrait.SHELTER: 1},
		{},
		0,
		0,
		{"decoration.bench": 1},
		1
	)
	assert_true(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_3_DEVELOPING_GARDEN,
			snap_bench,
			journal
		),
		"Resting spot trait achieves Day 3"
	)

	# Cat in journal
	journal.try_record_sighting("visitor.cat", 3000)
	assert_true(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_3_DEVELOPING_GARDEN,
			snap_empty,
			journal
		),
		"Cat discovery achieves Day 3"
	)


func _test_day_4_weather_discovery_evaluation() -> void:
	describe("Day 4 (Weather Discovery): frog visitor, water + rain weather, or 4+ discoveries")
	var snap_empty: GardenSnapshot = GardenSnapshot.new({}, {}, 0, 0)
	var journal: JournalState = JournalState.new()
	assert_false(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_4_WEATHER_DISCOVERY,
			snap_empty,
			journal
		),
		"Empty garden does not achieve Day 4"
	)

	# Rain + water trait
	var snap_rain_water: GardenSnapshot = GardenSnapshot.new(
		{"water": 1},
		{},
		0,
		0,
		{"decoration.clay_jar": 1},
		1,
		GardenTimePeriod.DAY,
		GardenWeather.RAIN
	)
	assert_true(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_4_WEATHER_DISCOVERY,
			snap_rain_water,
			journal
		),
		"Water trait during rain achieves Day 4"
	)

	# Frog in journal
	journal.try_record_sighting("visitor.frog", 4000)
	assert_true(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_4_WEATHER_DISCOVERY,
			snap_empty,
			journal
		),
		"Frog discovery achieves Day 4"
	)


func _test_day_5_water_habitat_evaluation() -> void:
	describe("Day 5 (Water Habitat): small pond decoration, water event, or 5+ discoveries")
	var snap_empty: GardenSnapshot = GardenSnapshot.new({}, {}, 0, 0)
	var journal: JournalState = JournalState.new()
	assert_false(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_5_WATER_HABITAT,
			snap_empty,
			journal
		),
		"Empty garden does not achieve Day 5"
	)

	# Small pond placed
	var snap_pond: GardenSnapshot = GardenSnapshot.new(
		{EnvironmentalTrait.WATER: 1},
		{},
		0,
		0,
		{"decoration.small_pond": 1},
		1
	)
	assert_true(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_5_WATER_HABITAT,
			snap_pond,
			journal
		),
		"Small pond placed achieves Day 5"
	)

	# 5 discoveries in journal
	var journal5: JournalState = JournalState.new()
	for vid: String in ["visitor.bird", "visitor.butterfly", "visitor.cat", "visitor.firefly", "visitor.frog"]:
		journal5.try_record_sighting(vid, 5000)
	assert_true(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_5_WATER_HABITAT,
			snap_empty,
			journal5
		),
		"5 discoveries achieves Day 5"
	)


func _test_day_6_night_discovery_evaluation() -> void:
	describe("Day 6 (Night Discovery): firefly visitor, lamp at night, or night event / 6+ discoveries")
	var snap_empty: GardenSnapshot = GardenSnapshot.new({}, {}, 0, 0)
	var journal: JournalState = JournalState.new()
	assert_false(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_6_NIGHT_DISCOVERY,
			snap_empty,
			journal
		),
		"Empty garden does not achieve Day 6"
	)

	# Night + lamp
	var snap_night_lamp: GardenSnapshot = GardenSnapshot.new(
		{EnvironmentalTrait.LIGHT: 1},
		{},
		0,
		0,
		{"decoration.garden_lamp": 1},
		1,
		GardenTimePeriod.NIGHT,
		GardenWeather.CLEAR
	)
	assert_true(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_6_NIGHT_DISCOVERY,
			snap_night_lamp,
			journal
		),
		"Lamp at night achieves Day 6"
	)

	# Firefly in journal
	journal.try_record_sighting("visitor.firefly", 6000)
	assert_true(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_6_NIGHT_DISCOVERY,
			snap_empty,
			journal
		),
		"Firefly in journal achieves Day 6"
	)


func _test_day_7_first_expansion_evaluation() -> void:
	describe("Day 7 (First Expansion): living_garden score threshold (45+) or 8+ discoveries")
	var snap_empty: GardenSnapshot = GardenSnapshot.new({}, {}, 0, 0)
	var journal: JournalState = JournalState.new()
	assert_false(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_7_FIRST_EXPANSION,
			snap_empty,
			journal
		),
		"Empty garden does not achieve Day 7"
	)

	# Add 8 discoveries to journal
	for pid: String in ["plant.banana", "plant.chili", "plant.holy_basil", "plant.jasmine", "plant.marigold"]:
		journal.try_record_sighting(pid, 1000)
	for vid: String in ["visitor.bird", "visitor.butterfly", "visitor.cat"]:
		journal.try_record_sighting(vid, 2000)
	assert_true(
		DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_7_FIRST_EXPANSION,
			snap_empty,
			journal
		),
		"8 discoveries achieves Day 7"
	)


func _test_evaluate_active_milestone_progression() -> void:
	describe("evaluate_active_milestone returns the earliest unachieved milestone")
	var snap: GardenSnapshot = GardenSnapshot.new({}, {}, 0, 0)
	var journal: JournalState = JournalState.new()

	# Start: Day 1 active
	var m_act1: DiscoveryPacingMilestone = DiscoveryPacingEvaluator.evaluate_active_milestone(snap, journal)
	assert_eq(m_act1.get_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE, "Starts at Day 1")
	assert_false(m_act1.is_achieved(), "Day 1 not achieved yet")
	assert_eq(DiscoveryPacingEvaluator.get_achieved_count(snap, journal), 0, "0 achieved")
	assert_false(DiscoveryPacingEvaluator.is_all_completed(snap, journal), "Not all completed")

	# Achieve Day 1 (plant marigold) -> active milestone becomes Day 2
	snap = GardenSnapshot.new({"flower": 1}, {"plant.marigold": 1}, 1, 0)
	var m_act2: DiscoveryPacingMilestone = DiscoveryPacingEvaluator.evaluate_active_milestone(snap, journal)
	assert_eq(m_act2.get_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_2_EARLY_RETURN, "Advances to Day 2")
	assert_false(m_act2.is_achieved(), "Day 2 not achieved yet")
	assert_eq(DiscoveryPacingEvaluator.get_achieved_count(snap, journal), 1, "1 achieved")

	# Achieve all milestones -> active milestone returns Day 7 (achieved)
	for pid: String in ["plant.banana", "plant.chili", "plant.holy_basil", "plant.jasmine", "plant.marigold"]:
		journal.try_record_sighting(pid, 1000)
	for vid: String in ["visitor.bird", "visitor.butterfly", "visitor.cat", "visitor.firefly", "visitor.frog"]:
		journal.try_record_sighting(vid, 2000)
	snap = GardenSnapshot.new(
		{EnvironmentalTrait.WATER: 1, EnvironmentalTrait.SHELTER: 1, EnvironmentalTrait.LIGHT: 1},
		{},
		0,
		0,
		{"decoration.small_pond": 1, "decoration.bench": 1, "decoration.garden_lamp": 1},
		3,
		GardenTimePeriod.NIGHT,
		GardenWeather.RAIN
	)
	var m_act_all: DiscoveryPacingMilestone = DiscoveryPacingEvaluator.evaluate_active_milestone(snap, journal)
	assert_eq(m_act_all.get_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_7_FIRST_EXPANSION, "All done -> Day 7")
	assert_true(m_act_all.is_achieved(), "Day 7 achieved")
	assert_eq(DiscoveryPacingEvaluator.get_achieved_count(snap, journal), 7, "All 7 achieved")
	assert_true(DiscoveryPacingEvaluator.is_all_completed(snap, journal), "All completed is true")


func _test_null_and_edge_case_safety() -> void:
	describe("Null inputs are handled safely without crashing")
	var m: DiscoveryPacingMilestone = DiscoveryPacingEvaluator.evaluate_active_milestone(null, null)
	assert_true(m != null and m.is_valid(), "Null inputs produce valid milestone")
	assert_eq(m.get_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE, "Null inputs start at Day 1")
	assert_false(m.is_achieved(), "Not achieved on null inputs")
	assert_eq(DiscoveryPacingEvaluator.get_achieved_count(null, null), 0, "0 achieved on null inputs")
	assert_false(DiscoveryPacingEvaluator.is_all_completed(null, null), "Not completed on null inputs")
