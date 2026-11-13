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
	"plant.chili": {
		PlantGrowth.Stage.PLANTED: "res://assets/plants/chili/chili_planted.png",
		PlantGrowth.Stage.SPROUT: "res://assets/plants/chili/chili_sprout.png",
		PlantGrowth.Stage.GROWING: "res://assets/plants/chili/chili_growing.png",
		PlantGrowth.Stage.MATURE: "res://assets/plants/chili/chili_mature.png",
	},
	"plant.jasmine": {
		PlantGrowth.Stage.PLANTED: "res://assets/plants/jasmine/jasmine_planted.png",
		PlantGrowth.Stage.SPROUT: "res://assets/plants/jasmine/jasmine_sprout.png",
		PlantGrowth.Stage.GROWING: "res://assets/plants/jasmine/jasmine_growing.png",
		PlantGrowth.Stage.MATURE: "res://assets/plants/jasmine/jasmine_mature.png",
	},
	"plant.banana": {
		PlantGrowth.Stage.PLANTED: "res://assets/plants/banana/banana_planted.png",
		PlantGrowth.Stage.SPROUT: "res://assets/plants/banana/banana_sprout.png",
		PlantGrowth.Stage.GROWING: "res://assets/plants/banana/banana_growing.png",
		PlantGrowth.Stage.MATURE: "res://assets/plants/banana/banana_mature.png",
	},
}

const DECORATION_TEXTURE_PATHS: Dictionary = {
	"decoration.clay_jar": "res://assets/decorations/clay_jar/clay_jar_idle.png",
	"decoration.bench": "res://assets/decorations/bench/bench_idle.png",
	"decoration.garden_lamp": "res://assets/decorations/garden_lamp/garden_lamp_off.png",
	"decoration.watering_can": "res://assets/decorations/watering_can/watering_can_idle.png",
	"decoration.wooden_fence": "res://assets/decorations/wooden_fence/wooden_fence_idle.png",
	"decoration.plant_pot": "res://assets/decorations/plant_pot/plant_pot_idle.png",
	"decoration.small_table": "res://assets/decorations/small_table/small_table_idle.png",
	"decoration.small_pond": "res://assets/decorations/small_pond/small_pond_idle.png",
}

const DECORATION_LIT_TEXTURE_PATHS: Dictionary = {
	"decoration.garden_lamp": "res://assets/decorations/garden_lamp/garden_lamp_on.png",
}

const VISITOR_TEXTURE_PATHS: Dictionary = {
	"visitor.cat": "res://assets/visitors/cat/cat_idle_00.png",
	"visitor.butterfly": "res://assets/visitors/butterfly/butterfly_flutter_00.png",
	"visitor.bird": "res://assets/visitors/bird/bird_idle_00.png",
	"visitor.frog": "res://assets/visitors/frog/frog_idle_00.png",
}

const VISITOR_ANIMATION_SPECS: Dictionary = {
	"visitor.cat": {
		"fps": 6.0,
		"loop": true,
		"frames": [
			"res://assets/visitors/cat/cat_idle_00.png",
			"res://assets/visitors/cat/cat_idle_01.png",
			"res://assets/visitors/cat/cat_idle_02.png",
			"res://assets/visitors/cat/cat_idle_03.png",
		],
	},
	"visitor.butterfly": {
		"fps": 12.0,
		"loop": true,
		"frames": [
			"res://assets/visitors/butterfly/butterfly_flutter_00.png",
			"res://assets/visitors/butterfly/butterfly_flutter_01.png",
			"res://assets/visitors/butterfly/butterfly_flutter_02.png",
			"res://assets/visitors/butterfly/butterfly_flutter_03.png",
		],
	},
	"visitor.bird": {
		"fps": 8.0,
		"loop": true,
		"frames": [
			"res://assets/visitors/bird/bird_idle_00.png",
			"res://assets/visitors/bird/bird_idle_01.png",
			"res://assets/visitors/bird/bird_idle_02.png",
			"res://assets/visitors/bird/bird_idle_03.png",
		],
	},
	"visitor.frog": {
		"fps": 6.0,
		"loop": true,
		"frames": [
			"res://assets/visitors/frog/frog_idle_00.png",
			"res://assets/visitors/frog/frog_idle_01.png",
			"res://assets/visitors/frog/frog_idle_02.png",
			"res://assets/visitors/frog/frog_idle_03.png",
		],
	},
}

const EFFECT_RAIN_RIPPLE_FRAMES: Array[String] = [
	"res://assets/effects/rain/effect_rain_ripple_00.png",
	"res://assets/effects/rain/effect_rain_ripple_01.png",
	"res://assets/effects/rain/effect_rain_ripple_02.png",
	"res://assets/effects/rain/effect_rain_ripple_03.png",
	"res://assets/effects/rain/effect_rain_ripple_04.png",
]

const EFFECT_HARVEST_PUFF_FRAMES: Array[String] = [
	"res://assets/effects/feedback/effect_harvest_puff_00.png",
	"res://assets/effects/feedback/effect_harvest_puff_01.png",
	"res://assets/effects/feedback/effect_harvest_puff_02.png",
	"res://assets/effects/feedback/effect_harvest_puff_03.png",
	"res://assets/effects/feedback/effect_harvest_puff_04.png",
]

static var _texture_cache: Dictionary = {}
static var _sprite_frames_cache: Dictionary = {}


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


## Clears internal cached texture and SpriteFrames references (primarily for test isolation).
static func clear_cache() -> void:
	_texture_cache.clear()
	_sprite_frames_cache.clear()


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


## Returns the resource path for a decoration sprite (preferring lit variant during evening/night if present).
static func get_decoration_texture_path(definition_id: String, time_period: String = "") -> String:
	var is_lit_hours: bool = (
		time_period == GardenTimePeriod.NIGHT
		or time_period == GardenTimePeriod.EVENING
	)
	if is_lit_hours and DECORATION_LIT_TEXTURE_PATHS.has(definition_id):
		var lit_path: String = str(DECORATION_LIT_TEXTURE_PATHS[definition_id])
		if ResourceLoader.exists(lit_path):
			return lit_path
	if DECORATION_TEXTURE_PATHS.has(definition_id):
		return str(DECORATION_TEXTURE_PATHS[definition_id])
	return ""


## Returns the cached Texture2D for a decoration sprite, or null for fallback.
static func get_decoration_texture(definition_id: String, time_period: String = "") -> Texture2D:
	return load_cached_texture(get_decoration_texture_path(definition_id, time_period))


## Returns the resource path for a Vertical Slice visitor sprite, or empty if unmapped.
static func get_visitor_texture_path(visitor_id: String) -> String:
	if VISITOR_TEXTURE_PATHS.has(visitor_id):
		return str(VISITOR_TEXTURE_PATHS[visitor_id])
	return ""


## Returns the cached Texture2D for a Vertical Slice visitor sprite, or null for fallback.
static func get_visitor_texture(visitor_id: String) -> Texture2D:
	return load_cached_texture(get_visitor_texture_path(visitor_id))


## Builds and caches a SpriteFrames resource for an animated visitor, or null if unmapped.
static func get_visitor_sprite_frames(visitor_id: String) -> SpriteFrames:
	if not VISITOR_ANIMATION_SPECS.has(visitor_id):
		return null
	var cache_key: String = "visitor:%s" % visitor_id
	if _sprite_frames_cache.has(cache_key):
		return _sprite_frames_cache[cache_key] as SpriteFrames
	var spec: Dictionary = VISITOR_ANIMATION_SPECS[visitor_id]
	var frame_paths: Array = spec.get("frames", [])
	var frames: SpriteFrames = _build_sprite_frames(
		&"idle",
		frame_paths,
		float(spec.get("fps", 8.0)),
		bool(spec.get("loop", true))
	)
	if frames != null:
		_sprite_frames_cache[cache_key] = frames
	return frames


## Returns cached SpriteFrames for raindrop water ripples, or null if unavailable.
static func get_rain_ripple_sprite_frames() -> SpriteFrames:
	var cache_key: String = "effect:rain_ripple"
	if _sprite_frames_cache.has(cache_key):
		return _sprite_frames_cache[cache_key] as SpriteFrames
	var frames: SpriteFrames = _build_sprite_frames(&"ripple", EFFECT_RAIN_RIPPLE_FRAMES, 10.0, true)
	if frames != null:
		_sprite_frames_cache[cache_key] = frames
	return frames


## Returns cached one-shot SpriteFrames for harvest/planting sparkle puffs, or null if unavailable.
static func get_harvest_puff_sprite_frames() -> SpriteFrames:
	var cache_key: String = "effect:harvest_puff"
	if _sprite_frames_cache.has(cache_key):
		return _sprite_frames_cache[cache_key] as SpriteFrames
	var frames: SpriteFrames = _build_sprite_frames(&"puff", EFFECT_HARVEST_PUFF_FRAMES, 12.0, false)
	if frames != null:
		_sprite_frames_cache[cache_key] = frames
	return frames


static func _build_sprite_frames(
	anim_name: StringName,
	frame_paths: Array,
	fps: float,
	loop: bool
) -> SpriteFrames:
	var loaded_textures: Array[Texture2D] = []
	for path_var: Variant in frame_paths:
		var tex: Texture2D = load_cached_texture(str(path_var))
		if tex == null:
			return null
		loaded_textures.append(tex)
	if loaded_textures.is_empty():
		return null

	var sf: SpriteFrames = SpriteFrames.new()
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop)
	for tex: Texture2D in loaded_textures:
		sf.add_frame(anim_name, tex)
	return sf


## Returns a UI thumbnail texture for a visitor (including firefly glow fallback for visitor.firefly).
static func get_visitor_thumbnail(visitor_id: String) -> Texture2D:
	var direct_tex: Texture2D = get_visitor_texture(visitor_id)
	if direct_tex != null:
		return direct_tex
	if visitor_id == "visitor.firefly":
		return get_firefly_glow_texture()
	return null


## Returns true if the visitor stands/rests on ground or surface (Option A bottom-center pivot).
## Airborne/perching flying visitors (butterfly, bird) keep Sprite2D centered at (0, 0).
static func is_grounded_visitor(visitor_id: String) -> bool:
	return visitor_id != "visitor.butterfly" and visitor_id != "visitor.bird"


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
