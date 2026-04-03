extends Node2D
class_name CombatScene

const UnitDatabaseScript = preload("res://scripts/data/unit_database.gd")

@export var player_unit_id: String = "novice"
@export var enemy_unit_id: String = "grinder"
@export var autoplay_demo: bool = false

@onready var player_character = $PlayerCharacter
@onready var enemy_character = $EnemyCharacter
@onready var fx_layer = $FXLayer
@onready var demo_label: Label = $HUD/PromptLabel

var _database = UnitDatabaseScript.new()
var _auto_demo_started: bool = false

func _ready() -> void:
	setup_by_id(player_unit_id, enemy_unit_id)
	queue_redraw()
	if autoplay_demo:
		call_deferred("_play_demo_exchange")

func setup_by_id(player_id: String, enemy_id: String) -> void:
	setup_units(_database.get_unit(player_id), _database.get_unit(enemy_id))

func setup_units(player_data, enemy_data) -> void:
	player_character.position = Vector2(260.0, 440.0)
	enemy_character.position = Vector2(860.0, 300.0)
	player_character.apply_unit_data(player_data)
	enemy_character.apply_unit_data(enemy_data)
	demo_label.text = "Space: player swing  |  E: enemy swing  |  H: both hit flash"

func play_exchange(attacker_is_player: bool = true) -> void:
	var attacker = player_character if attacker_is_player else enemy_character
	var defender = enemy_character if attacker_is_player else player_character
	attacker.play_attack()
	defender.play_hit_flash()
	fx_layer.play_spin_burst(defender.global_position + Vector2(0.0, -84.0), _spin_tint(attacker_is_player))
	fx_layer.play_hit_flash_effect(defender.global_position + Vector2(0.0, -56.0), Color(1.0, 1.0, 1.0, 0.92))
	fx_layer.play_dust(attacker.global_position + Vector2(0.0, 24.0), Color(0.98, 0.92, 0.78, 0.7))

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return
	var court_rect := Rect2(80.0, 120.0, viewport_size.x - 160.0, viewport_size.y - 210.0)
	draw_rect(court_rect, Color(0.08, 0.20, 0.33, 1.0), true)
	draw_rect(court_rect.grow(14.0), Color(0.03, 0.10, 0.18, 0.45), false, 18.0)
	var service_y := court_rect.position.y + court_rect.size.y * 0.44
	var baseline_y := court_rect.position.y + court_rect.size.y * 0.80
	var inner_margin := court_rect.size.x * 0.16
	draw_line(Vector2(court_rect.position.x, service_y), Vector2(court_rect.end.x, service_y), Color(0.95, 0.97, 1.0), 4.0)
	draw_line(Vector2(court_rect.position.x + inner_margin, court_rect.position.y), Vector2(court_rect.position.x + inner_margin, court_rect.end.y), Color(0.95, 0.97, 1.0), 4.0)
	draw_line(Vector2(court_rect.end.x - inner_margin, court_rect.position.y), Vector2(court_rect.end.x - inner_margin, court_rect.end.y), Color(0.95, 0.97, 1.0), 4.0)
	draw_line(Vector2(court_rect.position.x + court_rect.size.x * 0.5, service_y), Vector2(court_rect.position.x + court_rect.size.x * 0.5, court_rect.end.y), Color(0.95, 0.97, 1.0), 4.0)
	draw_line(Vector2(court_rect.position.x, baseline_y), Vector2(court_rect.end.x, baseline_y), Color(0.95, 0.97, 1.0), 6.0)
	draw_line(Vector2(court_rect.position.x, court_rect.position.y + court_rect.size.y * 0.62), Vector2(court_rect.end.x, court_rect.position.y + court_rect.size.y * 0.62), Color(0.94, 0.97, 1.0), 7.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				play_exchange(true)
			KEY_E:
				play_exchange(false)
			KEY_H:
				player_character.play_hit_flash()
				enemy_character.play_hit_flash()
				fx_layer.play_hit_flash_effect(player_character.global_position + Vector2(0.0, -52.0))
				fx_layer.play_hit_flash_effect(enemy_character.global_position + Vector2(0.0, -52.0))

func _play_demo_exchange() -> void:
	if _auto_demo_started:
		return
	_auto_demo_started = true
	play_exchange(true)

func _spin_tint(attacker_is_player: bool) -> Color:
	return Color(0.54, 0.84, 1.0, 0.86) if attacker_is_player else Color(0.74, 0.92, 0.44, 0.84)
