extends RefCounted

func apply_major_presentation(host, run_state, major_data: Dictionary) -> void:
	var theme: Dictionary = host._get_presentation_theme(major_data)
	var text_color: Color = Color(theme.get("text", Color.WHITE))
	var accent: Color = Color(theme.get("accent", Color.WHITE))
	var surface_key := String(major_data.get("surface_key", "hardcourt"))

	if host.backdrop != null and host.backdrop.has_method("apply_backdrop_theme"):
		host.backdrop.call("apply_backdrop_theme", theme, run_state.phase == "idle")
		if host.theme_manager != null and host.theme_manager.has_method("get_background_texture") and host.backdrop.has_method("set_surface_texture"):
			host.backdrop.call("set_surface_texture", host.theme_manager.call("get_background_texture", surface_key))
	else:
		host.backdrop.color = Color(theme.get("background", Color(0.08, 0.11, 0.12)))

	_apply_text_styles(host, text_color, accent)
	_apply_panel_styles(host, theme, accent)
	_apply_button_styles(host, accent)
	_apply_icon_palettes(host, accent, text_color)

	host.atmosphere_panel.visible = run_state.phase != "idle"
	host.atmosphere_label.text = _build_atmosphere_text(host, major_data, theme)
	host.map_view.call("set_palette", Dictionary(theme.get("map_palette", {})))

func _apply_text_styles(host, text_color: Color, accent: Color) -> void:
	host.title_label.add_theme_color_override("font_color", accent)
	host.subtitle_label.add_theme_color_override("font_color", text_color)
	host.landing_start_button.add_theme_font_size_override("font_size", 26)
	host.class_name_label.add_theme_color_override("font_color", accent)
	host.map_title_label.add_theme_color_override("font_color", accent)
	host.combat_header_label.add_theme_color_override("font_color", accent)
	host.reward_header_label.add_theme_color_override("font_color", accent)
	if is_instance_valid(host._equipment_bonus_title_label):
		host._equipment_bonus_title_label.add_theme_color_override("font_color", accent)
	if is_instance_valid(host._equipment_bonus_body_label):
		host._equipment_bonus_body_label.add_theme_color_override("font_color", text_color)
	host.run_status_label.add_theme_color_override("font_color", text_color)
	host.action_callout_label.add_theme_color_override("font_color", text_color)
	host.stage_player_title_label.add_theme_color_override("font_color", accent)
	host.stage_player_hud_body_label.add_theme_color_override("font_color", text_color)
	host.stage_major_label.add_theme_color_override("font_color", accent)
	host.stage_serve_state_label.add_theme_color_override("font_color", text_color)
	host.stage_score_label.add_theme_color_override("font_color", text_color)
	host.stage_meta_label.add_theme_color_override("font_color", text_color)
	host.stage_enemy_title_label.add_theme_color_override("font_color", accent)
	host.stage_enemy_hud_body_label.add_theme_color_override("font_color", text_color)
	host.stage_flow_body_label.add_theme_color_override("font_color", text_color)
	host.stage_rally_body_label.add_theme_color_override("font_color", text_color)
	host.stage_intent_body_label.add_theme_color_override("font_color", text_color)
	host.stage_player_pod_title_label.add_theme_color_override("font_color", accent)
	host.stage_player_pod_body_label.add_theme_color_override("font_color", text_color)
	host.stage_enemy_pod_title_label.add_theme_color_override("font_color", accent)
	host.stage_enemy_pod_body_label.add_theme_color_override("font_color", text_color)
	host.stage_stamina_value_label.add_theme_color_override("font_color", accent)
	host.stage_stamina_hint_label.add_theme_color_override("font_color", text_color)
	host.stage_hand_title_label.add_theme_color_override("font_color", accent)
	host.stage_turn_hint_label.add_theme_color_override("font_color", text_color)
	host.rest_eyebrow_label.add_theme_color_override("font_color", accent)
	host.rest_question_label.add_theme_color_override("font_color", text_color)
	host.rest_summary_label.add_theme_color_override("font_color", text_color)
	host.rest_ledger_title_label.add_theme_color_override("font_color", accent)
	host.rest_ledger_body_label.add_theme_color_override("font_color", text_color)
	host.rest_hint_label.add_theme_color_override("font_color", text_color)
	if is_instance_valid(host._shop_eyebrow_label):
		host._shop_eyebrow_label.add_theme_color_override("font_color", accent)
	if is_instance_valid(host._shop_question_label):
		host._shop_question_label.add_theme_color_override("font_color", text_color)
	if is_instance_valid(host._shop_summary_label):
		host._shop_summary_label.add_theme_color_override("font_color", text_color)
	if is_instance_valid(host._shop_ledger_title_label):
		host._shop_ledger_title_label.add_theme_color_override("font_color", accent)
	if is_instance_valid(host._shop_ledger_body_label):
		host._shop_ledger_body_label.add_theme_color_override("font_color", text_color)
	if is_instance_valid(host._shop_market_title_label):
		host._shop_market_title_label.add_theme_color_override("font_color", accent)
	if is_instance_valid(host._shop_hint_label):
		host._shop_hint_label.add_theme_color_override("font_color", text_color)
	host.node_info_label.add_theme_color_override("font_color", text_color)
	host.match_summary_label.add_theme_color_override("font_color", text_color)
	host.launch_title_label.add_theme_color_override("font_color", accent)
	host.launch_body_label.add_theme_color_override("font_color", text_color)
	host.player_summary_label.add_theme_color_override("font_color", text_color)
	host.enemy_intent_label.add_theme_color_override("font_color", text_color)
	host.enemy_summary_label.add_theme_color_override("font_color", text_color)
	host.atmosphere_label.add_theme_color_override("font_color", text_color)
	host.class_view.add_theme_color_override("default_color", text_color)
	host.log_view.add_theme_color_override("default_color", text_color)

func _panel_options(variant: String, tint_strength: float = -1.0) -> Dictionary:
	var options := {"variant": variant}
	if tint_strength >= 0.0:
		options["tint_strength"] = tint_strength
	return options

func _apply_panel_styles(host, theme: Dictionary, accent: Color) -> void:
	host._apply_panel_style(host.atmosphere_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))), accent, _panel_options("subtle"))
	host._apply_panel_style(host.landing_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).lightened(0.06), accent, _panel_options("hero", 0.70))
	host._apply_panel_style(host.reveal_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))), accent, _panel_options("hero", 0.72))
	host._apply_panel_style(host.action_callout_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).lightened(0.03), accent, _panel_options("hero", 0.72))
	host._apply_panel_style(host.combat_stage_panel, Color(theme.get("panel", Color(0.12, 0.15, 0.17))).darkened(0.05), accent, _panel_options("primary"))
	host._apply_panel_style(host.rest_checkpoint_panel, Color(theme.get("panel", Color(0.12, 0.15, 0.17))).darkened(0.03), accent, _panel_options("primary"))
	if is_instance_valid(host._rest_header_panel):
		host._apply_panel_style(host._rest_header_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).lightened(0.01), accent, _panel_options("hero", 0.70))
	host._apply_panel_style(host.rest_prompt_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).lightened(0.02), accent, _panel_options("primary"))
	host._apply_panel_style(host.rest_ledger_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.01), accent, _panel_options("secondary"))
	host._apply_panel_style(host.rest_scene_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.08), accent, _panel_options("arena"))
	if is_instance_valid(host._shop_checkpoint_panel):
		host._apply_panel_style(host._shop_checkpoint_panel, Color(theme.get("panel", Color(0.12, 0.15, 0.17))).darkened(0.03), accent, _panel_options("primary"))
	if is_instance_valid(host._shop_header_panel):
		host._apply_panel_style(host._shop_header_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).lightened(0.01), accent, _panel_options("hero", 0.70))
	if is_instance_valid(host._shop_prompt_panel):
		host._apply_panel_style(host._shop_prompt_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).lightened(0.02), accent, _panel_options("primary"))
	if is_instance_valid(host._shop_ledger_panel):
		host._apply_panel_style(host._shop_ledger_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.01), accent, _panel_options("secondary"))
	if is_instance_valid(host._shop_market_panel):
		host._apply_panel_style(host._shop_market_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.05), accent, _panel_options("secondary"))
	if is_instance_valid(host._reward_checkpoint_panel):
		host._apply_panel_style(host._reward_checkpoint_panel, Color(theme.get("panel", Color(0.12, 0.15, 0.17))).darkened(0.03), accent, _panel_options("primary"))
	if is_instance_valid(host._reward_header_panel):
		host._apply_panel_style(host._reward_header_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).lightened(0.01), accent, _panel_options("hero", 0.70))
	host._apply_panel_style(host.stage_player_hud, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))), accent, _panel_options("secondary"))
	host._apply_panel_style(host.stage_score_hud, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).lightened(0.04), accent, _panel_options("hero", 0.72))
	host._apply_panel_style(host.stage_serve_state_panel, Color(theme.get("panel", Color(0.12, 0.15, 0.17))).lightened(0.04), accent.lightened(0.12), _panel_options("hero", 0.68))
	host._apply_panel_style(host.stage_enemy_hud, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))), accent, _panel_options("secondary"))
	host._apply_panel_style(host.stage_string_badge_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.01), accent, _panel_options("chip"))
	host._apply_panel_style(host.stage_racquet_badge_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.01), accent, _panel_options("chip"))
	host._apply_panel_style(host.stage_arena_panel, Color(theme.get("panel", Color(0.12, 0.15, 0.17))).darkened(0.10), accent, _panel_options("arena"))
	host._apply_panel_style(host.stage_flow_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.03), accent, _panel_options("secondary"))
	host._apply_panel_style(host.stage_rally_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.03), accent, _panel_options("secondary"))
	host._apply_panel_style(host.stage_intent_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.03), accent, _panel_options("secondary"))
	host._apply_panel_style(host.stage_player_pod, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.03), accent, _panel_options("secondary"))
	host._apply_panel_style(host.stage_enemy_pod, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.03), accent, _panel_options("secondary"))
	host._apply_panel_style(host.stage_stamina_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))), accent, _panel_options("secondary"))
	host._apply_panel_style(host.stage_hand_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).lightened(0.02), accent, _panel_options("secondary"))
	host._apply_panel_style(host.stage_action_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))), accent, _panel_options("secondary"))
	host._apply_panel_style(host.run_status_panel, Color(theme.get("panel", Color(0.12, 0.15, 0.17))), accent, _panel_options("secondary"))
	host._apply_panel_style(host.class_panel, Color(theme.get("panel", Color(0.12, 0.15, 0.17))), accent, _panel_options("secondary"))
	host._apply_panel_style(host.map_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))), accent, _panel_options("secondary"))
	host._apply_panel_style(host.combat_panel, Color(theme.get("panel", Color(0.12, 0.15, 0.17))), accent, _panel_options("secondary"))
	host._apply_panel_style(host.launch_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))), accent, _panel_options("hero", 0.72))
	host._apply_panel_style(host.log_panel, Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))), accent, _panel_options("secondary"))

func _apply_button_styles(host, accent: Color) -> void:
	var shadow_text := Color(0.07, 0.09, 0.10)
	host._apply_button_style(host.prev_button, accent.darkened(0.08), accent.darkened(0.30), shadow_text)
	host._apply_button_style(host.next_button, accent.darkened(0.08), accent.darkened(0.30), shadow_text)
	host._apply_button_style(host.start_run_button, accent.lightened(0.02), accent.darkened(0.28), shadow_text)
	host._apply_button_style(host.continue_run_button, accent.lightened(0.02), accent.darkened(0.28), shadow_text)
	host._apply_button_style(host.reset_run_button, accent.darkened(0.06), accent.darkened(0.32), shadow_text)
	host._apply_button_style(host.launch_start_button, accent.lightened(0.02), accent.darkened(0.24), shadow_text)
	host._apply_button_style(host.launch_continue_button, accent.lightened(0.02), accent.darkened(0.24), shadow_text)
	host._apply_button_style(host.end_turn_button, accent.lightened(0.05), accent.darkened(0.24), shadow_text)
	host._apply_button_style(host.landing_start_button, accent, accent.darkened(0.28), shadow_text)
	host._apply_button_style(host.reveal_proceed_button, accent, accent.darkened(0.28), shadow_text)
	host._apply_button_style(host.dismiss_reveal_button, accent.darkened(0.04), accent.darkened(0.28), shadow_text)
	host._apply_button_style(host.primary_action_button, accent, accent.darkened(0.28), shadow_text)
	host._apply_button_style(host._accessibility_button, accent.lightened(0.04), accent.darkened(0.28), shadow_text)
	host._apply_button_style(host.rest_leave_button, accent.lightened(0.02), accent.darkened(0.24), shadow_text)
	if is_instance_valid(host._shop_leave_button):
		host._apply_button_style(host._shop_leave_button, accent.lightened(0.02), accent.darkened(0.24), shadow_text)
	host._apply_button_style(host.stage_end_turn_button, accent.lightened(0.05), accent.darkened(0.20), shadow_text)

func _apply_icon_palettes(host, accent: Color, text_color: Color) -> void:
	if host.landing_ball_icon.has_method("set_palette"):
		host.landing_ball_icon.call("set_palette", accent, text_color)
	if host.theme_manager != null and host.theme_manager.has_method("get_icon_texture") and host.landing_ball_icon.has_method("set_icon_texture"):
		host.landing_ball_icon.call("set_icon_texture", host.theme_manager.call("get_icon_texture", "ball"))
	if host.landing_racquet_icon.has_method("set_palette"):
		host.landing_racquet_icon.call("set_palette", text_color, accent)
	if host.landing_trophy_icon.has_method("set_palette"):
		host.landing_trophy_icon.call("set_palette", accent.lightened(0.1), text_color)
	if host.action_callout_icon.has_method("set_palette"):
		host.action_callout_icon.call("set_palette", accent, text_color)

func _build_atmosphere_text(host, major_data: Dictionary, theme: Dictionary) -> String:
	if major_data.is_empty():
		return "Select a class and start a run to light up the tournament presentation."
	var featured_field: Array = Array(major_data.get("featured_field", []))
	var featured_preview := PackedStringArray()
	for index in range(mini(2, featured_field.size())):
		var entry: Dictionary = featured_field[index]
		featured_preview.append("#%d %s" % [int(entry.get("seed", 0)), String(entry.get("name", "Contender"))])
	var final_rule: Dictionary = Dictionary(major_data.get("final_rule", {}))
	return "%s | %s\nCourt Effect: %s\nAmbience: %s\nFeatured: %s\nFinal Twist: %s" % [
		String(major_data.get("name", "Major")),
		String(major_data.get("surface", "Court")),
		String(major_data.get("surface_rule_text", "No surface modifier.")),
		String(theme.get("ambient", "")),
		host._join_strings(featured_preview) if not featured_preview.is_empty() else "Field still settling",
		String(final_rule.get("name", "Final Rule")),
	]
