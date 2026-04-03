class_name CharacterModelDef
extends RefCounted

var class_id: StringName
var model_name: String = ""
var real_world_inspirations: PackedStringArray = PackedStringArray()
var fantasy_lineage: String = ""
var silhouette: String = ""
var outfit: String = ""
var racquet_design: String = ""
var palette: PackedStringArray = PackedStringArray()
var monster_traits: PackedStringArray = PackedStringArray()
var animation_notes: PackedStringArray = PackedStringArray()
var model_prompt: String = ""

func _init(
	model_class_id: StringName,
	model_model_name: String,
	model_real_world_inspirations: PackedStringArray,
	model_fantasy_lineage: String,
	model_silhouette: String,
	model_outfit: String,
	model_racquet_design: String,
	model_palette: PackedStringArray,
	model_monster_traits: PackedStringArray,
	model_animation_notes: PackedStringArray,
	model_model_prompt: String
) -> void:
	class_id = model_class_id
	model_name = model_model_name
	real_world_inspirations = model_real_world_inspirations
	fantasy_lineage = model_fantasy_lineage
	silhouette = model_silhouette
	outfit = model_outfit
	racquet_design = model_racquet_design
	palette = model_palette
	monster_traits = model_monster_traits
	animation_notes = model_animation_notes
	model_prompt = model_model_prompt
