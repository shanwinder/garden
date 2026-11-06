## test_garden_return_summary.gd
## Unit tests for GardenReturnSummary domain value object.
class_name TestGardenReturnSummary
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGardenReturnSummary"


func run_tests() -> void:
	_test_type_contract()
	_test_valid_return_summaries_and_queries()
	_test_defensive_immutability()
	_test_invalid_summaries_rejected()


func _test_type_contract() -> void:
	describe("GardenReturnSummary extends RefCounted and is not Node or Resource")
	var summary: Variant = GardenReturnSummary.new(
		1000,
		1600,
		600,
		false,
		["plant-1"],
		["plant-1"],
		1,
		GardenTimePeriod.NIGHT,
		GardenTimePeriod.NIGHT,
		GardenWeather.CLEAR,
		GardenWeather.CLEAR
	)
	assert_true(summary is GardenReturnSummary, "Must be GardenReturnSummary")
	assert_true(summary is RefCounted, "Must extend RefCounted")
	assert_false(summary is Node, "Must not be a Node")
	assert_false(summary is Resource, "Must not be a Resource")


func _test_valid_return_summaries_and_queries() -> void:
	describe("Valid GardenReturnSummary exposes accurate away-time, growth, and atmosphere queries")
	# 1. Growth & maturity change
	var s_growth: GardenReturnSummary = GardenReturnSummary.new(
		1000,
		1600,
		600,
		false,
		["inst-a", "inst-b"],
		["inst-a"],
		1,
		GardenTimePeriod.NIGHT,
		GardenTimePeriod.NIGHT,
		GardenWeather.CLEAR,
		GardenWeather.CLEAR
	)
	assert_true(s_growth.is_valid(), "Valid growth summary")
	assert_eq(s_growth.get_previous_utc_seconds(), 1000, "previous_utc_seconds is 1000")
	assert_eq(s_growth.get_current_utc_seconds(), 1600, "current_utc_seconds is 1600")
	assert_eq(s_growth.get_elapsed_seconds(), 600, "elapsed_seconds is 600")
	assert_false(s_growth.was_clock_rolled_back(), "was_clock_rolled_back() false")
	assert_eq(s_growth.get_advanced_plant_ids(), ["inst-a", "inst-b"], "advanced_plant_ids matches")
	assert_eq(s_growth.get_advanced_plant_count(), 2, "advanced_plant_count is 2")
	assert_eq(s_growth.get_newly_matured_plant_ids(), ["inst-a"], "newly_matured_plant_ids matches")
	assert_eq(s_growth.get_newly_matured_plant_count(), 1, "newly_matured_plant_count is 1")
	assert_eq(s_growth.get_ready_to_harvest_count(), 1, "ready_to_harvest_count is 1")
	assert_true(s_growth.has_plant_growth_changes(), "has_plant_growth_changes() true")
	assert_false(s_growth.has_time_period_changed(), "has_time_period_changed() false")
	assert_false(s_growth.has_weather_changed(), "has_weather_changed() false")
	assert_false(s_growth.has_atmosphere_changes(), "has_atmosphere_changes() false")
	assert_true(s_growth.has_meaningful_changes(), "has_meaningful_changes() true")

	# 2. Atmosphere change only (morning -> day, clear -> cloudy)
	var s_atmo: GardenReturnSummary = GardenReturnSummary.new(
		21600,
		43200,
		21600,
		false,
		[],
		[],
		0,
		GardenTimePeriod.MORNING,
		GardenTimePeriod.DAY,
		GardenWeather.CLEAR,
		GardenWeather.CLOUDY
	)
	assert_true(s_atmo.is_valid(), "Valid atmosphere-only summary")
	assert_false(s_atmo.has_plant_growth_changes(), "has_plant_growth_changes() false")
	assert_true(s_atmo.has_time_period_changed(), "has_time_period_changed() true")
	assert_true(s_atmo.has_weather_changed(), "has_weather_changed() true")
	assert_true(s_atmo.has_atmosphere_changes(), "has_atmosphere_changes() true")
	assert_true(s_atmo.has_meaningful_changes(), "has_meaningful_changes() true")

	# 3. Zero elapsed time
	var s_zero: GardenReturnSummary = GardenReturnSummary.new(
		1000,
		1000,
		0,
		false,
		[],
		[],
		0,
		GardenTimePeriod.NIGHT,
		GardenTimePeriod.NIGHT,
		GardenWeather.CLEAR,
		GardenWeather.CLEAR
	)
	assert_true(s_zero.is_valid(), "Valid zero-elapsed summary")
	assert_false(s_zero.has_meaningful_changes(), "Zero elapsed -> no meaningful changes")

	# 4. Clock rollback (current < previous -> clamped elapsed = 0, clock_rolled_back = true)
	var s_rollback: GardenReturnSummary = GardenReturnSummary.new(
		5000,
		3000,
		0,
		true,
		[],
		[],
		0,
		GardenTimePeriod.NIGHT,
		GardenTimePeriod.NIGHT,
		GardenWeather.CLEAR,
		GardenWeather.CLEAR
	)
	assert_true(s_rollback.is_valid(), "Valid clock rollback summary")
	assert_true(s_rollback.was_clock_rolled_back(), "was_clock_rolled_back() true")
	assert_eq(s_rollback.get_elapsed_seconds(), 0, "Elapsed clamped to 0 on rollback")
	assert_false(s_rollback.has_meaningful_changes(), "Clock rollback -> has_meaningful_changes() false")


func _test_defensive_immutability() -> void:
	describe("Mutating input or returned plant ID arrays does not mutate GardenReturnSummary")
	var adv_in: Array[String] = ["inst-1", "inst-2"]
	var mat_in: Array[String] = ["inst-1"]
	var summary: GardenReturnSummary = GardenReturnSummary.new(
		1000,
		2000,
		1000,
		false,
		adv_in,
		mat_in,
		1,
		GardenTimePeriod.NIGHT,
		GardenTimePeriod.NIGHT,
		GardenWeather.CLEAR,
		GardenWeather.CLEAR
	)
	adv_in.append("inst-99")
	mat_in.append("inst-99")
	assert_eq(summary.get_advanced_plant_ids(), ["inst-1", "inst-2"], "Input mutation ignored")
	assert_eq(summary.get_newly_matured_plant_ids(), ["inst-1"], "Input mature mutation ignored")

	var adv_out: Array[String] = summary.get_advanced_plant_ids()
	var mat_out: Array[String] = summary.get_newly_matured_plant_ids()
	adv_out.clear()
	mat_out.clear()
	assert_eq(summary.get_advanced_plant_count(), 2, "Returned array mutation ignored")
	assert_eq(summary.get_newly_matured_plant_count(), 1, "Returned mature array mutation ignored")


func _test_invalid_summaries_rejected() -> void:
	describe("Invalid timestamps, mismatched elapsed/rollback, unsorted IDs, or non-subset mature IDs fail is_valid()")
	# Negative previous_utc_seconds
	var bad_prev: GardenReturnSummary = GardenReturnSummary.new(
		-1, 100, 101, false, [], [], 0, "night", "night", "clear", "clear"
	)
	assert_false(bad_prev.is_valid(), "Negative previous_utc_seconds rejected")

	# Mismatched elapsed_seconds
	var bad_elapsed: GardenReturnSummary = GardenReturnSummary.new(
		100, 200, 50, false, [], [], 0, "night", "night", "clear", "clear"
	)
	assert_false(bad_elapsed.is_valid(), "Mismatched elapsed_seconds rejected")

	# Mismatched clock_rolled_back flag
	var bad_rollback: GardenReturnSummary = GardenReturnSummary.new(
		200, 100, 0, false, [], [], 0, "night", "night", "clear", "clear"
	)
	assert_false(bad_rollback.is_valid(), "False rollback flag when current < previous rejected")

	# Advanced plant IDs present during clock rollback
	var bad_rollback_adv: GardenReturnSummary = GardenReturnSummary.new(
		200, 100, 0, true, ["inst-1"], [], 0, "night", "night", "clear", "clear"
	)
	assert_false(bad_rollback_adv.is_valid(), "Advanced plants during clock rollback rejected")

	# Unsorted advanced_plant_ids
	var bad_order: GardenReturnSummary = GardenReturnSummary.new(
		100, 200, 100, false, ["inst-b", "inst-a"], [], 0, "night", "night", "clear", "clear"
	)
	assert_false(bad_order.is_valid(), "Unsorted advanced_plant_ids rejected")

	# Newly matured ID not in advanced_plant_ids
	var bad_subset: GardenReturnSummary = GardenReturnSummary.new(
		100, 200, 100, false, ["inst-a"], ["inst-b"], 1, "night", "night", "clear", "clear"
	)
	assert_false(bad_subset.is_valid(), "Mature ID outside advanced_plant_ids rejected")

	# Invalid time period or weather state
	var bad_atmo: GardenReturnSummary = GardenReturnSummary.new(
		100, 200, 100, false, [], [], 0, "invalid_period", "night", "clear", "clear"
	)
	assert_false(bad_atmo.is_valid(), "Invalid time period rejected")
