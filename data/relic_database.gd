class_name RelicDatabase
extends RefCounted

const RelicDef = preload("res://scripts/core/relic_def.gd")

var _relics: Dictionary = {}

func _init() -> void:
	_register_relics()

func get_relic(relic_id: StringName) -> RelicDef:
	return _relics.get(relic_id)

func get_all_relics() -> Array[RelicDef]:
	var relics: Array[RelicDef] = []
	for relic in _relics.values():
		relics.append(relic)
	relics.sort_custom(func(a: RelicDef, b: RelicDef) -> bool:
		return a.name < b.name
	)
	return relics

func get_reward_pool(allowed_rarities: PackedStringArray = PackedStringArray()) -> Array[RelicDef]:
	var relics: Array[RelicDef] = []
	for relic in _relics.values():
		if allowed_rarities.is_empty() or allowed_rarities.has(relic.rarity):
			relics.append(relic)
	relics.sort_custom(func(a: RelicDef, b: RelicDef) -> bool:
		return a.name < b.name
	)
	return relics

func _add_relic(relic: RelicDef) -> void:
	_relics[relic.id] = relic

func _register_relics() -> void:
	_add_relic(RelicDef.new(&"lead_tape", "Lead Tape", "common", "+5% pressure on Power-tag shots.", {"power_pressure_bonus": 0.05}))
	_add_relic(RelicDef.new(&"dampener", "Dampener", "common", "First unforced error each game loses 10 less Condition.", {"first_error_condition_reduction": 10}))
	_add_relic(RelicDef.new(&"polyester_strings", "Polyester Strings", "common", "Spin-tag shots apply +1 extra Spin.", {"extra_spin": 1}))
	_add_relic(RelicDef.new(&"fresh_grips", "Fresh Grips", "common", "+1 Stamina on the opening point of each game.", {"opening_point_stamina": 1}))
	_add_relic(RelicDef.new(&"wristband", "Wristband", "common", "Heal 2 Condition after each encounter.", {"heal_after_encounter": 2}))
	_add_relic(RelicDef.new(&"compression_sleeve", "Compression Sleeve", "common", "Fatigue decays 1 extra step between points.", {"extra_fatigue_decay": 1}))
	_add_relic(RelicDef.new(&"new_balls", "New Balls", "common", "First serve each point gains +5% accuracy.", {"first_serve_accuracy": 0.05}))
	_add_relic(RelicDef.new(&"court_shoes", "Court Shoes", "common", "Footwork cards gain +4 Guard.", {"footwork_guard_bonus": 4}))
	_add_relic(RelicDef.new(&"overgrip", "Overgrip", "common", "+1 extra draw on the first turn of each point.", {"opening_draw": 1}))
	_add_relic(RelicDef.new(&"practice_cones", "Practice Cones", "common", "Card rewards show one extra option.", {"extra_card_reward_choice": 1}))
	_add_relic(RelicDef.new(&"serve_scout_notes", "Serve Scout Notes", "common", "On return points, start with Focus 1 and Guard 2.", {"return_point_focus": 1, "return_point_guard": 2}))
	_add_relic(RelicDef.new(&"hawk_eye_token", "Hawk-Eye Token", "uncommon", "Once per encounter, reroll an accuracy check.", {}))
	_add_relic(RelicDef.new(&"string_saver", "String Saver", "uncommon", "Slice shots also prepare you for the next exchange.", {"slice_focus": 1}))
	_add_relic(RelicDef.new(&"headband", "Headband", "uncommon", "After you play 3 cards in a turn, gain 1 Focus.", {"focus_after_three_cards": 1}))
	_add_relic(RelicDef.new(&"split_step_timer", "Split-Step Timer", "uncommon", "Start each point with a better first read.", {"opening_guard": 3}))
	_add_relic(RelicDef.new(&"return_coach", "Return Coach", "uncommon", "Return cards gain +4 pressure and +6% accuracy on return points.", {"return_pressure_bonus": 4, "return_accuracy_bonus": 0.06}))
	_add_relic(RelicDef.new(&"training_ladder", "Training Ladder", "uncommon", "Rest sites also sharpen your deck. Upgrade system pending.", {}))
	_add_relic(RelicDef.new(&"clay_specialist", "Clay Specialist", "uncommon", "Topspin pressure is stronger at Roland-Garros.", {"act_two_topspin_bonus": 4}))
	_add_relic(RelicDef.new(&"grass_specialist", "Grass Specialist", "uncommon", "Net shots gain +10% accuracy and +10 pressure.", {"net_accuracy_bonus": 0.10, "net_pressure_bonus": 10}))
	_add_relic(RelicDef.new(&"small_sweet_spot", "Small Sweet Spot", "uncommon", "+1 max Stamina, but -5% shot accuracy.", {"max_stamina_bonus": 1, "global_accuracy_bonus": -0.05}))
	_add_relic(RelicDef.new(&"big_sweet_spot", "Big Sweet Spot", "uncommon", "+10% shot accuracy.", {"global_accuracy_bonus": 0.10}))
	_add_relic(RelicDef.new(&"rally_counter", "Rally Counter", "uncommon", "After 6 exchanges in a point, start the next point with +1 Stamina.", {"long_rally_bonus_stamina": 1}))
	_add_relic(RelicDef.new(&"champions_towel", "Champion's Towel", "rare", "Between games in boss fights, heal 15 Condition.", {"boss_game_heal": 15}))
	_add_relic(RelicDef.new(&"titanium_frame", "Titanium Frame", "rare", "Power shots ignore LowBall penalties.", {"power_ignore_lowball": true}))
	_add_relic(RelicDef.new(&"smart_targeting", "Smart Targeting", "rare", "Your first line-breaker each point is stronger.", {"signature_pressure_bonus": 6}))
	_add_relic(RelicDef.new(&"serve_clock", "Serve Clock", "rare", "Serve cards cost 1 less Stamina.", {"serve_cost_reduction": 1}))
	_add_relic(RelicDef.new(&"chip_charge_playbook", "Chip-Charge Playbook", "rare", "After you play a return card, gain 4 Guard and Momentum 1.", {"return_guard_bonus": 4, "return_momentum_bonus": 1}))
	_add_relic(RelicDef.new(&"net_cord_charm", "Net Cord Charm", "rare", "Once per encounter, a missed touch shot gets a second chance.", {}))
	_add_relic(RelicDef.new(&"mental_coach", "Mental Coach", "rare", "At Deuce, gain Focus 1 and Momentum 1 once per game.", {"deuce_focus": 1, "deuce_momentum": 1}))
	_add_relic(RelicDef.new(&"physio_kit", "Physio Kit", "rare", "Heal 4 Condition after each boss or elite encounter.", {"heal_after_elite": 4, "heal_after_boss": 4}))
	_add_relic(RelicDef.new(&"lucky_coin_toss", "Lucky Coin Toss", "rare", "You always serve first and gain +1 Stamina on opening points.", {"player_serves_first": true, "opening_point_stamina": 1}))
	_add_relic(RelicDef.new(&"signature_racquet", "Signature Racquet", "boss", "Signature-tag shots gain +4 pressure.", {"signature_pressure_bonus": 4}))
	_add_relic(RelicDef.new(&"trophy_of_the_tour", "Trophy of the Tour", "boss", "Boss relic rewards show one extra option.", {"extra_boss_relic_choice": 1}))
