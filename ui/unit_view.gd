class_name UnitView
extends Node2D

@onready var character = $Character

var _theme: Dictionary = {}
var _unit_anchor: Vector2 = Vector2.ZERO
var _is_targeted: bool = false
var _target_strength: float = 0.0
var _activation_strength: float = 0.0
var _status_strength: float = 0.0
var _status_color: Color = Color.WHITE
var _rest_scale: Vector2 = Vector2.ONE

var _target_tween: Tween = null
var _activation_tween: Tween = null
var _status_tween: Tween = null
var _hit_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_unit_anchor = position
	queue_redraw()

func apply_unit_data(data: Resource, theme: Dictionary = {}, targeted: bool = false) -> void:
	_theme = theme.duplicate(true)
	_is_targeted = targeted
	if character != null and character.has_method("apply_unit_data"):
		character.apply_unit_data(data)
	_rest_scale = scale
	queue_redraw()

func set_anchor_position(anchor: Vector2) -> void:
	_unit_anchor = anchor
	position = anchor

func set_theme(theme: Dictionary) -> void:
	_theme = theme.duplicate(true)
	queue_redraw()

func set_targeted(active: bool) -> void:
	_is_targeted = active
	if active:
		_tween_target_strength(1.0, 0.14)
	else:
		_tween_target_strength(0.0, 0.18)

func pulse_activation() -> void:
	if _activation_tween != null:
		_activation_tween.kill()
	_activation_strength = 0.0
	_activation_tween = create_tween()
	_activation_tween.tween_method(_set_activation_strength, 0.0, 1.0, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_activation_tween.tween_method(_set_activation_strength, 1.0, 0.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_activation_tween.finished.connect(func() -> void:
		_activation_tween = null
	)

func play_attack() -> void:
	pulse_activation()
	if character != null and character.has_method("play_attack"):
		character.play_attack()

func play_hit_reaction(direction_sign: float) -> void:
	if character != null and character.has_method("play_hit_flash"):
		character.play_hit_flash()
	if _hit_tween != null:
		_hit_tween.kill()
	if character == null:
		return
	var attack_root = character.attack_root
	if attack_root == null:
		return
	attack_root.scale = Vector2.ONE
	var knockback := Vector2(10.0 * direction_sign, -5.0)
	_hit_tween = create_tween()
	_hit_tween.parallel().tween_property(attack_root, "position", knockback, 0.07).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hit_tween.parallel().tween_property(attack_root, "scale", Vector2(0.94, 1.10), 0.07).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hit_tween.chain()
	_hit_tween.parallel().tween_property(attack_root, "position", Vector2.ZERO, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hit_tween.parallel().tween_property(attack_root, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hit_tween.finished.connect(func() -> void:
		_hit_tween = null
	)

func pulse_status(color_value: Color) -> void:
	_status_color = color_value
	if _status_tween != null:
		_status_tween.kill()
	_status_strength = 0.0
	_status_tween = create_tween()
	_status_tween.tween_method(_set_status_strength, 0.0, 1.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_status_tween.tween_method(_set_status_strength, 1.0, 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_status_tween.finished.connect(func() -> void:
		_status_tween = null
	)

func clear_feedback() -> void:
	set_targeted(false)
	_set_activation_strength(0.0)
	_set_status_strength(0.0)

func _draw() -> void:
	var accent := Color(_theme.get("accent", Color(0.68, 0.86, 1.0)))
	var overlay := Color(_theme.get("overlay", Color(0.55, 0.34, 0.90)))
	var shadow := Color(_theme.get("shadow", Color(0.03, 0.04, 0.08, 0.82)))
	var base_center := Vector2(0.0, 30.0)
	if _activation_strength > 0.001:
		var aura := accent.lightened(0.08)
		aura.a = 0.18 * _activation_strength
		draw_circle(base_center + Vector2(0.0, -72.0), 52.0 + 10.0 * _activation_strength, aura)
	if _is_targeted or _target_strength > 0.001:
		var ring := accent if _is_targeted else overlay
		ring.a = 0.62 * maxf(_target_strength, 0.12)
		draw_arc(base_center, 42.0 + 4.0 * _target_strength, 0.0, TAU, 28, ring, 3.0, true)
		draw_arc(base_center, 30.0 + 2.0 * _target_strength, 0.0, TAU, 28, ring.lightened(0.12), 1.4, true)
	if _status_strength > 0.001:
		var pulse := _status_color
		pulse.a = 0.44 * _status_strength
		draw_circle(base_center + Vector2(0.0, -56.0), 28.0 + 16.0 * _status_strength, pulse)
	var floor_shadow := shadow
	floor_shadow.a = 0.18
	draw_ellipse_outline(base_center, Vector2(46.0, 16.0), floor_shadow, 1.4)

func draw_ellipse_outline(center: Vector2, radii: Vector2, color_value: Color, width: float) -> void:
	var points := PackedVector2Array()
	for index in range(33):
		var angle := TAU * float(index) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_polyline(points, color_value, width, true)

func _tween_target_strength(target: float, duration: float) -> void:
	if _target_tween != null:
		_target_tween.kill()
	_target_tween = create_tween()
	_target_tween.tween_method(_set_target_strength, _target_strength, target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_target_tween.finished.connect(func() -> void:
		_target_tween = null
	)

func _set_target_strength(value: float) -> void:
	_target_strength = value
	queue_redraw()

func _set_activation_strength(value: float) -> void:
	_activation_strength = value
	queue_redraw()

func _set_status_strength(value: float) -> void:
	_status_strength = value
	queue_redraw()
