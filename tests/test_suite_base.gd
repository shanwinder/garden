## test_suite_base.gd
## Base class for all test suites in the Garden native headless test harness.
##
## Usage:
##   Extend this class, override run_tests(), call the assert_* helpers.
##   The runner calls run_suite() and reads passed/failed counts.
##
## Design constraints:
##   - No autoload, no scene, no global mutable state.
##   - Typed GDScript throughout.
##   - Intentionally small: only assertions justified by current need.
class_name TestSuiteBase
extends RefCounted

# ── State ────────────────────────────────────────────────────────────────────

var suite_name: String = "UnnamedSuite"
var _passed: int = 0
var _failed: int = 0
var _current_test: String = ""

# ── Public API called by the runner ──────────────────────────────────────────

## Entry point called by the runner.
## Subclasses must override run_tests() and call the assert_* methods there.
func run_suite() -> void:
	_passed = 0
	_failed = 0
	_current_test = ""
	setup()
	run_tests()
	teardown()


## Returns the number of assertions that passed in this suite.
func passed_count() -> int:
	return _passed


## Returns the number of assertions that failed in this suite.
func failed_count() -> int:
	return _failed

# ── Lifecycle hooks (override if needed; kept intentionally minimal) ──────────

## Called once before run_tests(). Override for per-suite setup.
func setup() -> void:
	pass


## Called once after run_tests(). Override for per-suite teardown.
func teardown() -> void:
	pass

# ── Test declaration helper ───────────────────────────────────────────────────

## Call at the start of each logical test to name it in failure output.
func describe(test_label: String) -> void:
	_current_test = test_label

# ── Assertion helpers ─────────────────────────────────────────────────────────

## Assert that [param condition] is true.
func assert_true(condition: bool, message: String = "") -> void:
	if condition:
		_pass()
	else:
		var detail: String = message if message != "" else "expected true, got false"
		_fail(detail)


## Assert that [param condition] is false.
func assert_false(condition: bool, message: String = "") -> void:
	if not condition:
		_pass()
	else:
		var detail: String = message if message != "" else "expected false, got true"
		_fail(detail)


## Assert that [param actual] equals [param expected].
## Works for any Variant that supports ==.
func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual == expected:
		_pass()
	else:
		var detail: String = message if message != "" \
			else "expected %s == %s" % [str(expected), str(actual)]
		_fail(detail)


## Assert that [param actual] does not equal [param expected].
func assert_ne(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		_pass()
	else:
		var detail: String = message if message != "" \
			else "expected %s != %s but they were equal" % [str(expected), str(actual)]
		_fail(detail)


## Unconditionally fail with [param message].
## Use this to signal a code path that must not be reached.
func fail(message: String) -> void:
	_fail(message)

# ── Internal helpers ──────────────────────────────────────────────────────────

func _pass() -> void:
	_passed += 1


func _fail(detail: String) -> void:
	_failed += 1
	var location: String = _current_test if _current_test != "" else "(no test label)"
	print("  FAIL [%s] %s: %s" % [suite_name, location, detail])

# ── Abstract method ───────────────────────────────────────────────────────────

## Subclasses must override this and call assert_* methods inside it.
func run_tests() -> void:
	push_error("TestSuiteBase.run_tests() not overridden in '%s'" % suite_name)
