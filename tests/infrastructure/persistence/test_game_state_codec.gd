## test_game_state_codec.gd
## Unit tests for GameStateCodec versioned persistence snapshot encoder and decoder.
##
## Verifies:
## 1. Type contract: RefCounted, pure codec.
## 2. Success tests:
##    - Default empty GameState encode shape (currency: "0", plants: [])
##    - Default GameState decode
##    - Economy-only nonzero balance round trip
##    - Single plant round trip
##    - Multiple plants round trip
##    - Deterministic ascending order of plants by runtime instance ID
##    - Full GameState round trip (currency + multiple plants)
##    - JSON stringify and parse round trip
##    - Int64 fidelity boundary round trips (0, 1, 2^53-1, 2^53, 2^53+1, MAX_INT64)
##    - Planted_at timestamp fidelity boundary round trips
##    - Full max-boundary GameState round trip (MAX_CURRENCY + MAX_INT64 timestamp)
##    - Reconstructed state, EconomyState, and PlantStates are new objects
##    - Encoding does not mutate source GameState
## 3. Failure tests:
##    - Null / non-dictionary snapshot
##    - Missing / invalid / unsupported schema_version (0, 2, strings, fractional floats; accepts 1 and 1.0)
##    - Missing / invalid / negative / overflow / non-canonical decimal strings / numeric currency
##    - Missing / invalid plants array
##    - Missing / invalid / empty plant fields
##    - Missing / invalid / non-canonical decimal strings / numeric planted_at
##    - Invalid definition ID / non-plant namespace
##    - Duplicate runtime instance IDs
##    - Unexpected keys in root, economy, and plant entries
## 4. Determinism tests:
##    - Different insertion order produces identical serialized plant order and JSON string
class_name TestGameStateCodec
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGameStateCodec"


func run_tests() -> void:
	_test_type_contract()
	_test_encode_null_state()
	_test_default_state_encode_and_decode()
	_test_economy_round_trip()
	_test_single_plant_round_trip()
	_test_multiple_plants_round_trip_and_ordering()
	_test_full_game_state_round_trip()
	_test_json_round_trip()
	_test_currency_boundary_round_trips()
	_test_planted_at_boundary_round_trips()
	_test_full_max_boundary_game_state()
	_test_object_independence_and_no_source_mutation()
	_test_determinism_differing_insertion_order()
	_test_failure_root_validation()
	_test_failure_schema_version_validation()
	_test_failure_economy_validation()
	_test_failure_plants_validation()
	_test_failure_duplicate_plant_instance_ids()
	_test_failure_unexpected_keys()


func _test_type_contract() -> void:
	describe("GameStateCodec type contract: RefCounted, not Node, not Resource")
	var codec: GameStateCodec = GameStateCodec.new()
	assert_true(codec != null, "Codec instance must not be null")
	assert_true(codec is GameStateCodec, "Instance must satisfy 'is GameStateCodec'")
	assert_true(codec is RefCounted, "GameStateCodec must extend RefCounted")
	var obj: Variant = codec
	assert_false(obj is Node, "GameStateCodec must not be a Node")
	assert_false(obj is Resource, "GameStateCodec must not be a Resource")
	assert_eq(GameStateCodec.CURRENT_SCHEMA_VERSION, 1, "CURRENT_SCHEMA_VERSION must be 1")


func _test_encode_null_state() -> void:
	describe("Encoding null GameState safely returns empty Dictionary")
	var encoded: Dictionary = GameStateCodec.encode(null)
	assert_eq(encoded.size(), 0, "Encoding null GameState must return empty Dictionary")


func _test_default_state_encode_and_decode() -> void:
	describe("Default empty GameState encodes to valid V1 shape and decodes cleanly")
	var original: GameState = GameState.new()
	var encoded: Dictionary = GameStateCodec.encode(original)

	assert_eq(encoded.get("schema_version"), 1, "Root schema_version must be 1")
	assert_true(encoded.has("economy"), "Root must contain economy")
	assert_true(encoded.has("plants"), "Root must contain plants")

	var economy_data: Variant = encoded.get("economy")
	assert_true(economy_data is Dictionary, "economy must be a Dictionary")
	assert_eq((economy_data as Dictionary).get("currency"), "0", "Default currency must be '0'")

	var plants_data: Variant = encoded.get("plants")
	assert_true(plants_data is Array, "plants must be an Array")
	assert_eq((plants_data as Array).size(), 0, "Default plants array must be empty")

	var decoded: GameState = GameStateCodec.decode(encoded)
	assert_true(decoded != null, "Decoded GameState from default encoded must not be null")
	assert_eq(decoded.get_economy().get_currency(), 0, "Decoded currency must be 0")
	assert_eq(decoded.get_plants().get_count(), 0, "Decoded plants count must be 0")


func _test_economy_round_trip() -> void:
	describe("Economy-only nonzero balance round-trips correctly")
	var original: GameState = GameState.new()
	var grant_ok: bool = original.get_economy().grant_currency(12345)
	assert_true(grant_ok, "Grant currency to original state should succeed")

	var encoded: Dictionary = GameStateCodec.encode(original)
	var economy_data: Variant = encoded.get("economy")
	assert_true(economy_data is Dictionary, "economy must be a Dictionary")
	assert_eq((economy_data as Dictionary).get("currency"), "12345", "Currency must be encoded as string '12345'")

	var decoded: GameState = GameStateCodec.decode(encoded)

	assert_true(decoded != null, "Decoded GameState must not be null")
	assert_eq(decoded.get_economy().get_currency(), 12345, "Currency must match original balance")
	assert_eq(decoded.get_plants().get_count(), 0, "Plant count must remain 0")


func _test_single_plant_round_trip() -> void:
	describe("Single plant round-trips correctly")
	var original: GameState = GameState.new()
	var plant: PlantState = PlantState.new("plant-001", "plant.holy_basil", 1700000000)
	var add_ok: bool = original.get_plants().try_add_plant(plant)
	assert_true(add_ok, "Adding plant to original should succeed")

	var encoded: Dictionary = GameStateCodec.encode(original)
	var plants_data: Array = encoded.get("plants") as Array
	assert_eq(plants_data.size(), 1, "Plants array size must be 1")
	assert_eq((plants_data[0] as Dictionary).get("planted_at"), "1700000000", "planted_at must be encoded as string '1700000000'")

	var decoded: GameState = GameStateCodec.decode(encoded)

	assert_true(decoded != null, "Decoded GameState must not be null")
	assert_eq(decoded.get_plants().get_count(), 1, "Decoded plant count must be 1")
	assert_true(decoded.get_plants().has_runtime_instance_id("plant-001"), "Decoded collection must contain plant-001")

	var decoded_plant: PlantState = decoded.get_plants().get_plant("plant-001")
	assert_true(decoded_plant != null, "Retrieved plant must not be null")
	assert_eq(decoded_plant.get_runtime_instance_id(), "plant-001", "Instance ID must match")
	assert_eq(decoded_plant.get_definition_id(), "plant.holy_basil", "Definition ID must match")
	assert_eq(decoded_plant.get_planted_at(), 1700000000, "Planted_at must match")


func _test_multiple_plants_round_trip_and_ordering() -> void:
	describe("Multiple plants serialize in deterministic ascending order of runtime instance ID")
	var original: GameState = GameState.new()
	# Add in unsorted order: z-999, a-001, m-050
	original.get_plants().try_add_plant(PlantState.new("z-999", "plant.jasmine", 3000))
	original.get_plants().try_add_plant(PlantState.new("a-001", "plant.holy_basil", 1000))
	original.get_plants().try_add_plant(PlantState.new("m-050", "plant.chili", 2000))

	var encoded: Dictionary = GameStateCodec.encode(original)
	var raw_plants: Array = encoded.get("plants") as Array
	assert_eq(raw_plants.size(), 3, "Encoded plants array size must be 3")

	# Check deterministic ascending order in serialized array
	assert_eq((raw_plants[0] as Dictionary).get("instance_id"), "a-001", "First serialized plant must be a-001")
	assert_eq((raw_plants[0] as Dictionary).get("planted_at"), "1000", "First serialized planted_at string")
	assert_eq((raw_plants[1] as Dictionary).get("instance_id"), "m-050", "Second serialized plant must be m-050")
	assert_eq((raw_plants[1] as Dictionary).get("planted_at"), "2000", "Second serialized planted_at string")
	assert_eq((raw_plants[2] as Dictionary).get("instance_id"), "z-999", "Third serialized plant must be z-999")
	assert_eq((raw_plants[2] as Dictionary).get("planted_at"), "3000", "Third serialized planted_at string")

	var decoded: GameState = GameStateCodec.decode(encoded)
	assert_true(decoded != null, "Decoded GameState must not be null")
	assert_eq(decoded.get_plants().get_count(), 3, "Decoded count must be 3")

	var all_decoded: Array[PlantState] = decoded.get_plants().get_all_plants()
	assert_eq(all_decoded[0].get_runtime_instance_id(), "a-001", "Decoded index 0 instance_id")
	assert_eq(all_decoded[0].get_definition_id(), "plant.holy_basil", "Decoded index 0 definition_id")
	assert_eq(all_decoded[0].get_planted_at(), 1000, "Decoded index 0 planted_at")

	assert_eq(all_decoded[1].get_runtime_instance_id(), "m-050", "Decoded index 1 instance_id")
	assert_eq(all_decoded[1].get_definition_id(), "plant.chili", "Decoded index 1 definition_id")
	assert_eq(all_decoded[1].get_planted_at(), 2000, "Decoded index 1 planted_at")

	assert_eq(all_decoded[2].get_runtime_instance_id(), "z-999", "Decoded index 2 instance_id")
	assert_eq(all_decoded[2].get_definition_id(), "plant.jasmine", "Decoded index 2 definition_id")
	assert_eq(all_decoded[2].get_planted_at(), 3000, "Decoded index 2 planted_at")


func _test_full_game_state_round_trip() -> void:
	describe("Full GameState round trip with currency and multiple plants")
	var original: GameState = GameState.new()
	original.get_economy().grant_currency(9876)
	original.get_plants().try_add_plant(PlantState.new("plant-1", "plant.holy_basil", 500))
	original.get_plants().try_add_plant(PlantState.new("plant-2", "plant.chili", 1500))

	var encoded: Dictionary = GameStateCodec.encode(original)
	var decoded: GameState = GameStateCodec.decode(encoded)

	assert_true(decoded != null, "Decoded state must not be null")
	assert_eq(decoded.get_economy().get_currency(), 9876, "Currency must match")
	assert_eq(decoded.get_plants().get_count(), 2, "Plants count must match")
	assert_true(decoded.get_plants().has_runtime_instance_id("plant-1"), "Has plant-1")
	assert_true(decoded.get_plants().has_runtime_instance_id("plant-2"), "Has plant-2")


func _test_json_round_trip() -> void:
	describe("Full JSON stringify and parse round trip preserves all persistent facts")
	var original: GameState = GameState.new()
	original.get_economy().grant_currency(500)
	original.get_plants().try_add_plant(PlantState.new("plant-a", "plant.holy_basil", 1700000000))
	original.get_plants().try_add_plant(PlantState.new("plant-b", "plant.marigold", 1700000500))

	# Encode -> stringify -> parse_string -> decode
	var encoded: Dictionary = GameStateCodec.encode(original)
	var json_string: String = JSON.stringify(encoded)
	var parsed_variant: Variant = JSON.parse_string(json_string)

	assert_true(parsed_variant != null, "Parsed JSON must not be null")
	assert_true(parsed_variant is Dictionary, "Parsed JSON must be Dictionary")

	var decoded: GameState = GameStateCodec.decode(parsed_variant)
	assert_true(decoded != null, "Decoded GameState from parsed JSON must not be null")

	assert_eq(decoded.get_economy().get_currency(), 500, "Decoded currency must be 500")
	assert_eq(decoded.get_plants().get_count(), 2, "Decoded plants count must be 2")

	var p1: PlantState = decoded.get_plants().get_plant("plant-a")
	assert_true(p1 != null, "plant-a must exist")
	assert_eq(p1.get_definition_id(), "plant.holy_basil", "plant-a definition_id")
	assert_eq(p1.get_planted_at(), 1700000000, "plant-a planted_at")

	var p2: PlantState = decoded.get_plants().get_plant("plant-b")
	assert_true(p2 != null, "plant-b must exist")
	assert_eq(p2.get_definition_id(), "plant.marigold", "plant-b definition_id")
	assert_eq(p2.get_planted_at(), 1700000500, "plant-b planted_at")


func _test_currency_boundary_round_trips() -> void:
	describe("Boundary tests: currency values round-trip exactly through JSON stringify/parse")
	var boundary_values: Array[int] = [
		0,
		1,
		9007199254740991,
		9007199254740992,
		9007199254740993,
		EconomyState.MAX_CURRENCY,
	]
	for val: int in boundary_values:
		var original: GameState = GameState.new()
		if val > 0:
			var grant_ok: bool = original.get_economy().grant_currency(val)
			assert_true(grant_ok, "Granting %d currency must succeed" % val)
		var encoded: Dictionary = GameStateCodec.encode(original)
		assert_eq(
			(encoded.get("economy") as Dictionary).get("currency"),
			str(val),
			"Encoded currency for %d must be exact string '%s'" % [val, str(val)]
		)
		var json_text: String = JSON.stringify(encoded)
		var parsed: Variant = JSON.parse_string(json_text)
		assert_true(parsed is Dictionary, "Parsed JSON must be Dictionary for currency %d" % val)
		var decoded: GameState = GameStateCodec.decode(parsed)
		assert_true(decoded != null, "Decoded GameState for currency %d must not be null" % val)
		var decoded_currency: int = decoded.get_economy().get_currency()
		assert_eq(decoded_currency, val, "Decoded currency for %d must equal original exactly" % val)
		assert_eq(typeof(decoded_currency), TYPE_INT, "Decoded currency type must remain TYPE_INT")


func _test_planted_at_boundary_round_trips() -> void:
	describe("Boundary tests: planted_at values round-trip exactly through JSON stringify/parse")
	var boundary_values: Array[int] = [
		0,
		1700000000,
		9007199254740991,
		9007199254740992,
		9007199254740993,
		9223372036854775807,
	]
	for val: int in boundary_values:
		var original: GameState = GameState.new()
		var plant: PlantState = PlantState.new("plant-boundary", "plant.holy_basil", val)
		var add_ok: bool = original.get_plants().try_add_plant(plant)
		assert_true(add_ok, "Adding plant with planted_at %d must succeed" % val)
		var encoded: Dictionary = GameStateCodec.encode(original)
		var raw_plants: Array = encoded.get("plants") as Array
		assert_eq(
			(raw_plants[0] as Dictionary).get("planted_at"),
			str(val),
			"Encoded planted_at for %d must be exact string '%s'" % [val, str(val)]
		)
		var json_text: String = JSON.stringify(encoded)
		var parsed: Variant = JSON.parse_string(json_text)
		assert_true(parsed is Dictionary, "Parsed JSON must be Dictionary for planted_at %d" % val)
		var decoded: GameState = GameStateCodec.decode(parsed)
		assert_true(decoded != null, "Decoded GameState for planted_at %d must not be null" % val)
		var decoded_plant: PlantState = decoded.get_plants().get_plant("plant-boundary")
		assert_true(decoded_plant != null, "Decoded plant must not be null for planted_at %d" % val)
		var decoded_planted_at: int = decoded_plant.get_planted_at()
		assert_eq(decoded_planted_at, val, "Decoded planted_at for %d must equal original exactly" % val)
		assert_eq(typeof(decoded_planted_at), TYPE_INT, "Decoded planted_at type must remain TYPE_INT")


func _test_full_max_boundary_game_state() -> void:
	describe("Full GameState max-boundary JSON round-trip: MAX_CURRENCY + MAX_INT64 planted_at")
	var original: GameState = GameState.new()
	var grant_ok: bool = original.get_economy().grant_currency(EconomyState.MAX_CURRENCY)
	assert_true(grant_ok, "Grant MAX_CURRENCY must succeed")

	var plant: PlantState = PlantState.new("plant-max-bound", "plant.holy_basil", 9223372036854775807)
	var add_ok: bool = original.get_plants().try_add_plant(plant)
	assert_true(add_ok, "Add plant with max planted_at must succeed")

	var encoded: Dictionary = GameStateCodec.encode(original)
	var json_text: String = JSON.stringify(encoded)
	var parsed: Variant = JSON.parse_string(json_text)
	assert_true(parsed is Dictionary, "Parsed JSON must be Dictionary")

	var decoded: GameState = GameStateCodec.decode(parsed)
	assert_true(decoded != null, "Decoded GameState from parsed JSON must not be null")
	assert_eq(decoded.get_economy().get_currency(), EconomyState.MAX_CURRENCY, "Decoded currency must be exact MAX_CURRENCY")
	assert_eq(decoded.get_plants().get_count(), 1, "Decoded plant count must be 1")
	assert_true(decoded.get_plants().has_runtime_instance_id("plant-max-bound"), "Decoded collection must contain plant-max-bound")

	var decoded_plant: PlantState = decoded.get_plants().get_plant("plant-max-bound")
	assert_true(decoded_plant != null, "Retrieved plant must not be null")
	assert_eq(decoded_plant.get_runtime_instance_id(), "plant-max-bound", "Runtime instance ID matches")
	assert_eq(decoded_plant.get_definition_id(), "plant.holy_basil", "Definition ID matches")
	assert_eq(decoded_plant.get_planted_at(), 9223372036854775807, "Planted_at matches max int64 exactly")


func _test_object_independence_and_no_source_mutation() -> void:
	describe("Decoded state slices are new objects and encoding does not mutate source state")
	var original: GameState = GameState.new()
	original.get_economy().grant_currency(100)
	var original_plant: PlantState = PlantState.new("p-1", "plant.holy_basil", 1000)
	original.get_plants().try_add_plant(original_plant)

	var encoded: Dictionary = GameStateCodec.encode(original)

	# Verify source state was not mutated by encode
	assert_eq(original.get_economy().get_currency(), 100, "Original currency intact after encode")
	assert_eq(original.get_plants().get_count(), 1, "Original plant count intact after encode")

	var decoded: GameState = GameStateCodec.decode(encoded)
	assert_true(decoded != null, "Decoded state must not be null")

	# Decoded GameState is distinct instance
	assert_ne(decoded, original, "Decoded GameState must be a distinct object reference")

	# Decoded EconomyState is distinct instance
	assert_ne(decoded.get_economy(), original.get_economy(), "Decoded EconomyState must be distinct object reference")

	# Decoded PlantState is distinct instance
	var decoded_plant: PlantState = decoded.get_plants().get_plant("p-1")
	assert_ne(decoded_plant, original_plant, "Decoded PlantState must be reconstructed, not original reference")

	# Mutating decoded does not mutate original
	decoded.get_economy().grant_currency(50)
	assert_eq(decoded.get_economy().get_currency(), 150, "Decoded balance changed to 150")
	assert_eq(original.get_economy().get_currency(), 100, "Original balance remains 100")


func _test_determinism_differing_insertion_order() -> void:
	describe("Determinism: two GameStates with same plants in different insertion order produce identical serialized JSON")
	var state_1: GameState = GameState.new()
	state_1.get_economy().grant_currency(200)
	state_1.get_plants().try_add_plant(PlantState.new("c-03", "plant.jasmine", 300))
	state_1.get_plants().try_add_plant(PlantState.new("a-01", "plant.holy_basil", 100))
	state_1.get_plants().try_add_plant(PlantState.new("b-02", "plant.chili", 200))

	var state_2: GameState = GameState.new()
	state_2.get_economy().grant_currency(200)
	state_2.get_plants().try_add_plant(PlantState.new("a-01", "plant.holy_basil", 100))
	state_2.get_plants().try_add_plant(PlantState.new("b-02", "plant.chili", 200))
	state_2.get_plants().try_add_plant(PlantState.new("c-03", "plant.jasmine", 300))

	var encoded_1: Dictionary = GameStateCodec.encode(state_1)
	var encoded_2: Dictionary = GameStateCodec.encode(state_2)

	var plants_1: Array = encoded_1.get("plants") as Array
	var plants_2: Array = encoded_2.get("plants") as Array

	assert_eq(plants_1.size(), plants_2.size(), "Plant array sizes must match")
	for i in range(plants_1.size()):
		var dict_1: Dictionary = plants_1[i] as Dictionary
		var dict_2: Dictionary = plants_2[i] as Dictionary
		assert_eq(dict_1.get("instance_id"), dict_2.get("instance_id"), "instance_id at index %d matches" % i)
		assert_eq(dict_1.get("definition_id"), dict_2.get("definition_id"), "definition_id at index %d matches" % i)
		assert_eq(dict_1.get("planted_at"), dict_2.get("planted_at"), "planted_at at index %d matches" % i)

	var json_1: String = JSON.stringify(encoded_1)
	var json_2: String = JSON.stringify(encoded_2)
	assert_eq(json_1, json_2, "Stringified JSON of encoded snapshots must match byte-for-byte")


func _test_failure_root_validation() -> void:
	describe("Root validation rejects null, non-dictionaries, and missing root keys")
	assert_true(GameStateCodec.decode(null) == null, "Reject null")
	assert_true(GameStateCodec.decode(123) == null, "Reject integer root")
	assert_true(GameStateCodec.decode("string") == null, "Reject string root")
	assert_true(GameStateCodec.decode([]) == null, "Reject array root")

	# Missing root keys
	var missing_version: Dictionary = {
		"economy": {"currency": "0"},
		"plants": []
	}
	assert_true(GameStateCodec.decode(missing_version) == null, "Reject missing schema_version")

	var missing_economy: Dictionary = {
		"schema_version": 1,
		"plants": []
	}
	assert_true(GameStateCodec.decode(missing_economy) == null, "Reject missing economy")

	var missing_plants: Dictionary = {
		"schema_version": 1,
		"economy": {"currency": "0"}
	}
	assert_true(GameStateCodec.decode(missing_plants) == null, "Reject missing plants")


func _test_failure_schema_version_validation() -> void:
	describe("Schema version validation accepts 1 and 1.0; rejects 0, 2, 999, fractional floats, strings, booleans, null")
	var valid_base: Dictionary = {
		"schema_version": 1,
		"economy": {"currency": "0"},
		"plants": []
	}

	# Accepted: native integer 1
	var v1_int: Dictionary = valid_base.duplicate(true)
	v1_int["schema_version"] = 1
	assert_true(GameStateCodec.decode(v1_int) != null, "Accept schema_version int 1")

	# Accepted: JSON-deserialized float 1.0
	var v1_float: Dictionary = valid_base.duplicate(true)
	v1_float["schema_version"] = 1.0
	assert_true(GameStateCodec.decode(v1_float) != null, "Accept schema_version float 1.0")

	var v0: Dictionary = valid_base.duplicate(true)
	v0["schema_version"] = 0
	assert_true(GameStateCodec.decode(v0) == null, "Reject schema_version 0")

	var v2: Dictionary = valid_base.duplicate(true)
	v2["schema_version"] = 2
	assert_true(GameStateCodec.decode(v2) == null, "Reject schema_version 2")

	var v999: Dictionary = valid_base.duplicate(true)
	v999["schema_version"] = 999
	assert_true(GameStateCodec.decode(v999) == null, "Reject schema_version 999")

	var v_str: Dictionary = valid_base.duplicate(true)
	v_str["schema_version"] = "1"
	assert_true(GameStateCodec.decode(v_str) == null, "Reject string schema_version '1'")

	var v_float_frac: Dictionary = valid_base.duplicate(true)
	v_float_frac["schema_version"] = 1.5
	assert_true(GameStateCodec.decode(v_float_frac) == null, "Reject fractional float schema_version 1.5")

	var v_bool: Dictionary = valid_base.duplicate(true)
	v_bool["schema_version"] = true
	assert_true(GameStateCodec.decode(v_bool) == null, "Reject boolean schema_version true")

	var v_null: Dictionary = valid_base.duplicate(true)
	v_null["schema_version"] = null
	assert_true(GameStateCodec.decode(v_null) == null, "Reject null schema_version")


func _test_failure_economy_validation() -> void:
	describe("Economy validation rejects non-dict, missing currency, invalid decimal strings, and numeric types")
	var valid_base: Dictionary = {
		"schema_version": 1,
		"economy": {"currency": "0"},
		"plants": []
	}

	var non_dict_eco: Dictionary = valid_base.duplicate(true)
	non_dict_eco["economy"] = 100
	assert_true(GameStateCodec.decode(non_dict_eco) == null, "Reject non-dictionary economy")

	var missing_currency: Dictionary = valid_base.duplicate(true)
	missing_currency["economy"] = {}
	assert_true(GameStateCodec.decode(missing_currency) == null, "Reject missing currency")

	# Rejections for currency: invalid canonical decimal strings and non-string types
	var invalid_currencies: Array = [
		"",
		"00",
		"01",
		"+1",
		"-1",
		" 1",
		"1 ",
		"1.0",
		"1e3",
		"01e2",
		"abc",
		"１２３",
		"9223372036854775808", # overflow
		123,                   # numeric int rejected
		123.0,                 # numeric float rejected
		0,                     # numeric int 0 rejected
		0.0,                   # numeric float 0.0 rejected
		-1,                    # negative numeric rejected
		10.5,                  # fractional float rejected
		true,                  # bool rejected
		false,                 # bool rejected
		null,                  # null rejected
		[],                    # array rejected
		{},                    # dictionary rejected
	]

	for bad_val: Variant in invalid_currencies:
		var bad_eco: Dictionary = valid_base.duplicate(true)
		bad_eco["economy"] = {"currency": bad_val}
		assert_true(
			GameStateCodec.decode(bad_eco) == null,
			"Reject invalid currency: %s (type %d)" % [str(bad_val), typeof(bad_val)]
		)


func _test_failure_plants_validation() -> void:
	describe("Plants validation rejects wrong types, missing fields, invalid IDs, invalid planted_at decimal strings and numerics")
	var valid_base: Dictionary = {
		"schema_version": 1,
		"economy": {"currency": "0"},
		"plants": []
	}

	var non_array_plants: Dictionary = valid_base.duplicate(true)
	non_array_plants["plants"] = {}
	assert_true(GameStateCodec.decode(non_array_plants) == null, "Reject non-array plants")

	var non_dict_entry: Dictionary = valid_base.duplicate(true)
	non_dict_entry["plants"] = ["not_a_dictionary"]
	assert_true(GameStateCodec.decode(non_dict_entry) == null, "Reject non-dictionary plant entry")

	# Missing instance_id
	var missing_inst_id: Dictionary = valid_base.duplicate(true)
	missing_inst_id["plants"] = [{
		"definition_id": "plant.holy_basil",
		"planted_at": "1000"
	}]
	assert_true(GameStateCodec.decode(missing_inst_id) == null, "Reject missing instance_id")

	# Instance ID wrong type (int instead of string)
	var int_inst_id: Dictionary = valid_base.duplicate(true)
	int_inst_id["plants"] = [{
		"instance_id": 123,
		"definition_id": "plant.holy_basil",
		"planted_at": "1000"
	}]
	assert_true(GameStateCodec.decode(int_inst_id) == null, "Reject integer instance_id")

	# Empty instance_id
	var empty_inst_id: Dictionary = valid_base.duplicate(true)
	empty_inst_id["plants"] = [{
		"instance_id": "",
		"definition_id": "plant.holy_basil",
		"planted_at": "1000"
	}]
	assert_true(GameStateCodec.decode(empty_inst_id) == null, "Reject empty instance_id")

	# Missing definition_id
	var missing_def_id: Dictionary = valid_base.duplicate(true)
	missing_def_id["plants"] = [{
		"instance_id": "p-1",
		"planted_at": "1000"
	}]
	assert_true(GameStateCodec.decode(missing_def_id) == null, "Reject missing definition_id")

	# Definition ID wrong type
	var int_def_id: Dictionary = valid_base.duplicate(true)
	int_def_id["plants"] = [{
		"instance_id": "p-1",
		"definition_id": 456,
		"planted_at": "1000"
	}]
	assert_true(GameStateCodec.decode(int_def_id) == null, "Reject integer definition_id")

	# Invalid stable content ID syntax
	var invalid_syntax_def: Dictionary = valid_base.duplicate(true)
	invalid_syntax_def["plants"] = [{
		"instance_id": "p-1",
		"definition_id": "plant..holy_basil",
		"planted_at": "1000"
	}]
	assert_true(GameStateCodec.decode(invalid_syntax_def) == null, "Reject invalid syntax definition_id")

	# Non-plant namespace ID
	var non_plant_def: Dictionary = valid_base.duplicate(true)
	non_plant_def["plants"] = [{
		"instance_id": "p-1",
		"definition_id": "visitor.butterfly",
		"planted_at": "1000"
	}]
	assert_true(GameStateCodec.decode(non_plant_def) == null, "Reject non-plant namespace definition_id")

	# Missing planted_at
	var missing_planted_at: Dictionary = valid_base.duplicate(true)
	missing_planted_at["plants"] = [{
		"instance_id": "p-1",
		"definition_id": "plant.holy_basil"
	}]
	assert_true(GameStateCodec.decode(missing_planted_at) == null, "Reject missing planted_at")

	# Rejections for planted_at: invalid canonical decimal strings and non-string types
	var invalid_planted_at: Array = [
		"",
		"00",
		"01",
		"+1",
		"-1",
		" 1",
		"1 ",
		"1.0",
		"1e3",
		"01e2",
		"abc",
		"１２３",
		"9223372036854775808", # overflow
		1000,                  # numeric int rejected
		1000.0,                # numeric float rejected
		0,                     # numeric int 0 rejected
		0.0,                   # numeric float 0.0 rejected
		-1,                    # negative numeric rejected
		1000.5,                # fractional float rejected
		true,                  # bool rejected
		false,                 # bool rejected
		null,                  # null rejected
		[],                    # array rejected
		{},                    # dictionary rejected
	]

	for bad_val: Variant in invalid_planted_at:
		var bad_plant: Dictionary = valid_base.duplicate(true)
		bad_plant["plants"] = [{
			"instance_id": "p-1",
			"definition_id": "plant.holy_basil",
			"planted_at": bad_val
		}]
		assert_true(
			GameStateCodec.decode(bad_plant) == null,
			"Reject invalid planted_at: %s (type %d)" % [str(bad_val), typeof(bad_val)]
		)


func _test_failure_duplicate_plant_instance_ids() -> void:
	describe("Duplicate plant runtime instance IDs reject the entire snapshot")
	var dup_snapshot: Dictionary = {
		"schema_version": 1,
		"economy": {"currency": "100"},
		"plants": [
			{
				"instance_id": "dup-id",
				"definition_id": "plant.holy_basil",
				"planted_at": "1000"
			},
			{
				"instance_id": "dup-id",
				"definition_id": "plant.chili",
				"planted_at": "2000"
			}
		]
	}
	var decoded: GameState = GameStateCodec.decode(dup_snapshot)
	assert_true(decoded == null, "Duplicate instance IDs must reject the entire snapshot (return null)")


func _test_failure_unexpected_keys() -> void:
	describe("Strict V1 policy: unexpected keys in root, economy, or plant entries are rejected")
	# Unexpected key in root
	var extra_root: Dictionary = {
		"schema_version": 1,
		"economy": {"currency": "0"},
		"plants": [],
		"unexpected_root_key": "bad"
	}
	assert_true(GameStateCodec.decode(extra_root) == null, "Reject unexpected key in root")

	# Unexpected key in economy
	var extra_eco: Dictionary = {
		"schema_version": 1,
		"economy": {
			"currency": "0",
			"extra_eco_key": 999
		},
		"plants": []
	}
	assert_true(GameStateCodec.decode(extra_eco) == null, "Reject unexpected key in economy")

	# Unexpected key in plant entry
	var extra_plant: Dictionary = {
		"schema_version": 1,
		"economy": {"currency": "0"},
		"plants": [
			{
				"instance_id": "p-1",
				"definition_id": "plant.holy_basil",
				"planted_at": "1000",
				"growth_stage": "mature" # derived field strictly forbidden
			}
		]
	}
	assert_true(GameStateCodec.decode(extra_plant) == null, "Reject unexpected key in plant entry (e.g. growth_stage)")
