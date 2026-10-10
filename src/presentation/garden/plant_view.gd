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

## Provisional display-only labels for approved plant definitions (presentation text only).
const PROVISIONAL_PLANT_DISPLAY_NAMES: Dictionary = {
	"plant.holy_basil": "กะเพรา",
	"plant.chili": "พริก",
	"plant.jasmine": "มะลิ",
	"plant.marigold": "ดาวเรือง",
	"plant.banana": "กล้วย",
}

var _runtime_instance_id: String = ""
var _definition_id: String = ""
var _display_name: String = ""
var _planted_at: int = 0
var _stage: PlantGrowth.Stage = PlantGrowth.Stage.INVALID
var _is_selected: bool = false

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
	planted_at: int
) -> void:
	_runtime_instance_id = runtime_instance_id
	_definition_id = definition_id
	_display_name = PROVISIONAL_PLANT_DISPLAY_NAMES.get(definition_id, definition_id)
	_stage = stage
	_planted_at = planted_at
	_render()


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

	_name_label.text = _display_name if not _display_name.is_empty() else "—"
	_id_label.text = "ID: %s" % _runtime_instance_id if not _runtime_instance_id.is_empty() else ""

	match _stage:
		PlantGrowth.Stage.PLANTED:
			_stage_label.text = "เพาะเมล็ด"
			_stage_badge.text = "[เมล็ด]"
		PlantGrowth.Stage.SPROUT:
			_stage_label.text = "ต้นกล้า"
			_stage_badge.text = "[ต้นกล้า]"
		PlantGrowth.Stage.GROWING:
			_stage_label.text = "กำลังโต"
			_stage_badge.text = "[กำลังโต]"
		PlantGrowth.Stage.MATURE:
			_stage_label.text = "โตเต็มที่"
			_stage_badge.text = "[โตเต็มที่]"
		_:
			_stage_label.text = "ไม่ทราบสถานะ"
			_stage_badge.text = "[ข้อมูลไม่สมบูรณ์]"

	_update_selection_visual()


func _update_selection_visual() -> void:
	_resolve_nodes()
	if _selection_highlight != null:
		_selection_highlight.visible = _is_selected
