## garden_view.gd
## Presentation container and controller for Garden's authoritative plant collection.
##
## Architectural rules:
## - Belongs to the presentation layer (src/presentation/garden/).
## - Pure view/controller for the garden plant display and inspection.
## - Does not own, mutate, or duplicate authoritative GameState.
## - Receives GameSession, ContentCatalog, and GameClock via explicit dependency injection.
## - Does not depend directly on the global App Autoload.
## - Samples GameClock once per refresh and distributes the timestamp across all plants.
## - Derives growth stages exclusively via PlantGrowth domain rules.
## - Displays plants in deterministic order matching PlantCollectionState.get_all_plants().
## - Does not call planting commands, grant/spend currency, or call repository.save().
## - Ephemeral presentation selection only; selection is never persisted.
## - Handles empty garden and blocked startup gracefully.
class_name GardenView
extends Control

signal planting_requested(definition_id: String)
signal harvest_requested(runtime_instance_id: String)
signal visitor_observation_requested()
signal event_observation_requested()
signal decoration_purchase_requested(definition_id: String)

const PLANT_VIEW_SCENE: PackedScene = preload("res://scenes/garden/plant_view.tscn")

const PROVISIONAL_TRAIT_DISPLAY_NAMES: Dictionary = {
	"dense_vegetation": "พุ่มไม้หนาแน่น",
	"flower": "ดอกไม้",
	"food": "พืชอาหาร",
	"fruit": "ผลไม้",
	"light": "แสงไฟ",
	"perch": "กิ่งไม้เกาะพัก",
	"shade": "ร่มเงา",
	"shelter": "ที่หลบพัก",
	"water": "แหล่งน้ำ",
}

const PROVISIONAL_VISITOR_DISPLAY_NAMES: Dictionary = {
	"visitor.bird": "นกกระจอกบ้านสวน",
	"visitor.butterfly": "ผีเสื้อบ้านสวน",
	"visitor.cat": "แมวข้างบ้าน",
	"visitor.firefly": "หิ่งห้อย",
	"visitor.frog": "กบในสวน",
}

const PROVISIONAL_TIME_PERIOD_DISPLAY_NAMES: Dictionary = {
	"morning": "ยามเช้า",
	"day": "กลางวัน",
	"evening": "ยามเย็น",
	"night": "ยามค่ำคืน",
}

const PROVISIONAL_WEATHER_DISPLAY_NAMES: Dictionary = {
	"clear": "ท้องฟ้าแจ่มใส",
	"cloudy": "มีเมฆมาก",
	"rain": "ฝนตก",
}

const PROVISIONAL_EVENT_DISPLAY_NAMES: Dictionary = {
	"event.bird_shade_song": "นกร้องเพลงใต้ร่มไม้",
	"event.cat_sleeping_bench": "แมวนอนหลับบนม้านั่ง",
	"event.firefly_night_glow": "หิ่งห้อยเรืองแสงยามค่ำ",
	"event.frog_rain_chorus": "กบร้องเพลงกลางสายฝน",
	"event.morning_butterflies": "ฝูงผีเสื้อยามเช้า",
}

const PROVISIONAL_EVENT_DESCRIPTIONS: Dictionary = {
	"event.bird_shade_song": "นกกระจอกส่งเสียงร้องสดใสอยู่บนกิ่งไม้ใต้ร่มเงา",
	"event.cat_sleeping_bench": "แมวข้างบ้านขดตัวนอนหลับอย่างสบายใจอยู่บนม้านั่งไม้",
	"event.firefly_night_glow": "แสงหิ่งห้อยส่องประกายระยิบระยับอยู่ตามพุ่มไม้ยามค่ำคืน",
	"event.frog_rain_chorus": "กบในสวนส่งเสียงร้องรับสายฝนอยู่ริมแหล่งน้ำ",
	"event.morning_butterflies": "ฝูงผีเสื้อโบยบินวนเวียนตอมดอกไม้ในแสงแดดอ่อน",
}

const PROVISIONAL_PROGRESSION_STAGE_DISPLAY_NAMES: Dictionary = {
	"starting_garden": "สวนเริ่มต้น",
	"growing_garden": "สวนกำลังเติบโต",
	"shady_garden": "สวนร่มรื่น",
	"living_garden": "สวนมีชีวิต",
	"happy_garden_home": "บ้านสวนแสนสุข",
}

const PROVISIONAL_GUIDANCE_DISPLAY_NAMES: Dictionary = {
	"guidance.plant_first": "ลองปลูกต้นไม้ต้นแรกในสวน",
	"guidance.observe_visitor": "ลองสำรวจผู้มาเยือนที่แวะมาในสวน",
	"guidance.place_decoration": "ลองเก็บเกี่ยวเหรียญและวางของตกแต่งชิ้นแรก",
	"guidance.create_water_habitat": "ลองจัดวางตุ่มน้ำหรือบ่อน้ำเล็กเพื่อเพิ่มแหล่งน้ำ",
	"guidance.discover_more": "ลองปลูกพันธุ์ไม้และสำรวจผู้มาเยือนให้ครบในสมุดบ้านสวน",
	"guidance.enjoy_garden": "เพลิดเพลินกับบรรยากาศบ้านสวนแสนสุขตามอัธยาศัย",
}

const TIME_PERIOD_BASE_COLORS: Dictionary = {
	"morning": Color(0.16, 0.20, 0.14, 1.0),
	"day": Color(0.12, 0.18, 0.14, 1.0),
	"evening": Color(0.18, 0.15, 0.13, 1.0),
	"night": Color(0.08, 0.10, 0.15, 1.0),
}

const DEFAULT_BACKGROUND_COLOR: Color = Color(0.12, 0.15, 0.13, 1.0)
const CLOUDY_TINT_COLOR: Color = Color(0.14, 0.16, 0.18, 1.0)
const RAIN_TINT_COLOR: Color = Color(0.10, 0.14, 0.20, 1.0)

var _session: GameSession = null
var _catalog: ContentCatalog = null
var _game_clock: GameClock = null

var _selected_runtime_instance_id: String = ""
var _current_visitor_id: String = ""
var _current_event_id: String = ""
var _eligible_visitor_ids: Array[String] = []
var _eligible_event_ids: Array[String] = []
var _last_snapshot: GardenSnapshot = null
var _last_progression_summary: GardenProgressionSummary = null
var _last_return_summary: GardenReturnSummary = null
var _last_refresh_utc_seconds: int = 0
var _has_refresh_timestamp: bool = false
var _selected_plant_definition_id: String = ""
var _selected_plant_stage: PlantGrowth.Stage = PlantGrowth.Stage.INVALID
var _selected_plant_seconds_until_next_stage: int = -1
var _selected_plant_seconds_until_mature: int = -1
var _selected_plant_traits: Array[String] = []
var _selected_plant_harvest_reward: int = 0
var _selected_plant_planted_at: int = -1
var _next_time_period: String = ""
var _seconds_until_next_time_period: int = 0
var _next_weather_state: String = ""
var _seconds_until_next_weather_state: int = 0
var _is_blocked: bool = false
var _blocked_message: String = ""
var _last_checkpoint_result: PlantingCheckpointResult = null
var _last_harvest_checkpoint_result: HarvestCheckpointResult = null
var _last_visitor_selection_result: VisitorSelectionResult = null
var _last_visitor_observation_checkpoint_result: VisitorObservationCheckpointResult = null
var _last_event_selection_result: EventSelectionResult = null
var _last_decoration_purchase_checkpoint_result: DecorationPurchaseCheckpointResult = null

var _background_rect: ColorRect = null
var _refresh_button: Button = null
var _plant_button: Button = null
var _currency_label: Label = null
var _progression_label: Label = null
var _atmosphere_label: Label = null
var _environment_label: Label = null
var _visitor_row: Control = null
var _visitor_status_label: Label = null
var _observe_visitor_button: Button = null
var _observe_event_button: Button = null
var _journal_row: Control = null
var _journal_status_label: Label = null
var _journal_button: Button = null
var _decoration_row: Control = null
var _decoration_status_label: Label = null
var _decorate_button: Button = null
var _feedback_area: Control = null
var _feedback_label: Label = null
var _planting_picker: PlantingPicker = null
var _journal_panel: JournalPanel = null
var _decoration_picker: DecorationPicker = null

var _plants_container: Container = null
var _plants_scroll: ScrollContainer = null
var _empty_container: Control = null
var _empty_label: Label = null
var _blocked_container: Control = null
var _blocked_label: Label = null

var _no_selection_label: Label = null
var _details_content: Control = null
var _detail_name_label: Label = null
var _detail_stage_label: Label = null
var _detail_reward_label: Label = null
var _detail_id_label: Label = null
var _detail_planted_at_label: Label = null
var _harvest_button: Button = null


func _ready() -> void:
	_resolve_nodes()
	if _is_blocked:
		_show_blocked_visual()
	elif _session != null:
		refresh_from_session()


## Resolves child node references safely whether _ready has fired or not.
func _resolve_nodes() -> void:
	if _background_rect == null:
		_background_rect = get_node_or_null("Background") as ColorRect
	if _refresh_button == null:
		_refresh_button = get_node_or_null("MainMargin/LayoutBox/HeaderArea/RefreshButton") as Button
	if _plant_button == null:
		_plant_button = get_node_or_null("MainMargin/LayoutBox/HeaderArea/PlantButton") as Button
	if _currency_label == null:
		_currency_label = get_node_or_null("MainMargin/LayoutBox/CurrencyLabel") as Label
	if _progression_label == null:
		_progression_label = get_node_or_null("MainMargin/LayoutBox/ProgressionLabel") as Label
	if _atmosphere_label == null:
		_atmosphere_label = get_node_or_null("MainMargin/LayoutBox/AtmosphereLabel") as Label
	if _environment_label == null:
		_environment_label = get_node_or_null("MainMargin/LayoutBox/EnvironmentLabel") as Label
	if _visitor_row == null:
		_visitor_row = get_node_or_null("MainMargin/LayoutBox/VisitorRow") as Control
	if _visitor_status_label == null:
		_visitor_status_label = get_node_or_null("MainMargin/LayoutBox/VisitorRow/VisitorStatusLabel") as Label
	if _observe_visitor_button == null:
		_observe_visitor_button = get_node_or_null("MainMargin/LayoutBox/VisitorRow/ObserveVisitorButton") as Button
	if _observe_event_button == null:
		_observe_event_button = get_node_or_null("MainMargin/LayoutBox/VisitorRow/ObserveEventButton") as Button
	if _journal_row == null:
		_journal_row = get_node_or_null("MainMargin/LayoutBox/JournalRow") as Control
	if _journal_status_label == null:
		_journal_status_label = get_node_or_null("MainMargin/LayoutBox/JournalRow/JournalStatusLabel") as Label
	if _journal_button == null:
		_journal_button = get_node_or_null("MainMargin/LayoutBox/JournalRow/JournalButton") as Button
	if _decoration_row == null:
		_decoration_row = get_node_or_null("MainMargin/LayoutBox/DecorationRow") as Control
	if _decoration_status_label == null:
		_decoration_status_label = get_node_or_null("MainMargin/LayoutBox/DecorationRow/DecorationStatusLabel") as Label
	if _decorate_button == null:
		_decorate_button = get_node_or_null("MainMargin/LayoutBox/DecorationRow/DecorateButton") as Button
	if _feedback_area == null:
		_feedback_area = get_node_or_null("MainMargin/LayoutBox/FeedbackArea") as Control
	if _feedback_label == null:
		_feedback_label = get_node_or_null("MainMargin/LayoutBox/FeedbackArea/FeedbackMargin/FeedbackLabel") as Label
	if _planting_picker == null:
		_planting_picker = get_node_or_null("PlantingPicker") as PlantingPicker
	if _journal_panel == null:
		_journal_panel = get_node_or_null("JournalPanel") as JournalPanel
	if _decoration_picker == null:
		_decoration_picker = get_node_or_null("DecorationPicker") as DecorationPicker
	if _plants_container == null:
		_plants_container = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/PlantsContainer") as Container
	if _plants_scroll == null:
		_plants_scroll = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll") as ScrollContainer
	if _empty_container == null:
		_empty_container = get_node_or_null("MainMargin/LayoutBox/ContentArea/EmptyStateContainer") as Control
	if _empty_label == null:
		_empty_label = get_node_or_null("MainMargin/LayoutBox/ContentArea/EmptyStateContainer/EmptyLabel") as Label
	if _blocked_container == null:
		_blocked_container = get_node_or_null("MainMargin/LayoutBox/ContentArea/BlockedStateContainer") as Control
	if _blocked_label == null:
		_blocked_label = get_node_or_null("MainMargin/LayoutBox/ContentArea/BlockedStateContainer/BlockedLabel") as Label
	if _no_selection_label == null:
		_no_selection_label = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/NoSelectionLabel") as Label
	if _details_content == null:
		_details_content = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/DetailsContent") as Control
	if _detail_name_label == null:
		_detail_name_label = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/DetailsContent/DetailNameLabel") as Label
	if _detail_stage_label == null:
		_detail_stage_label = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/DetailsContent/DetailStageLabel") as Label
	if _detail_reward_label == null:
		_detail_reward_label = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/DetailsContent/DetailRewardLabel") as Label
	if _detail_id_label == null:
		_detail_id_label = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/DetailsContent/DetailIdLabel") as Label
	if _detail_planted_at_label == null:
		_detail_planted_at_label = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/DetailsContent/DetailPlantedAtLabel") as Label
	if _harvest_button == null:
		_harvest_button = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/DetailsContent/HarvestButton") as Button
	_connect_signals()


func _connect_signals() -> void:
	if _refresh_button != null and not _refresh_button.pressed.is_connected(_on_refresh_button_pressed):
		_refresh_button.pressed.connect(_on_refresh_button_pressed)
	if _plant_button != null and not _plant_button.pressed.is_connected(open_planting_picker):
		_plant_button.pressed.connect(open_planting_picker)
	if _planting_picker != null and not _planting_picker.planting_requested.is_connected(_on_picker_planting_requested):
		_planting_picker.planting_requested.connect(_on_picker_planting_requested)
	if _harvest_button != null and not _harvest_button.pressed.is_connected(_on_harvest_button_pressed):
		_harvest_button.pressed.connect(_on_harvest_button_pressed)
	if _observe_visitor_button != null and not _observe_visitor_button.pressed.is_connected(_on_observe_visitor_button_pressed):
		_observe_visitor_button.pressed.connect(_on_observe_visitor_button_pressed)
	if _observe_event_button != null and not _observe_event_button.pressed.is_connected(_on_observe_event_button_pressed):
		_observe_event_button.pressed.connect(_on_observe_event_button_pressed)
	if _journal_button != null and not _journal_button.pressed.is_connected(open_journal_panel):
		_journal_button.pressed.connect(open_journal_panel)
	if _decorate_button != null and not _decorate_button.pressed.is_connected(open_decoration_picker):
		_decorate_button.pressed.connect(open_decoration_picker)
	if _decoration_picker != null and not _decoration_picker.decoration_purchase_requested.is_connected(_on_picker_decoration_purchase_requested):
		_decoration_picker.decoration_purchase_requested.connect(_on_picker_decoration_purchase_requested)


## Explicit dependency injection API for GardenView.
## Allows unit and integration tests to inject test doubles without App Autoload.
func bind_garden(
	session: GameSession,
	catalog: ContentCatalog,
	game_clock: GameClock
) -> void:
	_session = session
	_catalog = catalog
	_game_clock = game_clock

	_resolve_nodes()
	if _planting_picker != null and _catalog != null:
		_planting_picker.bind_catalog(_catalog)
		_planting_picker.set_picker_enabled(true)
	if _journal_panel != null:
		_journal_panel.set_journal_enabled(true)
	if _decoration_picker != null and _catalog != null:
		_decoration_picker.bind_catalog(_catalog)
		_decoration_picker.set_picker_enabled(true)

	if _plant_button != null:
		_plant_button.disabled = false
	if _journal_button != null:
		_journal_button.disabled = false
	if _decorate_button != null:
		_decorate_button.disabled = false

	if _session == null or _catalog == null or _game_clock == null:
		show_blocked_startup("ไม่สามารถเริ่มต้นสวนได้เนื่องจากข้อมูลไม่สมบูรณ์")
		return

	_is_blocked = false
	_blocked_message = ""
	_has_refresh_timestamp = false
	_last_refresh_utc_seconds = 0
	_last_return_summary = null
	refresh_from_session()


## Displays a safe readable state when startup failed or session is unavailable.
func show_blocked_startup(message: String = "") -> void:
	_is_blocked = true
	_blocked_message = message if not message.is_empty() else "ไม่สามารถโหลดสวนได้ในขณะนี้"
	_resolve_nodes()
	if _plant_button != null:
		_plant_button.disabled = true
	if _journal_button != null:
		_journal_button.disabled = true
	if _decorate_button != null:
		_decorate_button.disabled = true
	if _planting_picker != null:
		_planting_picker.set_picker_enabled(false)
		_planting_picker.close_picker()
	if _journal_panel != null:
		_journal_panel.set_journal_enabled(false)
		_journal_panel.close_journal()
	if _decoration_picker != null:
		_decoration_picker.set_picker_enabled(false)
		_decoration_picker.close_picker()
	_show_blocked_visual()


## Explicit refresh API: re-reads authoritative GameState and samples clock once.
func refresh_from_session() -> void:
	if _is_blocked or _session == null or _catalog == null or _game_clock == null:
		_show_blocked_visual()
		return

	# Sample the injected GameClock once for all plants (Requirement 10).
	var now_utc: int = _game_clock.utc_now_seconds()

	if _has_refresh_timestamp and now_utc >= 0 and _last_refresh_utc_seconds >= 0:
		_last_return_summary = GardenReturnEvaluator.evaluate_return_between(
			_session.get_state(),
			_catalog,
			_last_refresh_utc_seconds,
			now_utc
		)
	else:
		_last_return_summary = null

	if now_utc >= 0:
		_last_refresh_utc_seconds = now_utc
		_has_refresh_timestamp = true

	# Read authoritative currency balance directly from GameSession (no presentation cache).
	_resolve_nodes()
	if _currency_label != null:
		_currency_label.visible = true
		_currency_label.text = "เหรียญ: %d" % _session.get_currency()

	# Authoritative plant collection in deterministic order (Requirement 9, 20).
	var plants: Array[PlantState] = _session.get_state().get_plants().get_all_plants()

	_render_plants(plants, now_utc)
	_update_environment_and_visitors(now_utc)
	_update_journal_ui()


func _on_refresh_button_pressed() -> void:
	refresh_from_session()


func _render_plants(plants: Array[PlantState], now_utc: int) -> void:
	_resolve_nodes()

	if _blocked_container != null:
		_blocked_container.visible = false

	# Gracefully handle empty garden (Requirement 16).
	if plants.is_empty():
		_clear_plant_views()
		_selected_runtime_instance_id = ""
		if _empty_container != null:
			_empty_container.visible = true
		if _plants_scroll != null:
			_plants_scroll.visible = false
		_update_details_panel(null, null, PlantGrowth.Stage.INVALID, 0)
		return

	if _empty_container != null:
		_empty_container.visible = false
	if _plants_scroll != null:
		_plants_scroll.visible = true

	# Clear previous plant views to avoid duplicate nodes on refresh (Requirement 19).
	_clear_plant_views()

	var selected_plant_state: PlantState = null
	var selected_definition: PlantDefinition = null
	var selected_stage: PlantGrowth.Stage = PlantGrowth.Stage.INVALID

	for plant_state: PlantState in plants:
		var instance_id: String = plant_state.get_runtime_instance_id()
		var def_id: String = plant_state.get_definition_id()
		var planted_at: int = plant_state.get_planted_at()

		# Look up definition in ContentCatalog (Requirement 9).
		var definition: PlantDefinition = _catalog.get_plant(def_id)

		# Derive growth stage using existing PlantGrowth domain logic (Requirement 9, 11).
		var stage: PlantGrowth.Stage = PlantGrowth.Stage.INVALID
		var harvest_reward: int = 0
		var seconds_until_next_stage: int = -1
		var seconds_until_mature: int = -1
		var plant_traits: Array[String] = []
		if definition != null:
			stage = PlantGrowth.stage_for_state_at(plant_state, definition, now_utc)
			harvest_reward = definition.harvest_reward
			seconds_until_next_stage = PlantGrowth.seconds_until_next_stage_at(plant_state, definition, now_utc)
			seconds_until_mature = PlantGrowth.seconds_until_mature_at(plant_state, definition, now_utc)
			plant_traits = definition.environmental_traits.duplicate()

		# Instantiate PlantView component.
		var view: PlantView = PLANT_VIEW_SCENE.instantiate() as PlantView
		view.bind_plant_data(
			instance_id,
			def_id,
			stage,
			planted_at,
			harvest_reward,
			seconds_until_mature,
			plant_traits,
			seconds_until_next_stage
		)
		view.plant_selected.connect(_on_plant_selected)

		# Preserve existing selection if this plant is still present (Requirement 18, 19).
		if instance_id == _selected_runtime_instance_id:
			view.set_selected(true)
			selected_plant_state = plant_state
			selected_definition = definition
			selected_stage = stage

		if _plants_container != null:
			_plants_container.add_child(view)

	# If the previously selected plant no longer exists, safely clear selection (Requirement 18).
	if selected_plant_state == null:
		_selected_runtime_instance_id = ""
		_update_details_panel(null, null, PlantGrowth.Stage.INVALID, 0)
	else:
		_update_details_panel(selected_plant_state, selected_definition, selected_stage, now_utc)


func _clear_plant_views() -> void:
	if _plants_container == null:
		return
	for child: Node in _plants_container.get_children():
		_plants_container.remove_child(child)
		child.queue_free()


func _on_plant_selected(runtime_instance_id: String) -> void:
	_selected_runtime_instance_id = runtime_instance_id

	_resolve_nodes()
	if _plants_container != null:
		for child: Node in _plants_container.get_children():
			if child is PlantView:
				var view: PlantView = child as PlantView
				view.set_selected(view.get_runtime_instance_id() == runtime_instance_id)

	if _session != null:
		var plant_state: PlantState = _session.get_state().get_plants().get_plant(runtime_instance_id)
		if plant_state != null:
			var definition: PlantDefinition = _catalog.get_plant(plant_state.get_definition_id()) if _catalog != null else null
			var now_utc: int = _game_clock.utc_now_seconds() if _game_clock != null else 0
			var stage: PlantGrowth.Stage = PlantGrowth.Stage.INVALID
			if definition != null:
				stage = PlantGrowth.stage_for_state_at(plant_state, definition, now_utc)
			_update_details_panel(plant_state, definition, stage, now_utc)
			return

	_update_details_panel(null, null, PlantGrowth.Stage.INVALID, 0)


func _update_details_panel(
	plant_state: PlantState,
	definition: PlantDefinition,
	stage: PlantGrowth.Stage,
	now_utc: int
) -> void:
	_resolve_nodes()
	if _no_selection_label == null or _details_content == null:
		return

	if plant_state == null:
		_selected_plant_definition_id = ""
		_selected_plant_stage = PlantGrowth.Stage.INVALID
		_selected_plant_seconds_until_next_stage = -1
		_selected_plant_seconds_until_mature = -1
		_selected_plant_traits = []
		_selected_plant_harvest_reward = 0
		_selected_plant_planted_at = -1
		_no_selection_label.visible = true
		_details_content.visible = false
		if _harvest_button != null:
			_harvest_button.disabled = true
			_harvest_button.text = "ยังไม่พร้อมเก็บเกี่ยว"
		return

	_no_selection_label.visible = false
	_details_content.visible = true

	_selected_plant_definition_id = plant_state.get_definition_id()
	_selected_plant_stage = stage
	_selected_plant_seconds_until_next_stage = PlantGrowth.seconds_until_next_stage_at(
		plant_state,
		definition,
		now_utc
	)
	_selected_plant_seconds_until_mature = PlantGrowth.seconds_until_mature_at(
		plant_state,
		definition,
		now_utc
	)
	_selected_plant_traits = (
		definition.environmental_traits.duplicate()
		if definition != null
		else []
	)
	_selected_plant_harvest_reward = (
		maxi(0, definition.harvest_reward)
		if definition != null
		else 0
	)
	_selected_plant_planted_at = plant_state.get_planted_at()

	var def_id: String = plant_state.get_definition_id()
	var thai_name: String = PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.get(def_id, def_id)

	if _detail_name_label != null:
		if not _selected_plant_traits.is_empty():
			var trait_names: PackedStringArray = PackedStringArray()
			for trait_id: String in _selected_plant_traits:
				trait_names.append(PROVISIONAL_TRAIT_DISPLAY_NAMES.get(trait_id, trait_id))
			_detail_name_label.text = (
				"พืช: %s (%s) | คุณสมบัติ: %s"
				% [thai_name, def_id, ", ".join(trait_names)]
			)
		else:
			_detail_name_label.text = "พืช: %s (%s)" % [thai_name, def_id]

	if _detail_stage_label != null:
		var stage_text: String = ""
		match stage:
			PlantGrowth.Stage.PLANTED:
				stage_text = "เพาะเมล็ด (PLANTED)"
			PlantGrowth.Stage.SPROUT:
				stage_text = "ต้นกล้า (SPROUT)"
			PlantGrowth.Stage.GROWING:
				stage_text = "กำลังโต (GROWING)"
			PlantGrowth.Stage.MATURE:
				stage_text = "โตเต็มที่ (MATURE)"
			_:
				stage_text = "ไม่ทราบสถานะ (INVALID)"
		if stage == PlantGrowth.Stage.MATURE:
			_detail_stage_label.text = "ระยะ: %s — พร้อมเก็บเกี่ยวแล้ว" % stage_text
		elif stage != PlantGrowth.Stage.INVALID and _selected_plant_seconds_until_mature > 0:
			_detail_stage_label.text = (
				"ระยะ: %s — โตเต็มที่ในอีก %d วินาที (ระยะถัดไปในอีก %d วินาที)"
				% [
					stage_text,
					_selected_plant_seconds_until_mature,
					_selected_plant_seconds_until_next_stage,
				]
			)
		else:
			_detail_stage_label.text = "ระยะ: %s" % stage_text

	if _detail_reward_label != null:
		if definition != null and definition.harvest_reward > 0:
			_detail_reward_label.text = "รางวัลเก็บเกี่ยว: %d เหรียญ" % definition.harvest_reward
		else:
			_detail_reward_label.text = "รางวัลเก็บเกี่ยว: —"

	if _detail_id_label != null:
		_detail_id_label.text = "รหัสประจำต้น: %s" % plant_state.get_runtime_instance_id()

	if _detail_planted_at_label != null:
		_detail_planted_at_label.text = "ปลูกเมื่อ: %d (Unix UTC)" % plant_state.get_planted_at()

	if _harvest_button != null:
		var can_harvest: bool = (
			not _is_blocked
			and stage == PlantGrowth.Stage.MATURE
			and definition != null
			and definition.harvest_reward > 0
		)
		_harvest_button.disabled = not can_harvest
		if can_harvest:
			_harvest_button.text = "เก็บเกี่ยว (+%d เหรียญ)" % definition.harvest_reward
		else:
			_harvest_button.text = "ยังไม่พร้อมเก็บเกี่ยว"


func _show_blocked_visual() -> void:
	_resolve_nodes()
	_clear_plant_views()
	_selected_runtime_instance_id = ""
	_current_visitor_id = ""
	_current_event_id = ""
	_eligible_visitor_ids = []
	_eligible_event_ids = []
	_last_snapshot = null
	_last_progression_summary = null
	_last_return_summary = null
	_last_refresh_utc_seconds = 0
	_has_refresh_timestamp = false
	_selected_plant_definition_id = ""
	_selected_plant_stage = PlantGrowth.Stage.INVALID
	_selected_plant_seconds_until_next_stage = -1
	_selected_plant_seconds_until_mature = -1
	_selected_plant_traits = []
	_selected_plant_harvest_reward = 0
	_selected_plant_planted_at = -1
	_next_time_period = ""
	_seconds_until_next_time_period = 0
	_next_weather_state = ""
	_seconds_until_next_weather_state = 0

	if _background_rect != null:
		_background_rect.color = DEFAULT_BACKGROUND_COLOR
	if _currency_label != null:
		_currency_label.visible = false
	if _progression_label != null:
		_progression_label.visible = false
	if _atmosphere_label != null:
		_atmosphere_label.visible = false
	if _environment_label != null:
		_environment_label.visible = false
	if _visitor_row != null:
		_visitor_row.visible = false
	if _observe_visitor_button != null:
		_observe_visitor_button.disabled = true
	if _observe_event_button != null:
		_observe_event_button.disabled = true
	if _journal_row != null:
		_journal_row.visible = false
	if _journal_button != null:
		_journal_button.disabled = true
	if _decoration_row != null:
		_decoration_row.visible = false
	if _decorate_button != null:
		_decorate_button.disabled = true
	if _feedback_area != null:
		_feedback_area.visible = false
	if _empty_container != null:
		_empty_container.visible = false
	if _plants_scroll != null:
		_plants_scroll.visible = false
	if _blocked_container != null:
		_blocked_container.visible = true
	if _blocked_label != null:
		_blocked_label.text = _blocked_message if not _blocked_message.is_empty() else "ไม่สามารถโหลดสวนได้ในขณะนี้"

	_update_details_panel(null, null, PlantGrowth.Stage.INVALID, 0)


func _update_environment_and_visitors(now_utc: int) -> void:
	_resolve_nodes()
	_last_snapshot = GardenSnapshotBuilder.build_snapshot(
		_session.get_state(),
		_catalog,
		now_utc
	)

	var journal: JournalState = (
		_session.get_state().get_journal()
		if _session != null and _session.get_state() != null
		else null
	)
	if _planting_picker != null:
		_planting_picker.update_garden_context(_last_snapshot, journal)
	if _decoration_picker != null:
		_decoration_picker.update_shop_context(_session.get_currency(), _last_snapshot)

	_last_progression_summary = GardenProgressionStage.evaluate(_last_snapshot, journal)
	if _progression_label != null and _last_progression_summary != null:
		_progression_label.visible = true
		var stage_id: String = _last_progression_summary.get_stage_id()
		var stage_name: String = PROVISIONAL_PROGRESSION_STAGE_DISPLAY_NAMES.get(stage_id, stage_id)
		var score: int = _last_progression_summary.get_establishment_score()
		var guidance_id: String = _last_progression_summary.get_guidance_id()
		var guidance_text: String = PROVISIONAL_GUIDANCE_DISPLAY_NAMES.get(guidance_id, guidance_id)
		if _last_progression_summary.is_max_stage():
			_progression_label.text = (
				"ระดับสวน: %s (%d แต้ม, สูงสุดแล้ว) | วันนี้ทำอะไรดี: %s"
				% [stage_name, score, guidance_text]
			)
		else:
			var next_stage_id: String = _last_progression_summary.get_next_stage_id()
			var next_stage_name: String = PROVISIONAL_PROGRESSION_STAGE_DISPLAY_NAMES.get(
				next_stage_id,
				next_stage_id
			)
			var points_remaining: int = _last_progression_summary.get_points_to_next_stage()
			_progression_label.text = (
				"ระดับสวน: %s (%d แต้ม, อีก %d แต้มสู่%s) | วันนี้ทำอะไรดี: %s"
				% [stage_name, score, points_remaining, next_stage_name, guidance_text]
			)

	var time_period: String = _last_snapshot.get_time_period()
	var weather_state: String = _last_snapshot.get_weather_state()
	_next_time_period = GardenTimePeriod.next_period_for_utc_seconds(now_utc)
	_seconds_until_next_time_period = GardenTimePeriod.seconds_until_next_period(now_utc)
	_next_weather_state = GardenWeather.next_weather_for_utc_seconds(now_utc)
	_seconds_until_next_weather_state = GardenWeather.seconds_until_next_weather(now_utc)

	var eligible_events: Array[EventDefinition] = EventEligibility.filter_eligible_events(
		_catalog.get_all_events(),
		_last_snapshot
	)
	_eligible_event_ids = []
	for event_def: EventDefinition in eligible_events:
		_eligible_event_ids.append(event_def.id)

	if _atmosphere_label != null:
		_atmosphere_label.visible = true
		var time_name: String = PROVISIONAL_TIME_PERIOD_DISPLAY_NAMES.get(time_period, time_period)
		var weather_name: String = PROVISIONAL_WEATHER_DISPLAY_NAMES.get(weather_state, weather_state)
		var events_summary: String = "สงบเงียบ"
		if not _eligible_event_ids.is_empty():
			var event_names: PackedStringArray = PackedStringArray()
			for eid: String in _eligible_event_ids:
				event_names.append(PROVISIONAL_EVENT_DISPLAY_NAMES.get(eid, eid))
			events_summary = ", ".join(event_names)
		_atmosphere_label.text = (
			"บรรยากาศสวน: %s | สภาพอากาศ: %s | เหตุการณ์ในสวน: %s"
			% [time_name, weather_name, events_summary]
		)

	if _background_rect != null:
		_background_rect.color = _compute_atmosphere_background_color(time_period, weather_state)

	if _environment_label != null:
		_environment_label.visible = true
		var active_traits: Array[String] = _last_snapshot.get_active_traits()
		if active_traits.is_empty():
			_environment_label.text = "สภาพแวดล้อมสวน: ยังไม่มี"
		else:
			var trait_parts: PackedStringArray = PackedStringArray()
			for trait_id: String in active_traits:
				var trait_name: String = PROVISIONAL_TRAIT_DISPLAY_NAMES.get(trait_id, trait_id)
				var count: int = _last_snapshot.get_trait_count(trait_id)
				trait_parts.append("%s (%d)" % [trait_name, count])
			_environment_label.text = "สภาพแวดล้อมสวน: %s" % ", ".join(trait_parts)

	var eligible_visitors: Array[VisitorDefinition] = VisitorEligibility.filter_eligible_visitors(
		_catalog.get_all_visitors(),
		_last_snapshot
	)
	_eligible_visitor_ids = []
	for visitor_def: VisitorDefinition in eligible_visitors:
		_eligible_visitor_ids.append(visitor_def.id)

	if not _current_visitor_id.is_empty() and not _eligible_visitor_ids.has(_current_visitor_id):
		_current_visitor_id = ""
	if not _current_event_id.is_empty() and not _eligible_event_ids.has(_current_event_id):
		_current_event_id = ""

	if _visitor_row != null:
		_visitor_row.visible = true

	if _observe_visitor_button != null:
		_observe_visitor_button.disabled = _is_blocked or _eligible_visitor_ids.is_empty()
	if _observe_event_button != null:
		_observe_event_button.disabled = _is_blocked or _eligible_event_ids.is_empty()

	if _visitor_status_label != null:
		if not _current_visitor_id.is_empty():
			var visitor_name: String = PROVISIONAL_VISITOR_DISPLAY_NAMES.get(
				_current_visitor_id,
				_current_visitor_id
			)
			_visitor_status_label.text = "ผู้มาเยือนในสวน: %s (%s)" % [visitor_name, _current_visitor_id]
		elif not _eligible_visitor_ids.is_empty():
			var names: PackedStringArray = PackedStringArray()
			for vid: String in _eligible_visitor_ids:
				names.append(PROVISIONAL_VISITOR_DISPLAY_NAMES.get(vid, vid))
			_visitor_status_label.text = "ผู้มาเยือนที่อาจพบ: %s" % ", ".join(names)
		else:
			_visitor_status_label.text = "ผู้มาเยือน: ยังไม่มีผู้มาเยือน"

	if _decoration_row != null:
		_decoration_row.visible = true
	if _decorate_button != null:
		_decorate_button.disabled = _is_blocked or _session == null
	if _decoration_status_label != null:
		var total_decor: int = _last_snapshot.get_total_decoration_count()
		if total_decor <= 0:
			_decoration_status_label.text = "ของตกแต่งในสวน: ยังไม่มี"
		else:
			var decor_parts: PackedStringArray = PackedStringArray()
			for decor_id: String in _last_snapshot.get_present_decoration_definition_ids():
				var decor_name: String = DecorationPicker.PROVISIONAL_DECORATION_DISPLAY_NAMES.get(
					decor_id,
					decor_id
				)
				var d_count: int = _last_snapshot.get_decoration_count_for_definition(decor_id)
				decor_parts.append("%s (%d)" % [decor_name, d_count])
			_decoration_status_label.text = (
				"ของตกแต่งในสวน (%d ชิ้น): %s" % [total_decor, ", ".join(decor_parts)]
			)


func _update_journal_ui() -> void:
	_resolve_nodes()
	var journal: JournalState = _session.get_state().get_journal() if _session != null and _session.get_state() != null else null
	var decorations: DecorationCollectionState = (
		_session.get_state().get_decorations()
		if _session != null and _session.get_state() != null
		else null
	)
	if _journal_panel != null:
		_journal_panel.bind_journal(journal, _catalog, decorations, _last_snapshot)

	if _journal_row != null:
		_journal_row.visible = true
	if _journal_button != null:
		_journal_button.disabled = _is_blocked or _session == null

	if _journal_status_label != null:
		if _catalog == null:
			_journal_status_label.text = "สมุดบ้านสวน: ค้นพบแล้ว 0 / 0 รายการ"
			return

		var total_plants: int = _catalog.get_plant_count()
		var total_visitors: int = _catalog.get_visitor_count()
		var total_entries: int = total_plants + total_visitors
		var disc_plants: int = 0
		var disc_visitors: int = 0

		if journal != null:
			for pid: String in _catalog.get_all_plant_ids():
				if journal.has_discovered(pid):
					disc_plants += 1
			for vid: String in _catalog.get_all_visitor_ids():
				if journal.has_discovered(vid):
					disc_visitors += 1

		var disc_total: int = disc_plants + disc_visitors
		_journal_status_label.text = (
			"สมุดบ้านสวน: ค้นพบแล้ว %d / %d รายการ (พืช %d/%d, ผู้มาเยือน %d/%d)"
			% [disc_total, total_entries, disc_plants, total_plants, disc_visitors, total_visitors]
		)


## Pure query for testing: returns true if startup is blocked.
func is_startup_blocked() -> bool:
	return _is_blocked


## Pure query for testing: returns true if empty garden message is visible.
func is_empty_garden_displayed() -> bool:
	_resolve_nodes()
	return _empty_container != null and _empty_container.visible


## Pure query for testing: returns count of rendered PlantView items.
func get_displayed_plant_count() -> int:
	_resolve_nodes()
	return _plants_container.get_child_count() if _plants_container != null else 0


## Pure query for testing: returns all rendered PlantView items in order.
func get_plant_views() -> Array[PlantView]:
	_resolve_nodes()
	var views: Array[PlantView] = []
	if _plants_container != null:
		for child: Node in _plants_container.get_children():
			if child is PlantView:
				views.append(child as PlantView)
	return views


## Pure query for testing: returns PlantView with matching runtime instance ID.
func get_plant_view_by_id(runtime_instance_id: String) -> PlantView:
	_resolve_nodes()
	if _plants_container != null:
		for child: Node in _plants_container.get_children():
			if child is PlantView and (child as PlantView).get_runtime_instance_id() == runtime_instance_id:
				return child as PlantView
	return null


## Pure query for testing: returns ephemeral selected runtime instance ID.
func get_selected_runtime_instance_id() -> String:
	return _selected_runtime_instance_id


## Pure query for testing: returns blocked message string.
func get_blocked_message() -> String:
	return _blocked_message


## Pure query for testing: returns empty state message string.
func get_empty_message() -> String:
	_resolve_nodes()
	return _empty_label.text if _empty_label != null else ""


## Pure query for testing: returns Refresh button instance.
func get_refresh_button() -> Button:
	_resolve_nodes()
	return _refresh_button


## Pure query for testing: returns text displayed in details label.
func get_detail_name_text() -> String:
	_resolve_nodes()
	return _detail_name_label.text if _detail_name_label != null else ""


## Pure query for testing: returns text displayed in detail stage label.
func get_detail_stage_text() -> String:
	_resolve_nodes()
	return _detail_stage_label.text if _detail_stage_label != null else ""


func _on_picker_planting_requested(definition_id: String) -> void:
	planting_requested.emit(definition_id)


## Opens the planting picker modal.
func open_planting_picker() -> void:
	if _is_blocked or _session == null:
		return
	_resolve_nodes()
	if _planting_picker != null:
		_planting_picker.open_picker()


## Closes the planting picker modal.
func close_planting_picker() -> void:
	_resolve_nodes()
	if _planting_picker != null:
		_planting_picker.close_picker()


## Displays user feedback from a PlantingCheckpointResult.
func show_planting_result(result: PlantingCheckpointResult) -> void:
	_last_checkpoint_result = result
	_resolve_nodes()
	if _feedback_area == null or _feedback_label == null or result == null:
		return

	_feedback_area.visible = true
	match result.get_status():
		PlantingCheckpointResult.Status.NOT_READY:
			_feedback_label.text = "ระบบยังไม่พร้อมสำหรับการปลูกต้นไม้"
		PlantingCheckpointResult.Status.PLANTING_REJECTED:
			var reason_str: String = ""
			var reg_result: PlantRegistrationResult = result.get_registration_result()
			if reg_result != null:
				match reg_result.get_status():
					PlantRegistrationResult.INVALID_INPUT:
						reason_str = "INVALID_INPUT"
					PlantRegistrationResult.UNKNOWN_DEFINITION_ID:
						reason_str = "UNKNOWN_DEFINITION_ID"
					PlantRegistrationResult.DUPLICATE_INSTANCE_ID:
						reason_str = "DUPLICATE_INSTANCE_ID"
					PlantRegistrationResult.INSERTION_REJECTED:
						reason_str = "INSERTION_REJECTED"
					PlantRegistrationResult.ID_GENERATION_FAILED:
						reason_str = "ID_GENERATION_FAILED"
					_:
						reason_str = "UNKNOWN"
			if not reason_str.is_empty():
				_feedback_label.text = "ไม่สามารถเพิ่มต้นไม้ได้ (%s)" % reason_str
			else:
				_feedback_label.text = "ไม่สามารถเพิ่มต้นไม้ได้"
		PlantingCheckpointResult.Status.REGISTERED_SAVED:
			_feedback_label.text = "เพิ่มต้นไม้และบันทึกเรียบร้อยแล้ว"
		PlantingCheckpointResult.Status.REGISTERED_SAVE_FAILED:
			_feedback_label.text = "เพิ่มต้นไม้แล้ว แต่ยังบันทึกไม่สำเร็จ"
		_:
			_feedback_label.text = "สถานะการปลูกไม่ระบุ"


## Pure query for testing: returns child PlantingPicker instance.
func get_planting_picker() -> PlantingPicker:
	_resolve_nodes()
	return _planting_picker


## Pure query for testing: returns planting trigger Button instance.
func get_plant_button() -> Button:
	_resolve_nodes()
	return _plant_button


## Pure query for testing: returns true if planting interaction is currently enabled.
func is_planting_enabled() -> bool:
	_resolve_nodes()
	return not _is_blocked and _session != null and _plant_button != null and not _plant_button.disabled and _planting_picker != null and _planting_picker.is_picker_enabled()


## Pure query for testing: returns current feedback text.
func get_feedback_text() -> String:
	_resolve_nodes()
	return _feedback_label.text if _feedback_label != null else ""


## Pure query for testing: returns true if feedback area is visible.
func is_feedback_visible() -> bool:
	_resolve_nodes()
	return _feedback_area != null and _feedback_area.visible


## Pure query for testing: returns last received PlantingCheckpointResult.
func get_last_checkpoint_result() -> PlantingCheckpointResult:
	return _last_checkpoint_result


func _on_harvest_button_pressed() -> void:
	if _is_blocked or _session == null or _selected_runtime_instance_id.is_empty():
		return
	if _harvest_button != null and _harvest_button.disabled:
		return
	harvest_requested.emit(_selected_runtime_instance_id)


## Displays user feedback from a HarvestCheckpointResult.
func show_harvest_result(result: HarvestCheckpointResult) -> void:
	_last_harvest_checkpoint_result = result
	_resolve_nodes()
	if _feedback_area == null or _feedback_label == null or result == null:
		return

	_feedback_area.visible = true
	match result.get_status():
		HarvestCheckpointResult.Status.NOT_READY:
			_feedback_label.text = "ระบบยังไม่พร้อมสำหรับการเก็บเกี่ยว"
		HarvestCheckpointResult.Status.HARVEST_REJECTED:
			var reason_str: String = ""
			var harvest_res: PlantHarvestResult = result.get_harvest_result()
			if harvest_res != null:
				match harvest_res.get_status():
					PlantHarvestResult.INVALID_INPUT:
						reason_str = "INVALID_INPUT"
					PlantHarvestResult.PLANT_NOT_FOUND:
						reason_str = "PLANT_NOT_FOUND"
					PlantHarvestResult.UNKNOWN_DEFINITION_ID:
						reason_str = "UNKNOWN_DEFINITION_ID"
					PlantHarvestResult.PLANT_NOT_MATURE:
						reason_str = "PLANT_NOT_MATURE"
					PlantHarvestResult.INVALID_REWARD:
						reason_str = "INVALID_REWARD"
					PlantHarvestResult.CURRENCY_GRANT_REJECTED:
						reason_str = "CURRENCY_GRANT_REJECTED"
					PlantHarvestResult.STATE_UPDATE_REJECTED:
						reason_str = "STATE_UPDATE_REJECTED"
					_:
						reason_str = "UNKNOWN"
			if not reason_str.is_empty():
				_feedback_label.text = "ไม่สามารถเก็บเกี่ยวได้ (%s)" % reason_str
			else:
				_feedback_label.text = "ไม่สามารถเก็บเกี่ยวได้"
		HarvestCheckpointResult.Status.HARVESTED_SAVED:
			_feedback_label.text = (
				"เก็บเกี่ยวสำเร็จ (+%d เหรียญ) และบันทึกเรียบร้อยแล้ว"
				% result.get_reward_granted()
			)
		HarvestCheckpointResult.Status.HARVESTED_SAVE_FAILED:
			_feedback_label.text = (
				"เก็บเกี่ยวสำเร็จ (+%d เหรียญ) แต่ยังบันทึกไม่สำเร็จ"
				% result.get_reward_granted()
			)
		_:
			_feedback_label.text = "สถานะการเก็บเกี่ยวไม่ระบุ"


## Pure query for testing: returns currency HUD Label instance.
func get_currency_label() -> Label:
	_resolve_nodes()
	return _currency_label


## Pure query for testing: returns displayed currency HUD text.
func get_currency_text() -> String:
	_resolve_nodes()
	return _currency_label.text if _currency_label != null else ""


## Pure query for testing: returns text displayed in detail reward label.
func get_detail_reward_text() -> String:
	_resolve_nodes()
	return _detail_reward_label.text if _detail_reward_label != null else ""


## Pure query for testing: returns Harvest button instance.
func get_harvest_button() -> Button:
	_resolve_nodes()
	return _harvest_button


## Pure query for testing: returns true if Harvest button is currently enabled.
func is_harvest_button_enabled() -> bool:
	_resolve_nodes()
	return not _is_blocked and _session != null and _harvest_button != null and not _harvest_button.disabled


## Pure query for testing: returns last received HarvestCheckpointResult.
func get_last_harvest_checkpoint_result() -> HarvestCheckpointResult:
	return _last_harvest_checkpoint_result


func _on_observe_visitor_button_pressed() -> void:
	if _is_blocked or _session == null:
		return
	if _observe_visitor_button != null and _observe_visitor_button.disabled:
		return
	visitor_observation_requested.emit()


## Displays user feedback and active visitor state from a VisitorSelectionResult.
func show_visitor_result(result: VisitorSelectionResult) -> void:
	_last_visitor_selection_result = result
	_resolve_nodes()
	if result == null:
		return

	if _feedback_area != null and _feedback_label != null:
		_feedback_area.visible = true
		match result.get_status():
			VisitorSelectionResult.Status.SELECTED:
				var vid: String = result.get_selected_visitor_id()
				_current_visitor_id = vid
				var vname: String = PROVISIONAL_VISITOR_DISPLAY_NAMES.get(vid, vid)
				_feedback_label.text = "พบผู้มาเยือนในสวน: %s (%s)" % [vname, vid]
				if _visitor_status_label != null:
					_visitor_status_label.text = "ผู้มาเยือนในสวน: %s (%s)" % [vname, vid]
			VisitorSelectionResult.Status.NO_ELIGIBLE_VISITORS:
				_current_visitor_id = ""
				_feedback_label.text = "ยังไม่มีผู้มาเยือนที่ตรงกับสภาพแวดล้อมสวนในขณะนี้"
			VisitorSelectionResult.Status.INVALID_INPUT, VisitorSelectionResult.Status.SELECTION_FAILED:
				_feedback_label.text = "ระบบยังไม่พร้อมสำหรับการสำรวจผู้มาเยือน"
			_:
				_feedback_label.text = "สถานะผู้มาเยือนไม่ระบุ"


## Pure query for testing: returns environment summary text.
func get_environment_text() -> String:
	_resolve_nodes()
	return _environment_label.text if _environment_label != null else ""


## Pure query for testing: returns visitor status text.
func get_visitor_status_text() -> String:
	_resolve_nodes()
	return _visitor_status_label.text if _visitor_status_label != null else ""


## Pure query for testing: returns ObserveVisitorButton instance.
func get_observe_visitor_button() -> Button:
	_resolve_nodes()
	return _observe_visitor_button


## Pure query for testing: returns true if ObserveVisitorButton is currently enabled.
func is_observe_visitor_button_enabled() -> bool:
	_resolve_nodes()
	return not _is_blocked and _session != null and _observe_visitor_button != null and not _observe_visitor_button.disabled


## Pure query for testing: returns current active ephemeral visitor ID, or empty string.
func get_current_visitor_id() -> String:
	return _current_visitor_id


## Pure query for testing: returns eligible visitor IDs from last refresh.
func get_eligible_visitor_ids() -> Array[String]:
	return _eligible_visitor_ids.duplicate()


## Pure query for testing: returns last derived GardenSnapshot.
func get_last_garden_snapshot() -> GardenSnapshot:
	return _last_snapshot


## Pure query for testing: returns last received VisitorSelectionResult.
func get_last_visitor_selection_result() -> VisitorSelectionResult:
	return _last_visitor_selection_result


## Displays user feedback, active visitor state, and journal discovery status from a VisitorObservationCheckpointResult.
func show_visitor_observation_result(result: VisitorObservationCheckpointResult) -> void:
	_last_visitor_observation_checkpoint_result = result
	_resolve_nodes()
	if result == null:
		return

	_last_visitor_selection_result = result.get_selection_result()
	if _feedback_area != null and _feedback_label != null:
		_feedback_area.visible = true
		match result.get_status():
			VisitorObservationCheckpointResult.Status.OBSERVED_SAVED:
				var vid: String = result.get_selected_visitor_id()
				_current_visitor_id = vid
				var vname: String = PROVISIONAL_VISITOR_DISPLAY_NAMES.get(vid, vid)
				if result.is_first_discovery():
					_feedback_label.text = (
						"พบผู้มาเยือนในสวน: %s (%s) — บันทึกการค้นพบใหม่ลงสมุดบ้านสวนแล้ว"
						% [vname, vid]
					)
				else:
					_feedback_label.text = (
						"พบผู้มาเยือนในสวน: %s (%s) — บันทึกลงสมุดบ้านสวนแล้ว"
						% [vname, vid]
					)
				if _visitor_status_label != null:
					_visitor_status_label.text = "ผู้มาเยือนในสวน: %s (%s)" % [vname, vid]
			VisitorObservationCheckpointResult.Status.OBSERVED_SAVE_FAILED:
				var vid_fail: String = result.get_selected_visitor_id()
				_current_visitor_id = vid_fail
				var vname_fail: String = PROVISIONAL_VISITOR_DISPLAY_NAMES.get(vid_fail, vid_fail)
				_feedback_label.text = (
					"พบผู้มาเยือนในสวน: %s (%s) แต่ยังบันทึกไม่สำเร็จ"
					% [vname_fail, vid_fail]
				)
				if _visitor_status_label != null:
					_visitor_status_label.text = "ผู้มาเยือนในสวน: %s (%s)" % [vname_fail, vid_fail]
			VisitorObservationCheckpointResult.Status.NO_ELIGIBLE_VISITORS:
				_current_visitor_id = ""
				_feedback_label.text = "ยังไม่มีผู้มาเยือนที่ตรงกับสภาพแวดล้อมสวนในขณะนี้"
			VisitorObservationCheckpointResult.Status.NOT_READY, VisitorObservationCheckpointResult.Status.OBSERVATION_REJECTED:
				_feedback_label.text = "ระบบยังไม่พร้อมสำหรับการสำรวจผู้มาเยือน"
			_:
				_feedback_label.text = "สถานะผู้มาเยือนไม่ระบุ"


## Opens the journal modal panel.
func open_journal_panel() -> void:
	if _is_blocked or _session == null:
		return
	_resolve_nodes()
	if _journal_panel != null:
		_journal_panel.open_journal()


## Closes the journal modal panel.
func close_journal_panel() -> void:
	_resolve_nodes()
	if _journal_panel != null:
		_journal_panel.close_journal()


## Pure query for testing: returns child JournalPanel instance.
func get_journal_panel() -> JournalPanel:
	_resolve_nodes()
	return _journal_panel


## Pure query for testing: returns JournalButton instance.
func get_journal_button() -> Button:
	_resolve_nodes()
	return _journal_button


## Pure query for testing: returns true if JournalButton is currently enabled.
func is_journal_button_enabled() -> bool:
	_resolve_nodes()
	return not _is_blocked and _session != null and _journal_button != null and not _journal_button.disabled


## Pure query for testing: returns journal summary text in HUD.
func get_journal_status_text() -> String:
	_resolve_nodes()
	return _journal_status_label.text if _journal_status_label != null else ""


## Pure query for testing: returns last received VisitorObservationCheckpointResult.
func get_last_visitor_observation_checkpoint_result() -> VisitorObservationCheckpointResult:
	return _last_visitor_observation_checkpoint_result


func _on_picker_decoration_purchase_requested(definition_id: String) -> void:
	decoration_purchase_requested.emit(definition_id)


## Opens the decoration picker modal.
func open_decoration_picker() -> void:
	if _is_blocked or _session == null:
		return
	_resolve_nodes()
	if _decoration_picker != null:
		_decoration_picker.open_picker()


## Closes the decoration picker modal.
func close_decoration_picker() -> void:
	_resolve_nodes()
	if _decoration_picker != null:
		_decoration_picker.close_picker()


## Displays user feedback from a DecorationPurchaseCheckpointResult.
func show_decoration_purchase_result(result: DecorationPurchaseCheckpointResult) -> void:
	_last_decoration_purchase_checkpoint_result = result
	_resolve_nodes()
	if _feedback_area == null or _feedback_label == null or result == null:
		return

	_feedback_area.visible = true
	match result.get_status():
		DecorationPurchaseCheckpointResult.Status.NOT_READY:
			_feedback_label.text = "ระบบยังไม่พร้อมสำหรับการซื้อของตกแต่ง"
		DecorationPurchaseCheckpointResult.Status.PURCHASE_REJECTED:
			var reason_str: String = ""
			var purchase_res: DecorationPurchaseResult = result.get_purchase_result()
			if purchase_res != null:
				match purchase_res.get_status():
					DecorationPurchaseResult.INSUFFICIENT_CURRENCY:
						_feedback_label.text = "เหรียญไม่เพียงพอสำหรับการซื้อของตกแต่ง (INSUFFICIENT_CURRENCY)"
						return
					DecorationPurchaseResult.INVALID_INPUT:
						reason_str = "INVALID_INPUT"
					DecorationPurchaseResult.UNKNOWN_DEFINITION_ID:
						reason_str = "UNKNOWN_DEFINITION_ID"
					DecorationPurchaseResult.INVALID_PRICE:
						reason_str = "INVALID_PRICE"
					DecorationPurchaseResult.DUPLICATE_INSTANCE_ID:
						reason_str = "DUPLICATE_INSTANCE_ID"
					DecorationPurchaseResult.ID_GENERATION_FAILED:
						reason_str = "ID_GENERATION_FAILED"
					DecorationPurchaseResult.CURRENCY_SPEND_REJECTED:
						reason_str = "CURRENCY_SPEND_REJECTED"
					DecorationPurchaseResult.INSERTION_REJECTED:
						reason_str = "INSERTION_REJECTED"
					_:
						reason_str = "UNKNOWN"
			if not reason_str.is_empty():
				_feedback_label.text = "ไม่สามารถซื้อของตกแต่งได้ (%s)" % reason_str
			else:
				_feedback_label.text = "ไม่สามารถซื้อของตกแต่งได้"
		DecorationPurchaseCheckpointResult.Status.PURCHASED_SAVED:
			_feedback_label.text = (
				"ซื้อและวางของตกแต่งสำเร็จ (-%d เหรียญ) และบันทึกเรียบร้อยแล้ว"
				% result.get_price_spent()
			)
		DecorationPurchaseCheckpointResult.Status.PURCHASED_SAVE_FAILED:
			_feedback_label.text = (
				"ซื้อและวางของตกแต่งสำเร็จ (-%d เหรียญ) แต่ยังบันทึกไม่สำเร็จ"
				% result.get_price_spent()
			)
		_:
			_feedback_label.text = "สถานะการซื้อของตกแต่งไม่ระบุ"


## Pure query for testing: returns child DecorationPicker instance.
func get_decoration_picker() -> DecorationPicker:
	_resolve_nodes()
	return _decoration_picker


## Pure query for testing: returns DecorateButton instance.
func get_decorate_button() -> Button:
	_resolve_nodes()
	return _decorate_button


## Pure query for testing: returns true if decoration interaction is currently enabled.
func is_decorating_enabled() -> bool:
	_resolve_nodes()
	return (
		not _is_blocked
		and _session != null
		and _decorate_button != null
		and not _decorate_button.disabled
		and _decoration_picker != null
		and _decoration_picker.is_picker_enabled()
	)


## Pure query for testing: returns decoration status text in HUD.
func get_decoration_status_text() -> String:
	_resolve_nodes()
	return _decoration_status_label.text if _decoration_status_label != null else ""


## Pure query for testing: returns count of placed decorations in the latest snapshot.
func get_displayed_decoration_count() -> int:
	return _last_snapshot.get_total_decoration_count() if _last_snapshot != null else 0


## Pure query for testing: returns last received DecorationPurchaseCheckpointResult.
func get_last_decoration_purchase_checkpoint_result() -> DecorationPurchaseCheckpointResult:
	return _last_decoration_purchase_checkpoint_result


static func _compute_atmosphere_background_color(time_period: String, weather_state: String) -> Color:
	var base_color: Color = TIME_PERIOD_BASE_COLORS.get(time_period, DEFAULT_BACKGROUND_COLOR)
	match weather_state:
		GardenWeather.CLOUDY:
			return base_color.lerp(CLOUDY_TINT_COLOR, 0.25)
		GardenWeather.RAIN:
			return base_color.lerp(RAIN_TINT_COLOR, 0.35)
		_:
			return base_color


## Pure query for testing: returns atmosphere HUD summary text.
func get_atmosphere_text() -> String:
	_resolve_nodes()
	return _atmosphere_label.text if _atmosphere_label != null else ""


## Pure query for testing: returns canonical time period from the latest snapshot.
func get_current_time_period() -> String:
	return _last_snapshot.get_time_period() if _last_snapshot != null else ""


## Pure query for testing: returns canonical weather state from the latest snapshot.
func get_current_weather_state() -> String:
	return _last_snapshot.get_weather_state() if _last_snapshot != null else ""


## Pure query for testing: returns eligible ambient/special event IDs from the latest refresh.
func get_eligible_event_ids() -> Array[String]:
	return _eligible_event_ids.duplicate()


## Pure query for testing: returns current background ColorRect color.
func get_background_color() -> Color:
	_resolve_nodes()
	return _background_rect.color if _background_rect != null else DEFAULT_BACKGROUND_COLOR


## Pure query for testing: returns progression HUD Label node.
func get_progression_label() -> Label:
	_resolve_nodes()
	return _progression_label


## Pure query for testing: returns progression HUD summary text.
func get_progression_text() -> String:
	_resolve_nodes()
	return _progression_label.text if _progression_label != null else ""


## Pure query for testing: returns canonical progression stage ID from the latest refresh.
func get_current_progression_stage_id() -> String:
	return _last_progression_summary.get_stage_id() if _last_progression_summary != null else ""


## Pure query for testing: returns establishment score from the latest refresh.
func get_current_establishment_score() -> int:
	return _last_progression_summary.get_establishment_score() if _last_progression_summary != null else 0


## Pure query for testing: returns canonical next progression stage ID from the latest refresh, or "" if at max stage.
func get_next_progression_stage_id() -> String:
	return _last_progression_summary.get_next_stage_id() if _last_progression_summary != null else ""


## Pure query for testing: returns remaining points to reach the next progression stage from the latest refresh, or 0 if at max stage.
func get_points_to_next_progression_stage() -> int:
	return _last_progression_summary.get_points_to_next_stage() if _last_progression_summary != null else 0


## Pure query for testing: returns canonical gentle guidance ID from the latest refresh.
func get_current_guidance_id() -> String:
	return _last_progression_summary.get_guidance_id() if _last_progression_summary != null else ""


## Pure query for testing: returns the last derived GardenProgressionSummary.
func get_last_progression_summary() -> GardenProgressionSummary:
	return _last_progression_summary


## Displays calm, non-intrusive feedback summarizing away/offline changes from a GardenReturnSummary.
func show_return_summary(summary: GardenReturnSummary) -> void:
	_last_return_summary = summary
	_resolve_nodes()
	if _feedback_area == null or _feedback_label == null or summary == null:
		return

	if not summary.has_meaningful_changes():
		return

	_feedback_area.visible = true
	if summary.has_plant_growth_changes():
		var grown_count: int = summary.get_advanced_plant_count()
		var newly_mature_count: int = summary.get_newly_matured_plant_count()
		if newly_mature_count > 0:
			_feedback_label.text = (
				"ต้นไม้ในสวนเติบโตขึ้นระหว่างที่คุณไม่อยู่ (เติบโต %d ต้น, พร้อมเก็บเกี่ยว %d ต้น)"
				% [grown_count, summary.get_ready_to_harvest_count()]
			)
		else:
			_feedback_label.text = (
				"ต้นไม้ในสวนเติบโตขึ้นระหว่างที่คุณไม่อยู่ (%d ต้น)"
				% grown_count
			)
	else:
		var time_name: String = PROVISIONAL_TIME_PERIOD_DISPLAY_NAMES.get(
			summary.get_current_time_period(),
			summary.get_current_time_period()
		)
		var weather_name: String = PROVISIONAL_WEATHER_DISPLAY_NAMES.get(
			summary.get_current_weather_state(),
			summary.get_current_weather_state()
		)
		_feedback_label.text = (
			"บรรยากาศในสวนเปลี่ยนไประหว่างที่คุณไม่อยู่ (%s, %s)"
			% [time_name, weather_name]
		)


## Pure query for testing: returns the last derived GardenReturnSummary.
func get_last_return_summary() -> GardenReturnSummary:
	return _last_return_summary


## Pure query for testing: returns the UTC seconds timestamp from the last refresh.
func get_last_refresh_utc_seconds() -> int:
	return _last_refresh_utc_seconds


## Pure query for testing: returns true if at least one valid refresh timestamp has been recorded.
func has_refresh_timestamp() -> bool:
	return _has_refresh_timestamp


func _on_observe_event_button_pressed() -> void:
	if _is_blocked or _session == null:
		return
	if _observe_event_button != null and _observe_event_button.disabled:
		return
	event_observation_requested.emit()


## Displays calm Thai user feedback and ephemeral active event state from an EventSelectionResult.
func show_event_result(result: EventSelectionResult) -> void:
	_last_event_selection_result = result
	_resolve_nodes()
	if result == null:
		return

	if _feedback_area != null and _feedback_label != null:
		_feedback_area.visible = true
		match result.get_status():
			EventSelectionResult.Status.SELECTED:
				var eid: String = result.get_selected_event_id()
				_current_event_id = eid
				var ename: String = PROVISIONAL_EVENT_DISPLAY_NAMES.get(eid, eid)
				var edesc: String = PROVISIONAL_EVENT_DESCRIPTIONS.get(eid, "")
				if not edesc.is_empty():
					_feedback_label.text = "ชมเหตุการณ์ในสวน: %s (%s) — %s" % [ename, eid, edesc]
				else:
					_feedback_label.text = "ชมเหตุการณ์ในสวน: %s (%s)" % [ename, eid]
			EventSelectionResult.Status.NO_ELIGIBLE_EVENTS:
				_current_event_id = ""
				_feedback_label.text = "ยังไม่มีเหตุการณ์พิเศษที่เกิดขึ้นในสวนขณะนี้"
			EventSelectionResult.Status.INVALID_INPUT, EventSelectionResult.Status.SELECTION_FAILED:
				_feedback_label.text = "ระบบยังไม่พร้อมสำหรับการชมเหตุการณ์ในสวน"
			_:
				_feedback_label.text = "สถานะเหตุการณ์ในสวนไม่ระบุ"


## Pure query for testing: returns ObserveEventButton instance.
func get_observe_event_button() -> Button:
	_resolve_nodes()
	return _observe_event_button


## Pure query for testing: returns true if ObserveEventButton is currently enabled.
func is_observe_event_button_enabled() -> bool:
	_resolve_nodes()
	return (
		not _is_blocked
		and _session != null
		and _observe_event_button != null
		and not _observe_event_button.disabled
	)


## Pure query for testing: returns current active ephemeral event ID, or empty string.
func get_current_event_id() -> String:
	return _current_event_id


## Pure query for testing: returns last received EventSelectionResult.
func get_last_event_selection_result() -> EventSelectionResult:
	return _last_event_selection_result


## Pure query for testing: returns remaining seconds until the selected plant advances to its next stage, or -1 if none selected.
func get_selected_plant_seconds_until_next_stage() -> int:
	return _selected_plant_seconds_until_next_stage


## Pure query for testing: returns remaining seconds until the selected plant reaches MATURE, or -1 if none selected.
func get_selected_plant_seconds_until_mature() -> int:
	return _selected_plant_seconds_until_mature


## Pure query for testing: returns canonical next time-of-day period from the latest refresh.
func get_next_time_period() -> String:
	return _next_time_period


## Pure query for testing: returns remaining seconds until the next time-of-day period transition from the latest refresh.
func get_seconds_until_next_time_period() -> int:
	return _seconds_until_next_time_period


## Pure query for testing: returns canonical next weather state from the latest refresh.
func get_next_weather_state() -> String:
	return _next_weather_state


## Pure query for testing: returns remaining seconds until the next 2-hour weather window transition from the latest refresh.
func get_seconds_until_next_weather_state() -> int:
	return _seconds_until_next_weather_state


## Pure query for testing: returns environmental traits for the currently selected plant, or empty array if none selected.
func get_selected_plant_traits() -> Array[String]:
	return _selected_plant_traits.duplicate()


## Pure query for testing: returns the count of mature plants ready to harvest in the latest snapshot (0 if blocked).
func get_ready_to_harvest_plant_count() -> int:
	if _is_blocked or _last_snapshot == null:
		return 0
	return _last_snapshot.get_mature_plant_count()


## Pure query for testing: returns the selected plant's definition ID, or "" if no plant is selected or startup is blocked.
func get_selected_plant_definition_id() -> String:
	return _selected_plant_definition_id if not _is_blocked else ""


## Pure query for testing: returns the selected plant's derived PlantGrowth.Stage, or PlantGrowth.Stage.INVALID if none selected or blocked.
func get_selected_plant_stage() -> PlantGrowth.Stage:
	return _selected_plant_stage if not _is_blocked else PlantGrowth.Stage.INVALID


## Pure query for testing: returns deterministic runtime_instance_ids of all rendered PlantView cards ready to harvest.
func get_ready_to_harvest_plant_ids() -> Array[String]:
	if _is_blocked:
		return []
	var result: Array[String] = []
	for pv: PlantView in get_plant_views():
		if pv != null and pv.is_ready_to_harvest():
			result.append(pv.get_runtime_instance_id())
	return result


## Pure query for testing: returns the sum of harvest_reward across all rendered PlantView cards currently ready to harvest (0 if blocked or none ready).
func get_total_pending_harvest_reward() -> int:
	if _is_blocked:
		return 0
	var total: int = 0
	for pv: PlantView in get_plant_views():
		if pv != null and pv.is_ready_to_harvest():
			total += pv.get_harvest_reward()
	return total


## Pure query for testing: returns the selected plant's harvest reward, or 0 if none selected or blocked.
func get_selected_plant_harvest_reward() -> int:
	return _selected_plant_harvest_reward if not _is_blocked else 0


## Pure query for testing: returns the selected plant's planted_at UTC timestamp, or -1 if none selected or blocked.
func get_selected_plant_planted_at() -> int:
	return _selected_plant_planted_at if not _is_blocked else -1


## Pure query for testing: returns text displayed in detail instance ID label.
func get_detail_id_text() -> String:
	_resolve_nodes()
	return _detail_id_label.text if _detail_id_label != null else ""


## Pure query for testing: returns text displayed in detail planted-at timestamp label.
func get_detail_planted_at_text() -> String:
	_resolve_nodes()
	return _detail_planted_at_label.text if _detail_planted_at_label != null else ""


## Pure query for testing: returns deterministic runtime_instance_ids of all rendered PlantView cards still growing (PLANTED, SPROUT, or GROWING).
func get_growing_plant_ids() -> Array[String]:
	if _is_blocked:
		return []
	var result: Array[String] = []
	for pv: PlantView in get_plant_views():
		if pv != null:
			var st: PlantGrowth.Stage = pv.get_stage()
			if st == PlantGrowth.Stage.PLANTED or st == PlantGrowth.Stage.SPROUT or st == PlantGrowth.Stage.GROWING:
				result.append(pv.get_runtime_instance_id())
	return result


## Pure query for testing: returns the count of rendered PlantView cards still growing (PLANTED, SPROUT, or GROWING).
func get_growing_plant_count() -> int:
	return get_growing_plant_ids().size()


## Pure query for testing: returns the minimum remaining seconds until mature across all growing PlantView cards, or -1 if none growing or blocked.
func get_minimum_seconds_until_next_harvest() -> int:
	if _is_blocked:
		return -1
	var min_sec: int = -1
	for pv: PlantView in get_plant_views():
		if pv != null:
			var st: PlantGrowth.Stage = pv.get_stage()
			var sec: int = pv.get_seconds_until_mature()
			if (st == PlantGrowth.Stage.PLANTED or st == PlantGrowth.Stage.SPROUT or st == PlantGrowth.Stage.GROWING) and sec > 0:
				if min_sec < 0 or sec < min_sec:
					min_sec = sec
	return min_sec


## Pure query for testing: returns active environmental trait IDs in the latest snapshot, or [] if blocked.
func get_active_environmental_traits() -> Array[String]:
	if _is_blocked or _last_snapshot == null:
		return []
	return _last_snapshot.get_active_traits()


## Pure query for testing: returns count for [param trait_id] in the latest snapshot, or 0 if blocked.
func get_environmental_trait_count(trait_id: String) -> int:
	if _is_blocked or _last_snapshot == null:
		return 0
	return _last_snapshot.get_trait_count(trait_id)


## Pure query for testing: returns deterministic definition IDs of placed decorations in the latest snapshot, or [] if blocked.
func get_present_decoration_definition_ids() -> Array[String]:
	if _is_blocked or _last_snapshot == null:
		return []
	return _last_snapshot.get_present_decoration_definition_ids()


## Pure query for testing: returns placed count for [param definition_id] in the latest snapshot, or 0 if blocked.
func get_placed_decoration_count_for_id(definition_id: String) -> int:
	if _is_blocked or _last_snapshot == null:
		return 0
	return _last_snapshot.get_decoration_count_for_definition(definition_id)


## Pure query for testing: returns the minimum remaining seconds until the next stage across all growing PlantView cards, or -1 if none growing or blocked.
func get_minimum_seconds_until_next_stage_transition() -> int:
	if _is_blocked:
		return -1
	var min_sec: int = -1
	for pv: PlantView in get_plant_views():
		if pv != null and pv.is_growing_stage():
			var sec: int = pv.get_seconds_until_next_stage()
			if sec > 0 and (min_sec < 0 or sec < min_sec):
				min_sec = sec
	return min_sec


## Pure query for testing: returns deterministic definition IDs of planted plants in the latest snapshot, or [] if blocked.
func get_present_plant_definition_ids() -> Array[String]:
	if _is_blocked or _last_snapshot == null:
		return []
	return _last_snapshot.get_present_plant_definition_ids()


## Pure query for testing: returns planted count for [param definition_id] in the latest snapshot, or 0 if blocked.
func get_planted_count_for_id(definition_id: String) -> int:
	if _is_blocked or _last_snapshot == null:
		return 0
	return _last_snapshot.get_plant_count_for_definition(definition_id)


## Pure query for testing: returns deterministic runtime_instance_ids of rendered PlantView cards matching [param stage].
func get_plant_ids_for_stage(stage: PlantGrowth.Stage) -> Array[String]:
	if _is_blocked:
		return []
	var result: Array[String] = []
	for pv: PlantView in get_plant_views():
		if pv != null and pv.get_stage() == stage:
			result.append(pv.get_runtime_instance_id())
	return result


## Pure query for testing: returns count of rendered PlantView cards matching [param stage].
func get_plant_count_for_stage(stage: PlantGrowth.Stage) -> int:
	return get_plant_ids_for_stage(stage).size()


## Pure query for testing: returns deterministic runtime_instance_ids of rendered PlantView cards matching [param definition_id].
func get_plant_ids_for_definition_id(definition_id: String) -> Array[String]:
	if _is_blocked or definition_id.is_empty():
		return []
	var result: Array[String] = []
	for pv: PlantView in get_plant_views():
		if pv != null and pv.get_definition_id() == definition_id:
			result.append(pv.get_runtime_instance_id())
	return result


## Pure query for testing: returns count of distinct plant definitions currently planted in the latest snapshot (0 if blocked).
func get_distinct_planted_species_count() -> int:
	return get_present_plant_definition_ids().size()


## Pure query for testing: returns count of distinct decoration definitions currently placed in the latest snapshot (0 if blocked).
func get_distinct_placed_decoration_species_count() -> int:
	return get_present_decoration_definition_ids().size()


## Pure query for testing: returns count of discovered entries in the child JournalPanel (0 if blocked).
func get_discovered_entry_count_in_garden() -> int:
	if _is_blocked:
		return 0
	_resolve_nodes()
	return _journal_panel.get_discovered_entry_count() if _journal_panel != null else 0


## Pure query for testing: returns true if the garden has reached its maximum progression stage ("happy_garden_home") and is not blocked.
func is_at_max_progression_stage() -> bool:
	return not _is_blocked and _last_progression_summary != null and _last_progression_summary.is_max_stage()


## Pure query for testing: returns deterministic runtime_instance_ids of rendered PlantView cards exposing [param trait_id].
func get_plant_ids_with_environmental_trait(trait_id: String) -> Array[String]:
	if _is_blocked or trait_id.is_empty():
		return []
	var result: Array[String] = []
	for pv: PlantView in get_plant_views():
		if pv != null and pv.has_environmental_trait(trait_id):
			result.append(pv.get_runtime_instance_id())
	return result


## Pure query for testing: returns count of rendered PlantView cards exposing [param trait_id].
func get_plant_count_with_environmental_trait(trait_id: String) -> int:
	return get_plant_ids_with_environmental_trait(trait_id).size()


## Pure query for testing: returns count of undiscovered entries in the child JournalPanel (0 if blocked).
func get_undiscovered_entry_count_in_garden() -> int:
	if _is_blocked:
		return 0
	_resolve_nodes()
	return _journal_panel.get_undiscovered_entry_count() if _journal_panel != null else 0


## Pure query for testing: returns true if all catalog entries in the child JournalPanel have been discovered (false if blocked).
func is_all_journal_entries_discovered_in_garden() -> bool:
	if _is_blocked:
		return false
	_resolve_nodes()
	return _journal_panel != null and _journal_panel.is_all_entries_discovered_in_journal()


## Pure query for testing: returns count of eligible visitors from the latest refresh (0 if blocked).
func get_eligible_visitor_count() -> int:
	return _eligible_visitor_ids.size() if not _is_blocked else 0


## Pure query for testing: returns count of eligible ambient/special events from the latest refresh (0 if blocked).
func get_eligible_event_count() -> int:
	return _eligible_event_ids.size() if not _is_blocked else 0


## Pure query for testing: returns true if a plant is currently selected and startup is not blocked.
func has_selected_plant() -> bool:
	return not _is_blocked and not _selected_runtime_instance_id.is_empty()


## Pure query for testing: returns true if a plant is currently selected, at MATURE stage, has a positive harvest reward, and startup is not blocked.
func is_selected_plant_ready_to_harvest() -> bool:
	return (
		not _is_blocked
		and not _selected_runtime_instance_id.is_empty()
		and _selected_plant_stage == PlantGrowth.Stage.MATURE
		and _selected_plant_harvest_reward > 0
	)


## Pure query for testing: returns true if [param trait_id] has a positive count in the latest snapshot (false if blocked).
func has_active_environmental_trait(trait_id: String) -> bool:
	return (
		not _is_blocked
		and not trait_id.is_empty()
		and _last_snapshot != null
		and _last_snapshot.get_trait_count(trait_id) > 0
	)


## Pure query for testing: returns count of distinct active environmental traits in the latest snapshot (0 if blocked).
func get_active_environmental_trait_count() -> int:
	return get_active_environmental_traits().size()


## Pure query for testing: returns true if [param definition_id] has at least one planted instance in the latest snapshot (false if blocked).
func is_plant_definition_present_in_garden(definition_id: String) -> bool:
	return (
		not _is_blocked
		and not definition_id.is_empty()
		and _last_snapshot != null
		and _last_snapshot.get_plant_count_for_definition(definition_id) > 0
	)


## Pure query for testing: returns true if [param definition_id] has at least one placed decoration instance in the latest snapshot (false if blocked).
func is_decoration_definition_present_in_garden(definition_id: String) -> bool:
	return (
		not _is_blocked
		and not definition_id.is_empty()
		and _last_snapshot != null
		and _last_snapshot.get_decoration_count_for_definition(definition_id) > 0
	)


## Pure query for testing: returns true if [param visitor_id] is currently eligible in the latest refresh (false if blocked).
func is_visitor_currently_eligible(visitor_id: String) -> bool:
	return not _is_blocked and not visitor_id.is_empty() and _eligible_visitor_ids.has(visitor_id)


## Pure query for testing: returns true if [param event_id] is currently eligible in the latest refresh (false if blocked).
func is_event_currently_eligible(event_id: String) -> bool:
	return not _is_blocked and not event_id.is_empty() and _eligible_event_ids.has(event_id)


## Pure query for testing: returns true if at least one plant is currently rendered in the garden and startup is not blocked.
func has_any_planted_plants_in_garden() -> bool:
	return not _is_blocked and get_displayed_plant_count() > 0


## Pure query for testing: returns true if at least one rendered plant is still growing and startup is not blocked.
func has_any_growing_plants_in_garden() -> bool:
	return not _is_blocked and get_growing_plant_count() > 0


## Pure query for testing: returns true if at least one plant in the latest snapshot is mature/ready to harvest and startup is not blocked.
func has_any_ready_to_harvest_plants_in_garden() -> bool:
	return not _is_blocked and get_ready_to_harvest_plant_count() > 0


## Pure query for testing: returns true if at least one decoration is placed in the latest snapshot and startup is not blocked.
func has_any_placed_decorations_in_garden() -> bool:
	return not _is_blocked and get_displayed_decoration_count() > 0


## Pure query for testing: returns true if at least one environmental trait is active in the latest snapshot and startup is not blocked.
func has_any_active_environmental_traits_in_garden() -> bool:
	return not _is_blocked and get_active_environmental_trait_count() > 0


## Pure query for testing: returns true if at least one visitor is currently eligible in the latest refresh and startup is not blocked.
func has_any_eligible_visitors_in_garden() -> bool:
	return not _is_blocked and get_eligible_visitor_count() > 0


## Pure query for testing: returns true if at least one ambient/special event is currently eligible in the latest refresh and startup is not blocked.
func has_any_eligible_events_in_garden() -> bool:
	return not _is_blocked and get_eligible_event_count() > 0


## Pure query for testing: returns true if a plant is currently selected, startup is not blocked, and the selected plant exposes [param trait_id].
func has_selected_plant_environmental_trait(trait_id: String) -> bool:
	return (
		not _is_blocked
		and not _selected_runtime_instance_id.is_empty()
		and not trait_id.is_empty()
		and _selected_plant_traits.has(trait_id)
	)


## Pure query for testing: returns true if a plant is currently selected, startup is not blocked, and the selected plant is at an active growing stage (PLANTED, SPROUT, or GROWING).
func is_selected_plant_growing() -> bool:
	return (
		not _is_blocked
		and not _selected_runtime_instance_id.is_empty()
		and (
			_selected_plant_stage == PlantGrowth.Stage.PLANTED
			or _selected_plant_stage == PlantGrowth.Stage.SPROUT
			or _selected_plant_stage == PlantGrowth.Stage.GROWING
		)
	)


## Pure query for testing: returns count of environmental traits on the currently selected plant (0 if none selected or blocked).
func get_selected_plant_trait_count() -> int:
	if _is_blocked or _selected_runtime_instance_id.is_empty():
		return 0
	return _selected_plant_traits.size()


## Pure query for testing: returns true if a plant is currently selected, startup is not blocked, and the selected plant has at least one environmental trait.
func has_selected_plant_any_environmental_traits() -> bool:
	return get_selected_plant_trait_count() > 0


## Pure query for testing: returns true if at least one plant is rendered in the garden, startup is not blocked, and all rendered plants are ready to harvest.
func is_all_planted_plants_ready_to_harvest_in_garden() -> bool:
	var displayed: int = get_displayed_plant_count()
	return (
		not _is_blocked
		and displayed > 0
		and get_growing_plant_count() == 0
		and get_ready_to_harvest_plant_count() == displayed
	)


## Pure query for testing: returns true if at least one catalog entry in the child JournalPanel has been discovered (false if blocked).
func has_any_discovered_entries_in_garden() -> bool:
	return not _is_blocked and get_discovered_entry_count_in_garden() > 0


## Pure query for testing: returns true if at least one catalog entry in the child JournalPanel is still undiscovered (false if blocked).
func has_any_undiscovered_entries_in_garden() -> bool:
	return not _is_blocked and get_undiscovered_entry_count_in_garden() > 0


## Pure query for testing: returns true if a visitor has been observed and is currently active in the garden HUD (false if blocked).
func has_active_visitor_in_garden() -> bool:
	return not _is_blocked and not _current_visitor_id.is_empty()


## Pure query for testing: returns true if an ambient/special event has been observed and is currently active in the garden HUD (false if blocked).
func has_active_event_in_garden() -> bool:
	return not _is_blocked and not _current_event_id.is_empty()


## Pure query for testing: returns true if a GameSession is bound and startup is not blocked.
func has_bound_session() -> bool:
	return not _is_blocked and _session != null


## Pure query for testing: returns true if a ContentCatalog is bound and startup is not blocked.
func has_bound_catalog() -> bool:
	return not _is_blocked and _catalog != null


## Pure query for testing: returns true if a GameClock is bound and startup is not blocked.
func has_bound_clock() -> bool:
	return not _is_blocked and _game_clock != null


## Pure query for testing: returns true if a GardenSnapshot has been derived and startup is not blocked.
func has_last_garden_snapshot() -> bool:
	return not _is_blocked and _last_snapshot != null


## Pure query for testing: returns true if a GardenProgressionSummary has been derived and startup is not blocked.
func has_last_progression_summary() -> bool:
	return not _is_blocked and _last_progression_summary != null


## Pure query for testing: returns true if a GardenReturnSummary has been received and startup is not blocked.
func has_last_return_summary() -> bool:
	return not _is_blocked and _last_return_summary != null


## Pure query for testing: returns true if the child PlantingPicker modal is currently open and startup is not blocked.
func is_planting_picker_open_in_garden() -> bool:
	if _is_blocked:
		return false
	_resolve_nodes()
	return _planting_picker != null and _planting_picker.is_picker_open()


## Pure query for testing: returns true if the child DecorationPicker modal is currently open and startup is not blocked.
func is_decoration_picker_open_in_garden() -> bool:
	if _is_blocked:
		return false
	_resolve_nodes()
	return _decoration_picker != null and _decoration_picker.is_picker_open()


## Pure query for testing: returns true if the child JournalPanel modal is currently open and startup is not blocked.
func is_journal_open_in_garden() -> bool:
	if _is_blocked:
		return false
	_resolve_nodes()
	return _journal_panel != null and _journal_panel.is_journal_open()


## Pure query for testing: returns true if any child modal (PlantingPicker, DecorationPicker, or JournalPanel) is currently open and startup is not blocked.
func is_any_modal_open_in_garden() -> bool:
	return (
		is_planting_picker_open_in_garden()
		or is_decoration_picker_open_in_garden()
		or is_journal_open_in_garden()
	)


## Pure query for testing: returns true if a PlantingCheckpointResult has been received and startup is not blocked.
func has_last_planting_checkpoint_result() -> bool:
	return not _is_blocked and _last_checkpoint_result != null


## Pure query for testing: returns true if a HarvestCheckpointResult has been received and startup is not blocked.
func has_last_harvest_checkpoint_result() -> bool:
	return not _is_blocked and _last_harvest_checkpoint_result != null


## Pure query for testing: returns true if a VisitorSelectionResult has been received and startup is not blocked.
func has_last_visitor_selection_result() -> bool:
	return not _is_blocked and _last_visitor_selection_result != null


## Pure query for testing: returns true if a VisitorObservationCheckpointResult has been received and startup is not blocked.
func has_last_visitor_observation_checkpoint_result() -> bool:
	return not _is_blocked and _last_visitor_observation_checkpoint_result != null


## Pure query for testing: returns true if an EventSelectionResult has been received and startup is not blocked.
func has_last_event_selection_result() -> bool:
	return not _is_blocked and _last_event_selection_result != null


## Pure query for testing: returns true if a DecorationPurchaseCheckpointResult has been received and startup is not blocked.
func has_last_decoration_purchase_checkpoint_result() -> bool:
	return not _is_blocked and _last_decoration_purchase_checkpoint_result != null


## Pure query for testing: returns the localized Thai display name for the currently selected plant, or "" if none selected or blocked.
func get_selected_plant_display_name() -> String:
	if _is_blocked or _selected_runtime_instance_id.is_empty() or _selected_plant_definition_id.is_empty():
		return ""
	return PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.get(_selected_plant_definition_id, _selected_plant_definition_id)


## Pure query for testing: returns the localized Thai display name for the current active visitor in the garden HUD, or "" if none active or blocked.
func get_current_visitor_display_name() -> String:
	if _is_blocked or _current_visitor_id.is_empty():
		return ""
	return PROVISIONAL_VISITOR_DISPLAY_NAMES.get(_current_visitor_id, _current_visitor_id)


## Pure query for testing: returns the localized Thai display name for the current active ambient/special event in the garden HUD, or "" if none active or blocked.
func get_current_event_display_name() -> String:
	if _is_blocked or _current_event_id.is_empty():
		return ""
	return PROVISIONAL_EVENT_DISPLAY_NAMES.get(_current_event_id, _current_event_id)


## Pure query for testing: returns the localized Thai description for the current active ambient/special event in the garden HUD, or "" if none active or blocked.
func get_current_event_description() -> String:
	if _is_blocked or _current_event_id.is_empty():
		return ""
	return PROVISIONAL_EVENT_DESCRIPTIONS.get(_current_event_id, "")


## Pure query for testing: returns the localized Thai display name for the current time period from the latest snapshot, or "" if blocked/unavailable.
func get_current_time_period_display_name() -> String:
	var tp: String = get_current_time_period()
	if _is_blocked or tp.is_empty():
		return ""
	return PROVISIONAL_TIME_PERIOD_DISPLAY_NAMES.get(tp, tp)


## Pure query for testing: returns the localized Thai display name for the current weather state from the latest snapshot, or "" if blocked/unavailable.
func get_current_weather_display_name() -> String:
	var ws: String = get_current_weather_state()
	if _is_blocked or ws.is_empty():
		return ""
	return PROVISIONAL_WEATHER_DISPLAY_NAMES.get(ws, ws)


## Pure query for testing: returns the localized Thai display name for the next time period from the latest refresh, or "" if blocked/unavailable.
func get_next_time_period_display_name() -> String:
	if _is_blocked or _next_time_period.is_empty():
		return ""
	return PROVISIONAL_TIME_PERIOD_DISPLAY_NAMES.get(_next_time_period, _next_time_period)


## Pure query for testing: returns the localized Thai display name for the next weather state from the latest refresh, or "" if blocked/unavailable.
func get_next_weather_display_name() -> String:
	if _is_blocked or _next_weather_state.is_empty():
		return ""
	return PROVISIONAL_WEATHER_DISPLAY_NAMES.get(_next_weather_state, _next_weather_state)


## Pure query for testing: returns the localized Thai display name for the current progression stage from the latest refresh, or "" if blocked/unavailable.
func get_current_progression_stage_display_name() -> String:
	var st_id: String = get_current_progression_stage_id()
	if _is_blocked or st_id.is_empty():
		return ""
	return PROVISIONAL_PROGRESSION_STAGE_DISPLAY_NAMES.get(st_id, st_id)


## Pure query for testing: returns the localized Thai display name for the next progression stage from the latest refresh, or "" if at max stage or blocked/unavailable.
func get_next_progression_stage_display_name() -> String:
	var next_id: String = get_next_progression_stage_id()
	if _is_blocked or next_id.is_empty():
		return ""
	return PROVISIONAL_PROGRESSION_STAGE_DISPLAY_NAMES.get(next_id, next_id)


## Pure query for testing: returns the localized Thai display name for the current optional gentle guidance prompt from the latest refresh, or "" if blocked/unavailable.
func get_current_guidance_display_name() -> String:
	var gid: String = get_current_guidance_id()
	if _is_blocked or gid.is_empty():
		return ""
	return PROVISIONAL_GUIDANCE_DISPLAY_NAMES.get(gid, gid)


## Pure query for testing: returns true if a plant is currently selected, startup is not blocked, and the selected plant is at PLANTED stage.
func is_selected_plant_planted_stage() -> bool:
	return not _is_blocked and not _selected_runtime_instance_id.is_empty() and _selected_plant_stage == PlantGrowth.Stage.PLANTED


## Pure query for testing: returns true if a plant is currently selected, startup is not blocked, and the selected plant is at SPROUT stage.
func is_selected_plant_sprout_stage() -> bool:
	return not _is_blocked and not _selected_runtime_instance_id.is_empty() and _selected_plant_stage == PlantGrowth.Stage.SPROUT


## Pure query for testing: returns true if a plant is currently selected, startup is not blocked, and the selected plant is at GROWING stage.
func is_selected_plant_growing_phase_stage() -> bool:
	return not _is_blocked and not _selected_runtime_instance_id.is_empty() and _selected_plant_stage == PlantGrowth.Stage.GROWING


## Pure query for testing: returns true if a plant is currently selected, startup is not blocked, and the selected plant is at MATURE stage.
func is_selected_plant_mature_stage() -> bool:
	return not _is_blocked and not _selected_runtime_instance_id.is_empty() and _selected_plant_stage == PlantGrowth.Stage.MATURE


## Pure query for testing: returns localized Thai display name for [param trait_id], or "" if empty.
func get_trait_display_name_for_id(trait_id: String) -> String:
	if trait_id.is_empty():
		return ""
	return PROVISIONAL_TRAIT_DISPLAY_NAMES.get(trait_id, trait_id)


## Pure query for testing: returns localized Thai display name for [param visitor_id], or "" if empty.
func get_visitor_display_name_for_id(visitor_id: String) -> String:
	if visitor_id.is_empty():
		return ""
	return PROVISIONAL_VISITOR_DISPLAY_NAMES.get(visitor_id, visitor_id)


## Pure query for testing: returns localized Thai display name for [param event_id], or "" if empty.
func get_event_display_name_for_id(event_id: String) -> String:
	if event_id.is_empty():
		return ""
	return PROVISIONAL_EVENT_DISPLAY_NAMES.get(event_id, event_id)


## Pure query for testing: returns localized Thai description for [param event_id], or "" if empty/unknown.
func get_event_description_for_id(event_id: String) -> String:
	if event_id.is_empty():
		return ""
	return PROVISIONAL_EVENT_DESCRIPTIONS.get(event_id, "")


## Pure query for testing: returns localized Thai display name for [param time_period], or "" if empty.
func get_time_period_display_name_for_id(time_period: String) -> String:
	if time_period.is_empty():
		return ""
	return PROVISIONAL_TIME_PERIOD_DISPLAY_NAMES.get(time_period, time_period)


## Pure query for testing: returns localized Thai display name for [param weather_state], or "" if empty.
func get_weather_display_name_for_id(weather_state: String) -> String:
	if weather_state.is_empty():
		return ""
	return PROVISIONAL_WEATHER_DISPLAY_NAMES.get(weather_state, weather_state)


## Pure query for testing: returns localized Thai display name for [param stage_id], or "" if empty.
func get_progression_stage_display_name_for_id(stage_id: String) -> String:
	if stage_id.is_empty():
		return ""
	return PROVISIONAL_PROGRESSION_STAGE_DISPLAY_NAMES.get(stage_id, stage_id)


## Pure query for testing: returns localized Thai display name for [param guidance_id], or "" if empty.
func get_guidance_display_name_for_id(guidance_id: String) -> String:
	if guidance_id.is_empty():
		return ""
	return PROVISIONAL_GUIDANCE_DISPLAY_NAMES.get(guidance_id, guidance_id)


## Pure query for testing: returns localized Thai display names for all active environmental traits in the latest snapshot, or [] if blocked/empty.
func get_active_environmental_trait_display_names() -> Array[String]:
	if _is_blocked or _last_snapshot == null:
		return []
	var result: Array[String] = []
	for trait_id: String in _last_snapshot.get_active_traits():
		result.append(PROVISIONAL_TRAIT_DISPLAY_NAMES.get(trait_id, trait_id))
	return result


## Pure query for testing: returns localized Thai display names for environmental traits on the currently selected plant, or [] if none selected or blocked.
func get_selected_plant_trait_display_names() -> Array[String]:
	if _is_blocked or _selected_runtime_instance_id.is_empty():
		return []
	var result: Array[String] = []
	for trait_id: String in _selected_plant_traits:
		result.append(PROVISIONAL_TRAIT_DISPLAY_NAMES.get(trait_id, trait_id))
	return result


## Pure query for testing: returns localized Thai display names for eligible visitors from the latest refresh, or [] if blocked/empty.
func get_eligible_visitor_display_names() -> Array[String]:
	if _is_blocked:
		return []
	var result: Array[String] = []
	for vid: String in _eligible_visitor_ids:
		result.append(PROVISIONAL_VISITOR_DISPLAY_NAMES.get(vid, vid))
	return result


## Pure query for testing: returns localized Thai display names for eligible ambient/special events from the latest refresh, or [] if blocked/empty.
func get_eligible_event_display_names() -> Array[String]:
	if _is_blocked:
		return []
	var result: Array[String] = []
	for eid: String in _eligible_event_ids:
		result.append(PROVISIONAL_EVENT_DISPLAY_NAMES.get(eid, eid))
	return result


## Pure query for testing: returns localized Thai display names for distinct planted plant species in the latest snapshot, or [] if blocked/empty.
func get_present_plant_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_present_plant_definition_ids():
		result.append(PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.get(def_id, def_id))
	return result


## Pure query for testing: returns localized Thai display names for distinct placed decoration species in the latest snapshot, or [] if blocked/empty.
func get_present_decoration_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_present_decoration_definition_ids():
		result.append(DecorationPicker.PROVISIONAL_DECORATION_DISPLAY_NAMES.get(def_id, def_id))
	return result


## Pure query for testing: returns localized Thai display name for plant [param definition_id], or "" if empty.
func get_plant_display_name_for_id(definition_id: String) -> String:
	if definition_id.is_empty():
		return ""
	return PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.get(definition_id, definition_id)


## Pure query for testing: returns localized Thai display name for decoration [param definition_id], or "" if empty.
func get_decoration_display_name_for_id(definition_id: String) -> String:
	if definition_id.is_empty():
		return ""
	return DecorationPicker.PROVISIONAL_DECORATION_DISPLAY_NAMES.get(definition_id, definition_id)


## Pure query for testing: returns localized Thai growth stage display name for the currently selected plant, or "" if none selected or blocked.
func get_selected_plant_stage_display_name() -> String:
	if _is_blocked or _selected_runtime_instance_id.is_empty():
		return ""
	match _selected_plant_stage:
		PlantGrowth.Stage.PLANTED:
			return "เพาะเมล็ด"
		PlantGrowth.Stage.SPROUT:
			return "ต้นกล้า"
		PlantGrowth.Stage.GROWING:
			return "กำลังโต"
		PlantGrowth.Stage.MATURE:
			return "โตเต็มที่"
		_:
			return "ไม่ทราบสถานะ"


## Pure query for testing: returns true if [param visitor_id] is in the provisional localized visitor display dictionary.
func is_known_visitor_id(visitor_id: String) -> bool:
	return not visitor_id.is_empty() and PROVISIONAL_VISITOR_DISPLAY_NAMES.has(visitor_id)


## Pure query for testing: returns true if [param event_id] is in the provisional localized event display dictionary.
func is_known_event_id(event_id: String) -> bool:
	return not event_id.is_empty() and PROVISIONAL_EVENT_DISPLAY_NAMES.has(event_id)


## Pure query for testing: returns true if [param trait_id] is in the provisional localized trait display dictionary.
func is_known_environmental_trait(trait_id: String) -> bool:
	return not trait_id.is_empty() and PROVISIONAL_TRAIT_DISPLAY_NAMES.has(trait_id)


## Pure query for testing: returns true if [param time_period] is in the provisional localized time-of-day display dictionary.
func is_known_time_period_id(time_period: String) -> bool:
	return not time_period.is_empty() and PROVISIONAL_TIME_PERIOD_DISPLAY_NAMES.has(time_period)


## Pure query for testing: returns true if [param weather_state] is in the provisional localized weather display dictionary.
func is_known_weather_state_id(weather_state: String) -> bool:
	return not weather_state.is_empty() and PROVISIONAL_WEATHER_DISPLAY_NAMES.has(weather_state)


## Pure query for testing: returns true if [param stage_id] is in the provisional localized progression stage display dictionary.
func is_known_progression_stage_id(stage_id: String) -> bool:
	return not stage_id.is_empty() and PROVISIONAL_PROGRESSION_STAGE_DISPLAY_NAMES.has(stage_id)


## Pure query for testing: returns true if [param guidance_id] is in the provisional localized gentle guidance display dictionary.
func is_known_guidance_id(guidance_id: String) -> bool:
	return not guidance_id.is_empty() and PROVISIONAL_GUIDANCE_DISPLAY_NAMES.has(guidance_id)


## Pure query for testing: returns true if [param definition_id] is in the provisional localized plant display dictionary.
func is_known_plant_definition_id(definition_id: String) -> bool:
	return not definition_id.is_empty() and PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.has(definition_id)


## Pure query for testing: returns true if [param definition_id] is in the provisional localized decoration display dictionary.
func is_known_decoration_definition_id(definition_id: String) -> bool:
	return not definition_id.is_empty() and DecorationPicker.PROVISIONAL_DECORATION_DISPLAY_NAMES.has(definition_id)


## Pure query for testing: returns true if startup is not blocked and [param definition_id] exists as a plant definition in the bound catalog.
func has_plant_in_garden_catalog(definition_id: String) -> bool:
	return not _is_blocked and not definition_id.is_empty() and _catalog != null and _catalog.has_plant(definition_id)


## Pure query for testing: returns true if startup is not blocked and [param definition_id] exists as a visitor definition in the bound catalog.
func has_visitor_in_garden_catalog(definition_id: String) -> bool:
	return not _is_blocked and not definition_id.is_empty() and _catalog != null and _catalog.has_visitor(definition_id)


## Pure query for testing: returns true if startup is not blocked and [param definition_id] exists as a decoration definition in the bound catalog.
func has_decoration_in_garden_catalog(definition_id: String) -> bool:
	return not _is_blocked and not definition_id.is_empty() and _catalog != null and _catalog.has_decoration(definition_id)


## Pure query for testing: returns true if startup is not blocked and [param definition_id] exists as an ambient event definition in the bound catalog.
func has_event_in_garden_catalog(definition_id: String) -> bool:
	return not _is_blocked and not definition_id.is_empty() and _catalog != null and _catalog.has_event(definition_id)


## Pure query for testing: returns the stage-aware visual accent color for the currently selected plant, or STAGE_ACCENT_INVALID if none selected or blocked.
func get_selected_plant_stage_accent_color() -> Color:
	if _is_blocked or _selected_runtime_instance_id.is_empty():
		return PlantView.STAGE_ACCENT_INVALID
	match _selected_plant_stage:
		PlantGrowth.Stage.PLANTED:
			return PlantView.STAGE_ACCENT_PLANTED
		PlantGrowth.Stage.SPROUT:
			return PlantView.STAGE_ACCENT_SPROUT
		PlantGrowth.Stage.GROWING:
			return PlantView.STAGE_ACCENT_GROWING
		PlantGrowth.Stage.MATURE:
			return PlantView.STAGE_ACCENT_MATURE
		_:
			return PlantView.STAGE_ACCENT_INVALID


## Pure query for testing: returns true if a plant is currently selected, startup is not blocked, the selected plant is growing, and has a positive countdown to MATURE.
func has_selected_plant_countdown_to_mature() -> bool:
	return is_selected_plant_growing() and _selected_plant_seconds_until_mature > 0


## Pure query for testing: returns true if a plant is currently selected, startup is not blocked, the selected plant is growing, and has a positive countdown to the next stage.
func has_selected_plant_countdown_to_next_stage() -> bool:
	return is_selected_plant_growing() and _selected_plant_seconds_until_next_stage > 0


## Pure query for testing: returns true if a plant is currently selected, startup is not blocked, and the selected plant has a positive harvest reward.
func has_selected_plant_harvest_reward() -> bool:
	return not _is_blocked and not _selected_runtime_instance_id.is_empty() and _selected_plant_harvest_reward > 0


## Pure query for testing: returns total plant definitions in the bound catalog (0 if blocked/unbound).
func get_total_catalog_plant_count_in_garden() -> int:
	return _catalog.get_plant_count() if not _is_blocked and _catalog != null else 0


## Pure query for testing: returns total visitor definitions in the bound catalog (0 if blocked/unbound).
func get_total_catalog_visitor_count_in_garden() -> int:
	return _catalog.get_visitor_count() if not _is_blocked and _catalog != null else 0


## Pure query for testing: returns total decoration definitions in the bound catalog (0 if blocked/unbound).
func get_total_catalog_decoration_count_in_garden() -> int:
	return _catalog.get_decoration_count() if not _is_blocked and _catalog != null else 0


## Pure query for testing: returns total ambient event definitions in the bound catalog (0 if blocked/unbound).
func get_total_catalog_event_count_in_garden() -> int:
	return _catalog.get_event_count() if not _is_blocked and _catalog != null else 0


## Pure query for testing: returns deterministic catalog-ordered IDs of all plants in the bound catalog, or [] if blocked/unbound.
func get_all_catalog_plant_ids_in_garden() -> Array[String]:
	return _catalog.get_all_plant_ids() if not _is_blocked and _catalog != null else []


## Pure query for testing: returns deterministic catalog-ordered IDs of all visitors in the bound catalog, or [] if blocked/unbound.
func get_all_catalog_visitor_ids_in_garden() -> Array[String]:
	return _catalog.get_all_visitor_ids() if not _is_blocked and _catalog != null else []


## Pure query for testing: returns deterministic catalog-ordered IDs of all decorations in the bound catalog, or [] if blocked/unbound.
func get_all_catalog_decoration_ids_in_garden() -> Array[String]:
	return _catalog.get_all_decoration_ids() if not _is_blocked and _catalog != null else []


## Pure query for testing: returns deterministic catalog-ordered IDs of all ambient events in the bound catalog, or [] if blocked/unbound.
func get_all_catalog_event_ids_in_garden() -> Array[String]:
	return _catalog.get_all_event_ids() if not _is_blocked and _catalog != null else []


## Pure query for testing: returns true if startup is not blocked, a catalog is bound, and all catalog plant species are currently planted in the latest snapshot.
func is_all_catalog_plant_species_present_in_garden() -> bool:
	var total: int = get_total_catalog_plant_count_in_garden()
	return total > 0 and get_distinct_planted_species_count() >= total


## Pure query for testing: returns true if startup is not blocked, a catalog is bound, and all catalog decoration species are currently placed in the latest snapshot.
func is_all_catalog_decoration_species_present_in_garden() -> bool:
	var total: int = get_total_catalog_decoration_count_in_garden()
	return total > 0 and get_distinct_placed_decoration_species_count() >= total


## Pure query for testing: returns localized Thai display names for all plants in the bound catalog in deterministic catalog order, or [] if blocked/unbound.
func get_all_catalog_plant_display_names_in_garden() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_all_catalog_plant_ids_in_garden():
		result.append(get_plant_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all visitors in the bound catalog in deterministic catalog order, or [] if blocked/unbound.
func get_all_catalog_visitor_display_names_in_garden() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_all_catalog_visitor_ids_in_garden():
		result.append(get_visitor_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all decorations in the bound catalog in deterministic catalog order, or [] if blocked/unbound.
func get_all_catalog_decoration_display_names_in_garden() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_all_catalog_decoration_ids_in_garden():
		result.append(get_decoration_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all ambient events in the bound catalog in deterministic catalog order, or [] if blocked/unbound.
func get_all_catalog_event_display_names_in_garden() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_all_catalog_event_ids_in_garden():
		result.append(get_event_display_name_for_id(def_id))
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of catalog plants that are NOT currently planted in the latest snapshot, or [] if blocked/unbound.
func get_unplanted_catalog_plant_ids_in_garden() -> Array[String]:
	if _is_blocked or _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_plant_ids():
		if not is_plant_definition_present_in_garden(def_id):
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of catalog decorations that are NOT currently placed in the latest snapshot, or [] if blocked/unbound.
func get_unplaced_catalog_decoration_ids_in_garden() -> Array[String]:
	if _is_blocked or _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_decoration_ids():
		if not is_decoration_definition_present_in_garden(def_id):
			result.append(def_id)
	return result


## Pure query for testing: returns count of catalog plant species that are NOT currently planted in the latest snapshot (0 if blocked/unbound).
func get_unplanted_catalog_plant_count_in_garden() -> int:
	return get_unplanted_catalog_plant_ids_in_garden().size()


## Pure query for testing: returns count of catalog decoration species that are NOT currently placed in the latest snapshot (0 if blocked/unbound).
func get_unplaced_catalog_decoration_count_in_garden() -> int:
	return get_unplaced_catalog_decoration_ids_in_garden().size()


## Pure query for testing: returns true if startup is not blocked and at least one catalog plant species is NOT currently planted in the latest snapshot.
func has_any_unplanted_catalog_plants_in_garden() -> bool:
	return get_unplanted_catalog_plant_count_in_garden() > 0


## Pure query for testing: returns true if startup is not blocked and at least one catalog decoration species is NOT currently placed in the latest snapshot.
func has_any_unplaced_catalog_decorations_in_garden() -> bool:
	return get_unplaced_catalog_decoration_count_in_garden() > 0


## Pure query for testing: returns localized Thai display names for catalog plants that are NOT currently planted in the latest snapshot in deterministic catalog order, or [] if blocked/unbound.
func get_unplanted_catalog_plant_display_names_in_garden() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_unplanted_catalog_plant_ids_in_garden():
		result.append(get_plant_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized Thai display names for catalog decorations that are NOT currently placed in the latest snapshot in deterministic catalog order, or [] if blocked/unbound.
func get_unplaced_catalog_decoration_display_names_in_garden() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_unplaced_catalog_decoration_ids_in_garden():
		result.append(get_decoration_display_name_for_id(def_id))
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of catalog visitors that are NOT currently eligible in the latest refresh, or [] if blocked/unbound.
func get_ineligible_catalog_visitor_ids_in_garden() -> Array[String]:
	if _is_blocked or _catalog == null:
		return []
	var result: Array[String] = []
	for vid: String in _catalog.get_all_visitor_ids():
		if not is_visitor_currently_eligible(vid):
			result.append(vid)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of catalog ambient events that are NOT currently eligible in the latest refresh, or [] if blocked/unbound.
func get_ineligible_catalog_event_ids_in_garden() -> Array[String]:
	if _is_blocked or _catalog == null:
		return []
	var result: Array[String] = []
	for eid: String in _catalog.get_all_event_ids():
		if not is_event_currently_eligible(eid):
			result.append(eid)
	return result


## Pure query for testing: returns count of catalog visitors that are NOT currently eligible in the latest refresh (0 if blocked/unbound).
func get_ineligible_catalog_visitor_count_in_garden() -> int:
	return get_ineligible_catalog_visitor_ids_in_garden().size()


## Pure query for testing: returns count of catalog ambient events that are NOT currently eligible in the latest refresh (0 if blocked/unbound).
func get_ineligible_catalog_event_count_in_garden() -> int:
	return get_ineligible_catalog_event_ids_in_garden().size()


## Pure query for testing: returns true if startup is not blocked and at least one catalog visitor is NOT currently eligible in the latest refresh.
func has_any_ineligible_catalog_visitors_in_garden() -> bool:
	return get_ineligible_catalog_visitor_count_in_garden() > 0


## Pure query for testing: returns true if startup is not blocked and at least one catalog ambient event is NOT currently eligible in the latest refresh.
func has_any_ineligible_catalog_events_in_garden() -> bool:
	return get_ineligible_catalog_event_count_in_garden() > 0


## Pure query for testing: returns localized Thai display names for catalog visitors that are NOT currently eligible in the latest refresh in deterministic catalog order, or [] if blocked/unbound.
func get_ineligible_catalog_visitor_display_names_in_garden() -> Array[String]:
	var result: Array[String] = []
	for vid: String in get_ineligible_catalog_visitor_ids_in_garden():
		result.append(get_visitor_display_name_for_id(vid))
	return result


## Pure query for testing: returns localized Thai display names for catalog ambient events that are NOT currently eligible in the latest refresh in deterministic catalog order, or [] if blocked/unbound.
func get_ineligible_catalog_event_display_names_in_garden() -> Array[String]:
	var result: Array[String] = []
	for eid: String in get_ineligible_catalog_event_ids_in_garden():
		result.append(get_event_display_name_for_id(eid))
	return result
