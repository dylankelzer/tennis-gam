class_name FXSpriteEffect
extends Node2D

@onready var sprite: Sprite2D = $Sprite

func play(texture: Texture2D, config: Dictionary = {}) -> void:
	if sprite == null:
		return
	sprite.texture = texture
	sprite.centered = true
	position = Vector2(config.get("position", Vector2.ZERO))
	sprite.scale = Vector2(config.get("scale", Vector2.ONE))
	sprite.modulate = Color(config.get("color", Color.WHITE))
	sprite.rotation = float(config.get("rotation", 0.0))
	var drift := Vector2(config.get("drift", Vector2.ZERO))
	var end_scale := Vector2(config.get("end_scale", sprite.scale))
	var end_rotation := float(config.get("end_rotation", sprite.rotation))
	var duration := maxf(0.05, float(config.get("duration", 0.18)))
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.parallel().tween_property(sprite, "scale", end_scale, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "rotation", end_rotation, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position", position + drift, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(queue_free)
