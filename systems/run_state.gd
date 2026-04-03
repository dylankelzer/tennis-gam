class_name RunState
extends RefCounted

const PlayerClassDatabaseScript = preload("res://scripts/data/player_class_database.gd")
const CardDatabaseScript = preload("res://scripts/data/card_database.gd")
const EnemyDatabaseScript = preload("res://scripts/data/enemy_database.gd")
const PotionDatabaseScript = preload("res://scripts/data/potion_database.gd")
const RelicDatabaseScript = preload("res://scripts/data/relic_database.gd")
const PathGeneratorScript = preload("res://scripts/systems/path_generator.gd")
const MatchStateScript = preload("res://scripts/systems/match_state.gd")

const BASIC_REWARD_EXCLUSIONS = [
	"steady_serve",
	"crosscourt_rally",
	"basic_volley",
	"recover_breath",
]
const TOTAL_ACTS := 4
const MAX_POTIONS := 3
const SHOP_REWARD_TYPES := ["shop_card", "shop_potion", "shop_relic", "shop_remove", "card_upgrade", "racquet_upgrade"]
const ROUND_LABELS := [
	"Qualifying Round",
	"Opening Round",
	"Round of 32",
	"Round of 16",
	"Quarterfinal",
	"Semifinal",
	"Major Final",
]
const FINAL_RULE_POOL := [
	{
		"id": "no_ad_final",
		"name": "No-Ad Championship",
		"description": "Every deuce point in the final is sudden death.",
	},
	{
		"id": "server_spotlight",
		"name": "Spotlight Server",
		"description": "The server begins each point in the final with Momentum 1.",
	},
	{
		"id": "hot_streak",
		"name": "Hot Streak",
		"description": "Whoever wins a point in the final carries Momentum 1 into the next point.",
	},
	{
		"id": "pressure_cooker",
		"name": "Pressure Cooker",
		"description": "At deuce in the final, both sides open the point already under Pressure 1.",
	},
	{
		"id": "first_strike",
		"name": "First Strike",
		"description": "The first clean shot of each point in the final lands with extra force.",
	},
	{
		"id": "return_rush",
		"name": "Return Rush",
		"description": "The returner begins each point in the final with Focus 1 and Guard 4.",
	},
	{
		"id": "game_point_glare",
		"name": "Game Point Glare",
		"description": "At game point in the final, the point opens under immediate scoreboard pressure.",
	},
]
const MAJOR_DATA := {
	1: {
		"name": "Australian Open",
		"surface": "Blue Hardcourt",
		"blurb": "The run opens in Melbourne, where quick hardcourts and night-session pace punish slow starts.",
		"finale": "Survive the first slam draw and claim the Australian Open crown.",
	},
	2: {
		"name": "Roland-Garros",
		"surface": "Red Clay",
		"blurb": "Paris stretches every rally. Clay rewards depth, spin, and stubborn recovery.",
		"finale": "Outlast the grinders and monsters of Roland-Garros.",
	},
	3: {
		"name": "Wimbledon",
		"surface": "Grass",
		"blurb": "Low skids, quick hands, and net pressure define the grass bracket.",
		"finale": "Hold your nerve through the white-clad chaos of Wimbledon.",
	},
	4: {
		"name": "US Open",
		"surface": "Night Hardcourt",
		"blurb": "The final major is loud, heavy, and built for the hardest hitters in the roster.",
		"finale": "Win under the lights to take the US Open and the full tour.",
	},
}

var player_class_id: StringName = &"novice"
var seed: int = 0
var current_act: int = 0
var acts: Dictionary = {}
var deck_card_ids: PackedStringArray = PackedStringArray()
var relic_ids: PackedStringArray = PackedStringArray()
var potion_ids: PackedStringArray = PackedStringArray()
var bitcoin: int = 0
var racquet_tuning_level: int = 0
var deck_removal_count: int = 0
var max_condition: int = 0
var current_condition: int = 0
var accessible_node_ids: PackedInt32Array = PackedInt32Array()
var completed_node_ids: PackedInt32Array = PackedInt32Array()
var current_node_id: int = -1
var current_node_type: String = ""
var phase: String = "idle"
var status_message: String = "Choose a class to begin the tournament."
var pending_reward_reason: String = ""
var pending_equipment_bonus_summary: String = ""
var pending_reward_choices: Array = []
var active_match: MatchState = null
var last_match_log: String = ""
var last_match_summary: String = ""
var run_complete: bool = false
var run_failed: bool = false
var reveal_title: String = ""
var reveal_body: String = ""
var reveal_visible: bool = false
var major_contexts: Dictionary = {}
var _pending_trim_after_upgrade: bool = false
var _pending_trim_note: String = ""
var _pending_trim_return_to_shop: bool = false

var _class_database: PlayerClassDatabase = PlayerClassDatabaseScript.new()
var _card_database: CardDatabase = CardDatabaseScript.new()
var _enemy_database: EnemyDatabase = EnemyDatabaseScript.new()
var _potion_database: PotionDatabase = PotionDatabaseScript.new()
var _relic_database: RelicDatabase = RelicDatabaseScript.new()
var _path_generator: PathGenerator = PathGeneratorScript.new()
var _rng := RandomNumberGenerator.new()
var _encounter_counter: int = 0
var _advance_to_next_act_after_reward: bool = false

func start_new_run(class_id: StringName, run_seed: int = 0) -> void:
	var selected_class = _class_database.get_player_class(class_id)
	if selected_class == null:
		return

	player_class_id = class_id
	seed = run_seed if run_seed != 0 else int(Time.get_unix_time_from_system()) + Time.get_ticks_msec()
	_rng.seed = seed
	_generate_acts()
	_generate_major_contexts()
	deck_card_ids = selected_class.starting_deck.duplicate()
	relic_ids = PackedStringArray()
	potion_ids = PackedStringArray()
	bitcoin = 0
	racquet_tuning_level = 0
	deck_removal_count = 0
	max_condition = int(selected_class.base_stats.get("endurance", 70))
	current_condition = max_condition
	accessible_node_ids = PackedInt32Array()
	completed_node_ids = PackedInt32Array()
	current_node_id = -1
	current_node_type = ""
	pending_reward_reason = ""
	pending_equipment_bonus_summary = ""
	pending_reward_choices.clear()
	active_match = null
	last_match_log = ""
	last_match_summary = ""
	run_complete = false
	run_failed = false
	_encounter_counter = 0
	_advance_to_next_act_after_reward = false
	_pending_trim_after_upgrade = false
	_pending_trim_note = ""
	_pending_trim_return_to_shop = false
	_enter_act(1)

func restore_from_snapshot(snapshot: Dictionary) -> bool:
	if typeof(snapshot) != TYPE_DICTIONARY:
		return false

	var restored_class_id := StringName(String(snapshot.get("player_class_id", "novice")))
	var selected_class = _class_database.get_player_class(restored_class_id)
	var restored_seed := int(snapshot.get("seed", 0))
	if selected_class == null or restored_seed == 0:
		return false

	player_class_id = restored_class_id
	seed = restored_seed
	_rng.seed = seed
	_generate_acts()
	_generate_major_contexts()
	deck_card_ids = _to_packed_strings(snapshot.get("deck_card_ids", []))
	relic_ids = _to_packed_strings(snapshot.get("relic_ids", []))
	potion_ids = _to_packed_strings(snapshot.get("potion_ids", []))
	bitcoin = maxi(0, int(snapshot.get("bitcoin", 0)))
	racquet_tuning_level = maxi(0, int(snapshot.get("racquet_tuning_level", 0)))
	deck_removal_count = maxi(0, int(snapshot.get("deck_removal_count", 0)))
	max_condition = maxi(1, int(snapshot.get("max_condition", int(selected_class.base_stats.get("endurance", 70)))))
	current_condition = clampi(int(snapshot.get("current_condition", max_condition)), 0, max_condition)
	current_act = clampi(int(snapshot.get("current_act", 1)), 1, TOTAL_ACTS)
	accessible_node_ids = _to_packed_ints(snapshot.get("accessible_node_ids", []))
	completed_node_ids = _to_packed_ints(snapshot.get("completed_node_ids", []))
	current_node_id = int(snapshot.get("current_node_id", -1))
	current_node_type = String(snapshot.get("current_node_type", ""))
	phase = String(snapshot.get("phase", "map"))
	if phase not in ["map", "reward"]:
		phase = "map"
	status_message = String(snapshot.get("status_message", "Run restored from checkpoint."))
	pending_reward_reason = String(snapshot.get("pending_reward_reason", ""))
	pending_equipment_bonus_summary = String(snapshot.get("pending_equipment_bonus_summary", ""))
	pending_reward_choices = _normalize_reward_choices(snapshot.get("pending_reward_choices", []))
	active_match = null
	last_match_log = String(snapshot.get("last_match_log", ""))
	last_match_summary = String(snapshot.get("last_match_summary", ""))
	run_complete = false
	run_failed = false
	reveal_title = String(snapshot.get("reveal_title", ""))
	reveal_body = String(snapshot.get("reveal_body", ""))
	reveal_visible = bool(snapshot.get("reveal_visible", false))
	_encounter_counter = int(snapshot.get("encounter_counter", 0))
	_advance_to_next_act_after_reward = bool(snapshot.get("advance_to_next_act_after_reward", false))
	_pending_trim_after_upgrade = bool(snapshot.get("pending_trim_after_upgrade", false))
	_pending_trim_note = String(snapshot.get("pending_trim_note", ""))
	_pending_trim_return_to_shop = bool(snapshot.get("pending_trim_return_to_shop", false))

	if accessible_node_ids.is_empty():
		accessible_node_ids = _first_floor_node_ids(get_current_map_nodes())
	if phase == "reward" and pending_reward_choices.is_empty():
			phase = "map"
			pending_reward_reason = ""
			pending_equipment_bonus_summary = ""
			_advance_to_next_act_after_reward = false
			_pending_trim_after_upgrade = false
			_pending_trim_note = ""
			_pending_trim_return_to_shop = false
			status_message = "Reward checkpoint was empty, so the run resumed on the map."
	return true

func abandon_run() -> void:
	player_class_id = &"novice"
	seed = 0
	current_act = 0
	acts.clear()
	deck_card_ids = PackedStringArray()
	relic_ids = PackedStringArray()
	potion_ids = PackedStringArray()
	bitcoin = 0
	racquet_tuning_level = 0
	deck_removal_count = 0
	max_condition = 0
	current_condition = 0
	accessible_node_ids = PackedInt32Array()
	completed_node_ids = PackedInt32Array()
	current_node_id = -1
	current_node_type = ""
	pending_reward_reason = ""
	pending_equipment_bonus_summary = ""
	pending_reward_choices.clear()
	active_match = null
	last_match_log = ""
	last_match_summary = ""
	run_complete = false
	run_failed = false
	reveal_title = ""
	reveal_body = ""
	reveal_visible = false
	major_contexts.clear()
	_encounter_counter = 0
	_advance_to_next_act_after_reward = false
	_pending_trim_after_upgrade = false
	_pending_trim_note = ""
	_pending_trim_return_to_shop = false
	phase = "idle"
	status_message = "Choose a class to begin the tournament."

func has_checkpoint() -> bool:
	return current_act > 0 and phase in ["map", "reward"] and not run_complete and not run_failed

func to_snapshot() -> Dictionary:
	return {
		"player_class_id": String(player_class_id),
		"seed": seed,
		"current_act": current_act,
		"deck_card_ids": _packed_strings_to_array(deck_card_ids),
		"relic_ids": _packed_strings_to_array(relic_ids),
		"potion_ids": _packed_strings_to_array(potion_ids),
		"bitcoin": bitcoin,
		"racquet_tuning_level": racquet_tuning_level,
		"deck_removal_count": deck_removal_count,
		"max_condition": max_condition,
		"current_condition": current_condition,
		"accessible_node_ids": _packed_ints_to_array(accessible_node_ids),
		"completed_node_ids": _packed_ints_to_array(completed_node_ids),
		"current_node_id": current_node_id,
		"current_node_type": current_node_type,
		"phase": phase,
		"status_message": status_message,
		"pending_reward_reason": pending_reward_reason,
		"pending_equipment_bonus_summary": pending_equipment_bonus_summary,
		"pending_reward_choices": pending_reward_choices.duplicate(true),
		"last_match_log": last_match_log,
		"last_match_summary": last_match_summary,
		"reveal_title": reveal_title,
			"reveal_body": reveal_body,
		"reveal_visible": reveal_visible,
			"encounter_counter": _encounter_counter,
			"advance_to_next_act_after_reward": _advance_to_next_act_after_reward,
			"pending_trim_after_upgrade": _pending_trim_after_upgrade,
			"pending_trim_note": _pending_trim_note,
			"pending_trim_return_to_shop": _pending_trim_return_to_shop,
		}

func get_selected_class():
	return _class_database.get_player_class(player_class_id)

func get_current_map_nodes() -> Array:
	return acts.get(current_act, [])

func get_current_node():
	return get_node(current_node_id)

func _find_accessible_node_by_type(node_type: String) -> int:
	for node_id in accessible_node_ids:
		var node = get_node(int(node_id))
		if node != null and String(node.node_type) == node_type:
			return int(node_id)
	return -1

func get_major_data(act: int = -1) -> Dictionary:
	var resolved_act := act if act > 0 else current_act
	var base_data := {}
	if MAJOR_DATA.has(resolved_act):
		base_data = MAJOR_DATA[resolved_act].duplicate(true)
	else:
		base_data = {
		"name": "Exhibition Circuit",
		"surface": "Training Court",
		"surface_key": "hardcourt",
		"blurb": "No active major is running.",
		"finale": "No final is set.",
	}
	var context: Dictionary = major_contexts.get(resolved_act, {})
	for key in context.keys():
		base_data[key] = context[key]
	return base_data

func get_major_name(act: int = -1) -> String:
	return String(get_major_data(act).get("name", "Exhibition Circuit"))

func get_round_name(floor_index: int) -> String:
	if floor_index >= 0 and floor_index < ROUND_LABELS.size():
		return ROUND_LABELS[floor_index]
	return "Bracket Round"

func get_surface_rule_text(act: int = -1) -> String:
	return String(get_major_data(act).get("surface_rule_text", "No surface modifier."))

func get_final_rule_data(act: int = -1) -> Dictionary:
	return Dictionary(get_major_data(act).get("final_rule", {}))

func has_reveal() -> bool:
	return reveal_visible and (reveal_title != "" or reveal_body != "")

func get_reveal_data() -> Dictionary:
	return {
		"title": reveal_title,
		"body": reveal_body,
	}

func show_reveal(title: String, body: String) -> void:
	_show_reveal(title, body)

func dismiss_reveal() -> void:
	reveal_visible = false

func get_primary_accessible_node_id() -> int:
	if phase != "map" or accessible_node_ids.is_empty():
		return -1

	var type_priority := {
		"regular": 0,
		"elite": 1,
		"boss": 2,
		"event": 3,
		"rest": 4,
		"shop": 5,
		"treasure": 6,
	}
	var best_id := -1
	var best_priority := 999
	var best_floor := 999
	var best_lane := 999
	for node_id in accessible_node_ids:
		var node = get_node(int(node_id))
		if node == null:
			continue
		var node_priority := int(type_priority.get(String(node.node_type), 99))
		var node_floor := int(node.floor)
		var node_lane := int(node.lane)
		if node_priority < best_priority or (node_priority == best_priority and (node_floor < best_floor or (node_floor == best_floor and node_lane < best_lane))):
			best_id = int(node.id)
			best_priority = node_priority
			best_floor = node_floor
			best_lane = node_lane
	return best_id

func advance_to_primary_accessible_node() -> bool:
	var node_id := get_primary_accessible_node_id()
	if node_id < 0:
		return false
	return select_node(node_id)

func get_node(node_id: int):
	for node in get_current_map_nodes():
		if int(node.id) == node_id:
			return node
	return null

func can_select_node(node_id: int) -> bool:
	return phase == "map" and accessible_node_ids.has(node_id)

func select_node(node_id: int) -> bool:
	if not can_select_node(node_id):
		return false

	var node = get_node(node_id)
	if node == null:
		return false

	current_node_id = node_id
	current_node_type = String(node.node_type)
	pending_reward_reason = ""
	pending_reward_choices.clear()

	match current_node_type:
		"regular", "elite", "boss":
			_start_match(node)
		"rest":
			_resolve_rest_node()
		"event":
			_resolve_event_node()
		"shop":
			_resolve_shop_node()
		"treasure":
			_resolve_treasure_node()
		_:
			_mark_current_node_complete()
			phase = "map"
			status_message = "The bracket shifts quietly. Choose the next stop."
	return true

func play_card(hand_index: int) -> bool:
	if active_match == null:
		return false
	var played = active_match.call("play_card", hand_index)
	_handle_match_resolution_if_needed()
	return played

func end_player_turn() -> void:
	if active_match == null:
		return
	active_match.call("end_player_turn")
	_handle_match_resolution_if_needed()

func use_potion(potion_index: int) -> bool:
	if active_match == null or phase != "combat":
		return false
	var used := bool(active_match.call("use_potion", potion_index))
	if used:
		potion_ids = PackedStringArray(active_match.potion_ids)
		_handle_match_resolution_if_needed()
	return used

func choose_reward(choice_index: int) -> bool:
	if phase != "reward":
		return false
	if choice_index < 0 or choice_index >= pending_reward_choices.size():
		return false

	var choice: Dictionary = pending_reward_choices[choice_index]
	var reward_type := String(choice.get("reward_type", "card"))
	var note := "Reward claimed."
	match reward_type:
		"card":
			var card_id := String(choice.get("card_id", ""))
			if card_id != "":
				deck_card_ids.append(card_id)
				note = "Added %s to the deck." % String(choice.get("name", "Card"))
			_close_reward_phase(note)
		"shop_card":
			var price := int(choice.get("price_btc", 0))
			if not _can_afford(price):
				status_message = "Not enough bitcoin for that pickup."
				return false
			var shop_card_id := String(choice.get("card_id", ""))
			if shop_card_id == "":
				return false
			bitcoin -= price
			deck_card_ids.append(shop_card_id)
			note = "Bought %s for %d BTC. Wallet: %d BTC." % [String(choice.get("name", "Card")), price, bitcoin]
			_refresh_shop_checkpoint_phase(note)
		"shop_potion":
			var potion_price := int(choice.get("price_btc", 0))
			if potion_ids.size() >= MAX_POTIONS:
				status_message = "Potion belt is full. Use one before buying another."
				return false
			if not _can_afford(potion_price):
				status_message = "Not enough bitcoin for that potion."
				return false
			var potion_id := String(choice.get("potion_id", ""))
			if potion_id == "":
				return false
			bitcoin -= potion_price
			potion_ids.append(potion_id)
			note = "Bought %s for %d BTC. Potion belt: %d / %d. Wallet: %d BTC." % [
				String(choice.get("name", "Potion")),
				potion_price,
				potion_ids.size(),
				MAX_POTIONS,
				bitcoin,
			]
			_refresh_shop_checkpoint_phase(note)
		"shop_relic":
			var relic_price := int(choice.get("price_btc", 0))
			if not _can_afford(relic_price):
				status_message = "Not enough bitcoin for that relic."
				return false
			var shop_relic_id := String(choice.get("relic_id", ""))
			if shop_relic_id == "" or relic_ids.has(shop_relic_id):
				status_message = "That relic is no longer available."
				return false
			bitcoin -= relic_price
			relic_ids.append(shop_relic_id)
			note = "Bought relic %s for %d BTC. Wallet: %d BTC." % [String(choice.get("name", "Relic")), relic_price, bitcoin]
			_refresh_shop_checkpoint_phase(note)
		"shop_remove":
			var remove_price := int(choice.get("price_btc", 0))
			if not _can_afford(remove_price):
				status_message = "Not enough bitcoin for the deck service."
				return false
			if deck_card_ids.size() <= 5:
				status_message = "The deck is already too lean to cut another card."
				return false
			bitcoin -= remove_price
			deck_removal_count += 1
			note = "Paid %d BTC for a deck service. Choose one card to remove. Wallet: %d BTC." % [remove_price, bitcoin]
			_open_upgrade_trim_phase(note, true)
		"card_upgrade", "reward_upgrade":
			var upgrade_price := int(choice.get("price_btc", 0))
			if not _can_afford(upgrade_price):
				status_message = "Not enough bitcoin to upgrade that card."
				return false
			var base_card_id := String(choice.get("base_card_id", ""))
			var upgraded_card_id := String(choice.get("upgraded_card_id", ""))
			if not _replace_first_card(base_card_id, upgraded_card_id):
				status_message = "That card is no longer available to upgrade."
				return false
			if upgrade_price > 0:
				bitcoin -= upgrade_price
				note = "Upgraded %s for %d BTC. Wallet: %d BTC." % [String(choice.get("name", "Card Upgrade")), upgrade_price, bitcoin]
			else:
				note = "Upgraded %s. Remove one card to lock in the deck change." % String(choice.get("name", "Card Upgrade"))
			_open_upgrade_trim_phase(note, reward_type == "card_upgrade")
		"deck_trim":
			var trim_card_id := String(choice.get("card_id", ""))
			if not _remove_first_card(trim_card_id):
				status_message = "That card is no longer available to remove."
				return false
			note = "Removed %s from the deck." % String(choice.get("name", "Card"))
			_complete_upgrade_trim(note)
		"racquet_upgrade":
			var tune_price := int(choice.get("price_btc", 0))
			if not _can_afford(tune_price):
				status_message = "Not enough bitcoin to tune the racquet room."
				return false
			bitcoin -= tune_price
			racquet_tuning_level += 1
			note = "Racquet workshop tuned to level %d for %d BTC. Wallet: %d BTC." % [racquet_tuning_level, tune_price, bitcoin]
			_refresh_shop_checkpoint_phase(note)
		"rest_heal":
			var healed := _recover_condition(int(choice.get("heal_amount", 0)))
			note = "Recovery block restored %d Condition." % healed
			_close_reward_phase(note)
		"rest_endurance":
			var endurance_gain := maxi(1, int(choice.get("endurance_gain", 0)))
			max_condition += endurance_gain
			current_condition = mini(max_condition, current_condition + endurance_gain)
			note = "Endurance block raised max Condition by %d." % endurance_gain
			_close_reward_phase(note)
		"rest_focus":
			bitcoin += int(choice.get("bitcoin_bonus", 0))
			note = "Video session sharpened the plan. Found %d BTC in sponsorship credits." % int(choice.get("bitcoin_bonus", 0))
			_close_reward_phase(note)
		"relic":
			var relic_id := String(choice.get("relic_id", ""))
			if relic_id != "" and not relic_ids.has(relic_id):
				relic_ids.append(relic_id)
				note = "Claimed relic: %s." % String(choice.get("name", "Relic"))
			_close_reward_phase(note)
		"chest_gold":
			var gold_gain := int(choice.get("gold_amount", 0))
			bitcoin += gold_gain
			note = "Prize money: +%d BTC. Wallet: %d BTC." % [gold_gain, bitcoin]
			_close_reward_phase(note)
		_:
			return false
	return true

func skip_reward() -> void:
	if phase != "reward":
		return
	if _pending_trim_after_upgrade:
		status_message = "Choose one card to remove before leaving the upgrade screen."
		return
	_close_reward_phase("Left the checkpoint." if _is_checkpoint_menu() else "Skipped the reward.")

func get_run_summary() -> String:
	var lines := PackedStringArray()
	if phase == "idle":
		lines.append("No active run.")
		return "\n".join(lines)

	var major_data := get_major_data()
	lines.append("Major %d / %d: %s" % [current_act, TOTAL_ACTS, String(major_data.get("name", "Major"))])
	lines.append("Surface: %s" % String(major_data.get("surface", "Court")))
	lines.append("Court Effect: %s" % String(major_data.get("surface_rule_text", "No surface modifier.")))
	var final_rule: Dictionary = Dictionary(major_data.get("final_rule", {}))
	if not final_rule.is_empty():
		lines.append("Final Twist: %s" % String(final_rule.get("name", "Championship Rule")))
	lines.append("Condition: %d / %d" % [current_condition, max_condition])
	lines.append("Bitcoin: %d BTC" % bitcoin)
	lines.append("Racquet Tune: Lv.%d" % racquet_tuning_level)
	lines.append("Potions: %d / %d" % [potion_ids.size(), MAX_POTIONS])
	lines.append("Deck Size: %d" % deck_card_ids.size())
	lines.append("Relics: %d" % relic_ids.size())
	lines.append("Phase: %s" % phase.capitalize())
	lines.append("Seed: %d" % seed)
	if current_node_id >= 0:
		lines.append("Current Node: %s" % get_node_summary(current_node_id))
	return "\n".join(lines)

func get_node_summary(node_id: int = -1) -> String:
	var resolved_id := node_id if node_id >= 0 else current_node_id
	var node = get_node(resolved_id)
	if node == null:
		return "Select a highlighted node to continue the run."

	var parts := PackedStringArray()
	parts.append(get_round_name(int(node.floor)))
	if String(node.node_type) == "boss":
		parts.append(get_major_name() + " Final")
	else:
		parts.append(String(node.node_type).capitalize())
	if String(node.encounter_id) != "":
		var enemy = _enemy_database.get_enemy(node.encounter_id)
		if enemy != null:
			parts.append(enemy.name)
			var featured_entry := _get_featured_entry_for_enemy(enemy.id)
			if not featured_entry.is_empty():
				parts.append("Seed #%d %s" % [int(featured_entry.get("seed", 0)), String(featured_entry.get("role", "Featured"))])
			parts.append(enemy.summary)
			if String(node.node_type) in ["regular", "elite", "boss"]:
				parts.append("%d BTC on win" % _bitcoin_payout_for_encounter(String(node.node_type), not featured_entry.is_empty()))
	elif String(node.node_type) == "shop":
		parts.append("Checkpoint market")
	elif String(node.node_type) == "rest":
		parts.append("Recovery checkpoint")
	return " | ".join(parts)

func get_deck_preview(limit: int = 12) -> String:
	if deck_card_ids.is_empty():
		return "Deck is empty."

	var counts: Dictionary = {}
	for card_id in deck_card_ids:
		counts[card_id] = int(counts.get(card_id, 0)) + 1

	var ordered_ids: Array = counts.keys()
	ordered_ids.sort_custom(func(a, b) -> bool:
		return String(a) < String(b)
	)

	var lines := PackedStringArray()
	var shown := 0
	for card_id in ordered_ids:
		if shown >= limit:
			break
		var card = _card_database.get_card(StringName(card_id))
		if card == null:
			continue
		lines.append("%dx %s" % [int(counts[card_id]), card.name])
		shown += 1
	if ordered_ids.size() > limit:
		lines.append("...and %d more cards" % (ordered_ids.size() - limit))
	return "\n".join(lines)

func get_relic_preview(limit: int = 10) -> String:
	if relic_ids.is_empty():
		return "No relics yet."

	var lines := PackedStringArray()
	var shown := 0
	for relic_id in relic_ids:
		if shown >= limit:
			break
		var relic = _relic_database.get_relic(StringName(relic_id))
		if relic == null:
			continue
		lines.append("%s [%s]" % [relic.name, relic.rarity.capitalize()])
		shown += 1
	if relic_ids.size() > limit:
		lines.append("...and %d more relics" % (relic_ids.size() - limit))
	return "\n".join(lines)

func get_potion_preview(limit: int = 6) -> String:
	if potion_ids.is_empty():
		return "No potions stocked."

	var lines := PackedStringArray()
	var shown := 0
	for potion_id in potion_ids:
		if shown >= limit:
			break
		var potion = _potion_database.get_potion(StringName(potion_id))
		if potion == null:
			continue
		lines.append("%s [%s]" % [potion.name, potion.rarity.capitalize()])
		shown += 1
	if potion_ids.size() > limit:
		lines.append("...and %d more potions" % (potion_ids.size() - limit))
	return "\n".join(lines)

func get_reward_choices() -> Array:
	return pending_reward_choices.duplicate(true)

func get_pending_equipment_bonus_summary() -> String:
	return pending_equipment_bonus_summary

func get_reward_menu_kind() -> String:
	if phase != "reward" or pending_reward_choices.is_empty():
		return ""
	var saw_rest := false
	var saw_shop := false
	var saw_relic := false
	var saw_trim := false
	for choice in pending_reward_choices:
		var reward_type := String(Dictionary(choice).get("reward_type", "card"))
		if reward_type in ["rest_heal", "rest_endurance", "rest_focus"]:
			saw_rest = true
		elif SHOP_REWARD_TYPES.has(reward_type):
			saw_shop = true
		elif reward_type == "deck_trim":
			saw_trim = true
		elif reward_type == "relic":
			saw_relic = true
	if saw_trim and not saw_shop and not saw_rest and not saw_relic:
		return "trim"
	if saw_rest and not saw_shop and not saw_relic:
		return "rest"
	if saw_shop and not saw_rest and not saw_relic:
		return "shop"
	if saw_relic:
		return "relic"
	return "draft"

func is_checkpoint_menu() -> bool:
	return _is_checkpoint_menu()

func is_reward_skip_allowed() -> bool:
	return phase == "reward" and not _pending_trim_after_upgrade

func _generate_acts() -> void:
	acts.clear()
	for act in range(1, TOTAL_ACTS + 1):
		acts[act] = _path_generator.generate_act(act, seed + act * 7919, _enemy_database)

func _generate_major_contexts() -> void:
	major_contexts.clear()
	var rule_rng := RandomNumberGenerator.new()
	rule_rng.seed = seed + 424243
	var available_rules: Array = FINAL_RULE_POOL.duplicate(true)

	for act in range(1, TOTAL_ACTS + 1):
		var surface_key := _surface_key_for_act(act)
		var boss_pool: Array = _enemy_database.get_pool(act, "boss")
		var boss_id := StringName()
		if not boss_pool.is_empty():
			boss_id = boss_pool[0].id
		var selected_rule := _pick_weighted_final_rule(String(boss_id), available_rules, rule_rng)
		major_contexts[act] = {
			"surface_key": surface_key,
			"surface_rule_text": _surface_rule_text(surface_key),
			"featured_field": _build_featured_field(act),
			"boss_id": String(boss_id),
			"final_rule": selected_rule,
		}
		_apply_featured_seed_pressure(act)

func _surface_key_for_act(act: int) -> String:
	match act:
		2:
			return "clay"
		3:
			return "grass"
		_:
			return "hardcourt"

func _surface_rule_text(surface_key: String) -> String:
	match surface_key:
		"clay":
			return "Topspin and rally patterns gain bite. Long points leave both players heavier on the legs."
		"grass":
			return "Serve, slice, and net pressure come through faster and lower."
		_:
			return "Serve and power shots come off the court quickly with extra pace."

func _build_featured_field(act: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + act * 13337
	var featured: Array = []
	var used_ids: Dictionary = {}
	var seed_numbers: Array = [1, 2, 3, 4, 5, 6, 7, 8]
	_shuffle_with_rng(seed_numbers, rng)

	var regular_pool: Array = _enemy_database.get_pool(act, "regular")
	var elite_pool: Array = _enemy_database.get_pool(act, "elite")
	var boss_pool: Array = _enemy_database.get_pool(act, "boss")

	_append_featured_entries(featured, regular_pool, 2, "Main Draw Threat", used_ids, seed_numbers, rng)
	_append_featured_entries(featured, elite_pool, 1, "Dark Horse", used_ids, seed_numbers, rng)
	_append_featured_entries(featured, boss_pool, 1, "Final Seed", used_ids, seed_numbers, rng)
	return featured

func _append_featured_entries(target: Array, pool: Array, count: int, role: String, used_ids: Dictionary, seed_numbers: Array, rng: RandomNumberGenerator) -> void:
	var working_pool: Array = pool.duplicate()
	_shuffle_with_rng(working_pool, rng)
	for enemy in working_pool:
		if target.size() >= 4:
			return
		if count <= 0:
			return
		if used_ids.has(String(enemy.id)):
			continue
		used_ids[String(enemy.id)] = true
		var seed_number: int = int(seed_numbers.pop_front()) if not seed_numbers.is_empty() else target.size() + 1
		target.append({
			"seed": int(seed_number),
			"enemy_id": String(enemy.id),
			"name": enemy.name,
			"role": role,
			"category": enemy.category,
		})
		count -= 1

func _format_featured_field(featured_field: Array) -> String:
	if featured_field.is_empty():
		return "Field still settling."
	var lines := PackedStringArray()
	for entry in featured_field:
		lines.append("#%d %s - %s" % [int(entry.get("seed", 0)), String(entry.get("name", "Contender")), String(entry.get("role", ""))])
	return "\n".join(lines)

func _shuffle_with_rng(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temp = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temp

func _pick_weighted_final_rule(boss_id: String, available_rules: Array, rng: RandomNumberGenerator) -> Dictionary:
	if available_rules.is_empty():
		return {}
	var total_weight := 0
	var weighted_rules: Array = []
	for rule in available_rules:
		var weight := _boss_rule_weight(boss_id, String(rule.get("id", "")))
		total_weight += weight
		weighted_rules.append({
			"weight": weight,
			"rule": rule,
		})
	var roll := rng.randi_range(1, maxi(1, total_weight))
	var running := 0
	for entry in weighted_rules:
		running += int(entry.get("weight", 1))
		if roll <= running:
			var selected_rule: Dictionary = Dictionary(entry.get("rule", {})).duplicate(true)
			_remove_rule_from_pool(available_rules, String(selected_rule.get("id", "")))
			return selected_rule
	var fallback_rule: Dictionary = Dictionary(available_rules[0]).duplicate(true)
	_remove_rule_from_pool(available_rules, String(fallback_rule.get("id", "")))
	return fallback_rule

func _boss_rule_weight(boss_id: String, rule_id: String) -> int:
	var preferences := {
		"melbourne_mirage": {
			"server_spotlight": 5,
			"no_ad_final": 4,
			"first_strike": 4,
			"return_rush": 2,
		},
		"terre_battue_tyrant": {
			"pressure_cooker": 5,
			"hot_streak": 4,
			"game_point_glare": 4,
			"return_rush": 2,
		},
		"centre_court_specter": {
			"first_strike": 5,
			"server_spotlight": 4,
			"return_rush": 4,
			"no_ad_final": 2,
		},
		"arthur_ashe_umbra": {
			"hot_streak": 5,
			"pressure_cooker": 4,
			"game_point_glare": 4,
			"no_ad_final": 3,
		},
	}
	if preferences.has(boss_id):
		return int(Dictionary(preferences[boss_id]).get(rule_id, 1))
	return 1

func _remove_rule_from_pool(available_rules: Array, rule_id: String) -> void:
	for index in range(available_rules.size()):
		if String(available_rules[index].get("id", "")) == rule_id:
			available_rules.remove_at(index)
			return

func _apply_featured_seed_pressure(act: int) -> void:
	var nodes: Array = acts.get(act, [])
	if nodes.is_empty() or not major_contexts.has(act):
		return
	var featured_field: Array = Array(Dictionary(major_contexts[act]).get("featured_field", []))
	var featured_regulars: Array = []
	var featured_elites: Array = []
	for entry in featured_field:
		var category := String(entry.get("category", ""))
		if category == "regular":
			featured_regulars.append(entry)
		elif category == "elite":
			featured_elites.append(entry)

	_assign_featured_to_nodes(nodes, featured_regulars, "regular", 2)
	_assign_featured_to_nodes(nodes, featured_elites, "elite", 1)

func _assign_featured_to_nodes(nodes: Array, featured_entries: Array, node_type: String, max_assignments: int) -> void:
	var assignment_count := 0
	for node in nodes:
		if assignment_count >= max_assignments or featured_entries.is_empty():
			return
		if String(node.node_type) != node_type:
			continue
		var entry: Dictionary = Dictionary(featured_entries[assignment_count])
		node.encounter_id = StringName(String(entry.get("enemy_id", "")))
		assignment_count += 1

func _get_featured_entry_for_enemy(enemy_id: StringName, act: int = -1) -> Dictionary:
	var major_data := get_major_data(act)
	var featured_field: Array = Array(major_data.get("featured_field", []))
	for entry in featured_field:
		if String(entry.get("enemy_id", "")) == String(enemy_id):
			return Dictionary(entry)
	return {}

func _enter_act(act: int) -> void:
	current_act = act
	accessible_node_ids = _first_floor_node_ids(get_current_map_nodes())
	completed_node_ids = PackedInt32Array()
	current_node_id = -1
	current_node_type = ""
	pending_reward_reason = ""
	pending_reward_choices.clear()
	active_match = null
	phase = "map"
	var major_data := get_major_data(current_act)
	var final_rule: Dictionary = Dictionary(major_data.get("final_rule", {}))
	status_message = "%s begins. Choose a route through the bracket." % String(major_data.get("name", "Major"))
	_show_reveal(
		"%s Draw" % String(major_data.get("name", "Major")),
		"%s\nSurface: %s\nCourt Effect: %s\nChampionship Twist: %s\n%s\n\nFeatured Seeds\n%s" % [
			String(major_data.get("blurb", "")),
			String(major_data.get("surface", "Court")),
			String(major_data.get("surface_rule_text", "No surface modifier.")),
			String(final_rule.get("name", "Final Rule")),
			String(final_rule.get("description", "")),
			_format_featured_field(Array(major_data.get("featured_field", []))),
		]
	)

func _first_floor_node_ids(nodes: Array) -> PackedInt32Array:
	var node_ids := PackedInt32Array()
	for node in nodes:
		if int(node.floor) == 0:
			node_ids.append(int(node.id))
	return node_ids

func _start_match(node) -> void:
	var class_def = get_selected_class()
	var enemy_def = _enemy_database.get_enemy(node.encounter_id)
	if class_def == null or enemy_def == null:
		phase = "map"
		status_message = "Encounter data was missing. Choose another node."
		return

	_encounter_counter += 1
	var encounter_seed := seed + current_act * 104729 + int(node.id) * 193 + _encounter_counter
	var major_data := get_major_data()
	var match_context := {
		"major_name": String(major_data.get("name", "Major")),
		"surface_key": String(major_data.get("surface_key", "hardcourt")),
		"surface_name": String(major_data.get("surface", "Court")),
		"final_rule": Dictionary(major_data.get("final_rule", {})),
		"racquet_tuning_level": racquet_tuning_level,
		"potion_ids": potion_ids.duplicate(),
	}
	var featured_entry := _get_featured_entry_for_enemy(enemy_def.id)
	last_match_log = ""
	last_match_summary = ""
	active_match = MatchStateScript.new(class_def, enemy_def, deck_card_ids, current_condition, String(node.node_type), encounter_seed, relic_ids, match_context)
	phase = "combat"
	if String(node.node_type) == "boss":
		var final_rule: Dictionary = Dictionary(major_data.get("final_rule", {}))
		_show_reveal(
			"%s Final" % String(major_data.get("name", "Major")),
			"%s\nOpponent: %s\nSurface: %s\nCourt Effect: %s\nChampionship Twist: %s\n%s" % [
				String(major_data.get("finale", "")),
				enemy_def.name,
				String(major_data.get("surface", "Court")),
				String(major_data.get("surface_rule_text", "No surface modifier.")),
				String(final_rule.get("name", "Final Rule")),
				String(final_rule.get("description", "")),
			]
		)
		status_message = "Championship match: %s in the %s final. Twist: %s." % [enemy_def.name, String(major_data.get("name", "Major")), String(final_rule.get("name", "Final Rule"))]
	else:
		status_message = "Facing %s in %s on %s." % [enemy_def.name, get_round_name(int(node.floor)), String(major_data.get("surface", "Court"))]
		if not featured_entry.is_empty():
			status_message += " Featured seed #%d: %s." % [int(featured_entry.get("seed", 0)), String(featured_entry.get("role", "Threat"))]

func _handle_match_resolution_if_needed() -> void:
	if active_match == null:
		return
	if active_match.state != "won" and active_match.state != "lost":
		current_condition = active_match.player.current_condition
		potion_ids = PackedStringArray(active_match.potion_ids)
		return

	current_condition = active_match.player.current_condition
	potion_ids = PackedStringArray(active_match.potion_ids)
	last_match_log = active_match.call("get_log_text")
	last_match_summary = active_match.call("get_match_summary")
	var resolved_node_type = current_node_type
	var enemy_id = active_match.enemy_def.id
	var enemy_name = active_match.enemy_def.name
	var result_reason = active_match.result_reason
	var was_victory = active_match.state == "won"
	var equipment_bonus := Dictionary(active_match.call("get_round_equipment_bonus"))
	active_match = null

	if was_victory:
		_mark_current_node_complete()
		var relic_notes = _apply_post_encounter_relics(resolved_node_type)
		var equipment_bundle := _apply_equipment_round_bonus(equipment_bonus)
		var equipment_note := String(equipment_bundle.get("note", ""))
		pending_equipment_bonus_summary = equipment_note.strip_edges()
		var extra_card_choices := int(equipment_bundle.get("extra_card_choices", 0))
		var featured_entry := _get_featured_entry_for_enemy(enemy_id)
		var featured_note := ""
		var featured_reward_bonus := 0
		var bitcoin_payout := _bitcoin_payout_for_encounter(resolved_node_type, not featured_entry.is_empty())
		var bitcoin_note := ""
		if bitcoin_payout > 0:
			bitcoin += bitcoin_payout
			bitcoin_note = " Earned %d BTC." % bitcoin_payout
		if not featured_entry.is_empty():
			var featured_heal := _recover_condition(3 if resolved_node_type == "regular" else 5)
			featured_reward_bonus = 1
			featured_note = " Defeated featured seed #%d and recovered %d Condition." % [int(featured_entry.get("seed", 0)), featured_heal]
		match resolved_node_type:
			"regular":
				_open_card_reward_phase(3 + featured_reward_bonus + extra_card_choices, "Match won against %s.%s%s%s%s Choose a specialty shot." % [enemy_name, relic_notes, bitcoin_note, featured_note, equipment_note], PackedStringArray())
			"elite":
				var elite_heal := _recover_condition(6)
				_open_card_reward_phase(3 + featured_reward_bonus + extra_card_choices, "Elite defeated. Recover %d Condition.%s%s%s%s Draft one card." % [elite_heal, relic_notes, bitcoin_note, featured_note, equipment_note], PackedStringArray())
			"boss":
				var current_major_name := get_major_name()
				if current_act >= TOTAL_ACTS:
					run_complete = true
					phase = "run_won"
					_show_reveal(
						"Grand Slam Complete",
						"You won the %s and cleared all four majors.\nFinal opponent: %s" % [current_major_name, enemy_name]
					)
					status_message = "Championship secured at the %s. %s was the final obstacle.%s%s%s" % [current_major_name, enemy_name, relic_notes, bitcoin_note, equipment_note]
				else:
					var boss_heal := _recover_condition(10)
					var next_major_name := get_major_name(current_act + 1)
					_advance_to_next_act_after_reward = true
					_open_relic_reward_phase(3, "%s conquered. Recover %d Condition.%s%s%s Choose one relic before %s." % [current_major_name, boss_heal, relic_notes, bitcoin_note, equipment_note, next_major_name], PackedStringArray(["rare", "boss"]))
			_:
				phase = "map"
				status_message = "Encounter cleared.%s%s%s Choose the next node." % [relic_notes, bitcoin_note, equipment_note]
	else:
		run_failed = true
		phase = "run_lost"
		pending_equipment_bonus_summary = ""
		status_message = "Run ended at %s. %s" % [get_major_name(), result_reason]

func _mark_current_node_complete() -> void:
	var node = get_current_node()
	if node == null:
		return
	if not completed_node_ids.has(int(node.id)):
		completed_node_ids.append(int(node.id))
	var next_ids := PackedInt32Array()
	for next_node_id in node.next_node_ids:
		next_ids.append(int(next_node_id))
	accessible_node_ids = next_ids

func _resolve_rest_node() -> void:
	_mark_current_node_complete()
	pending_equipment_bonus_summary = ""
	_open_rest_checkpoint_phase()

func _resolve_event_node() -> void:
	_mark_current_node_complete()
	pending_equipment_bonus_summary = ""
	var event_roll := _rng.randi_range(0, 4)
	match event_roll:
		0:
			var healed := _recover_condition(8)
			phase = "map"
			status_message = "Physio Tent: recover %d Condition before the next round." % healed
		1:
			current_condition = maxi(1, current_condition - 4)
			_open_card_reward_phase(2, "Shadow Rally: lose 4 Condition, then choose one breakthrough shot.", PackedStringArray(["signature", "tempo", "control"]))
		2:
			max_condition += 4
			current_condition = mini(max_condition, current_condition + 4)
			phase = "map"
			status_message = "Altitude Camp: max Condition and current Condition both increase by 4."
		3:
			_open_relic_reward_phase(3, "Locker Raid: claim one relic from the traveling kit.", PackedStringArray(["common", "uncommon"]))
		4:
			var scouted_entry := _pick_random_featured_entry()
			var scout_heal := _recover_condition(5)
			phase = "map"
			if scouted_entry.is_empty():
				status_message = "Scouting report was stale, but the downtime restored %d Condition." % scout_heal
			else:
				status_message = "Scout Report: seed #%d %s looks vulnerable in this draw. Recover %d Condition and prepare for a featured clash." % [int(scouted_entry.get("seed", 0)), String(scouted_entry.get("name", "Contender")), scout_heal]

func _resolve_shop_node() -> void:
	_mark_current_node_complete()
	pending_equipment_bonus_summary = ""
	_refresh_shop_checkpoint_phase("Checkpoint open. Stock potions, buy relics, add cards, or tune the racquet room.")

func _resolve_treasure_node() -> void:
	_mark_current_node_complete()
	pending_equipment_bonus_summary = ""
	_open_chest_phase()

func _open_chest_phase() -> void:
	var chest_choices: Array = []

	# Option 1: Relic (one random relic from common/uncommon/rare pool)
	var relic_offers := _generate_relic_rewards(1, PackedStringArray(["common", "uncommon", "rare"]))
	for relic_offer in relic_offers:
		chest_choices.append(relic_offer)

	# Option 2: Bitcoin payout (scales with act)
	var gold_amount := 20 + current_act * 5
	chest_choices.append({
		"reward_type": "chest_gold",
		"name": "Prize Money",
		"description": "Tournament sponsorship payout: %d BTC. Covers equipment upgrades, shop picks, or deck surgery." % gold_amount,
		"gold_amount": gold_amount,
		"display_type": "GOLD",
		"display_art": "Sponsor Cheque",
		"display_icon": "ball",
		"footer_text": "Gain %d BTC" % gold_amount,
	})

	# Option 3: Random modifier card from the kit bag
	var all_cards: Array = _card_database.get_all_cards()
	var modifier_pool: Array = []
	for card in all_cards:
		if PackedStringArray(card.tags).has("modifier"):
			modifier_pool.append(card)
	if not modifier_pool.is_empty():
		_shuffle_with_rng(modifier_pool, _rng)
		var mod_card = modifier_pool[0]
		var mod_footer := "Modifier card — equip at the start of a match"
		var synergy := _equipment_synergy_note_for_card(mod_card)
		if synergy != "":
			mod_footer = synergy + "\n" + mod_footer
		chest_choices.append({
			"reward_type": "card",
			"card_id": String(mod_card.id),
			"name": mod_card.name,
			"description": mod_card.description,
			"cost": mod_card.cost,
			"tags": PackedStringArray(mod_card.tags),
			"display_type": "FIND",
			"display_art": "Kit Bag",
			"display_icon": "focus",
			"footer_text": mod_footer,
		})

	_set_reward_phase("Stringer's Cache: choose one reward from the kit.", chest_choices)

func _recover_condition(amount: int) -> int:
	var previous := current_condition
	current_condition = mini(max_condition, current_condition + maxi(0, amount))
	return current_condition - previous

func _bitcoin_payout_for_encounter(encounter_kind: String, featured: bool = false) -> int:
	var payout := 0
	match encounter_kind:
		"regular":
			payout = 10
		"elite":
			payout = 20
		"boss":
			payout = 30
	if featured:
		payout += 4
	return payout

func _apply_post_encounter_relics(encounter_kind: String) -> String:
	var notes := PackedStringArray()
	var heal_amount := _relic_effect_value("heal_after_encounter")
	if encounter_kind == "elite":
		heal_amount += _relic_effect_value("heal_after_elite")
	elif encounter_kind == "boss":
		heal_amount += _relic_effect_value("heal_after_boss")
	if heal_amount > 0:
		var healed := _recover_condition(heal_amount)
		if healed > 0:
			notes.append(" Healed %d Condition from relics." % healed)
	return "".join(notes)

func _apply_equipment_round_bonus(bonus_bundle: Dictionary) -> Dictionary:
	var note_parts := PackedStringArray()
	var bitcoin_gain := maxi(0, int(bonus_bundle.get("bitcoin_bonus", 0)))
	var condition_gain := maxi(0, int(bonus_bundle.get("condition_bonus", 0)))
	var extra_card_choices := maxi(0, int(bonus_bundle.get("extra_card_choices", 0)))
	if bitcoin_gain > 0:
		bitcoin += bitcoin_gain
	if condition_gain > 0:
		var healed := _recover_condition(condition_gain)
		if healed > 0:
			note_parts.append(" Recovered %d Condition from equipment." % healed)
	if extra_card_choices > 0:
		note_parts.append(" Equipment opens +%d extra card option." % extra_card_choices)
	var notes_value = bonus_bundle.get("notes", PackedStringArray())
	if typeof(notes_value) == TYPE_PACKED_STRING_ARRAY:
		for entry in PackedStringArray(notes_value):
			note_parts.append(" " + String(entry))
	elif notes_value is Array:
		for entry in notes_value:
			note_parts.append(" " + String(entry))
	if bitcoin_gain > 0:
		note_parts.append(" Wallet +%d BTC from gear." % bitcoin_gain)
	return {
		"note": "".join(note_parts),
		"extra_card_choices": extra_card_choices,
	}

func _open_card_reward_phase(base_choice_count: int, reason: String, preferred_tags: PackedStringArray = PackedStringArray()) -> void:
	var choice_count := base_choice_count + _relic_effect_value("extra_card_reward_choice")
	var rewards := _generate_card_rewards(choice_count, preferred_tags)
	for upgrade_offer in _generate_card_upgrade_choices(1, false):
		rewards.append(upgrade_offer)
	_set_reward_phase(reason, rewards)

func _open_shop_card_reward_phase(base_choice_count: int, reason: String) -> void:
	var choice_count := base_choice_count + _relic_effect_value("extra_card_reward_choice")
	_set_reward_phase(reason, _generate_shop_card_rewards(choice_count))

func _open_relic_reward_phase(base_choice_count: int, reason: String, allowed_rarities: PackedStringArray = PackedStringArray()) -> void:
	var choice_count := base_choice_count
	if allowed_rarities.has("boss"):
		choice_count += _relic_effect_value("extra_boss_relic_choice")
	_set_reward_phase(reason, _generate_relic_rewards(choice_count, allowed_rarities))

func _open_rest_checkpoint_phase() -> void:
	var heal_amount := maxi(14, int(ceil(float(max_condition) * 0.24)))
	var rest_choices: Array = [{
		"reward_type": "rest_heal",
		"name": "Rest",
		"description": "Recover %d Condition and settle in beside the fire before the next match." % heal_amount,
		"display_type": "REST",
		"display_art": "Ice Bath Reset",
		"display_icon": "focus",
		"heal_amount": heal_amount,
		"footer_text": "Recover %d Condition" % heal_amount,
	}]
	# Card upgrade options are only available when condition is healthy (>= 50% of max).
	# A beat-up player needs rest more than card work; a healthy player earns the upgrade slot.
	var condition_threshold := int(ceil(float(max_condition) * 0.5))
	if current_condition >= condition_threshold:
		for upgrade_offer in _generate_card_upgrade_choices(3, false):
			rest_choices.append(upgrade_offer)
	else:
		# Below threshold: offer an endurance block to raise the ceiling instead
		rest_choices.append({
			"reward_type": "rest_endurance",
			"name": "Endurance Block",
			"description": "Hard conditioning work raises your stamina ceiling. Max Condition increases by 4 and you recover that 4 immediately.",
			"display_type": "REST",
			"display_art": "Endurance Camp",
			"display_icon": "pressure",
			"endurance_gain": 4,
			"footer_text": "Max Condition +4 (requires low condition)",
		})
	_set_reward_phase("Recovery camp. Choose one way to prep for the next branch.", rest_choices)

func _refresh_shop_checkpoint_phase(note: String = "") -> void:
	var choices := _generate_checkpoint_shop_choices()
	if choices.is_empty():
		phase = "map"
		status_message = note + "\nThe checkpoint had nothing left worth buying. Choose the next node."
		return
	var intro := "Checkpoint market. Wallet: %d BTC. Shop potions, relics, cards, upgrades, and racquet tuning." % bitcoin
	if note != "":
		intro = note + "\n" + intro
	_set_reward_phase(intro, choices)

func _set_reward_phase(reason: String, choices: Array) -> void:
	pending_reward_reason = reason
	pending_reward_choices = choices
	if pending_reward_choices.is_empty():
		phase = "map"
		status_message = reason + " No valid rewards were available, so the run continues."
		return
	phase = "reward"
	status_message = reason

func _close_reward_phase(note: String) -> void:
	pending_reward_reason = ""
	pending_reward_choices.clear()
	pending_equipment_bonus_summary = ""
	_pending_trim_after_upgrade = false
	_pending_trim_note = ""
	_pending_trim_return_to_shop = false
	if _advance_to_next_act_after_reward:
		_advance_to_next_act_after_reward = false
		_enter_act(current_act + 1)
		status_message = note + "\n" + status_message
	else:
		phase = "map"
		status_message = note + "\nChoose the next node."

func _open_upgrade_trim_phase(note: String, return_to_shop: bool) -> void:
	_pending_trim_after_upgrade = true
	_pending_trim_note = note
	_pending_trim_return_to_shop = return_to_shop
	var trim_choices := _generate_deck_trim_choices()
	_set_reward_phase(note + "\nTrim one card from the deck after the upgrade.", trim_choices)

func _complete_upgrade_trim(trim_note: String) -> void:
	var combined_note := _pending_trim_note
	if combined_note != "":
		combined_note += "\n" + trim_note
	else:
		combined_note = trim_note
	var return_to_shop := _pending_trim_return_to_shop
	_pending_trim_after_upgrade = false
	_pending_trim_note = ""
	_pending_trim_return_to_shop = false
	if return_to_shop:
		_refresh_shop_checkpoint_phase(combined_note)
	else:
		_close_reward_phase(combined_note)

func _generate_checkpoint_shop_choices() -> Array:
	var choices: Array = []
	for potion_offer in _generate_shop_potion_choices(2):
		choices.append(potion_offer)
	for relic_offer in _generate_shop_relic_choices(2):
		choices.append(relic_offer)
	var removal_offer := _generate_shop_remove_offer()
	if not removal_offer.is_empty():
		choices.append(removal_offer)
	for card_offer in _generate_shop_card_rewards(3):
		var price := _shop_card_price(card_offer)
		card_offer["reward_type"] = "shop_card"
		card_offer["price_btc"] = price
		card_offer["display_type"] = "BUY"
		card_offer["display_art"] = "Checkpoint Shop"
		card_offer["display_icon"] = "ball"
		# Preserve any synergy note that _generate_shop_card_rewards injected, then append price
		var existing_footer := String(card_offer.get("footer_text", ""))
		var price_text := "Costs %d BTC" % price
		card_offer["footer_text"] = (existing_footer + "\n" + price_text) if existing_footer != "" else price_text
		choices.append(card_offer)
	for upgrade_offer in _generate_card_upgrade_choices(2):
		choices.append(upgrade_offer)
	var racquet_offer := _generate_racquet_upgrade_offer()
	if not racquet_offer.is_empty():
		choices.append(racquet_offer)
	return choices

func _generate_shop_remove_offer() -> Dictionary:
	if deck_card_ids.size() <= 5:
		return {}
	var price := _shop_remove_price()
	return {
		"reward_type": "shop_remove",
		"name": "Deck Purge Service",
		"description": "Pay the stringer to cut one weak card from the deck and tighten your draw quality.",
		"price_btc": price,
		"display_type": "CUT",
		"display_art": "Deck Surgeon",
		"display_icon": "focus",
		"footer_text": "Remove 1 card for %d BTC" % price,
	}

func _generate_card_upgrade_choices(choice_count: int, is_shop_offer: bool = true) -> Array:
	var unique_ids: Array = []
	var seen: Dictionary = {}
	for card_id in deck_card_ids:
		var card = _card_database.get_card(StringName(card_id))
		if card == null or card.upgrade_to == &"":
			continue
		if seen.has(String(card.id)):
			continue
		seen[String(card.id)] = true
		unique_ids.append(String(card.id))
	_shuffle_with_rng(unique_ids, _rng)
	var choices: Array = []
	for index in range(mini(choice_count, unique_ids.size())):
		var base_card_id := String(unique_ids[index])
		var base_card = _card_database.get_card(StringName(base_card_id))
		if base_card == null:
			continue
		var upgraded_card = _card_database.get_card(base_card.upgrade_to)
		if upgraded_card == null:
			continue
		var price := _card_upgrade_price(base_card)
		var reward_type := "card_upgrade" if is_shop_offer else "reward_upgrade"
		var footer_text := "Upgrade one copy for %d BTC, then trim one card" % price if is_shop_offer else "Upgrade one copy to +, then trim one card"
		choices.append({
			"reward_type": reward_type,
			"name": "%s -> %s" % [base_card.name, upgraded_card.name],
			"description": upgraded_card.description,
			"base_card_id": String(base_card.id),
			"upgraded_card_id": String(upgraded_card.id),
			"price_btc": price if is_shop_offer else 0,
			"display_type": "UPGRADE" if is_shop_offer else "PLUS",
			"display_art": "Card Lab",
			"display_icon": "pressure",
			"footer_text": footer_text,
		})
	return choices

func _generate_shop_potion_choices(choice_count: int) -> Array:
	if potion_ids.size() >= MAX_POTIONS:
		return []
	var source_pool: Array = _potion_database.get_shop_pool()
	if source_pool.is_empty():
		return []
	var weighted_pool: Array = []
	for potion in source_pool:
		weighted_pool.append({
			"potion": potion,
			"weight": _shop_potion_weight(potion),
		})
	var rewards: Array = []
	var offer_count := mini(choice_count, MAX_POTIONS - potion_ids.size())
	while rewards.size() < offer_count and not weighted_pool.is_empty():
		var selected_index := _pick_weighted_shop_entry(weighted_pool)
		var entry: Dictionary = weighted_pool[selected_index]
		weighted_pool.remove_at(selected_index)
		var potion = entry.get("potion")
		rewards.append({
			"reward_type": "shop_potion",
			"potion_id": String(potion.id),
			"name": potion.name,
			"description": potion.description,
			"rarity": potion.rarity,
			"price_btc": int(potion.price_btc),
			"display_type": "POTION",
			"display_art": String(potion.art_label),
			"display_icon": String(potion.icon_kind),
			"footer_text": "Costs %d BTC • Belt %d/%d" % [int(potion.price_btc), potion_ids.size(), MAX_POTIONS],
		})
	return rewards

func _generate_shop_relic_choices(choice_count: int) -> Array:
	var source_pool: Array = _relic_database.get_reward_pool(PackedStringArray(["common", "uncommon", "rare"]))
	var weighted_pool: Array = []
	for relic in source_pool:
		if relic_ids.has(String(relic.id)):
			continue
		weighted_pool.append({
			"relic": relic,
			"weight": _relic_reward_weight(relic),
		})
	var rewards: Array = []
	while rewards.size() < choice_count and not weighted_pool.is_empty():
		var selected_index := _pick_weighted_shop_entry(weighted_pool)
		var entry: Dictionary = weighted_pool[selected_index]
		weighted_pool.remove_at(selected_index)
		var relic = entry.get("relic")
		var price := _shop_relic_price(relic)
		rewards.append({
			"reward_type": "shop_relic",
			"relic_id": String(relic.id),
			"name": relic.name,
			"description": relic.description,
			"rarity": relic.rarity,
			"price_btc": price,
			"display_type": "RELIC",
			"display_art": "Tour Gear",
			"display_icon": "trophy",
			"footer_text": "Costs %d BTC" % price,
		})
	return rewards

func _generate_racquet_upgrade_offer() -> Dictionary:
	if racquet_tuning_level >= 3:
		return {}
	var price := 18 + racquet_tuning_level * 10
	return {
		"reward_type": "racquet_upgrade",
		"name": "Racquet Workshop Lv.%d" % (racquet_tuning_level + 1),
		"description": "Improve all future racquet-weight setups this run with extra guard and pressure tuning.",
		"price_btc": price,
		"display_type": "TUNE",
		"display_art": "Frame Bench",
		"display_icon": "frame",
		"footer_text": "Upgrade racquet systems for %d BTC" % price,
	}

func _shop_card_price(card_offer: Dictionary) -> int:
	var card_id := String(card_offer.get("card_id", ""))
	var card = _card_database.get_card(StringName(card_id))
	var effects := {}
	var tags := _to_packed_strings(card_offer.get("tags", []))
	var cost := int(card_offer.get("cost", 0))
	if card != null:
		effects = Dictionary(card.effects)
		tags = PackedStringArray(card.tags)
		cost = int(card.cost)

	var score := 6.0 + float(cost) * 2.5
	score += float(int(effects.get("damage", 0))) * 0.55
	score += float(int(effects.get("guard", 0))) * 0.34
	score += float(int(effects.get("heal", 0))) * 0.75
	score += float(int(effects.get("pressure", 0))) * 1.6
	score += float(int(effects.get("spin", 0))) * 1.4
	score += float(int(effects.get("open_court", 0))) * 1.8
	score += float(int(effects.get("draw", 0))) * 3.5
	score += float(int(effects.get("combo_draw", 0))) * 2.8
	score += float(int(effects.get("draw_if_pressured", 0))) * 2.5
	score += float(int(effects.get("draw_if_returning", 0))) * 2.5
	score += float(int(effects.get("momentum", 0))) * 2.0
	score += float(int(effects.get("focus", 0))) * 2.2
	score += float(int(effects.get("focus_if_returning", 0))) * 2.0
	score += float(int(effects.get("next_turn_stamina", 0))) * 3.0
	score += float(int(effects.get("endurance_scaling", 0))) * 4.0
	score += float(int(effects.get("retain_bonus", 0))) * 4.0
	score += float(int(effects.get("next_net_bonus_damage", 0))) * 0.45
	score += float(int(effects.get("bonus_vs_guard", 0))) * 0.40
	score += float(int(effects.get("bonus_vs_spin", 0))) * 0.45
	if effects.has("multi_hit"):
		for hit_value in PackedInt32Array(effects.get("multi_hit", PackedInt32Array())):
			score += float(int(hit_value)) * 0.38
	if effects.has("string_modifiers"):
		score += 8.0 + float(Dictionary(effects.get("string_modifiers", {})).size()) * 1.6
	if effects.has("racquet_modifiers"):
		score += 14.0 + float(Dictionary(effects.get("racquet_modifiers", {})).size()) * 1.9
	if bool(effects.get("exhaust", false)):
		score -= 1.5
	if tags.has("modifier"):
		score += 2.0
	if tags.has("string"):
		score += 5.0
	if tags.has("racquet") or tags.has("weight"):
		score += 12.0
	if tags.has("serve") or tags.has("return"):
		score += 1.0
	if tags.has("signature"):
		score += 4.0
	if tags.has("power"):
		score += 2.5
	if tags.has("healing"):
		score += 2.0
	return clampi(int(round(score)), 8, 58)

func _card_upgrade_price(card) -> int:
	var price := 14 + int(card.cost) * 4
	if card.tags.has("modifier"):
		price += 4
	if card.tags.has("signature"):
		price += 3
	return price

func _shop_remove_price() -> int:
	var bloating := maxi(0, deck_card_ids.size() - 20)
	var base_price := 16 + current_act * 2 + int(floor(float(bloating) / 2.0))
	# Each removal raises the cost 10% compounding — encourages early trimming over late hoarding
	var scaled := int(ceil(float(base_price) * pow(1.1, deck_removal_count)))
	return clampi(scaled, 18, 60)

func _shop_relic_price(relic) -> int:
	if relic == null:
		return 999
	var price := 24
	match String(relic.rarity):
		"uncommon":
			price = 34
		"rare":
			price = 48
	if _relic_matches_class_plan(relic):
		price += 4
	return price

func _shop_potion_weight(potion) -> int:
	if potion == null:
		return 1
	var weight := 1
	match String(potion.id):
		"spin_serum":
			weight += _deck_tag_count("topspin") + _deck_tag_count("slice")
		"stamina_gel":
			weight += _deck_tag_count("power") + _deck_tag_count("net")
		"focus_salts":
			weight += _deck_tag_count("control") + _deck_tag_count("return")
		"clutch_draught":
			weight += _deck_tag_count("signature") + _deck_tag_count("power")
	if _find_accessible_node_by_type("boss") >= 0:
		weight += 2
	return maxi(1, weight)

func _pick_weighted_shop_entry(weighted_pool: Array) -> int:
	var total_weight := 0
	for entry in weighted_pool:
		total_weight += int(entry.get("weight", 1))
	var roll := _rng.randi_range(1, maxi(1, total_weight))
	var running := 0
	for index in range(weighted_pool.size()):
		running += int(weighted_pool[index].get("weight", 1))
		if roll <= running:
			return index
	return 0

func _can_afford(price_btc: int) -> bool:
	return bitcoin >= maxi(0, price_btc)

func _replace_first_card(base_card_id: String, upgraded_card_id: String) -> bool:
	for index in range(deck_card_ids.size()):
		if String(deck_card_ids[index]) == base_card_id:
			deck_card_ids[index] = upgraded_card_id
			return true
	return false

func _remove_first_card(card_id: String) -> bool:
	for index in range(deck_card_ids.size()):
		if String(deck_card_ids[index]) == card_id:
			deck_card_ids.remove_at(index)
			return true
	return false

func _generate_deck_trim_choices() -> Array:
	var counts: Dictionary = {}
	for card_id in deck_card_ids:
		var key := String(card_id)
		counts[key] = int(counts.get(key, 0)) + 1
	var unique_ids := counts.keys()
	unique_ids.sort()
	var choices: Array = []
	for card_id in unique_ids:
		var card = _card_database.get_card(StringName(String(card_id)))
		if card == null:
			continue
		var copies := int(counts.get(card_id, 1))
		choices.append({
			"reward_type": "deck_trim",
			"card_id": String(card.id),
			"name": card.name,
			"description": "Remove one copy of %s from the deck to complete the upgrade path." % card.name,
			"cost": card.cost,
			"tags": PackedStringArray(card.tags),
			"display_type": "CUT",
			"display_art": "Deck Trim",
			"display_icon": "focus",
			"footer_text": "Remove 1 copy (%d in deck)" % copies,
		})
	return choices

func _is_checkpoint_menu() -> bool:
	for choice in pending_reward_choices:
		var reward_type := String(Dictionary(choice).get("reward_type", ""))
		if SHOP_REWARD_TYPES.has(reward_type) or reward_type in ["rest_heal", "rest_endurance", "rest_focus", "reward_upgrade"]:
			return true
	return false

func _generate_card_rewards(choice_count: int, preferred_tags: PackedStringArray = PackedStringArray()) -> Array:
	var all_cards: Array = _card_database.get_all_cards()
	all_cards.sort_custom(func(a, b) -> bool:
		return String(a.id) < String(b.id)
	)
	var weighted_pool: Array = []
	for card in all_cards:
		if BASIC_REWARD_EXCLUSIONS.has(String(card.id)):
			continue
		weighted_pool.append({
			"card": card,
			"weight": _reward_card_weight(card, preferred_tags),
		})
	if weighted_pool.is_empty():
		for card in all_cards:
			if BASIC_REWARD_EXCLUSIONS.has(String(card.id)):
				continue
			weighted_pool.append({
				"card": card,
				"weight": 1,
			})

	var rewards: Array = []
	while rewards.size() < choice_count and not weighted_pool.is_empty():
		var index := _pick_weighted_card_index(weighted_pool)
		var entry: Dictionary = weighted_pool[index]
		var card = entry.get("card")
		weighted_pool.remove_at(index)
		rewards.append({
			"reward_type": "card",
			"card_id": String(card.id),
			"name": card.name,
			"description": card.description,
			"cost": card.cost,
			"tags": PackedStringArray(card.tags),
		})
	_maybe_force_return_offer(rewards, all_cards)
	return rewards

func _generate_shop_card_rewards(choice_count: int) -> Array:
	var all_cards: Array = _card_database.get_all_cards()
	var weighted_pool: Array = []
	for card in all_cards:
		if BASIC_REWARD_EXCLUSIONS.has(String(card.id)):
			continue
		weighted_pool.append({
			"card": card,
			"weight": _shop_card_weight(card),
		})

	var rewards: Array = []
	while rewards.size() < choice_count and not weighted_pool.is_empty():
		var selected_index := _pick_weighted_card_index(weighted_pool)
		var entry: Dictionary = weighted_pool[selected_index]
		var card = entry.get("card")
		weighted_pool.remove_at(selected_index)
		var reward := {
			"reward_type": "card",
			"card_id": String(card.id),
			"name": card.name,
			"description": card.description,
			"cost": card.cost,
			"tags": PackedStringArray(card.tags),
		}
		var synergy_note := _equipment_synergy_note_for_card(card)
		if synergy_note != "":
			reward["footer_text"] = synergy_note
		rewards.append(reward)
	_maybe_force_return_offer(rewards, all_cards)
	return rewards

func _maybe_force_return_offer(rewards: Array, all_cards: Array) -> void:
	if rewards.is_empty():
		return
	if _return_reward_bias() < _return_offer_force_threshold():
		return
	for reward in rewards:
		var reward_tags = Dictionary(reward).get("tags", PackedStringArray())
		if typeof(reward_tags) == TYPE_PACKED_STRING_ARRAY and PackedStringArray(reward_tags).has("return"):
			return
	var forced_reward := _best_tagged_reward_offer("return", rewards, all_cards)
	if forced_reward.is_empty():
		return
	rewards[rewards.size() - 1] = forced_reward

func _best_tagged_reward_offer(tag: String, current_rewards: Array, all_cards: Array) -> Dictionary:
	var taken_ids := {}
	for reward in current_rewards:
		taken_ids[String(Dictionary(reward).get("card_id", ""))] = true
	var best_card = null
	var best_weight := -1
	for card in all_cards:
		if BASIC_REWARD_EXCLUSIONS.has(String(card.id)):
			continue
		if taken_ids.has(String(card.id)):
			continue
		if not card.tags.has(tag):
			continue
		var weight := _reward_card_weight(card, PackedStringArray([tag]))
		if weight > best_weight:
			best_weight = weight
			best_card = card
	if best_card == null:
		return {}
	return {
		"reward_type": "card",
		"card_id": String(best_card.id),
		"name": best_card.name,
		"description": best_card.description,
		"cost": best_card.cost,
		"tags": PackedStringArray(best_card.tags),
	}

func _shop_card_weight(card) -> int:
	var weight := 1
	if card.tags.has("modifier"):
		weight += 5
	if card.tags.has("string"):
		weight += 4
	if card.tags.has("racquet") or card.tags.has("weight"):
		weight += 4
	if card.tags.has("skill") or card.tags.has("recovery") or card.tags.has("footwork") or card.tags.has("control"):
		weight += 2
	if card.tags.has("return"):
		weight += _return_reward_bias()
	if _card_matches_class_equipment_synergy(card):
		weight += 4
	return weight

func _reward_card_weight(card, preferred_tags: PackedStringArray = PackedStringArray()) -> int:
	var weight := 1
	if not preferred_tags.is_empty():
		if _card_has_any_tag(card, preferred_tags):
			weight += 7
		else:
			weight += 1
	for tag in _class_reward_affinity_tags():
		if card.tags.has(tag):
			weight += 2
	if card.tags.has("return"):
		weight += _return_reward_bias()
	if _card_matches_class_equipment_synergy(card):
		weight += 1
	return weight

func _return_reward_bias() -> int:
	var bias := 0
	var return_count := _deck_tag_count("return")
	if return_count > 0:
		bias += mini(4, return_count)
	if _deck_tag_count("serve") > 0:
		bias += 2
	bias += _return_class_bias()
	return bias

func _return_class_bias() -> int:
	match player_class_id:
		&"novice":
			return 4
		&"pusher":
			return 6
		&"slicer":
			return 3
		&"power":
			return 6
		&"all_arounder":
			return 4
		&"baseliner":
			return 2
		&"serve_and_volley":
			return 8
		&"master":
			return 2
		&"alcaraz":
			return 4
	return 0

func _return_offer_force_threshold() -> int:
	match player_class_id:
		&"serve_and_volley", &"pusher":
			return 5
		&"novice", &"all_arounder", &"alcaraz":
			return 6
		&"power":
			return 5
		&"slicer":
			return 7
		_:
			return 99

func _class_reward_affinity_tags() -> PackedStringArray:
	match player_class_id:
		&"novice":
			return PackedStringArray(["return", "control", "recovery"])
		&"pusher":
			return PackedStringArray(["return", "control", "footwork"])
		&"slicer":
			return PackedStringArray(["slice", "return", "control"])
		&"power":
			return PackedStringArray(["serve", "return", "power", "recovery", "training", "tempo", "control"])
		&"all_arounder":
			return PackedStringArray(["return", "control"])
		&"baseliner":
			return PackedStringArray(["topspin", "rally", "return", "recovery", "control", "signature", "footwork"])
		&"serve_and_volley":
			return PackedStringArray(["serve", "return", "volley"])
		&"master":
			return PackedStringArray(["control", "return", "tempo", "recovery", "technique"])
		&"alcaraz":
			return PackedStringArray(["serve", "return", "tempo", "signature", "footwork", "topspin", "recovery", "net", "control"])
	return PackedStringArray()

func _deck_tag_count(tag: String) -> int:
	var count := 0
	for card_id in deck_card_ids:
		var card = _card_database.get_card(StringName(String(card_id)))
		if card != null and card.tags.has(tag):
			count += 1
	return count

func _pick_weighted_card_index(weighted_pool: Array) -> int:
	var total_weight := 0
	for entry in weighted_pool:
		total_weight += int(entry.get("weight", 1))
	var roll := _rng.randi_range(1, maxi(1, total_weight))
	var running := 0
	for index in range(weighted_pool.size()):
		running += int(weighted_pool[index].get("weight", 1))
		if roll <= running:
			return index
	return 0

func _card_matches_class_equipment_synergy(card) -> bool:
	var card_id := String(card.id)
	match player_class_id:
		&"novice":
			return card_id == "natural_gut_lacing" or card_id == "synthetic_gut_setup" or card_id == "head_light_control_frame"
		&"pusher":
			return card_id == "natural_gut_lacing" or card_id == "multifilament_touch" or card_id == "counterweighted_handle"
		&"slicer":
			return card_id == "natural_gut_lacing" or card_id == "multifilament_touch" or card_id == "lead_tape_3_9" or card_id == "head_light_control_frame"
		&"power":
			return card_id == "kevlar_coil" or card_id == "polyester_bed" or card_id == "synthetic_gut_setup" or card_id == "hybrid_string_job" or card_id == "pro_stock_frame" or card_id == "lead_tape_12" or card_id == "extra_long_leverage_frame"
		&"all_arounder":
			return card_id == "hybrid_string_job" or card_id == "synthetic_gut_setup" or card_id == "lead_tape_3_9" or card_id == "counterweighted_handle"
		&"baseliner":
			return card_id == "polyester_bed" or card_id == "pro_stock_frame"
		&"serve_and_volley":
			return card_id == "hybrid_string_job" or card_id == "multifilament_touch" or card_id == "lead_tape_12" or card_id == "counterweighted_handle"
		&"master":
			return card_id == "natural_gut_lacing" or card_id == "lead_tape_3_9" or card_id == "head_light_control_frame"
		&"alcaraz":
			return card_id == "hybrid_string_job" or card_id == "polyester_bed" or card_id == "lead_tape_12" or card_id == "extra_long_leverage_frame"
	return false

func _equipment_synergy_note_for_card(card) -> String:
	if card == null:
		return ""
	var effects := Dictionary(card.effects)
	if effects.has("string_type"):
		return _class_database.get_string_synergy_note(player_class_id, String(effects.get("string_type", "")))
	if effects.has("racquet_weight_type"):
		return _class_database.get_racquet_synergy_note(player_class_id, String(effects.get("racquet_weight_type", "")))
	return ""

func _generate_relic_rewards(choice_count: int, allowed_rarities: PackedStringArray = PackedStringArray()) -> Array:
	var source_pool: Array = _relic_database.get_reward_pool(allowed_rarities)
	var weighted_pool: Array = []
	for relic in source_pool:
		if not relic_ids.has(String(relic.id)):
			weighted_pool.append({
				"relic": relic,
				"weight": _relic_reward_weight(relic),
			})

	var rewards: Array = []
	while rewards.size() < choice_count and not weighted_pool.is_empty():
		var index := _pick_weighted_relic_index(weighted_pool)
		var entry: Dictionary = weighted_pool[index]
		var relic = entry.get("relic")
		weighted_pool.remove_at(index)
		rewards.append({
			"reward_type": "relic",
			"relic_id": String(relic.id),
			"name": relic.name,
			"description": relic.description,
			"rarity": relic.rarity,
		})
	_maybe_force_return_relic_offer(rewards, source_pool)
	return rewards

func _relic_reward_weight(relic) -> int:
	var weight := 1
	if String(relic.rarity) == "boss":
		weight += 2
	elif String(relic.rarity) == "rare":
		weight += 1
	if _relic_supports_return_archetype(relic):
		weight += _return_reward_bias()
		if _deck_tag_count("return") > 0:
			weight += 2
	if _relic_matches_class_plan(relic):
		weight += 2
	return weight

func _pick_weighted_relic_index(weighted_pool: Array) -> int:
	var total_weight := 0
	for entry in weighted_pool:
		total_weight += int(entry.get("weight", 1))
	var roll := _rng.randi_range(1, maxi(1, total_weight))
	var running := 0
	for index in range(weighted_pool.size()):
		running += int(weighted_pool[index].get("weight", 1))
		if roll <= running:
			return index
	return 0

func _maybe_force_return_relic_offer(rewards: Array, source_pool: Array) -> void:
	if rewards.is_empty():
		return
	if _return_reward_bias() < _return_offer_force_threshold():
		return
	for reward in rewards:
		if _is_return_relic_id(String(Dictionary(reward).get("relic_id", ""))):
			return
	var forced_reward := _best_return_relic_offer(rewards, source_pool)
	if forced_reward.is_empty():
		return
	rewards[rewards.size() - 1] = forced_reward

func _best_return_relic_offer(current_rewards: Array, source_pool: Array) -> Dictionary:
	var taken_ids := {}
	for reward in current_rewards:
		taken_ids[String(Dictionary(reward).get("relic_id", ""))] = true
	var best_relic = null
	var best_weight := -1
	for relic in source_pool:
		if relic_ids.has(String(relic.id)):
			continue
		if taken_ids.has(String(relic.id)):
			continue
		if not _relic_supports_return_archetype(relic):
			continue
		var weight := _relic_reward_weight(relic)
		if weight > best_weight:
			best_weight = weight
			best_relic = relic
	if best_relic == null:
		return {}
	return {
		"reward_type": "relic",
		"relic_id": String(best_relic.id),
		"name": best_relic.name,
		"description": best_relic.description,
		"rarity": best_relic.rarity,
	}

func _relic_supports_return_archetype(relic) -> bool:
	if relic == null:
		return false
	var relic_id := String(relic.id)
	if _is_return_relic_id(relic_id):
		return true
	for key in Dictionary(relic.effects).keys():
		if String(key).begins_with("return_"):
			return true
	return false

func _is_return_relic_id(relic_id: String) -> bool:
	return relic_id in ["serve_scout_notes", "return_coach", "chip_charge_playbook"]

func _relic_matches_class_plan(relic) -> bool:
	if relic == null:
		return false
	var relic_id := String(relic.id)
	match player_class_id:
		&"novice":
			return relic_id in ["serve_scout_notes", "return_coach", "big_sweet_spot"]
		&"pusher":
			return relic_id in ["serve_scout_notes", "return_coach", "headband", "court_shoes"]
		&"slicer":
			return relic_id in ["string_saver", "serve_scout_notes", "return_coach"]
		&"power":
			return relic_id in ["return_coach", "chip_charge_playbook", "serve_clock", "lead_tape"]
		&"all_arounder":
			return relic_id in ["return_coach", "serve_scout_notes", "headband"]
		&"baseliner":
			return relic_id in ["polyester_strings", "big_sweet_spot", "clay_specialist"]
		&"serve_and_volley":
			return relic_id in ["chip_charge_playbook", "serve_scout_notes", "grass_specialist", "return_coach"]
		&"master":
			return relic_id in ["mental_coach", "return_coach", "big_sweet_spot"]
		&"alcaraz":
			return relic_id in ["return_coach", "chip_charge_playbook", "mental_coach", "polyester_strings"]
	return false

func _card_has_any_tag(card, tags: PackedStringArray) -> bool:
	for tag in tags:
		if card.tags.has(tag):
			return true
	return false

func _relic_effect_value(effect_name: String) -> int:
	var total := 0
	for relic_id in relic_ids:
		var relic = _relic_database.get_relic(StringName(relic_id))
		if relic != null:
			total += int(relic.effects.get(effect_name, 0))
	return total

func _pick_random_featured_entry(act: int = -1) -> Dictionary:
	var major_data := get_major_data(act)
	var featured_field: Array = Array(major_data.get("featured_field", []))
	if featured_field.is_empty():
		return {}
	return Dictionary(featured_field[_rng.randi_range(0, featured_field.size() - 1)])

func _show_reveal(title: String, body: String) -> void:
	reveal_title = title
	reveal_body = body
	reveal_visible = true

func _normalize_reward_choices(raw_choices) -> Array:
	var normalized: Array = []
	if typeof(raw_choices) != TYPE_ARRAY:
		return normalized
	for raw_choice in raw_choices:
		if typeof(raw_choice) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = raw_choice.duplicate(true)
		if choice.has("tags"):
			choice["tags"] = _to_packed_strings(choice.get("tags", []))
		normalized.append(choice)
	return normalized

func _to_packed_strings(values) -> PackedStringArray:
	var packed := PackedStringArray()
	if typeof(values) != TYPE_ARRAY and typeof(values) != TYPE_PACKED_STRING_ARRAY:
		return packed
	for value in values:
		packed.append(String(value))
	return packed

func _to_packed_ints(values) -> PackedInt32Array:
	var packed := PackedInt32Array()
	if typeof(values) != TYPE_ARRAY and typeof(values) != TYPE_PACKED_INT32_ARRAY:
		return packed
	for value in values:
		packed.append(int(value))
	return packed

func _packed_strings_to_array(values: PackedStringArray) -> Array:
	var output: Array = []
	for value in values:
		output.append(String(value))
	return output

func _packed_ints_to_array(values: PackedInt32Array) -> Array:
	var output: Array = []
	for value in values:
		output.append(int(value))
	return output
