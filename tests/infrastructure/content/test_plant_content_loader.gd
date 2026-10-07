## test_plant_content_loader.gd
## Integration and unit tests for PlantContentLoader and PlantContentLoadResult.
##
## Exercises real Godot ResourceLoader interactions against the five authored MVP plant
## resources and verifies failure handling, catalog integration, and growth rules.
class_name TestPlantContentLoader
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestPlantContentLoader"


func run_tests() -> void:
	_test_type_contracts()
	_test_production_resources_exist()
	_test_production_load_success_and_types()
	_test_production_stable_ids()
	_test_production_is_valid()
	_test_production_growth_thresholds()
	_test_production_unique_ids()
	_test_production_content_catalog_integration()
	_test_production_plant_growth_integration()
	_test_production_exact_stage_boundary_transitions()
	_test_immutability_and_repeated_loads()
	_test_path_order_preservation()
	_test_defensive_encapsulation()
	_test_failure_missing_path()
	_test_failure_empty_path()
	_test_failure_duplicate_path()
	_test_failure_non_res_path()
	_test_failure_wrong_resource_type()
	_test_failure_mixed_valid_and_invalid()


func _test_type_contracts() -> void:
	describe("PlantContentLoader and PlantContentLoadResult satisfy RefCounted contracts")
	var loader: PlantContentLoader = PlantContentLoader.new()
	assert_true(loader != null, "Loader instance should not be null")
	assert_true(loader is PlantContentLoader, "Loader must satisfy 'is PlantContentLoader'")
	assert_true(loader is RefCounted, "Loader must extend RefCounted")
	var loader_obj: Variant = loader
	assert_false(loader_obj is Node, "Loader must not be a Node")
	assert_false(loader_obj is Resource, "Loader must not be a Resource")

	var result: PlantContentLoadResult = loader.load_production_definitions()
	assert_true(result != null, "LoadResult instance should not be null")
	assert_true(result is PlantContentLoadResult, "Result must satisfy 'is PlantContentLoadResult'")
	assert_true(result is RefCounted, "Result must extend RefCounted")
	var result_obj: Variant = result
	assert_false(result_obj is Node, "Result must not be a Node")
	assert_false(result_obj is Resource, "Result must not be a Resource")


func _test_production_resources_exist() -> void:
	describe("Test A: All five production resources exist on filesystem")
	var expected_paths: Array[String] = [
		"res://content/plants/banana.tres",
		"res://content/plants/chili.tres",
		"res://content/plants/holy_basil.tres",
		"res://content/plants/jasmine.tres",
		"res://content/plants/marigold.tres",
	]
	assert_eq(PlantContentLoader.PRODUCTION_PLANT_PATHS, expected_paths, "Manifest paths must match expected list")

	for path: String in expected_paths:
		assert_true(ResourceLoader.exists(path), "Production resource must exist: %s" % path)


func _test_production_load_success_and_types() -> void:
	describe("Test B: All five load successfully as PlantDefinition instances")
	var loader: PlantContentLoader = PlantContentLoader.new()
	var result: PlantContentLoadResult = loader.load_production_definitions()

	assert_true(result.is_loaded(), "Production load must succeed")
	assert_eq(result.get_status(), PlantContentLoadResult.Status.LOADED, "Status must be LOADED")
	assert_eq(result.get_failed_path(), "", "Failed path must be empty on success")
	assert_eq(result.get_error_message(), "", "Error message must be empty on success")

	var defs: Array[PlantDefinition] = result.get_definitions()
	assert_eq(defs.size(), 5, "Must load exactly five definitions")

	for def: PlantDefinition in defs:
		assert_true(def != null, "Definition instance must not be null")
		assert_true(def is PlantDefinition, "Each entry must satisfy 'is PlantDefinition'")
		assert_true(def is Resource, "PlantDefinition must be a Resource")


func _test_production_stable_ids() -> void:
	describe("Test C: All five have exact expected stable content IDs")
	var loader: PlantContentLoader = PlantContentLoader.new()
	var result: PlantContentLoadResult = loader.load_production_definitions()
	var defs: Array[PlantDefinition] = result.get_definitions()

	var actual_ids: Array[String] = []
	for def: PlantDefinition in defs:
		actual_ids.append(def.id)

	var expected_ids: Array[String] = [
		"plant.banana",
		"plant.chili",
		"plant.holy_basil",
		"plant.jasmine",
		"plant.marigold",
	]
	assert_eq(actual_ids, expected_ids, "Loaded definition IDs must match manifest order exactly")


func _test_production_is_valid() -> void:
	describe("Test D: All five pass PlantDefinition.is_valid()")
	var loader: PlantContentLoader = PlantContentLoader.new()
	var result: PlantContentLoadResult = loader.load_production_definitions()
	var defs: Array[PlantDefinition] = result.get_definitions()

	for def: PlantDefinition in defs:
		assert_true(def.is_valid(), "Plant definition '%s' must be valid" % def.id)


func _test_production_growth_thresholds() -> void:
	describe("Test E: Every resource has the specified provisional growth thresholds")
	var loader: PlantContentLoader = PlantContentLoader.new()
	var result: PlantContentLoadResult = loader.load_production_definitions()
	var defs: Array[PlantDefinition] = result.get_definitions()

	var expected_thresholds: Dictionary = {
		"plant.holy_basil": {"sprout": 60, "growing": 180, "mature": 600},
		"plant.chili": {"sprout": 120, "growing": 480, "mature": 1200},
		"plant.jasmine": {"sprout": 300, "growing": 1200, "mature": 3600},
		"plant.marigold": {"sprout": 180, "growing": 900, "mature": 2700},
		"plant.banana": {"sprout": 1800, "growing": 5400, "mature": 21600},
	}

	for def: PlantDefinition in defs:
		assert_true(expected_thresholds.has(def.id), "Expected thresholds must define plant: %s" % def.id)
		var expected: Dictionary = expected_thresholds[def.id]
		assert_eq(def.sprout_after_seconds, expected["sprout"], "%s sprout threshold must match" % def.id)
		assert_eq(def.growing_after_seconds, expected["growing"], "%s growing threshold must match" % def.id)
		assert_eq(def.mature_after_seconds, expected["mature"], "%s mature threshold must match" % def.id)

		assert_true(def.sprout_after_seconds > 0, "%s sprout threshold must be > 0" % def.id)
		assert_true(def.growing_after_seconds > def.sprout_after_seconds, "%s growing must be > sprout" % def.id)
		assert_true(def.mature_after_seconds > def.growing_after_seconds, "%s mature must be > growing" % def.id)


func _test_production_unique_ids() -> void:
	describe("Test F: No duplicate definition ID exists among the five resources")
	var loader: PlantContentLoader = PlantContentLoader.new()
	var result: PlantContentLoadResult = loader.load_production_definitions()
	var defs: Array[PlantDefinition] = result.get_definitions()

	var seen_ids: Dictionary = {}
	for def: PlantDefinition in defs:
		assert_false(seen_ids.has(def.id), "Duplicate definition ID encountered: %s" % def.id)
		seen_ids[def.id] = true
	assert_eq(seen_ids.size(), 5, "Total unique ID count must be exactly 5")


func _test_production_content_catalog_integration() -> void:
	describe("Tests G, H, I, J: ContentCatalog successfully integrates with loaded production definitions")
	var loader: PlantContentLoader = PlantContentLoader.new()
	var result: PlantContentLoadResult = loader.load_production_definitions()
	var defs: Array[PlantDefinition] = result.get_definitions()

	# G. try_create succeeds
	var catalog: ContentCatalog = ContentCatalog.try_create(defs)
	assert_true(catalog != null, "ContentCatalog.try_create must succeed with loaded production definitions")

	# H. catalog count is exactly 5
	assert_eq(catalog.get_plant_count(), 5, "Catalog count must be exactly 5")

	# I. deterministic ascending order
	var expected_sorted_ids: Array[String] = [
		"plant.banana",
		"plant.chili",
		"plant.holy_basil",
		"plant.jasmine",
		"plant.marigold",
	]
	assert_eq(catalog.get_all_plant_ids(), expected_sorted_ids, "Catalog plant IDs must enumerate in ascending order")

	# J. Each lookup returns corresponding loaded reference
	for def: PlantDefinition in defs:
		assert_true(catalog.has_plant(def.id), "Catalog must contain %s" % def.id)
		var retrieved: PlantDefinition = catalog.get_plant(def.id)
		assert_true(retrieved == def, "get_plant(%s) must return exact loaded Resource reference" % def.id)


func _test_production_plant_growth_integration() -> void:
	describe("Test K: PlantGrowth.stage_for_state_at can use loaded definitions")
	var loader: PlantContentLoader = PlantContentLoader.new()
	var result: PlantContentLoadResult = loader.load_production_definitions()
	var defs: Array[PlantDefinition] = result.get_definitions()

	for def: PlantDefinition in defs:
		var state: PlantState = PlantState.new("test-inst-%s" % def.id, def.id, 1000)
		assert_true(state.is_valid(), "PlantState must be valid for %s" % def.id)

		var stage: PlantGrowth.Stage = PlantGrowth.stage_for_state_at(state, def, 1000)
		assert_eq(stage, PlantGrowth.Stage.PLANTED, "At planted time, stage must be PLANTED for %s" % def.id)


func _test_production_exact_stage_boundary_transitions() -> void:
	describe("Test L: Exact growth-stage boundary transitions match each loaded definition's thresholds")
	var loader: PlantContentLoader = PlantContentLoader.new()
	var result: PlantContentLoadResult = loader.load_production_definitions()
	var defs: Array[PlantDefinition] = result.get_definitions()

	for def: PlantDefinition in defs:
		var s: int = def.sprout_after_seconds
		var g: int = def.growing_after_seconds
		var m: int = def.mature_after_seconds

		# PLANTED
		assert_eq(PlantGrowth.stage_for_elapsed_seconds(def, 0), PlantGrowth.Stage.PLANTED, "%s at 0 must be PLANTED" % def.id)
		assert_eq(PlantGrowth.stage_for_elapsed_seconds(def, s - 1), PlantGrowth.Stage.PLANTED, "%s at sprout-1 must be PLANTED" % def.id)

		# SPROUT
		assert_eq(PlantGrowth.stage_for_elapsed_seconds(def, s), PlantGrowth.Stage.SPROUT, "%s at sprout must be SPROUT" % def.id)
		assert_eq(PlantGrowth.stage_for_elapsed_seconds(def, g - 1), PlantGrowth.Stage.SPROUT, "%s at growing-1 must be SPROUT" % def.id)

		# GROWING
		assert_eq(PlantGrowth.stage_for_elapsed_seconds(def, g), PlantGrowth.Stage.GROWING, "%s at growing must be GROWING" % def.id)
		assert_eq(PlantGrowth.stage_for_elapsed_seconds(def, m - 1), PlantGrowth.Stage.GROWING, "%s at mature-1 must be GROWING" % def.id)

		# MATURE
		assert_eq(PlantGrowth.stage_for_elapsed_seconds(def, m), PlantGrowth.Stage.MATURE, "%s at mature must be MATURE" % def.id)
		assert_eq(PlantGrowth.stage_for_elapsed_seconds(def, m + 100), PlantGrowth.Stage.MATURE, "%s after mature must be MATURE" % def.id)


func _test_immutability_and_repeated_loads() -> void:
	describe("Tests M & N: Loader does not mutate fields; repeated loads return equivalent data")
	var loader: PlantContentLoader = PlantContentLoader.new()

	var result1: PlantContentLoadResult = loader.load_production_definitions()
	var defs1: Array[PlantDefinition] = result1.get_definitions()

	# Verify field preservation
	assert_eq(defs1[0].id, "plant.banana", "banana ID unmutated")
	assert_eq(defs1[0].sprout_after_seconds, 1800, "banana sprout unmutated")
	assert_eq(defs1[0].growing_after_seconds, 5400, "banana growing unmutated")
	assert_eq(defs1[0].mature_after_seconds, 21600, "banana mature unmutated")

	var result2: PlantContentLoadResult = loader.load_production_definitions()
	var defs2: Array[PlantDefinition] = result2.get_definitions()

	assert_eq(defs1.size(), defs2.size(), "Both loads must produce 5 definitions")
	for i in range(defs1.size()):
		assert_eq(defs1[i].id, defs2[i].id, "Definition %d ID must match across loads" % i)
		assert_eq(defs1[i].sprout_after_seconds, defs2[i].sprout_after_seconds, "Definition %d sprout must match across loads" % i)
		assert_eq(defs1[i].growing_after_seconds, defs2[i].growing_after_seconds, "Definition %d growing must match across loads" % i)
		assert_eq(defs1[i].mature_after_seconds, defs2[i].mature_after_seconds, "Definition %d mature must match across loads" % i)


func _test_path_order_preservation() -> void:
	describe("load_from_paths preserves caller's path order")
	var loader: PlantContentLoader = PlantContentLoader.new()

	var custom_order: Array[String] = [
		"res://content/plants/marigold.tres",
		"res://content/plants/holy_basil.tres",
		"res://content/plants/chili.tres",
	]
	var result: PlantContentLoadResult = loader.load_from_paths(custom_order)
	assert_true(result.is_loaded(), "Custom order load must succeed")
	var defs: Array[PlantDefinition] = result.get_definitions()
	assert_eq(defs.size(), 3, "Must return 3 definitions")
	assert_eq(defs[0].id, "plant.marigold", "First must be marigold")
	assert_eq(defs[1].id, "plant.holy_basil", "Second must be holy_basil")
	assert_eq(defs[2].id, "plant.chili", "Third must be chili")


func _test_defensive_encapsulation() -> void:
	describe("Defensive encapsulation: input arrays and returned arrays cannot corrupt loader or result")
	var loader: PlantContentLoader = PlantContentLoader.new()

	var input_paths: Array[String] = [
		"res://content/plants/chili.tres",
		"res://content/plants/jasmine.tres",
	]
	var result: PlantContentLoadResult = loader.load_from_paths(input_paths)
	assert_true(result.is_loaded(), "Initial load must succeed")

	# Mutate input array
	input_paths.clear()
	assert_eq(result.get_definitions().size(), 2, "Result definitions must not be affected by caller clearing input array")

	# Mutate returned definitions array
	var returned_defs: Array[PlantDefinition] = result.get_definitions()
	returned_defs.clear()
	assert_eq(result.get_definitions().size(), 2, "Result definitions must not be affected by caller clearing returned array")


func _test_failure_missing_path() -> void:
	describe("Failure: missing resource path is rejected")
	var loader: PlantContentLoader = PlantContentLoader.new()
	var missing_path: String = "res://content/plants/nonexistent_plant.tres"
	var result: PlantContentLoadResult = loader.load_from_paths([missing_path])

	assert_false(result.is_loaded(), "Missing path load must fail")
	assert_eq(result.get_status(), PlantContentLoadResult.Status.LOAD_FAILED, "Status must be LOAD_FAILED")
	assert_eq(result.get_definitions().size(), 0, "Definitions must be empty on failure")
	assert_eq(result.get_failed_path(), missing_path, "Failed path must report missing path")
	assert_true(result.get_error_message().length() > 0, "Error message must be present")


func _test_failure_empty_path() -> void:
	describe("Failure: empty resource path is rejected")
	var loader: PlantContentLoader = PlantContentLoader.new()
	var result: PlantContentLoadResult = loader.load_from_paths([""])

	assert_false(result.is_loaded(), "Empty path load must fail")
	assert_eq(result.get_status(), PlantContentLoadResult.Status.LOAD_FAILED, "Status must be LOAD_FAILED")
	assert_eq(result.get_definitions().size(), 0, "Definitions must be empty on failure")
	assert_true(result.get_error_message().length() > 0, "Error message must be present")


func _test_failure_duplicate_path() -> void:
	describe("Failure: duplicate resource path is rejected")
	var loader: PlantContentLoader = PlantContentLoader.new()
	var dup_path: String = "res://content/plants/chili.tres"
	var result: PlantContentLoadResult = loader.load_from_paths([dup_path, dup_path])

	assert_false(result.is_loaded(), "Duplicate path load must fail")
	assert_eq(result.get_status(), PlantContentLoadResult.Status.LOAD_FAILED, "Status must be LOAD_FAILED")
	assert_eq(result.get_definitions().size(), 0, "Definitions must be empty on failure")
	assert_eq(result.get_failed_path(), dup_path, "Failed path must report duplicate path")
	assert_true(result.get_error_message().length() > 0, "Error message must be present")


func _test_failure_non_res_path() -> void:
	describe("Failure: non-res:// resource path is rejected")
	var loader: PlantContentLoader = PlantContentLoader.new()
	var non_res_paths: Array[String] = [
		"content/plants/chili.tres",
		"/Applications/garden/content/plants/chili.tres",
		"user://content/plants/chili.tres",
	]
	for path: String in non_res_paths:
		var result: PlantContentLoadResult = loader.load_from_paths([path])
		assert_false(result.is_loaded(), "Non-res path '%s' load must fail" % path)
		assert_eq(result.get_status(), PlantContentLoadResult.Status.LOAD_FAILED, "Status must be LOAD_FAILED")
		assert_eq(result.get_definitions().size(), 0, "Definitions must be empty on failure")
		assert_eq(result.get_failed_path(), path, "Failed path must report offending path")


func _test_failure_wrong_resource_type() -> void:
	describe("Failure: resource of wrong type is rejected")
	var loader: PlantContentLoader = PlantContentLoader.new()
	# res://scenes/app/main.tscn is a PackedScene (Resource), not a PlantDefinition
	var wrong_type_path: String = "res://scenes/app/main.tscn"
	assert_true(ResourceLoader.exists(wrong_type_path), "main.tscn must exist")

	var result: PlantContentLoadResult = loader.load_from_paths([wrong_type_path])
	assert_false(result.is_loaded(), "Wrong resource type load must fail")
	assert_eq(result.get_status(), PlantContentLoadResult.Status.LOAD_FAILED, "Status must be LOAD_FAILED")
	assert_eq(result.get_definitions().size(), 0, "Definitions must be empty on failure")
	assert_eq(result.get_failed_path(), wrong_type_path, "Failed path must report wrong type path")
	assert_true(result.get_error_message().length() > 0, "Error message must be present")


func _test_failure_mixed_valid_and_invalid() -> void:
	describe("Failure: mixed valid and invalid paths enforce all-or-nothing guarantee")
	var loader: PlantContentLoader = PlantContentLoader.new()
	var valid_path: String = "res://content/plants/chili.tres"
	var invalid_path: String = "res://content/plants/nonexistent.tres"

	# Invalid as second entry
	var result1: PlantContentLoadResult = loader.load_from_paths([valid_path, invalid_path])
	assert_false(result1.is_loaded(), "Mixed load [valid, invalid] must fail")
	assert_eq(result1.get_status(), PlantContentLoadResult.Status.LOAD_FAILED, "Status must be LOAD_FAILED")
	assert_eq(result1.get_definitions().size(), 0, "Must not expose partial successfully loaded content")
	assert_eq(result1.get_failed_path(), invalid_path, "Failed path must report invalid path")

	# Invalid as first entry
	var result2: PlantContentLoadResult = loader.load_from_paths([invalid_path, valid_path])
	assert_false(result2.is_loaded(), "Mixed load [invalid, valid] must fail")
	assert_eq(result2.get_status(), PlantContentLoadResult.Status.LOAD_FAILED, "Status must be LOAD_FAILED")
	assert_eq(result2.get_definitions().size(), 0, "Must not expose partial content")
	assert_eq(result2.get_failed_path(), invalid_path, "Failed path must report invalid path")
