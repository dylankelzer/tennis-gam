class_name PortraitTile
extends Control

var _subject: Dictionary = {}
var _portrait_texture: Texture2D = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(164, 164)
	queue_redraw()

func apply_subject(subject: Dictionary) -> void:
	_subject = subject.duplicate(true)
	_portrait_texture = _resolve_texture(_subject)
	tooltip_text = "%s\n%s" % [String(_subject.get("title", "")), String(_subject.get("subtitle", ""))]
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	var frame := Color(_subject.get("frame_color", Color(0.82, 0.86, 0.94, 1.0)))
	var inner := Color(_subject.get("inner_color", Color(0.11, 0.17, 0.24, 1.0)))
	var glow := Color(_subject.get("glow_color", Color(0.36, 0.72, 1.0, 1.0)))
	var accent := Color(_subject.get("accent_color", Color(0.96, 0.98, 1.0, 1.0)))
	var silhouette := String(_subject.get("silhouette_kind", "hero"))
	var energy := String(_subject.get("energy_kind", "arc"))
	var enemy := bool(_subject.get("enemy", false))

	_draw_frame(rect, frame, inner)
	_draw_background(rect, inner, glow)
	_draw_texture_layer(rect, glow)
	_draw_energy(rect, glow, energy)
	if _portrait_texture == null:
		_draw_bust(rect, accent, glow, silhouette, enemy)
	_draw_caption_band(rect, frame, accent)

func _resolve_texture(subject: Dictionary) -> Texture2D:
	var direct_texture = subject.get("texture")
	if direct_texture is Texture2D:
		return direct_texture
	var texture_paths = subject.get("texture_paths", [])
	if texture_paths is Array:
		for path_value in texture_paths:
			var candidate_path := String(path_value)
			if candidate_path != "" and ResourceLoader.exists(candidate_path):
				var candidate_resource = load(candidate_path)
				if candidate_resource is Texture2D:
					return candidate_resource
	var texture_path := String(subject.get("texture_path", ""))
	if texture_path == "":
		return null
	if not ResourceLoader.exists(texture_path):
		return null
	var loaded = load(texture_path)
	return loaded if loaded is Texture2D else null

func _draw_frame(rect: Rect2, frame: Color, inner: Color) -> void:
	var outer := inner.darkened(0.62)
	outer.a = 0.92
	draw_rect(rect.grow(-1.0), outer)
	draw_rect(rect.grow(-7.0), inner.darkened(0.10))
	var border := frame.lightened(0.08)
	border.a = 0.96
	draw_rect(Rect2(rect.position + Vector2(4.0, 4.0), rect.size - Vector2(8.0, 8.0)), border, false, 2.8)
	draw_rect(Rect2(rect.position + Vector2(10.0, 10.0), rect.size - Vector2(20.0, 20.0)), Color(0.98, 0.99, 1.0, 0.24), false, 1.2)
	draw_rect(Rect2(rect.position + Vector2(12.0, 12.0), rect.size - Vector2(24.0, 24.0)), border.darkened(0.42), false, 1.4)
	draw_rect(Rect2(12.0, 12.0, rect.size.x - 24.0, 18.0), Color(1.0, 1.0, 1.0, 0.08))
	_draw_corner_plate(Rect2(16.0, 16.0, 18.0, 18.0), border)
	_draw_corner_plate(Rect2(rect.size.x - 34.0, rect.size.y - 34.0, 18.0, 18.0), border)

func _draw_background(rect: Rect2, inner: Color, glow: Color) -> void:
	var top := inner.lightened(0.06)
	var bottom := inner.darkened(0.30)
	for idx in range(52):
		var t := float(idx) / 51.0
		var band := top.lerp(bottom, t)
		draw_rect(Rect2(12.0, 12.0 + (rect.size.y - 24.0) * t, rect.size.x - 24.0, rect.size.y / 52.0 + 1.0), band)
	var glow_main := glow
	glow_main.a = 0.28
	var glow_secondary := glow.lightened(0.12)
	glow_secondary.a = 0.16
	draw_circle(Vector2(rect.size.x * 0.34, rect.size.y * 0.34), rect.size.x * 0.20, glow_main)
	draw_circle(Vector2(rect.size.x * 0.68, rect.size.y * 0.30), rect.size.x * 0.16, glow_secondary)
	_draw_diagonal_glow(rect, glow.lightened(0.04), -36.0, 0.12)
	_draw_diagonal_glow(rect, glow.darkened(0.10), 32.0, 0.08)
	_draw_ellipse_outline(Vector2(rect.size.x * 0.82, rect.size.y * 0.16), Vector2(10.0, 10.0), Color(1.0, 1.0, 1.0, 0.16), 1.2)

func _draw_diagonal_glow(rect: Rect2, color_value: Color, rotation_degrees: float, alpha_scale: float) -> void:
	var overlay := color_value
	overlay.a = alpha_scale
	var band := PackedVector2Array([
		Vector2(rect.size.x * 0.08, rect.size.y * 0.18),
		Vector2(rect.size.x * 0.40, rect.size.y * 0.12),
		Vector2(rect.size.x * 0.92, rect.size.y * 0.78),
		Vector2(rect.size.x * 0.60, rect.size.y * 0.84),
	])
	var center := rect.size * 0.5
	for idx in range(band.size()):
		band[idx] = center + (band[idx] - center).rotated(deg_to_rad(rotation_degrees))
	_fill_polygon(band, overlay)

func _draw_texture_layer(rect: Rect2, glow: Color) -> void:
	if _portrait_texture == null:
		return
	var art_rect := Rect2(12.0, 12.0, rect.size.x - 24.0, rect.size.y - 56.0)
	_draw_texture_cover(_portrait_texture, art_rect)
	var vignette := Color(0.02, 0.03, 0.05, 0.16)
	draw_rect(art_rect.grow(-2.0), vignette, false, 3.0)
	var overlay := glow
	overlay.a = 0.12
	draw_rect(art_rect, overlay)

func _draw_texture_cover(texture: Texture2D, art_rect: Rect2) -> void:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale_factor := maxf(art_rect.size.x / texture_size.x, art_rect.size.y / texture_size.y)
	var scaled_size := texture_size * scale_factor
	var offset := (scaled_size - art_rect.size) * 0.5
	var source_rect := Rect2(offset / scale_factor, art_rect.size / scale_factor)
	draw_texture_rect_region(texture, art_rect, source_rect)

func _draw_energy(rect: Rect2, glow: Color, energy: String) -> void:
	match energy:
		"burst":
			_draw_energy_ring(rect, glow, 0.31, 3.6)
			for idx in range(10):
				var angle := TAU * float(idx) / 8.0
				var start := Vector2(rect.size.x * 0.50, rect.size.y * 0.42) + Vector2(cos(angle), sin(angle)) * rect.size.x * 0.10
				var end := Vector2(rect.size.x * 0.50, rect.size.y * 0.42) + Vector2(cos(angle), sin(angle)) * rect.size.x * 0.30
				var streak := glow
				streak.a = 0.28
				draw_line(start, end, streak, 3.4, true)
		"spiral":
			_draw_energy_ring(rect, glow, 0.29, 3.0)
			_draw_arc_swoosh(rect, glow, 0.16, 0.86, 18.0)
			_draw_arc_swoosh(rect, glow.lightened(0.16), 0.42, 1.32, -14.0)
		"flare":
			_draw_energy_ring(rect, glow, 0.30, 3.2)
			var flare := glow
			flare.a = 0.30
			draw_rect(Rect2(rect.size.x * 0.16, rect.size.y * 0.22, rect.size.x * 0.68, rect.size.y * 0.10), flare)
			draw_rect(Rect2(rect.size.x * 0.24, rect.size.y * 0.30, rect.size.x * 0.52, rect.size.y * 0.05), flare.lightened(0.15))
		_:
			_draw_energy_ring(rect, glow, 0.28, 3.2)
			_draw_arc_swoosh(rect, glow, 0.24, 1.12, 0.0)

func _draw_energy_ring(rect: Rect2, glow: Color, radius_ratio: float, width: float) -> void:
	var ring := glow
	ring.a = 0.24
	_draw_ellipse_outline(Vector2(rect.size.x * 0.52, rect.size.y * 0.38), Vector2(rect.size.x * radius_ratio, rect.size.y * (radius_ratio * 0.78)), ring, width)
	var inner := glow.lightened(0.12)
	inner.a = 0.14
	_draw_ellipse_outline(Vector2(rect.size.x * 0.52, rect.size.y * 0.38), Vector2(rect.size.x * (radius_ratio - 0.05), rect.size.y * ((radius_ratio - 0.05) * 0.76)), inner, 1.6)

func _draw_arc_swoosh(rect: Rect2, color_value: Color, start_t: float, end_t: float, y_shift: float) -> void:
	var points := PackedVector2Array()
	for idx in range(24):
		var t := lerpf(start_t, end_t, float(idx) / 23.0)
		var angle := t * PI
		points.append(Vector2(
			rect.size.x * 0.50 + cos(angle) * rect.size.x * 0.28,
			rect.size.y * 0.40 + sin(angle) * rect.size.y * 0.18 + y_shift
		))
	var stroke := color_value
	stroke.a = 0.24
	draw_polyline(points, stroke, 3.6, true)

func _draw_bust(rect: Rect2, accent: Color, glow: Color, silhouette: String, enemy: bool) -> void:
	var portrait_kind := String(_subject.get("portrait_kind", "player"))
	var variant_kind := String(_subject.get("variant_kind", "human"))
	if portrait_kind == "enemy":
		_draw_enemy_portrait(rect, accent, glow, variant_kind, silhouette)
		return
	_draw_player_portrait(rect, accent, glow, variant_kind, silhouette)

func _draw_caption_band(rect: Rect2, frame: Color, accent: Color) -> void:
	var band := frame.darkened(0.34)
	band.a = 0.88
	draw_rect(Rect2(12.0, rect.size.y - 34.0, rect.size.x - 24.0, 18.0), band)
	var spark := accent
	spark.a = 0.26
	draw_rect(Rect2(18.0, rect.size.y - 28.0, rect.size.x - 36.0, 6.0), spark)
	var seam := accent.lightened(0.10)
	seam.a = 0.46
	var seam_center := Vector2(rect.size.x - 26.0, rect.size.y - 25.0)
	draw_circle(seam_center, 6.0, seam)
	draw_arc(seam_center, 4.0, -0.8, 0.8, 12, band.darkened(0.28), 1.0, true)
	draw_arc(seam_center, 4.0, PI - 0.8, PI + 0.8, 12, band.darkened(0.28), 1.0, true)

func _draw_corner_plate(area: Rect2, color_value: Color) -> void:
	draw_rect(area, color_value, false, 1.2)
	draw_line(area.position, area.position + Vector2(area.size.x, 0.0), color_value.lightened(0.16), 1.2, true)
	draw_line(area.position, area.position + Vector2(0.0, area.size.y), color_value.lightened(0.16), 1.2, true)

func _draw_player_portrait(rect: Rect2, accent: Color, glow: Color, variant_kind: String, silhouette: String) -> void:
	var center := Vector2(rect.size.x * 0.50, rect.size.y * 0.60)
	_draw_hero_bust(center, accent, glow, variant_kind, silhouette, false, 1.0)

func _draw_enemy_portrait(rect: Rect2, accent: Color, glow: Color, variant_kind: String, silhouette: String) -> void:
	var center := Vector2(rect.size.x * 0.50, rect.size.y * 0.60)
	var shadow := Color(0.0, 0.0, 0.0, 0.26)
	_draw_soft_ellipse(Rect2(center.x - 50.0, center.y + 38.0, 100.0, 22.0), shadow, 24)
	match variant_kind:
		"duo":
			_draw_human_enemy_bust(center + Vector2(-22.0, 10.0), accent, glow, "cap", true, 0.82)
			_draw_human_enemy_bust(center + Vector2(24.0, 6.0), accent.lightened(0.08), glow, "headband", true, 0.88)
		"human":
			_draw_human_enemy_bust(center, accent, glow, silhouette, true, 1.0)
		"machine":
			_draw_machine_enemy_bust(center, accent, glow)
		"stone":
			_draw_stone_enemy_bust(center, accent, glow)
		"specter":
			_draw_specter_enemy_bust(center, accent, glow)
		"vampire":
			_draw_vampire_enemy_bust(center, accent, glow)
		_:
			_draw_beast_enemy_bust(center, accent, glow)

func _draw_human_enemy_bust(center: Vector2, accent: Color, glow: Color, silhouette: String, enemy: bool, scale: float) -> void:
	_draw_hero_bust(center, accent, glow, "enemy_human", silhouette, enemy, scale)

func _draw_hero_bust(center: Vector2, accent: Color, glow: Color, variant_kind: String, silhouette: String, enemy: bool, scale: float) -> void:
	var palette := _human_palette(String(_subject.get("title", variant_kind)) + silhouette)
	var shirt := accent.darkened(0.14)
	var trim := accent.lightened(0.24)
	var skin := Color(palette.get("skin", Color(0.84, 0.68, 0.54)))
	var skin_shadow := Color(palette.get("skin_shadow", skin.darkened(0.18)))
	var hair := Color(palette.get("hair", Color(0.18, 0.12, 0.09)))
	var facing := -1.0 if enemy else 1.0
	var broad := silhouette == "brute" or variant_kind in ["power", "baseliner", "all_arounder", "alcaraz"]
	var shoulder_center := center + Vector2(-10.0 * facing * scale, 4.0 * scale)
	var head_center := center + Vector2(-6.0 * facing * scale, -40.0 * scale)
	var shadow := Color(0.0, 0.0, 0.0, 0.28)
	_draw_soft_ellipse(Rect2(center.x - 56.0 * scale, center.y + 38.0 * scale, 112.0 * scale, 20.0 * scale), shadow, 22)
	_draw_portrait_glow(center + Vector2(6.0 * facing * scale, -22.0 * scale), glow, scale)
	_draw_racquet(center + Vector2(58.0 * facing * scale, -6.0 * scale), trim, enemy)
	_draw_torso(shoulder_center, shirt, trim, enemy, broad, scale)
	_draw_neck(head_center + Vector2(0.0, 18.0 * scale), skin_shadow, scale)
	_draw_face(head_center, skin, skin_shadow, scale, facing)
	_draw_hair_style(head_center + Vector2(0.0, -14.0 * scale), hair, trim, variant_kind, silhouette, enemy, scale)
	var arm_color := skin_shadow
	draw_line(shoulder_center + Vector2(28.0 * facing * scale, -2.0 * scale), shoulder_center + Vector2(46.0 * facing * scale, 22.0 * scale), arm_color, 7.0 * scale, true)
	draw_line(shoulder_center + Vector2(-18.0 * facing * scale, 2.0 * scale), shoulder_center + Vector2(-38.0 * facing * scale, 26.0 * scale), arm_color, 6.0 * scale, true)

func _draw_machine_enemy_bust(center: Vector2, accent: Color, glow: Color) -> void:
	var armor := accent.darkened(0.34)
	var panel := glow.lightened(0.10)
	panel.a = 0.90
	_draw_racquet(center + Vector2(-52.0, -4.0), accent.lightened(0.18), true)
	_draw_soft_ellipse(Rect2(center.x - 50.0, center.y - 8.0, 100.0, 82.0), armor, 24)
	draw_rect(Rect2(center.x - 24.0, center.y - 68.0, 48.0, 42.0), armor.lightened(0.05))
	draw_rect(Rect2(center.x - 20.0, center.y - 58.0, 40.0, 14.0), panel)
	draw_circle(center + Vector2(-12.0, -8.0), 9.0, panel)
	draw_circle(center + Vector2(12.0, -8.0), 9.0, panel)
	draw_rect(Rect2(center.x - 10.0, center.y + 6.0, 20.0, 26.0), panel.darkened(0.20))

func _draw_stone_enemy_bust(center: Vector2, accent: Color, glow: Color) -> void:
	var rock := accent.darkened(0.28)
	var seams := glow.lightened(0.12)
	seams.a = 0.72
	_draw_racquet(center + Vector2(-56.0, -6.0), accent.lightened(0.12), true)
	var body := PackedVector2Array([
		center + Vector2(-48.0, 46.0),
		center + Vector2(-58.0, -4.0),
		center + Vector2(-30.0, -42.0),
		center + Vector2(28.0, -46.0),
		center + Vector2(58.0, -4.0),
		center + Vector2(48.0, 46.0),
	])
	_fill_polygon(body, rock)
	draw_rect(Rect2(center.x - 22.0, center.y - 74.0, 44.0, 36.0), rock.lightened(0.06))
	draw_line(center + Vector2(-18.0, -2.0), center + Vector2(12.0, 10.0), seams, 3.0, true)
	draw_line(center + Vector2(8.0, -28.0), center + Vector2(28.0, -4.0), seams, 3.0, true)
	draw_circle(center + Vector2(-10.0, -58.0), 4.0, glow.lightened(0.18))
	draw_circle(center + Vector2(10.0, -58.0), 4.0, glow.lightened(0.18))

func _draw_specter_enemy_bust(center: Vector2, accent: Color, glow: Color) -> void:
	var cloak := accent.darkened(0.40)
	var aura := glow.lightened(0.18)
	aura.a = 0.20
	_draw_racquet(center + Vector2(-50.0, -4.0), glow.lightened(0.20), true)
	draw_circle(center + Vector2(0.0, -34.0), 46.0, aura)
	var hood := PackedVector2Array([
		center + Vector2(-42.0, 40.0),
		center + Vector2(-30.0, -12.0),
		center + Vector2(0.0, -76.0),
		center + Vector2(30.0, -12.0),
		center + Vector2(42.0, 40.0),
	])
	_fill_polygon(hood, cloak)
	draw_circle(center + Vector2(-10.0, -38.0), 4.0, glow.lightened(0.24))
	draw_circle(center + Vector2(10.0, -38.0), 4.0, glow.lightened(0.24))

func _draw_vampire_enemy_bust(center: Vector2, accent: Color, glow: Color) -> void:
	var cape := accent.darkened(0.34)
	var skin := Color(0.88, 0.84, 0.86)
	var hair := Color(0.08, 0.05, 0.08)
	_draw_racquet(center + Vector2(-56.0, -6.0), glow.lightened(0.10), true)
	_draw_torso(center, cape, glow.lightened(0.12), true, false)
	_draw_neck(center + Vector2(0.0, -18.0), skin.darkened(0.12))
	_draw_face(center + Vector2(0.0, -40.0), skin, skin.darkened(0.12))
	_draw_hair_style(center + Vector2(0.0, -56.0), hair, glow.lightened(0.12), "vampire", "hero", true)
	draw_line(center + Vector2(-6.0, -20.0), center + Vector2(-2.0, -10.0), glow.lightened(0.20), 1.6, true)
	draw_line(center + Vector2(6.0, -20.0), center + Vector2(2.0, -10.0), glow.lightened(0.20), 1.6, true)

func _draw_beast_enemy_bust(center: Vector2, accent: Color, glow: Color) -> void:
	var hide := accent.darkened(0.28)
	var horn := glow.lightened(0.08)
	_draw_racquet(center + Vector2(-54.0, -2.0), glow.lightened(0.14), true)
	_draw_soft_ellipse(Rect2(center.x - 54.0, center.y + 6.0, 108.0, 62.0), hide, 28)
	_draw_soft_ellipse(Rect2(center.x - 30.0, center.y - 66.0, 60.0, 60.0), hide.lightened(0.06), 28)
	draw_line(center + Vector2(-16.0, -56.0), center + Vector2(-28.0, -88.0), horn, 5.0, true)
	draw_line(center + Vector2(16.0, -56.0), center + Vector2(28.0, -88.0), horn, 5.0, true)
	draw_circle(center + Vector2(-10.0, -44.0), 4.0, glow.lightened(0.20))
	draw_circle(center + Vector2(10.0, -44.0), 4.0, glow.lightened(0.20))

func _draw_torso(center: Vector2, body_color: Color, trim: Color, enemy: bool, broad: bool = false, scale: float = 1.0) -> void:
	var shoulder := 44.0 * scale if broad else 36.0 * scale
	var waist := 22.0 * scale
	var height := 76.0 * scale
	var torso := PackedVector2Array([
		center + Vector2(-shoulder, -16.0 * scale),
		center + Vector2(shoulder, -16.0 * scale),
		center + Vector2(waist + 10.0 * scale, height * 0.24),
		center + Vector2(waist, height * 0.48),
		center + Vector2(-waist, height * 0.48),
		center + Vector2(-waist - 10.0 * scale, height * 0.24),
	])
	_fill_polygon(torso, body_color)
	draw_rect(Rect2(center.x - 10.0 * scale, center.y - 12.0 * scale, 20.0 * scale, height * 0.38), trim.darkened(0.18))
	draw_line(center + Vector2(-shoulder + 8.0 * scale, -6.0 * scale), center + Vector2(0.0, 14.0 * scale), trim, 2.0 * scale, true)
	draw_line(center + Vector2(shoulder - 8.0 * scale, -6.0 * scale), center + Vector2(0.0, 14.0 * scale), trim, 2.0 * scale, true)
	var sleeve := body_color.lightened(0.10)
	draw_line(center + Vector2(-shoulder + 4.0 * scale, -4.0 * scale), center + Vector2(-shoulder - 10.0 * scale, 28.0 * scale), sleeve, 10.0 * scale, true)
	draw_line(center + Vector2(shoulder - 4.0 * scale, -4.0 * scale), center + Vector2(shoulder + 10.0 * scale, 28.0 * scale), sleeve, 10.0 * scale, true)
	if enemy:
		draw_rect(Rect2(center.x - 18.0 * scale, center.y + 14.0 * scale, 36.0 * scale, 8.0 * scale), trim.lightened(0.04))

func _draw_neck(anchor: Vector2, skin_shadow: Color, scale: float = 1.0) -> void:
	draw_rect(Rect2(anchor.x - 9.0 * scale, anchor.y - 8.0 * scale, 18.0 * scale, 20.0 * scale), skin_shadow)

func _draw_face(center: Vector2, skin: Color, skin_shadow: Color, scale: float = 1.0, facing: float = 1.0) -> void:
	var face := PackedVector2Array([
		center + Vector2(-18.0, -20.0) * scale,
		center + Vector2(-14.0, 8.0) * scale,
		center + Vector2(-4.0, 22.0) * scale,
		center + Vector2(10.0, 16.0) * scale,
		center + Vector2(18.0, -2.0) * scale,
		center + Vector2(12.0, -18.0) * scale,
		center + Vector2(-2.0, -24.0) * scale,
	])
	_fill_polygon(face, skin)
	var jaw := PackedVector2Array([
		center + Vector2(-12.0, 6.0) * scale,
		center + Vector2(-2.0, 18.0) * scale,
		center + Vector2(10.0, 14.0) * scale,
		center + Vector2(14.0, 0.0) * scale,
		center + Vector2(-4.0, 2.0) * scale,
	])
	_fill_polygon(jaw, skin_shadow)
	var brow := skin_shadow.darkened(0.18)
	draw_line(center + Vector2(-9.0 * facing, -6.0) * scale, center + Vector2(2.0 * facing, -8.0) * scale, brow, 2.0 * scale, true)
	draw_line(center + Vector2(0.0 * facing, -2.0) * scale, center + Vector2(10.0 * facing, -4.0) * scale, brow, 1.8 * scale, true)
	draw_circle(center + Vector2(-5.0 * facing, -4.0) * scale, 1.6 * scale, Color(0.08, 0.08, 0.10))
	draw_circle(center + Vector2(5.0 * facing, -1.0) * scale, 1.4 * scale, Color(0.08, 0.08, 0.10))
	draw_line(center + Vector2(0.0, 0.0), center + Vector2(2.0 * facing, 8.0) * scale, skin_shadow.darkened(0.20), 1.2 * scale, true)
	draw_line(center + Vector2(-4.0 * facing, 12.0) * scale, center + Vector2(5.0 * facing, 11.0) * scale, skin_shadow.darkened(0.24), 1.6 * scale, true)

func _draw_hair_style(anchor: Vector2, hair: Color, trim: Color, variant_kind: String, silhouette: String, enemy: bool, scale: float = 1.0) -> void:
	match variant_kind:
		"novice", "pusher", "serve_and_volley", "enemy_human":
			if silhouette == "cap":
				_draw_cap(anchor, trim)
				return
		"slicer":
			_draw_visor(anchor, trim, scale)
			return
		"power", "all_arounder", "baseliner", "alcaraz", "vampire":
			_draw_headband(anchor + Vector2(0.0, 8.0 * scale), trim)
		_:
			pass
	if silhouette == "machine":
		_draw_machine_visor(anchor + Vector2(0.0, 12.0 * scale), trim)
		return
	var hair_shape := PackedVector2Array([
		anchor + Vector2(-18.0 * scale, 18.0 * scale),
		anchor + Vector2(-20.0 * scale, -2.0 * scale),
		anchor + Vector2(0.0, -20.0 * scale),
		anchor + Vector2(20.0 * scale, -2.0 * scale),
		anchor + Vector2(18.0 * scale, 18.0 * scale),
		anchor + Vector2(0.0, 10.0 * scale),
	])
	_fill_polygon(hair_shape, hair)
	if enemy and variant_kind == "specter":
		_draw_hood(anchor + Vector2(0.0, 8.0 * scale), trim)

func _draw_portrait_glow(center: Vector2, glow: Color, scale: float = 1.0) -> void:
	var haze := glow
	haze.a = 0.18
	draw_circle(center, 36.0 * scale, haze)
	var ring := glow.lightened(0.14)
	ring.a = 0.18
	draw_circle(center + Vector2(0.0, -4.0 * scale), 24.0 * scale, ring)

func _human_palette(key: String) -> Dictionary:
	var index: int = abs(hash(key)) % 4
	match index:
		0:
			return {"skin": Color(0.95, 0.78, 0.64), "skin_shadow": Color(0.78, 0.60, 0.48), "hair": Color(0.20, 0.12, 0.08)}
		1:
			return {"skin": Color(0.86, 0.68, 0.50), "skin_shadow": Color(0.67, 0.49, 0.35), "hair": Color(0.16, 0.10, 0.08)}
		2:
			return {"skin": Color(0.67, 0.49, 0.34), "skin_shadow": Color(0.50, 0.34, 0.22), "hair": Color(0.11, 0.08, 0.07)}
		_:
			return {"skin": Color(0.49, 0.34, 0.24), "skin_shadow": Color(0.35, 0.24, 0.18), "hair": Color(0.08, 0.06, 0.05)}

func _draw_cap(anchor: Vector2, color_value: Color) -> void:
	var brim := PackedVector2Array([
		anchor + Vector2(-18.0, 4.0),
		anchor + Vector2(16.0, 0.0),
		anchor + Vector2(6.0, 10.0),
		anchor + Vector2(-14.0, 9.0),
	])
	_fill_polygon(brim, color_value)
	draw_circle(anchor + Vector2(0.0, 4.0), 14.0, color_value.darkened(0.08))

func _draw_hood(anchor: Vector2, color_value: Color) -> void:
	var hood := PackedVector2Array([
		anchor + Vector2(-18.0, 10.0),
		anchor + Vector2(0.0, -14.0),
		anchor + Vector2(18.0, 10.0),
		anchor + Vector2(10.0, 22.0),
		anchor + Vector2(-10.0, 22.0),
	])
	_fill_polygon(hood, color_value)

func _draw_horns(anchor: Vector2, color_value: Color) -> void:
	draw_line(anchor + Vector2(-8.0, 4.0), anchor + Vector2(-20.0, -14.0), color_value, 4.0, true)
	draw_line(anchor + Vector2(8.0, 4.0), anchor + Vector2(20.0, -14.0), color_value, 4.0, true)
	draw_line(anchor + Vector2(-20.0, -14.0), anchor + Vector2(-14.0, -4.0), color_value, 4.0, true)
	draw_line(anchor + Vector2(20.0, -14.0), anchor + Vector2(14.0, -4.0), color_value, 4.0, true)

func _draw_headband(anchor: Vector2, color_value: Color) -> void:
	draw_rect(Rect2(anchor.x - 16.0, anchor.y - 4.0, 32.0, 8.0), color_value)

func _draw_shoulders(center: Vector2, color_value: Color) -> void:
	draw_line(center + Vector2(-34.0, -4.0), center + Vector2(-48.0, 18.0), color_value, 10.0, true)
	draw_line(center + Vector2(34.0, -4.0), center + Vector2(48.0, 18.0), color_value, 10.0, true)

func _draw_visor(anchor: Vector2, color_value: Color, scale: float = 1.0) -> void:
	var brim := PackedVector2Array([
		anchor + Vector2(-18.0 * scale, 6.0 * scale),
		anchor + Vector2(18.0 * scale, 4.0 * scale),
		anchor + Vector2(8.0 * scale, 12.0 * scale),
		anchor + Vector2(-10.0 * scale, 11.0 * scale),
	])
	_fill_polygon(brim, color_value)
	draw_rect(Rect2(anchor.x - 14.0 * scale, anchor.y - 2.0 * scale, 28.0 * scale, 7.0 * scale), color_value.darkened(0.08))

func _draw_machine_visor(anchor: Vector2, color_value: Color) -> void:
	draw_rect(Rect2(anchor.x - 15.0, anchor.y - 8.0, 30.0, 16.0), color_value)
	var core := color_value.lightened(0.20)
	core.a = 0.9
	draw_circle(anchor, 4.0, core)

func _draw_racquet(anchor: Vector2, color_value: Color, enemy: bool) -> void:
	var head_center := anchor + Vector2(0.0, -10.0)
	_draw_ellipse_outline(head_center, Vector2(16.0, 21.0), color_value, 2.8)
	for idx in range(3):
		var x_offset := lerpf(-8.0, 8.0, float(idx) / 2.0)
		draw_line(head_center + Vector2(x_offset, -12.0), head_center + Vector2(x_offset, 12.0), color_value, 1.0, true)
		var y_offset := lerpf(-10.0, 10.0, float(idx) / 2.0)
		draw_line(head_center + Vector2(-10.0, y_offset), head_center + Vector2(10.0, y_offset), color_value, 1.0, true)
	var handle_end := anchor + Vector2(14.0 if not enemy else -14.0, 26.0)
	draw_line(anchor + Vector2(0.0, 10.0), handle_end, Color(0.46, 0.26, 0.12, 1.0), 4.0, true)

func _draw_soft_ellipse(area: Rect2, color_value: Color, point_count: int) -> void:
	var points := PackedVector2Array()
	var center := area.get_center()
	var radius_x := area.size.x * 0.5
	var radius_y := area.size.y * 0.5
	for idx in range(maxi(12, point_count)):
		var angle := TAU * float(idx) / float(maxi(12, point_count))
		points.append(Vector2(center.x + cos(angle) * radius_x, center.y + sin(angle) * radius_y))
	_fill_polygon(points, color_value)

func _draw_ellipse_outline(center: Vector2, radii: Vector2, color_value: Color, width: float) -> void:
	var points := PackedVector2Array()
	for idx in range(37):
		var angle := TAU * float(idx) / 36.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_polyline(points, color_value, width, true)

func _fill_polygon(points: PackedVector2Array, color_value: Color) -> void:
	var colors := PackedColorArray()
	for _unused in points:
		colors.append(color_value)
	draw_polygon(points, colors)
