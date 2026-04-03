@tool
extends SceneTree

const TelemetryBalanceAnalyzerScript = preload("res://scripts/tools/telemetry_balance_analyzer.gd")

func _initialize() -> void:
	var analyzer = TelemetryBalanceAnalyzerScript.new()
	var args := PackedStringArray(OS.get_cmdline_user_args())
	var run_id := ""
	for arg in args:
		if String(arg).begins_with("--run-id="):
			run_id = String(arg).trim_prefix("--run-id=")
	var summary: Dictionary = analyzer.analyze_run(run_id) if run_id != "" else analyzer.analyze_all_logs()
	var prefix := run_id if run_id != "" else "latest"
	var report_paths: Dictionary = analyzer.write_report_bundle(summary, prefix)
	print(analyzer.format_summary(summary))
	print("Summary JSON: %s" % String(report_paths.get("summary_json", "")))
	print("Cards CSV: %s" % String(report_paths.get("cards_csv", "")))
	print("Enemies CSV: %s" % String(report_paths.get("enemies_csv", "")))
	quit(0)
