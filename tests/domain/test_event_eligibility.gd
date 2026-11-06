## test_event_eligibility.gd
## Unit tests for Garden's EventEligibility domain service across all 5 MVP interaction matrix rows.
class_name TestEventEligibility
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestEventEligibility"


func run_tests() -> void:
	_test_null_and_invalid_inputs_rejected()
	_test_mvp_interaction_matrix_five_events()
	_test_filter_eligible_events_preserves_order()


func _make_event(
	id: String,
	trait_counts: Dictionary,
	decorations: Array[String],
	periods: Array[String],
	weathers: Array[String]
) -> EventDefinition:
	var def: EventDefinition = EventDefinition.new()
	def.id = id
	def.weight = 20.0
	def.required_trait_counts = trait_counts
	def.required_decoration_ids = decorations
	def.allowed_time_periods = periods
	def.allowed_weather_states = weathers
	return def


func _test_null_and_invalid_inputs_rejected() -> void:
	describe("EventEligibility safely rejects null or invalid definitions and snapshots")
	var empty: Array[String] = []
	var valid_event: EventDefinition = _make_event(
		"event.morning_butterflies",
		{"flower": 1},
		empty,
		empty,
		empty
	)
	var snapshot: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1},
		{"plant.jasmine": 1},
		1,
		0,
		{},
		0,
		"morning",
		"clear"
	)

	assert_false(EventEligibility.is_eligible(null, snapshot), "Null event definition must return false")
	assert_false(EventEligibility.is_eligible(valid_event, null), "Null snapshot must return false")

	var invalid_event: EventDefinition = EventDefinition.new()
	assert_false(EventEligibility.is_eligible(invalid_event, snapshot), "Invalid event definition must return false")


func _test_mvp_interaction_matrix_five_events() -> void:
	describe("All 5 MVP Interaction Matrix rows match their exact trait, decoration, time-of-day, and weather conditions")
	var empty: Array[String] = []
	var morning_periods: Array[String] = ["morning"]
	var clear_cloudy: Array[String] = ["clear", "cloudy"]
	var morning_butterflies: EventDefinition = _make_event(
		"event.morning_butterflies",
		{"flower": 1},
		empty,
		morning_periods,
		clear_cloudy
	)

	var morning_day: Array[String] = ["morning", "day"]
	var bird_shade_song: EventDefinition = _make_event(
		"event.bird_shade_song",
		{"perch": 1, "shade": 1},
		empty,
		morning_day,
		clear_cloudy
	)

	var bench_decor: Array[String] = ["decoration.bench"]
	var day_evening: Array[String] = ["day", "evening"]
	var cat_sleeping_bench: EventDefinition = _make_event(
		"event.cat_sleeping_bench",
		{"perch": 1, "shelter": 1},
		bench_decor,
		day_evening,
		clear_cloudy
	)

	var night_periods: Array[String] = ["night"]
	var clear_only: Array[String] = ["clear"]
	var firefly_night_glow: EventDefinition = _make_event(
		"event.firefly_night_glow",
		{"dense_vegetation": 1, "light": 1},
		empty,
		night_periods,
		clear_only
	)

	var rain_only: Array[String] = ["rain"]
	var frog_rain_chorus: EventDefinition = _make_event(
		"event.frog_rain_chorus",
		{"water": 1},
		empty,
		empty,
		rain_only
	)

	# Row 1: Jasmine (flower) + Morning -> Butterflies appear
	var snap_morning_flower: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1},
		{"plant.jasmine": 1},
		1,
		0,
		{},
		0,
		"morning",
		"clear"
	)
	assert_true(
		EventEligibility.is_eligible(morning_butterflies, snap_morning_flower),
		"Row 1: Jasmine + Morning + Clear triggers morning_butterflies"
	)
	var snap_night_flower: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1},
		{"plant.jasmine": 1},
		1,
		0,
		{},
		0,
		"night",
		"clear"
	)
	assert_false(
		EventEligibility.is_eligible(morning_butterflies, snap_night_flower),
		"Row 1: Jasmine at Night does not trigger morning_butterflies"
	)

	# Row 2: Banana (shade, perch) + Daytime -> Bird appears and sings
	var snap_day_banana: GardenSnapshot = GardenSnapshot.new(
		{"fruit": 1, "perch": 1, "shade": 1, "shelter": 1},
		{"plant.banana": 1},
		1,
		1,
		{},
		0,
		"day",
		"clear"
	)
	assert_true(
		EventEligibility.is_eligible(bird_shade_song, snap_day_banana),
		"Row 2: Banana + Daytime + Clear triggers bird_shade_song"
	)
	var snap_rain_banana: GardenSnapshot = GardenSnapshot.new(
		{"fruit": 1, "perch": 1, "shade": 1, "shelter": 1},
		{"plant.banana": 1},
		1,
		1,
		{},
		0,
		"day",
		"rain"
	)
	assert_false(
		EventEligibility.is_eligible(bird_shade_song, snap_rain_banana),
		"Row 2: Bird shade song is suppressed during rain"
	)

	# Row 3: Bench + Daytime/Evening -> Cat sleeps on bench
	var snap_bench_evening: GardenSnapshot = GardenSnapshot.new(
		{"perch": 1, "shelter": 1},
		{},
		0,
		0,
		{"decoration.bench": 1},
		1,
		"evening",
		"cloudy"
	)
	assert_true(
		EventEligibility.is_eligible(cat_sleeping_bench, snap_bench_evening),
		"Row 3: Bench + Evening + Cloudy triggers cat_sleeping_bench"
	)
	var snap_no_bench_evening: GardenSnapshot = GardenSnapshot.new(
		{"perch": 1, "shelter": 1},
		{},
		0,
		0,
		{"decoration.small_table": 1},
		1,
		"evening",
		"cloudy"
	)
	assert_false(
		EventEligibility.is_eligible(cat_sleeping_bench, snap_no_bench_evening),
		"Row 3: Without decoration.bench, cat_sleeping_bench is not eligible even if shelter/perch traits exist"
	)

	# Row 4: Garden Lamp (light) + Holy Basil (dense_vegetation) + Night -> Fireflies appear
	var snap_night_lamp_basil: GardenSnapshot = GardenSnapshot.new(
		{"dense_vegetation": 1, "light": 1},
		{"plant.holy_basil": 1},
		1,
		0,
		{"decoration.garden_lamp": 1},
		1,
		"night",
		"clear"
	)
	assert_true(
		EventEligibility.is_eligible(firefly_night_glow, snap_night_lamp_basil),
		"Row 4: Garden Lamp + Holy Basil + Night + Clear triggers firefly_night_glow"
	)

	# Row 5: Small Pond (water) + Rain -> Frog appears and sings
	var snap_rain_pond: GardenSnapshot = GardenSnapshot.new(
		{"water": 1},
		{},
		0,
		0,
		{"decoration.small_pond": 1},
		1,
		"night",
		"rain"
	)
	assert_true(
		EventEligibility.is_eligible(frog_rain_chorus, snap_rain_pond),
		"Row 5: Small Pond + Rain triggers frog_rain_chorus regardless of time period"
	)


func _test_filter_eligible_events_preserves_order() -> void:
	describe("filter_eligible_events preserves candidate order and skips null/ineligible entries")
	var empty: Array[String] = []
	var ev_a: EventDefinition = _make_event("event.a", {"flower": 1}, empty, empty, empty)
	var ev_b: EventDefinition = _make_event("event.b", {"water": 1}, empty, empty, empty)
	var ev_c: EventDefinition = _make_event("event.c", {"shade": 1}, empty, empty, empty)

	var snapshot: GardenSnapshot = GardenSnapshot.new(
		{"flower": 1, "shade": 1},
		{},
		0,
		0,
		{},
		0,
		"morning",
		"clear"
	)
	var candidates: Array[EventDefinition] = [ev_a, null, ev_b, ev_c]
	var eligible: Array[EventDefinition] = EventEligibility.filter_eligible_events(candidates, snapshot)

	assert_eq(eligible.size(), 2, "Exactly 2 events must be eligible")
	assert_eq(eligible[0].id, "event.a", "First eligible event must be event.a")
	assert_eq(eligible[1].id, "event.c", "Second eligible event must be event.c")
