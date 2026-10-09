## test_plant_runtime_id_generator.gd
## Deterministic unit test suite for PlantRuntimeIdGenerator.
##
## Verifies:
## A. Type contract (extends RefCounted, not Node, not Resource).
## B. Deterministic expected ID formatting.
## C. Prefix is exactly plant-inst-.
## D. Hexadecimal suffix is exactly 32 characters (total length 43).
## E. Lowercase hexadecimal only in suffix.
## F. Leading zeros retained in all 8-char segments.
## G. Exactly four RNG draws per candidate.
## H. Different scripted sequences produce different IDs.
## I. Generated candidate is not present in collection.
## J. One collision causes retry.
## K. Multiple collisions cause retries.
## L. Eight collisions return empty String.
## M. Existing PlantState references remain unchanged.
## N. Null collection returns empty String (0 RNG consumed).
## O. Null RandomSource returns empty String.
## P. No collection mutation on generation.
## Q. Existing opaque IDs are respected during collision checking.
## R. Generator does not depend on clock or filesystem.
class_name TestPlantRuntimeIdGenerator
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestPlantRuntimeIdGenerator"


func run_tests() -> void:
	_test_type_contract()
	_test_deterministic_id_formatting()
	_test_prefix_and_length()
	_test_lowercase_hex_character_set()
	_test_leading_zeros_and_boundary_values()
	_test_four_rng_draws_per_candidate()
	_test_distinct_sequences_produce_distinct_ids()
	_test_generated_candidate_not_in_collection()
	_test_single_collision_retry_success()
	_test_multiple_collisions_retry_success()
	_test_eight_collisions_exhaustion()
	_test_existing_plant_references_preserved()
	_test_null_dependencies_safety()
	_test_no_collection_mutation()
	_test_existing_opaque_ids_respected()


func _test_type_contract() -> void:
	describe("PlantRuntimeIdGenerator satisfies RefCounted type contract")
	var generator: PlantRuntimeIdGenerator = PlantRuntimeIdGenerator.new()
	assert_true(generator is RefCounted, "PlantRuntimeIdGenerator must extend RefCounted")
	var obj: Variant = generator
	assert_false(obj is Node, "PlantRuntimeIdGenerator must not be a Node")
	assert_false(obj is Resource, "PlantRuntimeIdGenerator must not be a Resource")


func _test_deterministic_id_formatting() -> void:
	describe("Deterministic expected ID formatting matches documented specification")
	var collection: PlantCollectionState = PlantCollectionState.new()
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])
	var id: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng)

	assert_eq(
		id,
		"plant-inst-00000001000000020000000300000004",
		"Generated ID must match exact documented hex format"
	)


func _test_prefix_and_length() -> void:
	describe("Prefix is exactly 'plant-inst-' and suffix is exactly 32 hex chars (43 total)")
	var collection: PlantCollectionState = PlantCollectionState.new()
	var rng: FakeRandomSource = FakeRandomSource.new([], [100, 200, 300, 400])
	var id: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng)

	assert_true(id.begins_with("plant-inst-"), "ID must begin with 'plant-inst-'")
	assert_eq(id.length(), 43, "Total ID length must be exactly 43 characters")
	var suffix: String = id.substr(11)
	assert_eq(suffix.length(), 32, "Suffix length must be exactly 32 characters")


func _test_lowercase_hex_character_set() -> void:
	describe("Suffix contains only lowercase hexadecimal characters [0-9a-f]")
	var collection: PlantCollectionState = PlantCollectionState.new()
	# 0x01234567 = 19088743, 0x89abcdef = 2309737967 (wait, max range is 2147483647 = 0x7fffffff)
	# Draw numbers that contain a, b, c, d, e, f in hex:
	# 0x0abcdef0 = 180145904, 0x12345678 = 305419896, 0x7abcdef0 = 2059198192
	var rng: FakeRandomSource = FakeRandomSource.new(
		[],
		[180145904, 305419896, 2059198192, 11259375] # 11259375 = 0x00abcdef
	)
	var id: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng)
	var suffix: String = id.substr(11)

	var valid_chars: String = "0123456789abcdef"
	var all_valid: bool = true
	for i: int in range(suffix.length()):
		var c: String = suffix[i]
		if valid_chars.find(c) == -1:
			all_valid = false
			break

	assert_true(all_valid, "Suffix must contain only lowercase hex characters [0-9a-f]")
	# Also ensure no uppercase characters exist
	assert_eq(suffix, suffix.to_lower(), "Suffix must be strictly lowercase")


func _test_leading_zeros_and_boundary_values() -> void:
	describe("Leading zeros are preserved across all segments and boundary values supported")
	var collection: PlantCollectionState = PlantCollectionState.new()
	# 0 -> "00000000"
	# 15 -> "0000000f"
	# 255 -> "000000ff"
	# 2147483647 (0x7fffffff) -> "7fffffff"
	var rng: FakeRandomSource = FakeRandomSource.new([], [0, 15, 255, 2147483647])
	var id: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng)

	assert_eq(
		id,
		"plant-inst-000000000000000f000000ff7fffffff",
		"Zeroes and max boundary value must format correctly with leading zeros preserved"
	)


func _test_four_rng_draws_per_candidate() -> void:
	describe("Candidate generation consumes exactly four integer draws and no extra draws")
	var collection: PlantCollectionState = PlantCollectionState.new()
	# Supply 5 ints. If exactly 4 are consumed, the 5th remains unconsumed.
	var rng: FakeRandomSource = FakeRandomSource.new([], [10, 20, 30, 40, 999])
	var id: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng)

	assert_eq(id, "plant-inst-0000000a000000140000001e00000028", "ID matches first 4 draws")
	# 5th draw is still available in rng
	var remaining: int = rng.range_int(0, 1000)
	assert_eq(remaining, 999, "5th draw was not consumed by candidate generator")


func _test_distinct_sequences_produce_distinct_ids() -> void:
	describe("Different scripted sequences produce distinct IDs")
	var collection: PlantCollectionState = PlantCollectionState.new()
	var rng1: FakeRandomSource = FakeRandomSource.new([], [1, 1, 1, 1])
	var rng2: FakeRandomSource = FakeRandomSource.new([], [2, 2, 2, 2])

	var id1: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng1)
	var id2: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng2)

	assert_ne(id1, id2, "Distinct RNG streams must produce distinct runtime instance IDs")


func _test_generated_candidate_not_in_collection() -> void:
	describe("Generated candidate is verified absent from the target collection")
	var collection: PlantCollectionState = PlantCollectionState.new()
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])
	var id: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng)

	assert_false(
		collection.has_runtime_instance_id(id),
		"Generated ID must not already exist in the collection"
	)


func _test_single_collision_retry_success() -> void:
	describe("One collision causes a retry and consumes eight draws, returning second candidate")
	var collection: PlantCollectionState = PlantCollectionState.new()
	# Pre-populate collection with candidate 1
	var existing_plant: PlantState = PlantState.new(
		"plant-inst-00000001000000020000000300000004",
		"plant.holy_basil",
		1000
	)
	var added: bool = collection.try_add_plant(existing_plant)
	assert_true(added, "Pre-population of plant must succeed")

	# Script 8 draws: first 4 match existing_plant, next 4 form candidate 2
	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])
	var id: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng)

	assert_eq(
		id,
		"plant-inst-00000005000000060000000700000008",
		"Generator must skip colliding candidate and return second candidate"
	)
	assert_false(collection.has_runtime_instance_id(id), "Returned candidate is not in collection")


func _test_multiple_collisions_retry_success() -> void:
	describe("Multiple collisions cause multiple retries and return next unique candidate")
	var collection: PlantCollectionState = PlantCollectionState.new()
	# Add 3 colliding candidates to collection
	collection.try_add_plant(PlantState.new("plant-inst-00000001000000010000000100000001", "plant.banana", 100))
	collection.try_add_plant(PlantState.new("plant-inst-00000002000000020000000200000002", "plant.chili", 100))
	collection.try_add_plant(PlantState.new("plant-inst-00000003000000030000000300000003", "plant.jasmine", 100))

	# Script 16 draws (3 collisions + 1 unique)
	var rng: FakeRandomSource = FakeRandomSource.new([], [
		1, 1, 1, 1, # Collides
		2, 2, 2, 2, # Collides
		3, 3, 3, 3, # Collides
		4, 4, 4, 4, # Unique!
	])
	var id: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng)

	assert_eq(
		id,
		"plant-inst-00000004000000040000000400000004",
		"Generator must retry through 3 collisions and return 4th candidate"
	)


func _test_eight_collisions_exhaustion() -> void:
	describe("Eight collisions exhaust attempts and return empty String")
	var collection: PlantCollectionState = PlantCollectionState.new()
	# Pre-populate 8 plants
	for i: int in range(1, 9):
		var existing_id: String = "%s%08x%08x%08x%08x" % [PlantRuntimeIdGenerator.ID_PREFIX, i, i, i, i]
		collection.try_add_plant(PlantState.new(existing_id, "plant.marigold", 500))

	# Script 32 draws matching all 8 candidates
	var draws: Array[int] = []
	for i: int in range(1, 9):
		draws.append_array([i, i, i, i])

	var rng: FakeRandomSource = FakeRandomSource.new([], draws)
	var id: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng)

	assert_eq(id, "", "Generator must return empty String after 8 collisions")
	assert_eq(collection.get_count(), 8, "Collection count remains 8")


func _test_existing_plant_references_preserved() -> void:
	describe("Existing PlantState references remain unchanged during candidate generation")
	var collection: PlantCollectionState = PlantCollectionState.new()
	var plant: PlantState = PlantState.new("plant-inst-00000001000000020000000300000004", "plant.holy_basil", 1000)
	collection.try_add_plant(plant)

	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4, 5, 6, 7, 8])
	var _id: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng)

	var stored: PlantState = collection.get_plant("plant-inst-00000001000000020000000300000004")
	assert_eq(stored, plant, "Stored plant reference must remain identical")
	assert_eq(stored.get_planted_at(), 1000, "Stored planted_at remains unchanged")
	assert_eq(stored.get_definition_id(), "plant.holy_basil", "Stored definition_id remains unchanged")


func _test_null_dependencies_safety() -> void:
	describe("Null dependencies return empty String without consuming RNG")
	var collection: PlantCollectionState = PlantCollectionState.new()
	var empty_rng: FakeRandomSource = FakeRandomSource.new([], [])

	# Null collection with non-null empty RNG
	var res1: String = PlantRuntimeIdGenerator.try_generate_unique_id(null, empty_rng)
	assert_eq(res1, "", "Null collection must return empty String")

	# Valid collection with null RNG
	var res2: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, null)
	assert_eq(res2, "", "Null RandomSource must return empty String")

	# Both null
	var res3: String = PlantRuntimeIdGenerator.try_generate_unique_id(null, null)
	assert_eq(res3, "", "Both null must return empty String")


func _test_no_collection_mutation() -> void:
	describe("Generation does not mutate collection or insert the candidate ID")
	var collection: PlantCollectionState = PlantCollectionState.new()
	assert_eq(collection.get_count(), 0, "Initial collection count is 0")

	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])
	var id: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng)

	assert_ne(id, "", "Generated ID is non-empty")
	assert_eq(collection.get_count(), 0, "Collection count must remain 0 after generation")
	assert_false(collection.has_runtime_instance_id(id), "Generated candidate is not inserted")


func _test_existing_opaque_ids_respected() -> void:
	describe("Existing opaque IDs (non-hex or legacy) are respected during collision checks")
	var collection: PlantCollectionState = PlantCollectionState.new()
	var legacy_plant: PlantState = PlantState.new("legacy-plant-xyz-001", "plant.banana", 500)
	collection.try_add_plant(legacy_plant)

	var rng: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])
	var id: String = PlantRuntimeIdGenerator.try_generate_unique_id(collection, rng)

	assert_eq(id, "plant-inst-00000001000000020000000300000004", "Candidate generation succeeds")
	assert_eq(collection.get_count(), 1, "Collection count remains 1")
	assert_true(collection.has_runtime_instance_id("legacy-plant-xyz-001"), "Legacy ID preserved")
