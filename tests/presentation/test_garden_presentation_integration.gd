## test_garden_presentation_integration.gd
## End-to-end integration test suite for Milestone 8 (Garden Presentation).
##
## Exercises MainScreen, GardenView, PlantingPicker, PlantView, AppRoot,
## GameSession, PlantGrowth, LifecycleCoordinator, LocalSaveRepository,
## GameStateCodec, and ContentCatalog together across isolated test save paths.
##
## Verifies:
## 1. Full player loop across process restart and offline growth progression:
##    clean first run -> touch plant via picker -> clock advance & UI refresh across
##    PLANTED/SPROUT/GROWING/MATURE -> second planting & backup rotation ->
##    process restart -> offline stage progression rendered in new MainScreen.
## 2. Transient save failure during UI planting (REGISTERED_SAVE_FAILED) followed by
##    APPLICATION_PAUSED lifecycle checkpoint recovery and process restart.
## 3. Corrupt PRIMARY with valid BACKUP recovers via LOADED_BACKUP and renders
##    recovered plants in MainScreen/GardenView with controls enabled.
## 4. All blocked startup pathways (LOAD_FAILED, INVALID_DEFINITIONS,
##    UNKNOWN_PLANT_IDS, INVALID_DATA, IO_ERROR) display exact Thai diagnostic
##    messages in GardenView, disable planting controls, and preserve disk files
##    across APPLICATION_PAUSED notifications.
## 5. Portrait layout sizing regression check across representative aspect ratios
##    (1080x1920, 720x1600, 1080x2400).
## 6. Test file hygiene: leaves no test artifacts in user://.
class_name TestGardenPresentationIntegration
extends TestSuiteBase

const MAIN_SCENE_PATH: String = "res://scenes/app/main.tscn"

const TEST_PRIMARY: String = "user://__garden_test_m8_e2e_primary.json"
const TEST_TEMP: String = "user://__garden_test_m8_e2e.tmp"
const TEST_BACKUP: String = "user://__garden_test_m8_e2e.bak"
const TEST_CORRUPT: String = "user://__garden_test_m8_e2e.corrupt"


class ToggleableSaveRepository extends LocalSaveRepository:
	var save_call_count: int = 0
	var should_fail_save: bool = false
	var forced_load_result: LocalSaveLoadResult = null

	func _init(
		p: String = TEST_PRIMARY,
		t: String = TEST_TEMP,
		b: String = TEST_BACKUP,
		c: String = TEST_CORRUPT
	) -> void:
		super._init(p, t, b, c)

	func save(state: GameState) -> bool:
		save_call_count += 1
		if should_fail_save:
			return false
		return super.save(state)

	func load() -> LocalSaveLoadResult:
		if forced_load_result != null:
			return forced_load_result
		return super.load()


class FailingContentLoader extends PlantContentLoader:
	func load_production_definitions() -> PlantContentLoadResult:
		return PlantContentLoadResult.create_failed(
			"res://content/plants/missing.tres",
			"Simulated loader failure"
		)


class IncompleteContentLoader extends PlantContentLoader:
	func load_production_definitions() -> PlantContentLoadResult:
		var basil: PlantDefinition = PlantDefinition.new()
		basil.id = "plant.holy_basil"
		basil.sprout_after_seconds = 60
		basil.growing_after_seconds = 180
		basil.mature_after_seconds = 300
		var defs: Array[PlantDefinition] = [basil]
		return PlantContentLoadResult.create_loaded(defs)


func _init() -> void:
	suite_name = "TestGardenPresentationIntegration"


func setup() -> void:
	_cleanup_test_files()


func teardown() -> void:
	_cleanup_test_files()


func run_tests() -> void:
	_test_full_player_loop_across_restart_and_offline_growth()
	_test_in_process_pause_resume_offline_growth_and_clock_rollback_safety()
	_test_harvest_and_economy_loop_across_restart_and_second_cycle()
	_test_reactive_garden_traits_and_visitor_loop()
	_test_decoration_shop_water_trait_and_frog_discovery_loop()
	_test_weather_time_of_day_and_ambient_events_matrix_loop()
	_test_garden_progression_and_gentle_guidance_e2e_loop()
	_test_first_time_user_experience_ftue_e2e_sequence()
	_test_suggested_seven_days_discovery_pacing_e2e_sequence()
	_test_offline_return_summary_and_resume_feedback_e2e_loop()
	_test_save_failure_recovered_by_lifecycle_pause_and_restart()
	_test_backup_recovery_renders_in_presentation()
	_test_all_blocked_startup_diagnostics_and_pause_safety()
	_test_localization_thai_english_switching_e2e()
	_test_coarse_grid_placement_and_first_expansion_e2e()
	_test_portrait_layout_bounds_regression()
	_test_file_hygiene()


func _cleanup_test_files() -> void:
	for path: String in [TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_CORRUPT]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _instantiate_bound_main_screen(app: AppRoot) -> MainScreen:
	var scene: PackedScene = load(MAIN_SCENE_PATH) as PackedScene
	var main_screen: MainScreen = scene.instantiate() as MainScreen
	main_screen._ready()
	main_screen.bind_app_root(app)
	return main_screen


func _test_full_player_loop_across_restart_and_offline_growth() -> void:
	describe("E2E: Clean run -> touch plant -> growth refresh -> 2nd plant -> restart & offline growth")
	_cleanup_test_files()

	# --- Session A: Clean first run at t = 1000 ---
	var repo_a: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock_a: FakeGameClock = FakeGameClock.new(1000, 0)
	var rng_a: FakeRandomSource = FakeRandomSource.new([], [10, 20, 30, 40, 50, 60, 70, 80])
	var app_a: AppRoot = AppRoot.new(repo_a, PlantContentLoader.new(), clock_a, rng_a)
	var load_res_a: LocalSaveLoadResult = app_a.bootstrap_session()

	assert_true(load_res_a != null, "Bootstrap result A must exist")
	assert_eq(load_res_a.get_status(), LocalSaveLoadResult.NO_SAVE, "Clean run must be NO_SAVE")
	assert_true(app_a.has_active_session(), "Session A must be active")

	var main_a: MainScreen = _instantiate_bound_main_screen(app_a)
	var view_a: GardenView = main_a.get_garden_view()
	assert_false(view_a.is_startup_blocked(), "GardenView A must not be blocked")
	assert_true(view_a.is_empty_garden_displayed(), "GardenView A must show empty state initially")
	assert_true(view_a.is_planting_enabled(), "Planting must be enabled on clean run")
	assert_eq(repo_a.save_call_count, 0, "Startup and initial render must not write to disk")

	# Open picker via PlantButton press, select holy_basil, then cancel first
	view_a.get_plant_button().pressed.emit()
	var picker_a: PlantingPicker = view_a.get_planting_picker()
	assert_true(picker_a.is_picker_open(), "PlantButton must open PlantingPicker")
	picker_a.select_plant_definition("plant.holy_basil")
	assert_true(picker_a.is_confirmation_active(), "Confirmation dialog active")
	picker_a.cancel_confirmation()
	assert_false(picker_a.is_confirmation_active(), "Confirmation closed after cancel")
	assert_eq(repo_a.save_call_count, 0, "Cancel must not save")
	assert_eq(view_a.get_displayed_plant_count(), 0, "Cancel must not add plant")

	# Select holy_basil (sprout=60, growing=180, mature=600) and confirm at t = 1000
	picker_a.select_plant_definition("plant.holy_basil")
	picker_a.confirm_planting()

	assert_false(picker_a.is_picker_open(), "Picker closes on confirm")
	assert_eq(repo_a.save_call_count, 1, "Confirm saves exactly once")
	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY save created on disk")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "No BACKUP on first save")
	assert_eq(view_a.get_displayed_plant_count(), 1, "One plant rendered in GardenView A")
	assert_true(
		view_a.get_feedback_text().contains("เพิ่มต้นไม้และบันทึกเรียบร้อยแล้ว"),
		"Feedback confirms REGISTERED_SAVED"
	)

	var basil_view_a: PlantView = view_a.get_plant_views()[0]
	var basil_id: String = basil_view_a.get_runtime_instance_id()
	assert_eq(basil_view_a.get_definition_id(), "plant.holy_basil", "Definition ID matches holy_basil")
	assert_eq(basil_view_a.get_planted_at(), 1000, "Planted at t = 1000")
	assert_eq(basil_view_a.get_stage(), PlantGrowth.Stage.PLANTED, "Initial stage is PLANTED")

	# Select the plant to inspect details
	basil_view_a.simulate_selection_input()
	assert_eq(view_a.get_selected_runtime_instance_id(), basil_id, "Basil selected in GardenView")
	assert_true(view_a.get_detail_name_text().contains("กะเพรา"), "Details panel shows Thai name")
	assert_true(view_a.get_detail_stage_text().contains("PLANTED"), "Details panel shows PLANTED")

	# Advance clock to SPROUT boundary (t = 1060, elapsed = 60s) and press Refresh button
	clock_a.advance_utc_seconds(60)
	view_a.get_refresh_button().pressed.emit()
	assert_eq(
		view_a.get_plant_view_by_id(basil_id).get_stage(),
		PlantGrowth.Stage.SPROUT,
		"Stage advances to SPROUT at +60s"
	)
	assert_true(view_a.get_detail_stage_text().contains("SPROUT"), "Details panel updates to SPROUT")
	assert_eq(repo_a.save_call_count, 1, "Refresh button must not trigger save")

	# Advance clock to GROWING boundary (t = 1180, elapsed = 180s) and refresh
	clock_a.advance_utc_seconds(120)
	view_a.get_refresh_button().pressed.emit()
	assert_eq(
		view_a.get_plant_view_by_id(basil_id).get_stage(),
		PlantGrowth.Stage.GROWING,
		"Stage advances to GROWING at +180s"
	)
	assert_true(view_a.get_detail_stage_text().contains("GROWING"), "Details panel updates to GROWING")

	# Advance clock to MATURE boundary (t = 1600, elapsed = 600s) and refresh
	clock_a.advance_utc_seconds(420)
	view_a.get_refresh_button().pressed.emit()
	assert_eq(
		view_a.get_plant_view_by_id(basil_id).get_stage(),
		PlantGrowth.Stage.MATURE,
		"Stage advances to MATURE at +600s"
	)
	assert_true(view_a.get_detail_stage_text().contains("MATURE"), "Details panel updates to MATURE")

	# Plant a second plant: chili (sprout=120, growing=480, mature=1200) at t = 1600
	view_a.get_plant_button().pressed.emit()
	picker_a.select_plant_definition("plant.chili")
	picker_a.confirm_planting()

	assert_eq(repo_a.save_call_count, 2, "Second planting triggers second save")
	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY exists")
	assert_true(FileAccess.file_exists(TEST_BACKUP), "Previous PRIMARY rotated to BACKUP")
	assert_eq(view_a.get_displayed_plant_count(), 2, "Two plants rendered")
	assert_eq(view_a.get_selected_runtime_instance_id(), basil_id, "Selection on basil preserved")

	var chili_id: String = ""
	for pv: PlantView in view_a.get_plant_views():
		if pv.get_runtime_instance_id() != basil_id:
			chili_id = pv.get_runtime_instance_id()
	assert_true(not chili_id.is_empty(), "Chili has distinct runtime instance ID")
	assert_eq(
		view_a.get_plant_view_by_id(chili_id).get_stage(),
		PlantGrowth.Stage.PLANTED,
		"Newly planted chili is PLANTED at t = 1600"
	)

	# Terminate Session A
	main_a.free()
	app_a.free()

	# --- Session B: Process restart after 500s offline (t = 2100) ---
	# At t = 2100:
	# - basil (planted at 1000, elapsed 1100s >= 600s) -> MATURE
	# - chili (planted at 1600, elapsed 500s: >= 480s growing, < 1200s mature) -> GROWING
	var repo_b: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock_b: FakeGameClock = FakeGameClock.new(2100, 0)
	var rng_b: FakeRandomSource = FakeRandomSource.new([], [1, 2, 3, 4])
	var app_b: AppRoot = AppRoot.new(repo_b, PlantContentLoader.new(), clock_b, rng_b)
	var load_res_b: LocalSaveLoadResult = app_b.bootstrap_session()

	assert_true(load_res_b != null, "Bootstrap result B must exist")
	assert_eq(load_res_b.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "Loaded from PRIMARY")
	assert_true(app_b.has_active_session(), "Session B active")

	var main_b: MainScreen = _instantiate_bound_main_screen(app_b)
	var view_b: GardenView = main_b.get_garden_view()

	assert_false(view_b.is_startup_blocked(), "GardenView B not blocked")
	assert_eq(view_b.get_displayed_plant_count(), 2, "Both persisted plants rendered on restart")
	assert_eq(repo_b.save_call_count, 0, "Restart and render must not write to disk")

	var basil_view_b: PlantView = view_b.get_plant_view_by_id(basil_id)
	var chili_view_b: PlantView = view_b.get_plant_view_by_id(chili_id)
	assert_true(basil_view_b != null, "Persisted basil view exists")
	assert_true(chili_view_b != null, "Persisted chili view exists")
	assert_eq(basil_view_b.get_planted_at(), 1000, "Basil planted_at preserved")
	assert_eq(chili_view_b.get_planted_at(), 1600, "Chili planted_at preserved")
	assert_eq(basil_view_b.get_stage(), PlantGrowth.Stage.MATURE, "Basil stage is MATURE after restart")
	assert_eq(chili_view_b.get_stage(), PlantGrowth.Stage.GROWING, "Chili progressed offline to GROWING")

	# Verify deterministic ordering in GardenView B
	var ordered_views_b: Array[PlantView] = view_b.get_plant_views()
	assert_true(
		ordered_views_b[0].get_runtime_instance_id() < ordered_views_b[1].get_runtime_instance_id(),
		"Rendered plant order is strictly sorted by runtime_instance_id"
	)

	main_b.free()
	app_b.free()
	_cleanup_test_files()



func _test_in_process_pause_resume_offline_growth_and_clock_rollback_safety() -> void:
	describe("E2E: In-process PAUSED -> RESUMED automatically refreshes growth stages and clamps clock rollback")
	_cleanup_test_files()

	var repo: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock: FakeGameClock = FakeGameClock.new(10000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([], [11, 22, 33, 44])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_screen: MainScreen = _instantiate_bound_main_screen(app)
	var view: GardenView = main_screen.get_garden_view()

	# Plant holy_basil (sprout=60, growing=180, mature=600) at t = 10000.
	view.get_plant_button().pressed.emit()
	var picker: PlantingPicker = view.get_planting_picker()
	picker.select_plant_definition("plant.holy_basil")
	picker.confirm_planting()

	assert_eq(repo.save_call_count, 1, "Confirm saves once")
	var basil_pv: PlantView = view.get_plant_views()[0]
	var basil_id: String = basil_pv.get_runtime_instance_id()
	assert_eq(basil_pv.get_stage(), PlantGrowth.Stage.PLANTED, "Initial stage PLANTED")

	# Select the plant so details panel is active.
	basil_pv.simulate_selection_input()
	assert_eq(view.get_selected_runtime_instance_id(), basil_id, "Basil selected")
	assert_true(view.get_detail_stage_text().contains("PLANTED"), "Details panel shows PLANTED")

	# 1. Background pause at t = 10000, advance clock to t = 10060 (+60s -> SPROUT), then resume.
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(repo.save_call_count, 2, "PAUSED checkpoints state to disk")
	clock.advance_utc_seconds(60)
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	assert_eq(repo.save_call_count, 2, "RESUMED performs zero disk writes")
	assert_eq(
		view.get_plant_view_by_id(basil_id).get_stage(),
		PlantGrowth.Stage.SPROUT,
		"Stage automatically refreshes to SPROUT on RESUMED without pressing RefreshButton"
	)
	assert_true(view.get_detail_stage_text().contains("SPROUT"), "Details panel updates to SPROUT on RESUMED")

	# 2. Background pause, device clock rolls backward before planted_at (t = 9500 < 10000), then resume.
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(repo.save_call_count, 3, "Second PAUSED checkpoints state")
	clock.set_utc_seconds(9500)
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	assert_eq(repo.save_call_count, 3, "RESUMED after rollback performs zero disk writes")
	assert_eq(
		view.get_plant_view_by_id(basil_id).get_stage(),
		PlantGrowth.Stage.PLANTED,
		"Clock rollback safely clamps elapsed time to >= 0 (stage PLANTED)"
	)
	assert_eq(
		view.get_plant_view_by_id(basil_id).get_planted_at(),
		10000,
		"Authoritative planted_at timestamp is never mutated by clock rollback"
	)
	assert_true(view.get_detail_stage_text().contains("PLANTED"), "Details panel reflects clamped PLANTED stage")

	# 3. Background pause, clock advances to t = 10600 (+600s -> MATURE), then resume.
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(repo.save_call_count, 4, "Third PAUSED checkpoints state")
	clock.set_utc_seconds(10600)
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	assert_eq(repo.save_call_count, 4, "Third RESUMED performs zero disk writes")
	assert_eq(
		view.get_plant_view_by_id(basil_id).get_stage(),
		PlantGrowth.Stage.MATURE,
		"Stage automatically refreshes to MATURE at t = 10600"
	)
	assert_eq(view.get_selected_runtime_instance_id(), basil_id, "Selection on basil preserved across 3 resumes")
	assert_true(view.get_detail_stage_text().contains("MATURE"), "Details panel updates to MATURE")

	main_screen.free()
	app.free()
	_cleanup_test_files()


func _test_harvest_and_economy_loop_across_restart_and_second_cycle() -> void:
	describe("E2E: Plant -> mature -> harvest (+5 coins, cycle reset) -> restart -> mature again -> 2nd harvest (10 coins)")
	_cleanup_test_files()

	var repo_1: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock_1: FakeGameClock = FakeGameClock.new(1000, 0)
	var rng_1: FakeRandomSource = FakeRandomSource.new([], [7, 8, 9, 10])
	var app_1: AppRoot = AppRoot.new(repo_1, PlantContentLoader.new(), clock_1, rng_1)
	app_1.bootstrap_session()

	var main_1: MainScreen = _instantiate_bound_main_screen(app_1)
	var view_1: GardenView = main_1.get_garden_view()
	assert_eq(view_1.get_currency_text(), "เหรียญ: 0", "Starts with 0 coins")

	# Plant holy_basil at t = 1000
	view_1.get_plant_button().pressed.emit()
	var picker_1: PlantingPicker = view_1.get_planting_picker()
	picker_1.select_plant_definition("plant.holy_basil")
	picker_1.confirm_planting()

	var basil_id: String = view_1.get_plant_views()[0].get_runtime_instance_id()
	view_1.get_plant_view_by_id(basil_id).simulate_selection_input()
	assert_false(view_1.is_harvest_button_enabled(), "Cannot harvest at t = 1000 (PLANTED)")

	# Background pause at t = 1000, resume at t = 1600 (+600s -> MATURE)
	app_1._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	clock_1.set_utc_seconds(1600)
	app_1._notification(Node.NOTIFICATION_APPLICATION_RESUMED)

	assert_eq(
		view_1.get_plant_view_by_id(basil_id).get_stage(),
		PlantGrowth.Stage.MATURE,
		"Basil automatically matures on resume at t = 1600"
	)
	assert_true(view_1.is_harvest_button_enabled(), "HarvestButton automatically enabled on resume at MATURE")

	# Harvest cycle 1 at t = 1600
	var saves_before_harvest_1: int = repo_1.save_call_count
	view_1.get_harvest_button().pressed.emit()
	assert_eq(repo_1.save_call_count, saves_before_harvest_1 + 1, "Harvest 1 checkpoints state to disk")
	assert_eq(view_1.get_currency_text(), "เหรียญ: 5", "HUD displays 5 coins after harvest 1")
	assert_eq(
		view_1.get_plant_view_by_id(basil_id).get_stage(),
		PlantGrowth.Stage.PLANTED,
		"Basil resets to PLANTED at t = 1600"
	)
	assert_false(view_1.is_harvest_button_enabled(), "HarvestButton disabled after cycle reset")

	main_1.free()
	app_1.free()

	# Restart into Session 2 at t = 2200 (+600s after cycle 1 reset -> MATURE again!)
	var repo_2: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock_2: FakeGameClock = FakeGameClock.new(2200, 0)
	var app_2: AppRoot = AppRoot.new(repo_2, PlantContentLoader.new(), clock_2, FakeRandomSource.new([], []))
	var load_res_2: LocalSaveLoadResult = app_2.bootstrap_session()
	assert_eq(load_res_2.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "Loaded from PRIMARY")

	var main_2: MainScreen = _instantiate_bound_main_screen(app_2)
	var view_2: GardenView = main_2.get_garden_view()
	assert_eq(view_2.get_currency_text(), "เหรียญ: 5", "Persisted 5 coins displayed on restart")

	var basil_pv_2: PlantView = view_2.get_plant_view_by_id(basil_id)
	assert_true(basil_pv_2 != null, "Same runtime_instance_id preserved across harvest and restart")
	assert_eq(basil_pv_2.get_planted_at(), 1600, "Cycle 2 start timestamp 1600 preserved")
	assert_eq(basil_pv_2.get_stage(), PlantGrowth.Stage.MATURE, "Basil matured again at t = 2200")

	basil_pv_2.simulate_selection_input()
	assert_true(view_2.is_harvest_button_enabled(), "HarvestButton enabled for cycle 2")

	# Harvest cycle 2 at t = 2200
	view_2.get_harvest_button().pressed.emit()
	assert_eq(repo_2.save_call_count, 1, "Harvest 2 saves once")
	assert_eq(view_2.get_currency_text(), "เหรียญ: 10", "HUD displays 10 coins after harvest 2")
	assert_eq(app_2.game_session.get_currency(), 10, "Authoritative currency is 10")
	assert_eq(
		view_2.get_plant_view_by_id(basil_id).get_planted_at(),
		2200,
		"Cycle 3 start timestamp reset to 2200"
	)

	main_2.free()
	app_2.free()
	_cleanup_test_files()


func _test_reactive_garden_traits_and_visitor_loop() -> void:
	describe("E2E: Empty garden -> plant banana -> traits emerge -> observe bird & cat -> Save V2 & Journal discoveries preserved across restart")
	_cleanup_test_files()

	var repo_1: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock_1: FakeGameClock = FakeGameClock.new(1000, 0)
	# Banana provides ["fruit", "perch", "shade", "shelter"]:
	# Eligible visitors:
	#   0: visitor.bird (weight 25.0) -> normalized [0.0, 0.625)
	#   1: visitor.cat  (weight 15.0) -> normalized [0.625, 1.0)
	var rng_1: FakeRandomSource = FakeRandomSource.new([0.2, 0.8], [11, 12, 13, 14])
	var app_1: AppRoot = AppRoot.new(repo_1, PlantContentLoader.new(), clock_1, rng_1)
	app_1.bootstrap_session()

	var main_1: MainScreen = _instantiate_bound_main_screen(app_1)
	var view_1: GardenView = main_1.get_garden_view()

	assert_false(view_1.is_observe_visitor_button_enabled(), "Cannot observe visitors on empty garden")
	assert_eq(
		view_1.get_journal_status_text(),
		"สมุดบ้านสวน: ค้นพบแล้ว 0 / 10 รายการ (พืช 0/5, ผู้มาเยือน 0/5)",
		"Empty journal status"
	)

	# Plant banana at t = 1000
	view_1.get_plant_button().pressed.emit()
	view_1.get_planting_picker().select_plant_definition("plant.banana")
	view_1.get_planting_picker().confirm_planting()

	assert_true(view_1.get_environment_text().contains("ผลไม้"), "Banana provides fruit trait in HUD")
	assert_true(view_1.get_environment_text().contains("ร่มเงา"), "Banana provides shade trait in HUD")
	assert_true(view_1.is_observe_visitor_button_enabled(), "ObserveVisitorButton enabled after planting banana")
	assert_eq(
		view_1.get_journal_status_text(),
		"สมุดบ้านสวน: ค้นพบแล้ว 1 / 10 รายการ (พืช 1/5, ผู้มาเยือน 0/5)",
		"Banana discovery recorded"
	)

	# Observe visitor 1 (roll 0.2 -> visitor.bird)
	view_1.get_observe_visitor_button().pressed.emit()
	assert_true(view_1.get_visitor_status_text().contains("นก"), "First observation selects bird")
	assert_eq(
		view_1.get_journal_status_text(),
		"สมุดบ้านสวน: ค้นพบแล้ว 2 / 10 รายการ (พืช 1/5, ผู้มาเยือน 1/5)",
		"Bird discovery recorded"
	)

	# Observe visitor 2 (roll 0.8 -> visitor.cat)
	view_1.get_observe_visitor_button().pressed.emit()
	assert_true(view_1.get_visitor_status_text().contains("แมว"), "Second observation selects cat")
	assert_eq(
		view_1.get_journal_status_text(),
		"สมุดบ้านสวน: ค้นพบแล้ว 3 / 10 รายการ (พืช 1/5, ผู้มาเยือน 2/5)",
		"Cat discovery recorded"
	)

	main_1.free()
	app_1.free()

	# Restart into Session 2 and verify Save Schema V2 compatibility, restored traits, and restored journal
	var repo_2: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock_2: FakeGameClock = FakeGameClock.new(2000, 0)
	var rng_2: FakeRandomSource = FakeRandomSource.new([0.9], [])
	var app_2: AppRoot = AppRoot.new(repo_2, PlantContentLoader.new(), clock_2, rng_2)
	var load_res_2: LocalSaveLoadResult = app_2.bootstrap_session()
	assert_eq(load_res_2.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "Save V2 loads cleanly after restart")

	var main_2: MainScreen = _instantiate_bound_main_screen(app_2)
	var view_2: GardenView = main_2.get_garden_view()
	assert_true(view_2.get_environment_text().contains("ผลไม้"), "Traits recomputed from persisted banana on restart")
	assert_true(view_2.is_observe_visitor_button_enabled(), "ObserveVisitorButton enabled on restart")
	assert_eq(
		view_2.get_journal_status_text(),
		"สมุดบ้านสวน: ค้นพบแล้ว 3 / 10 รายการ (พืช 1/5, ผู้มาเยือน 2/5)",
		"3 discoveries restored on restart"
	)

	view_2.get_observe_visitor_button().pressed.emit()
	assert_true(view_2.get_visitor_status_text().contains("แมว"), "Observation works after restart")
	assert_eq(
		view_2.get_journal_status_text(),
		"สมุดบ้านสวน: ค้นพบแล้ว 3 / 10 รายการ (พืช 1/5, ผู้มาเยือน 2/5)",
		"Repeat cat sighting keeps distinct count at 3"
	)
	assert_true(
		view_2.get_journal_panel().get_entry_text_for_id("visitor.cat").contains("จำนวนครั้งที่พบ: 2 ครั้ง"),
		"JournalPanel shows cat times_seen incremented to 2"
	)

	main_2.free()
	app_2.free()
	_cleanup_test_files()


func _test_decoration_shop_water_trait_and_frog_discovery_loop() -> void:
	describe("E2E: Plant marigold -> harvest coins -> buy clay_jar (-15 coins, adds water trait) -> visitor.frog unlocked and discovered in Journal -> Save V3 survives restart")
	_cleanup_test_files()

	var repo_1: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock_1: FakeGameClock = FakeGameClock.new(1000, 0)
	# Marigold provides ["flower"] -> visitor.butterfly (weight 30.0)
	# Clay jar provides ["water"] -> visitor.frog (weight 10.0)
	# Combined eligible visitors:
	#   0: visitor.butterfly (weight 30.0) -> normalized [0.0, 0.75)
	#   1: visitor.frog      (weight 10.0) -> normalized [0.75, 1.0)
	# Float roll 0.85 selects visitor.frog!
	var rng_1: FakeRandomSource = FakeRandomSource.new([0.85], [1, 2, 3, 4, 5, 6, 7, 8])
	var app_1: AppRoot = AppRoot.new(repo_1, PlantContentLoader.new(), clock_1, rng_1)
	app_1.bootstrap_session()

	var main_1: MainScreen = _instantiate_bound_main_screen(app_1)
	var view_1: GardenView = main_1.get_garden_view()

	# 1. Plant marigold (harvest_reward = 20, mature_after_seconds = 2700) at t = 1000
	view_1.get_plant_button().pressed.emit()
	view_1.get_planting_picker().select_plant_definition("plant.marigold")
	view_1.get_planting_picker().confirm_planting()

	var marigold_id: String = view_1.get_plant_views()[0].get_runtime_instance_id()
	view_1.get_plant_view_by_id(marigold_id).simulate_selection_input()

	# Before buying clay_jar, only butterfly is eligible (no frog)
	assert_false(view_1.get_visitor_status_text().contains("กบ"), "Frog not eligible before water decoration")

	# 2. Advance clock to t = 3700 (+2700s -> MATURE) and harvest marigold (+20 coins)
	clock_1.set_utc_seconds(3700)
	view_1.refresh_from_session()
	view_1.get_harvest_button().pressed.emit()
	assert_eq(view_1.get_currency_text(), "เหรียญ: 20", "20 coins after harvesting marigold")

	# 3. Open DecorationPicker and buy decoration.clay_jar (price = 15, trait = "water")
	view_1.get_decorate_button().pressed.emit()
	var dec_picker_1: DecorationPicker = view_1.get_decoration_picker()
	assert_true(dec_picker_1.is_picker_open(), "DecorationPicker opened")
	dec_picker_1.select_decoration_definition("decoration.clay_jar")
	dec_picker_1.confirm_purchase()

	assert_eq(view_1.get_currency_text(), "เหรียญ: 5", "5 coins remaining after buying clay_jar")
	assert_eq(
		view_1.get_decoration_status_text(),
		"ของตกแต่งในสวน (1 ชิ้น): ตุ่มน้ำดินเผา (1)",
		"Clay jar displayed in garden HUD"
	)
	assert_eq(view_1.get_rendered_decoration_count(), 1, "1 DecorationView card rendered in garden workspace")
	var dec_view_1: DecorationView = view_1.get_decoration_views()[0]
	assert_eq(dec_view_1.get_definition_id(), "decoration.clay_jar", "Rendered DecorationView is clay_jar")
	dec_view_1.get_touch_button().pressed.emit()
	assert_true(view_1.has_selected_decoration(), "Purchased clay_jar DecorationView can be selected for inspection")
	assert_true(view_1.get_detail_name_text().contains("ตุ่มน้ำดินเผา"), "Inspection panel shows clay_jar Thai name")
	assert_true(view_1.get_environment_text().contains("แหล่งน้ำ"), "Water trait active in environment HUD")
	assert_true(view_1.get_visitor_status_text().contains("กบ"), "Frog now eligible in visitor HUD")

	# 4. Observe visitor -> roll 0.85 selects visitor.frog and records discovery in Journal
	view_1.get_observe_visitor_button().pressed.emit()
	assert_true(view_1.get_visitor_status_text().contains("กบ"), "Visitor status shows frog visit")
	assert_eq(
		view_1.get_journal_status_text(),
		"สมุดบ้านสวน: ค้นพบแล้ว 2 / 10 รายการ (พืช 1/5, ผู้มาเยือน 1/5)",
		"Marigold + Frog discovered in journal"
	)

	main_1.free()
	app_1.free()

	# 5. Restart into Session 2 and verify Save Schema V3 preserves decorations, coins, water trait, and frog discovery
	var repo_2: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock_2: FakeGameClock = FakeGameClock.new(4000, 0)
	var app_2: AppRoot = AppRoot.new(repo_2, PlantContentLoader.new(), clock_2, FakeRandomSource.new([], []))
	var load_res_2: LocalSaveLoadResult = app_2.bootstrap_session()
	assert_eq(load_res_2.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "Save V3 loads cleanly after restart")

	var main_2: MainScreen = _instantiate_bound_main_screen(app_2)
	var view_2: GardenView = main_2.get_garden_view()
	assert_eq(view_2.get_currency_text(), "เหรียญ: 5", "5 coins preserved on restart")
	assert_eq(
		view_2.get_decoration_status_text(),
		"ของตกแต่งในสวน (1 ชิ้น): ตุ่มน้ำดินเผา (1)",
		"Persisted clay_jar displayed on restart"
	)
	assert_eq(view_2.get_rendered_decoration_count(), 1, "Persisted DecorationView card restored on restart")
	view_2.get_decoration_views()[0].get_touch_button().pressed.emit()
	assert_true(view_2.has_selected_decoration(), "Restored DecorationView selectable on restart")
	assert_eq(view_2.get_selected_decoration_definition_id(), "decoration.clay_jar", "Restored DecorationView definition ID matches")
	assert_true(view_2.get_environment_text().contains("แหล่งน้ำ"), "Water trait recomputed from persisted clay_jar")
	assert_true(
		view_2.get_journal_panel().get_entry_text_for_id("visitor.frog").contains("กบ"),
		"Frog entry unlocked in JournalPanel after restart"
	)

	main_2.free()
	app_2.free()
	_cleanup_test_files()


func _test_weather_time_of_day_and_ambient_events_matrix_loop() -> void:
	describe("E2E: All 5 MVP Interaction Matrix ambient events emerge across time-of-day, weather, plants, and decorations")
	_cleanup_test_files()

	var repo: ToggleableSaveRepository = ToggleableSaveRepository.new()
	# Start at t = 21600 -> hour 6 (morning), window 3 (clear)
	var clock: FakeGameClock = FakeGameClock.new(21600, 0)
	var rng: FakeRandomSource = FakeRandomSource.new(
		[0.1, 0.2, 0.45, 0.8, 0.5],
		[
			1, 2, 3, 4,
			5, 6, 7, 8,
			9, 10, 11, 12,
			13, 14, 15, 16,
			17, 18, 19, 20,
			21, 22, 23, 24,
		]
	)
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_screen: MainScreen = _instantiate_bound_main_screen(app)
	var view: GardenView = main_screen.get_garden_view()

	# Row 1: Jasmine + Morning (t = 21600, morning + clear) -> event.morning_butterflies
	assert_false(view.is_observe_event_button_enabled(), "ObserveEventButton initially disabled on empty garden")
	view.get_plant_button().pressed.emit()
	view.get_planting_picker().select_plant_definition("plant.jasmine")
	view.get_planting_picker().confirm_planting()
	assert_eq(view.get_eligible_event_ids(), ["event.morning_butterflies"], "Row 1: Morning butterflies active")
	assert_true(view.get_atmosphere_text().contains("ฝูงผีเสื้อยามเช้า"), "Row 1 HUD text")
	assert_true(view.is_observe_event_button_enabled(), "ObserveEventButton enabled on Row 1")
	view.get_observe_event_button().pressed.emit()
	assert_eq(view.get_current_event_id(), "event.morning_butterflies", "Row 1 observed via ObserveEventButton")
	assert_true(view.get_feedback_text().contains("ฝูงผีเสื้อโบยบินวนเวียนตอมดอกไม้"), "Row 1 feedback text")
	assert_eq(view.get_journal_panel().get_active_event_entry_count(), 1, "Row 1: 1 active event in JournalPanel")

	# Row 2: Banana + Daytime (t = 43200, hour 12 = day, window 6 = cloudy) -> event.bird_shade_song + morning_butterflies
	view.get_plant_button().pressed.emit()
	view.get_planting_picker().select_plant_definition("plant.banana")
	view.get_planting_picker().confirm_planting()
	clock.set_utc_seconds(43200)
	view.refresh_from_session()
	assert_eq(
		view.get_eligible_event_ids(),
		["event.bird_shade_song", "event.morning_butterflies"],
		"Row 2: Bird shade song and morning butterflies active at day"
	)
	assert_true(view.get_atmosphere_text().contains("นกร้องเพลงใต้ร่มไม้"), "Row 2 HUD text")
	view.get_observe_event_button().pressed.emit()
	assert_eq(view.get_current_event_id(), "event.bird_shade_song", "Row 2 observed via ObserveEventButton")
	assert_true(view.get_feedback_text().contains("นกกระจอกส่งเสียงร้องสดใส"), "Row 2 feedback text")
	assert_eq(view.get_journal_panel().get_active_event_entry_count(), 2, "Row 2: 2 active events in JournalPanel")

	# Row 3: Bench + Evening (t = 64800, hour 18 = evening, window 9 = cloudy) -> event.cat_sleeping_bench unlocked
	app.game_session.grant_currency(200)
	view.refresh_from_session()
	view.get_decorate_button().pressed.emit()
	view.get_decoration_picker().select_decoration_definition("decoration.bench")
	view.get_decoration_picker().confirm_purchase()
	clock.set_utc_seconds(64800)
	view.refresh_from_session()
	assert_true(
		view.get_eligible_event_ids().has("event.cat_sleeping_bench"),
		"Row 3: Cat sleeping on bench active at evening"
	)
	assert_true(view.get_atmosphere_text().contains("แมวนอนหลับบนม้านั่ง"), "Row 3 HUD text")
	view.get_observe_event_button().pressed.emit()
	assert_eq(view.get_current_event_id(), "event.cat_sleeping_bench", "Row 3 observed via ObserveEventButton")
	assert_true(view.get_feedback_text().contains("แมวข้างบ้านขดตัวนอนหลับ"), "Row 3 feedback text")
	assert_eq(view.get_journal_panel().get_placed_decoration_entry_count(), 1, "Row 3: 1 placed decoration in JournalPanel")

	# Row 4: Garden Lamp + Night (t = 72000, hour 20 = night, window 10 = clear) -> event.firefly_night_glow
	view.get_decorate_button().pressed.emit()
	view.get_decoration_picker().select_decoration_definition("decoration.garden_lamp")
	view.get_decoration_picker().confirm_purchase()
	clock.set_utc_seconds(72000)
	view.refresh_from_session()
	assert_true(
		view.get_eligible_event_ids().has("event.firefly_night_glow"),
		"Row 4: Firefly night glow active at night clear"
	)
	assert_true(view.get_atmosphere_text().contains("หิ่งห้อยเรืองแสงยามค่ำ"), "Row 4 HUD text")
	view.get_observe_event_button().pressed.emit()
	assert_eq(view.get_current_event_id(), "event.firefly_night_glow", "Row 4 observed via ObserveEventButton")
	assert_true(view.get_feedback_text().contains("แสงหิ่งห้อยส่องประกายระยิบระยับ"), "Row 4 feedback text")
	assert_eq(view.get_journal_panel().get_placed_decoration_entry_count(), 2, "Row 4: 2 placed decorations in JournalPanel")

	# Row 5: Small Pond + Rain (t = 14400, hour 4 = night, window 2 = rain) -> event.frog_rain_chorus
	view.get_decorate_button().pressed.emit()
	view.get_decoration_picker().select_decoration_definition("decoration.small_pond")
	view.get_decoration_picker().confirm_purchase()
	clock.set_utc_seconds(14400)
	view.refresh_from_session()
	assert_eq(view.get_eligible_event_ids(), ["event.frog_rain_chorus"], "Row 5: Frog rain chorus active during rain")
	assert_true(view.get_atmosphere_text().contains("กบร้องเพลงกลางสายฝน"), "Row 5 HUD text")
	var saves_before_ev5: int = repo.save_call_count
	view.get_observe_event_button().pressed.emit()
	assert_eq(repo.save_call_count, saves_before_ev5, "Observing event via ObserveEventButton performs zero disk writes")
	assert_eq(view.get_current_event_id(), "event.frog_rain_chorus", "Row 5 observed via ObserveEventButton")
	assert_true(view.get_feedback_text().contains("กบในสวนส่งเสียงร้องรับสายฝน"), "Row 5 feedback text")
	assert_eq(view.get_journal_panel().get_placed_decoration_entry_count(), 3, "Row 5: 3 placed decorations in JournalPanel")
	assert_eq(view.get_journal_panel().get_active_event_entry_count(), 1, "Row 5: 1 active event in JournalPanel")

	main_screen.free()
	app.free()
	_cleanup_test_files()


func _test_garden_progression_and_gentle_guidance_e2e_loop() -> void:
	describe("E2E: Full progression across all 5 canonical garden stages and 6 gentle guidance states with restart")
	_cleanup_test_files()

	var integers: Array[int] = []
	for i: int in range(1, 64):
		integers.append(i)
	var repo_a: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock_a: FakeGameClock = FakeGameClock.new(1000, 0)
	var rng_a: FakeRandomSource = FakeRandomSource.new([0.05], integers)
	var app_a: AppRoot = AppRoot.new(repo_a, PlantContentLoader.new(), clock_a, rng_a)
	app_a.bootstrap_session()
	app_a.game_session.grant_currency(300)

	var main_a: MainScreen = _instantiate_bound_main_screen(app_a)
	var view_a: GardenView = main_a.get_garden_view()

	# Stage 1: Starting Garden (0 pts), guidance.plant_first
	assert_eq(view_a.get_current_progression_stage_id(), GardenProgressionStage.STAGE_STARTING_GARDEN, "Stage 1: starting_garden")
	assert_eq(view_a.get_current_establishment_score(), 0, "Stage 1 score is 0")
	assert_eq(view_a.get_current_guidance_id(), GardenProgressionStage.GUIDANCE_PLANT_FIRST, "Guidance 1: plant_first")
	assert_true(view_a.get_progression_text().contains("สวนเริ่มต้น (0 แต้ม, อีก 10 แต้มสู่สวนกำลังเติบโต)"), "Stage 1 HUD label")

	# Stage 2: Growing Garden (14 pts) after planting jasmine, guidance.observe_visitor
	view_a.open_planting_picker()
	view_a.get_planting_picker().select_plant_definition("plant.jasmine")
	view_a.get_planting_picker().confirm_planting()
	assert_eq(view_a.get_current_progression_stage_id(), GardenProgressionStage.STAGE_GROWING_GARDEN, "Stage 2: growing_garden")
	assert_eq(view_a.get_current_establishment_score(), 14, "Stage 2 score is 14")
	assert_eq(view_a.get_current_guidance_id(), GardenProgressionStage.GUIDANCE_OBSERVE_VISITOR, "Guidance 2: observe_visitor")
	assert_true(view_a.get_progression_text().contains("สวนกำลังเติบโต (14 แต้ม, อีก 11 แต้มสู่สวนร่มรื่น)"), "Stage 2 HUD label")

	# Guidance 3: Observe butterfly (+5 pts -> 19 pts) -> guidance.place_decoration
	view_a.get_observe_visitor_button().pressed.emit()
	assert_eq(view_a.get_current_establishment_score(), 19, "Score is 19 after visitor observation")
	assert_eq(view_a.get_current_guidance_id(), GardenProgressionStage.GUIDANCE_PLACE_DECORATION, "Guidance 3: place_decoration")

	# Stage 3: Shady Garden (29 pts) after placing bench (+4 decor, +6 for shade & shelter), guidance.create_water_habitat
	view_a.get_decorate_button().pressed.emit()
	view_a.get_decoration_picker().select_decoration_definition("decoration.bench")
	view_a.get_decoration_picker().confirm_purchase()
	assert_eq(view_a.get_current_progression_stage_id(), GardenProgressionStage.STAGE_SHADY_GARDEN, "Stage 3: shady_garden")
	assert_eq(view_a.get_current_establishment_score(), 29, "Stage 3 score is 29")
	assert_eq(view_a.get_current_guidance_id(), GardenProgressionStage.GUIDANCE_CREATE_WATER_HABITAT, "Guidance 4: create_water_habitat")
	assert_true(view_a.get_progression_text().contains("สวนร่มรื่น (29 แต้ม, อีก 16 แต้มสู่สวนมีชีวิต)"), "Stage 3 HUD label")

	# Stage 4: Living Garden (47 pts) after planting holy_basil (+3 plant, +5 discovery, +3 food trait) + placing clay_jar (+4 decor, +3 water trait), guidance.discover_more
	view_a.open_planting_picker()
	view_a.get_planting_picker().select_plant_definition("plant.holy_basil")
	view_a.get_planting_picker().confirm_planting()
	view_a.get_decorate_button().pressed.emit()
	view_a.get_decoration_picker().select_decoration_definition("decoration.clay_jar")
	view_a.get_decoration_picker().confirm_purchase()
	assert_eq(view_a.get_current_progression_stage_id(), GardenProgressionStage.STAGE_LIVING_GARDEN, "Stage 4: living_garden")
	assert_eq(view_a.get_current_establishment_score(), 47, "Stage 4 score is 47")
	assert_eq(view_a.get_current_guidance_id(), GardenProgressionStage.GUIDANCE_DISCOVER_MORE, "Guidance 5: discover_more")
	assert_true(view_a.get_progression_text().contains("สวนมีชีวิต (47 แต้ม, อีก 23 แต้มสู่บ้านสวนแสนสุข)"), "Stage 4 HUD label")

	# Stage 5: Happy Garden Home (107 pts >= 70) after planting banana, chili, marigold (+9 plants, +15 discoveries, +6 fruit & perch traits),
	# advancing clock by +21600s so all 5 plants mature (+10), and recording remaining 4 visitors (+20)
	for pid: String in ["plant.banana", "plant.chili", "plant.marigold"]:
		view_a.open_planting_picker()
		view_a.get_planting_picker().select_plant_definition(pid)
		view_a.get_planting_picker().confirm_planting()
	clock_a.set_utc_seconds(22600)
	for vid: String in ["visitor.bird", "visitor.cat", "visitor.firefly", "visitor.frog"]:
		app_a.game_session.record_discovery_at(app_a.get_content_catalog(), vid, 22600)
	app_a._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	view_a.refresh_from_session()

	assert_eq(view_a.get_current_progression_stage_id(), GardenProgressionStage.STAGE_HAPPY_GARDEN_HOME, "Stage 5: happy_garden_home")
	assert_eq(view_a.get_current_establishment_score(), 107, "Stage 5 score is 107")
	assert_eq(view_a.get_next_progression_stage_id(), "", "Stage 5 next stage is empty")
	assert_eq(view_a.get_points_to_next_progression_stage(), 0, "Stage 5 points to next stage is 0")
	assert_eq(view_a.get_current_guidance_id(), GardenProgressionStage.GUIDANCE_ENJOY_GARDEN, "Guidance 6: enjoy_garden")
	assert_eq(
		view_a.get_progression_text(),
		"ระดับสวน: บ้านสวนแสนสุข (107 แต้ม, สูงสุดแล้ว) | วันนี้ทำอะไรดี: เพลิดเพลินกับบรรยากาศบ้านสวนแสนสุขตามอัธยาศัย",
		"Stage 5 HUD label"
	)

	main_a.free()
	app_a.free()

	# Restart into Session B at t = 22600 and verify deterministic progression restoration
	var repo_b: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock_b: FakeGameClock = FakeGameClock.new(22600, 0)
	var app_b: AppRoot = AppRoot.new(repo_b, PlantContentLoader.new(), clock_b, FakeRandomSource.new([], []))
	var load_res_b: LocalSaveLoadResult = app_b.bootstrap_session()
	assert_eq(load_res_b.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "Session B loaded from PRIMARY")

	var main_b: MainScreen = _instantiate_bound_main_screen(app_b)
	var view_b: GardenView = main_b.get_garden_view()
	assert_eq(view_b.get_current_progression_stage_id(), GardenProgressionStage.STAGE_HAPPY_GARDEN_HOME, "Restored stage is happy_garden_home")
	assert_eq(view_b.get_current_establishment_score(), 107, "Restored score is 107")
	assert_eq(view_b.get_current_guidance_id(), GardenProgressionStage.GUIDANCE_ENJOY_GARDEN, "Restored guidance is enjoy_garden")

	main_b.free()
	app_b.free()
	_cleanup_test_files()


func _test_first_time_user_experience_ftue_e2e_sequence() -> void:
	describe("E2E: Full 8-step First-Time User Experience (FTUE) sequence per GAME_DESIGN.md §21")
	_cleanup_test_files()

	var repo: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)
	var integers: Array[int] = []
	for i: int in range(1, 64):
		integers.append(i)
	var rng: FakeRandomSource = FakeRandomSource.new([0.85], integers)
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_screen: MainScreen = _instantiate_bound_main_screen(app)
	var view: GardenView = main_screen.get_garden_view()

	# Step 1: See garden (0 plants, 0 decorations, 0 coins) -> STEP_SEE_GARDEN
	assert_true(view.is_ftue_active(), "FTUE is active on first session")
	assert_false(view.is_ftue_completed(), "FTUE is not completed on first session")
	assert_eq(view.get_ftue_step_id(), FtueStep.STEP_SEE_GARDEN, "Step 1: STEP_SEE_GARDEN")
	assert_eq(view.get_ftue_step_index(), 0, "Step 1 index is 0")
	assert_true(view.get_ftue_label().visible, "FtueLabel is visible at Step 1")
	assert_true(view.get_ftue_text().contains("สำรวจสวน"), "Step 1 title in label")

	# Step 2: Plant something (marigold) -> STEP_WATCH_GROWTH
	view.open_planting_picker()
	view.get_planting_picker().select_plant_definition("plant.marigold")
	view.get_planting_picker().confirm_planting()
	assert_eq(view.get_ftue_step_id(), FtueStep.STEP_WATCH_GROWTH, "Step 2: STEP_WATCH_GROWTH after planting")
	assert_eq(view.get_ftue_step_index(), 1, "Step 2 index is 1")
	assert_true(view.get_ftue_text().contains("เฝ้ามองการเติบโต"), "Step 2 title in label")

	# Step 3: Advance clock +2700s to maturity -> STEP_HARVEST_PLANT
	clock.set_utc_seconds(3700)
	view.refresh_from_session()
	assert_eq(view.get_ftue_step_id(), FtueStep.STEP_HARVEST_PLANT, "Step 3: STEP_HARVEST_PLANT when plant matures")
	assert_eq(view.get_ftue_step_index(), 2, "Step 3 index is 2")
	assert_true(view.get_ftue_text().contains("เก็บเกี่ยวผลผลิต"), "Step 3 title in label")

	# Step 4: Harvest plant (+20 coins) -> STEP_PLACE_DECORATION
	var marigold_id: String = view.get_plant_views()[0].get_runtime_instance_id()
	view.get_plant_view_by_id(marigold_id).simulate_selection_input()
	view.get_harvest_button().pressed.emit()
	assert_eq(view.get_currency_text(), "เหรียญ: 20", "20 coins earned from harvest")
	assert_eq(view.get_ftue_step_id(), FtueStep.STEP_PLACE_DECORATION, "Step 4: STEP_PLACE_DECORATION when player has coins")
	assert_eq(view.get_ftue_step_index(), 3, "Step 4 index is 3")
	assert_true(view.get_ftue_text().contains("จัดวางของตกแต่ง"), "Step 4 title in label")

	# Step 5: Buy clay_jar (-15 coins, adds water trait) -> STEP_OBSERVE_VISITOR
	view.get_decorate_button().pressed.emit()
	view.get_decoration_picker().select_decoration_definition("decoration.clay_jar")
	view.get_decoration_picker().confirm_purchase()
	assert_eq(view.get_ftue_step_id(), FtueStep.STEP_OBSERVE_VISITOR, "Step 5: STEP_OBSERVE_VISITOR when decoration placed")
	assert_eq(view.get_ftue_step_index(), 4, "Step 5 index is 4")
	assert_true(view.get_ftue_text().contains("พบผู้มาเยือน"), "Step 5 title in label")

	# Step 6: Observe visitor (roll 0.85 selects visitor.frog) -> STEP_CHECK_JOURNAL
	view.get_observe_visitor_button().pressed.emit()
	assert_eq(view.get_ftue_step_id(), FtueStep.STEP_CHECK_JOURNAL, "Step 6: STEP_CHECK_JOURNAL after visitor recorded")
	assert_eq(view.get_ftue_step_index(), 5, "Step 6 index is 5")
	assert_true(view.get_ftue_text().contains("สมุดบ้านสวน"), "Step 6 title in label")

	# Step 7: Plant second plant (holy basil) -> 3 discoveries -> STEP_COMPLETED
	view.open_planting_picker()
	view.get_planting_picker().select_plant_definition("plant.holy_basil")
	view.get_planting_picker().confirm_planting()
	assert_true(view.is_ftue_completed(), "FTUE completed after established garden")
	assert_false(view.is_ftue_active(), "FTUE no longer active once completed")
	assert_eq(view.get_ftue_step_id(), FtueStep.STEP_COMPLETED, "Step 7: STEP_COMPLETED")
	assert_eq(view.get_ftue_step_index(), 6, "Step 7 index is 6")
	assert_false(view.get_ftue_label().visible, "FtueLabel is hidden when FTUE is completed")

	main_screen.free()
	app.free()
	_cleanup_test_files()


func _test_suggested_seven_days_discovery_pacing_e2e_sequence() -> void:
	describe("E2E: Full 7-phase Suggested First Seven Days of Discovery pacing per GAME_DESIGN.md §22")
	_cleanup_test_files()

	var repo: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)
	var scripted_ints: Array[int] = []
	for i: int in range(100):
		scripted_ints.append(1000 + i)
	var rng: FakeRandomSource = FakeRandomSource.new(
		[0.85, 0.5, 0.2, 0.9],
		scripted_ints
	)
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_screen: MainScreen = _instantiate_bound_main_screen(app)
	var view: GardenView = main_screen.get_garden_view()

	# 1. Day 1: Early phase (empty garden)
	assert_true(view.has_discovery_pacing_milestone(), "Has pacing milestone at start")
	assert_eq(view.get_discovery_pacing_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_1_EARLY_PHASE, "Starts at Day 1")
	assert_eq(view.get_discovery_pacing_day_index(), 1, "Day 1 index is 1")
	assert_false(view.is_discovery_pacing_achieved(), "Day 1 not achieved yet")
	assert_true(view.get_discovery_pacing_label().visible, "DiscoveryPacingLabel visible")

	# Plant marigold -> Day 1 achieved, advances to Day 2
	view.open_planting_picker()
	view.get_planting_picker().select_plant_definition("plant.marigold")
	view.get_planting_picker().confirm_planting()
	assert_eq(view.get_discovery_pacing_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_2_EARLY_RETURN, "Advances to Day 2")
	assert_eq(view.get_discovery_pacing_day_index(), 2, "Day 2 index is 2")
	assert_false(view.is_discovery_pacing_achieved(), "Day 2 not achieved yet")

	# 2. Advance time +2700s to mature and harvest to earn coins
	clock.set_utc_seconds(3700)
	view.refresh_from_session()
	var marigold_id: String = view.get_plant_views()[0].get_runtime_instance_id()
	view.get_plant_view_by_id(marigold_id).simulate_selection_input()
	view.get_harvest_button().pressed.emit()
	assert_eq(view.get_currency_text(), "เหรียญ: 20", "20 coins earned")

	# Purchase clay_jar (-15 coins) -> adds water trait -> Day 2 achieved, advances to Day 3
	view.get_decorate_button().pressed.emit()
	view.get_decoration_picker().select_decoration_definition("decoration.clay_jar")
	view.get_decoration_picker().confirm_purchase()
	assert_eq(view.get_discovery_pacing_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_3_DEVELOPING_GARDEN, "Advances to Day 3")
	assert_eq(view.get_discovery_pacing_day_index(), 3, "Day 3 index is 3")
	assert_false(view.is_discovery_pacing_achieved(), "Day 3 not achieved yet")

	# 3. Harvest marigold again to earn coins for bench
	clock.set_utc_seconds(6400)
	view.refresh_from_session()
	view.get_plant_view_by_id(marigold_id).simulate_selection_input()
	view.get_harvest_button().pressed.emit()
	assert_eq(view.get_currency_text(), "เหรียญ: 25", "25 coins available")

	# Purchase bench (-25 coins) -> resting_spot -> Day 3 achieved, advances to Day 4
	view.get_decorate_button().pressed.emit()
	view.get_decoration_picker().select_decoration_definition("decoration.bench")
	view.get_decoration_picker().confirm_purchase()
	assert_eq(view.get_discovery_pacing_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_4_WEATHER_DISCOVERY, "Advances to Day 4")
	assert_eq(view.get_discovery_pacing_day_index(), 4, "Day 4 index is 4")
	assert_false(view.is_discovery_pacing_achieved(), "Day 4 not achieved yet")

	# 4. Advance clock to rain weather timestamp
	# GardenWeather cycle: period 7200s (0..2879 sunny, 2880..5039 overcast, 5040..7199 rain)
	# 7200 * 2 + 5500 = 19900s -> rain
	clock.set_utc_seconds(19900)
	view.refresh_from_session()
	assert_eq(view.get_current_weather_state(), GardenWeather.RAIN, "Weather is rain")
	# Rain + water trait allows observing frog visitor
	view.get_observe_visitor_button().pressed.emit()
	# Satisfies Day 4 -> advances to Day 5
	assert_eq(view.get_discovery_pacing_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_5_WATER_HABITAT, "Advances to Day 5")
	assert_eq(view.get_discovery_pacing_day_index(), 5, "Day 5 index is 5")
	assert_false(view.is_discovery_pacing_achieved(), "Day 5 not achieved yet")

	# 5. Harvest marigold again to get coins
	view.get_plant_view_by_id(marigold_id).simulate_selection_input()
	view.get_harvest_button().pressed.emit()
	# Add coins directly to economy for small_pond (50 coins)
	app.game_session.get_state().get_economy().grant_currency(50)
	view.refresh_from_session()

	# Purchase small_pond (-50 coins) -> Day 5 achieved, advances to Day 6
	view.get_decorate_button().pressed.emit()
	view.get_decoration_picker().select_decoration_definition("decoration.small_pond")
	view.get_decoration_picker().confirm_purchase()
	assert_eq(view.get_discovery_pacing_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_6_NIGHT_DISCOVERY, "Advances to Day 6")
	assert_eq(view.get_discovery_pacing_day_index(), 6, "Day 6 index is 6")
	assert_false(view.is_discovery_pacing_achieved(), "Day 6 not achieved yet")

	# 6. Purchase garden_lamp (-30 coins) and shift clock to night
	app.game_session.get_state().get_economy().grant_currency(50)
	view.refresh_from_session()
	view.get_decorate_button().pressed.emit()
	view.get_decoration_picker().select_decoration_definition("decoration.garden_lamp")
	view.get_decoration_picker().confirm_purchase()

	# Shift clock to night period: 86400s cycle, night is 75600..86399
	clock.set_utc_seconds(80000)
	view.refresh_from_session()
	assert_eq(view.get_current_time_period(), GardenTimePeriod.NIGHT, "Time period is night")
	# Night + light from garden_lamp satisfies Day 6 -> advances to Day 7
	assert_eq(view.get_discovery_pacing_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_7_FIRST_EXPANSION, "Advances to Day 7")
	assert_eq(view.get_discovery_pacing_day_index(), 7, "Day 7 index is 7")
	assert_true(view.get_current_establishment_score() >= GardenProgressionStage.THRESHOLD_LIVING_GARDEN, "Living garden score reached")
	assert_true(view.is_discovery_pacing_achieved(), "Day 7 achieved with living garden establishment")
	assert_true(view.get_discovery_pacing_text().contains("สำเร็จแล้ว"), "Label indicates completion")

	# 7. Plant remaining plants and record sightings to complete journal
	var journal: JournalState = app.game_session.get_state().get_journal()
	for pid: String in ["plant.banana", "plant.chili", "plant.holy_basil", "plant.jasmine"]:
		journal.try_record_sighting(pid, 80000)
	for vid: String in ["visitor.bird", "visitor.butterfly", "visitor.cat", "visitor.firefly"]:
		journal.try_record_sighting(vid, 80000)

	view.refresh_from_session()
	assert_true(view.is_discovery_pacing_achieved(), "Day 7 remains achieved")
	assert_eq(view.get_discovery_pacing_milestone_id(), DiscoveryPacingMilestone.MILESTONE_DAY_7_FIRST_EXPANSION, "Milestone is Day 7")
	assert_true(view.get_discovery_pacing_text().contains("สำเร็จแล้ว"), "Label indicates completion")

	main_screen.free()
	app.free()
	_cleanup_test_files()


func _test_offline_return_summary_and_resume_feedback_e2e_loop() -> void:
	describe("E2E: Offline return observation summary across pause/resume, plant maturity, weather/time shift, and clock rollback")
	_cleanup_test_files()

	var repo: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock: FakeGameClock = FakeGameClock.new(1000, 0) # night, clear
	var rng: FakeRandomSource = FakeRandomSource.new([0.1], [1, 2, 3, 4, 5, 6, 7, 8])
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_screen: MainScreen = _instantiate_bound_main_screen(app)
	var view: GardenView = main_screen.get_garden_view()

	# Plant holy_basil (mature=600) and jasmine (sprout=600, growing=1800, mature=3600) at t=1000
	view.open_planting_picker()
	view.get_planting_picker().select_plant_definition("plant.holy_basil")
	view.get_planting_picker().confirm_planting()

	view.open_planting_picker()
	view.get_planting_picker().select_plant_definition("plant.jasmine")
	view.get_planting_picker().confirm_planting()

	var saves_after_planting: int = repo.save_call_count
	assert_eq(saves_after_planting, 2, "2 saves after 2 plantings")
	assert_eq(app.game_session.get_state().get_journal().get_count(), 2, "2 plant discoveries in journal")

	# 1. Pause at t=1000 (+1 save), return at t=14400 (+13400s -> 3 hours: night + rain; both plants MATURE)
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(repo.save_call_count, 3, "Pause checkpoints state once")

	clock.set_utc_seconds(14400)
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(repo.save_call_count, 3, "Resume performs zero disk writes")

	var sum1: GardenReturnSummary = view.get_last_return_summary()
	assert_true(sum1 != null and sum1.is_valid(), "Valid return summary on resume")
	assert_eq(sum1.get_elapsed_seconds(), 13400, "Elapsed 13400s")
	assert_eq(sum1.get_advanced_plant_count(), 2, "Both plants advanced")
	assert_eq(sum1.get_newly_matured_plant_count(), 2, "Both plants newly matured")
	assert_eq(sum1.get_ready_to_harvest_count(), 2, "2 plants ready to harvest")
	assert_false(sum1.has_time_period_changed(), "Still night at t=14400")
	assert_true(sum1.has_weather_changed(), "Weather changed clear -> rain")
	assert_true(view.is_feedback_visible(), "Return feedback displayed")
	assert_eq(
		view.get_feedback_text(),
		"ต้นไม้ในสวนเติบโตขึ้นระหว่างที่คุณไม่อยู่ (เติบโต 2 ต้น, พร้อมเก็บเกี่ยว 2 ต้น)",
		"Return feedback shows 2 newly matured plants and ready count"
	)
	# Verify no unobserved visitor discoveries were added during away time (GAME_DESIGN.md Section 19)
	assert_eq(
		app.game_session.get_state().get_journal().get_count(),
		2,
		"Offline return never automatically records unobserved visitors in JournalState"
	)

	# 2. Pause at t=14400 (+1 save), return at t=21600 (morning, clear; plants already mature -> atmosphere-only change)
	app._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(repo.save_call_count, 4, "Second pause checkpoints state once")
	clock.set_utc_seconds(21600)
	app._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	assert_eq(repo.save_call_count, 4, "Second resume performs zero disk writes")
	assert_eq(
		view.get_feedback_text(),
		"บรรยากาศในสวนเปลี่ยนไประหว่างที่คุณไม่อยู่ (ยามเช้า, ท้องฟ้าแจ่มใส)",
		"Return feedback shows atmosphere shift when plants were already mature"
	)

	main_screen.free()
	app.free()
	_cleanup_test_files()


func _test_save_failure_recovered_by_lifecycle_pause_and_restart() -> void:
	describe("E2E: REGISTERED_SAVE_FAILED in UI -> recovered on APPLICATION_PAUSED -> survives restart")
	_cleanup_test_files()

	var repo_a: ToggleableSaveRepository = ToggleableSaveRepository.new()
	repo_a.should_fail_save = true
	var clock_a: FakeGameClock = FakeGameClock.new(5000, 0)
	var rng_a: FakeRandomSource = FakeRandomSource.new([], [5, 6, 7, 8])
	var app_a: AppRoot = AppRoot.new(repo_a, PlantContentLoader.new(), clock_a, rng_a)
	app_a.bootstrap_session()

	var main_a: MainScreen = _instantiate_bound_main_screen(app_a)
	var view_a: GardenView = main_a.get_garden_view()

	# Plant jasmine while repository save fails
	view_a.open_planting_picker()
	view_a.get_planting_picker().select_plant_definition("plant.jasmine")
	view_a.get_planting_picker().confirm_planting()

	assert_eq(repo_a.save_call_count, 1, "Save attempted once on confirm")
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY not written due to simulated failure")
	assert_eq(view_a.get_displayed_plant_count(), 1, "Plant remains in memory and rendered in GardenView")
	assert_true(
		view_a.get_feedback_text().contains("เพิ่มต้นไม้แล้ว แต่ยังบันทึกไม่สำเร็จ"),
		"Unsaved warning displayed to player"
	)
	var jasmine_id: String = view_a.get_plant_views()[0].get_runtime_instance_id()

	# Restore save capability and trigger mobile pause checkpoint
	repo_a.should_fail_save = false
	app_a._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(
		app_a.lifecycle_coordinator.get_last_pause_outcome(),
		LifecycleCoordinator.SAVED,
		"Pause checkpoint saves the active in-memory session"
	)
	assert_true(FileAccess.file_exists(TEST_PRIMARY), "PRIMARY now exists on disk after pause")

	main_a.free()
	app_a.free()

	# Restart into Session B and verify jasmine was recovered
	var repo_b: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock_b: FakeGameClock = FakeGameClock.new(5400, 0)
	var app_b: AppRoot = AppRoot.new(repo_b, PlantContentLoader.new(), clock_b, FakeRandomSource.new([], []))
	var load_res_b: LocalSaveLoadResult = app_b.bootstrap_session()
	assert_eq(load_res_b.get_status(), LocalSaveLoadResult.LOADED_PRIMARY, "Loaded from PRIMARY")

	var main_b: MainScreen = _instantiate_bound_main_screen(app_b)
	var view_b: GardenView = main_b.get_garden_view()
	assert_eq(view_b.get_displayed_plant_count(), 1, "Jasmine rendered after restart")
	var jasmine_view_b: PlantView = view_b.get_plant_view_by_id(jasmine_id)
	assert_true(jasmine_view_b != null, "Exact jasmine runtime instance ID recovered")
	assert_eq(jasmine_view_b.get_stage(), PlantGrowth.Stage.SPROUT, "Jasmine at SPROUT (+400s)")

	main_b.free()
	app_b.free()
	_cleanup_test_files()



func _test_backup_recovery_renders_in_presentation() -> void:
	describe("E2E: Corrupt PRIMARY with valid BACKUP recovers via LOADED_BACKUP and renders in UI")
	_cleanup_test_files()

	# Write valid state to BACKUP and corrupt bytes to PRIMARY
	var valid_state: GameState = GameState.new()
	valid_state.get_plants().try_add_plant(PlantState.new("backup-marigold-1", "plant.marigold", 2000))
	var encoded: String = JSON.stringify(GameStateCodec.encode(valid_state))
	var fb: FileAccess = FileAccess.open(TEST_BACKUP, FileAccess.WRITE)
	fb.store_string(encoded)
	fb.close()

	var fp: FileAccess = FileAccess.open(TEST_PRIMARY, FileAccess.WRITE)
	fp.store_string("{corrupt_primary_json")
	fp.close()

	var repo: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var clock: FakeGameClock = FakeGameClock.new(4800, 0)
	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, FakeRandomSource.new([], []))
	var load_res: LocalSaveLoadResult = app.bootstrap_session()

	assert_eq(load_res.get_status(), LocalSaveLoadResult.LOADED_BACKUP, "Recovered from BACKUP")
	assert_true(app.has_active_session(), "Session is active from BACKUP")

	var main_screen: MainScreen = _instantiate_bound_main_screen(app)
	var view: GardenView = main_screen.get_garden_view()

	assert_false(view.is_startup_blocked(), "GardenView not blocked on LOADED_BACKUP")
	assert_true(view.is_planting_enabled(), "Planting enabled on LOADED_BACKUP")
	assert_eq(view.get_displayed_plant_count(), 1, "Recovered marigold rendered")
	var pv: PlantView = view.get_plant_view_by_id("backup-marigold-1")
	assert_true(pv != null, "backup-marigold-1 view exists")
	assert_eq(pv.get_stage(), PlantGrowth.Stage.MATURE, "Marigold at MATURE (+2800s >= 2700s)")

	main_screen.free()
	app.free()
	_cleanup_test_files()


func _test_all_blocked_startup_diagnostics_and_pause_safety() -> void:
	describe("E2E: All blocked startup pathways show exact Thai diagnostics and suppress pause saves")
	_cleanup_test_files()

	# 1. Content LOAD_FAILED
	var repo_1: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var app_1: AppRoot = AppRoot.new(
		repo_1,
		FailingContentLoader.new(),
		FakeGameClock.new(1000, 0),
		FakeRandomSource.new([], [])
	)
	app_1.bootstrap_session()
	var main_1: MainScreen = _instantiate_bound_main_screen(app_1)
	var view_1: GardenView = main_1.get_garden_view()
	assert_true(view_1.is_startup_blocked(), "Blocked on LOAD_FAILED")
	assert_false(view_1.is_planting_enabled(), "Planting disabled on LOAD_FAILED")
	assert_eq(view_1.get_blocked_message(), "ไม่สามารถโหลดข้อมูลพันธุ์ไม้ได้", "LOAD_FAILED message")
	app_1._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(repo_1.save_call_count, 0, "No save on pause when LOAD_FAILED")
	main_1.free()
	app_1.free()

	# 2. Content INVALID_DEFINITIONS (incomplete catalog)
	var repo_2: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var app_2: AppRoot = AppRoot.new(
		repo_2,
		IncompleteContentLoader.new(),
		FakeGameClock.new(1000, 0),
		FakeRandomSource.new([], [])
	)
	app_2.bootstrap_session()
	var main_2: MainScreen = _instantiate_bound_main_screen(app_2)
	var view_2: GardenView = main_2.get_garden_view()
	assert_true(view_2.is_startup_blocked(), "Blocked on INVALID_DEFINITIONS")
	assert_false(view_2.is_planting_enabled(), "Planting disabled on INVALID_DEFINITIONS")
	assert_eq(view_2.get_blocked_message(), "ข้อมูลพันธุ์ไม้ไม่ถูกต้องหรือขาดหาย", "INVALID_DEFINITIONS message")
	app_2._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(repo_2.save_call_count, 0, "No save on pause when INVALID_DEFINITIONS")
	main_2.free()
	app_2.free()

	# 3. Saved plant with unknown definition ID (UNKNOWN_PLANT_IDS)
	var unknown_state: GameState = GameState.new()
	unknown_state.get_plants().try_add_plant(PlantState.new("inst-future", "plant.future_lotus", 1000))
	var unknown_json: String = JSON.stringify(GameStateCodec.encode(unknown_state))
	var f_unk: FileAccess = FileAccess.open(TEST_PRIMARY, FileAccess.WRITE)
	f_unk.store_string(unknown_json)
	f_unk.close()

	var repo_3: ToggleableSaveRepository = ToggleableSaveRepository.new()
	var app_3: AppRoot = AppRoot.new(
		repo_3,
		PlantContentLoader.new(),
		FakeGameClock.new(1000, 0),
		FakeRandomSource.new([], [])
	)
	app_3.bootstrap_session()
	var main_3: MainScreen = _instantiate_bound_main_screen(app_3)
	var view_3: GardenView = main_3.get_garden_view()
	assert_true(view_3.is_startup_blocked(), "Blocked on UNKNOWN_PLANT_IDS")
	assert_false(view_3.is_planting_enabled(), "Planting disabled on UNKNOWN_PLANT_IDS")
	assert_eq(
		view_3.get_blocked_message(),
		"ข้อมูลบันทึกมีพันธุ์ไม้ที่ไม่รองรับในเวอร์ชันนี้",
		"UNKNOWN_PLANT_IDS message"
	)
	app_3._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(repo_3.save_call_count, 0, "No save on pause when UNKNOWN_PLANT_IDS")
	assert_eq(
		FileAccess.get_file_as_string(TEST_PRIMARY),
		unknown_json,
		"On-disk save with unknown plant ID preserved untouched"
	)
	main_3.free()
	app_3.free()
	_cleanup_test_files()

	# 4. Persistence IO_ERROR
	var repo_4: ToggleableSaveRepository = ToggleableSaveRepository.new()
	repo_4.forced_load_result = LocalSaveLoadResult.io_error()
	var app_4: AppRoot = AppRoot.new(
		repo_4,
		PlantContentLoader.new(),
		FakeGameClock.new(1000, 0),
		FakeRandomSource.new([], [])
	)
	app_4.bootstrap_session()
	var main_4: MainScreen = _instantiate_bound_main_screen(app_4)
	var view_4: GardenView = main_4.get_garden_view()
	assert_true(view_4.is_startup_blocked(), "Blocked on IO_ERROR")
	assert_false(view_4.is_planting_enabled(), "Planting disabled on IO_ERROR")
	assert_eq(view_4.get_blocked_message(), "เกิดข้อผิดพลาดในการอ่านไฟล์บันทึก", "IO_ERROR message")
	app_4._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(repo_4.save_call_count, 0, "No save on pause when IO_ERROR")
	main_4.free()
	app_4.free()


func _test_portrait_layout_bounds_regression() -> void:
	describe("Portrait layout regression: panels fit within 1080x1920, 720x1600, and 1080x2400")
	var viewports: Array[Vector2] = [
		Vector2(1080, 1920),
		Vector2(720, 1600),
		Vector2(1080, 2400),
	]

	for vp_size: Vector2 in viewports:
		var main_screen: MainScreen = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as MainScreen
		main_screen._ready()

		var view: GardenView = main_screen.get_garden_view()
		var picker: PlantingPicker = view.get_planting_picker()
		var dec_picker: DecorationPicker = view.get_decoration_picker()
		var journal: JournalPanel = view.get_journal_panel()
		var picker_panel: Control = picker.get_node_or_null("CenterContainer/PickerPanel") as Control
		var confirm_panel: Control = picker.get_node_or_null("ConfirmationOverlay/ConfirmCenter/ConfirmPanel") as Control
		var dec_picker_panel: Control = dec_picker.get_node_or_null("CenterContainer/PickerPanel") as Control
		var dec_confirm_panel: Control = dec_picker.get_node_or_null("ConfirmationOverlay/ConfirmCenter/ConfirmPanel") as Control
		var journal_modal_panel: Control = journal.get_node_or_null("CenterContainer/JournalModalPanel") as Control
		var blocked_label: Control = view.get_node_or_null("MainMargin/LayoutBox/ContentArea/BlockedStateContainer/BlockedLabel") as Control
		var content_area: Control = view.get_node_or_null("MainMargin/LayoutBox/ContentArea") as Control
		var main_margin: MarginContainer = view.get_node_or_null("MainMargin") as MarginContainer
		var layout_box: Control = view.get_node_or_null("MainMargin/LayoutBox") as Control
		var plant_card: PlantView = (load("res://scenes/garden/plant_view.tscn") as PackedScene).instantiate() as PlantView
		var decor_card: DecorationView = (load("res://scenes/garden/decoration_view.tscn") as PackedScene).instantiate() as DecorationView

		assert_true(picker_panel != null, "PickerPanel exists")
		assert_true(confirm_panel != null, "ConfirmPanel exists")
		assert_true(dec_picker_panel != null, "DecorationPicker PickerPanel exists")
		assert_true(dec_confirm_panel != null, "DecorationPicker ConfirmPanel exists")
		assert_true(journal_modal_panel != null, "JournalModalPanel exists")
		assert_true(blocked_label != null, "BlockedLabel exists")
		assert_true(content_area != null, "ContentArea exists")
		assert_true(main_margin != null, "MainMargin exists")
		assert_true(layout_box != null, "LayoutBox exists")

		assert_true(
			content_area.custom_minimum_size.y >= 320.0,
			"ContentArea guarantees >= 320px vertical garden space at viewport %s" % str(vp_size)
		)
		var margin_x: float = float(
			main_margin.get_theme_constant("margin_left") + main_margin.get_theme_constant("margin_right")
		)
		var margin_y: float = float(
			main_margin.get_theme_constant("margin_top") + main_margin.get_theme_constant("margin_bottom")
		)
		var lb_min: Vector2 = layout_box.get_combined_minimum_size()
		assert_true(
			lb_min.x + margin_x <= vp_size.x and lb_min.y + margin_y <= vp_size.y,
			"LayoutBox minimum size %s + margins fits within viewport %s" % [str(lb_min), str(vp_size)]
		)
		assert_true(
			plant_card.custom_minimum_size.x * 2.0 + 16.0 + margin_x <= vp_size.x,
			"2-column PlantView cards fit within viewport width %s" % str(vp_size)
		)
		assert_true(
			decor_card.custom_minimum_size.x * 2.0 + 16.0 + margin_x <= vp_size.x,
			"2-column DecorationView cards fit within viewport width %s" % str(vp_size)
		)
		plant_card.free()
		decor_card.free()

		assert_true(
			picker_panel.custom_minimum_size.x <= vp_size.x and picker_panel.custom_minimum_size.y <= vp_size.y,
			"PickerPanel custom_minimum_size fits within viewport %s" % str(vp_size)
		)
		assert_true(
			confirm_panel.custom_minimum_size.x <= vp_size.x and confirm_panel.custom_minimum_size.y <= vp_size.y,
			"ConfirmPanel custom_minimum_size fits within viewport %s" % str(vp_size)
		)
		assert_true(
			dec_picker_panel.custom_minimum_size.x <= vp_size.x and dec_picker_panel.custom_minimum_size.y <= vp_size.y,
			"DecorationPicker PickerPanel custom_minimum_size fits within viewport %s" % str(vp_size)
		)
		assert_true(
			dec_confirm_panel.custom_minimum_size.x <= vp_size.x and dec_confirm_panel.custom_minimum_size.y <= vp_size.y,
			"DecorationPicker ConfirmPanel custom_minimum_size fits within viewport %s" % str(vp_size)
		)
		assert_true(
			journal_modal_panel.custom_minimum_size.x <= vp_size.x and journal_modal_panel.custom_minimum_size.y <= vp_size.y,
			"JournalModalPanel custom_minimum_size fits within viewport %s" % str(vp_size)
		)
		assert_true(
			blocked_label.custom_minimum_size.x <= vp_size.x,
			"BlockedLabel custom_minimum_size.x fits within viewport %s" % str(vp_size)
		)

		# Also verify English locale static sizing stays within bounds at this portrait viewport.
		view.set_locale("en")
		var lb_min_en: Vector2 = layout_box.get_combined_minimum_size()
		assert_true(
			lb_min_en.x + margin_x <= vp_size.x and lb_min_en.y + margin_y <= vp_size.y,
			"LayoutBox English minimum size %s + margins fits within viewport %s" % [str(lb_min_en), str(vp_size)]
		)

		main_screen.free()


func _test_localization_thai_english_switching_e2e() -> void:
	describe("E2E: Live Thai/English localization switching updates HUD, cards, pickers, journal, feedback, blocked diagnostics, and leaves save data locale-independent")
	_cleanup_test_files()
	var repo: LocalSaveRepository = LocalSaveRepository.new(TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_CORRUPT)
	var clock: FakeGameClock = FakeGameClock.new(1000, 0)
	var rng: FakeRandomSource = FakeRandomSource.new([0.0], [1, 2, 3, 4, 5, 6, 7, 8])

	var app: AppRoot = AppRoot.new(repo, PlantContentLoader.new(), clock, rng)
	app.bootstrap_session()

	var main_screen: MainScreen = _instantiate_bound_main_screen(app)
	var view: GardenView = main_screen.get_garden_view()

	# 1. Default locale is Thai ("th")
	assert_eq(view.get_locale(), "th", "Default locale is Thai")
	assert_eq(view.get_plant_button().text, "ปลูกต้นไม้", "Thai plant button")
	assert_eq(view.get_currency_text(), "เหรียญ: 0", "Thai currency HUD")

	# Plant mature jasmine + buy clay jar + observe frog/butterfly
	var picker: PlantingPicker = view.get_planting_picker()
	view.get_plant_button().pressed.emit()
	picker.select_plant_definition("plant.jasmine")
	assert_true(picker.get_confirm_prompt_text().contains("มะลิ"), "Thai picker confirm prompt")
	picker.confirm_planting()
	assert_true(view.get_feedback_text().contains("เพิ่มต้นไม้และบันทึกเรียบร้อยแล้ว"), "Thai planting feedback")

	# 2. Switch to English via LanguageButton press -> live re-render across all views & active feedback!
	view.get_language_button().pressed.emit()
	assert_eq(view.get_locale(), "en", "LanguageButton toggles to 'en'")
	assert_eq(view.get_plant_button().text, "Plant", "English plant button")
	assert_eq(view.get_refresh_button().text, "Refresh", "English refresh button")
	assert_eq(view.get_journal_button().text, "Journal", "English journal button")
	assert_eq(view.get_decorate_button().text, "Decorate", "English decorate button")
	assert_eq(view.get_currency_text(), "Coins: 0", "English currency HUD")
	assert_eq(view.get_feedback_text(), "Plant added and saved", "Active planting feedback re-rendered in English")
	assert_true(view.get_progression_text().contains("Garden Stage: "), "English progression stage HUD")
	assert_true(view.get_daily_guidance_text().contains("Today's Suggestions:"), "English daily guidance HUD")
	assert_true(view.get_ftue_text().contains("First Steps:"), "English FTUE HUD")
	assert_true(view.get_discovery_pacing_text().contains("Discovery Goal:"), "English pacing HUD")
	assert_true(view.get_atmosphere_text().contains("Atmosphere:"), "English atmosphere HUD")

	# PlantView card and DetailsArea in English
	var pview: PlantView = view.get_plant_views()[0]
	assert_eq(pview.get_display_name(), "Jasmine", "PlantView renders English name")
	assert_eq(pview.get_stage_label_text(), "Planted", "PlantView renders English stage")
	pview.simulate_selection_input()
	assert_eq(view.get_details_header_text(), "Plant Details", "Details header in English")
	assert_true(view.get_detail_name_text().contains("Jasmine"), "Details name in English")

	# Advance clock so jasmine matures, harvest & earn coins, buy bench decoration -> inspect in English
	clock.set_utc_seconds(1000 + 3600)
	view.refresh_from_session()
	assert_eq(view.get_plant_views()[0].get_stage_label_text(), "Mature (+25 coins)", "Mature PlantView in English")
	view.get_harvest_button().pressed.emit()
	assert_eq(view.get_currency_text(), "Coins: 25", "Harvest updated English currency HUD")
	assert_eq(view.get_feedback_text(), "Harvested (+25 coins) and saved", "English harvest feedback")

	var dec_picker: DecorationPicker = view.get_decoration_picker()
	view.open_decoration_picker()
	assert_true(
		dec_picker.get_decoration_option_text_for_id("decoration.bench").contains("Wooden Garden Bench"),
		"DecorationPicker renders English item names"
	)
	dec_picker.select_decoration_definition("decoration.bench")
	assert_true(dec_picker.get_confirm_prompt_text().contains("Buy and place Wooden Garden Bench"), "DecorationPicker confirm prompt in English")
	# Toggling back to Thai while confirmation overlay is open updates confirm prompt live!
	view.toggle_locale()
	assert_eq(view.get_locale(), "th", "Toggled back to 'th'")
	assert_true(dec_picker.get_confirm_prompt_text().contains("ม้านั่งไม้ในสวน"), "Open DecorationPicker confirm prompt updates live to Thai")
	assert_eq(view.get_feedback_text(), "เก็บเกี่ยวสำเร็จ (+25 เหรียญ) และบันทึกเรียบร้อยแล้ว", "Feedback banner updates live back to Thai")
	view.toggle_locale()
	assert_eq(view.get_locale(), "en", "Toggled back to 'en'")
	dec_picker.confirm_purchase()

	var dview: DecorationView = view.get_decoration_views()[0]
	assert_eq(dview.get_display_name(), "Wooden Garden Bench", "DecorationView renders English name")
	assert_eq(dview.get_role_badge_text(), "[Decoration]", "DecorationView renders English role badge")
	dview.get_touch_button().pressed.emit()
	assert_eq(view.get_details_header_text(), "Decoration Details", "Decoration details header in English")
	assert_eq(view.get_harvest_button().text, "Decorations are not harvested", "Decoration harvest disabled message in English")

	# JournalPanel in English (including secret event clue!)
	var journal: JournalPanel = view.get_journal_panel()
	view.open_journal_panel()
	assert_true(journal.get_summary_text().contains("discovered"), "Journal summary in English")
	assert_true(journal.get_entry_text_for_id("plant.jasmine").contains("[Discovered] Jasmine"), "Journal plant entry in English")
	assert_true(journal.get_entry_text_for_id("decoration.bench").contains("[Placed] Wooden Garden Bench"), "Journal decoration entry in English")
	assert_true(
		journal.get_entry_text_for_id("event.cat_jasmine_night_rest").contains("[???] Secret Garden Mystery"),
		"Journal secret event mystery placeholder in English"
	)

	# 3. Save Schema V3 payload remains 100% locale-independent (no display text persisted!)
	var raw_json: String = FileAccess.get_file_as_string(TEST_PRIMARY)
	assert_false(raw_json.contains("Jasmine"), "Save file never stores English display text")
	assert_false(raw_json.contains("มะลิ"), "Save file never stores Thai display text")
	assert_true(raw_json.contains("plant.jasmine"), "Save file stores stable IDs")
	assert_true(raw_json.contains("decoration.bench"), "Save file stores stable decoration IDs")

	main_screen.free()
	app.free()

	# 4. Blocked startup diagnostic re-translates when locale toggles
	var corrupt_repo: ToggleableSaveRepository = ToggleableSaveRepository.new()
	corrupt_repo.forced_load_result = LocalSaveLoadResult.invalid_data()
	var blocked_app: AppRoot = AppRoot.new(
		corrupt_repo,
		PlantContentLoader.new(),
		FakeGameClock.new(1000, 0),
		FakeRandomSource.new([], [])
	)
	blocked_app.bootstrap_session()
	var blocked_main: MainScreen = _instantiate_bound_main_screen(blocked_app)
	var blocked_view: GardenView = blocked_main.get_garden_view()
	assert_eq(blocked_view.get_blocked_message(), "ข้อมูลบันทึกเสียหาย ไม่สามารถเปิดสวนได้", "Blocked startup defaults to Thai")
	blocked_view.toggle_locale()
	assert_eq(blocked_view.get_blocked_message(), "Save data is corrupted; unable to open garden", "Blocked startup translates to English on toggle")
	blocked_main.free()
	blocked_app.free()
	_cleanup_test_files()


func _test_coarse_grid_placement_and_first_expansion_e2e() -> void:
	describe("E2E: Coarse Logical Grid cell targeting, item moving, First Expansion unlock, and Schema V4 persistence across restart")
	_cleanup_test_files()
	var repo_1: LocalSaveRepository = LocalSaveRepository.new(TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_CORRUPT)
	var clock_1: FakeGameClock = FakeGameClock.new(1000, 0)
	var rng_1: FakeRandomSource = FakeRandomSource.new([0.0], [1, 2, 3, 4, 5, 6, 7, 8])

	var app_1: AppRoot = AppRoot.new(repo_1, PlantContentLoader.new(), clock_1, rng_1)
	app_1.bootstrap_session()
	var main_1: MainScreen = _instantiate_bound_main_screen(app_1)
	var view_1: GardenView = main_1.get_garden_view()

	# 1. Target empty cell (1, 1) in zone.main, then plant holy basil via PlantingPicker
	app_1.try_plant_and_checkpoint("plant.holy_basil", GardenZone.ZONE_MAIN, 1, 1)
	view_1.refresh_from_session()

	var plant_views: Array[PlantView] = view_1.get_plant_views()
	assert_eq(plant_views.size(), 1, "1 plant view rendered")
	var basil_id: String = plant_views[0].get_runtime_instance_id()
	assert_eq(plant_views[0].get_zone_id(), GardenZone.ZONE_MAIN, "Basil placed in zone.main")
	assert_eq(plant_views[0].get_grid_x(), 1, "Basil placed at grid_x=1")
	assert_eq(plant_views[0].get_grid_y(), 1, "Basil placed at grid_y=1")

	# Check cell occupancy button in grid
	var cell_btn: Button = view_1.get_zone_grid_cell_button(1, 1)
	assert_true(cell_btn != null, "Cell (1,1) button exists")
	assert_true(cell_btn.text.contains("กะเพรา"), "Cell (1,1) button displays occupant")

	# 2. Grant coins and purchase bench decoration targeted at (2, 2)
	app_1.game_session.grant_currency(100)
	app_1.try_purchase_decoration_and_checkpoint("decoration.bench", GardenZone.ZONE_MAIN, 2, 2)
	view_1.refresh_from_session()

	var decor_views: Array[DecorationView] = view_1.get_decoration_views()
	assert_eq(decor_views.size(), 1, "1 decoration view rendered")
	var bench_id: String = decor_views[0].get_runtime_instance_id()
	assert_eq(decor_views[0].get_zone_id(), GardenZone.ZONE_MAIN, "Bench placed in zone.main")
	assert_eq(decor_views[0].get_grid_x(), 2, "Bench placed at grid_x=2")
	assert_eq(decor_views[0].get_grid_y(), 2, "Bench placed at grid_y=2")

	# 3. Move plant from (1, 1) to (3, 3) via move command
	var move_res: GardenPlacementCheckpointResult = app_1.try_move_item_and_checkpoint(
		basil_id,
		GardenZone.ZONE_MAIN,
		3,
		3
	)
	assert_true(move_res.is_moved(), "Plant move succeeded")
	assert_true(move_res.is_saved(), "Plant move checkpoint saved")
	view_1.refresh_from_session()

	var updated_pview: PlantView = view_1.get_plant_view_by_id(basil_id)
	assert_eq(updated_pview.get_grid_x(), 3, "Plant moved to X=3")
	assert_eq(updated_pview.get_grid_y(), 3, "Plant moved to Y=3")

	# 4. Check Save Schema V4 wire format on disk
	var raw_save: String = FileAccess.get_file_as_string(TEST_PRIMARY)
	var parsed_save: Variant = JSON.parse_string(raw_save)
	assert_true(parsed_save is Dictionary, "Saved PRIMARY is JSON object")
	var save_dict: Dictionary = parsed_save as Dictionary
	assert_eq(int(save_dict["schema_version"]), 4, "Save file uses Schema V4")
	var saved_plants: Array = save_dict["plants"] as Array
	assert_eq((saved_plants[0] as Dictionary).get("grid_x"), "3", "Saved plant grid_x is 3")
	assert_eq((saved_plants[0] as Dictionary).get("grid_y"), "3", "Saved plant grid_y is 3")
	assert_eq((saved_plants[0] as Dictionary).get("zone_id"), "zone.main", "Saved plant zone_id is zone.main")

	# 5. First Expansion unlock & move across zones:
	# Add enough discoveries to unlock Adjacent Zone 2 (8+ discoveries)
	for i: int in range(8):
		app_1.game_session.record_discovery_at(
			app_1.get_content_catalog(),
			"plant.holy_basil" if i == 0 else "plant.chili" if i == 1 else "plant.jasmine" if i == 2 else "plant.marigold" if i == 3 else "plant.banana" if i == 4 else "visitor.butterfly" if i == 5 else "visitor.bird" if i == 6 else "visitor.cat",
			1000 + i
		)
	view_1.refresh_from_session()
	assert_true(view_1.is_adjacent_zone_unlocked(), "Adjacent Zone 2 is unlocked")

	# Move bench to Adjacent Zone 2 at (1, 1)
	var move_decor_res: GardenPlacementCheckpointResult = app_1.try_move_item_and_checkpoint(
		bench_id,
		GardenZone.ZONE_ADJACENT_1,
		1,
		1
	)
	assert_true(move_decor_res.is_moved(), "Bench move to adjacent zone succeeded")
	assert_true(move_decor_res.is_saved(), "Bench move checkpoint saved")

	main_1.free()
	app_1.free()

	# 6. Process restart: simulate fresh launch from the Schema V4 save file
	var repo_2: LocalSaveRepository = LocalSaveRepository.new(TEST_PRIMARY, TEST_TEMP, TEST_BACKUP, TEST_CORRUPT)
	var clock_2: FakeGameClock = FakeGameClock.new(2000, 0)
	var rng_2: FakeRandomSource = FakeRandomSource.new([], [])
	var app_2: AppRoot = AppRoot.new(repo_2, PlantContentLoader.new(), clock_2, rng_2)
	var load_res: LocalSaveLoadResult = app_2.bootstrap_session()
	assert_true(load_res.is_loaded(), "Session bootstrapped from Schema V4 save")

	var main_2: MainScreen = _instantiate_bound_main_screen(app_2)
	var view_2: GardenView = main_2.get_garden_view()

	var reloaded_basil: PlantState = app_2.game_session.get_state().get_plants().get_plant(basil_id)
	assert_true(reloaded_basil != null, "Basil preserved across restart")
	assert_eq(reloaded_basil.get_zone_id(), GardenZone.ZONE_MAIN, "Reloaded basil in zone.main")
	assert_eq(reloaded_basil.get_grid_x(), 3, "Reloaded basil X=3")
	assert_eq(reloaded_basil.get_grid_y(), 3, "Reloaded basil Y=3")

	var reloaded_bench: DecorationState = app_2.game_session.get_state().get_decorations().get_decoration(bench_id)
	assert_true(reloaded_bench != null, "Bench preserved across restart")
	assert_eq(reloaded_bench.get_zone_id(), GardenZone.ZONE_ADJACENT_1, "Reloaded bench in zone.adjacent_1")
	assert_eq(reloaded_bench.get_grid_x(), 1, "Reloaded bench X=1")
	assert_eq(reloaded_bench.get_grid_y(), 1, "Reloaded bench Y=1")

	# Check UI view details reflect restored placement
	var reloaded_dview: DecorationView = view_2.get_decoration_view_by_id(bench_id)
	assert_true(reloaded_dview != null, "DecorationView exists for bench")
	assert_eq(reloaded_dview.get_zone_id(), GardenZone.ZONE_ADJACENT_1, "DecorationView zone_id is zone.adjacent_1")
	assert_eq(reloaded_dview.get_grid_x(), 1, "DecorationView grid_x is 1")
	assert_eq(reloaded_dview.get_grid_y(), 1, "DecorationView grid_y is 1")

	reloaded_dview.get_touch_button().pressed.emit()
	assert_true(view_2.get_detail_placement_text().contains("มุมสวนข้างบ้าน"), "Details panel displays restored zone")
	assert_true(view_2.get_detail_placement_text().contains("(1, 1)"), "Details panel displays restored coords (1,1)")

	main_2.free()
	app_2.free()
	_cleanup_test_files()


func _test_file_hygiene() -> void:
	describe("File hygiene: no integration test save files remain in user://")
	_cleanup_test_files()
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "TEST_PRIMARY cleaned up")
	assert_false(FileAccess.file_exists(TEST_TEMP), "TEST_TEMP cleaned up")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "TEST_BACKUP cleaned up")
	assert_false(FileAccess.file_exists(TEST_CORRUPT), "TEST_CORRUPT cleaned up")
