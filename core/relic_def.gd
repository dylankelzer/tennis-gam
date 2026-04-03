class_name RelicDef
extends RefCounted

var id: StringName
var name: String = ""
var rarity: String = "common"
var description: String = ""
var effects: Dictionary = {}

func _init(
	relic_id: StringName,
	relic_name: String,
	relic_rarity: String,
	relic_description: String,
	relic_effects: Dictionary = {}
) -> void:
	id = relic_id
	name = relic_name
	rarity = relic_rarity
	description = relic_description
	effects = relic_effects.duplicate(true)
