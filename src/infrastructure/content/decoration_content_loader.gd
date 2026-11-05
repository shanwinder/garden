## decoration_content_loader.gd
## Resource-loading adapter for authored DecorationDefinition resources.
##
## Owns Godot ResourceLoader interactions and enforces strict all-or-nothing loading
## against an explicit deterministic path manifest.
##
## Architectural rules:
## - Belongs to the infrastructure content layer (src/infrastructure/content/).
## - Lightweight loading adapter: extends RefCounted (not Node, Autoload, singleton, or Resource).
## - Does not depend on AppRoot, GameSession, GameState, LifecycleCoordinator, or LocalSaveRepository.
## - Avoids depending on ContentCatalog from infrastructure; catalog validation remains at application level.
## - Deterministic production manifest: exactly eight explicit resource paths.
## - No directory scanning, recursive discovery, or filesystem enumeration order dependence.
## - Strict all-or-nothing validation: rejects empty, non-res, duplicate, missing, null, or wrong-type resources.
## - Preserves caller's path order in path-based loading.
## - Does not mutate caller's path array; encapsulated result collections.
## - Retains authored Resource references without deep cloning.
class_name DecorationContentLoader
extends RefCounted

## Explicit deterministic production resource manifest for MVP decorations.
const PRODUCTION_DECORATION_PATHS: Array[String] = [
	"res://content/decorations/bench.tres",
	"res://content/decorations/clay_jar.tres",
	"res://content/decorations/garden_lamp.tres",
	"res://content/decorations/plant_pot.tres",
	"res://content/decorations/small_pond.tres",
	"res://content/decorations/small_table.tres",
	"res://content/decorations/watering_can.tres",
	"res://content/decorations/wooden_fence.tres",
]

const RES_PREFIX: String = "res://"


## Loads the standard eight authored MVP decoration definitions from the explicit production manifest.
func load_production_definitions() -> DecorationContentLoadResult:
	return load_from_paths(PRODUCTION_DECORATION_PATHS)


## Loads decoration definitions from the provided [param paths], enforcing all-or-nothing validation.
##
## Validation requirements:
## - Rejects empty path strings
## - Rejects duplicate paths
## - Requires valid 'res://' prefix
## - Requires ResourceLoader to find and successfully load the resource
## - Rejects null resources
## - Requires the loaded Resource to be an instance of DecorationDefinition
##
## Preserves caller's path order. Does not mutate [param paths].
func load_from_paths(paths: Array[String]) -> DecorationContentLoadResult:
	var loaded_definitions: Array[DecorationDefinition] = []
	var seen_paths: Dictionary = {}

	for path: String in paths:
		if path.is_empty():
			return DecorationContentLoadResult.create_failed("", "Resource path cannot be empty")

		if seen_paths.has(path):
			return DecorationContentLoadResult.create_failed(path, "Duplicate resource path in manifest: %s" % path)
		seen_paths[path] = true

		if not path.begins_with(RES_PREFIX):
			return DecorationContentLoadResult.create_failed(path, "Resource path must begin with '%s': %s" % [RES_PREFIX, path])

		if not ResourceLoader.exists(path):
			return DecorationContentLoadResult.create_failed(path, "Resource does not exist: %s" % path)

		var res: Resource = ResourceLoader.load(path)
		if res == null:
			return DecorationContentLoadResult.create_failed(path, "Failed to load resource (returned null): %s" % path)

		if not (res is DecorationDefinition):
			return DecorationContentLoadResult.create_failed(
				path,
				"Resource is not DecorationDefinition (type: %s): %s" % [res.get_class(), path]
			)

		loaded_definitions.append(res as DecorationDefinition)

	return DecorationContentLoadResult.create_loaded(loaded_definitions)
