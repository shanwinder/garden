## game_session.gd
## Application-layer runtime coordinator and authoritative state owner.
##
## GameSession owns exactly one authoritative GameState instance during an
## active gameplay session.
##
## Architectural rules:
## - Belongs to the application layer.
## - Owns the canonical GameState instance; does not duplicate, serialize,
##   or replace it after construction.
## - Not a Node, Resource, Autoload, singleton, or manager class.
## - Does not expose a generic Variant/Dictionary state bag or direct
##   state-replacement API in this task.
## - Does not take infrastructure dependencies (GameClock, RandomSource,
##   PersistenceService, etc.) in Task 2.2.
class_name GameSession
extends RefCounted

var _state: GameState


func _init(initial_state: GameState = null) -> void:
	if initial_state == null:
		_state = GameState.new()
	else:
		_state = initial_state


## Returns the authoritative GameState instance owned by this session.
func get_state() -> GameState:
	return _state
