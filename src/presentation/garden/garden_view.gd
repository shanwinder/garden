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

const PLANT_VIEW_SCENE: PackedScene = preload("res://scenes/garden/plant_view.tscn")

var _session: GameSession = null
var _catalog: ContentCatalog = null
var _game_clock: GameClock = null

var _selected_runtime_instance_id: String = ""
var _is_blocked: bool = false
var _blocked_message: String = ""

var _refresh_button: Button = null
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
var _detail_id_label: Label = null
var _detail_planted_at_label: Label = null


func _ready() -> void:
	_resolve_nodes()
	if _refresh_button != null and not _refresh_button.pressed.is_connected(_on_refresh_button_pressed):
		_refresh_button.pressed.connect(_on_refresh_button_pressed)
	if _is_blocked:
		_show_blocked_visual()
	elif _session != null:
		refresh_from_session()


## Resolves child node references safely whether _ready has fired or not.
func _resolve_nodes() -> void:
	if _refresh_button == null:
		_refresh_button = get_node_or_null("MainMargin/LayoutBox/HeaderArea/RefreshButton") as Button
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
	if _detail_id_label == null:
		_detail_id_label = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/DetailsContent/DetailIdLabel") as Label
	if _detail_planted_at_label == null:
		_detail_planted_at_label = get_node_or_null("MainMargin/LayoutBox/DetailsArea/MarginContainer/DetailsVBox/DetailsContent/DetailPlantedAtLabel") as Label


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

	if _session == null or _catalog == null or _game_clock == null:
		show_blocked_startup("ไม่สามารถเริ่มต้นสวนได้เนื่องจากข้อมูลไม่สมบูรณ์")
		return

	_is_blocked = false
	_blocked_message = ""
	refresh_from_session()


## Displays a safe readable state when startup failed or session is unavailable.
func show_blocked_startup(message: String = "") -> void:
	_is_blocked = true
	_blocked_message = message if not message.is_empty() else "ไม่สามารถโหลดสวนได้ในขณะนี้"
	_show_blocked_visual()


## Explicit refresh API: re-reads authoritative GameState and samples clock once.
func refresh_from_session() -> void:
	if _is_blocked or _session == null or _catalog == null or _game_clock == null:
		_show_blocked_visual()
		return

	# Sample the injected GameClock once for all plants (Requirement 10).
	var now_utc: int = _game_clock.utc_now_seconds()

	# Authoritative plant collection in deterministic order (Requirement 9, 20).
	var plants: Array[PlantState] = _session.get_state().get_plants().get_all_plants()

	_render_plants(plants, now_utc)


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
		if definition != null:
			stage = PlantGrowth.stage_for_state_at(plant_state, definition, now_utc)

		# Instantiate PlantView component.
		var view: PlantView = PLANT_VIEW_SCENE.instantiate() as PlantView
		view.bind_plant_data(instance_id, def_id, stage, planted_at)
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
		_no_selection_label.visible = true
		_details_content.visible = false
		return

	_no_selection_label.visible = false
	_details_content.visible = true

	var def_id: String = plant_state.get_definition_id()
	var thai_name: String = PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.get(def_id, def_id)

	if _detail_name_label != null:
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
		_detail_stage_label.text = "ระยะ: %s" % stage_text

	if _detail_id_label != null:
		_detail_id_label.text = "รหัสประจำต้น: %s" % plant_state.get_runtime_instance_id()

	if _detail_planted_at_label != null:
		_detail_planted_at_label.text = "ปลูกเมื่อ: %d (Unix UTC)" % plant_state.get_planted_at()


func _show_blocked_visual() -> void:
	_resolve_nodes()
	_clear_plant_views()
	_selected_runtime_instance_id = ""

	if _empty_container != null:
		_empty_container.visible = false
	if _plants_scroll != null:
		_plants_scroll.visible = false
	if _blocked_container != null:
		_blocked_container.visible = true
	if _blocked_label != null:
		_blocked_label.text = _blocked_message if not _blocked_message.is_empty() else "ไม่สามารถโหลดสวนได้ในขณะนี้"

	_update_details_panel(null, null, PlantGrowth.Stage.INVALID, 0)


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
