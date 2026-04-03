class_name CardContentResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var cost: int = 1
@export_multiline var description: String = ""
@export var tags: PackedStringArray = PackedStringArray()
@export var effects: Dictionary = {}
@export var upgrade_to: String = ""
@export var category: String = ""
@export var shot_family: String = ""
@export var slot_roles: PackedStringArray = PackedStringArray()
@export var requires: Dictionary = {}
