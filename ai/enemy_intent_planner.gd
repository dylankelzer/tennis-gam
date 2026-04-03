class_name EnemyIntentPlanner
extends RefCounted

func validate_intent_schema(enemy_id: String, intent: Dictionary, asset_path: String = "") -> PackedStringArray:
	var errors := PackedStringArray()
	var context := enemy_id
	if asset_path != "":
		context = "%s :: %s" % [asset_path, enemy_id]
	var name := String(intent.get("name", "")).strip_edges()
	if name == "":
		errors.append("%s :: intent.name must be non-empty" % context)
	for key in intent.keys():
		var value = intent[key]
		if (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and (is_nan(float(value)) or is_inf(float(value))):
			errors.append("%s :: intent.%s must be finite" % [context, String(key)])
	return errors

func choose_intent(enemy_def, context: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if enemy_def == null:
		return {"name": "Stall", "guard": 4}
	var intent_cycle: Array = Array(enemy_def.get("intent_cycle") if enemy_def is Dictionary else enemy_def.intent_cycle) if enemy_def != null else []
	if intent_cycle.is_empty():
		return {"name": "Stall", "guard": 4}
	var best_score := -INF
	var best_intent: Dictionary = {}
	var ai_state := determine_ai_state(enemy_def, context)
	for raw_intent in intent_cycle:
		var intent := Dictionary(raw_intent)
		var score := score_intent(enemy_def, ai_state, intent, context)
		score += rng.randf_range(0.0, 0.35)
		if score > best_score:
			best_score = score
			best_intent = intent.duplicate(true)
	return best_intent

func determine_ai_state(enemy_def, context: Dictionary) -> String:
	var current_server := String(context.get("current_server", "player"))
	var exchanges := int(context.get("rally_exchanges", 0))
	var rally_pressure := float(context.get("rally_pressure", 0.0))
	var rally_target := maxf(1.0, float(context.get("rally_target", 100.0)))
	var rally_pressure_normalized := rally_pressure / rally_target
	if current_server == "enemy" and exchanges == 0:
		return "ServeMode"
	if rally_pressure_normalized <= -0.85:
		return "CloseOut"
	if rally_pressure_normalized >= 0.55:
		return "Defend"
	if enemy_def.keywords.has("net"):
		return "NetPlay"
	if rally_pressure_normalized >= 0.25:
		return "Panic"
	return "Attack"

func score_intent(enemy_def, ai_state: String, intent: Dictionary, context: Dictionary) -> float:
	var score := 0.0
	var damage := float(intent.get("damage", 0)) * float(maxi(1, int(intent.get("hits", 1))))
	var guard_value := float(intent.get("guard", 0))
	var fatigue_value := float(intent.get("fatigue", 0))
	var pressure_value := float(intent.get("pressure", 0))
	var open_court_value := float(intent.get("open_court", 0))
	# New disruption effects — valued similarly to fatigue/pressure
	var tilt_value := float(intent.get("tilt", 0))
	var cost_up_value := float(intent.get("cost_up", 0))
	var position_lock_value := float(intent.get("position_lock", 0))
	var rally_pressure := int(context.get("rally_pressure", 0))
	var rally_target := maxi(20, int(context.get("rally_target", 100)))
	var current_server := String(context.get("current_server", "player"))
	var player_guard := int(context.get("player_guard", 0))
	var enemy_guard := int(context.get("enemy_guard", 0))
	var player_return_support := float(context.get("player_return_support", 0.0))
	var rally_cards_played := int(context.get("rally_cards_played_this_turn", 0))
	var player_current_stamina := int(context.get("player_current_stamina", 0))
	var player_max_stamina := maxi(1, int(context.get("player_max_stamina", 1)))
	var player_fatigue := int(context.get("player_fatigue", 0))
	var player_open_court := int(context.get("player_open_court", 0))
	var player_pressure_to_win := maxi(0, rally_target - rally_pressure)
	var enemy_pressure_to_win := maxi(0, rally_target + rally_pressure)
	var closeout_window := maxi(6, int(round(float(rally_target) * 0.22)))
	var defend_window := maxi(6, int(round(float(rally_target) * 0.22)))
	var panic_window := maxi(8, int(round(float(rally_target) * 0.38)))
	var player_low_stamina := player_current_stamina <= maxi(1, int(ceil(float(player_max_stamina) * 0.4)))

	match ai_state:
		"ServeMode":
			score += damage * 1.2 + pressure_value * 2.0 + cost_up_value * 2.5
		"CloseOut":
			score += damage * 1.5 + open_court_value * 4.0 + position_lock_value * 2.0
		"Defend":
			score += guard_value * 1.5 + fatigue_value * 3.0 + pressure_value * 1.5 + tilt_value * 2.5
		"NetPlay":
			score += damage + open_court_value * 3.0 + guard_value * 0.5 + position_lock_value * 3.0
		"Panic":
			score += guard_value * 1.7 + fatigue_value * 2.0 + tilt_value * 1.8
		_:
			score += damage * 1.1 + pressure_value * 1.5 + tilt_value * 1.5 + cost_up_value * 1.5

	if player_pressure_to_win <= defend_window:
		score += guard_value * 1.6
		score += fatigue_value * 2.4
		score += pressure_value * 1.2
	if enemy_pressure_to_win <= closeout_window:
		score += damage * 0.6
		score += open_court_value * 3.0
		if player_open_court > 0:
			score += float(player_open_court) * 2.5
	if player_pressure_to_win <= panic_window:
		score += guard_value * 0.8 + fatigue_value * 0.9
	if player_low_stamina:
		score += fatigue_value * 2.0
		score += pressure_value * 0.6
	if player_fatigue > 0:
		score += fatigue_value * minf(2.5, 1.0 + float(player_fatigue) * 0.25)
	if rally_pressure >= 0 and enemy_guard <= 2:
		score += guard_value * 0.5
	if enemy_def.keywords.has("net") and intent_name(intent).findn("volley") >= 0:
		score += 4.0
	if enemy_def.keywords.has("serve") and current_server == "enemy":
		score += 3.0
		var weak_return_pressure := clampf(6.5 - player_return_support, 0.0, 6.5)
		var strong_return_pressure := clampf(player_return_support - 4.0, 0.0, 8.0)
		match serve_pattern(intent):
			"punish", "jam", "burst":
				score += weak_return_pressure * 2.2
				score -= strong_return_pressure * 2.0
			"probe":
				score += strong_return_pressure * 1.8
				score += float(intent.get("momentum", 0)) * 2.0
				score += guard_value * 0.5
			"approach":
				score += strong_return_pressure * 1.6
				score += open_court_value * 2.0
				score += guard_value * 0.7
				score -= weak_return_pressure * 0.6
			"finish":
				score += strong_return_pressure * 1.2
				score += open_court_value * 2.0
				if player_guard <= 4:
					score += 3.0
	if intent.has("bonus_if_player_attacked") and rally_cards_played > 0:
		score += int(intent.get("bonus_if_player_attacked", 0))
	if intent.has("bonus_if_player_guard_low") and player_guard <= 4:
		score += int(intent.get("bonus_if_player_guard_low", 0))
	return score

func describe_intent(intent: Dictionary) -> String:
	var parts := PackedStringArray([intent_name(intent)])
	if intent.has("damage"):
		parts.append(str(intent.get("damage", 0)) + " pressure")
	if intent.has("hits"):
		parts.append(str(intent.get("hits", 1)) + " hits")
	if intent.has("guard"):
		parts.append("Guard +" + str(intent.get("guard", 0)))
	if intent.has("fatigue"):
		parts.append("Fatigue +" + str(intent.get("fatigue", 0)))
	if intent.has("pressure"):
		parts.append("Pressure +" + str(intent.get("pressure", 0)))
	if intent.has("open_court"):
		parts.append("Open Court +" + str(intent.get("open_court", 0)))
	if intent.has("tilt"):
		parts.append("Tilt ×" + str(intent.get("tilt", 0)))
	if intent.has("cost_up"):
		parts.append("Cost Spike ×" + str(intent.get("cost_up", 0)))
	if intent.has("position_lock"):
		parts.append("Position Lock ×" + str(intent.get("position_lock", 0)))
	return " | ".join(parts)

func project_intent(intent: Dictionary, context: Dictionary) -> Dictionary:
	var intent_label := intent_name(intent).to_lower()
	var projection := {
		"position": String(context.get("enemy_position", "Baseline")),
		"lane": "Center",
		"ball_state": String(context.get("ball_state", "NormalBall")),
	}
	if intent_label.find("serve") >= 0 or intent_label.find("toss") >= 0 or intent_label.find("kick") >= 0:
		projection["position"] = "Baseline"
		projection["lane"] = "Body"
		projection["ball_state"] = "HighBall"
	elif intent_label.find("volley") >= 0 or intent_label.find("intercept") >= 0 or intent_label.find("poach") >= 0:
		projection["position"] = "Net"
		projection["lane"] = "Crosscourt"
		projection["ball_state"] = "AtNet"
	elif intent_label.find("approach") >= 0 or intent_label.find("sneak") >= 0 or intent_label.find("crash") >= 0:
		projection["position"] = "ServiceLine"
		projection["lane"] = "Center"
		projection["ball_state"] = "AtNet"
	elif intent_label.find("lob") >= 0 or intent_label.find("arc") >= 0 or intent_label.find("sky") >= 0 or intent_label.find("kicker") >= 0:
		projection["position"] = "Baseline"
		projection["lane"] = "Deep"
		projection["ball_state"] = "HighBall"
	elif intent_label.find("angle") >= 0:
		projection["position"] = "ServiceLine"
		projection["lane"] = "Crosscourt"
		projection["ball_state"] = "AtNet"
	elif intent_label.find("line") >= 0 or intent_label.find("passing") >= 0 or intent_label.find("redirect") >= 0:
		projection["position"] = "Baseline"
		projection["lane"] = "Down The Line"
		projection["ball_state"] = "NormalBall"
	elif intent_label.find("backpedal") >= 0 or intent_label.find("retreat") >= 0 or intent_label.find("shield") >= 0 or intent_label.find("wall") >= 0 or intent_label.find("roost") >= 0 or intent_label.find("dig") >= 0:
		projection["position"] = "Baseline"
		projection["lane"] = "Deep"
		projection["ball_state"] = "NormalBall"
	return projection

func format_projection(intent: Dictionary, context: Dictionary) -> String:
	if intent.is_empty():
		return ""
	var projection := project_intent(intent, context)
	return "Ends %s | Lane %s | Ball %s" % [
		String(projection.get("position", "Baseline")),
		String(projection.get("lane", "Center")),
		String(projection.get("ball_state", "NormalBall")),
	]

func intent_name(intent: Dictionary) -> String:
	return String(intent.get("name", "Pattern"))

func serve_pattern(intent: Dictionary) -> String:
	if intent.has("serve_pattern"):
		return String(intent.get("serve_pattern", "neutral"))
	var lowered := intent_name(intent).to_lower()
	if lowered.find("approach") >= 0 or lowered.find("rush") >= 0 or lowered.find("volley") >= 0:
		return "approach"
	if lowered.find("burst") >= 0 or lowered.find("ace") >= 0 or lowered.find("prime time") >= 0:
		return "punish"
	if lowered.find("kick") >= 0 or lowered.find("toss") >= 0 or lowered.find("slider") >= 0:
		return "probe"
	return "neutral"
