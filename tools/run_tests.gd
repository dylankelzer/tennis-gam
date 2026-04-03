extends SceneTree

const TEST_SCRIPTS := [
	"res://scripts/tests/content_validator_smoke.gd",
	"res://scripts/tests/content_validator_failure_smoke.gd",
	"res://scripts/tests/reference_path_validator_smoke.gd",
	"res://scripts/tests/reference_path_validator_failure_smoke.gd",
	"res://scripts/tests/telemetry_smoke.gd",
	"res://scripts/tests/accessibility_settings_smoke.gd",
	"res://scripts/tests/theme_manager_smoke.gd",
	"res://scripts/tests/main_ui_text_builder_smoke.gd",
	"res://scripts/tests/front_screen_controller_smoke.gd",
	"res://scripts/tests/main_theme_controller_smoke.gd",
	"res://scripts/tests/meta_sidebar_controller_smoke.gd",
	"res://scripts/tests/combat_hud_presenter_smoke.gd",
	"res://scripts/tests/combat_arena_view_orientation_smoke.gd",
	"res://scripts/tests/unit_view_smoke.gd",
	"res://scripts/tests/fx_root_smoke.gd",
	"res://scripts/tests/stage_visual_presentation_smoke.gd",
	"res://scripts/tests/victory_axis_ui_smoke.gd",
	"res://scripts/tests/endurance_attrition_smoke.gd",
	"res://scripts/tests/combat_ui_pooling_smoke.gd",
	"res://scripts/tests/tennis_score_rules_smoke.gd",
	"res://scripts/tests/deterministic_combat_smoke.gd",
	"res://scripts/tests/enemy_ai_closeout_bias_smoke.gd",
	"res://scripts/tests/match_state_architecture_smoke.gd",
	"res://scripts/tests/match_state_tennis_patterns_smoke.gd",
	"res://scripts/tests/player_card_logic_tree_smoke.gd",
	"res://scripts/tests/return_relic_identity_smoke.gd",
	"res://scripts/tests/main_flow_smoke.gd",
	"res://scripts/tests/pane_transition_smoke.gd",
	"res://scripts/tests/path_select_screen_smoke.gd",
]

func _initialize() -> void:
	var executable := OS.get_executable_path()
	var project_path := ProjectSettings.globalize_path("res://")
	var failed := false
	for test_script in TEST_SCRIPTS:
		var output: Array = []
		var exit_code := OS.execute(
			executable,
			PackedStringArray(["--headless", "--path", project_path, "--script", test_script]),
			output,
			true
		)
		var transcript := "\n".join(PackedStringArray(output))
		print("=== %s ===" % test_script)
		if transcript != "":
			print(transcript)
		if exit_code != 0:
			push_error("Test failed: %s" % test_script)
			failed = true
	if failed:
		push_error("TEST SUITE FAILED")
		quit(1)
		return
	print("TEST SUITE PASS")
	quit(0)
