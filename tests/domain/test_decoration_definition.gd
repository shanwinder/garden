## test_decoration_definition.gd
## Unit tests for Garden's DecorationDefinition domain content contract.
class_name TestDecorationDefinition
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestDecorationDefinition"


func run_tests() -> void:
	_test_type_contract_and_defaults()
	_test_valid_definitions()
	_test_invalid_id_price_and_traits()


func _test_type_contract_and_defaults() -> void:
	describe("DecorationDefinition extends Resource and defaults to invalid until configured")
	var def: DecorationDefinition = DecorationDefinition.new()
	assert_true(def != null, "DecorationDefinition instance must not be null")
	assert_true(def is DecorationDefinition, "Must be DecorationDefinition")
	assert_true(def is Resource, "Must extend Resource")
	var obj: Variant = def
	assert_false(obj is Node, "Must not be a Node")
	assert_eq(DecorationDefinition.DECORATION_NAMESPACE_PREFIX, "decoration.", "Namespace prefix constant is 'decoration.'")
	assert_false(def.is_valid(), "Fresh default DecorationDefinition with empty id is invalid")


func _test_valid_definitions() -> void:
	describe("Valid DecorationDefinition instances pass is_valid() with 0 or positive price and valid traits")
	var pot: DecorationDefinition = DecorationDefinition.new()
	pot.id = "decoration.plant_pot"
	pot.price = 10
	pot.environmental_traits = []
	assert_true(pot.is_valid(), "Plant pot with empty traits is valid")
	assert_false(pot.has_environmental_trait("water"), "Plant pot has no water trait")

	var pond: DecorationDefinition = DecorationDefinition.new()
	pond.id = "decoration.small_pond"
	pond.price = 50
	pond.environmental_traits = ["shelter", "water"]
	assert_true(pond.is_valid(), "Small pond with shelter + water traits is valid")
	assert_true(pond.has_environmental_trait("water"), "Small pond has water trait")
	assert_true(pond.has_environmental_trait("shelter"), "Small pond has shelter trait")
	assert_eq(pond.get_environmental_traits(), ["shelter", "water"], "get_environmental_traits returns traits")

	var free_decor: DecorationDefinition = DecorationDefinition.new()
	free_decor.id = "decoration.wooden_fence"
	free_decor.price = 0
	free_decor.environmental_traits = ["perch"]
	assert_true(free_decor.is_valid(), "Decoration with price == 0 is valid")


func _test_invalid_id_price_and_traits() -> void:
	describe("DecorationDefinition rejects non-decoration IDs, negative prices, and invalid or duplicate traits")
	var bad_ns: DecorationDefinition = DecorationDefinition.new()
	bad_ns.id = "plant.holy_basil"
	bad_ns.price = 15
	assert_false(bad_ns.is_valid(), "Plant namespace fails is_valid()")

	var neg_price: DecorationDefinition = DecorationDefinition.new()
	neg_price.id = "decoration.clay_jar"
	neg_price.price = -1
	assert_false(neg_price.is_valid(), "Negative price fails is_valid()")

	var bad_trait: DecorationDefinition = DecorationDefinition.new()
	bad_trait.id = "decoration.clay_jar"
	bad_trait.price = 15
	bad_trait.environmental_traits = ["unknown_trait"]
	assert_false(bad_trait.is_valid(), "Unknown trait fails is_valid()")

	var dup_trait: DecorationDefinition = DecorationDefinition.new()
	dup_trait.id = "decoration.clay_jar"
	dup_trait.price = 15
	dup_trait.environmental_traits = ["water", "water"]
	assert_false(dup_trait.is_valid(), "Duplicate trait fails is_valid()")
