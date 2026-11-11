## test_garden_localization.gd
## Comprehensive unit and contract tests for Garden's centralized Thai/English localization system
## per GAME_DESIGN.md §32 and ARCHITECTURE.md §32.
class_name TestGardenLocalization
extends TestSuiteBase


func _init() -> void:
	suite_name = "TestGardenLocalization"


func run_tests() -> void:
	_test_pure_refcounted_contract()
	_test_locale_normalization_and_toggling()
	_test_th_en_key_parity_validity_and_placeholders()
	_test_content_definitions_and_tres_localization_keys()
	_test_invalid_definition_localization_keys_rejected()
	_test_domain_vocabularies_localized_in_th_and_en()
	_test_progression_evaluators_support_th_and_en_with_stable_keys()
	_test_fallback_and_formatting_safety()


func _test_pure_refcounted_contract() -> void:
	describe("GardenLocalization, GardenLocalizationTh, and GardenLocalizationEn satisfy pure RefCounted contracts")
	var loc: Variant = GardenLocalization.new()
	var th: Variant = GardenLocalizationTh.new()
	var en: Variant = GardenLocalizationEn.new()
	assert_true(loc is RefCounted and not (loc is Node) and not (loc is Resource), "GardenLocalization is pure RefCounted")
	assert_true(th is RefCounted and not (th is Node) and not (th is Resource), "GardenLocalizationTh is pure RefCounted")
	assert_true(en is RefCounted and not (en is Node) and not (en is Resource), "GardenLocalizationEn is pure RefCounted")
	assert_eq(GardenLocalization.DEFAULT_LOCALE, "th", "Default locale is Thai ('th')")
	assert_eq(GardenLocalization.SUPPORTED_LOCALES, ["th", "en"], "Supported locales are ['th', 'en']")


func _test_locale_normalization_and_toggling() -> void:
	describe("Locale normalization handles regional tags and unknown fallbacks cleanly")
	assert_true(GardenLocalization.is_supported_locale("th"), "'th' supported")
	assert_true(GardenLocalization.is_supported_locale("en"), "'en' supported")
	assert_false(GardenLocalization.is_supported_locale("fr"), "'fr' unsupported")
	assert_false(GardenLocalization.is_supported_locale(""), "'' unsupported")

	assert_eq(GardenLocalization.normalize_locale("th"), "th", "th -> th")
	assert_eq(GardenLocalization.normalize_locale("th_TH"), "th", "th_TH -> th")
	assert_eq(GardenLocalization.normalize_locale("TH-th"), "th", "TH-th -> th")
	assert_eq(GardenLocalization.normalize_locale("en"), "en", "en -> en")
	assert_eq(GardenLocalization.normalize_locale("en_US"), "en", "en_US -> en")
	assert_eq(GardenLocalization.normalize_locale(" en-GB "), "en", "en-GB -> en")
	assert_eq(GardenLocalization.normalize_locale("ja"), "th", "Unsupported locale falls back to default 'th'")
	assert_eq(GardenLocalization.normalize_locale(""), "th", "Empty locale falls back to default 'th'")

	assert_eq(GardenLocalization.other_locale("th"), "en", "other_locale('th') == 'en'")
	assert_eq(GardenLocalization.other_locale("en"), "th", "other_locale('en') == 'th'")


func _extract_format_placeholders(template: String) -> Array[String]:
	var placeholders: Array[String] = []
	var i: int = 0
	var length: int = template.length()
	while i < length - 1:
		if template[i] == "%":
			var next_ch: String = template[i + 1]
			if next_ch == "%":
				i += 2
				continue
			if next_ch == "s" or next_ch == "d" or next_ch == "f":
				placeholders.append(next_ch)
				i += 2
				continue
		i += 1
	return placeholders


func _test_th_en_key_parity_validity_and_placeholders() -> void:
	describe("Thai and English localization tables have exact 1:1 key parity, non-empty strings, valid keys, and matching placeholders")
	var th_keys: Array[String] = GardenLocalization.get_all_keys("th")
	var en_keys: Array[String] = GardenLocalization.get_all_keys("en")
	assert_true(th_keys.size() > 100, "Localization catalog holds comprehensive key set")
	assert_eq(th_keys, en_keys, "Thai and English key sets must match 1:1")

	for key: String in th_keys:
		assert_true(GardenLocalization.is_valid_key(key), "Key '%s' must follow canonical dot-separated format" % key)
		var th_val: String = GardenLocalization.translate(key, "th")
		var en_val: String = GardenLocalization.translate(key, "en")
		assert_false(th_val.is_empty(), "Thai string for '%s' must not be empty" % key)
		assert_false(en_val.is_empty(), "English string for '%s' must not be empty" % key)
		assert_eq(
			_extract_format_placeholders(th_val),
			_extract_format_placeholders(en_val),
			"Format placeholders must match 1:1 for key '%s'" % key
		)


func _test_content_definitions_and_tres_localization_keys() -> void:
	describe("All 24 production .tres definitions carry valid name_key & description_key with TH and EN translations")
	var plants: Array[PlantDefinition] = PlantContentLoader.new().load_production_definitions().get_definitions()
	var visitors: Array[VisitorDefinition] = VisitorContentLoader.new().load_production_definitions().get_definitions()
	var decorations: Array[DecorationDefinition] = DecorationContentLoader.new().load_production_definitions().get_definitions()
	var events: Array[EventDefinition] = EventContentLoader.new().load_production_definitions().get_definitions()

	assert_eq(plants.size(), 5, "5 plants loaded")
	assert_eq(visitors.size(), 5, "5 visitors loaded")
	assert_eq(decorations.size(), 8, "8 decorations loaded")
	assert_eq(events.size(), 6, "6 events loaded")

	for p: PlantDefinition in plants:
		assert_true(p.is_valid(), "Plant '%s' valid" % p.id)
		assert_eq(p.name_key, "%s.name" % p.id, "Plant '%s' has explicit name_key" % p.id)
		assert_eq(p.description_key, "%s.description" % p.id, "Plant '%s' has explicit description_key" % p.id)
		assert_true(GardenLocalization.has_key(p.get_effective_name_key(), "th"), "TH plant name key exists for %s" % p.id)
		assert_true(GardenLocalization.has_key(p.get_effective_name_key(), "en"), "EN plant name key exists for %s" % p.id)
		assert_ne(
			GardenLocalization.get_plant_name(p.id, "th", p),
			GardenLocalization.get_plant_name(p.id, "en", p),
			"Plant '%s' has distinct TH/EN names" % p.id
		)
		assert_false(GardenLocalization.get_plant_description(p.id, "en", p).is_empty(), "EN plant description exists for %s" % p.id)

	for d: DecorationDefinition in decorations:
		assert_true(d.is_valid(), "Decoration '%s' valid" % d.id)
		assert_eq(d.name_key, "%s.name" % d.id, "Decoration '%s' has explicit name_key" % d.id)
		assert_eq(d.description_key, "%s.description" % d.id, "Decoration '%s' has explicit description_key" % d.id)
		assert_ne(
			GardenLocalization.get_decoration_name(d.id, "th", d),
			GardenLocalization.get_decoration_name(d.id, "en", d),
			"Decoration '%s' has distinct TH/EN names" % d.id
		)
		assert_false(GardenLocalization.get_decoration_description(d.id, "en", d).is_empty(), "EN decoration description exists for %s" % d.id)

	for v: VisitorDefinition in visitors:
		assert_true(v.is_valid(), "Visitor '%s' valid" % v.id)
		assert_eq(v.name_key, "%s.name" % v.id, "Visitor '%s' has explicit name_key" % v.id)
		assert_eq(v.description_key, "%s.description" % v.id, "Visitor '%s' has explicit description_key" % v.id)
		assert_ne(
			GardenLocalization.get_visitor_name(v.id, "th", v),
			GardenLocalization.get_visitor_name(v.id, "en", v),
			"Visitor '%s' has distinct TH/EN names" % v.id
		)

	for e: EventDefinition in events:
		assert_true(e.is_valid(), "Event '%s' valid" % e.id)
		assert_eq(e.name_key, "%s.name" % e.id, "Event '%s' has explicit name_key" % e.id)
		assert_eq(e.description_key, "%s.description" % e.id, "Event '%s' has explicit description_key" % e.id)
		assert_ne(
			GardenLocalization.get_event_name(e.id, "th", e),
			GardenLocalization.get_event_name(e.id, "en", e),
			"Event '%s' has distinct TH/EN names" % e.id
		)
		assert_ne(
			GardenLocalization.get_event_description(e.id, "th", e),
			GardenLocalization.get_event_description(e.id, "en", e),
			"Event '%s' has distinct TH/EN descriptions" % e.id
		)


func _test_invalid_definition_localization_keys_rejected() -> void:
	describe("Invalid explicit name_key or description_key fails Definition.is_valid()")
	var bad_plant: PlantDefinition = PlantDefinition.new()
	bad_plant.id = "plant.holy_basil"
	bad_plant.sprout_after_seconds = 10
	bad_plant.growing_after_seconds = 20
	bad_plant.mature_after_seconds = 30
	assert_true(bad_plant.is_valid(), "Empty optional keys remain valid for programmatic fixtures")
	assert_eq(bad_plant.get_effective_name_key(), "plant.holy_basil.name", "Derives fallback name_key")
	bad_plant.name_key = "Invalid Key With Spaces"
	assert_false(bad_plant.is_valid(), "Invalid plant name_key rejected")
	bad_plant.name_key = "plant.holy_basil.name"
	bad_plant.description_key = "plant..bad"
	assert_false(bad_plant.is_valid(), "Invalid plant description_key rejected")

	var bad_decor: DecorationDefinition = DecorationDefinition.new()
	bad_decor.id = "decoration.bench"
	bad_decor.price = 10
	bad_decor.name_key = "Bad.Key"
	assert_false(bad_decor.is_valid(), "Invalid decoration name_key rejected")

	var bad_visitor: VisitorDefinition = VisitorDefinition.new()
	bad_visitor.id = "visitor.cat"
	bad_visitor.weight = 1.0
	bad_visitor.description_key = "visitor.cat."
	assert_false(bad_visitor.is_valid(), "Invalid visitor description_key rejected")

	var bad_event: EventDefinition = EventDefinition.new()
	bad_event.id = "event.test_event"
	bad_event.weight = 1.0
	bad_event.name_key = "event_no_dot"
	assert_false(bad_event.is_valid(), "Invalid event name_key rejected")


func _test_domain_vocabularies_localized_in_th_and_en() -> void:
	describe("All environmental traits, time periods, weather states, stages, and plant growth stages localize cleanly in TH and EN")
	for trait_id: String in EnvironmentalTrait.ALL_TRAITS:
		assert_true(GardenLocalization.is_known_trait_id(trait_id), "Trait %s known" % trait_id)
		assert_ne(
			GardenLocalization.get_trait_name(trait_id, "th"),
			GardenLocalization.get_trait_name(trait_id, "en"),
			"Trait %s differs between TH and EN" % trait_id
		)

	for tp: String in GardenTimePeriod.ALL_PERIODS:
		assert_true(GardenLocalization.is_known_time_period_id(tp), "Time period %s known" % tp)
		assert_ne(
			GardenLocalization.get_time_period_name(tp, "th"),
			GardenLocalization.get_time_period_name(tp, "en"),
			"Time period %s differs between TH and EN" % tp
		)

	for ws: String in GardenWeather.ALL_WEATHER_STATES:
		assert_true(GardenLocalization.is_known_weather_state_id(ws), "Weather %s known" % ws)
		assert_ne(
			GardenLocalization.get_weather_name(ws, "th"),
			GardenLocalization.get_weather_name(ws, "en"),
			"Weather %s differs between TH and EN" % ws
		)

	for st_id: String in GardenProgressionStage.ALL_STAGES:
		assert_true(GardenLocalization.is_known_progression_stage_id(st_id), "Stage %s known" % st_id)
		assert_ne(
			GardenLocalization.get_progression_stage_name(st_id, "th"),
			GardenLocalization.get_progression_stage_name(st_id, "en"),
			"Progression stage %s differs between TH and EN" % st_id
		)

	for gid: String in GardenProgressionStage.ALL_GUIDANCE_IDS:
		assert_true(GardenLocalization.is_known_guidance_id(gid), "Guidance %s known" % gid)
		assert_ne(
			GardenLocalization.get_guidance_text(gid, "th"),
			GardenLocalization.get_guidance_text(gid, "en"),
			"Guidance %s differs between TH and EN" % gid
		)

	for stage: PlantGrowth.Stage in [
		PlantGrowth.Stage.PLANTED,
		PlantGrowth.Stage.SPROUT,
		PlantGrowth.Stage.GROWING,
		PlantGrowth.Stage.MATURE,
		PlantGrowth.Stage.INVALID,
	]:
		assert_ne(
			GardenLocalization.get_plant_stage_name(stage, "th"),
			GardenLocalization.get_plant_stage_name(stage, "en"),
			"PlantGrowth stage %d differs between TH and EN" % int(stage)
		)


func _test_progression_evaluators_support_th_and_en_with_stable_keys() -> void:
	describe("DailyGuidanceEvaluator, FtueEvaluator, DiscoveryPacingEvaluator, and GardenProgressionStage localize TH & EN with stable keys")
	var empty_snapshot: GardenSnapshot = GardenSnapshot.new()
	var journal: JournalState = JournalState.new()

	var summary_th: GardenProgressionSummary = GardenProgressionStage.evaluate(empty_snapshot, journal, 0, 0, "th")
	var summary_en: GardenProgressionSummary = GardenProgressionStage.evaluate(empty_snapshot, journal, 0, 0, "en")

	assert_eq(summary_th.get_ftue_step_id(), summary_en.get_ftue_step_id(), "FTUE ID independent of locale")
	assert_eq(summary_th.get_ftue_step().get_title_key(), "ftue.see_garden.title", "FTUE exposes stable title key")
	assert_eq(summary_th.get_ftue_step().get_instruction_key(), "ftue.see_garden.instruction", "FTUE exposes stable instruction key")
	assert_ne(summary_th.get_ftue_title(), summary_en.get_ftue_title(), "FTUE title differs TH vs EN")
	assert_ne(summary_th.get_ftue_instruction(), summary_en.get_ftue_instruction(), "FTUE instruction differs TH vs EN")

	assert_eq(summary_th.get_daily_guidance_ids(), summary_en.get_daily_guidance_ids(), "Daily guidance IDs independent of locale")
	for i: int in range(3):
		var item_th: DailyGuidanceItem = summary_th.get_daily_guidance_items()[i]
		var item_en: DailyGuidanceItem = summary_en.get_daily_guidance_items()[i]
		assert_eq(item_th.get_display_text_key(), item_en.get_display_text_key(), "Daily guidance stable key matches")
		assert_ne(item_th.get_display_text(), item_en.get_display_text(), "Daily guidance text localized TH vs EN")

	assert_eq(summary_th.get_discovery_pacing_milestone_id(), summary_en.get_discovery_pacing_milestone_id(), "Pacing milestone ID independent of locale")
	var pm_th: DiscoveryPacingMilestone = summary_th.get_discovery_pacing_milestone()
	var pm_en: DiscoveryPacingMilestone = summary_en.get_discovery_pacing_milestone()
	assert_eq(pm_th.get_title_key(), "pacing.day_1_early_phase.title", "Pacing stable title key")
	assert_eq(pm_th.get_description_key(), "pacing.day_1_early_phase.description", "Pacing stable description key")
	assert_eq(pm_th.get_recommended_focus_key(), "pacing.day_1_early_phase.focus", "Pacing stable focus key")
	assert_ne(pm_th.get_title(), pm_en.get_title(), "Pacing title localized TH vs EN")
	assert_ne(pm_th.get_description(), pm_en.get_description(), "Pacing description localized TH vs EN")
	assert_ne(pm_th.get_recommended_focus(), pm_en.get_recommended_focus(), "Pacing focus localized TH vs EN")


func _test_fallback_and_formatting_safety() -> void:
	describe("Missing localization keys and unknown content IDs fall back gracefully without crashing")
	assert_eq(GardenLocalization.translate("nonexistent.key", "en"), "nonexistent.key", "Missing key returns key")
	assert_eq(GardenLocalization.translate("nonexistent.key", "en", "Safe Fallback"), "Safe Fallback", "Missing key honors explicit fallback")
	assert_eq(GardenLocalization.translate("", "en", "Empty"), "Empty", "Empty key returns fallback")
	assert_eq(GardenLocalization.get_plant_name("plant.custom_unknown", "en"), "plant.custom_unknown", "Unknown plant falls back to ID")
	assert_eq(GardenLocalization.get_event_description("event.custom_unknown", "en"), "", "Unknown event description returns empty string")
