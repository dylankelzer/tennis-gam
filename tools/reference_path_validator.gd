@tool
class_name ReferencePathValidator
extends RefCounted

const SCRIPT_SUFFIXES := [".gd", ".tscn", ".tres"]
const SKIP_DIRECTORIES := {
	".git": true,
	".godot": true,
	"build": true,
}
const GDSCRIPT_PATTERNS := {
	"preload": "preload\\(\\s*([\"'])(res://[^\"'\\n]+)\\1\\s*\\)",
	"resource_loader": "ResourceLoader\\.load\\(\\s*([\"'])(res://[^\"'\\n]+)\\1",
	"load": "(?<![A-Za-z0-9_\\.])load\\(\\s*([\"'])(res://[^\"'\\n]+)\\1",
}
const EXT_RESOURCE_PATTERN := "(?m)^\\[ext_resource\\s+[^\\]]*path=\"(res://[^\"\\n]+)\"[^\\]]*\\]"
const PROJECT_PATH_PATTERN := "(?m)=\\\"\\*?(res://[^\"\\n]+)\\\""

var _dir_entry_cache: Dictionary = {}

func validate_project(project_root: String = "res://") -> Dictionary:
	_dir_entry_cache.clear()
	var project_root_abs := _normalize_project_root(project_root)
	var errors := PackedStringArray()
	var warnings := PackedStringArray()
	if project_root_abs == "":
		errors.append("%s :: project root could not be resolved" % project_root)
		return _build_result(false, errors, warnings, 0, 0, project_root_abs)
	if not DirAccess.dir_exists_absolute(project_root_abs):
		errors.append("%s :: project root directory missing" % project_root_abs)
		return _build_result(false, errors, warnings, 0, 0, project_root_abs)

	var file_paths := PackedStringArray()
	_collect_source_files(project_root_abs, file_paths)
	file_paths.sort()
	return validate_files(file_paths, project_root_abs)

func validate_files(file_paths: PackedStringArray, project_root_abs: String) -> Dictionary:
	_dir_entry_cache.clear()
	var errors := PackedStringArray()
	var warnings := PackedStringArray()
	var reference_count := 0
	var seen_keys := {}
	for file_path in file_paths:
		var references := _extract_references_from_file(file_path)
		for reference in references:
			var dedupe_key := "%s|%s|%s|%d" % [
				String(reference.get("source", "")),
				String(reference.get("kind", "")),
				String(reference.get("path", "")),
				int(reference.get("line", 0)),
			]
			if seen_keys.has(dedupe_key):
				continue
			seen_keys[dedupe_key] = true
			reference_count += 1
			var result := _validate_reference_path(String(reference.get("path", "")), project_root_abs)
			if bool(result.get("ok", false)):
				continue
			errors.append(_format_reference_error(reference, result))
	return _build_result(errors.is_empty(), errors, warnings, file_paths.size(), reference_count, project_root_abs)

func format_report(result: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append("Reference path validation summary")
	lines.append("Project root: %s" % String(result.get("project_root", "")))
	lines.append("Files scanned: %d" % int(result.get("file_count", 0)))
	lines.append("Static references checked: %d" % int(result.get("reference_count", 0)))
	lines.append("Warnings: %d" % PackedStringArray(result.get("warnings", PackedStringArray())).size())
	lines.append("Errors: %d" % PackedStringArray(result.get("errors", PackedStringArray())).size())
	return "\n".join(lines)

func _build_result(ok: bool, errors: PackedStringArray, warnings: PackedStringArray, file_count: int, reference_count: int, project_root_abs: String) -> Dictionary:
	return {
		"ok": ok,
		"errors": errors,
		"warnings": warnings,
		"file_count": file_count,
		"reference_count": reference_count,
		"project_root": project_root_abs,
	}

func _normalize_project_root(project_root: String) -> String:
	if project_root == "":
		return ""
	if project_root.begins_with("res://") or project_root.begins_with("user://"):
		return ProjectSettings.globalize_path(project_root).trim_suffix("/")
	return project_root.simplify_path().trim_suffix("/")

func _collect_source_files(directory_path: String, file_paths: PackedStringArray) -> void:
	var dir := DirAccess.open(directory_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry_name := dir.get_next()
		if entry_name == "":
			break
		if entry_name == "." or entry_name == "..":
			continue
		var entry_path := directory_path.path_join(entry_name)
		if dir.current_is_dir():
			if SKIP_DIRECTORIES.has(entry_name):
				continue
			_collect_source_files(entry_path, file_paths)
			continue
		if entry_name == "project.godot" or _has_source_suffix(entry_name):
			file_paths.append(entry_path)
	dir.list_dir_end()

func _has_source_suffix(file_name: String) -> bool:
	for suffix in SCRIPT_SUFFIXES:
		if file_name.ends_with(String(suffix)):
			return true
	return false

func _extract_references_from_file(file_path: String) -> Array:
	var content := FileAccess.get_file_as_string(file_path)
	var references: Array = []
	if file_path.ends_with(".gd"):
		for kind in GDSCRIPT_PATTERNS.keys():
			references.append_array(_collect_pattern_matches(content, file_path, String(kind), String(GDSCRIPT_PATTERNS[kind]), 2))
	elif file_path.ends_with(".tscn") or file_path.ends_with(".tres"):
		references.append_array(_collect_pattern_matches(content, file_path, "ext_resource", EXT_RESOURCE_PATTERN, 1))
	elif file_path.get_file() == "project.godot":
		references.append_array(_collect_pattern_matches(content, file_path, "project_setting", PROJECT_PATH_PATTERN, 1))
	return references

func _collect_pattern_matches(content: String, file_path: String, kind: String, pattern: String, capture_index: int) -> Array:
	var regex := RegEx.new()
	var compile_error := regex.compile(pattern)
	if compile_error != OK:
		return []
	var matches := regex.search_all(content)
	var results: Array = []
	for match in matches:
		var res_path := String(match.get_string(capture_index))
		if not res_path.begins_with("res://"):
			continue
		results.append({
			"source": file_path,
			"kind": kind,
			"path": res_path,
			"line": _line_number_for_offset(content, match.get_start(capture_index)),
		})
	return results

func _line_number_for_offset(content: String, offset: int) -> int:
	if offset <= 0:
		return 1
	return content.substr(0, offset).count("\n") + 1

func _validate_reference_path(res_path: String, project_root_abs: String) -> Dictionary:
	if not res_path.begins_with("res://"):
		return {"ok": false, "kind": "invalid", "message": "reference must begin with res://"}
	var relative_path := res_path.trim_prefix("res://")
	if relative_path == "":
		return {"ok": false, "kind": "invalid", "message": "reference is empty"}
	var segments := relative_path.split("/", false)
	var current_dir := project_root_abs
	var actual_segments: Array = []
	for segment_index in range(segments.size()):
		var segment := String(segments[segment_index])
		if not DirAccess.dir_exists_absolute(current_dir):
			return {
				"ok": false,
				"kind": "missing",
				"missing_path": "res://" + _join_segments(actual_segments),
				"message": "parent directory missing before '%s'" % segment,
			}
		var exact_match := ""
		var case_insensitive_match := ""
		for entry_name in _list_directory_entries(current_dir):
			var entry := String(entry_name)
			if entry == segment:
				exact_match = entry
				break
			if case_insensitive_match == "" and entry.to_lower() == segment.to_lower():
				case_insensitive_match = entry
		if exact_match != "":
			actual_segments.append(exact_match)
			current_dir = current_dir.path_join(exact_match)
			continue
		if case_insensitive_match != "":
			var actual_path_segments := actual_segments.duplicate()
			actual_path_segments.append(case_insensitive_match)
			for remaining_index in range(segment_index + 1, segments.size()):
				actual_path_segments.append(String(segments[remaining_index]))
			return {
				"ok": false,
				"kind": "case_mismatch",
				"actual_path": "res://" + _join_segments(actual_path_segments),
				"missing_path": res_path,
			}
		var missing_segments := actual_segments.duplicate()
		missing_segments.append(segment)
		return {
			"ok": false,
			"kind": "missing",
			"missing_path": "res://" + _join_segments(missing_segments),
		}
	if DirAccess.dir_exists_absolute(current_dir):
		return {
			"ok": false,
			"kind": "directory_reference",
			"actual_path": res_path,
		}
	if not FileAccess.file_exists(current_dir):
		return {
			"ok": false,
			"kind": "missing",
			"missing_path": res_path,
		}
	return {"ok": true}

func _list_directory_entries(directory_path: String) -> PackedStringArray:
	if _dir_entry_cache.has(directory_path):
		return PackedStringArray(_dir_entry_cache[directory_path])
	var entries := PackedStringArray()
	var dir := DirAccess.open(directory_path)
	if dir == null:
		return entries
	dir.list_dir_begin()
	while true:
		var entry_name := dir.get_next()
		if entry_name == "":
			break
		if entry_name == "." or entry_name == "..":
			continue
		entries.append(entry_name)
	dir.list_dir_end()
	_dir_entry_cache[directory_path] = entries
	return entries

func _join_segments(segments: Array) -> String:
	var joined := PackedStringArray()
	for segment in segments:
		joined.append(String(segment))
	return "/".join(joined)

func _format_reference_error(reference: Dictionary, result: Dictionary) -> String:
	var source_path := String(reference.get("source", ""))
	var line := int(reference.get("line", 0))
	var kind := String(reference.get("kind", "reference"))
	var res_path := String(reference.get("path", ""))
	var prefix := "%s:%d :: %s :: %s" % [source_path, line, kind, res_path]
	match String(result.get("kind", "")):
		"case_mismatch":
			return "%s :: case mismatch; actual path is %s" % [prefix, String(result.get("actual_path", ""))]
		"missing":
			return "%s :: missing file %s" % [prefix, String(result.get("missing_path", res_path))]
		"directory_reference":
			return "%s :: references a directory instead of a file" % prefix
		_:
			return "%s :: %s" % [prefix, String(result.get("message", "invalid reference"))]
