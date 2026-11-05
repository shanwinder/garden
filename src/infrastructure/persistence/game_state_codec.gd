## game_state_codec.gd
## Versioned GameState snapshot encoder, migrator, and decoder.
##
## GameStateCodec provides pure, deterministic serialization, schema migration (V1 -> V2),
## and deserialization between authoritative runtime GameState instances and JSON-compatible
## snapshot dictionaries.
##
## Architectural rules:
## - Belongs to the infrastructure persistence layer (src/infrastructure/persistence/).
## - Snapshot codec only; NOT file storage or I/O (no FileAccess, DirAccess, user://).
## - GameState remains the authoritative runtime state model.
## - Schema contains only persistent facts; derived plant growth stages and timings
##   are intentionally excluded.
## - Static definition resources (PlantDefinition, VisitorDefinition) are NOT serialized into the snapshot.
## - Current schema contract: CURRENT_SCHEMA_VERSION = 2 (with sequential V1 -> V2 migration).
## - Unsupported schema versions (0, 3, 999, etc.) are strictly rejected.
## - Validates definition IDs structurally (namespace prefix and syntax); catalog existence
##   is validated at the application startup boundary (PlantSaveContentValidator).
## - Pure codec: extends RefCounted; no Node, Resource, singleton, Autoload, SceneTree,
##   GameClock, or RandomSource dependencies.
## - Decode is all-or-nothing: invalid or corrupted data returns null and never exposes
##   a partially reconstructed GameState.
## - Persistent int64 domain values (currency, planted_at, first_seen_at, times_seen) are
##   encoded as canonical decimal Strings to prevent 64-bit float precision loss through
##   Godot JSON stringify/parse.
## - Runtime domain values remain int; string conversion exists only at the persistence wire boundary.
## - schema_version remains a small numeric discriminator (accepts native int 1/2 and JSON-parsed float 1.0/2.0).
class_name GameStateCodec
extends RefCounted

## Supported schema versions.
const SCHEMA_VERSION_V1: int = 1
const SCHEMA_VERSION_V2: int = 2
const CURRENT_SCHEMA_VERSION: int = SCHEMA_VERSION_V2

## Field keys for deterministic root snapshot.
const KEY_SCHEMA_VERSION: String = "schema_version"
const KEY_ECONOMY: String = "economy"
const KEY_PLANTS: String = "plants"
const KEY_DISCOVERIES: String = "discoveries"

## Field keys for economy snapshot.
const KEY_CURRENCY: String = "currency"

## Field keys for plant instance snapshot entries.
const KEY_INSTANCE_ID: String = "instance_id"
const KEY_DEFINITION_ID: String = "definition_id"
const KEY_PLANTED_AT: String = "planted_at"

## Field keys for discovery record snapshot entries (V2+).
const KEY_FIRST_SEEN_AT: String = "first_seen_at"
const KEY_TIMES_SEEN: String = "times_seen"

## Maximum representable signed 64-bit integer in GDScript (2^63 - 1 = 0x7FFFFFFFFFFFFFFF).
const MAX_INT64: int = 9223372036854775807
const MAX_INT64_DIV_10: int = 922337203685477580
const MAX_INT64_MOD_10: int = 7


## Encodes an authoritative [param state] into a JSON-compatible V2 snapshot dictionary.
##
## Requirements and guarantees:
## - Returns a new Dictionary containing only JSON-compatible primitive types (Dictionary, Array, String, int).
## - Persistent int64 domain values (currency, planted_at, first_seen_at, times_seen) are encoded
##   as exact canonical decimal Strings to prevent 64-bit float precision loss through Godot JSON stringify/parse.
## - Plants are serialized in deterministic ascending order of runtime instance ID.
## - Discoveries are serialized in deterministic ascending order of definition ID.
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

	var journal: JournalState = state.get_journal()
	var all_records: Array[DiscoveryRecord] = journal.get_all_records() if journal != null else []
	var discoveries_data: Array = []

	for record: DiscoveryRecord in all_records:
		discoveries_data.append({
			KEY_DEFINITION_ID: record.get_definition_id(),
			KEY_FIRST_SEEN_AT: str(record.get_first_seen_at()),
			KEY_TIMES_SEEN: str(record.get_times_seen()),
		})

	return {
		KEY_SCHEMA_VERSION: CURRENT_SCHEMA_VERSION,
		KEY_ECONOMY: economy_data,
		KEY_PLANTS: plants_data,
		KEY_DISCOVERIES: discoveries_data,
	}


## Deterministically migrates a V1 root snapshot dictionary into a V2 root snapshot dictionary.
##
## Validation and guarantees:
## - Requires [param v1_snapshot] to be a Dictionary with exact V1 root keys
##   (schema_version, economy, plants) and schema_version == 1 (or 1.0).
## - Rejects any V1 dictionary containing unexpected root keys (including "discoveries").
## - Does not mutate [param v1_snapshot].
## - Returns the migrated V2 Dictionary on success, or null if V1 root validation fails.
static func migrate_v1_to_v2(v1_snapshot: Variant) -> Variant:
	if typeof(v1_snapshot) != TYPE_DICTIONARY:
		return null

	var v1_dict: Dictionary = v1_snapshot
	if (
		not v1_dict.has(KEY_SCHEMA_VERSION)
		or not v1_dict.has(KEY_ECONOMY)
		or not v1_dict.has(KEY_PLANTS)
	):
		return null

	for key: Variant in v1_dict.keys():
		if typeof(key) != TYPE_STRING:
			return null
		var key_str: String = key
		if (
			key_str != KEY_SCHEMA_VERSION
			and key_str != KEY_ECONOMY
			and key_str != KEY_PLANTS
		):
			return null

	var version: int = _extract_integral_schema_version(v1_dict[KEY_SCHEMA_VERSION])
	if version != SCHEMA_VERSION_V1:
		return null

	return {
		KEY_SCHEMA_VERSION: SCHEMA_VERSION_V2,
		KEY_ECONOMY: v1_dict[KEY_ECONOMY],
		KEY_PLANTS: v1_dict[KEY_PLANTS],
		KEY_DISCOVERIES: [],
	}


## Decodes a V1 or V2 [param snapshot] into a newly reconstructed GameState.
##
## Validation and guarantees:
## - [param snapshot] must be a Dictionary.
## - schema_version must be an integral JSON number equal to 1 (V1, automatically migrated to V2)
##   or 2 (V2). Rejects unsupported versions (0, 3, 999, strings, booleans, fractional floats).
## - V1 snapshots must have exact V1 root keys (schema_version, economy, plants) before migration.
## - V2 snapshots must have exact V2 root keys (schema_version, economy, plants, discoveries).
## - economy must be a Dictionary with exact allowed keys and canonical decimal String currency.
## - plants must be an Array of Dictionaries with exact allowed keys; duplicate instance_ids rejected.
## - discoveries must be an Array of Dictionaries with exact allowed keys (definition_id,
##   first_seen_at, times_seen); duplicate definition_ids rejected.
## - All-or-nothing: returns null on any validation failure, never returns partial state.
static func decode(snapshot: Variant) -> GameState:
	if typeof(snapshot) != TYPE_DICTIONARY:
		return null

	var input_dict: Dictionary = snapshot
	if not input_dict.has(KEY_SCHEMA_VERSION):
		return null

	var version: int = _extract_integral_schema_version(input_dict[KEY_SCHEMA_VERSION])
	var root_dict: Dictionary
	if version == SCHEMA_VERSION_V1:
		var migrated: Variant = migrate_v1_to_v2(input_dict)
		if typeof(migrated) != TYPE_DICTIONARY:
			return null
		root_dict = migrated
	elif version == SCHEMA_VERSION_V2:
		root_dict = input_dict
	else:
		return null

	# Validate V2 root keys strictly (exact shape, no unexpected keys).
	if (
		not root_dict.has(KEY_SCHEMA_VERSION)
		or not root_dict.has(KEY_ECONOMY)
		or not root_dict.has(KEY_PLANTS)
		or not root_dict.has(KEY_DISCOVERIES)
	):
		return null

	for key: Variant in root_dict.keys():
		if typeof(key) != TYPE_STRING:
			return null
		var key_str: String = key
		if (
			key_str != KEY_SCHEMA_VERSION
			and key_str != KEY_ECONOMY
			and key_str != KEY_PLANTS
			and key_str != KEY_DISCOVERIES
		):
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

	# Validate discoveries array (V2).
	var raw_discoveries: Variant = root_dict[KEY_DISCOVERIES]
	if typeof(raw_discoveries) != TYPE_ARRAY:
		return null

	var discoveries_array: Array = raw_discoveries
	var parsed_discoveries: Array[DiscoveryRecord] = []

	for item: Variant in discoveries_array:
		if typeof(item) != TYPE_DICTIONARY:
			return null

		var disc_dict: Dictionary = item
		if (
			not disc_dict.has(KEY_DEFINITION_ID)
			or not disc_dict.has(KEY_FIRST_SEEN_AT)
			or not disc_dict.has(KEY_TIMES_SEEN)
		):
			return null

		for key: Variant in disc_dict.keys():
			if typeof(key) != TYPE_STRING:
				return null
			var key_str: String = key
			if (
				key_str != KEY_DEFINITION_ID
				and key_str != KEY_FIRST_SEEN_AT
				and key_str != KEY_TIMES_SEEN
			):
				return null

		var raw_disc_def_id: Variant = disc_dict[KEY_DEFINITION_ID]
		var raw_first_seen: Variant = disc_dict[KEY_FIRST_SEEN_AT]
		var raw_times_seen: Variant = disc_dict[KEY_TIMES_SEEN]

		if typeof(raw_disc_def_id) != TYPE_STRING:
			return null

		var parsed_first_seen: Variant = _parse_canonical_non_negative_int(raw_first_seen)
		if parsed_first_seen == null:
			return null

		var parsed_times_seen: Variant = _parse_canonical_non_negative_int(raw_times_seen)
		if parsed_times_seen == null:
			return null

		var first_seen_at: int = parsed_first_seen
		var times_seen: int = parsed_times_seen
		if first_seen_at < 0 or first_seen_at > MAX_INT64:
			return null
		if times_seen < 1 or times_seen > MAX_INT64:
			return null

		var record: DiscoveryRecord = DiscoveryRecord.new(
			raw_disc_def_id,
			first_seen_at,
			times_seen
		)
		if not record.is_valid():
			return null

		parsed_discoveries.append(record)

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

	var journal: JournalState = reconstructed.get_journal()
	for record: DiscoveryRecord in parsed_discoveries:
		var put_ok: bool = journal.try_put_record(record)
		if not put_ok:
			# Duplicate definition_id or domain validation rejection -> reject entire snapshot.
			return null

	return reconstructed


## Extracts an integral schema version (1 or 2) from [param raw_version], or returns -1 if invalid.
static func _extract_integral_schema_version(raw_version: Variant) -> int:
	var val_type: int = typeof(raw_version)
	if val_type == TYPE_INT:
		var v: int = raw_version
		if v == SCHEMA_VERSION_V1 or v == SCHEMA_VERSION_V2:
			return v
		return -1
	if val_type == TYPE_FLOAT:
		var f: float = raw_version
		if is_finite(f) and floor(f) == f:
			var iv: int = int(f)
			if iv == SCHEMA_VERSION_V1 or iv == SCHEMA_VERSION_V2:
				return iv
		return -1
	return -1


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
