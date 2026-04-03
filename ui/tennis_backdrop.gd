class_name TennisBackdrop
extends ColorRect

var _sky_top: Color = Color(0.93, 0.82, 0.68, 1.0)
var _sky_bottom: Color = Color(0.73, 0.86, 0.93, 1.0)
var _haze_color: Color = Color(0.97, 0.92, 0.82, 0.32)
var _court_top: Color = Color(0.20, 0.46, 0.68, 1.0)
var _court_bottom: Color = Color(0.09, 0.22, 0.35, 1.0)
var _walkway_color: Color = Color(0.73, 0.58, 0.42, 1.0)
var _line_color: Color = Color(0.92, 0.96, 0.87, 0.92)
var _net_color: Color = Color(0.95, 0.97, 0.94, 0.68)
var _shadow_color: Color = Color(0.07, 0.12, 0.10, 0.14)
var _foliage_color: Color = Color(0.31, 0.45, 0.28, 0.24)
var _sun_color: Color = Color(1.0, 0.90, 0.72, 0.32)
var _surface_texture: Texture2D = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(0, 0, 0, 0)
	queue_redraw()

func set_surface_texture(texture: Texture2D) -> void:
	_surface_texture = texture
	queue_redraw()

func apply_backdrop_theme(theme: Dictionary, is_idle: bool = false) -> void:
	var background: Color = Color(theme.get("background", Color(0.08, 0.11, 0.12)))
	var accent: Color = Color(theme.get("accent", Color(0.89, 0.93, 0.92)))
	var panel_alt: Color = Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22)))
	var border: Color = Color(theme.get("border", accent))

	if is_idle:
		_sky_top = Color(0.96, 0.85, 0.71, 1.0)
		_sky_bottom = Color(0.69, 0.84, 0.92, 1.0)
		_haze_color = Color(0.99, 0.93, 0.84, 0.36)
		_court_top = Color(0.25, 0.50, 0.72, 1.0)
		_court_bottom = Color(0.12, 0.25, 0.39, 1.0)
		_walkway_color = Color(0.74, 0.58, 0.41, 1.0)
		_line_color = Color(0.96, 0.97, 0.90, 0.95)
		_net_color = Color(0.97, 0.98, 0.94, 0.70)
		_shadow_color = Color(0.06, 0.12, 0.09, 0.12)
		_foliage_color = Color(0.27, 0.42, 0.24, 0.22)
		_sun_color = Color(1.0, 0.92, 0.74, 0.34)
	else:
		_sky_top = background.lightened(0.42).lerp(Color(0.96, 0.83, 0.69, 1.0), 0.22)
		_sky_bottom = background.lightened(0.18).lerp(accent.lightened(0.08), 0.28)
		_haze_color = accent.lightened(0.15)
		_haze_color.a = 0.22
		_court_top = background.lerp(accent, 0.34)
		_court_bottom = background.darkened(0.12).lerp(panel_alt, 0.32)
		_walkway_color = panel_alt.lightened(0.10).lerp(Color(0.68, 0.54, 0.40, 1.0), 0.28)
		_line_color = Color(0.95, 0.97, 0.91, 0.90)
		_net_color = Color(0.97, 0.98, 0.94, 0.64)
		_shadow_color = background.darkened(0.35)
		_shadow_color.a = 0.16
		_foliage_color = border.darkened(0.25)
		_foliage_color.a = 0.18
		_sun_color = accent.lightened(0.22)
		_sun_color.a = 0.20
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_draw_vertical_gradient(Rect2(Vector2.ZERO, size), _sky_top, _sky_bottom, 72)
	_draw_surface_texture()
	_draw_haze()
	_draw_garden_shadows()
	_draw_vignette()
	_draw_court()

func _draw_vertical_gradient(area: Rect2, start_color: Color, end_color: Color, strips: int) -> void:
	var strip_count := maxi(1, strips)
	for strip_index in range(strip_count):
		var t0 := float(strip_index) / float(strip_count)
		var t1 := float(strip_index + 1) / float(strip_count)
		var y := area.position.y + area.size.y * t0
		var height := area.size.y * (t1 - t0) + 1.0
		var band_color := start_color.lerp(end_color, t0)
		draw_rect(Rect2(area.position.x, y, area.size.x, height), band_color)

func _draw_haze() -> void:
	draw_circle(Vector2(size.x * 0.17, size.y * 0.16), min(size.x, size.y) * 0.11, _sun_color)
	draw_circle(Vector2(size.x * 0.19, size.y * 0.19), min(size.x, size.y) * 0.18, _haze_color)
	draw_rect(Rect2(0.0, size.y * 0.28, size.x, size.y * 0.08), _haze_color)
	draw_rect(Rect2(0.0, 0.0, size.x, size.y * 0.14), Color(1.0, 1.0, 1.0, 0.05))

func _draw_surface_texture() -> void:
	if _surface_texture == null:
		return
	var tint := Color(1.0, 1.0, 1.0, 0.22)
	draw_texture_rect(_surface_texture, Rect2(Vector2.ZERO, size), true, tint)

func _draw_vignette() -> void:
	var edge := Color(0.02, 0.05, 0.09, 0.10)
	draw_rect(Rect2(0.0, 0.0, size.x, size.y * 0.10), edge)
	draw_rect(Rect2(0.0, size.y * 0.90, size.x, size.y * 0.10), edge)
	draw_circle(Vector2(-size.x * 0.04, size.y * 0.46), size.y * 0.52, edge)
	draw_circle(Vector2(size.x * 1.04, size.y * 0.48), size.y * 0.56, edge)
	var sweep := PackedVector2Array([
		Vector2(size.x * 0.52, 0.0),
		Vector2(size.x * 0.76, 0.0),
		Vector2(size.x * 0.48, size.y),
		Vector2(size.x * 0.24, size.y),
	])
	_solid_polygon(sweep, Color(1.0, 1.0, 1.0, 0.04))

func _draw_garden_shadows() -> void:
	draw_circle(Vector2(size.x * 0.05, size.y * 0.23), size.y * 0.18, _foliage_color)
	draw_circle(Vector2(size.x * 0.96, size.y * 0.18), size.y * 0.20, _foliage_color)
	draw_circle(Vector2(size.x * 0.86, size.y * 0.86), size.y * 0.22, _shadow_color)
	draw_circle(Vector2(size.x * 0.18, size.y * 0.90), size.y * 0.20, _shadow_color)

func _draw_court() -> void:
	var top_y := size.y * 0.34
	var bottom_y := size.y * 0.97
	var top_left := Vector2(size.x * 0.29, top_y)
	var top_right := Vector2(size.x * 0.71, top_y)
	var bottom_left := Vector2(size.x * 0.05, bottom_y)
	var bottom_right := Vector2(size.x * 0.95, bottom_y)
	var walkway_top_left := Vector2(size.x * 0.01, size.y * 0.90)
	var walkway_top_right := Vector2(size.x * 0.99, size.y * 0.90)

	_solid_polygon(
		PackedVector2Array([walkway_top_left, walkway_top_right, bottom_right, bottom_left]),
		_walkway_color
	)

	var court_points := PackedVector2Array([top_left, top_right, bottom_right, bottom_left])
	_solid_polygon(court_points, _court_bottom)
	_solid_polygon(
		PackedVector2Array([
			top_left.lerp(bottom_left, 0.18),
			top_right.lerp(bottom_right, 0.18),
			bottom_right.lerp(top_right, 0.08),
			bottom_left.lerp(top_left, 0.08),
		]),
		_court_top
	)
	for stripe_index in range(8):
		var stripe_rect := Rect2(
			lerpf(top_left.x, bottom_left.x, 0.04) + float(stripe_index) * (bottom_right.x - bottom_left.x) / 8.0,
			top_y + 6.0,
			(bottom_right.x - bottom_left.x) / 8.0 + 2.0,
			(bottom_y - top_y) * 0.86
		)
		var stripe := _court_top.lightened(0.04 if stripe_index % 2 == 0 else -0.02)
		stripe.a = 0.10
		draw_rect(stripe_rect, stripe)

	var court_shadow := _shadow_color
	court_shadow.a *= 0.7
	_solid_polygon(
		PackedVector2Array([
			Vector2(size.x * 0.00, size.y * 0.94),
			Vector2(size.x * 0.20, size.y * 0.82),
			Vector2(size.x * 0.31, size.y * 0.82),
			Vector2(size.x * 0.00, size.y * 0.99),
		]),
		court_shadow
	)

	_draw_court_lines(top_left, top_right, bottom_left, bottom_right)
	_draw_net(top_left, top_right, bottom_left, bottom_right)

func _draw_court_lines(top_left: Vector2, top_right: Vector2, bottom_left: Vector2, bottom_right: Vector2) -> void:
	var outer_left := [top_left, bottom_left]
	var outer_right := [top_right, bottom_right]
	var singles_top_left := top_left.lerp(top_right, 0.12)
	var singles_top_right := top_right.lerp(top_left, 0.12)
	var singles_bottom_left := bottom_left.lerp(bottom_right, 0.12)
	var singles_bottom_right := bottom_right.lerp(bottom_left, 0.12)
	var service_ratio := 0.43
	var service_left := singles_top_left.lerp(singles_bottom_left, service_ratio)
	var service_right := singles_top_right.lerp(singles_bottom_right, service_ratio)
	var service_left_far := singles_top_left.lerp(singles_bottom_left, 0.73)
	var service_right_far := singles_top_right.lerp(singles_bottom_right, 0.73)
	var center_service_top := service_left.lerp(service_right, 0.5)
	var center_service_bottom := service_left_far.lerp(service_right_far, 0.5)

	_draw_border_line(outer_left[0], outer_right[0], 3.0)
	_draw_border_line(outer_left[1], outer_right[1], 3.2)
	_draw_border_line(outer_left[0], outer_left[1], 3.0)
	_draw_border_line(outer_right[0], outer_right[1], 3.0)
	_draw_border_line(singles_top_left, singles_bottom_left, 2.2)
	_draw_border_line(singles_top_right, singles_bottom_right, 2.2)
	_draw_border_line(service_left, service_right, 2.0)
	_draw_border_line(service_left_far, service_right_far, 2.0)
	_draw_border_line(center_service_top, center_service_bottom, 2.0)
	_draw_border_line(
		Vector2((top_left.x + top_right.x) * 0.5 - 18.0, top_left.y - 16.0),
		Vector2((top_left.x + top_right.x) * 0.5 + 18.0, top_left.y - 16.0),
		1.4
	)

func _draw_net(top_left: Vector2, top_right: Vector2, bottom_left: Vector2, bottom_right: Vector2) -> void:
	var net_left := top_left.lerp(bottom_left, 0.29)
	var net_right := top_right.lerp(bottom_right, 0.29)
	draw_line(net_left, net_right, _net_color, 3.0, true)
	var post_color := _net_color
	post_color.a = 0.85
	draw_line(net_left, net_left + Vector2(0.0, -size.y * 0.035), post_color, 2.0, true)
	draw_line(net_right, net_right + Vector2(0.0, -size.y * 0.035), post_color, 2.0, true)

func _draw_border_line(from_point: Vector2, to_point: Vector2, width: float) -> void:
	draw_line(from_point, to_point, _line_color, width, true)

func _solid_polygon(points: PackedVector2Array, color_value: Color) -> void:
	var colors := PackedColorArray()
	for _unused in points:
		colors.append(color_value)
	draw_polygon(points, colors)
