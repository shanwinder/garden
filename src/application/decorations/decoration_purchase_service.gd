## decoration_purchase_service.gd
## Application service coordinating validated decoration purchase, coin deduction,
## and placement into authoritative GameState.
##
## Architectural rules:
## - Belongs to the application layer (src/application/decorations/).
## - Pure application service: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Receives all dependencies explicitly; no global App or SceneTree access.
## - Does not access filesystem or persist state.
## - All-or-nothing validation:
##   - Prevalidates dependencies, definition syntax, catalog membership, positive price,
##     and sufficient currency balance BEFORE sampling GameClock, consuming RNG, or
##     mutating EconomyState / DecorationCollectionState.
##   - Insufficient funds never mutates currency, never inserts a decoration, and never
##     consumes RNG.
##   - Samples GameClock.utc_now_seconds() at most once per valid command.
class_name DecorationPurchaseService
extends RefCounted


## Validates inputs, deducts the decoration's coin price from EconomyState, and registers
## a new DecorationState in [param state] at an explicit [param placed_at] timestamp.
static func try_purchase_and_place_at(
	state: GameState,
	catalog: ContentCatalog,
	instance_id: String,
	definition_id: String,
	placed_at: int
) -> DecorationPurchaseResult:
	# 1. Structural input validation
	if state == null or catalog == null:
		return DecorationPurchaseResult.invalid_input()

	if instance_id.is_empty():
		return DecorationPurchaseResult.invalid_input()

	if placed_at < 0:
		return DecorationPurchaseResult.invalid_input()

	if not _is_structurally_valid_decoration_definition_id(definition_id):
		return DecorationPurchaseResult.invalid_input()

	var economy: EconomyState = state.get_economy()
	var decorations: DecorationCollectionState = state.get_decorations()
	if economy == null or decorations == null:
		return DecorationPurchaseResult.invalid_input()

	# 2. Catalog membership validation
	if not catalog.has_decoration(definition_id):
		return DecorationPurchaseResult.unknown_definition_id()

	var definition: DecorationDefinition = catalog.get_decoration(definition_id)
	if definition == null or not definition.is_valid():
		return DecorationPurchaseResult.unknown_definition_id()

	# 3. Price validation
	var price: int = definition.price
	if price <= 0:
		return DecorationPurchaseResult.invalid_price()

	# 4. Currency sufficiency check (before any mutation)
	if economy.get_currency() < price:
		return DecorationPurchaseResult.insufficient_currency()

	# 5. Runtime instance uniqueness validation
	if decorations.has_runtime_instance_id(instance_id):
		return DecorationPurchaseResult.duplicate_instance_id()

	# 6. Construct DecorationState and verify structural validity before spending
	var decoration: DecorationState = DecorationState.new(instance_id, definition_id, placed_at)
	if not decoration.is_valid():
		return DecorationPurchaseResult.insertion_rejected()

	# 7. Spend currency and insert decoration atomically
	var spent: bool = economy.try_spend_currency(price)
	if not spent:
		return DecorationPurchaseResult.currency_spend_rejected()

	var inserted: bool = decorations.try_add_decoration(decoration)
	if not inserted:
		# Roll back currency deduction if collection insertion unexpectedly fails
		economy.grant_currency(price)
		return DecorationPurchaseResult.insertion_rejected()

	return DecorationPurchaseResult.purchased(decoration, price, economy.get_currency())


## Validates dependencies, checks catalog and currency sufficiency BEFORE sampling clock
## or consuming RNG, captures current UTC timestamp once, generates a unique runtime ID,
## and delegates to [method try_purchase_and_place_at].
static func try_purchase_and_place_now(
	state: GameState,
	catalog: ContentCatalog,
	game_clock: GameClock,
	random_source: RandomSource,
	definition_id: String
) -> DecorationPurchaseResult:
	# 1. Dependency presence validation
	if state == null or catalog == null or game_clock == null or random_source == null:
		return DecorationPurchaseResult.invalid_input()

	var economy: EconomyState = state.get_economy()
	var decorations: DecorationCollectionState = state.get_decorations()
	if economy == null or decorations == null:
		return DecorationPurchaseResult.invalid_input()

	# 2. Structural definition ID validation
	if not _is_structurally_valid_decoration_definition_id(definition_id):
		return DecorationPurchaseResult.invalid_input()

	# 3. Catalog membership validation
	if not catalog.has_decoration(definition_id):
		return DecorationPurchaseResult.unknown_definition_id()

	var definition: DecorationDefinition = catalog.get_decoration(definition_id)
	if definition == null or not definition.is_valid():
		return DecorationPurchaseResult.unknown_definition_id()

	# 4. Price and currency sufficiency check BEFORE clock sampling or RNG draws
	var price: int = definition.price
	if price <= 0:
		return DecorationPurchaseResult.invalid_price()

	if economy.get_currency() < price:
		return DecorationPurchaseResult.insufficient_currency()

	# 5. Timestamp capture (sampled exactly once per valid command)
	var placed_at: int = game_clock.utc_now_seconds()
	if placed_at < 0:
		return DecorationPurchaseResult.invalid_input()

	# 6. Runtime ID generation (consumes RNG only after all preconditions pass)
	var instance_id: String = DecorationRuntimeIdGenerator.try_generate_unique_id(
		decorations,
		random_source
	)
	if instance_id.is_empty():
		return DecorationPurchaseResult.id_generation_failed()

	# 7. Authoritative purchase & placement
	return try_purchase_and_place_at(
		state,
		catalog,
		instance_id,
		definition_id,
		placed_at
	)


static func _is_structurally_valid_decoration_definition_id(def_id: String) -> bool:
	if def_id.is_empty():
		return false
	if not def_id.begins_with(DecorationDefinition.DECORATION_NAMESPACE_PREFIX):
		return false
	return StableContentId.is_valid(def_id)
