## test_visitor_definition.gd
## Unit tests for Garden's VisitorDefinition domain resource.
class_name TestVisitorDefinition
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestVisitorDefinition"


func run_tests() -> void:
	_test_type_contract_and_default_invalid()
	_test_valid_definitions()
	_test_invalid_ids()
	_test_invalid_weights()
	_test_invalid_required_trait_counts()
	_test_invalid_required_plant_ids_and_minimums()


func _test_type_contract_and_default_invalid() -> void:
	describe("VisitorDefinition extends Resource, is not a Node, and default instance is invalid")
	var def: VisitorDefinition = VisitorDefinition.new()
	assert_true(def != null, "Instance must not be null")
	assert_true(def is VisitorDefinition, "Must be VisitorDefinition")
	assert_true(def is Resource, "Must extend Resource")
	var obj: Variant = def
	assert_false(obj is Node, "Must not be a Node")

	assert_eq(def.id, "", "Default id is empty")
	assert_eq(def.weight, 0.0, "Default weight is 0.0")
	assert_false(def.is_valid(), "Default fresh VisitorDefinition must be invalid")


func _test_valid_definitions() -> void:
	describe("Valid VisitorDefinition instances with canonical visitor IDs and positive weights return true")
	var butterfly: VisitorDefinition = VisitorDefinition.new()
	butterfly.id = "visitor.butterfly"
	butterfly.weight = 30.0
	butterfly.required_trait_counts = {"flower": 1}
	butterfly.min_total_plants = 1
	assert_true(butterfly.is_valid(), "Butterfly visitor definition must be valid")

	var rare_cat: VisitorDefinition = VisitorDefinition.new()
	rare_cat.id = "visitor.cat"
	rare_cat.weight = 5.5
	rare_cat.required_trait_counts = {"shade": 1, "flower": 2}
	rare_cat.required_plant_ids = ["plant.jasmine", "plant.banana"]
	rare_cat.min_total_plants = 3
	rare_cat.min_mature_plants = 1
	assert_true(rare_cat.is_valid(), "Multi-requirement visitor definition must be valid")


func _test_invalid_ids() -> void:
	describe("VisitorDefinition rejects non-visitor namespace or malformed IDs")
	var bad_ids: Array[String] = [
		"",
		"visitor",
		"Visitor.butterfly",
		"visitor.",
		"visitor..butterfly",
		"plant.holy_basil",
		"decoration.clay_jar",
		"event.cat_sleeping",
		"visitor.123",
	]
	for bad_id: String in bad_ids:
		var def: VisitorDefinition = VisitorDefinition.new()
		def.id = bad_id
		def.weight = 10.0
		def.required_trait_counts = {"flower": 1}
		assert_false(def.is_valid(), "VisitorDefinition with invalid ID '%s' must be invalid" % bad_id)


func _test_invalid_weights() -> void:
	describe("VisitorDefinition rejects zero, negative, or non-finite weights")
	var bad_weights: Array[float] = [0.0, -0.1, -10.0, NAN, INF, -INF]
	for w: float in bad_weights:
		var def: VisitorDefinition = VisitorDefinition.new()
		def.id = "visitor.butterfly"
		def.weight = w
		def.required_trait_counts = {"flower": 1}
		assert_false(def.is_valid(), "VisitorDefinition with weight %s must be invalid" % str(w))


func _test_invalid_required_trait_counts() -> void:
	describe("VisitorDefinition rejects unknown trait keys or non-positive/non-int trait counts")
	var bad_trait_maps: Array[Dictionary] = [
		{"unknown_trait": 1},
		{"flower": 0},
		{"flower": -1},
		{"flower": 1.5},
		{"flower": "1"},
		{123: 1},
	]
	for bad_map: Dictionary in bad_trait_maps:
		var def: VisitorDefinition = VisitorDefinition.new()
		def.id = "visitor.butterfly"
		def.weight = 10.0
		def.required_trait_counts = bad_map
		assert_false(
			def.is_valid(),
			"VisitorDefinition with invalid required_trait_counts %s must be invalid" % str(bad_map)
		)


func _test_invalid_required_plant_ids_and_minimums() -> void:
	describe("VisitorDefinition rejects invalid/duplicate required_plant_ids and negative minimums")
	var def_neg_total: VisitorDefinition = VisitorDefinition.new()
	def_neg_total.id = "visitor.butterfly"
	def_neg_total.weight = 10.0
	def_neg_total.min_total_plants = -1
	assert_false(def_neg_total.is_valid(), "Negative min_total_plants must be invalid")

	var def_neg_mature: VisitorDefinition = VisitorDefinition.new()
	def_neg_mature.id = "visitor.butterfly"
	def_neg_mature.weight = 10.0
	def_neg_mature.min_mature_plants = -1
	assert_false(def_neg_mature.is_valid(), "Negative min_mature_plants must be invalid")

	var def_bad_plant: VisitorDefinition = VisitorDefinition.new()
	def_bad_plant.id = "visitor.butterfly"
	def_bad_plant.weight = 10.0
	def_bad_plant.required_plant_ids = ["visitor.frog"]
	assert_false(def_bad_plant.is_valid(), "Non-plant ID in required_plant_ids must be invalid")

	var def_dup_plant: VisitorDefinition = VisitorDefinition.new()
	def_dup_plant.id = "visitor.butterfly"
	def_dup_plant.weight = 10.0
	def_dup_plant.required_plant_ids = ["plant.jasmine", "plant.jasmine"]
	assert_false(def_dup_plant.is_valid(), "Duplicate plant ID in required_plant_ids must be invalid")
