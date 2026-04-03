extends SceneTree

const FX_BASE := "res://assets/fx"
const UNIT_ASSET_PATHS := {
	"novice": "res://assets/units/player/novice",
	"grinder": "res://assets/units/enemy/grinder",
}

func _initialize() -> void:
	_generate_character_set("novice", {
		"primary": Color8(70, 146, 230),
		"secondary": Color8(232, 243, 255),
		"skin": Color8(212, 178, 146),
		"accent": Color8(86, 194, 255),
		"hair": Color8(56, 38, 28),
		"shadow": Color(0.0, 0.0, 0.0, 0.38),
	})
	_generate_character_set("grinder", {
		"primary": Color8(96, 134, 38),
		"secondary": Color8(220, 233, 198),
		"skin": Color8(176, 145, 104),
		"accent": Color8(170, 220, 76),
		"hair": Color8(54, 46, 24),
		"shadow": Color(0.0, 0.0, 0.0, 0.42),
	})
	_generate_fx_textures()
	print("GENERATED COMBAT ASSETS")
	quit()

func _generate_character_set(unit_id: String, palette: Dictionary) -> void:
	var folder := String(UNIT_ASSET_PATHS.get(unit_id, "res://assets/units/player/novice"))
	_save_image(_make_body_image(palette), "%s/body.png" % folder)
	_save_image(_make_racquet_image(palette), "%s/racquet.png" % folder)
	_save_image(_make_aura_image(palette), "%s/aura.png" % folder)
	_save_image(_make_shadow_image(palette), "%s/shadow.png" % folder)

func _generate_fx_textures() -> void:
	_save_image(_make_hit_flash_image(), "%s/hit_flash.png" % FX_BASE)
	_save_image(_make_spin_burst_image(), "%s/spin_burst.png" % FX_BASE)
	_save_image(_make_dust_image(), "%s/dust.png" % FX_BASE)

func _save_image(image: Image, path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var error := image.save_png(absolute_path)
	if error != OK:
		push_error("Failed to save %s" % path)

func _make_body_image(palette: Dictionary) -> Image:
	var image := Image.create(192, 224, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var primary: Color = palette["primary"]
	var secondary: Color = palette["secondary"]
	var skin: Color = palette["skin"]
	var hair: Color = palette["hair"]
	_draw_glow_circle(image, Vector2(96.0, 76.0), 54.0, palette["accent"], 0.22)
	_draw_filled_circle(image, Vector2i(96, 44), 24, skin)
	_draw_filled_rect(image, Rect2i(66, 66, 60, 74), primary)
	_draw_filled_rect(image, Rect2i(72, 72, 48, 18), secondary)
	_draw_filled_rect(image, Rect2i(48, 76, 18, 64), secondary)
	_draw_filled_rect(image, Rect2i(126, 76, 18, 62), primary.darkened(0.1))
	_draw_filled_rect(image, Rect2i(74, 140, 20, 56), primary.darkened(0.08))
	_draw_filled_rect(image, Rect2i(98, 140, 20, 56), primary.darkened(0.18))
	_draw_filled_rect(image, Rect2i(72, 192, 24, 14), Color8(248, 248, 248))
	_draw_filled_rect(image, Rect2i(96, 192, 24, 14), Color8(248, 248, 248))
	_draw_filled_rect(image, Rect2i(70, 18, 52, 12), primary.darkened(0.25))
	_draw_filled_rect(image, Rect2i(78, 12, 36, 10), secondary)
	_draw_filled_rect(image, Rect2i(74, 28, 44, 8), hair)
	return image

func _make_racquet_image(palette: Dictionary) -> Image:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var frame: Color = palette["primary"].lightened(0.15)
	var strings: Color = palette["secondary"]
	_draw_ellipse_outline(image, Vector2(56.0, 42.0), Vector2(28.0, 34.0), 4.5, frame)
	_draw_line(image, Vector2i(54, 70), Vector2i(66, 116), frame, 4)
	_draw_line(image, Vector2i(52, 108), Vector2i(68, 124), palette["accent"], 5)
	for x in [40, 48, 56, 64, 72]:
		_draw_line(image, Vector2i(x, 16), Vector2i(x, 68), strings, 1)
	for y in [24, 36, 48, 60]:
		_draw_line(image, Vector2i(30, y), Vector2i(82, y), strings, 1)
	return image

func _make_aura_image(palette: Dictionary) -> Image:
	var image := Image.create(192, 192, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var accent: Color = palette["accent"]
	var center := Vector2(96.0, 96.0)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance := center.distance_to(Vector2(float(x), float(y)))
			var alpha := clampf(1.0 - distance / 78.0, 0.0, 1.0)
			if alpha <= 0.0:
				continue
			alpha = pow(alpha, 2.2) * 0.85
			image.set_pixel(x, y, Color(accent.r, accent.g, accent.b, alpha))
	return image

func _make_shadow_image(palette: Dictionary) -> Image:
	var image := Image.create(160, 72, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var shadow: Color = palette["shadow"]
	var center := Vector2(80.0, 36.0)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var normalized_x := (float(x) - center.x) / 58.0
			var normalized_y := (float(y) - center.y) / 22.0
			var distance := normalized_x * normalized_x + normalized_y * normalized_y
			if distance > 1.0:
				continue
			var alpha := (1.0 - distance) * shadow.a
			image.set_pixel(x, y, Color(shadow.r, shadow.g, shadow.b, alpha))
	return image

func _make_hit_flash_image() -> Image:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var center := Vector2(64.0, 64.0)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var point := Vector2(float(x), float(y))
			var radial := center.distance_to(point)
			var spoke := absf(sin((point.angle_to_point(center) + PI) * 4.0))
			var alpha := clampf(1.0 - radial / 54.0, 0.0, 1.0)
			alpha *= 0.4 + 0.6 * spoke
			if alpha > 0.02:
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return image

func _make_spin_burst_image() -> Image:
	var image := Image.create(192, 192, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var center := Vector2(96.0, 96.0)
	for i in range(3):
		var radius := 34.0 + float(i) * 18.0
		for angle_index in range(180):
			var angle := deg_to_rad(float(angle_index) * 2.0 + float(i) * 14.0)
			var point := center + Vector2(cos(angle), sin(angle)) * radius
			_draw_soft_dot(image, point, 4.5 + float(i), Color(0.56, 0.86, 1.0, 0.32 - float(i) * 0.06))
	return image

func _make_dust_image() -> Image:
	var image := Image.create(160, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	for center in [Vector2(44.0, 54.0), Vector2(78.0, 46.0), Vector2(116.0, 56.0)]:
		_draw_glow_circle(image, center, 28.0, Color(1.0, 0.94, 0.78, 0.4), 0.8)
	return image

func _draw_glow_circle(image: Image, center: Vector2, radius: float, color_value: Color, strength: float) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance := center.distance_to(Vector2(float(x), float(y)))
			var alpha := clampf(1.0 - distance / radius, 0.0, 1.0)
			if alpha <= 0.0:
				continue
			alpha = pow(alpha, 2.0) * color_value.a * strength
			var existing := image.get_pixel(x, y)
			image.set_pixel(x, y, existing.blend(Color(color_value.r, color_value.g, color_value.b, alpha)))

func _draw_soft_dot(image: Image, center: Vector2, radius: float, color_value: Color) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance := center.distance_to(Vector2(float(x), float(y)))
			var alpha := clampf(1.0 - distance / radius, 0.0, 1.0)
			if alpha <= 0.0:
				continue
			var existing := image.get_pixel(x, y)
			image.set_pixel(x, y, existing.blend(Color(color_value.r, color_value.g, color_value.b, alpha * color_value.a)))

func _draw_filled_rect(image: Image, rect: Rect2i, color_value: Color) -> void:
	var left := maxi(0, rect.position.x)
	var top := maxi(0, rect.position.y)
	var right := mini(image.get_width(), rect.position.x + rect.size.x)
	var bottom := mini(image.get_height(), rect.position.y + rect.size.y)
	for y in range(top, bottom):
		for x in range(left, right):
			image.set_pixel(x, y, color_value)

func _draw_filled_circle(image: Image, center: Vector2i, radius: int, color_value: Color) -> void:
	var radius_sq := radius * radius
	for y in range(center.y - radius, center.y + radius + 1):
		if y < 0 or y >= image.get_height():
			continue
		for x in range(center.x - radius, center.x + radius + 1):
			if x < 0 or x >= image.get_width():
				continue
			var dx := x - center.x
			var dy := y - center.y
			if dx * dx + dy * dy <= radius_sq:
				image.set_pixel(x, y, color_value)

func _draw_ellipse_outline(image: Image, center: Vector2, radii: Vector2, thickness: float, color_value: Color) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var normalized_x := (float(x) - center.x) / radii.x
			var normalized_y := (float(y) - center.y) / radii.y
			var distance := sqrt(normalized_x * normalized_x + normalized_y * normalized_y)
			if absf(distance - 1.0) <= thickness / maxf(radii.x, radii.y):
				image.set_pixel(x, y, color_value)

func _draw_line(image: Image, start: Vector2i, end: Vector2i, color_value: Color, thickness: int) -> void:
	var delta := end - start
	var steps := maxi(abs(delta.x), abs(delta.y))
	if steps <= 0:
		return
	for step in range(steps + 1):
		var t := float(step) / float(steps)
		var point := Vector2(start).lerp(Vector2(end), t)
		for offset_y in range(-thickness, thickness + 1):
			for offset_x in range(-thickness, thickness + 1):
				var px := int(round(point.x)) + offset_x
				var py := int(round(point.y)) + offset_y
				if px < 0 or px >= image.get_width() or py < 0 or py >= image.get_height():
					continue
				image.set_pixel(px, py, color_value)
