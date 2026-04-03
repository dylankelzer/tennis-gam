extends SceneTree

const CardContentResourceScript = preload("res://scripts/data/resources/card_content_resource.gd")
const CardDatabaseScript = preload("res://scripts/data/card_database.gd")
const CardLibraryResourceScript = preload("res://scripts/data/resources/card_library_resource.gd")
const EnemyContentResourceScript = preload("res://scripts/data/resources/enemy_content_resource.gd")
const EnemyDatabaseScript = preload("res://scripts/data/enemy_database.gd")
const EnemyLibraryResourceScript = preload("res://scripts/data/resources/enemy_library_resource.gd")

const CARD_LIBRARY_PATH := "res://data/cards/card_library.tres"
const ENEMY_LIBRARY_PATH := "res://data/enemies/enemy_library.tres"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/cards")
	DirAccess.make_dir_recursive_absolute("res://data/enemies")

	var card_database = CardDatabaseScript.new()
	var enemy_database = EnemyDatabaseScript.new()

	var card_library := CardLibraryResourceScript.new()
	card_library.cards = _build_card_entries(card_database)
	var enemy_library := EnemyLibraryResourceScript.new()
	enemy_library.enemies = _build_enemy_entries(enemy_database)

	var card_save := ResourceSaver.save(card_library, CARD_LIBRARY_PATH)
	if card_save != OK:
		push_error("Failed to save card library: %s" % error_string(card_save))
		quit(1)
		return
	var enemy_save := ResourceSaver.save(enemy_library, ENEMY_LIBRARY_PATH)
	if enemy_save != OK:
		push_error("Failed to save enemy library: %s" % error_string(enemy_save))
		quit(1)
		return

	print("CONTENT RESOURCE GENERATION PASS")
	print({
		"cards": card_library.cards.size(),
		"enemies": enemy_library.enemies.size(),
		"card_library": CARD_LIBRARY_PATH,
		"enemy_library": ENEMY_LIBRARY_PATH,
	})
	quit(0)

func _build_card_entries(card_database) -> Array:
	var entries: Array = []
	for card in card_database.get_all_cards(true, true):
		var entry := CardContentResourceScript.new()
		entry.id = String(card.id)
		entry.name = card.name
		entry.cost = card.cost
		entry.description = card.description
		entry.tags = PackedStringArray(card.tags)
		entry.effects = Dictionary(card.effects).duplicate(true)
		entry.upgrade_to = String(card.upgrade_to)
		entry.category = card.category
		entry.shot_family = card.shot_family
		entry.slot_roles = PackedStringArray(card.slot_roles)
		entry.requires = Dictionary(card.requires).duplicate(true)
		entries.append(entry)
	entries.sort_custom(func(a, b) -> bool:
		return a.id < b.id
	)
	return entries

func _build_enemy_entries(enemy_database) -> Array:
	var entries: Array = []
	for enemy in enemy_database.get_all_enemies():
		var entry := EnemyContentResourceScript.new()
		entry.id = String(enemy.id)
		entry.name = enemy.name
		entry.act = enemy.act
		entry.category = enemy.category
		entry.style = enemy.style
		entry.summary = enemy.summary
		entry.max_health = enemy.max_health
		entry.intent_cycle = Array(enemy.intent_cycle).duplicate(true)
		entry.keywords = PackedStringArray(enemy.keywords)
		entries.append(entry)
	entries.sort_custom(func(a, b) -> bool:
		return a.id < b.id
	)
	return entries
