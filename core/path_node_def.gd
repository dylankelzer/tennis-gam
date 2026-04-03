class_name PathNodeDef
extends RefCounted

var id: int = -1
var floor: int = 0
var lane: int = 0
var node_type: String = "regular"
var encounter_id: StringName = &""
var next_node_ids: PackedInt32Array = PackedInt32Array()

func _init(node_id: int, node_floor: int, node_lane: int, type_name: String, assigned_encounter_id: StringName = &"") -> void:
	id = node_id
	floor = node_floor
	lane = node_lane
	node_type = type_name
	encounter_id = assigned_encounter_id
