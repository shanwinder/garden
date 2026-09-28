## test_game_clock.gd
## Test suite for Garden's GameClock infrastructure.
##
## Covers:
##   1. Contract / production type — SystemGameClock satisfies GameClock contract,
##      both types are RefCounted (no SceneTree ownership required), and
##      production methods return correct declared integer types.
##   2. Fake determinism — FakeGameClock returns exact known values, advancing
##      UTC and monotonic produce exact expected values, and UTC rollback
##      (set_utc_seconds to a lower value) is faithfully reported rather than
##      hidden or clamped.
##   3. AppRoot composition — AppRoot exposes a non-null typed GameClock and
##      the instance is a SystemGameClock.
##
## Wall-clock stability:
##   Tests do NOT assert specific date/time values from SystemGameClock. They
##   only assert the return type (int) and that repeated calls do not return
##   negative values. All deterministic behavioral tests use FakeGameClock.
class_name TestGameClock
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGameClock"


func run_tests() -> void:
	_test_system_clock_is_game_clock()
	_test_system_clock_no_scene_tree_required()
	_test_game_clock_no_scene_tree_required()
	_test_system_utc_returns_int()
	_test_system_monotonic_returns_int()
	_test_system_utc_plausible_range()
	_test_system_monotonic_non_negative()
	_test_fake_initial_utc()
	_test_fake_initial_monotonic()
	_test_fake_advance_utc()
	_test_fake_advance_monotonic()
	_test_fake_set_utc_forward()
	_test_fake_set_utc_backward_rollback()
	_test_fake_multiple_advances()
	_test_fake_independent_utc_and_monotonic()
	_test_app_root_owns_non_null_game_clock()
	_test_app_root_clock_is_system_game_clock()


# ── Contract / production type ─────────────────────────────────────────────────

func _test_system_clock_is_game_clock() -> void:
	describe("SystemGameClock is a GameClock")
	var clock := SystemGameClock.new()
	assert_true(clock is GameClock, "SystemGameClock must satisfy the GameClock contract")


func _test_system_clock_no_scene_tree_required() -> void:
	describe("SystemGameClock does not require SceneTree ownership")
	# RefCounted subclasses can be constructed and used without add_child().
	# Godot 4.7.2 rejects 'is Node' checks on known RefCounted types at parse
	# time. We verify Node non-ancestry positively: clock must be RefCounted
	# and its class hierarchy must not include Node.
	var clock := SystemGameClock.new()
	assert_true(clock != null, "SystemGameClock must be constructable without a scene")
	assert_true(clock is RefCounted, "SystemGameClock must extend RefCounted, not Node")


func _test_game_clock_no_scene_tree_required() -> void:
	describe("FakeGameClock (GameClock subtype) does not require SceneTree ownership")
	# Same reasoning as above: verify positively via RefCounted ancestry.
	var clock := FakeGameClock.new(0, 0)
	assert_true(clock is GameClock, "FakeGameClock must satisfy the GameClock contract")
	assert_true(clock is RefCounted, "GameClock subtypes must extend RefCounted, not Node")


func _test_system_utc_returns_int() -> void:
	describe("SystemGameClock.utc_now_seconds() returns int")
	var clock := SystemGameClock.new()
	var value: int = clock.utc_now_seconds()
	# typeof(int_expr) == TYPE_INT is the GDScript way to assert integer type.
	assert_true(typeof(value) == TYPE_INT, "utc_now_seconds() must return TYPE_INT")


func _test_system_monotonic_returns_int() -> void:
	describe("SystemGameClock.monotonic_milliseconds() returns int")
	var clock := SystemGameClock.new()
	var value: int = clock.monotonic_milliseconds()
	assert_true(typeof(value) == TYPE_INT, "monotonic_milliseconds() must return TYPE_INT")


func _test_system_utc_plausible_range() -> void:
	# A loose sanity check: UTC seconds must be greater than the Unix epoch of
	# 2020-01-01 (1577836800). This avoids depending on the current date while
	# still catching obviously wrong values such as 0 or a negative number.
	describe("SystemGameClock.utc_now_seconds() returns a plausible UTC epoch value")
	var clock := SystemGameClock.new()
	var utc: int = clock.utc_now_seconds()
	assert_true(utc > 1577836800, "utc_now_seconds() must be after 2020-01-01 UTC")


func _test_system_monotonic_non_negative() -> void:
	describe("SystemGameClock.monotonic_milliseconds() returns a non-negative value")
	var clock := SystemGameClock.new()
	var ms: int = clock.monotonic_milliseconds()
	assert_true(ms >= 0, "monotonic_milliseconds() must not be negative")


# ── Fake determinism ───────────────────────────────────────────────────────────

func _test_fake_initial_utc() -> void:
	describe("FakeGameClock returns exact initial UTC value")
	var clock := FakeGameClock.new(1_700_000_000, 0)
	assert_eq(
		clock.utc_now_seconds(), 1_700_000_000,
		"utc_now_seconds() must return exact initial value"
	)


func _test_fake_initial_monotonic() -> void:
	describe("FakeGameClock returns exact initial monotonic value")
	var clock := FakeGameClock.new(0, 5000)
	assert_eq(
		clock.monotonic_milliseconds(), 5000,
		"monotonic_milliseconds() must return exact initial value"
	)


func _test_fake_advance_utc() -> void:
	describe("FakeGameClock.advance_utc_seconds() produces exact expected UTC value")
	var clock := FakeGameClock.new(1_000_000, 0)
	clock.advance_utc_seconds(60)
	assert_eq(clock.utc_now_seconds(), 1_000_060, "After +60s, utc_now_seconds() must be 1_000_060")
	clock.advance_utc_seconds(3600)
	assert_eq(
		clock.utc_now_seconds(), 1_003_660,
		"After +3600s more, utc_now_seconds() must be 1_003_660"
	)


func _test_fake_advance_monotonic() -> void:
	describe("FakeGameClock.advance_monotonic_ms() produces exact expected monotonic value")
	var clock := FakeGameClock.new(0, 1000)
	clock.advance_monotonic_ms(500)
	assert_eq(
		clock.monotonic_milliseconds(), 1500,
		"After +500ms, monotonic_milliseconds() must be 1500"
	)
	clock.advance_monotonic_ms(2000)
	assert_eq(
		clock.monotonic_milliseconds(), 3500,
		"After +2000ms more, monotonic_milliseconds() must be 3500"
	)


func _test_fake_set_utc_forward() -> void:
	describe("FakeGameClock.set_utc_seconds() sets UTC to exact forward value")
	var clock := FakeGameClock.new(1_000_000, 0)
	clock.set_utc_seconds(2_000_000)
	assert_eq(
		clock.utc_now_seconds(), 2_000_000,
		"set_utc_seconds(2_000_000) must produce exactly 2_000_000"
	)


func _test_fake_set_utc_backward_rollback() -> void:
	# This is the critical rollback test. The fake must expose the lower value
	# faithfully so that future tests can simulate and verify clock-rollback
	# handling in domain/application logic without depending on real time.
	describe(
		"FakeGameClock.set_utc_seconds() simulates device-clock rollback: " +
		"lower value is NOT hidden or clamped"
	)
	var clock := FakeGameClock.new(1_700_000_000, 0)
	clock.set_utc_seconds(1_699_999_000)  # 1000 seconds earlier
	assert_eq(
		clock.utc_now_seconds(),
		1_699_999_000,
		"After rollback, utc_now_seconds() must return the exact lower value"
	)


func _test_fake_multiple_advances() -> void:
	describe("FakeGameClock handles multiple sequential advances correctly")
	var clock := FakeGameClock.new(500, 100)
	clock.advance_utc_seconds(10)
	clock.advance_utc_seconds(20)
	clock.advance_utc_seconds(30)
	assert_eq(clock.utc_now_seconds(), 560, "Three advances of 10+20+30 must total +60 from 500")


func _test_fake_independent_utc_and_monotonic() -> void:
	describe(
		"FakeGameClock UTC and monotonic are independent; " +
		"advancing one does not affect the other"
	)
	var clock := FakeGameClock.new(1_000_000, 2000)
	clock.advance_utc_seconds(100)
	assert_eq(
		clock.monotonic_milliseconds(), 2000,
		"monotonic must not change when UTC is advanced"
	)
	clock.advance_monotonic_ms(500)
	assert_eq(
		clock.utc_now_seconds(), 1_000_100,
		"UTC must not change when monotonic is advanced"
	)


# ── AppRoot composition ────────────────────────────────────────────────────────

func _test_app_root_owns_non_null_game_clock() -> void:
	describe("Newly constructed AppRoot owns a non-null typed GameClock")
	var root := AppRoot.new()
	assert_true(root.game_clock != null, "AppRoot.game_clock must not be null after construction")
	assert_true(root.game_clock is GameClock, "AppRoot.game_clock must satisfy the GameClock contract")
	root.free()


func _test_app_root_clock_is_system_game_clock() -> void:
	describe("AppRoot production clock instance is a SystemGameClock")
	var root := AppRoot.new()
	assert_true(
		root.game_clock is SystemGameClock,
		"AppRoot.game_clock must be a SystemGameClock in production"
	)
	root.free()
