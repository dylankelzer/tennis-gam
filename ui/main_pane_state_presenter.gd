extends RefCounted

const FRONT_SCREEN_CLASS_SELECT := "class_select"
const FRONT_SCREEN_TRANSITION := "transition"

var _cached_result: Dictionary = {}
var _cached_key: String = ""

func classify_reward_menu(phase: String, reward_choices: Array) -> String:
	if phase != "reward" or reward_choices.is_empty():
		return ""
	var saw_rest := false
	var saw_shop := false
	var saw_relic := false
	var saw_trim := false
	for choice in reward_choices:
		var reward_type := String(Dictionary(choice).get("reward_type", "card"))
		if reward_type in ["rest_heal", "rest_endurance", "rest_focus"]:
			saw_rest = true
		elif reward_type in ["shop_card", "shop_potion", "shop_relic", "shop_remove", "card_upgrade", "racquet_upgrade"]:
			saw_shop = true
		elif reward_type == "deck_trim":
			saw_trim = true
		elif reward_type == "relic":
			saw_relic = true
	if saw_trim and not saw_shop and not saw_rest and not saw_relic:
		return "trim"
	if saw_rest and not saw_shop and not saw_relic:
		return "rest"
	if saw_shop and not saw_rest and not saw_relic:
		return "shop"
	if saw_relic:
		return "relic"
	return "draft"

func invalidate() -> void:
	_cached_key = ""

func build(run_state, front_screen_mode: String) -> Dictionary:
	var phase := String(run_state.phase)
	var has_match := run_state.active_match != null
	var has_reveal := run_state.has_reveal()
	var completed_empty := run_state.completed_node_ids.is_empty()
	var accessible_count := int(run_state.accessible_node_ids.size()) if phase == "map" else 0
	var reward_count := int(run_state.get_reward_choices().size())
	var key := "%s|%s|%d|%d|%d|%d|%d" % [phase, front_screen_mode, int(has_match), int(has_reveal), int(completed_empty), accessible_count, reward_count]
	if key == _cached_key and not _cached_result.is_empty():
		return _cached_result
	_cached_key = key
	var reward_menu_kind := classify_reward_menu(phase, run_state.get_reward_choices())
	var is_idle := phase == "idle"
	var is_class_select_screen := is_idle and front_screen_mode == FRONT_SCREEN_CLASS_SELECT
	var is_transition_screen := is_idle and front_screen_mode == FRONT_SCREEN_TRANSITION
	var is_landing_screen := is_idle and not is_class_select_screen and not is_transition_screen
	var is_live_combat := run_state.active_match != null
	var is_rest_checkpoint := reward_menu_kind == "rest"
	var is_shop_checkpoint := reward_menu_kind == "shop"
	var is_reward_checkpoint := phase == "reward" and reward_menu_kind not in ["", "rest", "shop"]
	var is_path_select_screen: bool = phase == "map" and not run_state.completed_node_ids.is_empty() and not run_state.has_reveal()
	var is_fullscreen_checkpoint: bool = is_rest_checkpoint or is_shop_checkpoint or is_reward_checkpoint
	var is_fullscreen_flow_screen: bool = is_fullscreen_checkpoint or is_path_select_screen
	var map_accessible := PackedInt32Array()
	if phase == "map":
		map_accessible = run_state.accessible_node_ids
	var result := {
		"phase": phase,
		"reward_menu_kind": reward_menu_kind,
		"is_idle": is_idle,
		"is_class_select_screen": is_class_select_screen,
		"is_transition_screen": is_transition_screen,
		"is_landing_screen": is_landing_screen,
		"is_live_combat": is_live_combat,
		"is_rest_checkpoint": is_rest_checkpoint,
		"is_shop_checkpoint": is_shop_checkpoint,
		"is_reward_checkpoint": is_reward_checkpoint,
		"is_path_select_screen": is_path_select_screen,
		"is_fullscreen_checkpoint": is_fullscreen_checkpoint,
		"is_fullscreen_flow_screen": is_fullscreen_flow_screen,
		"show_header_box": (not is_live_combat) and (not is_fullscreen_flow_screen),
		"show_top_bar": (is_class_select_screen or (not is_idle)) and (not is_live_combat) and (not is_fullscreen_flow_screen) and (not is_transition_screen),
		"show_body_split": (is_class_select_screen or (not is_idle)) and (not is_live_combat) and (not is_fullscreen_flow_screen) and (not is_transition_screen),
		"show_subtitle": (is_class_select_screen or (not is_idle)) and (not is_live_combat) and (not is_fullscreen_flow_screen) and (not is_transition_screen),
		"show_reveal_panel": (not is_idle) and run_state.has_reveal() and (not is_fullscreen_flow_screen),
		"map_accessible": map_accessible,
	}
	_cached_result = result
	return result
