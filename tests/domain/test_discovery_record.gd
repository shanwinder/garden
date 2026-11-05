## test_discovery_record.gd
## Unit tests for DiscoveryRecord domain value object.
class_name TestDiscoveryRecord
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestDiscoveryRecord"


func run_tests() -> void:
	_test_type_contract()
	_test_valid_plant_and_visitor_records()
	_test_invalid_records_rejected()
	_test_with_additional_sighting_preserves_first_seen_at_and_guards_overflow()


func _test_type_contract() -> void:
	describe("DiscoveryRecord extends RefCounted and is not Node or Resource")
	var rec: Variant = DiscoveryRecord.new("plant.holy_basil", 1000, 1)
	assert_true(rec is DiscoveryRecord, "Must satisfy 'is DiscoveryRecord'")
	assert_true(rec is RefCounted, "Must extend RefCounted")
	assert_false(rec is Node, "Must not be a Node")
	assert_false(rec is Resource, "Must not be a Resource")


func _test_valid_plant_and_visitor_records() -> void:
	describe("Valid plant and visitor discovery records preserve exact fields")
	var plant_rec: DiscoveryRecord = DiscoveryRecord.new("plant.holy_basil", 0, 1)
	assert_true(plant_rec.is_valid(), "plant.holy_basil record at t=0 is valid")
	assert_eq(plant_rec.get_definition_id(), "plant.holy_basil", "Definition ID matches")
	assert_eq(plant_rec.get_first_seen_at(), 0, "first_seen_at is 0")
	assert_eq(plant_rec.get_times_seen(), 1, "times_seen is 1")
	assert_true(plant_rec.is_plant_discovery(), "is_plant_discovery() true")
	assert_false(plant_rec.is_visitor_discovery(), "is_visitor_discovery() false")

	var visitor_rec: DiscoveryRecord = DiscoveryRecord.new(
		"visitor.butterfly",
		9223372036854775807,
		42
	)
	assert_true(visitor_rec.is_valid(), "visitor.butterfly record at MAX_INT64 is valid")
	assert_eq(visitor_rec.get_definition_id(), "visitor.butterfly", "Definition ID matches")
	assert_eq(visitor_rec.get_first_seen_at(), 9223372036854775807, "first_seen_at is MAX_INT64")
	assert_eq(visitor_rec.get_times_seen(), 42, "times_seen is 42")
	assert_false(visitor_rec.is_plant_discovery(), "is_plant_discovery() false")
	assert_true(visitor_rec.is_visitor_discovery(), "is_visitor_discovery() true")


func _test_invalid_records_rejected() -> void:
	describe("Invalid IDs, unsupported namespaces, negative first_seen_at, and times_seen < 1 are rejected")
	var invalid_ids: Array[String] = [
		"",
		"plant.",
		"visitor.",
		"plant.UPPERCASE",
		"visitor.UPPERCASE",
		"decoration.clay_jar",
		"event.cat_sleeping",
		"holy_basil",
	]
	for bad_id: String in invalid_ids:
		assert_false(
			DiscoveryRecord.is_supported_discovery_id(bad_id),
			"Unsupported/invalid discovery ID rejected: %s" % bad_id
		)
		var rec_bad_id: DiscoveryRecord = DiscoveryRecord.new(bad_id, 1000, 1)
		assert_false(rec_bad_id.is_valid(), "Record with invalid ID rejected: %s" % bad_id)

	var neg_time: DiscoveryRecord = DiscoveryRecord.new("plant.holy_basil", -1, 1)
	assert_false(neg_time.is_valid(), "Negative first_seen_at rejected")

	var zero_seen: DiscoveryRecord = DiscoveryRecord.new("plant.holy_basil", 1000, 0)
	assert_false(zero_seen.is_valid(), "times_seen == 0 rejected")

	var neg_seen: DiscoveryRecord = DiscoveryRecord.new("visitor.bird", 1000, -5)
	assert_false(neg_seen.is_valid(), "Negative times_seen rejected")


func _test_with_additional_sighting_preserves_first_seen_at_and_guards_overflow() -> void:
	describe("with_additional_sighting returns new immutable record preserving first_seen_at and guarding overflow")
	var first: DiscoveryRecord = DiscoveryRecord.new("visitor.cat", 1500, 1)
	var second: DiscoveryRecord = first.with_additional_sighting(2500)
	assert_true(second != null, "Second sighting succeeds")
	assert_ne(second, first, "Returns new instance")
	assert_eq(first.get_times_seen(), 1, "Original record remains immutable at times_seen = 1")
	assert_eq(second.get_definition_id(), "visitor.cat", "Definition ID preserved")
	assert_eq(second.get_first_seen_at(), 1500, "Original first_seen_at = 1500 preserved")
	assert_eq(second.get_times_seen(), 2, "times_seen incremented to 2")

	# Negative sighting timestamp rejected
	assert_eq(first.with_additional_sighting(-1), null, "Negative seen_at_utc rejected")

	# MAX_INT64 times_seen overflow rejected
	var max_rec: DiscoveryRecord = DiscoveryRecord.new(
		"visitor.cat",
		1500,
		DiscoveryRecord.MAX_INT64
	)
	assert_eq(max_rec.with_additional_sighting(3000), null, "Overflow beyond MAX_INT64 rejected")
