extends RefCounted

const FRONT_SCREEN_TRANSITION := "transition"
const FRONT_SCREEN_CLASS_SELECT := "class_select"

func build_transition_payload(selected_class) -> Dictionary:
	return {
		"callout_visible": true,
		"callout_text": "Entering the opening round for %s. Building the first match screen..." % String(selected_class.name if selected_class != null else "your class"),
		"icon_kind": "ball",
		"primary_visible": false,
	}

func build_primary_action_payload(run_state, front_screen_mode: String, selected_class, has_saved_run: bool) -> Dictionary:
	var payload := {
		"callout_visible": false,
		"callout_text": "",
		"icon_kind": "racquet",
		"primary_visible": true,
		"primary_text": "Start Run",
		"primary_disabled": false,
	}
	var phase := String(run_state.phase)
	if phase == "idle":
		if front_screen_mode == FRONT_SCREEN_TRANSITION:
			return {
				"callout_visible": true,
				"callout_text": "Locking in the class and loading the opening round.",
				"icon_kind": "ball",
				"primary_visible": false,
				"primary_text": "Start Run",
				"primary_disabled": true,
			}
		payload["callout_text"] = "Ready to step onto the tour."
		payload["primary_text"] = "Start Run"
		payload["primary_disabled"] = selected_class == null
		return payload
	if phase == "map":
		var next_node_id := int(run_state.get_primary_accessible_node_id())
		payload["callout_visible"] = next_node_id >= 0
		payload["callout_text"] = "Next stop: opening route is ready." if int(run_state.current_node_id) < 0 else "Continue the bracket from here."
		payload["primary_text"] = "Play Opening Match" if int(run_state.current_node_id) < 0 else "Play Next Match"
		payload["primary_disabled"] = next_node_id < 0
		payload["icon_kind"] = "ball"
		return payload
	if phase == "reward":
		payload["callout_visible"] = true
		payload["callout_text"] = "Choose a reward or skip to continue the tour."
		payload["primary_text"] = "Skip Reward"
		payload["icon_kind"] = "trophy"
		return payload
	if phase in ["run_won", "run_lost"]:
		payload["callout_visible"] = true
		payload["callout_text"] = "Reset and queue the next run."
		payload["primary_text"] = "Return to Start"
		payload["icon_kind"] = "trophy"
		return payload
	if has_saved_run:
		payload["callout_text"] = "Continue from the last safe checkpoint or start fresh."
	return payload

func build_reveal_action_payload(run_state) -> Dictionary:
	var payload := {
		"proceed_visible": false,
		"proceed_text": "",
		"dismiss_text": "Close Reveal",
	}
	if not run_state.has_reveal():
		return payload
	var phase := String(run_state.phase)
	if phase == "map":
		var next_node_id := int(run_state.get_primary_accessible_node_id())
		if next_node_id >= 0:
			payload["proceed_visible"] = true
			payload["proceed_text"] = "Begin Opening Round" if int(run_state.current_node_id) < 0 else "Play Next Match"
			payload["dismiss_text"] = "View Bracket"
			return payload
	if phase == "combat":
		payload["proceed_visible"] = true
		payload["proceed_text"] = "Play Match"
	return payload

func build_launch_payload(run_state, front_screen_mode: String, selected_class, has_saved_run: bool) -> Dictionary:
	var show_launch_panel := String(run_state.phase) == "idle" and front_screen_mode == FRONT_SCREEN_CLASS_SELECT
	return {
		"show_launch_panel": show_launch_panel,
		"title": "Choose Your Class",
		"body": "Selected class: %s\nReview the passive, starter deck, and visual model on the left. When you are ready, begin the tournament or continue from the last safe checkpoint." % String(selected_class.name if selected_class != null else "None"),
		"start_text": "Begin Tournament",
		"show_continue": has_saved_run,
	}
