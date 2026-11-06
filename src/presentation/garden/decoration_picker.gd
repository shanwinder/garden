## decoration_picker.gd
## Visual input component for selecting and confirming a garden decoration purchase.
##
## Architectural rules:
## - Belongs to the presentation layer (src/presentation/garden/).
## - Visual input component only; extends Control.
## - Receives ContentCatalog via typed dependency injection (bind_catalog).
## - Does not depend directly on the global App Autoload or AppRoot.
## - Does not access GameState, EconomyState, GameClock, RandomSource, or LocalSaveRepository.
## - Reads prices and environmental traits directly from DecorationDefinition in ContentCatalog;
##   never invents or hardcodes prices or subtracts currency in UI code.
## - Enumerates get_all_decoration_ids() preserving deterministic catalog order.
## - Displays the eight approved Thai decoration display names, prices, and traits.
## - Requires explicit two-step confirmation before emitting decoration_purchase_requested signal.
## - Cancel emits no request and clears pending confirmation.
## - Confirm emits exactly one request with the exact definition ID.
## - Guards against duplicate confirmation dispatch.
class_name DecorationPicker
extends Control

signal decoration_purchase_requested(definition_id: String)
signal picker_closed()

const PROVISIONAL_DECORATION_DISPLAY_NAMES: Dictionary = {
	"decoration.bench": "ม้านั่งไม้ในสวน",
	"decoration.clay_jar": "ตุ่มน้ำดินเผา",
	"decoration.garden_lamp": "โคมไฟในสวน",
	"decoration.plant_pot": "กระถางดินเผา",
	"decoration.small_pond": "บ่อน้ำเล็ก",
	"decoration.small_table": "โต๊ะไม้เล็ก",
	"decoration.watering_can": "บัวรดน้ำสังกะสี",
	"decoration.wooden_fence": "รั้วไม้ระแนง",
}

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

var _catalog: ContentCatalog = null
var _snapshot: GardenSnapshot = null
var _available_currency: int = -1
var _has_currency_context: bool = false
var _pending_definition_id: String = ""
var _is_dispatching_confirmation: bool = false
var _is_enabled: bool = true
var _option_texts_by_id: Dictionary = {}

var _close_button: Button = null
var _decoration_list_container: Container = null
var _confirmation_overlay: Control = null
var _confirm_prompt_label: Label = null
var _confirm_button: Button = null
var _cancel_button: Button = null
var _decoration_buttons: Array[Button] = []


func _ready() -> void:
	_resolve_nodes()
	_connect_dialog_signals()
	if _confirmation_overlay != null:
		_confirmation_overlay.visible = false


func _resolve_nodes() -> void:
	if _close_button == null:
		_close_button = get_node_or_null("CenterContainer/PickerPanel/MarginContainer/VBoxContainer/HeaderHBox/CloseButton") as Button
	if _decoration_list_container == null:
		_decoration_list_container = get_node_or_null("CenterContainer/PickerPanel/MarginContainer/VBoxContainer/ScrollContainer/ListMargin/DecorationListContainer") as Container
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
	if _confirm_button != null and not _confirm_button.pressed.is_connected(confirm_purchase):
		_confirm_button.pressed.connect(confirm_purchase)
	if _cancel_button != null and not _cancel_button.pressed.is_connected(cancel_confirmation):
		_cancel_button.pressed.connect(cancel_confirmation)


## Binds a validated ContentCatalog and populates decoration choices in catalog order.
func bind_catalog(catalog: ContentCatalog) -> void:
	_catalog = catalog
	_pending_definition_id = ""
	_resolve_nodes()
	_clear_decoration_buttons()

	if _confirmation_overlay != null:
		_confirmation_overlay.visible = false

	if _catalog == null or _catalog.get_decoration_count() == 0:
		return

	var decoration_ids: Array[String] = _catalog.get_all_decoration_ids()
	for def_id: String in decoration_ids:
		var btn: Button = Button.new()
		btn.text = _format_decoration_button_text(def_id)
		_option_texts_by_id[def_id] = btn.text
		btn.custom_minimum_size = Vector2(0, 72)
		btn.focus_mode = Control.FOCUS_ALL
		btn.add_theme_font_size_override("font_size", 21)
		btn.disabled = not _is_enabled
		btn.pressed.connect(_on_decoration_option_pressed.bind(def_id))
		_decoration_buttons.append(btn)
		if _decoration_list_container != null:
			_decoration_list_container.add_child(btn)


## Updates optional read-only shop context (available currency and GardenSnapshot) and refreshes labels in-place.
func update_shop_context(available_currency: int, snapshot: GardenSnapshot = null) -> void:
	_available_currency = available_currency
	_has_currency_context = available_currency >= 0
	_snapshot = snapshot
	_refresh_button_labels()


func _refresh_button_labels() -> void:
	_option_texts_by_id.clear()
	if _catalog == null:
		return
	var decoration_ids: Array[String] = _catalog.get_all_decoration_ids()
	for idx: int in range(mini(decoration_ids.size(), _decoration_buttons.size())):
		var def_id: String = decoration_ids[idx]
		var formatted: String = _format_decoration_button_text(def_id)
		_option_texts_by_id[def_id] = formatted
		var btn: Button = _decoration_buttons[idx]
		if is_instance_valid(btn):
			btn.text = formatted


func _format_decoration_button_text(def_id: String) -> String:
	var def: DecorationDefinition = _catalog.get_decoration(def_id) if _catalog != null else null
	var thai_name: String = PROVISIONAL_DECORATION_DISPLAY_NAMES.get(def_id, def_id)
	var price_val: int = def.price if def != null else 0
	var traits_summary: String = _format_traits_summary(def)
	var text: String = "%s (%s) — %d เหรียญ | %s" % [thai_name, def_id, price_val, traits_summary]
	if _snapshot != null:
		var placed_count: int = _snapshot.get_decoration_count_for_definition(def_id)
		text += " | วางแล้ว %d ชิ้น" % placed_count
		text += " [จัดวางแล้ว]" if placed_count > 0 else " [ของตกแต่งใหม่]"
	if _has_currency_context and _available_currency < price_val:
		text += " [เหรียญไม่พอ]"
	return text


func _format_traits_summary(def: DecorationDefinition) -> String:
	if def == null or def.environmental_traits.is_empty():
		return "ตกแต่งสวยงาม"
	var parts: PackedStringArray = PackedStringArray()
	for trait_id: String in def.environmental_traits:
		parts.append(PROVISIONAL_TRAIT_DISPLAY_NAMES.get(trait_id, trait_id))
	return ", ".join(parts)


func _clear_decoration_buttons() -> void:
	_decoration_buttons.clear()
	_option_texts_by_id.clear()
	if _decoration_list_container == null:
		return
	for child: Node in _decoration_list_container.get_children():
		_decoration_list_container.remove_child(child)
		child.queue_free()


func _on_decoration_option_pressed(definition_id: String) -> void:
	select_decoration_definition(definition_id)


## Selects a decoration definition and displays the confirmation prompt without emitting purchase request.
func select_decoration_definition(definition_id: String) -> void:
	if not _is_enabled:
		return
	if _catalog == null or not _catalog.has_decoration(definition_id):
		return

	_pending_definition_id = definition_id
	_resolve_nodes()

	var def: DecorationDefinition = _catalog.get_decoration(definition_id)
	var price_val: int = def.price if def != null else 0
	var thai_name: String = PROVISIONAL_DECORATION_DISPLAY_NAMES.get(definition_id, definition_id)
	var traits_summary: String = _format_traits_summary(def)
	if _confirm_prompt_label != null:
		if _has_currency_context:
			_confirm_prompt_label.text = (
				"ซื้อและวาง%s (%d เหรียญ | เหรียญที่มี: %d เหรียญ | คุณสมบัติ: %s) ลงในสวนหรือไม่?"
				% [thai_name, price_val, _available_currency, traits_summary]
			)
		else:
			_confirm_prompt_label.text = (
				"ซื้อและวาง%s (%d เหรียญ | คุณสมบัติ: %s) ลงในสวนหรือไม่?"
				% [thai_name, price_val, traits_summary]
			)

	if _confirmation_overlay != null:
		_confirmation_overlay.visible = true


## Cancels the pending confirmation prompt without emitting a purchase request.
func cancel_confirmation() -> void:
	_pending_definition_id = ""
	_resolve_nodes()
	if _confirmation_overlay != null:
		_confirmation_overlay.visible = false


## Confirms purchase and emits decoration_purchase_requested exactly once for the pending definition.
func confirm_purchase() -> void:
	if not _is_enabled:
		return
	if _pending_definition_id.is_empty():
		return
	if _is_dispatching_confirmation:
		return
	if _catalog == null or not _catalog.has_decoration(_pending_definition_id):
		return

	_is_dispatching_confirmation = true
	var def_to_emit: String = _pending_definition_id
	_pending_definition_id = ""

	_resolve_nodes()
	if _confirmation_overlay != null:
		_confirmation_overlay.visible = false
	visible = false

	decoration_purchase_requested.emit(def_to_emit)
	_is_dispatching_confirmation = false


## Opens the decoration picker dialog.
func open_picker() -> void:
	if not _is_enabled:
		return
	_resolve_nodes()
	_pending_definition_id = ""
	if _confirmation_overlay != null:
		_confirmation_overlay.visible = false
	visible = true


## Closes the decoration picker dialog.
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
	for btn: Button in _decoration_buttons:
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


## Pure query for testing: returns available decoration definition IDs in current list.
func get_available_decoration_ids() -> Array[String]:
	if _catalog == null:
		return []
	return _catalog.get_all_decoration_ids()


## Pure query for testing: returns decoration buttons array.
func get_decoration_buttons() -> Array[Button]:
	return _decoration_buttons.duplicate()


## Pure query for testing: returns bound available currency, or -1 if no currency context has been provided.
func get_available_currency() -> int:
	return _available_currency if _has_currency_context else -1


## Pure query for testing: returns placed count for [param definition_id] from the bound GardenSnapshot, or 0.
func get_placed_count_for_id(definition_id: String) -> int:
	return _snapshot.get_decoration_count_for_definition(definition_id) if _snapshot != null else 0


## Pure query for testing: returns true if [param definition_id] exists in the catalog and is affordable under the bound currency context (or true if no currency context is set).
func can_afford_decoration(definition_id: String) -> bool:
	if _catalog == null or not _catalog.has_decoration(definition_id):
		return false
	if not _has_currency_context:
		return true
	var def: DecorationDefinition = _catalog.get_decoration(definition_id)
	return def != null and _available_currency >= def.price


## Pure query for testing: returns formatted option button text for [param definition_id].
func get_decoration_option_text_for_id(definition_id: String) -> String:
	return _option_texts_by_id.get(definition_id, "")


## Pure query for testing: returns a defensive copy of environmental traits for [param definition_id] in the bound catalog, or [].
func get_decoration_traits_for_id(definition_id: String) -> Array[String]:
	if _catalog == null or not _catalog.has_decoration(definition_id):
		return []
	var def: DecorationDefinition = _catalog.get_decoration(definition_id)
	return def.environmental_traits.duplicate() if def != null else []


## Pure query for testing: returns true if [param definition_id] is currently placed in the bound GardenSnapshot.
func is_decoration_placed(definition_id: String) -> bool:
	return _snapshot != null and _snapshot.get_decoration_count_for_definition(definition_id) > 0


## Pure query for testing: returns deterministic catalog-ordered IDs of decorations currently placed in the bound GardenSnapshot.
func get_placed_decoration_ids() -> Array[String]:
	if _catalog == null or _snapshot == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_decoration_ids():
		if _snapshot.get_decoration_count_for_definition(def_id) > 0:
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of decorations not yet placed in the bound GardenSnapshot.
func get_unplaced_decoration_ids() -> Array[String]:
	if _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_decoration_ids():
		if _snapshot == null or _snapshot.get_decoration_count_for_definition(def_id) <= 0:
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of decorations affordable under the current currency context.
func get_affordable_decoration_ids() -> Array[String]:
	if _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_decoration_ids():
		if can_afford_decoration(def_id):
			result.append(def_id)
	return result
