@tool
class_name TelemetryBalanceAnalyzer
extends RefCounted

const TELEMETRY_DIR := "user://telemetry"
const REPORT_DIR := "user://telemetry/reports"
const INCLUDED_RUN_OUTCOMES := {
	"won": true,
	"lost": true,
	"abandoned": true,
}

func analyze_all_logs(log_dir: String = TELEMETRY_DIR) -> Dictionary:
	return _analyze_log_paths(_collect_log_paths(log_dir), "")

func analyze_run(run_id: String, log_dir: String = TELEMETRY_DIR) -> Dictionary:
	if run_id.strip_edges() == "":
		return _empty_summary()
	var path := "%s/%s.jsonl" % [log_dir, run_id]
	var paths := PackedStringArray()
	if FileAccess.file_exists(path):
		paths.append(path)
	return _analyze_log_paths(paths, run_id)

func write_report_bundle(summary: Dictionary, prefix: String = "latest", report_dir: String = REPORT_DIR) -> Dictionary:
	_ensure_dir(report_dir)
	var safe_prefix := _sanitize_prefix(prefix)
	var summary_path := "%s/%s_summary.json" % [report_dir, safe_prefix]
	var cards_path := "%s/%s_cards.csv" % [report_dir, safe_prefix]
	var enemies_path := "%s/%s_enemies.csv" % [report_dir, safe_prefix]
	_write_json(summary_path, summary)
	_write_csv(cards_path, [
		"card_id",
		"pick_count",
		"pick_run_count",
		"pick_run_rate",
		"pick_event_rate",
		"upgrade_count",
		"upgrade_run_count",
		"upgrade_per_pick",
		"win_rate_when_picked",
		"win_rate_delta",
	], _card_csv_rows(Array(summary.get("card_metrics", []))))
	_write_csv(enemies_path, [
		"act",
		"enemy_id",
		"encounters",
		"wins",
		"losses",
		"win_rate",
		"avg_condition_delta_player",
		"avg_rally_exchanges_per_turn",
		"forced_error_rate",
	], _enemy_csv_rows(Array(summary.get("enemy_metrics", []))))
	return {
		"summary_json": ProjectSettings.globalize_path(summary_path),
		"cards_csv": ProjectSettings.globalize_path(cards_path),
		"enemies_csv": ProjectSettings.globalize_path(enemies_path),
	}

func format_summary(summary: Dictionary) -> String:
	var lines := PackedStringArray()
	var overview: Dictionary = Dictionary(summary.get("overview", {}))
	lines.append("Telemetry balance summary")
	lines.append("Runs: %d | Included runs: %d | Win rate: %.1f%%" % [
		int(overview.get("total_runs", 0)),
		int(overview.get("included_runs", 0)),
		float(overview.get("global_win_rate", 0.0)) * 100.0,
	])
	lines.append("Card picks: %d | Upgrades: %d | Encounters: %d" % [
		int(overview.get("total_card_picks", 0)),
		int(overview.get("total_card_upgrades", 0)),
		int(overview.get("total_encounters", 0)),
	])
	lines.append("Avg rally exchanges/turn: %.2f | Avg condition delta/encounter: %.2f | Forced errors: %.1f%%" % [
		float(overview.get("avg_rally_exchanges_per_turn", 0.0)),
		float(overview.get("avg_condition_delta_per_encounter", 0.0)),
		float(overview.get("forced_error_frequency", 0.0)) * 100.0,
	])
	return "\n".join(lines)

func _analyze_log_paths(log_paths: PackedStringArray, run_filter: String) -> Dictionary:
	var runs := {}
	for log_path in log_paths:
		for event in _read_log_events(log_path):
			var run_id := String(event.get("run_id", ""))
			if run_filter != "" and run_id != run_filter:
				continue
			if run_id == "":
				continue
			var run_data: Dictionary = Dictionary(runs.get(run_id, _new_run_data(run_id)))
			_ingest_event(run_data, event)
			runs[run_id] = run_data
	return _build_summary(runs, log_paths, run_filter)

func _read_log_events(path: String) -> Array:
	var events: Array = []
	if not FileAccess.file_exists(path):
		return events
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return events
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "":
			continue
		if not (line.begins_with("{") and line.ends_with("}")):
			continue
		var json := JSON.new()
		if json.parse(line) != OK:
			continue
		var parsed = json.data
		if typeof(parsed) == TYPE_DICTIONARY:
			events.append(Dictionary(parsed))
	file.close()
	return events

func _ingest_event(run_data: Dictionary, event: Dictionary) -> void:
	var kind := String(event.get("kind", ""))
	run_data["event_count"] = int(run_data.get("event_count", 0)) + 1
	if kind == "run_started":
		run_data["class_id"] = String(event.get("class_id", event.get("player_class_id", run_data.get("class_id", ""))))
		run_data["seed"] = int(event.get("seed", run_data.get("seed", 0)))
	elif kind == "run_finished":
		run_data["outcome"] = String(event.get("outcome", ""))
	if kind in ["card_picked", "shop_card_bought"]:
		var picked_card_id := String(event.get("card_id", ""))
		if picked_card_id != "":
			var pick_counts: Dictionary = Dictionary(run_data.get("pick_counts", {}))
			pick_counts[picked_card_id] = int(pick_counts.get(picked_card_id, 0)) + 1
			run_data["pick_counts"] = pick_counts
			var picked_runs: Dictionary = Dictionary(run_data.get("picked_card_ids", {}))
			picked_runs[picked_card_id] = true
			run_data["picked_card_ids"] = picked_runs
	if kind == "card_upgraded":
		var upgraded_card_id := String(event.get("card_id", event.get("base_card_id", "")))
		if upgraded_card_id == "":
			upgraded_card_id = String(event.get("upgraded_card_id", ""))
		if upgraded_card_id != "":
			var upgrade_counts: Dictionary = Dictionary(run_data.get("upgrade_counts", {}))
			upgrade_counts[upgraded_card_id] = int(upgrade_counts.get(upgraded_card_id, 0)) + 1
			run_data["upgrade_counts"] = upgrade_counts
			var upgraded_runs: Dictionary = Dictionary(run_data.get("upgraded_card_ids", {}))
			upgraded_runs[upgraded_card_id] = true
			run_data["upgraded_card_ids"] = upgraded_runs

	var encounter_id := String(event.get("encounter_id", ""))
	if encounter_id == "":
		return
	var encounter: Dictionary = _ensure_encounter(run_data, encounter_id)
	encounter["act"] = int(event.get("act", encounter.get("act", 0)))
	encounter["enemy_id"] = String(event.get("enemy_id", encounter.get("enemy_id", "")))
	encounter["enemy_name"] = String(event.get("enemy_name", encounter.get("enemy_name", "")))
	encounter["match_label"] = String(event.get("match_label", encounter.get("match_label", "")))
	encounter["major_name"] = String(event.get("major_name", encounter.get("major_name", "")))
	encounter["surface"] = String(event.get("surface", encounter.get("surface", "")))

	match kind:
		"match_started":
			encounter["player_condition_start"] = int(event.get("player_condition", encounter.get("player_condition_start", 0)))
			encounter["enemy_condition_start"] = int(event.get("enemy_condition", encounter.get("enemy_condition_start", 0)))
		"match_event":
			_ingest_match_event(encounter, event)
		"encounter_finished":
			encounter["outcome"] = String(event.get("outcome", encounter.get("outcome", "")))
			encounter["result_reason"] = String(event.get("result_reason", encounter.get("result_reason", "")))
			encounter["player_condition_end"] = int(event.get("player_condition", encounter.get("player_condition_end", 0)))
			encounter["enemy_condition_end"] = int(event.get("enemy_condition", encounter.get("enemy_condition_end", 0)))
			encounter["final_point_number"] = int(event.get("point_number", encounter.get("final_point_number", 0)))
	run_data["encounters"][encounter_id] = encounter

func _ingest_match_event(encounter: Dictionary, event: Dictionary) -> void:
	var event_kind := String(event.get("event_kind", ""))
	if event_kind != "point_resolved":
		return
	var payload := Dictionary(event.get("payload", {}))
	encounter["points"] = int(encounter.get("points", 0)) + 1
	encounter["total_rally_exchanges"] = float(encounter.get("total_rally_exchanges", 0.0)) + float(payload.get("rally_exchanges", event.get("rally_exchanges", 0.0)))
	encounter["total_turns"] = float(encounter.get("total_turns", 0.0)) + float(event.get("turn_number", 0))
	var condition_delta := Dictionary(payload.get("condition_delta", {}))
	encounter["condition_delta_player"] = float(encounter.get("condition_delta_player", 0.0)) + float(condition_delta.get("player", 0.0))
	encounter["condition_delta_enemy"] = float(encounter.get("condition_delta_enemy", 0.0)) + float(condition_delta.get("enemy", 0.0))
	var forced_error := bool(payload.get("forced_error", false)) or String(payload.get("reason", "")) == "forced error"
	if forced_error:
		encounter["forced_error_points"] = int(encounter.get("forced_error_points", 0)) + 1
		if String(payload.get("winner", "")) == "enemy":
			encounter["player_forced_errors"] = int(encounter.get("player_forced_errors", 0)) + 1
		else:
			encounter["enemy_forced_errors"] = int(encounter.get("enemy_forced_errors", 0)) + 1

func _build_summary(runs: Dictionary, log_paths: PackedStringArray, run_filter: String) -> Dictionary:
	var total_runs := runs.size()
	var included_runs := 0
	var wins := 0
	var total_card_picks := 0
	var total_card_upgrades := 0
	var total_encounters := 0
	var total_condition_delta := 0.0
	var total_forced_error_points := 0
	var total_points := 0
	var total_rally_exchanges := 0.0
	var total_turns := 0.0
	var card_stats_map := {}
	var enemy_stats_map := {}

	for run_id in runs.keys():
		var run_data: Dictionary = Dictionary(runs[run_id])
		var outcome := String(run_data.get("outcome", ""))
		var include_run := INCLUDED_RUN_OUTCOMES.has(outcome)
		if include_run:
			included_runs += 1
			if outcome == "won":
				wins += 1

		var pick_counts: Dictionary = Dictionary(run_data.get("pick_counts", {}))
		for card_id in pick_counts.keys():
			var stat: Dictionary = Dictionary(card_stats_map.get(card_id, _new_card_stat(String(card_id))))
			var count := int(pick_counts[card_id])
			stat["pick_count"] = int(stat.get("pick_count", 0)) + count
			total_card_picks += count
			if include_run:
				stat["pick_run_count"] = int(stat.get("pick_run_count", 0)) + 1
				if outcome == "won":
					stat["pick_run_wins"] = int(stat.get("pick_run_wins", 0)) + 1
			card_stats_map[card_id] = stat

		var upgrade_counts: Dictionary = Dictionary(run_data.get("upgrade_counts", {}))
		for card_id in upgrade_counts.keys():
			var stat: Dictionary = Dictionary(card_stats_map.get(card_id, _new_card_stat(String(card_id))))
			var upgrade_count := int(upgrade_counts[card_id])
			stat["upgrade_count"] = int(stat.get("upgrade_count", 0)) + upgrade_count
			total_card_upgrades += upgrade_count
			if include_run:
				stat["upgrade_run_count"] = int(stat.get("upgrade_run_count", 0)) + 1
			card_stats_map[card_id] = stat

		var encounters: Dictionary = Dictionary(run_data.get("encounters", {}))
		for encounter_id in encounters.keys():
			var encounter: Dictionary = Dictionary(encounters[encounter_id])
			if String(encounter.get("outcome", "")) == "":
				continue
			total_encounters += 1
			total_condition_delta += float(encounter.get("condition_delta_player", 0.0))
			total_forced_error_points += int(encounter.get("forced_error_points", 0))
			total_points += int(encounter.get("points", 0))
			total_rally_exchanges += float(encounter.get("total_rally_exchanges", 0.0))
			total_turns += float(encounter.get("total_turns", 0.0))
			var enemy_key := "%02d|%s" % [int(encounter.get("act", 0)), String(encounter.get("enemy_id", "unknown"))]
			var enemy_stat: Dictionary = Dictionary(enemy_stats_map.get(enemy_key, _new_enemy_stat(encounter)))
			enemy_stat["encounters"] = int(enemy_stat.get("encounters", 0)) + 1
			if String(encounter.get("outcome", "")) == "won":
				enemy_stat["wins"] = int(enemy_stat.get("wins", 0)) + 1
			else:
				enemy_stat["losses"] = int(enemy_stat.get("losses", 0)) + 1
			enemy_stat["total_condition_delta_player"] = float(enemy_stat.get("total_condition_delta_player", 0.0)) + float(encounter.get("condition_delta_player", 0.0))
			enemy_stat["total_rally_exchanges"] = float(enemy_stat.get("total_rally_exchanges", 0.0)) + float(encounter.get("total_rally_exchanges", 0.0))
			enemy_stat["total_turns"] = float(enemy_stat.get("total_turns", 0.0)) + float(encounter.get("total_turns", 0.0))
			enemy_stat["forced_error_points"] = int(enemy_stat.get("forced_error_points", 0)) + int(encounter.get("forced_error_points", 0))
			enemy_stat["points"] = int(enemy_stat.get("points", 0)) + int(encounter.get("points", 0))
			enemy_stats_map[enemy_key] = enemy_stat

	var global_win_rate := float(wins) / float(maxi(1, included_runs))
	var card_metrics: Array = []
	for card_id in card_stats_map.keys():
		var stat: Dictionary = Dictionary(card_stats_map[card_id])
		var pick_run_count := int(stat.get("pick_run_count", 0))
		var pick_count := int(stat.get("pick_count", 0))
		var upgrade_count := int(stat.get("upgrade_count", 0))
		var win_rate_when_picked := float(stat.get("pick_run_wins", 0)) / float(maxi(1, pick_run_count))
		stat["pick_run_rate"] = float(pick_run_count) / float(maxi(1, included_runs))
		stat["pick_event_rate"] = float(pick_count) / float(maxi(1, total_card_picks))
		stat["upgrade_per_pick"] = float(upgrade_count) / float(maxi(1, pick_count))
		stat["win_rate_when_picked"] = win_rate_when_picked
		stat["win_rate_delta"] = win_rate_when_picked - global_win_rate
		card_metrics.append(stat)
	card_metrics.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pick_diff := int(a.get("pick_count", 0)) - int(b.get("pick_count", 0))
		if pick_diff == 0:
			return String(a.get("card_id", "")) < String(b.get("card_id", ""))
		return pick_diff > 0
	)

	var enemy_metrics: Array = []
	for enemy_key in enemy_stats_map.keys():
		var stat: Dictionary = Dictionary(enemy_stats_map[enemy_key])
		var encounters_count := int(stat.get("encounters", 0))
		var wins_count := int(stat.get("wins", 0))
		var points_count := int(stat.get("points", 0))
		var total_turn_count := float(stat.get("total_turns", 0.0))
		stat["win_rate"] = float(wins_count) / float(maxi(1, encounters_count))
		stat["avg_condition_delta_player"] = float(stat.get("total_condition_delta_player", 0.0)) / float(maxi(1, encounters_count))
		stat["avg_rally_exchanges_per_turn"] = float(stat.get("total_rally_exchanges", 0.0)) / maxf(1.0, total_turn_count)
		stat["forced_error_rate"] = float(stat.get("forced_error_points", 0)) / float(maxi(1, points_count))
		enemy_metrics.append(stat)
	enemy_metrics.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var win_rate_diff := float(a.get("win_rate", 0.0)) - float(b.get("win_rate", 0.0))
		if absf(win_rate_diff) < 0.0001:
			return String(a.get("enemy_id", "")) < String(b.get("enemy_id", ""))
		return win_rate_diff < 0.0
	)

	return {
		"generated_at_unix": int(Time.get_unix_time_from_system()),
		"log_file_count": log_paths.size(),
		"run_filter": run_filter,
		"overview": {
			"total_runs": total_runs,
			"included_runs": included_runs,
			"wins": wins,
			"global_win_rate": global_win_rate,
			"total_card_picks": total_card_picks,
			"total_card_upgrades": total_card_upgrades,
			"total_encounters": total_encounters,
			"avg_rally_exchanges_per_turn": total_rally_exchanges / maxf(1.0, total_turns),
			"avg_condition_delta_per_encounter": total_condition_delta / float(maxi(1, total_encounters)),
			"forced_error_frequency": float(total_forced_error_points) / float(maxi(1, total_points)),
		},
		"top_picked_cards": card_metrics.slice(0, mini(8, card_metrics.size())),
		"cards_correlated_with_wins": _sorted_by_metric(card_metrics, "win_rate_delta", 8, true),
		"cards_correlated_with_losses": _sorted_by_metric(card_metrics, "win_rate_delta", 8, false),
		"enemy_difficulty": enemy_metrics.slice(0, mini(8, enemy_metrics.size())),
		"card_metrics": card_metrics,
		"enemy_metrics": enemy_metrics,
	}

func _sorted_by_metric(entries: Array, key: String, limit: int, descending: bool) -> Array:
	var copied := entries.duplicate(true)
	copied.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_value := float(a.get(key, 0.0))
		var b_value := float(b.get(key, 0.0))
		if absf(a_value - b_value) < 0.0001:
			return String(a.get("card_id", "")) < String(b.get("card_id", ""))
		return a_value > b_value if descending else a_value < b_value
	)
	return copied.slice(0, mini(limit, copied.size()))

func _collect_log_paths(log_dir: String) -> PackedStringArray:
	var paths := PackedStringArray()
	var dir := DirAccess.open(log_dir)
	if dir == null:
		return paths
	dir.list_dir_begin()
	while true:
		var entry_name := dir.get_next()
		if entry_name == "":
			break
		if entry_name == "." or entry_name == "..":
			continue
		if dir.current_is_dir():
			continue
		if entry_name.ends_with(".jsonl"):
			paths.append("%s/%s" % [log_dir, entry_name])
	dir.list_dir_end()
	paths.sort()
	return paths

func _ensure_encounter(run_data: Dictionary, encounter_id: String) -> Dictionary:
	var encounters: Dictionary = Dictionary(run_data.get("encounters", {}))
	if not encounters.has(encounter_id):
		encounters[encounter_id] = {
			"encounter_id": encounter_id,
			"enemy_id": "",
			"enemy_name": "",
			"act": 0,
			"major_name": "",
			"surface": "",
			"match_label": "",
			"outcome": "",
			"result_reason": "",
			"points": 0,
			"total_rally_exchanges": 0.0,
			"total_turns": 0.0,
			"condition_delta_player": 0.0,
			"condition_delta_enemy": 0.0,
			"forced_error_points": 0,
			"player_forced_errors": 0,
			"enemy_forced_errors": 0,
			"player_condition_start": 0,
			"player_condition_end": 0,
			"enemy_condition_start": 0,
			"enemy_condition_end": 0,
			"final_point_number": 0,
		}
	run_data["encounters"] = encounters
	return Dictionary(encounters[encounter_id])

func _new_run_data(run_id: String) -> Dictionary:
	return {
		"run_id": run_id,
		"class_id": "",
		"seed": 0,
		"outcome": "",
		"event_count": 0,
		"pick_counts": {},
		"upgrade_counts": {},
		"picked_card_ids": {},
		"upgraded_card_ids": {},
		"encounters": {},
	}

func _new_card_stat(card_id: String) -> Dictionary:
	return {
		"card_id": card_id,
		"pick_count": 0,
		"pick_run_count": 0,
		"pick_run_wins": 0,
		"upgrade_count": 0,
		"upgrade_run_count": 0,
	}

func _new_enemy_stat(encounter: Dictionary) -> Dictionary:
	return {
		"act": int(encounter.get("act", 0)),
		"enemy_id": String(encounter.get("enemy_id", "")),
		"enemy_name": String(encounter.get("enemy_name", "")),
		"encounters": 0,
		"wins": 0,
		"losses": 0,
		"total_condition_delta_player": 0.0,
		"total_rally_exchanges": 0.0,
		"total_turns": 0.0,
		"forced_error_points": 0,
		"points": 0,
	}

func _card_csv_rows(card_metrics: Array) -> Array:
	var rows: Array = []
	for entry_variant in card_metrics:
		var entry := Dictionary(entry_variant)
		rows.append([
			String(entry.get("card_id", "")),
			str(int(entry.get("pick_count", 0))),
			str(int(entry.get("pick_run_count", 0))),
			_format_float(float(entry.get("pick_run_rate", 0.0))),
			_format_float(float(entry.get("pick_event_rate", 0.0))),
			str(int(entry.get("upgrade_count", 0))),
			str(int(entry.get("upgrade_run_count", 0))),
			_format_float(float(entry.get("upgrade_per_pick", 0.0))),
			_format_float(float(entry.get("win_rate_when_picked", 0.0))),
			_format_float(float(entry.get("win_rate_delta", 0.0))),
		])
	return rows

func _enemy_csv_rows(enemy_metrics: Array) -> Array:
	var rows: Array = []
	for entry_variant in enemy_metrics:
		var entry := Dictionary(entry_variant)
		rows.append([
			str(int(entry.get("act", 0))),
			String(entry.get("enemy_id", "")),
			str(int(entry.get("encounters", 0))),
			str(int(entry.get("wins", 0))),
			str(int(entry.get("losses", 0))),
			_format_float(float(entry.get("win_rate", 0.0))),
			_format_float(float(entry.get("avg_condition_delta_player", 0.0))),
			_format_float(float(entry.get("avg_rally_exchanges_per_turn", 0.0))),
			_format_float(float(entry.get("forced_error_rate", 0.0))),
		])
	return rows

func _write_json(path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

func _write_csv(path: String, header: Array, rows: Array) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_line(_csv_line(header))
	for row in rows:
		file.store_line(_csv_line(Array(row)))
	file.close()

func _csv_line(values: Array) -> String:
	var escaped := PackedStringArray()
	for value in values:
		var text := String(value).replace("\"", "\"\"")
		escaped.append("\"%s\"" % text)
	return ",".join(escaped)

func _ensure_dir(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute)

func _sanitize_prefix(prefix: String) -> String:
	var result := prefix.strip_edges()
	if result == "":
		return "latest"
	for character in ["/", "\\", ":", " ", "\t"]:
		result = result.replace(character, "_")
	return result

func _format_float(value: float) -> String:
	return "%.4f" % value

func _empty_summary() -> Dictionary:
	return {
		"generated_at_unix": int(Time.get_unix_time_from_system()),
		"log_file_count": 0,
		"run_filter": "",
		"overview": {
			"total_runs": 0,
			"included_runs": 0,
			"wins": 0,
			"global_win_rate": 0.0,
			"total_card_picks": 0,
			"total_card_upgrades": 0,
			"total_encounters": 0,
			"avg_rally_exchanges_per_turn": 0.0,
			"avg_condition_delta_per_encounter": 0.0,
			"forced_error_frequency": 0.0,
		},
		"top_picked_cards": [],
		"cards_correlated_with_wins": [],
		"cards_correlated_with_losses": [],
		"enemy_difficulty": [],
		"card_metrics": [],
		"enemy_metrics": [],
	}
