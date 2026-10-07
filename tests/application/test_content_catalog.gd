## test_content_catalog.gd
## Unit tests for Garden's ContentCatalog application service.
##
## Verifies:
## 1. Type contract: RefCounted, not Node, not Resource.
## 2. Empty catalog creation: empty array returns a valid empty catalog with count == 0.
## 3. Single and multiple valid PlantDefinition construction.
## 4. Query API correctness: has_plant, get_plant, get_plant_count.
## 5. Unknown ID lookups: has_plant is false, get_plant returns null without error.
## 6. Exact Resource reference preservation (no deep cloning).
## 7. Deterministic ascending enumeration order for get_all_plants and get_all_plant_ids regardless of input order.
## 8. Defensive encapsulation: input array mutation after construction does not alter catalog.
## 9. Defensive encapsulation: returned array mutations do not alter catalog.
## 10. Query idempotence across repeated calls.
## 11. All-or-nothing failure rejection: null entry, default invalid definition, empty ID, malformed ID,
##     non-plant namespace, invalid growth thresholds, adjacent duplicates, separated duplicates.
class_name TestContentCatalog
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestContentCatalog"


func run_tests() -> void:
	_test_type_contract()
	_test_empty_catalog()
	_test_single_and_multiple_valid_definitions()
	_test_query_api_and_unknown_lookups()
	_test_exact_resource_reference_preservation()
	_test_deterministic_enumeration_order()
	_test_input_array_defensive_encapsulation()
	_test_returned_array_defensive_encapsulation()
	_test_query_idempotence()
	_test_failure_rejection_null_and_invalid()
	_test_failure_rejection_duplicate_ids()


func _create_valid_definition(
	id: String = "plant.holy_basil",
	sprout: int = 60,
	growing: int = 300,
	mature: int = 900
) -> PlantDefinition:
	var def: PlantDefinition = PlantDefinition.new()
	def.id = id
	def.sprout_after_seconds = sprout
	def.growing_after_seconds = growing
	def.mature_after_seconds = mature
	return def


func _test_type_contract() -> void:
	describe("ContentCatalog satisfies RefCounted type contract and is neither Node nor Resource")
	var catalog: ContentCatalog = ContentCatalog.try_create([])
	assert_true(catalog != null, "Empty catalog instance should not be null")
	assert_true(catalog is ContentCatalog, "Instance must satisfy 'is ContentCatalog'")
	assert_true(catalog is RefCounted, "ContentCatalog must extend RefCounted")
	var obj: Variant = catalog
	assert_false(obj is Node, "ContentCatalog must not be a Node")
	assert_false(obj is Resource, "ContentCatalog must not be a Resource")

	var other: ContentCatalog = ContentCatalog.try_create([])
	assert_true(other != null, "Second empty catalog instance should not be null")
	assert_ne(catalog, other, "Separate constructions must yield distinct instances")


func _test_empty_catalog() -> void:
	describe("Empty plant-definition array creates a valid empty ContentCatalog")
	var empty_defs: Array[PlantDefinition] = []
	var catalog: ContentCatalog = ContentCatalog.try_create(empty_defs)

	assert_true(catalog != null, "try_create([]) must return a non-null ContentCatalog")
	assert_eq(catalog.get_plant_count(), 0, "Empty catalog count must be 0")
	assert_false(catalog.has_plant("plant.holy_basil"), "Empty catalog has_plant must be false")
	assert_true(catalog.get_plant("plant.holy_basil") == null, "Empty catalog get_plant must be null")

	var all_plants: Array[PlantDefinition] = catalog.get_all_plants()
	assert_eq(all_plants.size(), 0, "Empty catalog get_all_plants must return an empty array")

	var all_ids: Array[String] = catalog.get_all_plant_ids()
	assert_eq(all_ids.size(), 0, "Empty catalog get_all_plant_ids must return an empty array")


func _test_single_and_multiple_valid_definitions() -> void:
	describe("Single and multiple valid PlantDefinitions build successfully")
	var def1: PlantDefinition = _create_valid_definition("plant.holy_basil", 60, 300, 900)
	var catalog_single: ContentCatalog = ContentCatalog.try_create([def1])
	assert_true(catalog_single != null, "Catalog with 1 valid definition must build successfully")
	assert_eq(catalog_single.get_plant_count(), 1, "Catalog count must be 1")
	assert_true(catalog_single.has_plant("plant.holy_basil"), "Catalog must contain plant.holy_basil")

	var def2: PlantDefinition = _create_valid_definition("plant.chili", 30, 120, 400)
	var def3: PlantDefinition = _create_valid_definition("plant.marigold", 50, 150, 450)
	var catalog_multi: ContentCatalog = ContentCatalog.try_create([def1, def2, def3])
	assert_true(catalog_multi != null, "Catalog with 3 valid definitions must build successfully")
	assert_eq(catalog_multi.get_plant_count(), 3, "Catalog count must be 3")
	assert_true(catalog_multi.has_plant("plant.holy_basil"), "Catalog must contain plant.holy_basil")
	assert_true(catalog_multi.has_plant("plant.chili"), "Catalog must contain plant.chili")
	assert_true(catalog_multi.has_plant("plant.marigold"), "Catalog must contain plant.marigold")


func _test_query_api_and_unknown_lookups() -> void:
	describe("Query API returns exact facts; unknown ID lookups return false/null without errors")
	var def_basil: PlantDefinition = _create_valid_definition("plant.holy_basil")
	var catalog: ContentCatalog = ContentCatalog.try_create([def_basil])

	assert_true(catalog.has_plant("plant.holy_basil"), "has_plant must return true for existing ID")
	assert_false(catalog.has_plant("plant.unknown"), "has_plant must return false for unknown ID")
	assert_false(catalog.has_plant(""), "has_plant must return false for empty ID")
	assert_false(catalog.has_plant("plant.holy_basil "), "has_plant must return false for trailing space")
	assert_false(catalog.has_plant(" plant.holy_basil"), "has_plant must return false for leading space")
	assert_false(catalog.has_plant("Plant.holy_basil"), "has_plant must return false for uppercase ID")

	assert_true(catalog.get_plant("plant.unknown") == null, "get_plant must return null for unknown ID")
	assert_true(catalog.get_plant("") == null, "get_plant must return null for empty ID")
	assert_true(catalog.get_plant("plant.holy_basil ") == null, "get_plant must return null for trailing space")
	assert_true(catalog.get_plant("Plant.holy_basil") == null, "get_plant must return null for uppercase ID")


func _test_exact_resource_reference_preservation() -> void:
	describe("Exact PlantDefinition Resource references are retained without deep cloning")
	var def_a: PlantDefinition = _create_valid_definition("plant.holy_basil", 60, 300, 900)
	var def_b: PlantDefinition = _create_valid_definition("plant.chili", 30, 120, 400)

	var catalog: ContentCatalog = ContentCatalog.try_create([def_a, def_b])
	assert_true(catalog != null, "Catalog build must succeed")

	var retrieved_a: PlantDefinition = catalog.get_plant("plant.holy_basil")
	var retrieved_b: PlantDefinition = catalog.get_plant("plant.chili")

	assert_true(retrieved_a == def_a, "retrieved_a must be the exact same object reference as def_a")
	assert_true(retrieved_b == def_b, "retrieved_b must be the exact same object reference as def_b")


func _test_deterministic_enumeration_order() -> void:
	describe("get_all_plants and get_all_plant_ids return deterministic ascending ID order regardless of input order")
	var def_marigold: PlantDefinition = _create_valid_definition("plant.marigold", 50, 150, 450)
	var def_basil: PlantDefinition = _create_valid_definition("plant.holy_basil", 60, 300, 900)
	var def_chili: PlantDefinition = _create_valid_definition("plant.chili", 30, 120, 400)
	var def_banana: PlantDefinition = _create_valid_definition("plant.banana", 500, 1000, 2000)

	# Insertion order: marigold, basil, chili, banana
	var catalog: ContentCatalog = ContentCatalog.try_create([def_marigold, def_basil, def_chili, def_banana])
	assert_true(catalog != null, "Catalog build must succeed")

	var ids: Array[String] = catalog.get_all_plant_ids()
	assert_eq(ids.size(), 4, "ID count must be 4")
	assert_eq(ids[0], "plant.banana", "First ID must be plant.banana")
	assert_eq(ids[1], "plant.chili", "Second ID must be plant.chili")
	assert_eq(ids[2], "plant.holy_basil", "Third ID must be plant.holy_basil")
	assert_eq(ids[3], "plant.marigold", "Fourth ID must be plant.marigold")

	var plants: Array[PlantDefinition] = catalog.get_all_plants()
	assert_eq(plants.size(), 4, "Plant count must be 4")
	assert_true(plants[0] == def_banana, "First plant must be def_banana")
	assert_true(plants[1] == def_chili, "Second plant must be def_chili")
	assert_true(plants[2] == def_basil, "Third plant must be def_basil")
	assert_true(plants[3] == def_marigold, "Fourth plant must be def_marigold")

	# Reverse insertion order: banana, chili, basil, marigold
	var catalog_rev: ContentCatalog = ContentCatalog.try_create([def_banana, def_chili, def_basil, def_marigold])
	var rev_ids: Array[String] = catalog_rev.get_all_plant_ids()
	assert_eq(rev_ids, ids, "Reverse insertion must produce identical sorted ID array")


func _test_input_array_defensive_encapsulation() -> void:
	describe("Mutating caller's input array after construction does not change catalog membership")
	var def_a: PlantDefinition = _create_valid_definition("plant.holy_basil")
	var def_b: PlantDefinition = _create_valid_definition("plant.chili")
	var def_c: PlantDefinition = _create_valid_definition("plant.jasmine")

	var input_array: Array[PlantDefinition] = [def_a, def_b]
	var catalog: ContentCatalog = ContentCatalog.try_create(input_array)
	assert_true(catalog != null, "Catalog build must succeed")
	assert_eq(catalog.get_plant_count(), 2, "Initial count must be 2")

	# Caller mutates input array
	input_array.clear()
	input_array.append(def_c)

	assert_eq(catalog.get_plant_count(), 2, "Catalog count must remain 2 after caller clears input array")
	assert_true(catalog.has_plant("plant.holy_basil"), "Catalog must still contain plant.holy_basil")
	assert_true(catalog.has_plant("plant.chili"), "Catalog must still contain plant.chili")
	assert_false(catalog.has_plant("plant.jasmine"), "Catalog must not contain newly appended plant.jasmine")


func _test_returned_array_defensive_encapsulation() -> void:
	describe("Mutating arrays returned by get_all_plants and get_all_plant_ids does not change catalog")
	var def_a: PlantDefinition = _create_valid_definition("plant.holy_basil")
	var def_b: PlantDefinition = _create_valid_definition("plant.chili")

	var catalog: ContentCatalog = ContentCatalog.try_create([def_a, def_b])
	assert_true(catalog != null, "Catalog build must succeed")

	# Mutate returned plant array
	var plants: Array[PlantDefinition] = catalog.get_all_plants()
	assert_eq(plants.size(), 2, "Initial returned plant array size must be 2")
	plants.clear()

	assert_eq(catalog.get_plant_count(), 2, "Catalog count must remain 2 after caller clears returned plants array")
	assert_eq(catalog.get_all_plants().size(), 2, "Subsequent get_all_plants call must still return 2 plants")

	# Mutate returned ID array
	var ids: Array[String] = catalog.get_all_plant_ids()
	assert_eq(ids.size(), 2, "Initial returned ID array size must be 2")
	ids.clear()

	assert_eq(catalog.get_plant_count(), 2, "Catalog count must remain 2 after caller clears returned ids array")
	assert_eq(catalog.get_all_plant_ids().size(), 2, "Subsequent get_all_plant_ids call must still return 2 ids")


func _test_query_idempotence() -> void:
	describe("Query methods are side-effect free and idempotent across repeated calls")
	var def_a: PlantDefinition = _create_valid_definition("plant.holy_basil")
	var def_b: PlantDefinition = _create_valid_definition("plant.chili")
	var catalog: ContentCatalog = ContentCatalog.try_create([def_a, def_b])

	for i: int in range(5):
		assert_eq(catalog.get_plant_count(), 2, "Repeated get_plant_count() call %d must be 2" % i)
		assert_true(catalog.has_plant("plant.holy_basil"), "Repeated has_plant() call %d must be true" % i)
		assert_false(catalog.has_plant("plant.unknown"), "Repeated has_plant() for missing ID call %d must be false" % i)
		assert_true(catalog.get_plant("plant.holy_basil") == def_a, "Repeated get_plant() call %d must return def_a" % i)
		assert_true(catalog.get_plant("plant.unknown") == null, "Repeated get_plant() for missing ID call %d must return null" % i)
		assert_eq(catalog.get_all_plant_ids(), ["plant.chili", "plant.holy_basil"], "Repeated get_all_plant_ids() call %d must match" % i)


func _test_failure_rejection_null_and_invalid() -> void:
	describe("try_create rejects whole build on any null or invalid PlantDefinition")
	var valid_def: PlantDefinition = _create_valid_definition("plant.holy_basil")

	# 1. Null definition in array
	var catalog_null_only: ContentCatalog = ContentCatalog.try_create([null])
	assert_true(catalog_null_only == null, "Catalog with only null entry must return null")

	var catalog_null_mixed: ContentCatalog = ContentCatalog.try_create([valid_def, null])
	assert_true(catalog_null_mixed == null, "Catalog with mixed valid and null entry must return null")

	# 2. Fresh uninitialized default definition (invalid thresholds and empty id)
	var default_def: PlantDefinition = PlantDefinition.new()
	var catalog_default: ContentCatalog = ContentCatalog.try_create([default_def])
	assert_true(catalog_default == null, "Catalog with default uninitialized PlantDefinition must return null")

	# 3. Definition with empty ID
	var empty_id_def: PlantDefinition = _create_valid_definition("")
	var catalog_empty_id: ContentCatalog = ContentCatalog.try_create([empty_id_def])
	assert_true(catalog_empty_id == null, "Catalog with empty ID must return null")

	# 4. Definition with malformed stable ID (syntax invalid)
	var malformed_ids: Array[String] = [
		"plant",
		"plant.",
		"plant..basil",
		"Plant.holy_basil",
		"plant.holy basil",
		"plant.123",
		"res://plants/holy_basil.tres",
	]
	for malformed_id: String in malformed_ids:
		var malformed_def: PlantDefinition = _create_valid_definition(malformed_id)
		var catalog_malformed: ContentCatalog = ContentCatalog.try_create([malformed_def])
		assert_true(catalog_malformed == null, "Catalog with malformed ID '%s' must return null" % malformed_id)

	# 5. Definition with non-plant namespace
	var non_plant_ids: Array[String] = [
		"visitor.butterfly",
		"decoration.clay_jar",
		"event.cat_sleeping",
		"weather.rain",
	]
	for non_plant_id: String in non_plant_ids:
		var non_plant_def: PlantDefinition = _create_valid_definition(non_plant_id)
		var catalog_non_plant: ContentCatalog = ContentCatalog.try_create([non_plant_def])
		assert_true(catalog_non_plant == null, "Catalog with non-plant namespace ID '%s' must return null" % non_plant_id)

	# 6. Definition with invalid growth thresholds
	var invalid_threshold_triples: Array[Array] = [
		[0, 300, 900],
		[-1, 300, 900],
		[60, 60, 900],
		[60, 50, 900],
		[60, 300, 300],
		[60, 300, 250],
	]
	for triple: Array in invalid_threshold_triples:
		var bad_threshold_def: PlantDefinition = _create_valid_definition("plant.holy_basil", triple[0], triple[1], triple[2])
		var catalog_bad_thresh: ContentCatalog = ContentCatalog.try_create([bad_threshold_def])
		assert_true(
			catalog_bad_thresh == null,
			"Catalog with invalid growth thresholds (%d, %d, %d) must return null" % [triple[0], triple[1], triple[2]]
		)


func _test_failure_rejection_duplicate_ids() -> void:
	describe("try_create rejects whole build on duplicate PlantDefinition IDs")
	var def_a1: PlantDefinition = _create_valid_definition("plant.holy_basil", 60, 300, 900)
	var def_a2: PlantDefinition = _create_valid_definition("plant.holy_basil", 60, 300, 900)
	var def_b: PlantDefinition = _create_valid_definition("plant.chili", 30, 120, 400)
	var def_c: PlantDefinition = _create_valid_definition("plant.jasmine", 100, 200, 300)

	# 1. Adjacent duplicates
	var catalog_adjacent_dup: ContentCatalog = ContentCatalog.try_create([def_a1, def_a2])
	assert_true(catalog_adjacent_dup == null, "Catalog with adjacent duplicate IDs must return null")

	# 2. Duplicate of exact same object reference twice
	var catalog_same_ref_dup: ContentCatalog = ContentCatalog.try_create([def_a1, def_a1])
	assert_true(catalog_same_ref_dup == null, "Catalog with same object reference twice must return null")

	# 3. Duplicate IDs separated by other definitions
	var catalog_separated_dup: ContentCatalog = ContentCatalog.try_create([def_a1, def_b, def_c, def_a2])
	assert_true(catalog_separated_dup == null, "Catalog with separated duplicate IDs must return null")
