class_name PlayerClassDatabase
extends RefCounted

const PlayerClassDef = preload("res://scripts/core/player_class_def.gd")

const ORDER := [
	&"novice",
	&"pusher",
	&"slicer",
	&"power",
	&"all_arounder",
	&"baseliner",
	&"serve_and_volley",
	&"master",
	&"alcaraz"
]

var _classes: Dictionary = {}

func _init() -> void:
	_register_classes()

func get_player_class(class_id: StringName) -> PlayerClassDef:
	return _classes.get(class_id)

func get_all_classes_in_order() -> Array[PlayerClassDef]:
	var classes: Array[PlayerClassDef] = []
	for class_id in ORDER:
		classes.append(get_player_class(class_id))
	return classes

func _add_class(player_class: PlayerClassDef) -> void:
	_classes[player_class.id] = player_class

func _register_classes() -> void:
	_add_class(PlayerClassDef.new(
		&"novice",
		"Novice",
		1,
		"Forgiving starter",
		"A stable introduction to rally management, recovery, and basic combo turns with enough margin to survive a full Slam run.",
		"Fresh Strings",
		"The first Skill card you play each turn costs 0, draws 1, gains 1 Focus, and sets a light guard floor.",
		{"stamina": 5, "endurance": 84, "strength": 0, "control": 2, "footwork": 2, "focus": 1},
		PackedStringArray(["Steady Serve", "Recover Breath", "Split Step", "Rhythm Reset"]),
		_standard_starting_deck(PackedStringArray([
			"steady_serve",
			"deep_return",
			"crosscourt_rally",
			"crosscourt_rally",
			"block_return",
			"recover_breath",
			"recover_breath",
			"split_step",
			"backhand_redirect",
			"endurance_training",
		]), PackedStringArray(["rhythm_reset"]))
	))
	_add_class(PlayerClassDef.new(
		&"pusher",
		"Pusher",
		2,
		"Attrition specialist",
		"Wins by extending rallies, stacking pressure, and letting opponents overplay.",
		"Attrition Point",
		"The first time you gain Guard each turn, apply 2 Pressure and gain 1 Focus.",
		{"stamina": 5, "endurance": 82, "strength": 0, "control": 3, "footwork": 3, "focus": 1},
		PackedStringArray(["Moonball Reset", "Deep Return", "Relentless Return", "Deep Grind"]),
		_standard_starting_deck(PackedStringArray([
			"kick_serve",
			"deep_return",
			"moonball_reset",
			"relentless_return",
			"crosscourt_rally",
			"split_step",
			"recover_breath",
			"block_return",
			"endurance_training",
		]), PackedStringArray(["counterweighted_handle", "deep_grind"]))
	))
	_add_class(PlayerClassDef.new(
		&"slicer",
		"Slicer",
		3,
		"Control disruptor",
		"Turns the court ugly with low bounces, off-speed contact, and awkward geometry.",
		"Low Skid",
		"The first Slice card you play each turn gains extra skid pressure, and if the opponent is forward it opens the court harder.",
		{"stamina": 4, "endurance": 76, "strength": 0, "control": 4, "footwork": 2, "focus": 1},
		PackedStringArray(["Slice Drag", "Drop Shot", "Chip Return", "Razor Slice"]),
		_standard_starting_deck(PackedStringArray([
			"steady_serve",
			"chip_return",
			"slice_drag",
			"drop_shot",
			"lob_escape",
			"crosscourt_rally",
			"recover_breath",
			"split_step",
			"block_return",
		]), PackedStringArray(["natural_gut_lacing", "razor_slice"]))
	))
	_add_class(PlayerClassDef.new(
		&"power",
		"Power",
		4,
		"Explosive striker",
		"Trades subtlety for overwhelming contact and short, brutal exchanges, now with a cleaner serve-plus-one pattern that can actually hold up over a full major.",
		"Explosive Contact",
		"Whenever you spend all Stamina in a turn, gain 1 Momentum next turn. The first Serve, Return, or Power shot you play each point gains +6 pressure and +12% accuracy. After you play a Serve or Return, your next Power shot this turn costs 1 less, gains +10 pressure, and gives 3 Guard.",
		{"stamina": 5, "endurance": 92, "strength": 3, "control": 1, "footwork": 1, "focus": 2},
		PackedStringArray(["Flat Cannon", "Ace Hunter", "Return Rip", "Power Surge"]),
		_standard_starting_deck(PackedStringArray([
			"kick_serve",
			"steady_serve",
			"deep_return",
			"block_return",
			"flat_cannon",
			"ace_hunter",
			"recover_breath",
			"split_step",
			"endurance_training",
		]), PackedStringArray(["hybrid_string_job", "power_surge"]))
	))
	_add_class(PlayerClassDef.new(
		&"all_arounder",
		"All-Arounder",
		5,
		"Adaptive toolkit",
		"Switches patterns freely and gets rewarded for sequence variety.",
		"Pattern Read",
		"The first time you play a new shot tag each turn, draw 1. If you keep varying the pattern, gain 1 Focus.",
		{"stamina": 4, "endurance": 78, "strength": 2, "control": 2, "footwork": 2, "focus": 2},
		PackedStringArray(["Topspin Drive", "Approach Shot", "Deep Return", "Slice Drag", "All-Court Medley"]),
		_standard_starting_deck(PackedStringArray([
			"steady_serve",
			"deep_return",
			"topspin_drive",
			"slice_drag",
			"approach_shot",
			"backhand_redirect",
			"split_step",
			"recover_breath",
			"basic_volley",
		]), PackedStringArray(["all_court_medley"]))
	))
	_add_class(PlayerClassDef.new(
		&"baseliner",
		"Baseliner",
		6,
		"Rally tyrant",
		"Owns the back of the court with heavy spin and sustained damage scaling.",
		"Redline Rhythm",
		"After you play two Rally cards in a turn, your next Topspin or forehand-pattern attack gains +10 pressure and +10% accuracy.",
		{"stamina": 4, "endurance": 88, "strength": 2, "control": 2, "footwork": 2, "focus": 1},
		PackedStringArray(["Topspin Drive", "Inside-Out Forehand", "Redline Forehand"]),
		_standard_starting_deck(PackedStringArray([
			"steady_serve",
			"deep_return",
			"topspin_drive",
			"inside_out_forehand",
			"backhand_redirect",
			"crosscourt_rally",
			"split_step",
			"recover_breath",
			"down_the_line",
		]), PackedStringArray(["polyester_bed", "redline_forehand"]))
	))
	_add_class(PlayerClassDef.new(
		&"serve_and_volley",
		"Serve and Volley",
		7,
		"Tempo aggressor",
		"Starts points on offense and rushes the net before enemies can settle.",
		"Close the Net",
		"After you play a Serve or Return card, your next Net card this turn costs 0 and gains +10 pressure with +10% accuracy.",
		{"stamina": 5, "endurance": 82, "strength": 1, "control": 3, "footwork": 3, "focus": 1},
		PackedStringArray(["Kick Serve", "Net Rush", "Chip Return", "Knife Volley"]),
		_standard_starting_deck(PackedStringArray([
			"kick_serve",
			"chip_return",
			"deep_return",
			"approach_shot",
			"net_rush",
			"basic_volley",
			"block_return",
			"recover_breath",
			"split_step",
		]), PackedStringArray(["hybrid_string_job", "knife_volley"]))
	))
	_add_class(PlayerClassDef.new(
		&"master",
		"Master",
		8,
		"Technical endgame class",
		"Retains options, manipulates tempo, and punishes mistakes with precision.",
		"Court IQ",
		"Retain 1 card each turn. The first time each turn you play a retained card, gain 1 Focus, draw 1, and gain 3 Guard.",
		{"stamina": 5, "endurance": 86, "strength": 2, "control": 4, "footwork": 2, "focus": 2},
		PackedStringArray(["Masterclass", "Backhand Redirect", "Calculated Risk"]),
		_standard_starting_deck(PackedStringArray([
			"steady_serve",
			"deep_return",
			"backhand_counter_return",
			"backhand_redirect",
			"masterclass",
			"down_the_line",
			"split_step",
			"recover_breath",
		]), PackedStringArray(["natural_gut_lacing", "head_light_control_frame", "calculated_risk"]))
	))
	_add_class(PlayerClassDef.new(
		&"alcaraz",
		"Alcaraz",
		9,
		"Highlight-reel closer",
		"Combines pace, touch, footspeed, and fearless point construction into explosive combo turns.",
		"Elastic Attack",
		"The first time each turn you play Footwork into a Signature shot, draw 1, gain 1 Momentum, gain 1 Focus, add 2 Guard, make that Signature cost 1 less, and sharpen its finish.",
		{"stamina": 5, "endurance": 90, "strength": 3, "control": 3, "footwork": 3, "focus": 2},
		PackedStringArray(["Elastic Chase", "Highlight Reel", "Deep Return", "Sprinting Chase", "Match Point Strike"]),
		_standard_starting_deck(PackedStringArray([
			"kick_serve",
			"deep_return",
			"elastic_chase",
			"inside_out_forehand",
			"backhand_redirect",
			"net_rush",
			"highlight_reel",
			"second_wind",
			"topspin_drive",
		]), PackedStringArray(["hybrid_string_job", "sprinting_chase", "match_point_strike"]))
	))

func get_string_synergy_note(class_id: StringName, string_type: String) -> String:
	match class_id:
		&"novice":
			if string_type == "Natural Gut": return "Synergy: settles the Novice's contact point (+accuracy)."
			if string_type == "Synthetic Gut": return "Synergy: cleaner response window for Novice (+accuracy, +Guard)."
		&"pusher":
			if string_type == "Natural Gut": return "Synergy: feeds the Pusher's defensive touch (+heal, +Guard)."
			if string_type == "Multifilament": return "Synergy: Pusher stays comfortable in long exchanges (+Guard, +control acc)."
		&"slicer":
			if string_type == "Natural Gut": return "Synergy: sharpens Slicer touch and skid (+slice pressure, +control acc)."
			if string_type == "Multifilament": return "Synergy: easy touch for Slicer (+slice pressure, +control acc)."
		&"power":
			if string_type == "Kevlar": return "Synergy: Power builds swing through the court (+power/serve pressure)."
			if string_type == "Polyester": return "Synergy: Power keeps cut under control (+power/topspin pressure)."
		&"all_arounder":
			if string_type == "Hybrid": return "Synergy: fits All-Arounder's whole-court balance (+serve/net pressure, +control acc)."
			if string_type == "Synthetic Gut": return "Synergy: keeps All-Arounder balanced (+serve pressure, +control acc)."
		&"baseliner":
			if string_type == "Polyester": return "Synergy: unlocks heavier RPM for Baseliner (+topspin pressure, +spin)."
		&"serve_and_volley":
			if string_type == "Hybrid": return "Synergy: juices Serve and Volley first-strike patterns (+serve/net pressure)."
			if string_type == "Multifilament": return "Synergy: soft hands up front for Serve and Volley (+net pressure, +control acc)."
		&"master":
			if string_type == "Natural Gut": return "Synergy: rewards Master's precision (+global/control accuracy)."
		&"alcaraz":
			if string_type == "Hybrid": return "Synergy: amplifies Alcaraz-style variation (+serve/net/topspin pressure)."
			if string_type == "Polyester": return "Synergy: helps Alcaraz jump on spin accelerations (+topspin/serve pressure)."
	return ""

func get_racquet_synergy_note(class_id: StringName, racquet_type: String) -> String:
	match class_id:
		&"novice":
			if racquet_type == "Head-Light Control": return "Synergy: cleaner prep and steadier contact for Novice (+control acc, +Guard)."
		&"pusher":
			if racquet_type == "Counterweighted Handle": return "Synergy: Pusher turns counterweight into attrition stability (+Guard, +control pressure)."
		&"slicer":
			if racquet_type == "Head-Light Control": return "Synergy: Slicer knifes through the ball (+slice pressure, +control acc)."
			if racquet_type == "Lead Tape 3 and 9": return "Synergy: sharpens Slicer's skid and redirection (+slice/control pressure)."
		&"power":
			if racquet_type == "Extra-Long Lever": return "Synergy: Power leans into the lever for heavier first strikes (+serve/power pressure)."
			if racquet_type == "Pro Stock": return "Synergy: heavy pro stock lets Power swing through contact (+power/serve pressure)."
		&"all_arounder":
			if racquet_type == "Counterweighted Handle": return "Synergy: All-Arounder stays balanced in every pattern (+control/net pressure, +Guard)."
			if racquet_type == "Lead Tape 3 and 9": return "Synergy: extra stability on transitions for All-Arounder (+control/net pressure)."
		&"baseliner":
			if racquet_type == "Pro Stock": return "Synergy: Baseliner loads the pro stock with heavier RPM (+topspin pressure)."
		&"serve_and_volley":
			if racquet_type == "Counterweighted Handle": return "Synergy: fast first-volley pressure for Serve and Volley (+net pressure)."
			if racquet_type == "Lead Tape 12": return "Synergy: Serve and Volley knifes through the first strike (+serve/net pressure)."
		&"master":
			if racquet_type == "Head-Light Control": return "Synergy: Master extracts exact placement from head-light mold (+control acc/pressure)."
			if racquet_type == "Lead Tape 3 and 9": return "Synergy: Master uses side-balanced tape for precision (+control acc, +Guard)."
		&"alcaraz":
			if racquet_type == "Extra-Long Lever": return "Synergy: amplifies Alcaraz burst and spin (+serve/topspin/net pressure)."
			if racquet_type == "Lead Tape 12": return "Synergy: explosive lift to the Alcaraz build (+serve/power/topspin pressure)."
	return ""

func _standard_starting_deck(base_cards: PackedStringArray, single_cards: PackedStringArray = PackedStringArray()) -> PackedStringArray:
	var expanded := PackedStringArray()
	for _pass in range(2):
		for card_id in base_cards:
			expanded.append(card_id)
	# single_cards are modifier/equipment cards that should only appear once in the deck
	for card_id in single_cards:
		expanded.append(card_id)
	return expanded
