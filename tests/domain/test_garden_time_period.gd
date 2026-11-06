## test_garden_time_period.gd
## Unit tests for Garden's GardenTimePeriod domain time-of-day derivation and validation primitive.
class_name TestGardenTimePeriod
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGardenTimePeriod"


func run_tests() -> void:
	_test_canonical_periods_are_valid()
	_test_invalid_periods_rejected()
	_test_period_list_validation()
	_test_hour_of_day_derivation_and_negative_clamping()
	_test_period_for_hour_and_utc_seconds()
	_test_daytime_and_nighttime_helpers()
	_test_next_period_and_seconds_until_next_period()


func _test_canonical_periods_are_valid() -> void:
	describe("All 4 canonical time periods are valid and sorted in ALL_PERIODS")
	var expected: Array[String] = [
		"day",
		"evening",
		"morning",
		"night",
	]
	assert_eq(GardenTimePeriod.ALL_PERIODS, expected, "ALL_PERIODS must match canonical sorted list")
	assert_eq(GardenTimePeriod.get_all_periods(), expected, "get_all_periods() must return canonical sorted list")

	for period_id: String in expected:
		assert_true(
			GardenTimePeriod.is_valid(period_id),
			"Canonical period '%s' must be valid" % period_id
		)


func _test_invalid_periods_rejected() -> void:
	describe("Unknown, empty, cased, or whitespace-padded time periods are rejected")
	var invalid_periods: Array[String] = [
		"",
		"Morning",
		"DAY",
		" morning",
		"night ",
		"afternoon",
		"dawn",
		"dusk",
		"midnight",
	]
	for bad_period: String in invalid_periods:
		assert_false(
			GardenTimePeriod.is_valid(bad_period),
			"Invalid period '%s' must return false" % bad_period
		)


func _test_period_list_validation() -> void:
	describe("is_valid_period_list accepts empty or unique canonical lists and rejects duplicates or invalid periods")
	var empty_list: Array[String] = []
	assert_true(GardenTimePeriod.is_valid_period_list(empty_list), "Empty period list must be valid")

	var single_list: Array[String] = ["morning"]
	assert_true(GardenTimePeriod.is_valid_period_list(single_list), "Single valid period list must be valid")

	var multi_list: Array[String] = ["morning", "day", "evening"]
	assert_true(GardenTimePeriod.is_valid_period_list(multi_list), "Multiple unique valid periods must be valid")

	var duplicate_list: Array[String] = ["morning", "day", "morning"]
	assert_false(
		GardenTimePeriod.is_valid_period_list(duplicate_list),
		"Duplicate period in list must be rejected"
	)

	var invalid_entry_list: Array[String] = ["morning", "afternoon"]
	assert_false(
		GardenTimePeriod.is_valid_period_list(invalid_entry_list),
		"List containing unknown period must be rejected"
	)


func _test_hour_of_day_derivation_and_negative_clamping() -> void:
	describe("hour_of_day_for_utc_seconds derives 0..23 hours deterministically and clamps negative timestamps to 0")
	assert_eq(GardenTimePeriod.hour_of_day_for_utc_seconds(-3600), 0, "Negative timestamp clamps to 0 (hour 0)")
	assert_eq(GardenTimePeriod.hour_of_day_for_utc_seconds(0), 0, "0s is hour 0")
	assert_eq(GardenTimePeriod.hour_of_day_for_utc_seconds(3599), 0, "3599s is still hour 0")
	assert_eq(GardenTimePeriod.hour_of_day_for_utc_seconds(3600), 1, "3600s is hour 1")
	assert_eq(GardenTimePeriod.hour_of_day_for_utc_seconds(6 * 3600), 6, "21600s is hour 6")
	assert_eq(GardenTimePeriod.hour_of_day_for_utc_seconds(23 * 3600 + 3599), 23, "End of day is hour 23")
	assert_eq(GardenTimePeriod.hour_of_day_for_utc_seconds(86400), 0, "86400s wraps to hour 0 of next day")
	assert_eq(
		GardenTimePeriod.hour_of_day_for_utc_seconds(0, 7 * 3600),
		7,
		"UTC+7 offset shifts 0s to hour 7"
	)


func _test_period_for_hour_and_utc_seconds() -> void:
	describe("period_for_hour and period_for_utc_seconds map hours to morning, day, evening, and night")
	# Night: 0..5 and 20..23
	for h: int in [0, 1, 5, 20, 21, 23]:
		assert_eq(GardenTimePeriod.period_for_hour(h), "night", "Hour %d must map to night" % h)
		assert_eq(
			GardenTimePeriod.period_for_utc_seconds(h * 3600),
			"night",
			"Timestamp for hour %d must map to night" % h
		)

	# Morning: 6..10
	for h_m: int in [6, 7, 8, 9, 10]:
		assert_eq(GardenTimePeriod.period_for_hour(h_m), "morning", "Hour %d must map to morning" % h_m)
		assert_eq(
			GardenTimePeriod.period_for_utc_seconds(h_m * 3600),
			"morning",
			"Timestamp for hour %d must map to morning" % h_m
		)

	# Day: 11..16
	for h_d: int in [11, 12, 14, 16]:
		assert_eq(GardenTimePeriod.period_for_hour(h_d), "day", "Hour %d must map to day" % h_d)
		assert_eq(
			GardenTimePeriod.period_for_utc_seconds(h_d * 3600),
			"day",
			"Timestamp for hour %d must map to day" % h_d
		)

	# Evening: 17..19
	for h_e: int in [17, 18, 19]:
		assert_eq(GardenTimePeriod.period_for_hour(h_e), "evening", "Hour %d must map to evening" % h_e)
		assert_eq(
			GardenTimePeriod.period_for_utc_seconds(h_e * 3600),
			"evening",
			"Timestamp for hour %d must map to evening" % h_e
		)

	assert_eq(
		GardenTimePeriod.period_for_utc_seconds(-500),
		"night",
		"Negative timestamp clamps to 0s (night)"
	)


func _test_daytime_and_nighttime_helpers() -> void:
	describe("is_daytime and is_nighttime classify canonical periods accurately")
	assert_true(GardenTimePeriod.is_daytime("morning"), "morning is daytime")
	assert_true(GardenTimePeriod.is_daytime("day"), "day is daytime")
	assert_false(GardenTimePeriod.is_daytime("evening"), "evening is not daytime")
	assert_false(GardenTimePeriod.is_daytime("night"), "night is not daytime")

	assert_true(GardenTimePeriod.is_nighttime("night"), "night is nighttime")
	assert_false(GardenTimePeriod.is_nighttime("morning"), "morning is not nighttime")
	assert_false(GardenTimePeriod.is_nighttime("day"), "day is not nighttime")
	assert_false(GardenTimePeriod.is_nighttime("evening"), "evening is not nighttime")


func _test_next_period_and_seconds_until_next_period() -> void:
	describe("next_period_for_utc_seconds and seconds_until_next_period compute exact chronological transitions")
	assert_eq(GardenTimePeriod.next_period_for_period("morning"), "day", "morning -> day")
	assert_eq(GardenTimePeriod.next_period_for_period("day"), "evening", "day -> evening")
	assert_eq(GardenTimePeriod.next_period_for_period("evening"), "night", "evening -> night")
	assert_eq(GardenTimePeriod.next_period_for_period("night"), "morning", "night -> morning")
	assert_eq(GardenTimePeriod.next_period_for_period("invalid"), "", "invalid -> empty")

	# At t = 0 (00:00 night): 6 hours (21600s) until morning
	assert_eq(GardenTimePeriod.next_period_for_utc_seconds(0), "morning", "At 0s: next is morning")
	assert_eq(GardenTimePeriod.seconds_until_next_period(0), 21600, "At 0s: 21600s until morning")
	assert_eq(GardenTimePeriod.seconds_until_next_period(-500), 21600, "Negative timestamp clamps to 0s (21600s)")

	# At t = 21600 (06:00 morning): 5 hours (18000s) until day (11:00 = 39600s)
	assert_eq(GardenTimePeriod.next_period_for_utc_seconds(21600), "day", "At 21600s: next is day")
	assert_eq(GardenTimePeriod.seconds_until_next_period(21600), 18000, "At 21600s: 18000s until day")

	# At t = 39600 (11:00 day): 6 hours (21600s) until evening (17:00 = 61200s)
	assert_eq(GardenTimePeriod.next_period_for_utc_seconds(39600), "evening", "At 39600s: next is evening")
	assert_eq(GardenTimePeriod.seconds_until_next_period(39600), 21600, "At 39600s: 21600s until evening")

	# At t = 61200 (17:00 evening): 3 hours (10800s) until night (20:00 = 72000s)
	assert_eq(GardenTimePeriod.next_period_for_utc_seconds(61200), "night", "At 61200s: next is night")
	assert_eq(GardenTimePeriod.seconds_until_next_period(61200), 10800, "At 61200s: 10800s until night")

	# At t = 72000 (20:00 night): 10 hours (36000s) until next day's morning (06:00 = 108000s)
	assert_eq(GardenTimePeriod.next_period_for_utc_seconds(72000), "morning", "At 72000s: next is morning")
	assert_eq(GardenTimePeriod.seconds_until_next_period(72000), 36000, "At 72000s: 36000s until morning")

	# Boundary invariant across sample timestamps
	for sample_ts: int in [0, 1234, 21599, 21600, 30000, 39600, 50000, 61200, 71999, 72000, 86399]:
		var cur_p: String = GardenTimePeriod.period_for_utc_seconds(sample_ts)
		var next_p: String = GardenTimePeriod.next_period_for_utc_seconds(sample_ts)
		var rem: int = GardenTimePeriod.seconds_until_next_period(sample_ts)
		assert_eq(
			GardenTimePeriod.period_for_utc_seconds(sample_ts + rem - 1),
			cur_p,
			"1s before boundary at %d remains %s" % [sample_ts, cur_p]
		)
		assert_eq(
			GardenTimePeriod.period_for_utc_seconds(sample_ts + rem),
			next_p,
			"Exact boundary at %d + %d transitions to %s" % [sample_ts, rem, next_p]
		)
