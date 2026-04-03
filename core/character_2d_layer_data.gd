class_name Character2DLayerData
extends Resource

@export var texture: Texture2D
@export var offset: Vector2 = Vector2.ZERO
@export var sprite_scale: Vector2 = Vector2.ONE
@export var rotation_degrees: float = 0.0
@export var modulate: Color = Color.WHITE
@export var visible: bool = true
@export var z_index: int = 0

func duplicate_layer() -> Character2DLayerData:
	var layer: Character2DLayerData = get_script().new()
	layer.texture = texture
	layer.offset = offset
	layer.sprite_scale = sprite_scale
	layer.rotation_degrees = rotation_degrees
	layer.modulate = modulate
	layer.visible = visible
	layer.z_index = z_index
	return layer
