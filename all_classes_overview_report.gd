## all_classes_overview_report.gd
## Full-sweep simulation across all 9 classes, 15 seeds each (same seeds for cross-class comparison).
## Outputs per-class stats then an aggregated balance table.
## Run: Godot --headless --script scripts/tests/all_classes_overview_report.gd
extends SceneTree

const RunStateScript   = preload("res://scripts/systems/run_state.gd")
const CardDatabaseScript = preload("res://scripts/data/card_database.gd")
const RelicDatabaseScript = preload("res://scripts/data/relic_database.gd")

const SIM_SEED_START  := 5001
const SIM_SEED_COUNT  := 15
const MAX_SIM_STEPS   := 4500
const MAX_COMBAT_STEPS := 900

# Classes in unlock order — novice is first, alcaraz is last
const CLASS_ORDER := [
	&"novice", &"pusher", &"slicer", &"power", &"all_arounder",
	&"baseliner", &"serve_and_volley", &"master", &"alcaraz",
]

# ---------------------------------------------------------------------------
# Per-class sim profiles: preferred_cards, preferred_tags, preferred_relics,
# aggression (0.0=very defensive → 1.0=very aggressive)
# ---------------------------------------------------------------------------
const CLASS_PROFILES: Dictionary = {
	&"novice": {
		"preferred_cards": [
			"steady_serve","deep_return","crosscourt_rally","recover_breath",
			"split_step","backhand_redirect","endurance_training","block_return",
			"chip_return","multifilament_touch","synthetic_gut_setup",
		],
		"preferred_tags": ["return","rally","recovery","control","footwork","training","volley"],
		"preferred_relics": [
			"serve_scout_notes","return_coach","big_sweet_spot","fresh_grips",
			"compression_sleeve","wristband","practice_cones","mental_coach",
			"physio_kit","champions_towel",
		],
		"aggression": 0.3,
		"heal_threshold": 0.72,   # heals at rest if condition below this fraction
		"upgrade_threshold": 0.55, # upgrades at rest if condition above this fraction
	},
	&"pusher": {
		"preferred_cards": [
			"deep_return","moonball_reset","relentless_return","crosscourt_rally",
			"block_return","recover_breath","kick_serve","split_step","endurance_training",
			"counterweighted_handle","multifilament_touch",
		],
		"preferred_tags": ["return","rally","control","recovery","footwork","attrition"],
		"preferred_relics": [
			"return_coach","compression_sleeve","physio_kit","mental_coach",
			"wristband","big_sweet_spot","fresh_grips","practice_cones",
		],
		"aggression": 0.25,
		"heal_threshold": 0.78,
		"upgrade_threshold": 0.60,
	},
	&"slicer": {
		"preferred_cards": [
			"slice_drag","drop_shot","chip_return","lob_escape","crosscourt_rally",
			"block_return","recover_breath","split_step","natural_gut_lacing",
			"polyester_bed","backhand_redirect",
		],
		"preferred_tags": ["slice","control","drop","lob","footwork","return"],
		"preferred_relics": [
			"slice_specialist","polyester_strings","physio_kit","fresh_grips",
			"mental_coach","big_sweet_spot","compression_sleeve","wristband",
		],
		"aggression": 0.35,
		"heal_threshold": 0.75,
		"upgrade_threshold": 0.55,
	},
	&"power": {
		"preferred_cards": [
			"flat_cannon","ace_hunter","kick_serve","steady_serve","deep_return",
			"block_return","recover_breath","split_step","endurance_training",
			"hybrid_string_job","kevlar_coil",
		],
		"preferred_tags": ["power","serve","return","tempo","signature"],
		"preferred_relics": [
			"lead_tape","hybrid_strings","serve_clock","titanium_frame",
			"big_sweet_spot","opening_ace","mental_coach","return_coach",
		],
		"aggression": 0.72,
		"heal_threshold": 0.55,
		"upgrade_threshold": 0.45,
	},
	&"all_arounder": {
		"preferred_cards": [
			"topspin_drive","slice_drag","approach_shot","deep_return","steady_serve",
			"backhand_redirect","basic_volley","split_step","recover_breath",
			"crosscourt_rally","down_the_line",
		],
		"preferred_tags": ["topspin","slice","net","return","rally","footwork","control"],
		"preferred_relics": [
			"serve_scout_notes","return_coach","big_sweet_spot","grass_specialist",
			"clay_specialist","mental_coach","physio_kit","practice_cones",
		],
		"aggression": 0.50,
		"heal_threshold": 0.68,
		"upgrade_threshold": 0.52,
	},
	&"baseliner": {
		"preferred_cards": [
			"topspin_drive","inside_out_forehand","backhand_redirect","crosscourt_rally",
			"down_the_line","deep_return","steady_serve","split_step","recover_breath",
			"polyester_bed","lead_tape_3_and_9",
		],
		"preferred_tags": ["topspin","rally","forehand","crosscourt","down_the_line","control"],
		"preferred_relics": [
			"clay_specialist","polyester_strings","big_sweet_spot","mental_coach",
			"return_coach","compression_sleeve","practice_cones","wristband",
		],
		"aggression": 0.55,
		"heal_threshold": 0.65,
		"upgrade_threshold": 0.50,
	},
	&"serve_and_volley": {
		"preferred_cards": [
			"kick_serve","net_rush","basic_volley","chip_return","approach_shot",
			"deep_return","block_return","recover_breath","split_step",
			"hybrid_string_job","lead_tape_12",
		],
		"preferred_tags": ["serve","net","volley","tempo","return","footwork"],
		"preferred_relics": [
			"grass_specialist","serve_clock","split_step_timer","opening_ace",
			"mental_coach","big_sweet_spot","physio_kit","titanium_frame",
		],
		"aggression": 0.65,
		"heal_threshold": 0.60,
		"upgrade_threshold": 0.48,
	},
	&"master": {
		"preferred_cards": [
			"masterclass","backhand_redirect","down_the_line","backhand_counter_return",
			"deep_return","steady_serve","split_step","recover_breath",
			"natural_gut_lacing","head_light_control_frame",
		],
		"preferred_tags": ["control","return","down_the_line","retain","signature","tempo"],
		"preferred_relics": [
			"mental_coach","return_coach","serve_scout_notes","big_sweet_spot",
			"fresh_grips","compression_sleeve","practice_cones","physio_kit",
		],
		"aggression": 0.45,
		"heal_threshold": 0.65,
		"upgrade_threshold": 0.50,
	},
	&"alcaraz": {
		"preferred_cards": [
			"elastic_chase","highlight_reel","inside_out_forehand","backhand_redirect",
			"net_rush","topspin_drive","kick_serve","deep_return","second_wind",
			"hybrid_string_job","lead_tape_12",
		],
		"preferred_tags": ["signature","footwork","net","topspin","power","serve","tempo"],
		"preferred_relics": [
			"big_sweet_spot","grass_specialist","lead_tape","titanium_frame",
			"serve_clock","mental_coach","opening_ace","split_step_timer",
		],
		"aggression": 0.80,
		"heal_threshold": 0.52,
		"upgrade_threshold": 0.40,
	},
}

var _card_db  = CardDatabaseScript.new()
var _relic_db = RelicDatabaseScript.new()
var _current_class_id: StringName = &"novice"

# ---------------------------------------------------------------------------
func _initialize() -> void:
	var seeds: Array = []
	for i in range(SIM_SEED_COUNT):
		seeds.append(SIM_SEED_START + i)

	print("\n" + "=".repeat(72))
	print("  COURT OF CHAOS — ALL-CLASS OVERVIEW SIMULATION")
	print("  Seeds %d–%d  (%d runs per class, %d total)" % [
		SIM_SEED_START, SIM_SEED_START + SIM_SEED_COUNT - 1,
		SIM_SEED_COUNT, SIM_SEED_COUNT * CLASS_ORDER.size(),
	])
	print("=".repeat(72))

	var summary_rows: Array = []

	for class_id in CLASS_ORDER:
		_current_class_id = class_id
		var class_results := _run_class(class_id, seeds)
		summary_rows.append(class_results)
		_print_class_section(class_id, class_results)

	_print_summary_table(summary_rows)
	quit(0)

# ---------------------------------------------------------------------------
func _run_class(class_id: StringName, seeds: Array) -> Dictionary:
	var wins := 0
	var total_acts_reached: Array = [0, 0, 0, 0, 0]  # index = act 1-4, [0] unused
	var sum_cond_wins := 0
	var sum_cond_all := 0
	var sum_btc_all := 0
	var sum_deck_all := 0
	var sum_relics_wins := 0
	var sum_removals := 0
	var worst_death := {"act": 0, "seed": -1, "cond": 0, "reason": ""}
	var best_win := {"seed": -1, "cond": 0, "btc": 0, "deck": 0, "relics": 0}
	var per_seed: Array = []

	for seed in seeds:
		_current_class_id = class_id
		var result := _simulate_full_tour(class_id, seed)
		per_seed.append(result)
		var success := bool(result.get("success", false))
		var act := int(result.get("final_act", 1))
		var cond := int(result.get("condition", 0))
		var btc := int(result.get("bitcoin", 0))
		var deck := int(result.get("deck_size", 0))
		var relics := int(result.get("relic_count", 0))
		var removals := int(result.get("deck_removals", 0))

		sum_cond_all += cond
		sum_btc_all  += btc
		sum_deck_all += deck
		sum_removals += removals
		if act >= 1 and act <= 4:
			total_acts_reached[act] += 1

		if success:
			wins += 1
			sum_cond_wins += cond
			sum_relics_wins += relics
			if cond > best_win.get("cond", 0):
				best_win = {"seed": seed, "cond": cond, "btc": btc, "deck": deck, "relics": relics}
		else:
			if act > worst_death.get("act", 0):
				worst_death = {"act": act, "seed": seed, "cond": cond,
					"reason": String(result.get("reason", ""))}

	var n := float(SIM_SEED_COUNT)
	return {
		"class_id": String(class_id),
		"wins": wins,
		"win_rate": float(wins) / n,
		"deaths_by_act": total_acts_reached,
		"avg_cond_all": float(sum_cond_all) / n,
		"avg_cond_wins": float(sum_cond_wins) / float(maxi(1, wins)),
		"avg_btc": float(sum_btc_all) / n,
		"avg_deck": float(sum_deck_all) / n,
		"avg_relics_wins": float(sum_relics_wins) / float(maxi(1, wins)),
		"avg_removals": float(sum_removals) / n,
		"worst_death": worst_death,
		"best_win": best_win,
		"per_seed": per_seed,
	}

# ---------------------------------------------------------------------------
func _simulate_full_tour(class_id: StringName, seed: int) -> Dictionary:
	var run_state = RunStateScript.new()
	run_state.start_new_run(class_id, seed)
	var safety := 0

	while safety < MAX_SIM_STEPS and not bool(run_state.run_failed) and not bool(run_state.run_complete):
		safety += 1
		if bool(run_state.has_reveal()):
			run_state.dismiss_reveal()
		match String(run_state.phase):
			"map":
				var next_id := _choose_route(run_state)
				if next_id < 0:
					break
				run_state.select_node(next_id)
			"combat":
				if not _autoplay_match(run_state):
					return _failure(seed, run_state, "Lost a match.")
			"reward":
				_handle_reward(run_state)
			"run_lost", "idle":
				break
			_:
				break

	if bool(run_state.run_complete) or String(run_state.phase) == "run_won":
		return {
			"success": true,
			"seed": seed,
			"condition": int(run_state.current_condition),
			"bitcoin": int(run_state.bitcoin),
			"deck_size": int(run_state.deck_card_ids.size()),
			"relic_count": int(run_state.relic_ids.size()),
			"deck_removals": int(run_state.deck_removal_count),
			"final_act": 4,
		}
	return _failure(seed, run_state, String(run_state.status_message))

func _failure(seed: int, run_state, reason: String) -> Dictionary:
	return {
		"success": false,
		"seed": seed,
		"reason": reason,
		"final_act": int(run_state.current_act),
		"condition": int(run_state.current_condition),
		"bitcoin": int(run_state.bitcoin),
		"deck_size": int(run_state.deck_card_ids.size()),
		"relic_count": int(run_state.relic_ids.size()),
		"deck_removals": int(run_state.deck_removal_count),
	}

# ---------------------------------------------------------------------------
# Route selection — class aggression shifts elite vs rest preference
# ---------------------------------------------------------------------------
func _choose_route(run_state) -> int:
	var best_id := -1
	var best_score := -1e9
	for nid in run_state.accessible_node_ids:
		var node = run_state.get_node(int(nid))
		if node == null:
			continue
		var s := _route_score(run_state, node)
		if s > best_score:
			best_score = s
			best_id = int(node.id)
	return best_id

func _route_score(run_state, node) -> float:
	var t := String(node.node_type)
	var profile := Dictionary(CLASS_PROFILES.get(_current_class_id, {}))
	var aggression := float(profile.get("aggression", 0.5))
	var cond_ratio := 1.0
	if int(run_state.max_condition) > 0:
		cond_ratio = float(run_state.current_condition) / float(run_state.max_condition)
	var score := float(int(node.floor)) * 0.3
	match t:
		"boss":
			score += 1000.0
		"elite":
			# Aggressive classes like fighting elites; cautious classes avoid when hurt
			var elite_val := 60.0 + aggression * 30.0
			score += elite_val if cond_ratio >= (0.70 - aggression * 0.2) else 30.0
		"regular":
			score += 60.0
		"treasure":
			score += 58.0
		"shop":
			score += 62.0 if int(run_state.bitcoin) >= 14 else 28.0
		"rest":
			var heal_thresh := float(profile.get("heal_threshold", 0.68))
			score += 90.0 if cond_ratio <= heal_thresh else 22.0
		"event":
			score += 38.0
		_:
			score += 10.0
	return score

# ---------------------------------------------------------------------------
# Combat autoplay
# ---------------------------------------------------------------------------
func _autoplay_match(run_state) -> bool:
	var guard := 0
	while guard < MAX_COMBAT_STEPS and String(run_state.phase) == "combat" and run_state.active_match != null:
		guard += 1
		var m = run_state.active_match
		if String(m.state) == "player_turn":
			var played_any := false
			while run_state.active_match != null and String(run_state.active_match.state) == "player_turn":
				var best_idx := _best_card_index(run_state.active_match)
				if best_idx < 0:
					break
				var played := bool(run_state.play_card(best_idx))
				if not played:
					break
				played_any = true
				if String(run_state.phase) != "combat" or run_state.active_match == null:
					break
			if run_state.active_match != null and String(run_state.active_match.state) == "player_turn":
				run_state.end_player_turn()
			elif not played_any:
				run_state.end_player_turn()
		else:
			run_state.end_player_turn()
	return String(run_state.phase) in ["reward", "run_won"]

func _best_card_index(active_match) -> int:
	var hand_display: Array = active_match.get_hand_display()
	var best_idx := -1
	var best_score := -1e9
	for i in range(mini(active_match.hand.size(), hand_display.size())):
		var cv := Dictionary(hand_display[i])
		if not bool(cv.get("playable", true)):
			continue
		var ci = active_match.hand[i]
		var cd = _card_db.get_card(ci.card_id)
		if cd == null:
			continue
		var cost := int(cv.get("cost", active_match.get_card_cost(ci)))
		var s := _combat_score(active_match, cd, cost)
		if s > best_score:
			best_score = s
			best_idx = i
	return best_idx

func _combat_score(active_match, card_def, cost: int) -> float:
	var effects := Dictionary(card_def.effects)
	var tags := PackedStringArray(card_def.tags)
	var dmg := int(effects.get("damage", 0))
	if effects.has("multi_hit"):
		for hv in PackedInt32Array(effects.get("multi_hit", PackedInt32Array())):
			dmg += int(hv)
	var score := 0.0
	score += float(dmg) * 2.9
	score += float(int(effects.get("guard", 0))) * 1.8
	score += float(int(effects.get("heal", 0))) * (3.0 if int(active_match.player.current_condition) < int(active_match.player.max_condition) - 5 else 1.1)
	score += float(int(effects.get("draw", 0)) + int(effects.get("combo_draw", 0))) * 2.2
	score += float(int(effects.get("momentum", 0)) + int(effects.get("first_footwork_momentum", 0))) * 2.7
	score += float(int(effects.get("focus", 0))) * 2.4
	score += float(int(effects.get("pressure", 0)) + int(effects.get("open_court", 0))) * 1.9
	score += float(int(effects.get("spin", 0))) * 1.4
	score += float(int(effects.get("retain_bonus", 0)) + int(effects.get("endurance_scaling", 0))) * 2.0
	score += float(int(effects.get("next_turn_stamina", 0))) * 2.5
	# Situational bonuses
	if tags.has("serve") and String(active_match.current_server) == "player" and int(active_match.rally_state.exchanges) == 0:
		score += 4.5
	if tags.has("return") and String(active_match.current_server) == "enemy" and int(active_match.rally_state.exchanges) == 0:
		score += 5.2
	if tags.has("net") and String(active_match.rally_state.player_position) in ["ServiceLine", "Net"]:
		score += 2.5
	if tags.has("modifier"):
		score += 16.0 if String(active_match._active_string_name) == "" else 2.5
	# Closing pressure: go harder when near winning the point
	if int(active_match.rally_state.rp) >= int(active_match.rally_pressure_target) - 14:
		score += float(dmg) * 1.2 + float(int(effects.get("pressure", 0))) * 0.8
	# Defensive urgency: guard more when losing ground
	if int(active_match.rally_state.rp) <= -20:
		score += float(int(effects.get("guard", 0))) * 2.0 + float(int(effects.get("heal", 0))) * 1.6
	# Class bias
	score += _class_card_bias(String(card_def.id), tags, true)
	score -= float(cost) * 0.80
	return score

# ---------------------------------------------------------------------------
# Reward handling
# ---------------------------------------------------------------------------
func _handle_reward(run_state) -> void:
	var kind := String(run_state.get_reward_menu_kind())
	match kind:
		"shop":
			_handle_shop(run_state)
		"rest":
			_handle_rest(run_state)
		_:
			var idx := _best_reward_index(run_state)
			if idx >= 0:
				run_state.choose_reward(idx)
			else:
				run_state.skip_reward()

func _handle_rest(run_state) -> void:
	var profile := Dictionary(CLASS_PROFILES.get(_current_class_id, {}))
	var heal_thresh := float(profile.get("heal_threshold", 0.68))
	var upgrade_thresh := float(profile.get("upgrade_threshold", 0.52))
	var cond_ratio := 0.0
	if int(run_state.max_condition) > 0:
		cond_ratio = float(run_state.current_condition) / float(run_state.max_condition)
	var choices: Array = run_state.get_reward_choices()
	# Index 0 is always rest_heal; subsequent entries are upgrades or endurance
	if cond_ratio <= heal_thresh:
		run_state.choose_reward(0)
		return
	# Condition is good — pick best non-heal option
	var best_idx := 0  # fallback to heal
	var best_score := -1e9
	for i in range(choices.size()):
		var choice := Dictionary(choices[i])
		var rt := String(choice.get("reward_type", ""))
		var s := -1e9
		match rt:
			"rest_heal":
				# Only prefer heal if really hurt
				s = 22.0 if cond_ratio <= heal_thresh else 5.0
			"reward_upgrade":
				s = _upgrade_value(choice) + (12.0 if cond_ratio >= upgrade_thresh else -2.0)
			"rest_endurance":
				s = 14.0 if int(run_state.max_condition) < 95 else 4.0
			"rest_focus":
				s = 8.0
		if s > best_score:
			best_score = s
			best_idx = i
	run_state.choose_reward(best_idx)

func _upgrade_value(choice: Dictionary) -> float:
	var base_v := _card_value(String(choice.get("base_card_id", "")))
	var up_v   := _card_value(String(choice.get("upgraded_card_id", "")))
	return (up_v - base_v) * 1.4

func _handle_shop(run_state) -> void:
	var purchases := 0
	while String(run_state.phase) == "reward" and String(run_state.get_reward_menu_kind()) == "shop" and purchases < 5:
		var choices: Array = run_state.get_reward_choices()
		var best_idx := -1
		var best_score := 1.5  # minimum worthwhile threshold (lowered to reduce BTC hoarding)
		for i in range(choices.size()):
			var choice := Dictionary(choices[i])
			var rt := String(choice.get("reward_type", ""))
			var s := -1e9
			var price := int(choice.get("price_btc", 0))
			if price > int(run_state.bitcoin):
				continue
			match rt:
				"shop_card":
					s = _card_value(String(choice.get("card_id", ""))) - float(price) * 0.38
				"card_upgrade":
					s = _upgrade_value(choice) - float(price) * 0.34
				"shop_relic":
					s = _relic_value(String(choice.get("relic_id", ""))) - float(price) * 0.27
				"shop_remove":
					# Fire aggressively at deck>=23; base score raised so it beats threshold even at small decks
					var bloat := maxi(0, int(run_state.deck_card_ids.size()) - 20)
					s = 14.0 + float(bloat) * 2.2 - float(price) * 0.22
				"shop_potion":
					s = 5.5 - float(price) * 0.21
				"racquet_upgrade":
					s = 8.0 + float(int(run_state.racquet_tuning_level)) * 2.0 - float(price) * 0.28
			if s > best_score:
				best_score = s
				best_idx = i
		if best_idx < 0:
			break
		run_state.choose_reward(best_idx)
		purchases += 1
	if String(run_state.phase) == "reward" and String(run_state.get_reward_menu_kind()) == "shop":
		run_state.skip_reward()

func _best_reward_index(run_state) -> int:
	var choices: Array = run_state.get_reward_choices()
	var best_idx := -1
	var best_score := -1e9
	for i in range(choices.size()):
		var choice := Dictionary(choices[i])
		var rt := String(choice.get("reward_type", "card"))
		var s := -1e9
		match rt:
			"card":
				# Penalise taking a card if deck is already large — 1.2 per card over 22 (was 0.6)
				var bloat_penalty := float(maxi(0, int(run_state.deck_card_ids.size()) - 22)) * 1.2
				s = _card_value(String(choice.get("card_id", ""))) - bloat_penalty
			"relic":
				s = _relic_value(String(choice.get("relic_id", "")))
			"card_upgrade", "reward_upgrade":
				s = _upgrade_value(choice)
			"deck_trim":
				s = -_card_value(String(choice.get("card_id", ""))) + 4.0
			"rest_heal":
				s = 20.0 if int(run_state.current_condition) < int(run_state.max_condition) - 8 else 7.0
			"rest_endurance":
				s = 13.0 if int(run_state.max_condition) < 95 else 3.0
			"chest_gold":
				s = float(int(choice.get("gold_amount", 0))) * 0.35
		if s > best_score:
			best_score = s
			best_idx = i
	return best_idx

# ---------------------------------------------------------------------------
# Scoring helpers
# ---------------------------------------------------------------------------
func _card_value(card_id: String) -> float:
	if card_id == "":
		return -1000.0
	var card = _card_db.get_card(StringName(card_id))
	if card == null:
		return -1000.0
	var effects := Dictionary(card.effects)
	var tags := PackedStringArray(card.tags)
	var dmg := int(effects.get("damage", 0))
	if effects.has("multi_hit"):
		for hv in PackedInt32Array(effects.get("multi_hit", PackedInt32Array())):
			dmg += int(hv)
	var v := 0.0
	v += float(dmg) * 2.7
	v += float(int(effects.get("guard", 0))) * 1.6
	v += float(int(effects.get("draw", 0)) + int(effects.get("combo_draw", 0)) + int(effects.get("draw_if_pressured", 0))) * 2.0
	v += float(int(effects.get("momentum", 0)) + int(effects.get("focus", 0))) * 2.3
	v += float(int(effects.get("pressure", 0)) + int(effects.get("spin", 0)) + int(effects.get("open_court", 0))) * 1.8
	v += float(int(effects.get("heal", 0))) * 2.2
	v += float(int(effects.get("retain_bonus", 0)) + int(effects.get("endurance_scaling", 0)) + int(effects.get("next_turn_stamina", 0))) * 2.0
	if tags.has("modifier"):
		v += 10.0
	if tags.has("signature"):
		v += 3.0
	if tags.has("return"):
		v += 1.8
	if tags.has("serve"):
		v += 1.0
	v += _class_card_bias(card_id, tags, false)
	if bool(effects.get("exhaust", false)):
		v -= 1.0
	v -= float(int(card.cost)) * 0.72
	return v

func _relic_value(relic_id: String) -> float:
	if relic_id == "":
		return -1000.0
	var relic = _relic_db.get_relic(StringName(relic_id))
	if relic == null:
		return -1000.0
	var effects := Dictionary(relic.effects)
	var v := 6.0
	v += float(int(effects.get("extra_card_reward_choice", 0))) * 12.0
	v += float(int(effects.get("opening_draw", 0))) * 10.0
	v += float(int(effects.get("opening_point_stamina", 0))) * 9.0
	v += float(int(effects.get("max_stamina_bonus", 0))) * 10.0
	v += float(int(effects.get("heal_after_encounter", 0))) * 4.5
	v += float(int(effects.get("heal_after_elite", 0)) + int(effects.get("heal_after_boss", 0))) * 3.7
	v += float(int(effects.get("extra_fatigue_decay", 0))) * 6.0
	v += float(int(effects.get("extra_spin", 0))) * 4.0
	v += float(int(effects.get("slice_focus", 0)) + int(effects.get("focus_after_three_cards", 0))) * 5.5
	v += float(int(effects.get("opening_guard", 0))) * 2.4
	v += float(int(effects.get("net_pressure_bonus", 0))) * 0.8
	v += float(int(effects.get("signature_pressure_bonus", 0))) * 0.9
	v += float(int(effects.get("serve_cost_reduction", 0))) * 6.0
	v += float(int(effects.get("long_rally_bonus_stamina", 0))) * 7.0
	v += float(int(effects.get("deuce_focus", 0)) + int(effects.get("deuce_momentum", 0))) * 5.0
	v += float(effects.get("global_accuracy_bonus", 0.0)) * 90.0
	v += float(effects.get("first_serve_accuracy", 0.0)) * 40.0
	v += float(effects.get("power_pressure_bonus", 0.0)) * 20.0
	if bool(effects.get("player_serves_first", false)):
		v += 5.0
	# Per-class preferred relic bonus
	var preferred := PackedStringArray(Dictionary(CLASS_PROFILES.get(_current_class_id, {})).get("preferred_relics", PackedStringArray()))
	if preferred.has(relic_id):
		v += 18.0
	return v

func _class_card_bias(card_id: String, tags: PackedStringArray, combat: bool) -> float:
	var profile := Dictionary(CLASS_PROFILES.get(_current_class_id, {}))
	var preferred_cards := PackedStringArray(profile.get("preferred_cards", PackedStringArray()))
	var preferred_tags  := PackedStringArray(profile.get("preferred_tags", PackedStringArray()))
	var s := 0.0
	if preferred_cards.has(card_id):
		s += 12.0 if combat else 16.0
	for tag in preferred_tags:
		if tags.has(tag):
			s += 2.0 if combat else 3.4
	return s

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
func _print_class_section(class_id: StringName, data: Dictionary) -> void:
	var wins := int(data.get("wins", 0))
	var n := SIM_SEED_COUNT
	var win_rate := float(data.get("win_rate", 0.0)) * 100.0
	var deaths := Array(data.get("deaths_by_act", [0, 0, 0, 0, 0]))
	var avg_cond  := float(data.get("avg_cond_all", 0.0))
	var avg_btc   := float(data.get("avg_btc", 0.0))
	var avg_deck  := float(data.get("avg_deck", 0.0))
	var avg_rm    := float(data.get("avg_removals", 0.0))

	print("\n" + "-".repeat(60))
	print("  CLASS: %s" % String(class_id).to_upper())
	print("-".repeat(60))
	print("  Wins: %d / %d  (%.0f%%)" % [wins, n, win_rate])
	print("  Deaths by act:  Act1=%d  Act2=%d  Act3=%d  Act4=%d" % [
		deaths[1], deaths[2], deaths[3], deaths[4],
	])
	print("  Avg cond at end: %.1f   Avg BTC leftover: %.0f" % [avg_cond, avg_btc])
	print("  Avg deck size: %.1f    Avg removals taken: %.1f" % [avg_deck, avg_rm])
	if wins > 0:
		var bw := Dictionary(data.get("best_win", {}))
		print("  Best win:  seed %d  cond=%d  btc=%d  deck=%d  relics=%d" % [
			int(bw.get("seed", 0)), int(bw.get("cond", 0)), int(bw.get("btc", 0)),
			int(bw.get("deck", 0)), int(bw.get("relics", 0)),
		])
	else:
		var wd := Dictionary(data.get("worst_death", {}))
		print("  Furthest:  seed %d  act=%d  cond=%d" % [
			int(wd.get("seed", 0)), int(wd.get("act", 0)), int(wd.get("cond", 0)),
		])

	# Per-seed rows
	print("  Seed results:")
	for result in Array(data.get("per_seed", [])):
		var r := Dictionary(result)
		var ok := bool(r.get("success", false))
		var s := int(r.get("seed", 0))
		var c := int(r.get("condition", 0))
		var b := int(r.get("bitcoin", 0))
		var dk := int(r.get("deck_size", 0))
		var rl := int(r.get("relic_count", 0))
		var rm := int(r.get("deck_removals", 0))
		var act := int(r.get("final_act", 0))
		if ok:
			print("    %d  WIN   cond=%d  btc=%d  deck=%d  relics=%d  removals=%d" % [s, c, b, dk, rl, rm])
		else:
			print("    %d  fail  act=%d  cond=%d  btc=%d  deck=%d" % [s, act, c, b, dk])

func _print_summary_table(rows: Array) -> void:
	print("\n" + "=".repeat(72))
	print("  BALANCE OVERVIEW — ALL CLASSES")
	print("=".repeat(72))
	print("  %-18s  %4s  %5s  %5s  %5s  %5s  %5s" % [
		"Class", "Wins", "WR%", "AvgCnd", "AvgBTC", "AvgDck", "AvgRm",
	])
	print("  " + "-".repeat(58))
	for row in rows:
		var r := Dictionary(row)
		print("  %-18s  %4d  %5.0f  %5.1f  %5.0f  %5.1f  %5.1f" % [
			String(r.get("class_id", "")),
			int(r.get("wins", 0)),
			float(r.get("win_rate", 0.0)) * 100.0,
			float(r.get("avg_cond_all", 0.0)),
			float(r.get("avg_btc", 0.0)),
			float(r.get("avg_deck", 0.0)),
			float(r.get("avg_removals", 0.0)),
		])
	print("=".repeat(72))
	print("\nNotes for balance pass:")
	print("  Target win rate: 25-35% (novice), 35-50% (mid), 45-60% (alcaraz)")
	print("  BTC >80 avg = economy underuse  |  Deck >28 avg = draft bloat")
	print("  Cond <10 avg = attrition too punishing  |  Removals <0.5 = shop remove underused")
