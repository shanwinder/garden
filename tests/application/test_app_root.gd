## test_app_root.gd
## Structural test suite for Garden's application composition root (AppRoot).
##
## Verifies:
## 1. AppRoot can be instantiated as the expected Node-based composition root.
## 2. AppRoot composes GameSession which owns a canonical GameState.
## 3. Project has the expected Autoload registration: App -> res://src/application/app_root.gd.
## 4. There is currently only the intended application Autoload.
class_name TestAppRoot
extends TestSuiteBase

func _init() -> void:
	suite_name = "TestAppRoot"


func run_tests() -> void:
	_test_instantiation()
	_test_session_composition()
	_test_autoload_registration()
	_test_no_unapproved_autoloads()


func _test_instantiation() -> void:
	describe("AppRoot instantiates as a Node-based composition root")
	var root: AppRoot = AppRoot.new()
	assert_true(root != null, "AppRoot instance should not be null")
	assert_true(root is Node, "AppRoot must extend Node")
	assert_true(root is AppRoot, "Instance must be of type AppRoot")
	root.free()


func _test_session_composition() -> void:
	describe("AppRoot composes GameSession owning GameState with distinct instances")
	var root_a: AppRoot = AppRoot.new()
	assert_true(root_a.game_session != null, "AppRoot.game_session should not be null")
	assert_true(root_a.game_session is GameSession, "game_session must be of type GameSession")
	assert_true(root_a.game_session.get_state() != null, "game_session.get_state() must not be null")
	assert_true(root_a.game_session.get_state() is GameState, "game_session.get_state() must be of type GameState")

	var root_b: AppRoot = AppRoot.new()
	assert_ne(root_a.game_session, root_b.game_session, "Separate AppRoot instances must not share GameSession")
	assert_ne(
		root_a.game_session.get_state(),
		root_b.game_session.get_state(),
		"Separate AppRoot instances must not share GameState"
	)
	root_a.free()
	root_b.free()


func _test_autoload_registration() -> void:
	describe("Project registers App autoload pointing to res://src/application/app_root.gd")
	assert_true(
		ProjectSettings.has_setting("autoload/App"),
		"ProjectSettings must have 'autoload/App'"
	)
	var setting_value: String = str(ProjectSettings.get_setting("autoload/App"))
	# Godot 4 prefixes autoload paths with '*' when registered as a global singleton.
	var clean_path: String = setting_value.trim_prefix("*")
	assert_eq(
		clean_path,
		"res://src/application/app_root.gd",
		"Autoload 'App' must point to res://src/application/app_root.gd"
	)
	assert_true(
		setting_value.begins_with("*"),
		"Autoload 'App' must be configured as a singleton ('*' prefix)"
	)


func _test_no_unapproved_autoloads() -> void:
	describe("Project has only the single approved application Autoload")
	var autoload_names: Array[String] = []
	for prop: Dictionary in ProjectSettings.get_property_list():
		var prop_name: String = prop.get("name", "")
		if prop_name.begins_with("autoload/"):
			autoload_names.append(prop_name.trim_prefix("autoload/"))

	assert_eq(autoload_names.size(), 1, "There should be exactly 1 autoload configured")
	assert_true("App" in autoload_names, "The configured autoload must be 'App'")
