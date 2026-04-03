extends SceneTree

const CombatActorStateScript = preload("res://scripts/core/combat_actor_state.gd")
const PlannerScript = preload("res://scripts/ai/enemy_intent_planner.gd")

var _fail_count := 0

func _initialize() -> void:
	_test_tilt_status()
	_test_cost_up_status()
	_test_position_lock_status()
	_test_status_decay()
	_test_intent_planner_debuff_scoring()
	_test_intent_planner_null_guard()
	_test_intent_describe_debuffs()

	if _fail_count > 0:
		push_error("Debuff system smoke: %d test(s) failed." % _fail_count)
		quit(1)
	else:
		print("Debuff system smoke: all tests passed.")
		quit(0)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAIL: %s" % message)
		_fail_count += 1

func _test_tilt_status() -> void:
	var actor := CombatActorStateScript.new("Test Player", 100, 100, 10)
	_assert(actor.get_status("tilt") == 0, "tilt should start at 0")
	actor.add_status("tilt", 2)
	_assert(actor.get_status("tilt") == 2, "tilt should be 2 after adding 2")
	actor.add_status("tilt", 1)
	_assert(actor.get_status("tilt") == 3, "tilt should stack to 3")
	actor.set_status("tilt", 0)
	_assert(actor.get_status("tilt") == 0, "tilt should clear to 0")

func _test_cost_up_status() -> void:
	var actor := CombatActorStateScript.new("Test Player", 100, 100, 10)
	_assert(actor.get_status("cost_up") == 0, "cost_up should start at 0")
	actor.add_status("cost_up", 3)
	_assert(actor.get_status("cost_up") == 3, "cost_up should be 3 after adding 3")
	var consumed := actor.consume_status("cost_up")
	_assert(consumed == 3, "consume_status should return 3")
	_assert(actor.get_status("cost_up") == 0, "cost_up should be 0 after consume")

func _test_position_lock_status() -> void:
	var actor := CombatActorStateScript.new("Test Player", 100, 100, 10)
	actor.add_status("position_lock", 1)
	_assert(actor.get_status("position_lock") == 1, "position_lock should be 1")
	actor.set_status("position_lock", 0)
	_assert(actor.get_status("position_lock") == 0, "position_lock should clear")

func _test_status_decay() -> void:
	var actor := CombatActorStateScript.new("Test Player", 100, 100, 10)
	actor.add_status("tilt", 3)
	actor.add_status("cost_up", 2)
	actor.add_status("position_lock", 1)
	# Simulate between-point decay: tilt and cost_up decay by 1, position_lock clears
	actor.set_status("tilt", maxi(0, actor.get_status("tilt") - 1))
	actor.set_status("cost_up", maxi(0, actor.get_status("cost_up") - 1))
	actor.set_status("position_lock", 0)
	_assert(actor.get_status("tilt") == 2, "tilt should decay to 2")
	_assert(actor.get_status("cost_up") == 1, "cost_up should decay to 1")
	_assert(actor.get_status("position_lock") == 0, "position_lock should clear between points")

func _test_intent_planner_debuff_scoring() -> void:
	var planner := PlannerScript.new()
	var context := {
		"current_server": "player",
		"rally_exchanges": 2,
		"rally_pressure": 30,
		"rally_target": 64,
		"player_guard": 2,
		"enemy_guard": 4,
		"player_current_stamina": 3,
		"player_max_stamina": 6,
		"player_fatigue": 0,
		"player_open_court": 0,
		"player_return_support": 3.0,
		"rally_cards_played_this_turn": 0,
	}
	var tilt_intent := {"name": "Dizzy Slice", "tilt": 2, "guard": 3}
	var cost_intent := {"name": "Court Tax", "cost_up": 2, "pressure": 4}
	var lock_intent := {"name": "Pin Down", "position_lock": 1, "damage": 6}
	var enemy_def := {"keywords": PackedStringArray(), "intent_cycle": [tilt_intent, cost_intent, lock_intent]}
	var tilt_score := planner.score_intent(enemy_def, "Defend", tilt_intent, context)
	var cost_score := planner.score_intent(enemy_def, "ServeMode", cost_intent, context)
	var lock_score := planner.score_intent(enemy_def, "CloseOut", lock_intent, context)
	_assert(tilt_score > 0.0, "tilt intent should have positive score in Defend (%f)" % tilt_score)
	_assert(cost_score > 0.0, "cost_up intent should have positive score in ServeMode (%f)" % cost_score)
	_assert(lock_score > 0.0, "position_lock intent should have positive score in CloseOut (%f)" % lock_score)

func _test_intent_planner_null_guard() -> void:
	var planner := PlannerScript.new()
	var context := {"current_server": "player", "rally_exchanges": 0, "rally_target": 64}
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var result := planner.choose_intent(null, context, rng)
	_assert(result.get("name", "") == "Stall", "null enemy_def should return Stall intent")
	_assert(int(result.get("guard", 0)) == 4, "null enemy_def Stall should have guard 4")

func _test_intent_describe_debuffs() -> void:
	var planner := PlannerScript.new()
	var intent := {"name": "Heavy Spin", "tilt": 2, "cost_up": 1, "position_lock": 1, "damage": 4}
	var description := planner.describe_intent(intent)
	_assert(description.find("Tilt") >= 0, "describe_intent should include Tilt")
	_assert(description.find("Cost Spike") >= 0, "describe_intent should include Cost Spike")
	_assert(description.find("Position Lock") >= 0, "describe_intent should include Position Lock")
