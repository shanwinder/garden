## game_state_codec.gd
## Versioned GameState snapshot encoder and decoder.
##
## GameStateCodec provides pure, deterministic serialization and deserialization
## between authoritative runtime GameState instances and JSON-compatible snapshot dictionaries.
##
## Architectural rules:
## - Belongs to the infrastructure persistence layer (src/infrastructure/persistence/).
## - Snapshot codec only; NOT file storage or I/O (no FileAccess, DirAccess, user://).
## - GameState remains the authoritative runtime state model.
## - Schema contains only persistent facts; derived plant growth stages and timings
##   are intentionally excluded.
## - Static definition resources (PlantDefinition) are NOT serialized into the snapshot.
## - Strict V1 contract: CURRENT_SCHEMA_VERSION = 1.
## - Unsupported schema versions are strictly rejected; no schema migration exists yet.
## - Validates definition IDs structurally (namespace prefix and syntax); no ContentCatalog
##   lookup exists yet as ContentCatalog is not implemented.
## - Pure codec: extends RefCounted; no Node, Resource, singleton, Autoload, SceneTree,
##   GameClock, or RandomSource dependencies.
## - Decode is all-or-nothing: invalid or corrupted data returns null and never exposes
##   a partially reconstructed GameState.
## - JSON number is not a safe lossless wire representation for arbitrary Garden int64
##   persistent facts under Godot's JSON implementation (Godot JSON parses numbers as 64-bit float).
## - Persistent int64 domain values (currency, planted_at) are encoded as canonical decimal Strings
##   to prevent 64-bit float precision loss through Godot JSON stringify/parse.
## - Runtime domain values remain int; string conversion exists only at the persistence wire boundary.
## - schema_version remains a small numeric discriminator (accepts native int 1 and JSON-parsed float 1.0).
## - No schema migration exists because V1 has not yet reached filesystem persistence.
class_name GameStateCodec
extends RefCounted

## Supported schema version for V1 persistence snapshot.
const CURRENT_SCHEMA_VERSION: int = 1

## Field keys for deterministic root snapshot.
const KEY_SCHEMA_VERSION: String = "schema_version"
const KEY_ECONOMY: String = "economy"
const KEY_PLANTS: String = "plants"

## Field keys for economy snapshot.
const KEY_CURRENCY: String = "currency"

## Field keys for plant instance snapshot entries.
const KEY_INSTANCE_ID: String = "instance_id"
const KEY_DEFINITION_ID: String = "definition_id"
const KEY_PLANTED_AT: String = "planted_at"

## Maximum representable signed 64-bit integer in GDScript (2^63 - 1 = 0x7FFFFFFFFFFFFFFF).
const MAX_INT64: int = 9223372036854775807
const MAX_INT64_DIV_10: int = 922337203685477580
const MAX_INT64_MOD_10: int = 7


## Encodes an authoritative [param state] into a JSON-compatible V1 snapshot dictionary.
##
## Requirements and guarantees:
## - Returns a new Dictionary containing only JSON-compatible primitive types (Dictionary, Array, String, int).
## - Persistent int64 domain values (currency, planted_at) are encoded as exact canonical decimal Strings
##   to prevent 64-bit float precision loss through Godot JSON stringify/parse.
## - Plants are serialized in deterministic ascending order of runtime instance ID.
## - Does not serialize derived growth data or static definition resources.
## - Does not mutate [param state].
## - If [param state] is null, returns an empty Dictionary without crashing.
static func encode(state: GameState) -> Dictionary:
	if state == null:
		return {}

	var economy: EconomyState = state.get_economy()
	var economy_data: Dictionary = {
		KEY_CURRENCY: str(economy.get_currency()),
	}

	var plants_collection: PlantCollectionState = state.get_plants()
	var all_plants: Array[PlantState] = plants_collection.get_all_plants()
	var plants_data: Array = []

	for plant: PlantState in all_plants:
		plants_data.append({
			KEY_INSTANCE_ID: plant.get_runtime_instance_id(),
			KEY_DEFINITION_ID: plant.get_definition_id(),
			KEY_PLANTED_AT: str(plant.get_planted_at()),
		})

	return {
		KEY_SCHEMA_VERSION: CURRENT_SCHEMA_VERSION,
		KEY_ECONOMY: economy_data,
		KEY_PLANTS: plants_data,
	}


## Decodes a [param snapshot] into a newly reconstructed GameState.
##
## Validation and guarantees:
## - [param snapshot] must be a Dictionary with exact allowed root keys.
## - schema_version must be an integral JSON number exactly equal to 1 (accepts native int 1
##   and JSON-deserialized float 1.0; rejects unsupported versions, 0, 2, strings, booleans, fractional floats).
## - economy must be a Dictionary with exact allowed keys and canonical decimal String currency.
## - currency must be a canonical decimal String satisfying 0 <= currency <= EconomyState.MAX_CURRENCY.
## - Numeric currency (int, float) is strictly rejected to enforce string wire fidelity.
## - plants must be an Array of Dictionaries with exact allowed keys.
## - planted_at must be a canonical decimal String satisfying 0 <= planted_at <= MAX_INT64.
## - Numeric planted_at (int, float) is strictly rejected to enforce string wire fidelity.
## - Each plant entry must satisfy PlantState.is_valid().
## - Duplicate runtime instance IDs reject the entire snapshot.
## - Unknown/unexpected keys in root, economy, or plant objects are rejected.
## - All-or-nothing: returns null on any validation failure, never returns partial state.
## - Does not throw fatal errors or crash on corrupted save data.
static func decode(snapshot: Variant) -> GameState:
	if typeof(snapshot) != TYPE_DICTIONARY:
		return null

	var root_dict: Dictionary = snapshot

	# Validate root keys strictly (exact shape, no unexpected keys).
	if not root_dict.has(KEY_SCHEMA_VERSION) or not root_dict.has(KEY_ECONOMY) or not root_dict.has(KEY_PLANTS):
		return null

	for key: Variant in root_dict.keys():
		if typeof(key) != TYPE_STRING:
			return null
		var key_str: String = key
		if key_str != KEY_SCHEMA_VERSION and key_str != KEY_ECONOMY and key_str != KEY_PLANTS:
			return null

	# Validate schema_version (accepts int 1 or JSON-parsed float 1.0).
	var raw_version: Variant = root_dict[KEY_SCHEMA_VERSION]
	if not _is_valid_schema_version(raw_version):
		return null

	# Validate economy dictionary.
	var raw_economy: Variant = root_dict[KEY_ECONOMY]
	if typeof(raw_economy) != TYPE_DICTIONARY:
		return null

	var economy_dict: Dictionary = raw_economy
	if not economy_dict.has(KEY_CURRENCY):
		return null

	for key: Variant in economy_dict.keys():
		if typeof(key) != TYPE_STRING:
			return null
		var key_str: String = key
		if key_str != KEY_CURRENCY:
			return null

	var raw_currency: Variant = economy_dict[KEY_CURRENCY]
	var parsed_currency: Variant = _parse_canonical_non_negative_int(raw_currency)
	if parsed_currency == null:
		return null

	var currency: int = parsed_currency
	if currency < 0 or currency > EconomyState.MAX_CURRENCY:
		return null

	# Validate plants array.
	var raw_plants: Variant = root_dict[KEY_PLANTS]
	if typeof(raw_plants) != TYPE_ARRAY:
		return null

	var plants_array: Array = raw_plants
	var parsed_plants: Array[PlantState] = []

	for item: Variant in plants_array:
		if typeof(item) != TYPE_DICTIONARY:
			return null

		var plant_dict: Dictionary = item
		if (
			not plant_dict.has(KEY_INSTANCE_ID)
			or not plant_dict.has(KEY_DEFINITION_ID)
			or not plant_dict.has(KEY_PLANTED_AT)
		):
			return null

		for key: Variant in plant_dict.keys():
			if typeof(key) != TYPE_STRING:
				return null
			var key_str: String = key
			if (
				key_str != KEY_INSTANCE_ID
				and key_str != KEY_DEFINITION_ID
				and key_str != KEY_PLANTED_AT
			):
				return null

		var raw_instance_id: Variant = plant_dict[KEY_INSTANCE_ID]
		var raw_definition_id: Variant = plant_dict[KEY_DEFINITION_ID]
		var raw_planted_at: Variant = plant_dict[KEY_PLANTED_AT]

		if typeof(raw_instance_id) != TYPE_STRING:
			return null
		if typeof(raw_definition_id) != TYPE_STRING:
			return null

		var parsed_planted_at: Variant = _parse_canonical_non_negative_int(raw_planted_at)
		if parsed_planted_at == null:
			return null

		var planted_at: int = parsed_planted_at
		if planted_at < 0 or planted_at > MAX_INT64:
			return null

		var plant_state: PlantState = PlantState.new(
			raw_instance_id,
			raw_definition_id,
			planted_at
		)

		if not plant_state.is_valid():
			return null

		parsed_plants.append(plant_state)

	# Reconstruct GameState atomically using authoritative domain methods.
	var reconstructed: GameState = GameState.new()

	if currency > 0:
		var grant_ok: bool = reconstructed.get_economy().grant_currency(currency)
		if not grant_ok:
			return null

	var collection: PlantCollectionState = reconstructed.get_plants()
	for plant: PlantState in parsed_plants:
		var add_ok: bool = collection.try_add_plant(plant)
		if not add_ok:
			# Duplicate instance_id or domain validation rejection -> reject entire snapshot.
			return null

	return reconstructed


## Validates that [param raw_version] is an integral numeric value representing CURRENT_SCHEMA_VERSION.
## Accepts native int 1 and JSON-deserialized float 1.0.
## Rejects boolean, string, null, NaN, INF, unsupported versions (0, 2), and non-integral floats.
static func _is_valid_schema_version(raw_version: Variant) -> bool:
	var val_type: int = typeof(raw_version)
	if val_type == TYPE_INT:
		return raw_version == CURRENT_SCHEMA_VERSION
	if val_type == TYPE_FLOAT:
		var f: float = raw_version
		return is_finite(f) and floor(f) == f and int(f) == CURRENT_SCHEMA_VERSION
	return false


## Parses a canonical non-negative integer decimal string into an [code]int[/code].
##
## Requirements and guarantees:
## - Requires TYPE_STRING.
## - Accepts exactly "0" or "1"-"9" followed by zero or more "0"-"9" digits (ASCII only).
## - Detects signed 64-bit integer overflow BEFORE multiplication and addition.
## - Never converts through float.
## - Never silently clamps or saturates.
## - Returns the parsed [code]int[/code] on success, or [code]null[/code] on any validation/overflow failure.
static func _parse_canonical_non_negative_int(value: Variant) -> Variant:
	if typeof(value) != TYPE_STRING:
		return null

	var text: String = value
	var length: int = text.length()
	if length == 0:
		return null

	# "0" is the only valid number with leading zero.
	if text == "0":
		return 0

	# Any other valid canonical number must start with '1'..'9'.
	var first_code: int = text.unicode_at(0)
	if first_code < 49 or first_code > 57: # ASCII '1' to '9'
		return null

	var result: int = 0
	for i in range(length):
		var code: int = text.unicode_at(i)
		if code < 48 or code > 57: # ASCII '0' to '9'
			return null
		var digit: int = code - 48
		if result > MAX_INT64_DIV_10 or (result == MAX_INT64_DIV_10 and digit > MAX_INT64_MOD_10):
			return null
		result = result * 10 + digit

	return result
