## test_environmental_trait.gd
## Unit tests for Garden's EnvironmentalTrait domain validation primitive.
class_name TestEnvironmentalTrait
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestEnvironmentalTrait"


func run_tests() -> void:
	_test_canonical_traits_are_valid()
	_test_invalid_traits_rejected()
	_test_trait_list_validation()


func _test_canonical_traits_are_valid() -> void:
	describe("All 9 canonical environmental traits are valid and sorted in ALL_TRAITS")
	var expected: Array[String] = [
		"dense_vegetation",
		"flower",
		"food",
		"fruit",
		"light",
		"perch",
		"shade",
		"shelter",
		"water",
	]
	assert_eq(EnvironmentalTrait.ALL_TRAITS, expected, "ALL_TRAITS must match canonical sorted list")

	for trait_id: String in expected:
		assert_true(
			EnvironmentalTrait.is_valid(trait_id),
			"Canonical trait '%s' must be valid" % trait_id
		)


func _test_invalid_traits_rejected() -> void:
	describe("Unknown, empty, cased, or whitespace-padded traits are rejected")
	var invalid_traits: Array[String] = [
		"",
		"Flower",
		"FLOWER",
		" flower",
		"flower ",
		"plant.flower",
		"visitor.butterfly",
		"soil",
		"magic",
		"dense-vegetation",
	]
	for bad_trait: String in invalid_traits:
		assert_false(
			EnvironmentalTrait.is_valid(bad_trait),
			"Invalid trait '%s' must return false" % bad_trait
		)


func _test_trait_list_validation() -> void:
	describe("is_valid_trait_list accepts empty or unique canonical lists and rejects duplicates or invalid traits")
	var empty_list: Array[String] = []
	assert_true(EnvironmentalTrait.is_valid_trait_list(empty_list), "Empty trait list must be valid")

	var single_list: Array[String] = ["flower"]
	assert_true(EnvironmentalTrait.is_valid_trait_list(single_list), "Single valid trait list must be valid")

	var multi_list: Array[String] = ["fruit", "shade", "perch", "shelter"]
	assert_true(EnvironmentalTrait.is_valid_trait_list(multi_list), "Multiple unique valid traits must be valid")

	var duplicate_list: Array[String] = ["flower", "dense_vegetation", "flower"]
	assert_false(
		EnvironmentalTrait.is_valid_trait_list(duplicate_list),
		"Duplicate trait in list must be rejected"
	)

	var invalid_entry_list: Array[String] = ["flower", "unknown_trait"]
	assert_false(
		EnvironmentalTrait.is_valid_trait_list(invalid_entry_list),
		"List containing unknown trait must be rejected"
	)
