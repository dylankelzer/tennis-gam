class_name CheckpointHeaderArt
extends Control

var _theme: Dictionary = {}
var _mode: String = "reward"
var _title: String = ""
var _subtitle: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, 136.0)
	queue_redraw()

func apply_header(theme: Dictionary, mode: String, title: String, subtitle: String) -> void:
	_theme = theme.duplicate(true)
	_mode = mode
	_title = title
	_subtitle = subtitle
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var rect := Rect2(Vector2.ZERO, size)
	var background := Color(_theme.get("background", Color(0.08, 0.11, 0.12)))
	var panel := Color(_theme.get("panel", Color(0.12, 0.15, 0.17)))
	var panel_alt := Color(_theme.get("panel_alt", Color(0.16, 0.19, 0.22)))
	var accent := Color(_theme.get("accent", Color(0.92, 0.96, 0.98)))
	var border := Color(_theme.get("border", accent))
	var text_color := Color(_theme.get("text", Color.WHITE))

	var top := panel_alt.lightened(0.10).lerp(accent, 0.08)
	var bottom := panel.darkened(0.14).lerp(background, 0.26)
	_draw_vertical_gradient(rect, top, bottom, 42)
	draw_rect(Rect2(0.0, 0.0, rect.size.x, rect.size.y * 0.24), Color(1.0, 1.0, 1.0, 0.07))
	draw_rect(rect.grow(-2.0), Color(1.0, 1.0, 1.0, 0.05), false, 1.2)
	draw_rect(rect.grow(-8.0), border.lightened(0.10), false, 2.0)

	_draw_center_court(rect, border)
	_draw_side_banner(Rect2(rect.position.x + 18.0, rect.position.y + 18.0, 94.0, rect.size.y - 36.0), accent, border, true)
	_draw_side_banner(Rect2(rect.end.x - 112.0, rect.position.y + 18.0, 94.0, rect.size.y - 36.0), accent, border, false)
	_draw_mode_markers(rect, accent, border)
	_draw_text(rect, text_color, accent)

func _draw_vertical_gradient(area: Rect2, start_color: Color, end_color: Color, strips: int) -> void:
	for strip_index in range(maxi(1, strips)):
		var t0 := float(strip_index) / float(maxi(1, strips))
		var t1 := float(strip_index + 1) / float(maxi(1, strips))
		var band_color := start_color.lerp(end_color, t0)
		draw_rect(Rect2(area.position.x, area.position.y + area.size.y * t0, area.size.x, area.size.y * (t1 - t0) + 1.0), band_color)

func _draw_center_court(rect: Rect2, border: Color) -> void:
	var court := Rect2(rect.size.x * 0.27, rect.size.y * 0.18, rect.size.x * 0.46, rect.size.y * 0.64)
	var line := border.lightened(0.24)
	line.a = 0.26
	draw_rect(court, line, false, 2.0)
	draw_line(Vector2(court.position.x + court.size.x * 0.50, court.position.y), Vector2(court.position.x + court.size.x * 0.50, court.end.y), line, 2.0, true)
	draw_line(Vector2(court.position.x, court.position.y + court.size.y * 0.50), Vector2(court.end.x, court.position.y + court.size.y * 0.50), line, 2.0, true)
	var service_top := court.position.y + court.size.y * 0.27
	var service_bottom := court.position.y + court.size.y * 0.73
	draw_line(Vector2(court.position.x + court.size.x * 0.16, service_top), Vector2(court.end.x - court.size.x * 0.16, service_top), line, 1.4, true)
	draw_line(Vector2(court.position.x + court.size.x * 0.16, service_bottom), Vector2(court.end.x - court.size.x * 0.16, service_bottom), line, 1.4, true)
	draw_circle(Vector2(court.position.x + court.size.x * 0.74, court.position.y + court.size.y * 0.26), 6.0, Color(1.0, 1.0, 1.0, 0.18))

func _draw_side_banner(area: Rect2, accent: Color, border: Color, left_side: bool) -> void:
	var fill := accent.darkened(0.22)
	fill.a = 0.16
	draw_rect(area, fill)
	draw_rect(area, border, false, 1.6)
	var strip := Rect2(area.position.x, area.position.y, area.size.x, 18.0)
	draw_rect(strip, Color(1.0, 1.0, 1.0, 0.08))
	var icon_center := area.get_center() + Vector2(0.0, -8.0)
	match _mode:
		"shop":
			_draw_coin_stack(icon_center, accent, border)
			_draw_bottle(icon_center + Vector2(0.0, 22.0), accent.lightened(0.06), border)
		"rest":
			_draw_racquet_icon(icon_center, accent, border, left_side)
			_draw_moon_ball(icon_center + Vector2(0.0, 24.0), accent, border)
		"path":
			_draw_bracket_icon(icon_center, accent, border)
			_draw_route_ball(icon_center + Vector2(0.0, 24.0), accent, border, left_side)
		_:
			_draw_trophy_icon(icon_center, accent, border)
			_draw_ball_star(icon_center + Vector2(0.0, 24.0), accent, border)

func _draw_mode_markers(rect: Rect2, accent: Color, border: Color) -> void:
	var base_y := rect.size.y - 18.0
	var center_x := rect.size.x * 0.50
	for marker in range(5):
		var x := center_x + (float(marker) - 2.0) * 18.0
		var color_value := accent.lightened(0.08)
		color_value.a = 0.22 if marker != 2 else 0.48
		draw_circle(Vector2(x, base_y), 4.0, color_value)
	_draw_tennis_seams(Vector2(center_x, base_y), border, 6.0)

func _draw_text(rect: Rect2, text_color: Color, accent: Color) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var title_color := accent.lightened(0.08)
	var subtitle_color := text_color
	subtitle_color.a = 0.90
	draw_string(font, Vector2(rect.size.x * 0.29, rect.size.y * 0.42), _title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.42, 24, title_color)
	draw_string(font, Vector2(rect.size.x * 0.29, rect.size.y * 0.62), _subtitle, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.42, 14, subtitle_color)

func _draw_trophy_icon(center: Vector2, accent: Color, border: Color) -> void:
	var cup := PackedVector2Array([
		center + Vector2(-16.0, -18.0),
		center + Vector2(16.0, -18.0),
		center + Vector2(10.0, -2.0),
		center + Vector2(0.0, 10.0),
		center + Vector2(-10.0, -2.0),
	])
	_fill_polygon(cup, accent)
	draw_polyline(cup + PackedVector2Array([cup[0]]), border, 1.8, true)
	draw_line(center + Vector2(-16.0, -14.0), center + Vector2(-24.0, -6.0), accent, 2.4, true)
	draw_line(center + Vector2(16.0, -14.0), center + Vector2(24.0, -6.0), accent, 2.4, true)
	draw_rect(Rect2(center.x - 4.0, center.y + 8.0, 8.0, 10.0), accent.darkened(0.22))
	draw_rect(Rect2(center.x - 14.0, center.y + 18.0, 28.0, 6.0), accent.darkened(0.22))

func _draw_coin_stack(center: Vector2, accent: Color, border: Color) -> void:
	for idx in range(3):
		var y := center.y + float(idx) * 5.0
		draw_arc(Vector2(center.x, y), 18.0, 0.0, TAU, 24, accent.lightened(0.08), 2.0, true)
		draw_arc(Vector2(center.x, y), 10.0, 0.0, TAU, 24, border, 1.0, true)

func _draw_bottle(center: Vector2, accent: Color, border: Color) -> void:
	var body := Rect2(center.x - 10.0, center.y - 14.0, 20.0, 30.0)
	draw_rect(body, accent)
	draw_rect(body, border, false, 1.6)
	draw_rect(Rect2(center.x - 5.0, center.y - 20.0, 10.0, 8.0), accent.darkened(0.18))
	draw_rect(Rect2(center.x - 8.0, center.y - 4.0, 16.0, 6.0), Color(1.0, 1.0, 1.0, 0.18))

func _draw_racquet_icon(center: Vector2, accent: Color, border: Color, left_side: bool) -> void:
	var facing := -1.0 if left_side else 1.0
	var head_center := center + Vector2(6.0 * facing, -8.0)
	_draw_ellipse_outline(head_center, Vector2(16.0, 20.0), accent.lightened(0.06), 2.4)
	for idx in range(3):
		var x_off := lerpf(-8.0, 8.0, float(idx) / 2.0)
		draw_line(head_center + Vector2(x_off, -12.0), head_center + Vector2(x_off, 12.0), border, 1.0, true)
		var y_off := lerpf(-10.0, 10.0, float(idx) / 2.0)
		draw_line(head_center + Vector2(-9.0, y_off), head_center + Vector2(9.0, y_off), border, 1.0, true)
	draw_line(center + Vector2(-4.0 * facing, 10.0), center + Vector2(-18.0 * facing, 28.0), Color(0.93, 0.80, 0.58, 1.0), 3.0, true)

func _draw_moon_ball(center: Vector2, accent: Color, border: Color) -> void:
	draw_circle(center, 10.0, accent)
	_draw_tennis_seams(center, border, 8.0)
	draw_arc(center + Vector2(0.0, 0.0), 18.0, 0.6, 2.6, 18, accent.lightened(0.12), 2.0, true)

func _draw_ball_star(center: Vector2, accent: Color, border: Color) -> void:
	draw_circle(center, 9.0, accent)
	_draw_tennis_seams(center, border, 7.0)
	for idx in range(4):
		var angle := TAU * float(idx) / 4.0
		draw_line(center, center + Vector2(cos(angle), sin(angle)) * 18.0, accent.lightened(0.10), 2.0, true)

func _draw_bracket_icon(center: Vector2, accent: Color, border: Color) -> void:
	for side in [-1, 1]:
		var x: float = center.x + float(side) * 6.0
		draw_line(Vector2(x, center.y - 16.0), Vector2(x, center.y + 16.0), accent, 2.2, true)
		draw_line(Vector2(x, center.y - 10.0), Vector2(center.x, center.y - 10.0), accent, 2.2, true)
		draw_line(Vector2(x, center.y + 10.0), Vector2(center.x, center.y + 10.0), accent, 2.2, true)
	draw_line(Vector2(center.x, center.y - 10.0), Vector2(center.x, center.y + 10.0), border, 2.6, true)
	draw_circle(center + Vector2(0.0, -10.0), 3.0, border)
	draw_circle(center + Vector2(0.0, 10.0), 3.0, border)

func _draw_route_ball(center: Vector2, accent: Color, border: Color, left_side: bool) -> void:
	var facing := 1.0 if left_side else -1.0
	draw_circle(center, 8.0, accent)
	_draw_tennis_seams(center, border, 6.0)
	var trail := PackedVector2Array([
		center + Vector2(-18.0 * facing, -8.0),
		center + Vector2(-6.0 * facing, -4.0),
		center + Vector2(10.0 * facing, 4.0),
		center + Vector2(22.0 * facing, 12.0),
	])
	draw_polyline(trail, accent.lightened(0.12), 2.4, true)

func _draw_tennis_seams(center: Vector2, color_value: Color, radius: float) -> void:
	draw_arc(center, radius, -0.8, 0.8, 12, color_value, 1.0, true)
	draw_arc(center, radius, PI - 0.8, PI + 0.8, 12, color_value, 1.0, true)

func _draw_ellipse_outline(center: Vector2, radii: Vector2, color_value: Color, width: float) -> void:
	var points := PackedVector2Array()
	for segment in range(37):
		var angle := TAU * float(segment) / 36.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_polyline(points, color_value, width, true)

func _fill_polygon(points: PackedVector2Array, color_value: Color) -> void:
	var colors := PackedColorArray()
	for _unused in points:
		colors.append(color_value)
	draw_polygon(points, colors)
