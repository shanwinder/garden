## test_garden_snapshot.gd
## Unit tests for Garden's GardenSnapshot immutable domain query model.
class_name TestGardenSnapshot
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGardenSnapshot"


func run_tests() -> void:
	_test_type_contract_and_empty_defaults()
	_test_trait_and_plant_queries()
	_test_defensive_encapsulation_and_sanitization()
	_test_decoration_queries()


func _test_type_contract_and_empty_defaults() -> void:
	describe("GardenSnapshot satisfies RefCounted contract and defaults to empty garden")
	var snap: GardenSnapshot = GardenSnapshot.new()
	assert_true(snap != null, "Snapshot must not be null")
	assert_true(snap is GardenSnapshot, "Must be GardenSnapshot")
	assert_true(snap is RefCounted, "Must extend RefCounted")
	var obj: Variant = snap
	assert_false(obj is Node, "Must not be a Node")
	assert_false(obj is Resource, "Must not be a Resource")

	assert_true(snap.is_empty_garden(), "Default snapshot is empty garden")
	assert_eq(snap.get_total_plant_count(), 0, "Total plants 0")
	assert_eq(snap.get_mature_plant_count(), 0, "Mature plants 0")
	assert_eq(snap.get_active_traits().size(), 0, "No active traits")
	assert_eq(snap.get_present_plant_definition_ids().size(), 0, "No present plant IDs")
	assert_eq(snap.get_trait_count("flower"), 0, "Flower count 0")
	assert_false(snap.has_trait("flower", 1), "has_trait('flower', 1) is false")
	assert_false(snap.has_trait("flower", 0), "has_trait with min_count <= 0 is false")


func _test_trait_and_plant_queries() -> void:
	describe("GardenSnapshot reports exact trait counts, sorted active traits, and plant counts")
	var traits: Dictionary = {
		"shade": 1,
		"flower": 3,
		"dense_vegetation": 2,
	}
	var plants_by_id: Dictionary = {
		"plant.jasmine": 2,
		"plant.marigold": 1,
		"plant.banana": 1,
	}
	var snap: GardenSnapshot = GardenSnapshot.new(traits, plants_by_id, 4, 2)

	assert_false(snap.is_empty_garden(), "Not empty when total_plant_count == 4")
	assert_eq(snap.get_total_plant_count(), 4, "Total plant count is 4")
	assert_eq(snap.get_mature_plant_count(), 2, "Mature plant count is 2")

	assert_eq(snap.get_trait_count("flower"), 3, "Flower count is 3")
	assert_eq(snap.get_trait_count("dense_vegetation"), 2, "Dense vegetation count is 2")
	assert_eq(snap.get_trait_count("shade"), 1, "Shade count is 1")
	assert_eq(snap.get_trait_count("water"), 0, "Absent trait count is 0")

	assert_true(snap.has_trait("flower", 1), "has_trait flower >= 1")
	assert_true(snap.has_trait("flower", 3), "has_trait flower >= 3")
	assert_false(snap.has_trait("flower", 4), "has_trait flower >= 4 is false")
	assert_false(snap.has_trait("water", 1), "has_trait water >= 1 is false")

	var expected_traits: Array[String] = ["dense_vegetation", "flower", "shade"]
	assert_eq(snap.get_active_traits(), expected_traits, "Active traits sorted in ascending order")

	assert_eq(snap.get_plant_count_for_definition("plant.jasmine"), 2, "Jasmine count is 2")
	assert_eq(snap.get_plant_count_for_definition("plant.banana"), 1, "Banana count is 1")
	assert_eq(snap.get_plant_count_for_definition("plant.chili"), 0, "Chili count is 0")

	var expected_plants: Array[String] = ["plant.banana", "plant.jasmine", "plant.marigold"]
	assert_eq(
		snap.get_present_plant_definition_ids(),
		expected_plants,
		"Present plant definition IDs sorted in ascending order"
	)


func _test_defensive_encapsulation_and_sanitization() -> void:
	describe("GardenSnapshot defensively copies inputs/outputs and sanitizes non-positive or unknown entries")
	var input_traits: Dictionary = {
		"flower": 2,
		"water": 0,
		"shade": -3,
		"unknown_trait": 5,
	}
	var input_plants: Dictionary = {
		"plant.holy_basil": 1,
		"plant.chili": 0,
	}
	var snap: GardenSnapshot = GardenSnapshot.new(input_traits, input_plants, 2, 10)

	# Mature count clamped to total count; zero/negative/unknown traits ignored
	assert_eq(snap.get_total_plant_count(), 2, "Total count is 2")
	assert_eq(snap.get_mature_plant_count(), 2, "Mature count clamped to total count (2)")
	assert_eq(snap.get_active_traits(), ["flower"], "Only positive valid traits retained")
	assert_eq(snap.get_trait_count("water"), 0, "Zero trait count not active")
	assert_eq(snap.get_trait_count("shade"), 0, "Negative trait count ignored")
	assert_eq(snap.get_trait_count("unknown_trait"), 0, "Unknown trait ignored")

	# Mutating caller dictionaries after construction must not affect snapshot
	input_traits["flower"] = 99
	input_traits["water"] = 5
	input_plants["plant.holy_basil"] = 50
	assert_eq(snap.get_trait_count("flower"), 2, "Snapshot flower count unaffected by caller mutation")
	assert_eq(snap.get_trait_count("water"), 0, "Snapshot water count unaffected by caller mutation")
	assert_eq(
		snap.get_plant_count_for_definition("plant.holy_basil"),
		1,
		"Snapshot plant count unaffected by caller mutation"
	)

	# Mutating returned arrays must not affect snapshot
	var active: Array[String] = snap.get_active_traits()
	active.clear()
	assert_eq(snap.get_active_traits(), ["flower"], "Returned active traits array is a defensive copy")


func _test_decoration_queries() -> void:
	describe("GardenSnapshot stores and queries decoration counts and sorted present decoration IDs")
	var traits: Dictionary = {"water": 2, "shade": 1}
	var plants: Dictionary = {"plant.holy_basil": 1}
	var decors: Dictionary = {
		"decoration.small_pond": 1,
		"decoration.clay_jar": 2,
		"decoration.plant_pot": 0,
	}
	var snap: GardenSnapshot = GardenSnapshot.new(traits, plants, 1, 0, decors, 3)

	assert_eq(snap.get_total_decoration_count(), 3, "Total decoration count is 3")
	assert_eq(snap.get_decoration_count_for_definition("decoration.clay_jar"), 2, "Clay jar count is 2")
	assert_eq(snap.get_decoration_count_for_definition("decoration.small_pond"), 1, "Small pond count is 1")
	assert_eq(snap.get_decoration_count_for_definition("decoration.plant_pot"), 0, "Zero count decoration ignored")
	assert_eq(
		snap.get_present_decoration_definition_ids(),
		["decoration.clay_jar", "decoration.small_pond"],
		"Present decoration definition IDs sorted in ascending order"
	)
