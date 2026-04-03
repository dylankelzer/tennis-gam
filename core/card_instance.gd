class_name CardInstance
extends RefCounted

var uid: int = 0
var card_id: StringName = &""
var retained: bool = false

func _init(instance_uid: int, instance_card_id: StringName) -> void:
	uid = instance_uid
	card_id = instance_card_id
