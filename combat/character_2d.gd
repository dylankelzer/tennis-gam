extends Node2D
class_name CombatCharacter2D

const UnitDataScript = preload("res://scripts/data/unit_data.gd")
const AnimationDriverScript = preload("res://scripts/combat/animation_driver.gd")

const FLASH_SHADER_CODE := """
shader_type canvas_item;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	float mix_amount = flash_amount * tex.a;
	vec3 mixed_rgb = mix(tex.rgb, flash_color.rgb, mix_amount);
	COLOR = vec4(mixed_rgb, tex.a);
}
"""

static var _fallback_textures: Dictionary = {}

signal attack_started
signal attack_finished
signal hit_flash_played

@export var unit_data: Resource
@export var play_idle_on_ready: bool = true

@onready var idle_root: Node2D = $IdleRoot
@onready var attack_root: Node2D = $IdleRoot/AttackRoot
@onready var shadow_sprite: Sprite2D = $IdleRoot/AttackRoot/Shadow
@onready var aura_sprite: Sprite2D = $IdleRoot/AttackRoot/Aura
@onready var body_root: Node2D = $IdleRoot/AttackRoot/BodyRoot
@onready var body_sprite: Sprite2D = $IdleRoot/AttackRoot/BodyRoot/Body
@onready var racquet_pivot: Node2D = $IdleRoot/AttackRoot/BodyRoot/RacquetPivot
@onready var racquet_sprite: Sprite2D = $IdleRoot/AttackRoot/BodyRoot/RacquetPivot/Racquet

var _idle_time: float = 0.0
var _idle_active: bool = true
var _facing_sign: float = 1.0
var _attack_tween: Tween = null
var _flash_tween: Tween = null
var _flash_materials: Array[ShaderMaterial] = []
var _aura_rest_scale: Vector2 = Vector2.ONE
var _animation_driver := AnimationDriverScript.new()

func _ready() -> void:
	_ensure_data()
	_configure_flash_materials()
	_apply_unit_data()
	_idle_active = play_idle_on_ready and unit_data.idle_enabled
	set_process(true)

func _process(delta: float) -> void:
	_animation_driver.update_idle(self, delta)

func apply_unit_data(data: Resource) -> void:
	unit_data = data
	if is_inside_tree():
		_apply_unit_data()

func apply_data(data: Resource) -> void:
	apply_unit_data(data)

func set_facing_left(face_left: bool) -> void:
	_ensure_data()
	unit_data.face_left = face_left
	_facing_sign = -1.0 if face_left else 1.0
	_apply_root_scale()

func play_idle() -> void:
	_idle_active = true

func stop_idle() -> void:
	_idle_active = false
	idle_root.position = Vector2.ZERO

func play_attack() -> void:
	_animation_driver.play_attack(self)

func play_hit_flash() -> void:
	_animation_driver.play_hit_flash(self)

func is_attacking() -> bool:
	return _attack_tween != null and _attack_tween.is_running()

func _ensure_data() -> void:
	if unit_data == null:
		unit_data = UnitDataScript.new()

func _apply_unit_data() -> void:
	_ensure_data()
	_facing_sign = -1.0 if unit_data.face_left else 1.0
	_apply_root_scale()
	_apply_sprite(shadow_sprite, unit_data.shadow_texture, _get_fallback_texture(&"shadow"), unit_data.shadow_offset, unit_data.shadow_scale, unit_data.shadow_rotation_degrees, unit_data.shadow_modulate, unit_data.shadow_visible, -20)
	_apply_sprite(aura_sprite, unit_data.aura_texture, _get_fallback_texture(&"aura"), unit_data.aura_offset, unit_data.aura_scale, unit_data.aura_rotation_degrees, unit_data.aura_modulate, unit_data.aura_visible, -10)
	_apply_sprite(body_sprite, unit_data.body_texture, _get_fallback_texture(&"body"), unit_data.body_offset, unit_data.body_scale, unit_data.body_rotation_degrees, unit_data.body_modulate, unit_data.body_visible, 0)
	_apply_sprite(racquet_sprite, unit_data.racquet_texture, _get_fallback_texture(&"racquet"), Vector2.ZERO, unit_data.racquet_scale, unit_data.racquet_rotation_degrees, unit_data.racquet_modulate, unit_data.racquet_visible, 10)
	racquet_pivot.position = unit_data.racquet_offset
	_aura_rest_scale = unit_data.aura_scale
	_reset_attack_pose()

func _apply_root_scale() -> void:
	var scale_value := maxf(0.1, unit_data.root_scale)
	body_root.scale = Vector2(_facing_sign * scale_value, scale_value)
	attack_root.scale = Vector2.ONE

func _apply_sprite(sprite: Sprite2D, texture: Texture2D, fallback: Texture2D, offset: Vector2, sprite_scale: Vector2, rotation_degrees_value: float, tint: Color, visible_value: bool, z_index_value: int) -> void:
	sprite.texture = texture if texture != null else fallback
	sprite.position = offset
	sprite.scale = sprite_scale
	sprite.rotation_degrees = rotation_degrees_value
	sprite.modulate = tint
	sprite.visible = visible_value
	sprite.centered = true
	sprite.z_index = z_index_value

func _configure_flash_materials() -> void:
	_flash_materials.clear()
	for sprite in [body_sprite, racquet_sprite, aura_sprite]:
		var material := ShaderMaterial.new()
		material.shader = Shader.new()
		material.shader.code = FLASH_SHADER_CODE
		sprite.material = material
		_flash_materials.append(material)
	_set_flash_amount(0.0)

func _set_flash_amount(amount: float) -> void:
	if unit_data == null:
		return
	for material in _flash_materials:
		material.set_shader_parameter("flash_amount", clampf(amount, 0.0, 1.0))
		material.set_shader_parameter("flash_color", unit_data.hit_flash_color)

func _reset_attack_tween() -> void:
	if _attack_tween != null:
		_attack_tween.kill()
		_attack_tween = null

func _reset_attack_pose() -> void:
	idle_root.position = Vector2.ZERO
	attack_root.position = Vector2.ZERO
	body_root.rotation_degrees = 0.0
	racquet_pivot.rotation_degrees = 0.0
	aura_sprite.scale = _aura_rest_scale

func _finish_attack() -> void:
	_reset_attack_pose()
	_attack_tween = null
	attack_finished.emit()

func _finish_hit_flash() -> void:
	_flash_tween = null
	hit_flash_played.emit()

static func _get_fallback_texture(kind: StringName) -> Texture2D:
	if _fallback_textures.has(kind):
		return _fallback_textures[kind]
	var texture := _build_fallback_texture(kind)
	_fallback_textures[kind] = texture
	return texture

static func _build_fallback_texture(kind: StringName) -> Texture2D:
	match String(kind):
		"shadow":
			return _make_shadow_texture()
		"aura":
			return _make_aura_texture()
		"racquet":
			return _make_racquet_texture()
		_:
			return _make_body_texture()

static func _make_body_texture() -> Texture2D:
	var image := Image.create(96, 112, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var fill := Color.WHITE
	_draw_filled_circle(image, Vector2i(48, 18), 12, fill)
	_draw_filled_rect(image, Rect2i(38, 30, 20, 32), fill)
	_draw_filled_circle(image, Vector2i(48, 48), 16, fill)
	_draw_filled_rect(image, Rect2i(28, 34, 10, 28), fill)
	_draw_filled_rect(image, Rect2i(58, 34, 10, 28), fill)
	_draw_filled_rect(image, Rect2i(40, 62, 8, 34), fill)
	_draw_filled_rect(image, Rect2i(48, 62, 8, 34), fill)
	_draw_filled_rect(image, Rect2i(36, 94, 12, 8), fill)
	_draw_filled_rect(image, Rect2i(48, 94, 12, 8), fill)
	return ImageTexture.create_from_image(image)

static func _make_racquet_texture() -> Texture2D:
	var image := Image.create(88, 88, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var fill := Color.WHITE
	_draw_ellipse_outline(image, Vector2(42.0, 28.0), Vector2(18.0, 24.0), 3.5, fill)
	_draw_filled_rect(image, Rect2i(39, 46, 6, 24), fill)
	_draw_filled_rect(image, Rect2i(36, 66, 12, 12), fill)
	for x in [34, 42, 50]:
		_draw_line(image, Vector2i(x, 8), Vector2i(x, 48), Color(1.0, 1.0, 1.0, 0.65), 1)
	for y in [14, 24, 34, 44]:
		_draw_line(image, Vector2i(24, y), Vector2i(60, y), Color(1.0, 1.0, 1.0, 0.65), 1)
	return ImageTexture.create_from_image(image)

static func _make_aura_texture() -> Texture2D:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var center := Vector2(64.0, 64.0)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var distance := center.distance_to(Vector2(float(x), float(y)))
			var alpha := clampf(1.0 - distance / 54.0, 0.0, 1.0)
			alpha = alpha * alpha * 0.8
			if alpha <= 0.0:
				continue
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)

static func _make_shadow_texture() -> Texture2D:
	var image := Image.create(120, 56, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var center := Vector2(60.0, 28.0)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var normalized_x := (float(x) - center.x) / 44.0
			var normalized_y := (float(y) - center.y) / 16.0
			var distance := normalized_x * normalized_x + normalized_y * normalized_y
			if distance > 1.0:
				continue
			var alpha := (1.0 - distance) * 0.9
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)

static func _draw_filled_rect(image: Image, rect: Rect2i, color_value: Color) -> void:
	var left := maxi(0, rect.position.x)
	var top := maxi(0, rect.position.y)
	var right := mini(image.get_width(), rect.position.x + rect.size.x)
	var bottom := mini(image.get_height(), rect.position.y + rect.size.y)
	for y in range(top, bottom):
		for x in range(left, right):
			image.set_pixel(x, y, color_value)

static func _draw_filled_circle(image: Image, center: Vector2i, radius: int, color_value: Color) -> void:
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

static func _draw_ellipse_outline(image: Image, center: Vector2, radii: Vector2, thickness: float, color_value: Color) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var normalized_x := (float(x) - center.x) / radii.x
			var normalized_y := (float(y) - center.y) / radii.y
			var distance := sqrt(normalized_x * normalized_x + normalized_y * normalized_y)
			if absf(distance - 1.0) <= thickness / maxf(radii.x, radii.y):
				image.set_pixel(x, y, color_value)

static func _draw_line(image: Image, start: Vector2i, end: Vector2i, color_value: Color, thickness: int) -> void:
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
