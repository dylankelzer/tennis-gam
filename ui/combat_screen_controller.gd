extends RefCounted

var _sidebar_signature: String = ""

func invalidate_sidebar() -> void:
	_sidebar_signature = ""

func _compute_sidebar_signature(run_state, selected_class, available_class_count: int) -> String:
	var phase := String(run_state.phase)
	var match_sig := ""
	if run_state.active_match != null:
		var battle: Dictionary = run_state.active_match.get_battle_presentation()
		match_sig = "%d|%d|%s|%d" % [
			int(battle.get("turn_number", 0)),
			int(battle.get("point_number", 0)),
			String(battle.get("games_score", "")),
			int(battle.get("rally_pressure", 0)),
		]
	var class_id := String(selected_class.id) if selected_class != null else ""
	return "%s|%s|%s|%d" % [phase, class_id, match_sig, available_class_count]

func refresh_sidebar(host, run_state, combat_hud_presenter, selected_class, available_class_count: int, total_class_count: int, total_acts: int) -> void:
	var sig := _compute_sidebar_signature(run_state, selected_class, available_class_count)
	if sig == _sidebar_signature and _sidebar_signature != "":
		return
	_sidebar_signature = sig
	host._clear_container_preserving_pool(host.hand_buttons, host._hand_button_pool)
	host._refresh_equipment_badges(run_state.active_match)
	host._refresh_launch_panel()
	var payload: Dictionary = combat_hud_presenter.build_combat_panel_payload(
		run_state,
		selected_class,
		available_class_count,
		total_class_count,
		total_acts
	)
	host.hand_scroll.custom_minimum_size = Vector2(0, int(payload.get("hand_min_height", 168)))
	host.combat_header_label.text = String(payload.get("combat_header", ""))
	host.match_summary_label.text = String(payload.get("match_summary", ""))
	host.player_summary_label.text = String(payload.get("player_summary", ""))
	host.enemy_intent_label.text = String(payload.get("enemy_intent", ""))
	host.enemy_summary_label.text = String(payload.get("enemy_summary", ""))
	host.hand_header_label.text = String(payload.get("hand_header", "Hand"))
	match String(payload.get("panel_mode", "placeholder")):
		"hand":
			host._build_hand_buttons()
		"routes":
			host._build_route_buttons()
		_:
			host._add_placeholder(host.hand_buttons, String(payload.get("placeholder_text", "")))

func refresh_stage(host, run_state, major_data: Dictionary, combat_hud_presenter, player_logic_tree, class_database) -> void:
	var active_match = run_state.active_match
	host.combat_stage_panel.visible = active_match != null
	if active_match == null:
		host._reset_point_context_flash_state()
		return

	var theme: Dictionary = host._get_presentation_theme(major_data)
	var logic_tree: Dictionary = player_logic_tree.analyze_turn(active_match)
	var payload: Dictionary = combat_hud_presenter.build_stage_payload(
		active_match,
		run_state.get_major_name(),
		logic_tree,
		host._current_combat_compact_level()
	)
	var battle: Dictionary = Dictionary(payload.get("battle", {}))
	var player_data: Dictionary = Dictionary(battle.get("player", {}))
	var point_context := String(payload.get("point_context", ""))
	var point_context_banner := String(payload.get("point_context_banner", "RALLY LIVE"))
	var point_context_hint := String(payload.get("point_context_hint", ""))
	host._maybe_flash_point_context(point_context)
	host.stage_player_title_label.text = String(payload.get("player_title", "Player"))
	host.stage_player_title_label.tooltip_text = String(payload.get("player_title_full", "Player"))
	host.stage_player_hud_body_label.text = String(payload.get("player_hud_body", ""))
	host.stage_enemy_title_label.text = String(payload.get("enemy_title", "Opponent"))
	host.stage_enemy_title_label.tooltip_text = String(payload.get("enemy_title_full", "Opponent"))
	host.stage_enemy_hud_body_label.text = String(payload.get("enemy_hud_body", ""))
	host.stage_major_label.text = String(payload.get("major_label", ""))
	host.stage_serve_state_label.text = host._format_accessible_point_context_banner(point_context, point_context_banner)
	host.stage_serve_state_panel.tooltip_text = point_context_hint
	host._apply_point_context_badge(theme, point_context)
	host.stage_score_label.text = String(payload.get("score_label", ""))
	host.stage_meta_label.text = String(payload.get("meta_label", ""))
	host.stage_rally_body_label.text = String(payload.get("rally_body", ""))
	host.stage_flow_body_label.text = String(payload.get("flow_body", ""))
	host.stage_intent_body_label.text = String(payload.get("intent_body", ""))
	host.stage_player_pod_title_label.text = String(payload.get("player_pod_title", "You"))
	host.stage_player_pod_title_label.tooltip_text = String(payload.get("player_pod_title_full", "You"))
	host.stage_player_pod_body_label.text = String(payload.get("player_pod_body", ""))
	host.stage_enemy_pod_title_label.text = String(payload.get("enemy_pod_title", "Opponent"))
	host.stage_enemy_pod_title_label.tooltip_text = String(payload.get("enemy_pod_title_full", "Opponent"))
	host.stage_enemy_pod_body_label.text = String(payload.get("enemy_pod_body", ""))
	if host.stage_stamina_title_label != null:
		host.stage_stamina_title_label.text = String(payload.get("stamina_title", "Endurance"))
	host.stage_stamina_value_label.text = String(payload.get("stamina_label", "0 / 0"))
	host._refresh_status_row(host.stage_player_status_row, payload.get("player_statuses", PackedStringArray()), theme)
	host._refresh_status_row(host.stage_enemy_status_row, payload.get("enemy_statuses", PackedStringArray()), theme, true)
	host.stage_stamina_hint_label.text = String(payload.get("stamina_hint", ""))
	host.stage_hand_title_label.text = String(payload.get("hand_title", "Hand"))
	host.stage_turn_hint_label.text = String(payload.get("turn_hint", ""))
	host.stage_turn_hint_label.tooltip_text = String(payload.get("turn_hint_tooltip", ""))
	host.stage_event_feed_label.text = String(payload.get("event_feed", ""))
	host.stage_flow_panel.visible = false
	host.stage_rally_panel.visible = false
	host.stage_player_pod.visible = false
	host.stage_enemy_pod.visible = false
	host.stage_arena_bottom_row.visible = false
	var stage_top_spacer = host.get_node_or_null("MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaTopRow/StageArenaTopSpacer")
	if stage_top_spacer != null:
		stage_top_spacer.visible = false
	var stage_top_spacer_2 = host.get_node_or_null("MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaTopRow/StageArenaTopSpacer2")
	if stage_top_spacer_2 != null:
		stage_top_spacer_2.visible = false
	if host.stage_player_portrait.has_method("apply_subject"):
		var player_class = class_database.get_player_class(StringName(String(battle.get("player_class_id", ""))))
		host.stage_player_portrait.call("apply_subject", host._build_class_asset_subject(player_class, true))
	if host.stage_enemy_portrait.has_method("apply_subject"):
		host.stage_enemy_portrait.call("apply_subject", host._build_enemy_asset_subject(battle, theme))
	if host.stage_pressure_meter.has_method("apply_meter"):
		var track_texture: Texture2D = null
		var ball_texture: Texture2D = null
		var palette: Dictionary = {}
		if host.theme_manager != null:
			if host.theme_manager.has_method("get_palette"):
				palette = host.theme_manager.call("get_palette")
			if host.theme_manager.has_method("get_texture"):
				track_texture = host.theme_manager.call("get_texture", "base", "panel_secondary")
			if host.theme_manager.has_method("get_icon_texture"):
				ball_texture = host.theme_manager.call("get_icon_texture", "ball")
		var player_pressure_color := Color(palette.get("primary", theme.get("accent", Color(0.30, 0.82, 1.0))))
		var enemy_pressure_color := Color(palette.get("impact", Color(0.92, 0.48, 0.24)))
		host.stage_pressure_meter.call("apply_meter", {
			"mode": "centered",
			"value": float(int(battle.get("rally_pressure", 0))),
			"min": -float(int(battle.get("rally_pressure_max", 100))),
			"max": float(int(battle.get("rally_pressure_max", 100))),
			"left_color": player_pressure_color,
			"right_color": enemy_pressure_color,
			"frame_color": Color(theme.get("border", Color.WHITE)),
			"track_color": Color(theme.get("panel", Color(0.12, 0.15, 0.17))),
			"track_texture": track_texture,
			"ball_texture": ball_texture,
			"left_label": "YOU",
			"right_label": "OPP",
		})
	if host.stage_stamina_meter.has_method("apply_meter"):
		host.stage_stamina_meter.call("apply_meter", {
			"mode": "fill",
			"value": float(int(player_data.get("condition", 0))),
			"min": 0.0,
			"max": float(maxi(1, int(player_data.get("max_condition", 1)))),
			"left_color": Color(0.32, 0.45, 0.18, 1.0),
			"right_color": Color(0.76, 0.90, 0.34, 1.0),
			"frame_color": Color(theme.get("border", Color.WHITE)),
			"track_color": Color(theme.get("panel", Color(0.12, 0.15, 0.17))),
		})
	host._build_hand_buttons_into(host.stage_hand_buttons, true)
	if host.stage_arena_view.has_method("apply_arena_theme"):
		host.stage_arena_view.call("apply_arena_theme", theme)
	if host.stage_arena_view.has_method("set_presentation"):
		host.stage_arena_view.call("set_presentation", battle)
	host._refresh_stage_perf_panel(theme, battle)

func refresh_potion_rows(host, run_state, major_data: Dictionary) -> void:
	if not is_instance_valid(host._combat_potion_panel) or not is_instance_valid(host._stage_potion_panel):
		return
	var active_match = run_state.active_match
	var show_rows := active_match != null
	host._combat_potion_panel.visible = show_rows
	host._stage_potion_panel.visible = show_rows
	if not show_rows:
		host._hide_pooled_controls(host._combat_potion_button_pool)
		host._hide_pooled_controls(host._stage_potion_button_pool)
		return
	var potions: Array = active_match.call("get_potion_display")
	if potions.is_empty():
		host._combat_potion_panel.visible = false
		host._stage_potion_panel.visible = false
		host._hide_pooled_controls(host._combat_potion_button_pool)
		host._hide_pooled_controls(host._stage_potion_button_pool)
		return
	var theme: Dictionary = host._get_presentation_theme(major_data)
	var accent := Color(theme.get("accent", Color(0.72, 0.88, 1.0)))
	var fill := Color(theme.get("panel_alt", Color(0.16, 0.20, 0.24))).darkened(0.08)
	var text_color := Color(theme.get("text", Color.WHITE))
	host._apply_panel_style(host._combat_potion_panel, fill, accent, {"variant": "chip"})
	host._apply_panel_style(host._stage_potion_panel, fill, accent, {"variant": "chip"})
	host._combat_potion_title_label.text = "Potions"
	host._stage_potion_title_label.text = "Potions"
	host._combat_potion_title_label.add_theme_color_override("font_color", accent)
	host._stage_potion_title_label.add_theme_color_override("font_color", accent)
	host._sync_potion_buttons(host._combat_potion_buttons, host._combat_potion_button_pool, potions, accent, text_color, false)
	host._sync_potion_buttons(host._stage_potion_buttons, host._stage_potion_button_pool, potions, accent, text_color, true)
