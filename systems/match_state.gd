class_name MatchState
extends RefCounted

const CardDatabaseScript = preload("res://scripts/data/card_database.gd")
const CardInstanceScript = preload("res://scripts/core/card_instance.gd")
const CombatActorStateScript = preload("res://scripts/core/combat_actor_state.gd")
const DeckStateScript = preload("res://scripts/core/deck_state.gd")
const EnemyIntentPlannerScript = preload("res://scripts/ai/enemy_intent_planner.gd")
const MatchEventScript = preload("res://scripts/core/match_event.gd")
const PotionDatabaseScript = preload("res://scripts/data/potion_database.gd")
const RelicDatabaseScript = preload("res://scripts/data/relic_database.gd")
const RallyStateScript = preload("res://scripts/core/rally_state.gd")
const TennisScoreScript = preload("res://scripts/core/tennis_score.gd")

const HAND_SLOT_ORDER := ["initial_contact", "shot", "enhancer", "modifier", "special"]
const RETAIN_SLOT_PRIORITY := ["special", "modifier", "enhancer", "shot", "initial_contact"]
const BOSS_DEBUFF_CARD_IDS := [&"crowd_noise_debuff", &"late_whistle_debuff", &"tight_strings_debuff"]

var player_class
var enemy_def
var relic_ids: PackedStringArray = PackedStringArray()
var potion_ids: PackedStringArray = PackedStringArray()
var encounter_type: String = "regular"
var major_name: String = "Major"
var surface_key: String = "hardcourt"
var surface_name: String = "Hardcourt"
var final_rule_id: String = ""
var final_rule_name: String = ""
var final_rule_description: String = ""
var match_label: String = "Standard Game"
var racquet_tuning_level: int = 0
var rally_pressure_target: int = RallyStateScript.RP_MAX
var games_to_win: int = 1
var no_ad: bool = false
var player_games_won: int = 0
var enemy_games_won: int = 0
var current_server: String = "player"
var point_number: int = 0
var turn_number: int = 0
var point_condition_loss: int = 5
var state: String = "setup"
var result_reason: String = ""
var queued_enemy_intent: Dictionary = {}
var hand: Array = []
var hand_size: int = 5
var _hand_slots: Dictionary = {}
var _temp_card_uid: int = -1
var _novice_free_skill_used_this_turn: bool = false
var log_lines: PackedStringArray = PackedStringArray()

var tennis_score = TennisScoreScript.new()
var rally_state = RallyStateScript.new()
var player = null
var enemy = null

var _card_database = CardDatabaseScript.new()
var _player_deck = DeckStateScript.new()
var _enemy_intent_planner = EnemyIntentPlannerScript.new()
var _potion_database = PotionDatabaseScript.new()
var _relic_database = RelicDatabaseScript.new()
var _rng := RandomNumberGenerator.new()
var _used_tags_this_turn: Dictionary = {}
var _shot_cards_played_this_turn: int = 0
var _rally_cards_played_this_turn: int = 0
var _footwork_cards_played_this_turn: int = 0
var _next_topspin_bonus: int = 0
var _next_topspin_accuracy_bonus: float = 0.0
var _next_net_cost_free: bool = false
var _next_net_bonus_pressure: int = 0
var _next_net_bonus_accuracy: float = 0.0
var _first_guard_trigger_used_this_turn: bool = false
var _slice_bonus_used_this_turn: bool = false
var _master_focus_trigger_used_this_turn: bool = false
var _alcaraz_chain_ready: bool = false
var _alcaraz_bonus_used_this_turn: bool = false
var _cards_played_this_turn: int = 0
var _serve_used_this_turn: bool = false
var _point_is_opening_of_game: bool = true
var _opening_stamina_bonus_pending: int = 0
var _dampener_used_this_game: bool = false
var _mental_coach_used_this_game: bool = false
var _boss_changeover_used_this_game: bool = false
var _next_point_player_momentum: int = 0
var _next_point_enemy_momentum: int = 0
var _pressure_cooker_used_this_point: bool = false
var _first_strike_available: bool = true
var _power_first_strike_used_this_point: bool = false
var _power_plus_one_ready: bool = false
var _power_plus_one_active_for_card: bool = false
var _potion_used_this_turn: bool = false
var _turn_potion_accuracy_bonus: float = 0.0
var _turn_potion_extra_spin: int = 0
var _turn_potion_topspin_pressure_bonus: int = 0
var _turn_potion_slice_pressure_bonus: int = 0
var _turn_potion_power_pressure_bonus: int = 0
var _turn_potion_signature_pressure_bonus: int = 0
var _active_string_name: String = ""
var _active_string_type: String = ""
var _active_string_modifiers: Dictionary = {}
var _active_racquet_name: String = ""
var _active_racquet_type: String = ""
var _active_racquet_modifiers: Dictionary = {}
var _last_point_summary: String = ""
var _last_pressure_event: String = ""
var _recent_events: Array = []
var _event_listeners: Array[Callable] = []
var _starting_deck_size: int = 0

func _init(class_def, encounter_enemy_def, deck_card_ids: PackedStringArray, starting_condition: int, encounter_category: String, seed: int, encounter_relic_ids: PackedStringArray = PackedStringArray(), match_context: Dictionary = {}) -> void:
	player_class = class_def
	enemy_def = encounter_enemy_def
	relic_ids = encounter_relic_ids.duplicate()
	potion_ids = PackedStringArray(match_context.get("potion_ids", PackedStringArray())).duplicate()
	encounter_type = encounter_category
	major_name = String(match_context.get("major_name", "Major"))
	surface_key = String(match_context.get("surface_key", "hardcourt"))
	surface_name = String(match_context.get("surface_name", "Hardcourt"))
	racquet_tuning_level = maxi(0, int(match_context.get("racquet_tuning_level", 0)))
	var final_rule: Dictionary = Dictionary(match_context.get("final_rule", {}))
	final_rule_id = String(final_rule.get("id", ""))
	final_rule_name = String(final_rule.get("name", ""))
	final_rule_description = String(final_rule.get("description", ""))
	_rng.seed = seed
	_configure_match_format()
	_configure_rally_target()
	tennis_score = TennisScoreScript.new(no_ad)
	# Base loss is 2 + act (was 3 + act — further reduction; Act 2 = 4/pt, Act 3 = 5/pt, Act 4 = 6/pt before class modifier)
	point_condition_loss = 2 + int(enemy_def.act)
	if encounter_type == "elite":
		point_condition_loss += 2
	elif encounter_type == "boss":
		# Boss = named seeded opponent, elite-level challenge (+3 not +4)
		point_condition_loss += 3
	if player_class.id == &"novice":
		point_condition_loss = maxi(2, point_condition_loss - 2)
	elif player_class.id == &"pusher":
		point_condition_loss = maxi(2, point_condition_loss - 2)
	elif player_class.id == &"power":
		point_condition_loss = maxi(2, point_condition_loss - 5)
	elif player_class.id == &"all_arounder":
		point_condition_loss = maxi(2, point_condition_loss - 3)
	elif player_class.id == &"baseliner":
		point_condition_loss = maxi(2, point_condition_loss - 3)
	elif player_class.id == &"serve_and_volley":
		point_condition_loss = maxi(2, point_condition_loss - 2)
	elif player_class.id == &"master":
		point_condition_loss = maxi(2, point_condition_loss - 2)
	elif player_class.id == &"alcaraz":
		point_condition_loss = maxi(2, point_condition_loss - 5)
	elif player_class.id == &"slicer":
		point_condition_loss = maxi(2, point_condition_loss - 3)

	player = CombatActorStateScript.new(
		player_class.name,
		int(player_class.base_stats.get("endurance", 70)),
		starting_condition,
		int(player_class.base_stats.get("stamina", 3)) + _relic_bonus("max_stamina_bonus"),
		player_class.base_stats
	)
	enemy = CombatActorStateScript.new(
		enemy_def.name,
		maxi(30, enemy_def.max_health),
		maxi(30, enemy_def.max_health),
		_calculate_enemy_max_stamina(),
		_calculate_enemy_stats()
	)
	_reset_hand_slots()
	_starting_deck_size = deck_card_ids.size()
	_player_deck = DeckStateScript.new(deck_card_ids)
	_player_deck.call("shuffle", _rng)
	var opening_serve_bias := 0.5
	if player_class.id == &"serve_and_volley":
		opening_serve_bias = 1.0
	elif player_class.id == &"power":
		opening_serve_bias = 0.85
	elif player_class.id == &"alcaraz":
		opening_serve_bias = 0.72
	elif player_class.id == &"baseliner":
		opening_serve_bias = 0.62
	elif player_class.id == &"master":
		opening_serve_bias = 0.60
	elif player_class.id == &"all_arounder":
		opening_serve_bias = 0.60
	elif player_class.id == &"pusher" or player_class.id == &"slicer":
		opening_serve_bias = 0.55
	current_server = "player" if _has_relic("lucky_coin_toss") or _rng.randf() < opening_serve_bias else "enemy"
	_log_line(enemy_def.name + " steps onto the " + surface_name + ". Format: " + match_label + ".")
	_log_line("Point target set to %d rally pressure." % rally_pressure_target)
	_emit_event("match_initialized", {
		"surface": surface_name,
		"format": match_label,
		"encounter_type": encounter_type,
		"rally_target": rally_pressure_target,
	})
	if encounter_type == "boss" and final_rule_name != "":
		_log_line("Championship twist active: " + final_rule_name + ".")
	_start_new_point()

func start_new_point() -> void:
	_start_new_point()

func resolve_point_if_over() -> bool:
	return _check_point_or_match_resolution()

func add_event_listener(listener: Callable) -> void:
	if listener.is_null():
		return
	for existing_listener in _event_listeners:
		if existing_listener == listener:
			return
	_event_listeners.append(listener)

func remove_event_listener(listener: Callable) -> void:
	if listener.is_null():
		return
	for index in range(_event_listeners.size() - 1, -1, -1):
		if _event_listeners[index] == listener:
			_event_listeners.remove_at(index)

func play_card(hand_index: int) -> bool:
	_ensure_hand_slots_consistent()
	if state != "player_turn":
		return false
	if hand_index < 0 or hand_index >= hand.size():
		return false

	var slot_id := _slot_id_for_hand_index(hand_index)
	if slot_id == "":
		return false
	var card_instance = hand[hand_index]
	var card_def = _card_database.call("get_card", card_instance.card_id)
	if card_def == null:
		return false
	var play_error := _validate_card_play(card_def, true, slot_id)
	if play_error != "":
		_log_line(play_error)
		return false

	var novice_free_skill_triggered: bool = player_class.id == &"novice" and not _novice_free_skill_used_this_turn and card_def.tags.has("skill")
	var power_plus_one_active := _power_plus_one_available(card_def)
	var cost := get_card_cost(card_instance)
	if cost > player.current_stamina:
		_log_line("Not enough stamina for " + card_def.name + ".")
		return false

	_set_hand_slot(slot_id, null)
	player.current_stamina -= cost
	if novice_free_skill_triggered:
		_novice_free_skill_used_this_turn = true
	if card_def.tags.has("net") and _next_net_cost_free:
		_next_net_cost_free = false
		_next_net_bonus_accuracy = 0.0
	var was_retained := bool(card_instance.retained)
	card_instance.retained = false
	var shot_cards_before := _shot_cards_played_this_turn
	var rally_cards_before := _rally_cards_played_this_turn
	var footwork_cards_before := _footwork_cards_played_this_turn
	_cards_played_this_turn += 1
	if card_def.tags.has("serve"):
		_serve_used_this_turn = true
	_log_line("Player plays " + card_def.name + ".")
	_emit_event("card_played", {
		"card_id": String(card_def.id),
		"name": card_def.name,
		"slot_id": slot_id,
		"cost": cost,
		"category": card_def.category,
		"shot_family": card_def.shot_family,
	}, "player")

	_power_plus_one_active_for_card = power_plus_one_active
	_apply_player_passives_before_card(card_def, was_retained, novice_free_skill_triggered)
	_apply_card_effects(player, enemy, card_def, true, shot_cards_before, footwork_cards_before)
	_power_plus_one_active_for_card = false
	if power_plus_one_active:
		_power_plus_one_ready = false
		_log_line("Explosive Contact cashes in the serve-plus-one pattern.")

	if card_def.tags.has("rally") and player_class.id == &"baseliner" and rally_cards_before + 1 == 2:
		_next_topspin_bonus = 6
		_next_topspin_accuracy_bonus = 0.06
	if _has_relic("headband") and _cards_played_this_turn == 3:
		player.add_status("focus", maxi(1, _relic_bonus("focus_after_three_cards")))
		_log_line("Headband rewards the long combo with Focus.")

	if player_class.id == &"power" and player.current_stamina == 0:
		player.add_status("next_turn_momentum", 1)

	if bool(card_def.effects.get("exhaust", false)):
		_store_played_card_instance(card_instance, true)
	else:
		_store_played_card_instance(card_instance, false)

	if _check_point_or_match_resolution():
		return true

	_refresh_enemy_intent_preview()

	return true

func end_player_turn() -> void:
	if state != "player_turn":
		return
	_resolve_pending_special_boss_debuff()
	_prepare_retained_cards()
	_execute_enemy_turn()

func get_hand_display() -> Array[Dictionary]:
	_ensure_hand_slots_consistent()
	var cards: Array[Dictionary] = []
	for hand_index in range(hand.size()):
		var slot_id := _slot_id_for_hand_index(hand_index)
		var entry := _build_hand_entry(hand[hand_index], slot_id, hand_index)
		if not entry.is_empty():
			cards.append(entry)
	return cards

func get_hand_slot_display() -> Array[Dictionary]:
	_ensure_hand_slots_consistent()
	var cards: Array[Dictionary] = []
	var hand_index := 0
	for slot_id in HAND_SLOT_ORDER:
		var card_instance = _get_hand_slot(slot_id)
		if card_instance == null:
			cards.append(_build_empty_slot_entry(slot_id))
			continue
		var entry := _build_hand_entry(card_instance, slot_id, hand_index)
		if not entry.is_empty():
			cards.append(entry)
		hand_index += 1
	return cards

func get_potion_display() -> Array[Dictionary]:
	var display: Array[Dictionary] = []
	for index in range(potion_ids.size()):
		var potion_id := String(potion_ids[index])
		var potion = _potion_database.call("get_potion", StringName(potion_id))
		if potion == null:
			continue
		display.append({
			"inventory_index": index,
			"potion_id": potion_id,
			"name": potion.name,
			"description": potion.description,
			"rarity": potion.rarity,
			"icon_kind": potion.icon_kind,
			"usable": state == "player_turn" and not _potion_used_this_turn,
		})
	return display

func use_potion(potion_index: int) -> bool:
	if state != "player_turn" or _potion_used_this_turn:
		return false
	if potion_index < 0 or potion_index >= potion_ids.size():
		return false
	var potion_id := String(potion_ids[potion_index])
	var potion = _potion_database.call("get_potion", StringName(potion_id))
	if potion == null:
		return false
	var effects := Dictionary(potion.effects)
	if effects.has("stamina_now"):
		player.current_stamina = mini(player.max_stamina, player.current_stamina + int(effects.get("stamina_now", 0)))
	if effects.has("next_turn_stamina"):
		player.add_status("next_turn_stamina", int(effects.get("next_turn_stamina", 0)))
	if effects.has("focus"):
		player.add_status("focus", int(effects.get("focus", 0)))
	if effects.has("momentum"):
		player.add_status("momentum", int(effects.get("momentum", 0)))
	if effects.has("guard"):
		_gain_guard(player, int(effects.get("guard", 0)), true)
	if effects.has("fatigue_heal"):
		player.set_status("fatigue", maxi(0, player.get_status("fatigue") - int(effects.get("fatigue_heal", 0))))
	_turn_potion_accuracy_bonus += float(effects.get("turn_accuracy_bonus", 0.0))
	_turn_potion_extra_spin += int(effects.get("turn_extra_spin", 0))
	_turn_potion_topspin_pressure_bonus += int(effects.get("turn_topspin_pressure_bonus", 0))
	_turn_potion_slice_pressure_bonus += int(effects.get("turn_slice_pressure_bonus", 0))
	_turn_potion_power_pressure_bonus += int(effects.get("turn_power_pressure_bonus", 0))
	_turn_potion_signature_pressure_bonus += int(effects.get("turn_signature_pressure_bonus", 0))
	potion_ids.remove_at(potion_index)
	_potion_used_this_turn = true
	_log_line("Player uses %s." % potion.name)
	_emit_event("potion_used", {
		"potion_id": String(potion.id),
		"name": potion.name,
	}, "player")
	if encounter_type == "boss":
		_log_line("The potion swings the championship rhythm.")
	_refresh_enemy_intent_preview()
	return true

func _build_hand_entry(card_instance, slot_id: String, hand_index: int) -> Dictionary:
	var card_def = _card_database.call("get_card", card_instance.card_id)
	if card_def == null:
		return {}
	var playability := _card_playability(card_instance)
	var tactical_preview := _build_card_tactical_preview(card_def)
	var block_reason := String(playability.get("block_reason", ""))
	var slot_context := _slot_context_state(slot_id)
	var footer_text := String(tactical_preview.get("footer", ""))
	if block_reason != "":
		footer_text = "Locked: " + block_reason
	return {
		"name": card_def.name,
		"description": _compose_card_display_description(card_def.description, String(tactical_preview.get("summary", ""))),
		"cost": int(playability.get("cost", get_card_cost(card_instance))),
		"retained": bool(card_instance.retained),
		"tags": card_def.tags,
		"playable": bool(playability.get("playable", true)),
		"footer_text": footer_text,
		"tooltip_text": _compose_card_tooltip(card_def.description, String(tactical_preview.get("tooltip", "")), block_reason),
		"slot_id": slot_id,
		"slot_label": String(_card_database.call("get_hand_slot_label", slot_id)),
		"slot_subtitle": String(_card_database.call("get_hand_slot_subtitle", card_def, slot_id)),
		"hand_index": hand_index,
		"display_type": String(_card_database.call("get_hand_slot_label", slot_id)),
		"display_art": String(_card_database.call("get_hand_slot_subtitle", card_def, slot_id)),
		"slot_context": slot_context,
		"context_banner": _slot_context_banner(slot_context),
		"context_hint": _slot_context_hint(slot_context),
		"block_reason": block_reason,
		"wrong_opener": slot_id == "initial_contact" and _is_wrong_initial_contact_card(card_def),
	}

func _build_empty_slot_entry(slot_id: String) -> Dictionary:
	var slot_label := String(_card_database.call("get_hand_slot_label", slot_id))
	var slot_context := _slot_context_state(slot_id)
	var subtitle := _empty_slot_subtitle(slot_id, slot_context)
	var description := "No %s card is currently loaded into this tactical slot." % subtitle.to_lower()
	var footer_text := "Slots replenish at the start of turn and from draw effects."
	var tooltip_text := "Empty %s slot.\n%s" % [slot_label.to_lower(), subtitle]
	if slot_id == "initial_contact":
		match slot_context:
			"serve":
				description = "No legal serve opener is currently loaded into the INITIAL slot."
				footer_text = "Serve/Return required to open point."
				tooltip_text = "Empty initial slot.\nNo legal serve opener available for this point."
			"return":
				description = "No legal return opener is currently loaded into the INITIAL slot."
				footer_text = "Serve/Return required to open point."
				tooltip_text = "Empty initial slot.\nNo legal return opener available for this point."
	return {
		"name": slot_label.capitalize(),
		"description": description,
		"cost": 0,
		"retained": false,
		"tags": PackedStringArray(),
		"playable": false,
		"footer_text": footer_text,
		"tooltip_text": tooltip_text,
		"slot_id": slot_id,
		"slot_label": slot_label,
		"slot_subtitle": subtitle,
		"hand_index": -1,
		"display_title": slot_label.capitalize(),
		"display_type": slot_label,
		"display_art": subtitle,
		"display_icon": _slot_icon_kind(slot_id),
		"slot_context": slot_context,
		"context_banner": _slot_context_banner(slot_context),
		"context_hint": _slot_context_hint(slot_context),
	}

func _empty_slot_subtitle(slot_id: String, slot_context: String = "") -> String:
	match slot_id:
		"initial_contact":
			match slot_context:
				"serve":
					return "Serve opener ready"
				"return":
					return "Return opener ready"
				_:
					return "Point already opened"
		"shot":
			return "Rally shot / finisher"
		"enhancer":
			return "Guard / draw / recovery"
		"modifier":
			return "Strings / frame build"
		"special":
			return "Signature / spike / debuff"
	return "Tactical card"

func _slot_context_state(slot_id: String) -> String:
	if slot_id != "initial_contact":
		return ""
	if rally_state.exchanges > 0:
		return "rally"
	return "serve" if current_server == "player" else "return"

func _slot_context_banner(slot_context: String) -> String:
	match slot_context:
		"serve":
			return "SERVE REQUIRED"
		"return":
			return "RETURN REQUIRED"
		"rally":
			return "RALLY LIVE"
	return ""

func _slot_context_hint(slot_context: String) -> String:
	match slot_context:
		"serve":
			return "Point unopened. Serve required to open point from the INITIAL slot."
		"return":
			return "Point unopened. Return required to open point from the INITIAL slot."
		"rally":
			return "Point opened. Build pressure to the target or force an error to end the point."
	return ""

func _is_wrong_initial_contact_card(card_def) -> bool:
	if card_def == null:
		return false
	if rally_state.exchanges > 0:
		return card_def.tags.has("serve") or card_def.tags.has("return")
	if current_server == "player":
		return card_def.tags.has("return")
	return card_def.tags.has("serve")

func _slot_icon_kind(slot_id: String) -> String:
	match slot_id:
		"initial_contact":
			return "momentum"
		"shot":
			return "ball"
		"enhancer":
			return "focus"
		"modifier":
			return "pressure"
		"special":
			return "trophy"
	return "ball"

func get_enemy_intent_text() -> String:
	if queued_enemy_intent.is_empty():
		return "No telegraph."
	var projection := _format_enemy_intent_projection(queued_enemy_intent)
	var suffix := ""
	if projection != "":
		suffix = " | " + projection
	return _enemy_intent_summary() + suffix

func get_match_summary() -> String:
	var lines := PackedStringArray()
	lines.append("Format: " + match_label)
	lines.append("Surface: " + surface_name)
	if encounter_type == "boss" and final_rule_name != "":
		lines.append("Final Twist: " + final_rule_name)
	if _active_string_name != "":
		lines.append("Strings: " + _active_string_name)
	if _active_racquet_name != "":
		lines.append("Frame Weight: " + _active_racquet_name)
	if racquet_tuning_level > 0:
		lines.append("Racquet Workshop: Lv." + str(racquet_tuning_level))
	if not potion_ids.is_empty():
		lines.append("Potions Ready: " + str(potion_ids.size()))
	if games_to_win > 1:
		lines.append("Games: " + str(player_games_won) + " - " + str(enemy_games_won))
	lines.append("Score: " + tennis_score.display())
	lines.append("Scoreboard: Player %s | Opponent %s" % [tennis_score.player_score_label(), tennis_score.enemy_score_label()])
	lines.append("Server: " + current_server.capitalize())
	lines.append("Rally Pressure: " + str(rally_state.rp) + " / " + str(rally_pressure_target))
	lines.append("Ball State: " + rally_state.ball_state)
	lines.append("Ball Lane: " + rally_state.ball_lane)
	lines.append("Ball Position: x=%.2f depth=%s" % [rally_state.ball_x, rally_state.ball_depth])
	lines.append("Court Sides: Player=%s | Opponent=%s" % [rally_state.player_court_side, rally_state.enemy_court_side])
	lines.append("Point: " + str(point_number))
	return "\n".join(lines)

func get_player_summary() -> String:
	return _actor_summary(player, true)

func get_enemy_summary() -> String:
	return _actor_summary(enemy, false)

func get_log_text() -> String:
	return "\n".join(log_lines)

func get_recent_events(limit: int = 20) -> Array[Dictionary]:
	var start_index := maxi(0, _recent_events.size() - limit)
	var output: Array[Dictionary] = []
	for index in range(start_index, _recent_events.size()):
		var event = _recent_events[index]
		if event == null:
			continue
		output.append(event.to_dictionary())
	return output

func get_battle_presentation() -> Dictionary:
	return {
		"match_label": match_label,
		"major_name": major_name,
		"surface_key": surface_key,
		"surface_name": surface_name,
		"final_rule_name": final_rule_name,
		"player_class_id": player_class.id,
		"enemy_id": enemy_def.id,
		"enemy_style": enemy_def.style,
		"enemy_keywords": enemy_def.keywords,
		"enemy_category": enemy_def.category,
		"enemy_act": enemy_def.act,
		"games_score": "%d-%d" % [player_games_won, enemy_games_won],
		"score": tennis_score.display(),
		"score_player": tennis_score.player_score_label(),
		"score_enemy": tennis_score.enemy_score_label(),
		"score_status": tennis_score.score_status_label(),
		"server": current_server,
		"initial_contact_context": _slot_context_state("initial_contact"),
		"initial_contact_banner": _slot_context_banner(_slot_context_state("initial_contact")),
		"initial_contact_hint": _slot_context_hint(_slot_context_state("initial_contact")),
		"point_number": point_number,
		"turn_number": turn_number,
		"state": state,
		"encounter_type": encounter_type,
		"rally_pressure": rally_state.rp,
		"rally_pressure_max": rally_pressure_target,
		"ball_state": rally_state.ball_state,
		"ball_lane": rally_state.ball_lane,
		"ball_x": rally_state.ball_x,
		"ball_depth": rally_state.ball_depth,
		"rally_exchanges": rally_state.exchanges,
		"player_position": rally_state.player_position,
		"enemy_position": rally_state.enemy_position,
		"player_court_side": rally_state.player_court_side,
		"enemy_court_side": rally_state.enemy_court_side,
		"open_court_x": rally_state.open_court_x(true),
		"last_shot_family": rally_state.last_shot_family,
		"last_shot_lane": rally_state.last_shot_lane,
		"last_shot_name": rally_state.last_shot_name,
		"tactical_read": _build_tactical_read(),
		"last_point_summary": _last_point_summary,
		"last_pressure_event": _last_pressure_event,
		"potions": get_potion_display(),
		"player": _build_actor_presentation(player, true),
		"enemy": _build_actor_presentation(enemy, false),
		"enemy_intent_summary": _enemy_intent_summary(),
		"enemy_ai_state": _enemy_ai_state(),
		"enemy_intent": get_enemy_intent_text(),
		"enemy_intent_detail": _build_enemy_intent_detail(queued_enemy_intent),
		"enemy_intent_projection_data": _enemy_intent_projection(queued_enemy_intent),
		"enemy_intent_projection": _format_enemy_intent_projection(queued_enemy_intent),
		"recent_events": get_recent_events(),
	}

func get_round_equipment_bonus() -> Dictionary:
	var bonus := {
		"bitcoin_bonus": 0,
		"condition_bonus": 0,
		"extra_card_choices": 0,
		"notes": PackedStringArray(),
	}
	match _active_string_type:
		"Polyester":
			bonus["bitcoin_bonus"] = int(bonus.get("bitcoin_bonus", 0)) + 4
			_add_round_bonus_note(bonus, "Polyester bite drew extra sponsor heat: +4 BTC.")
		"Natural Gut":
			bonus["condition_bonus"] = int(bonus.get("condition_bonus", 0)) + 5
			_add_round_bonus_note(bonus, "Natural Gut softened the arm after the match: +5 Condition.")
		"Multifilament":
			bonus["extra_card_choices"] = int(bonus.get("extra_card_choices", 0)) + 1
			bonus["condition_bonus"] = int(bonus.get("condition_bonus", 0)) + 2
			_add_round_bonus_note(bonus, "Multifilament comfort opens an extra card look and restores 2 Condition.")
		"Synthetic Gut":
			bonus["bitcoin_bonus"] = int(bonus.get("bitcoin_bonus", 0)) + 2
			bonus["condition_bonus"] = int(bonus.get("condition_bonus", 0)) + 2
			_add_round_bonus_note(bonus, "Synthetic Gut stayed balanced through the round: +2 BTC and +2 Condition.")
		"Hybrid":
			bonus["extra_card_choices"] = int(bonus.get("extra_card_choices", 0)) + 1
			_add_round_bonus_note(bonus, "Hybrid feel opens one extra reward option.")
		"Kevlar":
			bonus["bitcoin_bonus"] = int(bonus.get("bitcoin_bonus", 0)) + 5
			_add_round_bonus_note(bonus, "Kevlar brutality boosted the purse: +5 BTC.")
	match _active_racquet_type:
		"Lead Tape 12":
			bonus["bitcoin_bonus"] = int(bonus.get("bitcoin_bonus", 0)) + 5
			_add_round_bonus_note(bonus, "Top-loaded pace impressed the crowd: +5 BTC.")
		"Lead Tape 3 and 9":
			bonus["condition_bonus"] = int(bonus.get("condition_bonus", 0)) + 3
			_add_round_bonus_note(bonus, "Side-balanced stability saves 3 Condition between rounds.")
		"Pro Stock":
			bonus["bitcoin_bonus"] = int(bonus.get("bitcoin_bonus", 0)) + 10
			_add_round_bonus_note(bonus, "The pro stock frame is expensive, but it pays back with +10 BTC.")
		"Head-Light Control":
			bonus["condition_bonus"] = int(bonus.get("condition_bonus", 0)) + 4
			_add_round_bonus_note(bonus, "Head-light control keeps the body fresh: +4 Condition.")
		"Extra-Long Lever":
			bonus["bitcoin_bonus"] = int(bonus.get("bitcoin_bonus", 0)) + 8
			_add_round_bonus_note(bonus, "The extra-long frame drew premium attention: +8 BTC.")
		"Counterweighted Handle":
			bonus["condition_bonus"] = int(bonus.get("condition_bonus", 0)) + 4
			_add_round_bonus_note(bonus, "Counterweight balance steadies recovery: +4 Condition.")
	return bonus

func get_equipment_loadout() -> Dictionary:
	return {
		"string": _build_equipment_entry(
			"STRING",
			"Factory Bed",
			"No string modifier equipped",
			"Play a string card to tune spin, touch, or recovery for the rest of the match.",
			_active_string_name,
			_active_string_type,
			_equipment_modifier_phrases(_active_string_modifiers, true)
		),
		"racquet": _build_equipment_entry(
			"FRAME",
			"Stock Frame",
			"No racquet modifier equipped",
			"Play a racquet-weight card to trade stability and power for faster endurance loss on missed points.",
			_active_racquet_name,
			_active_racquet_type,
			_equipment_modifier_phrases(_active_racquet_modifiers, false)
		),
	}

func get_return_relic_badges() -> Array[Dictionary]:
	var badges: Array[Dictionary] = []
	if _has_relic("serve_scout_notes"):
		var focus_bonus := maxi(0, _relic_bonus("return_point_focus"))
		var guard_bonus := maxi(0, _relic_bonus("return_point_guard"))
		badges.append({
			"slot": "RETURN RELIC",
			"name": "Serve Scout Notes",
			"summary": "Return points start with Focus +%d and Guard +%d." % [focus_bonus, guard_bonus],
			"details": "When the opponent serves, the point opens with a cleaner read. You gain Focus +%d and Guard +%d before drawing." % [focus_bonus, guard_bonus],
			"icon_kind": "focus",
		})
	if _has_relic("return_coach"):
		var pressure_bonus := maxi(0, _relic_bonus("return_pressure_bonus"))
		var accuracy_bonus := maxi(0.0, _relic_float_bonus("return_accuracy_bonus"))
		badges.append({
			"slot": "RETURN RELIC",
			"name": "Return Coach",
			"summary": "Return cards gain %s pressure and %s accuracy." % [_signed_int_text(pressure_bonus), _signed_percent_text(accuracy_bonus)],
			"details": "Return cards hit harder and cleaner on serve points. Live bonus: %s pressure and %s accuracy." % [_signed_int_text(pressure_bonus), _signed_percent_text(accuracy_bonus)],
			"icon_kind": "momentum",
		})
	if _has_relic("chip_charge_playbook"):
		var guard_bonus := maxi(0, _relic_bonus("return_guard_bonus"))
		var momentum_bonus := maxi(0, _relic_bonus("return_momentum_bonus"))
		badges.append({
			"slot": "RETURN RELIC",
			"name": "Chip-Charge Playbook",
			"summary": "After return cards: Guard +%d, Momentum +%d." % [guard_bonus, momentum_bonus],
			"details": "Once a return card lands, the playbook converts it into court position. You gain Guard +%d and Momentum +%d for the next strike." % [guard_bonus, momentum_bonus],
			"icon_kind": "guard",
		})
	return badges

func _configure_match_format() -> void:
	match encounter_type:
		"elite":
			match_label = "No-Ad Game"
			games_to_win = 1
			no_ad = true
		"boss":
			match_label = "Best of 3 Games"
			games_to_win = 2
			no_ad = false
			if final_rule_id == "no_ad_final":
				match_label = "Best of 3 Games (No-Ad Final)"
				no_ad = true
		_:
			match_label = "Standard Game"
			games_to_win = 1
			no_ad = false

func _configure_rally_target() -> void:
	var target := 42 + maxi(0, int(enemy_def.act) - 1) * 8
	match encounter_type:
		"elite":
			target += 10
		"boss":
			target += 18
		_:
			pass
	if player_class != null:
		match player_class.id:
			&"novice":
				target -= 9
			&"pusher":
				target -= 4
			&"slicer":
				target -= 4
			&"power":
				target -= 7
			&"all_arounder":
				target -= 2
			&"baseliner":
				target -= 5
			&"serve_and_volley":
				target -= 1
			&"master":
				target -= 5
			&"alcaraz":
				target -= 8
	rally_pressure_target = clampi(target, 34, RallyStateScript.RP_MAX)

func _calculate_enemy_max_stamina() -> int:
	var stamina := 2 + int(enemy_def.act)
	if enemy_def.category == "elite":
		stamina += 1
	elif enemy_def.category == "boss":
		stamina += 2
	return stamina

func _calculate_enemy_stats() -> Dictionary:
	var stats := {
		"strength": 2 + int(enemy_def.act) + (2 if enemy_def.category == "boss" else 1 if enemy_def.category == "elite" else 0),
		"control": 2 + int(enemy_def.act) + (1 if enemy_def.style.findn("Human") >= 0 else 0),
		"footwork": 2 + int(enemy_def.act),
		"focus": 1 + (1 if enemy_def.category == "boss" else 0),
	}
	if enemy_def.keywords.has("net"):
		stats["footwork"] = int(stats["footwork"]) + 1
	if enemy_def.keywords.has("spin"):
		stats["control"] = int(stats["control"]) + 1
	if enemy_def.keywords.has("strength"):
		stats["strength"] = int(stats["strength"]) + 1
	return stats

func _start_new_point() -> void:
	if state == "won" or state == "lost":
		return
	point_number += 1
	turn_number = 0
	_pressure_cooker_used_this_point = false
	_first_strike_available = true
	_power_first_strike_used_this_point = false
	_power_plus_one_ready = false
	_point_is_opening_of_game = tennis_score.player_points == 0 and tennis_score.enemy_points == 0
	rally_state.reset(current_server, rally_pressure_target)
	_clear_hand_between_points()
	_clear_point_only_statuses(player)
	_clear_point_only_statuses(enemy)
	_decay_between_points(player)
	_decay_between_points(enemy)
	_apply_surface_point_start()
	_apply_final_rule_point_start()
	player.refill_stamina()
	enemy.refill_stamina()
	# Note: player.guard and enemy.guard are NOT zeroed here. Guard is zeroed at the start
	# of each actor's turn in _begin_player_turn / _execute_enemy_turn. Any code that runs
	# between _start_new_point and _begin_player_turn (e.g. _apply_surface_point_start)
	# may observe stale guard values from the previous point.
	_log_line("Point " + str(point_number) + " begins. Server: " + current_server.capitalize() + ". First side to %d pressure takes it." % rally_pressure_target)
	_emit_event("point_started", {
		"server": current_server,
		"rally_target": rally_pressure_target,
		"surface": surface_name,
	})
	_begin_player_turn()

func _begin_player_turn() -> void:
	if state == "won" or state == "lost":
		return
	turn_number += 1
	state = "player_turn"
	_novice_free_skill_used_this_turn = false
	player.guard = 0
	player.refill_stamina()
	player.current_stamina = mini(player.max_stamina, player.current_stamina + player.consume_status("next_turn_stamina"))
	player.add_status("momentum", player.consume_status("next_turn_momentum"))
	if turn_number == 1 and _point_is_opening_of_game:
		player.current_stamina += _relic_bonus("opening_point_stamina")
	if turn_number == 1 and _opening_stamina_bonus_pending > 0:
		player.current_stamina += _opening_stamina_bonus_pending
		_opening_stamina_bonus_pending = 0
	if turn_number == 1 and _has_relic("split_step_timer"):
		_gain_guard(player, maxi(1, _relic_bonus("opening_guard")), true)
	if turn_number == 1 and _is_player_return_point():
		var return_focus := maxi(0, _relic_bonus("return_point_focus"))
		var return_guard := maxi(0, _relic_bonus("return_point_guard"))
		if return_focus > 0:
			player.add_status("focus", return_focus)
		if return_guard > 0:
			_gain_guard(player, return_guard, true)
		if return_focus > 0 or return_guard > 0:
			_log_line("Serve scout notes sharpen the return read.")
	if turn_number == 1 and player_class.id == &"master":
		_gain_guard(player, 2, true)
		_log_line("Court IQ: reading the court before the first shot — 2 Guard.")
	if turn_number == 1 and player_class.id == &"power":
		if current_server == "player":
			player.add_status("focus", 1)
			_gain_guard(player, 2, true)
			_log_line("Explosive Contact sharpens the service-game first strike.")
		elif _is_player_return_point():
			_gain_guard(player, 3, true)
			_log_line("Explosive Contact braces for the return game.")
	if tennis_score.is_deuce() and _has_relic("mental_coach") and not _mental_coach_used_this_game:
		player.add_status("focus", maxi(1, _relic_bonus("deuce_focus")))
		player.add_status("momentum", maxi(1, _relic_bonus("deuce_momentum")))
		_mental_coach_used_this_game = true
		_log_line("Mental Coach settles the deuce nerves.")
	# Log active disruption debuffs so the player is aware each turn
	if player.get_status("tilt") > 0:
		_log_line("Tilt ×" + str(player.get_status("tilt")) + " active — accuracy −" + str(player.get_status("tilt") * 5) + "% this turn.")
	if player.get_status("cost_up") > 0:
		_log_line("Cost spike ×" + str(player.get_status("cost_up")) + " — all cards cost +" + str(player.get_status("cost_up")) + " Stamina.")
	if player.get_status("position_lock") > 0:
		_log_line("Position locked — court geometry and positional bonuses suspended.")
	_reset_turn_trackers()
	var opening_draw_bonus := _relic_bonus("opening_draw") if turn_number == 1 else 0
	if turn_number == 1 and player_class.id == &"power" and current_server == "player":
		opening_draw_bonus += 1
	_draw_cards(maxi(0, _count_empty_hand_slots()) + mini(2, player.get_status("focus")) + opening_draw_bonus)
	# Clutter: a deck over 24 cards scrambles setup — one random opening-hand card is discarded
	if turn_number == 1 and _starting_deck_size > 24:
		_apply_clutter_discard()
	_emit_event("turn_started", {
		"side": "player",
		"stamina": player.current_stamina,
		"position": rally_state.player_position,
		"ball_state": rally_state.ball_state,
	}, "player")
	_refresh_enemy_intent_preview()

func _execute_enemy_turn() -> void:
	if state == "won" or state == "lost":
		return
	state = "enemy_turn"
	enemy.guard = 0
	enemy.refill_stamina()
	enemy.current_stamina = mini(enemy.max_stamina, enemy.current_stamina + enemy.consume_status("next_turn_stamina"))
	enemy.add_status("momentum", enemy.consume_status("next_turn_momentum"))
	_emit_event("turn_started", {
		"side": "enemy",
		"stamina": enemy.current_stamina,
		"position": rally_state.enemy_position,
		"ball_state": rally_state.ball_state,
	}, "enemy")
	if _boss_should_take_changeover():
		_resolve_boss_changeover()
		if _check_point_or_match_resolution():
			return
		_begin_player_turn()
		return
	if encounter_type == "boss" and rally_state.exchanges > 0:
		var drift := 4 + enemy_games_won * 2
		rally_state.apply_pressure("enemy", drift)
		_log_line(enemy.display_name + " imposes championship pressure (+" + str(drift) + ").")
		if _check_point_or_match_resolution():
			return

	# Disruption play: elite/boss enemies (and deep rallies) can forgo a normal shot to
	# inflict a persistent tactical debuff — fatigue ramp, cost spike, or position lock.
	if _should_enemy_disrupt():
		_execute_enemy_disruption_play()
		if _check_point_or_match_resolution():
			return
		_begin_player_turn()
		return

	queued_enemy_intent = _choose_enemy_intent()
	_log_line(enemy.display_name + " telegraphed " + _describe_intent(queued_enemy_intent) + ".")
	_resolve_enemy_intent(queued_enemy_intent)
	queued_enemy_intent = {}

	if _check_point_or_match_resolution():
		return

	_begin_player_turn()

func _resolve_enemy_intent(intent: Dictionary) -> void:
	var hits := maxi(1, int(intent.get("hits", 1)))
	var intent_landed := false
	if intent.has("guard"):
		enemy.guard += int(intent.get("guard", 0))
	if intent.has("momentum"):
		enemy.add_status("momentum", int(intent.get("momentum", 0)))
	if intent.has("thorns"):
		enemy.add_status("thorns", int(intent.get("thorns", 0)))
	if intent.has("heal"):
		enemy.restore_condition(int(intent.get("heal", 0)))
	for _index in range(hits):
		var pressure_delta := _intent_pressure(intent)
		if pressure_delta > 0:
			if encounter_type == "boss" and final_rule_id == "first_strike" and _first_strike_available:
				pressure_delta += 8
				_first_strike_available = false
				_log_line("First Strike detonates on the opening clean shot of the point.")
			if _intent_accuracy(intent) < _rng.randf():
				rally_state.force_error("enemy", enemy.display_name + " sprayed the ball wide.")
				return
			_apply_pressure_to_rally(false, pressure_delta)
			_apply_statuses_from_dictionary(enemy, player, intent, false)
			intent_landed = true
			if rally_state.is_point_over():
				return
	if intent.has("self_vulnerable"):
		enemy.add_status("pressure", int(intent.get("self_vulnerable", 0)))
	if intent.has("pressure") and not intent.has("damage"):
		player.add_status("pressure", int(intent.get("pressure", 0)))
	if intent.has("fatigue") and not intent.has("damage"):
		player.add_status("fatigue", int(intent.get("fatigue", 0)))
	if intent.has("open_court") and not intent.has("damage"):
		player.add_status("open_court", int(intent.get("open_court", 0)))
	if intent.has("cost_up") and not intent.has("damage"):
		var cu := int(intent.get("cost_up", 0))
		if cu > 0:
			player.add_status("cost_up", cu)
			_log_line(enemy.display_name + " dominates — your cards cost +" + str(cu) + " Stamina.")
	if intent.has("position_lock") and not intent.has("damage"):
		var pl := int(intent.get("position_lock", 0))
		if pl > 0:
			player.add_status("position_lock", pl)
			_log_line(enemy.display_name + " commands the court — your position bonuses are locked.")
	if intent.has("tilt") and not intent.has("damage"):
		var tl := int(intent.get("tilt", 0))
		if tl > 0:
			player.add_status("tilt", tl)
			_log_line(enemy.display_name + " rattles your rhythm — Tilt ×" + str(tl) + " applied.")
	if intent_landed or intent.has("guard") or intent.has("open_court") or intent.has("momentum"):
		_apply_enemy_intent_court_state(intent)

func _intent_pressure(intent: Dictionary) -> int:
	var pressure_delta := int(intent.get("damage", 0))
	pressure_delta += enemy.get_status("momentum") * 4
	pressure_delta += player.get_status("pressure") * 2
	if enemy_def.keywords.has("serve") and current_server == "enemy" and rally_state.exchanges == 0:
		var serve_pattern := _serve_pattern(intent)
		if serve_pattern in ["punish", "jam", "burst"]:
			var support_gap := maxi(0.0, 5.0 - _player_return_support_score())
			pressure_delta += int(round(support_gap))
	if player.get_status("open_court") > 0:
		pressure_delta += player.get_status("open_court") * 4
		player.set_status("open_court", 0)
	if intent.has("bonus_if_player_attacked") and _rally_cards_played_this_turn > 0:
		pressure_delta += int(intent.get("bonus_if_player_attacked", 0))
	if intent.has("bonus_if_player_guard_low") and player.guard <= 4:
		pressure_delta += int(intent.get("bonus_if_player_guard_low", 0))
	pressure_delta += int(enemy.stats.get("strength", 0))
	pressure_delta = maxi(0, pressure_delta - enemy.get_status("fatigue") * 2)
	enemy.set_status("momentum", 0)
	return pressure_delta

func _intent_accuracy(intent: Dictionary) -> float:
	var pressure_delta := float(intent.get("damage", 0))
	var accuracy := 0.84 + float(enemy.stats.get("control", 0)) * 0.02
	accuracy -= maxi(0.0, pressure_delta - 12.0) * 0.01
	accuracy -= float(enemy.get_status("fatigue")) * 0.04
	accuracy -= float(enemy.get_status("tilt")) * 0.05
	return clampf(accuracy, 0.35, 0.98)

func _reset_turn_trackers() -> void:
	_used_tags_this_turn.clear()
	_cards_played_this_turn = 0
	_serve_used_this_turn = false
	_shot_cards_played_this_turn = 0
	_rally_cards_played_this_turn = 0
	_footwork_cards_played_this_turn = 0
	_next_topspin_accuracy_bonus = 0.0
	_first_guard_trigger_used_this_turn = false
	_slice_bonus_used_this_turn = false
	_master_focus_trigger_used_this_turn = false
	_alcaraz_chain_ready = false
	_alcaraz_bonus_used_this_turn = false
	_power_plus_one_active_for_card = false
	_potion_used_this_turn = false
	_turn_potion_accuracy_bonus = 0.0
	_turn_potion_extra_spin = 0
	_turn_potion_topspin_pressure_bonus = 0
	_turn_potion_slice_pressure_bonus = 0
	_turn_potion_power_pressure_bonus = 0
	_turn_potion_signature_pressure_bonus = 0

func _apply_player_passives_before_card(card_def, was_retained: bool, novice_free_skill_triggered: bool = false) -> void:
	if was_retained and player_class.id == &"master" and not _master_focus_trigger_used_this_turn:
		player.add_status("focus", 1)
		_draw_cards(1)
		_gain_guard(player, 3, true)
		_master_focus_trigger_used_this_turn = true
		_log_line("Court IQ turns a retained card into Focus, Guard, and a fresh look.")

	if novice_free_skill_triggered:
		_draw_cards(1)
		player.add_status("focus", 1)
		_gain_guard(player, 1, true)
		_log_line("Fresh Strings smooths out the opening skill, draws 1, and adds 1 Guard.")

	if player_class.id == &"all_arounder":
		var has_new_tag := false
		for tag in card_def.tags:
			if not _used_tags_this_turn.has(String(tag)):
				has_new_tag = true
			_used_tags_this_turn[String(tag)] = true
		if has_new_tag:
			_draw_cards(1)
			if _used_tags_this_turn.size() >= 3:
				player.add_status("focus", 1)
			_log_line("Pattern Read rewards variety with flow and composure.")
	else:
		for tag in card_def.tags:
			_used_tags_this_turn[String(tag)] = true

	if card_def.tags.has("rally"):
		_rally_cards_played_this_turn += 1
	if _is_shot_card(card_def):
		_shot_cards_played_this_turn += 1

	if card_def.tags.has("footwork"):
		_footwork_cards_played_this_turn += 1
		_alcaraz_chain_ready = true

	if card_def.tags.has("signature") and player_class.id == &"alcaraz" and _alcaraz_chain_ready and not _alcaraz_bonus_used_this_turn:
		_draw_cards(1)
		player.add_status("momentum", 1)
		player.add_status("focus", 1)
		_gain_guard(player, 2, true)
		_alcaraz_chain_ready = false
		_alcaraz_bonus_used_this_turn = true
		_log_line("Elastic Attack triggers.")

	if (card_def.tags.has("serve") or card_def.tags.has("return")) and player_class.id == &"serve_and_volley":
		_next_net_cost_free = true
		_next_net_bonus_pressure += 10
		_next_net_bonus_accuracy += 0.10
	if player_class.id == &"power" and (card_def.tags.has("serve") or card_def.tags.has("return")):
		_power_plus_one_ready = true
		_gain_guard(player, 3, true)

func _apply_card_effects(attacker, defender, card_def, attacker_is_player: bool, shot_cards_before: int = 0, footwork_cards_before: int = 0) -> void:
	var effects: Dictionary = card_def.effects
	var is_shot := _is_shot_card(card_def)
	var shot_pressure := 0

	if effects.has("guard"):
		_gain_guard(attacker, int(effects.get("guard", 0)), attacker_is_player)
		if attacker_is_player and card_def.tags.has("footwork") and _has_relic("court_shoes"):
			_gain_guard(attacker, maxi(2, _relic_bonus("footwork_guard_bonus")), true)
	if effects.has("next_turn_stamina"):
		attacker.add_status("next_turn_stamina", int(effects.get("next_turn_stamina", 0)))
	if effects.has("draw") and attacker_is_player:
		_draw_cards(int(effects.get("draw", 0)))
	if effects.has("draw_if_pressured") and attacker_is_player and attacker.get_status("pressure") > 0:
		_draw_cards(int(effects.get("draw_if_pressured", 0)))
	if effects.has("draw_if_returning") and attacker_is_player and _is_player_return_point():
		_draw_cards(int(effects.get("draw_if_returning", 0)))
	if effects.has("combo_draw") and attacker_is_player and shot_cards_before > 0:
		_draw_cards(int(effects.get("combo_draw", 0)))
	if effects.has("heal"):
		var heal_bonus := _string_int_modifier("heal_bonus") if attacker_is_player else 0
		var healed = attacker.restore_condition(int(effects.get("heal", 0)) + attacker.get_status("endurance_scaling") + heal_bonus)
		if healed > 0:
			_log_line(attacker.display_name + " recovers " + str(healed) + " Condition.")
	if effects.has("momentum"):
		attacker.add_status("momentum", int(effects.get("momentum", 0)))
	if effects.has("focus"):
		attacker.add_status("focus", int(effects.get("focus", 0)))
	if effects.has("focus_if_returning") and attacker_is_player and _is_player_return_point():
		attacker.add_status("focus", int(effects.get("focus_if_returning", 0)))
	if effects.has("retain_bonus"):
		attacker.add_status("retain_bonus", int(effects.get("retain_bonus", 0)))
	if effects.has("endurance_scaling"):
		attacker.add_status("endurance_scaling", int(effects.get("endurance_scaling", 0)))
	if attacker_is_player and effects.has("string_type"):
		_equip_string_setup(card_def, effects)
	if attacker_is_player and effects.has("racquet_weight_type"):
		_equip_racquet_setup(card_def, effects)
	# position_lock suspends S&V close-net and serve position bonuses
	if attacker_is_player and player_class.id == &"serve_and_volley" and player.get_status("position_lock") == 0:
		if card_def.tags.has("serve") or card_def.tags.has("return"):
			_gain_guard(attacker, 3, true)
		if card_def.tags.has("net"):
			_gain_guard(attacker, 5, true)
	if effects.has("next_net_bonus_damage"):
		_next_net_bonus_pressure += int(effects.get("next_net_bonus_damage", 0))
	if effects.has("first_footwork_momentum") and footwork_cards_before == 0:
		attacker.add_status("momentum", int(effects.get("first_footwork_momentum", 0)))
	if attacker_is_player and card_def.tags.has("slice") and _has_relic("string_saver"):
		attacker.add_status("focus", maxi(1, _relic_bonus("slice_focus")))

	if effects.has("multi_hit"):
		for hit_pressure in effects.get("multi_hit", PackedInt32Array()):
			_resolve_shot_pressure(attacker, defender, card_def, int(hit_pressure), attacker_is_player)
			if rally_state.is_point_over():
				return
	elif is_shot:
		shot_pressure = int(effects.get("damage", 0))
		_resolve_shot_pressure(attacker, defender, card_def, shot_pressure, attacker_is_player)

	if attacker_is_player and card_def.tags.has("return"):
		var return_guard_bonus := maxi(0, _relic_bonus("return_guard_bonus"))
		var return_momentum_bonus := maxi(0, _relic_bonus("return_momentum_bonus"))
		if return_guard_bonus > 0:
			_gain_guard(attacker, return_guard_bonus, true)
		if return_momentum_bonus > 0:
			attacker.add_status("momentum", return_momentum_bonus)

	if not rally_state.is_point_over():
		_apply_statuses_from_dictionary(attacker, defender, effects, attacker_is_player)

func _resolve_shot_pressure(attacker, defender, card_def, base_pressure: int, attacker_is_player: bool) -> void:
	var accuracy := _card_accuracy(attacker, defender, card_def)
	if _rng.randf() > accuracy:
		rally_state.force_error("player" if attacker_is_player else "enemy", card_def.name + " missed under pressure.")
		return

	var pressure_delta := base_pressure
	pressure_delta += _shot_pattern_pressure_bonus(attacker, defender, card_def, attacker_is_player)
	pressure_delta += int(attacker.stats.get("strength", 0))
	pressure_delta += attacker.get_status("momentum") * 4
	pressure_delta += defender.get_status("pressure") * 2
	if defender.get_status("open_court") > 0:
		pressure_delta += defender.get_status("open_court") * 4
		defender.set_status("open_court", 0)

	# Court geometry bonus: reward attacking the open side created by the previous shot.
	# open_court_x() returns ±1.0 when the defender is displaced to one side. Attacking
	# the opposite side (the vacant side) adds pressure that scales with displacement.
	# position_lock suspends this bonus for the locked actor — they can't read the court.
	var _position_locked := attacker_is_player and player.get_status("position_lock") > 0
	var court_open_x := rally_state.open_court_x(attacker_is_player)
	if absf(court_open_x) >= 0.3 and not _position_locked:
		var lane := _shot_lane(card_def)
		var attacking_open_side := false
		if court_open_x > 0.3:
			# Ad side is open — crosscourt from deuce or DTL from ad exploits it
			attacking_open_side = lane == "Crosscourt" or lane == "Down The Line"
		elif court_open_x < -0.3:
			# Deuce side is open
			attacking_open_side = lane == "Crosscourt" or lane == "Down The Line"
		if attacking_open_side:
			var court_bonus := int(absf(court_open_x) * 8.0)
			pressure_delta += court_bonus
			if OS.is_debug_build() and attacker_is_player:
				print_verbose("[CourtGeo] Attacking open side (%.2f): +%d pressure" % [court_open_x, court_bonus])

	if card_def.effects.has("bonus_vs_guard") and defender.guard > 0:
		pressure_delta += int(card_def.effects.get("bonus_vs_guard", 0))
	if card_def.effects.has("bonus_vs_spin") and defender.get_status("spin") > 0:
		pressure_delta += int(card_def.effects.get("bonus_vs_spin", 0))
	if card_def.tags.has("net") and _next_net_bonus_pressure > 0:
		pressure_delta += _next_net_bonus_pressure
		_next_net_bonus_pressure = 0
	if (card_def.tags.has("topspin") or (player_class.id == &"baseliner" and card_def.id == &"inside_out_forehand")) and _next_topspin_bonus > 0:
		pressure_delta += _next_topspin_bonus
		_next_topspin_bonus = 0
		_next_topspin_accuracy_bonus = 0.0
	if card_def.tags.has("slice") and player_class.id == &"slicer" and not _slice_bonus_used_this_turn and attacker_is_player:
		if _actor_position(not attacker_is_player) in ["ServiceLine", "Net"]:
			defender.add_status("pressure", 1)
		_slice_bonus_used_this_turn = true
	if attacker_is_player and card_def.tags.has("net") and _has_relic("grass_specialist"):
		pressure_delta += _relic_bonus("net_pressure_bonus")
	if attacker_is_player and card_def.tags.has("topspin") and enemy_def.act == 2 and _has_relic("clay_specialist"):
		pressure_delta += _relic_bonus("act_two_topspin_bonus")
	if attacker_is_player and card_def.tags.has("power") and _has_relic("lead_tape"):
		pressure_delta += int(round(float(pressure_delta) * float(_relic_float_bonus("power_pressure_bonus"))))
	if attacker_is_player and card_def.tags.has("signature"):
		pressure_delta += _relic_bonus("signature_pressure_bonus")
	if attacker_is_player and card_def.tags.has("topspin"):
		pressure_delta += _string_int_modifier("topspin_pressure_bonus")
		pressure_delta += _racquet_int_modifier("topspin_pressure_bonus")
		pressure_delta += _turn_potion_topspin_pressure_bonus
	if attacker_is_player and card_def.tags.has("slice"):
		pressure_delta += _string_int_modifier("slice_pressure_bonus")
		pressure_delta += _racquet_int_modifier("slice_pressure_bonus")
		pressure_delta += _turn_potion_slice_pressure_bonus
	if attacker_is_player and card_def.tags.has("serve"):
		pressure_delta += _string_int_modifier("serve_pressure_bonus")
	if attacker_is_player and card_def.tags.has("net"):
		pressure_delta += _string_int_modifier("net_pressure_bonus")
	if attacker_is_player and card_def.tags.has("power"):
		pressure_delta += _string_int_modifier("power_pressure_bonus")
	if attacker_is_player and card_def.tags.has("control"):
		pressure_delta += _racquet_int_modifier("control_pressure_bonus")
	if attacker_is_player and card_def.tags.has("net"):
		pressure_delta += _racquet_int_modifier("net_pressure_bonus")
	if attacker_is_player and card_def.tags.has("serve"):
		pressure_delta += _racquet_int_modifier("serve_pressure_bonus")
	if attacker_is_player and card_def.tags.has("power"):
		pressure_delta += _racquet_int_modifier("power_pressure_bonus")
		pressure_delta += _turn_potion_power_pressure_bonus
	if attacker_is_player and card_def.tags.has("signature"):
		pressure_delta += _turn_potion_signature_pressure_bonus
	if attacker_is_player and player_class.id == &"baseliner":
		if card_def.tags.has("topspin"):
			pressure_delta += 3
		if card_def.id == &"inside_out_forehand":
			pressure_delta += 4
	if attacker_is_player and player_class.id == &"pusher":
		if card_def.tags.has("return") or card_def.tags.has("control"):
			pressure_delta += 2
		if defender.get_status("pressure") > 0:
			pressure_delta += 1
	if attacker_is_player and player_class.id == &"slicer":
		if card_def.tags.has("slice") or card_def.tags.has("drop") or card_def.tags.has("lob"):
			pressure_delta += 2
		if card_def.tags.has("control"):
			pressure_delta += 1
	if attacker_is_player and player_class.id == &"serve_and_volley":
		if card_def.tags.has("serve"):
			pressure_delta += 3
		if card_def.tags.has("net") and _actor_position(attacker_is_player) in ["ServiceLine", "Net"]:
			pressure_delta += 5
	if attacker_is_player and player_class.id == &"power":
		if card_def.tags.has("serve") or card_def.tags.has("power") or card_def.tags.has("return"):
			pressure_delta += 3
	if attacker_is_player and player_class.id == &"master":
		if card_def.tags.has("control") or card_def.tags.has("down_the_line") or card_def.tags.has("return"):
			pressure_delta += 3
	if attacker_is_player and player_class.id == &"alcaraz":
		if card_def.tags.has("signature"):
			pressure_delta += 5
		if card_def.tags.has("net") and _footwork_cards_played_this_turn > 0:
			pressure_delta += 3
		if _footwork_cards_played_this_turn > 0 and card_def.tags.has("signature"):
			pressure_delta += 4
	if attacker_is_player and _power_plus_one_active_for_card and card_def.tags.has("power"):
		pressure_delta += 6
	if attacker_is_player:
		pressure_delta += _enemy_matchup_pressure_bonus(card_def)
	if _power_first_strike_available(card_def, attacker_is_player):
		pressure_delta += 4
	if encounter_type == "boss" and final_rule_id == "first_strike" and _first_strike_available:
		pressure_delta += 8
		_first_strike_available = false
		_log_line("First Strike detonates on the opening clean shot of the point.")
	pressure_delta += _surface_pressure_bonus(card_def)
	if attacker.get_status("fatigue") > 0:
		pressure_delta = maxi(0, pressure_delta - attacker.get_status("fatigue") * 2)
	if OS.is_debug_build() and attacker_is_player:
		# base_pressure is the raw card value before any modifiers. pressure_delta is the
		# final value after class bonuses, relics, equipment, status effects, and fatigue.
		# modifier_total = net effect of everything stacked on top of the card's base damage.
		var modifier_total := pressure_delta - base_pressure
		print_verbose("[ShotDebug] %s | base=%d modifiers=%+d final=%d acc=%.2f fatigue=%d momentum=%d" % [
			card_def.name,
			base_pressure,
			modifier_total,
			pressure_delta,
			accuracy,
			attacker.get_status("fatigue"),
			attacker.get_status("momentum"),
		])
	_apply_pressure_to_rally(attacker_is_player, pressure_delta)
	attacker.set_status("momentum", 0)
	if _power_first_strike_available(card_def, attacker_is_player):
		_power_first_strike_used_this_point = true
		_log_line("Explosive Contact juices the first strike of the point.")
	_update_positions_and_ball_state(card_def, attacker_is_player)
	_apply_tactical_follow_up(attacker, defender, card_def, attacker_is_player)
	rally_state.record_shot(
		"player" if attacker_is_player else "enemy",
		_shot_family(card_def),
		_shot_lane(card_def),
		card_def.name
	)

func _apply_statuses_from_dictionary(attacker, defender, source: Dictionary, attacker_is_player: bool) -> void:
	if source.has("pressure"):
		defender.add_status("pressure", int(source.get("pressure", 0)))
	if source.has("spin"):
		var spin_amount := int(source.get("spin", 0))
		if attacker_is_player and _has_relic("polyester_strings"):
			spin_amount += _relic_bonus("extra_spin")
		if attacker_is_player:
			spin_amount += _string_int_modifier("extra_spin")
			spin_amount += _turn_potion_extra_spin
		defender.add_status("spin", spin_amount)
	if source.has("fatigue"):
		defender.add_status("fatigue", int(source.get("fatigue", 0)))
	if source.has("open_court"):
		defender.add_status("open_court", int(source.get("open_court", 0)))
	# Disruption debuffs — applied to the defender (enemy when player plays, player when enemy plays)
	if source.has("tilt"):
		var tilt_amount := int(source.get("tilt", 0))
		if tilt_amount > 0:
			defender.add_status("tilt", tilt_amount)
			var defender_name := defender.display_name if attacker_is_player else "You"
			_log_line(defender_name + " is tilted — accuracy drops " + str(tilt_amount * 5) + "%.")
	if source.has("position_lock"):
		var lock_amount := int(source.get("position_lock", 0))
		if lock_amount > 0:
			defender.add_status("position_lock", lock_amount)
			var defender_name := defender.display_name if attacker_is_player else "You"
			_log_line(defender_name + " is pushed out of position — court geometry bonuses suspended.")
	if source.has("cost_up"):
		var cost_amount := int(source.get("cost_up", 0))
		if cost_amount > 0:
			defender.add_status("cost_up", cost_amount)
			if not attacker_is_player:
				_log_line("Dominance: your next cards cost +" + str(cost_amount) + " Stamina.")

func _apply_pressure_to_rally(attacker_is_player: bool, pressure_delta: int) -> void:
	var attempted_pressure := maxi(0, pressure_delta)
	var absorbed := mini(enemy.guard if attacker_is_player else player.guard, pressure_delta)
	pressure_delta -= absorbed
	if attacker_is_player:
		enemy.guard = maxi(0, enemy.guard - absorbed)
	else:
		player.guard = maxi(0, player.guard - absorbed)
	var source_name: String = "Player" if attacker_is_player else enemy.display_name
	if attempted_pressure <= 0:
		_last_pressure_event = "%s did not create any rally pressure." % source_name
	elif pressure_delta <= 0:
		_last_pressure_event = "%s's %d pressure was fully absorbed by Guard." % [source_name, attempted_pressure]
	if pressure_delta > 0:
		rally_state.apply_pressure("player" if attacker_is_player else "enemy", pressure_delta)
		var direction := "+" if attacker_is_player else "-"
		var absorption_text := ""
		if absorbed > 0:
			absorption_text = " (%d blocked)" % absorbed
		_last_pressure_event = "%s shifted the rally %s%d.%s" % [
			source_name,
			direction,
			pressure_delta,
			absorption_text,
		]
		if attacker_is_player and enemy.get_status("thorns") > 0:
			var reflected = player.lose_condition(enemy.get_status("thorns"))
			if reflected > 0:
				_log_line("Thorns from " + enemy.display_name + " cost " + str(reflected) + " Condition.")
	_emit_event("pressure_shifted", {
		"source": source_name,
		"attempted": attempted_pressure,
		"blocked": absorbed,
		"applied": maxi(0, pressure_delta),
		"rally_pressure": rally_state.rp,
	}, "player" if attacker_is_player else "enemy")

func _gain_guard(actor, amount: int, actor_is_player: bool) -> void:
	var total = amount + actor.get_status("endurance_scaling")
	if actor_is_player:
		total += _string_int_modifier("guard_bonus")
		total += _racquet_int_modifier("guard_bonus")
	actor.guard += total
	if actor_is_player and player_class.id == &"pusher" and not _first_guard_trigger_used_this_turn:
		enemy.add_status("pressure", 2)
		player.add_status("focus", 1)
		_first_guard_trigger_used_this_turn = true
		_log_line("Attrition Point applies Pressure and sharpens the read.")

func _card_accuracy(attacker, defender, card_def) -> float:
	var accuracy := 0.78 + float(attacker.stats.get("control", 0)) * 0.03
	if attacker == player:
		if player_class.id == &"novice":
			accuracy += 0.04
		if player_class.id == &"all_arounder":
			accuracy += 0.02
		if player_class.id == &"power" and (card_def.tags.has("serve") or card_def.tags.has("return") or card_def.tags.has("power")):
			accuracy += 0.06
		if _power_first_strike_available(card_def, true):
			accuracy += 0.08
		if _power_plus_one_active_for_card and card_def.tags.has("power"):
			accuracy += 0.08
		if card_def.tags.has("net") and _next_net_bonus_accuracy > 0.0:
			accuracy += _next_net_bonus_accuracy
		accuracy += _relic_float_bonus("global_accuracy_bonus")
		accuracy += _string_float_modifier("global_accuracy_bonus")
		if card_def.tags.has("net") and _has_relic("grass_specialist"):
			accuracy += _relic_float_bonus("net_accuracy_bonus")
		if card_def.tags.has("serve") and rally_state.exchanges == 0 and current_server == "player":
			accuracy += _relic_float_bonus("first_serve_accuracy")
		if card_def.tags.has("control"):
			accuracy += _string_float_modifier("control_accuracy_bonus")
		if card_def.tags.has("power"):
			accuracy += _string_float_modifier("power_accuracy_bonus")
			accuracy += _racquet_float_modifier("power_accuracy_bonus")
		if card_def.tags.has("control"):
			accuracy += _racquet_float_modifier("control_accuracy_bonus")
		if (card_def.tags.has("topspin") or (player_class.id == &"baseliner" and card_def.id == &"inside_out_forehand")) and _next_topspin_accuracy_bonus > 0.0:
			accuracy += _next_topspin_accuracy_bonus
		if player_class.id == &"baseliner" and card_def.id == &"inside_out_forehand":
			accuracy += 0.03
		if player_class.id == &"baseliner" and (card_def.tags.has("topspin") or card_def.tags.has("rally")):
			accuracy += 0.02
		if player_class.id == &"baseliner" and (card_def.tags.has("topspin") or card_def.tags.has("rally")):
			accuracy += 0.02
		if player_class.id == &"serve_and_volley" and card_def.tags.has("net") and _actor_position(true) in ["ServiceLine", "Net"]:
			accuracy += 0.06
		if player_class.id == &"pusher" and (card_def.tags.has("control") or card_def.tags.has("return") or card_def.tags.has("recovery")):
			accuracy += 0.04
		if player_class.id == &"slicer" and (card_def.tags.has("slice") or card_def.tags.has("control") or card_def.tags.has("lob") or card_def.tags.has("drop")):
			accuracy += 0.05
		if player_class.id == &"master" and (card_def.tags.has("control") or card_def.tags.has("return") or card_def.tags.has("down_the_line")):
			accuracy += 0.05
		if player_class.id == &"alcaraz" and (card_def.tags.has("signature") or card_def.tags.has("net")):
			accuracy += 0.04
		if player_class.id == &"alcaraz" and _alcaraz_chain_ready and card_def.tags.has("signature"):
			accuracy += 0.08
		accuracy += _turn_potion_accuracy_bonus
		accuracy += _enemy_matchup_accuracy_bonus(card_def)
	accuracy += _surface_accuracy_bonus(card_def)
	accuracy += _shot_pattern_accuracy_bonus(attacker, defender, card_def)
	if card_def.tags.has("control"):
		accuracy += 0.06
	if card_def.tags.has("power"):
		accuracy -= 0.06
		if rally_state.ball_state == "LowBall" and not (attacker == player and _has_relic("titanium_frame")):
			accuracy -= 0.06
	if card_def.tags.has("signature"):
		accuracy -= 0.03
	if card_def.tags.has("net") and attacker_is_at_baseline(attacker):
		accuracy -= 0.10
	if card_def.tags.has("slice") and rally_state.ball_state == "HighBall":
		accuracy -= 0.05
	if card_def.tags.has("topspin") and rally_state.ball_state == "LowBall":
		accuracy -= 0.05
	accuracy -= float(attacker.get_status("fatigue")) * 0.04
	accuracy += float(attacker.get_status("focus")) * 0.01
	# tilt debuff: disorientation penalty (5% per stack) — applied by disruptive shots and enemy rhythm breaks
	accuracy -= float(attacker.get_status("tilt")) * 0.05
	# Court geometry accuracy bonus: hitting into the open side of the court is easier
	# because you have more margin — the opponent is out of position to punish an error.
	# position_lock blocks this: the actor can't read or exploit court geometry.
	if attacker == player and player.get_status("position_lock") == 0:
		var court_open := absf(rally_state.open_court_x(true))
		if court_open >= 0.3:
			var lane := _shot_lane(card_def)
			if lane == "Crosscourt" or lane == "Down The Line":
				accuracy += court_open * 0.05
	elif attacker != player:
		var court_open := absf(rally_state.open_court_x(false))
		if court_open >= 0.3:
			var lane := _shot_lane(card_def)
			if lane == "Crosscourt" or lane == "Down The Line":
				accuracy += court_open * 0.05
	# Depth bonus: blocked when position_lock is active
	if attacker == player and rally_state.ball_depth == "Short" and player.get_status("position_lock") == 0:
		if card_def.tags.has("topspin") or card_def.tags.has("power") or card_def.tags.has("down_the_line"):
			accuracy += 0.04
	return clampf(accuracy, 0.35, 0.98)

func attacker_is_at_baseline(attacker) -> bool:
	if attacker == player:
		return rally_state.player_position == "Baseline"
	return rally_state.enemy_position == "Baseline"

func is_point_unopened() -> bool:
	return rally_state.exchanges == 0 and not rally_state.is_point_over()

func is_player_server() -> bool:
	return current_server == "player"

func is_enemy_server() -> bool:
	return current_server == "enemy"

func _is_player_return_point() -> bool:
	return current_server == "enemy" and rally_state.exchanges == 0

func can_play_card(card_instance) -> Dictionary:
	var card_def = null
	if card_instance != null:
		card_def = _card_database.call("get_card", card_instance.card_id)
	if card_def == null:
		return {
			"ok": false,
			"playable": false,
			"reason": "Card data missing.",
			"block_reason": "Card data missing.",
			"cost": 99,
			"slot_id": "",
		}
	var cost := get_card_cost(card_instance)
	var slot_id := _slot_id_for_card_instance(card_instance)
	var reason := ""
	if state != "player_turn":
		reason = "Wait for your turn."
	else:
		reason = _validate_card_play(card_def, true, slot_id)
		if reason == "" and cost > player.current_stamina:
			reason = "Need %d stamina." % cost
	return {
		"ok": reason == "",
		"playable": reason == "",
		"reason": reason,
		"block_reason": reason,
		"cost": cost,
		"slot_id": slot_id,
		"card_id": String(card_def.id),
	}

func _card_playability(card_instance) -> Dictionary:
	return can_play_card(card_instance)

func _build_card_tactical_preview(card_def) -> Dictionary:
	var pressure_bonus := 0
	var accuracy_bonus := 0.0
	var notes := PackedStringArray()
	var tooltip_notes := PackedStringArray()
	if _is_shot_card(card_def):
		pressure_bonus = _shot_pattern_pressure_bonus(player, enemy, card_def, true)
		accuracy_bonus = _shot_pattern_accuracy_bonus(player, enemy, card_def)
	if card_def.tags.has("down_the_line") and (enemy.get_status("open_court") > 0 or rally_state.last_shot_lane == "Crosscourt"):
		notes.append("Change direction into the open court")
	if card_def.tags.has("drop") and rally_state.enemy_position == "Baseline":
		notes.append("Enemy is deep behind the baseline")
	if card_def.tags.has("volley") and rally_state.player_position in ["ServiceLine", "Net"]:
		notes.append("Forward court position is live")
	if card_def.tags.has("lob") and rally_state.enemy_position in ["ServiceLine", "Net"]:
		notes.append("Enemy has crowded the net")
	if card_def.tags.has("slice") and rally_state.enemy_position in ["ServiceLine", "Net"]:
		notes.append("Low skid at the feet")
	if card_def.tags.has("smash") and rally_state.ball_state == "HighBall":
		notes.append("High ball is sitting up")
	if card_def.tags.has("serve") and current_server == "player" and rally_state.exchanges == 0:
		notes.append("Service point first-strike window")
	if card_def.requires.has("attacker_position_in"):
		var required_positions: PackedStringArray = PackedStringArray(card_def.requires.get("attacker_position_in", PackedStringArray()))
		if required_positions.has(_actor_position(true)):
			notes.append("Court position is set for " + String(card_def.shot_family if card_def.shot_family != "" else "the shot"))
		else:
			notes.append("Needs " + _join_strings(required_positions))
	if card_def.tags.has("return") and _is_player_return_point() and enemy_def.keywords.has("serve"):
		if _player_return_support_score() >= 7.0:
			notes.append("Return package is primed for this server")
		else:
			notes.append("Big serve is testing the return read")
	var matchup_note := _enemy_matchup_note(card_def)
	if matchup_note != "":
		notes.append(matchup_note)
	if notes.is_empty():
		if pressure_bonus > 0:
			notes.append("Shot pattern is favorable")
		elif pressure_bonus < 0 or accuracy_bonus < 0.0:
			notes.append("Shot pattern is awkward from this court state")

	if pressure_bonus != 0:
		tooltip_notes.append("Pressure adj %s" % _signed_int_text(pressure_bonus))
	if not is_zero_approx(accuracy_bonus):
		tooltip_notes.append("Accuracy adj %s" % _signed_percent_text(accuracy_bonus))
	for note in notes:
		tooltip_notes.append(note)

	return {
		"summary": "Court Read: " + " | ".join(notes) if not notes.is_empty() else "",
		"footer": _build_card_tactical_footer(pressure_bonus, accuracy_bonus, notes),
		"tooltip": " | ".join(tooltip_notes),
	}

func _build_card_tactical_footer(pressure_bonus: int, accuracy_bonus: float, notes: PackedStringArray) -> String:
	var parts := PackedStringArray()
	if pressure_bonus != 0:
		parts.append("Pressure %s" % _signed_int_text(pressure_bonus))
	if not is_zero_approx(accuracy_bonus):
		parts.append("Acc %s" % _signed_percent_text(accuracy_bonus))
	if not notes.is_empty():
		parts.append(notes[0])
	return " | ".join(parts)

func _compose_card_display_description(base_description: String, tactical_summary: String) -> String:
	var display_description := _player_facing_rules_text(base_description)
	if tactical_summary == "":
		return display_description
	return "%s\n\n%s" % [display_description, tactical_summary]

func _compose_card_tooltip(base_description: String, tactical_tooltip: String, block_reason: String) -> String:
	var parts := PackedStringArray()
	var display_description := _player_facing_rules_text(base_description)
	if display_description != "":
		parts.append(display_description)
	if tactical_tooltip != "":
		parts.append(tactical_tooltip)
	if block_reason != "":
		parts.append("Play lock: " + block_reason)
	return "\n".join(parts)

func _player_facing_rules_text(text: String) -> String:
	var output := text
	output = output.replace("Deal ", "Create ")
	output = output.replace(" damage", " pressure")
	output = output.replace("Damage", "Pressure")
	output = output.replace("Your next Net card this turn gets +", "Your next Net card this turn gets +")
	output = output.replace("pressure. Can only open a point while serving.", "pressure. Serve required to open the point.")
	output = output.replace("point while serving.", "point while serving.")
	return output

func _validate_card_play(card_def, attacker_is_player: bool, slot_id: String = "") -> String:
	if card_def.tags.has("boss_debuff"):
		return "Boss pressure is clogging the special slot this turn."
	if slot_id != "":
		var roles: PackedStringArray = _card_database.call("get_hand_slot_roles", card_def)
		if not roles.has(slot_id):
			return "Wrong slot for this card."
	return _validate_card_requirements(card_def, attacker_is_player)

func _validate_card_requirements(card_def, attacker_is_player: bool) -> String:
	if not attacker_is_player:
		return ""
	var requirements: Dictionary = Dictionary(card_def.requires)
	if rally_state.exchanges == 0 and not card_def.tags.has("serve") and not card_def.tags.has("return"):
		return "Serve/Return required to open point."
	if bool(requirements.get("must_be_server", false)) and current_server != "player":
		return "Serve/Return required to open point."
	if bool(requirements.get("must_be_receiver", false)) and not _is_player_return_point():
		return "Serve/Return required to open point."
	if bool(requirements.get("point_open_only", false)) and rally_state.exchanges > 0:
		return "Serve/Return required to open point."
	if int(requirements.get("max_uses_per_turn", 0)) == 1 and card_def.tags.has("serve") and _serve_used_this_turn:
		return "Only one serve card can be used each turn."
	if requirements.has("attacker_position_in"):
		var required_positions: PackedStringArray = PackedStringArray(requirements.get("attacker_position_in", PackedStringArray()))
		if not required_positions.has(rally_state.player_position):
			return "%s needs %s positioning." % [card_def.name, _join_strings(required_positions)]
	if requirements.has("enemy_position_in"):
		var enemy_positions: PackedStringArray = PackedStringArray(requirements.get("enemy_position_in", PackedStringArray()))
		if not enemy_positions.has(rally_state.enemy_position):
			return "%s needs the opponent in %s." % [card_def.name, _join_strings(enemy_positions)]
	if requirements.has("ball_state_in"):
		var ball_states: PackedStringArray = PackedStringArray(requirements.get("ball_state_in", PackedStringArray()))
		if not ball_states.has(rally_state.ball_state):
			return "%s needs %s." % [card_def.name, _join_strings(ball_states)]
	return ""

func _shot_pattern_pressure_bonus(attacker, defender, card_def, attacker_is_player: bool) -> int:
	var bonus := 0
	var attacker_position := _actor_position(attacker_is_player)
	var defender_position := _actor_position(not attacker_is_player)
	var same_side_repeat: bool = rally_state.last_shot_side == ("player" if attacker_is_player else "enemy")

	if card_def.tags.has("serve") and rally_state.exchanges == 0:
		bonus += 4
	if card_def.tags.has("return"):
		if attacker_is_player and _is_player_return_point():
			bonus += 6
			bonus += _relic_bonus("return_pressure_bonus")
			if enemy_def.keywords.has("serve"):
				bonus += 2 + mini(4, int(floor(_player_return_support_score() / 2.5)))
		else:
			bonus -= 2
	if card_def.tags.has("crosscourt"):
		bonus += 2
	if card_def.tags.has("down_the_line"):
		if defender.get_status("open_court") > 0 or (same_side_repeat and rally_state.last_shot_lane == "Crosscourt"):
			bonus += 6
		else:
			bonus -= 1
	if card_def.tags.has("drop"):
		if defender_position == "Baseline":
			bonus += 6
		elif defender_position == "Net":
			bonus -= 4
	if card_def.tags.has("volley"):
		if attacker_position in ["ServiceLine", "Net"] or rally_state.ball_state == "AtNet":
			bonus += 5
		elif attacker_position == "Baseline":
			bonus -= 3
	if card_def.tags.has("lob"):
		if defender_position in ["ServiceLine", "Net"] or rally_state.ball_state == "AtNet":
			bonus += 6
		else:
			bonus += 1
	if card_def.tags.has("slice") and defender_position in ["ServiceLine", "Net"]:
		bonus += 4
	if card_def.tags.has("smash"):
		if rally_state.ball_state == "HighBall" or rally_state.last_shot_family == "Lob":
			bonus += 10
		else:
			bonus -= 6
	return bonus

func _power_first_strike_available(card_def, attacker_is_player: bool) -> bool:
	return attacker_is_player and player_class.id == &"power" and not _power_first_strike_used_this_point and (card_def.tags.has("serve") or card_def.tags.has("power") or card_def.tags.has("return"))

func _power_plus_one_available(card_def) -> bool:
	return player_class.id == &"power" and _power_plus_one_ready and card_def.tags.has("power") and _is_shot_card(card_def)

func _shot_pattern_accuracy_bonus(attacker, defender, card_def) -> float:
	var accuracy := 0.0
	var attacker_position := _position_for_actor(attacker)
	var defender_position := _position_for_actor(defender)
	var attacker_side := "player" if attacker == player else "enemy"
	var same_side_repeat: bool = rally_state.last_shot_side == attacker_side

	if card_def.tags.has("serve"):
		if rally_state.exchanges == 0 and ((attacker == player and current_server == "player") or (attacker == enemy and current_server == "enemy")):
			accuracy += 0.08
		else:
			accuracy -= 0.20
	if card_def.tags.has("return"):
		if attacker == player and _is_player_return_point():
			accuracy += 0.08
			accuracy += _relic_float_bonus("return_accuracy_bonus")
			if enemy_def.keywords.has("serve"):
				accuracy += 0.02 + minf(0.06, _player_return_support_score() * 0.008)
		else:
			accuracy -= 0.04
	if card_def.tags.has("crosscourt"):
		accuracy += 0.05
	if card_def.tags.has("down_the_line"):
		accuracy -= 0.07
		if defender.get_status("open_court") > 0 or (same_side_repeat and rally_state.last_shot_lane == "Crosscourt"):
			accuracy += 0.06
	if card_def.tags.has("drop"):
		if defender_position == "Baseline":
			accuracy += 0.06
		elif defender_position == "Net":
			accuracy -= 0.06
	if card_def.tags.has("volley"):
		if attacker_position in ["ServiceLine", "Net"] or rally_state.ball_state == "AtNet":
			accuracy += 0.06
		elif attacker_position == "Baseline":
			accuracy -= 0.08
	if card_def.tags.has("lob"):
		if defender_position in ["ServiceLine", "Net"] or rally_state.ball_state == "AtNet":
			accuracy += 0.06
	if card_def.tags.has("slice") and rally_state.ball_state == "LowBall":
		accuracy += 0.04
	if card_def.tags.has("smash"):
		if rally_state.ball_state == "HighBall" or rally_state.last_shot_family == "Lob":
			accuracy += 0.08
		else:
			accuracy -= 0.12
	return accuracy

func _enemy_matchup_pressure_bonus(card_def) -> int:
	var bonus := 0
	bonus += _keyword_style_pressure(card_def, "return", "return_weak", "return_resist")
	bonus += _keyword_style_pressure(card_def, "serve", "serve_weak", "serve_resist")
	bonus += _keyword_style_pressure(card_def, "power", "power_weak", "power_resist")
	bonus += _keyword_style_pressure(card_def, "topspin", "topspin_weak", "topspin_resist")
	bonus += _keyword_style_pressure(card_def, "slice", "slice_weak", "slice_resist")
	bonus += _keyword_style_pressure(card_def, "net", "net_weak", "net_resist")
	bonus += _keyword_style_pressure(card_def, "volley", "volley_weak", "volley_resist")
	bonus += _keyword_style_pressure(card_def, "lob", "lob_weak", "lob_resist")
	bonus += _keyword_style_pressure(card_def, "smash", "smash_weak", "smash_resist")
	bonus += _keyword_style_pressure(card_def, "down_the_line", "down_the_line_weak", "down_the_line_resist")
	bonus += _keyword_style_pressure(card_def, "drop", "drop_weak", "drop_resist")
	bonus += _keyword_style_pressure(card_def, "control", "control_weak", "control_resist")
	if player_class.id == &"baseliner" and card_def.id == &"inside_out_forehand":
		if enemy_def.keywords.has("forehand_weak"):
			bonus += 4
		if enemy_def.keywords.has("forehand_resist"):
			bonus -= 3
	return bonus

func _enemy_matchup_accuracy_bonus(card_def) -> float:
	var accuracy := 0.0
	accuracy += _keyword_style_accuracy(card_def, "return", "return_weak", "return_resist")
	accuracy += _keyword_style_accuracy(card_def, "serve", "serve_weak", "serve_resist")
	accuracy += _keyword_style_accuracy(card_def, "power", "power_weak", "power_resist")
	accuracy += _keyword_style_accuracy(card_def, "topspin", "topspin_weak", "topspin_resist")
	accuracy += _keyword_style_accuracy(card_def, "slice", "slice_weak", "slice_resist")
	accuracy += _keyword_style_accuracy(card_def, "net", "net_weak", "net_resist")
	accuracy += _keyword_style_accuracy(card_def, "volley", "volley_weak", "volley_resist")
	accuracy += _keyword_style_accuracy(card_def, "lob", "lob_weak", "lob_resist")
	accuracy += _keyword_style_accuracy(card_def, "smash", "smash_weak", "smash_resist")
	accuracy += _keyword_style_accuracy(card_def, "down_the_line", "down_the_line_weak", "down_the_line_resist")
	accuracy += _keyword_style_accuracy(card_def, "drop", "drop_weak", "drop_resist")
	accuracy += _keyword_style_accuracy(card_def, "control", "control_weak", "control_resist")
	if player_class.id == &"baseliner" and card_def.id == &"inside_out_forehand":
		if enemy_def.keywords.has("forehand_weak"):
			accuracy += 0.04
		if enemy_def.keywords.has("forehand_resist"):
			accuracy -= 0.03
	return accuracy

func _keyword_style_pressure(card_def, tag: String, weak_keyword: String, resist_keyword: String) -> int:
	if not card_def.tags.has(tag):
		return 0
	var weak_bonus := 4
	var resist_penalty := 3
	match tag:
		"serve", "power", "net", "volley":
			weak_bonus = 5
			resist_penalty = 2
		"slice", "control", "down_the_line":
			weak_bonus = 3
			resist_penalty = 3
	var bonus := 0
	if enemy_def.keywords.has(weak_keyword):
		bonus += weak_bonus
	if enemy_def.keywords.has(resist_keyword):
		bonus -= resist_penalty
	return bonus

func _keyword_style_accuracy(card_def, tag: String, weak_keyword: String, resist_keyword: String) -> float:
	if not card_def.tags.has(tag):
		return 0.0
	var weak_bonus := 0.04
	var resist_penalty := 0.03
	match tag:
		"serve", "power", "net", "volley":
			weak_bonus = 0.05
			resist_penalty = 0.02
		"slice", "control", "down_the_line":
			weak_bonus = 0.03
			resist_penalty = 0.03
	var bonus := 0.0
	if enemy_def.keywords.has(weak_keyword):
		bonus += weak_bonus
	if enemy_def.keywords.has(resist_keyword):
		bonus -= resist_penalty
	return bonus

func _enemy_matchup_note(card_def) -> String:
	var weakness_map := {
		"return": "Opponent leans vulnerable to strong returns",
		"serve": "Opponent looks shaky against clean serves",
		"power": "Opponent struggles with pace",
		"topspin": "Opponent hates heavy topspin",
		"slice": "Opponent dislikes skidding slice",
		"net": "Opponent is exposed to net pressure",
		"volley": "Opponent is exposed to net pressure",
		"lob": "Opponent is open to the lob",
		"smash": "Opponent is vulnerable above the shoulders",
		"down_the_line": "Opponent is exposed behind the change of direction",
		"drop": "Opponent is late covering the short court",
		"control": "Opponent can be outmaneuvered by touch and control",
	}
	var resist_map := {
		"return": "Opponent reads returns well",
		"serve": "Opponent handles pace off the serve",
		"power": "Opponent absorbs raw pace",
		"topspin": "Opponent handles heavy topspin",
		"slice": "Opponent sits comfortably on slice",
		"net": "Opponent is ready for first-volley pressure",
		"volley": "Opponent is ready for first-volley pressure",
		"lob": "Opponent recovers well against the lob",
		"smash": "Opponent keeps overheads from sitting up",
		"down_the_line": "Opponent covers the line well",
		"drop": "Opponent reads the drop shot early",
		"control": "Opponent is comfortable in touch exchanges",
	}
	for tag in weakness_map.keys():
		if card_def.tags.has(tag) and enemy_def.keywords.has(tag + "_weak"):
			return String(weakness_map[tag])
	for tag in resist_map.keys():
		if card_def.tags.has(tag) and enemy_def.keywords.has(tag + "_resist"):
			return String(resist_map[tag])
	if player_class.id == &"baseliner" and card_def.id == &"inside_out_forehand":
		if enemy_def.keywords.has("forehand_weak"):
			return "Opponent is exposed to the inside-out forehand"
		if enemy_def.keywords.has("forehand_resist"):
			return "Opponent tracks the inside-out forehand well"
	return ""

func _apply_tactical_follow_up(attacker, defender, card_def, attacker_is_player: bool) -> void:
	if card_def.tags.has("drop") and _actor_position(not attacker_is_player) == "ServiceLine":
		defender.add_status("pressure", 1)
	if card_def.tags.has("lob") and _actor_position(not attacker_is_player) == "Baseline":
		defender.add_status("pressure", 1)

func _apply_enemy_intent_court_state(intent: Dictionary) -> void:
	var intent_name := _intent_name(intent)
	var projection := _enemy_intent_projection(intent)
	var lane := String(projection.get("lane", "Center"))
	var projected_position := String(projection.get("position", rally_state.enemy_position))
	var projected_ball_state := String(projection.get("ball_state", rally_state.ball_state))
	var shot_family := "Rally"
	if lane == "Body" and projected_ball_state == "HighBall":
		shot_family = "Serve"
	elif projected_position == "Net":
		shot_family = "Volley"
	elif lane == "Deep" and projected_ball_state == "HighBall":
		shot_family = "Lob"
	elif lane == "Down The Line":
		shot_family = "Down The Line"
	elif lane == "Crosscourt":
		shot_family = "Crosscourt"
	rally_state.enemy_position = projected_position
	rally_state.ball_state = projected_ball_state
	rally_state.ball_lane = lane
	rally_state.record_shot("enemy", shot_family, lane, intent_name)

func _position_for_actor(actor) -> String:
	if actor == player:
		return rally_state.player_position
	return rally_state.enemy_position

func _actor_position(is_player_side: bool) -> String:
	return rally_state.player_position if is_player_side else rally_state.enemy_position

func _shot_family(card_def) -> String:
	if card_def != null and card_def.shot_family != "":
		return card_def.shot_family
	if card_def.tags.has("serve"):
		return "Serve"
	if card_def.tags.has("return"):
		return "Return"
	if card_def.tags.has("smash"):
		return "Overhead Smash"
	if card_def.tags.has("lob"):
		return "Lob"
	if card_def.tags.has("volley") or card_def.tags.has("net"):
		return "Volley"
	if card_def.tags.has("drop"):
		return "Drop Shot"
	if card_def.tags.has("slice"):
		return "Slice"
	if card_def.tags.has("down_the_line"):
		return "Down The Line"
	if card_def.tags.has("crosscourt"):
		return "Crosscourt"
	if card_def.tags.has("topspin"):
		return "Topspin Drive"
	return "Rally"

func _shot_lane(card_def) -> String:
	if card_def.tags.has("crosscourt"):
		return "Crosscourt"
	if card_def.tags.has("down_the_line"):
		return "Down The Line"
	if card_def.tags.has("drop"):
		return "Short"
	if card_def.tags.has("lob"):
		return "Deep"
	if card_def.tags.has("serve"):
		return "Body"
	return "Center"

# Shift ball_x based on the shot direction and pressure generated.
# Crosscourt pulls ball wide; DTL keeps it on the hitter's side; body/central shots drift back to center.
func _shift_ball_x_for_shot(card_def, attacker_is_player: bool) -> void:
	var lane := _shot_lane(card_def)
	# Pressure as a fraction of the rally target tells us how hard this shot pushed the geometry
	var pressure_fraction := clampf(float(absi(rally_state.rp)) / float(maxi(1, rally_state.pressure_target)), 0.0, 1.0)
	var shift_amount := 0.2 + pressure_fraction * 0.4  # 0.2 base, up to 0.6 on a dominant shot
	match lane:
		"Crosscourt":
			# Crosscourt from player goes toward ad side (+x), from enemy toward deuce (−x)
			var direction := 1.0 if attacker_is_player else -1.0
			rally_state.shift_ball_x(direction, shift_amount)
		"Down The Line":
			# DTL attacks the same side the attacker came from — pushes ball back toward center or slightly same side
			var direction := -0.5 if attacker_is_player else 0.5
			rally_state.shift_ball_x(direction, shift_amount * 0.7)
		"Body", "Center":
			# Central shots pull ball back toward center — defender can reset
			rally_state.shift_ball_x(-sign(rally_state.ball_x), absf(rally_state.ball_x) * 0.4)
		"Short":
			# Drop shot: ball dies at center-short, lateral position resets
			rally_state.shift_ball_x(-sign(rally_state.ball_x), absf(rally_state.ball_x) * 0.5)
		"Deep":
			# Lob: deep, neutralising, drifts back to center
			rally_state.shift_ball_x(-sign(rally_state.ball_x), absf(rally_state.ball_x) * 0.6)

func _update_positions_and_ball_state(card_def, attacker_is_player: bool) -> void:
	var position_ref := "player_position" if attacker_is_player else "enemy_position"
	var defender_position_ref := "enemy_position" if attacker_is_player else "player_position"
	if card_def.id == &"approach_shot":
		rally_state.set(position_ref, "ServiceLine")
	elif attacker_is_player and player_class.id == &"serve_and_volley" and (card_def.tags.has("serve") or card_def.tags.has("return")):
		rally_state.set(position_ref, "ServiceLine")
	elif card_def.tags.has("smash"):
		rally_state.set(position_ref, "Net")
	elif card_def.tags.has("net") or card_def.tags.has("volley"):
		rally_state.set(position_ref, "Net")
	elif card_def.tags.has("footwork"):
		rally_state.set(position_ref, "Baseline")
	elif card_def.tags.has("drop"):
		rally_state.set(position_ref, "ServiceLine")

	if card_def.tags.has("lob"):
		rally_state.ball_state = "HighBall"
		rally_state.ball_depth = "Deep"
		rally_state.set(defender_position_ref, "Baseline")
	elif card_def.tags.has("smash"):
		rally_state.ball_state = "AtNet"
		rally_state.ball_depth = "Short"
	elif card_def.tags.has("drop"):
		rally_state.ball_state = "AtNet"
		rally_state.ball_depth = "Short"
		rally_state.set(defender_position_ref, "ServiceLine")
	elif card_def.tags.has("slice"):
		rally_state.ball_state = "LowBall"
		rally_state.ball_depth = "Mid"
	elif card_def.tags.has("topspin") or card_def.id == &"kick_serve":
		rally_state.ball_state = "HighBall"
		rally_state.ball_depth = "Deep"
	elif card_def.tags.has("net") or card_def.tags.has("volley"):
		rally_state.ball_state = "AtNet"
		rally_state.ball_depth = "Short"
	else:
		rally_state.ball_state = "NormalBall"
		rally_state.ball_depth = "Deep"
	rally_state.ball_lane = _shot_lane(card_def)
	# Shift horizontal ball position based on shot direction, then reposition defender
	_shift_ball_x_for_shot(card_def, attacker_is_player)
	var defending_side := "enemy" if attacker_is_player else "player"
	rally_state.reposition_defender(defending_side)

func _is_shot_card(card_def) -> bool:
	for tag in card_def.tags:
		if tag in ["serve", "return", "rally", "net", "slice", "topspin", "power", "signature", "counter", "trick", "tempo", "crosscourt", "down_the_line", "drop", "volley", "lob", "smash"]:
			return true
	return false

func get_card_cost(card_instance) -> int:
	var card_def = _card_database.call("get_card", card_instance.card_id)
	if card_def == null:
		return 99
	if player_class.id == &"novice" and not _novice_free_skill_used_this_turn and card_def.tags.has("skill"):
		return 0
	if card_def.tags.has("net") and _next_net_cost_free:
		return 0
	var cost := _effective_card_stamina_cost(card_def)
	if card_def.tags.has("serve") and _has_relic("serve_clock"):
		cost -= _relic_bonus("serve_cost_reduction")
	if _power_plus_one_available(card_def):
		cost -= 1
	if player_class.id == &"alcaraz" and _alcaraz_chain_ready and card_def.tags.has("signature"):
		cost -= 1
	# cost_up debuff: each stack adds +1 Stamina to every card played this point
	cost += player.get_status("cost_up")
	return maxi(0, cost)

func _effective_card_stamina_cost(card_def) -> int:
	if card_def == null:
		return 99
	if card_def.tags.has("boss_debuff"):
		return int(card_def.cost)
	if _is_large_modifier_card(card_def):
		return 2
	if _is_modifier_card(card_def):
		return 1
	if _is_pressure_shot_card(card_def):
		return 2
	if _is_standard_shot_card(card_def):
		return 1
	return maxi(0, int(card_def.cost))

func _is_modifier_card(card_def) -> bool:
	if card_def == null:
		return false
	if card_def.tags.has("modifier") or card_def.tags.has("string") or card_def.tags.has("racquet"):
		return true
	return card_def.effects.has("string_type") or card_def.effects.has("racquet_weight_type")

func _is_large_modifier_card(card_def) -> bool:
	if not _is_modifier_card(card_def):
		return false
	if card_def.tags.has("racquet"):
		return true
	if int(card_def.effects.get("guard", 0)) >= 6:
		return true
	var modifier_effects := Dictionary(card_def.effects.get("string_modifiers", {}))
	if modifier_effects.is_empty():
		modifier_effects = Dictionary(card_def.effects.get("racquet_modifiers", {}))
	if int(modifier_effects.get("point_condition_penalty", 0)) >= 2:
		return true
	if int(modifier_effects.get("long_rally_fatigue", 0)) >= 1:
		return true
	for pressure_key in [
		"serve_pressure_bonus",
		"power_pressure_bonus",
		"net_pressure_bonus",
		"control_pressure_bonus",
		"slice_pressure_bonus",
		"topspin_pressure_bonus",
	]:
		if int(modifier_effects.get(pressure_key, 0)) >= 5:
			return true
	return false

func _is_standard_shot_card(card_def) -> bool:
	if card_def == null:
		return false
	return card_def.effects.has("damage") or card_def.effects.has("multi_hit")

func _is_pressure_shot_card(card_def) -> bool:
	if not _is_standard_shot_card(card_def):
		return false
	if int(card_def.cost) >= 2:
		return true
	if card_def.tags.has("power") or card_def.tags.has("signature"):
		return true
	if _shot_damage_total(card_def) >= 10:
		return true
	for rider_key in [
		"pressure",
		"open_court",
		"spin",
		"momentum",
		"combo_draw",
		"next_net_bonus_damage",
		"bonus_vs_guard",
		"bonus_vs_spin",
	]:
		if int(card_def.effects.get(rider_key, 0)) > 0:
			return true
	return false

func _shot_damage_total(card_def) -> int:
	if card_def == null:
		return 0
	if card_def.effects.has("multi_hit"):
		var total := 0
		for hit_value in PackedInt32Array(card_def.effects.get("multi_hit", PackedInt32Array())):
			total += int(hit_value)
		return total
	return int(card_def.effects.get("damage", 0))

func _prepare_retained_cards() -> void:
	var retain_count := _retain_count()
	var keep_slots := _choose_retained_slot_ids(retain_count)
	for slot_id in HAND_SLOT_ORDER:
		var card_instance = _get_hand_slot(slot_id)
		if card_instance == null:
			continue
		if keep_slots.has(slot_id):
			card_instance.retained = true
			continue
		card_instance.retained = false
		_store_played_card_instance(card_instance, false)
		_hand_slots[slot_id] = null
	_sync_hand_from_slots()
	_next_net_cost_free = false
	_next_net_bonus_pressure = 0
	_next_net_bonus_accuracy = 0.0
	_next_topspin_bonus = 0
	_next_topspin_accuracy_bonus = 0.0

func _choose_retained_slot_ids(retain_count: int) -> Dictionary:
	var keep_slots := {}
	if retain_count <= 0:
		return keep_slots
	for slot_id in RETAIN_SLOT_PRIORITY:
		if keep_slots.size() >= retain_count:
			break
		var card_instance = _get_hand_slot(slot_id)
		if card_instance == null:
			continue
		if int(card_instance.uid) < 0:
			continue
		keep_slots[slot_id] = true
	return keep_slots

func _retain_count() -> int:
	var retain_count = player.get_status("retain_bonus")
	if player_class.id == &"master":
		retain_count += 1
	return retain_count

func _apply_clutter_discard() -> void:
	# Pick a random occupied hand slot and discard it — the player loses one card from their opening hand
	var occupied_slots: Array = []
	for slot_id in HAND_SLOT_ORDER:
		if _get_hand_slot(slot_id) != null:
			occupied_slots.append(slot_id)
	if occupied_slots.is_empty():
		return
	var slot_to_lose: String = String(occupied_slots[_rng.randi_range(0, occupied_slots.size() - 1)])
	var card_instance = _get_hand_slot(slot_to_lose)
	if card_instance == null:
		return
	var card_def = _card_database.call("get_card", card_instance.card_id)
	var card_name: String = card_def.name if card_def != null else "a card"
	_set_hand_slot(slot_to_lose, null)
	_store_played_card_instance(card_instance, false)
	_log_line("Clutter (%d-card deck): %s slips from the bag before the point starts." % [_starting_deck_size, card_name])

func _draw_cards(count: int) -> void:
	_refill_hand_slots(count)

func _reset_hand_slots() -> void:
	_hand_slots.clear()
	for slot_id in HAND_SLOT_ORDER:
		_hand_slots[String(slot_id)] = null
	_sync_hand_from_slots()

func _sync_hand_from_slots() -> void:
	hand.clear()
	for slot_id in HAND_SLOT_ORDER:
		var card_instance = _get_hand_slot(slot_id)
		if card_instance != null:
			hand.append(card_instance)

func _get_hand_slot(slot_id: String):
	return _hand_slots.get(slot_id, null)

func _set_hand_slot(slot_id: String, card_instance) -> void:
	_hand_slots[slot_id] = card_instance
	_sync_hand_from_slots()

func _count_empty_hand_slots() -> int:
	var count := 0
	for slot_id in HAND_SLOT_ORDER:
		if _get_hand_slot(slot_id) == null:
			count += 1
	return count

func _occupied_hand_slot_count() -> int:
	return hand_size - _count_empty_hand_slots()

func _ensure_hand_slots_consistent() -> void:
	if _occupied_hand_slot_count() == hand.size():
		return
	var legacy_hand: Array = hand.duplicate()
	_reset_hand_slots()
	for card_instance in legacy_hand:
		var preferred_slot := _preferred_open_slot_for_card(card_instance)
		if preferred_slot == "":
			for slot_id in HAND_SLOT_ORDER:
				if _get_hand_slot(slot_id) == null:
					preferred_slot = slot_id
					break
		if preferred_slot != "":
			_hand_slots[preferred_slot] = card_instance
	_sync_hand_from_slots()

func _slot_id_for_hand_index(hand_index: int) -> String:
	var occupied_index := 0
	for slot_id in HAND_SLOT_ORDER:
		if _get_hand_slot(slot_id) == null:
			continue
		if occupied_index == hand_index:
			return slot_id
		occupied_index += 1
	return ""

func _slot_id_for_card_instance(card_instance) -> String:
	for slot_id in HAND_SLOT_ORDER:
		if _get_hand_slot(slot_id) == card_instance:
			return slot_id
	return ""

func _preferred_open_slot_for_card(card_instance) -> String:
	var card_def = _card_database.call("get_card", card_instance.card_id)
	if card_def == null:
		return ""
	var roles: PackedStringArray = _card_database.call("get_hand_slot_roles", card_def)
	for slot_id in HAND_SLOT_ORDER:
		if roles.has(slot_id) and _get_hand_slot(slot_id) == null:
			return slot_id
	return ""

func _refill_hand_slots(draw_count: int) -> void:
	var remaining := draw_count
	while remaining > 0:
		var filled_any := false
		for slot_id in HAND_SLOT_ORDER:
			if remaining <= 0:
				break
			if _get_hand_slot(slot_id) != null:
				continue
			var card_instance = _draw_card_for_slot(slot_id)
			if card_instance == null:
				continue
			_hand_slots[slot_id] = card_instance
			remaining -= 1
			filled_any = true
		if not filled_any:
			break
	_sync_hand_from_slots()

func _draw_card_for_slot(slot_id: String):
	if slot_id == "special":
		var boss_debuff = _spawn_special_slot_boss_debuff()
		if boss_debuff != null:
			return boss_debuff
	if slot_id == "initial_contact":
		return _player_deck.call("draw_matching", _rng, func(card_instance):
			return _card_matches_slot(card_instance, slot_id) and _card_matches_initial_contact_context(card_instance)
		)
	return _player_deck.call("draw_matching", _rng, func(card_instance):
		return _card_matches_slot(card_instance, slot_id)
	)

func _card_matches_initial_contact_context(card_instance) -> bool:
	var card_def = _card_database.call("get_card", card_instance.card_id)
	if card_def == null:
		return false
	if current_server == "player":
		return card_def.tags.has("serve")
	return card_def.tags.has("return")

func _card_matches_slot(card_instance, slot_id: String) -> bool:
	var card_def = _card_database.call("get_card", card_instance.card_id)
	if card_def == null:
		return false
	var roles: PackedStringArray = _card_database.call("get_hand_slot_roles", card_def)
	return roles.has(slot_id)

func _spawn_special_slot_boss_debuff():
	if encounter_type != "boss":
		return null
	if _cards_played_this_turn > 0:
		return null
	if turn_number < 2 or turn_number % 2 != 0:
		return null
	var debuff_index := int((_rng.randi() + turn_number + point_number) % BOSS_DEBUFF_CARD_IDS.size())
	var debuff_id: StringName = BOSS_DEBUFF_CARD_IDS[debuff_index]
	var debuff_def = _card_database.call("get_card", debuff_id)
	if debuff_def == null:
		return null
	var temp_card_instance = CardInstanceScript.new(_temp_card_uid, debuff_id)
	_temp_card_uid -= 1
	_log_line("%s forces %s into the special slot." % [enemy.display_name, debuff_def.name])
	return temp_card_instance

func _store_played_card_instance(card_instance, exhaust_card: bool) -> void:
	if card_instance == null:
		return
	if int(card_instance.uid) < 0:
		return
	if exhaust_card:
		_player_deck.call("exhaust", card_instance)
	else:
		_player_deck.call("discard", card_instance)

func _resolve_pending_special_boss_debuff() -> void:
	var special_card = _get_hand_slot("special")
	if special_card == null or int(special_card.uid) >= 0:
		return
	var card_def = _card_database.call("get_card", special_card.card_id)
	if card_def == null or not card_def.tags.has("boss_debuff"):
		return
	var effects: Dictionary = card_def.effects
	if effects.has("fatigue"):
		player.add_status("fatigue", int(effects.get("fatigue", 0)))
	if effects.has("pressure"):
		player.add_status("pressure", int(effects.get("pressure", 0)))
	if effects.has("open_court"):
		player.add_status("open_court", int(effects.get("open_court", 0)))
	_log_line("%s lingers into the end of turn." % card_def.name)
	_set_hand_slot("special", null)

func _check_point_or_match_resolution() -> bool:
	if not rally_state.is_point_over():
		return state == "won" or state == "lost"

	if rally_state.error_reason != "":
		_log_line(rally_state.error_reason)
	var winner = rally_state.resolve_winner()
	var point_reason := _build_point_reason(winner)
	var player_condition_delta := 0
	var enemy_condition_delta := 0
	if winner == "player":
		tennis_score.point_to_player()
		_log_line("Player wins the point. " + tennis_score.display())
	else:
		tennis_score.point_to_enemy()
		var condition_loss := point_condition_loss + int(rally_state.exchanges / 2) + _racquet_int_modifier("point_condition_penalty")
		var sloppy_endurance_tax := _calculate_sloppy_endurance_tax()
		condition_loss += sloppy_endurance_tax
		if rally_state.forced_error and _has_relic("dampener") and not _dampener_used_this_game:
			condition_loss = maxi(0, condition_loss - _relic_bonus("first_error_condition_reduction"))
			_dampener_used_this_game = true
			_log_line("Dampener softens the first missed point of the game.")
		var loss = player.lose_condition(condition_loss)
		player_condition_delta = -loss
		if sloppy_endurance_tax > 0:
			_log_line("Loose point management costs %d extra Endurance." % sloppy_endurance_tax)
		_log_line(enemy.display_name + " wins the point. You lose " + str(loss) + " Endurance. " + tennis_score.display())
	_last_point_summary = "%s won via %s. Score %s-%s." % [
		"Player" if winner == "player" else enemy.display_name,
		point_reason,
		tennis_score.player_score_label(),
		tennis_score.enemy_score_label(),
	]
	_emit_event("point_resolved", {
		"winner": winner,
		"reason": point_reason,
		"forced_error": rally_state.forced_error,
		"rally_exchanges": rally_state.exchanges,
		"score_player": tennis_score.player_score_label(),
		"score_enemy": tennis_score.enemy_score_label(),
		"rally_pressure": rally_state.rp,
		"score_status": tennis_score.score_status_label(),
		"games_player": player_games_won,
		"games_enemy": enemy_games_won,
		"condition_delta": {
			"player": player_condition_delta,
			"enemy": enemy_condition_delta,
		},
	})

	_apply_surface_point_end()
	_apply_final_rule_after_point(winner)

	if rally_state.exchanges >= 6 and _has_relic("rally_counter"):
		_opening_stamina_bonus_pending += maxi(1, _relic_bonus("long_rally_bonus_stamina"))
		_log_line("Rally Counter banks stamina for the next point.")

	if not player.is_alive():
		state = "lost"
		result_reason = "Condition dropped to 0."
		return true

	if tennis_score.is_game_over():
		if tennis_score.winner() == "player":
			player_games_won += 1
			_log_line("Player takes the game.")
			_emit_event("game_won", {"winner": "player", "games_player": player_games_won, "games_enemy": enemy_games_won}, "player")
		else:
			enemy_games_won += 1
			_log_line(enemy.display_name + " takes the game.")
			_emit_event("game_won", {"winner": "enemy", "games_player": player_games_won, "games_enemy": enemy_games_won}, "enemy")

		if player_games_won >= games_to_win:
			state = "won"
			result_reason = "Match won."
			_emit_event("match_resolved", {"winner": "player", "reason": result_reason}, "player")
			return true
		if enemy_games_won >= games_to_win:
			state = "lost"
			result_reason = "Match lost."
			_emit_event("match_resolved", {"winner": "enemy", "reason": result_reason}, "enemy")
			return true

		if encounter_type == "boss" and _has_relic("champions_towel"):
			var boss_game_heal: int = player.restore_condition(_relic_bonus("boss_game_heal"))
			if boss_game_heal > 0:
				_log_line("Champion's Towel restores " + str(boss_game_heal) + " Condition between games.")

		current_server = "enemy" if current_server == "player" else "player"
		tennis_score = TennisScoreScript.new(no_ad)
		_dampener_used_this_game = false
		_mental_coach_used_this_game = false
		_boss_changeover_used_this_game = false
		_log_line("New game. Server switches to " + current_server.capitalize() + ".")

	_start_new_point()
	return true

func _calculate_sloppy_endurance_tax() -> int:
	var tax := 0
	if player.current_stamina >= maxi(2, int(ceil(float(player.max_stamina) * 0.5))):
		tax += 1
	elif player.current_stamina > 0 and rally_state.exchanges >= 4:
		tax += 1
	if rally_state.forced_error:
		tax += 1
	if player.get_status("fatigue") >= 2:
		tax += 1
	if player.get_status("open_court") > 0:
		tax += 1
	return mini(3, tax)

func _build_point_reason(winner: String) -> String:
	if rally_state.forced_error:
		return "forced error"
	var signed_pressure := _signed_pressure_value(rally_state.rp)
	if winner == "player":
		return "%s rally pressure" % signed_pressure
	if winner == "enemy":
		return "%s rally pressure" % signed_pressure
	return "point resolution"

func _signed_pressure_value(value: int) -> String:
	return "%+d" % value

func _clear_hand_between_points() -> void:
	for slot_id in HAND_SLOT_ORDER:
		var card_instance = _get_hand_slot(slot_id)
		if card_instance == null:
			continue
		card_instance.retained = false
		_store_played_card_instance(card_instance, false)
	_reset_hand_slots()

func _clear_point_only_statuses(actor) -> void:
	actor.guard = 0
	for status_name in ["pressure", "spin", "open_court", "momentum", "thorns", "next_turn_stamina", "next_turn_momentum", "position_lock"]:
		actor.set_status(status_name, 0)

func _decay_between_points(actor) -> void:
	var decay := 1
	if actor == player:
		decay += _relic_bonus("extra_fatigue_decay")
	actor.set_status("fatigue", maxi(0, actor.get_status("fatigue") - decay))
	# tilt and cost_up are persistent disruption debuffs — decay by 1 per point like fatigue
	actor.set_status("tilt", maxi(0, actor.get_status("tilt") - 1))
	actor.set_status("cost_up", maxi(0, actor.get_status("cost_up") - 1))

func _should_enemy_disrupt() -> bool:
	# Can't disrupt before the point opens (serve/return exchange hasn't happened)
	if rally_state.exchanges == 0:
		return false
	# Don't disrupt if the enemy is already about to win the point
	var enemy_pressure_to_win := rally_pressure_target + rally_state.rp
	if enemy_pressure_to_win <= int(float(rally_pressure_target) * 0.20):
		return false
	var base_chance := 0.0
	if encounter_type == "boss":
		base_chance = 0.22
	elif encounter_type == "elite":
		base_chance = 0.15
	else:
		base_chance = 0.07
	# Escalate when player has strong momentum/focus (disruption is more tempting)
	base_chance += float(player.get_status("momentum")) * 0.03
	base_chance += float(player.get_status("focus")) * 0.02
	# Cap disruption chance so it doesn't happen every other turn
	base_chance = minf(base_chance, 0.35)
	return _rng.randf() < base_chance

func _choose_disruption_type() -> String:
	# Pick debuff based on enemy style and current state
	var options: PackedStringArray = PackedStringArray()
	# Fatigue ramp is universally available — enemy grinds the player down
	options.append("fatigue_ramp")
	# Power/serve enemies spike stamina costs
	if enemy_def.keywords.has("power") or enemy_def.keywords.has("serve"):
		options.append("cost_up")
		options.append("cost_up")  # weighted double
	# Net-rushing enemies lock court position
	if enemy_def.keywords.has("net"):
		options.append("position_lock")
		options.append("position_lock")
	# Aggressive/burst enemies cause tilt
	if enemy_def.keywords.has("burst") or enemy_def.style in ["Aggressive", "AllCourt"]:
		options.append("tilt")
		options.append("tilt")
	# Default: random tilt or fatigue
	if options.is_empty():
		options.append("tilt")
	var idx := _rng.randi_range(0, options.size() - 1)
	return options[idx]

func _execute_enemy_disruption_play() -> void:
	var disruption_type := _choose_disruption_type()
	match disruption_type:
		"fatigue_ramp":
			var amount := 1 + (1 if encounter_type == "boss" else 0)
			player.add_status("fatigue", amount)
			_log_line(enemy.display_name + " dictates the pace — you accumulate Fatigue ×" + str(amount) + ". Stamina ceiling drops.")
		"cost_up":
			player.add_status("cost_up", 1)
			_log_line(enemy.display_name + " dominates the court — your cards cost +1 Stamina until the point ends.")
		"position_lock":
			player.add_status("position_lock", 1)
			_log_line(enemy.display_name + " commands the net — your court-position bonuses are locked out this point.")
		"tilt":
			player.add_status("tilt", 1)
			_log_line(enemy.display_name + " rattles your contact — Tilt ×1 applied. Accuracy −5% until the point ends.")
	_emit_event("enemy_disruption", {
		"type": disruption_type,
		"actor": enemy.display_name,
	}, "enemy")

func _choose_enemy_intent() -> Dictionary:
	return _enemy_intent_planner.choose_intent(enemy_def, _build_enemy_ai_context(), _rng)

func _enemy_ai_state() -> String:
	return _enemy_intent_planner.determine_ai_state(enemy_def, _build_enemy_ai_context())

func _intent_utility(ai_state: String, intent: Dictionary) -> float:
	return _enemy_intent_planner.score_intent(enemy_def, ai_state, intent, _build_enemy_ai_context())

func _describe_intent(intent: Dictionary) -> String:
	return _enemy_intent_planner.describe_intent(intent)

func _enemy_intent_projection(intent: Dictionary) -> Dictionary:
	return _enemy_intent_planner.project_intent(intent, _build_enemy_ai_context())

func _format_enemy_intent_projection(intent: Dictionary) -> String:
	return _enemy_intent_planner.format_projection(intent, _build_enemy_ai_context())

func _intent_name(intent: Dictionary) -> String:
	return _enemy_intent_planner.intent_name(intent)

func _serve_pattern(intent: Dictionary) -> String:
	return _enemy_intent_planner.serve_pattern(intent)

func _build_enemy_intent_detail(intent: Dictionary) -> Dictionary:
	if intent.is_empty():
		return {}
	var projection := _enemy_intent_projection(intent)
	var per_hit_pressure := int(intent.get("damage", 0))
	var hits := maxi(1, int(intent.get("hits", 1)))
	return {
		"name": _intent_name(intent),
		"ai_state": _enemy_ai_state(),
		"per_hit_pressure": per_hit_pressure,
		"hits": hits,
		"total_pressure": per_hit_pressure * hits,
		"guard": int(intent.get("guard", 0)),
		"fatigue": int(intent.get("fatigue", 0)),
		"pressure": int(intent.get("pressure", 0)),
		"open_court": int(intent.get("open_court", 0)),
		"momentum": int(intent.get("momentum", 0)),
		"serve_pattern": _serve_pattern(intent),
		"position": String(projection.get("position", "Baseline")),
		"lane": String(projection.get("lane", "Center")),
		"ball_state": String(projection.get("ball_state", "NormalBall")),
		"summary": _describe_intent(intent),
		"projection": _format_enemy_intent_projection(intent),
	}

func _enemy_intent_summary() -> String:
	if queued_enemy_intent.is_empty():
		return "No telegraph."
	return _enemy_ai_state() + ": " + _describe_intent(queued_enemy_intent)

func _refresh_enemy_intent_preview() -> void:
	if state == "won" or state == "lost" or rally_state.is_point_over():
		queued_enemy_intent = {}
		return
	queued_enemy_intent = _choose_enemy_intent()

func _build_enemy_ai_context() -> Dictionary:
	return {
		"current_server": current_server,
		"rally_exchanges": rally_state.exchanges,
		"rally_pressure": rally_state.rp,
		"rally_target": rally_pressure_target,
		"enemy_position": rally_state.enemy_position,
		"ball_state": rally_state.ball_state,
		"player_guard": player.guard if player != null else 0,
		"enemy_guard": enemy.guard if enemy != null else 0,
		"player_current_stamina": player.current_stamina if player != null else 0,
		"player_max_stamina": player.max_stamina if player != null else 0,
		"player_fatigue": player.get_status("fatigue") if player != null else 0,
		"player_open_court": player.get_status("open_court") if player != null else 0,
		"player_return_support": _player_return_support_score(),
		"rally_cards_played_this_turn": _rally_cards_played_this_turn,
	}

func _actor_summary(actor, is_player: bool) -> String:
	var position = rally_state.player_position if is_player else rally_state.enemy_position
	var lines := PackedStringArray()
	lines.append(actor.display_name)
	lines.append("Condition: " + str(actor.current_condition) + " / " + str(actor.max_condition))
	lines.append("Stamina: " + str(actor.current_stamina) + " / " + str(actor.max_stamina))
	lines.append("Guard/Stability: " + str(actor.guard))
	lines.append("Position: " + position)
	lines.append("Pressure: " + str(actor.get_status("pressure")) + "  Spin: " + str(actor.get_status("spin")))
	lines.append("Fatigue: " + str(actor.get_status("fatigue")) + "  Focus: " + str(actor.get_status("focus")))
	return "\n".join(lines)

func _player_return_support_score() -> float:
	var score := 0.0
	var return_cards := _count_player_cards_with_tag("return")
	score += minf(5.0, float(return_cards) * 0.65)
	match player_class.id:
		&"serve_and_volley", &"pusher":
			score += 1.5
		&"novice", &"power", &"all_arounder", &"alcaraz", &"slicer":
			score += 1.0
		&"baseliner", &"master":
			score += 0.4
		_:
			score += 0.7
	if _has_relic("serve_scout_notes"):
		score += 1.75
	if _has_relic("return_coach"):
		score += 2.25
	if _has_relic("chip_charge_playbook"):
		score += 1.5
	match _active_string_type:
		"Natural Gut", "Multifilament":
			score += 0.6
		"Synthetic Gut":
			score += 0.35
	return score

func _count_player_cards_with_tag(tag: String) -> int:
	var count := 0
	for card_instance in hand:
		if _card_instance_has_tag(card_instance, tag):
			count += 1
	for card_instance in _player_deck.draw_pile:
		if _card_instance_has_tag(card_instance, tag):
			count += 1
	for card_instance in _player_deck.discard_pile:
		if _card_instance_has_tag(card_instance, tag):
			count += 1
	for card_instance in _player_deck.exhaust_pile:
		if _card_instance_has_tag(card_instance, tag):
			count += 1
	return count

func _card_instance_has_tag(card_instance, tag: String) -> bool:
	var card_def = _card_database.call("get_card", card_instance.card_id)
	return card_def != null and card_def.tags.has(tag)

func _build_actor_presentation(actor, is_player: bool) -> Dictionary:
	var position: String = rally_state.player_position if is_player else rally_state.enemy_position
	return {
		"name": actor.display_name,
		"condition": actor.current_condition,
		"max_condition": actor.max_condition,
		"stamina": actor.current_stamina,
		"max_stamina": actor.max_stamina,
		"guard": actor.guard,
		"position": position,
		"statuses": _build_status_tokens(actor),
	}

func _build_status_tokens(actor) -> PackedStringArray:
	var status_tokens := PackedStringArray()
	for status_name in ["momentum", "focus", "pressure", "spin", "fatigue", "open_court", "thorns", "tilt", "cost_up", "position_lock"]:
		var value: int = actor.get_status(status_name)
		if value > 0:
			status_tokens.append("%s %d" % [_format_status_name(status_name), value])
	return status_tokens

func _format_status_name(status_name: String) -> String:
	match status_name:
		"open_court":
			return "Open Court"
		"cost_up":
			return "Cost Spike"
		"position_lock":
			return "Pos Lock"
		_:
			return status_name.capitalize()

func _join_strings(values: PackedStringArray) -> String:
	if values.is_empty():
		return ""
	return ", ".join(values)

func _log_line(line: String) -> void:
	log_lines.append(line)
	if log_lines.size() > 28:
		log_lines.remove_at(0)
	_emit_event("log", {"text": line})

func _emit_event(kind: String, payload: Dictionary = {}, side: String = "") -> void:
	var event = MatchEventScript.new(kind, payload, side, point_number, turn_number)
	_recent_events.append(event)
	if _recent_events.size() > 48:
		_recent_events.remove_at(0)
	var event_dictionary := event.to_dictionary()
	for index in range(_event_listeners.size() - 1, -1, -1):
		var listener: Callable = _event_listeners[index]
		if listener.is_null() or not listener.is_valid():
			_event_listeners.remove_at(index)
			continue
		listener.call(event_dictionary)

func _apply_surface_point_start() -> void:
	match surface_key:
		"grass":
			rally_state.ball_state = "LowBall"
			_log_line("The grass stays low and slick at the start of the point.")
		_:
			pass

func _apply_final_rule_point_start() -> void:
	if encounter_type != "boss":
		return
	if final_rule_id == "server_spotlight":
		if current_server == "player":
			player.add_status("momentum", 1)
			_log_line("Spotlight Server gives the player Momentum.")
		else:
			enemy.add_status("momentum", 1)
			_log_line(enemy.display_name + " opens the point with server momentum.")
	if _next_point_player_momentum > 0:
		player.add_status("momentum", _next_point_player_momentum)
		_log_line("Hot Streak carries player momentum into the new point.")
		_next_point_player_momentum = 0
	if _next_point_enemy_momentum > 0:
		enemy.add_status("momentum", _next_point_enemy_momentum)
		_log_line(enemy.display_name + " carries momentum into the new point.")
		_next_point_enemy_momentum = 0
	if final_rule_id == "return_rush":
		if current_server == "player":
			enemy.add_status("focus", 1)
			enemy.guard += 4
			_log_line(enemy.display_name + " attacks the return under Return Rush.")
		else:
			player.add_status("focus", 1)
			player.guard += 4
			_log_line("Return Rush sharpens the player's first read.")
	if final_rule_id == "pressure_cooker" and tennis_score.is_deuce() and not _pressure_cooker_used_this_point:
		player.add_status("pressure", 1)
		enemy.add_status("pressure", 1)
		_pressure_cooker_used_this_point = true
		_log_line("Pressure Cooker turns deuce into a knife-edge point.")
	if final_rule_id == "game_point_glare" and _is_game_point_state():
		player.add_status("pressure", 1)
		enemy.add_status("pressure", 1)
		var threat_side := _game_point_side()
		if threat_side == "enemy":
			player.add_status("focus", 1)
		elif threat_side == "player":
			enemy.add_status("focus", 1)
		_log_line("Game Point Glare piles scoreboard pressure onto the opening ball.")

func _apply_surface_point_end() -> void:
	if surface_key == "clay" and rally_state.exchanges >= 4:
		player.add_status("fatigue", 1)
		enemy.add_status("fatigue", 1)
		_log_line("Clay grind leaves both sides carrying extra Fatigue.")
	if rally_state.exchanges >= 4 and _racquet_int_modifier("long_rally_fatigue") > 0:
		player.add_status("fatigue", _racquet_int_modifier("long_rally_fatigue"))
		_log_line(_active_racquet_name + " drags on the legs in the long rally.")

func _apply_final_rule_after_point(winner: String) -> void:
	if encounter_type != "boss":
		return
	if final_rule_id == "hot_streak":
		_next_point_player_momentum = 1 if winner == "player" else 0
		_next_point_enemy_momentum = 1 if winner == "enemy" else 0

func _game_point_side() -> String:
	if tennis_score.player_points >= 3 and tennis_score.player_points > tennis_score.enemy_points:
		return "player"
	if tennis_score.enemy_points >= 3 and tennis_score.enemy_points > tennis_score.player_points:
		return "enemy"
	return ""

func _is_game_point_state() -> bool:
	return _game_point_side() != ""

func _surface_pressure_bonus(card_def) -> int:
	match surface_key:
		"clay":
			if card_def.tags.has("topspin"):
				return 6
			if card_def.tags.has("rally"):
				return 2
		"grass":
			if card_def.tags.has("net"):
				return 6
			if card_def.tags.has("serve"):
				return 3
			if card_def.tags.has("slice"):
				return 2
		_:
			if card_def.tags.has("serve"):
				return 4
			if card_def.tags.has("power"):
				return 3
	return 0

func _surface_accuracy_bonus(card_def) -> float:
	match surface_key:
		"clay":
			if card_def.tags.has("topspin"):
				return 0.04
			if card_def.tags.has("rally"):
				return 0.02
		"grass":
			if card_def.tags.has("net"):
				return 0.08
			if card_def.tags.has("serve"):
				return 0.05
			if card_def.tags.has("slice"):
				return 0.04
		_:
			if card_def.tags.has("serve"):
				return 0.05
			if card_def.tags.has("power"):
				return 0.03
	return 0.0

func _equip_string_setup(card_def, effects: Dictionary) -> void:
	var previous_setup := _active_string_name
	_active_string_type = String(effects.get("string_type", "Custom"))
	_active_string_name = card_def.name
	var base_modifiers: Dictionary = Dictionary(effects.get("string_modifiers", {})).duplicate(true)
	var synergy_bundle := _class_string_synergy(_active_string_type)
	_active_string_modifiers = _merge_modifier_tables(base_modifiers, Dictionary(synergy_bundle.get("modifiers", {})))
	if previous_setup == "":
		_log_line("String setup equipped: " + _active_string_name + ".")
	elif previous_setup == _active_string_name:
		_log_line("String setup refreshed: " + _active_string_name + ".")
	else:
		_log_line("String setup changed from " + previous_setup + " to " + _active_string_name + ".")
	var synergy_note := String(synergy_bundle.get("note", ""))
	if synergy_note != "":
		_log_line(synergy_note)

func _equip_racquet_setup(card_def, effects: Dictionary) -> void:
	var previous_setup := _active_racquet_name
	_active_racquet_type = String(effects.get("racquet_weight_type", "Custom Frame"))
	_active_racquet_name = card_def.name
	var base_modifiers: Dictionary = Dictionary(effects.get("racquet_modifiers", {})).duplicate(true)
	var synergy_bundle := _class_racquet_synergy(_active_racquet_type)
	_active_racquet_modifiers = _merge_modifier_tables(base_modifiers, Dictionary(synergy_bundle.get("modifiers", {})))
	if racquet_tuning_level > 0:
		_active_racquet_modifiers = _merge_modifier_tables(_active_racquet_modifiers, _racquet_tuning_modifiers())
	if previous_setup == "":
		_log_line("Racquet weighting equipped: " + _active_racquet_name + ".")
	elif previous_setup == _active_racquet_name:
		_log_line("Racquet weighting refreshed: " + _active_racquet_name + ".")
	else:
		_log_line("Racquet weighting changed from " + previous_setup + " to " + _active_racquet_name + ".")
	if _racquet_int_modifier("point_condition_penalty") > 0:
		_log_line("The heavier frame will tax endurance on lost points.")
	if racquet_tuning_level > 0:
		_log_line("Racquet workshop tuning adds extra bite to the frame setup.")
	var synergy_note := String(synergy_bundle.get("note", ""))
	if synergy_note != "":
		_log_line(synergy_note)

func _string_int_modifier(modifier_name: String) -> int:
	return int(_active_string_modifiers.get(modifier_name, 0))

func _string_float_modifier(modifier_name: String) -> float:
	return float(_active_string_modifiers.get(modifier_name, 0.0))

func _racquet_int_modifier(modifier_name: String) -> int:
	return int(_active_racquet_modifiers.get(modifier_name, 0))

func _racquet_float_modifier(modifier_name: String) -> float:
	return float(_active_racquet_modifiers.get(modifier_name, 0.0))

func _racquet_tuning_modifiers() -> Dictionary:
	return {
		"guard_bonus": racquet_tuning_level,
		"serve_pressure_bonus": racquet_tuning_level,
		"control_pressure_bonus": racquet_tuning_level,
	}

func _build_equipment_entry(slot_label: String, default_name: String, default_subtitle: String, default_summary: String, equipped_name: String, equipped_type: String, effect_phrases: PackedStringArray) -> Dictionary:
	if equipped_name == "":
		return {
			"slot": slot_label,
			"name": default_name,
			"subtitle": default_subtitle,
			"summary": default_summary,
			"details": default_summary,
			"equipped": false,
		}

	var summary_parts := PackedStringArray()
	if equipped_type != "":
		summary_parts.append(equipped_type)
	for index in range(mini(2, effect_phrases.size())):
		summary_parts.append(effect_phrases[index])

	var detail_parts := PackedStringArray()
	if equipped_type != "":
		detail_parts.append(equipped_type)
	for phrase in effect_phrases:
		detail_parts.append(phrase)

	return {
		"slot": slot_label,
		"name": equipped_name,
		"subtitle": equipped_type if equipped_type != "" else "Match-long modifier equipped",
		"summary": " | ".join(summary_parts) if not summary_parts.is_empty() else "Match-long modifier equipped",
		"details": " | ".join(detail_parts) if not detail_parts.is_empty() else "Match-long modifier equipped",
		"equipped": true,
	}

func _build_tactical_read() -> String:
	var notes := PackedStringArray()
	match rally_state.enemy_position:
		"Net":
			notes.append("Enemy at Net: lobs and low slice feet checks gain value.")
		"ServiceLine":
			notes.append("Enemy mid-court: pass them or drop behind the first step.")
		_:
			notes.append("Enemy deep: drop shots and short angles are live.")
	match rally_state.ball_state:
		"HighBall":
			notes.append("High ball sitting up: overhead smash window.")
		"AtNet":
			notes.append("Ball is short: volleys and lobs both gain shape.")
		"LowBall":
			notes.append("Low skid: slice is clean, flat power is riskier.")
	if enemy.get_status("open_court") > 0:
		notes.append("Court is open: attack down the line now.")
	if rally_state.last_shot_lane == "Crosscourt":
		notes.append("Last lane was crosscourt: changing direction is stronger.")
	return " ".join(notes)

func _equipment_modifier_phrases(modifiers: Dictionary, is_string_setup: bool) -> PackedStringArray:
	var phrases := PackedStringArray()
	if modifiers.is_empty():
		return phrases

	if is_string_setup:
		_append_modifier_phrase(phrases, modifiers, "extra_spin", "Spin ")
		_append_modifier_phrase(phrases, modifiers, "topspin_pressure_bonus", "Topspin ")
		_append_modifier_phrase(phrases, modifiers, "slice_pressure_bonus", "Slice ")
		_append_modifier_phrase(phrases, modifiers, "serve_pressure_bonus", "Serve ")
		_append_modifier_phrase(phrases, modifiers, "net_pressure_bonus", "Net ")
		_append_modifier_phrase(phrases, modifiers, "power_pressure_bonus", "Power ")
		_append_modifier_phrase(phrases, modifiers, "heal_bonus", "Recover ")
		_append_modifier_phrase(phrases, modifiers, "guard_bonus", "Guard ")
		_append_modifier_percent_phrase(phrases, modifiers, "global_accuracy_bonus", "Accuracy ")
		_append_modifier_percent_phrase(phrases, modifiers, "control_accuracy_bonus", "Control ")
		_append_modifier_percent_phrase(phrases, modifiers, "power_accuracy_bonus", "Power ")
	else:
		_append_modifier_phrase(phrases, modifiers, "topspin_pressure_bonus", "Topspin ")
		_append_modifier_phrase(phrases, modifiers, "slice_pressure_bonus", "Slice ")
		_append_modifier_phrase(phrases, modifiers, "serve_pressure_bonus", "Serve ")
		_append_modifier_phrase(phrases, modifiers, "power_pressure_bonus", "Power ")
		_append_modifier_phrase(phrases, modifiers, "control_pressure_bonus", "Control ")
		_append_modifier_phrase(phrases, modifiers, "net_pressure_bonus", "Net ")
		_append_modifier_phrase(phrases, modifiers, "guard_bonus", "Guard ")
		_append_modifier_percent_phrase(phrases, modifiers, "control_accuracy_bonus", "Control ")
		_append_modifier_percent_phrase(phrases, modifiers, "power_accuracy_bonus", "Power ")
		_append_modifier_phrase(phrases, modifiers, "point_condition_penalty", "Lost Pts ")
		_append_modifier_phrase(phrases, modifiers, "long_rally_fatigue", "Long Rally Fatigue ")
	return phrases

func _append_modifier_phrase(phrases: PackedStringArray, modifiers: Dictionary, modifier_name: String, label: String) -> void:
	var value := int(modifiers.get(modifier_name, 0))
	if value == 0:
		return
	phrases.append(label + _signed_int_text(value))

func _append_modifier_percent_phrase(phrases: PackedStringArray, modifiers: Dictionary, modifier_name: String, label: String) -> void:
	var value := float(modifiers.get(modifier_name, 0.0))
	if is_zero_approx(value):
		return
	phrases.append(label + _signed_percent_text(value))

func _signed_int_text(value: int) -> String:
	if value > 0:
		return "+" + str(value)
	return str(value)

func _signed_percent_text(value: float) -> String:
	var percent := int(round(value * 100.0))
	if percent > 0:
		return "+" + str(percent) + "%"
	return str(percent) + "%"

func _add_round_bonus_note(bundle: Dictionary, note: String) -> void:
	var notes_value = bundle.get("notes", PackedStringArray())
	var notes := PackedStringArray()
	if typeof(notes_value) == TYPE_PACKED_STRING_ARRAY:
		notes = notes_value
	elif notes_value is Array:
		for entry in notes_value:
			notes.append(String(entry))
	notes.append(note)
	bundle["notes"] = notes

func _class_string_synergy(string_type: String) -> Dictionary:
	match player_class.id:
		&"novice":
			if string_type == "Natural Gut":
				return {"modifiers": {"global_accuracy_bonus": 0.02}, "note": "Natural Gut settles the Novice's contact point."}
			if string_type == "Synthetic Gut":
				return {"modifiers": {"global_accuracy_bonus": 0.02, "guard_bonus": 1}, "note": "Synthetic gut gives the Novice a cleaner, simpler response window."}
		&"pusher":
			if string_type == "Natural Gut":
				return {"modifiers": {"heal_bonus": 1, "guard_bonus": 1}, "note": "Natural Gut feeds the Pusher's defensive touch."}
			if string_type == "Multifilament":
				return {"modifiers": {"guard_bonus": 1, "control_accuracy_bonus": 0.02}, "note": "Multifilament keeps the Pusher comfortable in long exchanges."}
		&"slicer":
			if string_type == "Natural Gut":
				return {"modifiers": {"slice_pressure_bonus": 3, "control_accuracy_bonus": 0.02}, "note": "Natural Gut sharpens the Slicer's touch and skid."}
			if string_type == "Multifilament":
				return {"modifiers": {"slice_pressure_bonus": 2, "control_accuracy_bonus": 0.02}, "note": "Multifilament adds easy touch for the Slicer."}
		&"power":
			if string_type == "Kevlar":
				return {"modifiers": {"power_pressure_bonus": 4, "serve_pressure_bonus": 2}, "note": "Kevlar lets the Power build swing through the court."}
			if string_type == "Polyester":
				return {"modifiers": {"power_pressure_bonus": 2, "topspin_pressure_bonus": 2}, "note": "Polyester keeps the Power class's cut on the ball under control."}
		&"all_arounder":
			if string_type == "Hybrid":
				return {"modifiers": {"serve_pressure_bonus": 1, "net_pressure_bonus": 1, "control_accuracy_bonus": 0.02}, "note": "Hybrid strings fit the All-Arounder's whole-court balance."}
			if string_type == "Synthetic Gut":
				return {"modifiers": {"serve_pressure_bonus": 1, "control_accuracy_bonus": 0.02}, "note": "Synthetic gut keeps the All-Arounder balanced without overcommitting to one pattern."}
		&"baseliner":
			if string_type == "Polyester":
				return {"modifiers": {"topspin_pressure_bonus": 5, "extra_spin": 1}, "note": "Polyester unlocks heavier RPM for the Baseliner."}
		&"serve_and_volley":
			if string_type == "Hybrid":
				return {"modifiers": {"serve_pressure_bonus": 2, "net_pressure_bonus": 3}, "note": "Hybrid strings juice the Serve and Volley's first strike patterns."}
			if string_type == "Multifilament":
				return {"modifiers": {"net_pressure_bonus": 2, "control_accuracy_bonus": 0.02}, "note": "Multifilament gives the Serve and Volley class soft hands up front."}
		&"master":
			if string_type == "Natural Gut":
				return {"modifiers": {"global_accuracy_bonus": 0.03, "control_accuracy_bonus": 0.02}, "note": "Natural Gut rewards the Master's precision."}
		&"alcaraz":
			if string_type == "Hybrid":
				return {"modifiers": {"serve_pressure_bonus": 2, "net_pressure_bonus": 2, "topspin_pressure_bonus": 2}, "note": "Hybrid strings amplify Alcaraz-style variation."}
			if string_type == "Polyester":
				return {"modifiers": {"topspin_pressure_bonus": 3, "serve_pressure_bonus": 1}, "note": "Polyester helps the Alcaraz class jump on spin-heavy accelerations."}
	return {}

func _class_racquet_synergy(racquet_type: String) -> Dictionary:
	match player_class.id:
		&"novice":
			if racquet_type == "Head-Light Control":
				return {"modifiers": {"control_accuracy_bonus": 0.03, "guard_bonus": 1}, "note": "The head-light balance gives the Novice cleaner prep and steadier contact."}
		&"pusher":
			if racquet_type == "Counterweighted Handle":
				return {"modifiers": {"guard_bonus": 2, "control_pressure_bonus": 2}, "note": "The Pusher turns the counterweighted handle into pure attrition stability."}
		&"slicer":
			if racquet_type == "Head-Light Control":
				return {"modifiers": {"slice_pressure_bonus": 3, "control_accuracy_bonus": 0.02}, "note": "The Slicer knives through the ball with the head-light frame."}
			if racquet_type == "Lead Tape 3 and 9":
				return {"modifiers": {"slice_pressure_bonus": 2, "control_pressure_bonus": 1}, "note": "Side-balanced weighting sharpens the Slicer's skid and redirection."}
		&"power":
			if racquet_type == "Extra-Long Lever":
				return {"modifiers": {"serve_pressure_bonus": 3, "power_pressure_bonus": 3}, "note": "The Power build leans into the extra-long lever for heavier first strikes."}
			if racquet_type == "Pro Stock":
				return {"modifiers": {"power_pressure_bonus": 3, "serve_pressure_bonus": 1}, "note": "The heavy pro stock lets the Power class swing through contact."}
		&"all_arounder":
			if racquet_type == "Counterweighted Handle":
				return {"modifiers": {"control_pressure_bonus": 1, "net_pressure_bonus": 2, "guard_bonus": 1}, "note": "The All-Arounder uses the counterweight to stay balanced in every pattern."}
			if racquet_type == "Lead Tape 3 and 9":
				return {"modifiers": {"control_pressure_bonus": 2, "net_pressure_bonus": 1}, "note": "Side-balanced tape gives the All-Arounder extra stability on transitions."}
		&"baseliner":
			if racquet_type == "Pro Stock":
				return {"modifiers": {"topspin_pressure_bonus": 4, "point_condition_penalty": -1}, "note": "The Baseliner handles the pro stock and loads it with heavier RPM."}
		&"serve_and_volley":
			if racquet_type == "Counterweighted Handle":
				return {"modifiers": {"serve_pressure_bonus": 1, "net_pressure_bonus": 3}, "note": "The Serve and Volley class turns the counterweighted frame into fast first-volley pressure."}
			if racquet_type == "Lead Tape 12":
				return {"modifiers": {"serve_pressure_bonus": 2, "net_pressure_bonus": 2}, "note": "Top-loaded tape helps the Serve and Volley class knife through the first strike."}
		&"master":
			if racquet_type == "Head-Light Control":
				return {"modifiers": {"control_accuracy_bonus": 0.04, "control_pressure_bonus": 2}, "note": "The Master extracts exact placement from the head-light control mold."}
			if racquet_type == "Lead Tape 3 and 9":
				return {"modifiers": {"control_accuracy_bonus": 0.03, "guard_bonus": 1}, "note": "The Master uses side-balanced tape for precision without losing poise."}
		&"alcaraz":
			if racquet_type == "Extra-Long Lever":
				return {"modifiers": {"serve_pressure_bonus": 2, "topspin_pressure_bonus": 3, "net_pressure_bonus": 1}, "note": "The extra-long lever amplifies Alcaraz-style burst and spin."}
			if racquet_type == "Lead Tape 12":
				return {"modifiers": {"serve_pressure_bonus": 2, "power_pressure_bonus": 2, "topspin_pressure_bonus": 1}, "note": "Top-loaded tape adds explosive lift to the Alcaraz build."}
	return {}

func _merge_modifier_tables(base_modifiers: Dictionary, extra_modifiers: Dictionary) -> Dictionary:
	var merged := base_modifiers.duplicate(true)
	for modifier_name in extra_modifiers.keys():
		var existing_value = merged.get(modifier_name, 0)
		var extra_value = extra_modifiers[modifier_name]
		if typeof(existing_value) == TYPE_FLOAT or typeof(extra_value) == TYPE_FLOAT:
			merged[modifier_name] = float(existing_value) + float(extra_value)
		else:
			merged[modifier_name] = int(existing_value) + int(extra_value)
	return merged

func _has_relic(relic_id: String) -> bool:
	return relic_ids.has(relic_id)

func _relic_bonus(effect_name: String) -> int:
	var total := 0
	for relic_id in relic_ids:
		var relic = _relic_database.call("get_relic", StringName(relic_id))
		if relic != null:
			total += int(relic.effects.get(effect_name, 0))
	return total

func _relic_float_bonus(effect_name: String) -> float:
	var total := 0.0
	for relic_id in relic_ids:
		var relic = _relic_database.call("get_relic", StringName(relic_id))
		if relic != null:
			total += float(relic.effects.get(effect_name, 0.0))
	return total

func _boss_should_take_changeover() -> bool:
	if encounter_type != "boss" or _boss_changeover_used_this_game:
		return false
	if turn_number < 2:
		return false
	var heavy_player_pressure: bool = rally_state.rp >= 60
	var enemy_is_wobbling: bool = enemy.current_condition <= int(round(float(enemy.max_condition) * 0.45))
	return heavy_player_pressure or enemy_is_wobbling

func _resolve_boss_changeover() -> void:
	_boss_changeover_used_this_game = true
	var heal_amount: int = 8 + enemy_def.act * 3 + enemy_games_won * 2
	var guard_amount: int = 8 + enemy_def.act * 2
	var healed: int = enemy.restore_condition(heal_amount)
	enemy.guard += guard_amount
	enemy.set_status("fatigue", maxi(0, enemy.get_status("fatigue") - 1))
	enemy.add_status("next_turn_momentum", 1)
	_log_line("%s takes a changeover: +%d Condition, +%d Guard, reset footwork." % [enemy.display_name, healed, guard_amount])
