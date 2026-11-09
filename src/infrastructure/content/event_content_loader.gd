## event_content_loader.gd
## Resource-loading adapter for authored EventDefinition resources.
##
## Owns Godot ResourceLoader interactions and enforces strict all-or-nothing loading
## against an explicit deterministic path manifest.
##
## Architectural rules:
## - Belongs to the infrastructure content layer (src/infrastructure/content/).
## - Lightweight loading adapter: extends RefCounted (not Node, Autoload, singleton, or Resource).
## - Does not depend on AppRoot, GameSession, GameState, LifecycleCoordinator, or LocalSaveRepository.
## - Avoids depending on ContentCatalog from infrastructure; catalog validation remains at application level.
## - Deterministic production manifest: six explicit resource paths in ascending order
##   (five MVP ambient events plus one secret combination event).
## - No directory scanning, recursive discovery, or filesystem enumeration order dependence.
## - Strict all-or-nothing validation: rejects empty, non-res, duplicate, missing, null, or wrong-type resources.
## - Preserves caller's path order in path-based loading.
## - Does not mutate caller's path array; encapsulated result collections.
## - Retains authored Resource references without deep cloning.
class_name EventContentLoader
extends RefCounted

## Explicit deterministic production resource manifest for MVP ambient and secret events.
const PRODUCTION_EVENT_PATHS: Array[String] = [
	"res://content/events/bird_shade_song.tres",
	"res://content/events/cat_jasmine_night_rest.tres",
	"res://content/events/cat_sleeping_bench.tres",
	"res://content/events/firefly_night_glow.tres",
	"res://content/events/frog_rain_chorus.tres",
	"res://content/events/morning_butterflies.tres",
]

const RES_PREFIX: String = "res://"


## Loads the authored production event definitions from the explicit production manifest.
func load_production_definitions() -> EventContentLoadResult:
	return load_from_paths(PRODUCTION_EVENT_PATHS)


## Loads event definitions from an explicit Array[String] of resource paths.
## Enforces all-or-nothing validation and preserves the exact path order provided.
func load_from_paths(paths: Array[String]) -> EventContentLoadResult:
	if paths.is_empty():
		return EventContentLoadResult.create_failed("", "Resource path list must not be empty.")

	var seen_paths: Dictionary = {}
	var loaded_definitions: Array[EventDefinition] = []

	for path: String in paths:
		if path.is_empty():
			return EventContentLoadResult.create_failed(path, "Resource path must not be empty.")

		if not path.begins_with(RES_PREFIX):
			return EventContentLoadResult.create_failed(
				path,
				"Resource path must use the canonical 'res://' prefix."
			)

		if seen_paths.has(path):
			return EventContentLoadResult.create_failed(
				path,
				"Duplicate resource path in manifest."
			)
		seen_paths[path] = true

		if not ResourceLoader.exists(path):
			return EventContentLoadResult.create_failed(
				path,
				"Resource file does not exist at path."
			)

		var loaded_resource: Resource = ResourceLoader.load(path)
		if loaded_resource == null:
			return EventContentLoadResult.create_failed(
				path,
				"ResourceLoader failed to load resource at path."
			)

		if not (loaded_resource is EventDefinition):
			return EventContentLoadResult.create_failed(
				path,
				"Loaded resource is not an EventDefinition instance."
			)

		var event_def: EventDefinition = loaded_resource as EventDefinition
		loaded_definitions.append(event_def)

	return EventContentLoadResult.create_loaded(loaded_definitions)
