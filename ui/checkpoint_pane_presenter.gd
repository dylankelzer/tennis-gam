extends RefCounted

func build_next_round(run_state) -> String:
	var next_round := "Next branch"
	var next_node_id := int(run_state.get_primary_accessible_node_id())
	var next_node = run_state.get_node(next_node_id) if next_node_id >= 0 else null
	if next_node != null:
		next_round = "%s • %s" % [
			String(run_state.get_round_name(int(next_node.floor))),
			String(next_node.node_type).capitalize(),
		]
	return next_round

func build_run_ledger(run_state, max_potions: int, include_potions: bool = true) -> String:
	var lines := PackedStringArray([
		"Condition %d / %d" % [int(run_state.current_condition), int(run_state.max_condition)],
		"Bitcoin %d BTC" % int(run_state.bitcoin),
		"Racquet Tune Lv.%d" % int(run_state.racquet_tuning_level),
		"Deck %d cards" % int(run_state.deck_card_ids.size()),
		"Relics %d" % int(run_state.relic_ids.size()),
	])
	if include_potions:
		lines.append("Potions %d / %d" % [int(run_state.potion_ids.size()), max_potions])
	return "\n".join(lines)

func build_rest_payload(run_state, max_potions: int) -> Dictionary:
	var next_round := build_next_round(run_state)
	return {
		"eyebrow": String(run_state.get_major_name()) + " Recovery Camp",
		"question": "Reset the body or sharpen the deck?",
		"summary": "Recovery stop between matches. Condition %d/%d, wallet %d BTC, and %s is waiting." % [
			int(run_state.current_condition),
			int(run_state.max_condition),
			int(run_state.bitcoin),
			next_round,
		],
		"ledger_title": "Camp Ledger",
		"ledger_body": build_run_ledger(run_state, max_potions),
		"hint": "Choose one checkpoint action: recover condition for the next match, or spend the stop on a card upgrade.",
		"leave_text": "Leave Camp",
		"header_title": String(run_state.get_major_name()) + " Recovery Camp",
		"header_body": "Restore condition or upgrade the deck before %s." % next_round,
	}

func build_reward_payload(run_state, reward_kind: String, max_potions: int) -> Dictionary:
	var next_round := build_next_round(run_state)
	var question := "What do you add to your bag for the next round?"
	var offer_title := "Reward Draft"
	var hint := "Pick one reward, or skip if you want to keep the deck lean."
	match reward_kind:
		"trim":
			question = "Choose one card to cut before you continue."
			offer_title = "Deck Trim"
			hint = "Upgrades are not locked in until you remove one card from the deck."
		"relic":
			question = "Pick the edge you want for the next rounds."
			offer_title = "Relic Draft"
			hint = "Relics are permanent for the run. Choose the one that fits your line."
	return {
		"eyebrow": "%s Reward Screen" % String(run_state.get_major_name()),
		"question": question,
		"summary": "%s\nNext stop: %s." % [String(run_state.pending_reward_reason).strip_edges(), next_round],
		"ledger_title": "Run Ledger",
		"ledger_body": build_run_ledger(run_state, max_potions),
		"offer_title": offer_title,
		"hint": hint,
		"header_title": String(run_state.get_major_name()) + " Reward Room",
		"header_body": "Draft for %s and shape the next round." % next_round,
	}

func build_shop_payload(run_state, max_potions: int) -> Dictionary:
	var next_round := build_next_round(run_state)
	return {
		"eyebrow": "%s Pro Shop" % String(run_state.get_major_name()),
		"question": "Spend sponsor money before the next round?",
		"summary": "Tour checkpoint between matches. Wallet %d BTC, potion belt %d/%d, and %s is coming next." % [
			int(run_state.bitcoin),
			int(run_state.potion_ids.size()),
			max_potions,
			next_round,
		],
		"ledger_title": "Checkpoint Ledger",
		"ledger_body": build_run_ledger(run_state, max_potions),
		"hint": "Potions are for boss pressure swings, relics are permanent, and cards plus frame tuning reshape the whole run. Use Back to Route whenever you are done here.",
		"leave_text": "Back to Route",
		"market_title": "Card Market and Workshop",
		"header_title": String(run_state.get_major_name()) + " Pro Shop",
		"header_body": "Spend BTC on gear before %s." % next_round,
	}
