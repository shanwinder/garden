## game_state.gd
## Authoritative domain root for Garden's persistent runtime state.
##
## GameState is intended to become the single authoritative persistent runtime
## model for Garden.
##
## Architectural rules:
## - Nodes and scenes are visual representations (views/controllers) and must
##   not become canonical gameplay state.
## - This task defines the domain root TYPE only.
## - Runtime ownership will be established later by the application layer
##   (e.g., within GameSession).
## - State slices (economy, plants, visitors, weather, journal, etc.) will be
##   added only through explicit future contracts.
## - GameState is an in-memory domain model, not a file format. Serialization
##   and persistence boundaries belong to the infrastructure/persistence layer.
##
## Object contract:
## - Extends RefCounted (pure domain object; not a Node, not a Resource).
## - Constructable in isolation without SceneTree or engine lifecycle dependency.
## - Not an Autoload or singleton; separate constructions yield distinct instances.
## - Has no direct dependency on GameClock, RandomSource, App, or filesystem.
class_name GameState
extends RefCounted
