class_name EnemyContentResource
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var act: int = 1
@export var category: String = "regular"
@export var style: String = ""
@export_multiline var summary: String = ""
@export var max_health: int = 0
@export var intent_cycle: Array[Dictionary] = []
@export var keywords: PackedStringArray = PackedStringArray()
