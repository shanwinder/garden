## test_economy_state.gd
## Unit tests for Garden's EconomyState domain slice.
##
## Verifies:
## 1. Fresh EconomyState balance starts at 0.
## 2. EconomyState satisfies type contract: RefCounted, not Node, not Resource.
## 3. Valid positive grant increases currency balance.
## 4. Multiple positive grants accumulate correctly.
## 5. Spending exact balance reduces currency to 0.
## 6. Spending partial balance reduces currency correctly.
## 7. Insufficient funds returns false without error and preserves balance.
## 8. Valid maximum representable integer (64-bit int max) grant and spend succeed.
class_name TestEconomyState
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestEconomyState"


func run_tests() -> void:
	_test_fresh_balance()
	_test_type_contract()
	_test_positive_grant()
	_test_multiple_grants()
	_test_spend_valid_exact_amount()
	_test_spend_partial()
	_test_insufficient_funds()
	_test_max_int_boundary_grant_and_spend()


func _test_fresh_balance() -> void:
	describe("Fresh EconomyState has 0 currency balance")
	var economy: EconomyState = EconomyState.new()
	assert_true(economy != null, "EconomyState instance should not be null")
	assert_eq(economy.get_currency(), 0, "Fresh balance must be 0")


func _test_type_contract() -> void:
	describe("EconomyState extends RefCounted and is neither Node nor Resource")
	var economy: EconomyState = EconomyState.new()
	assert_true(economy is EconomyState, "Instance must satisfy 'is EconomyState'")
	assert_true(economy is RefCounted, "EconomyState must extend RefCounted")
	var obj: Variant = economy
	assert_false(obj is Node, "EconomyState must not be a Node")
	assert_false(obj is Resource, "EconomyState must not be a Resource")


func _test_positive_grant() -> void:
	describe("Positive grant increases balance and returns true")
	var economy: EconomyState = EconomyState.new()
	var result: bool = economy.grant_currency(5)
	assert_true(result, "grant_currency(5) must return true")
	assert_eq(economy.get_currency(), 5, "Balance must be 5 after granting 5")


func _test_multiple_grants() -> void:
	describe("Multiple positive grants accumulate balance correctly")
	var economy: EconomyState = EconomyState.new()
	assert_true(economy.grant_currency(5), "First grant(5) must return true")
	assert_true(economy.grant_currency(3), "Second grant(3) must return true")
	assert_eq(economy.get_currency(), 8, "Balance must be 8 after granting 5 and 3")


func _test_spend_valid_exact_amount() -> void:
	describe("Spending exact balance returns true and leaves balance at 0")
	var economy: EconomyState = EconomyState.new()
	economy.grant_currency(5)
	var result: bool = economy.try_spend_currency(5)
	assert_true(result, "try_spend_currency(5) with balance 5 must return true")
	assert_eq(economy.get_currency(), 0, "Balance must be 0 after spending exact amount")


func _test_spend_partial() -> void:
	describe("Spending partial balance returns true and decreases balance correctly")
	var economy: EconomyState = EconomyState.new()
	economy.grant_currency(10)
	var result: bool = economy.try_spend_currency(4)
	assert_true(result, "try_spend_currency(4) with balance 10 must return true")
	assert_eq(economy.get_currency(), 6, "Balance must be 6 after spending 4 from 10")


func _test_insufficient_funds() -> void:
	describe("Spending more than balance returns false as normal business outcome with balance unchanged")
	var economy: EconomyState = EconomyState.new()
	economy.grant_currency(3)
	var result: bool = economy.try_spend_currency(4)
	assert_false(result, "try_spend_currency(4) with balance 3 must return false")
	assert_eq(economy.get_currency(), 3, "Balance must remain unchanged at 3")


func _test_max_int_boundary_grant_and_spend() -> void:
	describe("Valid maximum representable 64-bit integer grant and spend succeed")
	var economy: EconomyState = EconomyState.new()
	var grant_result: bool = economy.grant_currency(EconomyState.MAX_CURRENCY)
	assert_true(grant_result, "Granting MAX_CURRENCY from 0 must return true")
	assert_eq(
		economy.get_currency(),
		EconomyState.MAX_CURRENCY,
		"Balance must equal MAX_CURRENCY"
	)
	var spend_result: bool = economy.try_spend_currency(EconomyState.MAX_CURRENCY)
	assert_true(spend_result, "Spending MAX_CURRENCY must return true")
	assert_eq(economy.get_currency(), 0, "Balance must return to 0 after spending MAX_CURRENCY")
