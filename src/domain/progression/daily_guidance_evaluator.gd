## daily_guidance_evaluator.gd
## Pure domain evaluator for Daily Guidance ("What could we do today? / วันนี้ทำอะไรดี").
##
## Derives three lightweight, non-punitive daily suggestions per GAME_DESIGN.md Section 20
## deterministically from a day index (or UTC timestamp) and current garden snapshot/journal.
##
## Canonical guidance identifiers:
## - "daily_guidance.harvest_produce"   : harvest produce 3 times (เก็บเกี่ยวผลผลิต 3 ครั้ง)
## - "daily_guidance.plant_flower"      : plant 1 flower (ปลูกไม้ดอก 1 ต้น เช่น มะลิ หรือ ดาวเรือง)
## - "daily_guidance.plant_crop"        : plant 1 crop/herb (ปลูกพืชสวนครัวหรือสมุนไพร 1 ต้น)
## - "daily_guidance.plant_any"         : plant 1 new plant (ปลูกพันธุ์ไม้ใหม่ในสวน 1 ต้น)
## - "daily_guidance.observe_visitor"   : observe 1 visitor (สำรวจสิ่งมีชีวิตผู้มาเยือน 1 ครั้ง)
## - "daily_guidance.observe_event"     : observe 1 event (สัมผัสบรรยากาศหรือเหตุการณ์พิเศษในสวน)
## - "daily_guidance.place_decoration"  : place 1 decoration (จัดวางของตกแต่งสวน 1 ชิ้น)
## - "daily_guidance.care_water_habitat": maintain water habitat (จัดวางหรือรักษาแหล่งน้ำในสวน)
## - "daily_guidance.check_journal"     : review discoveries (เปิดสมุดบ้านสวนเพื่อสำรวจการค้นพบ)
##
## Architectural rules:
## - Belongs to the domain progression layer (src/domain/progression/).
## - Pure domain class: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Deterministic, stateless, and side-effect free.
## - Independent of SceneTree, GameClock, RandomSource, and filesystem.
class_name DailyGuidanceEvaluator
extends RefCounted

const GUIDANCE_HARVEST_PRODUCE: String = "daily_guidance.harvest_produce"
const GUIDANCE_PLANT_FLOWER: String = "daily_guidance.plant_flower"
const GUIDANCE_PLANT_CROP: String = "daily_guidance.plant_crop"
const GUIDANCE_PLANT_ANY: String = "daily_guidance.plant_any"
const GUIDANCE_OBSERVE_VISITOR: String = "daily_guidance.observe_visitor"
const GUIDANCE_OBSERVE_EVENT: String = "daily_guidance.observe_event"
const GUIDANCE_PLACE_DECORATION: String = "daily_guidance.place_decoration"
const GUIDANCE_CARE_WATER_HABITAT: String = "daily_guidance.care_water_habitat"
const GUIDANCE_CHECK_JOURNAL: String = "daily_guidance.check_journal"

const ALL_DAILY_GUIDANCE_IDS: Array[String] = [
	GUIDANCE_HARVEST_PRODUCE,
	GUIDANCE_PLANT_FLOWER,
	GUIDANCE_PLANT_CROP,
	GUIDANCE_PLANT_ANY,
	GUIDANCE_OBSERVE_VISITOR,
	GUIDANCE_OBSERVE_EVENT,
	GUIDANCE_PLACE_DECORATION,
	GUIDANCE_CARE_WATER_HABITAT,
	GUIDANCE_CHECK_JOURNAL,
]

const CATEGORIES: Dictionary = {
	GUIDANCE_HARVEST_PRODUCE: "harvest",
	GUIDANCE_PLANT_FLOWER: "planting",
	GUIDANCE_PLANT_CROP: "planting",
	GUIDANCE_PLANT_ANY: "planting",
	GUIDANCE_OBSERVE_VISITOR: "visitor",
	GUIDANCE_OBSERVE_EVENT: "event",
	GUIDANCE_PLACE_DECORATION: "decoration",
	GUIDANCE_CARE_WATER_HABITAT: "environment",
	GUIDANCE_CHECK_JOURNAL: "journal",
}

const TARGET_COUNTS: Dictionary = {
	GUIDANCE_HARVEST_PRODUCE: 3,
	GUIDANCE_PLANT_FLOWER: 1,
	GUIDANCE_PLANT_CROP: 1,
	GUIDANCE_PLANT_ANY: 1,
	GUIDANCE_OBSERVE_VISITOR: 1,
	GUIDANCE_OBSERVE_EVENT: 1,
	GUIDANCE_PLACE_DECORATION: 1,
	GUIDANCE_CARE_WATER_HABITAT: 1,
	GUIDANCE_CHECK_JOURNAL: 1,
}


## Returns true if [param guidance_id] is one of the canonical daily guidance IDs.
static func is_valid_guidance_id(guidance_id: String) -> bool:
	return ALL_DAILY_GUIDANCE_IDS.has(guidance_id)


## Constructs a typed DailyGuidanceItem for [param guidance_id], or null if invalid.
static func create_item(
	guidance_id: String,
	locale: String = GardenLocalization.DEFAULT_LOCALE
) -> DailyGuidanceItem:
	if not is_valid_guidance_id(guidance_id):
		return null
	var category: String = CATEGORIES.get(guidance_id, "general")
	var count: int = TARGET_COUNTS.get(guidance_id, 1)
	var text: String = GardenLocalization.get_daily_guidance_text(guidance_id, locale)
	return DailyGuidanceItem.new(guidance_id, category, count, text)


## Deterministically derives exactly three distinct, non-punitive daily suggestions
## for [param day_number], adapted gently to current [param snapshot] and [param journal].
static func evaluate_daily_guidance(
	day_number: int,
	snapshot: GardenSnapshot = null,
	journal: JournalState = null,
	locale: String = GardenLocalization.DEFAULT_LOCALE
) -> Array[DailyGuidanceItem]:
	var day_idx: int = posmod(day_number, 1000000)

	# Pool 1: Growth & Harvest (พืชผลและการเก็บเกี่ยว)
	var pool_1: Array[String] = []
	if snapshot == null or snapshot.get_total_plant_count() <= 0:
		pool_1 = [GUIDANCE_PLANT_ANY, GUIDANCE_PLANT_FLOWER, GUIDANCE_PLANT_CROP]
	else:
		pool_1 = [GUIDANCE_HARVEST_PRODUCE, GUIDANCE_PLANT_FLOWER, GUIDANCE_PLANT_CROP]

	# Pool 2: Life, Visitors & Ambient Events (สิ่งมีชีวิตและบรรยากาศ)
	var pool_2: Array[String] = [
		GUIDANCE_OBSERVE_VISITOR,
		GUIDANCE_OBSERVE_EVENT,
	]

	# Pool 3: Care, Decorations & Journal (การดูแล ตกแต่ง และบันทึก)
	var pool_3: Array[String] = []
	if snapshot != null and snapshot.get_total_decoration_count() <= 0:
		pool_3 = [GUIDANCE_PLACE_DECORATION, GUIDANCE_CARE_WATER_HABITAT, GUIDANCE_CHECK_JOURNAL]
	else:
		pool_3 = [GUIDANCE_PLACE_DECORATION, GUIDANCE_CARE_WATER_HABITAT, GUIDANCE_CHECK_JOURNAL]

	var id_1: String = pool_1[posmod(day_idx, pool_1.size())]
	var id_2: String = pool_2[posmod(day_idx + 1, pool_2.size())]
	var id_3: String = pool_3[posmod(day_idx + 2, pool_3.size())]

	var item_1: DailyGuidanceItem = create_item(id_1, locale)
	var item_2: DailyGuidanceItem = create_item(id_2, locale)
	var item_3: DailyGuidanceItem = create_item(id_3, locale)

	var items: Array[DailyGuidanceItem] = []
	if item_1 != null:
		items.append(item_1)
	if item_2 != null:
		items.append(item_2)
	if item_3 != null:
		items.append(item_3)

	return items
