## garden_progression_stage.gd
## Pure domain rule evaluator for Garden Level / Garden Stage (GAME_DESIGN.md Section 18)
## and Optional Gentle Guidance (GAME_DESIGN.md Section 20).
##
## Derives how established the garden has become from an immutable GardenSnapshot and
## JournalState without mutating state, accessing clocks/RNG, or altering the save schema.
##
## Canonical stages (GAME_DESIGN.md Section 18):
## - "starting_garden"   (Starting Garden / สวนเริ่มต้น)       : 0+ pts
## - "growing_garden"    (Growing Garden / สวนกำลังเติบโต)     : 10+ pts
## - "shady_garden"      (Shady Garden / สวนร่มรื่น)            : 25+ pts
## - "living_garden"     (Living Garden / สวนมีชีวิต)           : 45+ pts
## - "happy_garden_home" (Happy Garden Home / บ้านสวนแสนสุข)   : 70+ pts
##
## Architectural rules:
## - Belongs to the domain progression layer (src/domain/progression/).
## - Pure domain class: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Deterministic, stateless, and side-effect free.
class_name GardenProgressionStage
extends RefCounted

const STARTING_GARDEN: String = "starting_garden"
const GROWING_GARDEN: String = "growing_garden"
const SHADY_GARDEN: String = "shady_garden"
const LIVING_GARDEN: String = "living_garden"
const HAPPY_GARDEN_HOME: String = "happy_garden_home"

const STAGE_STARTING_GARDEN: String = STARTING_GARDEN
const STAGE_GROWING_GARDEN: String = GROWING_GARDEN
const STAGE_SHADY_GARDEN: String = SHADY_GARDEN
const STAGE_LIVING_GARDEN: String = LIVING_GARDEN
const STAGE_HAPPY_GARDEN_HOME: String = HAPPY_GARDEN_HOME

const ALL_STAGES: Array[String] = [
	STARTING_GARDEN,
	GROWING_GARDEN,
	SHADY_GARDEN,
	LIVING_GARDEN,
	HAPPY_GARDEN_HOME,
]

const THRESHOLD_STARTING_GARDEN: int = 0
const THRESHOLD_GROWING_GARDEN: int = 10
const THRESHOLD_SHADY_GARDEN: int = 25
const THRESHOLD_LIVING_GARDEN: int = 45
const THRESHOLD_HAPPY_GARDEN_HOME: int = 70

const POINTS_PER_PLANT: int = 3
const POINTS_PER_MATURE_PLANT: int = 2
const POINTS_PER_DECORATION: int = 4
const POINTS_PER_ACTIVE_TRAIT: int = 3
const POINTS_PER_DISCOVERY: int = 5

const MVP_TARGET_DISCOVERY_COUNT: int = 10

const GUIDANCE_PLANT_FIRST: String = "guidance.plant_first"
const GUIDANCE_OBSERVE_VISITOR: String = "guidance.observe_visitor"
const GUIDANCE_PLACE_DECORATION: String = "guidance.place_decoration"
const GUIDANCE_CREATE_WATER_HABITAT: String = "guidance.create_water_habitat"
const GUIDANCE_DISCOVER_MORE: String = "guidance.discover_more"
const GUIDANCE_ENJOY_GARDEN: String = "guidance.enjoy_garden"

const ALL_GUIDANCE_IDS: Array[String] = [
	GUIDANCE_PLANT_FIRST,
	GUIDANCE_OBSERVE_VISITOR,
	GUIDANCE_PLACE_DECORATION,
	GUIDANCE_CREATE_WATER_HABITAT,
	GUIDANCE_DISCOVER_MORE,
	GUIDANCE_ENJOY_GARDEN,
]


## Returns true if [param stage_id] is one of the five canonical garden progression stages.
static func is_valid_stage(stage_id: String) -> bool:
	return ALL_STAGES.has(stage_id)


## Returns true if [param guidance_id] is a canonical gentle guidance identifier.
static func is_valid_guidance_id(guidance_id: String) -> bool:
	return ALL_GUIDANCE_IDS.has(guidance_id)


## Returns the zero-based index (0..4) of [param stage_id], or -1 if invalid.
static func stage_index(stage_id: String) -> int:
	return ALL_STAGES.find(stage_id)


## Returns the establishment score threshold required for [param stage_id], or 0 if invalid.
static func threshold_for_stage(stage_id: String) -> int:
	match stage_id:
		STARTING_GARDEN:
			return THRESHOLD_STARTING_GARDEN
		GROWING_GARDEN:
			return THRESHOLD_GROWING_GARDEN
		SHADY_GARDEN:
			return THRESHOLD_SHADY_GARDEN
		LIVING_GARDEN:
			return THRESHOLD_LIVING_GARDEN
		HAPPY_GARDEN_HOME:
			return THRESHOLD_HAPPY_GARDEN_HOME
		_:
			return 0


## Returns the canonical stage ID following [param stage_id], or "" if already at max stage or invalid.
static func next_stage_after(stage_id: String) -> String:
	var idx: int = stage_index(stage_id)
	if idx < 0 or idx + 1 >= ALL_STAGES.size():
		return ""
	return ALL_STAGES[idx + 1]


## Purely maps an establishment [param score] (clamping negative scores to 0) to its canonical stage ID.
static func stage_for_score(score: int) -> String:
	var clamped_score: int = maxi(0, score)
	if clamped_score >= THRESHOLD_HAPPY_GARDEN_HOME:
		return HAPPY_GARDEN_HOME
	if clamped_score >= THRESHOLD_LIVING_GARDEN:
		return LIVING_GARDEN
	if clamped_score >= THRESHOLD_SHADY_GARDEN:
		return SHADY_GARDEN
	if clamped_score >= THRESHOLD_GROWING_GARDEN:
		return GROWING_GARDEN
	return STARTING_GARDEN


## Computes the non-negative establishment score from [param snapshot] and optional [param journal].
static func compute_score(snapshot: GardenSnapshot, journal: JournalState = null) -> int:
	var score: int = 0
	if snapshot != null:
		score += maxi(0, snapshot.get_total_plant_count()) * POINTS_PER_PLANT
		score += maxi(0, snapshot.get_mature_plant_count()) * POINTS_PER_MATURE_PLANT
		score += maxi(0, snapshot.get_total_decoration_count()) * POINTS_PER_DECORATION
		score += snapshot.get_active_traits().size() * POINTS_PER_ACTIVE_TRAIT

	if journal != null:
		score += maxi(0, journal.get_count()) * POINTS_PER_DISCOVERY

	return score


## Selects a low-pressure, non-punitive gentle suggestion based on current garden state.
static func select_guidance(snapshot: GardenSnapshot, journal: JournalState = null) -> String:
	if snapshot == null or snapshot.get_total_plant_count() <= 0:
		return GUIDANCE_PLANT_FIRST

	var has_visitor_discovery: bool = false
	var total_discoveries: int = 0
	if journal != null:
		var records: Array[DiscoveryRecord] = journal.get_all_records()
		total_discoveries = records.size()
		for rec: DiscoveryRecord in records:
			if rec != null and rec.is_visitor_discovery():
				has_visitor_discovery = true
				break

	if not has_visitor_discovery:
		return GUIDANCE_OBSERVE_VISITOR

	if snapshot.get_total_decoration_count() <= 0:
		return GUIDANCE_PLACE_DECORATION

	if not snapshot.has_trait("water"):
		return GUIDANCE_CREATE_WATER_HABITAT

	if total_discoveries < MVP_TARGET_DISCOVERY_COUNT:
		return GUIDANCE_DISCOVER_MORE

	return GUIDANCE_ENJOY_GARDEN


## Evaluates [param snapshot], [param journal], and optional [param day_number] into an immutable GardenProgressionSummary.
static func evaluate(
	snapshot: GardenSnapshot,
	journal: JournalState = null,
	day_number: int = 0
) -> GardenProgressionSummary:
	var score: int = compute_score(snapshot, journal)
	var current_stage: String = stage_for_score(score)
	var current_index: int = stage_index(current_stage)
	var next_stage: String = next_stage_after(current_stage)
	var next_threshold: int = threshold_for_stage(next_stage) if not next_stage.is_empty() else 0
	var remaining: int = maxi(0, next_threshold - score) if not next_stage.is_empty() else 0
	var guidance: String = select_guidance(snapshot, journal)
	var daily_items: Array[DailyGuidanceItem] = DailyGuidanceEvaluator.evaluate_daily_guidance(
		day_number,
		snapshot,
		journal
	)

	return GardenProgressionSummary.new(
		current_stage,
		current_index,
		score,
		next_stage,
		next_threshold,
		remaining,
		guidance,
		daily_items
	)
