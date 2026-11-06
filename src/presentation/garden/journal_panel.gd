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
var _decorations: DecorationCollectionState = null
var _snapshot: GardenSnapshot = null
var _is_enabled: bool = true

var _close_button: Button = null
var _summary_label: Label = null
var _entries_container: Container = null

var _entry_texts_by_id: Dictionary = {}
var _discovered_count: int = 0
var _total_catalog_count: int = 0
var _discovered_plant_count: int = 0
var _discovered_visitor_count: int = 0
var _eligible_visitor_count: int = 0
var _total_decoration_count: int = 0
var _placed_decoration_count: int = 0
var _total_event_count: int = 0
var _active_event_count: int = 0


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


## Binds JournalState, ContentCatalog, and optional DecorationCollectionState / GardenSnapshot,
## rendering plant, visitor, decoration, and ambient event entries in deterministic catalog order.
func bind_journal(
	journal: JournalState,
	catalog: ContentCatalog,
	decorations: DecorationCollectionState = null,
	snapshot: GardenSnapshot = null
) -> void:
	_journal = journal
	_catalog = catalog
	_decorations = decorations
	_snapshot = snapshot
	_resolve_nodes()
	_clear_entries()

	_entry_texts_by_id.clear()
	_discovered_count = 0
	_total_catalog_count = 0
	_discovered_plant_count = 0
	_discovered_visitor_count = 0
	_eligible_visitor_count = 0
	_total_decoration_count = 0
	_placed_decoration_count = 0
	_total_event_count = 0
	_active_event_count = 0

	if _catalog == null:
		if _summary_label != null:
			_summary_label.text = "ค้นพบแล้ว 0 / 0 รายการ"
		return

	var plants: Array[PlantDefinition] = _catalog.get_all_plants()
	var visitors: Array[VisitorDefinition] = _catalog.get_all_visitors()
	var catalog_decorations: Array[DecorationDefinition] = _catalog.get_all_decorations()
	var catalog_events: Array[EventDefinition] = _catalog.get_all_events()
	_total_catalog_count = plants.size() + visitors.size()
	_total_decoration_count = catalog_decorations.size()
	_total_event_count = catalog_events.size()

	_add_section_header("หมวดพันธุ์ไม้ (%d ชนิด)" % plants.size())
	for plant_def: PlantDefinition in plants:
		var def_id: String = plant_def.id
		var record: DiscoveryRecord = _journal.get_record(def_id) if _journal != null else null
		var plant_traits: String = _format_plant_traits(plant_def)
		var entry_text: String = ""
		var is_disc: bool = record != null
		if is_disc:
			_discovered_count += 1
			_discovered_plant_count += 1
			var thai_name: String = PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.get(def_id, def_id)
			var planted_line: String = (
				" | กำลังปลูกในสวน: %d ต้น" % _count_planted_plant(def_id)
				if _snapshot != null
				else ""
			)
			entry_text = (
				"[ค้นพบแล้ว] %s (%s)\nพบครั้งแรกเมื่อ: %d | จำนวนครั้งที่ปลูก/พบ: %d ครั้ง%s\nโตเต็มที่ใน: %d วินาที | รางวัลเก็บเกี่ยว: %d เหรียญ | คุณสมบัติ: %s"
				% [
					thai_name,
					def_id,
					record.get_first_seen_at(),
					record.get_times_seen(),
					planted_line,
					plant_def.mature_after_seconds,
					plant_def.harvest_reward,
					plant_traits,
				]
			)
		else:
			entry_text = (
				"[???] พันธุ์ไม้ปริศนา\nคำใบ้: ลองปลูกพันธุ์ไม้ชนิดใหม่ในสวน (คุณสมบัติ: %s)"
				% plant_traits
			)
		_entry_texts_by_id[def_id] = entry_text
		_add_entry_label(entry_text, is_disc)

	_add_section_header("หมวดผู้มาเยือน (%d ชนิด)" % visitors.size())
	for visitor_def: VisitorDefinition in visitors:
		var def_id: String = visitor_def.id
		var record: DiscoveryRecord = _journal.get_record(def_id) if _journal != null else null
		var clue_text: String = _format_visitor_clue(visitor_def)
		var is_eligible_now: bool = (
			_snapshot != null
			and VisitorEligibility.is_eligible(visitor_def, _snapshot)
		)
		if is_eligible_now:
			_eligible_visitor_count += 1
		var entry_text: String = ""
		var is_disc: bool = record != null
		if is_disc:
			_discovered_count += 1
			_discovered_visitor_count += 1
			var v_name: String = GardenView.PROVISIONAL_VISITOR_DISPLAY_NAMES.get(def_id, def_id)
			var status_suffix: String = ""
			if _snapshot != null:
				status_suffix = (
					" | สถานะในสวน: มีโอกาสพบในขณะนี้"
					if is_eligible_now
					else " | สถานะในสวน: ยังไม่ตรงเงื่อนไขในขณะนี้"
				)
			entry_text = (
				"[ค้นพบแล้ว] %s (%s)\nพบครั้งแรกเมื่อ: %d | จำนวนครั้งที่พบ: %d ครั้ง%s\nสภาพแวดล้อมที่ชอบ: %s"
				% [
					v_name,
					def_id,
					record.get_first_seen_at(),
					record.get_times_seen(),
					status_suffix,
					clue_text,
				]
			)
		else:
			var eligible_hint: String = (
				"\nสถานะในสวน: สภาพแวดล้อมพร้อมแล้ว ลองสำรวจผู้มาเยือนในสวน"
				if is_eligible_now
				else ""
			)
			entry_text = (
				"[???] ผู้มาเยือนปริศนา\nคำใบ้สภาพแวดล้อมที่ชอบ: %s%s"
				% [clue_text, eligible_hint]
			)
		_entry_texts_by_id[def_id] = entry_text
		_add_entry_label(entry_text, is_disc)

	if not catalog_decorations.is_empty():
		_add_section_header("หมวดของตกแต่งสวน (%d ชนิด)" % catalog_decorations.size())
		for decor_def: DecorationDefinition in catalog_decorations:
			var def_id: String = decor_def.id
			var placed_count: int = _count_placed_decoration(def_id)
			var is_placed: bool = placed_count > 0
			var d_name: String = DecorationPicker.PROVISIONAL_DECORATION_DISPLAY_NAMES.get(def_id, def_id)
			var trait_text: String = _format_decoration_traits(decor_def)
			var entry_text: String = ""
			if is_placed:
				_placed_decoration_count += 1
				entry_text = (
					"[จัดวางแล้ว] %s (%s)\nจำนวนที่วางในสวน: %d ชิ้น | ราคา: %d เหรียญ | คุณสมบัติ: %s"
					% [d_name, def_id, placed_count, decor_def.price, trait_text]
				)
			else:
				entry_text = (
					"[ยังไม่ได้จัดวาง] %s (%s)\nราคา: %d เหรียญ | คุณสมบัติ: %s"
					% [d_name, def_id, decor_def.price, trait_text]
				)
			_entry_texts_by_id[def_id] = entry_text
			_add_entry_label(entry_text, is_placed)

	if not catalog_events.is_empty():
		_add_section_header("หมวดเหตุการณ์พิเศษในสวน (%d เหตุการณ์)" % catalog_events.size())
		for event_def: EventDefinition in catalog_events:
			var def_id: String = event_def.id
			var is_active: bool = (
				_snapshot != null
				and EventEligibility.is_eligible(event_def, _snapshot)
			)
			var e_name: String = GardenView.PROVISIONAL_EVENT_DISPLAY_NAMES.get(def_id, def_id)
			var e_desc: String = GardenView.PROVISIONAL_EVENT_DESCRIPTIONS.get(def_id, "")
			var clue_text: String = _format_event_clue(event_def)
			var entry_text: String = ""
			if is_active:
				_active_event_count += 1
				entry_text = (
					"[เกิดขึ้นได้ในสวน] %s (%s)\n%s\nเงื่อนไข: %s"
					% [e_name, def_id, e_desc, clue_text]
				)
			else:
				entry_text = (
					"[???] เหตุการณ์พิเศษปริศนา (%s)\nคำใบ้เงื่อนไข: %s"
					% [e_name, clue_text]
				)
			_entry_texts_by_id[def_id] = entry_text
			_add_entry_label(entry_text, is_active)

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


func _count_planted_plant(definition_id: String) -> int:
	if _snapshot == null:
		return 0
	return _snapshot.get_plant_count_for_definition(definition_id)


func _count_placed_decoration(definition_id: String) -> int:
	if _snapshot != null:
		return _snapshot.get_decoration_count_for_definition(definition_id)
	if _decorations == null:
		return 0
	var count: int = 0
	for state: DecorationState in _decorations.get_all_decorations():
		if state != null and state.get_definition_id() == definition_id:
			count += 1
	return count


func _format_plant_traits(plant_def: PlantDefinition) -> String:
	if plant_def == null or plant_def.environmental_traits.is_empty():
		return "พืชสวนครัว"
	var parts: PackedStringArray = PackedStringArray()
	for trait_id: String in plant_def.environmental_traits:
		parts.append(GardenView.PROVISIONAL_TRAIT_DISPLAY_NAMES.get(trait_id, trait_id))
	return ", ".join(parts)


func _format_decoration_traits(decor_def: DecorationDefinition) -> String:
	if decor_def == null or decor_def.environmental_traits.is_empty():
		return "ตกแต่งสวยงาม"
	var parts: PackedStringArray = PackedStringArray()
	for trait_id: String in decor_def.environmental_traits:
		parts.append(GardenView.PROVISIONAL_TRAIT_DISPLAY_NAMES.get(trait_id, trait_id))
	return ", ".join(parts)


func _format_event_clue(event_def: EventDefinition) -> String:
	if event_def == null:
		return "สวนที่มีบรรยากาศเหมาะสม"
	var parts: PackedStringArray = PackedStringArray()
	if not event_def.required_trait_counts.is_empty():
		var trait_keys: Array = event_def.required_trait_counts.keys()
		trait_keys.sort()
		for raw_key: Variant in trait_keys:
			var trait_id: String = str(raw_key)
			var trait_name: String = GardenView.PROVISIONAL_TRAIT_DISPLAY_NAMES.get(trait_id, trait_id)
			var count: int = int(event_def.required_trait_counts[raw_key])
			parts.append("%s (%d)" % [trait_name, count])
	for decor_id: String in event_def.required_decoration_ids:
		parts.append(DecorationPicker.PROVISIONAL_DECORATION_DISPLAY_NAMES.get(decor_id, decor_id))
	for plant_id: String in event_def.required_plant_ids:
		parts.append(PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.get(plant_id, plant_id))
	if not event_def.allowed_time_periods.is_empty():
		var t_names: PackedStringArray = PackedStringArray()
		for tp: String in event_def.allowed_time_periods:
			t_names.append(GardenView.PROVISIONAL_TIME_PERIOD_DISPLAY_NAMES.get(tp, tp))
		parts.append("ช่วงเวลา: %s" % ", ".join(t_names))
	if not event_def.allowed_weather_states.is_empty():
		var w_names: PackedStringArray = PackedStringArray()
		for ws: String in event_def.allowed_weather_states:
			w_names.append(GardenView.PROVISIONAL_WEATHER_DISPLAY_NAMES.get(ws, ws))
		parts.append("สภาพอากาศ: %s" % ", ".join(w_names))
	if parts.is_empty():
		return "สวนที่มีบรรยากาศเหมาะสม"
	return " | ".join(parts)


func _format_visitor_clue(visitor_def: VisitorDefinition) -> String:
	if visitor_def == null:
		return "สวนที่มีต้นไม้ร่มรื่น"
	var trait_parts: PackedStringArray = PackedStringArray()
	if not visitor_def.required_trait_counts.is_empty():
		var trait_keys: Array = visitor_def.required_trait_counts.keys()
		trait_keys.sort()
		for raw_key: Variant in trait_keys:
			var trait_id: String = str(raw_key)
			var trait_name: String = GardenView.PROVISIONAL_TRAIT_DISPLAY_NAMES.get(trait_id, trait_id)
			var count: int = int(visitor_def.required_trait_counts[raw_key])
			trait_parts.append("%s (%d)" % [trait_name, count])
	var extra_parts: PackedStringArray = PackedStringArray()
	for decor_id: String in visitor_def.required_decoration_ids:
		extra_parts.append(DecorationPicker.PROVISIONAL_DECORATION_DISPLAY_NAMES.get(decor_id, decor_id))
	for plant_id: String in visitor_def.required_plant_ids:
		extra_parts.append(PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.get(plant_id, plant_id))
	if not visitor_def.allowed_time_periods.is_empty():
		var t_names: PackedStringArray = PackedStringArray()
		for tp: String in visitor_def.allowed_time_periods:
			t_names.append(GardenView.PROVISIONAL_TIME_PERIOD_DISPLAY_NAMES.get(tp, tp))
		extra_parts.append("ช่วงเวลา: %s" % ", ".join(t_names))
	if not visitor_def.allowed_weather_states.is_empty():
		var w_names: PackedStringArray = PackedStringArray()
		for ws: String in visitor_def.allowed_weather_states:
			w_names.append(GardenView.PROVISIONAL_WEATHER_DISPLAY_NAMES.get(ws, ws))
		extra_parts.append("สภาพอากาศ: %s" % ", ".join(w_names))
	if trait_parts.is_empty() and extra_parts.is_empty():
		return "สวนที่มีต้นไม้ร่มรื่น"
	if extra_parts.is_empty():
		return ", ".join(trait_parts)
	var all_parts: PackedStringArray = PackedStringArray()
	if not trait_parts.is_empty():
		all_parts.append(", ".join(trait_parts))
	for ep: String in extra_parts:
		all_parts.append(ep)
	return " | ".join(all_parts)


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


## Pure query for testing: returns total decoration definitions rendered in the journal.
func get_total_decoration_entry_count() -> int:
	return _total_decoration_count


## Pure query for testing: returns count of distinct decoration definitions currently placed in the garden.
func get_placed_decoration_entry_count() -> int:
	return _placed_decoration_count


## Pure query for testing: returns total event definitions rendered in the journal.
func get_total_event_entry_count() -> int:
	return _total_event_count


## Pure query for testing: returns count of event definitions currently active/eligible in the bound snapshot.
func get_active_event_entry_count() -> int:
	return _active_event_count


## Pure query for testing: returns current planted count for [param definition_id] from the bound GardenSnapshot, or 0.
func get_planted_count_for_plant_id(definition_id: String) -> int:
	return _count_planted_plant(definition_id)


## Pure query for testing: returns count of catalog visitors currently eligible in the bound GardenSnapshot, or 0 if no snapshot is bound.
func get_eligible_visitor_entry_count() -> int:
	return _eligible_visitor_count


## Pure query for testing: returns true if [param visitor_id] is a catalog visitor currently eligible in the bound GardenSnapshot.
func is_visitor_eligible_in_journal(visitor_id: String) -> bool:
	if _catalog == null or _snapshot == null or not _catalog.has_visitor(visitor_id):
		return false
	var visitor_def: VisitorDefinition = _catalog.get_visitor(visitor_id)
	return VisitorEligibility.is_eligible(visitor_def, _snapshot)


## Pure query for testing: returns count of discovered plant entries in the current binding.
func get_discovered_plant_entry_count() -> int:
	return _discovered_plant_count


## Pure query for testing: returns count of discovered visitor entries in the current binding.
func get_discovered_visitor_entry_count() -> int:
	return _discovered_visitor_count


## Pure query for testing: returns current placed count for [param definition_id] from the bound GardenSnapshot / DecorationCollectionState, or 0.
func get_placed_count_for_decoration_id(definition_id: String) -> int:
	return _count_placed_decoration(definition_id)


## Pure query for testing: returns true if [param event_id] is a catalog event currently eligible in the bound GardenSnapshot.
func is_event_active_in_journal(event_id: String) -> bool:
	if _catalog == null or _snapshot == null or not _catalog.has_event(event_id):
		return false
	var event_def: EventDefinition = _catalog.get_event(event_id)
	return EventEligibility.is_eligible(event_def, _snapshot)
