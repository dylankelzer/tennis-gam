class_name SaveManager
extends RefCounted

const SAVE_DIR := "user://saves"
const PROGRESS_PATH := "user://saves/court_of_chaos_save.json"
const RUN_PATH := "user://saves/court_of_chaos_run.json"

func load_progress() -> Dictionary:
	var parsed = _read_json(PROGRESS_PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _default_progress()

	var progress := _default_progress()
	progress["run_clears"] = int(parsed.get("run_clears", 0))
	progress["last_selected_class"] = String(parsed.get("last_selected_class", "novice"))
	progress["victory_tutorial_seen"] = bool(parsed.get("victory_tutorial_seen", false))
	return progress

func save_progress(progress: Dictionary) -> void:
	_write_json(PROGRESS_PATH, progress)

func has_active_run() -> bool:
	return FileAccess.file_exists(RUN_PATH)

func load_active_run() -> Dictionary:
	var parsed = _read_json(RUN_PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func save_active_run(snapshot: Dictionary) -> void:
	_write_json(RUN_PATH, snapshot)

func clear_active_run() -> void:
	if FileAccess.file_exists(RUN_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN_PATH))

func _ensure_save_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.make_dir_recursive("saves")

func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var raw_text := file.get_as_text()
	file.close()
	return JSON.parse_string(raw_text)

func _write_json(path: String, payload: Dictionary) -> void:
	_ensure_save_dir()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

func _default_progress() -> Dictionary:
	return {
		"run_clears": 0,
		"last_selected_class": "novice",
		"victory_tutorial_seen": false,
	}
