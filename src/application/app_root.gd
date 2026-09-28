## app_root.gd
## Single application-level composition root for Garden.
##
## AppRoot is the single composition root for long-lived application and
## infrastructure services. It explicitly constructs one SystemGameClock and
## one GodotRandomSource, exposing each as a typed dependency.
##
## Composition:
##   AppRoot
##   ├── game_clock:    GameClock    -> SystemGameClock
##   └── random_source: RandomSource -> GodotRandomSource
##
## Dependency direction:
##   AppRoot constructs infrastructure services.
##   Application/domain code receives values from those services as arguments
##   rather than reading App.game_clock or App.random_source directly.
##
## Autoload rule:
##   Only one Autoload exists in this project: App -> res://src/application/app_root.gd.
##   GameClock, SystemGameClock, FakeGameClock, GodotRandomSource, and
##   FakeRandomSource must not become Autoloads.
class_name AppRoot
extends Node

## The production clock for this application session.
## Constructed once at composition time; never replaced at runtime.
## Tests that require deterministic time should use FakeGameClock injected
## directly into the unit under test rather than replacing this value.
var game_clock: GameClock

## The production random source for this application session.
## Constructed once at composition time; never replaced at runtime.
## Tests that require deterministic randomness should use FakeRandomSource
## injected directly into the unit under test rather than replacing this value.
var random_source: RandomSource


func _init() -> void:
	game_clock = SystemGameClock.new()
	random_source = GodotRandomSource.new()
