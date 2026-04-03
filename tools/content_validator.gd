@tool
class_name ContentValidator
extends RefCounted

const CARD_LIBRARY_PATH := "res://data/cards/card_library.tres"
const ENEMY_LIBRARY_PATH := "res://data/enemies/enemy_library.tres"
const EnemyIntentPlannerScript = preload("res://scripts/ai/enemy_intent_planner.gd")
const VALID_SLOT_ROLES := {
	"initial_contact": true,
	"shot": true,
	"enhancer": true,
	"modifier": true,
	"special": true,
}
const VALID_ENEMY_CATEGORIES := {
	"regular": true,
	"elite": true,
	"boss": true,
}

func validate_all() -> Dictionary:
	var cards_result := validate_card_library(CARD_LIBRARY_PATH)
	var enemies_result := validate_enemy_library(ENEMY_LIBRARY_PATH)
	var errors: PackedStringArray = PackedStringArray(cards_result.get("errors", PackedStringArray()))
	errors.append_array(PackedStringArray(enemies_result.get("errors", PackedStringArray())))
	var warnings: PackedStringArray = PackedStringArray(cards_result.get("warnings", PackedStringArray()))
	warnings.append_array(PackedStringArray(enemies_result.get("warnings", PackedStringArray())))
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"card_library_path": CARD_LIBRARY_PATH,
		"enemy_library_path": ENEMY_LIBRARY_PATH,
		"card_count": int(cards_result.get("count", 0)),
		"enemy_count": int(enemies_result.get("count", 0)),
	}

func validate_card_library(path: String) -> Dictionary:
	var errors := PackedStringArray()
	var warnings := PackedStringArray()
	var library = _load_resource(path, "card library", errors)
	if library == null:
		return {"ok": false, "errors": errors, "warnings": warnings, "count": 0}
	var cards_value = library.get("cards")
	if cards_value == null:
		errors.append("%s :: missing cards array" % path)
		return {"ok": false, "errors": errors, "warnings": warnings, "count": 0}
	return validate_card_resources(Array(cards_value), path, warnings, errors)

func validate_card_resources(cards: Array, path: String = CARD_LIBRARY_PATH, warnings: PackedStringArray = PackedStringArray(), errors: PackedStringArray = PackedStringArray()) -> Dictionary:
	var seen_ids := {}
	for index in cards.size():
		var resource = cards[index]
		var context := "%s :: card[%d]" % [path, index]
		if resource == null:
			errors.append("%s :: resource missing" % context)
			continue
		var card_id := String(resource.id)
		if not _require_non_empty_string(errors, context, "id", card_id):
			continue
		if seen_ids.has(card_id):
			errors.append("%s :: duplicate card id '%s'" % [context, card_id])
		else:
			seen_ids[card_id] = true
		_require_non_empty_string(errors, "%s :: %s" % [path, card_id], "name", String(resource.name))
		_require_type(errors, "%s :: %s" % [path, card_id], "description", resource.description, TYPE_STRING)
		_require_type(errors, "%s :: %s" % [path, card_id], "cost", resource.cost, TYPE_INT)
		_require_type(errors, "%s :: %s" % [path, card_id], "tags", resource.tags, TYPE_PACKED_STRING_ARRAY)
		_require_type(errors, "%s :: %s" % [path, card_id], "effects", resource.effects, TYPE_DICTIONARY)
		_require_type(errors, "%s :: %s" % [path, card_id], "upgrade_to", resource.upgrade_to, TYPE_STRING)
		_require_type(errors, "%s :: %s" % [path, card_id], "category", resource.category, TYPE_STRING)
		_require_type(errors, "%s :: %s" % [path, card_id], "shot_family", resource.shot_family, TYPE_STRING)
		_require_type(errors, "%s :: %s" % [path, card_id], "slot_roles", resource.slot_roles, TYPE_PACKED_STRING_ARRAY)
		_require_type(errors, "%s :: %s" % [path, card_id], "requires", resource.requires, TYPE_DICTIONARY)
		if int(resource.cost) < 0:
			errors.append("%s :: %s :: cost must be >= 0" % [path, card_id])
		if PackedStringArray(resource.slot_roles).is_empty():
			warnings.append("%s :: %s :: slot_roles is empty and will be inferred at runtime" % [path, card_id])
		for slot_role in PackedStringArray(resource.slot_roles):
			if not VALID_SLOT_ROLES.has(String(slot_role)):
				errors.append("%s :: %s :: invalid slot role '%s'" % [path, card_id, String(slot_role)])
		if String(resource.category) == "":
			warnings.append("%s :: %s :: category is empty and will be inferred at runtime" % [path, card_id])
		if String(resource.shot_family) == "":
			warnings.append("%s :: %s :: shot_family is empty and will be inferred at runtime" % [path, card_id])
		if PackedStringArray(resource.tags).has("boss_debuff") and String(resource.upgrade_to) != "":
			errors.append("%s :: %s :: boss debuffs cannot upgrade" % [path, card_id])
		for effect_key in Dictionary(resource.effects).keys():
			var value = resource.effects[effect_key]
			if _is_numeric_variant(value) and not _is_finite_number(float(value)):
				errors.append("%s :: %s :: effects.%s must be finite" % [path, card_id, String(effect_key)])

	for resource in cards:
		if resource == null:
			continue
		var card_id := String(resource.id)
		var upgrade_to := String(resource.upgrade_to)
		if upgrade_to != "" and not seen_ids.has(upgrade_to):
			errors.append("%s :: %s :: upgrade_to points to missing card '%s'" % [path, card_id, upgrade_to])

	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings, "count": cards.size(), "path": path}

func validate_enemy_library(path: String) -> Dictionary:
	var errors := PackedStringArray()
	var warnings := PackedStringArray()
	var library = _load_resource(path, "enemy library", errors)
	if library == null:
		return {"ok": false, "errors": errors, "warnings": warnings, "count": 0}
	var enemies_value = library.get("enemies")
	if enemies_value == null:
		errors.append("%s :: missing enemies array" % path)
		return {"ok": false, "errors": errors, "warnings": warnings, "count": 0}
	return validate_enemy_resources(Array(enemies_value), path, warnings, errors)

func validate_enemy_resources(enemies: Array, path: String = ENEMY_LIBRARY_PATH, warnings: PackedStringArray = PackedStringArray(), errors: PackedStringArray = PackedStringArray()) -> Dictionary:
	var seen_ids := {}
	var planner = EnemyIntentPlannerScript.new()
	for index in enemies.size():
		var resource = enemies[index]
		var context := "%s :: enemy[%d]" % [path, index]
		if resource == null:
			errors.append("%s :: resource missing" % context)
			continue
		var enemy_id := String(resource.id)
		if not _require_non_empty_string(errors, context, "id", enemy_id):
			continue
		if seen_ids.has(enemy_id):
			errors.append("%s :: duplicate enemy id '%s'" % [context, enemy_id])
		else:
			seen_ids[enemy_id] = true
		_require_non_empty_string(errors, "%s :: %s" % [path, enemy_id], "name", String(resource.name))
		_require_type(errors, "%s :: %s" % [path, enemy_id], "act", resource.act, TYPE_INT)
		_require_type(errors, "%s :: %s" % [path, enemy_id], "category", resource.category, TYPE_STRING)
		_require_type(errors, "%s :: %s" % [path, enemy_id], "max_health", resource.max_health, TYPE_INT)
		_require_type(errors, "%s :: %s" % [path, enemy_id], "intent_cycle", resource.intent_cycle, TYPE_ARRAY)
		_require_type(errors, "%s :: %s" % [path, enemy_id], "keywords", resource.keywords, TYPE_PACKED_STRING_ARRAY)
		_warn_if_missing_string(warnings, "%s :: %s" % [path, enemy_id], "style", String(resource.style))
		_warn_if_missing_string(warnings, "%s :: %s" % [path, enemy_id], "summary", String(resource.summary))
		if int(resource.act) < 1:
			errors.append("%s :: %s :: act must be >= 1" % [path, enemy_id])
		if int(resource.max_health) <= 0:
			errors.append("%s :: %s :: max_health must be > 0" % [path, enemy_id])
		if not VALID_ENEMY_CATEGORIES.has(String(resource.category)):
			errors.append("%s :: %s :: invalid category '%s'" % [path, enemy_id, String(resource.category)])
		if Array(resource.intent_cycle).is_empty():
			errors.append("%s :: %s :: intent_cycle cannot be empty" % [path, enemy_id])
		for intent_index in Array(resource.intent_cycle).size():
			var intent = Dictionary(Array(resource.intent_cycle)[intent_index])
			var intent_context := "%s :: %s :: intent[%d]" % [path, enemy_id, intent_index]
			var intent_errors := planner.validate_intent_schema(enemy_id, intent, intent_context)
			errors.append_array(intent_errors)
		if PackedStringArray(resource.keywords).is_empty():
			warnings.append("%s :: %s :: keywords is empty" % [path, enemy_id])

	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings, "count": enemies.size(), "path": path}

func format_report(result: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append("Content validation summary")
	lines.append("Cards: %d (%s)" % [int(result.get("card_count", 0)), String(result.get("card_library_path", CARD_LIBRARY_PATH))])
	lines.append("Enemies: %d (%s)" % [int(result.get("enemy_count", 0)), String(result.get("enemy_library_path", ENEMY_LIBRARY_PATH))])
	lines.append("Warnings: %d" % PackedStringArray(result.get("warnings", PackedStringArray())).size())
	lines.append("Errors: %d" % PackedStringArray(result.get("errors", PackedStringArray())).size())
	return "\n".join(lines)

func _load_resource(path: String, kind: String, errors: PackedStringArray):
	if not ResourceLoader.exists(path):
		errors.append("%s :: %s missing" % [path, kind])
		return null
	var resource = load(path)
	if resource == null:
		errors.append("%s :: %s failed to load" % [path, kind])
	return resource

func _require_type(errors: PackedStringArray, context: String, field_name: String, value, expected_type: int) -> bool:
	if typeof(value) != expected_type:
		errors.append("%s :: %s expected %s, got %s" % [context, field_name, type_string(expected_type), type_string(typeof(value))])
		return false
	return true

func _require_non_empty_string(errors: PackedStringArray, context: String, field_name: String, value: String) -> bool:
	if value.strip_edges() == "":
		errors.append("%s :: %s must be non-empty" % [context, field_name])
		return false
	return true

func _warn_if_missing_string(warnings: PackedStringArray, context: String, field_name: String, value: String) -> void:
	if value.strip_edges() == "":
		warnings.append("%s :: %s is empty" % [context, field_name])

func _is_numeric_variant(value) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

func _is_finite_number(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)
