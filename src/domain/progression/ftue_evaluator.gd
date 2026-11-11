## ftue_evaluator.gd
## Pure domain rule evaluator for First-Time User Experience (FTUE) sequence per GAME_DESIGN.md Section 21.
##
## Establishes a gentle, non-intrusive 8-stage introductory sequence:
## 1. See garden (no plants yet) -> prompt to plant first plant
## 2. Watch growth (plant growing, not mature) -> prompt to observe natural growth
## 3. Harvest (plant mature, 0 coins) -> prompt to harvest and earn coins
## 4. Decorate (coins earned >= 10, no decorations) -> prompt to place decoration
## 5. Observe visitor (decoration placed, no visitor in journal) -> prompt to observe visitor
## 6. Check journal (visitor discovered in journal) -> prompt to inspect journal
## 7. Completed (first session goals met) -> transition seamlessly to open garden play
##
## Architectural rules:
## - Belongs to the domain progression layer (src/domain/progression/).
## - Pure domain class: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Deterministic, stateless, and side-effect free.
## - Does not mutate GameState, JournalState, or EconomyState.
## - Does not access GameClock, RandomSource, or filesystem.
class_name FtueEvaluator
extends RefCounted

const MIN_DECORATION_PRICE: int = 10


## Constructs a typed FtueStep for [param step_id].
static func create_step(
	step_id: String,
	locale: String = GardenLocalization.DEFAULT_LOCALE
) -> FtueStep:
	var idx: int = FtueStep.step_index_for_id(step_id)
	if idx < 0:
		return null
	var title: String = GardenLocalization.get_ftue_title(step_id, locale)
	var instruction: String = GardenLocalization.get_ftue_instruction(step_id, locale)
	return FtueStep.new(step_id, idx, title, instruction)


## Purely evaluates current FTUE step from [param snapshot], [param journal], and [param currency].
static func evaluate(
	snapshot: GardenSnapshot,
	journal: JournalState = null,
	currency: int = 0,
	locale: String = GardenLocalization.DEFAULT_LOCALE
) -> FtueStep:
	var total_discoveries: int = journal.get_count() if journal != null else 0
	var has_visitor_discovery: bool = _has_visitor_discovery(journal)
	var plant_count: int = snapshot.get_total_plant_count() if snapshot != null else 0
	var mature_count: int = snapshot.get_mature_plant_count() if snapshot != null else 0
	var decoration_count: int = snapshot.get_total_decoration_count() if snapshot != null else 0

	# 1. Established garden checks (completed FTUE)
	if total_discoveries >= 3:
		return create_step(FtueStep.STEP_COMPLETED, locale)

	if has_visitor_discovery and (decoration_count >= 2 or plant_count >= 2 or currency > 50):
		return create_step(FtueStep.STEP_COMPLETED, locale)

	# 2. Step 6: Check journal after first visitor discovery
	if has_visitor_discovery:
		return create_step(FtueStep.STEP_CHECK_JOURNAL, locale)

	# 3. Step 5: Observe visitor after placing decoration
	if decoration_count > 0:
		return create_step(FtueStep.STEP_OBSERVE_VISITOR, locale)

	# 4. Step 4: Buy and place decoration if player has earned sufficient coins
	if currency >= MIN_DECORATION_PRICE:
		return create_step(FtueStep.STEP_PLACE_DECORATION, locale)

	# 5. Step 3: Harvest plant if at least one plant is mature
	if mature_count > 0:
		return create_step(FtueStep.STEP_HARVEST_PLANT, locale)

	# 6. Step 2: Watch plant grow if plants exist but none are mature yet
	if plant_count > 0:
		return create_step(FtueStep.STEP_WATCH_GROWTH, locale)

	# 7. Step 1: See garden / plant first plant for an empty garden
	return create_step(FtueStep.STEP_SEE_GARDEN, locale)


static func _has_visitor_discovery(journal: JournalState) -> bool:
	if journal == null:
		return false
	for rec: DiscoveryRecord in journal.get_all_records():
		if rec != null and rec.is_visitor_discovery():
			return true
	return false
