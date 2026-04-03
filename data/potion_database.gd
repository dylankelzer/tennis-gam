class_name PotionDatabase
extends RefCounted

const PotionDefScript = preload("res://scripts/core/potion_def.gd")

var _potions: Dictionary = {}

func _init() -> void:
	_register_potions()

func get_potion(potion_id: StringName):
	return _potions.get(potion_id)

func get_all_potions() -> Array:
	var potions: Array = []
	for potion in _potions.values():
		potions.append(potion)
	potions.sort_custom(func(a, b) -> bool:
		return a.name < b.name
	)
	return potions

func get_shop_pool() -> Array:
	return get_all_potions()

func _add_potion(potion) -> void:
	_potions[potion.id] = potion

func _register_potions() -> void:
	_add_potion(PotionDefScript.new(
		&"stamina_gel",
		"Stamina Gel",
		"common",
		14,
		"Gain 2 Stamina immediately and queue 1 Stamina for next turn. Best saved for long boss exchanges.",
		{"stamina_now": 2, "next_turn_stamina": 1},
		"momentum",
		"Bench Cooler"
	))
	_add_potion(PotionDefScript.new(
		&"spin_serum",
		"Spin Serum",
		"uncommon",
		18,
		"This turn, topspin and slice shots hit heavier and apply extra Spin.",
		{"turn_extra_spin": 2, "turn_topspin_pressure_bonus": 4, "turn_slice_pressure_bonus": 4},
		"spin",
		"RPM Lab"
	))
	_add_potion(PotionDefScript.new(
		&"focus_salts",
		"Focus Salts",
		"uncommon",
		17,
		"Gain Focus 3, Momentum 1, and a cleaner contact window this turn.",
		{"focus": 3, "momentum": 1, "turn_accuracy_bonus": 0.05},
		"focus",
		"Locker Tonic"
	))
	_add_potion(PotionDefScript.new(
		&"clutch_draught",
		"Clutch Draught",
		"rare",
		24,
		"Gain 8 Guard, shed 2 Fatigue, and juice the next Power or Signature strike.",
		{"guard": 8, "fatigue_heal": 2, "turn_power_pressure_bonus": 5, "turn_signature_pressure_bonus": 5},
		"pressure",
		"Boss Reserve"
	))
