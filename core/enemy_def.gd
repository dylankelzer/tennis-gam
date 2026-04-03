class_name EnemyDef
extends RefCounted

var id: StringName
var name: String = ""
var act: int = 1
var category: String = "regular"
var style: String = ""
var summary: String = ""
var max_health: int = 0
var intent_cycle: Array[Dictionary] = []
var keywords: PackedStringArray = PackedStringArray()

func _init(
	enemy_id: StringName,
	enemy_name: String,
	enemy_act: int,
	enemy_category: String,
	enemy_style: String,
	enemy_summary: String,
	enemy_max_health: int,
	enemy_intent_cycle: Array[Dictionary],
	enemy_keywords: PackedStringArray = PackedStringArray()
) -> void:
	id = enemy_id
	name = enemy_name
	act = enemy_act
	category = enemy_category
	style = enemy_style
	summary = enemy_summary
	max_health = enemy_max_health
	intent_cycle = enemy_intent_cycle.duplicate(true)
	keywords = enemy_keywords
