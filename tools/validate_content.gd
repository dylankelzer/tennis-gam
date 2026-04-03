@tool
extends SceneTree

const ContentValidatorScript = preload("res://scripts/tools/content_validator.gd")

func _initialize() -> void:
	var validator = ContentValidatorScript.new()
	var result: Dictionary = validator.validate_all()
	print(validator.format_report(result))
	for warning in PackedStringArray(result.get("warnings", PackedStringArray())):
		print("WARNING: %s" % warning)
	if bool(result.get("ok", false)):
		print("Validation OK")
		quit(0)
		return
	for error_text in PackedStringArray(result.get("errors", PackedStringArray())):
		push_error(error_text)
	push_error("Validation FAILED")
	quit(1)
