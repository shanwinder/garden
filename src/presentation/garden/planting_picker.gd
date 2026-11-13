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
signal ui_tapped()

var _catalog: ContentCatalog = null
var _snapshot: GardenSnapshot = null
var _journal: JournalState = null
var _pending_definition_id: String = ""
var _is_dispatching_confirmation: bool = false
var _is_enabled: bool = true
var _locale: String = GardenLocalization.DEFAULT_LOCALE
var _option_texts_by_id: Dictionary = {}

var _title_label: Label = null
var _close_button: Button = null
var _note_label: Label = null
var _plant_list_container: Container = null
var _confirmation_overlay: Control = null
var _confirm_title_label: Label = null
var _confirm_prompt_label: Label = null
var _confirm_notice_label: Label = null
var _confirm_button: Button = null
var _cancel_button: Button = null
var _plant_buttons: Array[Button] = []


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
	if _plant_list_container == null:
		_plant_list_container = get_node_or_null("CenterContainer/PickerPanel/MarginContainer/VBoxContainer/ScrollContainer/ListMargin/PlantListContainer") as Container
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
	if _confirm_button != null and not _confirm_button.pressed.is_connected(confirm_planting):
		_confirm_button.pressed.connect(confirm_planting)
	if _cancel_button != null and not _cancel_button.pressed.is_connected(_on_cancel_button_pressed):
		_cancel_button.pressed.connect(_on_cancel_button_pressed)


## Binds a validated ContentCatalog and populates plant choices in catalog order.
func bind_catalog(catalog: ContentCatalog) -> void:
	_catalog = catalog
	_pending_definition_id = ""
	_resolve_nodes()
	_apply_static_texts()
	_clear_plant_buttons()

	if _confirmation_overlay != null:
		_confirmation_overlay.visible = false

	if _catalog == null or _catalog.get_plant_count() == 0:
		return

	var plant_ids: Array[String] = _catalog.get_all_plant_ids()
	for def_id: String in plant_ids:
		var btn: Button = Button.new()
		btn.text = _format_plant_button_text(def_id)
		_option_texts_by_id[def_id] = btn.text
		btn.custom_minimum_size = Vector2(0, 72)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_ALL
		btn.add_theme_font_size_override("font_size", 21)
		_apply_button_icon(btn, def_id)
		btn.disabled = not _is_enabled
		btn.pressed.connect(_on_plant_option_pressed.bind(def_id))
		_plant_buttons.append(btn)
		if _plant_list_container != null:
			_plant_list_container.add_child(btn)


func _apply_button_icon(btn: Button, def_id: String) -> void:
	if btn == null:
		return
	var tex: Texture2D = GardenAssetCatalog.get_plant_texture(def_id, PlantGrowth.Stage.MATURE)
	btn.icon = tex
	btn.expand_icon = (tex != null)
	if tex != null:
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_constant_override("icon_max_width", 56)
		btn.add_theme_constant_override("h_separation", 12)


## Sets active display locale ("th" or "en") and refreshes picker labels in-place.
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
		_title_label.text = GardenLocalization.translate("ui.planting_picker.title", _locale)
	if _close_button != null:
		_close_button.text = GardenLocalization.translate("ui.common.close", _locale)
	if _note_label != null:
		_note_label.text = GardenLocalization.translate("ui.planting_picker.note", _locale)
	if _confirm_title_label != null:
		_confirm_title_label.text = GardenLocalization.translate("ui.planting_picker.confirm_title", _locale)
	if _confirm_notice_label != null:
		_confirm_notice_label.text = GardenLocalization.translate("ui.planting_picker.confirm_notice", _locale)
	if _cancel_button != null:
		_cancel_button.text = GardenLocalization.translate("ui.common.cancel", _locale)
	if _confirm_button != null:
		_confirm_button.text = GardenLocalization.translate("ui.common.confirm", _locale)


## Updates optional read-only GardenSnapshot and JournalState context and refreshes button labels in-place.
func update_garden_context(snapshot: GardenSnapshot, journal: JournalState = null) -> void:
	_snapshot = snapshot
	_journal = journal
	_refresh_button_labels()


func _refresh_button_labels() -> void:
	_option_texts_by_id.clear()
	if _catalog == null:
		return
	var plant_ids: Array[String] = _catalog.get_all_plant_ids()
	for idx: int in range(mini(plant_ids.size(), _plant_buttons.size())):
		var def_id: String = plant_ids[idx]
		var formatted: String = _format_plant_button_text(def_id)
		_option_texts_by_id[def_id] = formatted
		var btn: Button = _plant_buttons[idx]
		if is_instance_valid(btn):
			btn.text = formatted


func _format_plant_button_text(def_id: String) -> String:
	var def: PlantDefinition = _catalog.get_plant(def_id) if _catalog != null else null
	var display_name: String = GardenLocalization.get_plant_name(def_id, _locale, def)
	if def == null:
		return "%s (%s)" % [display_name, def_id]

	var details: PackedStringArray = PackedStringArray()
	if def.mature_after_seconds > 0:
		details.append(GardenLocalization.format_key("ui.planting_picker.mature_seconds", [def.mature_after_seconds], _locale))
	if def.harvest_reward > 0:
		details.append(GardenLocalization.format_key("ui.planting_picker.reward_coins", [def.harvest_reward], _locale))
	if not def.environmental_traits.is_empty():
		details.append(GardenLocalization.format_key("ui.planting_picker.traits", [_format_traits_summary(def)], _locale))
	if _snapshot != null:
		details.append(GardenLocalization.format_key("ui.planting_picker.planted_count", [_snapshot.get_plant_count_for_definition(def_id)], _locale))

	var formatted: String = (
		"%s (%s)" % [display_name, def_id]
		if details.is_empty()
		else "%s (%s) — %s" % [display_name, def_id, " | ".join(details)]
	)
	if _journal != null:
		formatted += GardenLocalization.translate(
			"ui.planting_picker.badge_discovered" if _journal.has_discovered(def_id) else "ui.planting_picker.badge_new",
			_locale
		)
	return formatted


func _format_traits_summary(def: PlantDefinition) -> String:
	if def == null or def.environmental_traits.is_empty():
		return ""
	var parts: PackedStringArray = PackedStringArray()
	for trait_id: String in def.environmental_traits:
		parts.append(GardenLocalization.get_trait_name(trait_id, _locale))
	return ", ".join(parts)


func _clear_plant_buttons() -> void:
	_plant_buttons.clear()
	_option_texts_by_id.clear()
	if _plant_list_container == null:
		return
	for child: Node in _plant_list_container.get_children():
		_plant_list_container.remove_child(child)
		child.queue_free()


func _on_plant_option_pressed(definition_id: String) -> void:
	if _is_enabled:
		ui_tapped.emit()
	select_plant_definition(definition_id)


func _on_close_button_pressed() -> void:
	ui_tapped.emit()
	close_picker()


func _on_cancel_button_pressed() -> void:
	ui_tapped.emit()
	cancel_confirmation()


## Selects a plant definition and displays the confirmation prompt without emitting planting request.
func select_plant_definition(definition_id: String) -> void:
	if not _is_enabled:
		return
	if _catalog == null or not _catalog.has_plant(definition_id):
		return

	_pending_definition_id = definition_id
	_resolve_nodes()
	_update_confirm_prompt_text(definition_id)

	if _confirmation_overlay != null:
		_confirmation_overlay.visible = true


func _update_confirm_prompt_text(definition_id: String) -> void:
	if _confirm_prompt_label == null:
		return
	var def: PlantDefinition = _catalog.get_plant(definition_id) if _catalog != null else null
	var display_name: String = GardenLocalization.get_plant_name(definition_id, _locale, def)
	var prompt_text: String = GardenLocalization.format_key("ui.planting_picker.prompt_simple", [display_name], _locale)
	if def != null and (def.mature_after_seconds > 0 or def.harvest_reward > 0):
		var prompt_parts: PackedStringArray = PackedStringArray()
		prompt_parts.append(GardenLocalization.format_key("ui.planting_picker.mature_seconds", [def.mature_after_seconds], _locale))
		prompt_parts.append(GardenLocalization.format_key("ui.planting_picker.reward_coins", [def.harvest_reward], _locale))
		var traits_summary: String = _format_traits_summary(def)
		if not traits_summary.is_empty():
			prompt_parts.append(GardenLocalization.format_key("ui.planting_picker.traits", [traits_summary], _locale))
		if _snapshot != null:
			prompt_parts.append(
				GardenLocalization.format_key("ui.planting_picker.planted_count", [_snapshot.get_plant_count_for_definition(definition_id)], _locale)
			)
		prompt_text = GardenLocalization.format_key(
			"ui.planting_picker.prompt_details",
			[display_name, " | ".join(prompt_parts)],
			_locale
		)
	elif _snapshot != null:
		prompt_text = GardenLocalization.format_key(
			"ui.planting_picker.prompt_planted_only",
			[display_name, _snapshot.get_plant_count_for_definition(definition_id)],
			_locale
		)
	if _journal != null:
		prompt_text += GardenLocalization.translate(
			"ui.planting_picker.badge_discovered" if _journal.has_discovered(definition_id) else "ui.planting_picker.badge_new",
			_locale
		)
	_confirm_prompt_label.text = prompt_text


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


## Pure query for testing: returns current planted count for [param definition_id] from the bound GardenSnapshot, or 0.
func get_planted_count_for_id(definition_id: String) -> int:
	return _snapshot.get_plant_count_for_definition(definition_id) if _snapshot != null else 0


## Pure query for testing: returns formatted option button text for [param definition_id].
func get_plant_option_text_for_id(definition_id: String) -> String:
	return _option_texts_by_id.get(definition_id, "")


## Pure query for testing: returns true if [param definition_id] has been discovered in the bound JournalState.
func is_plant_discovered(definition_id: String) -> bool:
	return _journal != null and _journal.has_discovered(definition_id)


## Pure query for testing: returns deterministic catalog-ordered IDs of plants not yet discovered in the bound JournalState.
func get_undiscovered_plant_ids() -> Array[String]:
	if _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_plant_ids():
		if _journal == null or not _journal.has_discovered(def_id):
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of plants already discovered in the bound JournalState.
func get_discovered_plant_ids() -> Array[String]:
	if _catalog == null or _journal == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_plant_ids():
		if _journal.has_discovered(def_id):
			result.append(def_id)
	return result


## Pure query for testing: returns a defensive copy of environmental traits for [param definition_id] in the bound catalog, or [].
func get_plant_traits_for_id(definition_id: String) -> Array[String]:
	if _catalog == null or not _catalog.has_plant(definition_id):
		return []
	var def: PlantDefinition = _catalog.get_plant(definition_id)
	return def.environmental_traits.duplicate() if def != null else []


## Pure query for testing: returns mature_after_seconds for [param definition_id] in the bound catalog, or 0 if unknown.
func get_mature_after_seconds_for_id(definition_id: String) -> int:
	if _catalog == null or not _catalog.has_plant(definition_id):
		return 0
	var def: PlantDefinition = _catalog.get_plant(definition_id)
	return maxi(0, def.mature_after_seconds) if def != null else 0


## Pure query for testing: returns harvest_reward for [param definition_id] in the bound catalog, or 0 if unknown.
func get_harvest_reward_for_id(definition_id: String) -> int:
	if _catalog == null or not _catalog.has_plant(definition_id):
		return 0
	var def: PlantDefinition = _catalog.get_plant(definition_id)
	return maxi(0, def.harvest_reward) if def != null else 0


## Pure query for testing: returns deterministic catalog-ordered IDs of plants currently planted in the bound GardenSnapshot.
func get_planted_plant_ids() -> Array[String]:
	if _catalog == null or _snapshot == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_plant_ids():
		if _snapshot.get_plant_count_for_definition(def_id) > 0:
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of plants not currently planted in the bound GardenSnapshot.
func get_unplanted_plant_ids() -> Array[String]:
	if _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_plant_ids():
		if _snapshot == null or _snapshot.get_plant_count_for_definition(def_id) <= 0:
			result.append(def_id)
	return result


## Pure query for testing: returns true if [param definition_id] is currently planted in the bound GardenSnapshot.
func is_plant_currently_planted(definition_id: String) -> bool:
	return _snapshot != null and _snapshot.get_plant_count_for_definition(definition_id) > 0


## Pure query for testing: returns sprout_after_seconds for [param definition_id] in the bound catalog, or 0 if unknown.
func get_sprout_after_seconds_for_id(definition_id: String) -> int:
	if _catalog == null or not _catalog.has_plant(definition_id):
		return 0
	var def: PlantDefinition = _catalog.get_plant(definition_id)
	return maxi(0, def.sprout_after_seconds) if def != null else 0


## Pure query for testing: returns growing_after_seconds for [param definition_id] in the bound catalog, or 0 if unknown.
func get_growing_after_seconds_for_id(definition_id: String) -> int:
	if _catalog == null or not _catalog.has_plant(definition_id):
		return 0
	var def: PlantDefinition = _catalog.get_plant(definition_id)
	return maxi(0, def.growing_after_seconds) if def != null else 0


## Pure query for testing: returns count of distinct plant definitions currently planted in the bound GardenSnapshot.
func get_planted_species_count() -> int:
	return get_planted_plant_ids().size()


## Pure query for testing: returns count of discovered plant definitions in the bound JournalState.
func get_discovered_plant_count() -> int:
	return get_discovered_plant_ids().size()


## Pure query for testing: returns total planted instances across all species in the bound GardenSnapshot, or 0.
func get_total_planted_instance_count() -> int:
	return _snapshot.get_total_plant_count() if _snapshot != null else 0


## Pure query for testing: returns count of undiscovered plant definitions in the bound JournalState.
func get_undiscovered_plant_count() -> int:
	return get_undiscovered_plant_ids().size()


## Pure query for testing: returns count of distinct plant definitions not currently planted in the bound GardenSnapshot.
func get_unplanted_species_count() -> int:
	return get_unplanted_plant_ids().size()


## Pure query for testing: returns true if [param definition_id] exists in the bound catalog and exposes [param trait_id].
func has_plant_trait(definition_id: String, trait_id: String) -> bool:
	if trait_id.is_empty() or _catalog == null or not _catalog.has_plant(definition_id):
		return false
	var def: PlantDefinition = _catalog.get_plant(definition_id)
	return def != null and def.environmental_traits.has(trait_id)


## Pure query for testing: returns deterministic catalog-ordered plant IDs that expose [param trait_id].
func get_plant_ids_with_trait(trait_id: String) -> Array[String]:
	if trait_id.is_empty() or _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_plant_ids():
		if has_plant_trait(def_id, trait_id):
			result.append(def_id)
	return result


## Pure query for testing: returns count of catalog plant definitions that expose [param trait_id].
func get_plant_count_with_trait(trait_id: String) -> int:
	return get_plant_ids_with_trait(trait_id).size()


## Pure query for testing: returns total plant definitions in the bound catalog, or 0 if unbound.
func get_total_catalog_plant_count() -> int:
	return _catalog.get_plant_count() if _catalog != null else 0


## Pure query for testing: returns true if all catalog plant definitions have been discovered in the bound JournalState.
func is_all_plants_discovered() -> bool:
	var total: int = get_total_catalog_plant_count()
	return total > 0 and get_discovered_plant_count() >= total


## Pure query for testing: returns true if all catalog plant definitions are currently planted in the bound GardenSnapshot.
func is_all_plant_species_planted() -> bool:
	var total: int = get_total_catalog_plant_count()
	return total > 0 and get_planted_species_count() >= total


## Pure query for testing: returns the localized display name for [param definition_id] if present in the bound catalog, or "" if unknown/unbound.
func get_plant_display_name_for_id(definition_id: String) -> String:
	if _catalog == null or not _catalog.has_plant(definition_id):
		return ""
	return GardenLocalization.get_plant_name(definition_id, _locale, _catalog.get_plant(definition_id))


## Pure query for testing: returns the count of environmental traits for [param definition_id] in the bound catalog, or 0 if unknown.
func get_plant_trait_count_for_id(definition_id: String) -> int:
	return get_plant_traits_for_id(definition_id).size()


## Pure query for testing: returns true if at least one plant is currently planted in the bound GardenSnapshot.
func has_any_planted_plants() -> bool:
	return get_total_planted_instance_count() > 0


## Pure query for testing: returns true if at least one catalog plant has been discovered in the bound JournalState.
func has_any_discovered_plants() -> bool:
	return get_discovered_plant_count() > 0


## Pure query for testing: returns true if [param definition_id] exists in the bound catalog.
func has_plant_in_catalog(definition_id: String) -> bool:
	return not definition_id.is_empty() and _catalog != null and _catalog.has_plant(definition_id)


## Pure query for testing: returns true if at least one catalog plant is not yet discovered in the bound JournalState.
func has_any_undiscovered_plants() -> bool:
	return get_undiscovered_plant_count() > 0


## Pure query for testing: returns true if at least one catalog plant species is not currently planted in the bound GardenSnapshot.
func has_any_unplanted_plants() -> bool:
	return get_unplanted_species_count() > 0


## Pure query for testing: returns true if a ContentCatalog is bound to this picker.
func has_bound_catalog() -> bool:
	return _catalog != null


## Pure query for testing: returns true if a GardenSnapshot is bound to this picker.
func has_bound_snapshot() -> bool:
	return _snapshot != null


## Pure query for testing: returns true if a JournalState is bound to this picker.
func has_bound_journal() -> bool:
	return _journal != null


## Pure query for testing: returns true if a plant definition is currently pending confirmation.
func has_pending_selection() -> bool:
	return not _pending_definition_id.is_empty()


## Pure query for testing: returns true if a plant definition is currently pending confirmation and has been discovered in the bound JournalState.
func is_pending_plant_discovered() -> bool:
	return not _pending_definition_id.is_empty() and is_plant_discovered(_pending_definition_id)


## Pure query for testing: returns true if a plant definition is currently pending confirmation and has at least one planted instance in the bound GardenSnapshot.
func is_pending_plant_currently_planted() -> bool:
	return not _pending_definition_id.is_empty() and is_plant_currently_planted(_pending_definition_id)


## Pure query for testing: returns current planted count for the pending plant definition, or 0 if none is pending.
func get_pending_plant_planted_count() -> int:
	return get_planted_count_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else 0


## Pure query for testing: returns catalog harvest_reward for the pending plant definition, or 0 if none is pending.
func get_pending_plant_harvest_reward() -> int:
	return get_harvest_reward_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else 0


## Pure query for testing: returns catalog mature_after_seconds for the pending plant definition, or 0 if none is pending.
func get_pending_plant_mature_after_seconds() -> int:
	return get_mature_after_seconds_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else 0


## Pure query for testing: returns the localized Thai display name for the pending plant definition, or "" if none is pending.
func get_pending_plant_display_name() -> String:
	return get_plant_display_name_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else ""


## Pure query for testing: returns a defensive copy of environmental traits for the pending plant definition, or [] if none is pending.
func get_pending_plant_traits() -> Array[String]:
	return get_plant_traits_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else []


## Pure query for testing: returns the count of environmental traits for the pending plant definition, or 0 if none is pending.
func get_pending_plant_trait_count() -> int:
	return get_plant_trait_count_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else 0


## Pure query for testing: returns true if a plant definition is pending confirmation and exposes at least one environmental trait.
func has_pending_plant_any_traits() -> bool:
	return get_pending_plant_trait_count() > 0


## Pure query for testing: returns catalog sprout_after_seconds for the pending plant definition, or 0 if none is pending.
func get_pending_plant_sprout_after_seconds() -> int:
	return get_sprout_after_seconds_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else 0


## Pure query for testing: returns catalog growing_after_seconds for the pending plant definition, or 0 if none is pending.
func get_pending_plant_growing_after_seconds() -> int:
	return get_growing_after_seconds_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else 0


## Pure query for testing: returns true if a plant definition is pending confirmation and exposes [param trait_id].
func has_pending_plant_trait(trait_id: String) -> bool:
	return not _pending_definition_id.is_empty() and has_plant_trait(_pending_definition_id, trait_id)


## Pure query for testing: returns formatted option button text for the pending plant definition, or "" if none is pending.
func get_pending_plant_option_text() -> String:
	return get_plant_option_text_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else ""


## Pure query for testing: returns the number of rendered plant option buttons.
func get_plant_button_count() -> int:
	return _plant_buttons.size()


## Pure query for testing: returns true if the confirmation prompt label has non-empty text.
func has_confirm_prompt_text() -> bool:
	return not get_confirm_prompt_text().is_empty()


## Pure query for testing: returns localized Thai traits summary string for [param definition_id] in the bound catalog, or "" if unknown/empty.
func get_plant_traits_summary_for_id(definition_id: String) -> String:
	if _catalog == null or not _catalog.has_plant(definition_id):
		return ""
	return _format_traits_summary(_catalog.get_plant(definition_id))


## Pure query for testing: returns localized Thai traits summary string for the pending plant definition, or "" if none is pending.
func get_pending_plant_traits_summary() -> String:
	return get_plant_traits_summary_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else ""


## Pure query for testing: returns true if [param definition_id] is in the localized plant catalog.
func is_known_plant_definition(definition_id: String) -> bool:
	return GardenLocalization.is_known_plant_id(definition_id)


## Pure query for testing: returns true if [param trait_id] is in the localized trait catalog.
func is_known_environmental_trait(trait_id: String) -> bool:
	return GardenLocalization.is_known_trait_id(trait_id)


## Pure query for testing: returns the localized display name for [param trait_id], or "" if empty.
func get_trait_display_name_for_id(trait_id: String) -> String:
	return GardenLocalization.get_trait_name(trait_id, _locale)


## Pure query for testing: returns localized display names for environmental traits of [param definition_id] in the bound catalog, or [] if unknown/unbound.
func get_plant_trait_display_names_for_id(definition_id: String) -> Array[String]:
	var result: Array[String] = []
	for trait_id: String in get_plant_traits_for_id(definition_id):
		result.append(GardenLocalization.get_trait_name(trait_id, _locale))
	return result


## Pure query for testing: returns localized Thai display names for environmental traits of the pending plant definition, or [] if none is pending.
func get_pending_plant_trait_display_names() -> Array[String]:
	return get_plant_trait_display_names_for_id(_pending_definition_id) if not _pending_definition_id.is_empty() else []


## Pure query for testing: returns true if [param definition_id] in the bound catalog exposes at least one environmental trait.
func has_plant_any_traits(definition_id: String) -> bool:
	return get_plant_trait_count_for_id(definition_id) > 0


## Pure query for testing: returns localized Thai display names for all catalog plants in deterministic catalog order, or [] if unbound.
func get_available_plant_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_available_plant_ids():
		result.append(get_plant_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all currently planted catalog plants in deterministic catalog order, or [] if unbound.
func get_planted_plant_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_planted_plant_ids():
		result.append(get_plant_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all unplanted catalog plants in deterministic catalog order, or [] if unbound.
func get_unplanted_plant_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_unplanted_plant_ids():
		result.append(get_plant_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all discovered catalog plants in deterministic catalog order, or [] if unbound.
func get_discovered_plant_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_discovered_plant_ids():
		result.append(get_plant_display_name_for_id(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all undiscovered catalog plants in deterministic catalog order, or [] if unbound.
func get_undiscovered_plant_display_names() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_undiscovered_plant_ids():
		result.append(get_plant_display_name_for_id(def_id))
	return result


## Pure query for testing: returns true if a plant definition is pending confirmation and is in the provisional localized plant display dictionary.
func is_pending_plant_known_definition() -> bool:
	return not _pending_definition_id.is_empty() and is_known_plant_definition(_pending_definition_id)


## Pure query for testing: returns localized Thai display names for catalog plants that expose [param trait_id] in deterministic catalog order, or [] if empty/unbound.
func get_plant_display_names_with_trait(trait_id: String) -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_plant_ids_with_trait(trait_id):
		result.append(get_plant_display_name_for_id(def_id))
	return result


## Pure query for testing: returns true if at least one catalog plant exposes [param trait_id].
func has_any_plants_with_trait(trait_id: String) -> bool:
	return get_plant_count_with_trait(trait_id) > 0


## Pure query for testing: returns true if a plant definition is pending confirmation and exists in the bound catalog.
func is_pending_plant_in_catalog() -> bool:
	return not _pending_definition_id.is_empty() and has_plant_in_catalog(_pending_definition_id)


## Pure query for testing: returns true if a plant definition is pending confirmation and has a positive harvest_reward.
func has_pending_plant_harvest_reward() -> bool:
	return get_pending_plant_harvest_reward() > 0


## Pure query for testing: returns true if a plant definition is pending confirmation and has a positive mature_after_seconds duration.
func has_pending_plant_mature_duration() -> bool:
	return get_pending_plant_mature_after_seconds() > 0


## Pure query for testing: returns true if a plant definition is pending confirmation and has NOT yet been discovered in the bound JournalState.
func is_pending_plant_undiscovered() -> bool:
	return not _pending_definition_id.is_empty() and has_plant_in_catalog(_pending_definition_id) and not is_plant_discovered(_pending_definition_id)


## Pure query for testing: returns true if a plant definition is pending confirmation and is NOT currently planted in the bound GardenSnapshot.
func is_pending_plant_unplanted() -> bool:
	return not _pending_definition_id.is_empty() and has_plant_in_catalog(_pending_definition_id) and not is_plant_currently_planted(_pending_definition_id)


## Pure query for testing: returns true if a plant definition is pending confirmation and has a positive sprout_after_seconds duration.
func has_pending_plant_sprout_duration() -> bool:
	return get_pending_plant_sprout_after_seconds() > 0


## Pure query for testing: returns true if a plant definition is pending confirmation and has a positive growing_after_seconds duration.
func has_pending_plant_growing_duration() -> bool:
	return get_pending_plant_growing_after_seconds() > 0


## Pure query for testing: returns true if a plant definition is pending confirmation and has a non-empty localized traits summary string.
func has_pending_plant_traits_summary() -> bool:
	return not get_pending_plant_traits_summary().is_empty()


## Pure query for testing: returns true if a plant definition is pending confirmation and has a non-empty formatted option button text.
func has_pending_plant_option_text() -> bool:
	return not get_pending_plant_option_text().is_empty()


## Pure query for testing: returns true if a plant definition is pending confirmation and has a non-empty localized display name.
func has_pending_plant_display_name() -> bool:
	return not get_pending_plant_display_name().is_empty()


## Pure query for testing: returns true if [param definition_id] has a non-empty formatted option button text in the picker.
func has_plant_option_text_for_id(definition_id: String) -> bool:
	return not get_plant_option_text_for_id(definition_id).is_empty()


## Pure query for testing: returns true if [param definition_id] has a non-empty localized display name in the bound catalog.
func has_plant_display_name_for_id(definition_id: String) -> bool:
	return not get_plant_display_name_for_id(definition_id).is_empty()


## Pure query for testing: returns true if [param definition_id] has a non-empty localized environmental traits summary in the bound catalog.
func has_plant_traits_summary_for_id(definition_id: String) -> bool:
	return not get_plant_traits_summary_for_id(definition_id).is_empty()


## Pure query for testing: returns true if [param definition_id] in the bound catalog has a positive harvest_reward (> 0).
func has_plant_positive_harvest_reward_for_id(definition_id: String) -> bool:
	return get_harvest_reward_for_id(definition_id) > 0


## Pure query for testing: returns true if [param definition_id] in the bound catalog has a positive mature_after_seconds duration (> 0).
func has_plant_positive_mature_duration_for_id(definition_id: String) -> bool:
	return get_mature_after_seconds_for_id(definition_id) > 0


## Pure query for testing: returns true if [param definition_id] in the bound catalog has a positive sprout_after_seconds duration (> 0).
func has_plant_positive_sprout_duration_for_id(definition_id: String) -> bool:
	return get_sprout_after_seconds_for_id(definition_id) > 0


## Pure query for testing: returns true if [param definition_id] in the bound catalog has a positive growing_after_seconds duration (> 0).
func has_plant_positive_growing_duration_for_id(definition_id: String) -> bool:
	return get_growing_after_seconds_for_id(definition_id) > 0


## Pure query for testing: returns true if [param definition_id] exists in the bound catalog and has NOT yet been discovered in the bound JournalState.
func is_plant_undiscovered(definition_id: String) -> bool:
	return has_plant_in_catalog(definition_id) and not is_plant_discovered(definition_id)


## Pure query for testing: returns true if [param definition_id] exists in the bound catalog and is NOT currently planted in the bound GardenSnapshot.
func is_plant_unplanted(definition_id: String) -> bool:
	return has_plant_in_catalog(definition_id) and not is_plant_currently_planted(definition_id)
