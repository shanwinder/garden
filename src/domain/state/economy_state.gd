## economy_state.gd
## Authoritative domain state slice for Garden's currency balance.
##
## EconomyState is the first persistent state slice owned by GameState.
## It maintains the authoritative, non-negative integer currency balance
## and explicit domain mutation methods.
##
## Architectural rules:
## - Belongs to the domain layer (src/domain/state/).
## - Pure domain object: extends RefCounted (not a Node, Resource, Autoload, singleton, or manager).
## - Encapsulates currency balance; does not expose a public setter or mutable property.
## - Stores persistent economy facts only; no pricing, shop, inventory, or item definitions.
## - All mutations are protected by release-active guard clauses against invalid inputs
##   and integer overflow.
class_name EconomyState
extends RefCounted

## Maximum representable signed 64-bit integer in GDScript (2^63 - 1 = 0x7FFFFFFFFFFFFFFF).
## Used to protect balance mutations against integer overflow.
const MAX_CURRENCY: int = 9223372036854775807

var _currency: int = 0


## Returns the authoritative currency balance.
func get_currency() -> int:
	return _currency


## Grants [param amount] to the currency balance.
##
## Validation:
## - [param amount] must be > 0. If <= 0, emits push_error() and returns false.
## - [param amount] must not cause integer overflow. If overflow would occur,
##   emits push_error() and returns false.
## - On valid grant, increases balance and returns true.
func grant_currency(amount: int) -> bool:
	if amount <= 0:
		push_error("EconomyState.grant_currency: amount must be positive, got %d" % amount)
		return false

	if amount > MAX_CURRENCY - _currency:
		push_error(
			"EconomyState.grant_currency: integer overflow risk granting %d to current balance %d"
			% [amount, _currency]
		)
		return false

	_currency += amount
	return true


## Attempts to spend [param amount] from the currency balance.
##
## Validation:
## - [param amount] must be > 0. If <= 0, emits push_error() and returns false.
## - If [param amount] > current balance, returns false without push_error()
##   (insufficient funds is a normal business outcome).
## - On valid and sufficient spend, decreases balance and returns true.
func try_spend_currency(amount: int) -> bool:
	if amount <= 0:
		push_error("EconomyState.try_spend_currency: amount must be positive, got %d" % amount)
		return false

	if amount > _currency:
		return false

	_currency -= amount
	return true
