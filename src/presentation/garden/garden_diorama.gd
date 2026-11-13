## garden_diorama.gd
## Illustrated 2D garden diorama presenting the background, placed plants/decorations,
## visitors, and deterministic day/night/weather atmosphere without owning GameState.
##
## Architectural rules:
## - Belongs to the presentation layer (src/presentation/garden/).
## - Reads authoritative domain objects passed from GardenView; never mutates GameState.
## - Preserves ASSET_PIPELINE.md 1:1 sprite scale (Vector2.ONE) and Option A bottom-center pivot
##   for grounded sprites vs centered pivot for airborne visitors (butterfly).
## - Zero per-plant Timers or _process growth loops; idle micro-motion uses Tween when in tree.
class_name GardenDiorama
extends Control

signal item_selected(item_kind: String, runtime_instance_id: String)
signal cell_selected(zone_id: String, grid_x: int, grid_y: int)
signal visitor_selected(visitor_id: String)

const DEFAULT_DIORAMA_HEIGHT: float = 680.0
const BACKGROUND_TOP_LEFT_OFFSET: Vector2 = Vector2(-540.0, -720.0)

const ZONE_MAIN_ORIGIN: Vector2 = Vector2(-285.0, 345.0)
const ZONE_MAIN_COL_STEP: Vector2 = Vector2(102.0, 4.0)
const ZONE_MAIN_ROW_STEP: Vector2 = Vector2(-8.0, 76.0)

const ZONE_ADJACENT_ORIGIN: Vector2 = Vector2(95.0, 375.0)
const ZONE_ADJACENT_COL_STEP: Vector2 = Vector2(68.0, 12.0)
const ZONE_ADJACENT_ROW_STEP: Vector2 = Vector2(-6.0, 92.0)

const BENCH_CAT_PERCH_OFFSET: Vector2 = Vector2(-8.0, -74.0)
const JASMINE_CAT_REST_OFFSET: Vector2 = Vector2(36.0, 6.0)
const DEFAULT_CAT_GROUND_POS: Vector2 = Vector2(185.0, 540.0)
const DEFAULT_BUTTERFLY_POS: Vector2 = Vector2(-20.0, 290.0)
const DEFAULT_FIREFLY_POS: Vector2 = Vector2(-60.0, 250.0)
const FLOWER_BUTTERFLY_OFFSET: Vector2 = Vector2(24.0, -172.0)

const POND_FROG_OFFSET: Vector2 = Vector2(-68.0, 14.0)
const JAR_FROG_OFFSET: Vector2 = Vector2(72.0, 10.0)
const DEFAULT_FROG_GROUND_POS: Vector2 = Vector2(145.0, 500.0)

const FENCE_BIRD_PERCH_OFFSET: Vector2 = Vector2(0.0, -124.0)
const LAMP_BIRD_PERCH_OFFSET: Vector2 = Vector2(4.0, -214.0)
const TABLE_BIRD_PERCH_OFFSET: Vector2 = Vector2(28.0, -118.0)
const JAR_BIRD_PERCH_OFFSET: Vector2 = Vector2(-42.0, -206.0)
const BANANA_BIRD_PERCH_OFFSET: Vector2 = Vector2(36.0, -246.0)
const BENCH_BIRD_PERCH_OFFSET: Vector2 = Vector2(88.0, -172.0)
const DEFAULT_BIRD_PERCH_POS: Vector2 = Vector2(-150.0, 178.0)

const FIREFLY_ANCHORS: Array[Vector2] = [
	Vector2(-240.0, 230.0),
	Vector2(-90.0, 260.0),
	Vector2(65.0, 210.0),
	Vector2(195.0, 305.0),
	Vector2(-150.0, 360.0),
]

const RAIN_RIPPLE_DEFAULT_POSITIONS: Array[Vector2] = [
	Vector2(-180.0, 485.0),
	Vector2(35.0, 520.0),
	Vector2(205.0, 470.0),
]

const MAX_AMBIENT_PLANT_SWAYS: int = 3

var _world_origin: Node2D = null
var _world_root: Node2D = null
var _background_sprite: Sprite2D = null
var _zone_highlights_layer: Node2D = null
var _rain_ripples_group: Node2D = null
var _placed_items_root: Node2D = null
var _visitors_root: Node2D = null
var _feedback_effects_layer: Node2D = null
var _lights_layer: Node2D = null
var _house_porch_glow: Sprite2D = null
var _fireflies_group: Node2D = null
var _rain_particles: CPUParticles2D = null
var _mist_overlay: ColorRect = null

var _active_tweens: Array[Tween] = []
var _active_lamp_glows: Array[Sprite2D] = []
var _item_entries: Dictionary = {} # runtime_instance_id -> Dictionary{node, kind, zone_id, grid_x, grid_y, world_pos}
var _zone_cells: Array[Dictionary] = [] # {zone_id, grid_x, grid_y, world_pos, occupied, marker}
var _active_visitor_node: Node2D = null
var _active_visitor_id: String = ""

var _selected_plant_id: String = ""
var _selected_decoration_id: String = ""
var _active_zone_id: String = GardenZone.ZONE_MAIN
var _target_zone_id: String = ""
var _target_grid_x: int = -1
var _target_grid_y: int = -1
var _is_move_mode: bool = false
var _last_time_period: String = GardenTimePeriod.DAY
var _last_weather_state: String = GardenWeather.CLEAR


func _ready() -> void:
	_resolve_nodes()
	_setup_static_layers()
	_update_world_origin_position()


func _exit_tree() -> void:
	_kill_active_tweens()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_world_origin_position()


func _resolve_nodes() -> void:
	if _world_origin == null:
		_world_origin = get_node_or_null("WorldOrigin") as Node2D
	if _world_root == null:
		_world_root = get_node_or_null("WorldOrigin/WorldRoot") as Node2D
	if _background_sprite == null:
		_background_sprite = get_node_or_null("WorldOrigin/WorldRoot/BackgroundSprite") as Sprite2D
	if _zone_highlights_layer == null:
		_zone_highlights_layer = get_node_or_null("WorldOrigin/WorldRoot/ZoneHighlightsLayer") as Node2D
	if _rain_ripples_group == null:
		_rain_ripples_group = get_node_or_null("WorldOrigin/WorldRoot/RainRipplesGroup") as Node2D
	if _placed_items_root == null:
		_placed_items_root = get_node_or_null("WorldOrigin/WorldRoot/PlacedItemsRoot") as Node2D
	if _visitors_root == null:
		_visitors_root = get_node_or_null("WorldOrigin/WorldRoot/VisitorsRoot") as Node2D
	if _feedback_effects_layer == null:
		_feedback_effects_layer = get_node_or_null("WorldOrigin/WorldRoot/FeedbackEffectsLayer") as Node2D
	if _lights_layer == null:
		_lights_layer = get_node_or_null("WorldOrigin/LightsLayer") as Node2D
	if _house_porch_glow == null:
		_house_porch_glow = get_node_or_null("WorldOrigin/LightsLayer/HousePorchGlow") as Sprite2D
	if _fireflies_group == null:
		_fireflies_group = get_node_or_null("WorldOrigin/LightsLayer/FirefliesGroup") as Node2D
	if _rain_particles == null:
		_rain_particles = get_node_or_null("WorldOrigin/RainParticles") as CPUParticles2D
	if _mist_overlay == null:
		_mist_overlay = get_node_or_null("MistOverlay") as ColorRect


func _setup_static_layers() -> void:
	if _background_sprite != null:
		_background_sprite.texture = GardenAssetCatalog.get_background_texture()
		_background_sprite.centered = false
		_background_sprite.offset = Vector2.ZERO
		_background_sprite.position = BACKGROUND_TOP_LEFT_OFFSET
		_background_sprite.scale = Vector2.ONE
		_background_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var glow_tex: Texture2D = GardenAssetCatalog.get_firefly_glow_texture()
	if _house_porch_glow != null and glow_tex != null:
		_house_porch_glow.texture = glow_tex
		_house_porch_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	if _rain_particles != null:
		var rain_tex: Texture2D = GardenAssetCatalog.get_rain_streak_texture()
		if rain_tex != null:
			_rain_particles.texture = rain_tex
		_rain_particles.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _update_world_origin_position() -> void:
	_resolve_nodes()
	if _world_origin == null:
		return
	var width: float = size.x if size.x > 0.0 else 960.0
	_world_origin.position = Vector2(width * 0.5, 0.0)


## Maps logical (zone_id, grid_x, grid_y) coordinates deterministically to diorama WorldOrigin pixels.
static func compute_grid_world_position(zone_id: String, grid_x: int, grid_y: int) -> Vector2:
	var clamped_x: int = maxi(0, grid_x)
	var clamped_y: int = maxi(0, grid_y)
	if zone_id == GardenZone.ZONE_ADJACENT_1:
		return (
			ZONE_ADJACENT_ORIGIN
			+ ZONE_ADJACENT_COL_STEP * float(clamped_x)
			+ ZONE_ADJACENT_ROW_STEP * float(clamped_y)
		)
	return (
		ZONE_MAIN_ORIGIN
		+ ZONE_MAIN_COL_STEP * float(clamped_x)
		+ ZONE_MAIN_ROW_STEP * float(clamped_y)
	)


## Rebuilds the diorama visuals cleanly from authoritative state and snapshot context.
func render_garden(
	state: GameState,
	catalog: ContentCatalog,
	now_utc: int,
	snapshot: GardenSnapshot,
	active_visitor_id: String,
	selected_plant_id: String,
	selected_decoration_id: String,
	active_zone_id: String,
	locale: String = GardenLocalization.DEFAULT_LOCALE,
	target_zone_id: String = "",
	target_grid_x: int = -1,
	target_grid_y: int = -1,
	is_move_mode: bool = false
) -> void:
	_resolve_nodes()
	_setup_static_layers()
	_update_world_origin_position()
	_kill_active_tweens()

	_selected_plant_id = selected_plant_id
	_selected_decoration_id = selected_decoration_id
	_active_zone_id = active_zone_id if not active_zone_id.is_empty() else GardenZone.ZONE_MAIN
	_target_zone_id = target_zone_id
	_target_grid_x = target_grid_x
	_target_grid_y = target_grid_y
	_is_move_mode = is_move_mode
	_active_visitor_id = active_visitor_id

	var time_period: String = snapshot.get_time_period() if snapshot != null else GardenTimePeriod.period_for_utc_seconds(now_utc)
	var weather_state: String = snapshot.get_weather_state() if snapshot != null else GardenWeather.weather_for_utc_seconds(now_utc)
	_last_time_period = time_period
	_last_weather_state = weather_state

	_clear_node_children(_zone_highlights_layer)
	_clear_node_children(_rain_ripples_group)
	_clear_node_children(_placed_items_root)
	_clear_node_children(_visitors_root)
	_clear_node_children(_fireflies_group)
	_active_lamp_glows.clear()
	_item_entries.clear()
	_zone_cells.clear()
	_active_visitor_node = null

	_render_zone_markers(state, snapshot)

	var plants: Array[PlantState] = state.get_plants().get_all_plants() if state != null and state.get_plants() != null else []
	var decor_collection: DecorationCollectionState = state.get_decorations() if state != null else null
	var decorations: Array[DecorationState] = decor_collection.get_all_decorations() if decor_collection != null else []

	var bench_pos: Vector2 = Vector2.INF
	var pond_pos: Vector2 = Vector2.INF
	var jar_pos: Vector2 = Vector2.INF
	var fence_pos: Vector2 = Vector2.INF
	var lamp_pos: Vector2 = Vector2.INF
	var table_pos: Vector2 = Vector2.INF
	var marigold_mature_pos: Vector2 = Vector2.INF
	var jasmine_mature_pos: Vector2 = Vector2.INF
	var banana_mature_pos: Vector2 = Vector2.INF
	var any_mature_pos: Vector2 = Vector2.INF
	var any_plant_pos: Vector2 = Vector2.INF

	for decor_state: DecorationState in decorations:
		var inst_id: String = decor_state.get_runtime_instance_id()
		var def_id: String = decor_state.get_definition_id()
		var world_pos: Vector2 = compute_grid_world_position(
			decor_state.get_zone_id(),
			decor_state.get_grid_x(),
			decor_state.get_grid_y()
		)
		match def_id:
			"decoration.bench":
				if bench_pos == Vector2.INF:
					bench_pos = world_pos
			"decoration.small_pond":
				if pond_pos == Vector2.INF:
					pond_pos = world_pos
			"decoration.clay_jar":
				if jar_pos == Vector2.INF:
					jar_pos = world_pos
			"decoration.wooden_fence":
				if fence_pos == Vector2.INF:
					fence_pos = world_pos
			"decoration.garden_lamp":
				if lamp_pos == Vector2.INF:
					lamp_pos = world_pos
			"decoration.small_table":
				if table_pos == Vector2.INF:
					table_pos = world_pos

		var item_node: Node2D = _create_decoration_node(
			inst_id,
			def_id,
			world_pos,
			inst_id == _selected_decoration_id and _selected_plant_id.is_empty(),
			catalog,
			time_period,
			locale
		)
		if _placed_items_root != null:
			_placed_items_root.add_child(item_node)
		_item_entries[inst_id] = {
			"node": item_node,
			"kind": "decoration",
			"zone_id": decor_state.get_zone_id(),
			"grid_x": decor_state.get_grid_x(),
			"grid_y": decor_state.get_grid_y(),
			"world_pos": world_pos,
		}

	var sway_candidates: Array[Node2D] = []
	for plant_state: PlantState in plants:
		var inst_id: String = plant_state.get_runtime_instance_id()
		var def_id: String = plant_state.get_definition_id()
		var definition: PlantDefinition = catalog.get_plant(def_id) if catalog != null else null
		var stage: PlantGrowth.Stage = (
			PlantGrowth.stage_for_state_at(plant_state, definition, now_utc)
			if definition != null
			else PlantGrowth.Stage.PLANTED
		)
		var world_pos: Vector2 = compute_grid_world_position(
			plant_state.get_zone_id(),
			plant_state.get_grid_x(),
			plant_state.get_grid_y()
		)
		if any_plant_pos == Vector2.INF:
			any_plant_pos = world_pos
		if stage == PlantGrowth.Stage.MATURE:
			if any_mature_pos == Vector2.INF:
				any_mature_pos = world_pos
			if def_id == "plant.marigold" and marigold_mature_pos == Vector2.INF:
				marigold_mature_pos = world_pos
			if def_id == "plant.jasmine" and jasmine_mature_pos == Vector2.INF:
				jasmine_mature_pos = world_pos
			if def_id == "plant.banana" and banana_mature_pos == Vector2.INF:
				banana_mature_pos = world_pos

		var item_node: Node2D = _create_plant_node(
			inst_id,
			def_id,
			stage,
			world_pos,
			inst_id == _selected_plant_id,
			catalog,
			locale
		)
		if _placed_items_root != null:
			_placed_items_root.add_child(item_node)
		if stage >= PlantGrowth.Stage.GROWING or inst_id == _selected_plant_id:
			var plant_sprite: Node2D = item_node.get_node_or_null("Sprite") as Node2D
			if plant_sprite != null:
				if inst_id == _selected_plant_id:
					sway_candidates.push_front(plant_sprite)
				else:
					sway_candidates.append(plant_sprite)
		_item_entries[inst_id] = {
			"node": item_node,
			"kind": "plant",
			"zone_id": plant_state.get_zone_id(),
			"grid_x": plant_state.get_grid_x(),
			"grid_y": plant_state.get_grid_y(),
			"world_pos": world_pos,
		}

	_start_plant_sway_tweens(sway_candidates)

	var flower_mature_pos: Vector2 = marigold_mature_pos if marigold_mature_pos != Vector2.INF else jasmine_mature_pos
	var visitor_anchors: Dictionary = {
		"bench_pos": bench_pos,
		"jasmine_mature_pos": jasmine_mature_pos,
		"flower_mature_pos": flower_mature_pos,
		"any_mature_pos": any_mature_pos,
		"any_plant_pos": any_plant_pos,
		"pond_pos": pond_pos,
		"jar_pos": jar_pos,
		"fence_pos": fence_pos,
		"lamp_pos": lamp_pos,
		"table_pos": table_pos,
		"banana_mature_pos": banana_mature_pos,
	}
	_render_active_visitor(
		active_visitor_id,
		visitor_anchors,
		catalog,
		locale
	)
	_apply_atmosphere(time_period, weather_state, active_visitor_id, snapshot, pond_pos)


## Updates zone cell target / move-mode highlights in place without rebuilding placed sprites.
func set_placement_highlight(
	target_zone_id: String,
	target_grid_x: int,
	target_grid_y: int,
	is_move_mode: bool,
	active_zone_id: String = ""
) -> void:
	_target_zone_id = target_zone_id
	_target_grid_x = target_grid_x
	_target_grid_y = target_grid_y
	_is_move_mode = is_move_mode
	if not active_zone_id.is_empty():
		_active_zone_id = active_zone_id
	_apply_zone_cell_styles()


## Updates selection ring visibility without rebuilding the full scene.
func set_selected_item(selected_plant_id: String, selected_decoration_id: String) -> void:
	_selected_plant_id = selected_plant_id
	_selected_decoration_id = selected_decoration_id
	for inst_id_var: Variant in _item_entries.keys():
		var inst_id: String = str(inst_id_var)
		var entry: Dictionary = _item_entries[inst_id]
		var node: Node2D = entry.get("node") as Node2D
		if node == null:
			continue
		var ring: CanvasItem = node.get_node_or_null("SelectionRing") as CanvasItem
		if ring == null:
			continue
		var kind: String = str(entry.get("kind", ""))
		if kind == "plant":
			ring.visible = (inst_id == _selected_plant_id)
		else:
			ring.visible = (inst_id == _selected_decoration_id and _selected_plant_id.is_empty())


## Clears temporary diorama overlays and stops animations when startup/save is blocked.
func clear_for_blocked_state() -> void:
	_resolve_nodes()
	_kill_active_tweens()
	_clear_node_children(_zone_highlights_layer)
	_clear_node_children(_rain_ripples_group)
	_clear_node_children(_placed_items_root)
	_clear_node_children(_visitors_root)
	_clear_node_children(_feedback_effects_layer)
	_clear_node_children(_fireflies_group)
	_active_lamp_glows.clear()
	_item_entries.clear()
	_zone_cells.clear()
	_active_visitor_node = null
	_active_visitor_id = ""
	if _rain_ripples_group != null:
		_rain_ripples_group.visible = false
	if _rain_particles != null:
		_rain_particles.emitting = false
		_rain_particles.visible = false
	if _house_porch_glow != null:
		_house_porch_glow.visible = false


func _render_zone_markers(state: GameState, snapshot: GardenSnapshot) -> void:
	if _zone_highlights_layer == null:
		return
	var unlocked_zones: Array[String] = [GardenZone.ZONE_MAIN]
	var journal: JournalState = state.get_journal() if state != null else null
	if GardenZone.is_zone_unlocked(GardenZone.ZONE_ADJACENT_1, snapshot, journal):
		unlocked_zones.append(GardenZone.ZONE_ADJACENT_1)

	for z_id: String in unlocked_zones:
		var width_cells: int = GardenZone.get_grid_width(z_id)
		var height_cells: int = GardenZone.get_grid_height(z_id)
		for gy: int in range(height_cells):
			for gx: int in range(width_cells):
				var world_pos: Vector2 = compute_grid_world_position(z_id, gx, gy)
				var occupant: Dictionary = GardenPlacement.get_occupant_at(state, z_id, gx, gy) if state != null else {}
				var occupied: bool = not occupant.is_empty()
				var marker: Polygon2D = Polygon2D.new()
				marker.position = world_pos
				marker.polygon = _build_ellipse_points(28.0, 12.0, 12)
				_zone_highlights_layer.add_child(marker)
				_zone_cells.append({
					"zone_id": z_id,
					"grid_x": gx,
					"grid_y": gy,
					"world_pos": world_pos,
					"occupied": occupied,
					"marker": marker,
				})

	_apply_zone_cell_styles()


func _apply_zone_cell_styles() -> void:
	for cell: Dictionary in _zone_cells:
		var marker: Polygon2D = cell.get("marker") as Polygon2D
		if marker == null or not is_instance_valid(marker):
			continue
		var z_id: String = str(cell.get("zone_id", GardenZone.ZONE_MAIN))
		var gx: int = int(cell.get("grid_x", -1))
		var gy: int = int(cell.get("grid_y", -1))
		var occupied: bool = bool(cell.get("occupied", false))
		var is_active_zone: bool = (z_id == _active_zone_id)
		var is_target: bool = (
			z_id == _target_zone_id
			and gx == _target_grid_x
			and gy == _target_grid_y
		)
		if is_target:
			marker.color = Color(0.98, 0.86, 0.34, 0.68)
			marker.scale = Vector2(1.22, 1.22)
		elif _is_move_mode and not occupied:
			marker.color = Color(0.55, 0.94, 0.60, 0.48 if is_active_zone else 0.30)
			marker.scale = Vector2(1.12, 1.12)
		elif occupied:
			marker.color = Color(0.88, 0.84, 0.64, 0.10 if is_active_zone else 0.06)
			marker.scale = Vector2.ONE
		else:
			var marker_alpha: float = 0.24 if is_active_zone else 0.12
			marker.color = (
				Color(0.95, 0.88, 0.56, marker_alpha)
				if z_id == GardenZone.ZONE_MAIN
				else Color(0.68, 0.88, 0.72, marker_alpha)
			)
			marker.scale = Vector2.ONE


func _create_plant_node(
	instance_id: String,
	definition_id: String,
	stage: PlantGrowth.Stage,
	world_pos: Vector2,
	is_selected: bool,
	catalog: ContentCatalog,
	locale: String
) -> Node2D:
	var container: Node2D = _create_base_item_node(instance_id, world_pos, is_selected, 38.0)
	var tex: Texture2D = GardenAssetCatalog.get_plant_texture(definition_id, stage)
	if tex != null:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = tex
		sprite.centered = true
		sprite.offset = GardenAssetCatalog.compute_bottom_center_offset(tex)
		sprite.scale = Vector2.ONE
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		container.add_child(sprite)
	else:
		var plant_def: PlantDefinition = catalog.get_plant(definition_id) if catalog != null else null
		var label_text: String = GardenLocalization.get_plant_name(definition_id, locale, plant_def)
		_add_fallback_token(
			container,
			label_text,
			_fallback_color_for_plant_stage(stage),
			true
		)
	return container


func _decoration_shadow_radius(definition_id: String) -> float:
	match definition_id:
		"decoration.small_pond":
			return 64.0
		"decoration.bench":
			return 52.0
		"decoration.wooden_fence":
			return 48.0
		"decoration.garden_lamp":
			return 26.0
		_:
			return 40.0


func _create_decoration_node(
	instance_id: String,
	definition_id: String,
	world_pos: Vector2,
	is_selected: bool,
	catalog: ContentCatalog,
	time_period: String,
	locale: String
) -> Node2D:
	var radius: float = _decoration_shadow_radius(definition_id)
	var container: Node2D = _create_base_item_node(instance_id, world_pos, is_selected, radius)
	var tex: Texture2D = GardenAssetCatalog.get_decoration_texture(definition_id, time_period)
	if tex != null:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = tex
		sprite.centered = true
		sprite.offset = GardenAssetCatalog.compute_bottom_center_offset(tex)
		sprite.scale = Vector2.ONE
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		container.add_child(sprite)
	else:
		var decor_def: DecorationDefinition = catalog.get_decoration(definition_id) if catalog != null else null
		var label_text: String = GardenLocalization.get_decoration_name(definition_id, locale, decor_def)
		_add_fallback_token(container, label_text, Color(0.68, 0.54, 0.38, 0.96), false)

	if definition_id == "decoration.garden_lamp" and (
		time_period == GardenTimePeriod.NIGHT or time_period == GardenTimePeriod.EVENING
	):
		var glow_tex: Texture2D = GardenAssetCatalog.get_firefly_glow_texture()
		if glow_tex != null:
			var lamp_glow: Sprite2D = Sprite2D.new()
			lamp_glow.name = "LampGlow"
			lamp_glow.texture = glow_tex
			lamp_glow.position = Vector2(0.0, -162.0)
			lamp_glow.scale = Vector2(2.4, 2.4)
			lamp_glow.modulate = Color(1.0, 0.86, 0.45, 0.72)
			var mat: CanvasItemMaterial = CanvasItemMaterial.new()
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			lamp_glow.material = mat
			container.add_child(lamp_glow)
			_active_lamp_glows.append(lamp_glow)

	return container


func _create_base_item_node(
	instance_id: String,
	world_pos: Vector2,
	is_selected: bool,
	shadow_rx: float
) -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = "Item_%s" % instance_id.validate_node_name()
	root.position = world_pos
	root.set_meta("instance_id", instance_id)

	var shadow: Polygon2D = Polygon2D.new()
	shadow.name = "ContactShadow"
	shadow.polygon = _build_ellipse_points(shadow_rx, shadow_rx * 0.38, 16)
	shadow.color = Color(0.08, 0.06, 0.04, 0.22)
	shadow.position = Vector2(0.0, 2.0)
	root.add_child(shadow)

	var ring: Polygon2D = Polygon2D.new()
	ring.name = "SelectionRing"
	ring.polygon = _build_ellipse_points(shadow_rx + 10.0, (shadow_rx + 10.0) * 0.42, 20)
	ring.color = Color(0.98, 0.86, 0.34, 0.58)
	ring.visible = is_selected
	root.add_child(ring)

	return root


func _add_fallback_token(
	container: Node2D,
	label_text: String,
	fill_color: Color,
	is_plant: bool
) -> void:
	var body: Polygon2D = Polygon2D.new()
	body.name = "FallbackToken"
	if is_plant:
		body.polygon = PackedVector2Array([
			Vector2(-24, 0),
			Vector2(24, 0),
			Vector2(18, -32),
			Vector2(0, -68),
			Vector2(-18, -32),
		])
	else:
		body.polygon = PackedVector2Array([
			Vector2(-28, 0),
			Vector2(28, 0),
			Vector2(28, -42),
			Vector2(-28, -42),
		])
	body.color = fill_color
	container.add_child(body)

	var tag: Label = Label.new()
	tag.name = "FallbackLabel"
	tag.text = label_text
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.position = Vector2(-58.0, -96.0)
	tag.custom_minimum_size = Vector2(116.0, 0.0)
	tag.add_theme_font_size_override("font_size", 15)
	tag.add_theme_color_override("font_color", Color(0.98, 0.97, 0.92, 1.0))
	tag.add_theme_color_override("font_shadow_color", Color(0.08, 0.1, 0.08, 0.85))
	tag.add_theme_constant_override("shadow_offset_x", 1)
	tag.add_theme_constant_override("shadow_offset_y", 1)
	container.add_child(tag)


func _compute_visitor_anchor(visitor_id: String, anchors: Dictionary) -> Vector2:
	var bench_pos: Vector2 = anchors.get("bench_pos", Vector2.INF)
	var jasmine_mature_pos: Vector2 = anchors.get("jasmine_mature_pos", Vector2.INF)
	var flower_mature_pos: Vector2 = anchors.get("flower_mature_pos", Vector2.INF)
	var any_mature_pos: Vector2 = anchors.get("any_mature_pos", Vector2.INF)
	var any_plant_pos: Vector2 = anchors.get("any_plant_pos", Vector2.INF)
	var pond_pos: Vector2 = anchors.get("pond_pos", Vector2.INF)
	var jar_pos: Vector2 = anchors.get("jar_pos", Vector2.INF)
	var fence_pos: Vector2 = anchors.get("fence_pos", Vector2.INF)
	var lamp_pos: Vector2 = anchors.get("lamp_pos", Vector2.INF)
	var table_pos: Vector2 = anchors.get("table_pos", Vector2.INF)
	var banana_mature_pos: Vector2 = anchors.get("banana_mature_pos", Vector2.INF)

	match visitor_id:
		"visitor.cat":
			if bench_pos != Vector2.INF:
				return bench_pos + BENCH_CAT_PERCH_OFFSET
			if jasmine_mature_pos != Vector2.INF:
				return jasmine_mature_pos + JASMINE_CAT_REST_OFFSET
			return DEFAULT_CAT_GROUND_POS
		"visitor.butterfly":
			if flower_mature_pos != Vector2.INF:
				return flower_mature_pos + FLOWER_BUTTERFLY_OFFSET
			if any_mature_pos != Vector2.INF:
				return any_mature_pos + FLOWER_BUTTERFLY_OFFSET
			if any_plant_pos != Vector2.INF:
				return any_plant_pos + Vector2(18.0, -130.0)
			return DEFAULT_BUTTERFLY_POS
		"visitor.firefly":
			return DEFAULT_FIREFLY_POS
		"visitor.frog":
			if pond_pos != Vector2.INF:
				return pond_pos + POND_FROG_OFFSET
			if jar_pos != Vector2.INF:
				return jar_pos + JAR_FROG_OFFSET
			return DEFAULT_FROG_GROUND_POS
		"visitor.bird":
			if fence_pos != Vector2.INF:
				return fence_pos + FENCE_BIRD_PERCH_OFFSET
			if lamp_pos != Vector2.INF:
				return lamp_pos + LAMP_BIRD_PERCH_OFFSET
			if table_pos != Vector2.INF:
				return table_pos + TABLE_BIRD_PERCH_OFFSET
			if jar_pos != Vector2.INF:
				return jar_pos + JAR_BIRD_PERCH_OFFSET
			if banana_mature_pos != Vector2.INF:
				return banana_mature_pos + BANANA_BIRD_PERCH_OFFSET
			if bench_pos != Vector2.INF:
				return bench_pos + BENCH_BIRD_PERCH_OFFSET
			return DEFAULT_BIRD_PERCH_POS
		_:
			return DEFAULT_CAT_GROUND_POS


func _render_active_visitor(
	visitor_id: String,
	anchors: Dictionary,
	catalog: ContentCatalog,
	locale: String
) -> void:
	if _visitors_root == null or visitor_id.is_empty():
		return

	var visitor_node: Node2D = Node2D.new()
	visitor_node.name = "Visitor_%s" % visitor_id.validate_node_name()
	visitor_node.set_meta("visitor_id", visitor_id)
	visitor_node.position = _compute_visitor_anchor(visitor_id, anchors)

	var visitor_frames: SpriteFrames = GardenAssetCatalog.get_visitor_sprite_frames(visitor_id)
	if visitor_frames != null:
		var anim_sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		anim_sprite.name = "Sprite"
		anim_sprite.sprite_frames = visitor_frames
		anim_sprite.animation = &"idle"
		anim_sprite.centered = true
		anim_sprite.scale = Vector2.ONE
		anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var frame_tex: Texture2D = visitor_frames.get_frame_texture(&"idle", 0)
		if GardenAssetCatalog.is_grounded_visitor(visitor_id):
			anim_sprite.offset = GardenAssetCatalog.compute_bottom_center_offset(frame_tex)
		else:
			anim_sprite.offset = Vector2.ZERO
		anim_sprite.play(&"idle")
		visitor_node.add_child(anim_sprite)
		_start_visitor_idle_tween(visitor_id, anim_sprite)
	elif visitor_id == "visitor.firefly" and GardenAssetCatalog.get_firefly_glow_texture() != null:
		var glow_sprite: Sprite2D = Sprite2D.new()
		glow_sprite.name = "Sprite"
		glow_sprite.texture = GardenAssetCatalog.get_firefly_glow_texture()
		glow_sprite.centered = true
		glow_sprite.scale = Vector2.ONE
		glow_sprite.modulate = Color(1.0, 0.95, 0.58, 0.92)
		var mat: CanvasItemMaterial = CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		glow_sprite.material = mat
		visitor_node.add_child(glow_sprite)
		_start_visitor_idle_tween("visitor.butterfly", glow_sprite)
	else:
		var vdef: VisitorDefinition = catalog.get_visitor(visitor_id) if catalog != null else null
		var vname: String = GardenLocalization.get_visitor_name(visitor_id, locale, vdef)
		_add_fallback_token(visitor_node, vname, Color(0.95, 0.85, 0.56, 0.92), false)

	_visitors_root.add_child(visitor_node)
	_active_visitor_node = visitor_node


func _start_visitor_idle_tween(visitor_id: String, sprite: Node2D) -> void:
	if not is_inside_tree() or sprite == null:
		return
	var tween: Tween = create_tween()
	tween.set_loops()
	if visitor_id == "visitor.butterfly":
		tween.tween_property(sprite, "position", Vector2(10.0, -10.0), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sprite, "position", Vector2(-8.0, 6.0), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	elif visitor_id == "visitor.bird":
		tween.tween_property(sprite, "position", Vector2(2.0, -5.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "position", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_interval(2.0)
	else:
		tween.tween_property(sprite, "position", Vector2(0.0, -2.5), 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sprite, "position", Vector2.ZERO, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tweens.append(tween)


func _start_plant_sway_tweens(plant_sprites: Array[Node2D]) -> void:
	if not is_inside_tree() or plant_sprites.is_empty():
		return
	var sway_count: int = mini(plant_sprites.size(), MAX_AMBIENT_PLANT_SWAYS)
	for i: int in range(sway_count):
		var sprite: Node2D = plant_sprites[i]
		if sprite == null or not is_instance_valid(sprite):
			continue
		var angle_rad: float = 0.022 if i % 2 == 0 else -0.020
		var half_period: float = 2.4 + float(i) * 0.35
		var tween: Tween = create_tween()
		tween.set_loops()
		tween.tween_property(sprite, "rotation", angle_rad, half_period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sprite, "rotation", -angle_rad * 0.85, half_period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_active_tweens.append(tween)


func _start_glow_pulse_tween(glow_sprite: Sprite2D, base_alpha: float, duration: float) -> void:
	if not is_inside_tree() or glow_sprite == null or not is_instance_valid(glow_sprite):
		return
	var low_alpha: float = maxf(0.18, base_alpha * 0.78)
	var high_alpha: float = minf(0.95, base_alpha * 1.12)
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(glow_sprite, "modulate:a", high_alpha, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(glow_sprite, "modulate:a", low_alpha, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tweens.append(tween)


func _apply_atmosphere(
	time_period: String,
	weather_state: String,
	active_visitor_id: String,
	snapshot: GardenSnapshot,
	pond_pos: Vector2 = Vector2.INF
) -> void:
	var period_tint: Color = _compute_world_period_tint(time_period)
	var weather_mult: Color = _compute_weather_multiplier(weather_state)
	var final_world_tint: Color = period_tint * weather_mult
	if _world_root != null:
		_world_root.modulate = final_world_tint

	if _mist_overlay != null:
		_mist_overlay.color = _compute_mist_overlay_color(time_period, weather_state)

	var is_raining: bool = (weather_state == GardenWeather.RAIN)
	if _rain_particles != null:
		_rain_particles.visible = is_raining
		_rain_particles.emitting = is_raining

	if _rain_ripples_group != null:
		_rain_ripples_group.visible = is_raining
		if is_raining:
			var ripple_frames: SpriteFrames = GardenAssetCatalog.get_rain_ripple_sprite_frames()
			if ripple_frames != null:
				var ripple_positions: Array[Vector2] = []
				if pond_pos != Vector2.INF:
					ripple_positions.append(pond_pos + Vector2(-18.0, -34.0))
					ripple_positions.append(pond_pos + Vector2(28.0, -24.0))
				for pos: Vector2 in RAIN_RIPPLE_DEFAULT_POSITIONS:
					ripple_positions.append(pos)
				var total_ripples: int = mini(ripple_positions.size(), 4)
				for idx: int in range(total_ripples):
					var ripple: AnimatedSprite2D = AnimatedSprite2D.new()
					ripple.name = "RainRipple_%d" % idx
					ripple.sprite_frames = ripple_frames
					ripple.animation = &"ripple"
					ripple.position = ripple_positions[idx]
					ripple.scale = Vector2.ONE
					ripple.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
					ripple.modulate = Color(1.0, 1.0, 1.0, 0.72)
					ripple.frame = idx % ripple_frames.get_frame_count(&"ripple")
					ripple.play(&"ripple")
					_rain_ripples_group.add_child(ripple)

	var is_warm_light_hours: bool = (
		time_period == GardenTimePeriod.NIGHT
		or time_period == GardenTimePeriod.EVENING
	)
	if _house_porch_glow != null:
		_house_porch_glow.visible = is_warm_light_hours
		if is_warm_light_hours:
			var glow_alpha: float = 0.72 if time_period == GardenTimePeriod.NIGHT else 0.40
			_house_porch_glow.modulate = Color(1.0, 0.84, 0.48, glow_alpha)
			_start_glow_pulse_tween(_house_porch_glow, glow_alpha, 2.2)

	if is_warm_light_hours:
		for l_idx: int in range(_active_lamp_glows.size()):
			var lamp_glow: Sprite2D = _active_lamp_glows[l_idx]
			_start_glow_pulse_tween(lamp_glow, 0.72, 1.8 + float(l_idx) * 0.25)

	var show_fireflies: bool = (time_period == GardenTimePeriod.NIGHT and not is_raining)
	if not show_fireflies and active_visitor_id == "visitor.firefly":
		show_fireflies = true
	if _fireflies_group != null:
		_fireflies_group.visible = show_fireflies
		if show_fireflies:
			var count: int = FIREFLY_ANCHORS.size()
			var has_firefly_trait: bool = (
				active_visitor_id == "visitor.firefly"
				or (snapshot != null and snapshot.get_trait_count("warm") > 0)
			)
			if not has_firefly_trait and count > 3:
				count = 3
			var glow_tex: Texture2D = GardenAssetCatalog.get_firefly_glow_texture()
			for i: int in range(count):
				var mote: Sprite2D = Sprite2D.new()
				mote.name = "Firefly_%d" % i
				mote.texture = glow_tex
				mote.position = FIREFLY_ANCHORS[i]
				mote.scale = Vector2.ONE
				mote.modulate = Color(1.0, 0.94, 0.56, 0.85)
				var mat: CanvasItemMaterial = CanvasItemMaterial.new()
				mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
				mote.material = mat
				_fireflies_group.add_child(mote)
				if is_inside_tree():
					var drift: Tween = create_tween()
					drift.set_loops()
					var base_pos: Vector2 = FIREFLY_ANCHORS[i]
					drift.tween_property(mote, "position", base_pos + Vector2(14.0, -12.0), 1.9 + float(i) * 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
					drift.tween_property(mote, "position", base_pos + Vector2(-10.0, 8.0), 2.1 + float(i) * 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
					_active_tweens.append(drift)


func _compute_world_period_tint(time_period: String) -> Color:
	match time_period:
		GardenTimePeriod.MORNING:
			return Color(1.0, 0.94, 0.88, 1.0)
		GardenTimePeriod.EVENING:
			return Color(0.95, 0.80, 0.70, 1.0)
		GardenTimePeriod.NIGHT:
			return Color(0.54, 0.60, 0.82, 1.0)
		_:
			return Color(1.0, 1.0, 0.98, 1.0)


func _compute_weather_multiplier(weather_state: String) -> Color:
	match weather_state:
		GardenWeather.CLOUDY:
			return Color(0.88, 0.91, 0.95, 1.0)
		GardenWeather.RAIN:
			return Color(0.76, 0.82, 0.92, 1.0)
		_:
			return Color(1.0, 1.0, 1.0, 1.0)


func _compute_mist_overlay_color(time_period: String, weather_state: String) -> Color:
	if weather_state == GardenWeather.RAIN:
		if time_period == GardenTimePeriod.NIGHT:
			return Color(0.08, 0.12, 0.22, 0.20)
		return Color(0.42, 0.50, 0.60, 0.14)
	if weather_state == GardenWeather.CLOUDY:
		return Color(0.68, 0.72, 0.78, 0.07)
	match time_period:
		GardenTimePeriod.MORNING:
			return Color(1.0, 0.92, 0.76, 0.06)
		GardenTimePeriod.EVENING:
			return Color(0.92, 0.56, 0.36, 0.09)
		GardenTimePeriod.NIGHT:
			return Color(0.10, 0.14, 0.28, 0.16)
		_:
			return Color(1.0, 1.0, 1.0, 0.0)


func _fallback_color_for_plant_stage(stage: PlantGrowth.Stage) -> Color:
	match stage:
		PlantGrowth.Stage.PLANTED:
			return Color(0.66, 0.52, 0.36, 0.96)
		PlantGrowth.Stage.SPROUT:
			return Color(0.52, 0.76, 0.44, 0.96)
		PlantGrowth.Stage.GROWING:
			return Color(0.36, 0.68, 0.38, 0.96)
		PlantGrowth.Stage.MATURE:
			return Color(0.28, 0.62, 0.34, 0.98)
		_:
			return Color(0.62, 0.58, 0.54, 0.92)


func _build_ellipse_points(rx: float, ry: float, segments: int) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(segments):
		var angle: float = (TAU * float(i)) / float(segments)
		pts.append(Vector2(cos(angle) * rx, sin(angle) * ry))
	return pts


func _gui_input(event: InputEvent) -> void:
	var click_pos: Vector2 = Vector2.INF
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			click_pos = mb.position
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			click_pos = touch.position

	if click_pos == Vector2.INF or _world_origin == null:
		return

	_handle_local_world_tap(click_pos - _world_origin.position)


## Deterministic test helper: simulates a tap at a WorldOrigin-local coordinate.
func simulate_tap_at_world_pos(local_world_pos: Vector2) -> void:
	_handle_local_world_tap(local_world_pos)


func _handle_local_world_tap(local_world_pos: Vector2) -> void:
	var best_id: String = ""
	var best_kind: String = ""
	var best_dist: float = 90.0

	for inst_id_var: Variant in _item_entries.keys():
		var inst_id: String = str(inst_id_var)
		var entry: Dictionary = _item_entries[inst_id]
		var item_pos: Vector2 = entry.get("world_pos", Vector2.INF)
		var target_center: Vector2 = item_pos + Vector2(0.0, -56.0)
		var d: float = local_world_pos.distance_to(target_center)
		if d <= best_dist:
			best_dist = d
			best_id = inst_id
			best_kind = str(entry.get("kind", ""))

	if _active_visitor_node != null and not _active_visitor_id.is_empty():
		var visitor_center: Vector2 = _active_visitor_node.position
		if GardenAssetCatalog.is_grounded_visitor(_active_visitor_id) and _active_visitor_id != "visitor.firefly":
			visitor_center += Vector2(0.0, -38.0)
		var visitor_dist: float = local_world_pos.distance_to(visitor_center)
		if visitor_dist <= 56.0 and (best_id.is_empty() or visitor_dist < best_dist):
			visitor_selected.emit(_active_visitor_id)
			return

	if not best_id.is_empty():
		item_selected.emit(best_kind, best_id)
		return

	var best_cell: Dictionary = {}
	var best_cell_dist: float = 54.0
	for cell: Dictionary in _zone_cells:
		var cell_pos: Vector2 = cell.get("world_pos", Vector2.INF)
		var d: float = local_world_pos.distance_to(cell_pos)
		if d <= best_cell_dist:
			best_cell_dist = d
			best_cell = cell

	if not best_cell.is_empty():
		cell_selected.emit(
			str(best_cell.get("zone_id", GardenZone.ZONE_MAIN)),
			int(best_cell.get("grid_x", 0)),
			int(best_cell.get("grid_y", 0))
		)


func _clear_node_children(container: Node) -> void:
	if container == null:
		return
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _kill_active_tweens() -> void:
	for tween: Tween in _active_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_active_tweens.clear()


## Pure query for testing: returns the BackgroundSprite node.
func get_background_sprite() -> Sprite2D:
	_resolve_nodes()
	return _background_sprite


## Pure query for testing: returns all rendered item Node2D wrappers in PlacedItemsRoot.
func get_rendered_item_nodes() -> Array[Node2D]:
	_resolve_nodes()
	var nodes: Array[Node2D] = []
	if _placed_items_root != null:
		for child: Node in _placed_items_root.get_children():
			if child is Node2D:
				nodes.append(child as Node2D)
	return nodes


## Pure query for testing: returns the rendered Node2D for a given plant or decoration instance ID.
func get_rendered_item_node(runtime_instance_id: String) -> Node2D:
	if _item_entries.has(runtime_instance_id):
		return _item_entries[runtime_instance_id].get("node") as Node2D
	return null


## Pure query for testing: returns the currently rendered visitor Node2D (or null).
func get_rendered_visitor_node() -> Node2D:
	return _active_visitor_node


## Pure query for testing: returns WorldRoot modulation color.
func get_world_modulate() -> Color:
	_resolve_nodes()
	return _world_root.modulate if _world_root != null else Color.WHITE


## Pure query for testing: returns true when rain particles are active.
func is_rain_active() -> bool:
	_resolve_nodes()
	return _rain_particles != null and _rain_particles.visible and _rain_particles.emitting


## Pure query for testing: returns RainParticles node.
func get_rain_particles() -> CPUParticles2D:
	_resolve_nodes()
	return _rain_particles


## Pure query for testing: returns true when night fireflies group is visible.
func are_fireflies_visible() -> bool:
	_resolve_nodes()
	return _fireflies_group != null and _fireflies_group.visible and _fireflies_group.get_child_count() > 0


## Pure query for testing: returns true when house porch light glow is visible.
func is_house_glow_visible() -> bool:
	_resolve_nodes()
	return _house_porch_glow != null and _house_porch_glow.visible


## Pure query for testing: returns currently selected plant ID in diorama.
func get_selected_plant_id() -> String:
	return _selected_plant_id


## Pure query for testing: returns currently selected decoration ID in diorama.
func get_selected_decoration_id() -> String:
	return _selected_decoration_id


## Pure query for testing: returns total rendered zone cell markers.
func get_zone_cell_marker_count() -> int:
	return _zone_cells.size()


## Pure query for testing: returns the Polygon2D marker for a given cell, or null.
func get_zone_cell_marker(zone_id: String, grid_x: int, grid_y: int) -> Polygon2D:
	for cell: Dictionary in _zone_cells:
		if (
			str(cell.get("zone_id", "")) == zone_id
			and int(cell.get("grid_x", -1)) == grid_x
			and int(cell.get("grid_y", -1)) == grid_y
		):
			return cell.get("marker") as Polygon2D
	return null


## Pure query for testing: returns the currently highlighted target cell dictionary.
func get_target_cell() -> Dictionary:
	return {
		"zone_id": _target_zone_id,
		"grid_x": _target_grid_x,
		"grid_y": _target_grid_y,
	}


## Plays a one-shot harvest/planting sparkle puff at the specified logical grid cell.
func play_feedback_puff_at_cell(zone_id: String, grid_x: int, grid_y: int) -> void:
	play_feedback_puff_at_world_pos(compute_grid_world_position(zone_id, grid_x, grid_y))


## Plays a one-shot harvest/planting sparkle puff at an existing rendered item's world anchor.
func play_feedback_puff_at_item(runtime_instance_id: String) -> void:
	if _item_entries.has(runtime_instance_id):
		var world_pos: Vector2 = _item_entries[runtime_instance_id].get("world_pos", Vector2.INF)
		if world_pos != Vector2.INF:
			play_feedback_puff_at_world_pos(world_pos)


## Plays a one-shot harvest/planting sparkle puff at a WorldOrigin-local position.
func play_feedback_puff_at_world_pos(world_pos: Vector2) -> void:
	_resolve_nodes()
	if _feedback_effects_layer == null:
		return
	var puff_frames: SpriteFrames = GardenAssetCatalog.get_harvest_puff_sprite_frames()
	if puff_frames == null:
		return
	var puff: AnimatedSprite2D = AnimatedSprite2D.new()
	puff.name = "FeedbackPuff_%d" % _feedback_effects_layer.get_child_count()
	puff.sprite_frames = puff_frames
	puff.animation = &"puff"
	puff.centered = true
	var frame0: Texture2D = puff_frames.get_frame_texture(&"puff", 0)
	puff.offset = GardenAssetCatalog.compute_bottom_center_offset(frame0)
	puff.position = world_pos
	puff.scale = Vector2.ONE
	puff.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	puff.animation_finished.connect(func() -> void:
		if is_instance_valid(puff):
			puff.queue_free()
	)
	_feedback_effects_layer.add_child(puff)
	puff.play(&"puff")


## Pure query for testing: returns true when diorama is highlighting valid move cells.
func is_move_highlight_active() -> bool:
	return _is_move_mode


## Pure query for testing: returns number of active raindrop ripple nodes.
func get_rain_ripple_count() -> int:
	_resolve_nodes()
	return _rain_ripples_group.get_child_count() if _rain_ripples_group != null else 0


## Pure query for testing: returns number of active one-shot feedback effect nodes.
func get_feedback_effect_count() -> int:
	_resolve_nodes()
	return _feedback_effects_layer.get_child_count() if _feedback_effects_layer != null else 0
