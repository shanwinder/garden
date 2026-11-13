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
signal ui_tapped()

var _catalog: ContentCatalog = null
var _snapshot: GardenSnapshot = null
var _available_currency: int = -1
var _has_currency_context: bool = false
var _pending_definition_id: String = ""
var _is_dispatching_confirmation: bool = false
var _is_enabled: bool = true
var _locale: String = GardenLocalization.DEFAULT_LOCALE
var _option_texts_by_id: Dictionary = {}

var _title_label: Label = null
var _close_button: Button = null
var _note_label: Label = null
var _decoration_list_container: Container = null
var _confirmation_overlay: Control = null
var _confirm_title_label: Label = null
var _confirm_prompt_label: Label = null
var _confirm_notice_label: Label = null
var _confirm_button: Button = null
var _cancel_button: Button = null
var _decoration_buttons: Array[Button] = []


func _ready() -> void:
	_resolve_nodes()
	_connect_dialog_signals()
	_apply_static_texts()
	if _confirmation_overlay != null:
		_confirmation_overlay.visible = false


func _resolve_nodes() -> void:
	if _title_label == null:
		_title_label = get_node_or_null("CenterContainer/PickerPanel/MarginContainer/VBoxContainer/HeaderHBox/TitleLabel") as Label
	if _close_button == null:
		_close_button = get_node_or_null("CenterContainer/PickerPanel/MarginContainer/VBoxContainer/HeaderHBox/CloseButton") as Button
	if _note_label == null:
		_note_label = get_node_or_null("CenterContainer/PickerPanel/MarginContainer/VBoxContainer/NoteLabel") as Label
	if _decoration_list_container == null:
		_decoration_list_container = get_node_or_null("CenterContainer/PickerPanel/MarginContainer/VBoxContainer/ScrollContainer/ListMargin/DecorationListContainer") as Container
	if _confirmation_overlay == null:
		_confirmation_overlay = get_node_or_null("ConfirmationOverlay") as Control
	if _confirm_title_label == null:
		_confirm_title_label = get_node_or_null("ConfirmationOverlay/ConfirmCenter/ConfirmPanel/MarginContainer/VBoxContainer/ConfirmTitleLabel") as Label
	if _confirm_prompt_label == null:
		_confirm_prompt_label = get_node_or_null("ConfirmationOverlay/ConfirmCenter/ConfirmPanel/MarginContainer/VBoxContainer/ConfirmPromptLabel") as Label
	if _confirm_notice_label == null:
		_confirm_notice_label = get_node_or_null("ConfirmationOverlay/ConfirmCenter/ConfirmPanel/MarginContainer/VBoxContainer/ConfirmNoticeLabel") as Label
	if _confirm_button == null:
		_confirm_button = get_node_or_null("ConfirmationOverlay/ConfirmCenter/ConfirmPanel/MarginContainer/VBoxContainer/ButtonHBox/ConfirmButton") as Button
	if _cancel_button == null:
		_cancel_button = get_node_or_null("ConfirmationOverlay/ConfirmCenter/ConfirmPanel/MarginContainer/VBoxContainer/ButtonHBox/CancelButton") as Button
	_connect_dialog_signals()


func _connect_dialog_signals() -> void:
	if _close_button != null and not _close_button.pressed.is_connected(_on_close_button_pressed):
		_close_button.pressed.connect(_on_close_button_pressed)
	if _confirm_button != null and not _confirm_button.pressed.is_connected(confirm_purchase):
		_confirm_button.pressed.connect(confirm_purchase)
	if _cancel_button != null and not _cancel_button.pressed.is_connected(_on_cancel_button_pressed):
		_cancel_button.pressed.connect(_on_cancel_button_pressed)


## Binds a validated ContentCatalog and populates decoration choices in catalog order.
func bind_catalog(catalog: ContentCatalog) -> void:
	_catalog = catalog
	_pending_definition_id = ""
	_resolve_nodes()
	_apply_static_texts()
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
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_ALL
		btn.add_theme_font_size_override("font_size", 21)
		_apply_button_icon(btn, def_id)
		btn.disabled = not _is_enabled
		btn.pressed.connect(_on_decoration_option_pressed.bind(def_id))
		_decoration_buttons.append(btn)
		if _decoration_list_container != null:
			_decoration_list_container.add_child(btn)


func _apply_button_icon(btn: Button, def_id: String) -> void:
	if btn == null:
		return
	var tex: Texture2D = GardenAssetCatalog.get_decoration_texture(def_id)
	btn.icon = tex
	btn.expand_icon = (tex != null)
	if tex != null:
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_constant_override("icon_max_width", 56)
		btn.add_theme_constant_override("h_separation", 12)


## Sets active display locale ("th" or "en") and refreshes decoration shop labels in-place.
func set_locale(locale: String) -> void:
	_locale = GardenLocalization.normalize_locale(locale)
	_resolve_nodes()
	_apply_static_texts()
	_refresh_button_labels()
	if not _pending_definition_id.is_empty():
		_update_confirm_prompt_text(_pending_definition_id)


## Returns active display locale ("th" or "en").
func get_locale() -> String:
	return _locale


func _apply_static_texts() -> void:
	if _title_label != null:
		_title_label.text = GardenLocalization.translate("ui.decoration_picker.title", _locale)
	if _close_button != null:
		_close_button.text = GardenLocalization.translate("ui.common.close", _locale)
	if _note_label != null:
		_note_label.text = GardenLocalization.translate("ui.decoration_picker.note", _locale)
	if _confirm_title_label != null:
		_confirm_title_label.text = GardenLocalization.translate("ui.decoration_picker.confirm_title", _locale)
	if _confirm_notice_label != null:
		_confirm_notice_label.text = GardenLocalization.translate("ui.decoration_picker.confirm_notice", _locale)
	if _cancel_button != null:
		_cancel_button.text = GardenLocalization.translate("ui.common.cancel", _locale)
	if _confirm_button != null:
		_confirm_button.text = GardenLocalization.translate("ui.common.confirm", _locale)


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
	var display_name: String = GardenLocalization.get_decoration_name(def_id, _locale, def)
	var price_val: int = def.price if def != null else 0
	var traits_summary: String = _format_traits_summary(def)
	var text: String = GardenLocalization.format_key(
		"ui.decoration_picker.option_base",
		[display_name, def_id, price_val, traits_summary],
		_locale
	)
	if _snapshot != null:
		var placed_count: int = _snapshot.get_decoration_count_for_definition(def_id)
		text += GardenLocalization.format_key("ui.decoration_picker.placed_count_suffix", [placed_count], _locale)
		text += GardenLocalization.translate(
			"ui.decoration_picker.badge_placed" if placed_count > 0 else "ui.decoration_picker.badge_new",
			_locale
		)
	if _has_currency_context and _available_currency < price_val:
		text += GardenLocalization.translate("ui.decoration_picker.badge_insufficient", _locale)
	return text


func _format_traits_summary(def: DecorationDefinition) -> String:
	if def == null or def.environmental_traits.is_empty():
		return GardenLocalization.translate("ui.decoration_picker.cosmetic", _locale)
	var parts: PackedStringArray = PackedStringArray()
	for trait_id: String in def.environmental_traits:
		parts.append(GardenLocalization.get_trait_name(trait_id, _locale))
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
	if _is_enabled:
		ui_tapped.emit()
	select_decoration_definition(definition_id)


func _on_close_button_pressed() -> void:
	ui_tapped.emit()
	close_picker()


func _on_cancel_button_pressed() -> void:
	ui_tapped.emit()
	cancel_confirmation()


## Selects a decoration definition and displays the confirmation prompt without emitting purchase request.
func select_decoration_definition(definition_id: String) -> void:
	if not _is_enabled:
		return
	if _catalog == null or not _catalog.has_decoration(definition_id):
		return

	_pending_definition_id = definition_id
	_resolve_nodes()
	_update_confirm_prompt_text(definition_id)

	if _confirmation_overlay != null:
		_confirmation_overlay.visible = true


func _update_confirm_prompt_text(definition_id: String) -> void:
	if _confirm_prompt_label == null:
		return
	var def: DecorationDefinition = _catalog.get_decoration(definition_id)
	var price_val: int = def.price if def != null else 0
	var display_name: String = GardenLocalization.get_decoration_name(definition_id, _locale, def)
	var traits_summary: String = _format_traits_summary(def)
	var prompt_parts: PackedStringArray = PackedStringArray()
	prompt_parts.append(GardenLocalization.format_key("ui.decoration_picker.price_coins", [price_val], _locale))
	if _has_currency_context:
		prompt_parts.append(GardenLocalization.format_key("ui.decoration_picker.available_coins", [_available_currency], _locale))
	prompt_parts.append(GardenLocalization.format_key("ui.decoration_picker.traits", [traits_summary], _locale))
	if _snapshot != null:
		prompt_parts.append(
			GardenLocalization.format_key("ui.decoration_picker.placed_count", [_snapshot.get_decoration_count_for_definition(definition_id)], _locale)
		)
	var prompt_text: String = GardenLocalization.format_key(
		"ui.decoration_picker.prompt_details",
		[display_name, " | ".join(prompt_parts)],
		_locale
	)
	if _snapshot != null:
		prompt_text += GardenLocalization.translate(
			"ui.decoration_picker.badge_placed" if _snapshot.get_decoration_count_for_definition(definition_id) > 0 else "ui.decoration_picker.badge_new",
			_locale
		)
	if _has_currency_context and _available_currency < price_val:
		prompt_text += GardenLocalization.translate("ui.decoration_picker.badge_insufficient", _locale)
	_confirm_prompt_label.text = prompt_text


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


## Pure query for testing: returns deterministic catalog-ordered IDs of decorations unaffordable under the current currency context.
func get_unaffordable_decoration_ids() -> Array[String]:
	if _catalog == null or not _has_currency_context:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_decoration_ids():
		if not can_afford_decoration(def_id):
			result.append(def_id)
	return result


## Pure query for testing: returns the catalog price for [param definition_id], or -1 if unknown.
func get_price_for_id(definition_id: String) -> int:
	if _catalog == null or not _catalog.has_decoration(definition_id):
		return -1
	var def: DecorationDefinition = _catalog.get_decoration(definition_id)
	return def.price if def != null else -1


## Pure query for testing: returns count of distinct decoration definitions currently placed in the bound GardenSnapshot.
func get_placed_decoration_species_count() -> int:
	return get_placed_decoration_ids().size()


## Pure query for testing: returns total placed decoration instances in the bound GardenSnapshot, or 0.
func get_total_placed_decoration_count() -> int:
	return _snapshot.get_total_decoration_count() if _snapshot != null else 0


## Pure query for testing: returns count of catalog decorations affordable under the current currency context.
func get_affordable_decoration_count() -> int:
	return get_affordable_decoration_ids().size()


## Pure query for testing: returns additional coins needed to afford [param definition_id] (0 if affordable or no currency context, -1 if unknown).
func get_coins_needed_for_id(definition_id: String) -> int:
	if _catalog == null or not _catalog.has_decoration(definition_id):
		return -1
	if not _has_currency_context:
		return 0
	var def: DecorationDefinition = _catalog.get_decoration(definition_id)
	if def == null:
		return -1
	return maxi(0, def.price - _available_currency)


## Pure query for testing: returns count of distinct decoration definitions not yet placed in the bound GardenSnapshot.
func get_unplaced_decoration_species_count() -> int:
	return get_unplaced_decoration_ids().size()


## Pure query for testing: returns count of catalog decorations unaffordable under the current currency context.
func get_unaffordable_decoration_count() -> int:
	return get_unaffordable_decoration_ids().size()


## Pure query for testing: returns true if [param definition_id] exists in the bound catalog and exposes [param trait_id].
func has_decoration_trait(definition_id: String, trait_id: String) -> bool:
	if trait_id.is_empty() or _catalog == null or not _catalog.has_decoration(definition_id):
		return false
	var def: DecorationDefinition = _catalog.get_decoration(definition_id)
	return def != null and def.environmental_traits.has(trait_id)


## Pure query for testing: returns deterministic catalog-ordered decoration IDs that expose [param trait_id].
func get_decoration_ids_with_trait(trait_id: String) -> Array[String]:
	if trait_id.is_empty() or _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_decoration_ids():
		if has_decoration_trait(def_id, trait_id):
			result.append(def_id)
	return result


## Pure query for testing: returns count of catalog decoration definitions that expose [param trait_id].
func get_decoration_count_with_trait(trait_id: String) -> int:
	return get_decoration_ids_with_trait(trait_id).size()


## Pure query for testing: returns total decoration definitions in the bound catalog, or 0 if unbound.
func get_total_catalog_decoration_count() -> int:
	return _catalog.get_decoration_count() if _catalog != null else 0


## Pure query for testing: returns true if all catalog decoration definitions are currently placed in the bound GardenSnapshot.
func is_all_decoration_species_placed() -> bool:
	var total: int = get_total_catalog_decoration_count()
	return total > 0 and get_placed_decoration_species_count() >= total


## Pure query for testing: returns true if all catalog decoration definitions are affordable under the current currency context.
func is_all_decorations_affordable() -> bool:
	var total: int = get_total_catalog_decoration_count()
	return total > 0 and get_affordable_decoration_count() >= total


## Pure query for testing: returns the localized display name for [param definition_id] if present in the bound catalog, or "" if unknown/unbound.
func get_decoration_display_name_for_id(definition_id: String) -> String:
	if _catalog == null or not _catalog.has_decoration(definition_id):
		return ""
	return GardenLocalization.get_decoration_name(definition_id, _locale, _catalog.get_decoration(definition_id))


## Pure query for testing: returns the count of environmental traits for [param definition_id] in the bound catalog, or 0 if unknown.
func get_decoration_trait_count_for_id(definition_id: String) -> int:
	return get_decoration_traits_for_id(definition_id).size()


## Pure query for testing: returns true if at least one decoration is currently placed in the bound GardenSnapshot.
func has_any_placed_decorations() -> bool:
	return get_total_placed_decoration_count() > 0


## Pure query for testing: returns true if at least one catalog decoration is affordable under the current currency context.
func has_any_affordable_decorations() -> bool:
	return get_affordable_decoration_count() > 0


## Pure query for testing: returns true if an explicit currency context has been bound to the picker.
func has_currency_context() -> bool:
	return _has_currency_context


## Pure query for testing: returns true if [param definition_id] exists in the bound catalog.
func has_decoration_in_catalog(definition_id: String) -> bool:
	return not definition_id.is_empty() and _catalog != null and _catalog.has_decoration(definition_id)


## Pure query for testing: returns true if at least one catalog decoration species is not yet placed in the bound GardenSnapshot.
func has_any_unplaced_decorations() -> bool:
	return get_unplaced_decoration_species_count() > 0


## Pure query for testing: returns true if at least one catalog decoration is unaffordable under the current currency context.
func has_any_unaffordable_decorations() -> bool:
	return get_unaffordable_decoration_count() > 0


## Pure query for testing: returns true if a ContentCatalog is bound to this picker.
func has_bound_catalog() -> bool:
	return _catalog != null


## Pure query for testing: returns true if a GardenSnapshot is bound to this picker.
func has_bound_snapshot() -> bool:
	return _snapshot != null


## Pure query for testing: returns true if a decoration definition is currently pending confirmation.
func has_pending_selection() -> bool:
	return not _pending_definition_id.is_empty()


## Pure query for testing: returns true if a decoration definition is currently pending confirmation and is placed in the bound GardenSnapshot.
func is_pending_decoration_placed() -> bool:
	return not _pending_definition_id.is_empty() and is_decoration_placed(_pending_definition_id)


## Pure query for testing: returns true if a decoration definition is currently pending confirmation and is affordable under the current currency context.
func can_afford_pending_decoration() -> bool:
	return not _pending_definition_id.is_empty() and can_afford_decoration(_pending_definition_id)


## Pure query for testing: returns catalog price for the pending decoration definition, or -1 if none is pending.
func get_pending_decoration_price() -> int:
	return get_price_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else -1


## Pure query for testing: returns placed count for the pending decoration definition, or 0 if none is pending.
func get_pending_decoration_placed_count() -> int:
	return get_placed_count_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else 0


## Pure query for testing: returns additional coins needed for the pending decoration definition, or -1 if none is pending.
func get_pending_decoration_coins_needed() -> int:
	return get_coins_needed_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else -1


## Pure query for testing: returns the localized Thai display name for the pending decoration definition, or "" if none is pending.
func get_pending_decoration_display_name() -> String:
	return get_decoration_display_name_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else ""


## Pure query for testing: returns a defensive copy of environmental traits for the pending decoration definition, or [] if none is pending.
func get_pending_decoration_traits() -> Array[String]:
	return get_decoration_traits_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else []


## Pure query for testing: returns the count of environmental traits for the pending decoration definition, or 0 if none is pending.
func get_pending_decoration_trait_count() -> int:
	return get_decoration_trait_count_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else 0


## Pure query for testing: returns true if a decoration definition is pending confirmation and exposes at least one environmental trait.
func has_pending_decoration_any_traits() -> bool:
	return get_pending_decoration_trait_count() > 0


## Pure query for testing: returns true if a decoration definition is pending confirmation and exposes [param trait_id].
func has_pending_decoration_trait(trait_id: String) -> bool:
	return not _pending_definition_id.is_empty() and has_decoration_trait(_pending_definition_id, trait_id)


## Pure query for testing: returns formatted option button text for the pending decoration definition, or "" if none is pending.
func get_pending_decoration_option_text() -> String:
	return get_decoration_option_text_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else ""


## Pure query for testing: returns the number of rendered decoration option buttons.
func get_decoration_button_count() -> int:
	return _decoration_buttons.size()


## Pure query for testing: returns true if the confirmation prompt label has non-empty text.
func has_confirm_prompt_text() -> bool:
	return not get_confirm_prompt_text().is_empty()


## Pure query for testing: returns localized Thai traits summary string for [param definition_id] in the bound catalog, or "" if unknown/unbound.
func get_decoration_traits_summary_for_id(definition_id: String) -> String:
	if _catalog == null or not _catalog.has_decoration(definition_id):
		return ""
	return _format_traits_summary(_catalog.get_decoration(definition_id))


## Pure query for testing: returns localized Thai traits summary string for the pending decoration definition, or "" if none is pending.
func get_pending_decoration_traits_summary() -> String:
	return get_decoration_traits_summary_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else ""


## Pure query for testing: returns true if [param definition_id] is in the localized decoration catalog.
func is_known_decoration_definition(definition_id: String) -> bool:
	return GardenLocalization.is_known_decoration_id(definition_id)


## Pure query for testing: returns true if [param trait_id] is in the localized trait catalog.
func is_known_environmental_trait(trait_id: String) -> bool:
	return GardenLocalization.is_known_trait_id(trait_id)


## Pure query for testing: returns the localized display name for [param trait_id], or "" if empty.
func get_trait_display_name_for_id(trait_id: String) -> String:
	return GardenLocalization.get_trait_name(trait_id, _locale)


## Pure query for testing: returns localized display names for environmental traits of [param definition_id] in the bound catalog, or [] if unknown/unbound.
func get_decoration_trait_display_names_for_id(definition_id: String) -> Array[String]:
	var result: Array[String] = []
	for trait_id: String in get_decoration_traits_for_id(definition_id):
		result.append(GardenLocalization.get_trait_name(trait_id, _locale))
	return result


## Pure query for testing: returns localized Thai display names for environmental traits of the pending decoration definition, or [] if none is pending.
func get_pending_decoration_trait_display_names() -> Array[String]:
	return get_decoration_trait_display_names_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else []


## Pure query for testing: returns true if [param definition_id] in the bound catalog exposes at least one environmental trait.
func has_decoration_any_traits(definition_id: String) -> bool:
	return get_decoration_trait_count_for_id(definition_id) > 0


## Pure query for testing: returns localized Thai display names for all catalog decorations in deterministic catalog order, or [] if unbound.
func get_available_decoration_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_available_decoration_ids():
		result.append(get_decoration_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all currently placed catalog decorations in deterministic catalog order, or [] if unbound.
func get_placed_decoration_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_placed_decoration_ids():
		result.append(get_decoration_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all unplaced catalog decorations in deterministic catalog order, or [] if unbound.
func get_unplaced_decoration_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_unplaced_decoration_ids():
		result.append(get_decoration_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all affordable catalog decorations in deterministic catalog order, or [] if unbound.
func get_affordable_decoration_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_affordable_decoration_ids():
		result.append(get_decoration_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all unaffordable catalog decorations in deterministic catalog order, or [] if unbound.
func get_unaffordable_decoration_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_unaffordable_decoration_ids():
		result.append(get_decoration_display_name_for_id(def_id))
	return result


## Pure query for testing: returns true if a decoration definition is pending confirmation and is in the provisional localized decoration display dictionary.
func is_pending_decoration_known_definition() -> bool:
	return not _pending_definition_id.is_empty() and is_known_decoration_definition(_pending_definition_id)


## Pure query for testing: returns localized Thai display names for catalog decorations that expose [param trait_id] in deterministic catalog order, or [] if empty/unbound.
func get_decoration_display_names_with_trait(trait_id: String) -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_decoration_ids_with_trait(trait_id):
		result.append(get_decoration_display_name_for_id(def_id))
	return result


## Pure query for testing: returns true if at least one catalog decoration exposes [param trait_id].
func has_any_decorations_with_trait(trait_id: String) -> bool:
	return get_decoration_count_with_trait(trait_id) > 0


## Pure query for testing: returns true if a decoration definition is pending confirmation and exists in the bound catalog.
func is_pending_decoration_in_catalog() -> bool:
	return not _pending_definition_id.is_empty() and has_decoration_in_catalog(_pending_definition_id)


## Pure query for testing: returns true if a decoration definition is pending confirmation and has a positive price.
func has_pending_decoration_positive_price() -> bool:
	return get_pending_decoration_price() > 0


## Pure query for testing: returns true if a decoration definition is pending confirmation and is NOT affordable under the current currency context.
func is_pending_decoration_unaffordable() -> bool:
	return not _pending_definition_id.is_empty() and has_decoration_in_catalog(_pending_definition_id) and not can_afford_decoration(_pending_definition_id)


## Pure query for testing: returns true if a decoration definition is pending confirmation and is NOT currently placed in the bound GardenSnapshot.
func is_pending_decoration_unplaced() -> bool:
	return not _pending_definition_id.is_empty() and has_decoration_in_catalog(_pending_definition_id) and not is_decoration_placed(_pending_definition_id)


## Pure query for testing: returns true if a decoration definition is pending confirmation and requires additional coins (> 0) under the current currency context.
func has_pending_decoration_coins_needed() -> bool:
	return get_pending_decoration_coins_needed() > 0


## Pure query for testing: returns true if a decoration definition is pending confirmation and has a non-empty localized traits summary string.
func has_pending_decoration_traits_summary() -> bool:
	return not get_pending_decoration_traits_summary().is_empty()


## Pure query for testing: returns true if a decoration definition is pending confirmation and has a non-empty formatted option button text.
func has_pending_decoration_option_text() -> bool:
	return not get_pending_decoration_option_text().is_empty()


## Pure query for testing: returns true if a decoration definition is pending confirmation and has a non-empty localized display name.
func has_pending_decoration_display_name() -> bool:
	return not get_pending_decoration_display_name().is_empty()


## Pure query for testing: returns true if [param definition_id] has a non-empty formatted option button text in the picker.
func has_decoration_option_text_for_id(definition_id: String) -> bool:
	return not get_decoration_option_text_for_id(definition_id).is_empty()


## Pure query for testing: returns true if [param definition_id] has a non-empty localized display name in the bound catalog.
func has_decoration_display_name_for_id(definition_id: String) -> bool:
	return not get_decoration_display_name_for_id(definition_id).is_empty()


## Pure query for testing: returns true if [param definition_id] has a non-empty localized environmental traits summary in the bound catalog.
func has_decoration_traits_summary_for_id(definition_id: String) -> bool:
	return not get_decoration_traits_summary_for_id(definition_id).is_empty()


## Pure query for testing: returns true if [param definition_id] in the bound catalog has a positive price (> 0).
func has_decoration_positive_price_for_id(definition_id: String) -> bool:
	return get_price_for_id(definition_id) > 0


## Pure query for testing: returns true if [param definition_id] in the bound catalog requires additional coins (> 0) under the current currency context.
func has_decoration_coins_needed_for_id(definition_id: String) -> bool:
	return get_coins_needed_for_id(definition_id) > 0


## Pure query for testing: returns true if [param definition_id] exists in the bound catalog and is NOT currently placed in the bound GardenSnapshot.
func is_decoration_unplaced(definition_id: String) -> bool:
	return has_decoration_in_catalog(definition_id) and not is_decoration_placed(definition_id)


## Pure query for testing: returns true if [param definition_id] exists in the bound catalog and is NOT affordable under the current currency context.
func is_decoration_unaffordable(definition_id: String) -> bool:
	return _has_currency_context and has_decoration_in_catalog(definition_id) and not can_afford_decoration(definition_id)


## Pure query for testing: returns true if at least one decoration definition exists in the bound catalog.
func has_available_decorations() -> bool:
	return get_total_catalog_decoration_count() > 0


## Pure query for testing: returns true if at least one decoration option button is rendered in the picker.
func has_rendered_decoration_buttons() -> bool:
	return get_decoration_button_count() > 0


## Pure query for testing: returns true if an explicit currency context is bound with a positive available currency balance (> 0).
func has_positive_available_currency() -> bool:
	return _has_currency_context and _available_currency > 0
