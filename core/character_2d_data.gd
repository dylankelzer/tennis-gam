class_name Character2DData
extends Resource

const Character2DLayerData = preload("res://scripts/core/character_2d_layer_data.gd")

@export_group("Identity")
@export var display_name: String = "Character"
@export var root_scale: float = 1.0
@export var face_left: bool = false

@export_group("Layers")
@export var body_layer: Character2DLayerData
@export var racquet_layer: Character2DLayerData
@export var aura_layer: Character2DLayerData
@export var shadow_layer: Character2DLayerData

@export_group("Idle")
@export var idle_enabled: bool = true
@export_range(0.0, 24.0, 0.1) var idle_bob_distance: float = 6.0
@export_range(0.1, 8.0, 0.05) var idle_bob_speed: float = 2.0

@export_group("Attack")
@export_range(4.0, 96.0, 1.0) var attack_lunge_distance: float = 26.0
@export_range(-48.0, 0.0, 1.0) var attack_lunge_height: float = -6.0
@export_range(15.0, 180.0, 1.0) var attack_swing_degrees: float = 72.0
@export_range(0.12, 1.2, 0.01) var attack_duration: float = 0.34

@export_group("Hit Flash")
@export_range(0.05, 0.5, 0.01) var hit_flash_duration: float = 0.12
@export var hit_flash_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export_range(0.0, 1.0, 0.01) var hit_flash_strength: float = 0.85

func _init() -> void:
	body_layer = _make_default_body_layer()
	racquet_layer = _make_default_racquet_layer()
	aura_layer = _make_default_aura_layer()
	shadow_layer = _make_default_shadow_layer()

func duplicate_data() -> Character2DData:
	var data: Character2DData = get_script().new()
	data.display_name = display_name
	data.root_scale = root_scale
	data.face_left = face_left
	data.idle_enabled = idle_enabled
	data.idle_bob_distance = idle_bob_distance
	data.idle_bob_speed = idle_bob_speed
	data.attack_lunge_distance = attack_lunge_distance
	data.attack_lunge_height = attack_lunge_height
	data.attack_swing_degrees = attack_swing_degrees
	data.attack_duration = attack_duration
	data.hit_flash_duration = hit_flash_duration
	data.hit_flash_color = hit_flash_color
	data.hit_flash_strength = hit_flash_strength
	data.body_layer = body_layer.duplicate_layer() if body_layer != null else null
	data.racquet_layer = racquet_layer.duplicate_layer() if racquet_layer != null else null
	data.aura_layer = aura_layer.duplicate_layer() if aura_layer != null else null
	data.shadow_layer = shadow_layer.duplicate_layer() if shadow_layer != null else null
	return data

func _make_default_body_layer() -> Character2DLayerData:
	var layer: Character2DLayerData = Character2DLayerData.new()
	layer.modulate = Color(0.72, 0.88, 1.0, 1.0)
	layer.z_index = 0
	return layer

func _make_default_racquet_layer() -> Character2DLayerData:
	var layer: Character2DLayerData = Character2DLayerData.new()
	layer.offset = Vector2(26.0, -18.0)
	layer.modulate = Color(0.95, 0.97, 1.0, 1.0)
	layer.z_index = 10
	return layer

func _make_default_aura_layer() -> Character2DLayerData:
	var layer: Character2DLayerData = Character2DLayerData.new()
	layer.offset = Vector2(0.0, -14.0)
	layer.sprite_scale = Vector2(1.08, 1.08)
	layer.modulate = Color(0.48, 0.82, 1.0, 0.34)
	layer.z_index = -10
	return layer

func _make_default_shadow_layer() -> Character2DLayerData:
	var layer: Character2DLayerData = Character2DLayerData.new()
	layer.offset = Vector2(0.0, 26.0)
	layer.sprite_scale = Vector2(1.0, 1.0)
	layer.modulate = Color(0.0, 0.0, 0.0, 0.28)
	layer.z_index = -20
	return layer
