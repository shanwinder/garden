## test_garden_audio.gd
## Automated verification for GardenAudioController, WAV stream loading,
## separate persistent mute settings, lifecycle pause, and GardenView audio integration.
class_name TestGardenAudio
extends TestSuiteBase

const GARDEN_VIEW_SCENE_PATH: String = "res://scenes/garden/garden_view.tscn"


func _init() -> void:
	suite_name = "TestGardenAudio"


func run_tests() -> void:
	_test_ambient_cue_resolution_and_stream_loading()
	_test_audio_settings_persistence_and_malformed_fallback()
	_test_lifecycle_pause_and_mute_state()
	_test_garden_view_audio_integration()


func _create_full_catalog() -> ContentCatalog:
	return ContentCatalog.try_create(
		PlantContentLoader.new().load_production_definitions().get_definitions(),
		VisitorContentLoader.new().load_production_definitions().get_definitions(),
		DecorationContentLoader.new().load_production_definitions().get_definitions(),
		EventContentLoader.new().load_production_definitions().get_definitions()
	)


func _test_ambient_cue_resolution_and_stream_loading() -> void:
	describe("GardenAudioController maps time/weather to ambient cues and loads all WAV streams")
	assert_eq(GardenAudioController.resolve_ambient_cue(GardenTimePeriod.MORNING, GardenWeather.CLEAR), "day", "Morning clear resolves to day ambient")
	assert_eq(GardenAudioController.resolve_ambient_cue(GardenTimePeriod.DAY, GardenWeather.CLOUDY), "day", "Day cloudy resolves to day ambient")
	assert_eq(GardenAudioController.resolve_ambient_cue(GardenTimePeriod.EVENING, GardenWeather.CLEAR), "night", "Evening clear resolves to night ambient")
	assert_eq(GardenAudioController.resolve_ambient_cue(GardenTimePeriod.NIGHT, GardenWeather.CLEAR), "night", "Night clear resolves to night ambient")
	assert_eq(GardenAudioController.resolve_ambient_cue(GardenTimePeriod.DAY, GardenWeather.RAIN), "rain", "Day rain resolves to rain ambient")
	assert_eq(GardenAudioController.resolve_ambient_cue(GardenTimePeriod.NIGHT, GardenWeather.RAIN), "rain", "Night rain prioritizes rain ambient")

	var controller: GardenAudioController = GardenAudioController.new()
	controller.set_settings_path("user://test_audio_unused_%d.json" % Time.get_ticks_usec())
	controller.update_atmosphere(GardenTimePeriod.DAY, GardenWeather.CLEAR)
	assert_eq(controller.get_current_ambient_cue(), "day", "Ambient cue set to day")
	controller.update_atmosphere(GardenTimePeriod.NIGHT, GardenWeather.CLEAR)
	assert_eq(controller.get_current_ambient_cue(), "night", "Ambient cue switches to night")
	controller.update_atmosphere(GardenTimePeriod.DAY, GardenWeather.RAIN)
	assert_eq(controller.get_current_ambient_cue(), "rain", "Ambient cue switches to rain")

	for cue_var: Variant in GardenAudioController.AMBIENT_CUE_PATHS.keys():
		var path: String = str(GardenAudioController.AMBIENT_CUE_PATHS[cue_var])
		assert_true(ResourceLoader.exists(path), "Ambient audio asset exists: %s" % path)
		var stream: AudioStream = ResourceLoader.load(path) as AudioStream
		assert_true(stream != null, "Ambient AudioStream loads cleanly: %s" % path)

	for sfx_var: Variant in GardenAudioController.SFX_CUE_PATHS.keys():
		var sfx_id: String = str(sfx_var)
		var sfx_path: String = str(GardenAudioController.SFX_CUE_PATHS[sfx_id])
		assert_true(ResourceLoader.exists(sfx_path), "SFX audio asset exists: %s" % sfx_path)
		var sfx_stream: AudioStream = ResourceLoader.load(sfx_path) as AudioStream
		assert_true(sfx_stream != null, "SFX AudioStream loads cleanly: %s" % sfx_path)
		controller.play_sfx(sfx_id)
		assert_eq(controller.get_last_sfx_cue(), sfx_id, "Controller records SFX cue: %s" % sfx_id)

	controller.play_sfx("unknown_cue")
	assert_eq(controller.get_last_sfx_cue(), "place_decor" if GardenAudioController.SFX_CUE_PATHS.has("place_decor") else controller.get_last_sfx_cue(), "Unknown SFX cue is safely ignored")
	controller.free()


func _test_audio_settings_persistence_and_malformed_fallback() -> void:
	describe("GardenAudioController persists mute preference separately from GameState and handles malformed JSON")
	var settings_path: String = "user://test_audio_settings_%d.json" % Time.get_ticks_usec()
	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_path)

	var c1: GardenAudioController = GardenAudioController.new()
	c1.set_settings_path(settings_path)
	c1.load_settings()
	assert_false(c1.is_muted(), "Defaults to unmuted when settings file does not exist")
	c1.set_muted(true, true)
	assert_true(c1.is_muted(), "Controller enters muted state")
	assert_true(FileAccess.file_exists(settings_path), "Audio settings file created")
	c1.free()

	var c2: GardenAudioController = GardenAudioController.new()
	c2.set_settings_path(settings_path)
	c2.load_settings()
	assert_true(c2.is_muted(), "Reloaded controller restores muted=true")
	var toggled: bool = c2.toggle_muted()
	assert_false(toggled, "toggle_muted switches back to false")
	c2.free()

	# Malformed JSON falls back safely without crashing
	var bad_file: FileAccess = FileAccess.open(settings_path, FileAccess.WRITE)
	bad_file.store_string("{not_valid_json")
	bad_file.close()
	var c3: GardenAudioController = GardenAudioController.new()
	c3.set_settings_path(settings_path)
	c3.load_settings()
	assert_false(c3.is_muted(), "Malformed settings JSON safely keeps default unmuted")
	c3.free()

	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_path)


func _test_lifecycle_pause_and_mute_state() -> void:
	describe("GardenAudioController respects lifecycle pause/resume notifications cleanly")
	var controller: GardenAudioController = GardenAudioController.new()
	controller.set_settings_path("user://test_audio_pause_%d.json" % Time.get_ticks_usec())
	controller.update_atmosphere(GardenTimePeriod.DAY, GardenWeather.CLEAR)
	assert_false(controller.is_paused(), "Initially unpaused")

	controller._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_true(controller.is_paused(), "Application pause notification pauses audio controller")
	assert_false(controller.is_ambient_playing(), "Ambient does not play while paused")

	controller._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_false(controller.is_paused(), "Application resume notification unpauses audio controller")
	controller.free()


func _test_garden_view_audio_integration() -> void:
	describe("GardenView wires AudioController, localized AudioButton, atmosphere sync, and action SFX")
	var scene: PackedScene = load(GARDEN_VIEW_SCENE_PATH) as PackedScene
	var view: GardenView = scene.instantiate() as GardenView
	var audio: GardenAudioController = view.get_audio_controller()
	var audio_btn: Button = view.get_audio_button()
	assert_true(audio != null, "GardenView includes GardenAudioController child")
	assert_true(audio_btn != null, "GardenView includes AudioButton")

	var test_settings: String = "user://test_gv_audio_%d.json" % Time.get_ticks_usec()
	audio.set_settings_path(test_settings)
	audio.set_muted(false, false)

	var catalog: ContentCatalog = _create_full_catalog()
	var state: GameState = GameState.new()
	var plant: PlantState = PlantState.new("p-audio-1", "plant.holy_basil", 1000, GardenZone.ZONE_MAIN, 0, 0)
	state.get_plants().try_add_plant(plant)
	var session: GameSession = GameSession.new(state)
	# Find a DAY/CLEAR timestamp via GardenTimePeriod/GardenWeather
	var day_clear_utc: int = 12 * 3600
	var clock: FakeGameClock = FakeGameClock.new(day_clear_utc, 0)

	view.bind_garden(session, catalog, clock)
	var expected_cue: String = GardenAudioController.resolve_ambient_cue(view.get_current_time_period(), view.get_current_weather_state())
	assert_eq(audio.get_current_ambient_cue(), expected_cue, "GardenView syncs AudioController ambient cue to current snapshot")

	assert_eq(audio_btn.text, "เสียง: เปิด", "AudioButton shows Thai unmuted label")
	audio_btn.pressed.emit()
	assert_true(audio.is_muted(), "Pressing AudioButton mutes audio")
	assert_eq(audio_btn.text, "เสียง: ปิด", "AudioButton shows Thai muted label")

	view.set_locale("en")
	assert_eq(audio_btn.text, "Sound: Off", "AudioButton localizes muted label to English")
	audio_btn.pressed.emit()
	assert_false(audio.is_muted(), "Pressing AudioButton again unmutes audio")
	assert_eq(audio_btn.text, "Sound: On", "AudioButton localizes unmuted label to English")
	assert_eq(audio.get_last_sfx_cue(), "ui_tap", "Unmuting plays ui_tap SFX")

	# Planting, harvest, decoration purchase, visitor/event SFX
	var reg_res: PlantRegistrationResult = PlantRegistrationResult.registered(plant)
	view.show_planting_result(PlantingCheckpointResult.registered_saved(reg_res))
	assert_eq(audio.get_last_sfx_cue(), "plant", "Successful planting triggers plant SFX")

	var harvest_res: PlantHarvestResult = PlantHarvestResult.harvested(plant, 15)
	view.show_harvest_result(HarvestCheckpointResult.harvested_saved(harvest_res))
	assert_eq(audio.get_last_sfx_cue(), "harvest", "Successful harvest triggers harvest SFX")

	var decor: DecorationState = DecorationState.new("d-audio-1", "decoration.bench", 1000, GardenZone.ZONE_MAIN, 1, 1)
	var buy_res: DecorationPurchaseResult = DecorationPurchaseResult.purchased(decor, 45, 70)
	view.show_decoration_purchase_result(DecorationPurchaseCheckpointResult.purchased_saved(buy_res))
	assert_eq(audio.get_last_sfx_cue(), "place_decor", "Successful decoration purchase triggers place_decor SFX")

	var cat_def: VisitorDefinition = catalog.get_visitor("visitor.cat")
	var eligible_ids: Array[String] = ["visitor.cat"]
	var vis_sel: VisitorSelectionResult = VisitorSelectionResult.selected(cat_def, eligible_ids, view.get_last_garden_snapshot())
	var disc_rec: DiscoveryRecord = DiscoveryRecord.new("visitor.cat", day_clear_utc, 1)
	var disc_res: JournalDiscoveryResult = JournalDiscoveryResult.first_discovery(disc_rec)
	var vis_obs: VisitorObservationCheckpointResult = VisitorObservationCheckpointResult.observed_saved(vis_sel, disc_res)
	view.show_visitor_observation_result(vis_obs)
	assert_eq(audio.get_last_sfx_cue(), "discover", "Visitor observation triggers discover SFX")

	# Blocked state pauses audio cleanly
	view.show_blocked_startup_key("ui.garden.blocked_save_error")
	assert_true(audio.is_paused(), "Blocked startup pauses GardenAudioController")

	if FileAccess.file_exists(test_settings):
		DirAccess.remove_absolute(test_settings)
	view.free()
