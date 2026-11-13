## test_garden_diorama.gd
## Automated verification for Vertical Slice 2D Visual Assets, GardenAssetCatalog,
## GardenDiorama world rendering, card sprite thumbnails, and GardenView integration.
class_name TestGardenDiorama
extends TestSuiteBase

const GARDEN_DIORAMA_SCENE_PATH: String = "res://scenes/garden/garden_diorama.tscn"
const GARDEN_VIEW_SCENE_PATH: String = "res://scenes/garden/garden_view.tscn"
const PLANT_VIEW_SCENE_PATH: String = "res://scenes/garden/plant_view.tscn"
const DECORATION_VIEW_SCENE_PATH: String = "res://scenes/garden/decoration_view.tscn"
const PLANTING_PICKER_SCENE_PATH: String = "res://scenes/garden/planting_picker.tscn"
const DECORATION_PICKER_SCENE_PATH: String = "res://scenes/garden/decoration_picker.tscn"


func _init() -> void:
	suite_name = "TestGardenDiorama"


func run_tests() -> void:
	_test_asset_catalog_vertical_slice_textures_and_caching()
	_test_diorama_background_and_sprite_contract()
	_test_diorama_growth_stages_and_fallback_tokens()
	_test_diorama_visitor_bench_and_butterfly_pivots()
	_test_diorama_jasmine_butterfly_and_firefly_visitor()
	_test_diorama_bird_and_frog_visitor_anchoring()
	_test_diorama_atmosphere_day_night_rain_fireflies()
	_test_diorama_cell_and_visitor_tapping_and_highlights()
	_test_card_sprite_thumbnails_and_fallbacks()
	_test_picker_sprite_thumbnails_and_fallbacks()
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
	assert_true(GardenAssetCatalog.is_grounded_visitor("visitor.frog"), "Frog is grounded visitor (Option A bottom-center)")
	assert_false(GardenAssetCatalog.is_grounded_visitor("visitor.butterfly"), "Butterfly is airborne (center pivot)")
	assert_false(GardenAssetCatalog.is_grounded_visitor("visitor.bird"), "Garden bird uses center-of-body perching pivot")
	assert_eq(GardenAssetCatalog.get_visitor_thumbnail("visitor.firefly"), GardenAssetCatalog.get_firefly_glow_texture(), "Firefly thumbnail resolves to glow texture")
	assert_eq(GardenAssetCatalog.get_decoration_texture("decoration.clay_jar", GardenTimePeriod.NIGHT), clay_jar, "Decoration without night variant falls back to idle texture")
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


func _test_diorama_jasmine_butterfly_and_firefly_visitor() -> void:
	describe("GardenDiorama anchors Butterfly on mature Jasmine and renders Firefly visitor with additive glow")
	var scene: PackedScene = load(GARDEN_DIORAMA_SCENE_PATH) as PackedScene
	var diorama: GardenDiorama = scene.instantiate() as GardenDiorama
	var catalog: ContentCatalog = _create_full_catalog()

	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-basil", "plant.holy_basil", 1000, GardenZone.ZONE_MAIN, 0, 0))
	state.get_plants().try_add_plant(PlantState.new("p-jasmine", "plant.jasmine", 1000, GardenZone.ZONE_MAIN, 2, 1))

	var snap: GardenSnapshot = GardenSnapshot.new({"flower": 1, "dense_vegetation": 1}, {"plant.holy_basil": 1, "plant.jasmine": 1}, 2, 0, {}, 0, GardenTimePeriod.DAY, GardenWeather.CLEAR)
	# t=5000 makes both holy_basil and jasmine MATURE
	diorama.render_garden(state, catalog, 5000, snap, "visitor.butterfly", "", "", GardenZone.ZONE_MAIN, "th")
	var butterfly_node: Node2D = diorama.get_rendered_visitor_node()
	var jasmine_node: Node2D = diorama.get_rendered_item_node("p-jasmine")
	assert_true(butterfly_node != null and jasmine_node != null, "Butterfly and Jasmine rendered")
	assert_eq(butterfly_node.position, jasmine_node.position + GardenDiorama.FLOWER_BUTTERFLY_OFFSET, "Butterfly prefers mature Jasmine flower over non-flower Basil")

	var night_snap: GardenSnapshot = GardenSnapshot.new({"dense_vegetation": 1}, {"plant.jasmine": 1}, 1, 0, {}, 0, GardenTimePeriod.NIGHT, GardenWeather.CLEAR)
	diorama.render_garden(state, catalog, 5000, night_snap, "visitor.firefly", "", "", GardenZone.ZONE_MAIN, "th")
	var firefly_node: Node2D = diorama.get_rendered_visitor_node()
	assert_true(firefly_node != null, "Firefly visitor node rendered")
	assert_eq(firefly_node.position, GardenDiorama.DEFAULT_FIREFLY_POS, "Firefly hovers over foliage rather than stone paver")
	assert_true(firefly_node.get_node_or_null("FallbackToken") == null, "Firefly uses glow sprite rather than boxy FallbackToken")
	var glow_sprite: Sprite2D = firefly_node.get_node_or_null("Sprite") as Sprite2D
	assert_true(glow_sprite != null and glow_sprite.texture == GardenAssetCatalog.get_firefly_glow_texture(), "Firefly visitor uses firefly glow texture")

	diorama.free()


func _test_diorama_cell_and_visitor_tapping_and_highlights() -> void:
	describe("GardenDiorama supports direct cell & visitor tapping and target/move highlights")
	var gv_scene: PackedScene = load(GARDEN_VIEW_SCENE_PATH) as PackedScene
	var view: GardenView = gv_scene.instantiate() as GardenView
	var diorama: GardenDiorama = view.get_garden_diorama()

	var catalog: ContentCatalog = _create_full_catalog()
	var state: GameState = GameState.new()
	state.get_plants().try_add_plant(PlantState.new("p-1", "plant.holy_basil", 1000, GardenZone.ZONE_MAIN, 1, 1))
	state.get_decorations().try_add_decoration(DecorationState.new("d-1", "decoration.bench", 1000, GardenZone.ZONE_MAIN, 2, 2))
	var session: GameSession = GameSession.new(state)
	var clock: FakeGameClock = FakeGameClock.new(2000, 0)
	view.bind_garden(session, catalog, clock)

	assert_eq(diorama.get_zone_cell_marker_count(), 16, "Unlocked zone.main renders 16 cell markers")

	# Tap empty cell (0, 0) directly in diorama -> targets cell in GardenView
	var cell_0_0_pos: Vector2 = GardenDiorama.compute_grid_world_position(GardenZone.ZONE_MAIN, 0, 0)
	diorama.simulate_tap_at_world_pos(cell_0_0_pos)
	var target: Dictionary = view.get_target_cell()
	assert_eq(target.get("zone_id"), GardenZone.ZONE_MAIN, "Tapping diorama cell targets zone.main")
	assert_eq(target.get("grid_x"), 0, "Tapping diorama cell targets grid_x=0")
	assert_eq(target.get("grid_y"), 0, "Tapping diorama cell targets grid_y=0")
	assert_eq(diorama.get_target_cell(), target, "Diorama target cell stays synced")
	var marker_0_0: Polygon2D = diorama.get_zone_cell_marker(GardenZone.ZONE_MAIN, 0, 0)
	assert_true(marker_0_0 != null and marker_0_0.scale.x > 1.1, "Targeted cell marker scales up visually")

	# Tap placed plant in diorama -> selects plant, clears target
	var p1_pos: Vector2 = GardenDiorama.compute_grid_world_position(GardenZone.ZONE_MAIN, 1, 1)
	diorama.simulate_tap_at_world_pos(p1_pos + Vector2(0.0, -40.0))
	assert_eq(view.get_selected_runtime_instance_id(), "p-1", "Tapping diorama plant selects p-1")

	# Enable move mode via MoveButton -> diorama highlights valid move cells
	view.get_move_button().pressed.emit()
	assert_true(diorama.is_move_highlight_active(), "MoveButton activates diorama move-mode cell highlights")

	var move_requests: Array = []
	view.move_item_requested.connect(func(inst_id: String, zid: String, gx: int, gy: int) -> void:
		move_requests.append([inst_id, zid, gx, gy])
	)
	var cell_3_2_pos: Vector2 = GardenDiorama.compute_grid_world_position(GardenZone.ZONE_MAIN, 3, 2)
	diorama.simulate_tap_at_world_pos(cell_3_2_pos)
	assert_eq(move_requests.size(), 1, "Tapping empty diorama cell in move mode emits move_item_requested")
	assert_eq(move_requests[0], ["p-1", GardenZone.ZONE_MAIN, 3, 2], "Diorama move coordinates match tapped cell")

	# Render active cat visitor on bench and tap cat directly -> emits visitor_observation_requested
	var snap: GardenSnapshot = GardenSnapshot.new({"warm": 1, "resting": 1}, {"plant.holy_basil": 1}, 1, 1, {"decoration.bench": 1}, 1, GardenTimePeriod.DAY, GardenWeather.CLEAR)
	diorama.render_garden(state, catalog, 2000, snap, "visitor.cat", "", "", GardenZone.ZONE_MAIN, "th")
	var observe_hits: Array[int] = []
	view.visitor_observation_requested.connect(func() -> void:
		observe_hits.append(1)
	)
	# Ensure ObserveVisitorButton is enabled in test context
	view.get_observe_visitor_button().disabled = false
	var cat_pos: Vector2 = diorama.get_rendered_visitor_node().position + Vector2(0.0, -30.0)
	diorama.simulate_tap_at_world_pos(cat_pos)
	assert_eq(observe_hits.size(), 1, "Tapping active visitor in diorama triggers visitor_observation_requested")

	view.free()


func _test_picker_sprite_thumbnails_and_fallbacks() -> void:
	describe("PlantingPicker and DecorationPicker display GardenAssetCatalog icons for illustrated entries")
	var catalog: ContentCatalog = _create_full_catalog()

	var p_scene: PackedScene = load(PLANTING_PICKER_SCENE_PATH) as PackedScene
	var p_picker: PlantingPicker = p_scene.instantiate() as PlantingPicker
	p_picker.bind_catalog(catalog)
	var p_list: Node = p_picker.get_node("CenterContainer/PickerPanel/MarginContainer/VBoxContainer/ScrollContainer/ListMargin/PlantListContainer")
	var found_chili_icon: bool = false
	var found_banana_null: bool = false
	for child: Node in p_list.get_children():
		var btn: Button = child as Button
		if btn == null:
			continue
		if btn.text.contains("plant.chili"):
			found_chili_icon = (btn.icon == GardenAssetCatalog.get_plant_texture("plant.chili", PlantGrowth.Stage.MATURE))
		elif btn.text.contains("plant.banana"):
			found_banana_null = (btn.icon == null)
	assert_true(found_chili_icon, "PlantingPicker shows mature sprite icon for plant.chili")
	assert_true(found_banana_null, "PlantingPicker leaves icon null for non-illustrated plant.banana")
	p_picker.free()

	var d_scene: PackedScene = load(DECORATION_PICKER_SCENE_PATH) as PackedScene
	var d_picker: DecorationPicker = d_scene.instantiate() as DecorationPicker
	d_picker.bind_catalog(catalog)
	var d_list: Node = d_picker.get_node("CenterContainer/PickerPanel/MarginContainer/VBoxContainer/ScrollContainer/ListMargin/DecorationListContainer")
	var found_bench_icon: bool = false
	var found_can_null: bool = false
	for child: Node in d_list.get_children():
		var btn: Button = child as Button
		if btn == null:
			continue
		if btn.text.contains("decoration.bench"):
			found_bench_icon = (btn.icon == GardenAssetCatalog.get_decoration_texture("decoration.bench"))
		elif btn.text.contains("decoration.watering_can"):
			found_can_null = (btn.icon == null)
	assert_true(found_bench_icon, "DecorationPicker shows sprite icon for decoration.bench")
	assert_true(found_can_null, "DecorationPicker leaves icon null for non-illustrated decoration.watering_can")
	d_picker.free()


func _test_diorama_bird_and_frog_visitor_anchoring() -> void:
	describe("GardenDiorama anchors Frog near pond/jar and Bird on fence/jar/banana perches")
	var scene: PackedScene = load(GARDEN_DIORAMA_SCENE_PATH) as PackedScene
	var diorama: GardenDiorama = scene.instantiate() as GardenDiorama
	var catalog: ContentCatalog = _create_full_catalog()

	# 1. Frog beside small_pond, fallback beside clay_jar, fallback to default ground
	var pond_state: GameState = GameState.new()
	pond_state.get_decorations().try_add_decoration(DecorationState.new("d-pond", "decoration.small_pond", 1000, GardenZone.ZONE_MAIN, 1, 2))
	pond_state.get_decorations().try_add_decoration(DecorationState.new("d-jar", "decoration.clay_jar", 1000, GardenZone.ZONE_MAIN, 2, 1))
	var frog_snap: GardenSnapshot = GardenSnapshot.new({"water": 2}, {}, 0, 0, {"decoration.small_pond": 1, "decoration.clay_jar": 1}, 2, GardenTimePeriod.DAY, GardenWeather.RAIN)
	diorama.render_garden(pond_state, catalog, 2000, frog_snap, "visitor.frog", "", "", GardenZone.ZONE_MAIN, "th")
	var pond_node: Node2D = diorama.get_rendered_item_node("d-pond")
	var frog_node: Node2D = diorama.get_rendered_visitor_node()
	assert_true(pond_node != null and frog_node != null, "Pond and Frog rendered")
	assert_eq(frog_node.position, pond_node.position + GardenDiorama.POND_FROG_OFFSET, "Frog anchors beside small_pond when present")

	var jar_only_state: GameState = GameState.new()
	jar_only_state.get_decorations().try_add_decoration(DecorationState.new("d-jar", "decoration.clay_jar", 1000, GardenZone.ZONE_MAIN, 2, 1))
	diorama.render_garden(jar_only_state, catalog, 2000, frog_snap, "visitor.frog", "", "", GardenZone.ZONE_MAIN, "th")
	assert_eq(diorama.get_rendered_visitor_node().position, diorama.get_rendered_item_node("d-jar").position + GardenDiorama.JAR_FROG_OFFSET, "Frog anchors beside clay_jar without pond")

	var empty_state: GameState = GameState.new()
	diorama.render_garden(empty_state, catalog, 2000, frog_snap, "visitor.frog", "", "", GardenZone.ZONE_MAIN, "th")
	assert_eq(diorama.get_rendered_visitor_node().position, GardenDiorama.DEFAULT_FROG_GROUND_POS, "Frog uses damp ground fallback without water decor")

	# 2. Bird on wooden_fence -> clay_jar -> default background fence perch
	var fence_state: GameState = GameState.new()
	fence_state.get_decorations().try_add_decoration(DecorationState.new("d-fence", "decoration.wooden_fence", 1000, GardenZone.ZONE_MAIN, 0, 0))
	fence_state.get_decorations().try_add_decoration(DecorationState.new("d-jar", "decoration.clay_jar", 1000, GardenZone.ZONE_MAIN, 2, 1))
	var bird_snap: GardenSnapshot = GardenSnapshot.new({"perch": 1, "fruit": 1}, {}, 0, 0, {"decoration.wooden_fence": 1, "decoration.clay_jar": 1}, 2, GardenTimePeriod.DAY, GardenWeather.CLEAR)
	diorama.render_garden(fence_state, catalog, 2000, bird_snap, "visitor.bird", "", "", GardenZone.ZONE_MAIN, "th")
	assert_eq(diorama.get_rendered_visitor_node().position, diorama.get_rendered_item_node("d-fence").position + GardenDiorama.FENCE_BIRD_PERCH_OFFSET, "Bird perches on wooden_fence when present")

	diorama.render_garden(jar_only_state, catalog, 2000, bird_snap, "visitor.bird", "", "", GardenZone.ZONE_MAIN, "th")
	assert_eq(diorama.get_rendered_visitor_node().position, diorama.get_rendered_item_node("d-jar").position + GardenDiorama.JAR_BIRD_PERCH_OFFSET, "Bird perches on clay_jar rim when fence/lamp/table absent")

	diorama.render_garden(empty_state, catalog, 2000, bird_snap, "visitor.bird", "", "", GardenZone.ZONE_MAIN, "th")
	assert_eq(diorama.get_rendered_visitor_node().position, GardenDiorama.DEFAULT_BIRD_PERCH_POS, "Bird perches on background fence rail fallback")

	# 3. Tapping center-pivoted bird visitor emits visitor_selected
	var tapped_visitors: Array[String] = []
	diorama.visitor_selected.connect(func(vid: String) -> void:
		tapped_visitors.append(vid)
	)
	diorama.simulate_tap_at_world_pos(GardenDiorama.DEFAULT_BIRD_PERCH_POS)
	assert_eq(tapped_visitors, ["visitor.bird"], "Tapping center-pivoted bird visitor emits visitor_selected")

	diorama.free()
