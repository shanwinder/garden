## journal_panel.gd
## Presentation modal view for the Garden Journal (สมุดบ้านสวน).
##
## Architectural rules:
## - Belongs to the presentation layer (src/presentation/garden/).
## - Pure read-only view component: extends Control.
## - Receives JournalState and ContentCatalog via explicit dependency injection (bind_journal).
## - Does not depend directly on the global App Autoload or AppRoot.
## - Does not mutate GameState, JournalState, EconomyState, or ContentCatalog.
## - Does not access GameClock, RandomSource, or LocalSaveRepository.
## - Renders discovered entries with localized display names, first_seen_at, and times_seen.
## - Renders undiscovered entries as mystery placeholders ("???") with gentle habitat clues.
class_name JournalPanel
extends Control

signal journal_closed()

var _journal: JournalState = null
var _catalog: ContentCatalog = null
var _is_enabled: bool = true

var _close_button: Button = null
var _summary_label: Label = null
var _entries_container: Container = null

var _entry_texts_by_id: Dictionary = {}
var _discovered_count: int = 0
var _total_catalog_count: int = 0
var _discovered_plant_count: int = 0
var _discovered_visitor_count: int = 0


func _ready() -> void:
	_resolve_nodes()
	_connect_signals()


func _resolve_nodes() -> void:
	if _close_button == null:
		_close_button = get_node_or_null("CenterContainer/JournalModalPanel/MarginContainer/VBoxContainer/HeaderHBox/CloseButton") as Button
	if _summary_label == null:
		_summary_label = get_node_or_null("CenterContainer/JournalModalPanel/MarginContainer/VBoxContainer/SummaryLabel") as Label
	if _entries_container == null:
		_entries_container = get_node_or_null("CenterContainer/JournalModalPanel/MarginContainer/VBoxContainer/ScrollContainer/ListMargin/EntriesContainer") as Container
	_connect_signals()


func _connect_signals() -> void:
	if _close_button != null and not _close_button.pressed.is_connected(close_journal):
		_close_button.pressed.connect(close_journal)


## Binds JournalState and ContentCatalog and renders all plant and visitor entries in catalog order.
func bind_journal(journal: JournalState, catalog: ContentCatalog) -> void:
	_journal = journal
	_catalog = catalog
	_resolve_nodes()
	_clear_entries()

	_entry_texts_by_id.clear()
	_discovered_count = 0
	_total_catalog_count = 0
	_discovered_plant_count = 0
	_discovered_visitor_count = 0

	if _catalog == null:
		if _summary_label != null:
			_summary_label.text = "ค้นพบแล้ว 0 / 0 รายการ"
		return

	var plants: Array[PlantDefinition] = _catalog.get_all_plants()
	var visitors: Array[VisitorDefinition] = _catalog.get_all_visitors()
	_total_catalog_count = plants.size() + visitors.size()

	_add_section_header("หมวดพันธุ์ไม้ (%d ชนิด)" % plants.size())
	for plant_def: PlantDefinition in plants:
		var def_id: String = plant_def.id
		var record: DiscoveryRecord = _journal.get_record(def_id) if _journal != null else null
		var entry_text: String = ""
		var is_disc: bool = record != null
		if is_disc:
			_discovered_count += 1
			_discovered_plant_count += 1
			var thai_name: String = PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.get(def_id, def_id)
			entry_text = (
				"[ค้นพบแล้ว] %s (%s)\nพบครั้งแรกเมื่อ: %d | จำนวนครั้งที่ปลูก/พบ: %d ครั้ง"
				% [thai_name, def_id, record.get_first_seen_at(), record.get_times_seen()]
			)
		else:
			entry_text = "[???] พันธุ์ไม้ปริศนา\nคำใบ้: ลองปลูกพันธุ์ไม้ชนิดใหม่ในสวน"
		_entry_texts_by_id[def_id] = entry_text
		_add_entry_label(entry_text, is_disc)

	_add_section_header("หมวดผู้มาเยือน (%d ชนิด)" % visitors.size())
	for visitor_def: VisitorDefinition in visitors:
		var def_id: String = visitor_def.id
		var record: DiscoveryRecord = _journal.get_record(def_id) if _journal != null else null
		var clue_text: String = _format_visitor_clue(visitor_def)
		var entry_text: String = ""
		var is_disc: bool = record != null
		if is_disc:
			_discovered_count += 1
			_discovered_visitor_count += 1
			var v_name: String = GardenView.PROVISIONAL_VISITOR_DISPLAY_NAMES.get(def_id, def_id)
			entry_text = (
				"[ค้นพบแล้ว] %s (%s)\nพบครั้งแรกเมื่อ: %d | จำนวนครั้งที่พบ: %d ครั้ง\nสภาพแวดล้อมที่ชอบ: %s"
				% [v_name, def_id, record.get_first_seen_at(), record.get_times_seen(), clue_text]
			)
		else:
			entry_text = "[???] ผู้มาเยือนปริศนา\nคำใบ้สภาพแวดล้อมที่ชอบ: %s" % clue_text
		_entry_texts_by_id[def_id] = entry_text
		_add_entry_label(entry_text, is_disc)

	if _summary_label != null:
		_summary_label.text = (
			"ค้นพบแล้ว %d / %d รายการ (พืช %d/%d, ผู้มาเยือน %d/%d)"
			% [
				_discovered_count,
				_total_catalog_count,
				_discovered_plant_count,
				plants.size(),
				_discovered_visitor_count,
				visitors.size(),
			]
		)


func _format_visitor_clue(visitor_def: VisitorDefinition) -> String:
	if visitor_def == null or visitor_def.required_trait_counts.is_empty():
		return "สวนที่มีต้นไม้ร่มรื่น"
	var trait_keys: Array = visitor_def.required_trait_counts.keys()
	trait_keys.sort()
	var parts: PackedStringArray = PackedStringArray()
	for raw_key: Variant in trait_keys:
		var trait_id: String = str(raw_key)
		var trait_name: String = GardenView.PROVISIONAL_TRAIT_DISPLAY_NAMES.get(trait_id, trait_id)
		var count: int = int(visitor_def.required_trait_counts[raw_key])
		parts.append("%s (%d)" % [trait_name, count])
	return ", ".join(parts)


func _add_section_header(title: String) -> void:
	if _entries_container == null:
		return
	var header: Label = Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45, 1))
	_entries_container.add_child(header)


func _add_entry_label(text: String, is_discovered: bool) -> void:
	if _entries_container == null:
		return
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 21)
	if is_discovered:
		lbl.add_theme_color_override("font_color", Color(0.9, 0.96, 0.9, 1))
	else:
		lbl.add_theme_color_override("font_color", Color(0.62, 0.68, 0.64, 1))
	_entries_container.add_child(lbl)


func _clear_entries() -> void:
	if _entries_container == null:
		return
	for child: Node in _entries_container.get_children():
		_entries_container.remove_child(child)
		child.queue_free()


## Opens the journal modal.
func open_journal() -> void:
	if not _is_enabled:
		return
	_resolve_nodes()
	visible = true


## Closes the journal modal.
func close_journal() -> void:
	_resolve_nodes()
	visible = false
	journal_closed.emit()


## Enables or disables interaction with the journal modal.
func set_journal_enabled(enabled: bool) -> void:
	_is_enabled = enabled
	_resolve_nodes()
	if _close_button != null:
		_close_button.disabled = not enabled
	if not enabled:
		visible = false


## Pure query for testing: returns true if journal modal is visible.
func is_journal_open() -> bool:
	return visible


## Pure query for testing: returns true if journal modal is enabled.
func is_journal_enabled() -> bool:
	return _is_enabled


## Pure query for testing: returns summary label text.
func get_summary_text() -> String:
	_resolve_nodes()
	return _summary_label.text if _summary_label != null else ""


## Pure query for testing: returns total catalog entries rendered.
func get_total_catalog_entry_count() -> int:
	return _total_catalog_count


## Pure query for testing: returns count of discovered entries in the current binding.
func get_discovered_entry_count() -> int:
	return _discovered_count


## Pure query for testing: returns rendered entry text for [param definition_id].
func get_entry_text_for_id(definition_id: String) -> String:
	return _entry_texts_by_id.get(definition_id, "")


## Pure query for testing: returns true if [param definition_id] has a rendered entry in the journal.
func has_displayed_entry_for_id(definition_id: String) -> bool:
	return _entry_texts_by_id.has(definition_id)


## Pure query for testing: returns CloseButton instance.
func get_close_button() -> Button:
	_resolve_nodes()
	return _close_button
