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
var _connected_app_root: AppRoot = null
var _is_app_root_explicitly_bound: bool = false


func _ready() -> void:
	_resolve_nodes()
	_connect_garden_signals()
	_bind_dependencies()


func _exit_tree() -> void:
	_disconnect_app_root_signals()


func _resolve_nodes() -> void:
	if _garden_view == null:
		_garden_view = get_node_or_null("GardenView") as GardenView


func _connect_garden_signals() -> void:
	_resolve_nodes()
	if _garden_view != null and not _garden_view.planting_requested.is_connected(_on_garden_planting_requested):
		_garden_view.planting_requested.connect(_on_garden_planting_requested)
	if _garden_view != null and not _garden_view.harvest_requested.is_connected(_on_garden_harvest_requested):
		_garden_view.harvest_requested.connect(_on_garden_harvest_requested)
	if _garden_view != null and not _garden_view.visitor_observation_requested.is_connected(_on_garden_visitor_observation_requested):
		_garden_view.visitor_observation_requested.connect(_on_garden_visitor_observation_requested)
	if _garden_view != null and not _garden_view.event_observation_requested.is_connected(_on_garden_event_observation_requested):
		_garden_view.event_observation_requested.connect(_on_garden_event_observation_requested)
	if _garden_view != null and not _garden_view.decoration_purchase_requested.is_connected(_on_garden_decoration_purchase_requested):
		_garden_view.decoration_purchase_requested.connect(_on_garden_decoration_purchase_requested)


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


func _sync_app_root_signals(app: AppRoot) -> void:
	if _connected_app_root != null and is_instance_valid(_connected_app_root) and _connected_app_root != app:
		if _connected_app_root.session_resumed.is_connected(_on_app_session_resumed):
			_connected_app_root.session_resumed.disconnect(_on_app_session_resumed)
		_connected_app_root = null

	if app != null and is_instance_valid(app):
		if not app.session_resumed.is_connected(_on_app_session_resumed):
			app.session_resumed.connect(_on_app_session_resumed)
		_connected_app_root = app


func _disconnect_app_root_signals() -> void:
	if _connected_app_root != null and is_instance_valid(_connected_app_root):
		if _connected_app_root.session_resumed.is_connected(_on_app_session_resumed):
			_connected_app_root.session_resumed.disconnect(_on_app_session_resumed)
	_connected_app_root = null


func _bind_dependencies() -> void:
	var app: AppRoot = _get_effective_app_root()
	_sync_app_root_signals(app)

	if _garden_view == null:
		return

	if app == null:
		_garden_view.show_blocked_startup_key("ui.startup.missing_app_root")
		return

	# Check startup readiness.
	if not app.has_active_session():
		var blocked_reason_key: String = _determine_blocked_reason_key(app)
		_garden_view.show_blocked_startup_key(blocked_reason_key)
		return

	if not app.has_content_catalog() or app.game_clock == null:
		_garden_view.show_blocked_startup_key("ui.startup.catalog_or_clock_unavailable")
		return

	# Bind authoritative dependencies to GardenView.
	_garden_view.bind_garden(
		app.game_session,
		app.get_content_catalog(),
		app.game_clock
	)


func _on_app_session_resumed() -> void:
	if _garden_view == null:
		return

	var app: AppRoot = _get_effective_app_root()
	if app == null:
		return

	if (
		not app.is_session_bootstrapped()
		or app.get_content_bootstrap_status() != AppRoot.ContentBootstrapStatus.READY
		or not app.has_active_session()
		or not app.has_content_catalog()
		or app.game_clock == null
	):
		return

	_garden_view.refresh_from_session()
	var return_summary: GardenReturnSummary = _garden_view.get_last_return_summary()
	if return_summary != null and return_summary.has_meaningful_changes():
		_garden_view.show_return_summary(return_summary)



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


func _on_garden_harvest_requested(runtime_instance_id: String) -> void:
	var app: AppRoot = _get_effective_app_root()
	if app == null:
		if _garden_view != null:
			_garden_view.show_harvest_result(HarvestCheckpointResult.not_ready())
		return

	# Verify bootstrap completed, content READY, and active session exists.
	if (
		not app.is_session_bootstrapped()
		or app.get_content_bootstrap_status() != AppRoot.ContentBootstrapStatus.READY
		or not app.has_active_session()
	):
		if _garden_view != null:
			_garden_view.show_harvest_result(HarvestCheckpointResult.not_ready())
		return

	# Invoke authoritative harvest checkpoint command exactly once.
	var result: HarvestCheckpointResult = app.try_harvest_and_checkpoint(runtime_instance_id)

	if _garden_view != null:
		_garden_view.show_harvest_result(result)
		if result != null and result.is_harvested():
			_garden_view.refresh_from_session()


func _on_garden_visitor_observation_requested() -> void:
	var app: AppRoot = _get_effective_app_root()
	if app == null:
		if _garden_view != null:
			_garden_view.show_visitor_observation_result(VisitorObservationCheckpointResult.not_ready())
		return

	if (
		not app.is_session_bootstrapped()
		or app.get_content_bootstrap_status() != AppRoot.ContentBootstrapStatus.READY
		or not app.has_active_session()
	):
		if _garden_view != null:
			_garden_view.show_visitor_observation_result(VisitorObservationCheckpointResult.not_ready())
		return

	var result: VisitorObservationCheckpointResult = app.try_observe_visitor_and_checkpoint()
	if _garden_view != null:
		_garden_view.show_visitor_observation_result(result)
		if result != null and result.is_observed():
			_garden_view.refresh_from_session()


func _on_garden_event_observation_requested() -> void:
	var app: AppRoot = _get_effective_app_root()
	if app == null:
		if _garden_view != null:
			_garden_view.show_event_result(EventSelectionResult.invalid_input())
		return

	if (
		not app.is_session_bootstrapped()
		or app.get_content_bootstrap_status() != AppRoot.ContentBootstrapStatus.READY
		or not app.has_active_session()
	):
		if _garden_view != null:
			_garden_view.show_event_result(EventSelectionResult.invalid_input())
		return

	var result: EventSelectionResult = app.evaluate_event_now()
	if _garden_view != null:
		_garden_view.show_event_result(result)


func _on_garden_decoration_purchase_requested(definition_id: String) -> void:
	var app: AppRoot = _get_effective_app_root()
	if app == null:
		if _garden_view != null:
			_garden_view.show_decoration_purchase_result(DecorationPurchaseCheckpointResult.not_ready())
		return

	if (
		not app.is_session_bootstrapped()
		or app.get_content_bootstrap_status() != AppRoot.ContentBootstrapStatus.READY
		or not app.has_active_session()
	):
		if _garden_view != null:
			_garden_view.show_decoration_purchase_result(DecorationPurchaseCheckpointResult.not_ready())
		return

	var result: DecorationPurchaseCheckpointResult = app.try_purchase_decoration_and_checkpoint(definition_id)
	if _garden_view != null:
		_garden_view.show_decoration_purchase_result(result)
		if result != null and result.is_purchased():
			_garden_view.refresh_from_session()



func _determine_blocked_reason_key(app: AppRoot) -> String:
	var content_status: AppRoot.ContentBootstrapStatus = app.get_content_bootstrap_status()
	if content_status == AppRoot.ContentBootstrapStatus.LOAD_FAILED:
		return "ui.startup.content_load_failed"
	elif content_status == AppRoot.ContentBootstrapStatus.INVALID_DEFINITIONS:
		return "ui.startup.content_invalid_definitions"

	var validation_result: PlantSaveContentValidationResult = app.get_saved_content_validation_result()
	if validation_result != null and not validation_result.is_compatible():
		return "ui.startup.save_incompatible"

	var load_result: LocalSaveLoadResult = app.get_startup_load_result()
	if load_result != null:
		match load_result.get_status():
			LocalSaveLoadResult.INVALID_DATA:
				return "ui.startup.save_corrupt"
			LocalSaveLoadResult.IO_ERROR:
				return "ui.startup.save_io_error"

	return "ui.startup.blocked_generic"


## Pure query for testing: returns child GardenView.
func get_garden_view() -> GardenView:
	_resolve_nodes()
	return _garden_view


## Pure query for testing: returns currently bound/effective AppRoot.
func get_effective_app_root() -> AppRoot:
	return _get_effective_app_root()
