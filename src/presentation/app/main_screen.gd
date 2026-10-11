## main_screen.gd
## Presentation composition adapter for the main application scene.
##
## Architectural rules:
## - Belongs to the presentation layer (src/presentation/app/).
## - Acts as a thin composition adapter binding AppRoot dependencies to GardenView.
## - Does NOT call bootstrap_session() again merely to render.
## - Does NOT create a replacement GameSession if startup failed.
## - Does NOT construct a second ContentCatalog, GameClock, or RandomSource.
## - Gracefully handles missing AppRoot or blocked sessions with safe diagnostic states.
## - Listens to GardenView.planting_requested signal.
## - Dispatches AppRoot.try_plant_and_checkpoint(definition_id) exactly once upon confirmed request.
## - Passes PlantingCheckpointResult outcome to GardenView for feedback display.
## - Refreshes GardenView from authoritative GameSession if registration succeeded.
## - Supports isolated AppRoot dependency injection via bind_app_root() for testing.
class_name MainScreen
extends Control

var _garden_view: GardenView = null
var _bound_app_root: AppRoot = null
var _is_app_root_explicitly_bound: bool = false


func _ready() -> void:
	_resolve_nodes()
	_connect_garden_signals()
	_bind_dependencies()


func _resolve_nodes() -> void:
	if _garden_view == null:
		_garden_view = get_node_or_null("GardenView") as GardenView


func _connect_garden_signals() -> void:
	_resolve_nodes()
	if _garden_view != null and not _garden_view.planting_requested.is_connected(_on_garden_planting_requested):
		_garden_view.planting_requested.connect(_on_garden_planting_requested)


## Explicit dependency injection seam allowing tests or coordinators to bind an isolated AppRoot.
func bind_app_root(app: AppRoot) -> void:
	_is_app_root_explicitly_bound = true
	_bound_app_root = app
	_resolve_nodes()
	_connect_garden_signals()
	_bind_dependencies()


func _get_effective_app_root() -> AppRoot:
	if _is_app_root_explicitly_bound:
		return _bound_app_root

	if not is_inside_tree() or get_tree() == null or get_tree().root == null:
		return null

	var app_node: Node = get_tree().root.get_node_or_null("App")
	if app_node != null and app_node is AppRoot:
		return app_node as AppRoot

	return null


func _bind_dependencies() -> void:
	if _garden_view == null:
		return

	var app: AppRoot = _get_effective_app_root()
	if app == null:
		_garden_view.show_blocked_startup("ไม่พบบริการหลักของระบบ (AppRoot)")
		return

	# Check startup readiness.
	if not app.has_active_session():
		var blocked_reason: String = _determine_blocked_reason(app)
		_garden_view.show_blocked_startup(blocked_reason)
		return

	if not app.has_content_catalog() or app.game_clock == null:
		_garden_view.show_blocked_startup("ข้อมูลพืชหรือระบบเวลาไม่พร้อมใช้งาน")
		return

	# Bind authoritative dependencies to GardenView.
	_garden_view.bind_garden(
		app.game_session,
		app.get_content_catalog(),
		app.game_clock
	)


func _on_garden_planting_requested(definition_id: String) -> void:
	var app: AppRoot = _get_effective_app_root()
	if app == null:
		if _garden_view != null:
			_garden_view.show_planting_result(PlantingCheckpointResult.not_ready())
		return

	# Verify bootstrap completed, content READY, and active session exists.
	if not app.is_session_bootstrapped() or app.get_content_bootstrap_status() != AppRoot.ContentBootstrapStatus.READY or not app.has_active_session():
		if _garden_view != null:
			_garden_view.show_planting_result(PlantingCheckpointResult.not_ready())
		return

	# Invoke authoritative planting checkpoint command exactly once.
	var result: PlantingCheckpointResult = app.try_plant_and_checkpoint(definition_id)

	if _garden_view != null:
		_garden_view.show_planting_result(result)
		if result != null and result.is_registered():
			_garden_view.refresh_from_session()


func _determine_blocked_reason(app: AppRoot) -> String:
	var content_status: AppRoot.ContentBootstrapStatus = app.get_content_bootstrap_status()
	if content_status == AppRoot.ContentBootstrapStatus.LOAD_FAILED:
		return "ไม่สามารถโหลดข้อมูลพันธุ์ไม้ได้"
	elif content_status == AppRoot.ContentBootstrapStatus.INVALID_DEFINITIONS:
		return "ข้อมูลพันธุ์ไม้ไม่ถูกต้องหรือขาดหาย"

	var validation_result: PlantSaveContentValidationResult = app.get_saved_content_validation_result()
	if validation_result != null and not validation_result.is_compatible():
		return "ข้อมูลบันทึกมีพันธุ์ไม้ที่ไม่รองรับในเวอร์ชันนี้"

	var load_result: LocalSaveLoadResult = app.get_startup_load_result()
	if load_result != null:
		match load_result.get_status():
			LocalSaveLoadResult.INVALID_DATA:
				return "ข้อมูลบันทึกเสียหาย ไม่สามารถเปิดสวนได้"
			LocalSaveLoadResult.IO_ERROR:
				return "เกิดข้อผิดพลาดในการอ่านไฟล์บันทึก"

	return "ไม่สามารถโหลดสวนได้ในขณะนี้"


## Pure query for testing: returns child GardenView.
func get_garden_view() -> GardenView:
	_resolve_nodes()
	return _garden_view


## Pure query for testing: returns currently bound/effective AppRoot.
func get_effective_app_root() -> AppRoot:
	return _get_effective_app_root()
