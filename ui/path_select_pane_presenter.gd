extends RefCounted

func build(run_state, hovered_node_id: int = -1) -> Dictionary:
	if String(run_state.phase) != "map":
		return {"visible": false}

	var accessible_ids: PackedInt32Array = run_state.accessible_node_ids
	var route_count := accessible_ids.size()
	var next_round_label := _next_round_label(run_state, accessible_ids)
	var focus_node_id := _resolve_focus_node_id(run_state, hovered_node_id)
	return {
		"visible": true,
		"eyebrow": "%s Draw" % run_state.get_major_name(),
		"question": "Where do you go next in the draw?",
		"summary": _build_summary(run_state, route_count),
		"header_title": "%s Route Select" % run_state.get_major_name(),
		"header_body": "Study the bracket, compare the open branches, and choose the route that shapes your next matchup and checkpoint access.",
		"map_title": "%s • %d route%s live" % [next_round_label, route_count, "" if route_count == 1 else "s"],
		"info_title": "Bracket Outlook",
		"info_body": _build_open_path_text(run_state, accessible_ids),
		"hint": _build_hint(route_count, focus_node_id >= 0),
		"detail_title": _build_detail_title(run_state, focus_node_id),
		"detail_body": _build_detail_body(run_state, focus_node_id),
		"map_nodes": run_state.get_current_map_nodes(),
		"accessible_node_ids": accessible_ids,
		"completed_node_ids": run_state.completed_node_ids,
		"current_node_id": int(run_state.current_node_id),
		"focus_node_id": focus_node_id,
	}

func build_detail(run_state, hovered_node_id: int = -1) -> Dictionary:
	var focus_node_id := _resolve_focus_node_id(run_state, hovered_node_id)
	var route_count := int(run_state.accessible_node_ids.size())
	return {
		"detail_title": _build_detail_title(run_state, focus_node_id),
		"detail_body": _build_detail_body(run_state, focus_node_id),
		"hint": _build_hint(route_count, focus_node_id >= 0),
		"focus_node_id": focus_node_id,
	}

func _next_round_label(run_state, accessible_ids: PackedInt32Array) -> String:
	if accessible_ids.is_empty():
		return "Bracket Routes"
	var first_node = run_state.get_node(int(accessible_ids[0]))
	if first_node == null:
		return "Bracket Routes"
	return "%s • %s" % [run_state.get_round_name(int(first_node.floor)), "Bracket Routes"]

func _build_open_path_text(run_state, accessible_ids: PackedInt32Array) -> String:
	if accessible_ids.is_empty():
		return "No highlighted routes are available yet."
	var lines := PackedStringArray()
	for route_index in range(mini(4, accessible_ids.size())):
		var node_id := int(accessible_ids[route_index])
		lines.append("• %s" % _compact_route_line(run_state, node_id))
	if accessible_ids.size() > 4:
		lines.append("• ...and %d more route%s" % [accessible_ids.size() - 4, "" if accessible_ids.size() - 4 == 1 else "s"])
	return "\n".join(lines)

func _build_hint(route_count: int, has_focus: bool) -> String:
	if route_count <= 0:
		return "Wait for the bracket to open the next branch."
	if route_count == 1:
		return "One route is open. Hover to preview it, then click the highlighted node to continue." if has_focus else "One route is open. Click the highlighted node to continue."
	return "%d routes are open. Hover a node for live details, then click to lock in your next stop." % route_count

func _build_summary(run_state, route_count: int) -> String:
	var summary := String(run_state.status_message).strip_edges()
	var route_line := "%d route%s open in the bracket." % [route_count, "" if route_count == 1 else "s"]
	if summary == "":
		return route_line
	return "%s\n%s" % [summary, route_line]

func _resolve_focus_node_id(run_state, hovered_node_id: int) -> int:
	if hovered_node_id >= 0 and run_state.can_select_node(hovered_node_id):
		return hovered_node_id
	return int(run_state.get_primary_accessible_node_id())

func _build_detail_title(run_state, node_id: int) -> String:
	if node_id < 0:
		return "Route Detail"
	var node = run_state.get_node(node_id)
	if node == null:
		return "Route Detail"
	return "%s • %s" % [run_state.get_round_name(int(node.floor)), _node_type_label(String(node.node_type))]

func _build_detail_body(run_state, node_id: int) -> String:
	if node_id < 0:
		return "Hover an open node to preview the branch."
	var node = run_state.get_node(node_id)
	if node == null:
		return "Hover an open node to preview the branch."
	var lines := PackedStringArray()
	lines.append(run_state.get_node_summary(node_id))
	lines.append("")
	lines.append("Select this branch to commit the run to that stop immediately.")
	return "\n".join(lines)

func _compact_route_line(run_state, node_id: int) -> String:
	var node = run_state.get_node(node_id)
	if node == null:
		return "Open route"
	return "%s • %s" % [run_state.get_round_name(int(node.floor)), _node_type_label(String(node.node_type))]

func _node_type_label(node_type: String) -> String:
	match node_type:
		"regular":
			return "Match"
		"elite":
			return "Elite Match"
		"boss":
			return "Final"
		"rest":
			return "Recovery Camp"
		"shop":
			return "Pro Shop"
		"treasure":
			return "Prize Cache"
		"event":
			return "Event"
		_:
			return node_type.capitalize()
