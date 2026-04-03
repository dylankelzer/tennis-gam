class_name MatchEvent
extends RefCounted

var kind: String = ""
var side: String = ""
var point_number: int = 0
var turn_number: int = 0
var payload: Dictionary = {}

func _init(event_kind: String, event_payload: Dictionary = {}, event_side: String = "", point: int = 0, turn: int = 0) -> void:
	kind = event_kind
	side = event_side
	point_number = point
	turn_number = turn
	payload = event_payload.duplicate(true)

func to_dictionary() -> Dictionary:
	return {
		"kind": kind,
		"side": side,
		"point_number": point_number,
		"turn_number": turn_number,
		"payload": payload.duplicate(true),
	}
