class_name RallyState
extends RefCounted

const RP_MAX := 100

var rp: int = 0
var pressure_target: int = RP_MAX
var ball_state: String = "NormalBall"
var ball_lane: String = "Center"
var player_position: String = "Baseline"
var enemy_position: String = "Baseline"
var point_server: String = "player"
var turn_owner: String = "player"
var forced_error: bool = false
var point_winner: String = ""
var error_reason: String = ""
var exchanges: int = 0
var last_shot_family: String = ""
var last_shot_lane: String = ""
var last_shot_side: String = ""
var last_shot_name: String = ""

# Dynamic court geometry — updated each shot so UI and logic can read real positions
# ball_x: horizontal ball position on court. -1.0 = far deuce wide, 0 = center, +1.0 = far ad wide
var ball_x: float = 0.0
# ball_depth: how deep the ball landed. "Deep"=near baseline, "Mid"=service-line, "Short"=inside service-line
var ball_depth: String = "Deep"
# Court side the player/opponent is currently standing on after covering the last shot
var player_court_side: String = "Center"  # "Deuce" | "Center" | "Ad"
var enemy_court_side: String = "Center"

func reset(server_side: String, rp_target: int = RP_MAX) -> void:
	rp = 0
	pressure_target = clampi(rp_target, 20, RP_MAX)
	ball_state = "NormalBall"
	ball_lane = "Center"
	player_position = "Baseline"
	enemy_position = "Baseline"
	point_server = server_side
	turn_owner = "player"
	forced_error = false
	point_winner = ""
	error_reason = ""
	exchanges = 0
	last_shot_family = ""
	last_shot_lane = ""
	last_shot_side = ""
	last_shot_name = ""
	ball_x = 0.0
	ball_depth = "Deep"
	player_court_side = "Center"
	enemy_court_side = "Center"

func apply_pressure(side: String, amount: int) -> void:
	if side == "player":
		rp = clampi(rp + maxi(0, amount), -RP_MAX, RP_MAX)
	else:
		rp = clampi(rp - maxi(0, amount), -RP_MAX, RP_MAX)
	turn_owner = "enemy" if side == "enemy" else "player"
	exchanges += 1

func record_shot(side: String, shot_family: String, shot_lane: String, shot_name: String = "") -> void:
	last_shot_side = side
	last_shot_family = shot_family
	last_shot_lane = shot_lane
	last_shot_name = shot_name
	if shot_lane != "":
		ball_lane = shot_lane

# Shift ball horizontally. direction: +1 = toward ad, -1 = toward deuce. amount: 0.0–1.0.
func shift_ball_x(direction: float, amount: float) -> void:
	ball_x = clampf(ball_x + direction * clampf(amount, 0.0, 1.0), -1.0, 1.0)

# After a shot, the defender runs to cover where the ball went. Update their court side.
func reposition_defender(defending_side: String) -> void:
	var target_side: String
	if ball_x < -0.3:
		target_side = "Deuce"
	elif ball_x > 0.3:
		target_side = "Ad"
	else:
		target_side = "Center"
	if defending_side == "player":
		player_court_side = target_side
	else:
		enemy_court_side = target_side

# Returns how open the court is for the attacker: 0.0 = centered, ±1.0 = far side fully open.
# Positive = ad side open, negative = deuce side open.
func open_court_x(attacker_is_player: bool) -> float:
	var defender_side := enemy_court_side if attacker_is_player else player_court_side
	match defender_side:
		"Deuce":
			return 1.0   # ad side is vacant
		"Ad":
			return -1.0  # deuce side is vacant
		_:
			return 0.0   # defender is centered

func force_error(losing_side: String, reason: String) -> void:
	forced_error = true
	error_reason = reason
	point_winner = "enemy" if losing_side == "player" else "player"

func is_point_over() -> bool:
	return forced_error or point_winner != "" or abs(rp) >= pressure_target

func resolve_winner() -> String:
	if point_winner != "":
		return point_winner
	if rp >= pressure_target:
		return "player"
	if rp <= -pressure_target:
		return "enemy"
	return ""
