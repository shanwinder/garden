## test_decoration_content_loader.gd
## Integration and unit tests for DecorationContentLoader and DecorationContentLoadResult.
class_name TestDecorationContentLoader
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestDecorationContentLoader"


func run_tests() -> void:
	_test_type_contracts()
	_test_production_resources_exist()
	_test_production_load_success_and_fields()
	_test_failure_modes_all_or_nothing()


func _test_type_contracts() -> void:
	describe("DecorationContentLoader and DecorationContentLoadResult satisfy RefCounted contracts")
	var loader: DecorationContentLoader = DecorationContentLoader.new()
	assert_true(loader != null, "Loader instance must not be null")
	assert_true(loader is DecorationContentLoader, "Must be DecorationContentLoader")
	assert_true(loader is RefCounted, "Must extend RefCounted")
	var obj: Variant = loader
	assert_false(obj is Node, "Must not be a Node")
	assert_false(obj is Resource, "Must not be a Resource")

	var result: DecorationContentLoadResult = loader.load_production_definitions()
	assert_true(result != null, "LoadResult must not be null")
	assert_true(result is DecorationContentLoadResult, "Must be DecorationContentLoadResult")
	assert_true(result is RefCounted, "Must extend RefCounted")


func _test_production_resources_exist() -> void:
	describe("All eight authored production decoration resources exist on filesystem")
	var expected_paths: Array[String] = [
		"res://content/decorations/bench.tres",
		"res://content/decorations/clay_jar.tres",
		"res://content/decorations/garden_lamp.tres",
		"res://content/decorations/plant_pot.tres",
		"res://content/decorations/small_pond.tres",
		"res://content/decorations/small_table.tres",
		"res://content/decorations/watering_can.tres",
		"res://content/decorations/wooden_fence.tres",
	]
	assert_eq(DecorationContentLoader.PRODUCTION_DECORATION_PATHS, expected_paths, "Manifest paths match")
	for path: String in expected_paths:
		assert_true(ResourceLoader.exists(path), "Resource must exist: %s" % path)


func _test_production_load_success_and_fields() -> void:
	describe("All eight production decoration resources load, pass is_valid(), and match expected prices and traits")
	var loader: DecorationContentLoader = DecorationContentLoader.new()
	var result: DecorationContentLoadResult = loader.load_production_definitions()

	assert_true(result.is_loaded(), "Production decoration load must succeed")
	assert_eq(result.get_status(), DecorationContentLoadResult.Status.LOADED, "Status LOADED")
	var defs: Array[DecorationDefinition] = result.get_definitions()
	assert_eq(defs.size(), 8, "Exactly 8 decoration definitions loaded")

	var expected_specs: Dictionary = {
		"decoration.bench": {"price": 25, "traits": ["shade", "shelter"]},
		"decoration.clay_jar": {"price": 15, "traits": ["water"]},
		"decoration.garden_lamp": {"price": 30, "traits": ["light", "perch"]},
		"decoration.plant_pot": {"price": 10, "traits": []},
		"decoration.small_pond": {"price": 50, "traits": ["shelter", "water"]},
		"decoration.small_table": {"price": 20, "traits": ["perch", "shade"]},
		"decoration.watering_can": {"price": 10, "traits": []},
		"decoration.wooden_fence": {"price": 15, "traits": ["perch", "shelter"]},
	}

	for def: DecorationDefinition in defs:
		assert_true(def.is_valid(), "Decoration definition %s must be valid" % def.id)
		assert_true(expected_specs.has(def.id), "Expected specs has %s" % def.id)
		var spec: Dictionary = expected_specs[def.id]
		assert_eq(def.price, spec["price"], "%s price matches" % def.id)
		assert_eq(def.environmental_traits, spec["traits"], "%s environmental_traits match" % def.id)


func _test_failure_modes_all_or_nothing() -> void:
	describe("DecorationContentLoader rejects empty, duplicate, non-res, missing, or wrong-type paths")
	var loader: DecorationContentLoader = DecorationContentLoader.new()

	assert_false(loader.load_from_paths([""]).is_loaded(), "Empty path rejected")
	assert_false(
		loader.load_from_paths([
			"res://content/decorations/clay_jar.tres",
			"res://content/decorations/clay_jar.tres",
		]).is_loaded(),
		"Duplicate path rejected"
	)
	assert_false(
		loader.load_from_paths(["content/decorations/clay_jar.tres"]).is_loaded(),
		"Non-res:// path rejected"
	)
	assert_false(
		loader.load_from_paths(["res://content/decorations/missing.tres"]).is_loaded(),
		"Missing path rejected"
	)
	assert_false(
		loader.load_from_paths(["res://content/plants/banana.tres"]).is_loaded(),
		"Wrong resource type (PlantDefinition instead of DecorationDefinition) rejected"
	)
	var mixed: DecorationContentLoadResult = loader.load_from_paths([
		"res://content/decorations/clay_jar.tres",
		"res://content/decorations/missing.tres",
	])
	assert_false(mixed.is_loaded(), "Mixed valid and invalid paths fail")
	assert_eq(mixed.get_definitions().size(), 0, "All-or-nothing: no partial definitions returned")
