class_name PathGenerator
extends RefCounted

const PathNodeDef = preload("res://scripts/core/path_node_def.gd")

const FLOOR_NODE_COUNTS := [3, 4, 4, 4, 3, 2]
const ROUND_LABELS := [
	"Qualifying",
	"Opening Round",
	"Round of 32",
	"Round of 16",
	"Quarterfinal",
	"Semifinal",
]

func generate_act(act: int, seed: int, enemy_database) -> Array[PathNodeDef]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var all_nodes: Array[PathNodeDef] = []
	var floors: Array = []
	var next_id := 1

	for floor_index in range(FLOOR_NODE_COUNTS.size()):
		var node_count: int = FLOOR_NODE_COUNTS[floor_index]
		var floor_nodes: Array[PathNodeDef] = []
		for lane in range(node_count):
			var node_type: String = _pick_node_type(floor_index, rng)
			var encounter_id: StringName = _pick_encounter_id(act, node_type, rng, enemy_database)
			var node := PathNodeDef.new(next_id, floor_index, lane, node_type, encounter_id)
			floor_nodes.append(node)
			all_nodes.append(node)
			next_id += 1
		floors.append(floor_nodes)

	_apply_checkpoint_overrides(floors, rng)
	_connect_floors(floors, rng)

	var boss_pool = enemy_database.get_pool(act, "boss")
	var boss_id: StringName = &""
	if not boss_pool.is_empty():
		boss_id = boss_pool[0].id
	var boss_node := PathNodeDef.new(next_id, FLOOR_NODE_COUNTS.size(), 0, "boss", boss_id)
	all_nodes.append(boss_node)
	for node in floors.back():
		node.next_node_ids.append(boss_node.id)

	return all_nodes

func _apply_checkpoint_overrides(floors: Array, rng: RandomNumberGenerator) -> void:
	# Floor 2 and 4: force one rest + one shop (mid-act checkpoints)
	# Floor 5: force one rest before the boss — player always has a breather before the final
	var forced_floors := {
		2: PackedStringArray(["rest", "shop"]),
		4: PackedStringArray(["rest", "shop"]),
		5: PackedStringArray(["rest"]),
	}
	for floor_index in forced_floors.keys():
		if int(floor_index) < 0 or int(floor_index) >= floors.size():
			continue
		var floor_nodes: Array = floors[int(floor_index)]
		if floor_nodes.is_empty():
			continue
		var lane_indices: Array[int] = []
		for lane in range(floor_nodes.size()):
			lane_indices.append(lane)
		for index in range(lane_indices.size() - 1, 0, -1):
			var swap_index := rng.randi_range(0, index)
			var tmp := lane_indices[index]
			lane_indices[index] = lane_indices[swap_index]
			lane_indices[swap_index] = tmp
		var forced_types: PackedStringArray = PackedStringArray(forced_floors[int(floor_index)])
		for forced_index in range(mini(forced_types.size(), lane_indices.size())):
			var node: PathNodeDef = floor_nodes[lane_indices[forced_index]]
			node.node_type = String(forced_types[forced_index])
			node.encounter_id = &""

func describe_act(nodes: Array[PathNodeDef], enemy_database) -> String:
	var floors: Dictionary = {}
	for node in nodes:
		if not floors.has(node.floor):
			floors[node.floor] = []
		floors[node.floor].append(node)

	var ordered_floors := floors.keys()
	ordered_floors.sort()

	var lines: PackedStringArray = PackedStringArray()
	for floor_number in ordered_floors:
		var line_parts: PackedStringArray = PackedStringArray()
		var floor_nodes: Array = floors[floor_number]
		floor_nodes.sort_custom(func(a: PathNodeDef, b: PathNodeDef) -> bool:
			return a.lane < b.lane
		)
		for node in floor_nodes:
			line_parts.append(_format_node(node, enemy_database))
		var label: String = "Major Final" if int(floor_number) == FLOOR_NODE_COUNTS.size() else ROUND_LABELS[min(int(floor_number), ROUND_LABELS.size() - 1)]
		lines.append(label + ": " + " | ".join(line_parts))
	return "\n".join(lines)

func _pick_node_type(floor_index: int, rng: RandomNumberGenerator) -> String:
	match floor_index:
		0:
			return "regular"
		1:
			return _weighted_pick(rng, [{"type": "regular", "weight": 75}, {"type": "event", "weight": 25}])
		2:
			return _weighted_pick(rng, [{"type": "regular", "weight": 55}, {"type": "rest", "weight": 20}, {"type": "shop", "weight": 15}, {"type": "event", "weight": 10}])
		3:
			return _weighted_pick(rng, [{"type": "regular", "weight": 40}, {"type": "elite", "weight": 25}, {"type": "event", "weight": 15}, {"type": "treasure", "weight": 20}])
		4:
			return _weighted_pick(rng, [{"type": "regular", "weight": 40}, {"type": "rest", "weight": 30}, {"type": "shop", "weight": 20}, {"type": "event", "weight": 10}])
		5:
			# Rest is now forced on one node at this floor; the random node gets elite or treasure
			return _weighted_pick(rng, [{"type": "elite", "weight": 55}, {"type": "treasure", "weight": 45}])
		_:
			return "regular"

func _weighted_pick(rng: RandomNumberGenerator, options: Array[Dictionary]) -> String:
	var total_weight := 0
	for option in options:
		total_weight += int(option["weight"])
	var roll := rng.randi_range(1, total_weight)
	var running := 0
	for option in options:
		running += int(option["weight"])
		if roll <= running:
			return String(option["type"])
	return String(options.back()["type"])

func _pick_encounter_id(act: int, node_type: String, rng: RandomNumberGenerator, enemy_database) -> StringName:
	if node_type != "regular" and node_type != "elite":
		return &""
	var pool = enemy_database.get_pool(act, node_type)
	if pool.is_empty():
		return &""
	return pool[rng.randi_range(0, pool.size() - 1)].id

func _connect_floors(floors: Array, rng: RandomNumberGenerator) -> void:
	for floor_index in range(floors.size() - 1):
		var current_floor: Array[PathNodeDef] = floors[floor_index]
		var next_floor: Array[PathNodeDef] = floors[floor_index + 1]
		var incoming: Dictionary = {}
		for next_node in next_floor:
			incoming[next_node.id] = 0

		for index in range(current_floor.size()):
			var node: PathNodeDef = current_floor[index]
			var primary_lane: int = _map_lane(index, current_floor.size(), next_floor.size())
			_link_nodes(node, next_floor[primary_lane], incoming)
			if rng.randf() < 0.4:
				var offset: int = -1 if rng.randf() < 0.5 else 1
				var secondary_lane: int = clampi(primary_lane + offset, 0, next_floor.size() - 1)
				if secondary_lane != primary_lane:
					_link_nodes(node, next_floor[secondary_lane], incoming)

		for next_node in next_floor:
			if incoming[next_node.id] == 0:
				var fallback_index: int = clampi(next_node.lane, 0, current_floor.size() - 1)
				_link_nodes(current_floor[fallback_index], next_node, incoming)

func _map_lane(index: int, current_size: int, next_size: int) -> int:
	if current_size <= 1:
		return 0
	var ratio := float(index) / float(current_size - 1)
	return clampi(int(round(ratio * float(next_size - 1))), 0, next_size - 1)

func _link_nodes(from_node: PathNodeDef, to_node: PathNodeDef, incoming: Dictionary) -> void:
	if from_node.next_node_ids.has(to_node.id):
		return
	from_node.next_node_ids.append(to_node.id)
	incoming[to_node.id] = int(incoming[to_node.id]) + 1

func _format_node(node: PathNodeDef, enemy_database) -> String:
	var type_label := node.node_type.capitalize()
	if node.encounter_id == &"":
		return type_label
	var enemy = enemy_database.get_enemy(node.encounter_id)
	if enemy == null:
		return type_label
	return type_label + " (" + enemy.name + ")"
