## test_event_content_loader.gd
## Integration and unit tests for EventContentLoader and EventContentLoadResult.
##
## Exercises real Godot ResourceLoader interactions against the six authored production event
## resources (five MVP ambient/special events plus one secret combination event) and verifies failure handling, catalog integration, and eligibility rules.
class_name TestEventContentLoader
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestEventContentLoader"


func run_tests() -> void:
	_test_type_contracts()
	_test_production_resources_exist()
	_test_production_load_success_and_fields()
	_test_production_catalog_and_eligibility_integration()
	_test_failure_modes_all_or_nothing()
	_test_secret_combination_event_content()


func _test_type_contracts() -> void:
	describe("EventContentLoader and EventContentLoadResult satisfy RefCounted contracts")
	var loader: EventContentLoader = EventContentLoader.new()
	assert_true(loader != null, "Loader instance should not be null")
	assert_true(loader is EventContentLoader, "Must be EventContentLoader")
	assert_true(loader is RefCounted, "Must extend RefCounted")
	var loader_obj: Variant = loader
	assert_false(loader_obj is Node, "Must not be a Node")
	assert_false(loader_obj is Resource, "Must not be a Resource")

	var result: EventContentLoadResult = loader.load_production_definitions()
	assert_true(result != null, "LoadResult must not be null")
	assert_true(result is EventContentLoadResult, "Must be EventContentLoadResult")
	assert_true(result is RefCounted, "Must extend RefCounted")


func _test_production_resources_exist() -> void:
	describe("All six authored production event resources exist on filesystem")
	var expected_paths: Array[String] = [
		"res://content/events/bird_shade_song.tres",
		"res://content/events/cat_jasmine_night_rest.tres",
		"res://content/events/cat_sleeping_bench.tres",
		"res://content/events/firefly_night_glow.tres",
		"res://content/events/frog_rain_chorus.tres",
		"res://content/events/morning_butterflies.tres",
	]
	assert_eq(EventContentLoader.PRODUCTION_EVENT_PATHS, expected_paths, "Manifest paths match")
	for path: String in expected_paths:
		assert_true(ResourceLoader.exists(path), "Resource must exist: %s" % path)


func _test_production_load_success_and_fields() -> void:
	describe("All six production event resources load, pass is_valid(), and match MVP Interaction Matrix")
	var loader: EventContentLoader = EventContentLoader.new()
	var result: EventContentLoadResult = loader.load_production_definitions()

	assert_true(result.is_loaded(), "Production event load must succeed")
	assert_eq(result.get_status(), EventContentLoadResult.Status.LOADED, "Status LOADED")
	var defs: Array[EventDefinition] = result.get_definitions()
	assert_eq(defs.size(), 6, "Exactly 6 event definitions loaded")

	var expected_ids: Array[String] = [
		"event.bird_shade_song",
		"event.cat_jasmine_night_rest",
		"event.cat_sleeping_bench",
		"event.firefly_night_glow",
		"event.frog_rain_chorus",
		"event.morning_butterflies",
	]
	for i: int in range(defs.size()):
		var def: EventDefinition = defs[i]
		assert_true(def.is_valid(), "Event definition %s must be valid" % def.id)
		assert_eq(def.id, expected_ids[i], "Event ID at index %d matches" % i)


func _test_production_catalog_and_eligibility_integration() -> void:
	describe("Loaded production plants, visitors, decorations, and events compose into ContentCatalog and drive event eligibility")
	var plant_res: PlantContentLoadResult = PlantContentLoader.new().load_production_definitions()
	var visitor_res: VisitorContentLoadResult = VisitorContentLoader.new().load_production_definitions()
	var decor_res: DecorationContentLoadResult = DecorationContentLoader.new().load_production_definitions()
	var event_res: EventContentLoadResult = EventContentLoader.new().load_production_definitions()
	var catalog: ContentCatalog = ContentCatalog.try_create(
		plant_res.get_definitions(),
		visitor_res.get_definitions(),
		decor_res.get_definitions(),
		event_res.get_definitions()
	)
	assert_true(catalog != null, "Catalog with 5 plants, 5 visitors, 8 decorations, and 6 events must build")
	assert_eq(catalog.get_event_count(), 6, "6 events in catalog")

	# Plant Jasmine + Morning (21600s -> hour 6 = morning, window 3 = clear) -> event.morning_butterflies
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("jas-1", "plant.jasmine", 1000))
	var snap: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, 21600)
	var eligible: Array[EventDefinition] = EventEligibility.filter_eligible_events(
		catalog.get_all_events(),
		snap
	)
	assert_eq(eligible.size(), 1, "Jasmine at morning clear enables 1 event")
	assert_eq(eligible[0].id, "event.morning_butterflies", "Morning butterflies event eligible")


func _test_failure_modes_all_or_nothing() -> void:
	describe("EventContentLoader rejects empty, duplicate, non-res, missing, or wrong-type paths")
	var loader: EventContentLoader = EventContentLoader.new()

	assert_false(loader.load_from_paths([""]).is_loaded(), "Empty path rejected")
	assert_false(
		loader.load_from_paths([
			"res://content/events/morning_butterflies.tres",
			"res://content/events/morning_butterflies.tres",
		]).is_loaded(),
		"Duplicate path rejected"
	)
	assert_false(
		loader.load_from_paths(["content/events/morning_butterflies.tres"]).is_loaded(),
		"Non-res:// path rejected"
	)
	assert_false(
		loader.load_from_paths(["res://content/events/missing.tres"]).is_loaded(),
		"Missing path rejected"
	)
	assert_false(
		loader.load_from_paths(["res://content/plants/banana.tres"]).is_loaded(),
		"Wrong resource type (PlantDefinition instead of EventDefinition) rejected"
	)
	var mixed: EventContentLoadResult = loader.load_from_paths([
		"res://content/events/morning_butterflies.tres",
		"res://content/events/missing.tres",
	])
	assert_false(mixed.is_loaded(), "Mixed valid and invalid paths fail")
	assert_eq(mixed.get_definitions().size(), 0, "All-or-nothing: no partial definitions returned")


func _test_secret_combination_event_content() -> void:
	describe("Authored secret combination event (jasmine x3 + bench + night) is rare, secret, and eligible only for the full combination")
	var plant_res: PlantContentLoadResult = PlantContentLoader.new().load_production_definitions()
	var visitor_res: VisitorContentLoadResult = VisitorContentLoader.new().load_production_definitions()
	var decor_res: DecorationContentLoadResult = DecorationContentLoader.new().load_production_definitions()
	var event_res: EventContentLoadResult = EventContentLoader.new().load_production_definitions()
	var catalog: ContentCatalog = ContentCatalog.try_create(
		plant_res.get_definitions(),
		visitor_res.get_definitions(),
		decor_res.get_definitions(),
		event_res.get_definitions()
	)
	assert_true(catalog != null, "Production catalog must build")
	var secret: EventDefinition = catalog.get_event("event.cat_jasmine_night_rest")
	assert_true(secret != null, "Secret event exists in catalog")
	assert_true(secret.is_secret, "Secret event is flagged is_secret")
	assert_eq(secret.required_plant_counts, {"plant.jasmine": 3}, "Requires 3 jasmine")
	assert_eq(secret.required_decoration_ids, ["decoration.bench"], "Requires a bench")
	assert_eq(secret.allowed_time_periods, ["night"], "Night only")
	for other: EventDefinition in catalog.get_all_events():
		if other.id == secret.id:
			continue
		assert_false(other.is_secret, "Ambient event %s is not secret" % other.id)
		assert_true(secret.weight < other.weight, "Secret event is rarer than %s" % other.id)

	# t = 3600 -> 01:00 UTC -> night
	var night_utc: int = 3600
	var state: GameState = GameState.new()
	state.get_decorations().try_add_decoration(DecorationState.new("dec-1", "decoration.bench", 100))
	state.get_plants().try_add_plant(PlantState.new("jas-1", "plant.jasmine", 100))
	state.get_plants().try_add_plant(PlantState.new("jas-2", "plant.jasmine", 100))
	var two_snap: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, night_utc)
	assert_eq(two_snap.get_time_period(), "night", "Snapshot is at night")
	assert_false(EventEligibility.is_eligible(secret, two_snap), "2 jasmine + bench at night is not enough")

	state.get_plants().try_add_plant(PlantState.new("jas-3", "plant.jasmine", 100))
	var three_snap: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, night_utc)
	assert_true(EventEligibility.is_eligible(secret, three_snap), "3 jasmine + bench at night is eligible")

	# 21600 -> 06:00 UTC -> morning
	var morning_snap: GardenSnapshot = GardenSnapshotBuilder.build_snapshot(state, catalog, 21600)
	assert_false(EventEligibility.is_eligible(secret, morning_snap), "Same garden in the morning is not eligible")
