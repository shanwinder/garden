## discovery_pacing_evaluator.gd
## Pure domain rule evaluator for the Suggested First Seven Days of Discovery pacing
## per GAME_DESIGN.md Section 22.
##
## Architectural rules:
## - Belongs to the domain progression layer (src/domain/progression/).
## - Pure domain class: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Deterministic, stateless, and side-effect free.
## - Does not mutate GameState, JournalState, or EconomyState.
## - Does not access GameClock, RandomSource, or filesystem.
## - Pacing reference target only; not a mandatory login lock or streak requirement.
class_name DiscoveryPacingEvaluator
extends RefCounted

const MILESTONE_THEMES: Dictionary = {
	DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE: "early_phase",
	DiscoveryPacingMilestone.MILESTONE_DAY_2_EARLY_RETURN: "early_return",
	DiscoveryPacingMilestone.MILESTONE_DAY_3_DEVELOPING_GARDEN: "developing_garden",
	DiscoveryPacingMilestone.MILESTONE_DAY_4_WEATHER_DISCOVERY: "weather_discovery",
	DiscoveryPacingMilestone.MILESTONE_DAY_5_WATER_HABITAT: "water_habitat",
	DiscoveryPacingMilestone.MILESTONE_DAY_6_NIGHT_DISCOVERY: "night_discovery",
	DiscoveryPacingMilestone.MILESTONE_DAY_7_FIRST_EXPANSION: "first_expansion",
}

const MILESTONE_TITLES: Dictionary = {
	DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE: "วันที่ 1: ก้าวแรกสู่สวนสวย",
	DiscoveryPacingMilestone.MILESTONE_DAY_2_EARLY_RETURN: "วันที่ 2: การกลับมาเยือน",
	DiscoveryPacingMilestone.MILESTONE_DAY_3_DEVELOPING_GARDEN: "วันที่ 3: สวนที่ค่อยๆ เติบโต",
	DiscoveryPacingMilestone.MILESTONE_DAY_4_WEATHER_DISCOVERY: "วันที่ 4: สายฝนและสภาพอากาศ",
	DiscoveryPacingMilestone.MILESTONE_DAY_5_WATER_HABITAT: "วันที่ 5: แหล่งน้ำฉ่ำเย็น",
	DiscoveryPacingMilestone.MILESTONE_DAY_6_NIGHT_DISCOVERY: "วันที่ 6: แสงไฟยามราตรี",
	DiscoveryPacingMilestone.MILESTONE_DAY_7_FIRST_EXPANSION: "วันที่ 7: สวนแสนสุขขยับขยาย",
}

const MILESTONE_DESCRIPTIONS: Dictionary = {
	DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE: "เริ่มต้นทำความรู้จักสวน ปลูกสมุนไพรโตเร็ว เรียนรู้การเก็บเกี่ยว และพบผู้มาเยือนตัวแรกอย่างผีเสื้อ",
	DiscoveryPacingMilestone.MILESTONE_DAY_2_EARLY_RETURN: "เริ่มสัมผัสองค์ประกอบของน้ำ เปิดโอกาสให้นกแวะเวียนมา และพบรายการใหม่ในสมุดบ้านสวน",
	DiscoveryPacingMilestone.MILESTONE_DAY_3_DEVELOPING_GARDEN: "จัดวางของตกแต่งอย่างอิสระมากขึ้น จัดวางม้านั่งพักผ่อน และเฝ้าคอยแมวเหมียวแวะมาพักผ่อน",
	DiscoveryPacingMilestone.MILESTONE_DAY_4_WEATHER_DISCOVERY: "เรียนรู้ว่าสภาพอากาศสร้างความมีชีวิตชีวาให้สวน สายฝนชุ่มฉ่ำชวนให้กบน้อยแวะมาใกล้แหล่งน้ำ",
	DiscoveryPacingMilestone.MILESTONE_DAY_5_WATER_HABITAT: "สร้างสระน้ำขนาดเล็กในสวน เพิ่มความชุ่มชื้นและเปิดรับเหตุการณ์และสิ่งมีชีวิตทางน้ำที่หลากหลาย",
	DiscoveryPacingMilestone.MILESTONE_DAY_6_NIGHT_DISCOVERY: "สัมผัสบรรยากาศยามค่ำคืนในสวน หิ่งห้อยส่องแสงระยิบระยับคู่กับแสงโคมไฟสวนยามค่ำคืน",
	DiscoveryPacingMilestone.MILESTONE_DAY_7_FIRST_EXPANSION: "สวนเติบโตจนพร้อมสู่การขยายขอบเขตและได้รับรางวัลความก้าวหน้า พร้อมให้ผู้เล่นทดลองดูแลสวนอย่างอิสระ",
}

const MILESTONE_FOCUSES: Dictionary = {
	DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE: "ลองปลูกพืชและเฝ้ามองผู้มาเยือนตัวแรกแวะเวียนมาในสวน",
	DiscoveryPacingMilestone.MILESTONE_DAY_2_EARLY_RETURN: "จัดวางของตกแต่งเกี่ยวกับน้ำหรือปลูกพืชเพื่อให้มีนกแวะมาเยือน",
	DiscoveryPacingMilestone.MILESTONE_DAY_3_DEVELOPING_GARDEN: "จัดวางม้านั่งพักผ่อนในสวนเพื่อสร้างบรรยากาศสงบให้แมวแวะมา",
	DiscoveryPacingMilestone.MILESTONE_DAY_4_WEATHER_DISCOVERY: "เฝ้ารอสภาพอากาศฝนตกและมีแหล่งน้ำเพื่อค้นพบกบน้อยในสวน",
	DiscoveryPacingMilestone.MILESTONE_DAY_5_WATER_HABITAT: "จัดวางสระน้ำขนาดเล็กเพื่อสร้างถิ่นอาศัยทางน้ำอันอุดมสมบูรณ์",
	DiscoveryPacingMilestone.MILESTONE_DAY_6_NIGHT_DISCOVERY: "เปิดโคมไฟสวนยามค่ำคืนและเฝ้าดูฝูงหิ่งห้อยส่องแสงในสวน",
	DiscoveryPacingMilestone.MILESTONE_DAY_7_FIRST_EXPANSION: "ดูแลสวนให้สมบูรณ์และทดลองจัดวางพืชและของตกแต่งตามความพึงพอใจ",
}


## Constructs a typed DiscoveryPacingMilestone for [param milestone_id] with evaluated [param is_achieved].
static func create_milestone(milestone_id: String, is_achieved: bool = false) -> DiscoveryPacingMilestone:
	var idx: int = DiscoveryPacingMilestone.day_index_for_id(milestone_id)
	if idx < 0:
		return null
	var theme: String = MILESTONE_THEMES.get(milestone_id, "")
	var title: String = MILESTONE_TITLES.get(milestone_id, "")
	var desc: String = MILESTONE_DESCRIPTIONS.get(milestone_id, "")
	var focus: String = MILESTONE_FOCUSES.get(milestone_id, "")
	return DiscoveryPacingMilestone.new(
		milestone_id,
		idx,
		theme,
		title,
		desc,
		focus,
		is_achieved
	)


## Evaluates whether [param milestone_id] is achieved from [param snapshot] and [param journal].
static func is_milestone_achieved(
	milestone_id: String,
	snapshot: GardenSnapshot,
	journal: JournalState = null
) -> bool:
	var j_count: int = journal.get_count() if journal != null else 0

	match milestone_id:
		DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE:
			# Plant fast herb, early harvest, butterfly visit, or first discovery
			if snapshot != null and snapshot.get_total_plant_count() > 0:
				return true
			if journal != null:
				if journal.has_discovered("visitor.butterfly") or journal.has_discovered("plant.holy_basil") or j_count >= 1:
					return true
			return false

		DiscoveryPacingMilestone.MILESTONE_DAY_2_EARLY_RETURN:
			# Water-related element, perch/bird activity, or journal has multiple discoveries
			if snapshot != null:
				if (
					snapshot.has_trait(EnvironmentalTrait.WATER)
					or snapshot.has_trait(EnvironmentalTrait.PERCH)
					or snapshot.get_decoration_count_for_definition("decoration.clay_jar") > 0
					or snapshot.get_decoration_count_for_definition("decoration.watering_can") > 0
				):
					return true
			if journal != null:
				if journal.has_discovered("visitor.bird") or j_count >= 2:
					return true
			return false

		DiscoveryPacingMilestone.MILESTONE_DAY_3_DEVELOPING_GARDEN:
			# Resting/shelter decoration (bench), cat visitor, or 2+ decorations
			if snapshot != null:
				if (
					snapshot.has_trait(EnvironmentalTrait.SHELTER)
					or snapshot.get_decoration_count_for_definition("decoration.bench") > 0
					or snapshot.get_total_decoration_count() >= 2
				):
					return true
			if journal != null:
				if journal.has_discovered("visitor.cat") or j_count >= 3:
					return true
			return false

		DiscoveryPacingMilestone.MILESTONE_DAY_4_WEATHER_DISCOVERY:
			# Frog visitor, rain + water habitat, 4+ discoveries, or small pond
			if journal != null:
				if journal.has_discovered("visitor.frog") or j_count >= 4:
					return true
			if snapshot != null:
				if (
					snapshot.get_decoration_count_for_definition("decoration.small_pond") > 0
					or (snapshot.has_trait(EnvironmentalTrait.WATER) and snapshot.get_weather_state() == GardenWeather.RAIN)
				):
					return true
			return false

		DiscoveryPacingMilestone.MILESTONE_DAY_5_WATER_HABITAT:
			# Small pond decoration, water events, or 5+ discoveries
			if snapshot != null:
				if snapshot.get_decoration_count_for_definition("decoration.small_pond") > 0:
					return true
			if journal != null:
				if j_count >= 5:
					return true
			return false

		DiscoveryPacingMilestone.MILESTONE_DAY_6_NIGHT_DISCOVERY:
			# Firefly visitor, lamp at night, or 6+ discoveries
			if journal != null:
				if journal.has_discovered("visitor.firefly") or j_count >= 6:
					return true
			if snapshot != null:
				if snapshot.get_time_period() == GardenTimePeriod.NIGHT and snapshot.has_trait(EnvironmentalTrait.LIGHT):
					return true
			return false

		DiscoveryPacingMilestone.MILESTONE_DAY_7_FIRST_EXPANSION:
			# Living garden score threshold (45 pts) or 8+ discoveries in journal
			if snapshot != null:
				var score: int = GardenProgressionStage.compute_score(snapshot, journal)
				if score >= GardenProgressionStage.THRESHOLD_LIVING_GARDEN:
					return true
			if journal != null:
				if j_count >= 8:
					return true
			return false

		_:
			return false


## Evaluates a single DiscoveryPacingMilestone value object for [param milestone_id].
static func evaluate_milestone(
	milestone_id: String,
	snapshot: GardenSnapshot,
	journal: JournalState = null
) -> DiscoveryPacingMilestone:
	var achieved: bool = is_milestone_achieved(milestone_id, snapshot, journal)
	return create_milestone(milestone_id, achieved)


## Evaluates all 7 canonical pacing milestones in order (Day 1..7).
static func evaluate_all(
	snapshot: GardenSnapshot,
	journal: JournalState = null
) -> Array[DiscoveryPacingMilestone]:
	var results: Array[DiscoveryPacingMilestone] = []
	for mid: String in DiscoveryPacingMilestone.ALL_MILESTONES:
		results.append(evaluate_milestone(mid, snapshot, journal))
	return results


## Evaluates and returns the active discovery pacing milestone.
## Returns the earliest unachieved milestone, or Day 7 if all milestones are completed.
static func evaluate_active_milestone(
	snapshot: GardenSnapshot,
	journal: JournalState = null,
	_day_number: int = 0
) -> DiscoveryPacingMilestone:
	var all_m: Array[DiscoveryPacingMilestone] = evaluate_all(snapshot, journal)
	for m: DiscoveryPacingMilestone in all_m:
		if not m.is_achieved():
			return m
	# All completed -> return Day 7 marked as achieved
	return all_m.back() if not all_m.is_empty() else null


## Returns the count of achieved milestones (0..7).
static func get_achieved_count(
	snapshot: GardenSnapshot,
	journal: JournalState = null
) -> int:
	var count: int = 0
	for mid: String in DiscoveryPacingMilestone.ALL_MILESTONES:
		if is_milestone_achieved(mid, snapshot, journal):
			count += 1
	return count


## Returns true if all 7 milestones are achieved.
static func is_all_completed(
	snapshot: GardenSnapshot,
	journal: JournalState = null
) -> bool:
	return get_achieved_count(snapshot, journal) == DiscoveryPacingMilestone.ALL_MILESTONES.size()
