## test_harness_smoke.gd
## Smoke test suite that proves the native test harness itself works.
##
## This suite tests only the harness — not any gameplay logic.
## All assertions in this suite must pass so that the committed repository
## exits with code 0.
##
## The failure-path contract (non-zero exit on failure) is verified separately
## outside the repository using a temporary project, as required by Task 0.4B.
class_name TestHarnessSmoke
extends TestSuiteBase

func _init() -> void:
	suite_name = "TestHarnessSmoke"


func run_tests() -> void:
	_test_assert_true_passes_on_true()
	_test_assert_false_passes_on_false()
	_test_assert_eq_passes_on_equal_ints()
	_test_assert_eq_passes_on_equal_strings()
	_test_assert_eq_passes_on_equal_booleans()
	_test_assert_ne_passes_on_different_ints()
	_test_assert_ne_passes_on_different_strings()
	_test_describe_sets_current_label()
	_test_pass_counter_increments()
	_test_failure_path_via_isolated_sub_suite()

# ── Individual tests ──────────────────────────────────────────────────────────

func _test_assert_true_passes_on_true() -> void:
	describe("assert_true passes when condition is true")
	assert_true(true)
	assert_true(1 == 1)
	assert_true("a" == "a")


func _test_assert_false_passes_on_false() -> void:
	describe("assert_false passes when condition is false")
	assert_false(false)
	assert_false(1 == 2)
	assert_false("a" == "b")


func _test_assert_eq_passes_on_equal_ints() -> void:
	describe("assert_eq passes for equal integers")
	assert_eq(1 + 1, 2)
	assert_eq(0, 0)
	assert_eq(-7, -7)


func _test_assert_eq_passes_on_equal_strings() -> void:
	describe("assert_eq passes for equal strings")
	assert_eq("garden", "garden")
	assert_eq("", "")


func _test_assert_eq_passes_on_equal_booleans() -> void:
	describe("assert_eq passes for equal booleans")
	assert_eq(true, true)
	assert_eq(false, false)


func _test_assert_ne_passes_on_different_ints() -> void:
	describe("assert_ne passes when integers differ")
	assert_ne(1, 2)
	assert_ne(0, -1)
	assert_ne(100, 99)


func _test_assert_ne_passes_on_different_strings() -> void:
	describe("assert_ne passes when strings differ")
	assert_ne("a", "b")
	assert_ne("garden", "GARDEN")


func _test_describe_sets_current_label() -> void:
	describe("describe() sets current_test label")
	assert_eq(_current_test, "describe() sets current_test label")


func _test_pass_counter_increments() -> void:
	describe("passed counter increments with each passing assertion")
	var before: int = _passed
	assert_true(true)
	assert_eq(_passed, before + 1)


func _test_failure_path_via_isolated_sub_suite() -> void:
	describe("failure path: a sub-suite that fails produces a non-zero failed count")
	# Create an isolated sub-suite instance that intentionally fails.
	# This proves the failure-recording mechanics work without polluting
	# the main suite's pass/fail counters.
	var probe: _FailingProbe = _FailingProbe.new()
	probe.run_suite()
	assert_eq(probe.passed_count(), 0, "probe should have 0 passes")
	assert_eq(probe.failed_count(), 1, "probe should have 1 recorded failure")


# ── Internal probe used only by _test_failure_path_via_isolated_sub_suite ────

## A minimal inner suite that unconditionally fails once.
## Used to verify that the failure-recording path works correctly
## without affecting the outer suite's counters.
class _FailingProbe extends TestSuiteBase:
	func _init() -> void:
		suite_name = "FailingProbe"

	func run_tests() -> void:
		describe("intentional failure probe")
		assert_true(false, "this assertion is expected to fail")
