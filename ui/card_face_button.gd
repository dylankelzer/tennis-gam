class_name CardFaceButton
extends Button

const BadgeIconScript = preload("res://scripts/ui/badge_icon.gd")

const SMALL_SIZE := Vector2(196, 228)
const LARGE_SIZE := Vector2(226, 304)
const LARGE_SIZE_COMPACT_1 := Vector2(214, 286)
const LARGE_SIZE_COMPACT_2 := Vector2(202, 266)
const LARGE_SIZE_COMPACT_3 := Vector2(190, 246)
const REWARD_SIZE := Vector2(220, 244)
const RELIC_SIZE := Vector2(220, 228)
const ROUTE_SIZE := Vector2(232, 156)
const SKIP_SIZE := Vector2(184, 132)
const REST_CHOICE_SIZE := Vector2(236, 198)

static func card_size_for_mode(mode: String, large: bool, compact_level: int) -> Vector2:
	match mode:
		"stage_card":
			match compact_level:
				1: return Vector2(112, 170)
				2: return Vector2(106, 160)
				3: return Vector2(98, 150)
				_: return Vector2(118, 178)
		"reward_card": return REWARD_SIZE
		"relic_reward": return RELIC_SIZE
		"route": return ROUTE_SIZE
		"skip": return SKIP_SIZE
		"rest_choice": return REST_CHOICE_SIZE
		_:
			if large:
				match compact_level:
					1: return LARGE_SIZE_COMPACT_1
					2: return LARGE_SIZE_COMPACT_2
					3: return LARGE_SIZE_COMPACT_3
					_: return LARGE_SIZE
			return SMALL_SIZE

func _text_limit_for_width(base_limit: int) -> int:
	var w := custom_minimum_size.x if custom_minimum_size.x > 0.0 else SMALL_SIZE.x
	var scale := w / SMALL_SIZE.x
	return maxi(20, int(round(float(base_limit) * scale)))

var _payload: Dictionary = {}
var _mode: String = "card"
var _large: bool = false
var _compact_level: int = 0
var _theme: Dictionary = {}
var _palette: Dictionary = {}
var _size_override: Vector2 = Vector2.ZERO
var _hand_fan_mode: bool = false
var _hand_fan_index: int = 0
var _hand_fan_total: int = 0
var _is_hovered: bool = false

var _margin: MarginContainer
var _root: VBoxContainer
var _top_row: HBoxContainer
var _cost_chip_panel: PanelContainer
var _cost_chip_label: Label
var _type_chip_panel: PanelContainer
var _type_chip_label: Label
var _title_label: Label
var _art_panel: PanelContainer
var _art_icon: Control
var _art_label: Label
var _description_label: Label
var _footer_label: Label
var _hover_tween: Tween = null

func _theme_manager():
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return null
	return tree.current_scene.get_node_or_null("ThemeManager")

func _accessibility_settings():
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("AccessibilitySettings")

func _font_scale_factor() -> float:
	var settings = _accessibility_settings()
	if settings != null and settings.has_method("get_font_scale"):
		return float(settings.get_font_scale())
	return 1.0

func _ui_scale_factor() -> float:
	var settings = _accessibility_settings()
	if settings != null and settings.has_method("get_ui_scale"):
		return float(settings.get_ui_scale())
	return 1.0

func _high_contrast_enabled() -> bool:
	var settings = _accessibility_settings()
	if settings != null and settings.has_method("is_high_contrast_enabled"):
		return bool(settings.is_high_contrast_enabled())
	return false

func _reduced_motion_enabled() -> bool:
	var settings = _accessibility_settings()
	if settings != null and settings.has_method("is_reduced_motion_enabled"):
		return bool(settings.is_reduced_motion_enabled())
	return false

func _scaled_font_size(size_value: int) -> int:
	return maxi(9, int(round(float(size_value) * _font_scale_factor())))

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	text = ""
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_hover_entered)
	mouse_exited.connect(_on_hover_exited)
	focus_entered.connect(_on_hover_entered)
	focus_exited.connect(_on_hover_exited)
	_ensure_layout()
	_refresh_visuals()

func set_tile_payload(payload: Dictionary, options: Dictionary = {}) -> void:
	_payload = payload.duplicate(true)
	_mode = String(options.get("mode", "card"))
	_large = bool(options.get("large", false))
	_compact_level = maxi(0, int(options.get("compact_level", 0)))
	_theme = Dictionary(options.get("theme", {}))
	_size_override = Vector2(options.get("size_override", Vector2.ZERO))
	_hand_fan_mode = false
	_hand_fan_index = 0
	_hand_fan_total = 0
	_is_hovered = false
	_ensure_layout()
	_refresh_visuals()

func configure_stage_hand_fan(slot_index: int, total_cards: int) -> void:
	_hand_fan_mode = true
	_hand_fan_index = maxi(0, slot_index)
	_hand_fan_total = maxi(1, total_cards)
	_apply_hand_fan_pose(false)

func clear_stage_hand_fan() -> void:
	_hand_fan_mode = false
	_hand_fan_index = 0
	_hand_fan_total = 1
	_is_hovered = false
	if is_instance_valid(_hover_tween):
		_hover_tween.kill()
	_hover_tween = null
	_apply_hand_fan_pose(false)

func _ensure_layout() -> void:
	if _margin != null:
		return
	_margin = MarginContainer.new()
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.set_anchors_preset(PRESET_FULL_RECT)
	_margin.offset_left = 10.0
	_margin.offset_top = 10.0
	_margin.offset_right = -10.0
	_margin.offset_bottom = -10.0
	add_child(_margin)

	_root = VBoxContainer.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_theme_constant_override("separation", 8)
	_margin.add_child(_root)

	_top_row = HBoxContainer.new()
	_top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_row.add_theme_constant_override("separation", 6)
	_root.add_child(_top_row)

	var cost_chip := _create_chip()
	_cost_chip_panel = cost_chip["panel"]
	_cost_chip_label = cost_chip["label"]
	_top_row.add_child(_cost_chip_panel)

	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_row.add_child(spacer)

	var type_chip := _create_chip()
	_type_chip_panel = type_chip["panel"]
	_type_chip_label = type_chip["label"]
	_top_row.add_child(_type_chip_panel)

	_title_label = Label.new()
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", 18)
	_root.add_child(_title_label)

	_art_panel = PanelContainer.new()
	_art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_panel.custom_minimum_size = Vector2(0, 82)
	_root.add_child(_art_panel)

	var art_margin := MarginContainer.new()
	art_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_margin.add_theme_constant_override("margin_left", 10)
	art_margin.add_theme_constant_override("margin_top", 10)
	art_margin.add_theme_constant_override("margin_right", 10)
	art_margin.add_theme_constant_override("margin_bottom", 10)
	_art_panel.add_child(art_margin)

	var art_box := VBoxContainer.new()
	art_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_box.alignment = BoxContainer.ALIGNMENT_CENTER
	art_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_box.add_theme_constant_override("separation", 6)
	art_margin.add_child(art_box)

	_art_icon = BadgeIconScript.new()
	_art_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_icon.custom_minimum_size = Vector2(54, 54)
	art_box.add_child(_art_icon)

	_art_label = Label.new()
	_art_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_art_label.add_theme_font_size_override("font_size", 13)
	art_box.add_child(_art_label)

	_description_label = Label.new()
	_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_description_label.add_theme_font_size_override("font_size", 13)
	_root.add_child(_description_label)

	_footer_label = Label.new()
	_footer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_footer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer_label.add_theme_font_size_override("font_size", 12)
	_root.add_child(_footer_label)

func _create_chip() -> Dictionary:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 12)
	margin.add_child(label)
	return {"panel": panel, "label": label}

func _refresh_visuals() -> void:
	if _margin == null or _cost_chip_panel == null or _cost_chip_label == null or _type_chip_label == null or _title_label == null or _art_panel == null or _art_icon == null or _art_label == null or _description_label == null or _footer_label == null:
		return
	var presentation := _build_presentation()
	var theme_manager = _theme_manager()
	if theme_manager != null and theme_manager.has_method("decorate_card_presentation"):
		presentation = theme_manager.call("decorate_card_presentation", presentation, _payload, _mode)
	_palette = presentation
	var presentation_size := Vector2(presentation.get("size", SMALL_SIZE))
	var is_stage_card := _mode == "stage_card"
	var roomy_stage := is_stage_card and presentation_size.x >= 148.0
	custom_minimum_size = presentation_size * _ui_scale_factor()
	tooltip_text = String(presentation.get("tooltip", ""))
	var description_text := String(presentation.get("description", ""))
	var footer_text := String(presentation.get("footer_text", ""))
	if is_stage_card:
		var desc_base := 84 if roomy_stage else (56 if _compact_level <= 1 else 44)
		var foot_base := 34 if roomy_stage else (22 if _compact_level <= 1 else 16)
		description_text = _compact_card_text(description_text, _text_limit_for_width(desc_base))
		footer_text = _compact_card_text(footer_text, _text_limit_for_width(foot_base))
	_root.add_theme_constant_override("separation", 6 if is_stage_card else 8)

	_cost_chip_panel.visible = String(presentation.get("cost_text", "")) != ""
	_cost_chip_label.text = String(presentation.get("cost_text", ""))
	_type_chip_label.text = String(presentation.get("type_text", ""))
	_title_label.text = String(presentation.get("title", "Tile"))
	_art_label.text = String(presentation.get("art_text", ""))
	_description_label.text = description_text
	_footer_label.text = footer_text
	_title_label.add_theme_font_size_override("font_size", _scaled_font_size(14 if is_stage_card else (16 if _large else 18)))
	_art_label.add_theme_font_size_override("font_size", _scaled_font_size(10 if is_stage_card else (12 if _large else 13)))
	_description_label.add_theme_font_size_override("font_size", _scaled_font_size(10 if is_stage_card else (12 if _large else 13)))
	_footer_label.add_theme_font_size_override("font_size", _scaled_font_size(9 if is_stage_card else (11 if _large else 12)))
	_title_label.max_lines_visible = 2 if is_stage_card else -1
	_description_label.max_lines_visible = 3 if is_stage_card else -1
	_footer_label.max_lines_visible = 2 if is_stage_card else -1
	_cost_chip_label.add_theme_font_size_override("font_size", _scaled_font_size(10 if is_stage_card else 12))
	_type_chip_label.add_theme_font_size_override("font_size", _scaled_font_size(10 if is_stage_card else 12))
	_art_icon.custom_minimum_size = (Vector2(36, 36) if is_stage_card else Vector2(54, 54)) * _ui_scale_factor()

	var text_color := Color(presentation.get("text_color", Color.WHITE))
	var muted_text := text_color.lerp(Color(presentation.get("fill_color", Color.BLACK)), 0.24)
	var accent := Color(presentation.get("accent_color", Color.WHITE))
	var chip_fill := Color(presentation.get("chip_fill", accent.darkened(0.20)))
	var chip_text := Color(presentation.get("chip_text", text_color))
	var art_fill := Color(presentation.get("art_fill", chip_fill))

	_title_label.add_theme_color_override("font_color", text_color)
	_art_label.add_theme_color_override("font_color", text_color)
	_description_label.add_theme_color_override("font_color", text_color)
	_footer_label.add_theme_color_override("font_color", muted_text)
	_cost_chip_label.add_theme_color_override("font_color", chip_text)
	_type_chip_label.add_theme_color_override("font_color", chip_text)

	_apply_button_style(
		Color(presentation.get("fill_color", Color(0.16, 0.20, 0.26, 0.98))),
		accent,
		text_color
	)
	_apply_panel_style(_cost_chip_panel, chip_fill, accent)
	_apply_panel_style(_type_chip_panel, chip_fill, accent)
	_apply_panel_style(_art_panel, art_fill, accent.lerp(art_fill, 0.24))
	if _art_icon.has_method("set"):
		_art_icon.set("icon_kind", String(presentation.get("icon_kind", "ball")))
	if _art_icon.has_method("set_icon_texture"):
		_art_icon.call("set_icon_texture", presentation.get("icon_texture", null))
	if _art_icon.has_method("set_palette"):
		_art_icon.call("set_palette", accent, text_color)

	var art_height := 82.0
	if _mode == "route":
		art_height = 60.0
	elif _mode == "skip":
		art_height = 54.0
	elif _mode in ["reward_card", "relic_reward"]:
		art_height = 88.0
	elif is_stage_card:
		art_height = 44.0 if roomy_stage else (32.0 if _compact_level >= 2 else 36.0)
	elif _large:
		art_height = 72.0
	_art_panel.custom_minimum_size = Vector2(0, art_height * _ui_scale_factor())
	if _hand_fan_mode:
		_apply_hand_fan_pose(false)
	queue_redraw()

func _build_presentation() -> Dictionary:
	var tags := _coerce_tags(_payload.get("tags", PackedStringArray()))
	var presentation := {
		"title": String(_payload.get("name", "Card")),
		"description": String(_payload.get("description", "")),
		"footer_text": String(_payload.get("footer_text", _join_tags(tags))),
		"cost_text": str(int(_payload.get("cost", 0))),
		"type_text": "SHOT",
		"art_text": _primary_tag_label(tags),
		"icon_kind": _icon_for_tags(tags),
		"fill_color": Color(0.17, 0.22, 0.29, 0.96),
		"accent_color": Color(0.68, 0.84, 0.98, 0.96),
		"text_color": Color(0.96, 0.98, 1.0, 1.0),
		"chip_fill": Color(0.10, 0.18, 0.24, 0.94),
		"chip_text": Color(0.96, 0.98, 1.0, 1.0),
		"art_fill": Color(0.11, 0.18, 0.26, 0.95),
		"size": SMALL_SIZE,
		"tooltip": String(_payload.get("tooltip_text", _payload.get("description", ""))),
	}

	match _mode:
		"stage_card":
			presentation["size"] = _size_override if _size_override != Vector2.ZERO else _stage_card_size()
			presentation["footer_text"] = String(_payload.get("footer_text", _join_tags(tags)))
		"reward_card":
			presentation["size"] = REWARD_SIZE
			presentation["type_text"] = "REWARD"
			presentation["art_text"] = "Draft Pick"
		"relic_reward":
			presentation["title"] = String(_payload.get("name", "Relic"))
			presentation["description"] = String(_payload.get("description", ""))
			presentation["footer_text"] = "Relic Reward"
			presentation["cost_text"] = ""
			presentation["type_text"] = String(_payload.get("rarity", "common")).capitalize()
			presentation["art_text"] = "Tour Gear"
			presentation["icon_kind"] = "trophy"
			presentation["fill_color"] = Color(0.22, 0.18, 0.10, 0.96)
			presentation["accent_color"] = Color(0.98, 0.80, 0.34, 1.0)
			presentation["art_fill"] = Color(0.30, 0.22, 0.10, 0.96)
			presentation["size"] = RELIC_SIZE
			presentation["tooltip"] = "%s [%s]" % [presentation["title"], presentation["type_text"]]
		"skip":
			presentation["title"] = String(_payload.get("title", "Skip Reward"))
			presentation["description"] = String(_payload.get("description", "Leave the reward behind and continue the bracket."))
			presentation["footer_text"] = String(_payload.get("footer_text", "Return to the tournament map"))
			presentation["cost_text"] = ""
			presentation["type_text"] = "SKIP"
			presentation["art_text"] = "No Pickup"
			presentation["icon_kind"] = "focus"
			presentation["fill_color"] = Color(0.16, 0.18, 0.22, 0.96)
			presentation["accent_color"] = Color(0.72, 0.78, 0.88, 1.0)
			presentation["art_fill"] = Color(0.18, 0.22, 0.28, 0.96)
			presentation["size"] = SKIP_SIZE
		"route":
			var node_type := String(_payload.get("node_type", "regular"))
			presentation["title"] = String(_payload.get("title", "Next Route"))
			presentation["description"] = String(_payload.get("description", ""))
			presentation["footer_text"] = String(_payload.get("footer_text", "Bracket advance"))
			presentation["cost_text"] = String(_payload.get("seed_text", ""))
			presentation["type_text"] = node_type.capitalize()
			presentation["art_text"] = String(_payload.get("round_label", "Round"))
			presentation["icon_kind"] = _icon_for_node_type(node_type)
			presentation["size"] = ROUTE_SIZE
			_apply_route_palette(presentation, node_type)
		"rest_choice":
			presentation["title"] = String(_payload.get("title", "Rest"))
			presentation["description"] = String(_payload.get("description", "Take a camp action before the next round."))
			presentation["footer_text"] = String(_payload.get("footer_text", "Choose one action"))
			presentation["cost_text"] = ""
			presentation["type_text"] = String(_payload.get("display_type", "REST"))
			presentation["art_text"] = String(_payload.get("display_art", "Recovery Camp"))
			presentation["icon_kind"] = String(_payload.get("display_icon", "focus"))
			presentation["fill_color"] = Color(0.12, 0.19, 0.15, 0.97)
			presentation["accent_color"] = Color(0.72, 0.94, 0.70, 1.0)
			presentation["art_fill"] = Color(0.15, 0.27, 0.18, 0.96)
			presentation["chip_fill"] = Color(0.10, 0.15, 0.11, 0.94)
			presentation["size"] = REST_CHOICE_SIZE
			match presentation["type_text"]:
				"TRAIN":
					presentation["fill_color"] = Color(0.24, 0.18, 0.10, 0.97)
					presentation["accent_color"] = Color(1.0, 0.82, 0.46, 1.0)
					presentation["art_fill"] = Color(0.32, 0.22, 0.10, 0.96)
					presentation["chip_fill"] = Color(0.16, 0.12, 0.08, 0.94)
				"SCOUT":
					presentation["fill_color"] = Color(0.11, 0.18, 0.24, 0.97)
					presentation["accent_color"] = Color(0.62, 0.86, 1.0, 1.0)
					presentation["art_fill"] = Color(0.14, 0.24, 0.33, 0.96)
					presentation["chip_fill"] = Color(0.09, 0.13, 0.18, 0.94)

	if _mode in ["card", "stage_card", "reward_card"]:
		_apply_tag_palette(presentation, tags)
		if bool(_payload.get("retained", false)):
			presentation["footer_text"] = _append_footer(String(presentation.get("footer_text", "")), "Retain")
		if bool(_payload.get("exhaust", false)):
			presentation["footer_text"] = _append_footer(String(presentation.get("footer_text", "")), "Exhaust")
		if tags.has("modifier"):
			if tags.has("string"):
				presentation["type_text"] = "STRING"
				presentation["art_text"] = "String Setup"
				presentation["icon_kind"] = _string_icon_for_title(String(presentation.get("title", "")))
			elif tags.has("racquet"):
				presentation["type_text"] = "FRAME"
				presentation["art_text"] = "Weight Setup"
				presentation["icon_kind"] = _frame_icon_for_title(String(presentation.get("title", "")))
			else:
				presentation["type_text"] = "MOD"
		elif tags.has("skill"):
			presentation["type_text"] = "SKILL"
		elif tags.has("power"):
			presentation["type_text"] = "POWER"
		elif tags.has("signature"):
			presentation["type_text"] = "SIGN"

	if _payload.has("display_title"):
		presentation["title"] = String(_payload.get("display_title", presentation["title"]))
	if _payload.has("display_description"):
		presentation["description"] = String(_payload.get("display_description", presentation["description"]))
	if _payload.has("display_footer"):
		presentation["footer_text"] = String(_payload.get("display_footer", presentation["footer_text"]))
	if _payload.has("display_type"):
		presentation["type_text"] = String(_payload.get("display_type", presentation["type_text"]))
	if _payload.has("display_art"):
		presentation["art_text"] = String(_payload.get("display_art", presentation["art_text"]))
	if _payload.has("display_icon"):
		presentation["icon_kind"] = String(_payload.get("display_icon", presentation["icon_kind"]))
	if _payload.has("price_btc"):
		presentation["cost_text"] = "B%d" % int(_payload.get("price_btc", 0))
	if _payload.has("tooltip_text"):
		presentation["tooltip"] = String(_payload.get("tooltip_text", presentation["tooltip"]))
	if _mode in ["card", "stage_card", "reward_card"]:
		_apply_slot_context_palette(presentation)
		_apply_blocked_context_palette(presentation)
	_apply_high_contrast_palette(presentation)

	return presentation

func _stage_card_size() -> Vector2:
	return card_size_for_mode("stage_card", _large, _compact_level)

func _compact_card_text(text: String, max_length: int) -> String:
	var normalized := text.replace("\n", " ").strip_edges()
	if normalized.length() <= max_length:
		return normalized
	return normalized.substr(0, max_length - 3).rstrip(" ,.;") + "..."

func _apply_route_palette(presentation: Dictionary, node_type: String) -> void:
	match node_type:
		"elite":
			presentation["fill_color"] = Color(0.35, 0.15, 0.12, 0.96)
			presentation["accent_color"] = Color(0.98, 0.53, 0.22, 1.0)
			presentation["art_fill"] = Color(0.46, 0.18, 0.12, 0.96)
		"boss":
			presentation["fill_color"] = Color(0.28, 0.20, 0.08, 0.96)
			presentation["accent_color"] = Color(1.0, 0.84, 0.32, 1.0)
			presentation["art_fill"] = Color(0.40, 0.26, 0.08, 0.96)
		"shop":
			presentation["fill_color"] = Color(0.22, 0.20, 0.10, 0.96)
			presentation["accent_color"] = Color(0.94, 0.86, 0.36, 1.0)
			presentation["art_fill"] = Color(0.30, 0.26, 0.12, 0.96)
		"rest":
			presentation["fill_color"] = Color(0.12, 0.23, 0.17, 0.96)
			presentation["accent_color"] = Color(0.62, 0.94, 0.72, 1.0)
			presentation["art_fill"] = Color(0.14, 0.31, 0.20, 0.96)
		"event":
			presentation["fill_color"] = Color(0.12, 0.20, 0.28, 0.96)
			presentation["accent_color"] = Color(0.60, 0.88, 1.0, 1.0)
			presentation["art_fill"] = Color(0.14, 0.26, 0.36, 0.96)
		"treasure":
			presentation["fill_color"] = Color(0.27, 0.20, 0.10, 0.96)
			presentation["accent_color"] = Color(1.0, 0.76, 0.30, 1.0)
			presentation["art_fill"] = Color(0.36, 0.24, 0.10, 0.96)
		_:
			presentation["fill_color"] = Color(0.10, 0.21, 0.28, 0.96)
			presentation["accent_color"] = Color(0.48, 0.86, 1.0, 1.0)
			presentation["art_fill"] = Color(0.13, 0.29, 0.39, 0.96)

func _apply_tag_palette(presentation: Dictionary, tags: PackedStringArray) -> void:
	if tags.has("serve"):
		presentation["fill_color"] = Color(0.40, 0.17, 0.10, 0.96)
		presentation["accent_color"] = Color(0.99, 0.69, 0.24, 1.0)
		presentation["art_fill"] = Color(0.54, 0.19, 0.10, 0.96)
	elif tags.has("topspin"):
		presentation["fill_color"] = Color(0.12, 0.28, 0.16, 0.96)
		presentation["accent_color"] = Color(0.56, 0.98, 0.44, 1.0)
		presentation["art_fill"] = Color(0.16, 0.39, 0.18, 0.96)
	elif tags.has("slice"):
		presentation["fill_color"] = Color(0.24, 0.14, 0.36, 0.96)
		presentation["accent_color"] = Color(0.82, 0.58, 1.0, 1.0)
		presentation["art_fill"] = Color(0.34, 0.16, 0.48, 0.96)
	elif tags.has("footwork"):
		presentation["fill_color"] = Color(0.10, 0.24, 0.35, 0.96)
		presentation["accent_color"] = Color(0.54, 0.88, 1.0, 1.0)
		presentation["art_fill"] = Color(0.12, 0.33, 0.48, 0.96)
	elif tags.has("modifier"):
		presentation["fill_color"] = Color(0.23, 0.21, 0.15, 0.96)
		presentation["accent_color"] = Color(0.92, 0.80, 0.52, 1.0)
		presentation["art_fill"] = Color(0.30, 0.26, 0.16, 0.96)
	elif tags.has("skill"):
		presentation["fill_color"] = Color(0.14, 0.20, 0.31, 0.96)
		presentation["accent_color"] = Color(0.60, 0.82, 1.0, 1.0)
		presentation["art_fill"] = Color(0.16, 0.26, 0.42, 0.96)
	elif tags.has("power"):
		presentation["fill_color"] = Color(0.32, 0.10, 0.10, 0.96)
		presentation["accent_color"] = Color(1.0, 0.47, 0.29, 1.0)
		presentation["art_fill"] = Color(0.46, 0.12, 0.10, 0.96)

func _apply_slot_context_palette(presentation: Dictionary) -> void:
	var slot_id := String(_payload.get("slot_id", ""))
	if slot_id != "initial_contact":
		return
	var slot_context := String(_payload.get("slot_context", ""))
	var context_banner := String(_payload.get("context_banner", ""))
	var context_hint := String(_payload.get("context_hint", ""))
	match slot_context:
		"serve":
			presentation["fill_color"] = Color(0.11, 0.25, 0.43, 0.97)
			presentation["accent_color"] = Color(0.56, 0.86, 1.0, 1.0)
			presentation["art_fill"] = Color(0.13, 0.35, 0.56, 0.96)
			presentation["type_text"] = "SERVE"
			presentation["art_text"] = context_banner if context_banner != "" else "Serve Window"
			presentation["icon_kind"] = "serve"
		"return":
			presentation["fill_color"] = Color(0.12, 0.30, 0.18, 0.97)
			presentation["accent_color"] = Color(0.66, 0.98, 0.72, 1.0)
			presentation["art_fill"] = Color(0.16, 0.40, 0.20, 0.96)
			presentation["type_text"] = "RETURN"
			presentation["art_text"] = context_banner if context_banner != "" else "Return Window"
			presentation["icon_kind"] = "return"
		"rally":
			presentation["fill_color"] = Color(0.20, 0.22, 0.26, 0.97)
			presentation["accent_color"] = Color(0.78, 0.82, 0.90, 1.0)
			presentation["art_fill"] = Color(0.24, 0.26, 0.32, 0.96)
			presentation["type_text"] = "RALLY"
			presentation["art_text"] = context_banner if context_banner != "" else "Rally Live"
			presentation["icon_kind"] = "rally"
	if context_hint != "":
		presentation["footer_text"] = _append_footer(String(presentation.get("footer_text", "")), context_hint)
	if _high_contrast_enabled():
		presentation["art_text"] = "[%s] %s" % [String(presentation.get("type_text", "STATE")), String(presentation.get("art_text", ""))]

func _apply_blocked_context_palette(presentation: Dictionary) -> void:
	var playable := bool(_payload.get("playable", true))
	var block_reason := String(_payload.get("block_reason", ""))
	if playable or block_reason == "":
		return
	if bool(_payload.get("wrong_opener", false)):
		presentation["fill_color"] = Color(0.18, 0.18, 0.20, 0.97)
		presentation["accent_color"] = Color(0.95, 0.48, 0.40, 1.0)
		presentation["art_fill"] = Color(0.25, 0.20, 0.20, 0.96)
		presentation["type_text"] = "LOCKED"
		presentation["art_text"] = "Wrong Opener"
		presentation["footer_text"] = _append_footer(String(presentation.get("footer_text", "")), "Use the other opener type")
		return
	if block_reason.begins_with("Serve cards") or block_reason.begins_with("Return cards") or block_reason == "Serve/Return required to open point.":
		presentation["fill_color"] = Color(0.20, 0.19, 0.21, 0.97)
		presentation["accent_color"] = Color(0.92, 0.60, 0.42, 1.0)
		presentation["art_fill"] = Color(0.24, 0.22, 0.24, 0.96)
		presentation["type_text"] = "LOCKED"
		presentation["footer_text"] = _append_footer(String(presentation.get("footer_text", "")), "Serve/Return required to open point.")
	elif block_reason.findn("open the point") >= 0:
		presentation["fill_color"] = Color(0.19, 0.20, 0.24, 0.97)
		presentation["accent_color"] = Color(0.76, 0.80, 0.92, 1.0)
		presentation["art_fill"] = Color(0.22, 0.24, 0.30, 0.96)
		presentation["type_text"] = "LOCKED"
		presentation["footer_text"] = _append_footer(String(presentation.get("footer_text", "")), "Opening contact already used")
	if _high_contrast_enabled():
		presentation["art_text"] = "[LOCKED] %s" % String(presentation.get("art_text", "Card Locked"))
		presentation["footer_text"] = _append_footer(String(presentation.get("footer_text", "")), block_reason)

func _apply_high_contrast_palette(presentation: Dictionary) -> void:
	if not _high_contrast_enabled():
		return
	var fill_color := Color(presentation.get("fill_color", Color(0.16, 0.20, 0.26, 0.98)))
	var accent_color := Color(presentation.get("accent_color", Color.WHITE))
	var dark_fill := fill_color.darkened(0.22)
	dark_fill.a = 0.99
	presentation["fill_color"] = dark_fill
	presentation["accent_color"] = accent_color.lightened(0.20)
	presentation["text_color"] = Color.WHITE
	presentation["chip_fill"] = dark_fill.darkened(0.15)
	presentation["chip_text"] = Color.WHITE
	presentation["art_fill"] = dark_fill.lightened(0.04)
	var type_text := String(presentation.get("type_text", "CARD"))
	var tooltip := String(presentation.get("tooltip", ""))
	if tooltip.find("[State]") < 0:
		presentation["tooltip"] = "[State] %s\n%s" % [type_text, tooltip]

func _apply_button_style(fill_color: Color, border_color: Color, text_color: Color) -> void:
	var theme_manager = _theme_manager()
	var normal: StyleBox = null
	var hover: StyleBox = null
	var pressed: StyleBox = null
	var disabled_style: StyleBox = null
	if theme_manager != null and theme_manager.has_method("make_button_style"):
		normal = Dictionary(theme_manager.call("make_button_style", fill_color, border_color, text_color, "normal")).get("style")
		hover = Dictionary(theme_manager.call("make_button_style", fill_color, border_color, text_color, "hover")).get("style")
		pressed = Dictionary(theme_manager.call("make_button_style", fill_color, border_color, text_color, "pressed")).get("style")
		disabled_style = Dictionary(theme_manager.call("make_button_style", fill_color, border_color, text_color, "disabled")).get("style")
	if normal == null:
		normal = _build_gloss_style(fill_color, border_color, 20, 0.34)
	if hover == null:
		hover = _build_gloss_style(fill_color.lightened(0.07), border_color.lightened(0.10), 20, 0.42)
	if pressed == null:
		pressed = _build_gloss_style(fill_color.darkened(0.08), border_color.darkened(0.04), 20, 0.18)
	if disabled_style == null:
		disabled_style = _build_gloss_style(fill_color.darkened(0.20), border_color.lerp(fill_color, 0.40), 20, 0.10)

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("disabled", disabled_style)
	add_theme_color_override("font_color", text_color)
	add_theme_color_override("font_disabled_color", text_color.lerp(fill_color, 0.45))

func _apply_panel_style(panel: PanelContainer, fill_color: Color, border_color: Color) -> void:
	var theme_manager = _theme_manager()
	var style: StyleBox = null
	if theme_manager != null and theme_manager.has_method("make_panel_style"):
		style = theme_manager.call("make_panel_style", fill_color, border_color, {
			"variant": "chip",
			"radius": 14,
			"shadow_alpha": 0.18,
			"border_width": 2,
			"content_margin_left": 8.0,
			"content_margin_right": 8.0,
			"content_margin_top": 6.0,
			"content_margin_bottom": 6.0,
		})
	if style == null:
		style = _build_gloss_style(fill_color, border_color, 14, 0.18)
	panel.add_theme_stylebox_override("panel", style)

func _apply_hand_fan_pose(hovered: bool) -> void:
	if not _hand_fan_mode:
		scale = Vector2.ONE
		rotation = 0.0
		position.y = 0.0
		z_index = 0
		return
	var spread := 0.0
	if _hand_fan_total > 1:
		spread = (float(_hand_fan_index) / float(_hand_fan_total - 1)) - 0.5
	var base_rotation := deg_to_rad(spread * 8.5)
	if _reduced_motion_enabled():
		base_rotation = 0.0
	pivot_offset = Vector2(size.x * 0.5, size.y * 0.90)
	if hovered:
		z_index = 100 + _hand_fan_index
		scale = Vector2(1.02, 1.02) if _reduced_motion_enabled() else Vector2(1.08, 1.08)
		rotation = 0.0
		position.y = -6.0 if _reduced_motion_enabled() else -22.0
	else:
		z_index = _hand_fan_index
		scale = Vector2.ONE
		rotation = base_rotation
		position.y = 0.0 if _reduced_motion_enabled() else abs(spread) * 18.0

func _animate_hand_hover(hovered: bool) -> void:
	if is_instance_valid(_hover_tween):
		_hover_tween.kill()
	var target_scale := Vector2.ONE
	var target_rotation := 0.0
	var target_y := 0.0
	var target_z := 0
	if _hand_fan_mode:
		var spread := 0.0
		if _hand_fan_total > 1:
			spread = (float(_hand_fan_index) / float(_hand_fan_total - 1)) - 0.5
		if _reduced_motion_enabled():
			target_scale = Vector2(1.02, 1.02) if hovered else Vector2.ONE
			target_rotation = 0.0
			target_y = -6.0 if hovered else 0.0
		else:
			target_scale = Vector2(1.08, 1.08) if hovered else Vector2.ONE
			target_rotation = 0.0 if hovered else deg_to_rad(spread * 8.5)
			target_y = -22.0 if hovered else abs(spread) * 18.0
		target_z = (100 + _hand_fan_index) if hovered else _hand_fan_index
	z_index = target_z
	if _reduced_motion_enabled():
		scale = target_scale
		rotation = target_rotation
		position = Vector2(position.x, target_y)
		return
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.tween_property(self, "scale", target_scale, 0.12)
	_hover_tween.tween_property(self, "rotation", target_rotation, 0.12)
	_hover_tween.tween_property(self, "position", Vector2(position.x, target_y), 0.12)

func _on_hover_entered() -> void:
	_is_hovered = true
	_animate_hand_hover(true)
	queue_redraw()

func _on_hover_exited() -> void:
	_is_hovered = false
	_animate_hand_hover(false)
	queue_redraw()

func _draw() -> void:
	if _palette.is_empty():
		return
	var rect := Rect2(Vector2.ZERO, size)
	var accent := Color(_palette.get("accent_color", Color.WHITE))
	var fill := Color(_palette.get("fill_color", Color(0.16, 0.20, 0.26, 0.98)))
	var text_color := Color(_palette.get("text_color", Color.WHITE))
	var surface_texture: Texture2D = _palette.get("surface_texture", null)
	var frame_texture: Texture2D = _palette.get("frame_texture", null)
	var divider_texture: Texture2D = _palette.get("divider_texture", null)
	if surface_texture != null:
		draw_texture_rect(surface_texture, rect.grow(-4.0), false, fill.lightened(0.08))
	var haze := accent
	haze.a = 0.10
	draw_circle(Vector2(rect.size.x * 0.78, rect.size.y * 0.18), rect.size.x * 0.18, haze)
	var gloss := accent.lightened(0.24)
	gloss.a = 0.16
	draw_rect(Rect2(12.0, 12.0, rect.size.x - 24.0, rect.size.y * 0.20), gloss)
	var glaze := Color(1.0, 1.0, 1.0, 0.08)
	var glare := PackedVector2Array([
		Vector2(rect.size.x * 0.12, rect.size.y * 0.10),
		Vector2(rect.size.x * 0.48, rect.size.y * 0.10),
		Vector2(rect.size.x * 0.76, rect.size.y * 0.36),
		Vector2(rect.size.x * 0.40, rect.size.y * 0.36),
	])
	_fill_polygon(glare, glaze)
	var flare := accent.lightened(0.08)
	flare.a = 0.18
	for stripe in range(4):
		var y := rect.size.y * (0.20 + float(stripe) * 0.15)
		draw_line(Vector2(18.0, y), Vector2(rect.size.x - 18.0, y + 6.0), flare, 1.6, true)
	var lace := accent.lightened(0.10)
	lace.a = 0.20
	draw_line(Vector2(18.0, rect.size.y * 0.16), Vector2(rect.size.x - 18.0, rect.size.y * 0.16), lace, 1.4, true)
	draw_line(Vector2(18.0, rect.size.y * 0.82), Vector2(rect.size.x - 18.0, rect.size.y * 0.82), lace, 1.4, true)
	var inset := Rect2(10.0, 10.0, rect.size.x - 20.0, rect.size.y - 20.0)
	draw_rect(inset, Color(1.0, 1.0, 1.0, 0.04), false, 1.2)
	var trim := fill.lightened(0.16)
	trim.a = 0.35
	draw_line(Vector2(18.0, rect.size.y - 24.0), Vector2(rect.size.x - 18.0, rect.size.y - 18.0), trim, 2.0, true)
	if divider_texture != null:
		draw_texture_rect(divider_texture, Rect2(16.0, rect.size.y * 0.82, rect.size.x - 32.0, 12.0), false, accent.lightened(0.12))
	var ball_color := accent.lightened(0.12)
	ball_color.a = 0.92
	var ball_center := Vector2(rect.size.x - 24.0, 24.0)
	draw_circle(ball_center, 7.0, ball_color)
	var seam := fill.darkened(0.30)
	seam.a = 0.86
	draw_arc(ball_center, 5.0, -0.8, 0.8, 12, seam, 1.2, true)
	draw_arc(ball_center, 5.0, PI - 0.8, PI + 0.8, 12, seam, 1.2, true)
	var service_box := Rect2(rect.size.x - 44.0, rect.size.y - 44.0, 22.0, 14.0)
	draw_rect(service_box, Color(0.0, 0.0, 0.0, 0.0), false, 1.2)
	draw_line(service_box.position + Vector2(service_box.size.x * 0.5, 0.0), service_box.position + Vector2(service_box.size.x * 0.5, service_box.size.y), text_color.lerp(fill, 0.35), 1.0, true)
	if frame_texture != null:
		draw_texture_rect(frame_texture, rect, false, accent.lightened(0.10))
	if _is_hovered:
		_draw_hover_glow(rect, accent)

func _draw_hover_glow(rect: Rect2, accent: Color) -> void:
	var outer := StyleBoxFlat.new()
	outer.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	outer.border_color = accent.lightened(0.18)
	outer.border_color.a = 0.58
	outer.set_border_width_all(2)
	outer.corner_radius_top_left = 22
	outer.corner_radius_top_right = 22
	outer.corner_radius_bottom_right = 22
	outer.corner_radius_bottom_left = 22
	outer.shadow_color = accent.lightened(0.08)
	outer.shadow_color.a = 0.26
	outer.shadow_size = 14
	outer.shadow_offset = Vector2.ZERO
	outer.anti_aliasing = true
	outer.anti_aliasing_size = 1.0
	outer.draw(get_canvas_item(), rect.grow(-2.0))

	var inner := StyleBoxFlat.new()
	inner.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	inner.border_color = Color(1.0, 1.0, 1.0, 0.22)
	inner.set_border_width_all(1)
	inner.corner_radius_top_left = 18
	inner.corner_radius_top_right = 18
	inner.corner_radius_bottom_right = 18
	inner.corner_radius_bottom_left = 18
	inner.anti_aliasing = true
	inner.anti_aliasing_size = 1.0
	inner.draw(get_canvas_item(), rect.grow(-8.0))

func _build_gloss_style(fill_color: Color, border_color: Color, radius: int, shadow_alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_detail = 12
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.0
	style.border_blend = true
	style.shadow_color = Color(0.02, 0.05, 0.08, shadow_alpha)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	style.expand_margin_bottom = 4.0
	style.expand_margin_left = 1.0
	style.expand_margin_right = 1.0
	style.expand_margin_top = 1.0
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style

func _fill_polygon(points: PackedVector2Array, color_value: Color) -> void:
	var colors := PackedColorArray()
	for _unused in points:
		colors.append(color_value)
	draw_polygon(points, colors)

func _icon_for_tags(tags: PackedStringArray) -> String:
	if tags.has("string"):
		return "string"
	if tags.has("racquet"):
		return "racquet_tune"
	if tags.has("topspin"):
		return "spin"
	if tags.has("footwork"):
		return "momentum"
	if tags.has("recovery"):
		return "focus"
	if tags.has("power"):
		return "pressure"
	if tags.has("slice"):
		return "guard"
	return "ball"

func _string_icon_for_title(title: String) -> String:
	var lowered := title.to_lower()
	if lowered.find("poly") >= 0:
		return "poly"
	if lowered.find("natural gut") >= 0 or lowered.find("gut") >= 0:
		return "gut"
	if lowered.find("multifilament") >= 0 or lowered.find("multi") >= 0:
		return "multi"
	if lowered.find("synthetic") >= 0:
		return "synthetic"
	return "string"

func _frame_icon_for_title(title: String) -> String:
	var lowered := title.to_lower()
	if lowered.find("lead tape") >= 0 or lowered.find("pro stock") >= 0 or lowered.find("frame") >= 0:
		return "racquet_tune"
	return "frame"

func _icon_for_node_type(node_type: String) -> String:
	match node_type:
		"elite":
			return "pressure"
		"boss":
			return "trophy"
		"shop":
			return "frame"
		"rest":
			return "focus"
		"event":
			return "momentum"
		"treasure":
			return "trophy"
		_:
			return "ball"

func _primary_tag_label(tags: PackedStringArray) -> String:
	if tags.is_empty():
		return "Utility"
	return String(tags[0]).capitalize()

func _append_footer(base_text: String, extra_text: String) -> String:
	if base_text == "":
		return extra_text
	return "%s • %s" % [base_text, extra_text]

func _join_tags(tags: PackedStringArray) -> String:
	var parts: Array[String] = []
	for tag in tags:
		parts.append(String(tag).capitalize())
	return " • ".join(parts)

func _coerce_tags(value) -> PackedStringArray:
	if typeof(value) == TYPE_PACKED_STRING_ARRAY:
		return value
	var tags := PackedStringArray()
	if value is Array:
		for entry in value:
			tags.append(String(entry))
	return tags
