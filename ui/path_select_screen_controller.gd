extends RefCounted

func refresh_path_panel(host, payload: Dictionary, major_data: Dictionary) -> void:
	if not is_instance_valid(host._path_select_panel):
		return
	var visible := bool(payload.get("visible", false))
	host._path_select_panel.visible = visible
	if not visible:
		return

	var theme: Dictionary = host._get_presentation_theme(major_data)
	var accent := Color(theme.get("accent", Color.WHITE))
	var text_color := Color(theme.get("text", Color.WHITE))
	var panel_fill := Color(theme.get("panel", Color(0.12, 0.15, 0.17))).darkened(0.03)
	var alt_fill := Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22)))

	host._apply_panel_style(host._path_select_panel, panel_fill, accent, {"variant": "primary"})
	if is_instance_valid(host._path_select_header_panel):
		host._apply_panel_style(host._path_select_header_panel, alt_fill.lightened(0.01), accent, {"variant": "hero", "tint_strength": 0.70})
	host._apply_panel_style(host._path_select_prompt_panel, alt_fill.lightened(0.02), accent, {"variant": "primary"})
	host._apply_panel_style(host._path_select_info_panel, alt_fill.darkened(0.01), accent, {"variant": "secondary"})
	host._apply_panel_style(host._path_select_map_panel, alt_fill.darkened(0.05), accent, {"variant": "arena"})

	host._path_select_eyebrow_label.text = String(payload.get("eyebrow", "Tournament Draw"))
	host._path_select_question_label.text = String(payload.get("question", "Choose the next round"))
	host._path_select_summary_label.text = String(payload.get("summary", ""))
	host._path_select_info_title_label.text = String(payload.get("info_title", "Open Paths"))
	host._path_select_info_body_label.text = String(payload.get("info_body", ""))
	host._path_select_map_title_label.text = String(payload.get("map_title", "Bracket Routes"))
	host._path_select_node_info_label.text = _build_detail_text(payload)
	host._path_select_hint_label.text = String(payload.get("hint", "Click a highlighted node to continue."))

	host._path_select_eyebrow_label.add_theme_color_override("font_color", accent)
	host._path_select_question_label.add_theme_color_override("font_color", text_color)
	host._path_select_summary_label.add_theme_color_override("font_color", text_color)
	host._path_select_info_title_label.add_theme_color_override("font_color", accent)
	host._path_select_info_body_label.add_theme_color_override("font_color", text_color)
	host._path_select_map_title_label.add_theme_color_override("font_color", accent)
	host._path_select_node_info_label.add_theme_color_override("font_color", text_color)
	host._path_select_hint_label.add_theme_color_override("font_color", text_color)

	host._refresh_checkpoint_header_art(
		host._path_select_header_art,
		"path",
		String(payload.get("header_title", "Route Select")),
		String(payload.get("header_body", "Pick a highlighted node to continue.")),
		theme
	)

	if is_instance_valid(host._path_select_map_view):
		host._path_select_map_view.set_palette(Dictionary(theme.get("map_palette", {})))
		host._path_select_map_view.set_map(
			Array(payload.get("map_nodes", [])),
			payload.get("accessible_node_ids", PackedInt32Array()),
			payload.get("completed_node_ids", PackedInt32Array()),
			int(payload.get("current_node_id", -1))
		)

func refresh_path_detail(host, payload: Dictionary) -> void:
	if not is_instance_valid(host._path_select_panel) or not bool(host._path_select_panel.visible):
		return
	host._path_select_node_info_label.text = _build_detail_text(payload)
	host._path_select_hint_label.text = String(payload.get("hint", "Click a highlighted node to continue."))

func _build_detail_text(payload: Dictionary) -> String:
	var title := String(payload.get("detail_title", "")).strip_edges()
	var body := String(payload.get("detail_body", "")).strip_edges()
	if title == "":
		return body
	if body == "":
		return title
	return "%s\n%s" % [title, body]
