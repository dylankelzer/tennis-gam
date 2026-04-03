extends SceneTree

const RunStateScript = preload("res://scripts/systems/run_state.gd")
const CardDatabaseScript = preload("res://scripts/data/card_database.gd")
const RelicDatabaseScript = preload("res://scripts/data/relic_database.gd")

const SEEDS := [1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010,
				1011, 1012, 1013, 1014, 1015, 1016, 1017, 1018, 1019, 1020]
const MAX_SIM_STEPS := 3600
const MAX_COMBAT_STEPS := 750
const CLASS_ID := &"novice"

const NOVICE_PROFILE := {
	"preferred_cards": [
		"steady_serve", "deep_return", "crosscourt_rally", "recover_breath",
		"split_step", "backhand_redirect", "endurance_training", "block_return",
		"chip_return", "multifilament_touch", "synthetic_gut_setup",
	],
	"preferred_tags": ["return", "rally", "recovery", "control", "footwork", "training", "volley"],
	"preferred_relics": [
		"serve_scout_notes", "return_coach", "big_sweet_spot", "fresh_grips",
		"compression_sleeve", "wristband", "practice_cones", "mental_coach",
		"physio_kit", "champions_towel",
	],
}

var _card_db = CardDatabaseScript.new()
var _relic_db = RelicDatabaseScript.new()

func _initialize() -> void:
	var wins := 0
	var total_condition_on_wins := 0
	var best_win_condition := -1
	var act_death_counts := {1: 0, 2: 0, 3: 0, 4: 0}
	var all_results: Array = []

	print("\n=== NOVICE 20-RUN SIMULATION (post-fix) ===\n")

	for seed in SEEDS:
		var result := _simulate_full_tour(seed)
		all_results.append(result)
		var success := bool(result.get("success", false))
		var seed_val := int(result.get("seed", seed))
		var condition := int(result.get("condition", 0))
		var act := int(result.get("final_act", 0))
		var deck_size := int(result.get("deck_size", 0))
		var bitcoin := int(result.get("bitcoin", 0))
		var relics := PackedStringArray(result.get("relics", PackedStringArray()))
		var acquired := PackedStringArray(result.get("acquired_cards", PackedStringArray()))
		var reason := String(result.get("reason", ""))
		var modifier_count := int(result.get("modifier_cards_in_deck", 0))

		if success:
			wins += 1
			total_condition_on_wins += condition
			best_win_condition = maxi(best_win_condition, condition)
			print("SEED %d  ✓ WIN   Cond %d  BTC %d  Deck %d  Modifiers %d  Relics [%s]" % [
				seed_val, condition, bitcoin, deck_size, modifier_count,
				", ".join(relics),
			])
		else:
			act_death_counts[act] = act_death_counts.get(act, 0) + 1
			print("SEED %d  ✗ FAIL  Act %d  Cond %d  BTC %d  Deck %d  Reason: %s" % [
				seed_val, act, condition, bitcoin, deck_size, reason,
			])

		if not acquired.is_empty():
			print("         Acquired: %s" % ", ".join(acquired))

	print("\n--- SUMMARY ---")
	print("Runs: %d  |  Wins: %d  |  Win Rate: %.0f%%" % [
		SEEDS.size(), wins, float(wins) / float(SEEDS.size()) * 100.0,
	])
	if wins > 0:
		print("Avg condition on wins: %.1f  |  Best: %d" % [
			float(total_condition_on_wins) / float(wins), best_win_condition,
		])
	print("Deaths by act: Act1=%d  Act2=%d  Act3=%d  Act4=%d" % [
		act_death_counts.get(1, 0), act_death_counts.get(2, 0),
		act_death_counts.get(3, 0), act_death_counts.get(4, 0),
	])
	quit(0)

func _simulate_full_tour(seed: int) -> Dictionary:
	var run_state = RunStateScript.new()
	run_state.start_new_run(CLASS_ID, seed)
	var safety := 0
	var acquired_cards: Array = []

	while safety < MAX_SIM_STEPS and not bool(run_state.run_failed) and not bool(run_state.run_complete):
		safety += 1
		if bool(run_state.has_reveal()):
			run_state.dismiss_reveal()
		match String(run_state.phase):
			"map":
				var next_node_id := _choose_route(run_state)
				if next_node_id < 0:
					break
				run_state.select_node(next_node_id)
			"combat":
				if not _autoplay_match(run_state):
					return _failure_result(seed, run_state, acquired_cards, "Lost a match.")
			"reward":
				_handle_reward_phase(run_state, acquired_cards)
			"run_lost":
				return _failure_result(seed, run_state, acquired_cards, String(run_state.status_message))
			"run_won":
				break
			_:
				break

	if bool(run_state.run_complete) or String(run_state.phase) == "run_won":
		return {
			"success": true,
			"seed": seed,
			"final_act": int(run_state.current_act),
			"condition": int(run_state.current_condition),
			"bitcoin": int(run_state.bitcoin),
			"deck_size": int(run_state.deck_card_ids.size()),
			"relics": PackedStringArray(run_state.relic_ids),
			"acquired_cards": PackedStringArray(acquired_cards),
			"modifier_cards_in_deck": _count_modifier_cards(run_state.deck_card_ids),
		}
	return _failure_result(seed, run_state, acquired_cards, "Sim limit reached.")

func _failure_result(seed: int, run_state, acquired_cards: Array, reason: String) -> Dictionary:
	return {
		"success": false,
		"seed": seed,
		"reason": reason,
		"final_act": int(run_state.current_act),
		"condition": int(run_state.current_condition),
		"bitcoin": int(run_state.bitcoin),
		"deck_size": int(run_state.deck_card_ids.size()),
		"relics": PackedStringArray(run_state.relic_ids),
		"acquired_cards": PackedStringArray(acquired_cards),
		"modifier_cards_in_deck": _count_modifier_cards(run_state.deck_card_ids),
		"progress_score": _progress_score(run_state),
	}

func _count_modifier_cards(deck_card_ids: PackedStringArray) -> int:
	var count := 0
	for card_id in deck_card_ids:
		var card = _card_db.get_card(card_id)
		if card != null and (card.tags.has("modifier") or card.tags.has("string") or card.tags.has("racquet")):
			count += 1
	return count

func _progress_score(run_state) -> float:
	var score := float(int(run_state.current_act) - 1) * 1000.0
	if int(run_state.current_node_id) >= 0:
		var node = run_state.get_node(int(run_state.current_node_id))
		if node != null:
			score += float(int(node.floor)) * 10.0
	score += float(int(run_state.current_condition)) * 0.1
	return score

func _choose_route(run_state) -> int:
	var best_node_id := -1
	var best_score := -1000000.0
	for node_id in run_state.accessible_node_ids:
		var node = run_state.get_node(int(node_id))
		if node == null:
			continue
		var score := _route_score(run_state, node)
		if score > best_score:
			best_score = score
			best_node_id = int(node.id)
	return best_node_id

func _route_score(run_state, node) -> float:
	var node_type := String(node.node_type)
	var condition_ratio := 1.0
	if int(run_state.max_condition) > 0:
		condition_ratio = float(run_state.current_condition) / float(run_state.max_condition)
	var score := float(node.floor) * 0.25
	match node_type:
		"boss": score += 1000.0
		"elite": score += 72.0 if condition_ratio >= 0.62 else 38.0
		"regular": score += 64.0
		"treasure": score += 59.0
		"shop": score += 60.0 if int(run_state.bitcoin) >= 16 else 26.0
		"rest": score += 86.0 if condition_ratio <= 0.68 else 28.0
		"event": score += 38.0
		_: score += 10.0
	if node_type == "regular" and int(node.floor) <= 2:
		score += 6.0
	return score

func _autoplay_match(run_state) -> bool:
	var guard := 0
	while guard < MAX_COMBAT_STEPS and String(run_state.phase) == "combat" and run_state.active_match != null:
		guard += 1
		var active_match = run_state.active_match
		if String(active_match.state) == "player_turn":
			var played_any := false
			while run_state.active_match != null and String(run_state.active_match.state) == "player_turn":
				var playable_index := _find_best_playable_card_index(run_state.active_match)
				if playable_index < 0:
					break
				if not bool(run_state.play_card(playable_index)):
					break
				played_any = true
				if String(run_state.phase) != "combat" or run_state.active_match == null:
					break
			if String(run_state.phase) == "combat" and run_state.active_match != null and String(run_state.active_match.state) == "player_turn":
				run_state.end_player_turn()
			elif not played_any:
				run_state.end_player_turn()
		else:
			run_state.end_player_turn()
	return String(run_state.phase) in ["reward", "run_won"]

func _find_best_playable_card_index(active_match) -> int:
	var hand_display: Array = active_match.get_hand_display()
	var best_index := -1
	var best_score := -1000000.0
	for index in range(mini(active_match.hand.size(), hand_display.size())):
		var card_view := Dictionary(hand_display[index])
		if not bool(card_view.get("playable", true)):
			continue
		var card_instance = active_match.hand[index]
		var card_def = _card_db.get_card(card_instance.card_id)
		if card_def == null:
			continue
		var cost := int(card_view.get("cost", active_match.get_card_cost(card_instance)))
		var score := _combat_card_score(active_match, card_def, cost)
		if score > best_score:
			best_score = score
			best_index = index
	return best_index

func _combat_card_score(active_match, card_def, cost: int) -> float:
	var effects := Dictionary(card_def.effects)
	var tags := PackedStringArray(card_def.tags)
	var score := 0.0
	var damage := int(effects.get("damage", 0))
	var guard := int(effects.get("guard", 0))
	var heal := int(effects.get("heal", 0))
	var draw := int(effects.get("draw", 0)) + int(effects.get("combo_draw", 0))
	var momentum := int(effects.get("momentum", 0)) + int(effects.get("first_footwork_momentum", 0))
	var focus := int(effects.get("focus", 0))
	var pressure := int(effects.get("pressure", 0))
	var spin := int(effects.get("spin", 0))
	var open_court := int(effects.get("open_court", 0))
	var retain_bonus := int(effects.get("retain_bonus", 0))
	var endurance_scaling := int(effects.get("endurance_scaling", 0))
	var next_turn_stamina := int(effects.get("next_turn_stamina", 0))
	if effects.has("multi_hit"):
		for hit_value in PackedInt32Array(effects.get("multi_hit", PackedInt32Array())):
			damage += int(hit_value)
	score += float(damage) * 2.9
	score += float(guard) * 1.8
	score += float(heal) * (3.1 if int(active_match.player.current_condition) < int(active_match.player.max_condition) else 1.0)
	score += float(draw) * 2.2
	score += float(momentum) * 2.7
	score += float(focus) * 2.4
	score += float(pressure) * 2.0
	score += float(spin) * 1.4
	score += float(open_court) * 2.0
	score += float(retain_bonus) * 1.8
	score += float(endurance_scaling) * 2.4
	score += float(next_turn_stamina) * 2.5
	if tags.has("serve") and String(active_match.current_server) == "player" and int(active_match.rally_state.exchanges) == 0:
		score += 4.4
	if tags.has("return") and String(active_match.current_server) == "enemy" and int(active_match.rally_state.exchanges) == 0:
		score += 5.2
	if tags.has("net") and String(active_match.rally_state.player_position) in ["ServiceLine", "Net"]:
		score += 2.3
	if tags.has("modifier"):
		if tags.has("string"):
			score += 16.0 if String(active_match._active_string_name) == "" else 3.0
		if tags.has("racquet") or tags.has("weight"):
			score += 15.0 if String(active_match._active_racquet_name) == "" else 3.0
	if int(active_match.rally_state.rp) >= int(active_match.rally_pressure_target) - 12:
		score += float(damage) * 1.3 + float(pressure) * 0.8
	if int(active_match.rally_state.rp) <= -18:
		score += float(guard) * 1.8 + float(heal) * 1.5
	score += _novice_card_bias(String(card_def.id), tags, true)
	score -= float(cost) * 0.82
	return score

func _handle_reward_phase(run_state, acquired_cards: Array) -> void:
	var reward_kind := String(run_state.get_reward_menu_kind())
	if reward_kind == "shop":
		_handle_shop_phase(run_state, acquired_cards)
		return
	if reward_kind == "rest":
		var current_condition := int(run_state.current_condition)
		var max_condition := maxi(1, int(run_state.max_condition))
		var rest_index := 0
		if current_condition > max_condition - 10:
			rest_index = 1 if max_condition <= 90 else 2
		var choices: Array = run_state.get_reward_choices()
		if rest_index < choices.size():
			run_state.choose_reward(rest_index)
		else:
			run_state.skip_reward()
		return
	var reward_index := _choose_best_reward_index(run_state)
	var reward_choices: Array = run_state.get_reward_choices()
	if reward_index >= 0 and reward_index < reward_choices.size():
		var choice := Dictionary(reward_choices[reward_index])
		var card_id := String(choice.get("card_id", ""))
		if card_id != "" and String(choice.get("reward_type", "")) in ["card", "shop_card"]:
			acquired_cards.append(card_id)
		run_state.choose_reward(reward_index)
	else:
		run_state.skip_reward()

func _handle_shop_phase(run_state, acquired_cards: Array) -> void:
	var purchases := 0
	while String(run_state.phase) == "reward" and String(run_state.get_reward_menu_kind()) == "shop" and purchases < 4:
		var reward_choices: Array = run_state.get_reward_choices()
		var best_index := -1
		var best_score := 2.5
		for index in range(reward_choices.size()):
			var choice := Dictionary(reward_choices[index])
			var reward_type := String(choice.get("reward_type", ""))
			var score := -1000000.0
			match reward_type:
				"shop_card":
					var price := int(choice.get("price_btc", 0))
					if price <= int(run_state.bitcoin):
						score = _card_long_term_value(String(choice.get("card_id", ""))) - float(price) * 0.38
				"card_upgrade":
					var price_upgrade := int(choice.get("price_btc", 0))
					if price_upgrade <= int(run_state.bitcoin):
						var base_val := _card_long_term_value(String(choice.get("base_card_id", "")))
						var up_val := _card_long_term_value(String(choice.get("upgraded_card_id", "")))
						score = (up_val - base_val) * 1.35 - float(price_upgrade) * 0.34
				"racquet_upgrade":
					var price_tune := int(choice.get("price_btc", 0))
					if price_tune <= int(run_state.bitcoin):
						score = 9.0 + float(int(run_state.racquet_tuning_level)) * 2.2 - float(price_tune) * 0.28
				"potion":
					var price_potion := int(choice.get("price_btc", 0))
					if price_potion <= int(run_state.bitcoin):
						score = 6.0 - float(price_potion) * 0.20
				"shop_relic":
					var price_relic := int(choice.get("price_btc", 0))
					if price_relic <= int(run_state.bitcoin):
						score = _relic_value(String(choice.get("relic_id", ""))) - float(price_relic) * 0.28
				"deck_remove":
					var price_remove := int(choice.get("price_btc", 0))
					if price_remove <= int(run_state.bitcoin):
						score = 12.0 + float(maxi(0, int(run_state.deck_card_ids.size()) - 20)) * 1.5 - float(price_remove) * 0.24
			if score > best_score:
				best_score = score
				best_index = index
		if best_index < 0:
			run_state.skip_reward()
			return
		var chosen := Dictionary(reward_choices[best_index])
		if String(chosen.get("reward_type", "")) == "shop_card":
			acquired_cards.append(String(chosen.get("card_id", "")))
		run_state.choose_reward(best_index)
		purchases += 1
	if String(run_state.phase) == "reward" and String(run_state.get_reward_menu_kind()) == "shop":
		run_state.skip_reward()

func _choose_best_reward_index(run_state) -> int:
	var reward_choices: Array = run_state.get_reward_choices()
	var best_index := -1
	var best_score := -1000000.0
	for index in range(reward_choices.size()):
		var choice := Dictionary(reward_choices[index])
		var reward_type := String(choice.get("reward_type", "card"))
		var score := -1000000.0
		match reward_type:
			"card", "shop_card":
				score = _card_long_term_value(String(choice.get("card_id", "")))
			"relic":
				score = _relic_value(String(choice.get("relic_id", "")))
			"card_upgrade", "reward_upgrade":
				var base_val := _card_long_term_value(String(choice.get("base_card_id", "")))
				var up_val := _card_long_term_value(String(choice.get("upgraded_card_id", "")))
				score = up_val - base_val
			"deck_trim":
				score = -_card_long_term_value(String(choice.get("card_id", "")))
			"rest_heal":
				score = 22.0 if int(run_state.current_condition) < int(run_state.max_condition) - 10 else 9.0
		if score > best_score:
			best_score = score
			best_index = index
	return best_index

func _card_long_term_value(card_id: String) -> float:
	var card = _card_db.get_card(StringName(card_id))
	if card == null:
		return -1000.0
	var effects := Dictionary(card.effects)
	var tags := PackedStringArray(card.tags)
	var damage := int(effects.get("damage", 0))
	if effects.has("multi_hit"):
		for hit_value in PackedInt32Array(effects.get("multi_hit", PackedInt32Array())):
			damage += int(hit_value)
	var value := 0.0
	value += float(damage) * 2.7
	value += float(int(effects.get("guard", 0))) * 1.6
	value += float(int(effects.get("draw", 0)) + int(effects.get("combo_draw", 0)) + int(effects.get("draw_if_pressured", 0))) * 2.0
	value += float(int(effects.get("momentum", 0)) + int(effects.get("focus", 0))) * 2.3
	value += float(int(effects.get("pressure", 0)) + int(effects.get("spin", 0)) + int(effects.get("open_court", 0))) * 1.8
	value += float(int(effects.get("heal", 0))) * 2.2
	value += float(int(effects.get("retain_bonus", 0)) + int(effects.get("endurance_scaling", 0)) + int(effects.get("next_turn_stamina", 0))) * 2.0
	if tags.has("modifier"): value += 10.0
	if tags.has("string"): value += 4.0
	if tags.has("racquet") or tags.has("weight"): value += 4.0
	if tags.has("signature"): value += 3.0
	if tags.has("serve"): value += 1.0
	if tags.has("return"): value += 1.6
	value += _novice_card_bias(card_id, tags, false)
	if bool(effects.get("exhaust", false)): value -= 1.1
	value -= float(int(card.cost)) * 0.75
	return value

func _relic_value(relic_id: String) -> float:
	var relic = _relic_db.get_relic(StringName(relic_id))
	if relic == null: return -1000.0
	var effects := Dictionary(relic.effects)
	var value := 6.0
	value += float(int(effects.get("extra_card_reward_choice", 0))) * 12.0
	value += float(int(effects.get("opening_draw", 0))) * 10.0
	value += float(int(effects.get("opening_point_stamina", 0))) * 9.0
	value += float(int(effects.get("max_stamina_bonus", 0))) * 10.0
	value += float(int(effects.get("heal_after_encounter", 0))) * 4.5
	value += float(int(effects.get("heal_after_elite", 0)) + int(effects.get("heal_after_boss", 0))) * 3.7
	value += float(int(effects.get("extra_fatigue_decay", 0))) * 6.0
	value += float(int(effects.get("extra_spin", 0))) * 4.0
	value += float(int(effects.get("slice_focus", 0)) + int(effects.get("focus_after_three_cards", 0))) * 5.5
	value += float(int(effects.get("opening_guard", 0))) * 2.4
	value += float(int(effects.get("net_pressure_bonus", 0))) * 0.8
	value += float(int(effects.get("signature_pressure_bonus", 0))) * 0.9
	value += float(int(effects.get("serve_cost_reduction", 0))) * 6.0
	value += float(int(effects.get("long_rally_bonus_stamina", 0))) * 7.0
	value += float(int(effects.get("deuce_focus", 0)) + int(effects.get("deuce_momentum", 0))) * 5.0
	value += float(effects.get("global_accuracy_bonus", 0.0)) * 90.0
	value += float(effects.get("first_serve_accuracy", 0.0)) * 40.0
	value += float(effects.get("power_pressure_bonus", 0.0)) * 20.0
	if bool(effects.get("player_serves_first", false)): value += 5.0
	if PackedStringArray(NOVICE_PROFILE.get("preferred_relics", PackedStringArray())).has(relic_id): value += 18.0
	return value

func _novice_card_bias(card_id: String, tags: PackedStringArray, combat_bias: bool) -> float:
	var score := 0.0
	var preferred_cards := PackedStringArray(NOVICE_PROFILE.get("preferred_cards", PackedStringArray()))
	var preferred_tags := PackedStringArray(NOVICE_PROFILE.get("preferred_tags", PackedStringArray()))
	if preferred_cards.has(card_id): score += 12.0 if combat_bias else 16.0
	for tag in preferred_tags:
		if tags.has(tag): score += 2.2 if combat_bias else 3.6
	if tags.has("power") and not tags.has("return"): score -= 0.8 if combat_bias else 1.4
	if tags.has("net") and not tags.has("control"): score -= 0.4 if combat_bias else 0.8
	return score
