## game_state.gd
## Authoritative domain root for Garden's persistent runtime state.
##
## GameState is the single authoritative persistent runtime model for Garden.
## It owns all persistent state slices, beginning with EconomyState in Milestone 2.
##
## Architectural rules:
## - Nodes and scenes are visual representations (views/controllers) and must
##   not become canonical gameplay state.
## - GameState is an in-memory domain model, not a file format. Serialization
##   and persistence boundaries belong to the infrastructure/persistence layer.
## - State slices are owned directly by GameState as typed domain objects.
## - GameState owns exactly one typed EconomyState instance.
## - Does not expose state replacement or setters for owned slices.
##
## Object contract:
## - Extends RefCounted (pure domain object; not a Node, not a Resource).
## - Constructable in isolation without SceneTree or engine lifecycle dependency.
## - Not an Autoload or singleton; separate constructions yield distinct instances.
## - Has no direct dependency on GameClock, RandomSource, App, or filesystem.
class_name GameState
extends RefCounted

var _economy: EconomyState


func _init() -> void:
	_economy = EconomyState.new()


## Returns the authoritative EconomyState slice owned by this GameState.
func get_economy() -> EconomyState:
	return _economy
