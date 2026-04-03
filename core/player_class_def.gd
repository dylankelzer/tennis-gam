class_name PlayerClassDef
extends RefCounted

var id: StringName
var name: String = ""
var unlock_rank: int = 0
var archetype: String = ""
var summary: String = ""
var passive_name: String = ""
var passive_description: String = ""
var base_stats: Dictionary = {}
var signature_shots: PackedStringArray = PackedStringArray()
var starting_deck: PackedStringArray = PackedStringArray()

func _init(
	class_id: StringName,
	player_class_name: String,
	class_unlock_rank: int,
	class_archetype: String,
	class_summary: String,
	class_passive_name: String,
	class_passive_description: String,
	class_base_stats: Dictionary,
	class_signature_shots: PackedStringArray,
	class_starting_deck: PackedStringArray
) -> void:
	id = class_id
	name = player_class_name
	unlock_rank = class_unlock_rank
	archetype = class_archetype
	summary = class_summary
	passive_name = class_passive_name
	passive_description = class_passive_description
	base_stats = class_base_stats.duplicate(true)
	signature_shots = class_signature_shots
	starting_deck = class_starting_deck
