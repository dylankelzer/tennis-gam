@tool
extends SceneTree

const ReferencePathValidatorScript = preload("res://scripts/tools/reference_path_validator.gd")

func _initialize() -> void:
	var validator = ReferencePathValidatorScript.new()
	var result: Dictionary = validator.validate_project()
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
