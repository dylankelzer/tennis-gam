extends RefCounted

func refresh_overview(
	host,
	run_state,
	selected_class,
	pane_state: Dictionary,
	front_screen_mode: String,
	ui_text_builder,
	progress: Dictionary,
	available_class_count: int,
	total_class_count: int,
	has_saved_run: bool
) -> void:
	var is_idle: bool = bool(pane_state.get("is_idle", run_state.phase == "idle"))
	var is_class_select_screen: bool = bool(pane_state.get("is_class_select_screen", false))
	var map_accessible: PackedInt32Array = pane_state.get("map_accessible", PackedInt32Array())

	host.class_name_label.text = selected_class.name if selected_class != null else "No Class"
	host.class_view.text = ui_text_builder.build_class_text(selected_class, is_class_select_screen or not is_idle)
	host.run_status_label.text = ui_text_builder.build_run_status_text(
		run_state,
		progress,
		available_class_count,
		total_class_count,
		has_saved_run,
		front_screen_mode
	)
	host.map_title_label.text = "Class Prep" if is_class_select_screen else ("Tournament Map" if run_state.phase == "idle" else "%s Draw" % run_state.get_major_name())
	host.map_view.set_map(run_state.get_current_map_nodes(), map_accessible, run_state.completed_node_ids, run_state.current_node_id)
	host.node_info_label.text = ui_text_builder.build_node_info_text(run_state, front_screen_mode)

func refresh_log_panel(host, run_state, ui_text_builder, unlock_progression) -> void:
	var major_data: Dictionary = {} if run_state.phase == "idle" else run_state.get_major_data()
	var tournament_block: String = ui_text_builder.build_tournament_log_block(major_data, run_state)
	var potion_block: String = "Potion Belt\n%s" % run_state.get_potion_preview()
	if run_state.active_match != null:
		host.log_view.text = "%s\n\n%s\n\n%s" % [tournament_block, potion_block, run_state.active_match.call("get_log_text")]
		return
	var relic_block: String = "Relic Loadout\n%s" % run_state.get_relic_preview()
	var deck_block: String = "Deck Preview\n%s" % run_state.get_deck_preview()
	if run_state.last_match_log != "":
		var summary_block: String = ""
		if run_state.last_match_summary != "":
			summary_block = "Last Match Summary\n%s\n\n" % run_state.last_match_summary
		host.log_view.text = "%s%s\n\nLast Match Log\n%s\n\n%s\n\n%s\n\n%s" % [summary_block, tournament_block, run_state.last_match_log, potion_block, relic_block, deck_block]
		return
	host.log_view.text = "%s\n\n%s\n\n%s\n\n%s\n\nRun Progression\n%s" % [tournament_block, potion_block, relic_block, deck_block, unlock_progression.describe_unlock_track()]
