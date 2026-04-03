class_name BadgeIcon
extends Control

static var _render_cache: Dictionary = {}
static var _cache_generation: int = 0
const _MAX_CACHE_SIZE := 128

var _icon_kind: String = "ball"
var _icon_texture: Texture2D = null
var _cached_draw_key: String = ""

@export var icon_kind: String = "ball":
	set(value):
		if _icon_kind != value:
			_icon_kind = value
			_cached_draw_key = ""
			queue_redraw()
	get:
		return _icon_kind
@export var accent_color: Color = Color(0.88, 0.95, 0.50, 1.0)
@export var rim_color: Color = Color(0.96, 0.98, 0.90, 1.0)
@export var fill_color: Color = Color(0.12, 0.24, 0.34, 0.95)

static func clear_render_cache() -> void:
	_render_cache.clear()
	_cache_generation += 1

func _make_cache_key() -> String:
	return "%s|%s|%s|%s|%dx%d" % [_icon_kind, accent_color.to_html(), rim_color.to_html(), fill_color.to_html(), int(size.x), int(size.y)]

func _ready() -> void:
	custom_minimum_size = Vector2(54, 54)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _theme_manager():
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return null
	return tree.current_scene.get_node_or_null("ThemeManager")

func set_palette(accent: Color, rim: Color) -> void:
	if accent_color != accent or rim_color != rim:
		accent_color = accent
		rim_color = rim
		_cached_draw_key = ""
		queue_redraw()

func set_icon_texture(texture: Texture2D) -> void:
	if _icon_texture != texture:
		_icon_texture = texture
		_cached_draw_key = ""
		queue_redraw()

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var center: Vector2 = rect.get_center()
	var radius: float = minf(size.x, size.y) * 0.42
	var resolved_texture := _icon_texture
	if resolved_texture == null:
		var theme_manager = _theme_manager()
		if theme_manager != null and theme_manager.has_method("get_icon_texture"):
			resolved_texture = theme_manager.call("get_icon_texture", _icon_kind)
	draw_circle(center, radius, fill_color)
	draw_circle(center + Vector2(0.0, radius * 0.12), radius * 0.96, Color(0.0, 0.0, 0.0, 0.10))
	draw_circle(center + Vector2(0.0, -radius * 0.08), radius * 0.82, accent_color.darkened(0.20))
	draw_rect(Rect2(center.x - radius * 0.78, center.y - radius * 0.82, radius * 1.56, radius * 0.44), Color(1.0, 1.0, 1.0, 0.10))
	draw_arc(center, radius, 0.0, TAU, 48, rim_color, 2.4, true)
	draw_arc(center, radius * 0.78, 0.0, TAU, 36, Color(1.0, 1.0, 1.0, 0.12), 1.0, true)
	if resolved_texture != null:
		var icon_rect := Rect2(center - Vector2(radius * 0.54, radius * 0.54), Vector2(radius * 1.08, radius * 1.08))
		var shadow_rect := Rect2(icon_rect.position + Vector2(0.0, 1.4), icon_rect.size)
		draw_texture_rect(resolved_texture, shadow_rect, false, Color(0.02, 0.04, 0.08, 0.26))
		draw_texture_rect(resolved_texture, icon_rect, false, Color(1.0, 1.0, 1.0, 0.94))
		return
	match _icon_kind:
		"bitcoin":
			_draw_bitcoin(center, radius)
		"potion":
			_draw_potion(center, radius)
		"stamina_potion":
			_draw_stamina_potion(center, radius)
		"spin_potion":
			_draw_spin_potion(center, radius)
		"focus_potion":
			_draw_focus_potion(center, radius)
		"clutch_potion":
			_draw_clutch_potion(center, radius)
		"poly":
			_draw_poly_string(center, radius)
		"gut":
			_draw_gut_string(center, radius)
		"multi":
			_draw_multi_string(center, radius)
		"synthetic":
			_draw_synthetic_string(center, radius)
		"racquet_tune":
			_draw_racquet_tune(center, radius)
		"serve":
			_draw_serve(center, radius)
		"return":
			_draw_return(center, radius)
		"rally":
			_draw_rally(center, radius)
		"pressure":
			_draw_pressure(center, radius)
		"spin":
			_draw_spin(center, radius)
		"fatigue":
			_draw_fatigue(center, radius)
		"focus":
			_draw_focus(center, radius)
		"momentum":
			_draw_momentum(center, radius)
		"guard":
			_draw_guard(center, radius)
		"open_court":
			_draw_open_court(center, radius)
		"thorns":
			_draw_thorns(center, radius)
		"tilt":
			_draw_tilt(center, radius)
		"cost_up":
			_draw_cost_up(center, radius)
		"position_lock":
			_draw_position_lock(center, radius)
		"string":
			_draw_string(center, radius)
		"frame":
			_draw_frame_icon(center, radius)
		"racquet":
			_draw_racquet(center, radius)
		"trophy":
			_draw_trophy(center, radius)
		_:
			_draw_ball(center, radius)

func _draw_bitcoin(center: Vector2, radius: float) -> void:
	var coin := accent_color.lightened(0.04)
	draw_circle(center, radius * 0.70, coin)
	draw_arc(center, radius * 0.70, 0.0, TAU, 36, rim_color, 2.0, true)
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, center + Vector2(-radius * 0.24, radius * 0.18), "B", HORIZONTAL_ALIGNMENT_LEFT, radius * 0.8, int(radius * 1.2), fill_color.darkened(0.55))

func _draw_potion(center: Vector2, radius: float) -> void:
	_draw_bottle(center, radius, accent_color, rim_color)

func _draw_stamina_potion(center: Vector2, radius: float) -> void:
	_draw_bottle(center, radius, Color(0.46, 0.92, 0.42, 1.0), rim_color)
	draw_line(center + Vector2(-radius * 0.18, 0.0), center + Vector2(radius * 0.18, 0.0), rim_color, 2.2, true)
	draw_line(center + Vector2(0.0, -radius * 0.18), center + Vector2(0.0, radius * 0.18), rim_color, 2.2, true)

func _draw_spin_potion(center: Vector2, radius: float) -> void:
	_draw_bottle(center, radius, Color(0.74, 0.98, 0.36, 1.0), rim_color)
	_draw_curve(center + Vector2(-radius * 0.18, -radius * 0.06), center + Vector2(0.0, -radius * 0.26), center + Vector2(radius * 0.18, 0.0), rim_color, 1.8)
	_draw_curve(center + Vector2(radius * 0.16, radius * 0.10), center + Vector2(0.0, radius * 0.26), center + Vector2(-radius * 0.14, radius * 0.02), rim_color, 1.8)

func _draw_focus_potion(center: Vector2, radius: float) -> void:
	_draw_bottle(center, radius, Color(0.62, 0.86, 1.0, 1.0), rim_color)
	draw_line(center + Vector2(-radius * 0.14, 0.0), center + Vector2(0.0, -radius * 0.16), rim_color, 2.0, true)
	draw_line(center + Vector2(0.0, -radius * 0.16), center + Vector2(radius * 0.14, 0.0), rim_color, 2.0, true)
	draw_line(center + Vector2(radius * 0.14, 0.0), center + Vector2(0.0, radius * 0.16), rim_color, 2.0, true)
	draw_line(center + Vector2(0.0, radius * 0.16), center + Vector2(-radius * 0.14, 0.0), rim_color, 2.0, true)

func _draw_clutch_potion(center: Vector2, radius: float) -> void:
	_draw_bottle(center, radius, Color(1.0, 0.60, 0.28, 1.0), rim_color)
	_draw_pressure(center + Vector2(0.0, 1.0), radius * 0.52)

func _draw_poly_string(center: Vector2, radius: float) -> void:
	_draw_string_spool(center, radius, Color(0.80, 0.98, 0.42, 1.0), rim_color, 5)

func _draw_gut_string(center: Vector2, radius: float) -> void:
	_draw_string_spool(center, radius, Color(0.98, 0.88, 0.64, 1.0), rim_color, 3)

func _draw_multi_string(center: Vector2, radius: float) -> void:
	_draw_string_spool(center, radius, Color(0.68, 0.96, 1.0, 1.0), rim_color, 7)

func _draw_synthetic_string(center: Vector2, radius: float) -> void:
	_draw_string_spool(center, radius, Color(0.90, 0.90, 0.94, 1.0), rim_color, 4)

func _draw_racquet_tune(center: Vector2, radius: float) -> void:
	_draw_frame_icon(center + Vector2(-radius * 0.08, -radius * 0.04), radius * 0.88)
	draw_arc(center + Vector2(radius * 0.22, radius * 0.14), radius * 0.24, 0.2, 5.4, 18, accent_color.lightened(0.12), 2.2, true)
	draw_line(center + Vector2(radius * 0.30, -radius * 0.12), center + Vector2(radius * 0.44, -radius * 0.26), accent_color.lightened(0.12), 2.0, true)
	draw_line(center + Vector2(radius * 0.30, -radius * 0.12), center + Vector2(radius * 0.24, -radius * 0.28), accent_color.lightened(0.12), 2.0, true)

func _draw_ball(center: Vector2, radius: float) -> void:
	draw_circle(center, radius * 0.86, accent_color)
	var seam: Color = rim_color
	seam.a = 0.92
	_draw_curve(center + Vector2(-radius * 0.38, -radius * 0.72), center + Vector2(-radius * 0.05, 0), center + Vector2(-radius * 0.18, radius * 0.74), seam, 4.0)
	_draw_curve(center + Vector2(radius * 0.38, -radius * 0.72), center + Vector2(radius * 0.05, 0), center + Vector2(radius * 0.18, radius * 0.74), seam, 4.0)

func _draw_racquet(center: Vector2, radius: float) -> void:
	var head_center: Vector2 = center + Vector2(-radius * 0.12, -radius * 0.14)
	draw_ellipse_outline(head_center, Vector2(radius * 0.72, radius * 0.88), accent_color, 3.4)
	for line_index in range(3):
		var x_offset := lerpf(-0.34, 0.34, float(line_index) / 2.0)
		draw_line(head_center + Vector2(radius * x_offset, -radius * 0.56), head_center + Vector2(radius * x_offset, radius * 0.56), rim_color, 1.4, true)
		var y_offset := lerpf(-0.42, 0.42, float(line_index) / 2.0)
		draw_line(head_center + Vector2(-radius * 0.52, radius * y_offset), head_center + Vector2(radius * 0.52, radius * y_offset), rim_color, 1.4, true)
	draw_line(center + Vector2(radius * 0.08, radius * 0.32), center + Vector2(radius * 0.56, radius * 0.86), Color(0.93, 0.80, 0.58, 1.0), 5.0, true)
	draw_line(center + Vector2(radius * 0.16, radius * 0.42), center + Vector2(radius * 0.46, radius * 0.76), Color(0.46, 0.27, 0.12, 1.0), 2.2, true)

func _draw_trophy(center: Vector2, radius: float) -> void:
	var cup_color: Color = accent_color.lightened(0.08)
	var stem_color: Color = accent_color.darkened(0.24)
	var cup_points: PackedVector2Array = PackedVector2Array([
		center + Vector2(-radius * 0.44, -radius * 0.42),
		center + Vector2(radius * 0.44, -radius * 0.42),
		center + Vector2(radius * 0.28, radius * 0.02),
		center + Vector2(0, radius * 0.24),
		center + Vector2(-radius * 0.28, radius * 0.02),
	])
	_fill_polygon(cup_points, cup_color)
	draw_polyline(cup_points + PackedVector2Array([cup_points[0]]), rim_color, 2.2, true)
	draw_line(center + Vector2(-radius * 0.44, -radius * 0.28), center + Vector2(-radius * 0.68, -radius * 0.04), cup_color, 3.0, true)
	draw_line(center + Vector2(radius * 0.44, -radius * 0.28), center + Vector2(radius * 0.68, -radius * 0.04), cup_color, 3.0, true)
	draw_line(center + Vector2(-radius * 0.68, -radius * 0.04), center + Vector2(-radius * 0.45, radius * 0.08), cup_color, 3.0, true)
	draw_line(center + Vector2(radius * 0.68, -radius * 0.04), center + Vector2(radius * 0.45, radius * 0.08), cup_color, 3.0, true)
	draw_rect(Rect2(center + Vector2(-radius * 0.10, radius * 0.22), Vector2(radius * 0.20, radius * 0.18)), stem_color)
	draw_rect(Rect2(center + Vector2(-radius * 0.34, radius * 0.44), Vector2(radius * 0.68, radius * 0.16)), stem_color)

func _draw_pressure(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -radius * 0.66),
		center + Vector2(radius * 0.34, -radius * 0.08),
		center + Vector2(radius * 0.10, -radius * 0.08),
		center + Vector2(radius * 0.32, radius * 0.62),
		center + Vector2(-radius * 0.36, radius * 0.06),
		center + Vector2(-radius * 0.10, radius * 0.06),
	])
	_fill_polygon(points, accent_color)
	draw_polyline(points + PackedVector2Array([points[0]]), rim_color, 2.0, true)

func _draw_spin(center: Vector2, radius: float) -> void:
	draw_circle(center, radius * 0.62, accent_color)
	var swirl := rim_color
	swirl.a = 0.94
	_draw_curve(center + Vector2(-radius * 0.40, -radius * 0.14), center + Vector2(-radius * 0.08, -radius * 0.48), center + Vector2(radius * 0.22, -radius * 0.04), swirl, 3.0)
	_draw_curve(center + Vector2(radius * 0.34, radius * 0.18), center + Vector2(radius * 0.04, radius * 0.52), center + Vector2(-radius * 0.24, radius * 0.06), swirl, 3.0)

func _draw_fatigue(center: Vector2, radius: float) -> void:
	var drop := PackedVector2Array([
		center + Vector2(0, -radius * 0.62),
		center + Vector2(radius * 0.34, -radius * 0.08),
		center + Vector2(radius * 0.22, radius * 0.42),
		center + Vector2(0, radius * 0.60),
		center + Vector2(-radius * 0.22, radius * 0.42),
		center + Vector2(-radius * 0.34, -radius * 0.08),
	])
	_fill_polygon(drop, accent_color)
	draw_polyline(drop + PackedVector2Array([drop[0]]), rim_color, 2.0, true)
	draw_circle(center + Vector2(radius * 0.34, -radius * 0.28), radius * 0.10, rim_color)

func _draw_focus(center: Vector2, radius: float) -> void:
	var star := PackedVector2Array()
	for point_index in range(10):
		var star_radius := radius * (0.58 if point_index % 2 == 0 else 0.24)
		var angle := -PI / 2.0 + TAU * float(point_index) / 10.0
		star.append(center + Vector2(cos(angle) * star_radius, sin(angle) * star_radius))
	_fill_polygon(star, accent_color)
	draw_polyline(star + PackedVector2Array([star[0]]), rim_color, 2.0, true)

func _draw_momentum(center: Vector2, radius: float) -> void:
	var bolt := PackedVector2Array([
		center + Vector2(radius * 0.08, -radius * 0.66),
		center + Vector2(-radius * 0.18, -radius * 0.10),
		center + Vector2(radius * 0.02, -radius * 0.10),
		center + Vector2(-radius * 0.08, radius * 0.56),
		center + Vector2(radius * 0.30, 0.0),
		center + Vector2(radius * 0.08, 0.0),
	])
	_fill_polygon(bolt, accent_color)
	draw_polyline(bolt + PackedVector2Array([bolt[0]]), rim_color, 2.0, true)

func _draw_guard(center: Vector2, radius: float) -> void:
	var shield := PackedVector2Array([
		center + Vector2(0, -radius * 0.62),
		center + Vector2(radius * 0.42, -radius * 0.36),
		center + Vector2(radius * 0.32, radius * 0.28),
		center + Vector2(0, radius * 0.64),
		center + Vector2(-radius * 0.32, radius * 0.28),
		center + Vector2(-radius * 0.42, -radius * 0.36),
	])
	_fill_polygon(shield, accent_color)
	draw_polyline(shield + PackedVector2Array([shield[0]]), rim_color, 2.0, true)

func _draw_open_court(center: Vector2, radius: float) -> void:
	draw_line(center + Vector2(-radius * 0.52, radius * 0.30), center + Vector2(radius * 0.10, -radius * 0.34), accent_color, 4.0, true)
	draw_line(center + Vector2(radius * 0.10, -radius * 0.34), center + Vector2(radius * 0.10, -radius * 0.10), accent_color, 4.0, true)
	draw_line(center + Vector2(radius * 0.10, -radius * 0.34), center + Vector2(radius * 0.34, -radius * 0.34), accent_color, 4.0, true)
	draw_line(center + Vector2(-radius * 0.54, radius * 0.38), center + Vector2(radius * 0.38, radius * 0.38), rim_color, 2.0, true)

func _draw_thorns(center: Vector2, radius: float) -> void:
	for point_index in range(5):
		var angle := -PI / 2.0 + TAU * float(point_index) / 5.0
		var start := center + Vector2(cos(angle) * radius * 0.10, sin(angle) * radius * 0.10)
		var tip := center + Vector2(cos(angle) * radius * 0.62, sin(angle) * radius * 0.62)
		draw_line(start, tip, accent_color, 4.0, true)
	draw_circle(center, radius * 0.18, rim_color)

func _draw_serve(center: Vector2, radius: float) -> void:
	var ball_center := center + Vector2(radius * 0.18, -radius * 0.34)
	draw_circle(ball_center, radius * 0.22, accent_color)
	var seam := Color(rim_color)
	seam.a = 0.90
	_draw_curve(ball_center + Vector2(-radius * 0.08, -radius * 0.16), ball_center + Vector2(-radius * 0.01, 0.0), ball_center + Vector2(-radius * 0.05, radius * 0.16), seam, 1.6)
	_draw_curve(ball_center + Vector2(radius * 0.08, -radius * 0.16), ball_center + Vector2(radius * 0.01, 0.0), ball_center + Vector2(radius * 0.05, radius * 0.16), seam, 1.6)
	var racquet_center := center + Vector2(-radius * 0.16, radius * 0.10)
	draw_ellipse_outline(racquet_center, Vector2(radius * 0.40, radius * 0.48), rim_color, 2.6)
	draw_line(center + Vector2(0, radius * 0.20), center + Vector2(radius * 0.34, radius * 0.72), Color(0.93, 0.80, 0.58, 1.0), 3.6, true)
	draw_line(center + Vector2(-radius * 0.44, radius * 0.48), center + Vector2(radius * 0.02, -radius * 0.62), accent_color.lightened(0.12), 2.8, true)
	draw_line(center + Vector2(radius * 0.02, -radius * 0.62), center + Vector2(radius * 0.14, -radius * 0.48), accent_color.lightened(0.12), 2.8, true)
	draw_line(center + Vector2(radius * 0.02, -radius * 0.62), center + Vector2(-radius * 0.12, -radius * 0.48), accent_color.lightened(0.12), 2.8, true)

func _draw_return(center: Vector2, radius: float) -> void:
	var ball_center := center + Vector2(radius * 0.30, -radius * 0.04)
	draw_circle(ball_center, radius * 0.22, accent_color)
	var seam := Color(rim_color)
	seam.a = 0.90
	_draw_curve(ball_center + Vector2(-radius * 0.08, -radius * 0.16), ball_center + Vector2(-radius * 0.01, 0.0), ball_center + Vector2(-radius * 0.05, radius * 0.16), seam, 1.6)
	_draw_curve(ball_center + Vector2(radius * 0.08, -radius * 0.16), ball_center + Vector2(radius * 0.01, 0.0), ball_center + Vector2(radius * 0.05, radius * 0.16), seam, 1.6)
	var racquet_center := center + Vector2(-radius * 0.16, radius * 0.08)
	draw_ellipse_outline(racquet_center, Vector2(radius * 0.42, radius * 0.50), rim_color, 2.6)
	draw_line(center + Vector2(0, radius * 0.22), center + Vector2(radius * 0.28, radius * 0.70), Color(0.93, 0.80, 0.58, 1.0), 3.6, true)
	draw_line(center + Vector2(-radius * 0.64, radius * 0.04), center + Vector2(-radius * 0.14, radius * 0.04), accent_color.lightened(0.12), 2.8, true)
	draw_line(center + Vector2(-radius * 0.64, radius * 0.04), center + Vector2(-radius * 0.50, -radius * 0.10), accent_color.lightened(0.12), 2.8, true)
	draw_line(center + Vector2(-radius * 0.64, radius * 0.04), center + Vector2(-radius * 0.50, radius * 0.18), accent_color.lightened(0.12), 2.8, true)

func _draw_rally(center: Vector2, radius: float) -> void:
	draw_circle(center, radius * 0.24, accent_color)
	var seam := Color(rim_color)
	seam.a = 0.88
	_draw_curve(center + Vector2(-radius * 0.08, -radius * 0.18), center + Vector2(-radius * 0.01, 0.0), center + Vector2(-radius * 0.05, radius * 0.18), seam, 1.5)
	_draw_curve(center + Vector2(radius * 0.08, -radius * 0.18), center + Vector2(radius * 0.01, 0.0), center + Vector2(radius * 0.05, radius * 0.18), seam, 1.5)
	var orbit_color := accent_color.lightened(0.10)
	draw_arc(center, radius * 0.56, -PI * 0.78, PI * 0.28, 28, orbit_color, 2.6, true)
	draw_arc(center, radius * 0.56, PI * 0.22, PI * 1.30, 28, orbit_color, 2.6, true)
	draw_line(center + Vector2(radius * 0.38, -radius * 0.46), center + Vector2(radius * 0.54, -radius * 0.34), orbit_color, 2.4, true)
	draw_line(center + Vector2(radius * 0.38, -radius * 0.46), center + Vector2(radius * 0.34, -radius * 0.26), orbit_color, 2.4, true)
	draw_line(center + Vector2(-radius * 0.40, radius * 0.44), center + Vector2(-radius * 0.56, radius * 0.32), orbit_color, 2.4, true)
	draw_line(center + Vector2(-radius * 0.40, radius * 0.44), center + Vector2(-radius * 0.34, radius * 0.24), orbit_color, 2.4, true)

func _draw_tilt(center: Vector2, radius: float) -> void:
	# Dizzy spiral — disorientation icon
	var spiral_color := accent_color.lightened(0.08)
	_draw_curve(
		center + Vector2(-radius * 0.44, -radius * 0.10),
		center + Vector2(-radius * 0.10, -radius * 0.52),
		center + Vector2(radius * 0.30, -radius * 0.14),
		spiral_color, 3.0
	)
	_draw_curve(
		center + Vector2(radius * 0.30, -radius * 0.14),
		center + Vector2(radius * 0.14, radius * 0.36),
		center + Vector2(-radius * 0.26, radius * 0.18),
		spiral_color, 3.0
	)
	_draw_curve(
		center + Vector2(-radius * 0.26, radius * 0.18),
		center + Vector2(-radius * 0.06, -radius * 0.08),
		center + Vector2(radius * 0.10, radius * 0.04),
		spiral_color, 2.4
	)
	# Small stars around the spiral
	for i in range(3):
		var angle := -PI * 0.6 + TAU * float(i) / 3.0
		var star_center := center + Vector2(cos(angle) * radius * 0.50, sin(angle) * radius * 0.50)
		var arm_len := radius * 0.10
		draw_line(star_center + Vector2(-arm_len, 0), star_center + Vector2(arm_len, 0), rim_color, 1.6, true)
		draw_line(star_center + Vector2(0, -arm_len), star_center + Vector2(0, arm_len), rim_color, 1.6, true)

func _draw_cost_up(center: Vector2, radius: float) -> void:
	# Upward arrow with stamina drain marks — cost spike icon
	var arrow_color := accent_color.lightened(0.06)
	var arrow := PackedVector2Array([
		center + Vector2(0, -radius * 0.62),
		center + Vector2(radius * 0.32, -radius * 0.16),
		center + Vector2(radius * 0.14, -radius * 0.16),
		center + Vector2(radius * 0.14, radius * 0.54),
		center + Vector2(-radius * 0.14, radius * 0.54),
		center + Vector2(-radius * 0.14, -radius * 0.16),
		center + Vector2(-radius * 0.32, -radius * 0.16),
	])
	_fill_polygon(arrow, arrow_color)
	draw_polyline(arrow + PackedVector2Array([arrow[0]]), rim_color, 2.0, true)
	# Cost tick marks on the shaft
	for i in range(3):
		var y := lerpf(radius * 0.08, radius * 0.44, float(i) / 2.0)
		draw_line(center + Vector2(-radius * 0.22, y), center + Vector2(radius * 0.22, y), rim_color, 1.6, true)

func _draw_position_lock(center: Vector2, radius: float) -> void:
	# Padlock icon — position lock
	var lock_color := accent_color.lightened(0.04)
	# Lock body
	var body_rect := Rect2(center.x - radius * 0.34, center.y - radius * 0.08, radius * 0.68, radius * 0.54)
	draw_rect(body_rect, lock_color)
	draw_rect(body_rect, rim_color, false, 2.0)
	# Lock shackle (arc)
	draw_arc(center + Vector2(0, -radius * 0.08), radius * 0.24, PI, TAU, 24, rim_color, 2.8, true)
	draw_arc(center + Vector2(0, -radius * 0.08), radius * 0.16, PI, TAU, 20, lock_color.darkened(0.15), 2.0, true)
	# Keyhole
	draw_circle(center + Vector2(0, radius * 0.16), radius * 0.10, fill_color.lightened(0.10))
	draw_line(center + Vector2(0, radius * 0.22), center + Vector2(0, radius * 0.36), fill_color.lightened(0.10), 2.4, true)

func _draw_string(center: Vector2, radius: float) -> void:
	var frame_rect := Rect2(center + Vector2(-radius * 0.46, -radius * 0.58), Vector2(radius * 0.92, radius * 1.08))
	draw_rect(frame_rect, accent_color, false, 2.4)
	for line_index in range(4):
		var x := lerpf(frame_rect.position.x + radius * 0.12, frame_rect.end.x - radius * 0.12, float(line_index) / 3.0)
		draw_line(Vector2(x, frame_rect.position.y + radius * 0.08), Vector2(x, frame_rect.end.y - radius * 0.08), rim_color, 1.2, true)
		var y := lerpf(frame_rect.position.y + radius * 0.12, frame_rect.end.y - radius * 0.12, float(line_index) / 3.0)
		draw_line(Vector2(frame_rect.position.x + radius * 0.08, y), Vector2(frame_rect.end.x - radius * 0.08, y), rim_color, 1.2, true)

func _draw_frame_icon(center: Vector2, radius: float) -> void:
	draw_ellipse_outline(center + Vector2(0, -radius * 0.10), Vector2(radius * 0.52, radius * 0.66), accent_color, 3.0)
	draw_line(center + Vector2(0, radius * 0.28), center + Vector2(radius * 0.26, radius * 0.60), Color(0.93, 0.80, 0.58, 1.0), 4.0, true)

func _draw_bottle(center: Vector2, radius: float, body_color: Color, outline_color: Color) -> void:
	var body := Rect2(center.x - radius * 0.24, center.y - radius * 0.34, radius * 0.48, radius * 0.72)
	draw_rect(body, body_color)
	draw_rect(body, outline_color, false, 1.6)
	draw_rect(Rect2(center.x - radius * 0.12, center.y - radius * 0.52, radius * 0.24, radius * 0.16), body_color.darkened(0.22))
	draw_rect(Rect2(center.x - radius * 0.16, center.y - radius * 0.10, radius * 0.32, radius * 0.10), Color(1.0, 1.0, 1.0, 0.16))

func _draw_string_spool(center: Vector2, radius: float, spool_color: Color, outline_color: Color, line_count: int) -> void:
	draw_circle(center, radius * 0.54, spool_color)
	draw_arc(center, radius * 0.54, 0.0, TAU, 36, outline_color, 2.0, true)
	draw_circle(center, radius * 0.20, fill_color)
	for idx in range(line_count):
		var angle := TAU * float(idx) / float(maxi(1, line_count))
		draw_line(center + Vector2(cos(angle), sin(angle)) * radius * 0.20, center + Vector2(cos(angle), sin(angle)) * radius * 0.50, outline_color, 1.2, true)

func _draw_curve(start: Vector2, control: Vector2, finish: Vector2, color_value: Color, width: float) -> void:
	var points := PackedVector2Array()
	var segments: int = 18
	for segment in range(segments + 1):
		var t := float(segment) / float(segments)
		var one_minus_t := 1.0 - t
		points.append(one_minus_t * one_minus_t * start + 2.0 * one_minus_t * t * control + t * t * finish)
	draw_polyline(points, color_value, width, true)

func draw_ellipse_outline(center: Vector2, radii: Vector2, color_value: Color, width: float) -> void:
	var points := PackedVector2Array()
	var segments: int = 36
	for segment in range(segments + 1):
		var angle := TAU * float(segment) / float(segments)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_polyline(points, color_value, width, true)

func _fill_polygon(points: PackedVector2Array, color_value: Color) -> void:
	var colors := PackedColorArray()
	for _unused in points:
		colors.append(color_value)
	draw_polygon(points, colors)
