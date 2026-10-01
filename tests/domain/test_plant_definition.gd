## test_plant_definition.gd
## Unit tests for Garden's PlantDefinition domain resource.
##
## Verifies:
## 1. PlantDefinition satisfies type contract: Resource, not Node, separate instances.
## 2. Default fresh PlantDefinition instance is invalid.
## 3. Valid definitions with canonical plant namespace IDs and strictly increasing
##    cumulative growth thresholds return true.
## 4. Invalid IDs (syntax, empty, missing plant namespace) return false.
## 5. Invalid cumulative growth thresholds (non-positive, non-increasing) return false.
## 6. Field independence: changing single fields invalidates without mutating other fields.
## 7. API purity and idempotence: no mutation, no normalization, repeated calls yield identical results.
class_name TestPlantDefinition
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestPlantDefinition"


func run_tests() -> void:
	_test_type_contract()
	_test_default_instance_is_invalid()
	_test_valid_definitions()
	_test_invalid_ids()
	_test_invalid_growth_thresholds()
	_test_field_independence_and_no_mutation()
	_test_api_purity_and_idempotence()


func _test_type_contract() -> void:
	describe("PlantDefinition satisfies Resource type contract and is not a Node")
	var instance: PlantDefinition = PlantDefinition.new()
	assert_true(instance != null, "PlantDefinition instance should not be null")
	assert_true(instance is PlantDefinition, "Instance must satisfy 'is PlantDefinition'")
	assert_true(instance is Resource, "PlantDefinition must extend Resource")
	var obj: Variant = instance
	assert_false(obj is Node, "PlantDefinition must not be a Node")

	var instance_2: PlantDefinition = PlantDefinition.new()
	assert_true(instance_2 != null, "Second PlantDefinition instance should not be null")
	assert_true(instance != instance_2, "Separate constructions must yield distinct instances")


func _test_default_instance_is_invalid() -> void:
	describe("Default fresh PlantDefinition instance is invalid")
	var definition: PlantDefinition = PlantDefinition.new()
	assert_eq(definition.id, "", "Default id must be empty string")
	assert_eq(definition.sprout_after_seconds, 0, "Default sprout_after_seconds must be 0")
	assert_eq(definition.growing_after_seconds, 0, "Default growing_after_seconds must be 0")
	assert_eq(definition.mature_after_seconds, 0, "Default mature_after_seconds must be 0")
	assert_false(definition.is_valid(), "Default fresh instance must be invalid")


func _test_valid_definitions() -> void:
	describe("Valid PlantDefinition instances return true")
	var test_cases: Array[Dictionary] = [
		{
			"id": "plant.holy_basil",
			"sprout": 60,
			"growing": 300,
			"mature": 900,
		},
		{
			"id": "plant.chili",
			"sprout": 1,
			"growing": 2,
			"mature": 3,
		},
		{
			"id": "plant.variant.holy_basil",
			"sprout": 10,
			"growing": 20,
			"mature": 30,
		},
		{
			"id": "plant.jasmine",
			"sprout": 100,
			"growing": 200,
			"mature": 300,
		},
		{
			"id": "plant.marigold",
			"sprout": 50,
			"growing": 150,
			"mature": 450,
		},
		{
			"id": "plant.banana",
			"sprout": 500,
			"growing": 1000,
			"mature": 2000,
		},
	]

	for tc: Dictionary in test_cases:
		var def: PlantDefinition = PlantDefinition.new()
		def.id = tc["id"]
		def.sprout_after_seconds = tc["sprout"]
		def.growing_after_seconds = tc["growing"]
		def.mature_after_seconds = tc["mature"]
		assert_true(
			def.is_valid(),
			"Valid definition '%s' (%d/%d/%d) must return true"
			% [def.id, def.sprout_after_seconds, def.growing_after_seconds, def.mature_after_seconds]
		)


func _test_invalid_ids() -> void:
	describe("Invalid IDs return false with otherwise valid growth thresholds")
	var invalid_ids: Array[String] = [
		"",
		"plant",
		"Plant.holy_basil",
		"plant.",
		"plant..basil",
		"visitor.butterfly",
		"decoration.clay_jar",
		"event.cat_sleeping",
		"weather.rain",
		"plant._basil",
		"plant.123",
		"res://plants/basil.tres",
	]

	for inv_id: String in invalid_ids:
		var def: PlantDefinition = PlantDefinition.new()
		def.id = inv_id
		def.sprout_after_seconds = 60
		def.growing_after_seconds = 300
		def.mature_after_seconds = 900
		assert_false(
			def.is_valid(),
			"Invalid ID '%s' with valid thresholds must return false" % inv_id
		)


func _test_invalid_growth_thresholds() -> void:
	describe("Invalid growth thresholds return false with valid ID")
	var invalid_triples: Array[Array] = [
		[0, 300, 900],
		[-1, 300, 900],
		[60, 60, 900],
		[60, 59, 900],
		[60, 300, 300],
		[60, 300, 299],
		[-5, -3, -1],
		[100, 50, 200],
	]

	for triple: Array in invalid_triples:
		var def: PlantDefinition = PlantDefinition.new()
		def.id = "plant.holy_basil"
		def.sprout_after_seconds = triple[0]
		def.growing_after_seconds = triple[1]
		def.mature_after_seconds = triple[2]
		assert_false(
			def.is_valid(),
			"Invalid thresholds (%d, %d, %d) must return false" % [triple[0], triple[1], triple[2]]
		)

	# Boundary minimum valid strictly increasing positive thresholds
	var valid_min: PlantDefinition = PlantDefinition.new()
	valid_min.id = "plant.holy_basil"
	valid_min.sprout_after_seconds = 1
	valid_min.growing_after_seconds = 2
	valid_min.mature_after_seconds = 3
	assert_true(valid_min.is_valid(), "Minimal thresholds (1, 2, 3) must return true")


func _test_field_independence_and_no_mutation() -> void:
	describe("Field independence: invalidating a single field does not mutate others; no normalization")
	var def: PlantDefinition = PlantDefinition.new()
	def.id = "plant.holy_basil"
	def.sprout_after_seconds = 60
	def.growing_after_seconds = 300
	def.mature_after_seconds = 900
	assert_true(def.is_valid(), "Baseline definition must be valid")

	# Test id independence and no normalization
	def.id = "Plant.holy_basil"
	assert_false(def.is_valid(), "Cased ID must make definition invalid")
	assert_eq(def.id, "Plant.holy_basil", "id must not be mutated or normalized")
	assert_eq(def.sprout_after_seconds, 60, "sprout_after_seconds must remain 60")
	assert_eq(def.growing_after_seconds, 300, "growing_after_seconds must remain 300")
	assert_eq(def.mature_after_seconds, 900, "mature_after_seconds must remain 900")

	# Restore id
	def.id = "plant.holy_basil"
	assert_true(def.is_valid(), "Restored id must make definition valid")

	# Invalidate sprout threshold
	def.sprout_after_seconds = 0
	assert_false(def.is_valid(), "Zero sprout threshold must make definition invalid")
	assert_eq(def.id, "plant.holy_basil", "id must remain unchanged")
	assert_eq(def.sprout_after_seconds, 0, "sprout threshold must remain 0 (no repair)")
	def.sprout_after_seconds = 60
	assert_true(def.is_valid(), "Restored sprout threshold must make definition valid")

	# Invalidate growing threshold
	def.growing_after_seconds = 50
	assert_false(def.is_valid(), "Growing <= sprout must make definition invalid")
	assert_eq(def.id, "plant.holy_basil", "id must remain unchanged")
	assert_eq(def.growing_after_seconds, 50, "growing threshold must remain 50 (no repair)")
	def.growing_after_seconds = 300
	assert_true(def.is_valid(), "Restored growing threshold must make definition valid")

	# Invalidate mature threshold
	def.mature_after_seconds = 200
	assert_false(def.is_valid(), "Mature <= growing must make definition invalid")
	assert_eq(def.id, "plant.holy_basil", "id must remain unchanged")
	assert_eq(def.mature_after_seconds, 200, "mature threshold must remain 200 (no repair)")
	def.mature_after_seconds = 900
	assert_true(def.is_valid(), "Restored mature threshold must make definition valid")


func _test_api_purity_and_idempotence() -> void:
	describe("Validation is pure, stateless, and idempotent across repeated calls")
	var valid_def: PlantDefinition = PlantDefinition.new()
	valid_def.id = "plant.holy_basil"
	valid_def.sprout_after_seconds = 60
	valid_def.growing_after_seconds = 300
	valid_def.mature_after_seconds = 900

	var invalid_def: PlantDefinition = PlantDefinition.new()
	invalid_def.id = "plant.holy_basil"
	invalid_def.sprout_after_seconds = 60
	invalid_def.growing_after_seconds = 60
	invalid_def.mature_after_seconds = 900

	for i: int in range(5):
		assert_true(
			valid_def.is_valid(),
			"Repeated is_valid() call %d on valid definition must return true" % i
		)
		assert_false(
			invalid_def.is_valid(),
			"Repeated is_valid() call %d on invalid definition must return false" % i
		)
