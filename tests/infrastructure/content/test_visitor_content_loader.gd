## test_visitor_content_loader.gd
## Integration and unit tests for VisitorContentLoader and VisitorContentLoadResult.
##
## Exercises real Godot ResourceLoader interactions against the five authored MVP visitor
## resources and verifies failure handling, catalog integration, and eligibility rules.
class_name TestVisitorContentLoader
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestVisitorContentLoader"


func run_tests() -> void:
	_test_type_contracts()
	_test_production_resources_exist()
	_test_production_load_success_and_fields()
	_test_production_catalog_and_eligibility_integration()
	_test_failure_modes_all_or_nothing()


func _test_type_contracts() -> void:
	describe("VisitorContentLoader and VisitorContentLoadResult satisfy RefCounted contracts")
	var loader: VisitorContentLoader = VisitorContentLoader.new()
	assert_true(loader != null, "Loader instance should not be null")
	assert_true(loader is VisitorContentLoader, "Must be VisitorContentLoader")
	assert_true(loader is RefCounted, "Must extend RefCounted")
	var loader_obj: Variant = loader
	assert_false(loader_obj is Node, "Must not be a Node")
	assert_false(loader_obj is Resource, "Must not be a Resource")

	var result: VisitorContentLoadResult = loader.load_production_definitions()
	assert_true(result != null, "LoadResult must not be null")
	assert_true(result is VisitorContentLoadResult, "Must be VisitorContentLoadResult")
	assert_true(result is RefCounted, "Must extend RefCounted")


func _test_production_resources_exist() -> void:
	describe("All five authored production visitor resources exist on filesystem")
	var expected_paths: Array[String] = [
		"res://content/visitors/bird.tres",
		"res://content/visitors/butterfly.tres",
		"res://content/visitors/cat.tres",
		"res://content/visitors/firefly.tres",
		"res://content/visitors/frog.tres",
	]
	assert_eq(VisitorContentLoader.PRODUCTION_VISITOR_PATHS, expected_paths, "Manifest paths match")
	for path: String in expected_paths:
		assert_true(ResourceLoader.exists(path), "Resource must exist: %s" % path)


func _test_production_load_success_and_fields() -> void:
	describe("All five production visitor resources load, pass is_valid(), and match expected traits and weights")
	var loader: VisitorContentLoader = VisitorContentLoader.new()
	var result: VisitorContentLoadResult = loader.load_production_definitions()

	assert_true(result.is_loaded(), "Production visitor load must succeed")
	assert_eq(result.get_status(), VisitorContentLoadResult.Status.LOADED, "Status LOADED")
	var defs: Array[VisitorDefinition] = result.get_definitions()
	assert_eq(defs.size(), 5, "Exactly 5 visitor definitions loaded")

	var expected_specs: Dictionary = {
		"visitor.bird": {"weight": 25.0, "trait": "fruit", "count": 1},
		"visitor.butterfly": {"weight": 30.0, "trait": "flower", "count": 1},
		"visitor.cat": {"weight": 15.0, "trait": "shade", "count": 1},
		"visitor.firefly": {"weight": 20.0, "trait": "dense_vegetation", "count": 1},
		"visitor.frog": {"weight": 10.0, "trait": "water", "count": 1},
	}

	for def: VisitorDefinition in defs:
		assert_true(def.is_valid(), "Visitor definition %s must be valid" % def.id)
		assert_true(expected_specs.has(def.id), "Expected specs has %s" % def.id)
		var spec: Dictionary = expected_specs[def.id]
		assert_eq(def.weight, spec["weight"], "%s weight matches" % def.id)
		assert_eq(
			def.required_trait_counts.get(spec["trait"], 0),
			spec["count"],
			"%s required trait '%s' count matches" % [def.id, spec["trait"]]
		)
		assert_eq(def.min_total_plants, 1, "%s min_total_plants is 1" % def.id)


func _test_production_catalog_and_eligibility_integration() -> void:
	describe("Loaded production plants and visitors compose into ContentCatalog and drive eligibility")
	var plant_res: PlantContentLoadResult = PlantContentLoader.new().load_production_definitions()
	var visitor_res: VisitorContentLoadResult = VisitorContentLoader.new().load_production_definitions()
	var catalog: ContentCatalog = ContentCatalog.try_create(
		plant_res.get_definitions(),
		visitor_res.get_definitions()
	)
	assert_true(catalog != null, "Catalog with 5 plants and 5 visitors must build")
	assert_eq(catalog.get_plant_count(), 5, "5 plants in catalog")
	assert_eq(catalog.get_visitor_count(), 5, "5 visitors in catalog")

	# Plant jasmine (flower, dense_vegetation) -> enables butterfly & firefly
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("jas-1", "plant.jasmine", 1000))
	var snap: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, 1000)
	var eligible: Array[VisitorDefinition] = VisitorEligibility.filter_eligible_visitors(
		catalog.get_all_visitors(),
		snap
	)
	assert_eq(eligible.size(), 2, "Jasmine enables 2 visitors")
	assert_eq(eligible[0].id, "visitor.butterfly", "Butterfly eligible")
	assert_eq(eligible[1].id, "visitor.firefly", "Firefly eligible")


func _test_failure_modes_all_or_nothing() -> void:
	describe("VisitorContentLoader rejects empty, duplicate, non-res, missing, or wrong-type paths")
	var loader: VisitorContentLoader = VisitorContentLoader.new()

	assert_false(loader.load_from_paths([""]).is_loaded(), "Empty path rejected")
	assert_false(
		loader.load_from_paths(["res://content/visitors/bird.tres", "res://content/visitors/bird.tres"]).is_loaded(),
		"Duplicate path rejected"
	)
	assert_false(
		loader.load_from_paths(["content/visitors/bird.tres"]).is_loaded(),
		"Non-res:// path rejected"
	)
	assert_false(
		loader.load_from_paths(["res://content/visitors/missing.tres"]).is_loaded(),
		"Missing path rejected"
	)
	assert_false(
		loader.load_from_paths(["res://content/plants/banana.tres"]).is_loaded(),
		"Wrong resource type (PlantDefinition instead of VisitorDefinition) rejected"
	)
	var mixed: VisitorContentLoadResult = loader.load_from_paths([
		"res://content/visitors/bird.tres",
		"res://content/visitors/missing.tres",
	])
	assert_false(mixed.is_loaded(), "Mixed valid and invalid paths fail")
	assert_eq(mixed.get_definitions().size(), 0, "All-or-nothing: no partial definitions returned")
