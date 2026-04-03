extends Node

signal settings_changed(snapshot: Dictionary)
signal bindings_changed(bindings: Dictionary)

const CONFIG_PATH := "user://settings.cfg"
const ACCESSIBILITY_SECTION := "accessibility"
const CONTROLS_SECTION := "controls"
const DEFAULT_SETTINGS := {
	"ui_scale": 1.0,
	"font_scale": 1.0,
	"high_contrast": false,
	"reduced_motion": false,
}
const ACTION_DEFAULTS := {
	"coc_primary_action": {"label": "Primary Action", "keycode": KEY_SPACE},
	"coc_end_turn": {"label": "End Turn", "keycode": KEY_E},
	"coc_prev_class": {"label": "Previous Class", "keycode": KEY_LEFT},
	"coc_next_class": {"label": "Next Class", "keycode": KEY_RIGHT},
	"coc_settings": {"label": "Accessibility", "keycode": KEY_F10},
}

var _settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var _bindings: Dictionary = {}

func _ready() -> void:
	_ensure_actions_exist()
	load_from_disk()

func load_from_disk() -> void:
	_settings = DEFAULT_SETTINGS.duplicate(true)
	_bindings.clear()
	var config := ConfigFile.new()
	var load_error := config.load(CONFIG_PATH)
	for key in DEFAULT_SETTINGS.keys():
		var default_value = DEFAULT_SETTINGS[key]
		if load_error == OK:
			_settings[key] = _coerce_setting_value(key, config.get_value(ACCESSIBILITY_SECTION, key, default_value))
		else:
			_settings[key] = default_value
	for action_name in ACTION_DEFAULTS.keys():
		var default_keycode := int(ACTION_DEFAULTS[action_name]["keycode"])
		var keycode := default_keycode
		if load_error == OK:
			keycode = int(config.get_value(CONTROLS_SECTION, action_name, default_keycode))
		_bindings[action_name] = keycode
		_apply_binding(action_name, keycode)
	settings_changed.emit(get_snapshot())
	bindings_changed.emit(get_bindings_snapshot())

func save_to_disk() -> void:
	var config := ConfigFile.new()
	for key in _settings.keys():
		config.set_value(ACCESSIBILITY_SECTION, key, _settings[key])
	for action_name in _bindings.keys():
		config.set_value(CONTROLS_SECTION, action_name, int(_bindings[action_name]))
	config.save(CONFIG_PATH)

func get_snapshot() -> Dictionary:
	return _settings.duplicate(true)

func get_bindings_snapshot() -> Dictionary:
	return _bindings.duplicate(true)

func get_ui_scale() -> float:
	return float(_settings.get("ui_scale", 1.0))

func get_font_scale() -> float:
	return float(_settings.get("font_scale", 1.0))

func is_high_contrast_enabled() -> bool:
	return bool(_settings.get("high_contrast", false))

func is_reduced_motion_enabled() -> bool:
	return bool(_settings.get("reduced_motion", false))

func set_setting(key: String, value, persist: bool = true) -> void:
	if not DEFAULT_SETTINGS.has(key):
		return
	var normalized = _coerce_setting_value(key, value)
	if _settings.get(key) == normalized:
		return
	_settings[key] = normalized
	if persist:
		save_to_disk()
	settings_changed.emit(get_snapshot())

func get_setting(key: String):
	return _settings.get(key, DEFAULT_SETTINGS.get(key))

func get_remappable_actions() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for action_name in ACTION_DEFAULTS.keys():
		rows.append({
			"action": action_name,
			"label": String(ACTION_DEFAULTS[action_name]["label"]),
			"binding_text": get_binding_text(action_name),
		})
	return rows

func get_binding_text(action_name: String) -> String:
	var keycode := int(_bindings.get(action_name, int(ACTION_DEFAULTS.get(action_name, {}).get("keycode", 0))))
	if keycode <= 0:
		return "Unbound"
	return OS.get_keycode_string(keycode)

func rebind_action_to_keycode(action_name: String, keycode: int, persist: bool = true) -> void:
	if not ACTION_DEFAULTS.has(action_name):
		return
	if keycode <= 0:
		return
	_bindings[action_name] = keycode
	_apply_binding(action_name, keycode)
	if persist:
		save_to_disk()
	bindings_changed.emit(get_bindings_snapshot())

func reset_bindings(persist: bool = true) -> void:
	for action_name in ACTION_DEFAULTS.keys():
		var keycode := int(ACTION_DEFAULTS[action_name]["keycode"])
		_bindings[action_name] = keycode
		_apply_binding(action_name, keycode)
	if persist:
		save_to_disk()
	bindings_changed.emit(get_bindings_snapshot())

func _ensure_actions_exist() -> void:
	for action_name in ACTION_DEFAULTS.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

func _apply_binding(action_name: String, keycode: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	InputMap.action_erase_events(action_name)
	if keycode <= 0:
		return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.keycode = keycode
	InputMap.action_add_event(action_name, event)

func _coerce_setting_value(key: String, value):
	match key:
		"ui_scale":
			return clampf(float(value), 0.85, 1.35)
		"font_scale":
			return clampf(float(value), 0.85, 1.50)
		"high_contrast", "reduced_motion":
			return bool(value)
		_:
			return value
