## garden_zone.gd
## Pure domain definition and rules for Garden's Coarse Logical Grid + Zones
## placement model per ARCHITECTURE.md §19 and GAME_DESIGN.md §15 & §22.
##
## Zones:
## - "zone.main"       (Main Garden / สวนหน้าบ้าน): 4x4 coarse logical grid (16 cells), always unlocked.
## - "zone.adjacent_1" (Adjacent Zone 2 / มุมสวนข้างบ้าน): 4x3 coarse logical grid (12 cells),
##   unlocked automatically without coin grinding upon reaching Living Garden (45+ pts)
##   or achieving the Day 7 First Expansion discovery pacing milestone.
##
## Architectural rules:
## - Belongs to the domain placement layer (src/domain/placement/).
## - Pure domain class: extends RefCounted (not Node, Resource, Autoload, singleton, or manager).
## - Deterministic, stateless, side-effect free, and resolution-independent.
class_name GardenZone
extends RefCounted

const ZONE_MAIN: String = "zone.main"
const ZONE_ADJACENT_1: String = "zone.adjacent_1"

const ALL_ZONE_IDS: Array[String] = [
	ZONE_MAIN,
	ZONE_ADJACENT_1,
]

const MAIN_GRID_WIDTH: int = 4
const MAIN_GRID_HEIGHT: int = 4

const ADJACENT_1_GRID_WIDTH: int = 4
const ADJACENT_1_GRID_HEIGHT: int = 3


## Returns true if [param zone_id] is a canonical Garden zone identifier.
static func is_valid_zone_id(zone_id: String) -> bool:
	return ALL_ZONE_IDS.has(zone_id)


## Returns the grid column count for [param zone_id], or 0 if invalid.
static func get_grid_width(zone_id: String) -> int:
	match zone_id:
		ZONE_MAIN:
			return MAIN_GRID_WIDTH
		ZONE_ADJACENT_1:
			return ADJACENT_1_GRID_WIDTH
		_:
			return 0


## Returns the grid row count for [param zone_id], or 0 if invalid.
static func get_grid_height(zone_id: String) -> int:
	match zone_id:
		ZONE_MAIN:
			return MAIN_GRID_HEIGHT
		ZONE_ADJACENT_1:
			return ADJACENT_1_GRID_HEIGHT
		_:
			return 0


## Returns the total logical grid cell count for [param zone_id], or 0 if invalid.
static func get_cell_count(zone_id: String) -> int:
	return get_grid_width(zone_id) * get_grid_height(zone_id)


## Returns true if ([param grid_x], [param grid_y]) lies within [param zone_id]'s grid bounds.
static func is_within_bounds(zone_id: String, grid_x: int, grid_y: int) -> bool:
	var width: int = get_grid_width(zone_id)
	var height: int = get_grid_height(zone_id)
	if width <= 0 or height <= 0:
		return false
	return grid_x >= 0 and grid_x < width and grid_y >= 0 and grid_y < height


## Returns true if [param zone_id] is unlocked for the given [param snapshot] and [param journal].
##
## Rules (ARCHITECTURE.md §19 / GAME_DESIGN.md §22):
## - "zone.main" is always unlocked.
## - "zone.adjacent_1" (First Expansion) unlocks automatically at Living Garden (45+ pts)
##   or upon achieving the Day 7 First Expansion milestone (8+ journal discoveries), without coin grinding.
static func is_zone_unlocked(
	zone_id: String,
	snapshot: GardenSnapshot,
	journal: JournalState = null
) -> bool:
	if zone_id == ZONE_MAIN:
		return true

	if zone_id == ZONE_ADJACENT_1:
		if snapshot != null:
			var score: int = GardenProgressionStage.compute_score(snapshot, journal)
			if score >= GardenProgressionStage.THRESHOLD_LIVING_GARDEN:
				return true
		if DiscoveryPacingEvaluator.is_milestone_achieved(
			DiscoveryPacingMilestone.MILESTONE_DAY_7_FIRST_EXPANSION,
			snapshot,
			journal
		):
			return true
		return false

	return false


## Returns a deterministic ordered Array[String] of all unlocked zone IDs.
static func get_unlocked_zone_ids(
	snapshot: GardenSnapshot,
	journal: JournalState = null
) -> Array[String]:
	var result: Array[String] = []
	for zone_id: String in ALL_ZONE_IDS:
		if is_zone_unlocked(zone_id, snapshot, journal):
			result.append(zone_id)
	return result


## Returns a canonical deterministic cell key for occupancy maps ("<zone_id>:<x>,<y>").
static func cell_key(zone_id: String, grid_x: int, grid_y: int) -> String:
	return "%s:%d,%d" % [zone_id, grid_x, grid_y]


## Returns all grid coordinates in [param zone_id] in deterministic row-major order (y ascending, then x ascending).
static func get_all_cells_for_zone(zone_id: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var width: int = get_grid_width(zone_id)
	var height: int = get_grid_height(zone_id)
	if width <= 0 or height <= 0:
		return cells
	for y: int in range(height):
		for x: int in range(width):
			cells.append(Vector2i(x, y))
	return cells


## Returns the localized display name for [param zone_id] in [param locale].
static func get_display_name(
	zone_id: String,
	locale: String = GardenLocalization.DEFAULT_LOCALE
) -> String:
	if not is_valid_zone_id(zone_id):
		return ""
	return GardenLocalization.translate("%s.name" % zone_id, locale, zone_id)
