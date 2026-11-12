## decoration_purchase_result.gd
## Strongly-typed outcome of a decoration purchase and placement operation.
##
## Architectural rules:
## - Belongs to the application layer (src/application/decorations/).
## - Pure application result: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Immutable after construction; read-only getters.
## - Distinguishes successful purchase (PURCHASED) from every explicit rejection reason.
class_name DecorationPurchaseResult
extends RefCounted

enum Status {
	PURCHASED,
	INVALID_INPUT,
	UNKNOWN_DEFINITION_ID,
	INVALID_PRICE,
	INSUFFICIENT_CURRENCY,
	DUPLICATE_INSTANCE_ID,
	ID_GENERATION_FAILED,
	CURRENCY_SPEND_REJECTED,
	INSERTION_REJECTED,
	INVALID_PLACEMENT,
	ZONE_LOCKED,
	CELL_OCCUPIED,
	GARDEN_FULL,
}

const PURCHASED: Status = Status.PURCHASED
const INVALID_INPUT: Status = Status.INVALID_INPUT
const UNKNOWN_DEFINITION_ID: Status = Status.UNKNOWN_DEFINITION_ID
const INVALID_PRICE: Status = Status.INVALID_PRICE
const INSUFFICIENT_CURRENCY: Status = Status.INSUFFICIENT_CURRENCY
const DUPLICATE_INSTANCE_ID: Status = Status.DUPLICATE_INSTANCE_ID
const ID_GENERATION_FAILED: Status = Status.ID_GENERATION_FAILED
const CURRENCY_SPEND_REJECTED: Status = Status.CURRENCY_SPEND_REJECTED
const INSERTION_REJECTED: Status = Status.INSERTION_REJECTED
const INVALID_PLACEMENT: Status = Status.INVALID_PLACEMENT
const ZONE_LOCKED: Status = Status.ZONE_LOCKED
const CELL_OCCUPIED: Status = Status.CELL_OCCUPIED
const GARDEN_FULL: Status = Status.GARDEN_FULL

var _status: Status
var _decoration: DecorationState = null
var _price_spent: int = 0
var _new_currency_balance: int = 0


func _init(
	status: Status,
	decoration: DecorationState = null,
	price_spent: int = 0,
	new_currency_balance: int = 0
) -> void:
	_status = status
	if _status == Status.PURCHASED and decoration != null and price_spent > 0:
		_decoration = decoration
		_price_spent = price_spent
		_new_currency_balance = maxi(0, new_currency_balance)
	else:
		_decoration = null
		_price_spent = 0
		_new_currency_balance = 0


static func purchased(
	decoration: DecorationState,
	price_spent: int,
	new_currency_balance: int
) -> DecorationPurchaseResult:
	if decoration == null or price_spent <= 0:
		return DecorationPurchaseResult.new(Status.INSERTION_REJECTED)
	return DecorationPurchaseResult.new(
		Status.PURCHASED,
		decoration,
		price_spent,
		new_currency_balance
	)


static func invalid_input() -> DecorationPurchaseResult:
	return DecorationPurchaseResult.new(Status.INVALID_INPUT)


static func unknown_definition_id() -> DecorationPurchaseResult:
	return DecorationPurchaseResult.new(Status.UNKNOWN_DEFINITION_ID)


static func invalid_price() -> DecorationPurchaseResult:
	return DecorationPurchaseResult.new(Status.INVALID_PRICE)


static func insufficient_currency() -> DecorationPurchaseResult:
	return DecorationPurchaseResult.new(Status.INSUFFICIENT_CURRENCY)


static func duplicate_instance_id() -> DecorationPurchaseResult:
	return DecorationPurchaseResult.new(Status.DUPLICATE_INSTANCE_ID)


static func id_generation_failed() -> DecorationPurchaseResult:
	return DecorationPurchaseResult.new(Status.ID_GENERATION_FAILED)


static func currency_spend_rejected() -> DecorationPurchaseResult:
	return DecorationPurchaseResult.new(Status.CURRENCY_SPEND_REJECTED)


static func insertion_rejected() -> DecorationPurchaseResult:
	return DecorationPurchaseResult.new(Status.INSERTION_REJECTED)


static func invalid_placement() -> DecorationPurchaseResult:
	return DecorationPurchaseResult.new(Status.INVALID_PLACEMENT)


static func zone_locked() -> DecorationPurchaseResult:
	return DecorationPurchaseResult.new(Status.ZONE_LOCKED)


static func cell_occupied() -> DecorationPurchaseResult:
	return DecorationPurchaseResult.new(Status.CELL_OCCUPIED)


static func garden_full() -> DecorationPurchaseResult:
	return DecorationPurchaseResult.new(Status.GARDEN_FULL)


func get_status() -> Status:
	return _status


func is_purchased() -> bool:
	return _status == Status.PURCHASED and _decoration != null


func get_decoration() -> DecorationState:
	return _decoration


func get_price_spent() -> int:
	return _price_spent


func get_new_currency_balance() -> int:
	return _new_currency_balance
