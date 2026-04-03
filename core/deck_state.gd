class_name DeckState
extends RefCounted

const CardInstance = preload("res://scripts/core/card_instance.gd")

var draw_pile: Array[CardInstance] = []
var discard_pile: Array[CardInstance] = []
var exhaust_pile: Array[CardInstance] = []
var _next_uid: int = 1

func _init(card_ids: PackedStringArray = PackedStringArray()) -> void:
	for card_id in card_ids:
		draw_pile.append(CardInstance.new(_next_uid, card_id))
		_next_uid += 1

func shuffle(rng: RandomNumberGenerator) -> void:
	for index in range(draw_pile.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var tmp: CardInstance = draw_pile[index]
		draw_pile[index] = draw_pile[swap_index]
		draw_pile[swap_index] = tmp

func shuffle_discard_into_draw(rng: RandomNumberGenerator) -> void:
	for card in discard_pile:
		draw_pile.append(card)
	discard_pile.clear()
	shuffle(rng)

func draw(count: int, rng: RandomNumberGenerator) -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	for _index in range(count):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			shuffle_discard_into_draw(rng)
		cards.append(draw_pile.pop_back())
	return cards

func draw_matching(rng: RandomNumberGenerator, predicate: Callable) -> CardInstance:
	var held_cards: Array[CardInstance] = []
	while true:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				break
			shuffle_discard_into_draw(rng)
		var next_card: CardInstance = draw_pile.pop_back()
		if predicate.call(next_card):
			for index in range(held_cards.size() - 1, -1, -1):
				draw_pile.append(held_cards[index])
			return next_card
		held_cards.append(next_card)
	for index in range(held_cards.size() - 1, -1, -1):
		draw_pile.append(held_cards[index])
	return null

func discard(card: CardInstance) -> void:
	discard_pile.append(card)

func discard_many(cards: Array[CardInstance]) -> void:
	for card in cards:
		discard(card)

func exhaust(card: CardInstance) -> void:
	exhaust_pile.append(card)

func add_card(card_id: StringName) -> void:
	discard_pile.append(CardInstance.new(_next_uid, card_id))
	_next_uid += 1

func total_cards() -> int:
	return draw_pile.size() + discard_pile.size() + exhaust_pile.size()
