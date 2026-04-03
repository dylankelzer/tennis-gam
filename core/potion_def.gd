class_name PotionDef
extends RefCounted

var id: StringName
var name: String = ""
var rarity: String = "common"
var price_btc: int = 0
var description: String = ""
var effects: Dictionary = {}
var icon_kind: String = "focus"
var art_label: String = "Tour Potion"

func _init(
	potion_id: StringName,
	potion_name: String,
	potion_rarity: String,
	potion_price_btc: int,
	potion_description: String,
	potion_effects: Dictionary = {},
	potion_icon_kind: String = "focus",
	potion_art_label: String = "Tour Potion"
) -> void:
	id = potion_id
	name = potion_name
	rarity = potion_rarity
	price_btc = potion_price_btc
	description = potion_description
	effects = potion_effects.duplicate(true)
	icon_kind = potion_icon_kind
	art_label = potion_art_label
