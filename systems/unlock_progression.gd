class_name UnlockProgression
extends RefCounted

const PlayerClassDatabaseScript = preload("res://scripts/data/player_class_database.gd")

var _class_database = PlayerClassDatabaseScript.new()

func get_unlock_order() -> Array[StringName]:
	var order: Array[StringName] = []
	for class_id in PlayerClassDatabaseScript.ORDER:
		order.append(class_id)
	return order

func get_unlocked_classes(run_clears: int) -> Array[StringName]:
	var unlocked: Array[StringName] = []
	for class_id in PlayerClassDatabaseScript.ORDER:
		unlocked.append(class_id)
	return unlocked

func get_next_unlock(run_clears: int) -> StringName:
	return &""

func describe_unlock_track() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("All classes are available from the start.")
	lines.append("Run power now grows inside each major:")
	lines.append("- Card rewards after match wins")
	lines.append("- Camp upgrades and recovery stops")
	lines.append("- Shop buys, removals, potions, and relics")
	lines.append("- Boss rewards between majors")
	return "\n".join(lines)
