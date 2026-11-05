## decoration_purchase_checkpoint_result.gd
## Strongly-typed outcome of a decoration purchase and persistence checkpoint attempt.
##
## Architectural rules:
## - Belongs to the application layer (src/application/decorations/).
## - Pure application result: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Strongly-typed status enum: NOT_READY, PURCHASE_REJECTED, PURCHASED_SAVED, PURCHASED_SAVE_FAILED.
class_name DecorationPurchaseCheckpointResult
extends RefCounted

enum Status {
	NOT_READY,
	PURCHASE_REJECTED,
	PURCHASED_SAVED,
	PURCHASED_SAVE_FAILED,
}

const NOT_READY: Status = Status.NOT_READY
const PURCHASE_REJECTED: Status = Status.PURCHASE_REJECTED
const PURCHASED_SAVED: Status = Status.PURCHASED_SAVED
const PURCHASED_SAVE_FAILED: Status = Status.PURCHASED_SAVE_FAILED

var _status: Status
var _purchase_result: DecorationPurchaseResult = null


func _init(status: Status, purchase_result: DecorationPurchaseResult = null) -> void:
	_status = status
	if _status == Status.NOT_READY:
		_purchase_result = null
	else:
		_purchase_result = purchase_result


static func not_ready() -> DecorationPurchaseCheckpointResult:
	return DecorationPurchaseCheckpointResult.new(Status.NOT_READY, null)


static func purchase_rejected(
	purchase_result: DecorationPurchaseResult
) -> DecorationPurchaseCheckpointResult:
	return DecorationPurchaseCheckpointResult.new(Status.PURCHASE_REJECTED, purchase_result)


static func purchased_saved(
	purchase_result: DecorationPurchaseResult
) -> DecorationPurchaseCheckpointResult:
	return DecorationPurchaseCheckpointResult.new(Status.PURCHASED_SAVED, purchase_result)


static func purchased_save_failed(
	purchase_result: DecorationPurchaseResult
) -> DecorationPurchaseCheckpointResult:
	return DecorationPurchaseCheckpointResult.new(Status.PURCHASED_SAVE_FAILED, purchase_result)


func get_status() -> Status:
	return _status


func get_purchase_result() -> DecorationPurchaseResult:
	return _purchase_result


func is_purchased() -> bool:
	return _status == Status.PURCHASED_SAVED or _status == Status.PURCHASED_SAVE_FAILED


func is_saved() -> bool:
	return _status == Status.PURCHASED_SAVED


func get_decoration() -> DecorationState:
	if not is_purchased() or _purchase_result == null:
		return null
	return _purchase_result.get_decoration()


func get_price_spent() -> int:
	if not is_purchased() or _purchase_result == null:
		return 0
	return _purchase_result.get_price_spent()


func get_new_currency_balance() -> int:
	if not is_purchased() or _purchase_result == null:
		return 0
	return _purchase_result.get_new_currency_balance()
