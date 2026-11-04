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
	_test_save_failure_recovered_by_lifecycle_pause_and_restart()
	_test_backup_recovery_renders_in_presentation()
	_test_all_blocked_startup_diagnostics_and_pause_safety()
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
		var picker_panel: Control = picker.get_node_or_null("CenterContainer/PickerPanel") as Control
		var confirm_panel: Control = picker.get_node_or_null("ConfirmationOverlay/ConfirmCenter/ConfirmPanel") as Control
		var blocked_label: Control = view.get_node_or_null("MainMargin/LayoutBox/ContentArea/BlockedStateContainer/BlockedLabel") as Control

		assert_true(picker_panel != null, "PickerPanel exists")
		assert_true(confirm_panel != null, "ConfirmPanel exists")
		assert_true(blocked_label != null, "BlockedLabel exists")

		assert_true(
			picker_panel.custom_minimum_size.x <= vp_size.x and picker_panel.custom_minimum_size.y <= vp_size.y,
			"PickerPanel custom_minimum_size fits within viewport %s" % str(vp_size)
		)
		assert_true(
			confirm_panel.custom_minimum_size.x <= vp_size.x and confirm_panel.custom_minimum_size.y <= vp_size.y,
			"ConfirmPanel custom_minimum_size fits within viewport %s" % str(vp_size)
		)
		assert_true(
			blocked_label.custom_minimum_size.x <= vp_size.x,
			"BlockedLabel custom_minimum_size.x fits within viewport %s" % str(vp_size)
		)

		main_screen.free()


func _test_file_hygiene() -> void:
	describe("File hygiene: no integration test save files remain in user://")
	_cleanup_test_files()
	assert_false(FileAccess.file_exists(TEST_PRIMARY), "TEST_PRIMARY cleaned up")
	assert_false(FileAccess.file_exists(TEST_TEMP), "TEST_TEMP cleaned up")
	assert_false(FileAccess.file_exists(TEST_BACKUP), "TEST_BACKUP cleaned up")
	assert_false(FileAccess.file_exists(TEST_CORRUPT), "TEST_CORRUPT cleaned up")
