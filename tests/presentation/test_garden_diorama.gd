## test_garden_diorama.gd
## Automated verification for Vertical Slice 2D Visual Assets, GardenAssetCatalog,
## GardenDiorama world rendering, card sprite thumbnails, and GardenView integration.
class_name TestGardenDiorama
extends TestSuiteBase

const GARDEN_DIORAMA_SCENE_PATH: String = "res://scenes/garden/garden_diorama.tscn"
const GARDEN_VIEW_SCENE_PATH: String = "res://scenes/garden/garden_view.tscn"
const PLANT_VIEW_SCENE_PATH: String = "res://scenes/garden/plant_view.tscn"
const DECORATION_VIEW_SCENE_PATH: String = "res://scenes/garden/decoration_view.tscn"


func _init() -> void:
	suite_name = "TestGardenDiorama"


func run_tests() -> void:
	_test_asset_catalog_vertical_slice_textures_and_caching()
	_test_diorama_background_and_sprite_contract()
	_test_diorama_growth_stages_and_fallback_tokens()
	_test_diorama_visitor_bench_and_butterfly_pivots()
	_test_diorama_atmosphere_day_night_rain_fireflies()
	_test_card_sprite_thumbnails_and_fallbacks()
	_test_garden_view_diorama_integration_and_blocked_cleanup()


func _create_full_catalog() -> ContentCatalog:
	return ContentCatalog.try_create(
		PlantContentLoader.new().load_production_definitions().get_definitions(),
		VisitorContentLoader.new().load_production_definitions().get_definitions(),
		DecorationContentLoader.new().load_production_definitions().get_definitions(),
		EventContentLoader.new().load_production_definitions().get_definitions()
	)


func _test_asset_catalog_vertical_slice_textures_and_caching() -> void:
	describe("GardenAssetCatalog maps Vertical Slice IDs/stages to exact imported textures and caches them")
	GardenAssetCatalog.clear_cache()

	var bg: Texture2D = GardenAssetCatalog.get_background_texture()
	assert_true(bg != null, "Background texture must load")
	assert_eq(bg.get_size(), Vector2(1080, 1920), "Background must match 1080x1920 reference canvas")

	var bg_cached: Texture2D = GardenAssetCatalog.get_background_texture()
	assert_true(bg == bg_cached, "Background texture lookup returns cached instance")

	var stages: Array[PlantGrowth.Stage] = [
		PlantGrowth.Stage.PLANTED,
		PlantGrowth.Stage.SPROUT,
		PlantGrowth.Stage.GROWING,
		PlantGrowth.Stage.MATURE,
	]
	var basil_textures: Array[Texture2D] = []
	for st: PlantGrowth.Stage in stages:
		var tex: Texture2D = GardenAssetCatalog.get_plant_texture("plant.holy_basil", st)
		assert_true(tex != null, "Holy basil stage texture must load: %s" % str(st))
		assert_eq(tex.get_size(), Vector2(240, 260), "Holy basil texture size matches 240x260")
		assert_false(basil_textures.has(tex), "Each Holy basil stage uses a distinct texture")
		basil_textures.append(tex)

	var marigold_textures: Array[Texture2D] = []
	for st: PlantGrowth.Stage in stages:
		var tex: Texture2D = GardenAssetCatalog.get_plant_texture("plant.marigold", st)
		assert_true(tex != null, "Marigold stage texture must load: %s" % str(st))
		assert_eq(tex.get_size(), Vector2(248, 288), "Marigold texture size matches 248x288")
		assert_false(marigold_textures.has(tex), "Each Marigold stage uses a distinct texture")
		marigold_textures.append(tex)

	var chili_textures: Array[Texture2D] = []
	for st: PlantGrowth.Stage in stages:
		var tex: Texture2D = GardenAssetCatalog.get_plant_texture("plant.chili", st)
		assert_true(tex != null, "Chili stage texture must load: %s" % str(st))
		assert_eq(tex.get_size(), Vector2(240, 268), "Chili texture size matches 240x268")
		assert_false(chili_textures.has(tex), "Each Chili stage uses a distinct texture")
		chili_textures.append(tex)

	var clay_jar: Texture2D = GardenAssetCatalog.get_decoration_texture("decoration.clay_jar")
	assert_true(clay_jar != null and clay_jar.get_size() == Vector2(240, 268), "Clay jar texture loads at 240x268")
	var bench: Texture2D = GardenAssetCatalog.get_decoration_texture("decoration.bench")
	assert_true(bench != null and bench.get_size() == Vector2(360, 248), "Bench texture loads at 360x248")

	var cat: Texture2D = GardenAssetCatalog.get_visitor_texture("visitor.cat")
	assert_true(cat != null and cat.get_size() == Vector2(168, 124), "Cat texture loads at 168x124")
	var butterfly: Texture2D = GardenAssetCatalog.get_visitor_texture("visitor.butterfly")
	assert_true(butterfly != null and butterfly.get_size() == Vector2(64, 64), "Butterfly texture loads at 64x64")

	assert_true(GardenAssetCatalog.is_grounded_visitor("visitor.cat"), "Cat is grounded visitor (Option A bottom-center)")
	assert_false(GardenAssetCatalog.is_grounded_visitor("visitor.butterfly"), "Butterfly is airborne (center pivot)")
	assert_eq(GardenAssetCatalog.compute_bottom_center_offset(clay_jar), Vector2(0.0, -134.0), "Bottom-center offset equals -height/2")

	var rain: Texture2D = GardenAssetCatalog.get_rain_streak_texture()
	assert_true(rain != null and rain.get_size() == Vector2(16, 128), "Rain streak texture loads at 16x128")
	var firefly: Texture2D = GardenAssetCatalog.get_firefly_glow_texture()
	assert_true(firefly != null and firefly.get_size() == Vector2(64, 64), "Firefly glow texture loads at 64x64")

	assert_true(GardenAssetCatalog.get_plant_texture("plant.banana", PlantGrowth.Stage.MATURE) == null, "Non-VS plant returns null for fallback")
	assert_true(GardenAssetCatalog.get_decoration_texture("decoration.watering_can") == null, "Non-VS decoration returns null for fallback")
	assert_true(GardenAssetCatalog.get_visitor_texture("visitor.bird") == null, "Non-VS visitor returns null for fallback")


func _test_diorama_background_and_sprite_contract() -> void:
	describe("GardenDiorama enforces 1:1 Sprite2D scale, Linear filter, and Option A bottom-center pivots")
	var scene: PackedScene = load(GARDEN_DIORAMA_SCENE_PATH) as PackedScene
	assert_true(scene != null, "GardenDiorama scene loads")
	var diorama: GardenDiorama = scene.instantiate() as GardenDiorama
	assert_true(diorama != null, "GardenDiorama instantiates")

	var catalog: ContentCatalog = _create_full_catalog()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-basil", "plant.holy_basil", 1000, GardenZone.ZONE_MAIN, 1, 1))
	state.get_decorations().try_add_decoration(DecorationState.new("d-jar", "decoration.clay_jar", 1000, GardenZone.ZONE_MAIN, 2, 1))

	var snap: GardenSnapshot = GardenSnapshot.new({}, {"plant.holy_basil": 1}, 1, 1, {"decoration.clay_jar": 1}, 1, GardenTimePeriod.DAY, GardenWeather.CLEAR)
	diorama.render_garden(state, catalog, 2000, snap, "", "p-basil", "", GardenZone.ZONE_MAIN, "th")

	var bg_sprite: Sprite2D = diorama.get_background_sprite()
	assert_true(bg_sprite != null and bg_sprite.texture != null, "BackgroundSprite has texture")
	assert_eq(bg_sprite.scale, Vector2.ONE, "BackgroundSprite renders at 1:1 scale")
	assert_eq(bg_sprite.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR, "BackgroundSprite uses Linear filtering")

	var basil_node: Node2D = diorama.get_rendered_item_node("p-basil")
	assert_true(basil_node != null, "Basil item node rendered in diorama")
	var basil_sprite: Sprite2D = basil_node.get_node_or_null("Sprite") as Sprite2D
	assert_true(basil_sprite != null and basil_sprite.texture != null, "Basil renders illustrated Sprite2D")
	assert_eq(basil_sprite.scale, Vector2.ONE, "Basil Sprite2D scale == Vector2.ONE")
	assert_eq(basil_sprite.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR, "Basil Sprite2D uses Linear filter")
	assert_true(basil_sprite.centered, "Basil Sprite2D uses centered=true with Option A offset")
	assert_eq(basil_sprite.offset, Vector2(0.0, -130.0), "Holy basil offset equals Vector2(0, -260/2)")

	var selection_ring: CanvasItem = basil_node.get_node_or_null("SelectionRing") as CanvasItem
	assert_true(selection_ring != null and selection_ring.visible, "Selected plant shows SelectionRing")

	var jar_node: Node2D = diorama.get_rendered_item_node("d-jar")
	assert_true(jar_node != null, "Clay jar item node rendered in diorama")
	var jar_sprite: Sprite2D = jar_node.get_node_or_null("Sprite") as Sprite2D
	assert_true(jar_sprite != null and jar_sprite.offset == Vector2(0.0, -134.0), "Clay jar uses Option A bottom-center offset")
	assert_true(basil_node.position != jar_node.position, "Distinct grid cells map to distinct world coordinates")

	diorama.set_selected_item("", "d-jar")
	assert_false(selection_ring.visible, "Plant SelectionRing hides when decoration is selected")
	var jar_ring: CanvasItem = jar_node.get_node_or_null("SelectionRing") as CanvasItem
	assert_true(jar_ring != null and jar_ring.visible, "Decoration SelectionRing activates on set_selected_item")

	diorama.free()


func _test_diorama_growth_stages_and_fallback_tokens() -> void:
	describe("GardenDiorama updates plant stage sprites across growth timestamps and renders fallbacks for non-VS items")
	var scene: PackedScene = load(GARDEN_DIORAMA_SCENE_PATH) as PackedScene
	var diorama: GardenDiorama = scene.instantiate() as GardenDiorama
	var catalog: ContentCatalog = _create_full_catalog()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-marigold", "plant.marigold", 1000, GardenZone.ZONE_MAIN, 0, 2))
	state.get_plants().try_add_plant(PlantState.new("p-banana", "plant.banana", 1000, GardenZone.ZONE_ADJACENT_1, 1, 1))
	state.get_decorations().try_add_decoration(DecorationState.new("d-can", "decoration.watering_can", 1000, GardenZone.ZONE_MAIN, 3, 2))

	var snap: GardenSnapshot = GardenSnapshot.new({}, {"plant.marigold": 1, "plant.banana": 1}, 2, 0, {"decoration.watering_can": 1}, 1, GardenTimePeriod.DAY, GardenWeather.CLEAR)

	# Planted at t=1000
	diorama.render_garden(state, catalog, 1005, snap, "", "", "", GardenZone.ZONE_MAIN, "en")
	var planted_tex: Texture2D = (diorama.get_rendered_item_node("p-marigold").get_node("Sprite") as Sprite2D).texture
	assert_eq(planted_tex, GardenAssetCatalog.get_plant_texture("plant.marigold", PlantGrowth.Stage.PLANTED), "Uses PLANTED marigold texture at t=1005")

	# Mature at t=4000 (production marigold mature_after_seconds=2700 -> 3700)
	diorama.render_garden(state, catalog, 4000, snap, "", "", "", GardenZone.ZONE_MAIN, "en")
	var mature_tex: Texture2D = (diorama.get_rendered_item_node("p-marigold").get_node("Sprite") as Sprite2D).texture
	assert_eq(mature_tex, GardenAssetCatalog.get_plant_texture("plant.marigold", PlantGrowth.Stage.MATURE), "Uses MATURE marigold texture at t=4000")
	assert_true(planted_tex != mature_tex, "Marigold texture switches across growth stages")

	# Fallback items render gracefully
	var banana_node: Node2D = diorama.get_rendered_item_node("p-banana")
	assert_true(banana_node != null and banana_node.get_node_or_null("FallbackToken") != null, "Non-VS plant renders fallback token")
	var can_node: Node2D = diorama.get_rendered_item_node("d-can")
	assert_true(can_node != null and can_node.get_node_or_null("FallbackToken") != null, "Non-VS decoration renders fallback token")

	diorama.free()


func _test_diorama_visitor_bench_and_butterfly_pivots() -> void:
	describe("GardenDiorama anchors Cat onto Bench when present and keeps Butterfly center-pivoted over mature flowers")
	var scene: PackedScene = load(GARDEN_DIORAMA_SCENE_PATH) as PackedScene
	var diorama: GardenDiorama = scene.instantiate() as GardenDiorama
	var catalog: ContentCatalog = _create_full_catalog()

	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-marigold", "plant.marigold", 1000, GardenZone.ZONE_MAIN, 2, 1))
	state.get_decorations().try_add_decoration(DecorationState.new("d-bench", "decoration.bench", 1000, GardenZone.ZONE_MAIN, 1, 2))

	var snap: GardenSnapshot = GardenSnapshot.new({}, {"plant.marigold": 1}, 1, 1, {"decoration.bench": 1}, 1, GardenTimePeriod.DAY, GardenWeather.CLEAR)

	# 1. Cat perched on bench
	diorama.render_garden(state, catalog, 4000, snap, "visitor.cat", "", "", GardenZone.ZONE_MAIN, "th")
	var cat_node: Node2D = diorama.get_rendered_visitor_node()
	assert_true(cat_node != null, "Cat visitor node rendered")
	var bench_node: Node2D = diorama.get_rendered_item_node("d-bench")
	assert_eq(cat_node.position, bench_node.position + GardenDiorama.BENCH_CAT_PERCH_OFFSET, "Cat anchors on bench seat surface when bench exists")
	var cat_sprite: Sprite2D = cat_node.get_node_or_null("Sprite") as Sprite2D
	assert_true(cat_sprite != null and cat_sprite.offset == Vector2(0.0, -62.0), "Cat uses Option A bottom-center offset (-124/2)")

	# 2. Butterfly anchored over mature marigold with center pivot
	diorama.render_garden(state, catalog, 4000, snap, "visitor.butterfly", "", "", GardenZone.ZONE_MAIN, "th")
	var butterfly_node: Node2D = diorama.get_rendered_visitor_node()
	assert_true(butterfly_node != null, "Butterfly visitor node rendered")
	var marigold_node: Node2D = diorama.get_rendered_item_node("p-marigold")
	assert_eq(butterfly_node.position, marigold_node.position + GardenDiorama.FLOWER_BUTTERFLY_OFFSET, "Butterfly anchors near mature marigold")
	var bfly_sprite: Sprite2D = butterfly_node.get_node_or_null("Sprite") as Sprite2D
	assert_true(bfly_sprite != null and bfly_sprite.centered and bfly_sprite.offset == Vector2.ZERO, "Butterfly preserves center pivot (0, 0)")

	# 3. Cat without bench falls back to foreground stone paver
	var no_bench_state: GameState = GameState.new()
	no_bench_state.get_plants().try_add_plant(PlantState.new("p-marigold", "plant.marigold", 1000, GardenZone.ZONE_MAIN, 2, 1))
	diorama.render_garden(no_bench_state, catalog, 2000, snap, "visitor.cat", "", "", GardenZone.ZONE_MAIN, "th")
	var ground_cat: Node2D = diorama.get_rendered_visitor_node()
	assert_eq(ground_cat.position, GardenDiorama.DEFAULT_CAT_GROUND_POS, "Cat uses paver fallback position without bench")

	diorama.free()


func _test_diorama_atmosphere_day_night_rain_fireflies() -> void:
	describe("GardenDiorama drives clear day, warm night lights + fireflies, and angled rain particles")
	var scene: PackedScene = load(GARDEN_DIORAMA_SCENE_PATH) as PackedScene
	var diorama: GardenDiorama = scene.instantiate() as GardenDiorama
	var catalog: ContentCatalog = _create_full_catalog()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-basil", "plant.holy_basil", 1000, GardenZone.ZONE_MAIN, 0, 0))

	# Day Clear
	var day_clear: GardenSnapshot = GardenSnapshot.new({}, {"plant.holy_basil": 1}, 1, 0, {}, 0, GardenTimePeriod.DAY, GardenWeather.CLEAR)
	diorama.render_garden(state, catalog, 2000, day_clear, "", "", "", GardenZone.ZONE_MAIN, "th")
	assert_false(diorama.is_rain_active(), "Day Clear has no rain particles")
	assert_false(diorama.are_fireflies_visible(), "Day Clear has no fireflies")
	assert_false(diorama.is_house_glow_visible(), "Day Clear has no house porch glow")

	# Night Clear
	var night_clear: GardenSnapshot = GardenSnapshot.new({"warm": 1}, {"plant.holy_basil": 1}, 1, 0, {}, 0, GardenTimePeriod.NIGHT, GardenWeather.CLEAR)
	diorama.render_garden(state, catalog, 2000, night_clear, "", "", "", GardenZone.ZONE_MAIN, "th")
	assert_true(diorama.is_house_glow_visible(), "Night enables warm house porch light glow")
	assert_true(diorama.are_fireflies_visible(), "Night Clear displays restrained firefly glows")
	assert_false(diorama.is_rain_active(), "Night Clear does not emit rain")
	assert_true(diorama.get_world_modulate().b > diorama.get_world_modulate().r, "Night world tint shifts cool indigo")

	# Day Rain
	var day_rain: GardenSnapshot = GardenSnapshot.new({}, {"plant.holy_basil": 1}, 1, 0, {}, 0, GardenTimePeriod.DAY, GardenWeather.RAIN)
	diorama.render_garden(state, catalog, 2000, day_rain, "", "", "", GardenZone.ZONE_MAIN, "th")
	assert_true(diorama.is_rain_active(), "Rain weather enables RainParticles emission")
	assert_true(diorama.get_rain_particles().texture == GardenAssetCatalog.get_rain_streak_texture(), "RainParticles uses imported rain streak texture")
	assert_false(diorama.are_fireflies_visible(), "Rain hides night fireflies")

	diorama.free()


func _test_card_sprite_thumbnails_and_fallbacks() -> void:
	describe("PlantView and DecorationView cards show VS sprite thumbnails while keeping card dimensions intact")
	var p_scene: PackedScene = load(PLANT_VIEW_SCENE_PATH) as PackedScene
	var p_card: PlantView = p_scene.instantiate() as PlantView
	assert_eq(p_card.custom_minimum_size, Vector2(260, 160), "PlantView minimum size preserved at 260x160")

	p_card.bind_plant_data("p1", "plant.holy_basil", PlantGrowth.Stage.MATURE, 1000, 5, 0, [], -1, "th")
	var p_icon: TextureRect = p_card.get_node_or_null("MarginContainer/VBoxContainer/StageContainer/PlantIcon") as TextureRect
	assert_true(p_icon != null and p_icon.visible, "Holy basil PlantView displays sprite thumbnail")
	assert_eq(p_icon.texture, GardenAssetCatalog.get_plant_texture("plant.holy_basil", PlantGrowth.Stage.MATURE), "PlantView thumbnail uses mature basil texture")

	p_card.bind_plant_data("p2", "plant.banana", PlantGrowth.Stage.PLANTED, 1000, 60, 100, [], -1, "th")
	assert_false(p_icon.visible, "Non-VS PlantView cleanly hides missing thumbnail")
	p_card.free()

	var d_scene: PackedScene = load(DECORATION_VIEW_SCENE_PATH) as PackedScene
	var d_card: DecorationView = d_scene.instantiate() as DecorationView
	assert_eq(d_card.custom_minimum_size, Vector2(260, 160), "DecorationView minimum size preserved at 260x160")

	d_card.bind_decoration_data("d1", "decoration.bench", 1000, 45, ["warm"], "th")
	var d_icon: TextureRect = d_card.get_node_or_null("MarginContainer/VBoxContainer/RoleContainer/DecorationIcon") as TextureRect
	assert_true(d_icon != null and d_icon.visible, "Bench DecorationView displays sprite thumbnail")
	assert_eq(d_icon.texture, GardenAssetCatalog.get_decoration_texture("decoration.bench"), "DecorationView thumbnail uses bench texture")

	d_card.bind_decoration_data("d2", "decoration.watering_can", 1000, 15, ["water"], "th")
	assert_false(d_icon.visible, "Non-VS DecorationView cleanly hides missing thumbnail")
	d_card.free()


func _test_garden_view_diorama_integration_and_blocked_cleanup() -> void:
	describe("GardenView synchronizes GardenDiorama selection and clears safely on blocked state")
	var gv_scene: PackedScene = load(GARDEN_VIEW_SCENE_PATH) as PackedScene
	var view: GardenView = gv_scene.instantiate() as GardenView

	var diorama: GardenDiorama = view.get_garden_diorama()
	assert_true(diorama != null, "GardenView embeds GardenDiorama")

	var catalog: ContentCatalog = _create_full_catalog()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("plant-vs-1", "plant.marigold", 1000, GardenZone.ZONE_MAIN, 1, 1))
	state.get_decorations().try_add_decoration(DecorationState.new("decor-vs-1", "decoration.bench", 1000, GardenZone.ZONE_MAIN, 2, 2))
	var session: GameSession = GameSession.new(state)
	var clock: FakeGameClock = FakeGameClock.new(2000, 0)

	view.bind_garden(session, catalog, clock)
	assert_eq(diorama.get_rendered_item_nodes().size(), 2, "GardenDiorama renders 1 plant + 1 decoration from session")

	# Selecting PlantView syncs GardenDiorama selection ring
	var pv: PlantView = view.get_plant_view_by_id("plant-vs-1")
	assert_true(pv != null, "PlantView rendered for plant-vs-1")
	pv.simulate_selection_input()
	assert_eq(diorama.get_selected_plant_id(), "plant-vs-1", "Selecting PlantView updates GardenDiorama selected plant")

	# Tapping diorama item selection signal updates GardenView selection
	diorama.item_selected.emit("decoration", "decor-vs-1")
	assert_eq(view.get_selected_decoration_instance_id(), "decor-vs-1", "Tapping diorama decoration selects it in GardenView")
	assert_eq(diorama.get_selected_decoration_id(), "decor-vs-1", "GardenDiorama keeps decoration selected")

	# Blocked state clears diorama safely
	view.show_blocked_startup_key("ui.garden.blocked_save_error")
	assert_eq(diorama.get_rendered_item_nodes().size(), 0, "Blocked state clears GardenDiorama rendered items")
	assert_false(diorama.is_rain_active(), "Blocked state disables rain particles")

	view.free()
