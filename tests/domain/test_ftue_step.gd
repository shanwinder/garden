## test_ftue_step.gd
## Unit tests for FtueStep immutable domain value object.
class_name TestFtueStep
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestFtueStep"


func run_tests() -> void:
	describe("FtueStep extends RefCounted and is pure domain value object")
	var step: Variant = FtueStep.new(
		FtueStep.STEP_SEE_GARDEN,
		0,
		"ก้าวแรกในสวน: สำรวจสวน",
		"ยินดีต้อนรับสู่บ้านสวน ลองเริ่มด้วยการเลือกปลูกพืชต้นแรกของคุณ"
	)
	assert_true(step is RefCounted, "Must extend RefCounted")
	assert_false(step is Node, "Must not extend Node")
	assert_false(step is Resource, "Must not extend Resource")

	describe("FtueStep canonical constants and index lookups")
	assert_eq(FtueStep.ALL_STEPS.size(), 7, "Must contain exactly 7 canonical steps")
	assert_true(FtueStep.is_valid_step_id(FtueStep.STEP_SEE_GARDEN), "STEP_SEE_GARDEN is valid")
	assert_true(FtueStep.is_valid_step_id(FtueStep.STEP_WATCH_GROWTH), "STEP_WATCH_GROWTH is valid")
	assert_true(FtueStep.is_valid_step_id(FtueStep.STEP_HARVEST_PLANT), "STEP_HARVEST_PLANT is valid")
	assert_true(FtueStep.is_valid_step_id(FtueStep.STEP_PLACE_DECORATION), "STEP_PLACE_DECORATION is valid")
	assert_true(FtueStep.is_valid_step_id(FtueStep.STEP_OBSERVE_VISITOR), "STEP_OBSERVE_VISITOR is valid")
	assert_true(FtueStep.is_valid_step_id(FtueStep.STEP_CHECK_JOURNAL), "STEP_CHECK_JOURNAL is valid")
	assert_true(FtueStep.is_valid_step_id(FtueStep.STEP_COMPLETED), "STEP_COMPLETED is valid")
	assert_false(FtueStep.is_valid_step_id("invalid.step"), "invalid.step is not valid")
	assert_false(FtueStep.is_valid_step_id(""), "Empty string is not valid")

	for i: int in range(FtueStep.ALL_STEPS.size()):
		var sid: String = FtueStep.ALL_STEPS[i]
		assert_eq(FtueStep.step_index_for_id(sid), i, "Index for %s must be %d" % [sid, i])

	describe("FtueStep getters and active/completed predicates")
	var step_welcome: FtueStep = FtueStep.new(
		FtueStep.STEP_SEE_GARDEN,
		0,
		"สำรวจสวน",
		"ลองปลูกพืช"
	)
	assert_eq(step_welcome.get_step_id(), FtueStep.STEP_SEE_GARDEN, "Correct step_id")
	assert_eq(step_welcome.get_step_index(), 0, "Correct step_index")
	assert_eq(step_welcome.get_title(), "สำรวจสวน", "Correct title")
	assert_eq(step_welcome.get_instruction(), "ลองปลูกพืช", "Correct instruction")
	assert_true(step_welcome.is_valid(), "step_welcome must be valid")
	assert_true(step_welcome.is_active(), "step_welcome must be active")
	assert_false(step_welcome.is_completed(), "step_welcome must not be completed")

	var step_done: FtueStep = FtueStep.new(
		FtueStep.STEP_COMPLETED,
		6,
		"สำเร็จแล้ว",
		"ยินดีด้วย"
	)
	assert_true(step_done.is_valid(), "step_done must be valid")
	assert_false(step_done.is_active(), "step_done must not be active")
	assert_true(step_done.is_completed(), "step_done must be completed")

	describe("FtueStep invalid invariant rejection")
	var invalid_id: FtueStep = FtueStep.new("bad.id", 0, "Title", "Instruction")
	assert_false(invalid_id.is_valid(), "Invalid step_id must fail is_valid")
	assert_false(invalid_id.is_active(), "Invalid step must not be active")

	var mismatched_idx: FtueStep = FtueStep.new(FtueStep.STEP_SEE_GARDEN, 3, "Title", "Instruction")
	assert_false(mismatched_idx.is_valid(), "Mismatched index must fail is_valid")

	var empty_title: FtueStep = FtueStep.new(FtueStep.STEP_SEE_GARDEN, 0, "", "Instruction")
	assert_false(empty_title.is_valid(), "Empty title must fail is_valid")

	var empty_instruction: FtueStep = FtueStep.new(FtueStep.STEP_SEE_GARDEN, 0, "Title", "")
	assert_false(empty_instruction.is_valid(), "Empty instruction must fail is_valid")
