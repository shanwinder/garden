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


## Encodes an authoritative [param state] into a JSON-compatible V1 snapshot dictionary.
##
## Requirements and guarantees:
## - Returns a new Dictionary containing only JSON-compatible primitive types (Dictionary, Array, String, int).
## - Plants are serialized in deterministic ascending order of runtime instance ID.
## - Does not serialize derived growth data or static definition resources.
## - Does not mutate [param state].
## - If [param state] is null, returns an empty Dictionary without crashing.
static func encode(state: GameState) -> Dictionary:
	if state == null:
		return {}

	var economy: EconomyState = state.get_economy()
	var economy_data: Dictionary = {
		KEY_CURRENCY: economy.get_currency(),
	}

	var plants_collection: PlantCollectionState = state.get_plants()
	var all_plants: Array[PlantState] = plants_collection.get_all_plants()
	var plants_data: Array = []

	for plant: PlantState in all_plants:
		plants_data.append({
			KEY_INSTANCE_ID: plant.get_runtime_instance_id(),
			KEY_DEFINITION_ID: plant.get_definition_id(),
			KEY_PLANTED_AT: plant.get_planted_at(),
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
## - schema_version must be integer 1 (rejects unsupported versions, 0, 2, strings, floats).
## - economy must be a Dictionary with exact allowed keys and non-negative integer currency.
## - currency must satisfy 0 <= currency <= EconomyState.MAX_CURRENCY.
## - plants must be an Array of Dictionaries with exact allowed keys.
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

	# Validate schema_version.
	var raw_version: Variant = root_dict[KEY_SCHEMA_VERSION]
	if not _is_integral(raw_version):
		return null
	if _to_int(raw_version) != CURRENT_SCHEMA_VERSION:
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
	if not _is_integral(raw_currency):
		return null

	if typeof(raw_currency) == TYPE_FLOAT:
		var f_cur: float = raw_currency
		if f_cur < 0.0 or f_cur > float(EconomyState.MAX_CURRENCY):
			return null

	var currency: int = _to_int(raw_currency)
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
		if not _is_integral(raw_planted_at):
			return null

		if typeof(raw_planted_at) == TYPE_FLOAT:
			var f_planted: float = raw_planted_at
			if f_planted < 0.0 or f_planted > float(EconomyState.MAX_CURRENCY):
				return null

		var planted_at: int = _to_int(raw_planted_at)
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


## Returns true if [param value] represents an integral numeric value.
##
## Handles both GDScript native TYPE_INT and JSON-deserialized TYPE_FLOAT without fractional parts.
## Rejects boolean, string, null, NaN, INF, out-of-range floats, and floats with non-zero fractional parts.
static func _is_integral(value: Variant) -> bool:
	var val_type: int = typeof(value)
	if val_type == TYPE_INT:
		return true
	if val_type == TYPE_FLOAT:
		var f: float = value
		if not is_finite(f) or floor(f) != f:
			return false
		if f > float(EconomyState.MAX_CURRENCY) or f < -float(EconomyState.MAX_CURRENCY):
			return false
		return true
	return false


## Converts an integer-compatible Variant to [code]int[/code].
static func _to_int(value: Variant) -> int:
	return int(value)
