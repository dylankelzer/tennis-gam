class_name AnimationDriver
extends RefCounted

func update_idle(character, delta: float) -> void:
	if character.unit_data == null:
		return
	if not character._idle_active or character.is_attacking() or not character.unit_data.idle_enabled:
		character.idle_root.position = Vector2.ZERO
		return
	character._idle_time += delta * character.unit_data.idle_bob_speed
	character.idle_root.position = Vector2(0.0, sin(character._idle_time) * character.unit_data.idle_bob_distance)

func play_attack(character) -> void:
	character._ensure_data()
	character._reset_attack_tween()
	character._reset_attack_pose()
	character.attack_started.emit()

	var duration: float = maxf(0.12, character.unit_data.attack_duration)
	var windup: float = duration * 0.25
	var strike: float = duration * 0.35
	var recover: float = maxf(0.06, duration - windup - strike)
	var sign: float = character._facing_sign

	character._attack_tween = character.create_tween()
	character._attack_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	character._attack_tween.parallel().tween_property(character.attack_root, "position", Vector2(-sign * character.unit_data.attack_lunge_distance * 0.12, 0.0), windup).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	character._attack_tween.parallel().tween_property(character.body_root, "rotation_degrees", -6.0 * sign, windup).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	character._attack_tween.parallel().tween_property(character.racquet_pivot, "rotation_degrees", -character.unit_data.attack_swing_degrees * 0.46 * sign, windup).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	character._attack_tween.parallel().tween_property(character.aura_sprite, "scale", character._aura_rest_scale * 1.08, windup).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	character._attack_tween.chain()
	character._attack_tween.parallel().tween_property(character.attack_root, "position", Vector2(sign * character.unit_data.attack_lunge_distance, character.unit_data.attack_lunge_height), strike).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	character._attack_tween.parallel().tween_property(character.body_root, "rotation_degrees", 7.0 * sign, strike).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	character._attack_tween.parallel().tween_property(character.racquet_pivot, "rotation_degrees", character.unit_data.attack_swing_degrees * sign, strike).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	character._attack_tween.parallel().tween_property(character.aura_sprite, "scale", character._aura_rest_scale * 1.18, strike).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	character._attack_tween.chain()
	character._attack_tween.parallel().tween_property(character.attack_root, "position", Vector2.ZERO, recover).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	character._attack_tween.parallel().tween_property(character.body_root, "rotation_degrees", 0.0, recover).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	character._attack_tween.parallel().tween_property(character.racquet_pivot, "rotation_degrees", 0.0, recover).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	character._attack_tween.parallel().tween_property(character.aura_sprite, "scale", character._aura_rest_scale, recover).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	character._attack_tween.finished.connect(character._finish_attack)

func play_hit_flash(character) -> void:
	character._ensure_data()
	if character._flash_tween != null:
		character._flash_tween.kill()
	character._set_flash_amount(character.unit_data.hit_flash_strength)
	character._flash_tween = character.create_tween()
	character._flash_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	character._flash_tween.tween_method(character._set_flash_amount, character.unit_data.hit_flash_strength, 0.0, character.unit_data.hit_flash_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	character._flash_tween.finished.connect(character._finish_hit_flash)
