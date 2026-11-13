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
signal planting_at_requested(definition_id: String, zone_id: String, grid_x: int, grid_y: int)
signal harvest_requested(runtime_instance_id: String)
signal visitor_observation_requested()
signal event_observation_requested()
signal decoration_purchase_requested(definition_id: String)
signal decoration_purchase_at_requested(definition_id: String, zone_id: String, grid_x: int, grid_y: int)
signal move_item_requested(runtime_instance_id: String, target_zone_id: String, target_grid_x: int, target_grid_y: int)
signal locale_changed(new_locale: String)

const PLANT_VIEW_SCENE: PackedScene = preload("res://scenes/garden/plant_view.tscn")
const DECORATION_VIEW_SCENE: PackedScene = preload("res://scenes/garden/decoration_view.tscn")

const TIME_PERIOD_BASE_COLORS: Dictionary = {
	"morning": Color(0.16, 0.20, 0.14, 1.0),
	"day": Color(0.12, 0.18, 0.14, 1.0),
	"evening": Color(0.18, 0.15, 0.13, 1.0),
	"night": Color(0.08, 0.10, 0.15, 1.0),
}

const DEFAULT_BACKGROUND_COLOR: Color = Color(0.12, 0.15, 0.13, 1.0)
const CLOUDY_TINT_COLOR: Color = Color(0.14, 0.16, 0.18, 1.0)
const RAIN_TINT_COLOR: Color = Color(0.10, 0.14, 0.20, 1.0)
const BASE_MAIN_MARGIN_PX: int = 28

var _session: GameSession = null
var _catalog: ContentCatalog = null
var _game_clock: GameClock = null

var _selected_runtime_instance_id: String = ""
var _selected_decoration_instance_id: String = ""
var _active_zone_id: String = GardenZone.ZONE_MAIN
var _target_zone_id: String = ""
var _target_grid_x: int = -1
var _target_grid_y: int = -1
var _is_move_mode: bool = false
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
var _selected_decoration_definition_id: String = ""
var _selected_decoration_traits: Array[String] = []
var _selected_decoration_price: int = 0
var _selected_decoration_placed_at: int = -1
var _next_time_period: String = ""
var _seconds_until_next_time_period: int = 0
var _next_weather_state: String = ""
var _seconds_until_next_weather_state: int = 0
var _is_blocked: bool = false
var _blocked_message: String = ""
var _blocked_message_key: String = ""
var _locale: String = GardenLocalization.DEFAULT_LOCALE
var _active_feedback_kind: String = ""
var _last_checkpoint_result: PlantingCheckpointResult = null
var _last_harvest_checkpoint_result: HarvestCheckpointResult = null
var _last_visitor_selection_result: VisitorSelectionResult = null
var _last_visitor_observation_checkpoint_result: VisitorObservationCheckpointResult = null
var _last_event_selection_result: EventSelectionResult = null
var _last_tapped_event_id: String = ""
var _last_decoration_purchase_checkpoint_result: DecorationPurchaseCheckpointResult = null
var _last_move_checkpoint_result: GardenPlacementCheckpointResult = null

var _background_rect: ColorRect = null
var _main_margin: MarginContainer = null
var _last_applied_margins: Dictionary = {
	"left": BASE_MAIN_MARGIN_PX,
	"top": BASE_MAIN_MARGIN_PX,
	"right": BASE_MAIN_MARGIN_PX,
	"bottom": BASE_MAIN_MARGIN_PX,
}
var _title_label: Label = null
var _refresh_button: Button = null
var _plant_button: Button = null
var _language_button: Button = null
var _currency_label: Label = null
var _progression_label: Label = null
var _daily_guidance_label: Label = null
var _ftue_label: Label = null
var _discovery_pacing_label: Label = null
var _atmosphere_label: Label = null
var _environment_label: Label = null
var _visitor_row: Control = null
var _visitor_status_label: Label = null
var _observe_visitor_button: Button = null
var _observe_event_button: Button = null
var _journal_row: Control = null
var _journal_status_label: Label = null
var _journal_button: Button = null
var _audio_button: Button = null
var _audio_controller: GardenAudioController = null
var _suppress_feedback_effects: bool = false
var _decoration_row: Control = null
var _decoration_status_label: Label = null
var _decorate_button: Button = null
var _feedback_area: Control = null
var _feedback_label: Label = null
var _planting_picker: PlantingPicker = null
var _journal_panel: JournalPanel = null
var _decoration_picker: DecorationPicker = null

var _zones_section_label: Label = null
var _garden_diorama: GardenDiorama = null
var _zone_tabs_row: Control = null
var _zone_main_button: Button = null
var _zone_adjacent_button: Button = null
var _zone_status_label: Label = null
var _zone_grid_container: GridContainer = null
var _plants_section_label: Label = null
var _plants_container: Container = null
var _decorations_section_label: Label = null
var _decorations_container: Container = null
var _plants_scroll: ScrollContainer = null
var _empty_container: Control = null
var _empty_label: Label = null
var _blocked_container: Control = null
var _blocked_label: Label = null

var _details_header_label: Label = null
var _no_selection_label: Label = null
var _details_content: Control = null
var _detail_name_label: Label = null
var _detail_stage_label: Label = null
var _detail_reward_label: Label = null
var _detail_id_label: Label = null
var _detail_planted_at_label: Label = null
var _detail_placement_label: Label = null
var _harvest_button: Button = null
var _move_button: Button = null


func _ready() -> void:
	_resolve_nodes()
	var viewport: Viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_refresh_safe_area_margins):
		viewport.size_changed.connect(_refresh_safe_area_margins)
	_refresh_safe_area_margins()
	_sync_back_navigation_state()
	_apply_static_texts()
	if _is_blocked:
		_show_blocked_visual()
	elif _session != null:
		refresh_from_session()


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().set_quit_on_go_back(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_refresh_safe_area_margins()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back_action()


func _unhandled_input(event: InputEvent) -> void:
	if event != null and event.is_action_pressed("ui_cancel"):
		if handle_back_action():
			var viewport: Viewport = get_viewport()
			if viewport != null:
				viewport.set_input_as_handled()


## Resolves child node references safely whether _ready has fired or not.
func _resolve_nodes() -> void:
	if _background_rect == null:
		_background_rect = get_node_or_null("Background") as ColorRect
	if _main_margin == null:
		_main_margin = get_node_or_null("MainMargin") as MarginContainer
	if _title_label == null:
		_title_label = get_node_or_null("MainMargin/LayoutBox/HeaderArea/TitleLabel") as Label
	if _refresh_button == null:
		_refresh_button = get_node_or_null("MainMargin/LayoutBox/HeaderArea/RefreshButton") as Button
	if _plant_button == null:
		_plant_button = get_node_or_null("MainMargin/LayoutBox/HeaderArea/PlantButton") as Button
	if _language_button == null:
		_language_button = get_node_or_null("MainMargin/LayoutBox/HeaderArea/LanguageButton") as Button
	if _currency_label == null:
		_currency_label = get_node_or_null("MainMargin/LayoutBox/CurrencyLabel") as Label
	if _progression_label == null:
		_progression_label = get_node_or_null("MainMargin/LayoutBox/ProgressionLabel") as Label
	if _daily_guidance_label == null:
		_daily_guidance_label = get_node_or_null("MainMargin/LayoutBox/DailyGuidanceLabel") as Label
	if _ftue_label == null:
		_ftue_label = get_node_or_null("MainMargin/LayoutBox/FtueLabel") as Label
	if _discovery_pacing_label == null:
		_discovery_pacing_label = get_node_or_null("MainMargin/LayoutBox/DiscoveryPacingLabel") as Label
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
	if _audio_button == null:
		_audio_button = get_node_or_null("MainMargin/LayoutBox/JournalRow/AudioButton") as Button
	if _audio_controller == null:
		_audio_controller = get_node_or_null("AudioController") as GardenAudioController
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
	if _garden_diorama == null:
		_garden_diorama = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/GardenItemsVBox/GardenDiorama") as GardenDiorama
	if _zones_section_label == null:
		_zones_section_label = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/GardenItemsVBox/ZonesSectionLabel") as Label
	if _zone_tabs_row == null:
		_zone_tabs_row = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/GardenItemsVBox/ZoneTabsRow") as Control
	if _zone_main_button == null:
		_zone_main_button = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/GardenItemsVBox/ZoneTabsRow/ZoneMainButton") as Button
	if _zone_adjacent_button == null:
		_zone_adjacent_button = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/GardenItemsVBox/ZoneTabsRow/ZoneAdjacentButton") as Button
	if _zone_status_label == null:
		_zone_status_label = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/GardenItemsVBox/ZoneStatusLabel") as Label
	if _zone_grid_container == null:
		_zone_grid_container = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/GardenItemsVBox/ZoneGridContainer") as GridContainer
	if _plants_section_label == null:
		_plants_section_label = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/GardenItemsVBox/PlantsSectionLabel") as Label
	if _plants_container == null:
		_plants_container = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/GardenItemsVBox/PlantsContainer") as Container
	if _decorations_section_label == null:
		_decorations_section_label = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/GardenItemsVBox/DecorationsSectionLabel") as Label
	if _decorations_container == null:
		_decorations_container = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/GardenItemsVBox/DecorationsContainer") as Container
	if _plants_scroll == null:
		_plants_scroll = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll") as ScrollContainer
	if _empty_container == null:
		_empty_container = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/GardenItemsVBox/EmptyStateContainer") as Control
	if _empty_label == null:
		_empty_label = get_node_or_null("MainMargin/LayoutBox/ContentArea/PlantsScroll/PlantsMargin/GardenItemsVBox/EmptyStateContainer/EmptyLabel") as Label
	if _blocked_container == null:
		_blocked_container = get_node_or_null("MainMargin/LayoutBox/ContentArea/BlockedStateContainer") as Control
	if _blocked_label == null:
		_blocked_label = get_node_or_null("MainMargin/LayoutBox/ContentArea/BlockedStateContainer/BlockedLabel") as Label
	if _details_header_label == null:
		_details_header_label = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/DetailsHeaderLabel") as Label
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
	if _detail_placement_label == null:
		_detail_placement_label = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/DetailsContent/DetailPlacementLabel") as Label
	if _harvest_button == null:
		_harvest_button = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/DetailsContent/DetailsActionsHBox/HarvestButton") as Button
	if _move_button == null:
		_move_button = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/DetailsContent/DetailsActionsHBox/MoveButton") as Button
	_connect_signals()


func _connect_signals() -> void:
	if _refresh_button != null and not _refresh_button.pressed.is_connected(_on_refresh_button_pressed):
		_refresh_button.pressed.connect(_on_refresh_button_pressed)
	if _plant_button != null and not _plant_button.pressed.is_connected(open_planting_picker):
		_plant_button.pressed.connect(open_planting_picker)
	if _language_button != null and not _language_button.pressed.is_connected(toggle_locale):
		_language_button.pressed.connect(toggle_locale)
	if _planting_picker != null and not _planting_picker.planting_requested.is_connected(_on_picker_planting_requested):
		_planting_picker.planting_requested.connect(_on_picker_planting_requested)
	if _planting_picker != null and not _planting_picker.picker_closed.is_connected(_on_modal_closed):
		_planting_picker.picker_closed.connect(_on_modal_closed)
	if _planting_picker != null and not _planting_picker.ui_tapped.is_connected(_on_child_ui_tapped):
		_planting_picker.ui_tapped.connect(_on_child_ui_tapped)
	if _harvest_button != null and not _harvest_button.pressed.is_connected(_on_harvest_button_pressed):
		_harvest_button.pressed.connect(_on_harvest_button_pressed)
	if _move_button != null and not _move_button.pressed.is_connected(_on_move_button_pressed):
		_move_button.pressed.connect(_on_move_button_pressed)
	if _zone_main_button != null and not _zone_main_button.pressed.is_connected(_on_zone_main_button_pressed):
		_zone_main_button.pressed.connect(_on_zone_main_button_pressed)
	if _zone_adjacent_button != null and not _zone_adjacent_button.pressed.is_connected(_on_zone_adjacent_button_pressed):
		_zone_adjacent_button.pressed.connect(_on_zone_adjacent_button_pressed)
	if _observe_visitor_button != null and not _observe_visitor_button.pressed.is_connected(_on_observe_visitor_button_pressed):
		_observe_visitor_button.pressed.connect(_on_observe_visitor_button_pressed)
	if _observe_event_button != null and not _observe_event_button.pressed.is_connected(_on_observe_event_button_pressed):
		_observe_event_button.pressed.connect(_on_observe_event_button_pressed)
	if _journal_button != null and not _journal_button.pressed.is_connected(open_journal_panel):
		_journal_button.pressed.connect(open_journal_panel)
	if _journal_panel != null and not _journal_panel.journal_closed.is_connected(_on_modal_closed):
		_journal_panel.journal_closed.connect(_on_modal_closed)
	if _journal_panel != null and not _journal_panel.ui_tapped.is_connected(_on_child_ui_tapped):
		_journal_panel.ui_tapped.connect(_on_child_ui_tapped)
	if _audio_button != null and not _audio_button.pressed.is_connected(toggle_audio_mute):
		_audio_button.pressed.connect(toggle_audio_mute)
	if _decorate_button != null and not _decorate_button.pressed.is_connected(open_decoration_picker):
		_decorate_button.pressed.connect(open_decoration_picker)
	if _decoration_picker != null and not _decoration_picker.decoration_purchase_requested.is_connected(_on_picker_decoration_purchase_requested):
		_decoration_picker.decoration_purchase_requested.connect(_on_picker_decoration_purchase_requested)
	if _decoration_picker != null and not _decoration_picker.picker_closed.is_connected(_on_modal_closed):
		_decoration_picker.picker_closed.connect(_on_modal_closed)
	if _decoration_picker != null and not _decoration_picker.ui_tapped.is_connected(_on_child_ui_tapped):
		_decoration_picker.ui_tapped.connect(_on_child_ui_tapped)
	if _garden_diorama != null and not _garden_diorama.item_selected.is_connected(_on_diorama_item_selected):
		_garden_diorama.item_selected.connect(_on_diorama_item_selected)
	if _garden_diorama != null and not _garden_diorama.cell_selected.is_connected(_on_zone_cell_pressed):
		_garden_diorama.cell_selected.connect(_on_zone_cell_pressed)
	if _garden_diorama != null and not _garden_diorama.visitor_selected.is_connected(_on_diorama_visitor_selected):
		_garden_diorama.visitor_selected.connect(_on_diorama_visitor_selected)
	if _garden_diorama != null and not _garden_diorama.event_selected.is_connected(_on_diorama_event_selected):
		_garden_diorama.event_selected.connect(_on_diorama_event_selected)


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
	_apply_static_texts()
	if _planting_picker != null and _catalog != null:
		_planting_picker.set_locale(_locale)
		_planting_picker.bind_catalog(_catalog)
		_planting_picker.set_picker_enabled(true)
	if _journal_panel != null:
		_journal_panel.set_locale(_locale)
		_journal_panel.set_journal_enabled(true)
	if _decoration_picker != null and _catalog != null:
		_decoration_picker.set_locale(_locale)
		_decoration_picker.bind_catalog(_catalog)
		_decoration_picker.set_picker_enabled(true)

	if _plant_button != null:
		_plant_button.disabled = false
	if _journal_button != null:
		_journal_button.disabled = false
	if _decorate_button != null:
		_decorate_button.disabled = false

	if _session == null or _catalog == null or _game_clock == null:
		show_blocked_startup_key("ui.garden.blocked_incomplete_deps")
		return

	_is_blocked = false
	_blocked_message = ""
	_blocked_message_key = ""
	_has_refresh_timestamp = false
	_last_refresh_utc_seconds = 0
	_last_return_summary = null
	refresh_from_session()


## Sets active display locale ("th" or "en") and re-renders GardenView, subviews, pickers, and journal.
func set_locale(locale: String) -> void:
	var normalized: String = GardenLocalization.normalize_locale(locale)
	_locale = normalized
	_resolve_nodes()
	_apply_static_texts()

	if _planting_picker != null:
		_planting_picker.set_locale(_locale)
	if _decoration_picker != null:
		_decoration_picker.set_locale(_locale)
	if _journal_panel != null:
		_journal_panel.set_locale(_locale)

	if _is_blocked:
		if not _blocked_message_key.is_empty():
			_blocked_message = GardenLocalization.translate(_blocked_message_key, _locale)
		_show_blocked_visual()
	elif _session != null and _catalog != null and _game_clock != null:
		_render_current_session_snapshot()
		_refresh_active_feedback_locale()

	locale_changed.emit(_locale)


## Returns active display locale ("th" or "en").
func get_locale() -> String:
	return _locale


## Toggles active display locale between Thai ("th") and English ("en").
func toggle_locale() -> void:
	_play_sfx("ui_tap")
	set_locale(GardenLocalization.other_locale(_locale))


## Toggles garden audio mute state and persists audio preference.
func toggle_audio_mute() -> void:
	_resolve_nodes()
	if _audio_controller == null:
		return
	var now_muted: bool = _audio_controller.toggle_muted()
	_update_audio_button_text()
	if not now_muted:
		_play_sfx("ui_tap")


## Pure query for testing: returns AudioController child node.
func get_audio_controller() -> GardenAudioController:
	_resolve_nodes()
	return _audio_controller


## Pure query for testing: returns AudioButton instance.
func get_audio_button() -> Button:
	_resolve_nodes()
	return _audio_button


## Pure query for testing: returns LanguageButton instance.
func get_language_button() -> Button:
	_resolve_nodes()
	return _language_button


func _apply_static_texts() -> void:
	if _title_label != null:
		_title_label.text = GardenLocalization.translate("ui.garden.title", _locale)
	if _plant_button != null:
		_plant_button.text = GardenLocalization.translate("ui.garden.plant_button", _locale)
	if _refresh_button != null:
		_refresh_button.text = GardenLocalization.translate("ui.garden.refresh_button", _locale)
	if _language_button != null:
		_language_button.text = GardenLocalization.translate("ui.common.language_button", _locale)
	if _observe_visitor_button != null:
		_observe_visitor_button.text = GardenLocalization.translate("ui.garden.observe_visitor_button", _locale)
	if _observe_event_button != null:
		_observe_event_button.text = GardenLocalization.translate("ui.garden.observe_event_button", _locale)
	if _journal_button != null:
		_journal_button.text = GardenLocalization.translate("ui.garden.journal_button", _locale)
	_update_audio_button_text()
	if _decorate_button != null:
		_decorate_button.text = GardenLocalization.translate("ui.garden.decorate_button", _locale)
	if _plants_section_label != null:
		_plants_section_label.text = GardenLocalization.translate("ui.garden.plants_section_header", _locale)
	if _decorations_section_label != null:
		_decorations_section_label.text = GardenLocalization.translate("ui.garden.decorations_section_header", _locale)
	if _empty_label != null:
		_empty_label.text = GardenLocalization.translate("ui.garden.empty_garden", _locale)
	if _no_selection_label != null:
		_no_selection_label.text = GardenLocalization.translate("ui.details.no_selection", _locale)
	if _move_button != null:
		_move_button.text = GardenLocalization.translate(
			"ui.details.move_cancel_button" if _is_move_mode else "ui.details.move_button",
			_locale
		)


func _update_audio_button_text() -> void:
	if _audio_button == null:
		return
	var is_muted: bool = _audio_controller != null and _audio_controller.is_muted()
	var key: String = "ui.garden.audio_off" if is_muted else "ui.garden.audio_on"
	_audio_button.text = GardenLocalization.translate(key, _locale)


func _play_sfx(cue_id: String) -> void:
	if _suppress_feedback_effects:
		return
	if _audio_controller != null:
		_audio_controller.play_sfx(cue_id)


## Displays a safe readable state using a localization key when startup failed or session is unavailable.
func show_blocked_startup_key(reason_key: String) -> void:
	_blocked_message_key = reason_key if not reason_key.is_empty() else "ui.garden.blocked_default"
	show_blocked_startup(GardenLocalization.translate(_blocked_message_key, _locale))


## Displays a safe readable state when startup failed or session is unavailable.
func show_blocked_startup(message: String = "") -> void:
	_is_blocked = true
	if message.is_empty():
		_blocked_message_key = "ui.garden.blocked_default"
		_blocked_message = GardenLocalization.translate(_blocked_message_key, _locale)
	else:
		if not _blocked_message_key.is_empty() and message != GardenLocalization.translate(_blocked_message_key, _locale):
			_blocked_message_key = ""
		_blocked_message = message
	_resolve_nodes()
	_apply_static_texts()
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

	_render_snapshot_at(now_utc)


func _render_current_session_snapshot() -> void:
	var now_utc: int = _game_clock.utc_now_seconds() if _game_clock != null else _last_refresh_utc_seconds
	_render_snapshot_at(now_utc)


func _render_snapshot_at(now_utc: int) -> void:
	# Read authoritative currency balance directly from GameSession (no presentation cache).
	_resolve_nodes()
	_apply_static_texts()
	if _currency_label != null:
		_currency_label.visible = true
		_currency_label.text = GardenLocalization.format_key("ui.garden.currency", [_session.get_currency()], _locale)

	# Authoritative plant and placed decoration collections in deterministic order.
	var plants: Array[PlantState] = _session.get_state().get_plants().get_all_plants()
	var decor_collection: DecorationCollectionState = _session.get_state().get_decorations()
	var decorations: Array[DecorationState] = (
		decor_collection.get_all_decorations()
		if decor_collection != null
		else []
	)

	_render_garden_items(plants, decorations, now_utc)
	_update_environment_and_visitors(now_utc)
	_update_garden_diorama(now_utc)
	_render_zone_grid()
	_update_journal_ui()


func _on_refresh_button_pressed() -> void:
	if not _is_blocked and _session != null:
		_play_sfx("ui_tap")
	refresh_from_session()


func _render_garden_items(
	plants: Array[PlantState],
	decorations: Array[DecorationState],
	now_utc: int
) -> void:
	_resolve_nodes()

	if _blocked_container != null:
		_blocked_container.visible = false

	# Gracefully handle completely empty garden (keep living Diorama and zone grid visible).
	if plants.is_empty() and decorations.is_empty():
		_clear_plant_views()
		_clear_decoration_views()
		_selected_runtime_instance_id = ""
		_selected_decoration_instance_id = ""
		if _plants_section_label != null:
			_plants_section_label.visible = false
		if _plants_container != null:
			_plants_container.visible = false
		if _decorations_section_label != null:
			_decorations_section_label.visible = false
		if _decorations_container != null:
			_decorations_container.visible = false
		if _plants_scroll != null:
			_plants_scroll.visible = true
		if _empty_container != null:
			_empty_container.visible = true
		_update_details_panel(null, null, PlantGrowth.Stage.INVALID, 0)
		return

	if _empty_container != null:
		_empty_container.visible = false
	if _plants_scroll != null:
		_plants_scroll.visible = true

	# Clear previous item views to avoid duplicate nodes on refresh.
	_clear_plant_views()
	_clear_decoration_views()

	if _plants_section_label != null:
		_plants_section_label.visible = not plants.is_empty()
	if _plants_container != null:
		_plants_container.visible = not plants.is_empty()

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
			seconds_until_next_stage,
			_locale,
			plant_state.get_zone_id(),
			plant_state.get_grid_x(),
			plant_state.get_grid_y()
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

	if _decorations_section_label != null:
		_decorations_section_label.visible = not decorations.is_empty()
	if _decorations_container != null:
		_decorations_container.visible = not decorations.is_empty()

	var selected_decoration_state: DecorationState = null
	var selected_decoration_def: DecorationDefinition = null

	for decor_state: DecorationState in decorations:
		var decor_inst_id: String = decor_state.get_runtime_instance_id()
		var decor_def_id: String = decor_state.get_definition_id()
		var placed_at: int = decor_state.get_placed_at()
		var decor_def: DecorationDefinition = _catalog.get_decoration(decor_def_id)
		var decor_price: int = decor_def.price if decor_def != null else 0
		var decor_traits: Array[String] = []
		if decor_def != null:
			decor_traits = decor_def.environmental_traits.duplicate()

		var decor_view: DecorationView = DECORATION_VIEW_SCENE.instantiate() as DecorationView
		decor_view.bind_decoration_data(
			decor_inst_id,
			decor_def_id,
			placed_at,
			decor_price,
			decor_traits,
			_locale,
			decor_state.get_zone_id(),
			decor_state.get_grid_x(),
			decor_state.get_grid_y()
		)
		decor_view.decoration_selected.connect(_on_decoration_selected)

		if selected_plant_state == null and decor_inst_id == _selected_decoration_instance_id:
			decor_view.set_selected(true)
			selected_decoration_state = decor_state
			selected_decoration_def = decor_def

		if _decorations_container != null:
			_decorations_container.add_child(decor_view)

	# Preserve active plant or decoration details; safely clear stale selection.
	if selected_plant_state != null:
		_selected_decoration_instance_id = ""
		_update_details_panel(selected_plant_state, selected_definition, selected_stage, now_utc)
	elif selected_decoration_state != null:
		_selected_runtime_instance_id = ""
		_update_decoration_details_panel(selected_decoration_state, selected_decoration_def)
	else:
		_selected_runtime_instance_id = ""
		_selected_decoration_instance_id = ""
		_update_details_panel(null, null, PlantGrowth.Stage.INVALID, 0)


func _clear_container_children(container: Container) -> void:
	if container == null:
		return
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _clear_plant_views() -> void:
	_clear_container_children(_plants_container)


func _clear_decoration_views() -> void:
	_clear_container_children(_decorations_container)


func _sync_selection_highlights() -> void:
	if _plants_container != null:
		for child: Node in _plants_container.get_children():
			if child is PlantView:
				var pview: PlantView = child as PlantView
				pview.set_selected(pview.get_runtime_instance_id() == _selected_runtime_instance_id)
	if _decorations_container != null:
		for child: Node in _decorations_container.get_children():
			if child is DecorationView:
				var dview: DecorationView = child as DecorationView
				dview.set_selected(dview.get_runtime_instance_id() == _selected_decoration_instance_id)
	if _garden_diorama != null:
		_garden_diorama.set_selected_item(_selected_runtime_instance_id, _selected_decoration_instance_id)


func _on_plant_selected(runtime_instance_id: String) -> void:
	_play_sfx("ui_tap")
	_selected_runtime_instance_id = runtime_instance_id
	_selected_decoration_instance_id = ""

	_resolve_nodes()
	_sync_selection_highlights()

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


func _on_decoration_selected(runtime_instance_id: String) -> void:
	_play_sfx("ui_tap")
	_selected_decoration_instance_id = runtime_instance_id
	_selected_runtime_instance_id = ""

	_resolve_nodes()
	_sync_selection_highlights()

	if _session != null and _session.get_state() != null and _session.get_state().get_decorations() != null:
		var decor_state: DecorationState = _session.get_state().get_decorations().get_decoration(runtime_instance_id)
		if decor_state != null:
			var definition: DecorationDefinition = (
				_catalog.get_decoration(decor_state.get_definition_id())
				if _catalog != null
				else null
			)
			_update_decoration_details_panel(decor_state, definition)
			return

	_update_details_panel(null, null, PlantGrowth.Stage.INVALID, 0)


func _clear_selected_plant_fields() -> void:
	_selected_plant_definition_id = ""
	_selected_plant_stage = PlantGrowth.Stage.INVALID
	_selected_plant_seconds_until_next_stage = -1
	_selected_plant_seconds_until_mature = -1
	_selected_plant_traits = []
	_selected_plant_harvest_reward = 0
	_selected_plant_planted_at = -1


func _clear_selected_decoration_fields() -> void:
	_selected_decoration_definition_id = ""
	_selected_decoration_traits = []
	_selected_decoration_price = 0
	_selected_decoration_placed_at = -1


func _update_decoration_details_panel(
	decor_state: DecorationState,
	definition: DecorationDefinition
) -> void:
	_resolve_nodes()
	if _no_selection_label == null or _details_content == null:
		return

	if decor_state == null:
		_update_details_panel(null, null, PlantGrowth.Stage.INVALID, 0)
		return

	_clear_selected_plant_fields()
	_no_selection_label.visible = false
	_details_content.visible = true
	if _details_header_label != null:
		_details_header_label.text = GardenLocalization.translate("ui.details.header_decoration", _locale)

	var def_id: String = decor_state.get_definition_id()
	_selected_decoration_definition_id = def_id
	var empty_traits: Array[String] = []
	_selected_decoration_traits = (
		definition.environmental_traits.duplicate()
		if definition != null
		else empty_traits
	)
	_selected_decoration_price = maxi(0, definition.price) if definition != null else 0
	_selected_decoration_placed_at = decor_state.get_placed_at()

	var display_name: String = GardenLocalization.get_decoration_name(def_id, _locale, definition)

	if _detail_name_label != null:
		if not _selected_decoration_traits.is_empty():
			var trait_names: PackedStringArray = PackedStringArray()
			for trait_id: String in _selected_decoration_traits:
				trait_names.append(GardenLocalization.get_trait_name(trait_id, _locale))
			_detail_name_label.text = GardenLocalization.format_key(
				"ui.details.decoration_name_traits",
				[display_name, def_id, ", ".join(trait_names)],
				_locale
			)
		else:
			_detail_name_label.text = GardenLocalization.format_key(
				"ui.details.decoration_name_cosmetic",
				[display_name, def_id],
				_locale
			)

	if _detail_stage_label != null:
		if not _selected_decoration_traits.is_empty():
			_detail_stage_label.text = GardenLocalization.translate("ui.details.decoration_status_traits", _locale)
		else:
			_detail_stage_label.text = GardenLocalization.translate("ui.details.decoration_status_cosmetic", _locale)

	if _detail_reward_label != null:
		if definition != null:
			_detail_reward_label.text = GardenLocalization.format_key("ui.details.decoration_price_coins", [definition.price], _locale)
		else:
			_detail_reward_label.text = GardenLocalization.translate("ui.details.decoration_price_none", _locale)

	if _detail_id_label != null:
		_detail_id_label.text = GardenLocalization.format_key("ui.details.decoration_instance_id", [decor_state.get_runtime_instance_id()], _locale)

	if _detail_planted_at_label != null:
		_detail_planted_at_label.text = GardenLocalization.format_key("ui.details.placed_at", [decor_state.get_placed_at()], _locale)

	if _detail_placement_label != null:
		_detail_placement_label.text = GardenLocalization.format_key(
			"ui.details.placement",
			[
				GardenLocalization.get_zone_name(decor_state.get_zone_id(), _locale),
				decor_state.get_grid_x(),
				decor_state.get_grid_y(),
			],
			_locale
		)

	if _harvest_button != null:
		_harvest_button.disabled = true
		_harvest_button.text = GardenLocalization.translate("ui.details.decoration_no_harvest", _locale)

	if _move_button != null:
		_move_button.disabled = _is_blocked
		_move_button.text = GardenLocalization.translate(
			"ui.details.move_cancel_button" if _is_move_mode else "ui.details.move_button",
			_locale
		)


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
		_clear_selected_plant_fields()
		_clear_selected_decoration_fields()
		_is_move_mode = false
		if _details_header_label != null:
			_details_header_label.text = GardenLocalization.translate("ui.details.header_plant", _locale)
		_no_selection_label.visible = true
		_details_content.visible = false
		if _detail_placement_label != null:
			_detail_placement_label.text = ""
		if _harvest_button != null:
			_harvest_button.disabled = true
			_harvest_button.text = GardenLocalization.translate("ui.details.harvest_not_ready", _locale)
		if _move_button != null:
			_move_button.disabled = true
			_move_button.text = GardenLocalization.translate("ui.details.move_button", _locale)
		_sync_back_navigation_state()
		return

	_clear_selected_decoration_fields()
	if _details_header_label != null:
		_details_header_label.text = GardenLocalization.translate("ui.details.header_plant", _locale)
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
	var empty_plant_traits: Array[String] = []
	_selected_plant_traits = (
		definition.environmental_traits.duplicate()
		if definition != null
		else empty_plant_traits
	)
	_selected_plant_harvest_reward = (
		maxi(0, definition.harvest_reward)
		if definition != null
		else 0
	)
	_selected_plant_planted_at = plant_state.get_planted_at()

	var def_id: String = plant_state.get_definition_id()
	var display_name: String = GardenLocalization.get_plant_name(def_id, _locale, definition)

	if _detail_name_label != null:
		if not _selected_plant_traits.is_empty():
			var trait_names: PackedStringArray = PackedStringArray()
			for trait_id: String in _selected_plant_traits:
				trait_names.append(GardenLocalization.get_trait_name(trait_id, _locale))
			_detail_name_label.text = GardenLocalization.format_key(
				"ui.details.plant_name_traits",
				[display_name, def_id, ", ".join(trait_names)],
				_locale
			)
		else:
			_detail_name_label.text = GardenLocalization.format_key(
				"ui.details.plant_name_only",
				[display_name, def_id],
				_locale
			)

	if _detail_stage_label != null:
		var stage_text: String = GardenLocalization.get_plant_stage_detail(stage, _locale)
		if stage == PlantGrowth.Stage.MATURE:
			_detail_stage_label.text = GardenLocalization.format_key("ui.details.stage_mature_ready", [stage_text], _locale)
		elif stage != PlantGrowth.Stage.INVALID and _selected_plant_seconds_until_mature > 0:
			_detail_stage_label.text = GardenLocalization.format_key(
				"ui.details.stage_countdown",
				[
					stage_text,
					_selected_plant_seconds_until_mature,
					_selected_plant_seconds_until_next_stage,
				],
				_locale
			)
		else:
			_detail_stage_label.text = GardenLocalization.format_key("ui.details.stage_only", [stage_text], _locale)

	if _detail_reward_label != null:
		if definition != null and definition.harvest_reward > 0:
			_detail_reward_label.text = GardenLocalization.format_key("ui.details.reward_coins", [definition.harvest_reward], _locale)
		else:
			_detail_reward_label.text = GardenLocalization.translate("ui.details.reward_none", _locale)

	if _detail_id_label != null:
		_detail_id_label.text = GardenLocalization.format_key("ui.details.plant_instance_id", [plant_state.get_runtime_instance_id()], _locale)

	if _detail_planted_at_label != null:
		_detail_planted_at_label.text = GardenLocalization.format_key("ui.details.planted_at", [plant_state.get_planted_at()], _locale)

	if _detail_placement_label != null:
		_detail_placement_label.text = GardenLocalization.format_key(
			"ui.details.placement",
			[
				GardenLocalization.get_zone_name(plant_state.get_zone_id(), _locale),
				plant_state.get_grid_x(),
				plant_state.get_grid_y(),
			],
			_locale
		)

	if _harvest_button != null:
		var can_harvest: bool = (
			not _is_blocked
			and stage == PlantGrowth.Stage.MATURE
			and definition != null
			and definition.harvest_reward > 0
		)
		_harvest_button.disabled = not can_harvest
		if can_harvest:
			_harvest_button.text = GardenLocalization.format_key("ui.details.harvest_ready", [definition.harvest_reward], _locale)
		else:
			_harvest_button.text = GardenLocalization.translate("ui.details.harvest_not_ready", _locale)

	if _move_button != null:
		_move_button.disabled = _is_blocked
		_move_button.text = GardenLocalization.translate(
			"ui.details.move_cancel_button" if _is_move_mode else "ui.details.move_button",
			_locale
		)


func _show_blocked_visual() -> void:
	_resolve_nodes()
	_clear_plant_views()
	_clear_decoration_views()
	_selected_runtime_instance_id = ""
	_selected_decoration_instance_id = ""
	_target_zone_id = ""
	_target_grid_x = -1
	_target_grid_y = -1
	_is_move_mode = false
	_current_visitor_id = ""
	_current_event_id = ""
	_eligible_visitor_ids = []
	_eligible_event_ids = []
	_last_snapshot = null
	_last_progression_summary = null
	_last_return_summary = null
	_last_refresh_utc_seconds = 0
	_has_refresh_timestamp = false
	_clear_selected_plant_fields()
	_clear_selected_decoration_fields()
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
	if _daily_guidance_label != null:
		_daily_guidance_label.visible = false
	if _ftue_label != null:
		_ftue_label.visible = false
	if _discovery_pacing_label != null:
		_discovery_pacing_label.visible = false
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
	if _plants_section_label != null:
		_plants_section_label.visible = false
	if _decorations_section_label != null:
		_decorations_section_label.visible = false
	if _decorations_container != null:
		_decorations_container.visible = false
	_hide_zone_grid()
	if _empty_container != null:
		_empty_container.visible = false
	if _plants_scroll != null:
		_plants_scroll.visible = false
	if _garden_diorama != null:
		_garden_diorama.clear_for_blocked_state()
	if _audio_controller != null:
		_audio_controller.set_paused(true)
	if _blocked_container != null:
		_blocked_container.visible = true
	if _blocked_label != null:
		_blocked_label.text = _blocked_message if not _blocked_message.is_empty() else GardenLocalization.translate("ui.garden.blocked_default", _locale)

	_update_details_panel(null, null, PlantGrowth.Stage.INVALID, 0)
	_sync_back_navigation_state()


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
	_sync_picker_placement_contexts()

	var day_number: int = int(now_utc / 86400) if now_utc >= 0 else 0
	var currency: int = _session.get_currency() if _session != null else 0
	_last_progression_summary = GardenProgressionStage.evaluate(_last_snapshot, journal, day_number, currency, _locale)
	if _progression_label != null and _last_progression_summary != null:
		_progression_label.visible = true
		var stage_id: String = _last_progression_summary.get_stage_id()
		var stage_name: String = GardenLocalization.get_progression_stage_name(stage_id, _locale)
		var score: int = _last_progression_summary.get_establishment_score()
		var guidance_id: String = _last_progression_summary.get_guidance_id()
		var guidance_text: String = GardenLocalization.get_guidance_text(guidance_id, _locale)
		if _last_progression_summary.is_max_stage():
			_progression_label.text = GardenLocalization.format_key(
				"ui.garden.progression_max",
				[stage_name, score, guidance_text],
				_locale
			)
		else:
			var next_stage_id: String = _last_progression_summary.get_next_stage_id()
			var next_stage_name: String = GardenLocalization.get_progression_stage_name(next_stage_id, _locale)
			var points_remaining: int = _last_progression_summary.get_points_to_next_stage()
			_progression_label.text = GardenLocalization.format_key(
				"ui.garden.progression_next",
				[stage_name, score, points_remaining, next_stage_name, guidance_text],
				_locale
			)

	if _daily_guidance_label != null:
		if _last_progression_summary != null and _last_progression_summary.has_daily_guidance():
			_daily_guidance_label.visible = true
			var daily_items: Array[DailyGuidanceItem] = _last_progression_summary.get_daily_guidance_items()
			var parts: PackedStringArray = PackedStringArray()
			for i: int in range(daily_items.size()):
				parts.append("%d. %s" % [i + 1, daily_items[i].get_display_text()])
			_daily_guidance_label.text = GardenLocalization.format_key("ui.garden.daily_guidance", [" • ".join(parts)], _locale)
		else:
			_daily_guidance_label.visible = false

	if _ftue_label != null:
		if _last_progression_summary != null and _last_progression_summary.is_ftue_active():
			_ftue_label.visible = true
			var ftue_step: FtueStep = _last_progression_summary.get_ftue_step()
			_ftue_label.text = GardenLocalization.format_key(
				"ui.garden.ftue_banner",
				[ftue_step.get_title(), ftue_step.get_instruction()],
				_locale
			)
		else:
			_ftue_label.visible = false

	if _discovery_pacing_label != null:
		if _last_progression_summary != null and _last_progression_summary.has_discovery_pacing_milestone():
			_discovery_pacing_label.visible = true
			var pacing: DiscoveryPacingMilestone = _last_progression_summary.get_discovery_pacing_milestone()
			var status_suffix: String = (
				GardenLocalization.translate("ui.garden.discovery_pacing_achieved_suffix", _locale)
				if pacing.is_achieved()
				else ""
			)
			_discovery_pacing_label.text = GardenLocalization.format_key(
				"ui.garden.discovery_pacing",
				[pacing.get_title(), status_suffix, pacing.get_recommended_focus()],
				_locale
			)
		else:
			_discovery_pacing_label.visible = false

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
		var time_name: String = GardenLocalization.get_time_period_name(time_period, _locale)
		var weather_name: String = GardenLocalization.get_weather_name(weather_state, _locale)
		var events_summary: String = GardenLocalization.translate("ui.garden.atmosphere_calm", _locale)
		if not _eligible_event_ids.is_empty():
			var event_names: PackedStringArray = PackedStringArray()
			for eid: String in _eligible_event_ids:
				var edef: EventDefinition = _catalog.get_event(eid) if _catalog != null else null
				event_names.append(GardenLocalization.get_event_name(eid, _locale, edef))
			events_summary = ", ".join(event_names)
		_atmosphere_label.text = GardenLocalization.format_key(
			"ui.garden.atmosphere",
			[time_name, weather_name, events_summary],
			_locale
		)

	if _background_rect != null:
		_background_rect.color = _compute_atmosphere_background_color(time_period, weather_state)
	if _audio_controller != null:
		_audio_controller.set_paused(false)
		_audio_controller.update_atmosphere(time_period, weather_state)

	if _environment_label != null:
		_environment_label.visible = true
		var active_traits: Array[String] = _last_snapshot.get_active_traits()
		if active_traits.is_empty():
			_environment_label.text = GardenLocalization.translate("ui.garden.environment_empty", _locale)
		else:
			var trait_parts: PackedStringArray = PackedStringArray()
			for trait_id: String in active_traits:
				var trait_name: String = GardenLocalization.get_trait_name(trait_id, _locale)
				var count: int = _last_snapshot.get_trait_count(trait_id)
				trait_parts.append("%s (%d)" % [trait_name, count])
			_environment_label.text = GardenLocalization.format_key("ui.garden.environment_traits", [", ".join(trait_parts)], _locale)

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
			var vdef: VisitorDefinition = _catalog.get_visitor(_current_visitor_id) if _catalog != null else null
			var visitor_name: String = GardenLocalization.get_visitor_name(_current_visitor_id, _locale, vdef)
			_visitor_status_label.text = GardenLocalization.format_key(
				"ui.garden.visitor_active",
				[visitor_name, _current_visitor_id],
				_locale
			)
		elif not _eligible_visitor_ids.is_empty():
			var names: PackedStringArray = PackedStringArray()
			for vid: String in _eligible_visitor_ids:
				var vdef: VisitorDefinition = _catalog.get_visitor(vid) if _catalog != null else null
				names.append(GardenLocalization.get_visitor_name(vid, _locale, vdef))
			_visitor_status_label.text = GardenLocalization.format_key("ui.garden.visitor_possible", [", ".join(names)], _locale)
		else:
			_visitor_status_label.text = GardenLocalization.translate("ui.garden.visitor_none", _locale)

	if _decoration_row != null:
		_decoration_row.visible = true
	if _decorate_button != null:
		_decorate_button.disabled = _is_blocked or _session == null
	if _decoration_status_label != null:
		var total_decor: int = _last_snapshot.get_total_decoration_count()
		if total_decor <= 0:
			_decoration_status_label.text = GardenLocalization.translate("ui.garden.decorations_status_empty", _locale)
		else:
			var decor_parts: PackedStringArray = PackedStringArray()
			for decor_id: String in _last_snapshot.get_present_decoration_definition_ids():
				var ddef: DecorationDefinition = _catalog.get_decoration(decor_id) if _catalog != null else null
				var decor_name: String = GardenLocalization.get_decoration_name(decor_id, _locale, ddef)
				var d_count: int = _last_snapshot.get_decoration_count_for_definition(decor_id)
				decor_parts.append("%s (%d)" % [decor_name, d_count])
			_decoration_status_label.text = GardenLocalization.format_key(
				"ui.garden.decorations_status",
				[total_decor, ", ".join(decor_parts)],
				_locale
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
		_journal_panel.bind_journal(journal, _catalog, decorations, _last_snapshot, _locale)

	if _journal_row != null:
		_journal_row.visible = true
	if _journal_button != null:
		_journal_button.disabled = _is_blocked or _session == null

	if _journal_status_label != null:
		if _catalog == null:
			_journal_status_label.text = GardenLocalization.translate("ui.garden.journal_status_empty", _locale)
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
		_journal_status_label.text = GardenLocalization.format_key(
			"ui.garden.journal_status",
			[disc_total, total_entries, disc_plants, total_plants, disc_visitors, total_visitors],
			_locale
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


## Pure query for testing: returns the embedded GardenDiorama instance.
func get_garden_diorama() -> GardenDiorama:
	_resolve_nodes()
	return _garden_diorama


func _update_garden_diorama(now_utc: int) -> void:
	_resolve_nodes()
	if _garden_diorama == null or _session == null or _session.get_state() == null:
		return
	_garden_diorama.render_garden(
		_session.get_state(),
		_catalog,
		now_utc,
		_last_snapshot,
		_current_visitor_id,
		_selected_runtime_instance_id,
		_selected_decoration_instance_id,
		_active_zone_id,
		_locale,
		_target_zone_id,
		_target_grid_x,
		_target_grid_y,
		_is_move_mode,
		_current_event_id
	)


func _sync_diorama_placement_highlight() -> void:
	_resolve_nodes()
	if _garden_diorama != null:
		_garden_diorama.set_placement_highlight(
			_target_zone_id,
			_target_grid_x,
			_target_grid_y,
			_is_move_mode,
			_active_zone_id
		)


func _trigger_diorama_puff_for_plant(plant: PlantState) -> void:
	_resolve_nodes()
	if _garden_diorama != null and plant != null:
		_garden_diorama.play_feedback_puff_at_cell(
			plant.get_zone_id(),
			plant.get_grid_x(),
			plant.get_grid_y()
		)


func _trigger_diorama_puff_for_decoration(decor: DecorationState) -> void:
	_resolve_nodes()
	if _garden_diorama != null and decor != null:
		_garden_diorama.play_feedback_puff_at_cell(
			decor.get_zone_id(),
			decor.get_grid_x(),
			decor.get_grid_y()
		)


func _sync_picker_placement_contexts() -> void:
	var state: GameState = _session.get_state() if _session != null else null
	var journal: JournalState = state.get_journal() if state != null else null
	var currency: int = _session.get_currency() if _session != null else 0
	var unlocked_zones: Array[String] = GardenZone.get_unlocked_zone_ids(_last_snapshot, journal)
	var has_free_slot: bool = true
	if state != null:
		var free_cell: Dictionary = GardenPlacement.find_first_free_cell(state, unlocked_zones, _active_zone_id)
		has_free_slot = free_cell.get("found", false) as bool
	var target_zone: String = ""
	var target_x: int = -1
	var target_y: int = -1
	if (
		not _target_zone_id.is_empty()
		and GardenZone.is_within_bounds(_target_zone_id, _target_grid_x, _target_grid_y)
		and GardenZone.is_zone_unlocked(_target_zone_id, _last_snapshot, journal)
	):
		target_zone = _target_zone_id
		target_x = _target_grid_x
		target_y = _target_grid_y
	if _planting_picker != null:
		_planting_picker.update_garden_context(_last_snapshot, journal, target_zone, target_x, target_y, has_free_slot)
	if _decoration_picker != null:
		_decoration_picker.update_shop_context(currency, _last_snapshot, target_zone, target_x, target_y, has_free_slot)


func _on_diorama_item_selected(item_kind: String, runtime_instance_id: String) -> void:
	if runtime_instance_id.is_empty():
		return
	_is_move_mode = false
	_target_zone_id = ""
	_target_grid_x = -1
	_target_grid_y = -1
	var item_zone_id: String = ""
	if _session != null and _session.get_state() != null:
		var state: GameState = _session.get_state()
		if item_kind == "plant" and state.get_plants() != null:
			var plant_state: PlantState = state.get_plants().get_plant(runtime_instance_id)
			if plant_state != null:
				item_zone_id = plant_state.get_zone_id()
		elif item_kind == "decoration" and state.get_decorations() != null:
			var decor_state: DecorationState = state.get_decorations().get_decoration(runtime_instance_id)
			if decor_state != null:
				item_zone_id = decor_state.get_zone_id()
		if (
			not item_zone_id.is_empty()
			and GardenZone.is_valid_zone_id(item_zone_id)
			and GardenZone.is_zone_unlocked(item_zone_id, _last_snapshot, state.get_journal())
		):
			_active_zone_id = item_zone_id
	if item_kind == "plant":
		_on_plant_selected(runtime_instance_id)
	elif item_kind == "decoration":
		_on_decoration_selected(runtime_instance_id)
	_render_zone_grid()
	_sync_diorama_placement_highlight()
	_sync_picker_placement_contexts()
	_sync_back_navigation_state()


func _on_diorama_visitor_selected(_visitor_id: String) -> void:
	_on_observe_visitor_button_pressed()


func _format_selected_event_feedback(event_id: String) -> String:
	var edef: EventDefinition = _catalog.get_event(event_id) if _catalog != null else null
	var ename: String = GardenLocalization.get_event_name(event_id, _locale, edef)
	var edesc: String = GardenLocalization.get_event_description(event_id, _locale, edef)
	if not edesc.is_empty():
		return GardenLocalization.format_key("ui.feedback.event_selected_desc", [ename, event_id, edesc], _locale)
	return GardenLocalization.format_key("ui.feedback.event_selected", [ename, event_id], _locale)


func _on_diorama_event_selected(event_id: String) -> void:
	if _is_blocked or event_id.is_empty():
		return
	_resolve_nodes()
	_current_event_id = event_id
	_last_tapped_event_id = event_id
	if _feedback_area != null and _feedback_label != null:
		_active_feedback_kind = "event_tap"
		_feedback_area.visible = true
		_feedback_label.text = _format_selected_event_feedback(event_id)
	_play_sfx("ui_tap")


func _on_picker_planting_requested(definition_id: String) -> void:
	_sync_back_navigation_state()
	if not _target_zone_id.is_empty() and _target_grid_x >= 0 and _target_grid_y >= 0:
		var z_id: String = _target_zone_id
		var gx: int = _target_grid_x
		var gy: int = _target_grid_y
		_target_zone_id = ""
		_target_grid_x = -1
		_target_grid_y = -1
		_sync_picker_placement_contexts()
		planting_at_requested.emit(definition_id, z_id, gx, gy)
	else:
		planting_requested.emit(definition_id)


## Opens the planting picker modal.
func open_planting_picker() -> void:
	if _is_blocked or _session == null:
		return
	_resolve_nodes()
	if _is_move_mode:
		_set_move_mode(false)
	_sync_picker_placement_contexts()
	_play_sfx("ui_tap")
	if _planting_picker != null:
		_planting_picker.open_picker()
	_sync_back_navigation_state()


## Closes the planting picker modal.
func close_planting_picker() -> void:
	_resolve_nodes()
	if _planting_picker != null:
		_planting_picker.close_picker()
	_sync_back_navigation_state()


## Displays user feedback from a PlantingCheckpointResult.
func show_planting_result(result: PlantingCheckpointResult) -> void:
	_last_checkpoint_result = result
	_resolve_nodes()
	if _feedback_area == null or _feedback_label == null or result == null:
		return

	_active_feedback_kind = "planting"
	_feedback_area.visible = true
	match result.get_status():
		PlantingCheckpointResult.Status.NOT_READY:
			_feedback_label.text = GardenLocalization.translate("ui.feedback.planting_not_ready", _locale)
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
					PlantRegistrationResult.INVALID_PLACEMENT:
						reason_str = "INVALID_PLACEMENT"
					PlantRegistrationResult.ZONE_LOCKED:
						reason_str = "ZONE_LOCKED"
					PlantRegistrationResult.CELL_OCCUPIED:
						reason_str = "CELL_OCCUPIED"
					PlantRegistrationResult.GARDEN_FULL:
						reason_str = "GARDEN_FULL"
					_:
						reason_str = "UNKNOWN"
			if not reason_str.is_empty():
				_feedback_label.text = GardenLocalization.format_key("ui.feedback.planting_rejected_reason", [reason_str], _locale)
			else:
				_feedback_label.text = GardenLocalization.translate("ui.feedback.planting_rejected", _locale)
		PlantingCheckpointResult.Status.REGISTERED_SAVED:
			_feedback_label.text = GardenLocalization.translate("ui.feedback.planting_saved", _locale)
			if not _suppress_feedback_effects:
				_trigger_diorama_puff_for_plant(result.get_plant())
				_play_sfx("plant")
		PlantingCheckpointResult.Status.REGISTERED_SAVE_FAILED:
			_feedback_label.text = GardenLocalization.translate("ui.feedback.planting_save_failed", _locale)
			if not _suppress_feedback_effects:
				_trigger_diorama_puff_for_plant(result.get_plant())
				_play_sfx("plant")
		_:
			_feedback_label.text = GardenLocalization.translate("ui.feedback.planting_unknown", _locale)


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
	if _is_move_mode:
		_set_move_mode(false)
	harvest_requested.emit(_selected_runtime_instance_id)


## Displays user feedback from a HarvestCheckpointResult.
func show_harvest_result(result: HarvestCheckpointResult) -> void:
	_last_harvest_checkpoint_result = result
	_resolve_nodes()
	if _feedback_area == null or _feedback_label == null or result == null:
		return

	_active_feedback_kind = "harvest"
	_feedback_area.visible = true
	match result.get_status():
		HarvestCheckpointResult.Status.NOT_READY:
			_feedback_label.text = GardenLocalization.translate("ui.feedback.harvest_not_ready", _locale)
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
				_feedback_label.text = GardenLocalization.format_key("ui.feedback.harvest_rejected_reason", [reason_str], _locale)
			else:
				_feedback_label.text = GardenLocalization.translate("ui.feedback.harvest_rejected", _locale)
		HarvestCheckpointResult.Status.HARVESTED_SAVED:
			_feedback_label.text = GardenLocalization.format_key("ui.feedback.harvest_saved", [result.get_reward_granted()], _locale)
			if not _suppress_feedback_effects:
				_trigger_diorama_puff_for_plant(result.get_plant())
				_play_sfx("harvest")
		HarvestCheckpointResult.Status.HARVESTED_SAVE_FAILED:
			_feedback_label.text = GardenLocalization.format_key("ui.feedback.harvest_save_failed", [result.get_reward_granted()], _locale)
			if not _suppress_feedback_effects:
				_trigger_diorama_puff_for_plant(result.get_plant())
				_play_sfx("harvest")
		_:
			_feedback_label.text = GardenLocalization.translate("ui.feedback.harvest_unknown", _locale)


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

	_active_feedback_kind = "visitor"
	if _feedback_area != null and _feedback_label != null:
		_feedback_area.visible = true
		match result.get_status():
			VisitorSelectionResult.Status.SELECTED:
				var vid: String = result.get_selected_visitor_id()
				_current_visitor_id = vid
				var vdef: VisitorDefinition = _catalog.get_visitor(vid) if _catalog != null else null
				var vname: String = GardenLocalization.get_visitor_name(vid, _locale, vdef)
				_feedback_label.text = GardenLocalization.format_key("ui.feedback.visitor_observed", [vname, vid], _locale)
				if _visitor_status_label != null:
					_visitor_status_label.text = GardenLocalization.format_key("ui.garden.visitor_active", [vname, vid], _locale)
			VisitorSelectionResult.Status.NO_ELIGIBLE_VISITORS:
				_current_visitor_id = ""
				_feedback_label.text = GardenLocalization.translate("ui.feedback.visitor_none_eligible", _locale)
			VisitorSelectionResult.Status.INVALID_INPUT, VisitorSelectionResult.Status.SELECTION_FAILED:
				_feedback_label.text = GardenLocalization.translate("ui.feedback.visitor_not_ready", _locale)
			_:
				_feedback_label.text = GardenLocalization.translate("ui.feedback.visitor_unknown", _locale)
	if not _suppress_feedback_effects:
		_update_garden_diorama(_game_clock.utc_now_seconds() if _game_clock != null else _last_refresh_utc_seconds)


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

	_active_feedback_kind = "visitor_obs"
	_last_visitor_selection_result = result.get_selection_result()
	if _feedback_area != null and _feedback_label != null:
		_feedback_area.visible = true
		match result.get_status():
			VisitorObservationCheckpointResult.Status.OBSERVED_SAVED:
				var vid: String = result.get_selected_visitor_id()
				_current_visitor_id = vid
				var vdef: VisitorDefinition = _catalog.get_visitor(vid) if _catalog != null else null
				var vname: String = GardenLocalization.get_visitor_name(vid, _locale, vdef)
				if result.is_first_discovery():
					_feedback_label.text = GardenLocalization.format_key("ui.feedback.visitor_observed_first", [vname, vid], _locale)
				else:
					_feedback_label.text = GardenLocalization.format_key("ui.feedback.visitor_observed_saved", [vname, vid], _locale)
				if _visitor_status_label != null:
					_visitor_status_label.text = GardenLocalization.format_key("ui.garden.visitor_active", [vname, vid], _locale)
				if not _suppress_feedback_effects:
					_play_sfx("discover")
			VisitorObservationCheckpointResult.Status.OBSERVED_SAVE_FAILED:
				var vid_fail: String = result.get_selected_visitor_id()
				_current_visitor_id = vid_fail
				var vdef_fail: VisitorDefinition = _catalog.get_visitor(vid_fail) if _catalog != null else null
				var vname_fail: String = GardenLocalization.get_visitor_name(vid_fail, _locale, vdef_fail)
				_feedback_label.text = GardenLocalization.format_key("ui.feedback.visitor_observed_save_failed", [vname_fail, vid_fail], _locale)
				if _visitor_status_label != null:
					_visitor_status_label.text = GardenLocalization.format_key("ui.garden.visitor_active", [vname_fail, vid_fail], _locale)
				if not _suppress_feedback_effects:
					_play_sfx("discover")
			VisitorObservationCheckpointResult.Status.NO_ELIGIBLE_VISITORS:
				_current_visitor_id = ""
				_feedback_label.text = GardenLocalization.translate("ui.feedback.visitor_none_eligible", _locale)
			VisitorObservationCheckpointResult.Status.NOT_READY, VisitorObservationCheckpointResult.Status.OBSERVATION_REJECTED:
				_feedback_label.text = GardenLocalization.translate("ui.feedback.visitor_not_ready", _locale)
			_:
				_feedback_label.text = GardenLocalization.translate("ui.feedback.visitor_unknown", _locale)
	if not _suppress_feedback_effects:
		_update_garden_diorama(_game_clock.utc_now_seconds() if _game_clock != null else _last_refresh_utc_seconds)


## Opens the journal modal panel.
func open_journal_panel() -> void:
	if _is_blocked or _session == null:
		return
	_resolve_nodes()
	_play_sfx("ui_tap")
	if _journal_panel != null:
		_journal_panel.open_journal()
	_sync_back_navigation_state()


## Closes the journal modal panel.
func close_journal_panel() -> void:
	_resolve_nodes()
	if _journal_panel != null:
		_journal_panel.close_journal()
	_sync_back_navigation_state()


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
	_sync_back_navigation_state()
	if not _target_zone_id.is_empty() and _target_grid_x >= 0 and _target_grid_y >= 0:
		var z_id: String = _target_zone_id
		var gx: int = _target_grid_x
		var gy: int = _target_grid_y
		_target_zone_id = ""
		_target_grid_x = -1
		_target_grid_y = -1
		_sync_picker_placement_contexts()
		decoration_purchase_at_requested.emit(definition_id, z_id, gx, gy)
	else:
		decoration_purchase_requested.emit(definition_id)


## Opens the decoration picker modal.
func open_decoration_picker() -> void:
	if _is_blocked or _session == null:
		return
	_resolve_nodes()
	if _is_move_mode:
		_set_move_mode(false)
	_sync_picker_placement_contexts()
	_play_sfx("ui_tap")
	if _decoration_picker != null:
		_decoration_picker.open_picker()
	_sync_back_navigation_state()


## Closes the decoration picker modal.
func close_decoration_picker() -> void:
	_resolve_nodes()
	if _decoration_picker != null:
		_decoration_picker.close_picker()
	_sync_back_navigation_state()


## Displays user feedback from a DecorationPurchaseCheckpointResult.
func show_decoration_purchase_result(result: DecorationPurchaseCheckpointResult) -> void:
	_last_decoration_purchase_checkpoint_result = result
	_resolve_nodes()
	if _feedback_area == null or _feedback_label == null or result == null:
		return

	_active_feedback_kind = "decoration"
	_feedback_area.visible = true
	match result.get_status():
		DecorationPurchaseCheckpointResult.Status.NOT_READY:
			_feedback_label.text = GardenLocalization.translate("ui.feedback.decoration_not_ready", _locale)
		DecorationPurchaseCheckpointResult.Status.PURCHASE_REJECTED:
			var reason_str: String = ""
			var purchase_res: DecorationPurchaseResult = result.get_purchase_result()
			if purchase_res != null:
				match purchase_res.get_status():
					DecorationPurchaseResult.INSUFFICIENT_CURRENCY:
						_feedback_label.text = GardenLocalization.translate("ui.feedback.decoration_insufficient_currency", _locale)
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
					DecorationPurchaseResult.INVALID_PLACEMENT:
						reason_str = "INVALID_PLACEMENT"
					DecorationPurchaseResult.ZONE_LOCKED:
						reason_str = "ZONE_LOCKED"
					DecorationPurchaseResult.CELL_OCCUPIED:
						reason_str = "CELL_OCCUPIED"
					DecorationPurchaseResult.GARDEN_FULL:
						reason_str = "GARDEN_FULL"
					_:
						reason_str = "UNKNOWN"
			if not reason_str.is_empty():
				_feedback_label.text = GardenLocalization.format_key("ui.feedback.decoration_rejected_reason", [reason_str], _locale)
			else:
				_feedback_label.text = GardenLocalization.translate("ui.feedback.decoration_rejected", _locale)
		DecorationPurchaseCheckpointResult.Status.PURCHASED_SAVED:
			_feedback_label.text = GardenLocalization.format_key("ui.feedback.decoration_saved", [result.get_price_spent()], _locale)
			if not _suppress_feedback_effects:
				_trigger_diorama_puff_for_decoration(result.get_decoration())
				_play_sfx("place_decor")
		DecorationPurchaseCheckpointResult.Status.PURCHASED_SAVE_FAILED:
			_feedback_label.text = GardenLocalization.format_key("ui.feedback.decoration_save_failed", [result.get_price_spent()], _locale)
			if not _suppress_feedback_effects:
				_trigger_diorama_puff_for_decoration(result.get_decoration())
				_play_sfx("place_decor")
		_:
			_feedback_label.text = GardenLocalization.translate("ui.feedback.decoration_unknown", _locale)


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


## Pure query for testing: returns the DailyGuidanceLabel node.
func get_daily_guidance_label() -> Label:
	_resolve_nodes()
	return _daily_guidance_label


## Pure query for testing: returns daily guidance HUD summary text.
func get_daily_guidance_text() -> String:
	_resolve_nodes()
	return _daily_guidance_label.text if _daily_guidance_label != null else ""


## Pure query for testing: returns true if daily guidance items are present in latest progression summary.
func has_daily_guidance() -> bool:
	return not _is_blocked and _last_progression_summary != null and _last_progression_summary.has_daily_guidance()


## Pure query for testing: returns count of daily guidance items.
func get_daily_guidance_count() -> int:
	return _last_progression_summary.get_daily_guidance_count() if _last_progression_summary != null else 0


## Pure query for testing: returns array of canonical IDs for daily guidance items.
func get_daily_guidance_ids() -> Array[String]:
	return _last_progression_summary.get_daily_guidance_ids() if _last_progression_summary != null else []


## Pure query for testing: returns array of localized display texts for daily guidance items.
func get_daily_guidance_display_texts() -> Array[String]:
	if _last_progression_summary == null:
		return []
	var texts: Array[String] = []
	for item: DailyGuidanceItem in _last_progression_summary.get_daily_guidance_items():
		texts.append(item.get_display_text())
	return texts


## Pure query for testing: returns typed DailyGuidanceItem at [param index], or null if invalid.
func get_daily_guidance_item(index: int) -> DailyGuidanceItem:
	if _last_progression_summary == null:
		return null
	var items: Array[DailyGuidanceItem] = _last_progression_summary.get_daily_guidance_items()
	if index < 0 or index >= items.size():
		return null
	return items[index]


## Pure query for testing: returns the FtueLabel node.
func get_ftue_label() -> Label:
	_resolve_nodes()
	return _ftue_label


## Pure query for testing: returns FTUE HUD banner text.
func get_ftue_text() -> String:
	_resolve_nodes()
	return _ftue_label.text if _ftue_label != null else ""


## Pure query for testing: returns true if an FTUE step is attached in latest progression summary.
func has_ftue_step() -> bool:
	return not _is_blocked and _last_progression_summary != null and _last_progression_summary.has_ftue_step()


## Pure query for testing: returns true if FTUE sequence is actively guiding the player.
func is_ftue_active() -> bool:
	return not _is_blocked and _last_progression_summary != null and _last_progression_summary.is_ftue_active()


## Pure query for testing: returns true if FTUE sequence has reached completion.
func is_ftue_completed() -> bool:
	return not _is_blocked and _last_progression_summary != null and _last_progression_summary.is_ftue_completed()


## Pure query for testing: returns canonical FTUE step ID.
func get_ftue_step_id() -> String:
	return _last_progression_summary.get_ftue_step_id() if _last_progression_summary != null else ""


## Pure query for testing: returns zero-based FTUE step index (0..6), or -1 if invalid.
func get_ftue_step_index() -> int:
	return _last_progression_summary.get_ftue_step_index() if _last_progression_summary != null else -1


## Pure query for testing: returns localized FTUE step title.
func get_ftue_title() -> String:
	return _last_progression_summary.get_ftue_title() if _last_progression_summary != null else ""


## Pure query for testing: returns localized FTUE step action instruction.
func get_ftue_instruction() -> String:
	return _last_progression_summary.get_ftue_instruction() if _last_progression_summary != null else ""


## Pure query for testing: returns the DiscoveryPacingLabel node.
func get_discovery_pacing_label() -> Label:
	_resolve_nodes()
	return _discovery_pacing_label


## Pure query for testing: returns discovery pacing HUD banner text.
func get_discovery_pacing_text() -> String:
	_resolve_nodes()
	return _discovery_pacing_label.text if _discovery_pacing_label != null else ""


## Pure query for testing: returns true if a discovery pacing milestone is attached in latest progression summary.
func has_discovery_pacing_milestone() -> bool:
	return not _is_blocked and _last_progression_summary != null and _last_progression_summary.has_discovery_pacing_milestone()


## Pure query for testing: returns canonical discovery pacing milestone ID.
func get_discovery_pacing_milestone_id() -> String:
	return _last_progression_summary.get_discovery_pacing_milestone_id() if _last_progression_summary != null else ""


## Pure query for testing: returns 1-based day index (1..7), or -1 if invalid.
func get_discovery_pacing_day_index() -> int:
	return _last_progression_summary.get_discovery_pacing_day_index() if _last_progression_summary != null else -1


## Pure query for testing: returns short theme key of active discovery pacing milestone.
func get_discovery_pacing_theme() -> String:
	return _last_progression_summary.get_discovery_pacing_theme() if _last_progression_summary != null else ""


## Pure query for testing: returns localized discovery pacing milestone title.
func get_discovery_pacing_title() -> String:
	return _last_progression_summary.get_discovery_pacing_title() if _last_progression_summary != null else ""


## Pure query for testing: returns localized discovery pacing milestone description.
func get_discovery_pacing_description() -> String:
	return _last_progression_summary.get_discovery_pacing_description() if _last_progression_summary != null else ""


## Pure query for testing: returns localized discovery pacing recommended focus.
func get_discovery_pacing_recommended_focus() -> String:
	return _last_progression_summary.get_discovery_pacing_recommended_focus() if _last_progression_summary != null else ""


## Pure query for testing: returns true if active discovery pacing milestone has been achieved.
func is_discovery_pacing_achieved() -> bool:
	return not _is_blocked and _last_progression_summary != null and _last_progression_summary.is_discovery_pacing_achieved()


## Displays calm, non-intrusive feedback summarizing away/offline changes from a GardenReturnSummary.
func show_return_summary(summary: GardenReturnSummary) -> void:
	_last_return_summary = summary
	_resolve_nodes()
	if _feedback_area == null or _feedback_label == null or summary == null:
		return

	if not summary.has_meaningful_changes():
		return

	_active_feedback_kind = "return"
	_feedback_area.visible = true
	if summary.has_plant_growth_changes():
		var grown_count: int = summary.get_advanced_plant_count()
		var newly_mature_count: int = summary.get_newly_matured_plant_count()
		if newly_mature_count > 0:
			_feedback_label.text = GardenLocalization.format_key(
				"ui.feedback.return_plants_ready",
				[grown_count, summary.get_ready_to_harvest_count()],
				_locale
			)
		else:
			_feedback_label.text = GardenLocalization.format_key(
				"ui.feedback.return_plants_grew",
				[grown_count],
				_locale
			)
	else:
		var time_name: String = GardenLocalization.get_time_period_name(summary.get_current_time_period(), _locale)
		var weather_name: String = GardenLocalization.get_weather_name(summary.get_current_weather_state(), _locale)
		_feedback_label.text = GardenLocalization.format_key(
			"ui.feedback.return_atmosphere",
			[time_name, weather_name],
			_locale
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


## Displays calm user feedback and ephemeral active event state from an EventSelectionResult.
func show_event_result(result: EventSelectionResult) -> void:
	_last_event_selection_result = result
	_resolve_nodes()
	if result == null:
		return

	_active_feedback_kind = "event"
	if _feedback_area != null and _feedback_label != null:
		_feedback_area.visible = true
		match result.get_status():
			EventSelectionResult.Status.SELECTED:
				var eid: String = result.get_selected_event_id()
				_current_event_id = eid
				_last_tapped_event_id = ""
				_feedback_label.text = _format_selected_event_feedback(eid)
				if not _suppress_feedback_effects:
					_play_sfx("discover")
			EventSelectionResult.Status.NO_ELIGIBLE_EVENTS:
				_current_event_id = ""
				_feedback_label.text = GardenLocalization.translate("ui.feedback.event_none_eligible", _locale)
			EventSelectionResult.Status.INVALID_INPUT, EventSelectionResult.Status.SELECTION_FAILED:
				_feedback_label.text = GardenLocalization.translate("ui.feedback.event_not_ready", _locale)
			_:
				_feedback_label.text = GardenLocalization.translate("ui.feedback.event_unknown", _locale)
	if not _suppress_feedback_effects:
		_update_garden_diorama(_game_clock.utc_now_seconds() if _game_clock != null else _last_refresh_utc_seconds)


func _refresh_active_feedback_locale() -> void:
	if _feedback_area == null or not _feedback_area.visible:
		return
	_suppress_feedback_effects = true
	match _active_feedback_kind:
		"planting":
			if _last_checkpoint_result != null:
				show_planting_result(_last_checkpoint_result)
		"harvest":
			if _last_harvest_checkpoint_result != null:
				show_harvest_result(_last_harvest_checkpoint_result)
		"visitor":
			if _last_visitor_selection_result != null:
				show_visitor_result(_last_visitor_selection_result)
		"visitor_obs":
			if _last_visitor_observation_checkpoint_result != null:
				show_visitor_observation_result(_last_visitor_observation_checkpoint_result)
		"decoration":
			if _last_decoration_purchase_checkpoint_result != null:
				show_decoration_purchase_result(_last_decoration_purchase_checkpoint_result)
		"event":
			if _last_event_selection_result != null:
				show_event_result(_last_event_selection_result)
		"event_tap":
			if not _last_tapped_event_id.is_empty():
				_feedback_label.text = _format_selected_event_feedback(_last_tapped_event_id)
		"move":
			if _last_move_checkpoint_result != null:
				show_move_result(_last_move_checkpoint_result)
		"return":
			if _last_return_summary != null:
				show_return_summary(_last_return_summary)
	_suppress_feedback_effects = false


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


## Pure query for testing: returns the localized display name for the currently selected plant, or "" if none selected or blocked.
func get_selected_plant_display_name() -> String:
	if _is_blocked or _selected_runtime_instance_id.is_empty() or _selected_plant_definition_id.is_empty():
		return ""
	var pdef: PlantDefinition = _catalog.get_plant(_selected_plant_definition_id) if _catalog != null else null
	return GardenLocalization.get_plant_name(_selected_plant_definition_id, _locale, pdef)


## Pure query for testing: returns the localized display name for the current active visitor in the garden HUD, or "" if none active or blocked.
func get_current_visitor_display_name() -> String:
	if _is_blocked or _current_visitor_id.is_empty():
		return ""
	var vdef: VisitorDefinition = _catalog.get_visitor(_current_visitor_id) if _catalog != null else null
	return GardenLocalization.get_visitor_name(_current_visitor_id, _locale, vdef)


## Pure query for testing: returns the localized display name for the current active ambient/special event in the garden HUD, or "" if none active or blocked.
func get_current_event_display_name() -> String:
	if _is_blocked or _current_event_id.is_empty():
		return ""
	var edef: EventDefinition = _catalog.get_event(_current_event_id) if _catalog != null else null
	return GardenLocalization.get_event_name(_current_event_id, _locale, edef)


## Pure query for testing: returns the localized description for the current active ambient/special event in the garden HUD, or "" if none active or blocked.
func get_current_event_description() -> String:
	if _is_blocked or _current_event_id.is_empty():
		return ""
	var edef: EventDefinition = _catalog.get_event(_current_event_id) if _catalog != null else null
	return GardenLocalization.get_event_description(_current_event_id, _locale, edef)


## Pure query for testing: returns the localized display name for the current time period from the latest snapshot, or "" if blocked/unavailable.
func get_current_time_period_display_name() -> String:
	var tp: String = get_current_time_period()
	if _is_blocked or tp.is_empty():
		return ""
	return GardenLocalization.get_time_period_name(tp, _locale)


## Pure query for testing: returns the localized display name for the current weather state from the latest snapshot, or "" if blocked/unavailable.
func get_current_weather_display_name() -> String:
	var ws: String = get_current_weather_state()
	if _is_blocked or ws.is_empty():
		return ""
	return GardenLocalization.get_weather_name(ws, _locale)


## Pure query for testing: returns the localized display name for the next time period from the latest refresh, or "" if blocked/unavailable.
func get_next_time_period_display_name() -> String:
	if _is_blocked or _next_time_period.is_empty():
		return ""
	return GardenLocalization.get_time_period_name(_next_time_period, _locale)


## Pure query for testing: returns the localized display name for the next weather state from the latest refresh, or "" if blocked/unavailable.
func get_next_weather_display_name() -> String:
	if _is_blocked or _next_weather_state.is_empty():
		return ""
	return GardenLocalization.get_weather_name(_next_weather_state, _locale)


## Pure query for testing: returns the localized display name for the current progression stage from the latest refresh, or "" if blocked/unavailable.
func get_current_progression_stage_display_name() -> String:
	var st_id: String = get_current_progression_stage_id()
	if _is_blocked or st_id.is_empty():
		return ""
	return GardenLocalization.get_progression_stage_name(st_id, _locale)


## Pure query for testing: returns the localized display name for the next progression stage from the latest refresh, or "" if at max stage or blocked/unavailable.
func get_next_progression_stage_display_name() -> String:
	var next_id: String = get_next_progression_stage_id()
	if _is_blocked or next_id.is_empty():
		return ""
	return GardenLocalization.get_progression_stage_name(next_id, _locale)


## Pure query for testing: returns the localized display name for the current optional gentle guidance prompt from the latest refresh, or "" if blocked/unavailable.
func get_current_guidance_display_name() -> String:
	var gid: String = get_current_guidance_id()
	if _is_blocked or gid.is_empty():
		return ""
	return GardenLocalization.get_guidance_text(gid, _locale)


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


## Pure query for testing: returns localized display name for [param trait_id], or "" if empty.
func get_trait_display_name_for_id(trait_id: String) -> String:
	return GardenLocalization.get_trait_name(trait_id, _locale)


## Pure query for testing: returns localized display name for [param visitor_id], or "" if empty.
func get_visitor_display_name_for_id(visitor_id: String) -> String:
	var vdef: VisitorDefinition = _catalog.get_visitor(visitor_id) if _catalog != null else null
	return GardenLocalization.get_visitor_name(visitor_id, _locale, vdef)


## Pure query for testing: returns localized display name for [param event_id], or "" if empty.
func get_event_display_name_for_id(event_id: String) -> String:
	var edef: EventDefinition = _catalog.get_event(event_id) if _catalog != null else null
	return GardenLocalization.get_event_name(event_id, _locale, edef)


## Pure query for testing: returns localized description for [param event_id], or "" if empty/unknown.
func get_event_description_for_id(event_id: String) -> String:
	var edef: EventDefinition = _catalog.get_event(event_id) if _catalog != null else null
	return GardenLocalization.get_event_description(event_id, _locale, edef)


## Pure query for testing: returns localized display name for [param time_period], or "" if empty.
func get_time_period_display_name_for_id(time_period: String) -> String:
	return GardenLocalization.get_time_period_name(time_period, _locale)


## Pure query for testing: returns localized display name for [param weather_state], or "" if empty.
func get_weather_display_name_for_id(weather_state: String) -> String:
	return GardenLocalization.get_weather_name(weather_state, _locale)


## Pure query for testing: returns localized display name for [param stage_id], or "" if empty.
func get_progression_stage_display_name_for_id(stage_id: String) -> String:
	return GardenLocalization.get_progression_stage_name(stage_id, _locale)


## Pure query for testing: returns localized display name for [param guidance_id], or "" if empty.
func get_guidance_display_name_for_id(guidance_id: String) -> String:
	return GardenLocalization.get_guidance_text(guidance_id, _locale)


## Pure query for testing: returns localized display names for all active environmental traits in the latest snapshot, or [] if blocked/empty.
func get_active_environmental_trait_display_names() -> Array[String]:
	if _is_blocked or _last_snapshot == null:
		return []
	var result: Array[String] = []
	for trait_id: String in _last_snapshot.get_active_traits():
		result.append(GardenLocalization.get_trait_name(trait_id, _locale))
	return result


## Pure query for testing: returns localized display names for environmental traits on the currently selected plant, or [] if none selected or blocked.
func get_selected_plant_trait_display_names() -> Array[String]:
	if _is_blocked or _selected_runtime_instance_id.is_empty():
		return []
	var result: Array[String] = []
	for trait_id: String in _selected_plant_traits:
		result.append(GardenLocalization.get_trait_name(trait_id, _locale))
	return result


## Pure query for testing: returns localized display names for eligible visitors from the latest refresh, or [] if blocked/empty.
func get_eligible_visitor_display_names() -> Array[String]:
	if _is_blocked:
		return []
	var result: Array[String] = []
	for vid: String in _eligible_visitor_ids:
		result.append(get_visitor_display_name_for_id(vid))
	return result


## Pure query for testing: returns localized display names for eligible ambient/special events from the latest refresh, or [] if blocked/empty.
func get_eligible_event_display_names() -> Array[String]:
	if _is_blocked:
		return []
	var result: Array[String] = []
	for eid: String in _eligible_event_ids:
		result.append(get_event_display_name_for_id(eid))
	return result


## Pure query for testing: returns localized display names for distinct planted plant species in the latest snapshot, or [] if blocked/empty.
func get_present_plant_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_present_plant_definition_ids():
		result.append(get_plant_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized display names for distinct placed decoration species in the latest snapshot, or [] if blocked/empty.
func get_present_decoration_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_present_decoration_definition_ids():
		result.append(get_decoration_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized display name for plant [param definition_id], or "" if empty.
func get_plant_display_name_for_id(definition_id: String) -> String:
	var pdef: PlantDefinition = _catalog.get_plant(definition_id) if _catalog != null else null
	return GardenLocalization.get_plant_name(definition_id, _locale, pdef)


## Pure query for testing: returns localized display name for decoration [param definition_id], or "" if empty.
func get_decoration_display_name_for_id(definition_id: String) -> String:
	var ddef: DecorationDefinition = _catalog.get_decoration(definition_id) if _catalog != null else null
	return GardenLocalization.get_decoration_name(definition_id, _locale, ddef)


## Pure query for testing: returns localized growth stage display name for the currently selected plant, or "" if none selected or blocked.
func get_selected_plant_stage_display_name() -> String:
	if _is_blocked or _selected_runtime_instance_id.is_empty():
		return ""
	return GardenLocalization.get_plant_stage_name(_selected_plant_stage, _locale)


## Pure query for testing: returns true if [param visitor_id] is in the localized visitor catalog.
func is_known_visitor_id(visitor_id: String) -> bool:
	return GardenLocalization.is_known_visitor_id(visitor_id)


## Pure query for testing: returns true if [param event_id] is in the localized event catalog.
func is_known_event_id(event_id: String) -> bool:
	return GardenLocalization.is_known_event_id(event_id)


## Pure query for testing: returns true if [param trait_id] is in the localized trait catalog.
func is_known_environmental_trait(trait_id: String) -> bool:
	return GardenLocalization.is_known_trait_id(trait_id)


## Pure query for testing: returns true if [param time_period] is in the localized time-of-day catalog.
func is_known_time_period_id(time_period: String) -> bool:
	return GardenLocalization.is_known_time_period_id(time_period)


## Pure query for testing: returns true if [param weather_state] is in the localized weather catalog.
func is_known_weather_state_id(weather_state: String) -> bool:
	return GardenLocalization.is_known_weather_state_id(weather_state)


## Pure query for testing: returns true if [param stage_id] is in the localized progression stage catalog.
func is_known_progression_stage_id(stage_id: String) -> bool:
	return GardenLocalization.is_known_progression_stage_id(stage_id)


## Pure query for testing: returns true if [param guidance_id] is in the localized gentle guidance catalog.
func is_known_guidance_id(guidance_id: String) -> bool:
	return GardenLocalization.is_known_guidance_id(guidance_id)


## Pure query for testing: returns true if [param definition_id] is in the localized plant catalog.
func is_known_plant_definition_id(definition_id: String) -> bool:
	return GardenLocalization.is_known_plant_id(definition_id)


## Pure query for testing: returns true if [param definition_id] is in the localized decoration catalog.
func is_known_decoration_definition_id(definition_id: String) -> bool:
	return GardenLocalization.is_known_decoration_id(definition_id)


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


## Pure query for testing: returns all rendered DecorationView items in deterministic runtime instance ID order.
func get_decoration_views() -> Array[DecorationView]:
	_resolve_nodes()
	var views: Array[DecorationView] = []
	if _decorations_container != null:
		for child: Node in _decorations_container.get_children():
			if child is DecorationView:
				views.append(child as DecorationView)
	return views


## Pure query for testing: returns DecorationView with matching runtime instance ID, or null if not found.
func get_decoration_view_by_id(runtime_instance_id: String) -> DecorationView:
	_resolve_nodes()
	if _decorations_container != null:
		for child: Node in _decorations_container.get_children():
			if child is DecorationView and (child as DecorationView).get_runtime_instance_id() == runtime_instance_id:
				return child as DecorationView
	return null


## Pure query for testing: returns count of rendered DecorationView items in the garden workspace.
func get_rendered_decoration_count() -> int:
	return get_decoration_views().size()


## Pure query for testing: returns ephemeral selected decoration runtime instance ID, or "".
func get_selected_decoration_instance_id() -> String:
	return _selected_decoration_instance_id if not _is_blocked else ""


## Pure query for testing: returns true if a placed decoration is currently selected and startup is not blocked.
func has_selected_decoration() -> bool:
	return not _is_blocked and not _selected_decoration_instance_id.is_empty()


## Pure query for testing: returns the selected decoration's definition ID, or "" if none selected or blocked.
func get_selected_decoration_definition_id() -> String:
	return _selected_decoration_definition_id if not _is_blocked else ""


## Pure query for testing: returns environmental traits for the currently selected decoration, or [] if none selected.
func get_selected_decoration_traits() -> Array[String]:
	return _selected_decoration_traits.duplicate() if not _is_blocked else []


## Pure query for testing: returns the selected decoration's purchase price, or 0 if none selected or blocked.
func get_selected_decoration_price() -> int:
	return _selected_decoration_price if not _is_blocked else 0


## Pure query for testing: returns the selected decoration's placed_at UTC timestamp, or -1 if none selected or blocked.
func get_selected_decoration_placed_at() -> int:
	return _selected_decoration_placed_at if not _is_blocked else -1


## Pure query for testing: returns the header label text in DetailsArea.
func get_details_header_text() -> String:
	_resolve_nodes()
	return _details_header_label.text if _details_header_label != null else ""


func _hide_zone_grid() -> void:
	_clear_container_children(_zone_grid_container)
	if _zones_section_label != null:
		_zones_section_label.visible = false
	if _zone_tabs_row != null:
		_zone_tabs_row.visible = false
	if _zone_status_label != null:
		_zone_status_label.visible = false
	if _zone_grid_container != null:
		_zone_grid_container.visible = false


func _render_zone_grid() -> void:
	_resolve_nodes()
	if _is_blocked or _session == null or _session.get_state() == null:
		_hide_zone_grid()
		return

	var state: GameState = _session.get_state()

	var journal: JournalState = state.get_journal()
	var main_unlocked: bool = GardenZone.is_zone_unlocked(GardenZone.ZONE_MAIN, _last_snapshot, journal)
	var adj_unlocked: bool = GardenZone.is_zone_unlocked(GardenZone.ZONE_ADJACENT_1, _last_snapshot, journal)
	if not GardenZone.is_valid_zone_id(_active_zone_id):
		_active_zone_id = GardenZone.ZONE_MAIN

	var active_zone_name: String = GardenLocalization.get_zone_name(_active_zone_id, _locale)
	var active_unlocked: bool = adj_unlocked if _active_zone_id == GardenZone.ZONE_ADJACENT_1 else main_unlocked
	var active_used: int = GardenPlacement.get_occupied_cell_count(state, _active_zone_id)
	var active_total: int = GardenZone.get_cell_count(_active_zone_id)

	if _zones_section_label != null:
		_zones_section_label.visible = true
		_zones_section_label.text = GardenLocalization.format_key(
			"ui.garden.zones_section_header",
			[active_zone_name],
			_locale
		)

	if _zone_tabs_row != null:
		_zone_tabs_row.visible = true

	if _zone_main_button != null:
		var main_name: String = GardenLocalization.get_zone_name(GardenZone.ZONE_MAIN, _locale)
		var main_used: int = GardenPlacement.get_occupied_cell_count(state, GardenZone.ZONE_MAIN)
		var main_total: int = GardenZone.get_cell_count(GardenZone.ZONE_MAIN)
		_zone_main_button.text = GardenLocalization.format_key(
			"ui.garden.zone_tab_unlocked",
			[main_name, main_used, main_total],
			_locale
		)
		_zone_main_button.modulate = Color(1.0, 1.0, 0.85, 1.0) if _active_zone_id == GardenZone.ZONE_MAIN else Color(0.85, 0.85, 0.85, 1.0)

	if _zone_adjacent_button != null:
		var adj_name: String = GardenLocalization.get_zone_name(GardenZone.ZONE_ADJACENT_1, _locale)
		if adj_unlocked:
			var adj_used: int = GardenPlacement.get_occupied_cell_count(state, GardenZone.ZONE_ADJACENT_1)
			var adj_total: int = GardenZone.get_cell_count(GardenZone.ZONE_ADJACENT_1)
			_zone_adjacent_button.text = GardenLocalization.format_key(
				"ui.garden.zone_tab_unlocked",
				[adj_name, adj_used, adj_total],
				_locale
			)
		else:
			_zone_adjacent_button.text = GardenLocalization.format_key(
				"ui.garden.zone_tab_locked",
				[adj_name],
				_locale
			)
		_zone_adjacent_button.modulate = Color(1.0, 1.0, 0.85, 1.0) if _active_zone_id == GardenZone.ZONE_ADJACENT_1 else Color(0.85, 0.85, 0.85, 1.0)

	if _zone_status_label != null:
		_zone_status_label.visible = true
		if not active_unlocked:
			_zone_status_label.text = GardenLocalization.translate("ui.garden.zone_status_locked", _locale)
		elif _is_move_mode:
			var moving_name: String = _get_selected_item_display_name()
			_zone_status_label.text = GardenLocalization.format_key(
				"ui.garden.zone_status_move",
				[moving_name],
				_locale
			)
		elif _target_zone_id == _active_zone_id and _target_grid_x >= 0 and _target_grid_y >= 0:
			_zone_status_label.text = GardenLocalization.format_key(
				"ui.garden.zone_status_target",
				[active_zone_name, _target_grid_x, _target_grid_y],
				_locale
			)
		else:
			_zone_status_label.text = GardenLocalization.format_key(
				"ui.garden.zone_status_unlocked",
				[active_zone_name, active_used, active_total],
				_locale
			)

	if _zone_grid_container == null:
		return

	_clear_container_children(_zone_grid_container)
	_zone_grid_container.visible = true
	var width: int = GardenZone.get_grid_width(_active_zone_id)
	var height: int = GardenZone.get_grid_height(_active_zone_id)
	_zone_grid_container.columns = maxi(1, width)

	for y: int in range(height):
		for x: int in range(width):
			var btn: Button = Button.new()
			btn.name = "Cell_%d_%d" % [x, y]
			btn.custom_minimum_size = Vector2(64, 56)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.clip_text = true
			btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			btn.focus_mode = Control.FOCUS_ALL
			btn.add_theme_font_size_override("font_size", 16)

			var occupant: Dictionary = GardenPlacement.get_occupant_at(state, _active_zone_id, x, y)
			var occ_kind: String = occupant.get("kind", "") as String
			var occ_id: String = occupant.get("instance_id", "") as String
			var occ_def_id: String = occupant.get("definition_id", "") as String

			if occ_kind == GardenPlacement.KIND_PLANT:
				var plant_name: String = GardenLocalization.get_plant_name(occ_def_id, _locale)
				btn.text = GardenLocalization.format_key("ui.garden.grid_cell_occupied", [plant_name, x, y], _locale)
				var is_sel: bool = not _selected_runtime_instance_id.is_empty() and occ_id == _selected_runtime_instance_id
				btn.modulate = Color(0.85, 1.0, 0.72, 1.0) if is_sel else Color(0.75, 0.92, 0.78, 1.0)
			elif occ_kind == GardenPlacement.KIND_DECORATION:
				var decor_name: String = GardenLocalization.get_decoration_name(occ_def_id, _locale)
				btn.text = GardenLocalization.format_key("ui.garden.grid_cell_occupied", [decor_name, x, y], _locale)
				var is_sel_d: bool = not _selected_decoration_instance_id.is_empty() and occ_id == _selected_decoration_instance_id
				btn.modulate = Color(1.0, 0.92, 0.68, 1.0) if is_sel_d else Color(0.92, 0.84, 0.72, 1.0)
			else:
				var is_target: bool = (_target_zone_id == _active_zone_id and _target_grid_x == x and _target_grid_y == y)
				if is_target:
					btn.text = GardenLocalization.format_key("ui.garden.grid_cell_target", [x, y], _locale)
					btn.modulate = Color(0.96, 0.88, 0.56, 1.0)
				else:
					btn.text = GardenLocalization.format_key("ui.garden.grid_cell_empty", [x, y], _locale)
					btn.modulate = Color(0.75, 0.75, 0.75, 0.85) if not active_unlocked else Color(0.88, 0.92, 0.88, 1.0)
				btn.disabled = not active_unlocked

			btn.pressed.connect(_on_zone_cell_pressed.bind(_active_zone_id, x, y))
			_zone_grid_container.add_child(btn)


func _get_selected_item_display_name() -> String:
	if not _selected_plant_definition_id.is_empty():
		return GardenLocalization.get_plant_name(_selected_plant_definition_id, _locale)
	if not _selected_decoration_definition_id.is_empty():
		return GardenLocalization.get_decoration_name(_selected_decoration_definition_id, _locale)
	return GardenLocalization.translate("ui.common.dash", _locale)


func _on_zone_main_button_pressed() -> void:
	_play_sfx("ui_tap")
	select_active_zone(GardenZone.ZONE_MAIN)


func _on_zone_adjacent_button_pressed() -> void:
	_play_sfx("ui_tap")
	select_active_zone(GardenZone.ZONE_ADJACENT_1)


func select_active_zone(zone_id: String) -> void:
	if not GardenZone.is_valid_zone_id(zone_id):
		return
	_active_zone_id = zone_id
	if not _target_zone_id.is_empty() and _target_zone_id != _active_zone_id:
		_target_zone_id = ""
		_target_grid_x = -1
		_target_grid_y = -1
	_render_zone_grid()
	_sync_picker_placement_contexts()
	_update_garden_diorama(_game_clock.utc_now_seconds() if _game_clock != null else _last_refresh_utc_seconds)


func _set_move_mode(enabled: bool) -> void:
	_is_move_mode = enabled
	if _is_move_mode:
		_target_zone_id = ""
		_target_grid_x = -1
		_target_grid_y = -1
	_resolve_nodes()
	if _move_button != null:
		_move_button.text = GardenLocalization.translate(
			"ui.details.move_cancel_button" if _is_move_mode else "ui.details.move_button",
			_locale
		)
	_render_zone_grid()
	_sync_diorama_placement_highlight()
	_sync_back_navigation_state()


func _on_move_button_pressed() -> void:
	if _is_blocked or _session == null:
		return
	if _selected_runtime_instance_id.is_empty() and _selected_decoration_instance_id.is_empty():
		return
	_play_sfx("ui_tap")
	_set_move_mode(not _is_move_mode)


func _on_zone_cell_pressed(zone_id: String, grid_x: int, grid_y: int) -> void:
	if _is_blocked or _session == null or _session.get_state() == null:
		return

	var state: GameState = _session.get_state()
	var occupant: Dictionary = GardenPlacement.get_occupant_at(state, zone_id, grid_x, grid_y)
	var occ_kind: String = occupant.get("kind", "") as String
	var occ_id: String = occupant.get("instance_id", "") as String

	if occ_kind == GardenPlacement.KIND_PLANT and not occ_id.is_empty():
		_is_move_mode = false
		_target_zone_id = ""
		_target_grid_x = -1
		_target_grid_y = -1
		_on_plant_selected(occ_id)
		_render_zone_grid()
		_sync_diorama_placement_highlight()
		_sync_back_navigation_state()
		return

	if occ_kind == GardenPlacement.KIND_DECORATION and not occ_id.is_empty():
		_is_move_mode = false
		_target_zone_id = ""
		_target_grid_x = -1
		_target_grid_y = -1
		_on_decoration_selected(occ_id)
		_render_zone_grid()
		_sync_diorama_placement_highlight()
		_sync_back_navigation_state()
		return

	if not GardenZone.is_zone_unlocked(zone_id, _last_snapshot, state.get_journal()):
		return

	if _is_move_mode:
		var moving_id: String = (
			_selected_runtime_instance_id
			if not _selected_runtime_instance_id.is_empty()
			else _selected_decoration_instance_id
		)
		if not moving_id.is_empty():
			_set_move_mode(false)
			move_item_requested.emit(moving_id, zone_id, grid_x, grid_y)
			return

	if _target_zone_id == zone_id and _target_grid_x == grid_x and _target_grid_y == grid_y:
		_target_zone_id = ""
		_target_grid_x = -1
		_target_grid_y = -1
	else:
		_active_zone_id = zone_id
		_target_zone_id = zone_id
		_target_grid_x = grid_x
		_target_grid_y = grid_y
	_play_sfx("ui_tap")
	_render_zone_grid()
	_sync_diorama_placement_highlight()
	_sync_picker_placement_contexts()
	_sync_back_navigation_state()


## Displays user feedback from a GardenPlacementCheckpointResult.
func show_move_result(result: GardenPlacementCheckpointResult) -> void:
	_last_move_checkpoint_result = result
	_resolve_nodes()
	if _feedback_area == null or _feedback_label == null or result == null:
		return

	_active_feedback_kind = "move"
	_feedback_area.visible = true
	match result.get_status():
		GardenPlacementCheckpointResult.Status.NOT_READY:
			_feedback_label.text = GardenLocalization.translate("ui.feedback.move_not_ready", _locale)
		GardenPlacementCheckpointResult.Status.MOVE_REJECTED:
			var reason_str: String = ""
			var move_res: GardenPlacementResult = result.get_placement_result()
			if move_res != null:
				match move_res.get_status():
					GardenPlacementResult.INVALID_INPUT:
						reason_str = "INVALID_INPUT"
					GardenPlacementResult.ITEM_NOT_FOUND:
						reason_str = "ITEM_NOT_FOUND"
					GardenPlacementResult.INVALID_PLACEMENT:
						reason_str = "INVALID_PLACEMENT"
					GardenPlacementResult.ZONE_LOCKED:
						reason_str = "ZONE_LOCKED"
					GardenPlacementResult.CELL_OCCUPIED:
						reason_str = "CELL_OCCUPIED"
					GardenPlacementResult.SAME_CELL:
						reason_str = "SAME_CELL"
					GardenPlacementResult.STATE_UPDATE_REJECTED:
						reason_str = "STATE_UPDATE_REJECTED"
					_:
						reason_str = "UNKNOWN"
			if not reason_str.is_empty():
				_feedback_label.text = GardenLocalization.format_key("ui.feedback.move_rejected_reason", [reason_str], _locale)
			else:
				_feedback_label.text = GardenLocalization.translate("ui.feedback.move_rejected", _locale)
		GardenPlacementCheckpointResult.Status.MOVED_SAVED, GardenPlacementCheckpointResult.Status.MOVED_SAVE_FAILED:
			var pr: GardenPlacementResult = result.get_placement_result()
			var item_name: String = ""
			var zone_name: String = ""
			var gx: int = 0
			var gy: int = 0
			if pr != null:
				if pr.get_item_kind() == GardenPlacement.KIND_PLANT:
					item_name = GardenLocalization.get_plant_name(pr.get_definition_id(), _locale)
				else:
					item_name = GardenLocalization.get_decoration_name(pr.get_definition_id(), _locale)
				zone_name = GardenLocalization.get_zone_name(pr.get_zone_id(), _locale)
				gx = pr.get_grid_x()
				gy = pr.get_grid_y()
			var key: String = (
				"ui.feedback.move_saved"
				if result.get_status() == GardenPlacementCheckpointResult.Status.MOVED_SAVED
				else "ui.feedback.move_save_failed"
			)
			_feedback_label.text = GardenLocalization.format_key(key, [item_name, zone_name, gx, gy], _locale)
			if not _suppress_feedback_effects:
				_play_sfx("place_decor")
				if _garden_diorama != null and pr != null:
					_garden_diorama.play_feedback_puff_at_cell(pr.get_zone_id(), gx, gy)
		_:
			_feedback_label.text = GardenLocalization.translate("ui.feedback.move_unknown", _locale)


## Pure query for testing: returns currently selected zone tab ID.
func get_active_zone_id() -> String:
	return _active_zone_id


## Pure query for testing: returns true if Adjacent Zone 2 is unlocked in the latest refresh.
func is_adjacent_zone_unlocked() -> bool:
	if _is_blocked or _session == null or _session.get_state() == null:
		return false
	return GardenZone.is_zone_unlocked(
		GardenZone.ZONE_ADJACENT_1,
		_last_snapshot,
		_session.get_state().get_journal()
	)


## Pure query for testing: returns MoveButton instance.
func get_move_button() -> Button:
	_resolve_nodes()
	return _move_button


## Pure query for testing: returns true if move mode is active.
func is_move_mode_active() -> bool:
	return _is_move_mode and not _is_blocked


## Pure query for testing: returns the currently targeted empty grid cell dictionary.
func get_target_cell() -> Dictionary:
	return {
		"zone_id": _target_zone_id,
		"grid_x": _target_grid_x,
		"grid_y": _target_grid_y,
	}


## Pure query for testing: returns text displayed in DetailPlacementLabel.
func get_detail_placement_text() -> String:
	_resolve_nodes()
	return _detail_placement_label.text if _detail_placement_label != null else ""


## Pure query for testing: returns the grid cell Button at ([param grid_x], [param grid_y]) in the active zone.
func get_zone_grid_cell_button(grid_x: int, grid_y: int) -> Button:
	_resolve_nodes()
	if _zone_grid_container == null:
		return null
	return _zone_grid_container.get_node_or_null("Cell_%d_%d" % [grid_x, grid_y]) as Button


## Pure query for testing: returns ZoneMainButton.
func get_zone_main_button() -> Button:
	_resolve_nodes()
	return _zone_main_button


## Pure query for testing: returns ZoneAdjacentButton.
func get_zone_adjacent_button() -> Button:
	_resolve_nodes()
	return _zone_adjacent_button


## Pure query for testing: returns ZoneStatusLabel text.
func get_zone_status_text() -> String:
	_resolve_nodes()
	return _zone_status_label.text if _zone_status_label != null else ""


## Pure helper computing safe-area-aware canvas margins on MainMargin from physical safe-area pixels.
static func compute_safe_area_margins(
	safe_area: Rect2i,
	screen_size: Vector2i,
	viewport_size: Vector2,
	base_margin: int = BASE_MAIN_MARGIN_PX
) -> Dictionary:
	var min_margin: int = maxi(0, base_margin)
	if (
		safe_area.size.x <= 0
		or safe_area.size.y <= 0
		or screen_size.x <= 0
		or screen_size.y <= 0
		or viewport_size.x <= 0.0
		or viewport_size.y <= 0.0
	):
		return {
			"left": min_margin,
			"top": min_margin,
			"right": min_margin,
			"bottom": min_margin,
		}

	var left_edge: int = clampi(safe_area.position.x, 0, screen_size.x)
	var top_edge: int = clampi(safe_area.position.y, 0, screen_size.y)
	var right_edge: int = clampi(safe_area.end.x, left_edge, screen_size.x)
	var bottom_edge: int = clampi(safe_area.end.y, top_edge, screen_size.y)
	if right_edge <= left_edge or bottom_edge <= top_edge:
		return {
			"left": min_margin,
			"top": min_margin,
			"right": min_margin,
			"bottom": min_margin,
		}

	var scale_x: float = viewport_size.x / float(screen_size.x)
	var scale_y: float = viewport_size.y / float(screen_size.y)
	var max_inset_x: int = maxi(min_margin, int(floor(viewport_size.x * 0.25)))
	var max_inset_y: int = maxi(min_margin, int(floor(viewport_size.y * 0.25)))

	return {
		"left": mini(max_inset_x, maxi(min_margin, ceili(float(left_edge) * scale_x))),
		"top": mini(max_inset_y, maxi(min_margin, ceili(float(top_edge) * scale_y))),
		"right": mini(max_inset_x, maxi(min_margin, ceili(float(screen_size.x - right_edge) * scale_x))),
		"bottom": mini(max_inset_y, maxi(min_margin, ceili(float(screen_size.y - bottom_edge) * scale_y))),
	}


## Applies explicit safe-area insets to MainMargin and returns the applied canvas margins.
func apply_safe_area_insets(
	safe_area: Rect2i,
	screen_size: Vector2i,
	viewport_size: Vector2
) -> Dictionary:
	_resolve_nodes()
	var margins: Dictionary = compute_safe_area_margins(
		safe_area,
		screen_size,
		viewport_size,
		BASE_MAIN_MARGIN_PX
	)
	_last_applied_margins = margins.duplicate()
	if _main_margin != null:
		_main_margin.add_theme_constant_override("margin_left", int(margins["left"]))
		_main_margin.add_theme_constant_override("margin_top", int(margins["top"]))
		_main_margin.add_theme_constant_override("margin_right", int(margins["right"]))
		_main_margin.add_theme_constant_override("margin_bottom", int(margins["bottom"]))
	return _last_applied_margins.duplicate()


func _refresh_safe_area_margins() -> void:
	if not is_inside_tree():
		return
	var viewport: Viewport = get_viewport()
	var viewport_size: Vector2 = viewport.get_visible_rect().size if viewport != null else size
	apply_safe_area_insets(
		DisplayServer.get_display_safe_area(),
		DisplayServer.window_get_size(),
		viewport_size
	)


## Pure query for testing: returns the last margins applied to MainMargin.
func get_applied_main_margins() -> Dictionary:
	return _last_applied_margins.duplicate()


## Returns true if an overlay modal, confirmation dialog, or move editing mode is active.
func has_active_back_target() -> bool:
	if _is_blocked:
		return false
	if _planting_picker != null and _planting_picker.is_picker_open():
		return true
	if _decoration_picker != null and _decoration_picker.is_picker_open():
		return true
	if _journal_panel != null and _journal_panel.is_journal_open():
		return true
	return _is_move_mode


## Returns true when Android system Back should quit to the launcher instead of dismissing UI.
func should_quit_on_go_back() -> bool:
	return not has_active_back_target()


func _sync_back_navigation_state() -> void:
	if is_inside_tree() and get_tree() != null:
		get_tree().set_quit_on_go_back(should_quit_on_go_back())


func _on_modal_closed() -> void:
	_sync_back_navigation_state()


func _on_child_ui_tapped() -> void:
	_play_sfx("ui_tap")


## Handles Android hardware/gesture back or ui_cancel by closing the top-most confirmation,
## modal overlay, or active move mode without risking unintended quit or data mutation.
func handle_back_action() -> bool:
	_resolve_nodes()
	if _is_blocked:
		_sync_back_navigation_state()
		return false
	if _planting_picker != null and _planting_picker.is_picker_open():
		if _planting_picker.is_confirmation_active():
			_planting_picker.cancel_confirmation()
		else:
			close_planting_picker()
		_play_sfx("ui_tap")
		_sync_back_navigation_state()
		return true
	if _decoration_picker != null and _decoration_picker.is_picker_open():
		if _decoration_picker.is_confirmation_active():
			_decoration_picker.cancel_confirmation()
		else:
			close_decoration_picker()
		_play_sfx("ui_tap")
		_sync_back_navigation_state()
		return true
	if _journal_panel != null and _journal_panel.is_journal_open():
		close_journal_panel()
		_play_sfx("ui_tap")
		_sync_back_navigation_state()
		return true
	if _is_move_mode:
		_set_move_mode(false)
		_play_sfx("ui_tap")
		return true
	_sync_back_navigation_state()
	return false
