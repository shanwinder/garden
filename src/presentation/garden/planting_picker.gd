## planting_picker.gd
## Visual input component for selecting and confirming a plant definition to plant.
##
## Architectural rules:
## - Belongs to the presentation layer (src/presentation/garden/).
## - Visual input component only; extends Control.
## - Receives ContentCatalog via typed dependency injection (bind_catalog).
## - Does not depend directly on the global App Autoload or AppRoot.
## - Does not access GameState, GameClock, RandomSource, or LocalSaveRepository.
## - Does not invent prices, currencies, or economy rules.
## - Enumerates get_all_plant_ids() preserving deterministic catalog order.
## - Displays the five approved Thai plant display names.
## - Requires explicit confirmation before emitting planting_requested signal.
## - Cancel emits no request and clears pending confirmation.
## - Confirm emits exactly one request with the exact definition ID.
## - Guards against duplicate confirmation dispatch.
class_name PlantingPicker
extends Control

signal planting_requested(definition_id: String)
signal picker_closed()

var _catalog: ContentCatalog = null
var _pending_definition_id: String = ""
var _is_dispatching_confirmation: bool = false
var _is_enabled: bool = true

var _close_button: Button = null
var _plant_list_container: Container = null
var _confirmation_overlay: Control = null
var _confirm_prompt_label: Label = null
var _confirm_button: Button = null
var _cancel_button: Button = null
var _plant_buttons: Array[Button] = []


func _ready() -> void:
	_resolve_nodes()
	_connect_dialog_signals()
	if _confirmation_overlay != null:
		_confirmation_overlay.visible = false


func _resolve_nodes() -> void:
	if _close_button == null:
		_close_button = get_node_or_null("CenterContainer/PickerPanel/MarginContainer/VBoxContainer/HeaderHBox/CloseButton") as Button
	if _plant_list_container == null:
		_plant_list_container = get_node_or_null("CenterContainer/PickerPanel/MarginContainer/VBoxContainer/ScrollContainer/ListMargin/PlantListContainer") as Container
	if _confirmation_overlay == null:
		_confirmation_overlay = get_node_or_null("ConfirmationOverlay") as Control
	if _confirm_prompt_label == null:
		_confirm_prompt_label = get_node_or_null("ConfirmationOverlay/ConfirmCenter/ConfirmPanel/MarginContainer/VBoxContainer/ConfirmPromptLabel") as Label
	if _confirm_button == null:
		_confirm_button = get_node_or_null("ConfirmationOverlay/ConfirmCenter/ConfirmPanel/MarginContainer/VBoxContainer/ButtonHBox/ConfirmButton") as Button
	if _cancel_button == null:
		_cancel_button = get_node_or_null("ConfirmationOverlay/ConfirmCenter/ConfirmPanel/MarginContainer/VBoxContainer/ButtonHBox/CancelButton") as Button
	_connect_dialog_signals()


func _connect_dialog_signals() -> void:
	if _close_button != null and not _close_button.pressed.is_connected(close_picker):
		_close_button.pressed.connect(close_picker)
	if _confirm_button != null and not _confirm_button.pressed.is_connected(confirm_planting):
		_confirm_button.pressed.connect(confirm_planting)
	if _cancel_button != null and not _cancel_button.pressed.is_connected(cancel_confirmation):
		_cancel_button.pressed.connect(cancel_confirmation)


## Binds a validated ContentCatalog and populates plant choices in catalog order.
func bind_catalog(catalog: ContentCatalog) -> void:
	_catalog = catalog
	_pending_definition_id = ""
	_resolve_nodes()
	_clear_plant_buttons()

	if _confirmation_overlay != null:
		_confirmation_overlay.visible = false

	if _catalog == null or _catalog.get_plant_count() == 0:
		return

	var plant_ids: Array[String] = _catalog.get_all_plant_ids()
	for def_id: String in plant_ids:
		var thai_name: String = PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.get(def_id, def_id)
		var btn: Button = Button.new()
		btn.text = "%s (%s)" % [thai_name, def_id]
		btn.custom_minimum_size = Vector2(0, 72)
		btn.focus_mode = Control.FOCUS_ALL
		btn.add_theme_font_size_override("font_size", 24)
		btn.disabled = not _is_enabled
		btn.pressed.connect(_on_plant_option_pressed.bind(def_id))
		_plant_buttons.append(btn)
		if _plant_list_container != null:
			_plant_list_container.add_child(btn)


func _clear_plant_buttons() -> void:
	_plant_buttons.clear()
	if _plant_list_container == null:
		return
	for child: Node in _plant_list_container.get_children():
		_plant_list_container.remove_child(child)
		child.queue_free()


func _on_plant_option_pressed(definition_id: String) -> void:
	select_plant_definition(definition_id)


## Selects a plant definition and displays the confirmation prompt without emitting planting request.
func select_plant_definition(definition_id: String) -> void:
	if not _is_enabled:
		return
	if _catalog == null or not _catalog.has_plant(definition_id):
		return

	_pending_definition_id = definition_id
	_resolve_nodes()

	var thai_name: String = PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.get(definition_id, definition_id)
	if _confirm_prompt_label != null:
		_confirm_prompt_label.text = "เพิ่มต้น%sลงในสวนหรือไม่?" % thai_name

	if _confirmation_overlay != null:
		_confirmation_overlay.visible = true


## Cancels the pending confirmation prompt without emitting a planting request.
func cancel_confirmation() -> void:
	_pending_definition_id = ""
	_resolve_nodes()
	if _confirmation_overlay != null:
		_confirmation_overlay.visible = false


## Confirms planting and emits planting_requested exactly once for the pending definition.
func confirm_planting() -> void:
	if not _is_enabled:
		return
	if _pending_definition_id.is_empty():
		return
	if _is_dispatching_confirmation:
		return
	if _catalog == null or not _catalog.has_plant(_pending_definition_id):
		return

	_is_dispatching_confirmation = true
	var def_to_emit: String = _pending_definition_id
	_pending_definition_id = ""

	_resolve_nodes()
	if _confirmation_overlay != null:
		_confirmation_overlay.visible = false
	visible = false

	planting_requested.emit(def_to_emit)
	_is_dispatching_confirmation = false


## Opens the planting picker dialog.
func open_picker() -> void:
	if not _is_enabled:
		return
	_resolve_nodes()
	_pending_definition_id = ""
	if _confirmation_overlay != null:
		_confirmation_overlay.visible = false
	visible = true


## Closes the planting picker dialog.
func close_picker() -> void:
	_pending_definition_id = ""
	_resolve_nodes()
	if _confirmation_overlay != null:
		_confirmation_overlay.visible = false
	visible = false
	picker_closed.emit()


## Enables or disables interaction with the picker.
func set_picker_enabled(enabled: bool) -> void:
	_is_enabled = enabled
	_resolve_nodes()
	if _close_button != null:
		_close_button.disabled = not enabled
	if _confirm_button != null:
		_confirm_button.disabled = not enabled
	if _cancel_button != null:
		_cancel_button.disabled = not enabled
	for btn: Button in _plant_buttons:
		if is_instance_valid(btn):
			btn.disabled = not enabled
	if not enabled:
		cancel_confirmation()
		visible = false


## Pure query for testing: returns true if picker dialog is visible/open.
func is_picker_open() -> bool:
	return visible


## Pure query for testing: returns true if picker is enabled.
func is_picker_enabled() -> bool:
	return _is_enabled


## Pure query for testing: returns true if confirmation dialog is visible.
func is_confirmation_active() -> bool:
	_resolve_nodes()
	return _confirmation_overlay != null and _confirmation_overlay.visible


## Pure query for testing: returns pending definition ID.
func get_pending_definition_id() -> String:
	return _pending_definition_id


## Pure query for testing: returns prompt label text.
func get_confirm_prompt_text() -> String:
	_resolve_nodes()
	return _confirm_prompt_label.text if _confirm_prompt_label != null else ""


## Pure query for testing: returns available plant definition IDs in current list.
func get_available_plant_ids() -> Array[String]:
	if _catalog == null:
		return []
	return _catalog.get_all_plant_ids()


## Pure query for testing: returns plant buttons array.
func get_plant_buttons() -> Array[Button]:
	return _plant_buttons.duplicate()
