class_name TennisScore
extends RefCounted

var player_points: int = 0
var enemy_points: int = 0
var no_ad: bool = false

func _init(use_no_ad: bool = false) -> void:
	no_ad = use_no_ad

func point_to_player() -> void:
	player_points += 1

func point_to_enemy() -> void:
	enemy_points += 1

func is_deuce() -> bool:
	return player_points >= 3 and enemy_points >= 3 and player_points == enemy_points

func advantage_side() -> String:
	if no_ad:
		return ""
	if player_points >= 3 and enemy_points >= 3:
		if player_points == enemy_points + 1:
			return "player"
		if enemy_points == player_points + 1:
			return "enemy"
	return ""

func is_game_over() -> bool:
	if player_points < 4 and enemy_points < 4:
		return false
	if no_ad and player_points >= 3 and enemy_points >= 3:
		return player_points != enemy_points
	return abs(player_points - enemy_points) >= 2

func winner() -> String:
	if not is_game_over():
		return ""
	return "player" if player_points > enemy_points else "enemy"

func reset(use_no_ad: bool = no_ad) -> void:
	player_points = 0
	enemy_points = 0
	no_ad = use_no_ad

func display() -> String:
	if is_game_over():
		return "Game"
	if no_ad and is_deuce():
		return "40 - 40 (No-Ad)"
	if is_deuce():
		return "Deuce"
	var advantage := advantage_side()
	if advantage != "":
		return "Ad In" if advantage == "player" else "Ad Out"
	return _point_name(player_points) + " - " + _point_name(enemy_points)

func player_score_label() -> String:
	if is_game_over():
		return "Game" if player_points > enemy_points else _point_name(mini(player_points, 3))
	var advantage := advantage_side()
	if advantage == "player":
		return "Ad"
	if advantage == "enemy":
		return "40"
	if no_ad and is_deuce():
		return "40"
	return _point_name(player_points)

func enemy_score_label() -> String:
	if is_game_over():
		return "Game" if enemy_points > player_points else _point_name(mini(enemy_points, 3))
	var advantage := advantage_side()
	if advantage == "enemy":
		return "Ad"
	if advantage == "player":
		return "40"
	if no_ad and is_deuce():
		return "40"
	return _point_name(enemy_points)

func score_status_label() -> String:
	if is_game_over():
		return "Game"
	if no_ad and is_deuce():
		return "No-Ad Point"
	var advantage := advantage_side()
	if advantage == "player":
		return "Advantage Player"
	if advantage == "enemy":
		return "Advantage Opponent"
	if is_deuce():
		return "Deuce"
	return "Point Live"

func _point_name(points: int) -> String:
	match points:
		0:
			return "Love"
		1:
			return "15"
		2:
			return "30"
		3:
			return "40"
		_:
			return str(points)
