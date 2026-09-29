## fake_random_source.gd
## Deterministic test double for Garden's RandomSource infrastructure.
##
## FakeRandomSource lets tests supply exact scripted sequences for next_float()
## and range_int() independently. It is the preferred randomness fake for
## deterministic unit tests of visitor selection, event weighting, and any
## other code that depends on RandomSource.
##
## Usage:
##   var src := FakeRandomSource.new([0.1, 0.7], [3, 8])
##   src.next_float()       # -> 0.1
##   src.next_float()       # -> 0.7
##   src.range_int(1, 5)    # -> 3
##   src.range_int(5, 10)   # -> 8
##
## Guarantees:
##   - scripted floats are consumed in order and never cycled silently
##   - scripted ints are consumed in order and never cycled silently
##   - exhausted sequence fails loudly (assert)
##   - scripted float values are validated to be in [0.0, 1.0) at construction
##   - scripted int values are validated against the requested range at call time
##   - float and int streams are fully independent
##   - caller mutation of the original input arrays after construction does NOT
##     affect the scripted sequences (independent copies are made at construction)
##
## This class must exist only under tests/. It must not be used in production.
class_name FakeRandomSource
extends RandomSource

var _floats: Array[float]
var _ints: Array[int]
var _float_index: int
var _int_index: int


## Constructs a scripted fake with explicit float and integer sequences.
##
## Parameters:
##   scripted_floats — values returned sequentially by next_float().
##                     Every value must satisfy 0.0 <= v < 1.0.
##   scripted_ints   — values returned sequentially by range_int().
##                     Each value is validated against the requested range
##                     at call time, not at construction.
##
## Independence guarantee:
##   Independent copies of both arrays are made at construction time.
##   Mutating the caller's original arrays after construction has no effect
##   on the scripted sequences returned by this fake.
func _init(scripted_floats: Array[float], scripted_ints: Array[int]) -> void:
	# Validate all scripted floats at construction time so a mis-authored
	# test fails immediately rather than at an unpredictable call site.
	for v: float in scripted_floats:
		assert(
			v >= 0.0 and v < 1.0,
			"FakeRandomSource: scripted float %s is outside valid range [0.0, 1.0)" % v
		)

	# Make independent copies so that caller mutation after construction
	# cannot corrupt the scripted sequence.
	_floats = scripted_floats.duplicate()
	_ints = scripted_ints.duplicate()
	_float_index = 0
	_int_index = 0


## Consumes and returns the next scripted float value.
##
## Fails loudly if the scripted float sequence has been exhausted.
func next_float() -> float:
	assert(
		_float_index < _floats.size(),
		"FakeRandomSource.next_float: scripted float sequence exhausted (consumed %d of %d)" % [
			_float_index, _floats.size()
		]
	)
	var value: float = _floats[_float_index]
	_float_index += 1
	return value


## Consumes and returns the next scripted integer value.
##
## Validates:
##   - min_value <= max_value  (fails loudly otherwise)
##   - the scripted value falls within [min_value, max_value]  (fails loudly otherwise)
##   - the scripted integer sequence has not been exhausted  (fails loudly otherwise)
func range_int(min_value: int, max_value: int) -> int:
	assert(
		min_value <= max_value,
		"FakeRandomSource.range_int: min_value (%d) must be <= max_value (%d)" % [min_value, max_value]
	)
	assert(
		_int_index < _ints.size(),
		"FakeRandomSource.range_int: scripted integer sequence exhausted (consumed %d of %d)" % [
			_int_index, _ints.size()
		]
	)
	var value: int = _ints[_int_index]
	assert(
		value >= min_value and value <= max_value,
		"FakeRandomSource.range_int: scripted value %d is outside requested range [%d, %d]" % [
			value, min_value, max_value
		]
	)
	_int_index += 1
	return value
