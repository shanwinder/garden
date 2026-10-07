## plant_content_loader.gd
## Resource-loading adapter for authored PlantDefinition resources.
##
## Owns Godot ResourceLoader interactions and enforces strict all-or-nothing loading
## against an explicit deterministic path manifest.
##
## Architectural rules:
## - Belongs to the infrastructure content layer (src/infrastructure/content/).
## - Lightweight loading adapter: extends RefCounted (not Node, Autoload, singleton, or Resource).
## - Does not depend on AppRoot, GameSession, GameState, LifecycleCoordinator, or LocalSaveRepository.
## - Avoids depending on ContentCatalog from infrastructure; catalog validation remains at application level.
## - Deterministic production manifest: exactly five explicit resource paths.
## - No directory scanning, recursive discovery, or filesystem enumeration order dependence.
## - Strict all-or-nothing validation: rejects empty, non-res, duplicate, missing, null, or wrong-type resources.
## - Preserves caller's path order in path-based loading.
## - Does not mutate caller's path array; encapsulated result collections.
## - Retains authored Resource references without deep cloning.
class_name PlantContentLoader
extends RefCounted

## Explicit deterministic production resource manifest for MVP plants.
const PRODUCTION_PLANT_PATHS: Array[String] = [
	"res://content/plants/banana.tres",
	"res://content/plants/chili.tres",
	"res://content/plants/holy_basil.tres",
	"res://content/plants/jasmine.tres",
	"res://content/plants/marigold.tres",
]

const RES_PREFIX: String = "res://"


## Loads the standard five authored MVP plant definitions from the explicit production manifest.
func load_production_definitions() -> PlantContentLoadResult:
	return load_from_paths(PRODUCTION_PLANT_PATHS)


## Loads plant definitions from the provided [param paths], enforcing all-or-nothing validation.
##
## Validation requirements:
## - Rejects empty path strings
## - Rejects duplicate paths
## - Requires valid 'res://' prefix
## - Requires ResourceLoader to find and successfully load the resource
## - Rejects null resources
## - Requires the loaded Resource to be an instance of PlantDefinition
##
## Preserves caller's path order. Does not mutate [param paths].
func load_from_paths(paths: Array[String]) -> PlantContentLoadResult:
	var loaded_definitions: Array[PlantDefinition] = []
	var seen_paths: Dictionary = {}

	for path: String in paths:
		if path.is_empty():
			return PlantContentLoadResult.create_failed("", "Resource path cannot be empty")

		if seen_paths.has(path):
			return PlantContentLoadResult.create_failed(path, "Duplicate resource path in manifest: %s" % path)
		seen_paths[path] = true

		if not path.begins_with(RES_PREFIX):
			return PlantContentLoadResult.create_failed(path, "Resource path must begin with '%s': %s" % [RES_PREFIX, path])

		if not ResourceLoader.exists(path):
			return PlantContentLoadResult.create_failed(path, "Resource does not exist: %s" % path)

		var res: Resource = ResourceLoader.load(path)
		if res == null:
			return PlantContentLoadResult.create_failed(path, "Failed to load resource (returned null): %s" % path)

		if not (res is PlantDefinition):
			return PlantContentLoadResult.create_failed(
				path,
				"Resource is not PlantDefinition (type: %s): %s" % [res.get_class(), path]
			)

		loaded_definitions.append(res as PlantDefinition)

	return PlantContentLoadResult.create_loaded(loaded_definitions)
