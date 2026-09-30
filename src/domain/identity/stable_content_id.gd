## stable_content_id.gd
## Canonical format validation primitive for stable content definition IDs.
##
## Provides stateless, deterministic validation for persistent content definition ID
## strings before any persistent plant, decoration, visitor, or event instance
## state is introduced.
##
## Architectural rules:
## - Belongs to the domain identity layer (src/domain/identity/).
## - Stateless validation primitive / namespace; contains no per-instance state.
## - Does not normalize, lowercase, trim, or mutate IDs.
## - Does not generate IDs or runtime instance IDs.
## - Validates syntax only; does not whitelist or restrict content namespaces.
## - Independent of SceneTree, App, GameClock, RandomSource, filesystem, and locale.
## - Validation is a pure query: returns false for invalid input without emitting push_error().
class_name StableContentId
extends RefCounted

const _CODE_A: int = 97 # 'a'
const _CODE_Z: int = 122 # 'z'
const _CODE_0: int = 48 # '0'
const _CODE_9: int = 57 # '9'
const _CODE_UNDERSCORE: int = 95 # '_'


## Returns true if [param value] conforms to the canonical stable content ID format.
##
## Canonical format:
## - At least two dot-separated segments (<segment>.<segment>[.<segment>...]).
## - No segment may be empty.
## - Each segment must begin with a lowercase ASCII letter (a-z).
## - Subsequent characters in each segment must be lowercase ASCII letters (a-z),
##   digits (0-9), or underscores (_).
static func is_valid(value: String) -> bool:
	if value.is_empty():
		return false

	var segments: PackedStringArray = value.split(".", true)
	if segments.size() < 2:
		return false

	for segment: String in segments:
		if segment.is_empty():
			return false

		var first_code: int = segment.unicode_at(0)
		if first_code < _CODE_A or first_code > _CODE_Z:
			return false

		var seg_len: int = segment.length()
		for i: int in range(1, seg_len):
			var code: int = segment.unicode_at(i)
			var is_lower: bool = code >= _CODE_A and code <= _CODE_Z
			var is_digit: bool = code >= _CODE_0 and code <= _CODE_9
			var is_underscore: bool = code == _CODE_UNDERSCORE
			if not (is_lower or is_digit or is_underscore):
				return false

	return true
