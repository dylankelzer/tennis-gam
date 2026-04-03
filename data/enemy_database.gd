class_name EnemyDatabase
extends RefCounted

const EnemyDef = preload("res://scripts/core/enemy_def.gd")
const ENEMY_LIBRARY_PATH := "res://data/enemies/enemy_library.tres"

var _enemies: Dictionary = {}

func _init() -> void:
	if not _load_resource_library():
		_register_enemies()

func get_enemy(enemy_id: StringName) -> EnemyDef:
	return _enemies.get(enemy_id)

func get_pool(act: int, category: String) -> Array[EnemyDef]:
	var pool: Array[EnemyDef] = []
	for enemy in _enemies.values():
		if enemy.act == act and enemy.category == category:
			pool.append(enemy)
	pool.sort_custom(func(a: EnemyDef, b: EnemyDef) -> bool:
		return a.name < b.name
	)
	return pool

func get_all_enemies() -> Array[EnemyDef]:
	var enemies: Array[EnemyDef] = []
	for enemy in _enemies.values():
		enemies.append(enemy)
	enemies.sort_custom(func(a: EnemyDef, b: EnemyDef) -> bool:
		if a.act == b.act:
			return a.name < b.name
		return a.act < b.act
	)
	return enemies

func _add_enemy(enemy: EnemyDef) -> void:
	_enemies[enemy.id] = enemy

func _load_resource_library() -> bool:
	_enemies.clear()
	if not ResourceLoader.exists(ENEMY_LIBRARY_PATH):
		return false
	var library = load(ENEMY_LIBRARY_PATH)
	if library == null:
		return false
	var resources: Array = Array(library.enemies)
	for resource in resources:
		var enemy := _resource_to_enemy_def(resource)
		if enemy == null:
			continue
		_add_enemy(enemy)
	return not _enemies.is_empty()

func _resource_to_enemy_def(resource) -> EnemyDef:
	if resource == null:
		return null
	return EnemyDef.new(
		StringName(resource.id),
		resource.name,
		int(resource.act),
		resource.category,
		resource.style,
		resource.summary,
		int(resource.max_health),
		Array(resource.intent_cycle).duplicate(true),
		PackedStringArray(resource.keywords)
	)

func _register_enemies() -> void:
	_add_enemy(EnemyDef.new(&"counterpuncher_apprentice", "Counterpuncher Apprentice", 1, "regular", "Human rival", "Blocks efficiently and punishes overcommitting.", 42, [{"name": "Dig In", "guard": 8}, {"name": "Counter Line", "damage": 7, "bonus_if_player_attacked": 4}], PackedStringArray(["guard", "counter", "topspin_weak", "power_weak", "forehand_weak", "slice_resist"])))
	_add_enemy(EnemyDef.new(&"moonball_goblin", "Moonball Goblin", 1, "regular", "Monster", "Floats looping balls that add Fatigue when unanswered.", 38, [{"name": "High Arc", "damage": 5, "fatigue": 1}, {"name": "Backpedal", "guard": 6}], PackedStringArray(["fatigue", "tempo", "net_weak", "volley_weak", "smash_weak"])))
	_add_enemy(EnemyDef.new(&"junkball_trickster", "Junkball Trickster", 1, "regular", "Human rival", "Alternates soft balls and awkward spins to scramble your hand quality.", 40, [{"name": "No Pace", "damage": 4, "pressure": 1}, {"name": "Short Angle", "open_court": 1}], PackedStringArray(["pressure", "control", "topspin_weak", "power_weak", "forehand_weak", "net_weak"])))
	_add_enemy(EnemyDef.new(&"ball_machine_imp", "Ball-Machine Imp", 1, "regular", "Monster", "Pelts the player with mechanical rhythm until broken.", 44, [{"name": "Rapid Feed", "damage": 4, "hits": 3}, {"name": "Overheat", "self_vulnerable": 1, "damage": 10}], PackedStringArray(["multi_hit", "machine", "slice_weak", "power_weak", "serve_resist"])))
	_add_enemy(EnemyDef.new(&"qualifier_bombardier", "Qualifier Bombardier", 1, "regular", "Human rival", "A ladder-climbing serve cannon that flattens weak returns and respects clean returners with a safer plus-one pattern.", 41, [{"name": "Body Jam Serve", "damage": 8, "pressure": 1, "serve_pattern": "jam"}, {"name": "Kick Probe", "damage": 6, "guard": 4, "momentum": 1, "serve_pattern": "probe"}, {"name": "T-Serve Rush", "damage": 9, "open_court": 1, "serve_pattern": "approach"}], PackedStringArray(["serve", "tempo", "return_weak", "net_weak", "forehand_weak", "slice_resist"])))
	_add_enemy(EnemyDef.new(&"doubles_poacher_duo", "Doubles Poacher Duo", 1, "elite", "Human rivals", "A coordinated pair that spikes damage when you leave the middle exposed.", 72, [{"name": "Intercept", "damage": 8, "pressure": 2}, {"name": "Crash Middle", "damage": 14}], PackedStringArray(["elite", "pair", "lob_weak", "down_the_line_weak", "slice_resist"])))
	_add_enemy(EnemyDef.new(&"clay_troll_grinder", "Clay Troll Grinder", 1, "elite", "Monster", "Stacks mud-like Fatigue and drags fights into the deep end.", 78, [{"name": "Heavy Bounce", "damage": 9, "fatigue": 1}, {"name": "Clay Shield", "guard": 14}], PackedStringArray(["elite", "fatigue", "drop_weak", "net_weak", "serve_resist", "slice_resist"])))
	_add_enemy(EnemyDef.new(&"melbourne_mirage", "Melbourne Mirage", 1, "boss", "Australian Open boss", "The first major final: a fast-court phantom that redlines early and feeds on crowd energy.", 186, [{"name": "Heat Check", "damage": 9, "momentum": 1}, {"name": "Bluecourt Redirect", "damage": 15, "open_court": 2}, {"name": "Night Session Finish", "damage": 23}], PackedStringArray(["boss", "rally", "hardcourt", "return_weak", "power_weak", "net_weak", "slice_resist"])))

	_add_enemy(EnemyDef.new(&"topspin_brute", "Topspin Brute", 2, "regular", "Human rival", "Heavy-spin forehands snowball if left unchecked.", 60, [{"name": "Heavy Forehand", "damage": 10, "spin": 2}, {"name": "Push Back", "damage": 7, "pressure": 1}], PackedStringArray(["spin", "strength", "slice_weak", "control_weak", "forehand_weak"])))
	_add_enemy(EnemyDef.new(&"racquet_wraith", "Racquet Wraith", 2, "regular", "Monster", "A ghostly attacker that phases between Guard and burst.", 58, [{"name": "Fade Out", "guard": 10}, {"name": "Phantom Swipe", "damage": 13}], PackedStringArray(["phase", "monster", "power_weak"])))
	_add_enemy(EnemyDef.new(&"net_bandit", "Net Bandit", 2, "regular", "Human rival", "Rushes forward and punishes slow setups.", 56, [{"name": "Sneak In", "guard": 5, "momentum": 1}, {"name": "Sharp Volley", "damage": 12}], PackedStringArray(["tempo", "net", "lob_weak", "down_the_line_weak", "volley_resist"])))
	_add_enemy(EnemyDef.new(&"servebot_hound", "Servebot Hound", 2, "regular", "Monster", "A four-legged server that threatens ace bursts every few turns.", 62, [{"name": "Laser Toss", "damage": 6, "guard": 3, "momentum": 1, "serve_pattern": "probe"}, {"name": "Service Burst", "damage": 16, "serve_pattern": "punish"}], PackedStringArray(["serve", "machine", "return_weak", "control_weak"])))
	_add_enemy(EnemyDef.new(&"lob_lobster", "Lob Lobster", 2, "elite", "Monster", "Uses looping lobs and clamps down when you over-extend.", 94, [{"name": "Sky Clamp", "damage": 10, "open_court": 2}, {"name": "Shell Up", "guard": 16}], PackedStringArray(["elite", "control", "drop_weak", "smash_weak"])))
	_add_enemy(EnemyDef.new(&"backboard_ogre", "Backboard Ogre", 2, "elite", "Monster", "Reflects basic attacks and grows angrier when hit repeatedly.", 102, [{"name": "Wall Back", "guard": 12, "thorns": 2}, {"name": "Crush Return", "damage": 18}], PackedStringArray(["elite", "counter", "drop_weak", "topspin_weak"])))
	_add_enemy(EnemyDef.new(&"terre_battue_tyrant", "Terre Battue Tyrant", 2, "boss", "Roland-Garros boss", "A clay monarch that drags out rallies until every footstep feels heavy.", 230, [{"name": "Heavy Kicker", "damage": 10, "spin": 2}, {"name": "Red Dust Drag", "pressure": 2, "fatigue": 1}, {"name": "Chatrier Crush", "damage": 25}], PackedStringArray(["boss", "summoner", "clay", "drop_weak", "net_weak", "power_weak", "serve_resist", "slice_resist"])))

	_add_enemy(EnemyDef.new(&"mirror_rival", "Mirror Rival", 3, "regular", "Human rival", "Copies your tempo and punishes predictable sequencing.", 82, [{"name": "Read Pattern", "pressure": 1}, {"name": "Mirror Strike", "damage": 15, "bonus_if_same_tag": 6}], PackedStringArray(["mindgame", "control", "tempo_resist", "slice_resist", "control_resist", "forehand_weak"])))
	_add_enemy(EnemyDef.new(&"volley_vampire", "Volley Vampire", 3, "regular", "Monster", "Steals life whenever it lands clean net contact.", 84, [{"name": "Drain Volley", "damage": 11, "heal": 6}, {"name": "Bat Retreat", "guard": 9}], PackedStringArray(["drain", "net", "lob_weak", "down_the_line_weak"])))
	_add_enemy(EnemyDef.new(&"ace_chimera", "Ace Chimera", 3, "regular", "Monster", "Shifts between serve patterns with unpredictable burst ceilings.", 88, [{"name": "Kick Head", "damage": 9, "pressure": 1, "serve_pattern": "probe"}, {"name": "Flat Head", "damage": 18, "serve_pattern": "punish"}], PackedStringArray(["serve", "burst", "return_weak"])))
	_add_enemy(EnemyDef.new(&"tempo_reaper", "Tempo Reaper", 3, "regular", "Monster", "Cuts down long turns by taxing extra card plays.", 86, [{"name": "Tempo Tax", "fatigue": 1}, {"name": "Cut Point", "damage": 17}], PackedStringArray(["tax", "tempo", "slice_weak", "power_weak"])))
	_add_enemy(EnemyDef.new(&"ad_court_executor", "Ad Court Executor", 3, "elite", "Human rival", "A precision server that widens weak returns but shifts to plus-one patterns against prepared returners.", 128, [{"name": "Wide Slider", "damage": 15, "open_court": 1, "serve_pattern": "punish"}, {"name": "Kick Plus-One", "damage": 10, "guard": 8, "momentum": 1, "serve_pattern": "probe"}, {"name": "First Volley Seal", "damage": 22, "serve_pattern": "finish"}], PackedStringArray(["elite", "serve", "net", "return_weak", "lob_weak", "slice_resist"])))
	_add_enemy(EnemyDef.new(&"ball_machine_hydra", "Ball-Machine Hydra", 3, "elite", "Monster", "A multi-headed launcher that floods the rally with projectiles.", 132, [{"name": "Triple Feed", "damage": 6, "hits": 3}, {"name": "Overclock", "momentum": 2}, {"name": "Hydra Burst", "damage": 26}], PackedStringArray(["elite", "multi_hit", "slice_weak", "control_weak"])))
	_add_enemy(EnemyDef.new(&"grandstand_gargoyle", "Grandstand Gargoyle", 3, "elite", "Monster", "Perches above the court and punishes weak defenses.", 126, [{"name": "Stone Toss", "damage": 14}, {"name": "Roost", "guard": 18}, {"name": "Dive Finish", "damage": 22, "bonus_if_player_guard_low": 8}], PackedStringArray(["elite", "pressure", "drop_weak", "power_weak"])))
	_add_enemy(EnemyDef.new(&"centre_court_specter", "Centre Court Specter", 3, "boss", "Wimbledon boss", "A grass-court apparition that serves huge and closes at the net before you can reset.", 286, [{"name": "White-Line Serve", "damage": 18, "pressure": 1, "serve_pattern": "punish"}, {"name": "Royal Approach", "guard": 10, "momentum": 1, "serve_pattern": "approach"}, {"name": "Champions' Volley", "damage": 31, "serve_pattern": "finish"}], PackedStringArray(["boss", "grass", "net", "return_weak", "lob_weak", "slice_resist"])))

	_add_enemy(EnemyDef.new(&"stadium_slugger", "Stadium Slugger", 4, "regular", "Human rival", "Thrives under loud conditions and takes every ball early off the bounce.", 98, [{"name": "Crowd Surge", "damage": 14, "pressure": 1}, {"name": "Step-In Strike", "damage": 18}, {"name": "Weight Transfer", "guard": 8, "momentum": 1}], PackedStringArray(["power", "tempo", "slice_resist", "control_weak", "forehand_weak"])))
	_add_enemy(EnemyDef.new(&"neon_howler", "Neon Howler", 4, "regular", "Monster", "A fluorescent courtside beast that rattles focus before unloading on short balls.", 96, [{"name": "Feedback Screech", "pressure": 2}, {"name": "Flash Snap", "damage": 19, "open_court": 1}, {"name": "Static Pulse", "fatigue": 1, "pressure": 1}], PackedStringArray(["pressure", "monster", "power_weak"])))
	_add_enemy(EnemyDef.new(&"subway_scrambler", "Subway Scrambler", 4, "regular", "Human rival", "Converts defense into offense in a single stride and never stops moving.", 100, [{"name": "Track Down", "guard": 8, "momentum": 1}, {"name": "Passing Rip", "damage": 17, "bonus_if_player_guard_low": 5}, {"name": "Cut Off Angle", "damage": 11, "open_court": 1}], PackedStringArray(["counter", "footwork", "topspin_weak"])))
	_add_enemy(EnemyDef.new(&"flashbulb_fiend", "Flashbulb Fiend", 4, "regular", "Monster", "Lives for the moment the lights pop and the point turns frantic.", 102, [{"name": "Strobe Feed", "damage": 7, "hits": 3}, {"name": "Blindside Burst", "damage": 21}, {"name": "Pop and Drive", "damage": 10, "momentum": 1}], PackedStringArray(["multi_hit", "burst", "control_weak", "power_weak"])))
	_add_enemy(EnemyDef.new(&"night_session_duo", "Night Session Duo", 4, "elite", "Human rivals", "A seeded pair that rides momentum swings and punishes weak second turns.", 152, [{"name": "Spotlight Pounce", "damage": 14, "pressure": 2}, {"name": "Midnight Wall", "guard": 16}, {"name": "Break Point Riot", "damage": 24}], PackedStringArray(["elite", "pair", "tempo", "lob_weak", "down_the_line_weak", "slice_resist"])))
	_add_enemy(EnemyDef.new(&"scoreboard_colossus", "Scoreboard Colossus", 4, "elite", "Monster", "A digital giant that escalates the pace every time it smells a finish.", 160, [{"name": "Time Violation", "fatigue": 2}, {"name": "Pixel Shield", "guard": 18}, {"name": "Statline Slam", "damage": 27, "bonus_if_player_guard_low": 8}], PackedStringArray(["elite", "pressure", "machine", "slice_weak", "control_weak"])))
	_add_enemy(EnemyDef.new(&"arthur_ashe_umbra", "Arthur Ashe Umbra", 4, "boss", "US Open boss", "The loudest, hardest final in the run: a champion-shadow that hits through noise, nerves, and fatigue.", 340, [{"name": "Prime Time Serve", "damage": 20, "pressure": 2, "serve_pattern": "punish"}, {"name": "Concrete Grind", "fatigue": 2, "open_court": 1}, {"name": "Tiebreak Torrent", "damage": 30, "hits": 2, "serve_pattern": "probe"}, {"name": "Midnight Crown", "damage": 42, "serve_pattern": "finish"}], PackedStringArray(["boss", "final", "hardcourt", "power", "return_weak", "power_weak", "slice_resist"])))
