class_name RestCheckpointView
extends Control

var _theme: Dictionary = {}
var _subject: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func apply_theme(theme: Dictionary) -> void:
	_theme = theme.duplicate(true)
	queue_redraw()

func apply_subject(subject: Dictionary) -> void:
	_subject = subject.duplicate(true)
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var background: Color = Color(_theme.get("background", Color(0.06, 0.09, 0.10)))
	var panel: Color = Color(_theme.get("panel", Color(0.10, 0.15, 0.16)))
	var panel_alt: Color = Color(_theme.get("panel_alt", Color(0.15, 0.22, 0.20)))
	var border: Color = Color(_theme.get("border", Color(0.72, 0.92, 0.74)))
	var accent: Color = Color(_theme.get("accent", Color(0.92, 0.98, 0.90)))
	var player_accent: Color = Color(_subject.get("accent_color", border))
	var player_glow: Color = Color(_subject.get("glow_color", player_accent))
	var ground_dark := panel.darkened(0.32)
	var ground_mid := panel_alt.darkened(0.16)
	var sky_top := background.darkened(0.18).lerp(Color(0.05, 0.08, 0.14), 0.35)
	var sky_bottom := background.lerp(panel, 0.55)

	_draw_vertical_gradient(Rect2(Vector2.ZERO, size), sky_top, sky_bottom, 72)
	_draw_canopy(panel_alt, border)
	_draw_ground(ground_dark, ground_mid)
	_draw_distant_tents(panel_alt, accent)
	_draw_camp_props(panel_alt, border, accent)
	_draw_fire_ring(player_accent, player_glow, accent)
	_draw_figures(player_accent, border, accent)
	_draw_foreground_shadows(ground_dark, border)

func _draw_vertical_gradient(area: Rect2, start_color: Color, end_color: Color, strips: int) -> void:
	var count := maxi(1, strips)
	for strip_index in range(count):
		var t0 := float(strip_index) / float(count)
		var t1 := float(strip_index + 1) / float(count)
		var band_color := start_color.lerp(end_color, t0)
		draw_rect(Rect2(area.position.x, area.position.y + area.size.y * t0, area.size.x, area.size.y * (t1 - t0) + 1.0), band_color)

func _draw_canopy(panel_alt: Color, border: Color) -> void:
	var canopy := panel_alt.darkened(0.28)
	canopy.a = 0.86
	var vine := border.darkened(0.38)
	vine.a = 0.28
	draw_rect(Rect2(0.0, 0.0, size.x, size.y * 0.22), canopy)
	for index in range(8):
		var x := lerpf(size.x * 0.08, size.x * 0.92, float(index) / 7.0)
		draw_line(Vector2(x, 0.0), Vector2(x + 18.0 * sin(float(index) * 1.8), size.y * (0.08 + 0.04 * (index % 3))), vine, 2.0, true)
		draw_circle(Vector2(x + 12.0, size.y * 0.11), 3.0, vine)
	var haze := border.lightened(0.15)
	haze.a = 0.06
	draw_circle(Vector2(size.x * 0.50, size.y * 0.18), size.x * 0.36, haze)

func _draw_ground(ground_dark: Color, ground_mid: Color) -> void:
	draw_rect(Rect2(0.0, size.y * 0.58, size.x, size.y * 0.42), ground_dark)
	draw_rect(Rect2(0.0, size.y * 0.46, size.x, size.y * 0.16), ground_mid)
	var court_line := Color(0.90, 0.92, 0.84, 0.12)
	draw_line(Vector2(size.x * 0.16, size.y * 0.78), Vector2(size.x * 0.84, size.y * 0.78), court_line, 2.0, true)
	draw_line(Vector2(size.x * 0.50, size.y * 0.64), Vector2(size.x * 0.50, size.y * 0.92), court_line, 2.0, true)

func _draw_distant_tents(panel_alt: Color, accent: Color) -> void:
	var tent_fill := panel_alt.darkened(0.20)
	var tent_edge := accent.darkened(0.22)
	tent_edge.a = 0.34
	_draw_tent(Vector2(size.x * 0.19, size.y * 0.50), Vector2(112.0, 72.0), tent_fill, tent_edge)
	_draw_tent(Vector2(size.x * 0.80, size.y * 0.47), Vector2(128.0, 78.0), tent_fill.lightened(0.04), tent_edge)
	var bench := panel_alt.darkened(0.16)
	draw_rect(Rect2(size.x * 0.69, size.y * 0.59, 118.0, 12.0), bench)
	draw_rect(Rect2(size.x * 0.72, size.y * 0.61, 10.0, 42.0), bench.darkened(0.12))
	draw_rect(Rect2(size.x * 0.84, size.y * 0.61, 10.0, 42.0), bench.darkened(0.12))

func _draw_tent(center: Vector2, footprint: Vector2, fill: Color, edge: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(-footprint.x * 0.5, footprint.y * 0.5),
		center + Vector2(0.0, -footprint.y * 0.5),
		center + Vector2(footprint.x * 0.5, footprint.y * 0.5),
	])
	_solid_polygon(points, fill)
	draw_line(points[0], points[1], edge, 2.0, true)
	draw_line(points[1], points[2], edge, 2.0, true)
	draw_line(points[0], points[2], edge, 2.0, true)

func _draw_camp_props(panel_alt: Color, border: Color, accent: Color) -> void:
	var bag_fill := panel_alt.darkened(0.18)
	var bag_edge := border.darkened(0.20)
	draw_rect(Rect2(size.x * 0.10, size.y * 0.72, 62.0, 34.0), bag_fill)
	draw_rect(Rect2(size.x * 0.12, size.y * 0.69, 26.0, 12.0), bag_fill.lightened(0.04))
	draw_line(Vector2(size.x * 0.15, size.y * 0.72), Vector2(size.x * 0.20, size.y * 0.66), bag_edge, 2.0, true)
	draw_line(Vector2(size.x * 0.20, size.y * 0.66), Vector2(size.x * 0.23, size.y * 0.75), bag_edge, 2.0, true)

	var cooler_fill := accent.darkened(0.36)
	draw_rect(Rect2(size.x * 0.26, size.y * 0.73, 54.0, 34.0), cooler_fill)
	draw_rect(Rect2(size.x * 0.26, size.y * 0.72, 54.0, 10.0), cooler_fill.lightened(0.10))

	var crate := panel_alt.darkened(0.10)
	draw_rect(Rect2(size.x * 0.76, size.y * 0.74, 50.0, 30.0), crate)
	draw_line(Vector2(size.x * 0.76, size.y * 0.74), Vector2(size.x * 0.81, size.y * 0.77), border.darkened(0.20), 2.0, true)
	draw_line(Vector2(size.x * 0.81, size.y * 0.74), Vector2(size.x * 0.76, size.y * 0.77), border.darkened(0.20), 2.0, true)

	var lamp_glow := accent.lightened(0.18)
	lamp_glow.a = 0.16
	var lamp_pos := Vector2(size.x * 0.62, size.y * 0.34)
	draw_circle(lamp_pos, 12.0, accent.darkened(0.18))
	draw_circle(lamp_pos, 60.0, lamp_glow)
	draw_line(lamp_pos + Vector2(0.0, 12.0), lamp_pos + Vector2(0.0, 88.0), accent.darkened(0.26), 3.0, true)

func _draw_fire_ring(player_accent: Color, player_glow: Color, accent: Color) -> void:
	var fire_center := Vector2(size.x * 0.50, size.y * 0.73)
	var outer_glow := player_glow.lightened(0.20)
	outer_glow.a = 0.18
	draw_circle(fire_center, 84.0, outer_glow)
	var ember := Color(1.0, 0.54, 0.18, 0.84)
	draw_circle(fire_center, 42.0, Color(1.0, 0.78, 0.34, 0.15))
	_solid_polygon(PackedVector2Array([
		fire_center + Vector2(-24.0, 20.0),
		fire_center + Vector2(0.0, -38.0),
		fire_center + Vector2(20.0, 18.0),
	]), ember)
	_solid_polygon(PackedVector2Array([
		fire_center + Vector2(-10.0, 22.0),
		fire_center + Vector2(10.0, -18.0),
		fire_center + Vector2(28.0, 20.0),
	]), accent.lightened(0.18))
	draw_line(fire_center + Vector2(-30.0, 28.0), fire_center + Vector2(18.0, 12.0), player_accent.darkened(0.32), 8.0, true)
	draw_line(fire_center + Vector2(-14.0, 10.0), fire_center + Vector2(30.0, 30.0), player_accent.darkened(0.38), 8.0, true)
	var smoke := accent.lightened(0.16)
	smoke.a = 0.12
	for puff in range(4):
		draw_circle(fire_center + Vector2(18.0 * sin(float(puff) * 0.9), -38.0 - 24.0 * puff), 18.0 + 5.0 * puff, smoke)

func _draw_figures(player_accent: Color, border: Color, accent: Color) -> void:
	var player_tint := player_accent.darkened(0.14)
	var support_tint := border.darkened(0.22)
	_draw_seated_figure(Vector2(size.x * 0.34, size.y * 0.77), player_tint, true)
	_draw_seated_figure(Vector2(size.x * 0.66, size.y * 0.77), support_tint, false)
	var racquet_edge := accent.lightened(0.10)
	draw_line(Vector2(size.x * 0.28, size.y * 0.69), Vector2(size.x * 0.24, size.y * 0.84), racquet_edge, 4.0, true)
	draw_arc(Vector2(size.x * 0.285, size.y * 0.66), 16.0, 0.0, TAU, 20, racquet_edge, 3.0, true)

func _draw_seated_figure(anchor: Vector2, tint: Color, left_facing: bool) -> void:
	var direction := -1.0 if left_facing else 1.0
	var shadow := tint.darkened(0.62)
	shadow.a = 0.18
	_draw_soft_ellipse(Rect2(anchor.x - 42.0, anchor.y - 6.0, 84.0, 20.0), shadow, 18)
	draw_circle(anchor + Vector2(0.0, -52.0), 13.0, tint.lightened(0.08))
	draw_line(anchor + Vector2(0.0, -40.0), anchor + Vector2(0.0, -6.0), tint, 12.0, true)
	draw_line(anchor + Vector2(0.0, -28.0), anchor + Vector2(24.0 * direction, -18.0), tint, 8.0, true)
	draw_line(anchor + Vector2(0.0, -24.0), anchor + Vector2(-24.0 * direction, -4.0), tint, 8.0, true)
	draw_line(anchor + Vector2(0.0, -8.0), anchor + Vector2(26.0 * direction, 18.0), tint, 10.0, true)
	draw_line(anchor + Vector2(0.0, -8.0), anchor + Vector2(-18.0 * direction, 20.0), tint, 10.0, true)
	draw_line(anchor + Vector2(-18.0 * direction, 20.0), anchor + Vector2(-4.0 * direction, 26.0), tint, 8.0, true)

func _draw_foreground_shadows(ground_dark: Color, border: Color) -> void:
	var vignette := ground_dark.darkened(0.22)
	vignette.a = 0.22
	draw_circle(Vector2(size.x * 0.08, size.y * 0.90), size.y * 0.18, vignette)
	draw_circle(Vector2(size.x * 0.90, size.y * 0.88), size.y * 0.20, vignette)
	var rim := border
	rim.a = 0.08
	draw_line(Vector2(size.x * 0.16, size.y * 0.78), Vector2(size.x * 0.84, size.y * 0.78), rim, 2.0, true)

func _draw_soft_ellipse(area: Rect2, color_value: Color, points_count: int) -> void:
	var ellipse_points := PackedVector2Array()
	var center := area.get_center()
	var radius_x := area.size.x * 0.5
	var radius_y := area.size.y * 0.5
	for point_idx in range(maxi(12, points_count)):
		var angle := TAU * float(point_idx) / float(maxi(12, points_count))
		ellipse_points.append(Vector2(center.x + cos(angle) * radius_x, center.y + sin(angle) * radius_y))
	_solid_polygon(ellipse_points, color_value)

func _solid_polygon(points: PackedVector2Array, color_value: Color) -> void:
	var colors := PackedColorArray()
	for _unused in points:
		colors.append(color_value)
	draw_polygon(points, colors)
