## test_plant_save_content_validator.gd
## Unit test suite for PlantSaveContentValidator and PlantSaveContentValidationResult.
##
## Verifies:
## A. Empty plant collection is COMPATIBLE.
## B. One known plant is COMPATIBLE.
## C. Multiple known plants are COMPATIBLE.
## D. Several runtime instances of the same known definition are COMPATIBLE.
## E. One structurally valid unknown definition ID returns UNKNOWN_PLANT_IDS.
## F. Multiple distinct unknown IDs return sorted ascending.
## G. Repeated unknown ID appears only once in diagnostics.
## H. Mixed known and unknown definitions return only unknown IDs.
## I. Exact ID case/spelling is preserved.
## J. Null GameState returns INVALID_INPUT.
## K. Null ContentCatalog returns INVALID_INPUT.
## L. Validation does not mutate GameState, PlantState, or ContentCatalog.
## M. Returned unknown-ID arrays cannot mutate result internals.
## N. Repeated calls return equivalent deterministic results.
## O. Validator is RefCounted, not Node/Resource/Autoload.
class_name TestPlantSaveContentValidator
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestPlantSaveContentValidator"


func run_tests() -> void:
	_test_validator_is_ref_counted()
	_test_empty_plant_collection_compatible()
	_test_one_known_plant_compatible()
	_test_multiple_known_plants_compatible()
	_test_multiple_instances_same_definition_compatible()
	_test_single_unknown_definition_returns_unknown_ids()
	_test_multiple_unknown_ids_sorted_ascending()
	_test_repeated_unknown_id_deduplicated()
	_test_mixed_known_and_unknown_returns_only_unknown()
	_test_exact_id_spelling_preserved()
	_test_null_game_state_returns_invalid_input()
	_test_null_content_catalog_returns_invalid_input()
	_test_validation_does_not_mutate_state_or_catalog()
	_test_defensive_copies_on_returned_arrays()
	_test_repeated_calls_deterministic()


func _test_validator_is_ref_counted() -> void:
	describe("Validator and ValidationResult are pure RefCounted objects")
	var validator: PlantSaveContentValidator = PlantSaveContentValidator.new()
	assert_true(validator is RefCounted, "PlantSaveContentValidator must extend RefCounted")
	var validator_obj: Object = validator
	assert_false(validator_obj is Node, "PlantSaveContentValidator must NOT extend Node")
	assert_false(validator_obj is Resource, "PlantSaveContentValidator must NOT extend Resource")

	var res_compat: PlantSaveContentValidationResult = PlantSaveContentValidationResult.compatible()
	assert_true(res_compat is RefCounted, "PlantSaveContentValidationResult must extend RefCounted")
	var res_obj: Object = res_compat
	assert_false(res_obj is Node, "PlantSaveContentValidationResult must NOT extend Node")
	assert_false(res_obj is Resource, "PlantSaveContentValidationResult must NOT extend Resource")
	assert_eq(res_compat.get_status(), PlantSaveContentValidationResult.COMPATIBLE, "status must be COMPATIBLE")
	assert_true(res_compat.is_compatible(), "is_compatible must be true")
	assert_eq(res_compat.get_unknown_definition_ids().size(), 0, "COMPATIBLE must have no unknown IDs")

	var res_invalid: PlantSaveContentValidationResult = PlantSaveContentValidationResult.invalid_input()
	assert_eq(res_invalid.get_status(), PlantSaveContentValidationResult.INVALID_INPUT, "status must be INVALID_INPUT")
	assert_false(res_invalid.is_compatible(), "is_compatible must be false for INVALID_INPUT")
	assert_eq(res_invalid.get_unknown_definition_ids().size(), 0, "INVALID_INPUT must have no unknown IDs")


func _test_empty_plant_collection_compatible() -> void:
	describe("Empty plant collection is COMPATIBLE with any valid catalog")
	var catalog: ContentCatalog = _create_test_catalog(["plant.basil", "plant.mint"])
	var state: GameState = GameState.new()
	assert_eq(state.get_plants().get_count(), 0, "state must have 0 plants")

	var result: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(state, catalog)
	assert_eq(result.get_status(), PlantSaveContentValidationResult.COMPATIBLE, "status must be COMPATIBLE")
	assert_true(result.is_compatible(), "is_compatible must be true")
	assert_eq(result.get_unknown_definition_ids(), [], "unknown IDs must be empty")


func _test_one_known_plant_compatible() -> void:
	describe("One known plant is COMPATIBLE")
	var catalog: ContentCatalog = _create_test_catalog(["plant.basil"])
	var state: GameState = GameState.new()
	var plant: PlantState = PlantState.new("p1", "plant.basil", 1000)
	state.get_plants().try_add_plant(plant)

	var result: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(state, catalog)
	assert_eq(result.get_status(), PlantSaveContentValidationResult.COMPATIBLE, "status must be COMPATIBLE")
	assert_true(result.is_compatible(), "is_compatible must be true")
	assert_eq(result.get_unknown_definition_ids(), [], "unknown IDs must be empty")


func _test_multiple_known_plants_compatible() -> void:
	describe("Multiple known plants are COMPATIBLE")
	var catalog: ContentCatalog = _create_test_catalog(["plant.basil", "plant.chili", "plant.mint"])
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p1", "plant.basil", 1000))
	state.get_plants().try_add_plant(PlantState.new("p2", "plant.chili", 1001))
	state.get_plants().try_add_plant(PlantState.new("p3", "plant.mint", 1002))

	var result: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(state, catalog)
	assert_eq(result.get_status(), PlantSaveContentValidationResult.COMPATIBLE, "status must be COMPATIBLE")
	assert_true(result.is_compatible(), "is_compatible must be true")
	assert_eq(result.get_unknown_definition_ids(), [], "unknown IDs must be empty")


func _test_multiple_instances_same_definition_compatible() -> void:
	describe("Several runtime instances of the same known definition are COMPATIBLE")
	var catalog: ContentCatalog = _create_test_catalog(["plant.basil"])
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p1", "plant.basil", 1000))
	state.get_plants().try_add_plant(PlantState.new("p2", "plant.basil", 2000))
	state.get_plants().try_add_plant(PlantState.new("p3", "plant.basil", 3000))

	var result: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(state, catalog)
	assert_eq(result.get_status(), PlantSaveContentValidationResult.COMPATIBLE, "status must be COMPATIBLE")
	assert_true(result.is_compatible(), "is_compatible must be true")
	assert_eq(result.get_unknown_definition_ids(), [], "unknown IDs must be empty")


func _test_single_unknown_definition_returns_unknown_ids() -> void:
	describe("One structurally valid unknown definition ID returns UNKNOWN_PLANT_IDS")
	var catalog: ContentCatalog = _create_test_catalog(["plant.basil"])
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p1", "plant.future_lotus", 1000))

	var result: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(state, catalog)
	assert_eq(result.get_status(), PlantSaveContentValidationResult.UNKNOWN_PLANT_IDS, "status must be UNKNOWN_PLANT_IDS")
	assert_false(result.is_compatible(), "is_compatible must be false")
	assert_eq(result.get_unknown_definition_ids(), ["plant.future_lotus"], "diagnostics must list plant.future_lotus")


func _test_multiple_unknown_ids_sorted_ascending() -> void:
	describe("Multiple distinct unknown IDs return sorted ascending")
	var catalog: ContentCatalog = _create_test_catalog(["plant.basil"])
	var state: GameState = GameState.new()
	# Added in reverse/unsorted order: zebra, cactus, apple
	state.get_plants().try_add_plant(PlantState.new("p1", "plant.zebra_flower", 1000))
	state.get_plants().try_add_plant(PlantState.new("p2", "plant.cactus", 1001))
	state.get_plants().try_add_plant(PlantState.new("p3", "plant.apple_tree", 1002))

	var result: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(state, catalog)
	assert_eq(result.get_status(), PlantSaveContentValidationResult.UNKNOWN_PLANT_IDS, "status must be UNKNOWN_PLANT_IDS")
	assert_false(result.is_compatible(), "is_compatible must be false")
	var expected: Array[String] = ["plant.apple_tree", "plant.cactus", "plant.zebra_flower"]
	assert_eq(result.get_unknown_definition_ids(), expected, "unknown IDs must be sorted ascending")


func _test_repeated_unknown_id_deduplicated() -> void:
	describe("Repeated unknown ID appears only once in diagnostics")
	var catalog: ContentCatalog = _create_test_catalog(["plant.basil"])
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p1", "plant.alien_orchid", 1000))
	state.get_plants().try_add_plant(PlantState.new("p2", "plant.alien_orchid", 2000))
	state.get_plants().try_add_plant(PlantState.new("p3", "plant.alien_orchid", 3000))

	var result: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(state, catalog)
	assert_eq(result.get_status(), PlantSaveContentValidationResult.UNKNOWN_PLANT_IDS, "status must be UNKNOWN_PLANT_IDS")
	assert_eq(result.get_unknown_definition_ids(), ["plant.alien_orchid"], "repeated unknown ID must be deduplicated")


func _test_mixed_known_and_unknown_returns_only_unknown() -> void:
	describe("Mixed known and unknown definitions return only unknown IDs")
	var catalog: ContentCatalog = _create_test_catalog(["plant.basil", "plant.mint"])
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p1", "plant.basil", 1000))
	state.get_plants().try_add_plant(PlantState.new("p2", "plant.unknown_rose", 1001))
	state.get_plants().try_add_plant(PlantState.new("p3", "plant.mint", 1002))
	state.get_plants().try_add_plant(PlantState.new("p4", "plant.unknown_cactus", 1003))

	var result: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(state, catalog)
	assert_eq(result.get_status(), PlantSaveContentValidationResult.UNKNOWN_PLANT_IDS, "status must be UNKNOWN_PLANT_IDS")
	assert_eq(
		result.get_unknown_definition_ids(),
		["plant.unknown_cactus", "plant.unknown_rose"],
		"must only return unknown IDs sorted"
	)


func _test_exact_id_spelling_preserved() -> void:
	describe("Exact ID case and spelling are preserved without normalization")
	var catalog: ContentCatalog = _create_test_catalog(["plant.basil"])
	var state: GameState = GameState.new()
	# Distinct case and characters
	state.get_plants().try_add_plant(PlantState.new("p1", "plant.rare_orchid_v2", 1000))

	var result: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(state, catalog)
	assert_eq(result.get_unknown_definition_ids(), ["plant.rare_orchid_v2"], "exact spelling must be preserved")


func _test_null_game_state_returns_invalid_input() -> void:
	describe("Null GameState returns INVALID_INPUT")
	var catalog: ContentCatalog = _create_test_catalog(["plant.basil"])
	var result: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(null, catalog)
	assert_eq(result.get_status(), PlantSaveContentValidationResult.INVALID_INPUT, "status must be INVALID_INPUT")
	assert_false(result.is_compatible(), "is_compatible must be false")
	assert_eq(result.get_unknown_definition_ids(), [], "unknown IDs must be empty on invalid input")


func _test_null_content_catalog_returns_invalid_input() -> void:
	describe("Null ContentCatalog returns INVALID_INPUT")
	var state: GameState = GameState.new()
	var result: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(state, null)
	assert_eq(result.get_status(), PlantSaveContentValidationResult.INVALID_INPUT, "status must be INVALID_INPUT")
	assert_false(result.is_compatible(), "is_compatible must be false")
	assert_eq(result.get_unknown_definition_ids(), [], "unknown IDs must be empty on invalid input")


func _test_validation_does_not_mutate_state_or_catalog() -> void:
	describe("Validation does not mutate GameState, PlantState, or ContentCatalog")
	var catalog: ContentCatalog = _create_test_catalog(["plant.basil"])
	var state: GameState = GameState.new()
	var plant: PlantState = PlantState.new("p1", "plant.unknown_tree", 1500)
	state.get_plants().try_add_plant(plant)

	var catalog_count_before: int = catalog.get_plant_count()
	var state_count_before: int = state.get_plants().get_count()

	var result: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(state, catalog)
	assert_eq(result.get_status(), PlantSaveContentValidationResult.UNKNOWN_PLANT_IDS, "status must be UNKNOWN_PLANT_IDS")

	assert_eq(catalog.get_plant_count(), catalog_count_before, "catalog count must be unchanged")
	assert_eq(state.get_plants().get_count(), state_count_before, "state plant count must be unchanged")
	assert_eq(state.get_plants().get_plant("p1"), plant, "stored plant reference must be unchanged")
	assert_eq(plant.get_definition_id(), "plant.unknown_tree", "plant definition_id must be unchanged")
	assert_eq(plant.get_runtime_instance_id(), "p1", "plant runtime instance ID must be unchanged")
	assert_eq(plant.get_planted_at(), 1500, "plant timestamp must be unchanged")


func _test_defensive_copies_on_returned_arrays() -> void:
	describe("Returned unknown-ID arrays cannot mutate result internals")
	var res: PlantSaveContentValidationResult = PlantSaveContentValidationResult.unknown_plant_ids(["plant.a", "plant.b"])
	var ids1: Array[String] = res.get_unknown_definition_ids()
	ids1.append("plant.c_injected")
	ids1[0] = "plant.mutated"

	var ids2: Array[String] = res.get_unknown_definition_ids()
	assert_eq(ids2, ["plant.a", "plant.b"], "mutating returned array must not affect internal result state")


func _test_repeated_calls_deterministic() -> void:
	describe("Repeated validator calls return deterministic equivalent outcomes")
	var catalog: ContentCatalog = _create_test_catalog(["plant.basil"])
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p1", "plant.unknown_x", 100))
	state.get_plants().try_add_plant(PlantState.new("p2", "plant.unknown_a", 200))

	var res1: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(state, catalog)
	var res2: PlantSaveContentValidationResult = PlantSaveContentValidator.validate(state, catalog)

	assert_eq(res1.get_status(), res2.get_status(), "status must be identical")
	assert_eq(res1.is_compatible(), res2.is_compatible(), "compatibility must be identical")
	assert_eq(res1.get_unknown_definition_ids(), res2.get_unknown_definition_ids(), "unknown IDs must be identical")


func _create_test_catalog(ids: Array[String]) -> ContentCatalog:
	var defs: Array[PlantDefinition] = []
	for id: String in ids:
		var def: PlantDefinition = PlantDefinition.new()
		def.id = id
		def.sprout_after_seconds = 60
		def.growing_after_seconds = 180
		def.mature_after_seconds = 600
		defs.append(def)
	return ContentCatalog.try_create(defs)
