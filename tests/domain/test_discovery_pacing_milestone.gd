## test_discovery_pacing_milestone.gd
## Unit tests for DiscoveryPacingMilestone immutable domain value object.
class_name TestDiscoveryPacingMilestone
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestDiscoveryPacingMilestone"


func run_tests() -> void:
	describe("DiscoveryPacingMilestone extends RefCounted and is pure domain value object")
	var m: Variant = DiscoveryPacingMilestone.new(
		DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE,
		1,
		"early_phase",
		"วันที่ 1: ก้าวแรกสู่สวนสวย",
		"เริ่มต้นทำความรู้จักสวน ปลูกสมุนไพรโตเร็ว และพบผู้มาเยือนตัวแรกอย่างผีเสื้อ",
		"ลองปลูกพืชและเฝ้ามองผู้มาเยือนตัวแรกแวะเวียนมาในสวน",
		false
	)
	assert_true(m is RefCounted, "Must extend RefCounted")
	assert_false(m is Node, "Must not extend Node")
	assert_false(m is Resource, "Must not extend Resource")

	describe("DiscoveryPacingMilestone canonical constants and day index lookups")
	assert_eq(DiscoveryPacingMilestone.ALL_MILESTONES.size(), 7, "Must contain exactly 7 canonical milestones")
	assert_true(DiscoveryPacingMilestone.is_valid_milestone_id(DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE), "DAY_1 is valid")
	assert_true(DiscoveryPacingMilestone.is_valid_milestone_id(DiscoveryPacingMilestone.MILESTONE_DAY_2_EARLY_RETURN), "DAY_2 is valid")
	assert_true(DiscoveryPacingMilestone.is_valid_milestone_id(DiscoveryPacingMilestone.MILESTONE_DAY_3_DEVELOPING_GARDEN), "DAY_3 is valid")
	assert_true(DiscoveryPacingMilestone.is_valid_milestone_id(DiscoveryPacingMilestone.MILESTONE_DAY_4_WEATHER_DISCOVERY), "DAY_4 is valid")
	assert_true(DiscoveryPacingMilestone.is_valid_milestone_id(DiscoveryPacingMilestone.MILESTONE_DAY_5_WATER_HABITAT), "DAY_5 is valid")
	assert_true(DiscoveryPacingMilestone.is_valid_milestone_id(DiscoveryPacingMilestone.MILESTONE_DAY_6_NIGHT_DISCOVERY), "DAY_6 is valid")
	assert_true(DiscoveryPacingMilestone.is_valid_milestone_id(DiscoveryPacingMilestone.MILESTONE_DAY_7_FIRST_EXPANSION), "DAY_7 is valid")
	assert_false(DiscoveryPacingMilestone.is_valid_milestone_id("invalid.milestone"), "invalid.milestone is not valid")
	assert_false(DiscoveryPacingMilestone.is_valid_milestone_id(""), "Empty string is not valid")

	for i: int in range(DiscoveryPacingMilestone.ALL_MILESTONES.size()):
		var mid: String = DiscoveryPacingMilestone.ALL_MILESTONES[i]
		assert_eq(DiscoveryPacingMilestone.day_index_for_id(mid), i + 1, "Day index for %s must be %d" % [mid, i + 1])
	assert_eq(DiscoveryPacingMilestone.day_index_for_id("invalid"), -1, "Invalid ID day index is -1")

	describe("DiscoveryPacingMilestone getters and predicates")
	var m1: DiscoveryPacingMilestone = DiscoveryPacingMilestone.new(
		DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE,
		1,
		"early_phase",
		"วันที่ 1: ก้าวแรกสู่สวนสวย",
		"คำอธิบาย",
		"คำแนะนำ",
		false
	)
	assert_eq(m1.get_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE, "Correct milestone_id")
	assert_eq(m1.get_day_index(), 1, "Correct day_index")
	assert_eq(m1.get_theme(), "early_phase", "Correct theme")
	assert_eq(m1.get_title(), "วันที่ 1: ก้าวแรกสู่สวนสวย", "Correct title")
	assert_eq(m1.get_description(), "คำอธิบาย", "Correct description")
	assert_eq(m1.get_recommended_focus(), "คำแนะนำ", "Correct recommended_focus")
	assert_false(m1.is_achieved(), "Not achieved yet")
	assert_true(m1.is_valid(), "Valid milestone")

	var m7: DiscoveryPacingMilestone = DiscoveryPacingMilestone.new(
		DiscoveryPacingMilestone.MILESTONE_DAY_7_FIRST_EXPANSION,
		7,
		"first_expansion",
		"วันที่ 7: สวนแสนสุขขยับขยาย",
		"คำอธิบาย",
		"คำแนะนำ",
		true
	)
	assert_true(m7.is_achieved(), "m7 is achieved")
	assert_true(m7.is_valid(), "m7 is valid")

	describe("DiscoveryPacingMilestone invalid invariant rejection")
	var bad_id: DiscoveryPacingMilestone = DiscoveryPacingMilestone.new("bad.id", 1, "theme", "title", "desc", "focus")
	assert_false(bad_id.is_valid(), "Invalid milestone_id must fail is_valid")

	var bad_day: DiscoveryPacingMilestone = DiscoveryPacingMilestone.new(
		DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE,
		5,
		"theme",
		"title",
		"desc",
		"focus"
	)
	assert_false(bad_day.is_valid(), "Mismatched day index must fail is_valid")

	var empty_title: DiscoveryPacingMilestone = DiscoveryPacingMilestone.new(
		DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE,
		1,
		"theme",
		"",
		"desc",
		"focus"
	)
	assert_false(empty_title.is_valid(), "Empty title must fail is_valid")

	var empty_focus: DiscoveryPacingMilestone = DiscoveryPacingMilestone.new(
		DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE,
		1,
		"theme",
		"title",
		"desc",
		""
	)
	assert_false(empty_focus.is_valid(), "Empty focus must fail is_valid")
