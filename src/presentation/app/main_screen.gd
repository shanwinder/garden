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
class_name MainScreen
extends Control

var _garden_view: GardenView = null


func _ready() -> void:
	_garden_view = get_node_or_null("GardenView") as GardenView
	_bind_dependencies()


func _bind_dependencies() -> void:
	if _garden_view == null:
		return

	# Locate the existing AppRoot Autoload.
	if not is_inside_tree() or get_tree() == null or get_tree().root == null:
		_garden_view.show_blocked_startup("ไม่พบบริการหลักของระบบ (AppRoot)")
		return

	var app_node: Node = get_tree().root.get_node_or_null("App")
	if app_node == null or not (app_node is AppRoot):
		_garden_view.show_blocked_startup("ไม่พบบริการหลักของระบบ (AppRoot)")
		return

	var app: AppRoot = app_node as AppRoot

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
	if _garden_view == null:
		_garden_view = get_node_or_null("GardenView") as GardenView
	return _garden_view
