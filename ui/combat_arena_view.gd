class_name CombatArenaView
extends Control

var _theme: Dictionary = {}
var _presentation: Dictionary = {}
var _external_units_enabled: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func apply_arena_theme(theme: Dictionary) -> void:
	_theme = theme.duplicate(true)
	queue_redraw()

func set_presentation(presentation: Dictionary) -> void:
	_presentation = presentation.duplicate(true)
	queue_redraw()

func set_external_units_enabled(enabled: bool) -> void:
	_external_units_enabled = enabled
	queue_redraw()

func get_layout_snapshot() -> Dictionary:
	if size.x <= 0.0 or size.y <= 0.0:
		return {}
	var rect := Rect2(Vector2.ZERO, size)
	var court_rect := Rect2(size.x * 0.17, size.y * 0.17, size.x * 0.66, size.y * 0.70)
	return {
		"rect": rect,
		"court_rect": court_rect,
		"player_anchor": _player_anchor(court_rect),
		"enemy_anchor": _enemy_anchor(court_rect),
		"ball_point": _ball_point(court_rect),
	}

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var accent: Color = Color(_theme.get("accent", Color(0.84, 0.93, 1.0)))
	var border: Color = Color(_theme.get("border", accent))
	var background: Color = Color(_theme.get("background", Color(0.06, 0.11, 0.14)))
	var text_tint: Color = Color(_theme.get("text", Color.WHITE))
	var surface_key := String(_presentation.get("surface_key", "hardcourt"))
	var major_name := String(_presentation.get("major_name", ""))
	var surface_palette := _surface_palette(surface_key, major_name)
	var player_color := accent.lightened(0.10)
	var enemy_color := Color(0.98, 0.41, 0.28, 1.0)
	var neutral_glow := text_tint
	neutral_glow.a = 0.10

	var rect := Rect2(Vector2.ZERO, size)
	var canvas_top: Color = Color(surface_palette.get("canvas_top", background.lightened(0.10)))
	var canvas_bottom: Color = Color(surface_palette.get("canvas_bottom", background.darkened(0.18)))
	_draw_vertical_gradient(rect, canvas_top, canvas_bottom, 72)
	draw_rect(Rect2(0.0, 0.0, rect.size.x, rect.size.y * 0.14), Color(1.0, 1.0, 1.0, 0.05))
	_draw_slam_backdrop(rect, surface_palette, border)
	var court_rect := Rect2(size.x * 0.17, size.y * 0.17, size.x * 0.66, size.y * 0.70)
	_draw_court(court_rect, border)
	_draw_slam_signage(rect, court_rect, surface_palette, border, major_name)
	_draw_side_labels(court_rect, player_color, enemy_color, border)
	_draw_pressure_glow(court_rect, accent, enemy_color, neutral_glow)
	_draw_ball_path(court_rect, player_color, enemy_color, text_tint)
	_draw_enemy_projection(court_rect, enemy_color, border)
	if not _external_units_enabled:
		_draw_actor_group(court_rect, _player_anchor(court_rect), player_color, true)
		_draw_actor_group(court_rect, _enemy_anchor(court_rect), enemy_color, false)
	_draw_serve_indicator(court_rect, player_color, enemy_color, border)
	_draw_net(court_rect, border)

func _draw_vertical_gradient(area: Rect2, start_color: Color, end_color: Color, strips: int) -> void:
	for strip_index in range(maxi(1, strips)):
		var t0 := float(strip_index) / float(maxi(1, strips))
		var t1 := float(strip_index + 1) / float(maxi(1, strips))
		var y := area.position.y + area.size.y * t0
		var band_color := start_color.lerp(end_color, t0)
		draw_rect(Rect2(area.position.x, y, area.size.x, area.size.y * (t1 - t0) + 1.0), band_color)

func _draw_slam_backdrop(rect: Rect2, surface_palette: Dictionary, border: Color) -> void:
	var poster_color := Color(surface_palette.get("poster", Color(0.88, 0.90, 0.92, 1.0)))
	var frame_color := poster_color.darkened(0.10)
	var guide_color := border.lightened(0.14)
	guide_color.a = 0.16
	draw_rect(Rect2(rect.position.x, rect.size.y * 0.06, rect.size.x, rect.size.y * 0.10), poster_color)
	draw_rect(Rect2(rect.position.x, rect.size.y * 0.84, rect.size.x, rect.size.y * 0.10), poster_color.darkened(0.04))
	draw_rect(Rect2(rect.size.x * 0.06, rect.size.y * 0.10, rect.size.x * 0.14, rect.size.y * 0.70), frame_color)
	draw_rect(Rect2(rect.size.x * 0.80, rect.size.y * 0.10, rect.size.x * 0.14, rect.size.y * 0.70), frame_color)
	for idx in range(4):
		var y := lerpf(rect.size.y * 0.18, rect.size.y * 0.78, float(idx) / 3.0)
		draw_line(Vector2(rect.size.x * 0.08, y), Vector2(rect.size.x * 0.92, y), guide_color, 2.0, true)
	draw_rect(Rect2(rect.size.x * 0.08, rect.size.y * 0.10, rect.size.x * 0.84, rect.size.y * 0.04), Color(1.0, 1.0, 1.0, 0.05))

func _surface_palette(surface_key: String, major_name: String = "") -> Dictionary:
	if surface_key == "hardcourt" and major_name.findn("US Open") >= 0:
		surface_key = "us_open"
	match surface_key:
		"clay":
			return {
				"canvas_top": Color(0.96, 0.90, 0.82, 1.0),
				"canvas_bottom": Color(0.88, 0.74, 0.63, 1.0),
				"poster": Color(0.98, 0.90, 0.80, 1.0),
				"surround": Color(0.92, 0.55, 0.40, 1.0),
				"court": Color(0.86, 0.52, 0.34, 1.0),
				"court_alt": Color(0.79, 0.45, 0.28, 1.0),
				"stripe": Color(0.95, 0.64, 0.48, 1.0),
				"line": Color(0.97, 0.96, 0.92, 1.0),
			}
		"grass":
			return {
				"canvas_top": Color(0.94, 0.95, 0.84, 1.0),
				"canvas_bottom": Color(0.79, 0.86, 0.58, 1.0),
				"poster": Color(0.93, 0.96, 0.84, 1.0),
				"surround": Color(0.64, 0.78, 0.22, 1.0),
				"court": Color(0.56, 0.72, 0.18, 1.0),
				"court_alt": Color(0.73, 0.84, 0.32, 1.0),
				"stripe": Color(0.82, 0.90, 0.42, 1.0),
				"line": Color(0.97, 0.99, 0.94, 1.0),
			}
		"us_open":
			return {
				"canvas_top": Color(0.87, 0.92, 0.88, 1.0),
				"canvas_bottom": Color(0.56, 0.72, 0.48, 1.0),
				"poster": Color(0.88, 0.93, 0.88, 1.0),
				"surround": Color(0.28, 0.53, 0.35, 1.0),
				"court": Color(0.23, 0.47, 0.69, 1.0),
				"court_alt": Color(0.16, 0.34, 0.56, 1.0),
				"stripe": Color(0.38, 0.62, 0.44, 1.0),
				"line": Color(0.96, 0.98, 0.96, 1.0),
			}
		_:
			return {
				"canvas_top": Color(0.94, 0.93, 0.86, 1.0),
				"canvas_bottom": Color(0.72, 0.82, 0.93, 1.0),
				"poster": Color(0.94, 0.94, 0.90, 1.0),
				"surround": Color(0.18, 0.49, 0.84, 1.0),
				"court": Color(0.24, 0.53, 0.82, 1.0),
				"court_alt": Color(0.16, 0.36, 0.64, 1.0),
				"stripe": Color(0.34, 0.61, 0.90, 1.0),
				"line": Color(0.97, 0.98, 0.97, 1.0),
			}

func _draw_court(court_rect: Rect2, border: Color) -> void:
	var surface_key := String(_presentation.get("surface_key", "hardcourt"))
	var major_name := String(_presentation.get("major_name", ""))
	var palette := _surface_palette(surface_key, major_name)
	var surround := Color(palette.get("surround", Color(0.19, 0.43, 0.67, 1.0)))
	var court_fill := Color(palette.get("court", surround.lightened(0.08)))
	var court_alt := Color(palette.get("court_alt", surround.darkened(0.08)))
	var stripe := Color(palette.get("stripe", surround.lightened(0.12)))
	var line_color := Color(palette.get("line", Color(0.96, 0.97, 0.94, 1.0)))
	var frame := surround.darkened(0.18)
	draw_rect(court_rect.grow(10.0), frame)
	draw_rect(court_rect, surround)
	draw_rect(Rect2(court_rect.position.x, court_rect.position.y, court_rect.size.x, court_rect.size.y * 0.10), Color(1.0, 1.0, 1.0, 0.06))
	if surface_key == "grass":
		for stripe_index in range(10):
			var stripe_rect := Rect2(
				court_rect.position.x + court_rect.size.x * float(stripe_index) / 10.0,
				court_rect.position.y,
				court_rect.size.x / 10.0 + 1.0,
				court_rect.size.y
			)
			draw_rect(stripe_rect, stripe if stripe_index % 2 == 0 else surround)
	elif surface_key == "clay":
		for stripe_index in range(5):
			var dust_band := Rect2(
				court_rect.position.x,
				court_rect.position.y + court_rect.size.y * (0.12 + 0.18 * float(stripe_index)),
				court_rect.size.x,
				court_rect.size.y * 0.05
			)
			draw_rect(dust_band, stripe.darkened(0.08))
	var play_rect := _play_rect(court_rect)
	draw_rect(play_rect, court_fill)
	draw_rect(play_rect.grow(-play_rect.size.x * 0.02), court_alt, false, 1.4)
	draw_rect(play_rect, line_color, false, 3.0)
	var singles_top := play_rect.position.y + play_rect.size.y * 0.14
	var singles_bottom := play_rect.position.y + play_rect.size.y * 0.86
	var service_left := play_rect.position.x + play_rect.size.x * 0.27
	var service_right := play_rect.position.x + play_rect.size.x * 0.73
	var center_y := play_rect.position.y + play_rect.size.y * 0.50
	_draw_line(Vector2(play_rect.position.x, singles_top), Vector2(play_rect.end.x, singles_top), line_color, 2.2)
	_draw_line(Vector2(play_rect.position.x, singles_bottom), Vector2(play_rect.end.x, singles_bottom), line_color, 2.2)
	_draw_line(Vector2(service_left, singles_top), Vector2(service_left, singles_bottom), line_color, 2.2)
	_draw_line(Vector2(service_right, singles_top), Vector2(service_right, singles_bottom), line_color, 2.2)
	_draw_line(Vector2(service_left, center_y), Vector2(service_right, center_y), line_color, 2.2)
	_draw_line(Vector2(play_rect.position.x, center_y), Vector2(play_rect.position.x + play_rect.size.x * 0.08, center_y), line_color, 2.2)
	_draw_line(Vector2(play_rect.end.x, center_y), Vector2(play_rect.end.x - play_rect.size.x * 0.08, center_y), line_color, 2.2)
	var header_band := Rect2(court_rect.position.x, court_rect.position.y - court_rect.size.y * 0.08, court_rect.size.x, court_rect.size.y * 0.05)
	var header_color := border.lightened(0.18)
	header_color.a = 0.15
	draw_rect(header_band, header_color)
	draw_rect(header_band.grow(-3.0), Color(1.0, 1.0, 1.0, 0.05), false, 1.2)
	var ball_stamp := Vector2(court_rect.position.x + court_rect.size.x * 0.92, court_rect.position.y + court_rect.size.y * 0.08)
	var seam := border.lightened(0.30)
	seam.a = 0.35
	draw_circle(ball_stamp, 7.0, seam)
	draw_arc(ball_stamp, 5.0, -0.8, 0.8, 12, frame.darkened(0.18), 1.0, true)
	draw_arc(ball_stamp, 5.0, PI - 0.8, PI + 0.8, 12, frame.darkened(0.18), 1.0, true)

func _play_rect(court_rect: Rect2) -> Rect2:
	return court_rect.grow_individual(-court_rect.size.x * 0.12, -court_rect.size.y * 0.05, -court_rect.size.x * 0.12, -court_rect.size.y * 0.05)

func _draw_slam_signage(rect: Rect2, court_rect: Rect2, surface_palette: Dictionary, border: Color, major_name: String) -> void:
	var font := ThemeDB.fallback_font
	var play_rect := _play_rect(court_rect)
	var sign_fill := Color(surface_palette.get("poster", Color(0.92, 0.94, 0.90, 1.0))).darkened(0.04)
	var sign_border := border.lightened(0.18)
	var sign_text := border.darkened(0.46)
	var major_tag := _major_abbreviation(major_name)
	var city_tag := _major_city_label(major_name)
	var left_board := Rect2(rect.size.x * 0.07, rect.size.y * 0.22, rect.size.x * 0.10, rect.size.y * 0.20)
	var right_board := Rect2(rect.size.x * 0.83, rect.size.y * 0.22, rect.size.x * 0.10, rect.size.y * 0.20)
	for board in [left_board, right_board]:
		draw_rect(board, sign_fill)
		draw_rect(board, sign_border, false, 2.0)
		draw_rect(board.grow(-8.0), Color(1.0, 1.0, 1.0, 0.08), false, 1.2)
		_draw_major_logo_mark(board.get_center() + Vector2(0.0, -10.0), sign_border, major_tag)
		if font != null:
			draw_string(font, board.position + Vector2(14.0, board.size.y - 18.0), city_tag, HORIZONTAL_ALIGNMENT_LEFT, board.size.x - 20.0, 12, sign_text)
	var net_badge := Rect2(play_rect.position.x + play_rect.size.x * 0.40, court_rect.position.y - court_rect.size.y * 0.10, play_rect.size.x * 0.20, court_rect.size.y * 0.06)
	var badge_fill := sign_fill.lightened(0.02)
	badge_fill.a = 0.92
	draw_rect(net_badge, badge_fill)
	draw_rect(net_badge, sign_border, false, 2.0)
	if font != null:
		draw_string(font, net_badge.position + Vector2(10.0, net_badge.size.y * 0.68), major_name, HORIZONTAL_ALIGNMENT_LEFT, net_badge.size.x - 12.0, 14, sign_text)
	var court_stamp := Rect2(play_rect.position.x + play_rect.size.x * 0.04, play_rect.end.y - play_rect.size.y * 0.13, play_rect.size.x * 0.12, play_rect.size.y * 0.06)
	var stamp_fill := Color(1.0, 1.0, 1.0, 0.10)
	draw_rect(court_stamp, stamp_fill)
	if font != null:
		var stamp_text := sign_border
		stamp_text.a = 0.50
		draw_string(font, court_stamp.position + Vector2(8.0, court_stamp.size.y * 0.70), major_tag, HORIZONTAL_ALIGNMENT_LEFT, court_stamp.size.x - 8.0, 13, stamp_text)

func _draw_major_logo_mark(center: Vector2, color_value: Color, label: String) -> void:
	var ring := color_value
	ring.a = 0.90
	draw_arc(center, 18.0, 0.0, TAU, 28, ring, 2.6, true)
	draw_arc(center, 11.0, 0.0, TAU, 28, ring, 1.2, true)
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, center + Vector2(-10.0, 5.0), label, HORIZONTAL_ALIGNMENT_LEFT, 24.0, 12, ring)

func _major_abbreviation(major_name: String) -> String:
	if major_name.findn("Australian") >= 0:
		return "AO"
	if major_name.findn("Roland") >= 0:
		return "RG"
	if major_name.findn("Wimbledon") >= 0:
		return "W"
	if major_name.findn("US Open") >= 0:
		return "US"
	return "GS"

func _major_city_label(major_name: String) -> String:
	if major_name.findn("Australian") >= 0:
		return "Melbourne"
	if major_name.findn("Roland") >= 0:
		return "Paris"
	if major_name.findn("Wimbledon") >= 0:
		return "London"
	if major_name.findn("US Open") >= 0:
		return "New York"
	return "Tour"

func _draw_side_labels(court_rect: Rect2, player_color: Color, enemy_color: Color, border: Color) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var play_rect := _play_rect(court_rect)
	_draw_side_pill(
		Rect2(play_rect.position.x + 8.0, play_rect.end.y - 34.0, 116.0, 24.0),
		"YOUR SIDE",
		player_color,
		border.darkened(0.40)
	)
	_draw_side_pill(
		Rect2(play_rect.end.x - 124.0, play_rect.position.y + 10.0, 116.0, 24.0),
		"OPPONENT",
		enemy_color,
		border.darkened(0.40)
	)

func _draw_side_pill(area: Rect2, text_value: String, fill_color: Color, text_color: Color) -> void:
	var fill := fill_color
	fill.a = 0.18
	draw_rect(area, fill)
	draw_rect(area, fill_color.lightened(0.14), false, 1.8)
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, area.position + Vector2(10.0, area.size.y * 0.72), text_value, HORIZONTAL_ALIGNMENT_LEFT, area.size.x - 16.0, 12, text_color)

func _draw_pressure_glow(court_rect: Rect2, player_color: Color, enemy_color: Color, neutral_glow: Color) -> void:
	var pressure := int(_presentation.get("rally_pressure", 0))
	var play_rect := _play_rect(court_rect)
	var pressure_ratio := _pressure_ratio()
	var anchor_x := play_rect.position.x + play_rect.size.x * (0.50 + pressure_ratio * 0.28)
	var glow := neutral_glow
	if pressure > 8:
		glow = player_color
		glow.a = 0.12 + 0.12 * absf(pressure_ratio)
	elif pressure < -8:
		glow = enemy_color
		glow.a = 0.12 + 0.12 * absf(pressure_ratio)
	draw_circle(Vector2(anchor_x, play_rect.position.y + play_rect.size.y * 0.50), play_rect.size.y * 0.18, glow)

func _draw_ball_path(court_rect: Rect2, player_color: Color, enemy_color: Color, neutral_color: Color) -> void:
	var player_anchor := _player_anchor(court_rect)
	var enemy_anchor := _enemy_anchor(court_rect)
	var ball_state := String(_presentation.get("ball_state", "NormalBall"))
	var pressure_ratio := _pressure_ratio()
	var base_t := 0.5 + pressure_ratio * 0.34
	var height_scale := 0.18
	if ball_state == "LowBall":
		height_scale = 0.09
	elif ball_state == "HighBall":
		height_scale = 0.28
	elif ball_state == "AtNet":
		height_scale = 0.06
	var play_rect := _play_rect(court_rect)
	var control_point := Vector2(
		lerpf(player_anchor.x, enemy_anchor.x, base_t),
		play_rect.position.y + play_rect.size.y * _ball_lane_ratio() - play_rect.size.y * height_scale
	)
	var trail_color := neutral_color
	trail_color.a = 0.28
	if pressure_ratio > 0.08:
		trail_color = player_color.lightened(0.08)
		trail_color.a = 0.32 + 0.24 * pressure_ratio
	elif pressure_ratio < -0.08:
		trail_color = enemy_color.lightened(0.04)
		trail_color.a = 0.32 + 0.24 * absf(pressure_ratio)
	var last_point := player_anchor
	for step in range(1, 24):
		var t := float(step) / 23.0
		var point := _quadratic_bezier(player_anchor, control_point, enemy_anchor, t)
		var stroke := trail_color
		stroke.a *= 0.60 + 0.40 * (1.0 - t)
		draw_line(last_point, point, stroke, 3.0, true)
		last_point = point
	var ball_color := Color(0.97, 0.94, 0.35, 1.0)
	var ball_point := _quadratic_bezier(player_anchor, control_point, enemy_anchor, clampf(base_t, 0.12, 0.88))
	draw_circle(ball_point, 7.8, ball_color)
	var ball_ring := player_color if pressure_ratio > 0.08 else (enemy_color if pressure_ratio < -0.08 else neutral_color.lightened(0.12))
	draw_arc(ball_point, 10.5, 0.0, TAU, 20, ball_ring, 1.8, true)

func _ball_point(court_rect: Rect2) -> Vector2:
	var player_anchor := _player_anchor(court_rect)
	var enemy_anchor := _enemy_anchor(court_rect)
	var ball_state := String(_presentation.get("ball_state", "NormalBall"))
	var pressure_ratio := _pressure_ratio()
	var base_t := 0.5 + pressure_ratio * 0.34
	var height_scale := 0.18
	if ball_state == "LowBall":
		height_scale = 0.09
	elif ball_state == "HighBall":
		height_scale = 0.28
	elif ball_state == "AtNet":
		height_scale = 0.06
	var play_rect := _play_rect(court_rect)
	var control_point := Vector2(
		lerpf(player_anchor.x, enemy_anchor.x, base_t),
		play_rect.position.y + play_rect.size.y * _ball_lane_ratio() - play_rect.size.y * height_scale
	)
	return _quadratic_bezier(player_anchor, control_point, enemy_anchor, clampf(base_t, 0.12, 0.88))

func _draw_actor_group(court_rect: Rect2, anchor: Vector2, tint: Color, is_player: bool) -> void:
	var scale := _actor_scale(court_rect, anchor)
	if is_player:
		_draw_human_actor(anchor, tint, true, scale, _player_variant_kind(), String(_presentation.get("player_position", "Baseline")))
		return

	var variant_kind := _enemy_variant_kind()
	var position_name := String(_presentation.get("enemy_position", "Baseline"))
	if variant_kind == "duo":
		_draw_human_actor(anchor + Vector2(-18.0 * scale, 6.0 * scale), tint.darkened(0.08), false, scale * 0.90, "duo_left", position_name)
		_draw_human_actor(anchor + Vector2(26.0 * scale, 2.0 * scale), tint.lightened(0.08), false, scale, "duo_right", position_name)
		return
	match variant_kind:
		"human":
			_draw_human_actor(anchor, tint, false, scale, "rival", position_name)
		"machine":
			_draw_machine_actor(anchor, tint, scale, position_name)
		"stone":
			_draw_stone_actor(anchor, tint, scale, position_name)
		"specter":
			_draw_specter_actor(anchor, tint, scale, position_name)
		"vampire":
			_draw_vampire_actor(anchor, tint, scale, position_name)
		_:
			_draw_beast_actor(anchor, tint, scale, position_name)

func _draw_human_actor(anchor: Vector2, tint: Color, is_player: bool, scale: float, variant_kind: String, position_name: String) -> void:
	var facing_dir := 1.0 if is_player else -1.0
	var torso_color := tint.darkened(0.10)
	var trim := tint.lightened(0.22)
	var shorts := torso_color.darkened(0.22)
	var skin_palette := _human_palette(variant_kind + position_name)
	var skin: Color = Color(skin_palette["skin"])
	var skin_shadow: Color = Color(skin_palette["skin_shadow"])
	var hair: Color = Color(skin_palette["hair"])
	var shadow := torso_color.darkened(0.78)
	shadow.a = 0.24
	_draw_soft_ellipse(Rect2(anchor.x - 36.0 * scale, anchor.y - 10.0 * scale, 72.0 * scale, 18.0 * scale), shadow, 22)
	var aura := trim
	aura.a = 0.12
	draw_circle(anchor + Vector2(0.0, -72.0 * scale), 26.0 * scale, aura)

	var torso_top := anchor + Vector2(0.0, -92.0 * scale)
	var torso_mid := anchor + Vector2(0.0, -50.0 * scale)
	var hip_y := anchor.y - 22.0 * scale
	var shoulder_width := 28.0 * scale
	var waist_width := 17.0 * scale
	var lean := _stance_lean(position_name, is_player) * scale
	var torso := PackedVector2Array([
		torso_top + Vector2(-shoulder_width + lean * 0.10, 0.0),
		torso_top + Vector2(shoulder_width + lean * 0.10, 0.0),
		Vector2(anchor.x + waist_width + lean + 10.0 * scale, hip_y - 12.0 * scale),
		Vector2(anchor.x + waist_width + lean, hip_y),
		Vector2(anchor.x - waist_width + lean, hip_y),
		Vector2(anchor.x - waist_width + lean - 10.0 * scale, hip_y - 12.0 * scale),
	])
	_solid_polygon(torso, torso_color)
	draw_rect(Rect2(anchor.x - 7.0 * scale + lean * 0.22, torso_top.y + 10.0 * scale, 14.0 * scale, 38.0 * scale), trim.darkened(0.10))
	draw_line(torso_top + Vector2(-shoulder_width + 8.0 * scale, 4.0 * scale), torso_mid + Vector2(lean * 0.1, 4.0 * scale), trim, 2.0 * scale, true)
	draw_line(torso_top + Vector2(shoulder_width - 8.0 * scale, 4.0 * scale), torso_mid + Vector2(lean * 0.1, 4.0 * scale), trim, 2.0 * scale, true)
	draw_rect(Rect2(anchor.x - 16.0 * scale + lean, hip_y - 2.0 * scale, 32.0 * scale, 24.0 * scale), shorts)
	draw_line(Vector2(anchor.x + lean, hip_y), anchor + Vector2(24.0 * facing_dir, -2.0) * scale, skin_shadow, 8.4 * scale, true)
	draw_line(Vector2(anchor.x + lean * 0.6, hip_y), anchor + Vector2(-10.0 * facing_dir, 5.0) * scale, skin_shadow, 7.4 * scale, true)
	draw_line(torso_mid + Vector2(lean * 0.2, -2.0 * scale), torso_mid + Vector2(32.0 * facing_dir, -12.0) * scale, skin, 7.2 * scale, true)
	draw_line(torso_mid + Vector2(-4.0 * lean, 0.0), torso_mid + Vector2(-20.0 * facing_dir, -4.0) * scale, skin, 6.2 * scale, true)
	var neck := Rect2(anchor.x - 6.0 * scale + lean * 0.18, torso_top.y - 10.0 * scale, 12.0 * scale, 14.0 * scale)
	draw_rect(neck, skin_shadow)
	var head_center := torso_top + Vector2(lean * 0.18, -24.0 * scale)
	_draw_soft_ellipse(Rect2(head_center.x - 14.0 * scale, head_center.y - 16.0 * scale, 28.0 * scale, 32.0 * scale), skin, 20)
	_draw_soft_ellipse(Rect2(head_center.x - 10.0 * scale, head_center.y + 4.0 * scale, 20.0 * scale, 8.0 * scale), skin_shadow, 16)
	_draw_hair_or_headgear(head_center, hair, trim, variant_kind, scale)
	draw_circle(head_center + Vector2(-4.0 * facing_dir, -1.6 * scale), 1.6 * scale, Color(0.08, 0.08, 0.10))
	draw_circle(head_center + Vector2(4.0 * facing_dir, -0.8 * scale), 1.5 * scale, Color(0.08, 0.08, 0.10))
	draw_line(head_center + Vector2(-4.0 * facing_dir, 7.0 * scale), head_center + Vector2(4.0 * facing_dir, 8.0 * scale), skin_shadow.darkened(0.12), 1.2 * scale, true)
	draw_line(head_center + Vector2(-7.0 * facing_dir, -5.0 * scale), head_center + Vector2(0.0, -7.0 * scale), skin_shadow.darkened(0.20), 1.3 * scale, true)
	draw_line(head_center + Vector2(0.0, -2.0 * scale), head_center + Vector2(2.0 * facing_dir, 5.0 * scale), skin_shadow.darkened(0.16), 1.1 * scale, true)
	_draw_racquet_outline(anchor + Vector2(42.0 * facing_dir, -20.0) * scale, trim, facing_dir, scale)
	draw_line(anchor + Vector2(22.0 * facing_dir, -8.0) * scale, anchor + Vector2(32.0 * facing_dir, 10.0) * scale, Color(0.82, 0.86, 0.90, 1.0), 2.0 * scale, true)

func _draw_machine_actor(anchor: Vector2, tint: Color, scale: float, position_name: String) -> void:
	var facing_dir := -1.0
	var shell := tint.darkened(0.20)
	var core := tint.lightened(0.24)
	var shadow := shell.darkened(0.78)
	shadow.a = 0.24
	_draw_soft_ellipse(Rect2(anchor.x - 36.0 * scale, anchor.y - 10.0 * scale, 72.0 * scale, 18.0 * scale), shadow, 22)
	draw_rect(Rect2(anchor.x - 24.0 * scale, anchor.y - 86.0 * scale, 48.0 * scale, 52.0 * scale), shell)
	draw_rect(Rect2(anchor.x - 18.0 * scale, anchor.y - 126.0 * scale, 36.0 * scale, 34.0 * scale), shell.lightened(0.08))
	draw_circle(anchor + Vector2(-8.0, -110.0) * scale, 5.0 * scale, core)
	draw_circle(anchor + Vector2(8.0, -110.0) * scale, 5.0 * scale, core)
	draw_rect(Rect2(anchor.x - 14.0 * scale, anchor.y - 68.0 * scale, 28.0 * scale, 8.0 * scale), core.darkened(0.18))
	draw_line(anchor + Vector2(-14.0, -34.0) * scale, anchor + Vector2(-24.0, 2.0) * scale, shell.lightened(0.06), 8.0 * scale, true)
	draw_line(anchor + Vector2(14.0, -34.0) * scale, anchor + Vector2(24.0, 2.0) * scale, shell.lightened(0.06), 8.0 * scale, true)
	draw_line(anchor + Vector2(-16.0, -72.0) * scale, anchor + Vector2(-34.0, -44.0 + _stance_lean(position_name, false) * 0.2) * scale, shell.lightened(0.08), 7.0 * scale, true)
	draw_line(anchor + Vector2(16.0, -72.0) * scale, anchor + Vector2(30.0, -52.0) * scale, shell.lightened(0.08), 7.0 * scale, true)
	_draw_racquet_outline(anchor + Vector2(-44.0, -62.0) * scale, core, facing_dir, scale)

func _draw_stone_actor(anchor: Vector2, tint: Color, scale: float, position_name: String) -> void:
	var facing_dir := -1.0
	var rock := tint.darkened(0.30)
	var seam := tint.lightened(0.18)
	var shadow := rock.darkened(0.80)
	shadow.a = 0.26
	_draw_soft_ellipse(Rect2(anchor.x - 40.0 * scale, anchor.y - 12.0 * scale, 80.0 * scale, 22.0 * scale), shadow, 24)
	var body := PackedVector2Array([
		anchor + Vector2(-28.0, -20.0) * scale,
		anchor + Vector2(-34.0, -78.0) * scale,
		anchor + Vector2(-16.0, -118.0) * scale,
		anchor + Vector2(18.0, -118.0) * scale,
		anchor + Vector2(36.0, -80.0) * scale,
		anchor + Vector2(30.0, -18.0) * scale,
		anchor + Vector2(0.0, 6.0) * scale,
	])
	_solid_polygon(body, rock)
	draw_rect(Rect2(anchor.x - 16.0 * scale, anchor.y - 146.0 * scale, 32.0 * scale, 28.0 * scale), rock.lightened(0.06))
	draw_line(anchor + Vector2(-10.0, -82.0) * scale, anchor + Vector2(20.0, -56.0) * scale, seam, 3.0 * scale, true)
	draw_line(anchor + Vector2(-22.0, -38.0) * scale, anchor + Vector2(12.0, -14.0) * scale, seam, 3.0 * scale, true)
	draw_circle(anchor + Vector2(-8.0, -132.0) * scale, 4.0 * scale, seam.lightened(0.20))
	draw_circle(anchor + Vector2(8.0, -132.0) * scale, 4.0 * scale, seam.lightened(0.20))
	draw_line(anchor + Vector2(-18.0, -34.0) * scale, anchor + Vector2(-30.0, 0.0) * scale, rock.lightened(0.04), 10.0 * scale, true)
	draw_line(anchor + Vector2(18.0, -34.0) * scale, anchor + Vector2(26.0, 2.0) * scale, rock.lightened(0.04), 10.0 * scale, true)
	draw_line(anchor + Vector2(-16.0, -86.0) * scale, anchor + Vector2(-34.0, -58.0 + _stance_lean(position_name, false) * 0.2) * scale, rock.lightened(0.08), 9.0 * scale, true)
	draw_line(anchor + Vector2(16.0, -88.0) * scale, anchor + Vector2(30.0, -66.0) * scale, rock.lightened(0.08), 8.0 * scale, true)
	_draw_racquet_outline(anchor + Vector2(-44.0, -72.0) * scale, seam, facing_dir, scale)

func _draw_specter_actor(anchor: Vector2, tint: Color, scale: float, position_name: String) -> void:
	var facing_dir := -1.0
	var cloak := tint.darkened(0.38)
	var aura := tint.lightened(0.20)
	aura.a = 0.16
	_draw_soft_ellipse(Rect2(anchor.x - 38.0 * scale, anchor.y - 10.0 * scale, 76.0 * scale, 18.0 * scale), aura, 22)
	draw_circle(anchor + Vector2(0.0, -96.0) * scale, 30.0 * scale, aura)
	var body := PackedVector2Array([
		anchor + Vector2(-28.0, -16.0) * scale,
		anchor + Vector2(-18.0, -84.0) * scale,
		anchor + Vector2(0.0, -132.0) * scale,
		anchor + Vector2(18.0, -84.0) * scale,
		anchor + Vector2(30.0, -14.0) * scale,
		anchor + Vector2(0.0, 6.0) * scale,
	])
	_solid_polygon(body, cloak)
	draw_circle(anchor + Vector2(-9.0, -104.0) * scale, 3.0 * scale, tint.lightened(0.36))
	draw_circle(anchor + Vector2(9.0, -104.0) * scale, 3.0 * scale, tint.lightened(0.36))
	draw_line(anchor + Vector2(-8.0, -76.0) * scale, anchor + Vector2(-28.0, -56.0 + _stance_lean(position_name, false) * 0.18) * scale, aura.lightened(0.24), 6.0 * scale, true)
	draw_line(anchor + Vector2(10.0, -74.0) * scale, anchor + Vector2(20.0, -50.0) * scale, aura.lightened(0.24), 5.0 * scale, true)
	_draw_racquet_outline(anchor + Vector2(-38.0, -70.0) * scale, aura.lightened(0.24), facing_dir, scale)

func _draw_vampire_actor(anchor: Vector2, tint: Color, scale: float, position_name: String) -> void:
	var facing_dir := -1.0
	var cloak := tint.darkened(0.28)
	var trim := tint.lightened(0.16)
	var skin := Color(0.90, 0.84, 0.86, 1.0)
	var hair := Color(0.08, 0.06, 0.10, 1.0)
	var shadow := cloak.darkened(0.80)
	shadow.a = 0.24
	_draw_soft_ellipse(Rect2(anchor.x - 32.0 * scale, anchor.y - 10.0 * scale, 64.0 * scale, 18.0 * scale), shadow, 22)
	_draw_human_actor(anchor, cloak, false, scale, "vampire", position_name)
	draw_line(anchor + Vector2(-6.0, -96.0) * scale, anchor + Vector2(-2.0, -88.0) * scale, trim, 1.6 * scale, true)
	draw_line(anchor + Vector2(6.0, -96.0) * scale, anchor + Vector2(2.0, -88.0) * scale, trim, 1.6 * scale, true)
	draw_circle(anchor + Vector2(0.0, -108.0) * scale, 14.0 * scale, skin)
	var hair_shape := PackedVector2Array([
		anchor + Vector2(-16.0, -108.0) * scale,
		anchor + Vector2(-8.0, -128.0) * scale,
		anchor + Vector2(0.0, -132.0) * scale,
		anchor + Vector2(10.0, -126.0) * scale,
		anchor + Vector2(16.0, -106.0) * scale,
		anchor + Vector2(2.0, -92.0) * scale,
		anchor + Vector2(-8.0, -94.0) * scale,
	])
	_solid_polygon(hair_shape, hair)

func _draw_beast_actor(anchor: Vector2, tint: Color, scale: float, position_name: String) -> void:
	var facing_dir := -1.0
	var fur := tint.darkened(0.24)
	var trim := tint.lightened(0.16)
	var shadow := fur.darkened(0.80)
	shadow.a = 0.24
	_draw_soft_ellipse(Rect2(anchor.x - 40.0 * scale, anchor.y - 12.0 * scale, 80.0 * scale, 22.0 * scale), shadow, 22)
	var body := PackedVector2Array([
		anchor + Vector2(-34.0, -12.0) * scale,
		anchor + Vector2(-20.0, -62.0) * scale,
		anchor + Vector2(4.0, -88.0) * scale,
		anchor + Vector2(30.0, -56.0) * scale,
		anchor + Vector2(24.0, -10.0) * scale,
		anchor + Vector2(6.0, 4.0) * scale,
	])
	_solid_polygon(body, fur)
	draw_circle(anchor + Vector2(4.0, -98.0) * scale, 22.0 * scale, fur.lightened(0.06))
	draw_line(anchor + Vector2(-4.0, -112.0) * scale, anchor + Vector2(-20.0, -136.0) * scale, trim, 4.0 * scale, true)
	draw_line(anchor + Vector2(10.0, -112.0) * scale, anchor + Vector2(24.0, -136.0) * scale, trim, 4.0 * scale, true)
	draw_circle(anchor + Vector2(-4.0, -102.0) * scale, 3.0 * scale, trim.lightened(0.24))
	draw_circle(anchor + Vector2(10.0, -102.0) * scale, 3.0 * scale, trim.lightened(0.24))
	draw_line(anchor + Vector2(-18.0, -42.0) * scale, anchor + Vector2(-30.0, 2.0) * scale, fur.lightened(0.06), 9.0 * scale, true)
	draw_line(anchor + Vector2(12.0, -40.0) * scale, anchor + Vector2(22.0, 0.0) * scale, fur.lightened(0.06), 9.0 * scale, true)
	draw_line(anchor + Vector2(12.0, -70.0) * scale, anchor + Vector2(30.0, -64.0 + _stance_lean(position_name, false) * 0.16) * scale, fur.lightened(0.10), 7.0 * scale, true)
	_draw_racquet_outline(anchor + Vector2(-34.0, -66.0) * scale, trim, facing_dir, scale)

func _draw_hair_or_headgear(head_center: Vector2, hair: Color, trim: Color, variant_kind: String, scale: float) -> void:
	match variant_kind:
		"novice":
			_draw_cap(head_center + Vector2(0.0, -2.0 * scale), trim, scale)
		"slicer":
			_draw_visor(head_center + Vector2(0.0, -2.0 * scale), trim, scale)
		"pusher", "power", "all_arounder", "baseliner", "master", "alcaraz", "vampire":
			_draw_headband(head_center + Vector2(0.0, -4.0 * scale), trim, scale)
		"serve_and_volley":
			_draw_cap(head_center + Vector2(0.0, -2.0 * scale), trim.lightened(0.08), scale)
		"duo_left":
			_draw_cap(head_center + Vector2(0.0, -2.0 * scale), trim.darkened(0.06), scale)
		"duo_right":
			_draw_headband(head_center + Vector2(0.0, -4.0 * scale), trim.lightened(0.08), scale)
		_:
			pass
	var hair_shape := PackedVector2Array([
		head_center + Vector2(-14.0, -6.0) * scale,
		head_center + Vector2(-8.0, -18.0) * scale,
		head_center + Vector2(0.0, -22.0) * scale,
		head_center + Vector2(10.0, -16.0) * scale,
		head_center + Vector2(14.0, -4.0) * scale,
		head_center + Vector2(0.0, 4.0) * scale,
	])
	_solid_polygon(hair_shape, hair)

func _draw_racquet_outline(anchor: Vector2, color_value: Color, facing_dir: float, scale: float) -> void:
	var head_center := anchor + Vector2(14.0 * facing_dir, -16.0) * scale
	draw_line(anchor + Vector2(0.0, 8.0) * scale, anchor + Vector2(12.0 * facing_dir, 24.0) * scale, Color(0.44, 0.24, 0.12, 1.0), 3.4 * scale, true)
	draw_arc(head_center, 11.0 * scale, 0.0, TAU, 26, color_value.lightened(0.18), 2.2 * scale, true)
	for idx in range(3):
		var x_shift := lerpf(-6.0, 6.0, float(idx) / 2.0)
		draw_line(head_center + Vector2(x_shift, -8.0) * scale, head_center + Vector2(x_shift, 8.0) * scale, color_value, 0.9 * scale, true)
		var y_shift := lerpf(-7.0, 7.0, float(idx) / 2.0)
		draw_line(head_center + Vector2(-7.0, y_shift) * scale, head_center + Vector2(7.0, y_shift) * scale, color_value, 0.9 * scale, true)

func _draw_net(court_rect: Rect2, border: Color) -> void:
	var play_rect := _play_rect(court_rect)
	var top := Vector2(play_rect.position.x + play_rect.size.x * 0.50, play_rect.position.y)
	var bottom := Vector2(play_rect.position.x + play_rect.size.x * 0.50, play_rect.end.y)
	var net_color := border.lightened(0.20)
	net_color.a = 0.84
	var tape := Color(0.96, 0.98, 0.95, 0.96)
	draw_line(top, bottom, net_color, 6.0, true)
	draw_line(top, bottom, tape, 2.4, true)
	draw_line(top, top + Vector2(-26.0, 0.0), net_color, 3.0, true)
	draw_line(bottom, bottom + Vector2(26.0, 0.0), net_color, 3.0, true)

func _draw_serve_indicator(court_rect: Rect2, player_color: Color, enemy_color: Color, border: Color) -> void:
	if int(_presentation.get("rally_exchanges", 0)) != 0:
		return
	var server := String(_presentation.get("server", "player"))
	var is_player_server := server == "player"
	var anchor := _player_anchor(court_rect) if is_player_server else _enemy_anchor(court_rect)
	var tint := player_color if is_player_server else enemy_color
	var ring := tint.lightened(0.12)
	ring.a = 0.92
	draw_arc(anchor + Vector2(0.0, -54.0), 20.0, 0.0, TAU, 28, ring, 2.4, true)
	draw_line(anchor + Vector2(0.0, -80.0), anchor + Vector2(0.0, -58.0), ring, 2.4, true)
	var arrow := PackedVector2Array([
		anchor + Vector2(0.0, -50.0),
		anchor + Vector2(-7.0, -60.0),
		anchor + Vector2(7.0, -60.0),
	])
	_solid_polygon(arrow, ring)
	var pill_rect := Rect2(anchor.x - 40.0, anchor.y - 112.0, 80.0, 22.0)
	var fill := border.darkened(0.26)
	fill.a = 0.82
	draw_rect(pill_rect, fill)
	draw_rect(pill_rect, ring, false, 1.4)
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, pill_rect.position + Vector2(14.0, 15.5), "SERVE", HORIZONTAL_ALIGNMENT_LEFT, pill_rect.size.x - 12.0, 11, ring)

func _draw_enemy_projection(court_rect: Rect2, enemy_color: Color, border: Color) -> void:
	var projection_data := Dictionary(_presentation.get("enemy_intent_projection_data", {}))
	if projection_data.is_empty():
		return
	var projected_anchor := _projection_anchor(court_rect, projection_data)
	var current_anchor := _enemy_anchor(court_rect)
	var ghost := enemy_color.lightened(0.12)
	ghost.a = 0.24
	var ring := border.lightened(0.10)
	ring.a = 0.88
	var lane_text := String(projection_data.get("lane", "Center"))
	var position_text := String(projection_data.get("position", "Baseline"))
	draw_dashed_line(current_anchor, projected_anchor, ring, 3.0, 9.0, true)
	draw_circle(projected_anchor, 18.0, ghost)
	draw_arc(projected_anchor, 24.0, 0.0, TAU, 28, ring, 2.4, true)
	draw_line(projected_anchor + Vector2(-10.0, 0.0), projected_anchor + Vector2(10.0, 0.0), ring, 2.0, true)
	draw_line(projected_anchor + Vector2(0.0, -10.0), projected_anchor + Vector2(0.0, 10.0), ring, 2.0, true)
	var font := ThemeDB.fallback_font
	if font != null:
		var font_size := 13
		var label := "%s • %s" % [position_text, lane_text]
		draw_string(font, projected_anchor + Vector2(-42.0, -18.0), label, HORIZONTAL_ALIGNMENT_LEFT, 100.0, font_size, ring)

func _player_anchor(court_rect: Rect2) -> Vector2:
	return _actor_anchor(court_rect, true, String(_presentation.get("player_position", "Baseline")))

func _enemy_anchor(court_rect: Rect2) -> Vector2:
	return _actor_anchor(court_rect, false, String(_presentation.get("enemy_position", "Baseline")))

func _projection_anchor(court_rect: Rect2, projection_data: Dictionary) -> Vector2:
	var position_name := String(projection_data.get("position", "Baseline"))
	var lane_name := String(projection_data.get("lane", "Center"))
	var anchor := _actor_anchor(court_rect, false, position_name)
	var lane_shift := 0.0
	match lane_name:
		"Crosscourt":
			lane_shift = -court_rect.size.y * 0.14
		"Down The Line":
			lane_shift = court_rect.size.y * 0.14
		"Body":
			lane_shift = court_rect.size.y * 0.05
		"Deep":
			lane_shift = 0.0
		_:
			lane_shift = 0.0
	var depth_shift := 0.0
	if lane_name == "Deep":
		depth_shift = court_rect.size.x * 0.04
	return anchor + Vector2(depth_shift, lane_shift)

func _actor_anchor(court_rect: Rect2, is_player: bool, position_name: String) -> Vector2:
	var play_rect := _play_rect(court_rect)
	var baseline_offset := court_rect.size.x * 0.045
	var x := play_rect.position.x - baseline_offset if is_player else play_rect.end.x + baseline_offset
	var y_ratio := 0.60 if is_player else 0.40
	match position_name:
		"ServiceLine":
			x = play_rect.position.x + play_rect.size.x * (0.31 if is_player else 0.69)
		"Net":
			x = play_rect.position.x + play_rect.size.x * (0.44 if is_player else 0.56)
		_:
			pass
	return Vector2(
		x,
		play_rect.position.y + play_rect.size.y * y_ratio
	)

func _actor_scale(court_rect: Rect2, anchor: Vector2) -> float:
	var play_rect := _play_rect(court_rect)
	var center_x := play_rect.position.x + play_rect.size.x * 0.50
	var distance_ratio := absf(anchor.x - center_x) / maxf(1.0, play_rect.size.x * 0.32)
	return lerpf(1.02, 0.92, clampf(distance_ratio, 0.0, 1.0))

func _pressure_ratio() -> float:
	var pressure := float(int(_presentation.get("rally_pressure", 0)))
	var pressure_target := maxf(1.0, float(int(_presentation.get("rally_pressure_max", 100))))
	return clampf(pressure / pressure_target, -1.0, 1.0)

func _ball_lane_ratio() -> float:
	match String(_presentation.get("ball_lane", "Center")):
		"Crosscourt":
			return 0.34
		"Down The Line":
			return 0.66
		"Body":
			return 0.54
		_:
			return 0.50

func _stance_lean(position_name: String, is_player: bool) -> float:
	var toward_court := 16.0 if is_player else -16.0
	match position_name:
		"ServiceLine":
			return toward_court * 0.55
		"Net":
			return toward_court
		_:
			return toward_court * 0.18

func _player_variant_kind() -> String:
	return String(_presentation.get("player_class_id", "novice"))

func _enemy_variant_kind() -> String:
	var enemy_id := String(_presentation.get("enemy_id", "")).to_lower()
	var enemy_style := String(_presentation.get("enemy_style", "")).to_lower()
	var enemy_keywords := _keyword_array(_presentation.get("enemy_keywords", PackedStringArray()))
	if enemy_keywords.has("pair") or enemy_id.find("duo") >= 0 or enemy_style.find("rivals") >= 0:
		return "duo"
	if enemy_keywords.has("machine") or enemy_id.find("machine") >= 0 or enemy_id.find("servebot") >= 0 or enemy_id.find("scoreboard") >= 0:
		return "machine"
	if enemy_id.find("specter") >= 0 or enemy_id.find("wraith") >= 0 or enemy_id.find("umbra") >= 0 or enemy_id.find("reaper") >= 0:
		return "specter"
	if enemy_id.find("golem") >= 0 or enemy_id.find("gargoyle") >= 0 or enemy_id.find("ogre") >= 0 or enemy_id.find("colossus") >= 0 or enemy_id.find("troll") >= 0:
		return "stone"
	if enemy_id.find("vampire") >= 0:
		return "vampire"
	if enemy_style.find("human") >= 0:
		return "human"
	return "beast"

func _keyword_array(value) -> PackedStringArray:
	if typeof(value) == TYPE_PACKED_STRING_ARRAY:
		return value
	var keywords := PackedStringArray()
	if value is Array:
		for entry in value:
			keywords.append(String(entry).to_lower())
	return keywords

func _human_palette(key: String) -> Dictionary:
	var index: int = abs(hash(key)) % 4
	match index:
		0:
			return {
				"skin": Color(0.95, 0.78, 0.64, 1.0),
				"skin_shadow": Color(0.77, 0.59, 0.48, 1.0),
				"hair": Color(0.20, 0.12, 0.08, 1.0),
			}
		1:
			return {
				"skin": Color(0.86, 0.68, 0.50, 1.0),
				"skin_shadow": Color(0.66, 0.49, 0.35, 1.0),
				"hair": Color(0.15, 0.10, 0.08, 1.0),
			}
		2:
			return {
				"skin": Color(0.67, 0.49, 0.34, 1.0),
				"skin_shadow": Color(0.49, 0.34, 0.23, 1.0),
				"hair": Color(0.11, 0.08, 0.07, 1.0),
			}
		_:
			return {
				"skin": Color(0.49, 0.34, 0.24, 1.0),
				"skin_shadow": Color(0.34, 0.24, 0.18, 1.0),
				"hair": Color(0.08, 0.06, 0.05, 1.0),
			}

func _draw_cap(anchor: Vector2, color_value: Color, scale: float) -> void:
	var brim := PackedVector2Array([
		anchor + Vector2(-14.0, 2.0) * scale,
		anchor + Vector2(12.0, 0.0) * scale,
		anchor + Vector2(4.0, 8.0) * scale,
		anchor + Vector2(-10.0, 7.0) * scale,
	])
	_solid_polygon(brim, color_value)
	draw_circle(anchor + Vector2(0.0, 3.0) * scale, 10.0 * scale, color_value.darkened(0.08))

func _draw_headband(anchor: Vector2, color_value: Color, scale: float) -> void:
	draw_rect(Rect2(anchor.x - 12.0 * scale, anchor.y - 3.0 * scale, 24.0 * scale, 6.0 * scale), color_value)

func _draw_visor(anchor: Vector2, color_value: Color, scale: float) -> void:
	var brim := PackedVector2Array([
		anchor + Vector2(-15.0, 4.0) * scale,
		anchor + Vector2(15.0, 2.0) * scale,
		anchor + Vector2(8.0, 9.0) * scale,
		anchor + Vector2(-8.0, 8.0) * scale,
	])
	_solid_polygon(brim, color_value)
	draw_rect(Rect2(anchor.x - 12.0 * scale, anchor.y - 2.0 * scale, 24.0 * scale, 6.0 * scale), color_value.darkened(0.08))

func _quadratic_bezier(start_point: Vector2, control_point: Vector2, end_point: Vector2, t: float) -> Vector2:
	var one_minus_t := 1.0 - t
	return one_minus_t * one_minus_t * start_point + 2.0 * one_minus_t * t * control_point + t * t * end_point

func _draw_line(start_point: Vector2, end_point: Vector2, color_value: Color, width: float) -> void:
	draw_line(start_point, end_point, color_value, width, true)

func _solid_polygon(points: PackedVector2Array, color_value: Color) -> void:
	var colors := PackedColorArray()
	for _unused in points:
		colors.append(color_value)
	draw_polygon(points, colors)

func _draw_soft_ellipse(area: Rect2, color_value: Color, points_count: int) -> void:
	var ellipse_points := PackedVector2Array()
	var center := area.get_center()
	var radius_x := area.size.x * 0.5
	var radius_y := area.size.y * 0.5
	for point_idx in range(maxi(12, points_count)):
		var angle := TAU * float(point_idx) / float(maxi(12, points_count))
		ellipse_points.append(Vector2(
			center.x + cos(angle) * radius_x,
			center.y + sin(angle) * radius_y
		))
	_solid_polygon(ellipse_points, color_value)
