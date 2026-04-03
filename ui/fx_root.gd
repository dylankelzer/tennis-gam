class_name FXRoot
extends Node2D

const FXControllerScript = preload("res://scripts/ui/fx_controller.gd")
const SLASH_ARC_PATH := "res://assets/fx/slashes/slash_arc_blue.png"
const TRAIL_ARC_PATH := "res://assets/fx/slashes/slash_01.png"
const HIT_SPARK_PATH := "res://assets/fx/impacts/impact_orange.png"
const IMPACT_DUST_PATH := "res://assets/fx/impacts/impact_small.png"
const STATUS_PULSE_PATH := "res://assets/fx/status/buff_green.png"
const STATUS_PULSE_ALT_PATH := "res://assets/fx/status/debuff_purple.png"

var _theme: Dictionary = {}
var _controller = null

func _ready() -> void:
	_controller = FXControllerScript.new(self)

func apply_theme_palette(theme: Dictionary) -> void:
	_theme = theme.duplicate(true)

func clear_fx() -> void:
	if _controller != null:
		_controller.clear()

func play_attack_exchange(start_position: Vector2, end_position: Vector2, attacker_side: String, shot_family: String = "") -> void:
	var direction := end_position - start_position
	var distance := maxf(1.0, direction.length())
	var angle := direction.angle()
	var tint := _attack_tint(attacker_side, shot_family)
	_spawn_fx(SLASH_ARC_PATH, {
		"position": start_position.lerp(end_position, 0.56),
		"scale": Vector2(clampf(distance / 220.0, 0.52, 1.36), 0.66),
		"end_scale": Vector2(clampf(distance / 170.0, 0.70, 1.55), 0.92),
		"rotation": angle,
		"end_rotation": angle + deg_to_rad(18.0 if attacker_side == "player" else -18.0),
		"color": tint,
		"drift": direction.normalized() * 18.0,
		"duration": 0.16,
	})
	_spawn_fx(TRAIL_ARC_PATH, {
		"position": start_position.lerp(end_position, 0.42),
		"scale": Vector2(clampf(distance / 250.0, 0.46, 1.12), 0.44),
		"end_scale": Vector2(clampf(distance / 180.0, 0.58, 1.32), 0.72),
		"rotation": angle,
		"end_rotation": angle,
		"color": tint.lightened(0.12),
		"drift": direction.normalized() * 24.0,
		"duration": 0.22,
	})
	play_hit_impact(end_position, tint)

func play_hit_impact(world_position: Vector2, tint: Color = Color.WHITE) -> void:
	_spawn_fx(HIT_SPARK_PATH, {
		"position": world_position,
		"scale": Vector2(0.45, 0.45),
		"end_scale": Vector2(1.18, 1.18),
		"color": tint.lightened(0.18),
		"drift": Vector2(0.0, -12.0),
		"duration": 0.14,
	})
	_spawn_fx(IMPACT_DUST_PATH, {
		"position": world_position + Vector2(0.0, 22.0),
		"scale": Vector2(0.54, 0.38),
		"end_scale": Vector2(1.02, 0.72),
		"color": tint.darkened(0.10),
		"drift": Vector2(0.0, -10.0),
		"duration": 0.20,
	})

func play_status_pulse(world_position: Vector2, kind: String = "positive") -> void:
	var tint := _status_tint(kind)
	_spawn_fx(_status_path(kind), {
		"position": world_position,
		"scale": Vector2(0.34, 0.34),
		"end_scale": Vector2(1.10, 1.10),
		"color": tint,
		"duration": 0.24,
	})

func play_target_ping(world_position: Vector2, kind: String = "primary") -> void:
	var tint := _status_tint(kind)
	_spawn_fx(_status_path(kind), {
		"position": world_position,
		"scale": Vector2(0.22, 0.22),
		"end_scale": Vector2(0.78, 0.78),
		"color": tint,
		"duration": 0.18,
	})

func _spawn_fx(path: String, config: Dictionary) -> void:
	if _controller != null:
		_controller.spawn(path, config)

func _attack_tint(attacker_side: String, shot_family: String) -> Color:
	if shot_family.findn("slice") >= 0:
		return Color(_theme.get("overlay", Color(0.55, 0.34, 0.90)))
	if shot_family.findn("topspin") >= 0:
		return Color(_theme.get("positive", Color(0.54, 0.96, 0.48)))
	if attacker_side == "enemy":
		return Color(_theme.get("impact", Color(0.98, 0.56, 0.28)))
	return Color(_theme.get("primary", Color(0.36, 0.82, 1.0)))

func _status_tint(kind: String) -> Color:
	match kind:
		"positive", "buff":
			return Color(_theme.get("positive", Color(0.54, 0.96, 0.48)))
		"impact", "danger":
			return Color(_theme.get("impact", Color(0.98, 0.56, 0.28)))
		"overlay", "rare":
			return Color(_theme.get("overlay", Color(0.55, 0.34, 0.90)))
		_:
			return Color(_theme.get("primary", Color(0.36, 0.82, 1.0)))

func _status_path(kind: String) -> String:
	match kind:
		"overlay", "rare", "debuff", "negative":
			return STATUS_PULSE_ALT_PATH
		_:
			return STATUS_PULSE_PATH
