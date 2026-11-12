## garden_asset_catalog.gd
## Presentation-layer mapping from stable domain IDs and growth stages to imported 2D textures.
##
## Architectural rules:
## - Belongs to the presentation layer (src/presentation/garden/).
## - Caches Texture2D loads cleanly; never queries filesystems per-frame.
## - Never duplicates or mutates GameState or ContentCatalog.
## - Preserves Option A (bottom-center grounded sprite) vs centered airborne anchor semantics.
class_name GardenAssetCatalog
extends RefCounted

const BG_MAIN_GARDEN_PATH: String = "res://assets/environment/background/bg_main_garden.png"

const EFFECT_RAIN_STREAK_PATH: String = "res://assets/effects/rain/effect_rain_streak.png"
const EFFECT_FIREFLY_GLOW_PATH: String = "res://assets/effects/firefly/effect_firefly_glow.png"

const PLANT_STAGE_TEXTURE_PATHS: Dictionary = {
	"plant.holy_basil": {
		PlantGrowth.Stage.PLANTED: "res://assets/plants/holy_basil/holy_basil_planted.png",
		PlantGrowth.Stage.SPROUT: "res://assets/plants/holy_basil/holy_basil_sprout.png",
		PlantGrowth.Stage.GROWING: "res://assets/plants/holy_basil/holy_basil_growing.png",
		PlantGrowth.Stage.MATURE: "res://assets/plants/holy_basil/holy_basil_mature.png",
	},
	"plant.marigold": {
		PlantGrowth.Stage.PLANTED: "res://assets/plants/marigold/marigold_planted.png",
		PlantGrowth.Stage.SPROUT: "res://assets/plants/marigold/marigold_sprout.png",
		PlantGrowth.Stage.GROWING: "res://assets/plants/marigold/marigold_growing.png",
		PlantGrowth.Stage.MATURE: "res://assets/plants/marigold/marigold_mature.png",
	},
}

const DECORATION_TEXTURE_PATHS: Dictionary = {
	"decoration.clay_jar": "res://assets/decorations/clay_jar/clay_jar_idle.png",
	"decoration.bench": "res://assets/decorations/bench/bench_idle.png",
}

const VISITOR_TEXTURE_PATHS: Dictionary = {
	"visitor.cat": "res://assets/visitors/cat/cat_idle_00.png",
	"visitor.butterfly": "res://assets/visitors/butterfly/butterfly_flutter_00.png",
}

static var _texture_cache: Dictionary = {}


## Loads and caches a Texture2D by resource path, returning null if unavailable.
static func load_cached_texture(resource_path: String) -> Texture2D:
	if resource_path.is_empty():
		return null
	if _texture_cache.has(resource_path):
		return _texture_cache[resource_path] as Texture2D
	if not ResourceLoader.exists(resource_path):
		return null
	var loaded: Resource = ResourceLoader.load(resource_path)
	if loaded is Texture2D:
		var tex: Texture2D = loaded as Texture2D
		_texture_cache[resource_path] = tex
		return tex
	return null


## Clears internal cached texture references (primarily for test isolation).
static func clear_cache() -> void:
	_texture_cache.clear()


## Returns the 1080x1920 background artwork texture for the main garden scene.
static func get_background_texture() -> Texture2D:
	return load_cached_texture(BG_MAIN_GARDEN_PATH)


## Returns the resource path for a Vertical Slice plant stage sprite, or empty if unmapped.
static func get_plant_texture_path(definition_id: String, stage: PlantGrowth.Stage) -> String:
	if not PLANT_STAGE_TEXTURE_PATHS.has(definition_id):
		return ""
	var stage_map: Dictionary = PLANT_STAGE_TEXTURE_PATHS[definition_id]
	if stage_map.has(stage):
		return str(stage_map[stage])
	if stage_map.has(PlantGrowth.Stage.PLANTED):
		return str(stage_map[PlantGrowth.Stage.PLANTED])
	return ""


## Returns the cached Texture2D for a Vertical Slice plant stage sprite, or null for fallback.
static func get_plant_texture(definition_id: String, stage: PlantGrowth.Stage) -> Texture2D:
	return load_cached_texture(get_plant_texture_path(definition_id, stage))


## Returns the resource path for a Vertical Slice decoration sprite, or empty if unmapped.
static func get_decoration_texture_path(definition_id: String) -> String:
	if DECORATION_TEXTURE_PATHS.has(definition_id):
		return str(DECORATION_TEXTURE_PATHS[definition_id])
	return ""


## Returns the cached Texture2D for a Vertical Slice decoration sprite, or null for fallback.
static func get_decoration_texture(definition_id: String) -> Texture2D:
	return load_cached_texture(get_decoration_texture_path(definition_id))


## Returns the resource path for a Vertical Slice visitor sprite, or empty if unmapped.
static func get_visitor_texture_path(visitor_id: String) -> String:
	if VISITOR_TEXTURE_PATHS.has(visitor_id):
		return str(VISITOR_TEXTURE_PATHS[visitor_id])
	return ""


## Returns the cached Texture2D for a Vertical Slice visitor sprite, or null for fallback.
static func get_visitor_texture(visitor_id: String) -> Texture2D:
	return load_cached_texture(get_visitor_texture_path(visitor_id))


## Returns true if the visitor stands/rests on ground or surface (Option A bottom-center pivot).
## Airborne insects like butterfly keep Sprite2D centered at (0, 0).
static func is_grounded_visitor(visitor_id: String) -> bool:
	return visitor_id != "visitor.butterfly"


## Returns the soft rain streak particle texture.
static func get_rain_streak_texture() -> Texture2D:
	return load_cached_texture(EFFECT_RAIN_STREAK_PATH)


## Returns the radial firefly / warm light glow texture.
static func get_firefly_glow_texture() -> Texture2D:
	return load_cached_texture(EFFECT_FIREFLY_GLOW_PATH)


## Computes Option A bottom-center Sprite2D offset so position matches ground contact point.
static func compute_bottom_center_offset(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	return Vector2(0.0, -float(texture.get_height()) * 0.5)
