class_name CardDatabase
extends RefCounted

const CardDef = preload("res://scripts/core/card_def.gd")
const CARD_LIBRARY_PATH := "res://data/cards/card_library.tres"

var _cards: Dictionary = {}

func _init() -> void:
	if not _load_resource_library():
		_register_cards()

func get_card(card_id: StringName) -> CardDef:
	return _cards.get(card_id)

func get_all_cards(include_upgrades: bool = false, include_boss_debuffs: bool = false) -> Array[CardDef]:
	var cards: Array[CardDef] = []
	for card in _cards.values():
		if not include_upgrades and String(card.id).ends_with("_plus"):
			continue
		if not include_boss_debuffs and card.tags.has("boss_debuff"):
			continue
		cards.append(card)
	return cards

func get_hand_slot_roles(card_def: CardDef) -> PackedStringArray:
	var roles := PackedStringArray()
	if card_def == null:
		return roles
	if not card_def.slot_roles.is_empty():
		return PackedStringArray(card_def.slot_roles)
	if card_def.tags.has("serve") or card_def.tags.has("return"):
		roles.append("initial_contact")
	if _is_shot_slot_card(card_def):
		roles.append("shot")
	if _is_enhancer_slot_card(card_def):
		roles.append("enhancer")
	if _is_modifier_slot_card(card_def):
		roles.append("modifier")
	if _is_special_slot_card(card_def):
		roles.append("special")
	if roles.is_empty():
		roles.append("shot")
	return roles

func get_hand_slot_label(slot_id: String) -> String:
	match slot_id:
		"initial_contact":
			return "INITIAL"
		"shot":
			return "SHOT"
		"enhancer":
			return "ENHANCER"
		"modifier":
			return "MODIFIER"
		"special":
			return "SPECIAL"
	return "CARD"

func get_hand_slot_subtitle(card_def: CardDef, slot_id: String) -> String:
	if card_def == null:
		return ""
	match slot_id:
		"initial_contact":
			return "Serve / Return"
		"shot":
			return _shot_family_text(card_def)
		"enhancer":
			return _enhancer_family_text(card_def)
		"modifier":
			return _modifier_family_text(card_def)
		"special":
			if card_def.tags.has("boss_debuff"):
				return "Boss Debuff"
			return _special_family_text(card_def)
	return ""

func build_deck(card_ids: PackedStringArray) -> Array[CardDef]:
	var deck: Array[CardDef] = []
	for card_id in card_ids:
		var card: CardDef = get_card(card_id)
		if card != null:
			deck.append(card)
	return deck

func _add_card(card: CardDef) -> void:
	_apply_card_metadata_defaults(card)
	if _should_skip_card(card):
		return
	_sanitize_card(card)
	_cards[card.id] = card

func _load_resource_library() -> bool:
	_cards.clear()
	if not ResourceLoader.exists(CARD_LIBRARY_PATH):
		return false
	var library = load(CARD_LIBRARY_PATH)
	if library == null:
		return false
	var resources: Array = Array(library.cards)
	for resource in resources:
		var card := _resource_to_card_def(resource)
		if card == null:
			continue
		_add_card(card)
	return not _cards.is_empty()

func _resource_to_card_def(resource) -> CardDef:
	if resource == null:
		return null
	return CardDef.new(
		StringName(resource.id),
		resource.name,
		int(resource.cost),
		resource.description,
		PackedStringArray(resource.tags),
		Dictionary(resource.effects).duplicate(true),
		StringName(resource.upgrade_to),
		resource.category,
		resource.shot_family,
		PackedStringArray(resource.slot_roles),
		Dictionary(resource.requires).duplicate(true)
	)

func _apply_card_metadata_defaults(card_def: CardDef) -> void:
	if card_def == null:
		return
	if card_def.category == "":
		card_def.category = _infer_category(card_def)
	if card_def.shot_family == "":
		card_def.shot_family = _infer_shot_family(card_def)
	if card_def.slot_roles.is_empty():
		card_def.slot_roles = _infer_slot_roles(card_def)
	if card_def.requires.is_empty():
		card_def.requires = _infer_card_requirements(card_def)

func _should_skip_card(card_def: CardDef) -> bool:
	if card_def == null:
		return true
	return card_def.tags.has("boss_debuff") and String(card_def.id).ends_with("_plus")

func _sanitize_card(card_def: CardDef) -> void:
	if card_def == null:
		return
	if card_def.tags.has("boss_debuff"):
		card_def.upgrade_to = &""

func _infer_category(card_def: CardDef) -> String:
	if card_def.tags.has("boss_debuff"):
		return "debuff"
	if card_def.tags.has("modifier") or card_def.tags.has("string") or card_def.tags.has("racquet"):
		return "modifier"
	if card_def.tags.has("footwork"):
		return "footwork"
	if card_def.tags.has("skill") or card_def.tags.has("recovery") or card_def.tags.has("training"):
		return "focus"
	if _has_any_tag(card_def, PackedStringArray(["serve", "return", "rally", "net", "slice", "topspin", "power", "signature", "counter", "trick", "tempo", "crosscourt", "down_the_line", "drop", "volley", "lob", "smash"])):
		return "shot"
	return "utility"

func _infer_shot_family(card_def: CardDef) -> String:
	if card_def.tags.has("serve"):
		return "Serve"
	if card_def.tags.has("return"):
		return "Return"
	if card_def.name.find("Forehand") >= 0:
		return "Forehand"
	if card_def.name.find("Backhand") >= 0:
		return "Backhand"
	if card_def.tags.has("smash"):
		return "Overhead Smash"
	if card_def.tags.has("volley") or card_def.tags.has("net"):
		return "Volley"
	if card_def.tags.has("drop"):
		return "Drop Shot"
	if card_def.tags.has("lob"):
		return "Lob"
	if card_def.tags.has("slice"):
		return "Slice"
	if card_def.tags.has("topspin"):
		return "Topspin"
	if card_def.tags.has("down_the_line"):
		return "Down The Line"
	if card_def.tags.has("crosscourt"):
		return "Crosscourt"
	return "Rally"

func _infer_slot_roles(card_def: CardDef) -> PackedStringArray:
	var roles := PackedStringArray()
	var initial_contact_card := card_def.tags.has("serve") or card_def.tags.has("return")
	if initial_contact_card:
		roles.append("initial_contact")
	if not initial_contact_card and _is_shot_slot_card(card_def):
		roles.append("shot")
	if _is_enhancer_slot_card(card_def):
		roles.append("enhancer")
	if _is_modifier_slot_card(card_def):
		roles.append("modifier")
	if _is_special_slot_card(card_def):
		roles.append("special")
	if roles.is_empty():
		roles.append("shot")
	return roles

func _infer_card_requirements(card_def: CardDef) -> Dictionary:
	var requirements := {}
	if card_def.tags.has("serve"):
		requirements["must_be_server"] = true
		requirements["point_open_only"] = true
		requirements["max_uses_per_turn"] = 1
	if card_def.tags.has("return"):
		requirements["must_be_receiver"] = true
		requirements["point_open_only"] = true
	if card_def.tags.has("smash"):
		requirements["attacker_position_in"] = PackedStringArray(["ServiceLine", "Net"])
	if card_def.id == &"overhead_smash":
		requirements["attacker_position_in"] = PackedStringArray(["ServiceLine", "Net"])
	return requirements

func _register_cards() -> void:
	_add_card(CardDef.new(&"steady_serve", "Steady Serve", 1, "Deal 7 damage. Can only open a point while serving.", PackedStringArray(["serve", "basic"]), {"damage": 7}))
	_add_card(CardDef.new(&"crosscourt_rally", "Crosscourt Rally", 1, "Deal 5 damage, open the court, and if you already played a shot this turn, draw 1.", PackedStringArray(["rally", "basic", "crosscourt"]), {"damage": 5, "combo_draw": 1, "open_court": 1}))
	_add_card(CardDef.new(&"basic_volley", "Basic Volley", 1, "Gain 5 Guard and deal 8 damage. Strongest when you close in.", PackedStringArray(["net", "basic", "volley"]), {"guard": 5, "damage": 8}))
	_add_card(CardDef.new(&"recover_breath", "Recover Breath", 1, "Gain 7 Guard and recover 1 Stamina next turn.", PackedStringArray(["recovery", "skill"]), {"guard": 7, "next_turn_stamina": 1}))
	_add_card(CardDef.new(&"split_step", "Split Step", 1, "Gain 8 Guard. Draw 1.", PackedStringArray(["footwork", "skill"]), {"guard": 8, "draw": 1}))
	_add_card(CardDef.new(&"topspin_drive", "Topspin Drive", 1, "Deal 10 damage. Apply 2 Spin.", PackedStringArray(["rally", "topspin"]), {"damage": 10, "spin": 2}))
	_add_card(CardDef.new(&"slice_drag", "Slice Drag", 1, "Deal 8 damage with a skidding slice. Apply 2 Pressure. Apply Tilt ×1 — the low skid disrupts their contact rhythm.", PackedStringArray(["slice", "control"]), {"damage": 8, "pressure": 2, "tilt": 1}))
	_add_card(CardDef.new(&"flat_cannon", "Flat Cannon", 2, "Deal 14 damage.", PackedStringArray(["power", "strike"]), {"damage": 14}))
	_add_card(CardDef.new(&"moonball_reset", "Moonball Reset", 1, "Gain 10 Guard. Apply Fatigue ×1 and Tilt ×1 to the opponent — the heavy high ball disrupts their rhythm and stacks fatigue.", PackedStringArray(["defense", "attrition"]), {"guard": 10, "fatigue": 1, "tilt": 1}))
	_add_card(CardDef.new(&"drop_shot", "Drop Shot", 1, "Deal 7 damage, apply 2 Open Court, and apply Position Lock ×1 — the opponent is dragged forward and loses their court-positioning advantage.", PackedStringArray(["control", "trick", "drop"]), {"damage": 7, "open_court": 2, "position_lock": 1}))
	_add_card(CardDef.new(&"kick_serve", "Kick Serve", 1, "Deal 8 damage. Can only open a point while serving. Gain 1 Momentum.", PackedStringArray(["serve", "tempo"]), {"damage": 8, "momentum": 1}))
	_add_card(CardDef.new(&"block_return", "Block Return", 0, "Deal 2 damage, gain 6 Guard, and if you are returning serve, draw 1.", PackedStringArray(["return", "control", "footwork"]), {"damage": 2, "guard": 6, "draw_if_returning": 1}))
	_add_card(CardDef.new(&"deep_return", "Deep Return", 1, "Deal 6 damage with depth. On a return point, open the court and gain 1 Focus.", PackedStringArray(["return", "rally", "crosscourt"]), {"damage": 6, "open_court": 1, "focus_if_returning": 1}))
	_add_card(CardDef.new(&"chip_return", "Chip Return", 1, "Deal 5 damage with a low chip return. Apply 1 Pressure, 1 Open Court, and Tilt ×1 — the awkward bounce disrupts their next shot timing.", PackedStringArray(["return", "slice", "control"]), {"damage": 5, "pressure": 1, "open_court": 1, "tilt": 1}))
	_add_card(CardDef.new(&"return_rip", "Return Rip", 1, "Deal 9 damage. Best used to drive through a serve before the server settles.", PackedStringArray(["return", "power", "down_the_line"]), {"damage": 9}))
	_add_card(CardDef.new(&"short_hop_pickup", "Short-Hop Pickup", 0, "Deal 3 damage and gain 5 Guard. On a return point, gain 1 Focus for the rally.", PackedStringArray(["return", "footwork", "control"]), {"damage": 3, "guard": 5, "focus_if_returning": 1}))
	_add_card(CardDef.new(&"lobbed_return", "Lobbed Return", 1, "Deal 4 damage, gain 5 Guard, and send a crowded attacker back with a lifted return.", PackedStringArray(["return", "lob", "control", "recovery"]), {"damage": 4, "guard": 5}))
	_add_card(CardDef.new(&"backhand_counter_return", "Backhand Counter Return", 1, "Deal 7 damage and open the court with a sharp backhand counter.", PackedStringArray(["return", "down_the_line", "control"]), {"damage": 7, "open_court": 1}))
	_add_card(CardDef.new(&"approach_shot", "Approach Shot", 1, "Deal 8 damage. Your next Net card this turn gets +6 damage.", PackedStringArray(["net", "tempo"]), {"damage": 8, "next_net_bonus_damage": 6}))
	_add_card(CardDef.new(&"net_rush", "Net Rush", 1, "Gain 6 Guard and deal 10 damage. Converts pressure best when you are forward.", PackedStringArray(["net", "tempo", "volley"]), {"guard": 6, "damage": 10}))
	_add_card(CardDef.new(&"passing_bullet", "Passing Bullet", 1, "Deal 11 damage. Deal 5 more against targets with Guard.", PackedStringArray(["counter", "rally"]), {"damage": 11, "bonus_vs_guard": 5}))
	_add_card(CardDef.new(&"lob_escape", "Lob Escape", 1, "Gain 6 Guard and float a lob over the court. Apply Position Lock ×1 — the lifted ball forces the attacker back, stranding them. If under Pressure, draw 2 instead.", PackedStringArray(["control", "recovery", "lob"]), {"guard": 6, "damage": 4, "draw_if_pressured": 2, "position_lock": 1}))
	_add_card(CardDef.new(&"inside_out_forehand", "Inside-Out Forehand", 1, "Deal 11 damage. If the target has Spin, deal 4 more and open the court.", PackedStringArray(["signature", "rally", "topspin"]), {"damage": 11, "bonus_vs_spin": 4, "open_court": 1}))
	_add_card(CardDef.new(&"backhand_redirect", "Backhand Redirect", 1, "Deal 7 damage and apply 1 Pressure with a redirected change of direction.", PackedStringArray(["control", "rally", "down_the_line"]), {"damage": 7, "pressure": 1}))
	_add_card(CardDef.new(&"second_wind", "Second Wind", 1, "Heal 5. Exhaust.", PackedStringArray(["recovery", "power"]), {"heal": 5, "exhaust": true}))
	_add_card(CardDef.new(&"endurance_training", "Endurance Training", 1, "Gain 6 Guard, recover 1 Stamina next turn, and increase Endurance scaling for the combat.", PackedStringArray(["skill", "training"]), {"guard": 6, "endurance_scaling": 1, "next_turn_stamina": 1}))
	_add_card(CardDef.new(&"ace_hunter", "Ace Hunter", 2, "Deal 18 damage. Can only open a point while serving. Exhaust.", PackedStringArray(["serve", "power"]), {"damage": 18, "exhaust": true}))
	_add_card(CardDef.new(&"down_the_line", "Down The Line", 1, "Deal 7 damage. Riskier, but deadly after you pull the court open.", PackedStringArray(["rally", "control", "down_the_line"]), {"damage": 7}))
	_add_card(CardDef.new(&"overhead_smash", "Overhead Smash", 2, "Deal 12 damage. Crushes high balls and short lobs.", PackedStringArray(["net", "power", "smash", "volley"]), {"damage": 12}))
	_add_card(CardDef.new(&"relentless_return", "Relentless Return", 1, "Deal 4 damage twice. Apply 1 Pressure on the second hit.", PackedStringArray(["attrition", "rally"]), {"multi_hit": PackedInt32Array([4, 4]), "pressure": 1}))
	_add_card(CardDef.new(&"masterclass", "Masterclass", 1, "Retain 1 extra card each turn. Gain 1 Focus.", PackedStringArray(["power", "technique"]), {"retain_bonus": 1, "focus": 1}))
	_add_card(CardDef.new(&"elastic_chase", "Elastic Chase", 0, "Deal 4 damage, gain 6 Guard, and draw 1. If this is your first Footwork card, gain 1 Momentum.", PackedStringArray(["footwork", "combo"]), {"damage": 4, "guard": 6, "draw": 1, "first_footwork_momentum": 1}))
	_add_card(CardDef.new(&"highlight_reel", "Highlight Reel", 1, "Deal 10 damage, apply 1 Open Court, then draw 2.", PackedStringArray(["signature", "tempo"]), {"damage": 10, "open_court": 1, "draw": 2}))
	_add_card(CardDef.new(&"polyester_bed", "Polyester Bed", 1, "Modifier - String. Equip polyester for the match. Topspin and Slice shots gain +4 pressure and Spin applications gain +1. Exhaust.", PackedStringArray(["modifier", "string", "control"]), {"string_type": "Polyester", "string_modifiers": {"extra_spin": 1, "topspin_pressure_bonus": 4, "slice_pressure_bonus": 4}, "exhaust": true}))
	_add_card(CardDef.new(&"natural_gut_lacing", "Natural Gut Lacing", 1, "Modifier - String. Equip natural gut for the match. Your shots gain +6% accuracy and recovery effects heal +2 more. Exhaust.", PackedStringArray(["modifier", "string", "recovery"]), {"string_type": "Natural Gut", "string_modifiers": {"global_accuracy_bonus": 0.06, "control_accuracy_bonus": 0.04, "heal_bonus": 2}, "exhaust": true}))
	_add_card(CardDef.new(&"multifilament_touch", "Multifilament Touch", 1, "Modifier - String. Equip a multifilament bed for the match. Volleys and control shots gain +3 pressure, accuracy rises, and guard cards gain +1. Exhaust.", PackedStringArray(["modifier", "string", "control", "volley"]), {"string_type": "Multifilament", "string_modifiers": {"net_pressure_bonus": 3, "control_accuracy_bonus": 0.04, "guard_bonus": 1}, "exhaust": true}))
	_add_card(CardDef.new(&"synthetic_gut_setup", "Synthetic Gut Setup", 1, "Modifier - String. Equip synthetic gut for the match. Serves and slice exchanges gain +2 pressure with a small global accuracy bump. Exhaust.", PackedStringArray(["modifier", "string", "tempo", "control"]), {"string_type": "Synthetic Gut", "string_modifiers": {"serve_pressure_bonus": 2, "slice_pressure_bonus": 2, "global_accuracy_bonus": 0.03}, "exhaust": true}))
	_add_card(CardDef.new(&"hybrid_string_job", "Hybrid String Job", 1, "Modifier - String. Equip a hybrid setup for the match. Serves and Net cards gain +5 pressure, and Control cards gain +4% accuracy. Exhaust.", PackedStringArray(["modifier", "string", "tempo"]), {"string_type": "Hybrid", "string_modifiers": {"serve_pressure_bonus": 5, "net_pressure_bonus": 5, "control_accuracy_bonus": 0.04}, "exhaust": true}))
	_add_card(CardDef.new(&"kevlar_coil", "Kevlar Coil", 1, "Modifier - String. Gain 6 Guard, then equip kevlar for the match. Power shots gain +7 pressure but lose 4% accuracy. Exhaust.", PackedStringArray(["modifier", "string", "power"]), {"guard": 6, "string_type": "Kevlar", "string_modifiers": {"power_pressure_bonus": 7, "power_accuracy_bonus": -0.04, "guard_bonus": 2}, "exhaust": true}))
	_add_card(CardDef.new(&"lead_tape_12", "Lead Tape (12 O'Clock)", 1, "Modifier - Racquet Weight. Equip top-loaded lead tape for the match. Serves and Power shots gain +6 pressure, but lost points cost +2 extra Condition. Exhaust.", PackedStringArray(["modifier", "racquet", "weight", "power"]), {"racquet_weight_type": "Lead Tape 12", "racquet_modifiers": {"serve_pressure_bonus": 6, "power_pressure_bonus": 6, "point_condition_penalty": 2}, "exhaust": true}))
	_add_card(CardDef.new(&"lead_tape_3_9", "Lead Tape (3 and 9)", 1, "Modifier - Racquet Weight. Gain 4 Guard, then equip side-balanced tape for the match. Control and Net shots gain +4 pressure, but lost points cost +1 extra Condition. Exhaust.", PackedStringArray(["modifier", "racquet", "weight", "control"]), {"guard": 4, "racquet_weight_type": "Lead Tape 3 and 9", "racquet_modifiers": {"control_pressure_bonus": 4, "net_pressure_bonus": 4, "point_condition_penalty": 1, "guard_bonus": 1}, "exhaust": true}))
	_add_card(CardDef.new(&"pro_stock_frame", "Pro Stock Frame", 1, "Modifier - Racquet Weight. Equip a heavy pro frame for the match. Power shots gain +9 pressure and Serves gain +4, but lost points cost +4 extra Condition and long rallies add Fatigue. Exhaust.", PackedStringArray(["modifier", "racquet", "weight", "power"]), {"racquet_weight_type": "Pro Stock", "racquet_modifiers": {"power_pressure_bonus": 9, "serve_pressure_bonus": 4, "point_condition_penalty": 4, "long_rally_fatigue": 1}, "exhaust": true}))
	_add_card(CardDef.new(&"head_light_control_frame", "Head-Light Control Frame", 1, "Modifier - Racquet Weight. Gain 5 Guard, then equip a head-light control frame for the match. Control shots gain +4 pressure and +6% accuracy, but lost points cost +1 extra Condition. Exhaust.", PackedStringArray(["modifier", "racquet", "weight", "control"]), {"guard": 5, "racquet_weight_type": "Head-Light Control", "racquet_modifiers": {"control_pressure_bonus": 4, "control_accuracy_bonus": 0.06, "guard_bonus": 1, "point_condition_penalty": 1}, "exhaust": true}))
	_add_card(CardDef.new(&"extra_long_leverage_frame", "Extra-Long Leverage Build", 1, "Modifier - Racquet Weight. Equip an extra-long frame for the match. Serves gain +8 pressure and Power shots gain +5, but lost points cost +3 extra Condition and long rallies add Fatigue. Exhaust.", PackedStringArray(["modifier", "racquet", "weight", "serve", "power"]), {"racquet_weight_type": "Extra-Long Lever", "racquet_modifiers": {"serve_pressure_bonus": 8, "power_pressure_bonus": 5, "point_condition_penalty": 3, "long_rally_fatigue": 1}, "exhaust": true}))
	_add_card(CardDef.new(&"counterweighted_handle", "Counterweighted Handle", 1, "Modifier - Racquet Weight. Gain 4 Guard, then equip a counterweighted build for the match. Net and Control shots gain +3 pressure and Control gains +3% accuracy, but lost points cost +1 extra Condition. Exhaust.", PackedStringArray(["modifier", "racquet", "weight", "tempo", "control"]), {"guard": 4, "racquet_weight_type": "Counterweighted Handle", "racquet_modifiers": {"net_pressure_bonus": 3, "control_pressure_bonus": 3, "control_accuracy_bonus": 0.03, "guard_bonus": 1, "point_condition_penalty": 1}, "exhaust": true}))
	# --- Class-Specific Signature Cards ---
	# NOVICE — Fresh Strings payoff: first Skill each turn costs 0, draws 1, gains 1 Focus, sets guard floor.
	# Rhythm Reset is a Skill so Fresh Strings fires on it: becomes free, draws 2 total, gains Focus, 10 Guard.
	_add_card(CardDef.new(&"rhythm_reset", "Rhythm Reset", 1,
		"Gain 10 Guard. Recover 1 Stamina this turn. Draw 1. Fresh Strings makes this free, draws 2, and gains Focus.",
		PackedStringArray(["recovery", "skill"]),
		{"guard": 10, "next_turn_stamina": 1, "draw": 1}))

	# PUSHER — Attrition Point payoff: first Guard gain each turn applies 2 Pressure and gains 1 Focus.
	# Deep Grind's Guard immediately triggers the passive: 8 total damage, 6 Guard, 3 Pressure, 1 Focus.
	_add_card(CardDef.new(&"deep_grind", "Deep Grind", 1,
		"Deal 4 damage twice. Gain 6 Guard. Apply 1 Pressure. Attrition Point: Guard gain triggers +2 Pressure and Focus.",
		PackedStringArray(["attrition", "rally"]),
		{"multi_hit": PackedInt32Array([4, 4]), "guard": 6, "pressure": 1}))

	# SLICER — Low Skid payoff: first Slice each turn gains extra skid pressure, opens court if opponent is forward.
	# Razor Slice is the Slice finisher — first Slice of the turn hits hardest with passive amplification.
	_add_card(CardDef.new(&"razor_slice", "Razor Slice", 1,
		"Deal 12 damage with a cutting slice. Apply 2 Pressure. Apply 1 Open Court. Low Skid sharpens the first Slice's skid and opens the court harder if the opponent is forward.",
		PackedStringArray(["slice", "control", "signature"]),
		{"damage": 12, "pressure": 2, "open_court": 1}))

	# POWER — Explosive Contact payoff: after a Serve or Return, the next Power card costs 1 less, gains +10 pressure, +3 Guard.
	# Power Surge is the Power finisher — at base cost 2, the passive makes it cost 1 with 26 total effective pressure.
	_add_card(CardDef.new(&"power_surge", "Power Surge", 2,
		"Deal 16 damage. Apply 2 Pressure. Gain 5 Guard. Explosive Contact: after a Serve or Return, this costs 1 and gains +10 pressure and +3 Guard.",
		PackedStringArray(["power", "signature"]),
		{"damage": 16, "pressure": 2, "guard": 5}))

	# ALL-AROUNDER — Pattern Read payoff: each new shot tag played this turn draws 1; maintaining variety gains Focus.
	# All-Court Medley has 4 distinct tags — can trigger Pattern Read up to 4 times if tags are fresh.
	_add_card(CardDef.new(&"all_court_medley", "All-Court Medley", 1,
		"Deal 7 damage. Apply 1 Spin. Apply 1 Pressure. Gain 4 Guard. Pattern Read: each new tag — rally, topspin, slice, control — draws 1 more this turn.",
		PackedStringArray(["rally", "topspin", "slice", "control"]),
		{"damage": 7, "spin": 1, "pressure": 1, "guard": 4}))

	# BASELINER — Redline Rhythm payoff: after 2 Rally cards, next Topspin/forehand gets +10 pressure, +10% accuracy.
	# Redline Forehand is a Rally+Topspin Signature — played third in a rally sequence it becomes a high-accuracy closer.
	_add_card(CardDef.new(&"redline_forehand", "Redline Forehand", 1,
		"Deal 13 damage. Apply 3 Spin. Apply 1 Open Court. Redline Rhythm: after two Rally cards this turn, gains +10 pressure and +10% accuracy.",
		PackedStringArray(["signature", "rally", "topspin"]),
		{"damage": 13, "spin": 3, "open_court": 1}))

	# SERVE & VOLLEY — Close the Net payoff: after a Serve or Return, the next Net card costs 0, gains +10 pressure, +10% accuracy.
	# Knife Volley is the Net finisher — after a Kick Serve, it becomes free with 24 total effective pressure.
	_add_card(CardDef.new(&"knife_volley", "Knife Volley", 2,
		"Deal 14 damage. Apply 2 Pressure. Gain 4 Guard. Apply 1 Open Court. Close the Net: after a Serve or Return, this costs 0 and gains +10 pressure and +10% accuracy.",
		PackedStringArray(["net", "volley", "signature"]),
		{"damage": 14, "pressure": 2, "guard": 4, "open_court": 1}))

	# MASTER — Court IQ payoff: retain 1 card/turn; playing a retained card grants Focus, draws 1, gains 3 Guard.
	# Calculated Risk is worth retaining — replaying it fires Court IQ for +Focus +1 Draw +3 Guard on top of its base.
	_add_card(CardDef.new(&"calculated_risk", "Calculated Risk", 1,
		"Deal 10 damage. Apply 2 Open Court. Gain 5 Guard. Court IQ: replaying this after retaining it grants +1 Focus, +1 Draw, and +3 Guard.",
		PackedStringArray(["power", "signature", "technique"]),
		{"damage": 10, "open_court": 2, "guard": 5}))

	# ALCARAZ — Elastic Attack payoffs: Footwork into Signature draws 1, +1 Momentum, +1 Focus, -1 cost, 2 Guard, sharpened finish.
	# Sprinting Chase is the Footwork setup — fires Elastic Attack and already provides momentum and draw.
	_add_card(CardDef.new(&"sprinting_chase", "Sprinting Chase", 1,
		"Gain 7 Guard. Draw 2. Apply 1 Open Court. If this is your first Footwork card this turn, gain 1 Momentum. Elastic Attack: then play a Signature to chain the full combo.",
		PackedStringArray(["footwork", "combo"]),
		{"guard": 7, "draw": 2, "open_court": 1, "first_footwork_momentum": 1}))
	# Match Point Strike is the Signature finisher — with Elastic Attack active it costs 1 and fires with 3 Draw, Momentum, Focus.
	_add_card(CardDef.new(&"match_point_strike", "Match Point Strike", 2,
		"Deal 16 damage. Apply 2 Open Court. Gain 3 Guard. Draw 1. Elastic Attack: after Footwork this turn, costs 1, draws 2 total, gains Momentum and Focus.",
		PackedStringArray(["signature", "power", "tempo"]),
		{"damage": 16, "open_court": 2, "guard": 3, "draw": 1}))

	# ── Player Disruption Cards ─────────────────────────────────────────────────────────────────
	# Cards that apply persistent tactical debuffs to the enemy, giving each shot archetype
	# a rogue-style status hook beyond pure pressure/guard math.

	# TILT ARCHETYPE: Disorienting shots that crack the opponent's contact window.
	_add_card(CardDef.new(&"heavy_moonball", "Heavy Moonball", 2,
		"Gain 8 Guard. Apply Fatigue ×2 and Tilt ×2 to the opponent — a crushing high ball that stacks fatigue and shreds their accuracy.",
		PackedStringArray(["defense", "attrition", "lob"]),
		{"guard": 8, "fatigue": 2, "tilt": 2}))

	# SLICE ANGLE — slice rogue card: full position lock + tilt combo
	_add_card(CardDef.new(&"angle_slice", "Angle Slice", 1,
		"Deal 9 damage. Apply Position Lock ×1 and Tilt ×1 — a cross-court knife that pulls the opponent offline and cracks their contact rhythm.",
		PackedStringArray(["slice", "control", "trick"]),
		{"damage": 9, "position_lock": 1, "tilt": 1}))

	# STAMINA DRAIN: Forces the opponent to burn resources on every response.
	_add_card(CardDef.new(&"court_dominance", "Court Dominance", 2,
		"Deal 8 damage. Apply Cost Spike ×2 to the opponent — a deep, dominant drive that makes every reply cost more.",
		PackedStringArray(["power", "rally"]),
		{"damage": 8, "cost_up": 2}))

	# NET COMMAND: Positional shutdown from the net.
	_add_card(CardDef.new(&"net_command", "Net Command", 1,
		"Gain 6 Guard. Deal 7 damage. Apply Position Lock ×1 — closing the net forces the passer offline and suspends their positional bonuses.",
		PackedStringArray(["net", "volley", "control"]),
		{"guard": 6, "damage": 7, "position_lock": 1}))

	# DISGUISED DRIVE: Topspin shot that tilts on contact — looks like a regular drive but arrives heavier.
	_add_card(CardDef.new(&"disguised_drive", "Disguised Drive", 1,
		"Deal 10 damage. Apply 1 Spin and Tilt ×1 — a disguised topspin drive that warps the opponent's read window.",
		PackedStringArray(["rally", "topspin", "trick"]),
		{"damage": 10, "spin": 1, "tilt": 1}))

	# GRIND TRAP: Attrition disruption — exhausts the opponent across turns.
	_add_card(CardDef.new(&"grind_trap", "Grind Trap", 1,
		"Deal 6 damage twice. Apply Fatigue ×1 — a relentless two-ball sequence that slowly drains the opponent's stamina ceiling.",
		PackedStringArray(["attrition", "rally"]),
		{"multi_hit": PackedInt32Array([6, 6]), "fatigue": 1}))

	_add_card(CardDef.new(&"crowd_noise_debuff", "Crowd Noise", 99, "Boss Debuff. The stadium roar rattles the special slot. Unplayable. End turn: gain 1 Fatigue.", PackedStringArray(["special", "boss_debuff"]), {"fatigue": 1}))
	_add_card(CardDef.new(&"late_whistle_debuff", "Late Whistle", 99, "Boss Debuff. The interruption breaks your rhythm. Unplayable. End turn: suffer 1 Pressure.", PackedStringArray(["special", "boss_debuff"]), {"pressure": 1}))
	_add_card(CardDef.new(&"tight_strings_debuff", "Tight Strings", 99, "Boss Debuff. The pressure tightens your contact window. Unplayable. End turn: gain 1 Fatigue and 1 Open Court.", PackedStringArray(["special", "boss_debuff"]), {"fatigue": 1, "open_court": 1}))
	_generate_upgraded_variants()

func _is_shot_slot_card(card_def: CardDef) -> bool:
	return _has_any_tag(card_def, PackedStringArray(["rally", "basic", "power", "net", "volley", "signature", "slice", "topspin", "lob", "drop", "smash", "control", "crosscourt", "down_the_line"]))

func _is_enhancer_slot_card(card_def: CardDef) -> bool:
	if _has_any_tag(card_def, PackedStringArray(["skill", "recovery", "footwork", "training", "tempo", "combo", "technique", "attrition", "defense"])):
		return true
	return card_def.effects.has("draw") or card_def.effects.has("guard") or card_def.effects.has("retain_bonus") or card_def.effects.has("next_turn_stamina") or card_def.effects.has("next_net_bonus_damage") or card_def.effects.has("endurance_scaling")

func _is_modifier_slot_card(card_def: CardDef) -> bool:
	if card_def.tags.has("modifier"):
		return true
	return card_def.tags.has("string") or card_def.tags.has("racquet") or card_def.effects.has("string_type") or card_def.effects.has("racquet_weight_type")

func _is_special_slot_card(card_def: CardDef) -> bool:
	if card_def.tags.has("boss_debuff"):
		return true
	if _has_any_tag(card_def, PackedStringArray(["signature", "power", "combo"])):
		return true
	return card_def.effects.has("exhaust") or card_def.effects.has("heal")

func _has_any_tag(card_def: CardDef, target_tags: PackedStringArray) -> bool:
	for tag in target_tags:
		if card_def.tags.has(tag):
			return true
	return false

func _shot_family_text(card_def: CardDef) -> String:
	if card_def.shot_family != "":
		return card_def.shot_family
	if card_def.tags.has("serve"):
		return "Serve Pattern"
	if card_def.tags.has("return"):
		return "Return Pattern"
	if card_def.name.find("Forehand") >= 0:
		return "Forehand"
	if card_def.name.find("Backhand") >= 0:
		return "Backhand"
	if card_def.tags.has("volley") or card_def.tags.has("net"):
		return "Volley"
	if card_def.tags.has("smash"):
		return "Overhead"
	if card_def.tags.has("slice"):
		return "Slice"
	if card_def.tags.has("topspin"):
		return "Topspin"
	return "Rally Shot"

func _enhancer_family_text(card_def: CardDef) -> String:
	if card_def.tags.has("footwork"):
		return "Footwork"
	if card_def.tags.has("recovery"):
		return "Recovery"
	if card_def.tags.has("tempo"):
		return "Tempo Boost"
	if card_def.tags.has("training"):
		return "Training"
	if card_def.tags.has("technique"):
		return "Technique"
	return "Tactical Boost"

func _modifier_family_text(card_def: CardDef) -> String:
	if card_def.tags.has("string"):
		return "String Setup"
	if card_def.tags.has("racquet"):
		return "Frame Setup"
	return "Gear Build"

func _special_family_text(card_def: CardDef) -> String:
	if card_def.category == "debuff":
		return "Boss Debuff"
	if card_def.tags.has("signature"):
		return "Signature"
	if card_def.tags.has("power"):
		return "Emergency Spike"
	if card_def.tags.has("recovery"):
		return "Recovery"
	return "Special"

func _generate_upgraded_variants() -> void:
	var base_cards: Array = _cards.values().duplicate()
	for base_card in base_cards:
		if base_card == null:
			continue
		if String(base_card.id).ends_with("_plus"):
			continue
		if base_card.tags.has("boss_debuff"):
			base_card.upgrade_to = &""
			continue
		var upgraded_id := StringName(String(base_card.id) + "_plus")
		if _cards.has(upgraded_id):
			continue
		var upgraded_effects: Dictionary = _upgrade_effects(Dictionary(base_card.effects))
		var upgraded_description: String = String(base_card.description)
		var summary: String = _build_upgrade_summary(Dictionary(base_card.effects), upgraded_effects)
		if summary != "":
			upgraded_description += " Upgraded: %s." % summary
		else:
			upgraded_description += " Upgraded."
		base_card.upgrade_to = upgraded_id
		_add_card(CardDef.new(
			upgraded_id,
			base_card.name + "+",
			base_card.cost,
			upgraded_description,
			PackedStringArray(base_card.tags),
			upgraded_effects,
			&""
		))

func _upgrade_effects(effects: Dictionary) -> Dictionary:
	var upgraded := effects.duplicate(true)
	for key in upgraded.keys():
		match String(key):
			"damage":
				upgraded[key] = int(upgraded[key]) + 3
			"guard":
				upgraded[key] = int(upgraded[key]) + 3
			"heal":
				upgraded[key] = int(upgraded[key]) + 2
			"spin", "pressure", "open_court", "momentum", "focus", "retain_bonus", "endurance_scaling", "next_turn_stamina", "first_footwork_momentum":
				upgraded[key] = int(upgraded[key]) + 1
			"draw", "draw_if_pressured", "combo_draw":
				upgraded[key] = int(upgraded[key]) + 1
			"next_net_bonus_damage", "bonus_vs_guard", "bonus_vs_spin":
				upgraded[key] = int(upgraded[key]) + 2
			"multi_hit":
				var boosted_hits := PackedInt32Array()
				for hit_value in PackedInt32Array(upgraded[key]):
					boosted_hits.append(int(hit_value) + 1)
				upgraded[key] = boosted_hits
			"string_modifiers", "racquet_modifiers":
				upgraded[key] = _upgrade_modifier_table(Dictionary(upgraded[key]))
	return upgraded

func _upgrade_modifier_table(modifiers: Dictionary) -> Dictionary:
	var upgraded := modifiers.duplicate(true)
	for modifier_name in upgraded.keys():
		match String(modifier_name):
			"extra_spin", "heal_bonus", "guard_bonus", "long_rally_fatigue":
				upgraded[modifier_name] = int(upgraded[modifier_name]) + 1
			"topspin_pressure_bonus", "slice_pressure_bonus", "serve_pressure_bonus", "net_pressure_bonus", "power_pressure_bonus", "control_pressure_bonus":
				upgraded[modifier_name] = int(upgraded[modifier_name]) + 2
			"point_condition_penalty":
				upgraded[modifier_name] = maxi(0, int(upgraded[modifier_name]) - 1)
			"global_accuracy_bonus", "control_accuracy_bonus", "power_accuracy_bonus":
				upgraded[modifier_name] = float(upgraded[modifier_name]) + 0.02
	return upgraded

func _build_upgrade_summary(base_effects: Dictionary, upgraded_effects: Dictionary) -> String:
	var notes := PackedStringArray()
	for key in upgraded_effects.keys():
		if not base_effects.has(key):
			continue
		match String(key):
			"damage":
				notes.append("+%d pressure" % (int(upgraded_effects[key]) - int(base_effects[key])))
			"guard":
				notes.append("+%d guard" % (int(upgraded_effects[key]) - int(base_effects[key])))
			"heal":
				notes.append("+%d heal" % (int(upgraded_effects[key]) - int(base_effects[key])))
			"draw", "draw_if_pressured", "combo_draw":
				notes.append("+%d draw" % (int(upgraded_effects[key]) - int(base_effects[key])))
			"string_modifiers":
				notes.append("better string tuning")
			"racquet_modifiers":
				notes.append("stronger frame tuning")
	if notes.is_empty():
		return ""
	return ", ".join(notes)
