class_name MapView
extends Control

signal node_selected(node_id: int)
signal node_hovered(node_id: int)
signal node_hover_cleared()

const DEFAULT_PALETTE := {
	"line": Color(0.28, 0.37, 0.34, 0.8),
	"line_completed": Color(0.78, 0.79, 0.58, 0.9),
	"line_accessible": Color(0.47, 0.72, 0.58, 0.9),
	"current": Color(0.92, 0.78, 0.28),
	"completed": Color(0.34, 0.49, 0.38),
	"regular": Color(0.21, 0.47, 0.37),
	"elite": Color(0.65, 0.29, 0.19),
	"boss": Color(0.76, 0.59, 0.16),
	"rest": Color(0.24, 0.56, 0.42),
	"event": Color(0.17, 0.41, 0.54),
	"shop": Color(0.42, 0.42, 0.22),
	"treasure": Color(0.63, 0.48, 0.18),
}
const CHIP_SIZE := Vector2(118.0, 82.0)

var _nodes: Array = []
var _accessible_node_ids: PackedInt32Array = PackedInt32Array()
var _completed_node_ids: PackedInt32Array = PackedInt32Array()
var _current_node_id: int = -1
var _positions: Dictionary = {}
var _button_layer: Control
var _palette: Dictionary = DEFAULT_PALETTE.duplicate(true)

func _ready() -> void:
	_button_layer = Control.new()
	_button_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_button_layer)
	_button_layer.set_anchors_preset(PRESET_FULL_RECT)
	_button_layer.grow_horizontal = GROW_DIRECTION_BOTH
	_button_layer.grow_vertical = GROW_DIRECTION_BOTH

func set_map(nodes: Array, accessible_node_ids: PackedInt32Array, completed_node_ids: PackedInt32Array, current_node_id: int = -1) -> void:
	_nodes = nodes
	_accessible_node_ids = accessible_node_ids
	_completed_node_ids = completed_node_ids
	_current_node_id = current_node_id
	_rebuild()

func set_palette(palette: Dictionary) -> void:
	_palette = DEFAULT_PALETTE.duplicate(true)
	_palette.merge(palette, true)
	_rebuild()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rebuild()

func _rebuild() -> void:
	if _button_layer == null:
		return
	for child in _button_layer.get_children():
		child.queue_free()
	_positions.clear()
	if _nodes.is_empty():
		queue_redraw()
		return

	var max_floor := 0
	var floor_counts: Dictionary = {}
	for node in _nodes:
		max_floor = maxi(max_floor, int(node.floor))
		floor_counts[node.floor] = maxi(int(floor_counts.get(node.floor, 0)), int(node.lane) + 1)

	var usable_width := maxi(360.0, size.x - 96.0)
	var usable_height := maxi(300.0, size.y - 96.0)
	for node in _nodes:
		var floor_count := maxi(1, int(floor_counts.get(node.floor, 1)))
		var x := 48.0 + _lane_ratio(int(node.lane), floor_count) * usable_width
		var y := 48.0 + _floor_ratio(int(node.floor), max_floor) * usable_height
		var position := Vector2(x, y)
		_positions[node.id] = position

		var button := Button.new()
		button.flat = true
		button.text = ""
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = CHIP_SIZE
		button.size = CHIP_SIZE
		button.position = position - CHIP_SIZE / 2.0
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.disabled = not _accessible_node_ids.has(node.id)
		button.tooltip_text = "%s\n%s" % [_node_label(node.node_type), _node_tooltip(node)]
		_apply_hitbox_style(button)
		button.pressed.connect(_emit_node_selected.bind(node.id))
		button.mouse_entered.connect(_emit_node_hovered.bind(node.id))
		button.focus_entered.connect(_emit_node_hovered.bind(node.id))
		button.mouse_exited.connect(_emit_node_hover_cleared)
		button.focus_exited.connect(_emit_node_hover_cleared)
		_button_layer.add_child(button)
	queue_redraw()

func _draw() -> void:
	if _nodes.is_empty():
		return
	_draw_floor_guides()
	_draw_court_backdrop()
	_draw_links()
	_draw_nodes()

func _draw_floor_guides() -> void:
	var max_floor := 0
	for node in _nodes:
		max_floor = maxi(max_floor, int(node.floor))
	var font: Font = ThemeDB.fallback_font
	for floor in range(max_floor + 1):
		var ratio := _floor_ratio(floor, max_floor)
		var y := 48.0 + ratio * maxi(300.0, size.y - 96.0)
		var guide := Color(1.0, 1.0, 1.0, 0.11)
		for segment in range(24):
			var start_x := 58.0 + float(segment) * ((size.x - 96.0) / 24.0)
			draw_line(Vector2(start_x, y), Vector2(start_x + 10.0, y), guide, 1.0, true)
		if font != null:
			draw_string(font, Vector2(12.0, y + 4.0), "F%d" % (floor + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.92, 0.96, 0.98, 0.68))

func _draw_court_backdrop() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var base := Color(0.03, 0.07, 0.10, 0.38)
	var haze := Color(1.0, 1.0, 1.0, 0.05)
	draw_rect(rect, base)
	var glow := Color(1.0, 1.0, 1.0, 0.05)
	draw_rect(Rect2(0.0, 0.0, rect.size.x, rect.size.y * 0.18), glow)
	for band in range(6):
		var y := 24.0 + float(band) * (rect.size.y - 48.0) / 5.0
		draw_line(Vector2(24.0, y), Vector2(rect.size.x - 24.0, y), haze, 1.0, true)
	var apron := Rect2(34.0, 24.0, rect.size.x - 68.0, rect.size.y - 48.0)
	var apron_fill := Color(0.05, 0.13, 0.18, 0.42)
	draw_rect(apron, apron_fill)
	var stripe_a := Color(0.09, 0.22, 0.30, 0.28)
	var stripe_b := Color(0.05, 0.16, 0.24, 0.18)
	for stripe_index in range(10):
		var stripe_rect := Rect2(
			apron.position.x + apron.size.x * float(stripe_index) / 10.0,
			apron.position.y,
			apron.size.x / 10.0 + 1.0,
			apron.size.y
		)
		draw_rect(stripe_rect, stripe_a if stripe_index % 2 == 0 else stripe_b)
	var court_line := Color(0.94, 0.98, 0.94, 0.12)
	draw_rect(Rect2(42.0, 32.0, rect.size.x - 84.0, rect.size.y - 64.0), court_line, false, 2.0)
	draw_line(Vector2(rect.size.x * 0.5, 32.0), Vector2(rect.size.x * 0.5, rect.size.y - 32.0), court_line, 2.0, true)
	draw_line(Vector2(74.0, rect.size.y * 0.5), Vector2(rect.size.x - 74.0, rect.size.y * 0.5), court_line, 3.0, true)
	draw_rect(Rect2(52.0, 40.0, rect.size.x - 104.0, 16.0), Color(1.0, 1.0, 1.0, 0.05))

func _draw_links() -> void:
	for node in _nodes:
		if not _positions.has(node.id):
			continue
		var from_position: Vector2 = _positions[node.id]
		for next_node_id in node.next_node_ids:
			if not _positions.has(next_node_id):
				continue
			var to_position: Vector2 = _positions[next_node_id]
			var line_color: Color = Color(_palette.get("line", Color(0.28, 0.37, 0.34, 0.8)))
			if _completed_node_ids.has(node.id):
				line_color = Color(_palette.get("line_completed", Color(0.78, 0.79, 0.58, 0.9)))
			elif _accessible_node_ids.has(node.id):
				line_color = Color(_palette.get("line_accessible", Color(0.47, 0.72, 0.58, 0.9)))
			var glow := line_color
			glow.a *= 0.24
			draw_line(from_position, to_position, glow, 10.0, true)
			draw_line(from_position, to_position, line_color, 3.0, true)

func _draw_nodes() -> void:
	for node in _nodes:
		if not _positions.has(node.id):
			continue
		_draw_node_chip(node, Vector2(_positions[node.id]))

func _draw_node_chip(node, center: Vector2) -> void:
	var rect := Rect2(center - CHIP_SIZE / 2.0, CHIP_SIZE)
	var fill := _node_color(node)
	var border := fill.lightened(0.26)
	var ribbon := fill.darkened(0.18)
	var text_color := Color(0.97, 0.98, 1.0, 1.0)
	var accessible: bool = _accessible_node_ids.has(int(node.id))
	var completed: bool = _completed_node_ids.has(int(node.id))
	var current: bool = _current_node_id == int(node.id)
	if not accessible and not completed and not current:
		fill = fill.darkened(0.30)
		border = border.lerp(fill, 0.45)
		text_color = text_color.lerp(fill, 0.42)
	if current:
		border = Color(_palette.get("current", border)).lightened(0.08)

	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.0, 0.0, 0.0, 0.24)
	shadow_style.corner_radius_top_left = 18
	shadow_style.corner_radius_top_right = 18
	shadow_style.corner_radius_bottom_right = 18
	shadow_style.corner_radius_bottom_left = 18
	shadow_style.shadow_color = Color(0.01, 0.03, 0.05, 0.32)
	shadow_style.shadow_size = 8
	draw_style_box(shadow_style, Rect2(rect.position + Vector2(0.0, 6.0), rect.size))

	var body_style := StyleBoxFlat.new()
	body_style.bg_color = fill
	body_style.border_color = border
	body_style.set_border_width_all(2)
	body_style.corner_radius_top_left = 18
	body_style.corner_radius_top_right = 18
	body_style.corner_radius_bottom_right = 18
	body_style.corner_radius_bottom_left = 18
	body_style.corner_detail = 12
	body_style.border_blend = true
	draw_style_box(body_style, rect)
	draw_rect(Rect2(rect.position + Vector2(8.0, 8.0), Vector2(rect.size.x - 16.0, 14.0)), Color(1.0, 1.0, 1.0, 0.09))
	draw_rect(Rect2(rect.position + Vector2(7.0, 7.0), Vector2(rect.size.x - 14.0, rect.size.y - 14.0)), Color(1.0, 1.0, 1.0, 0.05), false, 1.0)

	var ribbon_style := StyleBoxFlat.new()
	ribbon_style.bg_color = ribbon
	ribbon_style.border_color = border.lightened(0.10)
	ribbon_style.set_border_width_all(1)
	ribbon_style.corner_radius_top_left = 12
	ribbon_style.corner_radius_top_right = 12
	ribbon_style.corner_radius_bottom_right = 12
	ribbon_style.corner_radius_bottom_left = 12
	draw_style_box(ribbon_style, Rect2(rect.position + Vector2(10.0, 8.0), Vector2(rect.size.x - 20.0, 20.0)))

	var glow := border
	glow.a = 0.18 if accessible or current else 0.08
	draw_circle(center + Vector2(0.0, 8.0), 18.0, glow)
	var seam_color := border.lightened(0.10)
	seam_color.a = 0.18 if accessible or current else 0.10
	draw_arc(center + Vector2(0.0, 8.0), 12.0, -0.8, 0.8, 12, seam_color, 1.1, true)
	draw_arc(center + Vector2(0.0, 8.0), 12.0, PI - 0.8, PI + 0.8, 12, seam_color, 1.1, true)
	_draw_node_icon(String(node.node_type), center + Vector2(0.0, 6.0), text_color)
	_draw_centered_text(Rect2(rect.position.x, rect.position.y + 24.0, rect.size.x, 20.0), _round_code(int(node.floor)), text_color, 11)
	_draw_centered_text(Rect2(rect.position.x, rect.position.y + 54.0, rect.size.x, 20.0), _node_short_label(String(node.node_type)), text_color, 12)

func _draw_node_icon(node_type: String, center: Vector2, color_value: Color) -> void:
	match node_type:
		"elite":
			var points := PackedVector2Array([
				center + Vector2(0.0, -14.0),
				center + Vector2(11.0, -2.0),
				center + Vector2(5.0, 13.0),
				center + Vector2(-5.0, 13.0),
				center + Vector2(-11.0, -2.0),
			])
			_fill_polygon(points, color_value)
		"boss":
			draw_circle(center + Vector2(0.0, -2.0), 10.0, color_value)
			draw_line(center + Vector2(-14.0, -1.0), center + Vector2(-8.0, -6.0), color_value, 2.6, true)
			draw_line(center + Vector2(14.0, -1.0), center + Vector2(8.0, -6.0), color_value, 2.6, true)
			draw_rect(Rect2(center.x - 6.0, center.y + 7.0, 12.0, 4.0), color_value)
		"shop":
			draw_circle(center + Vector2(0.0, -2.0), 9.0, Color(0.0, 0.0, 0.0, 0.0))
			draw_arc(center + Vector2(0.0, -2.0), 9.0, 0.0, TAU, 18, color_value, 2.6, true)
			draw_line(center + Vector2(6.0, 6.0), center + Vector2(14.0, 14.0), color_value, 3.2, true)
		"rest":
			draw_circle(center, 10.0, color_value)
			draw_circle(center + Vector2(4.0, -2.0), 8.0, Color(0.0, 0.0, 0.0, 0.0))
		"event":
			draw_circle(center + Vector2(0.0, -10.0), 3.0, color_value)
			draw_rect(Rect2(center.x - 2.0, center.y - 6.0, 4.0, 12.0), color_value)
			draw_circle(center + Vector2(0.0, 10.0), 2.4, color_value)
		"treasure":
			draw_rect(Rect2(center.x - 11.0, center.y - 8.0, 22.0, 16.0), color_value)
			draw_line(center + Vector2(0.0, -8.0), center + Vector2(0.0, 8.0), Color(0.18, 0.10, 0.05, 0.9), 2.0, true)
		_:
			draw_circle(center, 10.0, color_value)
			var seam := color_value.darkened(0.30)
			draw_arc(center, 8.0, -0.8, 0.8, 12, seam, 1.5, true)
			draw_arc(center, 8.0, PI - 0.8, PI + 0.8, 12, seam, 1.5, true)

func _draw_centered_text(rect: Rect2, text: String, color_value: Color, font_size: int) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null or text == "":
		return
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := Vector2(rect.position.x + (rect.size.x - text_size.x) * 0.5, rect.position.y + rect.size.y * 0.65)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color_value)

func _fill_polygon(points: PackedVector2Array, color_value: Color) -> void:
	var colors := PackedColorArray()
	for _unused in points:
		colors.append(color_value)
	draw_polygon(points, colors)

func _apply_hitbox_style(button: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)

func _emit_node_selected(node_id: int) -> void:
	emit_signal("node_selected", node_id)

func _emit_node_hovered(node_id: int) -> void:
	emit_signal("node_hovered", node_id)

func _emit_node_hover_cleared() -> void:
	emit_signal("node_hover_cleared")

func _node_label(node_type: String) -> String:
	match node_type:
		"regular":
			return "Match"
		"elite":
			return "Elite"
		"boss":
			return "Final"
		"rest":
			return "Rest"
		"event":
			return "Event"
		"shop":
			return "Shop"
		"treasure":
			return "Chest"
		_:
			return node_type.capitalize()

func _node_short_label(node_type: String) -> String:
	match node_type:
		"regular":
			return "Match"
		"elite":
			return "Elite"
		"boss":
			return "Final"
		"rest":
			return "Rest"
		"event":
			return "Event"
		"shop":
			return "Shop"
		"treasure":
			return "Cache"
		_:
			return node_type.capitalize()

func _node_tooltip(node) -> String:
	return "%s • %s" % [_round_code(int(node.floor)), _node_label(String(node.node_type))]

func _round_code(floor: int) -> String:
	match floor:
		0:
			return "Q"
		1:
			return "R1"
		2:
			return "R2"
		3:
			return "R16"
		4:
			return "QF"
		5:
			return "SF"
		_:
			return "F"

func _node_color(node) -> Color:
	if _current_node_id == node.id:
		return Color(_palette.get("current", Color(0.92, 0.78, 0.28)))
	if _completed_node_ids.has(node.id):
		return Color(_palette.get("completed", Color(0.34, 0.49, 0.38)))
	match node.node_type:
		"regular":
			return Color(_palette.get("regular", Color(0.21, 0.47, 0.37)))
		"elite":
			return Color(_palette.get("elite", Color(0.65, 0.29, 0.19)))
		"boss":
			return Color(_palette.get("boss", Color(0.76, 0.59, 0.16)))
		"rest":
			return Color(_palette.get("rest", Color(0.24, 0.56, 0.42)))
		"event":
			return Color(_palette.get("event", Color(0.17, 0.41, 0.54)))
		"shop":
			return Color(_palette.get("shop", Color(0.42, 0.42, 0.22)))
		"treasure":
			return Color(_palette.get("treasure", Color(0.63, 0.48, 0.18)))
		_:
			return Color(0.38, 0.38, 0.38)

func _lane_ratio(lane: int, floor_count: int) -> float:
	if floor_count <= 1:
		return 0.5
	return float(lane) / float(floor_count - 1)

func _floor_ratio(floor: int, max_floor: int) -> float:
	if max_floor <= 0:
		return 0.0
	return float(floor) / float(max_floor)
