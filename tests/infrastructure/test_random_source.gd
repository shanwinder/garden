## test_random_source.gd
## Test suite for Garden's RandomSource infrastructure.
##
## Covers:
##   1. Contract / production type — GodotRandomSource satisfies RandomSource
##      contract, both types are RefCounted (no SceneTree required), and
##      production methods return values within specified bounds.
##   2. Fake determinism — FakeRandomSource returns exact scripted values in
##      order, float and int streams are independent, and bounds are validated.
##   3. FakeRandomSource array isolation — caller mutation of input arrays after
##      construction does not affect scripted sequences (Severity 4 fix).
##   4. Weighted selection — choose_weighted_index() boundary behavior is
##      verified with exact FakeRandomSource rolls. All tests are deterministic.
##   5. AppRoot composition — AppRoot exposes a non-null typed RandomSource
##      and the instance is a GodotRandomSource.
##
## Non-flakiness guarantee:
##   GodotRandomSource tests only assert type contracts and range membership.
##   They do NOT assert specific random values, consecutive-call differences,
##   distribution percentages, or seed-specific sequences.
##
##   All exact-value and boundary tests use FakeRandomSource.
class_name TestRandomSource
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestRandomSource"


func run_tests() -> void:
	# Contract / production type
	_test_godot_source_is_random_source()
	_test_godot_source_no_scene_tree_required()
	_test_fake_source_is_random_source()
	_test_fake_source_no_scene_tree_required()

	# GodotRandomSource production sanity
	_test_godot_next_float_in_range()
	_test_godot_range_int_within_bounds()
	_test_godot_range_int_equal_bounds()

	# FakeRandomSource scripted sequences
	_test_fake_floats_consumed_in_order()
	_test_fake_ints_consumed_in_order()
	_test_fake_streams_are_independent()
	_test_fake_range_int_equal_bounds()

	# FakeRandomSource array isolation (Severity 4 fix)
	_test_fake_float_array_isolated_from_caller()
	_test_fake_int_array_isolated_from_caller()

	# AppRoot composition
	_test_app_root_owns_non_null_random_source()
	_test_app_root_random_source_is_godot_random_source()

	# Weighted selection — single weight
	_test_weighted_single_entry()

	# Weighted selection — zero weights skipped
	_test_weighted_zero_weights_skipped()

	# Weighted selection — exact boundary behavior
	_test_weighted_boundary_roll_zero()
	_test_weighted_boundary_roll_below_first_threshold()
	_test_weighted_boundary_roll_at_first_threshold()
	_test_weighted_boundary_roll_near_one()

	# Weighted selection — three entries prove cumulative walk
	_test_weighted_three_entries_selects_middle()
	_test_weighted_three_entries_selects_last()

	# Weighted selection — caller array not mutated
	_test_weighted_does_not_mutate_caller_array()


# ── Contract / production type ────────────────────────────────────────────────

func _test_godot_source_is_random_source() -> void:
	describe("GodotRandomSource is a RandomSource")
	var src := GodotRandomSource.new()
	assert_true(src is RandomSource, "GodotRandomSource must satisfy the RandomSource contract")


func _test_godot_source_no_scene_tree_required() -> void:
	describe("GodotRandomSource does not require SceneTree ownership")
	var src := GodotRandomSource.new()
	assert_true(src != null, "GodotRandomSource must be constructable without a scene")
	assert_true(src is RefCounted, "GodotRandomSource must extend RefCounted, not Node")


func _test_fake_source_is_random_source() -> void:
	describe("FakeRandomSource is a RandomSource")
	var src := FakeRandomSource.new([], [])
	assert_true(src is RandomSource, "FakeRandomSource must satisfy the RandomSource contract")


func _test_fake_source_no_scene_tree_required() -> void:
	describe("FakeRandomSource does not require SceneTree ownership")
	var src := FakeRandomSource.new([], [])
	assert_true(src != null, "FakeRandomSource must be constructable without a scene")
	assert_true(src is RefCounted, "FakeRandomSource must extend RefCounted, not Node")


# ── GodotRandomSource production sanity ──────────────────────────────────────

func _test_godot_next_float_in_range() -> void:
	describe("GodotRandomSource.next_float() returns value in [0.0, 1.0)")
	var src := GodotRandomSource.new()
	# Sample several values; none may violate the contract.
	for _i: int in range(20):
		var v: float = src.next_float()
		assert_true(v >= 0.0, "next_float() must be >= 0.0, got %s" % v)
		assert_true(v < 1.0, "next_float() must be < 1.0, got %s" % v)


func _test_godot_range_int_within_bounds() -> void:
	describe("GodotRandomSource.range_int(1, 10) returns value in [1, 10]")
	var src := GodotRandomSource.new()
	for _i: int in range(20):
		var v: int = src.range_int(1, 10)
		assert_true(v >= 1, "range_int(1, 10) must be >= 1, got %d" % v)
		assert_true(v <= 10, "range_int(1, 10) must be <= 10, got %d" % v)


func _test_godot_range_int_equal_bounds() -> void:
	describe("GodotRandomSource.range_int(5, 5) returns exactly 5")
	var src := GodotRandomSource.new()
	var v: int = src.range_int(5, 5)
	assert_eq(v, 5, "range_int(5, 5) must return exactly 5")


# ── FakeRandomSource scripted sequences ──────────────────────────────────────

func _test_fake_floats_consumed_in_order() -> void:
	describe("FakeRandomSource scripted floats are consumed in order")
	var src := FakeRandomSource.new([0.1, 0.7, 0.0], [])
	assert_eq(src.next_float(), 0.1, "first next_float() must return 0.1")
	assert_eq(src.next_float(), 0.7, "second next_float() must return 0.7")
	assert_eq(src.next_float(), 0.0, "third next_float() must return 0.0")


func _test_fake_ints_consumed_in_order() -> void:
	describe("FakeRandomSource scripted ints are consumed in order")
	var src := FakeRandomSource.new([], [3, 8])
	assert_eq(src.range_int(1, 5), 3, "first range_int(1, 5) must return 3")
	assert_eq(src.range_int(5, 10), 8, "second range_int(5, 10) must return 8")


func _test_fake_streams_are_independent() -> void:
	describe("FakeRandomSource float and int streams are independent")
	# Consuming floats must not affect int stream and vice versa.
	var src := FakeRandomSource.new([0.2, 0.5], [7, 2])
	assert_eq(src.next_float(), 0.2, "first float must be 0.2")
	assert_eq(src.range_int(1, 10), 7, "first int must be 7")
	# Float stream must be unaffected by the int call above.
	assert_eq(src.next_float(), 0.5, "second float must be 0.5")
	# Int stream must be unaffected by the float calls above.
	assert_eq(src.range_int(1, 5), 2, "second int must be 2")


func _test_fake_range_int_equal_bounds() -> void:
	describe("FakeRandomSource.range_int(5, 5) with scripted 5 returns exactly 5")
	var src := FakeRandomSource.new([], [5])
	assert_eq(src.range_int(5, 5), 5, "range_int(5, 5) with scripted 5 must return 5")


# ── FakeRandomSource array isolation ─────────────────────────────────────────
#
# Closes the Severity 4 array-aliasing finding from Task 1.2R.
# Verifies that mutating the caller's original arrays after FakeRandomSource
# construction does NOT affect the scripted sequences.

func _test_fake_float_array_isolated_from_caller() -> void:
	describe("FakeRandomSource float sequence is independent of caller mutation")
	var caller_floats: Array[float] = [0.3, 0.6]
	var src := FakeRandomSource.new(caller_floats, [])
	# Mutate the caller's original array after construction.
	caller_floats[0] = 0.99
	caller_floats[1] = 0.01
	# The scripted sequence must still return the original values.
	assert_eq(
		src.next_float(), 0.3,
		"next_float() must return original scripted 0.3 even after caller mutated input"
	)
	assert_eq(
		src.next_float(), 0.6,
		"next_float() must return original scripted 0.6 even after caller mutated input"
	)


func _test_fake_int_array_isolated_from_caller() -> void:
	describe("FakeRandomSource int sequence is independent of caller mutation")
	var caller_ints: Array[int] = [4, 9]
	var src := FakeRandomSource.new([], caller_ints)
	# Mutate the caller's original array after construction.
	caller_ints[0] = 99
	caller_ints[1] = 99
	# The scripted sequence must still return the original values.
	assert_eq(
		src.range_int(1, 10), 4,
		"range_int() must return original scripted 4 even after caller mutated input"
	)
	assert_eq(
		src.range_int(1, 10), 9,
		"range_int() must return original scripted 9 even after caller mutated input"
	)


# ── AppRoot composition ───────────────────────────────────────────────────────

func _test_app_root_owns_non_null_random_source() -> void:
	describe("Newly constructed AppRoot owns a non-null typed RandomSource")
	var root := AppRoot.new()
	assert_true(
		root.random_source != null,
		"AppRoot.random_source must not be null after construction"
	)
	assert_true(
		root.random_source is RandomSource,
		"AppRoot.random_source must satisfy the RandomSource contract"
	)
	root.free()


func _test_app_root_random_source_is_godot_random_source() -> void:
	describe("AppRoot production random source instance is a GodotRandomSource")
	var root := AppRoot.new()
	assert_true(
		root.random_source is GodotRandomSource,
		"AppRoot.random_source must be a GodotRandomSource in production"
	)
	root.free()


# ── Weighted selection: single weight ────────────────────────────────────────

func _test_weighted_single_entry() -> void:
	describe("choose_weighted_index([5.0]) always returns 0")
	# Any valid roll (next_float in [0.0, 1.0)) must select the only entry.
	var src := FakeRandomSource.new([0.0, 0.5, 0.999], [])
	var weights: Array[float] = [5.0]
	assert_eq(src.choose_weighted_index(weights), 0, "roll 0.0 must select index 0")
	assert_eq(src.choose_weighted_index(weights), 0, "roll 0.5 must select index 0")
	assert_eq(src.choose_weighted_index(weights), 0, "roll 0.999 must select index 0")


# ── Weighted selection: zero weights skipped ─────────────────────────────────

func _test_weighted_zero_weights_skipped() -> void:
	describe("choose_weighted_index([0.0, 5.0, 0.0]) always returns index 1")
	# The only positive-weight entry is index 1. All rolls must land there.
	var src := FakeRandomSource.new([0.0, 0.5, 0.999], [])
	var weights: Array[float] = [0.0, 5.0, 0.0]
	assert_eq(
		src.choose_weighted_index(weights), 1,
		"roll 0.0 must select index 1 (only positive weight)"
	)
	assert_eq(
		src.choose_weighted_index(weights), 1,
		"roll 0.5 must select index 1 (only positive weight)"
	)
	assert_eq(
		src.choose_weighted_index(weights), 1,
		"roll 0.999 must select index 1 (only positive weight)"
	)


# ── Weighted selection: exact boundary behavior ───────────────────────────────
#
# weights [1.0, 3.0], total = 4.0
#   index 0 interval: [0.0, 1.0)  — roll < 1.0
#   index 1 interval: [1.0, 4.0)  — roll >= 1.0
#
# Boundary cases:
#   roll source 0.0   -> scaled roll = 0.0*4 = 0.0   -> 0.0 < 1.0  -> index 0
#   roll source 0.249 -> scaled roll = 0.249*4 = 0.996 -> 0.996 < 1.0 -> index 0
#   roll source 0.25  -> scaled roll = 0.25*4 = 1.0   -> NOT < 1.0 -> index 1
#   roll source 0.999 -> scaled roll = 0.999*4 = 3.996 -> index 1

func _test_weighted_boundary_roll_zero() -> void:
	describe("choose_weighted_index([1.0, 3.0]) with roll 0.0 selects index 0")
	var src := FakeRandomSource.new([0.0], [])
	var weights: Array[float] = [1.0, 3.0]
	assert_eq(
		src.choose_weighted_index(weights), 0,
		"roll=0.0 (scaled=0.0) must select index 0"
	)


func _test_weighted_boundary_roll_below_first_threshold() -> void:
	describe("choose_weighted_index([1.0, 3.0]) with roll 0.249 selects index 0")
	# scaled roll = 0.249 * 4 = 0.996 < 1.0 -> index 0
	var src := FakeRandomSource.new([0.249], [])
	var weights: Array[float] = [1.0, 3.0]
	assert_eq(
		src.choose_weighted_index(weights), 0,
		"roll=0.249 (scaled=0.996) must select index 0"
	)


func _test_weighted_boundary_roll_at_first_threshold() -> void:
	describe("choose_weighted_index([1.0, 3.0]) with roll 0.25 selects index 1")
	# scaled 0.25*4=1.0; cumulative after index 0 = 1.0; 1.0 < 1.0 is FALSE
	# -> advance; cumulative after index 1 = 4.0; 1.0 < 4.0 -> index 1
	var src := FakeRandomSource.new([0.25], [])
	var weights: Array[float] = [1.0, 3.0]
	assert_eq(
		src.choose_weighted_index(weights), 1,
		"roll=0.25 (scaled=1.0) must select index 1"
	)


func _test_weighted_boundary_roll_near_one() -> void:
	describe("choose_weighted_index([1.0, 3.0]) with roll 0.999 selects index 1")
	# scaled roll = 0.999 * 4 = 3.996 -> falls in index 1 interval [1.0, 4.0)
	var src := FakeRandomSource.new([0.999], [])
	var weights: Array[float] = [1.0, 3.0]
	assert_eq(
		src.choose_weighted_index(weights), 1,
		"roll=0.999 (scaled=3.996) must select index 1"
	)


# ── Weighted selection: three entries ────────────────────────────────────────
#
# weights [2.0, 5.0, 3.0], total = 10.0
#   index 0 interval: [0,  2.0)
#   index 1 interval: [2.0, 7.0)
#   index 2 interval: [7.0, 10.0)

func _test_weighted_three_entries_selects_middle() -> void:
	describe("choose_weighted_index([2.0, 5.0, 3.0]) with roll 0.5 selects index 1")
	# scaled roll = 0.5 * 10 = 5.0 -> NOT < 2.0 -> 5.0 < 7.0 -> index 1
	var src := FakeRandomSource.new([0.5], [])
	var weights: Array[float] = [2.0, 5.0, 3.0]
	assert_eq(
		src.choose_weighted_index(weights), 1,
		"roll=0.5 (scaled=5.0) must select middle index 1"
	)


func _test_weighted_three_entries_selects_last() -> void:
	describe("choose_weighted_index([2.0, 5.0, 3.0]) with roll 0.8 selects index 2")
	# scaled roll = 0.8 * 10 = 8.0 -> NOT < 2.0 -> NOT < 7.0 -> 8.0 < 10.0 -> index 2
	var src := FakeRandomSource.new([0.8], [])
	var weights: Array[float] = [2.0, 5.0, 3.0]
	assert_eq(
		src.choose_weighted_index(weights), 2,
		"roll=0.8 (scaled=8.0) must select last index 2"
	)


# ── Weighted selection: caller array not mutated ──────────────────────────────

func _test_weighted_does_not_mutate_caller_array() -> void:
	describe("choose_weighted_index does not mutate the caller's weight array")
	var src := FakeRandomSource.new([0.5], [])
	var weights: Array[float] = [1.0, 3.0]
	var weights_before: Array[float] = weights.duplicate()
	src.choose_weighted_index(weights)
	assert_eq(weights.size(), weights_before.size(), "weights array size must be unchanged")
	for i: int in range(weights.size()):
		assert_eq(
			weights[i], weights_before[i],
			"weights[%d] must be unchanged after choose_weighted_index" % i
		)
