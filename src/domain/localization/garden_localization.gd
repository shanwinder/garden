## garden_localization.gd
## Centralized Thai/English localization service and key registry per GAME_DESIGN.md §32
## and ARCHITECTURE.md §32.
##
## Centralizes all player-facing copy previously scattered in PROVISIONAL_* dictionaries
## across UI components and progression evaluators.
##
## Architectural rules:
## - Belongs to the domain localization layer (src/domain/localization/).
## - Pure stateless lookup class: extends RefCounted (not Node, Autoload, singleton, or manager).
## - Does not store mutable global state, read files, touch SceneTree, clock, or RNG.
## - Save data never depends on translated text; keys remain stable ASCII identifiers.
class_name GardenLocalization
extends RefCounted

const LOCALE_TH: String = "th"
const LOCALE_EN: String = "en"
const DEFAULT_LOCALE: String = LOCALE_TH

const SUPPORTED_LOCALES: Array[String] = [
	LOCALE_TH,
	LOCALE_EN,
]

const KNOWN_PLANT_IDS: Array[String] = [
	"plant.banana",
	"plant.chili",
	"plant.holy_basil",
	"plant.jasmine",
	"plant.marigold",
]

const KNOWN_DECORATION_IDS: Array[String] = [
	"decoration.bench",
	"decoration.clay_jar",
	"decoration.garden_lamp",
	"decoration.plant_pot",
	"decoration.small_pond",
	"decoration.small_table",
	"decoration.watering_can",
	"decoration.wooden_fence",
]

const KNOWN_VISITOR_IDS: Array[String] = [
	"visitor.bird",
	"visitor.butterfly",
	"visitor.cat",
	"visitor.firefly",
	"visitor.frog",
]

const KNOWN_EVENT_IDS: Array[String] = [
	"event.bird_shade_song",
	"event.cat_jasmine_night_rest",
	"event.cat_sleeping_bench",
	"event.firefly_night_glow",
	"event.frog_rain_chorus",
	"event.morning_butterflies",
]


## Returns true if [param locale] is a supported canonical locale code ("th" or "en").
static func is_supported_locale(locale: String) -> bool:
	return SUPPORTED_LOCALES.has(locale)


## Normalizes raw locale tags such as "th_TH", "en-US", or "" into a supported canonical locale.
static func normalize_locale(locale: String) -> String:
	var cleaned: String = locale.strip_edges().to_lower().replace("-", "_")
	if cleaned == LOCALE_TH or cleaned.begins_with("th_"):
		return LOCALE_TH
	if cleaned == LOCALE_EN or cleaned.begins_with("en_"):
		return LOCALE_EN
	return DEFAULT_LOCALE


## Returns the alternate supported locale ("th" <-> "en") for toggle controls.
static func other_locale(locale: String) -> String:
	return LOCALE_EN if normalize_locale(locale) == LOCALE_TH else LOCALE_TH


## Returns true if [param key] conforms to canonical dot-separated localization key syntax.
static func is_valid_key(key: String) -> bool:
	return StableContentId.is_valid(key)


## Returns the translation dictionary for normalized [param locale].
static func get_strings_for_locale(locale: String = DEFAULT_LOCALE) -> Dictionary:
	match normalize_locale(locale):
		LOCALE_EN:
			return GardenLocalizationEn.STRINGS
		_:
			return GardenLocalizationTh.STRINGS


## Returns true if [param key] exists in [param locale]'s translation table.
static func has_key(key: String, locale: String = DEFAULT_LOCALE) -> bool:
	if key.is_empty():
		return false
	return get_strings_for_locale(locale).has(key)


## Returns all sorted keys defined in [param locale]'s translation table.
static func get_all_keys(locale: String = DEFAULT_LOCALE) -> Array[String]:
	var result: Array[String] = []
	for k: Variant in get_strings_for_locale(locale).keys():
		result.append(String(k))
	result.sort()
	return result


## Translates [param key] in [param locale], falling back to DEFAULT_LOCALE, then [param fallback] or [param key].
static func translate(
	key: String,
	locale: String = DEFAULT_LOCALE,
	fallback: String = ""
) -> String:
	if key.is_empty():
		return fallback
	var table: Dictionary = get_strings_for_locale(locale)
	if table.has(key):
		return String(table[key])
	if normalize_locale(locale) != DEFAULT_LOCALE:
		var default_table: Dictionary = get_strings_for_locale(DEFAULT_LOCALE)
		if default_table.has(key):
			return String(default_table[key])
	return fallback if not fallback.is_empty() else key


## Translates [param key] in [param locale] and applies Godot `%` format arguments safely.
static func format_key(
	key: String,
	args: Array = [],
	locale: String = DEFAULT_LOCALE,
	fallback: String = ""
) -> String:
	var template: String = translate(key, locale, fallback)
	if args.is_empty():
		return template
	return template % args


# ── Canonical Key Builders ────────────────────────────────────────────────────

static func plant_name_key(definition_id: String) -> String:
	return "%s.name" % definition_id if not definition_id.is_empty() else ""


static func plant_description_key(definition_id: String) -> String:
	return "%s.description" % definition_id if not definition_id.is_empty() else ""


static func decoration_name_key(definition_id: String) -> String:
	return "%s.name" % definition_id if not definition_id.is_empty() else ""


static func decoration_description_key(definition_id: String) -> String:
	return "%s.description" % definition_id if not definition_id.is_empty() else ""


static func visitor_name_key(definition_id: String) -> String:
	return "%s.name" % definition_id if not definition_id.is_empty() else ""


static func visitor_description_key(definition_id: String) -> String:
	return "%s.description" % definition_id if not definition_id.is_empty() else ""


static func event_name_key(definition_id: String) -> String:
	return "%s.name" % definition_id if not definition_id.is_empty() else ""


static func event_description_key(definition_id: String) -> String:
	return "%s.description" % definition_id if not definition_id.is_empty() else ""


static func trait_name_key(trait_id: String) -> String:
	return "trait.%s.name" % trait_id if not trait_id.is_empty() else ""


static func time_period_name_key(time_period: String) -> String:
	return "time_period.%s.name" % time_period if not time_period.is_empty() else ""


static func weather_name_key(weather_state: String) -> String:
	return "weather.%s.name" % weather_state if not weather_state.is_empty() else ""


static func progression_stage_name_key(stage_id: String) -> String:
	return "progression_stage.%s.name" % stage_id if not stage_id.is_empty() else ""


static func guidance_text_key(guidance_id: String) -> String:
	return "%s.text" % guidance_id if not guidance_id.is_empty() else ""


static func daily_guidance_text_key(guidance_id: String) -> String:
	return "%s.text" % guidance_id if not guidance_id.is_empty() else ""


static func ftue_title_key(step_id: String) -> String:
	return "%s.title" % step_id if not step_id.is_empty() else ""


static func ftue_instruction_key(step_id: String) -> String:
	return "%s.instruction" % step_id if not step_id.is_empty() else ""


static func pacing_title_key(milestone_id: String) -> String:
	return "%s.title" % milestone_id if not milestone_id.is_empty() else ""


static func pacing_description_key(milestone_id: String) -> String:
	return "%s.description" % milestone_id if not milestone_id.is_empty() else ""


static func pacing_focus_key(milestone_id: String) -> String:
	return "%s.focus" % milestone_id if not milestone_id.is_empty() else ""


static func plant_stage_prefix(stage: PlantGrowth.Stage) -> String:
	match stage:
		PlantGrowth.Stage.PLANTED:
			return "plant_stage.planted"
		PlantGrowth.Stage.SPROUT:
			return "plant_stage.sprout"
		PlantGrowth.Stage.GROWING:
			return "plant_stage.growing"
		PlantGrowth.Stage.MATURE:
			return "plant_stage.mature"
		_:
			return "plant_stage.invalid"


# ── Domain Display Helpers ────────────────────────────────────────────────────

static func get_plant_name(
	definition_id: String,
	locale: String = DEFAULT_LOCALE,
	definition: PlantDefinition = null
) -> String:
	if definition_id.is_empty():
		return ""
	var key: String = (
		definition.get_effective_name_key()
		if definition != null
		else plant_name_key(definition_id)
	)
	return translate(key, locale, definition_id)


static func get_plant_description(
	definition_id: String,
	locale: String = DEFAULT_LOCALE,
	definition: PlantDefinition = null
) -> String:
	if definition_id.is_empty():
		return ""
	var key: String = (
		definition.get_effective_description_key()
		if definition != null
		else plant_description_key(definition_id)
	)
	return translate(key, locale, "") if has_key(key, DEFAULT_LOCALE) else ""


static func get_decoration_name(
	definition_id: String,
	locale: String = DEFAULT_LOCALE,
	definition: DecorationDefinition = null
) -> String:
	if definition_id.is_empty():
		return ""
	var key: String = (
		definition.get_effective_name_key()
		if definition != null
		else decoration_name_key(definition_id)
	)
	return translate(key, locale, definition_id)


static func get_decoration_description(
	definition_id: String,
	locale: String = DEFAULT_LOCALE,
	definition: DecorationDefinition = null
) -> String:
	if definition_id.is_empty():
		return ""
	var key: String = (
		definition.get_effective_description_key()
		if definition != null
		else decoration_description_key(definition_id)
	)
	return translate(key, locale, "") if has_key(key, DEFAULT_LOCALE) else ""


static func get_visitor_name(
	definition_id: String,
	locale: String = DEFAULT_LOCALE,
	definition: VisitorDefinition = null
) -> String:
	if definition_id.is_empty():
		return ""
	var key: String = (
		definition.get_effective_name_key()
		if definition != null
		else visitor_name_key(definition_id)
	)
	return translate(key, locale, definition_id)


static func get_visitor_description(
	definition_id: String,
	locale: String = DEFAULT_LOCALE,
	definition: VisitorDefinition = null
) -> String:
	if definition_id.is_empty():
		return ""
	var key: String = (
		definition.get_effective_description_key()
		if definition != null
		else visitor_description_key(definition_id)
	)
	return translate(key, locale, "") if has_key(key, DEFAULT_LOCALE) else ""


static func get_event_name(
	definition_id: String,
	locale: String = DEFAULT_LOCALE,
	definition: EventDefinition = null
) -> String:
	if definition_id.is_empty():
		return ""
	var key: String = (
		definition.get_effective_name_key()
		if definition != null
		else event_name_key(definition_id)
	)
	return translate(key, locale, definition_id)


static func get_event_description(
	definition_id: String,
	locale: String = DEFAULT_LOCALE,
	definition: EventDefinition = null
) -> String:
	if definition_id.is_empty():
		return ""
	var key: String = (
		definition.get_effective_description_key()
		if definition != null
		else event_description_key(definition_id)
	)
	if not has_key(key, locale) and not has_key(key, DEFAULT_LOCALE):
		return ""
	return translate(key, locale, "")


static func get_trait_name(trait_id: String, locale: String = DEFAULT_LOCALE) -> String:
	if trait_id.is_empty():
		return ""
	return translate(trait_name_key(trait_id), locale, trait_id)


static func get_time_period_name(time_period: String, locale: String = DEFAULT_LOCALE) -> String:
	if time_period.is_empty():
		return ""
	return translate(time_period_name_key(time_period), locale, time_period)


static func get_weather_name(weather_state: String, locale: String = DEFAULT_LOCALE) -> String:
	if weather_state.is_empty():
		return ""
	return translate(weather_name_key(weather_state), locale, weather_state)


static func get_progression_stage_name(stage_id: String, locale: String = DEFAULT_LOCALE) -> String:
	if stage_id.is_empty():
		return ""
	return translate(progression_stage_name_key(stage_id), locale, stage_id)


static func get_guidance_text(guidance_id: String, locale: String = DEFAULT_LOCALE) -> String:
	if guidance_id.is_empty():
		return ""
	return translate(guidance_text_key(guidance_id), locale, guidance_id)


static func get_daily_guidance_text(guidance_id: String, locale: String = DEFAULT_LOCALE) -> String:
	if guidance_id.is_empty():
		return ""
	return translate(daily_guidance_text_key(guidance_id), locale, guidance_id)


static func get_ftue_title(step_id: String, locale: String = DEFAULT_LOCALE) -> String:
	if step_id.is_empty():
		return ""
	var key: String = ftue_title_key(step_id)
	return translate(key, locale, "") if has_key(key, DEFAULT_LOCALE) else ""


static func get_ftue_instruction(step_id: String, locale: String = DEFAULT_LOCALE) -> String:
	if step_id.is_empty():
		return ""
	var key: String = ftue_instruction_key(step_id)
	return translate(key, locale, "") if has_key(key, DEFAULT_LOCALE) else ""


static func get_pacing_title(milestone_id: String, locale: String = DEFAULT_LOCALE) -> String:
	if milestone_id.is_empty():
		return ""
	var key: String = pacing_title_key(milestone_id)
	return translate(key, locale, "") if has_key(key, DEFAULT_LOCALE) else ""


static func get_pacing_description(milestone_id: String, locale: String = DEFAULT_LOCALE) -> String:
	if milestone_id.is_empty():
		return ""
	var key: String = pacing_description_key(milestone_id)
	return translate(key, locale, "") if has_key(key, DEFAULT_LOCALE) else ""


static func get_pacing_focus(milestone_id: String, locale: String = DEFAULT_LOCALE) -> String:
	if milestone_id.is_empty():
		return ""
	var key: String = pacing_focus_key(milestone_id)
	return translate(key, locale, "") if has_key(key, DEFAULT_LOCALE) else ""


static func get_plant_stage_name(stage: PlantGrowth.Stage, locale: String = DEFAULT_LOCALE) -> String:
	return translate("%s.name" % plant_stage_prefix(stage), locale)


static func get_plant_stage_detail(stage: PlantGrowth.Stage, locale: String = DEFAULT_LOCALE) -> String:
	return translate("%s.detail" % plant_stage_prefix(stage), locale)


# ── Known Definition & Vocabulary Membership Queries ──────────────────────────

static func is_known_plant_id(definition_id: String) -> bool:
	return not definition_id.is_empty() and has_key(plant_name_key(definition_id), DEFAULT_LOCALE)


static func is_known_decoration_id(definition_id: String) -> bool:
	return not definition_id.is_empty() and has_key(decoration_name_key(definition_id), DEFAULT_LOCALE)


static func is_known_visitor_id(definition_id: String) -> bool:
	return not definition_id.is_empty() and has_key(visitor_name_key(definition_id), DEFAULT_LOCALE)


static func is_known_event_id(definition_id: String) -> bool:
	return not definition_id.is_empty() and has_key(event_name_key(definition_id), DEFAULT_LOCALE)


static func is_known_trait_id(trait_id: String) -> bool:
	return not trait_id.is_empty() and has_key(trait_name_key(trait_id), DEFAULT_LOCALE)


static func is_known_time_period_id(time_period: String) -> bool:
	return not time_period.is_empty() and has_key(time_period_name_key(time_period), DEFAULT_LOCALE)


static func is_known_weather_state_id(weather_state: String) -> bool:
	return not weather_state.is_empty() and has_key(weather_name_key(weather_state), DEFAULT_LOCALE)


static func is_known_progression_stage_id(stage_id: String) -> bool:
	return not stage_id.is_empty() and has_key(progression_stage_name_key(stage_id), DEFAULT_LOCALE)


static func is_known_guidance_id(guidance_id: String) -> bool:
	return not guidance_id.is_empty() and has_key(guidance_text_key(guidance_id), DEFAULT_LOCALE)


static func get_known_plant_ids() -> Array[String]:
	var result: Array[String] = KNOWN_PLANT_IDS.duplicate()
	result.sort()
	return result


static func get_known_decoration_ids() -> Array[String]:
	var result: Array[String] = KNOWN_DECORATION_IDS.duplicate()
	result.sort()
	return result


static func get_known_trait_ids() -> Array[String]:
	return EnvironmentalTrait.ALL_TRAITS.duplicate()


static func get_zone_name(zone_id: String, locale: String = DEFAULT_LOCALE) -> String:
	if zone_id.is_empty():
		return ""
	return translate("%s.name" % zone_id, locale, zone_id)
