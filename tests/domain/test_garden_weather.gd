## test_garden_weather.gd
## Unit tests for Garden's GardenWeather domain weather schedule and validation primitive.
class_name TestGardenWeather
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGardenWeather"


func run_tests() -> void:
	_test_canonical_weather_states_are_valid()
	_test_invalid_weather_states_rejected()
	_test_weather_list_validation()
	_test_deterministic_schedule_and_negative_clamping()
	_test_schedule_covers_all_time_periods_and_weather_states()
	_test_next_weather_and_seconds_until_next_weather()


func _test_canonical_weather_states_are_valid() -> void:
	describe("All 3 canonical MVP weather states are valid and sorted in ALL_WEATHER_STATES")
	var expected: Array[String] = [
		"clear",
		"cloudy",
		"rain",
	]
	assert_eq(GardenWeather.ALL_WEATHER_STATES, expected, "ALL_WEATHER_STATES must match canonical sorted list")
	assert_eq(GardenWeather.get_all_weather_states(), expected, "get_all_weather_states() must return canonical sorted list")

	for weather_id: String in expected:
		assert_true(
			GardenWeather.is_valid(weather_id),
			"Canonical weather '%s' must be valid" % weather_id
		)


func _test_invalid_weather_states_rejected() -> void:
	describe("Unknown, empty, cased, or whitespace-padded weather states are rejected")
	var invalid_states: Array[String] = [
		"",
		"Clear",
		"RAIN",
		" clear",
		"rain ",
		"storm",
		"snow",
		"fog",
		"windy",
	]
	for bad_weather: String in invalid_states:
		assert_false(
			GardenWeather.is_valid(bad_weather),
			"Invalid weather '%s' must return false" % bad_weather
		)


func _test_weather_list_validation() -> void:
	describe("is_valid_weather_list accepts empty or unique canonical lists and rejects duplicates or invalid states")
	var empty_list: Array[String] = []
	assert_true(GardenWeather.is_valid_weather_list(empty_list), "Empty weather list must be valid")

	var single_list: Array[String] = ["rain"]
	assert_true(GardenWeather.is_valid_weather_list(single_list), "Single valid weather list must be valid")

	var multi_list: Array[String] = ["clear", "cloudy", "rain"]
	assert_true(GardenWeather.is_valid_weather_list(multi_list), "Multiple unique valid weather states must be valid")

	var duplicate_list: Array[String] = ["clear", "rain", "clear"]
	assert_false(
		GardenWeather.is_valid_weather_list(duplicate_list),
		"Duplicate weather in list must be rejected"
	)

	var invalid_entry_list: Array[String] = ["clear", "storm"]
	assert_false(
		GardenWeather.is_valid_weather_list(invalid_entry_list),
		"List containing unknown weather must be rejected"
	)


func _test_deterministic_schedule_and_negative_clamping() -> void:
	describe("weather_for_utc_seconds derives O(1) weather state across 2-hour windows and clamps negative timestamps")
	assert_eq(GardenWeather.window_index_for_utc_seconds(-5000), 0, "Negative timestamp clamps to window 0")
	assert_eq(GardenWeather.weather_for_utc_seconds(-5000), "clear", "Negative timestamp clamps to clear")

	# Window 0: [0, 7199] -> clear
	assert_eq(GardenWeather.weather_for_utc_seconds(0), "clear", "0s is clear")
	assert_eq(GardenWeather.weather_for_utc_seconds(7199), "clear", "7199s is clear")

	# Window 1: [7200, 14399] -> cloudy
	assert_eq(GardenWeather.weather_for_utc_seconds(7200), "cloudy", "7200s is cloudy")
	assert_eq(GardenWeather.weather_for_utc_seconds(14399), "cloudy", "14399s is cloudy")

	# Window 2: [14400, 21599] -> rain
	assert_eq(GardenWeather.weather_for_utc_seconds(14400), "rain", "14400s is rain")
	assert_eq(GardenWeather.weather_for_utc_seconds(21599), "rain", "21599s is rain")

	# Window 3: [21600, 28799] -> clear
	assert_eq(GardenWeather.weather_for_utc_seconds(21600), "clear", "21600s is clear")

	# Window 4: [28800, 35999] -> cloudy
	assert_eq(GardenWeather.weather_for_utc_seconds(28800), "cloudy", "28800s is cloudy")

	# Window 5: [36000, 43199] -> wraps cycle to clear
	assert_eq(GardenWeather.weather_for_utc_seconds(36000), "clear", "36000s wraps cycle to clear")


func _test_schedule_covers_all_time_periods_and_weather_states() -> void:
	describe("5-window cycle coprime with 12 windows/day ensures every time period experiences all 3 weather states")
	var seen_pairs: Dictionary = {}
	# Simulate 5 days (60 windows of 2 hours each)
	for window_idx: int in range(60):
		var ts: int = window_idx * GardenWeather.WEATHER_WINDOW_SECONDS
		var period: String = GardenTimePeriod.period_for_utc_seconds(ts)
		var weather: String = GardenWeather.weather_for_utc_seconds(ts)
		seen_pairs["%s|%s" % [period, weather]] = true

	for period_id: String in GardenTimePeriod.ALL_PERIODS:
		for weather_id: String in GardenWeather.ALL_WEATHER_STATES:
			var key: String = "%s|%s" % [period_id, weather_id]
			assert_true(
				seen_pairs.has(key),
				"Schedule must produce combination '%s' within 5 days" % key
			)


func _test_next_weather_and_seconds_until_next_weather() -> void:
	describe("next_weather_for_utc_seconds and seconds_until_next_weather compute exact 2-hour window transitions")
	assert_eq(GardenWeather.next_weather_for_utc_seconds(-500), "cloudy", "Negative timestamp clamps to window 0 -> next is cloudy")
	assert_eq(GardenWeather.seconds_until_next_weather(-500), 7200, "Negative timestamp clamps to 0s -> 7200s remaining")

	assert_eq(GardenWeather.next_weather_for_utc_seconds(0), "cloudy", "Window 0 (clear) -> next is cloudy")
	assert_eq(GardenWeather.seconds_until_next_weather(0), 7200, "At 0s: 7200s until next window")
	assert_eq(GardenWeather.seconds_until_next_weather(7199), 1, "At 7199s: 1s until next window")

	assert_eq(GardenWeather.next_weather_for_utc_seconds(7200), "rain", "Window 1 (cloudy) -> next is rain")
	assert_eq(GardenWeather.seconds_until_next_weather(7200), 7200, "At 7200s: 7200s until next window")

	assert_eq(GardenWeather.next_weather_for_utc_seconds(14400), "clear", "Window 2 (rain) -> next is clear")
	assert_eq(GardenWeather.next_weather_for_utc_seconds(21600), "cloudy", "Window 3 (clear) -> next is cloudy")
	assert_eq(GardenWeather.next_weather_for_utc_seconds(28800), "clear", "Window 4 (cloudy) -> wraps to clear")

	for sample_ts: int in [0, 500, 7199, 7200, 14399, 14400, 21600, 28800, 35999]:
		var cur_w: String = GardenWeather.weather_for_utc_seconds(sample_ts)
		var next_w: String = GardenWeather.next_weather_for_utc_seconds(sample_ts)
		var rem: int = GardenWeather.seconds_until_next_weather(sample_ts)
		assert_eq(
			GardenWeather.weather_for_utc_seconds(sample_ts + rem - 1),
			cur_w,
			"1s before window boundary at %d remains %s" % [sample_ts, cur_w]
		)
		assert_eq(
			GardenWeather.weather_for_utc_seconds(sample_ts + rem),
			next_w,
			"Exact window boundary at %d + %d transitions to %s" % [sample_ts, rem, next_w]
		)
