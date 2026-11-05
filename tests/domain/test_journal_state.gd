## test_journal_state.gd
## Unit tests for JournalState domain state slice.
class_name TestJournalState
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestJournalState"


func run_tests() -> void:
	_test_type_contract_and_initial_state()
	_test_try_put_record_and_uniqueness()
	_test_try_record_sighting_idempotent_first_discovery_and_repeat_count()
	_test_deterministic_ascending_enumeration_and_defensive_copies()


func _test_type_contract_and_initial_state() -> void:
	describe("JournalState extends RefCounted and starts empty")
	var journal: Variant = JournalState.new()
	assert_true(journal is JournalState, "Must satisfy 'is JournalState'")
	assert_true(journal is RefCounted, "Must extend RefCounted")
	assert_false(journal is Node, "Must not be a Node")
	assert_false(journal is Resource, "Must not be a Resource")

	var j: JournalState = journal as JournalState
	assert_eq(j.get_count(), 0, "Initial count is 0")
	assert_false(j.has_discovered("plant.holy_basil"), "Not discovered initially")
	assert_false(j.has_discovered(""), "Empty ID returns false")
	assert_eq(j.get_record("plant.holy_basil"), null, "Missing record returns null")
	assert_eq(j.get_record(""), null, "Empty ID returns null")
	assert_eq(j.get_all_records().size(), 0, "Empty records array")
	assert_eq(j.get_discovered_ids().size(), 0, "Empty discovered IDs array")


func _test_try_put_record_and_uniqueness() -> void:
	describe("try_put_record validates records and rejects duplicates")
	var journal: JournalState = JournalState.new()
	assert_false(journal.try_put_record(null), "Null record rejected")
	assert_false(
		journal.try_put_record(DiscoveryRecord.new("invalid.id", 100, 1)),
		"Invalid record rejected"
	)
	assert_eq(journal.get_count(), 0, "Count remains 0 after rejections")

	var rec1: DiscoveryRecord = DiscoveryRecord.new("plant.jasmine", 1200, 3)
	assert_true(journal.try_put_record(rec1), "Valid record accepted")
	assert_eq(journal.get_count(), 1, "Count is 1")
	assert_true(journal.has_discovered("plant.jasmine"), "has_discovered true")
	assert_eq(journal.get_record("plant.jasmine"), rec1, "Exact reference stored")

	# Duplicate definition_id rejected
	var rec_dup: DiscoveryRecord = DiscoveryRecord.new("plant.jasmine", 9999, 1)
	assert_false(journal.try_put_record(rec_dup), "Duplicate definition_id rejected")
	assert_eq(journal.get_record("plant.jasmine"), rec1, "Original record preserved")


func _test_try_record_sighting_idempotent_first_discovery_and_repeat_count() -> void:
	describe("try_record_sighting creates first discovery and increments times_seen on repeats while preserving first_seen_at")
	var journal: JournalState = JournalState.new()

	# Rejections leave journal untouched
	assert_false(journal.try_record_sighting("", 1000), "Empty ID rejected")
	assert_false(journal.try_record_sighting("decoration.bench", 1000), "Unsupported namespace rejected")
	assert_false(journal.try_record_sighting("visitor.frog", -1), "Negative timestamp rejected")
	assert_eq(journal.get_count(), 0, "Journal remains empty")

	# First sighting of visitor.butterfly at t = 1000
	assert_true(journal.try_record_sighting("visitor.butterfly", 1000), "First sighting succeeds")
	assert_eq(journal.get_count(), 1, "Count is 1")
	var r1: DiscoveryRecord = journal.get_record("visitor.butterfly")
	assert_true(r1 != null, "Record exists")
	assert_eq(r1.get_first_seen_at(), 1000, "first_seen_at is 1000")
	assert_eq(r1.get_times_seen(), 1, "times_seen is 1")

	# Second sighting at t = 2500
	assert_true(journal.try_record_sighting("visitor.butterfly", 2500), "Second sighting succeeds")
	assert_eq(journal.get_count(), 1, "Count remains 1")
	var r2: DiscoveryRecord = journal.get_record("visitor.butterfly")
	assert_eq(r2.get_first_seen_at(), 1000, "first_seen_at preserved at 1000")
	assert_eq(r2.get_times_seen(), 2, "times_seen incremented to 2")

	# Third sighting even if clock rolled backward to t = 500 (>= 0)
	assert_true(journal.try_record_sighting("visitor.butterfly", 500), "Third sighting succeeds")
	var r3: DiscoveryRecord = journal.get_record("visitor.butterfly")
	assert_eq(r3.get_first_seen_at(), 1000, "first_seen_at still 1000")
	assert_eq(r3.get_times_seen(), 3, "times_seen incremented to 3")


func _test_deterministic_ascending_enumeration_and_defensive_copies() -> void:
	describe("get_all_records and get_discovered_ids return deterministic ascending order and defensive copies")
	var journal: JournalState = JournalState.new()
	journal.try_record_sighting("visitor.frog", 300)
	journal.try_record_sighting("plant.banana", 100)
	journal.try_record_sighting("visitor.bird", 200)
	journal.try_record_sighting("plant.marigold", 150)

	var expected_ids: Array[String] = [
		"plant.banana",
		"plant.marigold",
		"visitor.bird",
		"visitor.frog",
	]
	assert_eq(journal.get_discovered_ids(), expected_ids, "Discovered IDs sorted ascending")

	var records: Array[DiscoveryRecord] = journal.get_all_records()
	assert_eq(records.size(), 4, "4 records returned")
	for i: int in range(expected_ids.size()):
		assert_eq(records[i].get_definition_id(), expected_ids[i], "Record %d ID matches" % i)

	# Mutating returned arrays does not mutate JournalState
	records.clear()
	var ids_copy: Array[String] = journal.get_discovered_ids()
	ids_copy.clear()
	assert_eq(journal.get_count(), 4, "JournalState count unaffected by array mutation")
