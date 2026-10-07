## run_tests.gd
## Command-line entry point for the Garden native headless test runner.
##
## Usage:
##   godot --headless --path . --script res://tests/run_tests.gd
##
## Exit codes:
##   0  — all registered tests passed
##   1  — one or more tests failed
##
## Design:
##   Suites are registered explicitly in _register_suites().
##   No reflection, no filesystem discovery, no plugin configuration.
##   Keep this file small and obvious.
extends SceneTree

# ── Suite registry ────────────────────────────────────────────────────────────

## Register every test suite here. Add a new suite by appending a new instance.
## Order is deterministic and explicit.
func _register_suites() -> Array[TestSuiteBase]:
	return [
		TestHarnessSmoke.new(),
		TestAppRoot.new(),
		TestLifecycleCoordinator.new(),
		TestGameSession.new(),
		TestGameClock.new(),
		TestRandomSource.new(),
		TestGameState.new(),
		TestEconomyState.new(),
		TestStableContentId.new(),
		TestPlantDefinition.new(),
		TestPlantGrowth.new(),
		TestPlantState.new(),
		TestPlantCollectionState.new(),
		TestGameStateCodec.new(),
		TestLocalSaveRepository.new(),
		TestPersistenceLifecycleIntegration.new(),
		TestContentCatalog.new(),
		TestPlantContentLoader.new(),
	]

# ── Runner ────────────────────────────────────────────────────────────────────

func _init() -> void:
	var suites: Array[TestSuiteBase] = _register_suites()

	var total_passed: int = 0
	var total_failed: int = 0

	print("=== Garden Test Runner ===")

	for suite: TestSuiteBase in suites:
		print("\n--- %s ---" % suite.suite_name)
		suite.run_suite()
		var p: int = suite.passed_count()
		var f: int = suite.failed_count()
		print("    passed: %d  failed: %d" % [p, f])
		total_passed += p
		total_failed += f

	print("\n=== Results: %d passed, %d failed ===" % [total_passed, total_failed])

	if total_failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("PASS")
		quit(0)
