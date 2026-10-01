## test_plant_growth.gd
## Unit tests for PlantGrowth deterministic growth stage rule.
##
## Verifies:
## 1. Type contract and Stage enum explicit numeric values (-1, 0, 1, 2, 3).
## 2. Invalid definition handling (null, fresh default, wrong namespace, invalid thresholds).
## 3. Negative elapsed seconds clamped to zero behavior (PLANTED stage, INT_MIN).
## 4. Exact stage boundaries (PLANTED, SPROUT, GROWING, MATURE).
## 5. Equality transitions immediately into the new stage.
## 6. Alternate definition thresholds verification (non-hardcoded behavior).
## 7. Large elapsed seconds and INT_MAX verification (O(1) execution, no overflow).
## 8. Purity and idempotence (definition unmutated, no global state dependencies).
class_name TestPlantGrowth
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestPlantGrowth"


func run_tests() -> void:
	_test_type_and_enum_contract()
	_test_invalid_definition_handling()
	_test_negative_elapsed_seconds()
	_test_planted_boundary()
	_test_sprout_boundary()
	_test_growing_boundary()
	_test_mature_boundary()
	_test_alternate_definition()
	_test_purity_and_idempotence()


func _create_valid_definition(
	def_id: String = "plant.holy_basil",
	sprout: int = 60,
	growing: int = 300,
	mature: int = 900
) -> PlantDefinition:
	var def: PlantDefinition = PlantDefinition.new()
	def.id = def_id
	def.sprout_after_seconds = sprout
	def.growing_after_seconds = growing
	def.mature_after_seconds = mature
	return def


func _test_type_and_enum_contract() -> void:
	describe("PlantGrowth satisfies RefCounted type contract and Stage enum values")
	var instance: PlantGrowth = PlantGrowth.new()
	assert_true(instance != null, "PlantGrowth instance should not be null")
	assert_true(instance is PlantGrowth, "Instance must satisfy 'is PlantGrowth'")
	assert_true(instance is RefCounted, "PlantGrowth must extend RefCounted")
	var obj: Variant = instance
	assert_false(obj is Node, "PlantGrowth must not be a Node")

	assert_eq(PlantGrowth.Stage.INVALID, -1, "Stage.INVALID must be -1")
	assert_eq(PlantGrowth.Stage.PLANTED, 0, "Stage.PLANTED must be 0")
	assert_eq(PlantGrowth.Stage.SPROUT, 1, "Stage.SPROUT must be 1")
	assert_eq(PlantGrowth.Stage.GROWING, 2, "Stage.GROWING must be 2")
	assert_eq(PlantGrowth.Stage.MATURE, 3, "Stage.MATURE must be 3")

	var def: PlantDefinition = _create_valid_definition()
	var stage: PlantGrowth.Stage = PlantGrowth.stage_for_elapsed_seconds(def, 0)
	assert_eq(stage, PlantGrowth.Stage.PLANTED, "Valid call returns expected Stage enum value")


func _test_invalid_definition_handling() -> void:
	describe("Invalid definitions return Stage.INVALID without mutating definition")
	# 1. null definition
	var null_stage: PlantGrowth.Stage = PlantGrowth.stage_for_elapsed_seconds(null, 100)
	assert_eq(null_stage, PlantGrowth.Stage.INVALID, "Null definition must return Stage.INVALID")

	# 2. Fresh default definition
	var default_def: PlantDefinition = PlantDefinition.new()
	var default_stage: PlantGrowth.Stage = PlantGrowth.stage_for_elapsed_seconds(default_def, 100)
	assert_eq(default_stage, PlantGrowth.Stage.INVALID, "Default uninitialized definition must return Stage.INVALID")

	# 3. Invalid namespace
	var wrong_ns_def: PlantDefinition = PlantDefinition.new()
	wrong_ns_def.id = "visitor.butterfly"
	wrong_ns_def.sprout_after_seconds = 60
	wrong_ns_def.growing_after_seconds = 300
	wrong_ns_def.mature_after_seconds = 900
	var wrong_ns_stage: PlantGrowth.Stage = PlantGrowth.stage_for_elapsed_seconds(wrong_ns_def, 100)
	assert_eq(wrong_ns_stage, PlantGrowth.Stage.INVALID, "Definition with wrong namespace must return Stage.INVALID")
	assert_eq(wrong_ns_def.id, "visitor.butterfly", "id must not be mutated or normalized")

	# 4. Invalid thresholds (equal thresholds: 60/60/900)
	var invalid_thresh_def: PlantDefinition = PlantDefinition.new()
	invalid_thresh_def.id = "plant.holy_basil"
	invalid_thresh_def.sprout_after_seconds = 60
	invalid_thresh_def.growing_after_seconds = 60
	invalid_thresh_def.mature_after_seconds = 900
	var invalid_thresh_stage: PlantGrowth.Stage = PlantGrowth.stage_for_elapsed_seconds(invalid_thresh_def, 100)
	assert_eq(invalid_thresh_stage, PlantGrowth.Stage.INVALID, "Definition with non-increasing thresholds must return Stage.INVALID")
	assert_eq(invalid_thresh_def.sprout_after_seconds, 60, "sprout_after_seconds must not be mutated")
	assert_eq(invalid_thresh_def.growing_after_seconds, 60, "growing_after_seconds must not be mutated")
	assert_eq(invalid_thresh_def.mature_after_seconds, 900, "mature_after_seconds must not be mutated")


func _test_negative_elapsed_seconds() -> void:
	describe("Negative elapsed seconds clamp to 0 and return Stage.PLANTED")
	var def: PlantDefinition = _create_valid_definition()

	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, -1),
		PlantGrowth.Stage.PLANTED,
		"Elapsed -1 must return Stage.PLANTED"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, -100),
		PlantGrowth.Stage.PLANTED,
		"Elapsed -100 must return Stage.PLANTED"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, -9223372036854775807),
		PlantGrowth.Stage.PLANTED,
		"Elapsed -9223372036854775807 must return Stage.PLANTED"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, -9223372036854775807 - 1),
		PlantGrowth.Stage.PLANTED,
		"Elapsed INT_MIN must return Stage.PLANTED without overflow"
	)


func _test_planted_boundary() -> void:
	describe("PLANTED boundary: 0, 1, and 59 seconds for thresholds 60/300/900")
	var def: PlantDefinition = _create_valid_definition("plant.holy_basil", 60, 300, 900)

	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 0),
		PlantGrowth.Stage.PLANTED,
		"Elapsed 0 must return Stage.PLANTED"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 1),
		PlantGrowth.Stage.PLANTED,
		"Elapsed 1 must return Stage.PLANTED"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 59),
		PlantGrowth.Stage.PLANTED,
		"Elapsed 59 must return Stage.PLANTED"
	)


func _test_sprout_boundary() -> void:
	describe("SPROUT boundary: 60, 61, and 299 seconds for thresholds 60/300/900")
	var def: PlantDefinition = _create_valid_definition("plant.holy_basil", 60, 300, 900)

	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 60),
		PlantGrowth.Stage.SPROUT,
		"Elapsed 60 must transition immediately to Stage.SPROUT"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 61),
		PlantGrowth.Stage.SPROUT,
		"Elapsed 61 must return Stage.SPROUT"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 299),
		PlantGrowth.Stage.SPROUT,
		"Elapsed 299 must return Stage.SPROUT"
	)


func _test_growing_boundary() -> void:
	describe("GROWING boundary: 300, 301, and 899 seconds for thresholds 60/300/900")
	var def: PlantDefinition = _create_valid_definition("plant.holy_basil", 60, 300, 900)

	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 300),
		PlantGrowth.Stage.GROWING,
		"Elapsed 300 must transition immediately to Stage.GROWING"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 301),
		PlantGrowth.Stage.GROWING,
		"Elapsed 301 must return Stage.GROWING"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 899),
		PlantGrowth.Stage.GROWING,
		"Elapsed 899 must return Stage.GROWING"
	)


func _test_mature_boundary() -> void:
	describe("MATURE boundary: 900, 901, large int, and INT_MAX for thresholds 60/300/900")
	var def: PlantDefinition = _create_valid_definition("plant.holy_basil", 60, 300, 900)

	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 900),
		PlantGrowth.Stage.MATURE,
		"Elapsed 900 must transition immediately to Stage.MATURE"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 901),
		PlantGrowth.Stage.MATURE,
		"Elapsed 901 must return Stage.MATURE"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 1000000),
		PlantGrowth.Stage.MATURE,
		"Large safe positive elapsed (1,000,000) must return Stage.MATURE"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 9223372036854775807),
		PlantGrowth.Stage.MATURE,
		"GDScript INT_MAX (9223372036854775807) must return Stage.MATURE without overflow"
	)


func _test_alternate_definition() -> void:
	describe("Alternate definition (1, 2, 3) proves rule is data-driven, not hardcoded")
	var def: PlantDefinition = _create_valid_definition("plant.chili", 1, 2, 3)

	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 0),
		PlantGrowth.Stage.PLANTED,
		"Elapsed 0 with alternate definition must return Stage.PLANTED"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 1),
		PlantGrowth.Stage.SPROUT,
		"Elapsed 1 with alternate definition must transition immediately to Stage.SPROUT"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 2),
		PlantGrowth.Stage.GROWING,
		"Elapsed 2 with alternate definition must transition immediately to Stage.GROWING"
	)
	assert_eq(
		PlantGrowth.stage_for_elapsed_seconds(def, 3),
		PlantGrowth.Stage.MATURE,
		"Elapsed 3 with alternate definition must transition immediately to Stage.MATURE"
	)


func _test_purity_and_idempotence() -> void:
	describe("stage_for_elapsed_seconds is pure, stateless, and idempotent across repeated calls")
	var def: PlantDefinition = _create_valid_definition("plant.holy_basil", 60, 300, 900)

	for i: int in range(5):
		var stage: PlantGrowth.Stage = PlantGrowth.stage_for_elapsed_seconds(def, 300)
		assert_eq(
			stage,
			PlantGrowth.Stage.GROWING,
			"Repeated call %d must return Stage.GROWING" % i
		)

	assert_eq(def.id, "plant.holy_basil", "id must remain unchanged")
	assert_eq(def.sprout_after_seconds, 60, "sprout_after_seconds must remain unchanged")
	assert_eq(def.growing_after_seconds, 300, "growing_after_seconds must remain unchanged")
	assert_eq(def.mature_after_seconds, 900, "mature_after_seconds must remain unchanged")
