class_name UnitDatabase
extends RefCounted

const UnitDataScript = preload("res://scripts/data/unit_data.gd")

const UNIT_PRESETS := {
	"novice": {
		"display_name": "Novice",
		"asset_path": "res://assets/units/player/novice",
		"face_left": false,
		"root_scale": 1.0,
		"body_offset": Vector2(0.0, -2.0),
		"aura_modulate": Color(0.48, 0.82, 1.0, 0.34),
		"shadow_scale": Vector2(1.08, 1.0),
		"idle_bob_distance": 5.0,
		"idle_bob_speed": 2.1,
		"attack_lunge_distance": 28.0,
		"attack_lunge_height": -7.0,
		"attack_swing_degrees": 76.0,
		"attack_duration": 0.34,
		"hit_flash_color": Color(1.0, 0.97, 0.88, 1.0),
	},
	"grinder": {
		"display_name": "Grinder",
		"asset_path": "res://assets/units/enemy/grinder",
		"face_left": true,
		"root_scale": 1.04,
		"body_offset": Vector2(0.0, 0.0),
		"aura_modulate": Color(0.62, 0.85, 0.34, 0.30),
		"shadow_scale": Vector2(1.12, 1.04),
		"idle_bob_distance": 4.0,
		"idle_bob_speed": 1.75,
		"attack_lunge_distance": 24.0,
		"attack_lunge_height": -4.0,
		"attack_swing_degrees": 68.0,
		"attack_duration": 0.38,
		"hit_flash_color": Color(1.0, 0.95, 0.72, 1.0),
	},
}

func list_unit_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in UNIT_PRESETS.keys():
		ids.append(String(key))
	ids.sort()
	return ids

func get_unit(unit_id: String):
	var normalized_id := unit_id.strip_edges().to_lower()
	var preset: Dictionary = UNIT_PRESETS.get(normalized_id, UNIT_PRESETS["novice"])
	return _build_unit(normalized_id if UNIT_PRESETS.has(normalized_id) else "novice", preset)

func get_default_player():
	return get_unit("novice")

func get_default_enemy():
	return get_unit("grinder")

func _build_unit(unit_id: String, preset: Dictionary):
	var data = UnitDataScript.new()
	var folder_path := String(preset.get("asset_path", "res://assets/units/player/novice"))
	data.unit_id = unit_id
	data.display_name = String(preset.get("display_name", unit_id.capitalize()))
	data.face_left = bool(preset.get("face_left", false))
	data.root_scale = float(preset.get("root_scale", 1.0))
	data.body_texture = _load_texture("%s/body.png" % folder_path)
	data.racquet_texture = _load_texture("%s/racquet.png" % folder_path)
	data.aura_texture = _load_texture("%s/aura.png" % folder_path)
	data.shadow_texture = _load_texture("%s/shadow.png" % folder_path)
	data.body_offset = preset.get("body_offset", Vector2.ZERO)
	data.aura_offset = preset.get("aura_offset", Vector2(0.0, -14.0))
	data.aura_scale = preset.get("aura_scale", Vector2(1.08, 1.08))
	data.aura_modulate = preset.get("aura_modulate", Color(1.0, 1.0, 1.0, 0.3))
	data.shadow_scale = preset.get("shadow_scale", Vector2.ONE)
	data.shadow_modulate = preset.get("shadow_modulate", Color(0.0, 0.0, 0.0, 0.3))
	data.idle_bob_distance = float(preset.get("idle_bob_distance", 6.0))
	data.idle_bob_speed = float(preset.get("idle_bob_speed", 2.0))
	data.attack_lunge_distance = float(preset.get("attack_lunge_distance", 26.0))
	data.attack_lunge_height = float(preset.get("attack_lunge_height", -6.0))
	data.attack_swing_degrees = float(preset.get("attack_swing_degrees", 72.0))
	data.attack_duration = float(preset.get("attack_duration", 0.34))
	data.hit_flash_color = preset.get("hit_flash_color", Color.WHITE)
	return data

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute_path):
		var image := Image.load_from_file(absolute_path)
		if image != null and not image.is_empty():
			return ImageTexture.create_from_image(image)
	return null
