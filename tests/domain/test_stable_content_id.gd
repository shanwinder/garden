## test_stable_content_id.gd
## Unit tests for Garden's StableContentId domain validation primitive.
##
## Verifies:
## 1. StableContentId satisfies type contract: RefCounted, not Node, not Resource.
## 2. Canonical valid IDs return true across all architecture examples.
## 3. Invalid IDs return false (empty, casing, malformed dots, whitespace, punctuation, etc.).
## 4. Boundary cases (shortest ID, trailing digits, underscores, segment starting rules).
## 5. Multi-segment support and non-whitelisted extensible namespaces.
## 6. Stateless, deterministic, and idempotent API purity without side effects.
class_name TestStableContentId
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestStableContentId"


func run_tests() -> void:
	_test_type_contract()
	_test_valid_canonical_ids()
	_test_invalid_ids()
	_test_boundary_cases()
	_test_extensible_namespaces()
	_test_api_purity_and_idempotence()


func _test_type_contract() -> void:
	describe("StableContentId extends RefCounted and is neither Node nor Resource")
	var instance: StableContentId = StableContentId.new()
	assert_true(instance != null, "StableContentId instance should not be null")
	assert_true(instance is StableContentId, "Instance must satisfy 'is StableContentId'")
	assert_true(instance is RefCounted, "StableContentId must extend RefCounted")
	var obj: Variant = instance
	assert_false(obj is Node, "StableContentId must not be a Node")
	assert_false(obj is Resource, "StableContentId must not be a Resource")


func _test_valid_canonical_ids() -> void:
	describe("Canonical valid stable content IDs return true")
	var valid_ids: Array[String] = [
		"plant.holy_basil",
		"plant.chili",
		"plant.jasmine",
		"visitor.butterfly",
		"visitor.frog",
		"decoration.clay_jar",
		"event.cat_sleeping",
		"progression.level_2",
		"plant.variant.holy_basil_2",
		"a.b",
		"a.b2",
		"namespace.name_with_underscores",
	]
	for id: String in valid_ids:
		assert_true(StableContentId.is_valid(id), "Valid ID '%s' must return true" % id)


func _test_invalid_ids() -> void:
	describe("Invalid content IDs return false")
	var invalid_ids: Array[String] = [
		"",
		"plant",
		".plant",
		"plant.",
		"plant..basil",
		"Plant.holy_basil",
		"plant.HolyBasil",
		"plant.holy-basil",
		"plant.holy basil",
		"plant/holy_basil",
		"res://plants/holy_basil.tres",
		"plant:holy_basil",
		"plant.123",
		"plant._holy_basil",
		"พืช.กะเพรา",
		"plant.basil!",
		"plant.basil?",
		"plant.basil#",
		"plant. basil",
		" plant.basil",
		"plant.basil\n",
		"a..b",
		"a...b",
		"a.b.",
		".a.b",
	]
	for id: String in invalid_ids:
		assert_false(StableContentId.is_valid(id), "Invalid ID '%s' must return false" % id)


func _test_boundary_cases() -> void:
	describe("Boundary cases: shortest ID, digits, underscores, and initial character constraints")
	# Shortest valid ID
	assert_true(StableContentId.is_valid("a.b"), "Shortest valid ID 'a.b' must return true")

	# Digits allowed after first character
	assert_true(StableContentId.is_valid("plant.chili2"), "'plant.chili2' must return true")

	# Underscore allowed after first character
	assert_true(StableContentId.is_valid("plant.holy_basil"), "'plant.holy_basil' must return true")

	# Underscore NOT allowed as first character of segment
	assert_false(StableContentId.is_valid("plant._basil"), "'plant._basil' must return false")

	# Digit NOT allowed as first character of segment
	assert_false(StableContentId.is_valid("plant.2basil"), "'plant.2basil' must return false")

	# Additional segments allowed
	assert_true(
		StableContentId.is_valid("plant.variant.holy_basil"),
		"'plant.variant.holy_basil' must return true"
	)


func _test_extensible_namespaces() -> void:
	describe("Non-whitelisted valid namespaces pass syntax validation without restriction")
	assert_true(StableContentId.is_valid("weather.rain"), "'weather.rain' must return true")
	assert_true(StableContentId.is_valid("audio.garden_day"), "'audio.garden_day' must return true")
	assert_true(
		StableContentId.is_valid("tutorial.first_visit"),
		"'tutorial.first_visit' must return true"
	)


func _test_api_purity_and_idempotence() -> void:
	describe("Validation is pure, stateless, and idempotent across repeated calls")
	var valid_id: String = "plant.holy_basil"
	var invalid_id: String = "plant..basil"

	for i: int in range(5):
		assert_true(
			StableContentId.is_valid(valid_id),
			"Repeated is_valid('%s') call %d must return true" % [valid_id, i]
		)
		assert_false(
			StableContentId.is_valid(invalid_id),
			"Repeated is_valid('%s') call %d must return false" % [invalid_id, i]
		)
