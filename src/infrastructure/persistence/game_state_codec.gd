## game_state_codec.gd
## Versioned GameState snapshot encoder, migrator, and decoder.
##
## GameStateCodec provides pure, deterministic serialization, schema migration (V1 -> V2 -> V3),
## and deserialization between authoritative runtime GameState instances and JSON-compatible
## snapshot dictionaries.
##
## Architectural rules:
## - Belongs to the infrastructure persistence layer (src/infrastructure/persistence/).
## - Snapshot codec only; NOT file storage or I/O (no FileAccess, DirAccess, user://).
## - GameState remains the authoritative runtime state model.
## - Schema contains only persistent facts; derived plant growth stages and timings
##   are intentionally excluded.
## - Static definition resources (PlantDefinition, VisitorDefinition, DecorationDefinition)
##   are NOT serialized into the snapshot.
## - Current schema contract: CURRENT_SCHEMA_VERSION = 3 (with sequential V1 -> V2 -> V3 migration).
## - Unsupported schema versions (0, 4, 999, etc.) are strictly rejected.
## - Validates definition IDs structurally (namespace prefix and syntax); catalog existence
##   is validated at the application startup boundary (PlantSaveContentValidator).
## - Pure codec: extends RefCounted; no Node, Resource, singleton, Autoload, SceneTree,
##   GameClock, or RandomSource dependencies.
## - Decode is all-or-nothing: invalid or corrupted data returns null and never exposes
##   a partially reconstructed GameState.
## - Persistent int64 domain values (currency, planted_at, first_seen_at, times_seen, placed_at) are
##   encoded as canonical decimal Strings to prevent 64-bit float precision loss through
##   Godot JSON stringify/parse.
## - Runtime domain values remain int; string conversion exists only at the persistence wire boundary.
## - schema_version remains a small numeric discriminator (accepts native int 1/2/3 and JSON-parsed float 1.0/2.0/3.0).
class_name GameStateCodec
extends RefCounted

## Supported schema versions.
const SCHEMA_VERSION_V1: int = 1
const SCHEMA_VERSION_V2: int = 2
const SCHEMA_VERSION_V3: int = 3
const CURRENT_SCHEMA_VERSION: int = SCHEMA_VERSION_V3

## Field keys for deterministic root snapshot.
const KEY_SCHEMA_VERSION: String = "schema_version"
const KEY_ECONOMY: String = "economy"
const KEY_PLANTS: String = "plants"
const KEY_DISCOVERIES: String = "discoveries"
const KEY_DECORATIONS: String = "decorations"

## Field keys for economy snapshot.
const KEY_CURRENCY: String = "currency"

## Field keys for plant and decoration instance snapshot entries.
const KEY_INSTANCE_ID: String = "instance_id"
const KEY_DEFINITION_ID: String = "definition_id"
const KEY_PLANTED_AT: String = "planted_at"
const KEY_PLACED_AT: String = "placed_at"

## Field keys for discovery record snapshot entries (V2+).
const KEY_FIRST_SEEN_AT: String = "first_seen_at"
const KEY_TIMES_SEEN: String = "times_seen"

## Maximum representable signed 64-bit integer in GDScript (2^63 - 1 = 0x7FFFFFFFFFFFFFFF).
const MAX_INT64: int = 9223372036854775807
const MAX_INT64_DIV_10: int = 922337203685477580
const MAX_INT64_MOD_10: int = 7


## Encodes an authoritative [param state] into a JSON-compatible V3 snapshot dictionary.
##
## Requirements and guarantees:
## - Returns a new Dictionary containing only JSON-compatible primitive types (Dictionary, Array, String, int).
## - Persistent int64 domain values (currency, planted_at, first_seen_at, times_seen, placed_at) are encoded
##   as exact canonical decimal Strings to prevent 64-bit float precision loss through Godot JSON stringify/parse.
## - Plants are serialized in deterministic ascending order of runtime instance ID.
## - Discoveries are serialized in deterministic ascending order of definition ID.
## - Decorations are serialized in deterministic ascending order of runtime instance ID.
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

	var decorations_collection: DecorationCollectionState = state.get_decorations()
	var all_decorations: Array[DecorationState] = (
		decorations_collection.get_all_decorations() if decorations_collection != null else []
	)
	var decorations_data: Array = []

	for decoration: DecorationState in all_decorations:
		decorations_data.append({
			KEY_INSTANCE_ID: decoration.get_runtime_instance_id(),
			KEY_DEFINITION_ID: decoration.get_definition_id(),
			KEY_PLACED_AT: str(decoration.get_placed_at()),
		})

	return {
		KEY_SCHEMA_VERSION: CURRENT_SCHEMA_VERSION,
		KEY_ECONOMY: economy_data,
		KEY_PLANTS: plants_data,
		KEY_DISCOVERIES: discoveries_data,
		KEY_DECORATIONS: decorations_data,
	}


## Deterministically migrates a V1 root snapshot dictionary into a V2 root snapshot dictionary.
##
## Validation and guarantees:
## - Requires [param v1_snapshot] to be a Dictionary with exact V1 root keys
##   (schema_version, economy, plants) and schema_version == 1 (or 1.0).
## - Rejects any V1 dictionary containing unexpected root keys (including "discoveries" or "decorations").
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


## Deterministically migrates a V2 root snapshot dictionary into a V3 root snapshot dictionary.
##
## Validation and guarantees:
## - Requires [param v2_snapshot] to be a Dictionary with exact V2 root keys
##   (schema_version, economy, plants, discoveries) and schema_version == 2 (or 2.0).
## - Rejects any V2 dictionary containing unexpected root keys (including "decorations").
## - Does not mutate [param v2_snapshot].
## - Returns the migrated V3 Dictionary on success, or null if V2 root validation fails.
static func migrate_v2_to_v3(v2_snapshot: Variant) -> Variant:
	if typeof(v2_snapshot) != TYPE_DICTIONARY:
		return null

	var v2_dict: Dictionary = v2_snapshot
	if (
		not v2_dict.has(KEY_SCHEMA_VERSION)
		or not v2_dict.has(KEY_ECONOMY)
		or not v2_dict.has(KEY_PLANTS)
		or not v2_dict.has(KEY_DISCOVERIES)
	):
		return null

	for key: Variant in v2_dict.keys():
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

	var version: int = _extract_integral_schema_version(v2_dict[KEY_SCHEMA_VERSION])
	if version != SCHEMA_VERSION_V2:
		return null

	return {
		KEY_SCHEMA_VERSION: SCHEMA_VERSION_V3,
		KEY_ECONOMY: v2_dict[KEY_ECONOMY],
		KEY_PLANTS: v2_dict[KEY_PLANTS],
		KEY_DISCOVERIES: v2_dict[KEY_DISCOVERIES],
		KEY_DECORATIONS: [],
	}


## Decodes a V1, V2, or V3 [param snapshot] into a newly reconstructed GameState.
##
## Validation and guarantees:
## - [param snapshot] must be a Dictionary.
## - schema_version must be an integral JSON number equal to 1 (migrated V1 -> V2 -> V3),
##   2 (migrated V2 -> V3), or 3 (V3). Rejects unsupported versions (0, 4, 999, strings, booleans, fractional floats).
## - V1 snapshots must have exact V1 root keys (schema_version, economy, plants) before migration.
## - V2 snapshots must have exact V2 root keys (schema_version, economy, plants, discoveries) before migration.
## - V3 snapshots must have exact V3 root keys (schema_version, economy, plants, discoveries, decorations).
## - economy must be a Dictionary with exact allowed keys and canonical decimal String currency.
## - plants must be an Array of Dictionaries with exact allowed keys; duplicate instance_ids rejected.
## - discoveries must be an Array of Dictionaries with exact allowed keys (definition_id,
##   first_seen_at, times_seen); duplicate definition_ids rejected.
## - decorations must be an Array of Dictionaries with exact allowed keys (instance_id,
##   definition_id, placed_at); duplicate instance_ids rejected.
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
		var migrated_v2: Variant = migrate_v1_to_v2(input_dict)
		if typeof(migrated_v2) != TYPE_DICTIONARY:
			return null
		var migrated_v3: Variant = migrate_v2_to_v3(migrated_v2)
		if typeof(migrated_v3) != TYPE_DICTIONARY:
			return null
		root_dict = migrated_v3
	elif version == SCHEMA_VERSION_V2:
		var migrated_from_v2: Variant = migrate_v2_to_v3(input_dict)
		if typeof(migrated_from_v2) != TYPE_DICTIONARY:
			return null
		root_dict = migrated_from_v2
	elif version == SCHEMA_VERSION_V3:
		root_dict = input_dict
	else:
		return null

	# Validate V3 root keys strictly (exact shape, no unexpected keys).
	if (
		not root_dict.has(KEY_SCHEMA_VERSION)
		or not root_dict.has(KEY_ECONOMY)
		or not root_dict.has(KEY_PLANTS)
		or not root_dict.has(KEY_DISCOVERIES)
		or not root_dict.has(KEY_DECORATIONS)
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
			and key_str != KEY_DECORATIONS
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

	# Validate decorations array (V3).
	var raw_decorations: Variant = root_dict[KEY_DECORATIONS]
	if typeof(raw_decorations) != TYPE_ARRAY:
		return null

	var decorations_array: Array = raw_decorations
	var parsed_decorations: Array[DecorationState] = []

	for item: Variant in decorations_array:
		if typeof(item) != TYPE_DICTIONARY:
			return null

		var decor_dict: Dictionary = item
		if (
			not decor_dict.has(KEY_INSTANCE_ID)
			or not decor_dict.has(KEY_DEFINITION_ID)
			or not decor_dict.has(KEY_PLACED_AT)
		):
			return null

		for key: Variant in decor_dict.keys():
			if typeof(key) != TYPE_STRING:
				return null
			var key_str: String = key
			if (
				key_str != KEY_INSTANCE_ID
				and key_str != KEY_DEFINITION_ID
				and key_str != KEY_PLACED_AT
			):
				return null

		var raw_decor_instance_id: Variant = decor_dict[KEY_INSTANCE_ID]
		var raw_decor_def_id: Variant = decor_dict[KEY_DEFINITION_ID]
		var raw_placed_at: Variant = decor_dict[KEY_PLACED_AT]

		if typeof(raw_decor_instance_id) != TYPE_STRING:
			return null
		if typeof(raw_decor_def_id) != TYPE_STRING:
			return null

		var parsed_placed_at: Variant = _parse_canonical_non_negative_int(raw_placed_at)
		if parsed_placed_at == null:
			return null

		var placed_at: int = parsed_placed_at
		if placed_at < 0 or placed_at > MAX_INT64:
			return null

		var decoration_state: DecorationState = DecorationState.new(
			raw_decor_instance_id,
			raw_decor_def_id,
			placed_at
		)
		if not decoration_state.is_valid():
			return null

		parsed_decorations.append(decoration_state)

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

	var decorations_collection: DecorationCollectionState = reconstructed.get_decorations()
	for decoration: DecorationState in parsed_decorations:
		var add_decor_ok: bool = decorations_collection.try_add_decoration(decoration)
		if not add_decor_ok:
			# Duplicate instance_id or domain validation rejection -> reject entire snapshot.
			return null

	return reconstructed


## Extracts an integral schema version (1, 2, or 3) from [param raw_version], or returns -1 if invalid.
static func _extract_integral_schema_version(raw_version: Variant) -> int:
	var val_type: int = typeof(raw_version)
	if val_type == TYPE_INT:
		var v: int = raw_version
		if v == SCHEMA_VERSION_V1 or v == SCHEMA_VERSION_V2 or v == SCHEMA_VERSION_V3:
			return v
		return -1
	if val_type == TYPE_FLOAT:
		var f: float = raw_version
		if is_finite(f) and floor(f) == f:
			var iv: int = int(f)
			if iv == SCHEMA_VERSION_V1 or iv == SCHEMA_VERSION_V2 or iv == SCHEMA_VERSION_V3:
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
