extends Node
class_name Telemetry

signal event_logged(kind: String, event: Dictionary)

const TELEMETRY_DIR := "user://telemetry"
const TELEMETRY_SETTINGS_PATH := "user://telemetry/settings.json"
const MAX_RECENT_EVENTS := 64
const MAX_RECENT_FIGHTS := 24
const MAX_RECENT_REWARDS := 48
const TelemetryBalanceAnalyzerScript = preload("res://scripts/tools/telemetry_balance_analyzer.gd")

var enabled: bool = false
var current_run_id: String = ""
var _file: FileAccess = null
var _current_act: float = 0.0
var _current_encounter: String = ""
var _current_encounter_code: float = 0.0
var _current_phase: String = "idle"
var _average_rally_exchanges: float = 0.0
var _monitors_registered: bool = false
var _rolling_stats: Dictionary = {}
var _latest_balance_summary: Dictionary = {}
var _latest_balance_report_paths: Dictionary = {}

func _ready() -> void:
	# Autoload nodes live under /root for the lifetime of the app and should not be freed.
	_reset_rolling_stats()
	_load_settings()
	if OS.has_environment("COURT_OF_CHAOS_TELEMETRY"):
		set_enabled(OS.get_environment("COURT_OF_CHAOS_TELEMETRY") == "1", false)
	_rolling_stats["enabled"] = enabled
	_register_custom_monitors()

func _exit_tree() -> void:
	_remove_custom_monitors()
	_close_file()

func is_enabled() -> bool:
	return enabled

func set_enabled(value: bool, persist: bool = true) -> void:
	var changed := enabled != value
	enabled = value
	if persist:
		_save_settings()
	if not enabled:
		_close_file()
		return
	if changed and current_run_id != "":
		start_run(current_run_id, {"telemetry_reenabled": true}, true)

func start_run(run_id: String, metadata: Dictionary = {}, append: bool = false) -> void:
	current_run_id = run_id
	if not enabled:
		_rolling_stats["current_run_id"] = current_run_id
		return
	_ensure_telemetry_dir()
	_close_file()
	var write_mode := FileAccess.WRITE_READ if append else FileAccess.WRITE
	var path := _get_run_log_path(run_id)
	_file = FileAccess.open(path, write_mode)
	if _file == null:
		push_warning("Telemetry could not open %s" % path)
		return
	if append:
		_file.seek_end()
	_rolling_stats["current_log_path"] = ProjectSettings.globalize_path(path)
	log_event("run_started" if not append else "run_attached", metadata)

func finish_run(outcome: String, payload: Dictionary = {}) -> void:
	var result_payload := payload.duplicate(true)
	result_payload["outcome"] = outcome
	log_event("run_finished", result_payload)
	_close_file()
	refresh_balance_reports(current_run_id)

func update_run_context(act: int, phase: String, encounter_id: String = "") -> void:
	_current_act = float(act)
	_current_phase = phase
	_current_encounter = encounter_id
	_current_encounter_code = _encounter_code(encounter_id)
	_rolling_stats["current_act"] = act
	_rolling_stats["current_phase"] = phase
	_rolling_stats["current_encounter_id"] = encounter_id

func update_average_rally_exchanges(value: float) -> void:
	_average_rally_exchanges = value
	_rolling_stats["average_rally_exchanges"] = value

func poll_perf_snapshot() -> Dictionary:
	return {
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"frame_time_ms": 1000.0 / maxf(1.0, float(Performance.get_monitor(Performance.TIME_FPS))),
		"process_time": Performance.get_monitor(Performance.TIME_PROCESS),
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"memory_static": Performance.get_monitor(Performance.MEMORY_STATIC),
		"memory_static_max": Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
		"video_mem_used": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
	}

func poll_perf() -> Dictionary:
	var snapshot := poll_perf_snapshot()
	return {
		"fps": snapshot.get("fps", 0.0),
		"objs": snapshot.get("objects", 0.0),
		"vram": snapshot.get("video_mem_used", 0.0),
	}

func log_event(kind_or_event, payload: Dictionary = {}) -> void:
	var kind := "event"
	var event: Dictionary = {
		"timestamp_unix": int(Time.get_unix_time_from_system()),
		"run_id": current_run_id,
		"act": int(_current_act),
		"phase": _current_phase,
		"encounter_id": _current_encounter,
	}
	if typeof(kind_or_event) == TYPE_DICTIONARY:
		var input_event: Dictionary = Dictionary(kind_or_event)
		kind = String(input_event.get("kind", "event"))
		for key in input_event.keys():
			event[key] = input_event[key]
	else:
		kind = String(kind_or_event)
		for key in payload.keys():
			event[key] = payload[key]
	event["kind"] = kind
	_record_event(kind, event)
	if enabled and _file != null:
		_file.store_line(JSON.stringify(event))
		_file.flush()
	event_logged.emit(kind, event)

func get_current_log_path() -> String:
	return String(_rolling_stats.get("current_log_path", ""))

func get_stats_snapshot() -> Dictionary:
	return _duplicate_variant(_rolling_stats)

func refresh_balance_reports(run_id: String = "") -> Dictionary:
	var analyzer = TelemetryBalanceAnalyzerScript.new()
	var aggregate_summary: Dictionary = analyzer.analyze_all_logs()
	_latest_balance_summary = aggregate_summary
	_latest_balance_report_paths = analyzer.write_report_bundle(aggregate_summary, "latest")
	var run_report_paths := {}
	if run_id.strip_edges() != "":
		var run_summary: Dictionary = analyzer.analyze_run(run_id)
		run_report_paths = analyzer.write_report_bundle(run_summary, run_id)
	_rolling_stats["balance_summary"] = _duplicate_variant(_latest_balance_summary)
	_rolling_stats["balance_report_paths"] = _duplicate_variant(_latest_balance_report_paths)
	_rolling_stats["current_run_report_paths"] = _duplicate_variant(run_report_paths)
	return _duplicate_variant(_latest_balance_summary)

func get_latest_balance_summary() -> Dictionary:
	if _latest_balance_summary.is_empty():
		refresh_balance_reports()
	return _duplicate_variant(_latest_balance_summary)

func get_latest_balance_report_paths() -> Dictionary:
	if _latest_balance_report_paths.is_empty():
		refresh_balance_reports()
	return _duplicate_variant(_latest_balance_report_paths)

func _ensure_telemetry_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.make_dir_recursive("telemetry")

func _get_run_log_path(run_id: String) -> String:
	return "%s/%s.jsonl" % [TELEMETRY_DIR, run_id]

func _close_file() -> void:
	if _file != null:
		_file.close()
	_file = null

func _register_custom_monitors() -> void:
	if _monitors_registered:
		return
	Performance.add_custom_monitor(&"court_of_chaos/current_act", Callable(self, "_monitor_current_act"))
	Performance.add_custom_monitor(&"court_of_chaos/current_encounter_code", Callable(self, "_monitor_current_encounter_code"))
	Performance.add_custom_monitor(&"court_of_chaos/current_phase_code", Callable(self, "_monitor_current_phase_code"))
	Performance.add_custom_monitor(&"court_of_chaos/avg_rally_exchanges", Callable(self, "_monitor_average_rally_exchanges"))
	_monitors_registered = true

func _remove_custom_monitors() -> void:
	if not _monitors_registered:
		return
	Performance.remove_custom_monitor(&"court_of_chaos/current_act")
	Performance.remove_custom_monitor(&"court_of_chaos/current_encounter_code")
	Performance.remove_custom_monitor(&"court_of_chaos/current_phase_code")
	Performance.remove_custom_monitor(&"court_of_chaos/avg_rally_exchanges")
	_monitors_registered = false

func _monitor_current_act() -> float:
	return _current_act

func _monitor_current_encounter_code() -> float:
	return _current_encounter_code

func _monitor_current_phase_code() -> float:
	match _current_phase:
		"idle":
			return 0.0
		"map":
			return 1.0
		"combat":
			return 2.0
		"reward":
			return 3.0
		"run_won":
			return 4.0
		"run_lost":
			return 5.0
	return -1.0

func _monitor_average_rally_exchanges() -> float:
	return _average_rally_exchanges

func _load_settings() -> void:
	if not FileAccess.file_exists(TELEMETRY_SETTINGS_PATH):
		return
	var file := FileAccess.open(TELEMETRY_SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	enabled = bool(Dictionary(parsed).get("enabled", false))

func _save_settings() -> void:
	_ensure_telemetry_dir()
	var file := FileAccess.open(TELEMETRY_SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Telemetry could not write %s" % TELEMETRY_SETTINGS_PATH)
		return
	file.store_string(JSON.stringify({
		"enabled": enabled,
		"local_only": true,
	}))
	file.close()

func _reset_rolling_stats() -> void:
	_rolling_stats = {
		"enabled": false,
		"local_only": true,
		"current_run_id": "",
		"current_log_path": "",
		"current_act": 0,
		"current_phase": "idle",
		"current_encounter_id": "",
		"average_rally_exchanges": 0.0,
		"total_events": 0,
		"events_by_kind": {},
		"recent_events": [],
		"recent_reward_events": [],
		"recent_fights": [],
		"encounter_outcomes": {"won": 0, "lost": 0},
		"performance": {},
		"balance_summary": {},
		"balance_report_paths": {},
		"current_run_report_paths": {},
	}

func _record_event(kind: String, event: Dictionary) -> void:
	_rolling_stats["enabled"] = enabled
	_rolling_stats["current_run_id"] = current_run_id
	_rolling_stats["current_encounter_id"] = _current_encounter
	_rolling_stats["current_phase"] = _current_phase
	_rolling_stats["current_act"] = int(_current_act)
	_rolling_stats["total_events"] = int(_rolling_stats.get("total_events", 0)) + 1
	var events_by_kind: Dictionary = Dictionary(_rolling_stats.get("events_by_kind", {}))
	events_by_kind[kind] = int(events_by_kind.get(kind, 0)) + 1
	_rolling_stats["events_by_kind"] = events_by_kind
	_append_limited("recent_events", event, MAX_RECENT_EVENTS)
	if kind in ["card_picked", "card_upgraded", "card_removed", "relic_acquired", "potion_acquired", "shop_card_bought", "racquet_tuned"]:
		_append_limited("recent_reward_events", event, MAX_RECENT_REWARDS)
	if kind == "encounter_finished":
		_append_limited("recent_fights", event, MAX_RECENT_FIGHTS)
		var outcomes: Dictionary = Dictionary(_rolling_stats.get("encounter_outcomes", {"won": 0, "lost": 0}))
		var outcome := String(event.get("outcome", ""))
		if outcome != "":
			outcomes[outcome] = int(outcomes.get(outcome, 0)) + 1
		_rolling_stats["encounter_outcomes"] = outcomes
	_rolling_stats["performance"] = poll_perf_snapshot()

func _append_limited(key: String, value, limit: int) -> void:
	var entries: Array = Array(_rolling_stats.get(key, []))
	entries.append(_duplicate_variant(value))
	while entries.size() > limit:
		entries.remove_at(0)
	_rolling_stats[key] = entries

func _encounter_code(encounter_id: String) -> float:
	if encounter_id == "":
		return 0.0
	return float(abs(encounter_id.hash()))

func _duplicate_variant(value):
	if typeof(value) == TYPE_DICTIONARY:
		return Dictionary(value).duplicate(true)
	if typeof(value) == TYPE_ARRAY:
		return Array(value).duplicate(true)
	if typeof(value) == TYPE_PACKED_STRING_ARRAY:
		return PackedStringArray(value)
	return value
