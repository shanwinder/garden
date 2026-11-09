## test_ftue_evaluator.gd
## Unit tests for FtueEvaluator domain rule service (GAME_DESIGN.md Section 21).
class_name TestFtueEvaluator
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestFtueEvaluator"


func run_tests() -> void:
	_test_evaluator_contract()
	_test_ftue_step_progression_sequence()
	_test_ftue_completion_and_established_garden()
	_test_null_and_edge_case_safety()


func _test_evaluator_contract() -> void:
	describe("FtueEvaluator extends RefCounted and is pure domain evaluator")
	var evaluator: Variant = FtueEvaluator.new()
	assert_true(evaluator is RefCounted, "Must extend RefCounted")
	assert_false(evaluator is Node, "Must not extend Node")
	assert_false(evaluator is Resource, "Must not extend Resource")

	var step: FtueStep = FtueEvaluator.create_step(FtueStep.STEP_SEE_GARDEN)
	assert_true(step != null and step.is_valid(), "create_step creates valid step")
	assert_eq(step.get_step_id(), FtueStep.STEP_SEE_GARDEN, "Correct step_id")
	var bad_step: FtueStep = FtueEvaluator.create_step("invalid.step")
	assert_true(bad_step == null, "Invalid step returns null")


func _test_ftue_step_progression_sequence() -> void:
	describe("FtueEvaluator accurately evaluates the 8-stage sequence from GAME_DESIGN.md §21")

	# Step 1: See garden (empty garden, 0 discoveries, 0 coins)
	var snap_empty: GardenSnapshot = GardenSnapshot.new({}, {}, 0, 0)
	var journal: JournalState = JournalState.new()
	var step1: FtueStep = FtueEvaluator.evaluate(snap_empty, journal, 0)
	assert_eq(step1.get_step_id(), FtueStep.STEP_SEE_GARDEN, "Empty garden evaluates to STEP_SEE_GARDEN")
	assert_eq(step1.get_step_index(), 0, "Index is 0")
	assert_true(step1.is_active(), "Step 1 is active")
	assert_false(step1.is_completed(), "Step 1 is not completed")

	# Step 2: Plant something (1 plant growing, mature = 0, coins = 0, 1 discovery)
	journal.try_record_sighting("plant.marigold", 1000)
	var snap_growing: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1},
		{"plant.marigold": 1},
		1,
		0 # 0 mature plants
	)
	var step2: FtueStep = FtueEvaluator.evaluate(snap_growing, journal, 0)
	assert_eq(step2.get_step_id(), FtueStep.STEP_WATCH_GROWTH, "Growing plant evaluates to STEP_WATCH_GROWTH")
	assert_eq(step2.get_step_index(), 1, "Index is 1")
	assert_true(step2.is_active(), "Step 2 is active")

	# Step 3: Plant reaches mature stage (mature = 1, coins = 0)
	var snap_mature: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1},
		{"plant.marigold": 1},
		1,
		1 # 1 mature plant
	)
	var step3: FtueStep = FtueEvaluator.evaluate(snap_mature, journal, 0)
	assert_eq(step3.get_step_id(), FtueStep.STEP_HARVEST_PLANT, "Mature plant evaluates to STEP_HARVEST_PLANT")
	assert_eq(step3.get_step_index(), 2, "Index is 2")
	assert_true(step3.is_active(), "Step 3 is active")

	# Step 4: Harvest produce -> coins earned (coins = 20, 0 decorations placed)
	var snap_harvested: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1},
		{"plant.marigold": 1},
		1,
		0
	)
	var step4: FtueStep = FtueEvaluator.evaluate(snap_harvested, journal, 20)
	assert_eq(step4.get_step_id(), FtueStep.STEP_PLACE_DECORATION, "Coins earned evaluates to STEP_PLACE_DECORATION")
	assert_eq(step4.get_step_index(), 3, "Index is 3")
	assert_true(step4.is_active(), "Step 4 is active")

	# Step 5: Place decoration (decoration count = 1, trait = water, no visitor discovered yet)
	var snap_decorated: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1, "water": 1},
		{"plant.marigold": 1},
		1,
		0,
		{"decoration.clay_jar": 1},
		1 # 1 decoration
	)
	var step5: FtueStep = FtueEvaluator.evaluate(snap_decorated, journal, 5)
	assert_eq(step5.get_step_id(), FtueStep.STEP_OBSERVE_VISITOR, "Placed decoration evaluates to STEP_OBSERVE_VISITOR")
	assert_eq(step5.get_step_index(), 4, "Index is 4")
	assert_true(step5.is_active(), "Step 5 is active")

	# Step 6: Encounter visitor -> recorded in journal (has_visitor_discovery = true, total discoveries = 2)
	journal.try_record_sighting("visitor.frog", 2000)
	var step6: FtueStep = FtueEvaluator.evaluate(snap_decorated, journal, 5)
	assert_eq(step6.get_step_id(), FtueStep.STEP_CHECK_JOURNAL, "Visitor observed evaluates to STEP_CHECK_JOURNAL")
	assert_eq(step6.get_step_index(), 5, "Index is 5")
	assert_true(step6.is_active(), "Step 6 is active")


func _test_ftue_completion_and_established_garden() -> void:
	describe("FtueEvaluator completes when garden is established with >= 3 discoveries or expanded layout")
	var journal: JournalState = JournalState.new()
	journal.try_record_sighting("plant.marigold", 1000)
	journal.try_record_sighting("visitor.frog", 2000)
	journal.try_record_sighting("plant.holy_basil", 3000)

	var snap: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1, "water": 1},
		{"plant.marigold": 1},
		1,
		0,
		{"decoration.clay_jar": 1},
		1
	)
	var step_done: FtueStep = FtueEvaluator.evaluate(snap, journal, 5)
	assert_eq(step_done.get_step_id(), FtueStep.STEP_COMPLETED, "3 discoveries evaluates to STEP_COMPLETED")
	assert_eq(step_done.get_step_index(), 6, "Index is 6")
	assert_true(step_done.is_completed(), "Step is completed")
	assert_false(step_done.is_active(), "Step is not active when completed")

	# Also completes if player has visitor discovery + multiple decorations
	var journal2: JournalState = JournalState.new()
	journal2.try_record_sighting("plant.marigold", 1000)
	journal2.try_record_sighting("visitor.butterfly", 2000)
	var snap_multi_decor: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1, "water": 1},
		{"plant.marigold": 1},
		1,
		0,
		{"decoration.clay_jar": 1, "decoration.bench": 1},
		2
	)
	var step_done2: FtueStep = FtueEvaluator.evaluate(snap_multi_decor, journal2, 10)
	assert_eq(step_done2.get_step_id(), FtueStep.STEP_COMPLETED, "Visitor + multiple decorations completes FTUE")


func _test_null_and_edge_case_safety() -> void:
	describe("FtueEvaluator gracefully handles null snapshots, null journal, and negative currency")
	var step_null: FtueStep = FtueEvaluator.evaluate(null, null, -10)
	assert_true(step_null != null and step_null.is_valid(), "Handles null inputs safely")
	assert_eq(step_null.get_step_id(), FtueStep.STEP_SEE_GARDEN, "Null inputs default to STEP_SEE_GARDEN")

	var mature_no_journal: FtueStep = FtueEvaluator.evaluate(
		GardenSnapshot.new({}, {}, 1, 1),
		null,
		0
	)
	assert_eq(mature_no_journal.get_step_id(), FtueStep.STEP_HARVEST_PLANT, "Mature plant without journal evaluates to HARVEST")
