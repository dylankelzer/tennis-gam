class_name UnitData
extends Resource

@export_group("Identity")
@export var unit_id: String = ""
@export var display_name: String = "Unit"
@export var face_left: bool = false
@export_range(0.25, 4.0, 0.01) var root_scale: float = 1.0

@export_group("Body Layer")
@export var body_texture: Texture2D
@export var body_offset: Vector2 = Vector2.ZERO
@export var body_scale: Vector2 = Vector2.ONE
@export_range(-180.0, 180.0, 0.1) var body_rotation_degrees: float = 0.0
@export var body_modulate: Color = Color.WHITE
@export var body_visible: bool = true

@export_group("Racquet Layer")
@export var racquet_texture: Texture2D
@export var racquet_offset: Vector2 = Vector2(26.0, -18.0)
@export var racquet_scale: Vector2 = Vector2.ONE
@export_range(-180.0, 180.0, 0.1) var racquet_rotation_degrees: float = 0.0
@export var racquet_modulate: Color = Color.WHITE
@export var racquet_visible: bool = true

@export_group("Aura Layer")
@export var aura_texture: Texture2D
@export var aura_offset: Vector2 = Vector2(0.0, -14.0)
@export var aura_scale: Vector2 = Vector2(1.08, 1.08)
@export_range(-180.0, 180.0, 0.1) var aura_rotation_degrees: float = 0.0
@export var aura_modulate: Color = Color(1.0, 1.0, 1.0, 0.3)
@export var aura_visible: bool = true

@export_group("Shadow Layer")
@export var shadow_texture: Texture2D
@export var shadow_offset: Vector2 = Vector2(0.0, 26.0)
@export var shadow_scale: Vector2 = Vector2.ONE
@export_range(-180.0, 180.0, 0.1) var shadow_rotation_degrees: float = 0.0
@export var shadow_modulate: Color = Color(0.0, 0.0, 0.0, 0.3)
@export var shadow_visible: bool = true

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

func duplicate_data() -> UnitData:
	var data: UnitData = get_script().new()
	data.unit_id = unit_id
	data.display_name = display_name
	data.face_left = face_left
	data.root_scale = root_scale
	data.body_texture = body_texture
	data.body_offset = body_offset
	data.body_scale = body_scale
	data.body_rotation_degrees = body_rotation_degrees
	data.body_modulate = body_modulate
	data.body_visible = body_visible
	data.racquet_texture = racquet_texture
	data.racquet_offset = racquet_offset
	data.racquet_scale = racquet_scale
	data.racquet_rotation_degrees = racquet_rotation_degrees
	data.racquet_modulate = racquet_modulate
	data.racquet_visible = racquet_visible
	data.aura_texture = aura_texture
	data.aura_offset = aura_offset
	data.aura_scale = aura_scale
	data.aura_rotation_degrees = aura_rotation_degrees
	data.aura_modulate = aura_modulate
	data.aura_visible = aura_visible
	data.shadow_texture = shadow_texture
	data.shadow_offset = shadow_offset
	data.shadow_scale = shadow_scale
	data.shadow_rotation_degrees = shadow_rotation_degrees
	data.shadow_modulate = shadow_modulate
	data.shadow_visible = shadow_visible
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
	return data
