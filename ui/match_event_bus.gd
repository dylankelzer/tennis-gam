class_name MatchEventBus
extends Node

signal point_started(context: Dictionary)
signal card_played(actor: String, card_id: String, delta: Dictionary)
signal rally_updated(snapshot: Dictionary)
signal point_ended(winner: String, score_snapshot: Dictionary, condition_delta: Dictionary)
signal raw_event(event: Dictionary)

var _bound_match = null
var _match_listener: Callable = Callable()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

func bind_match(match_state) -> void:
	if _bound_match == match_state:
		return
	_unbind_current_match()
	_bound_match = match_state
	if _bound_match == null:
		return
	if _match_listener.is_null():
		_match_listener = Callable(self, "_on_match_event")
	if _bound_match.has_method("add_event_listener"):
		_bound_match.add_event_listener(_match_listener)
	rally_updated.emit(_build_rally_snapshot())
	point_started.emit(_build_point_context_snapshot())

func clear_match() -> void:
	_unbind_current_match()

func _exit_tree() -> void:
	_unbind_current_match()

func _unbind_current_match() -> void:
	if _bound_match != null and _match_listener.is_valid() and _bound_match.has_method("remove_event_listener"):
		_bound_match.remove_event_listener(_match_listener)
	_bound_match = null

func _on_match_event(event: Dictionary) -> void:
	raw_event.emit(event.duplicate(true))
	var kind := String(event.get("kind", ""))
	var payload := Dictionary(event.get("payload", {}))
	match kind:
		"point_started":
			point_started.emit(_build_point_context_snapshot(payload))
			rally_updated.emit(_build_rally_snapshot())
		"card_played":
			card_played.emit(String(event.get("side", "")), String(payload.get("card_id", "")), payload.duplicate(true))
			rally_updated.emit(_build_rally_snapshot())
		"pressure_shifted", "turn_started", "potion_used", "match_initialized", "game_won":
			rally_updated.emit(_build_rally_snapshot())
		"point_resolved":
			point_ended.emit(
				String(payload.get("winner", "")),
				_build_score_snapshot(payload),
				Dictionary(payload.get("condition_delta", {})).duplicate(true)
			)
			rally_updated.emit(_build_rally_snapshot())
		"match_resolved":
			point_ended.emit(
				String(payload.get("winner", "")),
				_build_score_snapshot(payload),
				Dictionary(payload.get("condition_delta", {})).duplicate(true)
			)
			rally_updated.emit(_build_rally_snapshot())
		_:
			pass

func _build_rally_snapshot() -> Dictionary:
	if _bound_match == null or not _bound_match.has_method("get_battle_presentation"):
		return {}
	return Dictionary(_bound_match.get_battle_presentation()).duplicate(true)

func _build_point_context_snapshot(payload: Dictionary = {}) -> Dictionary:
	var snapshot := _build_rally_snapshot()
	if snapshot.is_empty():
		return payload.duplicate(true)
	snapshot["point_number"] = int(payload.get("point_number", snapshot.get("point_number", 0)))
	snapshot["turn_number"] = int(payload.get("turn_number", snapshot.get("turn_number", 0)))
	return snapshot

func _build_score_snapshot(payload: Dictionary = {}) -> Dictionary:
	var snapshot := _build_rally_snapshot()
	if snapshot.is_empty():
		return {
			"score_player": String(payload.get("score_player", "")),
			"score_enemy": String(payload.get("score_enemy", "")),
			"score_status": String(payload.get("score_status", "")),
			"games_player": int(payload.get("games_player", 0)),
			"games_enemy": int(payload.get("games_enemy", 0)),
		}
	return {
		"score_player": String(payload.get("score_player", snapshot.get("score_player", ""))),
		"score_enemy": String(payload.get("score_enemy", snapshot.get("score_enemy", ""))),
		"score_status": String(payload.get("score_status", snapshot.get("score_status", ""))),
		"games_player": int(payload.get("games_player", snapshot.get("games_player", 0))),
		"games_enemy": int(payload.get("games_enemy", snapshot.get("games_enemy", 0))),
		"point_number": int(snapshot.get("point_number", 0)),
		"server": String(snapshot.get("server", "")),
	}
