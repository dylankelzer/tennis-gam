extends RefCounted

const BadgeIconScript = preload("res://scripts/ui/badge_icon.gd")

func refresh_class_showcase(host, selected_class) -> void:
	if not is_instance_valid(host._class_showcase_panel):
		return

	var class_id := String(selected_class.id) if selected_class != null else "novice"
	var class_theme := Dictionary(host.CLASS_ASSET_THEMES.get(class_id, host.CLASS_ASSET_THEMES["novice"]))
	var accent := Color(class_theme.get("accent", Color(0.84, 0.90, 0.98)))
	var frame := Color(class_theme.get("frame", Color.WHITE))
	var inner := Color(class_theme.get("inner", Color(0.12, 0.15, 0.22)))
	var fill := inner.lerp(accent, 0.10)
	host._apply_panel_style(host._class_showcase_panel, fill, frame.lerp(accent, 0.35), {"variant": "hero", "tint_strength": 0.70})

	if host._class_showcase_portrait != null and host._class_showcase_portrait.has_method("apply_subject"):
		host._class_showcase_portrait.call("apply_subject", host._build_class_asset_subject(selected_class))

	if selected_class == null:
		host._class_showcase_name_label.text = "No Class"
		host._class_showcase_subtitle_label.text = "Browse the roster"
		host._class_showcase_meta_label.text = "Pick a class to review its passive, stat line, and opening package."
		host._clear_container(host._class_showcase_chip_row)
		return

	host._class_showcase_name_label.text = String(selected_class.name)
	host._class_showcase_name_label.add_theme_color_override("font_color", frame)
	host._class_showcase_subtitle_label.text = "%s • %s" % [String(selected_class.archetype), String(selected_class.passive_name)]
	host._class_showcase_subtitle_label.add_theme_color_override("font_color", accent.lightened(0.10))
	host._class_showcase_meta_label.text = _build_class_showcase_meta(selected_class)
	host._class_showcase_meta_label.add_theme_color_override("font_color", frame.lerp(fill, 0.18))

	host._clear_container(host._class_showcase_chip_row)
	var stats: Dictionary = Dictionary(selected_class.base_stats)
	var chip_specs := [
		{"icon": "stamina", "label": "Sta %d" % int(stats.get("stamina", 0))},
		{"icon": "pressure", "label": "End %d" % int(stats.get("endurance", 0))},
		{"icon": "focus", "label": "Ctl %d" % int(stats.get("control", 0))},
		{"icon": "momentum", "label": "Foot %d" % int(stats.get("footwork", 0))},
	]
	for chip_spec in chip_specs:
		host._class_showcase_chip_row.add_child(_build_class_showcase_chip(
			host,
			String(chip_spec.get("label", "")),
			String(chip_spec.get("icon", "ball")),
			fill.darkened(0.06),
			accent,
			frame
		))

func refresh_selection(host, selected_class) -> void:
	var subject: Dictionary = host._build_class_asset_subject(selected_class)
	if host.landing_portrait != null and host.landing_portrait.has_method("apply_subject"):
		host.landing_portrait.call("apply_subject", subject)
	if host.class_portrait != null and host.class_portrait.has_method("apply_subject"):
		host.class_portrait.call("apply_subject", subject)
	refresh_class_showcase(host, selected_class)

func refresh_primary_action(host, run_state, front_screen_mode: String, selected_class, has_saved_run: bool, presenter) -> void:
	var payload: Dictionary = presenter.build_primary_action_payload(run_state, front_screen_mode, selected_class, has_saved_run) if presenter != null else {}
	host.action_callout_panel.visible = bool(payload.get("callout_visible", false))
	host.action_callout_label.text = String(payload.get("callout_text", ""))
	host.primary_action_button.visible = bool(payload.get("primary_visible", true))
	host.primary_action_button.text = String(payload.get("primary_text", "Start Run"))
	host.primary_action_button.disabled = bool(payload.get("primary_disabled", false))
	if host.action_callout_icon.has_method("set"):
		host.action_callout_icon.set("icon_kind", String(payload.get("icon_kind", "racquet")))

func configure_reveal_actions(host, run_state, presenter) -> void:
	var payload: Dictionary = presenter.build_reveal_action_payload(run_state) if presenter != null else {}
	host.reveal_proceed_button.visible = bool(payload.get("proceed_visible", false))
	host.reveal_proceed_button.text = String(payload.get("proceed_text", ""))
	host.dismiss_reveal_button.text = String(payload.get("dismiss_text", "Close Reveal"))

func refresh_launch_panel(host, run_state, front_screen_mode: String, selected_class, has_saved_run: bool, presenter) -> void:
	var payload: Dictionary = presenter.build_launch_payload(run_state, front_screen_mode, selected_class, has_saved_run) if presenter != null else {}
	host.launch_panel.visible = bool(payload.get("show_launch_panel", false))
	if not host.launch_panel.visible:
		return
	host.launch_title_label.text = String(payload.get("title", "Choose Your Class"))
	host.launch_body_label.text = String(payload.get("body", ""))
	host.launch_start_button.text = String(payload.get("start_text", "Begin Tournament"))
	host.launch_continue_button.visible = bool(payload.get("show_continue", has_saved_run))

func _build_class_showcase_meta(selected_class) -> String:
	var signature_preview := PackedStringArray()
	for shot_name in Array(selected_class.signature_shots).slice(0, 3):
		signature_preview.append(String(shot_name))
	var signatures := _join_strings(signature_preview) if not signature_preview.is_empty() else "Tour fundamentals"
	return "%s\nSignatures: %s" % [String(selected_class.summary), signatures]

func _build_class_showcase_chip(
	host,
	text: String,
	icon_kind: String,
	fill_color: Color,
	border_color: Color,
	text_color: Color
) -> PanelContainer:
	var panel := PanelContainer.new()
	host._apply_panel_style(panel, fill_color, border_color, {"variant": "chip", "tint_strength": 0.64})
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)
	var icon: Control = BadgeIconScript.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.icon_kind = icon_kind
	icon.set_palette(border_color, text_color)
	if host.theme_manager != null and host.theme_manager.has_method("get_icon_texture") and icon.has_method("set_icon_texture"):
		icon.call("set_icon_texture", host.theme_manager.call("get_icon_texture", icon_kind))
	row.add_child(icon)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", text_color)
	row.add_child(label)
	return panel

func _join_strings(parts: PackedStringArray) -> String:
	if parts.is_empty():
		return ""
	if parts.size() == 1:
		return parts[0]
	if parts.size() == 2:
		return "%s and %s" % [parts[0], parts[1]]
	var values := parts.duplicate()
	var tail := values[values.size() - 1]
	values.remove_at(values.size() - 1)
	return "%s, and %s" % [", ".join(values), tail]
