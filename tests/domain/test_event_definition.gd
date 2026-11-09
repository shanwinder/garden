## test_event_definition.gd
## Unit tests for Garden's EventDefinition domain resource and invariants.
class_name TestEventDefinition
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestEventDefinition"


func run_tests() -> void:
	_test_type_contract_and_default_invalid()
	_test_valid_event_definitions()
	_test_invalid_id_rejected()
	_test_invalid_traits_plants_decorations_periods_weather_rejected()
	_test_invalid_weight_and_minimums_rejected()
	_test_secret_flag_and_required_plant_counts()


func _make_valid_event() -> EventDefinition:
	var def: EventDefinition = EventDefinition.new()
	def.id = "event.morning_butterflies"
	def.weight = 30.0
	def.required_trait_counts = {"flower": 1}
	var periods: Array[String] = ["morning"]
	def.allowed_time_periods = periods
	var weathers: Array[String] = ["clear", "cloudy"]
	def.allowed_weather_states = weathers
	def.min_total_plants = 1
	return def


func _test_type_contract_and_default_invalid() -> void:
	describe("EventDefinition extends Resource, is not a Node, and default instance is invalid")
	var def: EventDefinition = EventDefinition.new()
	assert_true(def != null, "Instance must not be null")
	assert_true(def is EventDefinition, "Must be EventDefinition")
	assert_true(def is Resource, "Must extend Resource")
	var obj: Variant = def
	assert_false(obj is Node, "Must not be a Node")
	assert_false(def.is_valid(), "Fresh default EventDefinition must be invalid")


func _test_valid_event_definitions() -> void:
	describe("Valid EventDefinition instances pass is_valid() with trait, decoration, time, and weather requirements")
	var def: EventDefinition = _make_valid_event()
	assert_true(def.is_valid(), "Valid morning_butterflies definition must pass is_valid()")

	var bench_event: EventDefinition = EventDefinition.new()
	bench_event.id = "event.cat_sleeping_bench"
	bench_event.weight = 20.0
	var req_decors: Array[String] = ["decoration.bench"]
	bench_event.required_decoration_ids = req_decors
	var req_periods: Array[String] = ["day", "evening"]
	bench_event.allowed_time_periods = req_periods
	var req_weathers: Array[String] = ["clear", "cloudy"]
	bench_event.allowed_weather_states = req_weathers
	bench_event.min_total_decorations = 1
	assert_true(bench_event.is_valid(), "Valid decoration-requiring event must pass is_valid()")


func _test_invalid_id_rejected() -> void:
	describe("EventDefinition rejects non-event or malformed IDs")
	var bad_ids: Array[String] = [
		"",
		"morning_butterflies",
		"visitor.butterfly",
		"plant.jasmine",
		"decoration.bench",
		"event.",
		"event.Morning",
		"event.bad-id",
	]
	for bad_id: String in bad_ids:
		var def: EventDefinition = _make_valid_event()
		def.id = bad_id
		assert_false(def.is_valid(), "Invalid event id '%s' must be rejected" % bad_id)


func _test_invalid_traits_plants_decorations_periods_weather_rejected() -> void:
	describe("EventDefinition rejects invalid/duplicate traits, plants, decorations, periods, or weather")
	var bad_trait: EventDefinition = _make_valid_event()
	bad_trait.required_trait_counts = {"unknown_trait": 1}
	assert_false(bad_trait.is_valid(), "Unknown required_trait_counts key must be rejected")

	var zero_trait: EventDefinition = _make_valid_event()
	zero_trait.required_trait_counts = {"flower": 0}
	assert_false(zero_trait.is_valid(), "Zero required_trait_counts value must be rejected")

	var bad_plant: EventDefinition = _make_valid_event()
	var bad_plants: Array[String] = ["visitor.butterfly"]
	bad_plant.required_plant_ids = bad_plants
	assert_false(bad_plant.is_valid(), "Non-plant ID in required_plant_ids must be rejected")

	var dup_decor: EventDefinition = _make_valid_event()
	var dup_decors: Array[String] = ["decoration.bench", "decoration.bench"]
	dup_decor.required_decoration_ids = dup_decors
	assert_false(dup_decor.is_valid(), "Duplicate required_decoration_ids must be rejected")

	var bad_decor: EventDefinition = _make_valid_event()
	var bad_decors: Array[String] = ["plant.jasmine"]
	bad_decor.required_decoration_ids = bad_decors
	assert_false(bad_decor.is_valid(), "Non-decoration ID in required_decoration_ids must be rejected")

	var bad_period: EventDefinition = _make_valid_event()
	var bad_periods: Array[String] = ["afternoon"]
	bad_period.allowed_time_periods = bad_periods
	assert_false(bad_period.is_valid(), "Invalid allowed_time_period must be rejected")

	var bad_weather: EventDefinition = _make_valid_event()
	var bad_weathers: Array[String] = ["storm"]
	bad_weather.allowed_weather_states = bad_weathers
	assert_false(bad_weather.is_valid(), "Invalid allowed_weather_state must be rejected")


func _test_invalid_weight_and_minimums_rejected() -> void:
	describe("EventDefinition rejects non-positive/non-finite weights and negative minimum counts")
	var zero_w: EventDefinition = _make_valid_event()
	zero_w.weight = 0.0
	assert_false(zero_w.is_valid(), "Zero weight must be rejected")

	var neg_w: EventDefinition = _make_valid_event()
	neg_w.weight = -1.0
	assert_false(neg_w.is_valid(), "Negative weight must be rejected")

	var nan_w: EventDefinition = _make_valid_event()
	nan_w.weight = NAN
	assert_false(nan_w.is_valid(), "NaN weight must be rejected")

	var inf_w: EventDefinition = _make_valid_event()
	inf_w.weight = INF
	assert_false(inf_w.is_valid(), "Infinite weight must be rejected")

	var neg_plants: EventDefinition = _make_valid_event()
	neg_plants.min_total_plants = -1
	assert_false(neg_plants.is_valid(), "Negative min_total_plants must be rejected")

	var neg_mature: EventDefinition = _make_valid_event()
	neg_mature.min_mature_plants = -1
	assert_false(neg_mature.is_valid(), "Negative min_mature_plants must be rejected")

	var neg_decors: EventDefinition = _make_valid_event()
	neg_decors.min_total_decorations = -1
	assert_false(neg_decors.is_valid(), "Negative min_total_decorations must be rejected")


func _test_secret_flag_and_required_plant_counts() -> void:
	describe("EventDefinition supports secret combination events with validated required_plant_counts")
	var def: EventDefinition = _make_valid_event()
	assert_false(def.is_secret, "is_secret defaults to false")
	assert_eq(def.required_plant_counts, {}, "required_plant_counts defaults to empty")

	var secret: EventDefinition = _make_valid_event()
	secret.id = "event.cat_jasmine_night_rest"
	secret.is_secret = true
	secret.required_plant_counts = {"plant.jasmine": 3}
	assert_true(secret.is_valid(), "Secret event with positive plant count must be valid")

	var bad_counts: Array[Dictionary] = [
		{"plant.jasmine": 0},
		{"plant.jasmine": -2},
		{"plant.jasmine": 3.0},
		{"plant.jasmine": "3"},
		{"decoration.bench": 1},
		{"plant.Jasmine": 1},
		{"plant.": 1},
		{7: 1},
	]
	for bad: Dictionary in bad_counts:
		var invalid: EventDefinition = _make_valid_event()
		invalid.required_plant_counts = bad
		assert_false(invalid.is_valid(), "Invalid required_plant_counts %s must be rejected" % str(bad))
