## decoration_view.gd
## Presentation component representing one placed runtime decoration in the garden.
##
## Architectural rules:
## - Belongs to the presentation layer (src/presentation/garden/).
## - Pure view/controller for one runtime decoration item.
## - Does not own, mutate, or duplicate authoritative GameState.
## - Does not access save repository, filesystem, GameClock, RandomSource, or App.
## - Does not maintain a separate decoration model registry.
## - Identity is runtime_instance_id (String), never Godot ObjectID.
## - Touch/click triggers selection notification via signal.
class_name DecorationView
extends PanelContainer

signal decoration_selected(runtime_instance_id: String)

const ACCENT_WATER: Color = Color(0.56, 0.84, 0.94, 1.0)
const ACCENT_LIGHT: Color = Color(0.98, 0.86, 0.48, 1.0)
const ACCENT_NATURE: Color = Color(0.72, 0.88, 0.64, 1.0)
const ACCENT_COSMETIC: Color = Color(0.88, 0.78, 0.66, 1.0)
const ACCENT_UNBOUND: Color = Color(0.75, 0.70, 0.70, 1.0)

var _runtime_instance_id: String = ""
var _definition_id: String = ""
var _display_name: String = ""
var _placed_at: int = -1
var _price: int = 0
var _environmental_traits: Array[String] = []
var _is_selected: bool = false
var _locale: String = GardenLocalization.DEFAULT_LOCALE

var _name_label: Label = null
var _role_badge: Label = null
var _trait_summary_badge: Label = null
var _id_label: Label = null
var _touch_button: Button = null
var _selection_highlight: Panel = null


func _ready() -> void:
	_resolve_nodes()
	_render()


## Resolves child node references safely whether _ready has fired or not.
func _resolve_nodes() -> void:
	if _name_label == null:
		_name_label = get_node_or_null("MarginContainer/VBoxContainer/DecorationNameLabel") as Label
	if _role_badge == null:
		_role_badge = get_node_or_null("MarginContainer/VBoxContainer/RoleContainer/RoleBadge") as Label
	if _trait_summary_badge == null:
		_trait_summary_badge = get_node_or_null("MarginContainer/VBoxContainer/RoleContainer/TraitSummaryBadge") as Label
	if _id_label == null:
		_id_label = get_node_or_null("MarginContainer/VBoxContainer/InstanceIdLabel") as Label
	if _touch_button == null:
		_touch_button = get_node_or_null("TouchButton") as Button
	if _selection_highlight == null:
		_selection_highlight = get_node_or_null("SelectionHighlight") as Panel
	_connect_signals()


func _connect_signals() -> void:
	if _touch_button != null and not _touch_button.pressed.is_connected(_on_touch_button_pressed):
		_touch_button.pressed.connect(_on_touch_button_pressed)


## Binds read-only presentation data for this placed decoration view.
## Does not mutate GameState or DecorationState.
func bind_decoration_data(
	runtime_instance_id: String,
	definition_id: String,
	placed_at: int,
	price: int = 0,
	environmental_traits: Array[String] = [],
	locale: String = ""
) -> void:
	if not locale.is_empty():
		_locale = GardenLocalization.normalize_locale(locale)
	_runtime_instance_id = runtime_instance_id
	_definition_id = definition_id
	_display_name = GardenLocalization.get_decoration_name(definition_id, _locale)
	_placed_at = placed_at
	_price = maxi(0, price)
	_environmental_traits = environmental_traits.duplicate()
	_render()


func set_locale(locale: String) -> void:
	_locale = GardenLocalization.normalize_locale(locale)
	if not _definition_id.is_empty():
		_display_name = GardenLocalization.get_decoration_name(_definition_id, _locale)
	_render()


func get_locale() -> String:
	return _locale


func get_runtime_instance_id() -> String:
	return _runtime_instance_id


func get_definition_id() -> String:
	return _definition_id


func get_display_name() -> String:
	return _display_name


func get_placed_at() -> int:
	return _placed_at


func get_price() -> int:
	return _price


func get_environmental_traits() -> Array[String]:
	return _environmental_traits.duplicate()


func get_environmental_trait_count() -> int:
	return _environmental_traits.size()


func has_any_environmental_traits() -> bool:
	return not _environmental_traits.is_empty()


func has_environmental_trait(trait_id: String) -> bool:
	return not trait_id.is_empty() and _environmental_traits.has(trait_id)


func is_bound() -> bool:
	return (
		not _runtime_instance_id.is_empty()
		and not _definition_id.is_empty()
		and _placed_at >= 0
	)


func is_known_decoration_definition() -> bool:
	return GardenLocalization.is_known_decoration_id(_definition_id)


func get_traits_summary_text() -> String:
	if _environmental_traits.is_empty():
		return ""
	var parts: PackedStringArray = PackedStringArray()
	for trait_id: String in _environmental_traits:
		parts.append(GardenLocalization.get_trait_name(trait_id, _locale))
	return ", ".join(parts)


func get_trait_accent_color() -> Color:
	if not is_bound():
		return ACCENT_UNBOUND
	if _environmental_traits.has(EnvironmentalTrait.WATER):
		return ACCENT_WATER
	if _environmental_traits.has(EnvironmentalTrait.LIGHT):
		return ACCENT_LIGHT
	if not _environmental_traits.is_empty():
		return ACCENT_NATURE
	return ACCENT_COSMETIC


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_resolve_nodes()
	if _selection_highlight != null:
		_selection_highlight.visible = _is_selected


func is_selected() -> bool:
	return _is_selected


func is_selection_highlight_visible() -> bool:
	_resolve_nodes()
	return _selection_highlight != null and _selection_highlight.visible


func get_name_label_text() -> String:
	_resolve_nodes()
	return _name_label.text if _name_label != null else ""


func get_role_badge_text() -> String:
	_resolve_nodes()
	return _role_badge.text if _role_badge != null else ""


func get_trait_summary_badge_text() -> String:
	_resolve_nodes()
	return _trait_summary_badge.text if _trait_summary_badge != null else ""


func get_instance_id_label_text() -> String:
	_resolve_nodes()
	return _id_label.text if _id_label != null else ""


func get_touch_button() -> Button:
	_resolve_nodes()
	return _touch_button


func is_touch_button_enabled() -> bool:
	_resolve_nodes()
	return _touch_button != null and not _touch_button.disabled


func _render() -> void:
	_resolve_nodes()
	var accent: Color = get_trait_accent_color()

	if _role_badge != null:
		_role_badge.text = GardenLocalization.translate("ui.decoration_card.role_badge", _locale)
		_role_badge.modulate = accent

	if _trait_summary_badge != null:
		if not is_bound():
			_trait_summary_badge.text = GardenLocalization.translate("ui.common.dash", _locale)
		elif not _environmental_traits.is_empty():
			_trait_summary_badge.text = get_traits_summary_text()
		else:
			_trait_summary_badge.text = GardenLocalization.translate("ui.decoration_card.cosmetic", _locale)
		_trait_summary_badge.modulate = accent

	if _name_label != null:
		_name_label.text = _display_name if not _display_name.is_empty() else GardenLocalization.translate("ui.common.dash", _locale)

	if _id_label != null:
		var short_id: String = _runtime_instance_id if not _runtime_instance_id.is_empty() else GardenLocalization.translate("ui.common.dash", _locale)
		if _price > 0:
			_id_label.text = GardenLocalization.format_key(
				"ui.decoration_card.id_price",
				[short_id, _price],
				_locale
			)
		else:
			_id_label.text = GardenLocalization.format_key(
				"ui.decoration_card.id_only",
				[short_id],
				_locale
			)

	if _selection_highlight != null:
		_selection_highlight.visible = _is_selected


func _on_touch_button_pressed() -> void:
	if not _runtime_instance_id.is_empty():
		decoration_selected.emit(_runtime_instance_id)
