## plant_view.gd
## Presentation component representing one runtime plant in the garden.
##
## Architectural rules:
## - Belongs to the presentation layer (src/presentation/garden/).
## - Pure view/controller for one runtime plant item.
## - Does not own, mutate, or duplicate authoritative GameState.
## - Does not access save repository, filesystem, or network.
## - Does not maintain a separate plant model registry.
## - Identity is runtime_instance_id (String), never Godot ObjectID.
## - No per-plant timers, busy loops, or _process growth calculations.
## - Touch/click triggers selection notification via signal.
class_name PlantView
extends PanelContainer

signal plant_selected(runtime_instance_id: String)

const STAGE_ACCENT_PLANTED: Color = Color(0.82, 0.74, 0.58, 1.0)
const STAGE_ACCENT_SPROUT: Color = Color(0.62, 0.88, 0.64, 1.0)
const STAGE_ACCENT_GROWING: Color = Color(0.48, 0.86, 0.56, 1.0)
const STAGE_ACCENT_MATURE: Color = Color(0.96, 0.84, 0.38, 1.0)
const STAGE_ACCENT_INVALID: Color = Color(0.75, 0.70, 0.70, 1.0)

var _runtime_instance_id: String = ""
var _definition_id: String = ""
var _display_name: String = ""
var _planted_at: int = 0
var _stage: PlantGrowth.Stage = PlantGrowth.Stage.INVALID
var _harvest_reward: int = 0
var _seconds_until_next_stage: int = -1
var _seconds_until_mature: int = -1
var _environmental_traits: Array[String] = []
var _zone_id: String = GardenZone.ZONE_MAIN
var _grid_x: int = 0
var _grid_y: int = 0
var _is_selected: bool = false
var _locale: String = GardenLocalization.DEFAULT_LOCALE

var _name_label: Label = null
var _stage_label: Label = null
var _stage_badge: Label = null
var _id_label: Label = null
var _touch_button: Button = null
var _selection_highlight: Panel = null


func _ready() -> void:
	_resolve_nodes()
	if _touch_button != null and not _touch_button.pressed.is_connected(_on_touch_button_pressed):
		_touch_button.pressed.connect(_on_touch_button_pressed)
	_render()


## Resolves child node references safely whether _ready has fired or not.
func _resolve_nodes() -> void:
	if _name_label == null:
		_name_label = get_node_or_null("MarginContainer/VBoxContainer/PlantNameLabel") as Label
	if _stage_label == null:
		_stage_label = get_node_or_null("MarginContainer/VBoxContainer/StageContainer/StageLabel") as Label
	if _stage_badge == null:
		_stage_badge = get_node_or_null("MarginContainer/VBoxContainer/StageContainer/StageBadge") as Label
	if _id_label == null:
		_id_label = get_node_or_null("MarginContainer/VBoxContainer/InstanceIdLabel") as Label
	if _touch_button == null:
		_touch_button = get_node_or_null("TouchButton") as Button
	if _selection_highlight == null:
		_selection_highlight = get_node_or_null("SelectionHighlight") as Panel


## Binds presentation data for this plant view.
## Does not mutate GameState or PlantState.
func bind_plant_data(
	runtime_instance_id: String,
	definition_id: String,
	stage: PlantGrowth.Stage,
	planted_at: int,
	harvest_reward: int = 0,
	seconds_until_mature: int = -1,
	environmental_traits: Array[String] = [],
	seconds_until_next_stage: int = -1,
	locale: String = "",
	zone_id: String = GardenZone.ZONE_MAIN,
	grid_x: int = 0,
	grid_y: int = 0
) -> void:
	if not locale.is_empty():
		_locale = GardenLocalization.normalize_locale(locale)
	_runtime_instance_id = runtime_instance_id
	_definition_id = definition_id
	_display_name = GardenLocalization.get_plant_name(definition_id, _locale)
	_stage = stage
	_planted_at = planted_at
	_harvest_reward = maxi(0, harvest_reward)
	_seconds_until_mature = seconds_until_mature
	_environmental_traits = environmental_traits.duplicate()
	_seconds_until_next_stage = (
		0
		if stage == PlantGrowth.Stage.MATURE
		else seconds_until_next_stage
	)
	_zone_id = zone_id
	_grid_x = grid_x
	_grid_y = grid_y
	_render()


## Sets active display locale ("th" or "en") and re-renders this plant card.
func set_locale(locale: String) -> void:
	_locale = GardenLocalization.normalize_locale(locale)
	if not _definition_id.is_empty():
		_display_name = GardenLocalization.get_plant_name(_definition_id, _locale)
	_render()


## Returns active display locale ("th" or "en").
func get_locale() -> String:
	return _locale


## Pure query for the bound runtime instance ID.
func get_runtime_instance_id() -> String:
	return _runtime_instance_id


## Pure query for the definition ID.
func get_definition_id() -> String:
	return _definition_id


## Pure query for the display name.
func get_display_name() -> String:
	return _display_name


## Pure query for the planted timestamp.
func get_planted_at() -> int:
	return _planted_at


## Pure query for the derived growth stage.
func get_stage() -> PlantGrowth.Stage:
	return _stage


## Pure query for the bound zone ID.
func get_zone_id() -> String:
	return _zone_id


## Pure query for the bound logical grid X coordinate.
func get_grid_x() -> int:
	return _grid_x


## Pure query for the bound logical grid Y coordinate.
func get_grid_y() -> int:
	return _grid_y


## Pure query for the bound harvest reward (0 if not set).
func get_harvest_reward() -> int:
	return _harvest_reward


## Pure query for the bound remaining seconds until MATURE (-1 if not set).
func get_seconds_until_mature() -> int:
	return _seconds_until_mature


## Pure query for the bound remaining seconds until the next growth stage (-1 if not set, 0 if MATURE).
func get_seconds_until_next_stage() -> int:
	return _seconds_until_next_stage


## Pure query returning true if this plant view is at an active growing stage (PLANTED, SPROUT, or GROWING).
func is_growing_stage() -> bool:
	return (
		_stage == PlantGrowth.Stage.PLANTED
		or _stage == PlantGrowth.Stage.SPROUT
		or _stage == PlantGrowth.Stage.GROWING
	)


## Pure query returning a defensive copy of the bound environmental traits.
func get_environmental_traits() -> Array[String]:
	return _environmental_traits.duplicate()


## Pure query returning localized environmental traits summary, or "" if empty.
func get_traits_summary_text() -> String:
	if _environmental_traits.is_empty():
		return ""
	var parts: PackedStringArray = PackedStringArray()
	for trait_id: String in _environmental_traits:
		parts.append(GardenLocalization.get_trait_name(trait_id, _locale))
	return ", ".join(parts)


## Pure query returning the rendered instance ID & traits subtitle label text.
func get_instance_id_label_text() -> String:
	_resolve_nodes()
	return _id_label.text if _id_label != null else ""


## Pure query returning the stage-aware visual accent color for the current growth stage.
func get_stage_accent_color() -> Color:
	match _stage:
		PlantGrowth.Stage.PLANTED:
			return STAGE_ACCENT_PLANTED
		PlantGrowth.Stage.SPROUT:
			return STAGE_ACCENT_SPROUT
		PlantGrowth.Stage.GROWING:
			return STAGE_ACCENT_GROWING
		PlantGrowth.Stage.MATURE:
			return STAGE_ACCENT_MATURE
		_:
			return STAGE_ACCENT_INVALID


## Pure query returning true if this plant view is at PLANTED stage.
func is_planted_stage() -> bool:
	return _stage == PlantGrowth.Stage.PLANTED


## Pure query returning true if this plant view is at SPROUT stage.
func is_sprout_stage() -> bool:
	return _stage == PlantGrowth.Stage.SPROUT


## Pure query returning true if this plant view is at GROWING stage.
func is_growing_phase_stage() -> bool:
	return _stage == PlantGrowth.Stage.GROWING


## Pure query returning true if this plant view is at MATURE stage.
func is_mature_stage() -> bool:
	return _stage == PlantGrowth.Stage.MATURE


## Pure query returning true if this plant view has a valid (non-INVALID) growth stage.
func is_valid_stage() -> bool:
	return _stage != PlantGrowth.Stage.INVALID


## Pure query returning true if this plant view is at MATURE stage with a positive harvest reward.
func is_ready_to_harvest() -> bool:
	return _stage == PlantGrowth.Stage.MATURE and _harvest_reward > 0


## Pure query returning true if [param trait_id] is present in the bound environmental traits.
func has_environmental_trait(trait_id: String) -> bool:
	return not trait_id.is_empty() and _environmental_traits.has(trait_id)


## Pure query returning the count of bound environmental traits.
func get_environmental_trait_count() -> int:
	return _environmental_traits.size()


## Pure query returning true if this plant view has at least one bound environmental trait.
func has_any_environmental_traits() -> bool:
	return not _environmental_traits.is_empty()


## Pure query returning true if this plant view has a positive harvest reward.
func has_harvest_reward() -> bool:
	return _harvest_reward > 0


## Pure query returning true if this plant view is at an active growing stage with a positive countdown to MATURE.
func has_countdown_to_mature() -> bool:
	return is_growing_stage() and _seconds_until_mature > 0


## Pure query returning true if this plant view is at an active growing stage with a positive countdown to the next stage.
func has_countdown_to_next_stage() -> bool:
	return is_growing_stage() and _seconds_until_next_stage > 0


## Pure query returning true if a non-empty runtime_instance_id is bound.
func has_runtime_instance_id() -> bool:
	return not _runtime_instance_id.is_empty()


## Pure query returning true if a non-empty definition_id is bound.
func has_definition_id() -> bool:
	return not _definition_id.is_empty()


## Pure query returning true if a non-empty display name is bound.
func has_display_name() -> bool:
	return not _display_name.is_empty()


## Pure query returning true if this plant view has bound runtime_instance_id, definition_id, and a valid growth stage.
func is_bound() -> bool:
	return (
		not _runtime_instance_id.is_empty()
		and not _definition_id.is_empty()
		and _stage != PlantGrowth.Stage.INVALID
	)


## Pure query returning true if this plant view is at INVALID growth stage.
func is_invalid_stage() -> bool:
	return _stage == PlantGrowth.Stage.INVALID


## Pure query returning true if a positive planted_at timestamp is bound.
func has_planted_timestamp() -> bool:
	return _planted_at > 0


## Pure query returning true if the bound definition_id is in the localized plant catalog.
func is_known_plant_definition() -> bool:
	return GardenLocalization.is_known_plant_id(_definition_id)


## Pure query returning true if the selection highlight node is currently visible.
func is_selection_highlight_visible() -> bool:
	_resolve_nodes()
	return _selection_highlight != null and _selection_highlight.visible


## Pure query returning true if [param trait_id] is in the localized trait catalog.
func is_known_environmental_trait(trait_id: String) -> bool:
	return GardenLocalization.is_known_trait_id(trait_id)


## Pure query returning true if the touch button is present and not disabled.
func is_touch_button_enabled() -> bool:
	_resolve_nodes()
	return _touch_button != null and not _touch_button.disabled


## Pure query returning true if the rendered instance ID / traits subtitle label is non-empty.
func has_instance_id_label_text() -> bool:
	return not get_instance_id_label_text().is_empty()


## Pure query returning true if the rendered traits summary text is non-empty.
func has_traits_summary_text() -> bool:
	return not get_traits_summary_text().is_empty()


## Pure query returning true if the rendered plant name label text is non-empty and not the placeholder "—".
func has_name_label_text() -> bool:
	var txt: String = get_name_label_text()
	return not txt.is_empty() and txt != "—"


## Pure query returning true if the rendered stage label text is non-empty.
func has_stage_label_text() -> bool:
	return not get_stage_label_text().is_empty()


## Pure query returning true if the rendered stage badge text is non-empty.
func has_stage_badge_text() -> bool:
	return not get_stage_badge_text().is_empty()


## Pure query returning the localized display name for [param trait_id], or "" if empty.
func get_trait_display_name_for_id(trait_id: String) -> String:
	return GardenLocalization.get_trait_name(trait_id, _locale)


## Pure query returning the localized display name for [param definition_id], or "" if empty.
func get_plant_display_name_for_id(definition_id: String) -> String:
	return GardenLocalization.get_plant_name(definition_id, _locale)


## Pure query returning true if [param definition_id] is in the localized plant catalog.
func is_known_plant_definition_id(definition_id: String) -> bool:
	return GardenLocalization.is_known_plant_id(definition_id)


## Pure query returning localized display names for all bound environmental traits in order.
func get_bound_trait_display_names() -> Array[String]:
	var result: Array[String] = []
	for trait_id: String in _environmental_traits:
		result.append(GardenLocalization.get_trait_name(trait_id, _locale))
	return result


## Pure query returning the canonical localized display name for the bound growth stage.
func get_stage_display_name() -> String:
	return get_stage_display_name_for_stage(_stage)


## Pure query returning the canonical localized display name for [param stage].
func get_stage_display_name_for_stage(stage: PlantGrowth.Stage) -> String:
	return GardenLocalization.get_plant_stage_name(stage, _locale)


## Pure query returning the stage-aware visual accent color for [param stage].
func get_stage_accent_color_for_stage(stage: PlantGrowth.Stage) -> Color:
	match stage:
		PlantGrowth.Stage.PLANTED:
			return STAGE_ACCENT_PLANTED
		PlantGrowth.Stage.SPROUT:
			return STAGE_ACCENT_SPROUT
		PlantGrowth.Stage.GROWING:
			return STAGE_ACCENT_GROWING
		PlantGrowth.Stage.MATURE:
			return STAGE_ACCENT_MATURE
		_:
			return STAGE_ACCENT_INVALID


## Pure query returning true if at least one bound environmental trait is in the provisional localized trait display dictionary.
func has_known_environmental_trait() -> bool:
	for trait_id: String in _environmental_traits:
		if is_known_environmental_trait(trait_id):
			return true
	return false


## Pure query returning true if this plant view has at least one bound environmental trait and all bound traits are in the provisional localized trait display dictionary.
func is_all_bound_traits_known() -> bool:
	if _environmental_traits.is_empty():
		return false
	for trait_id: String in _environmental_traits:
		if not is_known_environmental_trait(trait_id):
			return false
	return true


## Pure query returning bound environmental trait IDs that are in the provisional localized trait display dictionary in order.
func get_known_bound_trait_ids() -> Array[String]:
	var result: Array[String] = []
	for trait_id: String in _environmental_traits:
		if is_known_environmental_trait(trait_id):
			result.append(trait_id)
	return result


## Pure query returning bound environmental trait IDs that are NOT in the provisional localized trait display dictionary in order.
func get_unknown_bound_trait_ids() -> Array[String]:
	var result: Array[String] = []
	for trait_id: String in _environmental_traits:
		if not is_known_environmental_trait(trait_id):
			result.append(trait_id)
	return result


## Pure query returning count of bound environmental traits that are in the provisional localized trait display dictionary.
func get_known_bound_trait_count() -> int:
	return get_known_bound_trait_ids().size()


## Pure query returning true if [param stage] is an active growing stage (PLANTED, SPROUT, or GROWING).
func is_stage_growing_for_stage(stage: PlantGrowth.Stage) -> bool:
	return (
		stage == PlantGrowth.Stage.PLANTED
		or stage == PlantGrowth.Stage.SPROUT
		or stage == PlantGrowth.Stage.GROWING
	)


## Pure query returning count of bound environmental traits that are NOT in the provisional localized trait display dictionary.
func get_unknown_bound_trait_count() -> int:
	return get_unknown_bound_trait_ids().size()


## Pure query returning true if at least one bound environmental trait is NOT in the provisional localized trait display dictionary.
func has_unknown_environmental_trait() -> bool:
	return get_unknown_bound_trait_count() > 0


## Pure query returning localized display names for bound environmental traits that are in the localized trait catalog in order.
func get_known_bound_trait_display_names() -> Array[String]:
	var result: Array[String] = []
	for trait_id: String in get_known_bound_trait_ids():
		result.append(GardenLocalization.get_trait_name(trait_id, _locale))
	return result


## Pure query returning true if [param stage] is a valid (non-INVALID) growth stage.
func is_stage_valid_for_stage(stage: PlantGrowth.Stage) -> bool:
	return (
		stage == PlantGrowth.Stage.PLANTED
		or stage == PlantGrowth.Stage.SPROUT
		or stage == PlantGrowth.Stage.GROWING
		or stage == PlantGrowth.Stage.MATURE
	)


## Pure query returning true if [param stage] is MATURE stage.
func is_stage_mature_for_stage(stage: PlantGrowth.Stage) -> bool:
	return stage == PlantGrowth.Stage.MATURE


## Pure query returning fallback display names for bound environmental traits that are NOT in the localized trait catalog in order.
func get_unknown_bound_trait_display_names() -> Array[String]:
	var result: Array[String] = []
	for trait_id: String in get_unknown_bound_trait_ids():
		result.append(GardenLocalization.get_trait_name(trait_id, _locale))
	return result


## Pure query returning true if [param stage] is PLANTED stage.
func is_stage_planted_for_stage(stage: PlantGrowth.Stage) -> bool:
	return stage == PlantGrowth.Stage.PLANTED


## Pure query returning true if [param stage] is SPROUT stage.
func is_stage_sprout_for_stage(stage: PlantGrowth.Stage) -> bool:
	return stage == PlantGrowth.Stage.SPROUT


## Pure query returning true if [param stage] is GROWING stage.
func is_stage_growing_phase_for_stage(stage: PlantGrowth.Stage) -> bool:
	return stage == PlantGrowth.Stage.GROWING


## Pure query returning true if [param stage] is NOT a valid growth stage (i.e. INVALID or unrecognized).
func is_stage_invalid_for_stage(stage: PlantGrowth.Stage) -> bool:
	return not is_stage_valid_for_stage(stage)


## Pure query returning true if [param definition_id] is in the provisional localized plant display dictionary and maps to a non-empty display name.
func has_known_plant_display_name_for_id(definition_id: String) -> bool:
	return is_known_plant_definition_id(definition_id) and not get_plant_display_name_for_id(definition_id).is_empty()


## Pure query returning true if [param trait_id] is in the provisional localized trait display dictionary and maps to a non-empty display name.
func has_known_trait_display_name_for_id(trait_id: String) -> bool:
	return is_known_environmental_trait(trait_id) and not get_trait_display_name_for_id(trait_id).is_empty()


## Pure query returning deterministic sorted environmental trait IDs from the localized trait catalog.
func get_known_trait_ids_in_dictionary() -> Array[String]:
	return GardenLocalization.get_known_trait_ids()


## Pure query returning deterministic sorted plant definition IDs from the localized plant catalog.
func get_known_plant_definition_ids_in_dictionary() -> Array[String]:
	return GardenLocalization.get_known_plant_ids()


## Pure query returning count of environmental traits in the localized trait catalog.
func get_known_trait_count_in_dictionary() -> int:
	return GardenLocalization.get_known_trait_ids().size()


## Pure query returning count of plant definitions in the localized plant catalog.
func get_known_plant_definition_count_in_dictionary() -> int:
	return GardenLocalization.get_known_plant_ids().size()


## Pure query for the rendered plant name label text.
func get_name_label_text() -> String:
	_resolve_nodes()
	return _name_label.text if _name_label != null else ""


## Pure query for the rendered stage label text.
func get_stage_label_text() -> String:
	_resolve_nodes()
	return _stage_label.text if _stage_label != null else ""


## Pure query for the rendered stage badge text.
func get_stage_badge_text() -> String:
	_resolve_nodes()
	return _stage_badge.text if _stage_badge != null else ""


## Pure query for the selection state.
func is_selected() -> bool:
	return _is_selected


## Updates selection state and visual feedback.
func set_selected(selected: bool) -> void:
	_is_selected = selected
	_update_selection_visual()


## Simulates touch/click input on this plant item (used in tests and input routing).
func simulate_selection_input() -> void:
	_on_touch_button_pressed()


func _on_touch_button_pressed() -> void:
	if not _runtime_instance_id.is_empty():
		plant_selected.emit(_runtime_instance_id)


func _render() -> void:
	_resolve_nodes()
	if _name_label == null:
		return

	_name_label.text = _display_name if not _display_name.is_empty() else GardenLocalization.translate("ui.common.dash", _locale)
	if _runtime_instance_id.is_empty():
		_id_label.text = ""
	else:
		var traits_summary: String = get_traits_summary_text()
		if not traits_summary.is_empty():
			_id_label.text = GardenLocalization.format_key(
				"ui.plant_card.id_traits",
				[_runtime_instance_id, traits_summary],
				_locale
			)
		else:
			_id_label.text = GardenLocalization.format_key(
				"ui.plant_card.id_only",
				[_runtime_instance_id],
				_locale
			)

	if _stage_badge != null:
		_stage_badge.add_theme_color_override("font_color", get_stage_accent_color())

	var stage_prefix: String = GardenLocalization.plant_stage_prefix(_stage)
	match _stage:
		PlantGrowth.Stage.PLANTED, PlantGrowth.Stage.SPROUT, PlantGrowth.Stage.GROWING:
			_stage_label.text = GardenLocalization.translate("%s.name" % stage_prefix, _locale)
			_stage_badge.text = (
				GardenLocalization.format_key("%s.badge_countdown" % stage_prefix, [_seconds_until_mature], _locale)
				if _seconds_until_mature > 0
				else GardenLocalization.translate("%s.badge" % stage_prefix, _locale)
			)
		PlantGrowth.Stage.MATURE:
			_stage_label.text = (
				GardenLocalization.format_key("plant_stage.mature.label_reward", [_harvest_reward], _locale)
				if _harvest_reward > 0
				else GardenLocalization.translate("plant_stage.mature.name", _locale)
			)
			_stage_badge.text = (
				GardenLocalization.format_key("plant_stage.mature.badge_reward", [_harvest_reward], _locale)
				if _harvest_reward > 0
				else GardenLocalization.translate("plant_stage.mature.badge", _locale)
			)
		_:
			_stage_label.text = GardenLocalization.translate("plant_stage.invalid.name", _locale)
			_stage_badge.text = GardenLocalization.translate("plant_stage.invalid.badge", _locale)

	_update_selection_visual()


func _update_selection_visual() -> void:
	_resolve_nodes()
	if _selection_highlight != null:
		_selection_highlight.visible = _is_selected
