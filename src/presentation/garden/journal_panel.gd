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

## Clue shown for secret combination events instead of their exact recipe
## (GAME_DESIGN.md Section 12: encourage experimentation without listing the combination).
const SECRET_EVENT_CLUE_TEXT: String = "ความลับของสวน ลองผสมพันธุ์ไม้ ของตกแต่ง และช่วงเวลาในแบบที่ยังไม่เคยลอง"

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
			elif event_def.is_secret:
				# Secret combination events stay unnamed until their combination is present,
				# so the journal hints that more exists without listing the recipe.
				entry_text = "[???] เหตุการณ์ลับปริศนา\nคำใบ้: %s" % clue_text
			else:
				entry_text = (
					"[???] เหตุการณ์พิเศษปริศนา (%s)\nคำใบ้เงื่อนไข: %s"
					% [e_name, clue_text]
				)
			_entry_texts_by_id[def_id] = entry_text
			_add_entry_label(entry_text, is_active)

	if _summary_label != null:
		var base_summary: String = (
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
		var extra_parts: PackedStringArray = PackedStringArray()
		if _total_decoration_count > 0:
			extra_parts.append("ของตกแต่ง %d/%d" % [_placed_decoration_count, _total_decoration_count])
		if _total_event_count > 0:
			extra_parts.append("เหตุการณ์ %d/%d" % [_active_event_count, _total_event_count])
		if not extra_parts.is_empty():
			base_summary += " | " + " | ".join(extra_parts)
		_summary_label.text = base_summary


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
	if event_def.is_secret:
		return SECRET_EVENT_CLUE_TEXT
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
	if not event_def.required_plant_counts.is_empty():
		var plant_count_keys: Array = event_def.required_plant_counts.keys()
		plant_count_keys.sort()
		for raw_plant_key: Variant in plant_count_keys:
			var counted_plant_id: String = str(raw_plant_key)
			var plant_name: String = PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.get(counted_plant_id, counted_plant_id)
			parts.append("%s x%d" % [plant_name, int(event_def.required_plant_counts[raw_plant_key])])
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


## Pure query for testing: returns deterministic catalog-ordered IDs of discovered plants in the bound JournalState.
func get_discovered_plant_ids_in_journal() -> Array[String]:
	if _catalog == null or _journal == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_plant_ids():
		if _journal.has_discovered(def_id):
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of undiscovered plants in the bound JournalState.
func get_undiscovered_plant_ids_in_journal() -> Array[String]:
	if _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_plant_ids():
		if _journal == null or not _journal.has_discovered(def_id):
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of discovered visitors in the bound JournalState.
func get_discovered_visitor_ids_in_journal() -> Array[String]:
	if _catalog == null or _journal == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_visitor_ids():
		if _journal.has_discovered(def_id):
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of undiscovered visitors in the bound JournalState.
func get_undiscovered_visitor_ids_in_journal() -> Array[String]:
	if _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_visitor_ids():
		if _journal == null or not _journal.has_discovered(def_id):
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of visitors currently eligible in the bound GardenSnapshot.
func get_eligible_visitor_ids_in_journal() -> Array[String]:
	if _catalog == null or _snapshot == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_visitor_ids():
		if is_visitor_eligible_in_journal(def_id):
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of decorations currently placed in the bound GardenSnapshot / DecorationCollectionState.
func get_placed_decoration_ids_in_journal() -> Array[String]:
	if _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_decoration_ids():
		if _count_placed_decoration(def_id) > 0:
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of ambient events currently active/eligible in the bound GardenSnapshot.
func get_active_event_ids_in_journal() -> Array[String]:
	if _catalog == null or _snapshot == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_event_ids():
		if is_event_active_in_journal(def_id):
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of visitors currently ineligible in the bound GardenSnapshot.
func get_ineligible_visitor_ids_in_journal() -> Array[String]:
	if _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_visitor_ids():
		if _snapshot == null or not is_visitor_eligible_in_journal(def_id):
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of decorations not yet placed in the bound GardenSnapshot / DecorationCollectionState.
func get_unplaced_decoration_ids_in_journal() -> Array[String]:
	if _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_decoration_ids():
		if _count_placed_decoration(def_id) <= 0:
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered IDs of ambient events currently inactive/ineligible in the bound GardenSnapshot.
func get_inactive_event_ids_in_journal() -> Array[String]:
	if _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_event_ids():
		if _snapshot == null or not is_event_active_in_journal(def_id):
			result.append(def_id)
	return result


## Pure query for testing: returns true if [param definition_id] has been discovered in the bound JournalState.
func is_entry_discovered_in_journal(definition_id: String) -> bool:
	return _journal != null and _journal.has_discovered(definition_id)


## Pure query for testing: returns times_seen for [param definition_id] in the bound JournalState, or 0 if undiscovered.
func get_times_seen_for_id(definition_id: String) -> int:
	if _journal == null:
		return 0
	var rec: DiscoveryRecord = _journal.get_record(definition_id)
	return rec.get_times_seen() if rec != null else 0


## Pure query for testing: returns first_seen_at UTC timestamp for [param definition_id] in the bound JournalState, or -1 if undiscovered.
func get_first_seen_at_for_id(definition_id: String) -> int:
	if _journal == null:
		return -1
	var rec: DiscoveryRecord = _journal.get_record(definition_id)
	return rec.get_first_seen_at() if rec != null else -1


## Pure query for testing: returns deterministic catalog-ordered IDs of plants currently planted in the bound GardenSnapshot.
func get_currently_planted_plant_ids_in_journal() -> Array[String]:
	if _catalog == null or _snapshot == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_plant_ids():
		if _count_planted_plant(def_id) > 0:
			result.append(def_id)
	return result


## Pure query for testing: returns count of distinct plant definitions currently planted in the bound GardenSnapshot.
func get_currently_planted_plant_entry_count() -> int:
	return get_currently_planted_plant_ids_in_journal().size()


## Pure query for testing: returns deterministic catalog-ordered IDs of plants not currently planted in the bound GardenSnapshot.
func get_unplanted_plant_ids_in_journal() -> Array[String]:
	if _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_plant_ids():
		if _count_planted_plant(def_id) <= 0:
			result.append(def_id)
	return result


## Pure query for testing: returns total count of undiscovered catalog entries (plants + visitors) in the current binding.
func get_undiscovered_entry_count() -> int:
	return maxi(0, _total_catalog_count - _discovered_count)


## Pure query for testing: returns count of undiscovered plant entries in the current binding.
func get_undiscovered_plant_entry_count() -> int:
	return get_undiscovered_plant_ids_in_journal().size()


## Pure query for testing: returns count of undiscovered visitor entries in the current binding.
func get_undiscovered_visitor_entry_count() -> int:
	return get_undiscovered_visitor_ids_in_journal().size()


## Pure query for testing: returns total sum of times_seen across all discovered catalog plants and visitors in the bound JournalState.
func get_total_sighting_count_in_journal() -> int:
	return get_total_plant_sighting_count_in_journal() + get_total_visitor_sighting_count_in_journal()


## Pure query for testing: returns total sum of times_seen across all discovered catalog plants in the bound JournalState.
func get_total_plant_sighting_count_in_journal() -> int:
	if _catalog == null or _journal == null:
		return 0
	var total: int = 0
	for pid: String in _catalog.get_all_plant_ids():
		total += get_times_seen_for_id(pid)
	return total


## Pure query for testing: returns total sum of times_seen across all discovered catalog visitors in the bound JournalState.
func get_total_visitor_sighting_count_in_journal() -> int:
	if _catalog == null or _journal == null:
		return 0
	var total: int = 0
	for vid: String in _catalog.get_all_visitor_ids():
		total += get_times_seen_for_id(vid)
	return total


## Pure query for testing: returns count of catalog visitors currently ineligible in the bound GardenSnapshot.
func get_ineligible_visitor_entry_count() -> int:
	return get_ineligible_visitor_ids_in_journal().size()


## Pure query for testing: returns count of distinct decoration definitions not yet placed in the garden.
func get_unplaced_decoration_entry_count() -> int:
	return get_unplaced_decoration_ids_in_journal().size()


## Pure query for testing: returns count of ambient event definitions currently inactive/ineligible in the bound GardenSnapshot.
func get_inactive_event_entry_count() -> int:
	return get_inactive_event_ids_in_journal().size()


## Pure query for testing: returns count of distinct plant definitions not currently planted in the bound GardenSnapshot.
func get_unplanted_plant_entry_count() -> int:
	return get_unplanted_plant_ids_in_journal().size()


## Pure query for testing: returns true if all catalog entries (plants + visitors) have been discovered in the current binding.
func is_all_entries_discovered_in_journal() -> bool:
	return _total_catalog_count > 0 and _discovered_count >= _total_catalog_count


## Pure query for testing: returns total plant definitions in the bound catalog, or 0 if unbound.
func get_total_plant_entry_count() -> int:
	return _catalog.get_plant_count() if _catalog != null else 0


## Pure query for testing: returns total visitor definitions in the bound catalog, or 0 if unbound.
func get_total_visitor_entry_count() -> int:
	return _catalog.get_visitor_count() if _catalog != null else 0


## Pure query for testing: returns true if all catalog plant definitions have been discovered in the current binding.
func is_all_plants_discovered_in_journal() -> bool:
	var total_plants: int = get_total_plant_entry_count()
	return total_plants > 0 and _discovered_plant_count >= total_plants


## Pure query for testing: returns true if all catalog visitor definitions have been discovered in the current binding.
func is_all_visitors_discovered_in_journal() -> bool:
	var total_visitors: int = get_total_visitor_entry_count()
	return total_visitors > 0 and _discovered_visitor_count >= total_visitors


## Pure query for testing: returns true if all catalog decoration definitions have been placed at least once in the garden.
func is_all_decorations_placed_in_journal() -> bool:
	return _total_decoration_count > 0 and _placed_decoration_count >= _total_decoration_count


## Pure query for testing: returns true if all catalog ambient event definitions are currently active/eligible in the bound snapshot.
func is_all_events_active_in_journal() -> bool:
	return _total_event_count > 0 and _active_event_count >= _total_event_count


## Pure query for testing: returns true if at least one catalog entry (plant or visitor) has been discovered in the current binding.
func has_any_discovered_entries_in_journal() -> bool:
	return _discovered_count > 0


## Pure query for testing: returns true if at least one catalog plant has been discovered in the current binding.
func has_any_discovered_plants_in_journal() -> bool:
	return _discovered_plant_count > 0


## Pure query for testing: returns true if at least one catalog visitor has been discovered in the current binding.
func has_any_discovered_visitors_in_journal() -> bool:
	return _discovered_visitor_count > 0


## Pure query for testing: returns true if at least one catalog visitor is currently eligible in the bound GardenSnapshot.
func has_any_eligible_visitors_in_journal() -> bool:
	return _eligible_visitor_count > 0


## Pure query for testing: returns true if at least one catalog decoration has been placed in the garden.
func has_any_placed_decorations_in_journal() -> bool:
	return _placed_decoration_count > 0


## Pure query for testing: returns true if at least one catalog ambient event is currently active/eligible in the bound GardenSnapshot.
func has_any_active_events_in_journal() -> bool:
	return _active_event_count > 0


## Pure query for testing: returns true if all catalog visitor definitions are currently eligible in the bound GardenSnapshot.
func is_all_visitors_eligible_in_journal() -> bool:
	var total_visitors: int = get_total_visitor_entry_count()
	return total_visitors > 0 and _eligible_visitor_count >= total_visitors


## Pure query for testing: returns true if at least one catalog entry (plant or visitor) is still undiscovered in the current binding.
func has_any_undiscovered_entries_in_journal() -> bool:
	return get_undiscovered_entry_count() > 0


## Pure query for testing: returns true if at least one catalog plant is still undiscovered in the current binding.
func has_any_undiscovered_plants_in_journal() -> bool:
	return get_undiscovered_plant_entry_count() > 0


## Pure query for testing: returns true if at least one catalog visitor is still undiscovered in the current binding.
func has_any_undiscovered_visitors_in_journal() -> bool:
	return get_undiscovered_visitor_entry_count() > 0


## Pure query for testing: returns true if at least one catalog visitor is currently ineligible in the bound GardenSnapshot.
func has_any_ineligible_visitors_in_journal() -> bool:
	return get_ineligible_visitor_entry_count() > 0


## Pure query for testing: returns true if at least one catalog decoration has not yet been placed in the garden.
func has_any_unplaced_decorations_in_journal() -> bool:
	return get_unplaced_decoration_entry_count() > 0


## Pure query for testing: returns true if at least one catalog ambient event is currently inactive/ineligible in the bound GardenSnapshot.
func has_any_inactive_events_in_journal() -> bool:
	return get_inactive_event_entry_count() > 0


## Pure query for testing: returns true if at least one catalog plant is currently planted in the bound GardenSnapshot.
func has_any_currently_planted_plants_in_journal() -> bool:
	return get_currently_planted_plant_entry_count() > 0


## Pure query for testing: returns true if at least one catalog plant is not currently planted in the bound GardenSnapshot.
func has_any_unplanted_plants_in_journal() -> bool:
	return get_unplanted_plant_entry_count() > 0


## Pure query for testing: returns true if all catalog plant definitions are currently planted in the bound GardenSnapshot.
func is_all_planted_species_present_in_journal() -> bool:
	var total_plants: int = get_total_plant_entry_count()
	return total_plants > 0 and get_currently_planted_plant_entry_count() >= total_plants


## Pure query for testing: returns true if a JournalState is bound to this panel.
func has_bound_journal() -> bool:
	return _journal != null


## Pure query for testing: returns true if a ContentCatalog is bound to this panel.
func has_bound_catalog() -> bool:
	return _catalog != null


## Pure query for testing: returns true if a DecorationCollectionState is bound to this panel.
func has_bound_decorations() -> bool:
	return _decorations != null


## Pure query for testing: returns true if a GardenSnapshot is bound to this panel.
func has_bound_snapshot() -> bool:
	return _snapshot != null


## Pure query for testing: returns true if [param definition_id] exists as a plant definition in the bound catalog.
func has_plant_in_journal_catalog(definition_id: String) -> bool:
	return not definition_id.is_empty() and _catalog != null and _catalog.has_plant(definition_id)


## Pure query for testing: returns true if [param definition_id] exists as a visitor definition in the bound catalog.
func has_visitor_in_journal_catalog(definition_id: String) -> bool:
	return not definition_id.is_empty() and _catalog != null and _catalog.has_visitor(definition_id)


## Pure query for testing: returns true if [param definition_id] exists as a decoration definition in the bound catalog.
func has_decoration_in_journal_catalog(definition_id: String) -> bool:
	return not definition_id.is_empty() and _catalog != null and _catalog.has_decoration(definition_id)


## Pure query for testing: returns true if [param definition_id] exists as an ambient event definition in the bound catalog.
func has_event_in_journal_catalog(definition_id: String) -> bool:
	return not definition_id.is_empty() and _catalog != null and _catalog.has_event(definition_id)


## Pure query for testing: returns deterministic catalog-ordered IDs of all plants in the bound catalog, or [] if unbound.
func get_all_plant_ids_in_journal() -> Array[String]:
	return _catalog.get_all_plant_ids() if _catalog != null else []


## Pure query for testing: returns deterministic catalog-ordered IDs of all visitors in the bound catalog, or [] if unbound.
func get_all_visitor_ids_in_journal() -> Array[String]:
	return _catalog.get_all_visitor_ids() if _catalog != null else []


## Pure query for testing: returns deterministic catalog-ordered IDs of all decorations in the bound catalog, or [] if unbound.
func get_all_decoration_ids_in_journal() -> Array[String]:
	return _catalog.get_all_decoration_ids() if _catalog != null else []


## Pure query for testing: returns deterministic catalog-ordered IDs of all ambient events in the bound catalog, or [] if unbound.
func get_all_event_ids_in_journal() -> Array[String]:
	return _catalog.get_all_event_ids() if _catalog != null else []


## Pure query for testing: returns total planted plant instances across all catalog plant species in the bound GardenSnapshot, or 0 if unbound.
func get_total_planted_plant_instance_count_in_journal() -> int:
	return _snapshot.get_total_plant_count() if _snapshot != null else 0


## Pure query for testing: returns total placed decoration instances across all catalog decoration species in the bound GardenSnapshot / DecorationCollectionState, or 0 if unbound.
func get_total_placed_decoration_instance_count_in_journal() -> int:
	if _snapshot != null:
		return _snapshot.get_total_decoration_count()
	if _decorations != null:
		return _decorations.get_all_decorations().size()
	return 0


## Pure query for testing: returns true if [param definition_id] is a catalog decoration currently placed in the garden.
func is_decoration_placed_in_journal(definition_id: String) -> bool:
	return has_decoration_in_journal_catalog(definition_id) and _count_placed_decoration(definition_id) > 0


## Pure query for testing: returns true if [param definition_id] is a catalog plant currently planted in the bound GardenSnapshot.
func is_plant_currently_planted_in_journal(definition_id: String) -> bool:
	return has_plant_in_journal_catalog(definition_id) and _count_planted_plant(definition_id) > 0


## Pure query for testing: returns localized Thai display name for a plant [param definition_id] in the bound catalog, or "" if not in catalog.
func get_plant_display_name_in_journal(definition_id: String) -> String:
	if not has_plant_in_journal_catalog(definition_id):
		return ""
	return PlantView.PROVISIONAL_PLANT_DISPLAY_NAMES.get(definition_id, definition_id)


## Pure query for testing: returns localized Thai display name for a visitor [param definition_id] in the bound catalog, or "" if not in catalog.
func get_visitor_display_name_in_journal(definition_id: String) -> String:
	if not has_visitor_in_journal_catalog(definition_id):
		return ""
	return GardenView.PROVISIONAL_VISITOR_DISPLAY_NAMES.get(definition_id, definition_id)


## Pure query for testing: returns localized Thai display name for a decoration [param definition_id] in the bound catalog, or "" if not in catalog.
func get_decoration_display_name_in_journal(definition_id: String) -> String:
	if not has_decoration_in_journal_catalog(definition_id):
		return ""
	return DecorationPicker.PROVISIONAL_DECORATION_DISPLAY_NAMES.get(definition_id, definition_id)


## Pure query for testing: returns localized Thai display name for an ambient event [param definition_id] in the bound catalog, or "" if not in catalog.
func get_event_display_name_in_journal(definition_id: String) -> String:
	if not has_event_in_journal_catalog(definition_id):
		return ""
	return GardenView.PROVISIONAL_EVENT_DISPLAY_NAMES.get(definition_id, definition_id)


## Pure query for testing: returns localized Thai description for an ambient event [param definition_id] in the bound catalog, or "" if not in catalog.
func get_event_description_in_journal(definition_id: String) -> String:
	if not has_event_in_journal_catalog(definition_id):
		return ""
	return GardenView.PROVISIONAL_EVENT_DESCRIPTIONS.get(definition_id, "")


## Pure query for testing: returns true if the rendered summary label text is non-empty.
func has_summary_text() -> bool:
	return not get_summary_text().is_empty()


## Pure query for testing: returns total number of displayed entry texts across all sections in the current binding.
func get_displayed_entry_count() -> int:
	return _entry_texts_by_id.size()


## Pure query for testing: returns true if at least one entry text is displayed in the current binding.
func has_any_displayed_entries() -> bool:
	return not _entry_texts_by_id.is_empty()


## Pure query for testing: returns localized Thai traits summary string for a plant [param definition_id] in the bound catalog, or "" if not in catalog.
func get_plant_traits_summary_in_journal(definition_id: String) -> String:
	if not has_plant_in_journal_catalog(definition_id):
		return ""
	return _format_plant_traits(_catalog.get_plant(definition_id))


## Pure query for testing: returns localized Thai traits summary string for a decoration [param definition_id] in the bound catalog, or "" if not in catalog.
func get_decoration_traits_summary_in_journal(definition_id: String) -> String:
	if not has_decoration_in_journal_catalog(definition_id):
		return ""
	return _format_decoration_traits(_catalog.get_decoration(definition_id))


## Pure query for testing: returns localized Thai habitat clue string for a visitor [param definition_id] in the bound catalog, or "" if not in catalog.
func get_visitor_clue_in_journal(definition_id: String) -> String:
	if not has_visitor_in_journal_catalog(definition_id):
		return ""
	return _format_visitor_clue(_catalog.get_visitor(definition_id))


## Pure query for testing: returns localized Thai condition clue string for an ambient event [param definition_id] in the bound catalog, or "" if not in catalog.
func get_event_clue_in_journal(definition_id: String) -> String:
	if not has_event_in_journal_catalog(definition_id):
		return ""
	return _format_event_clue(_catalog.get_event(definition_id))


## Pure query for testing: returns catalog price for a decoration [param definition_id] in the bound catalog, or -1 if not in catalog.
func get_decoration_price_in_journal(definition_id: String) -> int:
	if not has_decoration_in_journal_catalog(definition_id):
		return -1
	var def: DecorationDefinition = _catalog.get_decoration(definition_id)
	return def.price if def != null else -1


## Pure query for testing: returns catalog harvest_reward for a plant [param definition_id] in the bound catalog, or 0 if not in catalog.
func get_plant_harvest_reward_in_journal(definition_id: String) -> int:
	if not has_plant_in_journal_catalog(definition_id):
		return 0
	var def: PlantDefinition = _catalog.get_plant(definition_id)
	return maxi(0, def.harvest_reward) if def != null else 0


## Pure query for testing: returns catalog mature_after_seconds for a plant [param definition_id] in the bound catalog, or 0 if not in catalog.
func get_plant_mature_after_seconds_in_journal(definition_id: String) -> int:
	if not has_plant_in_journal_catalog(definition_id):
		return 0
	var def: PlantDefinition = _catalog.get_plant(definition_id)
	return maxi(0, def.mature_after_seconds) if def != null else 0


## Pure query for testing: returns catalog sprout_after_seconds for a plant [param definition_id] in the bound catalog, or 0 if not in catalog.
func get_plant_sprout_after_seconds_in_journal(definition_id: String) -> int:
	if not has_plant_in_journal_catalog(definition_id):
		return 0
	var def: PlantDefinition = _catalog.get_plant(definition_id)
	return maxi(0, def.sprout_after_seconds) if def != null else 0


## Pure query for testing: returns catalog growing_after_seconds for a plant [param definition_id] in the bound catalog, or 0 if not in catalog.
func get_plant_growing_after_seconds_in_journal(definition_id: String) -> int:
	if not has_plant_in_journal_catalog(definition_id):
		return 0
	var def: PlantDefinition = _catalog.get_plant(definition_id)
	return maxi(0, def.growing_after_seconds) if def != null else 0


## Pure query for testing: returns a defensive copy of environmental traits for a plant [param definition_id] in the bound catalog, or [] if not in catalog.
func get_plant_traits_in_journal(definition_id: String) -> Array[String]:
	if not has_plant_in_journal_catalog(definition_id):
		return []
	var def: PlantDefinition = _catalog.get_plant(definition_id)
	return def.environmental_traits.duplicate() if def != null else []


## Pure query for testing: returns a defensive copy of environmental traits for a decoration [param definition_id] in the bound catalog, or [] if not in catalog.
func get_decoration_traits_in_journal(definition_id: String) -> Array[String]:
	if not has_decoration_in_journal_catalog(definition_id):
		return []
	var def: DecorationDefinition = _catalog.get_decoration(definition_id)
	return def.environmental_traits.duplicate() if def != null else []


## Pure query for testing: returns localized Thai display names for environmental traits of a plant [param definition_id] in the bound catalog, or [] if not in catalog.
func get_plant_trait_display_names_in_journal(definition_id: String) -> Array[String]:
	var result: Array[String] = []
	for trait_id: String in get_plant_traits_in_journal(definition_id):
		result.append(GardenView.PROVISIONAL_TRAIT_DISPLAY_NAMES.get(trait_id, trait_id))
	return result


## Pure query for testing: returns localized Thai display names for environmental traits of a decoration [param definition_id] in the bound catalog, or [] if not in catalog.
func get_decoration_trait_display_names_in_journal(definition_id: String) -> Array[String]:
	var result: Array[String] = []
	for trait_id: String in get_decoration_traits_in_journal(definition_id):
		result.append(GardenView.PROVISIONAL_TRAIT_DISPLAY_NAMES.get(trait_id, trait_id))
	return result


## Pure query for testing: returns true if [param definition_id] is a plant in the bound catalog and exposes [param trait_id].
func has_plant_trait_in_journal(definition_id: String, trait_id: String) -> bool:
	if trait_id.is_empty() or not has_plant_in_journal_catalog(definition_id):
		return false
	return get_plant_traits_in_journal(definition_id).has(trait_id)


## Pure query for testing: returns true if [param definition_id] is a decoration in the bound catalog and exposes [param trait_id].
func has_decoration_trait_in_journal(definition_id: String, trait_id: String) -> bool:
	if trait_id.is_empty() or not has_decoration_in_journal_catalog(definition_id):
		return false
	return get_decoration_traits_in_journal(definition_id).has(trait_id)


## Pure query for testing: returns count of environmental traits for a plant [param definition_id] in the bound catalog, or 0 if not in catalog.
func get_plant_trait_count_in_journal(definition_id: String) -> int:
	return get_plant_traits_in_journal(definition_id).size()


## Pure query for testing: returns count of environmental traits for a decoration [param definition_id] in the bound catalog, or 0 if not in catalog.
func get_decoration_trait_count_in_journal(definition_id: String) -> int:
	return get_decoration_traits_in_journal(definition_id).size()


## Pure query for testing: returns true if a plant [param definition_id] in the bound catalog exposes at least one environmental trait.
func has_plant_any_traits_in_journal(definition_id: String) -> bool:
	return get_plant_trait_count_in_journal(definition_id) > 0


## Pure query for testing: returns true if a decoration [param definition_id] in the bound catalog exposes at least one environmental trait.
func has_decoration_any_traits_in_journal(definition_id: String) -> bool:
	return get_decoration_trait_count_in_journal(definition_id) > 0


## Pure query for testing: returns localized Thai display names for all catalog plants in deterministic catalog order, or [] if unbound.
func get_all_plant_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_all_plant_ids_in_journal():
		result.append(get_plant_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all catalog visitors in deterministic catalog order, or [] if unbound.
func get_all_visitor_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_all_visitor_ids_in_journal():
		result.append(get_visitor_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all catalog decorations in deterministic catalog order, or [] if unbound.
func get_all_decoration_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_all_decoration_ids_in_journal():
		result.append(get_decoration_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for all catalog ambient events in deterministic catalog order, or [] if unbound.
func get_all_event_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_all_event_ids_in_journal():
		result.append(get_event_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for discovered catalog plants in deterministic catalog order, or [] if unbound.
func get_discovered_plant_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_discovered_plant_ids_in_journal():
		result.append(get_plant_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for discovered catalog visitors in deterministic catalog order, or [] if unbound.
func get_discovered_visitor_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_discovered_visitor_ids_in_journal():
		result.append(get_visitor_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for placed catalog decorations in deterministic catalog order, or [] if unbound.
func get_placed_decoration_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_placed_decoration_ids_in_journal():
		result.append(get_decoration_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for active/eligible catalog ambient events in deterministic catalog order, or [] if unbound.
func get_active_event_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_active_event_ids_in_journal():
		result.append(get_event_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for undiscovered catalog plants in deterministic catalog order, or [] if unbound.
func get_undiscovered_plant_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_undiscovered_plant_ids_in_journal():
		result.append(get_plant_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for undiscovered catalog visitors in deterministic catalog order, or [] if unbound.
func get_undiscovered_visitor_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_undiscovered_visitor_ids_in_journal():
		result.append(get_visitor_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for currently eligible catalog visitors in deterministic catalog order, or [] if unbound.
func get_eligible_visitor_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_eligible_visitor_ids_in_journal():
		result.append(get_visitor_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for currently ineligible catalog visitors in deterministic catalog order, or [] if unbound.
func get_ineligible_visitor_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_ineligible_visitor_ids_in_journal():
		result.append(get_visitor_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for unplaced catalog decorations in deterministic catalog order, or [] if unbound.
func get_unplaced_decoration_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_unplaced_decoration_ids_in_journal():
		result.append(get_decoration_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for inactive/ineligible catalog ambient events in deterministic catalog order, or [] if unbound.
func get_inactive_event_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_inactive_event_ids_in_journal():
		result.append(get_event_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for currently planted catalog plants in deterministic catalog order, or [] if unbound.
func get_currently_planted_plant_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_currently_planted_plant_ids_in_journal():
		result.append(get_plant_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for unplanted catalog plants in deterministic catalog order, or [] if unbound.
func get_unplanted_plant_display_names_in_journal() -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_unplanted_plant_ids_in_journal():
		result.append(get_plant_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns deterministic catalog-ordered plant IDs in the bound catalog that expose [param trait_id], or [] if empty/unbound.
func get_plant_ids_with_trait_in_journal(trait_id: String) -> Array[String]:
	if trait_id.is_empty() or _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_plant_ids():
		if has_plant_trait_in_journal(def_id, trait_id):
			result.append(def_id)
	return result


## Pure query for testing: returns deterministic catalog-ordered decoration IDs in the bound catalog that expose [param trait_id], or [] if empty/unbound.
func get_decoration_ids_with_trait_in_journal(trait_id: String) -> Array[String]:
	if trait_id.is_empty() or _catalog == null:
		return []
	var result: Array[String] = []
	for def_id: String in _catalog.get_all_decoration_ids():
		if has_decoration_trait_in_journal(def_id, trait_id):
			result.append(def_id)
	return result


## Pure query for testing: returns count of catalog plants in the bound catalog that expose [param trait_id].
func get_plant_count_with_trait_in_journal(trait_id: String) -> int:
	return get_plant_ids_with_trait_in_journal(trait_id).size()


## Pure query for testing: returns count of catalog decorations in the bound catalog that expose [param trait_id].
func get_decoration_count_with_trait_in_journal(trait_id: String) -> int:
	return get_decoration_ids_with_trait_in_journal(trait_id).size()


## Pure query for testing: returns true if at least one catalog plant in the bound catalog exposes [param trait_id].
func has_any_plants_with_trait_in_journal(trait_id: String) -> bool:
	return get_plant_count_with_trait_in_journal(trait_id) > 0


## Pure query for testing: returns true if at least one catalog decoration in the bound catalog exposes [param trait_id].
func has_any_decorations_with_trait_in_journal(trait_id: String) -> bool:
	return get_decoration_count_with_trait_in_journal(trait_id) > 0


## Pure query for testing: returns localized Thai display names for catalog plants that expose [param trait_id] in deterministic catalog order, or [] if empty/unbound.
func get_plant_display_names_with_trait_in_journal(trait_id: String) -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_plant_ids_with_trait_in_journal(trait_id):
		result.append(get_plant_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns localized Thai display names for catalog decorations that expose [param trait_id] in deterministic catalog order, or [] if empty/unbound.
func get_decoration_display_names_with_trait_in_journal(trait_id: String) -> Array[String]:
	var result: Array[String] = []
	for def_id: String in get_decoration_ids_with_trait_in_journal(trait_id):
		result.append(get_decoration_display_name_in_journal(def_id))
	return result


## Pure query for testing: returns true if a plant [param definition_id] has a non-empty localized display name in the bound catalog.
func has_plant_display_name_in_journal(definition_id: String) -> bool:
	return not get_plant_display_name_in_journal(definition_id).is_empty()


## Pure query for testing: returns true if a visitor [param definition_id] has a non-empty localized display name in the bound catalog.
func has_visitor_display_name_in_journal(definition_id: String) -> bool:
	return not get_visitor_display_name_in_journal(definition_id).is_empty()


## Pure query for testing: returns true if a decoration [param definition_id] has a non-empty localized display name in the bound catalog.
func has_decoration_display_name_in_journal(definition_id: String) -> bool:
	return not get_decoration_display_name_in_journal(definition_id).is_empty()


## Pure query for testing: returns true if an ambient event [param definition_id] has a non-empty localized display name in the bound catalog.
func has_event_display_name_in_journal(definition_id: String) -> bool:
	return not get_event_display_name_in_journal(definition_id).is_empty()


## Pure query for testing: returns true if an ambient event [param definition_id] has a non-empty localized flavor description in the bound catalog.
func has_event_description_in_journal(definition_id: String) -> bool:
	return not get_event_description_in_journal(definition_id).is_empty()


## Pure query for testing: returns true if a plant [param definition_id] has a non-empty localized environmental traits summary in the bound catalog.
func has_plant_traits_summary_in_journal(definition_id: String) -> bool:
	return not get_plant_traits_summary_in_journal(definition_id).is_empty()


## Pure query for testing: returns true if a decoration [param definition_id] has a non-empty localized environmental traits summary in the bound catalog.
func has_decoration_traits_summary_in_journal(definition_id: String) -> bool:
	return not get_decoration_traits_summary_in_journal(definition_id).is_empty()


## Pure query for testing: returns true if a visitor [param definition_id] has a non-empty localized habitat clue in the bound catalog.
func has_visitor_clue_in_journal(definition_id: String) -> bool:
	return not get_visitor_clue_in_journal(definition_id).is_empty()


## Pure query for testing: returns true if an ambient event [param definition_id] has a non-empty localized condition clue in the bound catalog.
func has_event_clue_in_journal(definition_id: String) -> bool:
	return not get_event_clue_in_journal(definition_id).is_empty()


## Pure query for testing: returns true if a decoration [param definition_id] in the bound catalog has a positive price (> 0).
func has_decoration_positive_price_in_journal(definition_id: String) -> bool:
	return get_decoration_price_in_journal(definition_id) > 0


## Pure query for testing: returns true if a plant [param definition_id] in the bound catalog has a positive harvest_reward (> 0).
func has_plant_positive_harvest_reward_in_journal(definition_id: String) -> bool:
	return get_plant_harvest_reward_in_journal(definition_id) > 0


## Pure query for testing: returns true if a plant [param definition_id] in the bound catalog has a positive mature_after_seconds duration (> 0).
func has_plant_positive_mature_duration_in_journal(definition_id: String) -> bool:
	return get_plant_mature_after_seconds_in_journal(definition_id) > 0
