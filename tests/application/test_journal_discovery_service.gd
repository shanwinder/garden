## test_journal_discovery_service.gd
## Unit tests for JournalDiscoveryService and JournalDiscoveryResult.
class_name TestJournalDiscoveryService
extends TestSuiteBase


class CountingClock extends FakeGameClock:
	var read_count: int = 0

	func _init(initial_utc: int = 1700000000) -> void:
		super._init(initial_utc, 0)

	func utc_now_seconds() -> int:
		read_count += 1
		return super.utc_now_seconds()


func _init() -> void:
	suite_name = "TestJournalDiscoveryService"


func run_tests() -> void:
	_test_type_contracts()
	_test_record_discovery_at_first_and_repeat_sighting_idempotency()
	_test_record_discovery_at_rejects_invalid_and_unknown_inputs()
	_test_record_discovery_now_prevalidates_before_sampling_clock()
	_test_result_value_object_rejects_inconsistent_construction()


func _create_production_catalog() -> ContentCatalog:
	var plants: Array[PlantDefinition] = PlantContentLoader.new().load_production_definitions().get_definitions()
	var visitors: Array[VisitorDefinition] = VisitorContentLoader.new().load_production_definitions().get_definitions()
	return ContentCatalog.try_create(plants, visitors)


func _test_type_contracts() -> void:
	describe("JournalDiscoveryService and JournalDiscoveryResult satisfy RefCounted contract")
	var service: Variant = JournalDiscoveryService.new()
	assert_true(service is RefCounted, "JournalDiscoveryService must extend RefCounted")
	assert_false(service is Node, "JournalDiscoveryService must not be a Node")
	assert_false(service is Resource, "JournalDiscoveryService must not be a Resource")

	var result: Variant = JournalDiscoveryResult.invalid_input()
	assert_true(result is RefCounted, "JournalDiscoveryResult must extend RefCounted")
	assert_false(result is Node, "JournalDiscoveryResult must not be a Node")
	assert_false(result is Resource, "JournalDiscoveryResult must not be a Resource")


func _test_record_discovery_at_first_and_repeat_sighting_idempotency() -> void:
	describe("record_discovery_at distinguishes FIRST_DISCOVERY and REPEAT_SIGHTING and preserves first_seen_at")
	var catalog: ContentCatalog = _create_production_catalog()
	var state: GameState = GameState.new()

	var first: JournalDiscoveryResult = JournalDiscoveryService.record_discovery_at(
		state,
		catalog,
		"visitor.butterfly",
		1700000100
	)
	assert_true(first.is_recorded(), "First discovery of known visitor should be recorded")
	assert_true(first.is_first_discovery(), "First discovery should report is_first_discovery() = true")
	assert_false(first.is_repeat_sighting(), "First discovery should report is_repeat_sighting() = false")
	assert_eq(first.get_status(), JournalDiscoveryResult.FIRST_DISCOVERY, "Status should be FIRST_DISCOVERY")
	assert_eq(first.get_definition_id(), "visitor.butterfly", "get_definition_id() matches")
	assert_true(first.get_record() != null, "First discovery should return DiscoveryRecord")
	if first.get_record() != null:
		assert_eq(first.get_record().get_definition_id(), "visitor.butterfly", "Record definition_id matches")
		assert_eq(first.get_record().get_first_seen_at(), 1700000100, "Record first_seen_at matches")
		assert_eq(first.get_record().get_times_seen(), 1, "Record times_seen starts at 1")

	var second: JournalDiscoveryResult = JournalDiscoveryService.record_discovery_at(
		state,
		catalog,
		"visitor.butterfly",
		1700000999
	)
	assert_true(second.is_recorded(), "Repeat sighting of known visitor should be recorded")
	assert_false(second.is_first_discovery(), "Repeat sighting should not be flagged as first discovery")
	assert_true(second.is_repeat_sighting(), "Repeat sighting should report is_repeat_sighting() = true")
	assert_eq(second.get_status(), JournalDiscoveryResult.REPEAT_SIGHTING, "Status should be REPEAT_SIGHTING")
	assert_true(second.get_record() != null, "Repeat sighting should return updated DiscoveryRecord")
	if second.get_record() != null:
		assert_eq(second.get_record().get_first_seen_at(), 1700000100, "Repeat sighting must preserve original first_seen_at")
		assert_eq(second.get_record().get_times_seen(), 2, "Repeat sighting must increment times_seen to 2")

	var plant_first: JournalDiscoveryResult = JournalDiscoveryService.record_discovery_at(
		state,
		catalog,
		"plant.jasmine",
		1700000200
	)
	assert_true(plant_first.is_recorded(), "First discovery of known plant should succeed")
	assert_true(plant_first.is_first_discovery(), "First discovery of plant should be FIRST_DISCOVERY")
	assert_eq(state.get_journal().get_count(), 2, "JournalState should contain 2 distinct discoveries")


func _test_record_discovery_at_rejects_invalid_and_unknown_inputs() -> void:
	describe("record_discovery_at rejects null dependencies, negative timestamps, invalid syntax, and unknown IDs")
	var catalog: ContentCatalog = _create_production_catalog()
	var state: GameState = GameState.new()

	var null_state: JournalDiscoveryResult = JournalDiscoveryService.record_discovery_at(
		null,
		catalog,
		"plant.jasmine",
		1700000000
	)
	assert_false(null_state.is_recorded(), "Null GameState must fail")
	assert_eq(null_state.get_status(), JournalDiscoveryResult.INVALID_INPUT, "Null state status")

	var null_catalog: JournalDiscoveryResult = JournalDiscoveryService.record_discovery_at(
		state,
		null,
		"plant.jasmine",
		1700000000
	)
	assert_false(null_catalog.is_recorded(), "Null ContentCatalog must fail")
	assert_eq(null_catalog.get_status(), JournalDiscoveryResult.INVALID_INPUT, "Null catalog status")

	var negative_time: JournalDiscoveryResult = JournalDiscoveryService.record_discovery_at(
		state,
		catalog,
		"plant.jasmine",
		-1
	)
	assert_false(negative_time.is_recorded(), "Negative timestamp must fail")
	assert_eq(negative_time.get_status(), JournalDiscoveryResult.INVALID_INPUT, "Negative timestamp status")

	var unsupported_namespace: JournalDiscoveryResult = JournalDiscoveryService.record_discovery_at(
		state,
		catalog,
		"decor.stone_lantern",
		1700000000
	)
	assert_false(unsupported_namespace.is_recorded(), "Unsupported namespace must fail")
	assert_eq(unsupported_namespace.get_status(), JournalDiscoveryResult.INVALID_INPUT, "Unsupported namespace status")

	var unknown_plant: JournalDiscoveryResult = JournalDiscoveryService.record_discovery_at(
		state,
		catalog,
		"plant.unknown_orchid",
		1700000000
	)
	assert_false(unknown_plant.is_recorded(), "Unknown plant definition_id must fail")
	assert_eq(unknown_plant.get_status(), JournalDiscoveryResult.UNKNOWN_DEFINITION_ID, "Unknown plant status")

	var unknown_visitor: JournalDiscoveryResult = JournalDiscoveryService.record_discovery_at(
		state,
		catalog,
		"visitor.unknown_bird",
		1700000000
	)
	assert_false(unknown_visitor.is_recorded(), "Unknown visitor definition_id must fail")
	assert_eq(unknown_visitor.get_status(), JournalDiscoveryResult.UNKNOWN_DEFINITION_ID, "Unknown visitor status")
	assert_eq(state.get_journal().get_count(), 0, "Rejected calls must not mutate JournalState")


func _test_record_discovery_now_prevalidates_before_sampling_clock() -> void:
	describe("record_discovery_now prevalidates inputs and catalog membership before sampling GameClock")
	var catalog: ContentCatalog = _create_production_catalog()
	var state: GameState = GameState.new()
	var clock: CountingClock = CountingClock.new(1700000555)

	var invalid_id: JournalDiscoveryResult = JournalDiscoveryService.record_discovery_now(
		state,
		catalog,
		clock,
		"BadId"
	)
	assert_false(invalid_id.is_recorded(), "Invalid ID must be rejected")
	assert_eq(clock.read_count, 0, "Clock must not be sampled when definition_id syntax is invalid")

	var unknown_id: JournalDiscoveryResult = JournalDiscoveryService.record_discovery_now(
		state,
		catalog,
		clock,
		"visitor.ghost_owl"
	)
	assert_false(unknown_id.is_recorded(), "Unknown ID must be rejected")
	assert_eq(clock.read_count, 0, "Clock must not be sampled when definition_id is unknown in catalog")

	var valid_res: JournalDiscoveryResult = JournalDiscoveryService.record_discovery_now(
		state,
		catalog,
		clock,
		"visitor.frog"
	)
	assert_true(valid_res.is_recorded(), "Valid discovery via record_discovery_now should succeed")
	assert_eq(clock.read_count, 1, "Clock should be sampled_once on valid discovery")
	if valid_res.get_record() != null:
		assert_eq(valid_res.get_record().get_first_seen_at(), 1700000555, "Discovery should use clock timestamp")


func _test_result_value_object_rejects_inconsistent_construction() -> void:
	describe("JournalDiscoveryResult factory methods reject null or invalid DiscoveryRecord")
	var bad_first: JournalDiscoveryResult = JournalDiscoveryResult.first_discovery(null)
	assert_false(bad_first.is_recorded(), "first_discovery(null) must not be recorded")
	assert_eq(bad_first.get_status(), JournalDiscoveryResult.STATE_UPDATE_REJECTED, "Degrades to STATE_UPDATE_REJECTED")

	var bad_repeat: JournalDiscoveryResult = JournalDiscoveryResult.repeat_sighting(null)
	assert_false(bad_repeat.is_recorded(), "repeat_sighting(null) must not be recorded")
	assert_eq(bad_repeat.get_status(), JournalDiscoveryResult.STATE_UPDATE_REJECTED, "Degrades to STATE_UPDATE_REJECTED")
