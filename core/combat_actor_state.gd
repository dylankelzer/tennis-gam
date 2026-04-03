class_name CombatActorState
extends RefCounted

var display_name: String = ""
var max_condition: int = 0
var current_condition: int = 0
var max_stamina: int = 0
var current_stamina: int = 0
var guard: int = 0
var stats: Dictionary = {}
var statuses: Dictionary = {
	"pressure": 0,
	"spin": 0,
	"fatigue": 0,
	"open_court": 0,
	"momentum": 0,
	"focus": 0,
	"retain_bonus": 0,
	"next_turn_stamina": 0,
	"next_turn_momentum": 0,
	"endurance_scaling": 0,
	"thorns": 0,
	# Persistent disruption debuffs — decay between points (like fatigue)
	# tilt: accuracy penalty (tilt × 5%) from disorienting shots / rhythm breaks
	"tilt": 0,
	# cost_up: each card costs +1 extra Stamina per stack — stamina tax from court domination
	"cost_up": 0,
	# position_lock: cleared per point-start; blocks court-geometry and position-based bonuses
	"position_lock": 0,
}

func _init(actor_name: String, actor_max_condition: int, actor_current_condition: int, actor_max_stamina: int, actor_stats: Dictionary = {}) -> void:
	display_name = actor_name
	max_condition = actor_max_condition
	current_condition = clampi(actor_current_condition, 0, max_condition)
	max_stamina = maxi(0, actor_max_stamina)
	current_stamina = max_stamina
	stats = actor_stats.duplicate(true)

func get_status(status_name: String) -> int:
	return int(statuses.get(status_name, 0))

func set_status(status_name: String, value: int) -> void:
	statuses[status_name] = maxi(0, value)

func add_status(status_name: String, value: int) -> void:
	set_status(status_name, get_status(status_name) + value)

func consume_status(status_name: String) -> int:
	var value := get_status(status_name)
	set_status(status_name, 0)
	return value

func restore_condition(amount: int) -> int:
	var previous := current_condition
	current_condition = mini(max_condition, current_condition + maxi(0, amount))
	return current_condition - previous

func lose_condition(amount: int) -> int:
	var previous := current_condition
	current_condition = maxi(0, current_condition - maxi(0, amount))
	return previous - current_condition

func take_pressure(amount: int) -> int:
	var incoming := maxi(0, amount)
	var absorbed := mini(guard, incoming)
	guard -= absorbed
	var dealt := incoming - absorbed
	return dealt

func is_alive() -> bool:
	return current_condition > 0

func refill_stamina() -> void:
	current_stamina = maxi(0, max_stamina - get_status("fatigue"))
