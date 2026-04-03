class_name TennisMeter
extends Control

var _config: Dictionary = {
	"mode": "fill",
	"value": 0.0,
	"min": 0.0,
	"max": 100.0,
	"left_color": Color(0.86, 0.20, 0.18, 1.0),
	"right_color": Color(0.22, 0.78, 0.34, 1.0),
	"track_color": Color(0.10, 0.12, 0.16, 0.96),
	"frame_color": Color(0.80, 0.86, 0.96, 1.0),
	"ball_color": Color(0.95, 0.95, 0.32, 1.0),
	"track_texture": null,
	"ball_texture": null,
	"left_label": "",
	"right_label": "",
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(180, 28)
	queue_redraw()

func apply_meter(config: Dictionary) -> void:
	for key in config.keys():
		_config[key] = config[key]
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var outer := rect.grow(-1.0)
	var frame_color := Color(_config.get("frame_color", Color(0.8, 0.86, 0.96, 1.0)))
	var track_color := Color(_config.get("track_color", Color(0.10, 0.12, 0.16, 0.96)))
	draw_rect(outer, frame_color.darkened(0.55))
	draw_rect(outer.grow(-2.0), frame_color, false, 2.0)
	var track_rect := outer.grow(-6.0)
	draw_rect(track_rect, track_color)
	var track_texture: Texture2D = _config.get("track_texture", null)
	if track_texture != null:
		draw_texture_rect(track_texture, track_rect, true, Color(1.0, 1.0, 1.0, 0.22))
	if String(_config.get("mode", "fill")) == "centered":
		_draw_centered_meter(track_rect)
	else:
		_draw_fill_meter(track_rect)

func _draw_centered_meter(track_rect: Rect2) -> void:
	var min_value := float(_config.get("min", -100.0))
	var max_value := float(_config.get("max", 100.0))
	var value := clampf(float(_config.get("value", 0.0)), min_value, max_value)
	var center_x := track_rect.position.x + track_rect.size.x * 0.5
	var mid_y := track_rect.position.y + track_rect.size.y * 0.5
	var left_color := Color(_config.get("left_color", Color.RED))
	var right_color := Color(_config.get("right_color", Color.GREEN))
	var left_rect := Rect2(track_rect.position, Vector2(track_rect.size.x * 0.5, track_rect.size.y))
	var right_rect := Rect2(Vector2(center_x, track_rect.position.y), Vector2(track_rect.size.x * 0.5, track_rect.size.y))
	_draw_horizontal_gradient(left_rect, left_color.darkened(0.22), left_color, 24)
	_draw_horizontal_gradient(right_rect, right_color, right_color.darkened(0.12), 24)
	_draw_meter_endcap(Vector2(track_rect.position.x + 2.0, mid_y), track_rect.size.y * 0.34, left_color, true)
	_draw_meter_endcap(Vector2(track_rect.end.x - 2.0, mid_y), track_rect.size.y * 0.34, right_color, false)
	_draw_centered_labels(track_rect, String(_config.get("left_label", "")), String(_config.get("right_label", "")), left_color, right_color)
	var mid_color := Color(1, 1, 1, 0.22)
	draw_line(Vector2(center_x, track_rect.position.y), Vector2(center_x, track_rect.end.y), mid_color, 2.0, true)
	var ball_texture: Texture2D = _config.get("ball_texture", null)
	if ball_texture != null:
		var center_marker_rect := Rect2(
			Vector2(center_x - track_rect.size.y * 0.40, track_rect.position.y + track_rect.size.y * 0.10),
			Vector2(track_rect.size.y * 0.80, track_rect.size.y * 0.80)
		)
		draw_texture_rect(ball_texture, center_marker_rect, false, Color(1.0, 1.0, 1.0, 0.26))
	var normalized := inverse_lerp(min_value, max_value, value)
	var ball_x := track_rect.position.x + track_rect.size.x * normalized
	var ball_center := Vector2(ball_x, mid_y)
	var base_ball_color := Color(_config.get("ball_color", Color(0.95, 0.95, 0.32, 1.0)))
	var pressure_side_color := left_color.lerp(right_color, normalized)
	var pressure_pull := absf(normalized - 0.5) * 2.0
	var ball_tint := base_ball_color.lerp(pressure_side_color, 0.18 + pressure_pull * 0.34)
	var glow := ball_tint
	glow.a = 0.18
	if pressure_pull > 0.18:
		_draw_ball_trail(ball_center, normalized < 0.5, pressure_pull, ball_tint, track_rect)
	draw_circle(ball_center, track_rect.size.y * 0.78, glow)
	if ball_texture != null:
		var ball_rect := Rect2(
			ball_center - Vector2(track_rect.size.y * 0.46, track_rect.size.y * 0.46),
			Vector2(track_rect.size.y * 0.92, track_rect.size.y * 0.92)
		)
		var shadow_rect := Rect2(ball_rect.position + Vector2(0.0, 1.2), ball_rect.size)
		draw_texture_rect(ball_texture, shadow_rect, false, Color(0.02, 0.04, 0.08, 0.28))
		draw_texture_rect(ball_texture, ball_rect, false, ball_tint)
	else:
		draw_circle(ball_center, track_rect.size.y * 0.42, ball_tint)
		var seam := Color(0.98, 0.98, 0.90, 0.95)
		_draw_curve(ball_center + Vector2(-track_rect.size.y * 0.12, -track_rect.size.y * 0.32), ball_center + Vector2(-track_rect.size.y * 0.02, 0.0), ball_center + Vector2(-track_rect.size.y * 0.08, track_rect.size.y * 0.32), seam, 2.0)
		_draw_curve(ball_center + Vector2(track_rect.size.y * 0.12, -track_rect.size.y * 0.32), ball_center + Vector2(track_rect.size.y * 0.02, 0.0), ball_center + Vector2(track_rect.size.y * 0.08, track_rect.size.y * 0.32), seam, 2.0)

func _draw_fill_meter(track_rect: Rect2) -> void:
	var min_value := float(_config.get("min", 0.0))
	var max_value := float(_config.get("max", 100.0))
	var value := clampf(float(_config.get("value", 0.0)), min_value, max_value)
	var normalized := 0.0 if is_equal_approx(max_value, min_value) else inverse_lerp(min_value, max_value, value)
	var fill_rect := Rect2(track_rect.position, Vector2(track_rect.size.x * normalized, track_rect.size.y))
	_draw_horizontal_gradient(fill_rect, Color(_config.get("left_color", Color(0.12, 0.52, 0.24, 1.0))), Color(_config.get("right_color", Color(0.32, 0.92, 0.42, 1.0))), 24)
	var highlight := Color(1, 1, 1, 0.10)
	draw_rect(Rect2(track_rect.position, Vector2(fill_rect.size.x, track_rect.size.y * 0.36)), highlight)

func _draw_horizontal_gradient(area: Rect2, start_color: Color, end_color: Color, strips: int) -> void:
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return
	for idx in range(maxi(1, strips)):
		var t0 := float(idx) / float(maxi(1, strips))
		var t1 := float(idx + 1) / float(maxi(1, strips))
		var x := area.position.x + area.size.x * t0
		var band := start_color.lerp(end_color, t0)
		draw_rect(Rect2(x, area.position.y, area.size.x * (t1 - t0) + 1.0, area.size.y), band)

func _draw_curve(start: Vector2, control: Vector2, finish: Vector2, color_value: Color, width: float) -> void:
	var points := PackedVector2Array()
	for segment in range(13):
		var t := float(segment) / 12.0
		var one_minus_t := 1.0 - t
		points.append(one_minus_t * one_minus_t * start + 2.0 * one_minus_t * t * control + t * t * finish)
	draw_polyline(points, color_value, width, true)

func _draw_meter_endcap(center: Vector2, radius: float, color_value: Color, left_side: bool) -> void:
	var shadow := color_value.darkened(0.56)
	shadow.a = 0.28
	draw_circle(center + Vector2(0.0, 1.2), radius * 1.26, shadow)
	draw_circle(center, radius * 1.20, color_value.darkened(0.32))
	draw_circle(center, radius * 0.86, color_value.lightened(0.10))
	draw_circle(center + Vector2(0.0, -radius * 0.22), radius * 0.26, Color(1.0, 1.0, 1.0, 0.18))
	var direction := -1.0 if left_side else 1.0
	draw_line(
		center + Vector2(direction * radius * 0.10, -radius * 0.36),
		center + Vector2(direction * radius * 0.48, radius * 0.36),
		Color(1.0, 1.0, 1.0, 0.22),
		1.4,
		true
	)

func _draw_centered_labels(track_rect: Rect2, left_label: String, right_label: String, left_color: Color, right_color: Color) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var baseline_y := minf(size.y - 2.0, track_rect.end.y + 10.0)
	if left_label != "":
		var left_text_color := left_color.lightened(0.22)
		left_text_color.a = 0.92
		draw_string(font, Vector2(track_rect.position.x + 4.0, baseline_y), left_label, HORIZONTAL_ALIGNMENT_LEFT, 36.0, 9, left_text_color)
	if right_label != "":
		var right_text_color := right_color.lightened(0.18)
		right_text_color.a = 0.92
		draw_string(font, Vector2(track_rect.end.x - 40.0, baseline_y), right_label, HORIZONTAL_ALIGNMENT_LEFT, 36.0, 9, right_text_color)

func _draw_ball_trail(ball_center: Vector2, is_left_side: bool, pressure_pull: float, ball_tint: Color, track_rect: Rect2) -> void:
	var direction := 1.0 if is_left_side else -1.0
	var trail_length := lerpf(track_rect.size.x * 0.05, track_rect.size.x * 0.16, clampf((pressure_pull - 0.18) / 0.82, 0.0, 1.0))
	for step in range(3):
		var t := float(step + 1) / 3.0
		var sample_center := ball_center + Vector2(direction * trail_length * t, 0.0)
		var sample_color := ball_tint
		sample_color.a = lerpf(0.16, 0.04, t)
		draw_circle(sample_center, lerpf(track_rect.size.y * 0.34, track_rect.size.y * 0.14, t), sample_color)
