class_name FXLayer
extends Node2D

const HIT_FLASH_PATH := "res://assets/fx/hit_flash.png"
const SPIN_BURST_PATH := "res://assets/fx/spin_burst.png"
const DUST_PATH := "res://assets/fx/dust.png"

var _texture_cache: Dictionary = {}

func play_hit_flash_effect(world_position: Vector2, tint: Color = Color(1.0, 1.0, 1.0, 0.92)) -> void:
	_spawn_fx(_load_texture(HIT_FLASH_PATH), world_position, Vector2(0.45, 0.45), Vector2(1.25, 1.25), tint, 0.16)

func play_spin_burst(world_position: Vector2, tint: Color = Color(0.56, 0.84, 1.0, 0.88)) -> void:
	_spawn_fx(_load_texture(SPIN_BURST_PATH), world_position, Vector2(0.55, 0.55), Vector2(1.15, 1.15), tint, 0.28, 180.0)

func play_dust(world_position: Vector2, tint: Color = Color(1.0, 0.96, 0.82, 0.72)) -> void:
	_spawn_fx(_load_texture(DUST_PATH), world_position, Vector2(0.5, 0.35), Vector2(1.0, 0.72), tint, 0.24)

func _spawn_fx(texture: Texture2D, world_position: Vector2, start_scale: Vector2, end_scale: Vector2, tint: Color, duration: float, end_rotation_degrees: float = 0.0) -> void:
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = to_local(world_position)
	sprite.scale = start_scale
	sprite.modulate = tint
	sprite.centered = true
	add_child(sprite)

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.parallel().tween_property(sprite, "scale", end_scale, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "rotation_degrees", end_rotation_degrees, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "position", sprite.position + Vector2(0.0, -10.0), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(sprite.queue_free)

func _load_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	if texture == null:
		var absolute_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(absolute_path):
			var image := Image.load_from_file(absolute_path)
			if image != null and not image.is_empty():
				texture = ImageTexture.create_from_image(image)
	_texture_cache[path] = texture
	return texture
