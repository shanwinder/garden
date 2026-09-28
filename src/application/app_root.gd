## app_root.gd
## Single application-level composition root for Garden.
##
## AppRoot is the single composition root for long-lived application and
## infrastructure services. It explicitly constructs one SystemGameClock and
## exposes it as a typed dependency for downstream consumers.
##
## Dependency direction:
##   AppRoot constructs infrastructure services.
##   Application/domain code receives values from those services as arguments
##   rather than reading App.game_clock directly.
##
## Autoload rule:
##   Only one Autoload exists in this project: App -> res://src/application/app_root.gd.
##   GameClock, SystemGameClock, and FakeGameClock must not become Autoloads.
class_name AppRoot
extends Node

## The production clock for this application session.
## Constructed once at composition time; never replaced at runtime.
## Tests that require deterministic time should use FakeGameClock injected
## directly into the unit under test rather than replacing this value.
var game_clock: GameClock


func _init() -> void:
	game_clock = SystemGameClock.new()
