class_name CharacterModelDatabase
extends RefCounted

const CharacterModelDef = preload("res://scripts/core/character_model_def.gd")

var _models: Dictionary = {}

func _init() -> void:
	_register_models()

func get_model(class_id: StringName) -> CharacterModelDef:
	return _models.get(class_id)

func get_all_models() -> Array[CharacterModelDef]:
	var models: Array[CharacterModelDef] = []
	for model in _models.values():
		models.append(model)
	return models

func _add_model(model: CharacterModelDef) -> void:
	_models[model.class_id] = model

func _register_models() -> void:
	_add_model(CharacterModelDef.new(
		&"novice",
		"The Greenhorn Satyr",
		PackedStringArray(["Coco Gauff"]),
		"Fey satyr academy hopeful",
		"Lean sprinter frame, spring-loaded legs, oversized racquet, and small antlers that read youthful rather than regal.",
		"A stitched training jacket over light leather pads, court-band wraps, and a belt of spare grip tape and glowing tennis balls.",
		"A beginner's racquet reworked into a living ash-wood frame with vine-string runes and soft fey glow at the throat.",
		PackedStringArray(["moss green", "cream", "oak brown", "sunlit yellow"]),
		PackedStringArray(["small antlers", "satyr legs", "fey eyes"]),
		PackedStringArray(["bouncy split-step idle", "eager two-hand backhand prep", "quick hop on card draw"]),
		"3D character model turnaround of a tennis prodigy inspired by Coco Gauff, fused with a young satyr from a high-fantasy RPG world. Athletic teenage silhouette, light leather training gear, small antlers, ash-wood racquet with runic strings, grounded realistic materials, front side back views, neutral pose."
	))
	_add_model(CharacterModelDef.new(
		&"pusher",
		"The Mire Marathoner",
		PackedStringArray(["Caroline Wozniacki", "Gilles Simon"]),
		"Bog-born turtlefolk endurance hunter",
		"Low center of gravity, shell-backed shoulders, long defensive reach, and a relentless cross-court runner profile.",
		"Mud-stained scale mail under layered court cloth, hydration flasks, ankle wraps, and a shell cape worn like a weathered mantle.",
		"A wide-body defensive racquet with a hooked guard, built to absorb pace and redirect it with ugly angles.",
		PackedStringArray(["swamp green", "stone gray", "deep teal", "aged bronze"]),
		PackedStringArray(["partial shell carapace", "scaled forearms", "marsh lantern markings"]),
		PackedStringArray(["slow stalking idle", "compact reset swings", "shoulder roll after gaining Guard"]),
		"3D character model turnaround of a tennis grinder inspired by Caroline Wozniacki and Gilles Simon, fused with a turtlefolk marsh hunter. Endurance-focused silhouette, shell-backed shoulders, layered swamp gear, defensive racquet shield, realistic dark fantasy RPG materials, front side back views, neutral pose."
	))
	_add_model(CharacterModelDef.new(
		&"slicer",
		"The Raven-Cut Duelist",
		PackedStringArray(["Ash Barty", "Steffi Graf"]),
		"Raven harpy court duelist",
		"Compact torso, sharp shoulders, feathered cape silhouette, and one arm always slightly lowered as if carving under the ball.",
		"Elegant fitted leathers, feather trims, asymmetrical shoulder guard, and a half-cloak that breaks into layered black plumage.",
		"A thin obsidian racquet with a blade-like rim and cross-strings shaped like talon tracery.",
		PackedStringArray(["midnight black", "silver", "burgundy", "ice white"]),
		PackedStringArray(["feathered pauldrons", "talon gauntlet", "avian eyes"]),
		PackedStringArray(["knife-like slice follow-through", "gliding sidestep idle", "head tilt before debuff attacks"]),
		"3D character model turnaround of a technical tennis artist inspired by Ash Barty and Steffi Graf, fused with a raven harpy duelist. Sleek athletic build, elegant dark leathers, feather cloak, obsidian racquet blade, high-fantasy CRPG realism, front side back views, neutral pose."
	))
	_add_model(CharacterModelDef.new(
		&"power",
		"The Stormhorn Breaker",
		PackedStringArray(["Serena Williams", "Aryna Sabalenka"]),
		"Storm minotaur champion",
		"Broad chest, heavy planted stance, horned silhouette, and explosive shoulder line that sells overwhelming contact power.",
		"Reinforced leather harness, plated thigh guards, rune-etched wrist wraps, and a champion's mantle split for movement.",
		"A brutal hammer-racquet hybrid with thick strings, storm charms, and impact scars along the frame.",
		PackedStringArray(["storm blue", "charcoal", "gold", "electric white"]),
		PackedStringArray(["forward-curving horns", "thunder scars", "glowing breath in exertion"]),
		PackedStringArray(["coiled serve idle", "violent shoulder-driven forehand", "screen-shake stomp on big hits"]),
		"3D character model turnaround of a dominant power server inspired by Serena Williams and Aryna Sabalenka, fused with a storm minotaur. Powerful athletic frame, plated leather armor, horned headpiece, racquet maul with rune strings, grounded high-fantasy RPG realism, front side back views, neutral pose."
	))
	_add_model(CharacterModelDef.new(
		&"all_arounder",
		"The Mooncourt Morph",
		PackedStringArray(["Roger Federer", "Iga Swiatek"]),
		"Moon elf displacer-beast hybrid",
		"Balanced elegant silhouette with long reach, floating cape tails, and subtle duplicate after-images when in motion.",
		"Court nobility coat over fitted dueling gear, moon-thread sash, lightweight armor panels, and ceremonial tournament pins.",
		"An adaptive silver racquet whose frame shifts shape slightly depending on the shot family being used.",
		PackedStringArray(["moon silver", "navy", "soft violet", "white gold"]),
		PackedStringArray(["catlike tail", "faint second-image shimmer", "elongated ears"]),
		PackedStringArray(["calm upright idle", "effortless one-step transitions", "clean follow-through with trailing after-image"]),
		"3D character model turnaround of an all-court tennis stylist inspired by Roger Federer and Iga Swiatek, fused with a moon elf and displacer beast. Graceful athletic silhouette, layered noble gear, adaptive silver racquet, subtle after-image magic, realistic fantasy RPG materials, front side back views, neutral pose."
	))
	_add_model(CharacterModelDef.new(
		&"baseliner",
		"The Red Clay Salamander",
		PackedStringArray(["Rafael Nadal"]),
		"Fire salamander clay warlord",
		"Muscular runner silhouette, wrapped knees and forearms, fierce forward lean, and a coiling torso built for heavy topspin.",
		"Dusty clay-colored wraps, sleeveless battle tunic, charred leather belt pieces, and ritual cords tied around the biceps.",
		"A flame-tempered racquet with scorched strings and molten edge markings that glow hotter during long rallies.",
		PackedStringArray(["clay red", "ember orange", "burnt umber", "black"]),
		PackedStringArray(["scaled shoulders", "heat haze aura", "ember freckles"]),
		PackedStringArray(["ritual bounce idle", "whip-heavy topspin finish", "feral sprint between shots"]),
		"3D character model turnaround of a clay-court tennis warrior inspired by Rafael Nadal, fused with a fire salamander champion. Intensely athletic build, wrapped arms and knees, scorched clay gear, molten racquet accents, dark high-fantasy RPG realism, front side back views, neutral pose."
	))
	_add_model(CharacterModelDef.new(
		&"serve_and_volley",
		"The Gryphon Poacher",
		PackedStringArray(["Martina Navratilova", "Stefan Edberg"]),
		"Gryphon-blooded sky knight",
		"Narrow waist, strong shoulders, wing-like cape spread, and a forward-balanced stance that always looks ready to close the net.",
		"Light knight armor over an agile court bodysuit, feathered mantle, vambraces built for reflex volleys, and polished greaves.",
		"A spear-straight racquet with talon motifs, flight feathers tied to the throat, and a hooked grip pommel.",
		PackedStringArray(["ivory", "navy", "gold", "falcon brown"]),
		PackedStringArray(["feather crest", "partial wing mantle", "predator pupils"]),
		PackedStringArray(["knife-step approach idle", "stabbing volley motion", "quick airborne split-step"]),
		"3D character model turnaround of a serve-and-volley tennis attacker inspired by Martina Navratilova and Stefan Edberg, fused with a gryphon knight. Fast athletic silhouette, feathered mantle, light plate armor, talon-themed racquet, realistic high-fantasy CRPG materials, front side back views, neutral pose."
	))
	_add_model(CharacterModelDef.new(
		&"master",
		"The Ivory Court Savant",
		PackedStringArray(["Novak Djokovic", "Martina Hingis"]),
		"Ancient dragon-elf tactician",
		"Tall composed silhouette, high collar, quiet hands, and an aura of total balance that reads dangerous without bulk.",
		"Scholar-warrior robes over fitted armor, dragonbone filigree, fingerless grip gloves, and a long tactical mantle.",
		"An ivory racquet with precise geometric cutouts, dragonbone inlays, and an almost ceremonial symmetry.",
		PackedStringArray(["ivory", "forest green", "obsidian", "pale gold"]),
		PackedStringArray(["fine facial scales", "eldritch gaze", "long pointed ears"]),
		PackedStringArray(["stillness-heavy idle", "surgical redirection swing", "minimal movement recovery pose"]),
		"3D character model turnaround of a cerebral tennis master inspired by Novak Djokovic and Martina Hingis, fused with an ancient dragon-elf strategist. Lean elite-athlete silhouette, scholar-warrior armor, ivory racquet with geometric cutouts, grounded fantasy RPG realism, front side back views, neutral pose."
	))
	_add_model(CharacterModelDef.new(
		&"alcaraz",
		"The Sunfang Prodigy",
		PackedStringArray(["Carlos Alcaraz"]),
		"Solar lion-fey champion",
		"Compact explosive build, loose predatory shoulders, bright mane silhouette, and kinetic posture that feels one beat ahead of the court.",
		"Layered prince-of-the-court leathers, sun-cloth sash, athletic shorts over plated leggings, and trophy charms woven into the gear.",
		"A radiant gold racquet with clawed supports, solar filaments through the strings, and bright enamel in the handle wrap.",
		PackedStringArray(["sun gold", "crimson", "warm white", "sand"]),
		PackedStringArray(["mane-like hair crest", "feline canines", "light-spill footsteps"]),
		PackedStringArray(["restless bounce idle", "elastic full-body shot chain", "celebratory fist-clench after burst combos"]),
		"3D character model turnaround of a tennis prodigy inspired by Carlos Alcaraz, fused with a solar lion-fey champion. Compact explosive athlete, radiant layered leathers, golden racquet with claw supports, bright heroic fantasy RPG realism, front side back views, neutral pose."
	))
