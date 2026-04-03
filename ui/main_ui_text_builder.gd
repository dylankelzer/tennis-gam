class_name MainUITextBuilder
extends RefCounted

const FRONT_SCREEN_LANDING := "landing"
const FRONT_SCREEN_CLASS_SELECT := "class_select"
const FRONT_SCREEN_TRANSITION := "transition"

var _card_database: CardDatabase
var _model_database: CharacterModelDatabase
var _unlock_progression: UnlockProgression

func _init(card_database: CardDatabase, model_database: CharacterModelDatabase, unlock_progression: UnlockProgression) -> void:
	_card_database = card_database
	_model_database = model_database
	_unlock_progression = unlock_progression

func build_class_text(selected_class, compact: bool = false) -> String:
	if selected_class == null:
		return "No class is currently available."

	var lines := PackedStringArray()
	var stat_line := "STA %s | END %s | STR %s | CTL %s | FWT %s | FOC %s" % [
		str(selected_class.base_stats.get("stamina", 0)),
		str(selected_class.base_stats.get("endurance", 0)),
		str(selected_class.base_stats.get("strength", 0)),
		str(selected_class.base_stats.get("control", 0)),
		str(selected_class.base_stats.get("footwork", 0)),
		str(selected_class.base_stats.get("focus", 0)),
	]
	if compact:
		lines.append("Passive - %s" % selected_class.passive_name)
		lines.append(selected_class.passive_description)
		lines.append("")
		lines.append("Stat Line")
		lines.append(stat_line)
		lines.append("")
		lines.append("Signature Package")
		lines.append(_join_strings(PackedStringArray(Array(selected_class.signature_shots).slice(0, 4))))
		var model_compact = _model_database.get_model(selected_class.id)
		if model_compact != null:
			lines.append("")
			lines.append("Visual Direction")
			lines.append("%s • %s" % [String(model_compact.model_name), String(model_compact.fantasy_lineage)])
		lines.append("")
		lines.append("Starter Mix")
		for mix_line in build_deck_mix_lines(Array(selected_class.starting_deck)):
			lines.append("- %s" % mix_line)
		return "\n".join(lines)
	lines.append("%s - %s" % [selected_class.name, selected_class.archetype])
	lines.append(selected_class.summary)
	lines.append("")
	lines.append("Passive - %s" % selected_class.passive_name)
	lines.append(selected_class.passive_description)
	lines.append("")
	lines.append("Stat Line")
	lines.append(stat_line)
	lines.append("")
	lines.append("Signature Shots")
	for shot_name in selected_class.signature_shots:
		lines.append("- %s" % shot_name)

	var model = _model_database.get_model(selected_class.id)
	if model != null:
		lines.append("")
		lines.append("Character Model")
		lines.append("- Concept: %s" % model.model_name)
		lines.append("- Inspiration: %s" % _join_strings(model.real_world_inspirations))
		lines.append("- Fantasy lineage: %s" % model.fantasy_lineage)
		lines.append("- Silhouette: %s" % model.silhouette)
		lines.append("- Palette: %s" % _join_strings(model.palette))

	lines.append("")
	lines.append("Starting Deck Mix")
	for mix_line in build_deck_mix_lines(Array(selected_class.starting_deck)):
		lines.append("- %s" % mix_line)
	return "\n".join(lines)

func build_deck_mix_lines(deck_ids: Array) -> PackedStringArray:
	var counts := {}
	var ordered_ids := []
	for raw_card_id in deck_ids:
		var card_id := String(raw_card_id)
		if not counts.has(card_id):
			counts[card_id] = 0
			ordered_ids.append(card_id)
		counts[card_id] = int(counts[card_id]) + 1
	var lines := PackedStringArray()
	for card_id in ordered_ids:
		var card = _card_database.get_card(StringName(card_id))
		var card_name := String(card_id).capitalize()
		if card != null:
			card_name = card.name
		var count := int(counts.get(card_id, 0))
		if count > 1:
			lines.append("%dx %s" % [count, card_name])
		else:
			lines.append(card_name)
	return lines

func build_run_status_text(run_state: RunState, progress: Dictionary, available_class_count: int, total_class_count: int, has_saved_run: bool, front_screen_mode: String) -> String:
	var lines := PackedStringArray()
	lines.append(run_state.status_message)
	if run_state.phase == "idle":
		if front_screen_mode == FRONT_SCREEN_LANDING:
			lines.append("Press Start Run to enter class select.")
		elif front_screen_mode == FRONT_SCREEN_TRANSITION:
			lines.append("Loading the opening round and building the first match screen.")
		else:
			lines.append("Pick a class, then begin the tournament.")
		lines.append("")
		lines.append("Persistent Progress")
		lines.append("Run Clears: %d" % int(progress.get("run_clears", 0)))
		lines.append("Available Classes: %d / %d" % [available_class_count, total_class_count])
		lines.append("Saved Checkpoint: %s" % ("Ready to continue" if has_saved_run else "None"))
	else:
		lines.append("")
		lines.append("Condition %d / %d | Deck %d | Relics %d" % [
			run_state.current_condition,
			run_state.max_condition,
			run_state.deck_card_ids.size(),
			run_state.relic_ids.size(),
		])
		lines.append("Bitcoin %d BTC | Racquet Tune Lv.%d | Potions %d/%d" % [
			int(run_state.bitcoin),
			int(run_state.racquet_tuning_level),
			int(run_state.potion_ids.size()),
			int(RunState.MAX_POTIONS),
		])
		lines.append("Checkpoint: %s" % ("Ready" if has_saved_run else "None"))
	return "\n".join(lines)

func build_tournament_log_block(major_data: Dictionary, run_state: RunState) -> String:
	if major_data.is_empty():
		return "Tournament Desk\nNo major active."
	var lines := PackedStringArray()
	lines.append("Tournament Desk")
	lines.append(String(major_data.get("name", "Major")) + " - " + String(major_data.get("surface", "Court")))
	lines.append("Wallet: %d BTC | Racquet Tune Lv.%d | Potions %d/%d" % [
		int(run_state.bitcoin),
		int(run_state.racquet_tuning_level),
		int(run_state.potion_ids.size()),
		int(RunState.MAX_POTIONS),
	])
	lines.append("Court Effect: " + String(major_data.get("surface_rule_text", "No surface modifier.")))
	var final_rule: Dictionary = Dictionary(major_data.get("final_rule", {}))
	lines.append("Final Twist: " + String(final_rule.get("name", "Final Rule")))
	var featured_field: Array = Array(major_data.get("featured_field", []))
	for entry in featured_field:
		lines.append("#%d %s - %s" % [int(entry.get("seed", 0)), String(entry.get("name", "Contender")), String(entry.get("role", ""))])
	return "\n".join(lines)

func build_node_info_text(run_state: RunState, front_screen_mode: String) -> String:
	match run_state.phase:
		"idle":
			if front_screen_mode == FRONT_SCREEN_CLASS_SELECT:
				return "Cycle through the available classes, compare their starting decks, and press Begin Tournament when you are ready."
			if front_screen_mode == FRONT_SCREEN_TRANSITION:
				return "Loading the opening round. The class-select screen is paused while the first match is prepared."
			return "Press Start Run to open class select."
		"map":
			return String(run_state.get_node_summary()) + "\n\nClick a highlighted node to travel there."
		"combat":
			return String(run_state.get_node_summary()) + "\n\nResolve the match on the right. The map will unlock again after the encounter."
		"reward":
			return "Checkpoint open. Draft rewards, spend bitcoin, or leave the checkpoint from the right panel before moving on."
		"run_won", "run_lost":
			return run_state.status_message
		_:
			return run_state.get_node_summary()

func _join_strings(values: PackedStringArray) -> String:
	if values.is_empty():
		return ""
	return ", ".join(values)
