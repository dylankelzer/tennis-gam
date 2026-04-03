class_name FXController
extends RefCounted

const FXSpriteScene = preload("res://scenes/components/fx/fx_sprite_effect.tscn")

var _host: Node2D
var _texture_cache: Dictionary = {}

func _init(host: Node2D) -> void:
	_host = host

func clear() -> void:
	if _host == null:
		return
	for child in _host.get_children():
		child.queue_free()

func spawn(path: String, config: Dictionary) -> void:
	if _host == null:
		return
	var texture := _load_texture(path)
	if texture == null:
		return
	var fx = FXSpriteScene.instantiate()
	_host.add_child(fx)
	fx.play(texture, config)

func _load_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	if texture == null:
		var absolute_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(absolute_path):
			var image := Image.load_from_file(absolute_path)
			if image != null and not image.is_empty():
				texture = ImageTexture.create_from_image(image)
	_texture_cache[path] = texture
	return texture
