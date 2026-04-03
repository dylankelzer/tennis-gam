class_name PlayerCardLogicTree
extends RefCounted

const CardDatabaseScript = preload("res://scripts/data/card_database.gd")

var _card_database = CardDatabaseScript.new()

func analyze_turn(active_match) -> Dictionary:
	if active_match == null:
		return {
			"headline": "No active match.",
			"recommended_card_name": "",
			"recommended_slot": "",
			"recommended_hand_index": -1,
			"recommended_reason": "",
			"tree": _action_leaf("No match is active."),
			"tree_lines": PackedStringArray(["No active match."]),
		}

	var candidates := _collect_candidates(active_match)
	var point_context := _point_context(active_match)
	var checks := {
		"is_player_turn": String(active_match.state) == "player_turn",
		"is_opening_contact": point_context in ["serve", "return"],
		"is_serve_window": point_context == "serve",
		"is_return_window": point_context == "return",
		"closeout_window": _is_closeout_window(active_match),
		"needs_stabilize": _needs_stabilize(active_match),
		"enemy_at_net": String(active_match.rally_state.enemy_position) in ["ServiceLine", "Net"],
		"ball_sits_high": String(active_match.rally_state.ball_state) == "HighBall",
		"court_is_open": int(active_match.enemy.get_status("open_court")) > 0 or String(active_match.rally_state.last_shot_lane) == "Crosscourt",
		"player_is_forward": String(active_match.rally_state.player_position) in ["ServiceLine", "Net"],
		"safe_to_equip": _safe_to_equip(active_match),
	}
	var recommendation := _recommend_card(active_match, candidates, checks)
	var tree := _build_tree(checks, recommendation)
	var headline := _build_headline(checks, recommendation)
	var tree_lines := PackedStringArray()
	_flatten_tree(tree, 0, tree_lines)
	return {
		"headline": headline,
		"recommended_card_name": String(recommendation.get("name", "")),
		"recommended_slot": String(recommendation.get("slot_id", "")),
		"recommended_hand_index": int(recommendation.get("hand_index", -1)),
		"recommended_reason": String(recommendation.get("reason", "")),
		"tree": tree,
		"tree_lines": tree_lines,
	}

func choose_best_playable_card_index(active_match) -> int:
	return int(analyze_turn(active_match).get("recommended_hand_index", -1))

func _collect_candidates(active_match) -> Array:
	var output: Array = []
	var hand_display: Array = active_match.get_hand_slot_display()
	for entry in hand_display:
		var view := Dictionary(entry)
		var hand_index := int(view.get("hand_index", -1))
		if hand_index < 0 or hand_index >= active_match.hand.size():
			continue
		if not bool(view.get("playable", false)):
			continue
		var instance = active_match.hand[hand_index]
		var card_def = _card_database.get_card(instance.card_id)
		if card_def == null:
			continue
		var pressure_bonus := int(active_match._shot_pattern_pressure_bonus(active_match.player, active_match.enemy, card_def, true)) if active_match._is_shot_card(card_def) else 0
		var accuracy_bonus := float(active_match._shot_pattern_accuracy_bonus(active_match.player, active_match.enemy, card_def)) if active_match._is_shot_card(card_def) else 0.0
		output.append({
			"name": card_def.name,
			"id": String(card_def.id),
			"slot_id": String(view.get("slot_id", "")),
			"hand_index": hand_index,
			"tags": PackedStringArray(card_def.tags),
			"cost": int(view.get("cost", active_match.get_card_cost(instance))),
			"card_def": card_def,
			"pressure_bonus": pressure_bonus,
			"accuracy_bonus": accuracy_bonus,
			"base_score": _candidate_base_score(active_match, card_def),
		})
	return output

func _candidate_base_score(active_match, card_def) -> float:
	var score := 0.0
	score += float(active_match._shot_pattern_pressure_bonus(active_match.player, active_match.enemy, card_def, true))
	score += float(active_match._enemy_matchup_pressure_bonus(card_def))
	score += float(active_match._turn_potion_power_pressure_bonus if card_def.tags.has("power") else 0)
	score += float(active_match._turn_potion_signature_pressure_bonus if card_def.tags.has("signature") else 0)
	score += float(active_match._turn_potion_topspin_pressure_bonus if card_def.tags.has("topspin") else 0)
	score += float(active_match._turn_potion_slice_pressure_bonus if card_def.tags.has("slice") else 0)
	score += float(active_match._shot_pattern_accuracy_bonus(active_match.player, active_match.enemy, card_def)) * 18.0
	score += float(active_match._enemy_matchup_accuracy_bonus(card_def)) * 20.0
	return score

func _point_context(active_match) -> String:
	if int(active_match.rally_state.exchanges) == 0:
		if String(active_match.current_server) == "player":
			return "serve"
		if String(active_match.current_server) == "enemy":
			return "return"
	return "rally"

func _is_closeout_window(active_match) -> bool:
	return int(active_match.rally_state.rp) >= int(active_match.rally_pressure_target) - 10

func _needs_stabilize(active_match) -> bool:
	var condition_ratio := float(active_match.player.current_condition) / float(maxi(1, active_match.player.max_condition))
	return int(active_match.rally_state.rp) <= -18 or condition_ratio <= 0.35 or active_match.player.get_status("fatigue") >= 2

func _safe_to_equip(active_match) -> bool:
	var exchanges := int(active_match.rally_state.exchanges)
	return exchanges <= 1 and int(active_match.rally_state.rp) > -12 and not _is_closeout_window(active_match)

func _recommend_card(active_match, candidates: Array, checks: Dictionary) -> Dictionary:
	if not bool(checks.get("is_player_turn", false)):
		return {}

	if bool(checks.get("is_serve_window", false)):
		var serve_pick := _recommend_serve_opener(candidates, bool(checks.get("closeout_window", false)))
		if not serve_pick.is_empty():
			return serve_pick
	if bool(checks.get("is_return_window", false)):
		var return_pick := _recommend_return_opener(candidates, active_match, checks)
		if not return_pick.is_empty():
			return return_pick

	if bool(checks.get("closeout_window", false)):
		var finish_pick := _recommend_finisher(candidates, checks)
		if not finish_pick.is_empty():
			return finish_pick
	if bool(checks.get("needs_stabilize", false)):
		var stabilize_pick := _recommend_stabilizer(candidates)
		if not stabilize_pick.is_empty():
			return stabilize_pick
	if bool(checks.get("enemy_at_net", false)):
		var punish_net_pick := _recommend_punish_net(candidates)
		if not punish_net_pick.is_empty():
			return punish_net_pick
	if bool(checks.get("ball_sits_high", false)) and bool(checks.get("player_is_forward", false)):
		var smash_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
			return _has_tag(candidate, "smash")
		, "High ball at the front of the court: cash it with an overhead.")
		if not smash_pick.is_empty():
			return smash_pick
	if bool(checks.get("court_is_open", false)):
		var redirect_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
			return _has_tag(candidate, "down_the_line") or String(candidate.get("id", "")) == "backhand_redirect"
		, "The court is open: change direction now before the lane closes.")
		if not redirect_pick.is_empty():
			return redirect_pick
	if String(active_match.rally_state.enemy_position) == "Baseline":
		var drop_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
			return _has_tag(candidate, "drop")
		, "The opponent is deep: use a drop shot to pull them short.")
		if not drop_pick.is_empty():
			return drop_pick
	if bool(checks.get("player_is_forward", false)):
		var forward_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
			return _has_tag(candidate, "volley") or _has_tag(candidate, "net")
		, "You are already forward: finish through the volley lane.")
		if not forward_pick.is_empty():
			return forward_pick
	if bool(checks.get("safe_to_equip", false)):
		var gear_pick := _recommend_gear(candidates, active_match)
		if not gear_pick.is_empty():
			return gear_pick
	var build_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
		return _has_tag(candidate, "crosscourt") or _has_tag(candidate, "topspin") or _has_tag(candidate, "rally")
	, "No immediate cash-out: build a safer pattern and open the next lane.")
	if not build_pick.is_empty():
		return build_pick
	var enhancer_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
		return _has_tag(candidate, "footwork") or _has_tag(candidate, "recovery") or _has_tag(candidate, "skill")
	, "No clean attack: reset your footing and keep the point playable.")
	if not enhancer_pick.is_empty():
		return enhancer_pick
	return _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
		return true
	, "Take the highest-value legal play available.")

func _recommend_serve_opener(candidates: Array, closeout_window: bool) -> Dictionary:
	if closeout_window:
		var power_serve := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
			return _has_tag(candidate, "serve") and (_has_tag(candidate, "power") or String(candidate.get("id", "")) == "ace_hunter")
		, "You are near the target: use the biggest serve opener to end the point fast.")
		if not power_serve.is_empty():
			return power_serve
	var kick_serve := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
		return String(candidate.get("id", "")) == "kick_serve"
	, "Start with kick and momentum so the plus-one ball comes back higher and easier to attack.")
	if not kick_serve.is_empty():
		return kick_serve
	var steady_serve := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
		return _has_tag(candidate, "serve")
	, "Open the point with a legal serve before spending the other slots.")
	return steady_serve

func _recommend_return_opener(candidates: Array, active_match, checks: Dictionary) -> Dictionary:
	if bool(checks.get("needs_stabilize", false)):
		var block_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
			return String(candidate.get("id", "")) in ["block_return", "short_hop_pickup"]
		, "Start the return point with a controlled block so you do not lose the rally immediately.")
		if not block_pick.is_empty():
			return block_pick
	if bool(checks.get("enemy_at_net", false)):
		var net_return := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
			return String(candidate.get("id", "")) == "lobbed_return" or _has_tag(candidate, "lob") or _has_tag(candidate, "slice")
		, "The server is crowding forward: lift or chip the return behind them.")
		if not net_return.is_empty():
			return net_return
	if active_match.enemy_def.keywords.has("serve"):
		var deep_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
			return String(candidate.get("id", "")) in ["deep_return", "backhand_counter_return", "return_rip"]
		, "Against a big serve, use depth or a firm redirect before the server settles into plus-one tennis.")
		if not deep_pick.is_empty():
			return deep_pick
	return _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
		return _has_tag(candidate, "return")
	, "Open the point with a legal return and take over the rally from there.")

func _recommend_finisher(candidates: Array, checks: Dictionary) -> Dictionary:
	if bool(checks.get("ball_sits_high", false)) and bool(checks.get("player_is_forward", false)):
		var smash_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
			return _has_tag(candidate, "smash")
		, "This is the cleanest finish: the ball is sitting up for an overhead.")
		if not smash_pick.is_empty():
			return smash_pick
	if bool(checks.get("enemy_at_net", false)):
		var punish_net_pick := _recommend_punish_net(candidates)
		if not punish_net_pick.is_empty():
			return punish_net_pick
	if bool(checks.get("court_is_open", false)):
		var line_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
			return _has_tag(candidate, "down_the_line") or String(candidate.get("id", "")) == "backhand_redirect"
		, "The angle is open: change direction now to close the point.")
		if not line_pick.is_empty():
			return line_pick
	if bool(checks.get("player_is_forward", false)):
		var volley_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
			return _has_tag(candidate, "volley") or _has_tag(candidate, "net")
		, "You are already on top of the net: end the exchange with a volley.")
		if not volley_pick.is_empty():
			return volley_pick
	return _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
		return _has_tag(candidate, "power") or _has_tag(candidate, "signature")
	, "The pressure is already high: use your hardest clean finisher now.")

func _recommend_stabilizer(candidates: Array) -> Dictionary:
	var recovery_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
		return _has_tag(candidate, "recovery") or _has_tag(candidate, "footwork") or _has_tag(candidate, "skill") or String(candidate.get("id", "")) in ["block_return", "short_hop_pickup"]
	, "You are behind in the point: stabilize with guard, recovery, or footwork before swinging bigger.")
	if not recovery_pick.is_empty():
		return recovery_pick
	return _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
		return _has_tag(candidate, "control") or _has_tag(candidate, "slice")
	, "No full reset is available: use a control ball to stop the rally from slipping away.")

func _recommend_punish_net(candidates: Array) -> Dictionary:
	var lob_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
		return _has_tag(candidate, "lob")
	, "Opponent is forward: the lob is the cleanest punishment.")
	if not lob_pick.is_empty():
		return lob_pick
	var low_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
		return _has_tag(candidate, "slice") or String(candidate.get("id", "")) == "passing_bullet"
	, "Opponent is forward: keep the ball low or thread the pass.")
	return low_pick

func _recommend_gear(candidates: Array, active_match) -> Dictionary:
	if String(active_match._active_string_name) == "":
		var string_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
			return _has_tag(candidate, "string")
		, "You have breathing room: equip your string setup now so the rest of the match gets stronger.")
		if not string_pick.is_empty():
			return string_pick
	if String(active_match._active_racquet_name) == "":
		var racquet_pick := _best_matching_candidate(candidates, func(candidate: Dictionary) -> bool:
			return _has_tag(candidate, "racquet") or _has_tag(candidate, "weight")
		, "You have breathing room: lock in the racquet profile before the next heavy exchange.")
		if not racquet_pick.is_empty():
			return racquet_pick
	return {}

func _best_matching_candidate(candidates: Array, predicate: Callable, reason: String) -> Dictionary:
	var best_candidate: Dictionary = {}
	var best_score := -INF
	for candidate_variant in candidates:
		var candidate := Dictionary(candidate_variant)
		if not predicate.call(candidate):
			continue
		var score := float(candidate.get("base_score", 0.0)) - float(candidate.get("cost", 0)) * 0.8
		if score > best_score:
			best_score = score
			best_candidate = candidate
	if best_candidate.is_empty():
		return {}
	best_candidate["reason"] = reason
	return best_candidate

func _has_tag(candidate: Dictionary, tag: String) -> bool:
	return PackedStringArray(candidate.get("tags", PackedStringArray())).has(tag)

func _build_headline(checks: Dictionary, recommendation: Dictionary) -> String:
	if not bool(checks.get("is_player_turn", false)):
		return "Logic tree: wait while the enemy resolves."
	if recommendation.is_empty():
		return "Logic tree: no legal card, so end the turn."
	return "Logic tree: %s from %s. %s" % [
		String(recommendation.get("name", "No card")),
		String(recommendation.get("slot_id", "slot")).capitalize(),
		String(recommendation.get("reason", "")),
	]

func _build_tree(checks: Dictionary, recommendation: Dictionary) -> Dictionary:
	var action_text := "End turn."
	if not recommendation.is_empty():
		action_text = "Play %s from %s. %s" % [
			String(recommendation.get("name", "a card")),
			String(recommendation.get("slot_id", "the hand")).capitalize(),
			String(recommendation.get("reason", "")),
		]
	return _decision_node(
		"Is it your turn?",
		bool(checks.get("is_player_turn", false)),
		_decision_node(
			"Is the point still unopened?",
			bool(checks.get("is_opening_contact", false)),
			_decision_node(
				"Are you serving this point?",
				bool(checks.get("is_serve_window", false)),
				_action_leaf("Play a legal serve opener first, then build your plus-one ball."),
				_action_leaf("Play a legal return opener first, then either redirect or stabilize.")
			),
			_decision_node(
				"Are you close to winning the point already?",
				bool(checks.get("closeout_window", false)),
				_action_leaf("Cash the point with the best finisher: smash, line change, volley, or power ball."),
				_decision_node(
					"Are you under pressure or low on condition?",
					bool(checks.get("needs_stabilize", false)),
					_action_leaf("Stabilize first with recovery, guard, footwork, or control."),
					_decision_node(
						"Is the opponent crowding the net?",
						bool(checks.get("enemy_at_net", false)),
						_action_leaf("Punish the net with a lob, pass, or low slice at the feet."),
						_decision_node(
							"Is the court open for a direction change?",
							bool(checks.get("court_is_open", false)),
							_action_leaf("Change direction now with down-the-line or a redirect."),
							_decision_node(
								"Do you have time to invest in gear?",
								bool(checks.get("safe_to_equip", false)),
								_action_leaf("If no clean tactical shot exists, equip string or racquet now."),
								_action_leaf(action_text)
							)
						)
					)
				)
			)
		),
		_action_leaf("Wait, read the intent, and prepare the next branch.")
	)

func _decision_node(check_text: String, result: bool, true_branch: Dictionary, false_branch: Dictionary) -> Dictionary:
	return {
		"type": "decision",
		"check": check_text,
		"result": result,
		"true_branch": true_branch,
		"false_branch": false_branch,
	}

func _action_leaf(action_text: String) -> Dictionary:
	return {
		"type": "action",
		"action": action_text,
	}

func _flatten_tree(node: Dictionary, depth: int, lines: PackedStringArray) -> void:
	var prefix := ""
	for _i in range(depth):
		prefix += "  "
	var node_type := String(node.get("type", ""))
	if node_type == "decision":
		lines.append("%s? %s -> %s" % [
			prefix + String(node.get("check", "Decision")),
			"yes" if bool(node.get("result", false)) else "no",
			"T" if bool(node.get("result", false)) else "F",
		])
		var next_node := Dictionary(node.get("true_branch", {})) if bool(node.get("result", false)) else Dictionary(node.get("false_branch", {}))
		_flatten_tree(next_node, depth + 1, lines)
		return
	lines.append("%sAction: %s" % [prefix, String(node.get("action", ""))])
