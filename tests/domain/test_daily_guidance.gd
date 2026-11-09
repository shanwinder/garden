## test_daily_guidance.gd
## Unit tests for DailyGuidanceItem and DailyGuidanceEvaluator domain contracts (GAME_DESIGN.md Section 20).
class_name TestDailyGuidance
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestDailyGuidance"


func run_tests() -> void:
	_test_item_type_contract_and_validation()
	_test_evaluator_vocabulary_and_item_creation()
	_test_evaluator_deterministic_three_suggestions()
	_test_evaluator_adapts_to_garden_context()
	_test_evaluator_handles_edge_cases_safely()


func _test_item_type_contract_and_validation() -> void:
	describe("DailyGuidanceItem extends RefCounted and enforces domain invariants")
	var item_variant: Variant = DailyGuidanceItem.new(
		"daily_guidance.harvest_produce",
		"harvest",
		3,
		"เก็บเกี่ยวผลผลิต 3 ครั้ง"
	)
	assert_true(item_variant is DailyGuidanceItem, "Must be DailyGuidanceItem")
	assert_true(item_variant is RefCounted, "Must extend RefCounted")
	assert_false(item_variant is Node, "Must not be a Node")
	assert_false(item_variant is Resource, "Must not be a Resource")

	var item: DailyGuidanceItem = item_variant as DailyGuidanceItem

	assert_eq(item.get_id(), "daily_guidance.harvest_produce", "ID getter matches")
	assert_eq(item.get_category(), "harvest", "Category getter matches")
	assert_eq(item.get_target_count(), 3, "Target count getter matches")
	assert_eq(item.get_display_text(), "เก็บเกี่ยวผลผลิต 3 ครั้ง", "Display text matches")
	assert_true(item.is_valid(), "Valid item passes is_valid()")

	# Clamps non-positive target count to at least 1
	var item_clamped: DailyGuidanceItem = DailyGuidanceItem.new(
		"daily_guidance.plant_flower",
		"planting",
		0,
		"ปลูกไม้ดอก 1 ต้น"
	)
	assert_eq(item_clamped.get_target_count(), 1, "Target count clamped to 1")
	assert_true(item_clamped.is_valid(), "Clamped item is valid")

	# Invalid namespace prefix
	var item_bad_ns: DailyGuidanceItem = DailyGuidanceItem.new(
		"bad_prefix.test",
		"harvest",
		1,
		"ข้อความทดสอบ"
	)
	assert_false(item_bad_ns.is_valid(), "Invalid namespace prefix fails is_valid()")

	# Empty category
	var item_no_cat: DailyGuidanceItem = DailyGuidanceItem.new(
		"daily_guidance.test",
		"",
		1,
		"ข้อความทดสอบ"
	)
	assert_false(item_no_cat.is_valid(), "Empty category fails is_valid()")

	# Empty display text
	var item_no_text: DailyGuidanceItem = DailyGuidanceItem.new(
		"daily_guidance.test",
		"general",
		1,
		""
	)
	assert_false(item_no_text.is_valid(), "Empty display text fails is_valid()")


func _test_evaluator_vocabulary_and_item_creation() -> void:
	describe("DailyGuidanceEvaluator vocabulary and item creation")
	var expected_ids: Array[String] = [
		DailyGuidanceEvaluator.GUIDANCE_HARVEST_PRODUCE,
		DailyGuidanceEvaluator.GUIDANCE_PLANT_FLOWER,
		DailyGuidanceEvaluator.GUIDANCE_PLANT_CROP,
		DailyGuidanceEvaluator.GUIDANCE_PLANT_ANY,
		DailyGuidanceEvaluator.GUIDANCE_OBSERVE_VISITOR,
		DailyGuidanceEvaluator.GUIDANCE_OBSERVE_EVENT,
		DailyGuidanceEvaluator.GUIDANCE_PLACE_DECORATION,
		DailyGuidanceEvaluator.GUIDANCE_CARE_WATER_HABITAT,
		DailyGuidanceEvaluator.GUIDANCE_CHECK_JOURNAL,
	]
	assert_eq(DailyGuidanceEvaluator.ALL_DAILY_GUIDANCE_IDS, expected_ids, "Vocabulary IDs match")

	for gid: String in expected_ids:
		assert_true(DailyGuidanceEvaluator.is_valid_guidance_id(gid), "Valid guidance ID: %s" % gid)
		var it: DailyGuidanceItem = DailyGuidanceEvaluator.create_item(gid)
		assert_true(it != null, "Item created for %s" % gid)
		assert_true(it.is_valid(), "Item valid for %s" % gid)
		assert_eq(it.get_id(), gid, "ID matches for %s" % gid)
		assert_false(it.get_display_text().is_empty(), "Display text not empty for %s" % gid)

	assert_false(DailyGuidanceEvaluator.is_valid_guidance_id(""), "Empty ID invalid")
	assert_false(DailyGuidanceEvaluator.is_valid_guidance_id("daily_guidance.unknown"), "Unknown ID invalid")
	assert_true(DailyGuidanceEvaluator.create_item("unknown") == null, "Create item for unknown returns null")


func _test_evaluator_deterministic_three_suggestions() -> void:
	describe("DailyGuidanceEvaluator returns exactly 3 distinct suggestions deterministically per day")
	var day_1: Array[DailyGuidanceItem] = DailyGuidanceEvaluator.evaluate_daily_guidance(1)
	assert_eq(day_1.size(), 3, "Day 1 returns exactly 3 items")

	# Check distinct IDs
	var ids_day_1: Array[String] = [day_1[0].get_id(), day_1[1].get_id(), day_1[2].get_id()]
	assert_false(ids_day_1[0] == ids_day_1[1], "Item 1 and 2 are distinct")
	assert_false(ids_day_1[1] == ids_day_1[2], "Item 2 and 3 are distinct")
	assert_false(ids_day_1[0] == ids_day_1[2], "Item 1 and 3 are distinct")

	# Deterministic: calling again with day 1 produces identical results
	var day_1_repeat: Array[DailyGuidanceItem] = DailyGuidanceEvaluator.evaluate_daily_guidance(1)
	assert_eq(day_1_repeat.size(), 3, "Day 1 repeat returns 3 items")
	for i: int in range(3):
		assert_eq(day_1[i].get_id(), day_1_repeat[i].get_id(), "Deterministic ID match at index %d" % i)

	# Rotation: consecutive days rotate suggestions
	var day_2: Array[DailyGuidanceItem] = DailyGuidanceEvaluator.evaluate_daily_guidance(2)
	assert_eq(day_2.size(), 3, "Day 2 returns 3 items")
	var day_1_ids: String = ",".join(ids_day_1)
	var day_2_ids: String = "%s,%s,%s" % [day_2[0].get_id(), day_2[1].get_id(), day_2[2].get_id()]
	assert_false(day_1_ids == day_2_ids, "Day 1 and Day 2 sets rotate")


func _test_evaluator_adapts_to_garden_context() -> void:
	describe("DailyGuidanceEvaluator adapts gently to garden snapshot")
	# Empty garden (0 plants) -> suggests planting, not harvesting
	var empty_snap: GardenSnapshot = GardenSnapshot.new({}, {}, 0, 0)
	var items_empty: Array[DailyGuidanceItem] = DailyGuidanceEvaluator.evaluate_daily_guidance(0, empty_snap)
	assert_eq(items_empty.size(), 3, "Empty garden gets 3 items")
	assert_eq(items_empty[0].get_id(), DailyGuidanceEvaluator.GUIDANCE_PLANT_ANY, "Empty garden suggests planting any plant")

	# Garden with plants -> includes harvest produce option
	var snap_planted: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1},
		{"plant.jasmine": 1},
		1,
		1
	)
	var items_planted: Array[DailyGuidanceItem] = DailyGuidanceEvaluator.evaluate_daily_guidance(0, snap_planted)
	assert_eq(items_planted.size(), 3, "Planted garden gets 3 items")
	assert_eq(items_planted[0].get_id(), DailyGuidanceEvaluator.GUIDANCE_HARVEST_PRODUCE, "Planted garden suggests harvesting produce")


func _test_evaluator_handles_edge_cases_safely() -> void:
	describe("DailyGuidanceEvaluator handles negative day numbers and null inputs safely")
	var neg_items: Array[DailyGuidanceItem] = DailyGuidanceEvaluator.evaluate_daily_guidance(-5, null, null)
	assert_eq(neg_items.size(), 3, "Negative day number produces 3 items")
	for it: DailyGuidanceItem in neg_items:
		assert_true(it != null and it.is_valid(), "Item from negative day is valid")

	var zero_items: Array[DailyGuidanceItem] = DailyGuidanceEvaluator.evaluate_daily_guidance(0, null, null)
	assert_eq(zero_items.size(), 3, "Day 0 produces 3 items")
