class_name CombatHudPresenter
extends RefCounted

func build_combat_panel_payload(run_state, selected_class, available_class_count: int, total_class_count: int, total_acts: int) -> Dictionary:
	var payload := {
		"panel_mode": "placeholder",
		"combat_header": "",
		"match_summary": "",
		"player_summary": "",
		"enemy_intent": "",
		"enemy_summary": "",
		"hand_header": "Hand",
		"placeholder_text": "",
		"hand_min_height": 168,
	}

	if String(run_state.phase) == "idle":
		payload["combat_header"] = "Tournament Lobby"
		payload["match_summary"] = "Select a class, review its starting plan, then begin the tournament when the loadout looks right."
		payload["player_summary"] = "Class: %s\nStarting deck: %d cards\nUnlocked roster: %d / %d" % [
			String(selected_class.name if selected_class != null else "None"),
			int(selected_class.starting_deck.size() if selected_class != null else 0),
			available_class_count,
			total_class_count,
		]
		payload["enemy_intent"] = "Run Flow\nLanding -> Class Select -> Major Reveal -> Match"
		payload["enemy_summary"] = "Press Begin Tournament to lock in this class for the next run.\nContinue Run restores the last safe checkpoint instead."
		payload["hand_header"] = "Prep Notes"
		payload["placeholder_text"] = "Browse classes on the left, then press Begin Tournament when you are ready to enter the draw."
		return payload

	if run_state.active_match != null:
		var active_match = run_state.active_match
		var battle: Dictionary = active_match.get_battle_presentation()
		var intent_detail: Dictionary = Dictionary(battle.get("enemy_intent_detail", {}))
		payload["panel_mode"] = "hand"
		payload["combat_header"] = "Live Match"
		payload["match_summary"] = active_match.get_match_summary()
		payload["player_summary"] = active_match.get_player_summary()
		payload["enemy_intent"] = "Opponent Plan\n" + "\n".join(_build_enemy_plan_lines(intent_detail, true))
		payload["enemy_summary"] = active_match.get_enemy_summary()
		payload["hand_header"] = "Hand"
		return payload

	match String(run_state.phase):
		"reward":
			var is_checkpoint_menu: bool = run_state.is_checkpoint_menu()
			var reward_menu_kind := String(run_state.get_reward_menu_kind())
			payload["combat_header"] = "Deck Trim" if reward_menu_kind == "trim" else ("Checkpoint" if is_checkpoint_menu else "Reward Draft")
			payload["match_summary"] = run_state.pending_reward_reason
			payload["player_summary"] = run_state.get_run_summary()
			payload["enemy_intent"] = "Enemy Intent\nNo active opponent."
			payload["enemy_summary"] = "Choose one card to cut after taking the upgrade." if reward_menu_kind == "trim" else ("Spend bitcoin, recover, or leave the checkpoint." if is_checkpoint_menu else "Choose a reward, then return to the map.")
			payload["hand_header"] = "Deck Trim" if reward_menu_kind == "trim" else ("Checkpoint Offers" if is_checkpoint_menu else "Hand")
			payload["placeholder_text"] = "No hand while rewards are open."
		"run_won":
			payload["combat_header"] = "Run Complete"
			payload["match_summary"] = run_state.status_message
			payload["player_summary"] = run_state.get_run_summary()
			payload["enemy_intent"] = "Enemy Intent\nNo active opponent."
			payload["enemy_summary"] = "Start another run to push the roster further."
			payload["placeholder_text"] = "The trophy is already in your hands."
		"run_lost":
			payload["combat_header"] = "Run Over"
			payload["match_summary"] = run_state.status_message
			payload["player_summary"] = run_state.get_run_summary()
			payload["enemy_intent"] = "Enemy Intent\nNo active opponent."
			payload["enemy_summary"] = "Reset or start a new run when ready."
			payload["placeholder_text"] = "No cards remain in play."
		_:
			var primary_node_id := int(run_state.get_primary_accessible_node_id())
			var primary_route_summary := "No route is currently available."
			if primary_node_id >= 0:
				primary_route_summary = run_state.get_node_summary(primary_node_id)
			payload["panel_mode"] = "routes"
			payload["combat_header"] = "Bracket Select"
			payload["match_summary"] = primary_route_summary
			payload["player_summary"] = "Choose the next stop from the bracket buttons below or click the left-side map."
			payload["enemy_intent"] = "Route Select\nPick a route to enter the next match, shop, rest stop, or event."
			payload["enemy_summary"] = "Major %d of %d\nEndurance %d / %d\nDeck %d cards\nRelics %d\nBitcoin %d BTC\nRacquet Tune Lv.%d" % [
				int(run_state.current_act),
				total_acts,
				int(run_state.current_condition),
				int(run_state.max_condition),
				int(run_state.deck_card_ids.size()),
				int(run_state.relic_ids.size()),
				int(run_state.bitcoin),
				int(run_state.racquet_tuning_level),
			]
			payload["hand_header"] = "Available Routes"
			payload["hand_min_height"] = 240

	return payload

func build_stage_payload(active_match, major_name: String, logic_tree: Dictionary, compact_level: int) -> Dictionary:
	var battle: Dictionary = active_match.get_battle_presentation()
	var player_data: Dictionary = Dictionary(battle.get("player", {}))
	var enemy_data: Dictionary = Dictionary(battle.get("enemy", {}))
	var games_score := String(battle.get("games_score", "0-0"))
	var score_status := String(battle.get("score_status", "Point Live"))
	var final_rule_name := String(battle.get("final_rule_name", ""))
	var hand_display: Array = active_match.get_hand_slot_display()
	var last_pressure_event := String(battle.get("last_pressure_event", ""))
	var recent_events: Array = Array(battle.get("recent_events", []))
	var point_number := int(battle.get("point_number", 0))
	var turn_number := int(battle.get("turn_number", 0))
	var score_player := String(battle.get("score_player", "Love"))
	var score_enemy := String(battle.get("score_enemy", "Love"))
	var point_context := _battle_initial_contact_context(battle)
	var point_context_banner := _battle_initial_contact_banner(battle)
	var point_context_hint := _battle_initial_contact_hint(battle)
	var pressure_now := int(battle.get("rally_pressure", 0))
	var pressure_target := int(battle.get("rally_pressure_max", 100))
	var rally_lines := PackedStringArray([
		"Point End: %s/%d pressure • X%d" % [
			_signed_value(pressure_now),
			pressure_target,
			int(battle.get("rally_exchanges", 0)),
		],
		"Endurance tracks run attrition • %s" % String(battle.get("ball_state", "NormalBall")),
	])
	var flow_lines := PackedStringArray([
		"Tennis score drives the match, not Endurance.",
		"Point %d • %s serves • %s" % [
			point_number,
			String(battle.get("server", "player")).capitalize(),
			"You act" if active_match.state == "player_turn" else "Enemy acts",
		],
	])
	var meta_line := "Games %s • %s • Point End %s/%d pressure" % [
		games_score,
		String(battle.get("match_label", "Match")),
		_signed_value(pressure_now),
		pressure_target,
	]
	var intent_detail: Dictionary = Dictionary(battle.get("enemy_intent_detail", {}))
	var intent_lines := _build_enemy_plan_lines(intent_detail, false)
	if intent_lines.is_empty():
		var intent_summary := String(battle.get("enemy_intent_summary", "No telegraph."))
		var intent_projection := String(battle.get("enemy_intent_projection", ""))
		intent_lines = PackedStringArray([compact_stage_summary(intent_summary, compact_level)])
		if intent_projection != "":
			intent_lines.append("Next %s" % intent_projection)
		elif last_pressure_event != "":
			intent_lines.append(compact_stage_summary(last_pressure_event, compact_level))

	var occupied_slots := 0
	for slot_entry in hand_display:
		if int(Dictionary(slot_entry).get("hand_index", -1)) >= 0:
			occupied_slots += 1

	return {
		"battle": battle,
		"player_title": _compact_actor_title(String(player_data.get("name", "Player")), 18),
		"player_title_full": String(player_data.get("name", "Player")),
		"player_hud_body": _build_stage_hud_body(player_data),
		"enemy_title": _compact_actor_title(String(enemy_data.get("name", "Opponent")), 18),
		"enemy_title_full": String(enemy_data.get("name", "Opponent")),
		"enemy_hud_body": _build_stage_hud_body(enemy_data),
		"major_label": "%s • %s" % [major_name, String(battle.get("surface_name", "Court"))],
		"point_context": point_context,
		"point_context_banner": point_context_banner,
		"point_context_hint": point_context_hint,
		"score_label": "Tennis Score • %s | %s" % [score_player, score_enemy],
		"meta_label": compact_stage_summary("%s • %s%s" % [
			meta_line,
			score_status,
			" • " + final_rule_name if final_rule_name != "" else "",
		], compact_level),
		"rally_body": "\n".join(rally_lines),
		"flow_body": "\n".join(flow_lines),
		"intent_body": "\n".join(intent_lines),
		"player_pod_title": _compact_actor_title(String(player_data.get("name", "You")), 20),
		"player_pod_title_full": String(player_data.get("name", "You")),
		"player_pod_body": _build_stage_actor_body(player_data),
		"enemy_pod_title": _compact_actor_title(String(enemy_data.get("name", "Opponent")), 20),
		"enemy_pod_title_full": String(enemy_data.get("name", "Opponent")),
		"enemy_pod_body": _build_stage_actor_body(enemy_data),
		"player_statuses": player_data.get("statuses", PackedStringArray()),
		"enemy_statuses": enemy_data.get("statuses", PackedStringArray()),
		"stamina_title": "Endurance",
		"stamina_label": "%d / %d" % [
			int(player_data.get("condition", 0)),
			int(player_data.get("max_condition", 0)),
		],
		"stamina_hint": "Stamina %d/%d • sloppy points drain endurance and force more rest stops." % [
			int(player_data.get("stamina", 0)),
			int(player_data.get("max_stamina", 0)),
		],
		"hand_title": "Hand • %s • %d/%d" % [point_context_banner, occupied_slots, hand_display.size()],
		"turn_hint": _build_turn_hint(active_match, point_context, logic_tree),
		"turn_hint_tooltip": "\n".join(PackedStringArray(logic_tree.get("tree_lines", PackedStringArray()))),
		"event_feed": format_recent_match_events(recent_events),
		"point_number": point_number,
	}

func compact_stage_summary(text: String, compact_level: int) -> String:
	var normalized := text.replace("\n", " ").strip_edges()
	if compact_level <= 0:
		return text
	if compact_level == 1:
		if normalized.length() <= 88:
			return normalized
		return normalized.substr(0, 85).rstrip(" ,.;") + "..."
	var sentence_end := normalized.find(".")
	if sentence_end > 0:
		normalized = normalized.substr(0, sentence_end + 1)
	if normalized.length() <= 62:
		return normalized
	return normalized.substr(0, 59).rstrip(" ,.;") + "..."

func _build_enemy_plan_lines(intent_detail: Dictionary, sidebar_mode: bool) -> PackedStringArray:
	if intent_detail.is_empty():
		return PackedStringArray(["Plan: No telegraph yet."])
	var plan_name := String(intent_detail.get("name", "")).strip_edges()
	if plan_name == "":
		return PackedStringArray(["Plan: No telegraph yet."])
	var ai_state := String(intent_detail.get("ai_state", "")).strip_edges()
	var plan_line := "Plan: %s" % plan_name
	if ai_state != "":
		plan_line += " (%s)" % ai_state
	var lines := PackedStringArray([plan_line])
	var per_hit_pressure := int(intent_detail.get("per_hit_pressure", 0))
	var hits := maxi(1, int(intent_detail.get("hits", 1)))
	var total_pressure := int(intent_detail.get("total_pressure", 0))
	if total_pressure > 0:
		var pressure_line := "Pressure: %d" % total_pressure
		if hits > 1:
			pressure_line += " (%d x %d hits)" % [per_hit_pressure, hits]
		lines.append(pressure_line)
	var court_bits := PackedStringArray()
	var position := String(intent_detail.get("position", "")).strip_edges()
	var lane := String(intent_detail.get("lane", "")).strip_edges()
	var ball_state := String(intent_detail.get("ball_state", "")).strip_edges()
	if position != "":
		court_bits.append(position)
	if lane != "":
		court_bits.append(lane)
	if ball_state != "":
		court_bits.append(ball_state)
	if not court_bits.is_empty():
		lines.append("Court: " + " • ".join(court_bits))
	var rider_bits := PackedStringArray()
	for rider in [
		{"key": "guard", "label": "Guard"},
		{"key": "fatigue", "label": "Fatigue"},
		{"key": "pressure", "label": "RP"},
		{"key": "open_court", "label": "Open Court"},
		{"key": "momentum", "label": "Momentum"},
		{"key": "tilt", "label": "Tilt"},
		{"key": "cost_up", "label": "Cost Spike"},
		{"key": "position_lock", "label": "Pos Lock"},
	]:
		var amount := int(intent_detail.get(String(rider["key"]), 0))
		if amount > 0:
			rider_bits.append("%s +%d" % [String(rider["label"]), amount])
	if not rider_bits.is_empty():
		lines.append("Adds: " + ", ".join(rider_bits))
	elif sidebar_mode:
		lines.append("Adds: No extra rider effects.")
	return lines

func format_recent_match_events(events: Array) -> String:
	if events.is_empty():
		return "Recent events will stack here once the point opens."
	var lines := PackedStringArray()
	for index in range(events.size() - 1, -1, -1):
		var event := Dictionary(events[index])
		var line := _describe_recent_event(event)
		if line == "":
			continue
		lines.append("• " + line)
		if lines.size() >= 3:
			break
	if lines.is_empty():
		return "Recent events will stack here once the point opens."
	return "\n".join(lines)

func _describe_recent_event(event: Dictionary) -> String:
	var kind := String(event.get("kind", ""))
	var payload := Dictionary(event.get("payload", {}))
	var side := String(event.get("side", ""))
	match kind:
		"card_played":
			return "%s: %s" % [_event_side_label(side), String(payload.get("name", "a card"))]
		"pressure_shifted":
			return "%s RP from %s" % [_signed_value(int(payload.get("amount", 0))), String(payload.get("source", "rally exchange"))]
		"point_started":
			return "Point %d • %s serves" % [int(event.get("point_number", 0)), String(payload.get("server", "player")).capitalize()]
		"point_resolved":
			return "%s won point • %s" % [String(payload.get("winner", "match")).capitalize(), String(payload.get("reason", "rally resolution"))]
		"game_won":
			return "%s took the game" % String(payload.get("winner", "match")).capitalize()
		"match_resolved":
			return "%s won the match" % String(payload.get("winner", "match")).capitalize()
		"potion_used":
			return "%s used %s" % [_event_side_label(side), String(payload.get("name", "a potion"))]
		"log":
			return String(payload.get("line", ""))
	return ""

func _event_side_label(side: String) -> String:
	if side == "":
		return "Match"
	return side.capitalize()

func _battle_initial_contact_context(battle: Dictionary) -> String:
	var context := String(battle.get("initial_contact_context", ""))
	if context != "":
		return context
	if int(battle.get("rally_exchanges", 0)) > 0:
		return "rally"
	return "serve" if String(battle.get("server", "player")) == "player" else "return"

func _battle_initial_contact_banner(battle: Dictionary) -> String:
	var banner := String(battle.get("initial_contact_banner", ""))
	if banner != "":
		return banner
	match _battle_initial_contact_context(battle):
		"serve":
			return "SERVE REQUIRED"
		"return":
			return "RETURN REQUIRED"
		_:
			return "RALLY LIVE"

func _battle_initial_contact_hint(battle: Dictionary) -> String:
	var hint := String(battle.get("initial_contact_hint", ""))
	if hint != "":
		return hint
	match _battle_initial_contact_context(battle):
		"serve":
			return "Point unopened. Serve required to open point from the INITIAL slot."
		"return":
			return "Point unopened. Return required to open point from the INITIAL slot."
		_:
			return "Point opened. Chase the rally pressure target or force an error to end the point."

func _build_turn_hint(active_match, point_context: String, logic_tree: Dictionary = {}) -> String:
	if active_match.state != "player_turn":
		return "Enemy response resolving. The point ends at the pressure target or on an error."
	var recommendation := String(logic_tree.get("recommended_card_name", ""))
	var recommendation_reason := String(logic_tree.get("recommended_reason", ""))
	match point_context:
		"serve":
			if recommendation != "":
				return "Serve required. Point ends at the pressure target or on an error. %s: %s" % [recommendation, recommendation_reason]
			return "Serve required. Use INITIAL to open, then build pressure."
		"return":
			if recommendation != "":
				return "Return required. Point ends at the pressure target or on an error. %s: %s" % [recommendation, recommendation_reason]
			return "Return required. Use INITIAL to open, then redirect or stabilize."
		_:
			if recommendation != "":
				return "Rally live. Tennis score wins the match; Endurance is run attrition. %s: %s" % [recommendation, recommendation_reason]
			return "Rally live. Build pressure with SHOT, ENHANCER, and MODIFIER."

func _build_stage_hud_body(actor_data: Dictionary) -> String:
	var status_summary := "Stable"
	var status_value = actor_data.get("statuses", PackedStringArray())
	if typeof(status_value) == TYPE_PACKED_STRING_ARRAY and not PackedStringArray(status_value).is_empty():
		status_summary = PackedStringArray(status_value)[0]
	elif status_value is Array and not Array(status_value).is_empty():
		status_summary = String(Array(status_value)[0])
	var summary := PackedStringArray([
		"E%d" % int(actor_data.get("condition", 0)),
		"S%d" % int(actor_data.get("stamina", 0)),
		"G%d" % int(actor_data.get("guard", 0)),
		_compact_court_position(String(actor_data.get("position", "Baseline"))),
	])
	if status_summary != "Stable":
		summary.append(_compact_actor_title(status_summary, 10))
	return " • ".join(summary)

func _build_stage_actor_body(actor_data: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append("Endurance %d • Guard %d" % [
		int(actor_data.get("condition", 0)),
		int(actor_data.get("guard", 0)),
	])
	lines.append("Court %s • Stamina %d" % [
		String(actor_data.get("position", "Baseline")),
		int(actor_data.get("stamina", 0)),
	])
	var status_summary := "Stable"
	var statuses := PackedStringArray()
	var status_value = actor_data.get("statuses", PackedStringArray())
	if typeof(status_value) == TYPE_PACKED_STRING_ARRAY:
		statuses = status_value
	elif status_value is Array:
		for entry in status_value:
			statuses.append(String(entry))
	if not statuses.is_empty():
		status_summary = _join_strings(statuses)
	lines.append(status_summary)
	return "\n".join(lines)

func _compact_actor_title(name: String, max_length: int) -> String:
	if name.length() <= max_length:
		return name
	return name.substr(0, max_length - 3).rstrip(" ") + "..."

func _compact_court_position(position: String) -> String:
	match position.to_lower():
		"baseline":
			return "Base"
		"serviceline":
			return "Mid"
		"net":
			return "Net"
	return position

func _join_strings(values: PackedStringArray) -> String:
	if values.is_empty():
		return ""
	return ", ".join(values)

func _signed_value(amount: int) -> String:
	return "+%d" % amount if amount > 0 else str(amount)
