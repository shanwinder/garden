## test_visitor_eligibility.gd
## Deterministic unit tests for VisitorEligibility domain rules.
class_name TestVisitorEligibility
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestVisitorEligibility"


func run_tests() -> void:
	_test_null_and_invalid_inputs()
	_test_trait_count_eligibility_boundaries()
	_test_plant_id_and_maturity_requirements()
	_test_filter_eligible_visitors_order_and_filtering()
	_test_decoration_time_and_weather_eligibility()


func _create_visitor(
	id: String,
	traits: Dictionary = {},
	min_total: int = 1,
	min_mature: int = 0,
	req_plants: Array[String] = []
) -> VisitorDefinition:
	var v: VisitorDefinition = VisitorDefinition.new()
	v.id = id
	v.weight = 10.0
	v.required_trait_counts = traits
	v.min_total_plants = min_total
	v.min_mature_plants = min_mature
	v.required_plant_ids = req_plants
	return v


func _test_null_and_invalid_inputs() -> void:
	describe("VisitorEligibility safely returns false/empty for null or invalid inputs")
	var valid_visitor: VisitorDefinition = _create_visitor("visitor.butterfly", {"flower": 1})
	var invalid_visitor: VisitorDefinition = VisitorDefinition.new()
	var snap: GardenSnapshot = GardenSnapshot.new({"flower": 1}, {"plant.marigold": 1}, 1, 0)

	assert_false(VisitorEligibility.is_eligible(null, snap), "Null visitor is ineligible")
	assert_false(VisitorEligibility.is_eligible(valid_visitor, null), "Null snapshot is ineligible")
	assert_false(VisitorEligibility.is_eligible(invalid_visitor, snap), "Invalid visitor is ineligible")
	assert_eq(VisitorEligibility.filter_eligible_visitors([valid_visitor], null).size(), 0, "Null snapshot returns empty array")


func _test_trait_count_eligibility_boundaries() -> void:
	describe("VisitorEligibility checks exact trait thresholds and multi-trait AND requirements")
	var butterfly: VisitorDefinition = _create_visitor("visitor.butterfly", {"flower": 2}, 1)
	var frog: VisitorDefinition = _create_visitor("visitor.frog", {"water": 1, "shade": 1}, 1)

	var empty_snap: GardenSnapshot = GardenSnapshot.new()
	assert_false(VisitorEligibility.is_eligible(butterfly, empty_snap), "Ineligible on empty garden")

	var one_flower_snap: GardenSnapshot = GardenSnapshot.new({"flower": 1}, {"plant.marigold": 1}, 1, 0)
	assert_false(VisitorEligibility.is_eligible(butterfly, one_flower_snap), "Ineligible when flower == 1 < 2")

	var two_flower_snap: GardenSnapshot = GardenSnapshot.new({"flower": 2}, {"plant.marigold": 2}, 2, 0)
	assert_true(VisitorEligibility.is_eligible(butterfly, two_flower_snap), "Eligible at exact boundary flower == 2")

	var water_only_snap: GardenSnapshot = GardenSnapshot.new({"water": 1}, {"plant.banana": 1}, 1, 0)
	assert_false(VisitorEligibility.is_eligible(frog, water_only_snap), "Ineligible when missing second required trait 'shade'")

	var water_and_shade_snap: GardenSnapshot = GardenSnapshot.new({"water": 1, "shade": 2}, {"plant.banana": 1}, 1, 0)
	assert_true(VisitorEligibility.is_eligible(frog, water_and_shade_snap), "Eligible when both water and shade requirements met")


func _test_plant_id_and_maturity_requirements() -> void:
	describe("VisitorEligibility enforces required_plant_ids, min_total_plants, and min_mature_plants")
	var jasmine_cat: VisitorDefinition = _create_visitor(
		"visitor.cat",
		{"flower": 1, "shade": 1},
		2,
		1,
		["plant.jasmine"]
	)

	# Has traits (from marigold + banana), 2 total, 1 mature, but missing plant.jasmine
	var snap_no_jasmine: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1, "shade": 1},
		{"plant.marigold": 1, "plant.banana": 1},
		2,
		1
	)
	assert_false(
		VisitorEligibility.is_eligible(jasmine_cat, snap_no_jasmine),
		"Ineligible when required plant.jasmine is not present"
	)

	# Has plant.jasmine + banana, 2 total, but 0 mature
	var snap_not_mature: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1, "shade": 1},
		{"plant.jasmine": 1, "plant.banana": 1},
		2,
		0
	)
	assert_false(
		VisitorEligibility.is_eligible(jasmine_cat, snap_not_mature),
		"Ineligible when mature_plant_count (0) < min_mature_plants (1)"
	)

	# All conditions met
	var snap_all_met: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1, "shade": 1},
		{"plant.jasmine": 1, "plant.banana": 1},
		2,
		1
	)
	assert_true(
		VisitorEligibility.is_eligible(jasmine_cat, snap_all_met),
		"Eligible when traits, required plant ID, total count, and mature count are all met"
	)


func _test_filter_eligible_visitors_order_and_filtering() -> void:
	describe("filter_eligible_visitors preserves input order and filters out ineligible visitors")
	var v_bird: VisitorDefinition = _create_visitor("visitor.bird", {"fruit": 1})
	var v_butterfly: VisitorDefinition = _create_visitor("visitor.butterfly", {"flower": 1})
	var v_cat: VisitorDefinition = _create_visitor("visitor.cat", {"shade": 1})
	var v_firefly: VisitorDefinition = _create_visitor("visitor.firefly", {"dense_vegetation": 1})
	var v_frog: VisitorDefinition = _create_visitor("visitor.frog", {"water": 1})

	var all_visitors: Array[VisitorDefinition] = [v_bird, v_butterfly, v_cat, v_firefly, v_frog]

	# Garden with jasmine (flower, dense_vegetation) and banana (fruit, shade, perch, shelter)
	var snap: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1, "dense_vegetation": 1, "fruit": 1, "shade": 1},
		{"plant.jasmine": 1, "plant.banana": 1},
		2,
		1
	)

	var eligible: Array[VisitorDefinition] = VisitorEligibility.filter_eligible_visitors(all_visitors, snap)
	assert_eq(eligible.size(), 4, "4 of 5 visitors are eligible (frog excluded due to no water)")
	assert_eq(eligible[0].id, "visitor.bird", "1st eligible is visitor.bird")
	assert_eq(eligible[1].id, "visitor.butterfly", "2nd eligible is visitor.butterfly")
	assert_eq(eligible[2].id, "visitor.cat", "3rd eligible is visitor.cat")
	assert_eq(eligible[3].id, "visitor.firefly", "4th eligible is visitor.firefly")


func _test_decoration_time_and_weather_eligibility() -> void:
	describe("VisitorEligibility enforces required_decoration_ids, allowed_time_periods, and allowed_weather_states")
	var rain_frog: VisitorDefinition = _create_visitor("visitor.frog", {"water": 1}, 0)
	rain_frog.required_decoration_ids = ["decoration.small_pond"]
	rain_frog.allowed_time_periods = ["evening", "night"]
	rain_frog.allowed_weather_states = ["rain"]

	var snap_match: GardenSnapshot = GardenSnapshot.new(
		{"water": 1},
		{},
		0,
		0,
		{"decoration.small_pond": 1},
		1,
		"night",
		"rain"
	)
	assert_true(
		VisitorEligibility.is_eligible(rain_frog, snap_match),
		"Eligible when required decoration, time period, and weather state all match"
	)

	var snap_wrong_decor: GardenSnapshot = GardenSnapshot.new(
		{"water": 1},
		{},
		0,
		0,
		{"decoration.clay_jar": 1},
		1,
		"night",
		"rain"
	)
	assert_false(
		VisitorEligibility.is_eligible(rain_frog, snap_wrong_decor),
		"Ineligible when required decoration is missing"
	)

	var snap_wrong_period: GardenSnapshot = GardenSnapshot.new(
		{"water": 1},
		{},
		0,
		0,
		{"decoration.small_pond": 1},
		1,
		"morning",
		"rain"
	)
	assert_false(
		VisitorEligibility.is_eligible(rain_frog, snap_wrong_period),
		"Ineligible when time_period is not in allowed_time_periods"
	)

	var snap_wrong_weather: GardenSnapshot = GardenSnapshot.new(
		{"water": 1},
		{},
		0,
		0,
		{"decoration.small_pond": 1},
		1,
		"night",
		"clear"
	)
	assert_false(
		VisitorEligibility.is_eligible(rain_frog, snap_wrong_weather),
		"Ineligible when weather_state is not in allowed_weather_states"
	)
