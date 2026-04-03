class_name CardDef
extends RefCounted

var id: StringName
var name: String = ""
var cost: int = 1
var description: String = ""
var tags: PackedStringArray = PackedStringArray()
var effects: Dictionary = {}
var upgrade_to: StringName = &""
var category: String = ""
var shot_family: String = ""
var slot_roles: PackedStringArray = PackedStringArray()
var requires: Dictionary = {}

func _init(
	card_id: StringName,
	card_name: String,
	card_cost: int,
	card_description: String,
	card_tags: PackedStringArray = PackedStringArray(),
	card_effects: Dictionary = {},
	card_upgrade_to: StringName = &"",
	card_category: String = "",
	card_shot_family: String = "",
	card_slot_roles: PackedStringArray = PackedStringArray(),
	card_requires: Dictionary = {}
) -> void:
	id = card_id
	name = card_name
	cost = card_cost
	description = card_description
	tags = card_tags
	effects = card_effects.duplicate(true)
	upgrade_to = card_upgrade_to
	category = card_category
	shot_family = card_shot_family
	slot_roles = card_slot_roles.duplicate()
	requires = card_requires.duplicate(true)
