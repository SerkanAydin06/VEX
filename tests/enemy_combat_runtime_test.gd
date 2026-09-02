extends Node

var _errors: Array[String] = []


func _ready() -> void:
	_test_attack_target_resolution()
	_test_attack_timing_decisions()
	_test_attack_recovery_plans()
	_test_projectile_intercept()
	_test_damage_retaliation_math()

	if _errors.is_empty():
		print("ENEMY COMBAT RUNTIME TEST: OK")
		get_tree().quit(0)
		return
	for error: String in _errors:
		push_error(error)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _expect_vec3(actual: Vector3, expected: Vector3, message: String, tolerance := 0.001) -> void:
	_expect(actual.distance_to(expected) <= tolerance, "%s: %s != %s" % [message, actual, expected])


func _test_attack_target_resolution() -> void:
	var visible := VexEnemyCombatRuntime.resolve_attack_target(
		Vector3.ZERO,
		true,
		true,
		Vector3(4.0, 0.0, 1.0),
		true,
		Vector3(2.0, 0.0, 0.0)
	)
	_expect(bool(visible.get("valid", false)), "Visible player target became invalid")
	_expect_vec3(
		visible.get("position", Vector3.ZERO) as Vector3,
		Vector3(4.0, 0.0, 1.0),
		"Visible player no longer wins attack target selection"
	)

	var remembered := VexEnemyCombatRuntime.resolve_attack_target(
		Vector3(1.0, 0.0, 0.0),
		false,
		true,
		Vector3(9.0, 0.0, 0.0),
		true,
		Vector3(3.0, 0.0, -2.0)
	)
	_expect(bool(remembered.get("valid", false)), "Last-seen attack target became invalid")
	_expect_vec3(
		remembered.get("position", Vector3.ZERO) as Vector3,
		Vector3(3.0, 0.0, -2.0),
		"Last-seen target fallback changed"
	)

	var missing := VexEnemyCombatRuntime.resolve_attack_target(
		Vector3(1.0, 0.0, 2.0),
		false,
		false,
		Vector3.ZERO,
		false,
		Vector3.ZERO
	)
	_expect(not bool(missing.get("valid", true)), "Missing attack target became valid")
	_expect_vec3(
		missing.get("position", Vector3.ZERO) as Vector3,
		Vector3(1.0, 0.0, 2.0),
		"Missing target fallback position changed"
	)


func _test_attack_timing_decisions() -> void:
	_expect(
		VexEnemyCombatRuntime.should_start_attack(9.0, 9.0),
		"Attack range boundary no longer starts attack"
	)
	_expect(
		not VexEnemyCombatRuntime.should_start_attack(9.01, 9.0),
		"Out-of-range target now starts attack"
	)
	_expect(
		VexEnemyCombatRuntime.should_fire_after_windup(9.65, 9.0, 0.65, true),
		"Windup tolerance boundary no longer fires"
	)
	_expect(
		not VexEnemyCombatRuntime.should_fire_after_windup(9.66, 9.0, 0.65, true),
		"Windup fire escaped range tolerance"
	)
	_expect(
		not VexEnemyCombatRuntime.should_fire_after_windup(5.0, 9.0, 0.65, false),
		"Windup fire ignored lost line of sight"
	)
	_expect(
		is_equal_approx(VexEnemyCombatRuntime.remaining_attack_cooldown(0.80, 0.25), 0.55),
		"Attack cooldown remainder changed"
	)
	_expect(
		is_equal_approx(VexEnemyCombatRuntime.remaining_attack_cooldown(0.20, 0.40), 0.0),
		"Attack cooldown remainder no longer clamps to zero"
	)


func _test_attack_recovery_plans() -> void:
	var close_plan := VexEnemyCombatRuntime.attack_recovery_plan(
		Vector3.ZERO,
		Vector3(10.0, 0.0, 0.0),
		true,
		2.0,
		3.0,
		4.0,
		2.0,
		1.0,
		1.0,
		6.0,
		3.1,
		0.72,
		0.58,
		0.35,
		0.45
	)
	_expect(bool(close_plan.get("valid", false)), "Close recovery plan became invalid")
	_expect_vec3(
		close_plan.get("facing_direction", Vector3.ZERO) as Vector3,
		Vector3.RIGHT,
		"Close recovery facing changed"
	)
	_expect_vec3(
		close_plan.get("desired_velocity", Vector3.ZERO) as Vector3,
		Vector3(4.0, 0.0, 0.0),
		"Close recovery no longer overwrites strafe with chase velocity"
	)

	var approach_plan := VexEnemyCombatRuntime.attack_recovery_plan(
		Vector3.ZERO,
		Vector3(8.0, 0.0, 0.0),
		false,
		2.0,
		3.0,
		4.0,
		2.0,
		0.0,
		1.0,
		6.0,
		3.1,
		0.72,
		0.58,
		0.35,
		0.45
	)
	_expect_vec3(
		approach_plan.get("desired_velocity", Vector3.ZERO) as Vector3,
		Vector3(3.0, 0.0, 0.0),
		"Ranged recovery approach speed changed"
	)

	var retreat_plan := VexEnemyCombatRuntime.attack_recovery_plan(
		Vector3.ZERO,
		Vector3(1.0, 0.0, 0.0),
		false,
		2.0,
		3.0,
		4.0,
		0.0,
		0.0,
		1.0,
		6.0,
		3.1,
		0.72,
		0.58,
		0.35,
		0.45
	)
	_expect_vec3(
		retreat_plan.get("desired_velocity", Vector3.ZERO) as Vector3,
		Vector3(-1.74, 0.0, 0.0),
		"Ranged recovery retreat speed changed"
	)

	var strafe_plan := VexEnemyCombatRuntime.attack_recovery_plan(
		Vector3.ZERO,
		Vector3(6.0, 0.0, 0.0),
		false,
		2.0,
		3.0,
		4.0,
		0.0,
		1.0,
		1.0,
		6.0,
		3.1,
		0.72,
		0.58,
		0.35,
		0.45
	)
	_expect_vec3(
		strafe_plan.get("desired_velocity", Vector3.ZERO) as Vector3,
		Vector3(0.0, 0.0, 1.08),
		"Attack recovery strafe scaling changed"
	)

	var zero_plan := VexEnemyCombatRuntime.attack_recovery_plan(
		Vector3.ZERO,
		Vector3.ZERO,
		false,
		2.0,
		3.0,
		4.0,
		2.0,
		1.0,
		1.0,
		6.0,
		3.1,
		0.72,
		0.58,
		0.35,
		0.45
	)
	_expect(not bool(zero_plan.get("valid", true)), "Zero-distance recovery plan became valid")


func _test_projectile_intercept() -> void:
	var stationary := VexEnemyCombatRuntime.calculate_intercept_time(
		Vector3.ZERO,
		Vector3(10.0, 0.0, 0.0),
		Vector3.ZERO,
		5.0
	)
	_expect(is_equal_approx(stationary, 2.0), "Stationary intercept time changed")

	var moving_away := VexEnemyCombatRuntime.calculate_intercept_time(
		Vector3.ZERO,
		Vector3(10.0, 0.0, 0.0),
		Vector3(1.0, 0.0, 0.0),
		5.0
	)
	_expect(is_equal_approx(moving_away, 2.5), "Moving target intercept time changed")

	var unreachable := VexEnemyCombatRuntime.calculate_intercept_time(
		Vector3.ZERO,
		Vector3(10.0, 0.0, 0.0),
		Vector3(10.0, 0.0, 0.0),
		5.0
	)
	_expect(is_equal_approx(unreachable, 2.0), "Unreachable intercept fallback changed")


func _test_damage_retaliation_math() -> void:
	var approach := VexEnemyCombatRuntime.damage_source_approach_position(
		Vector3(10.0, 2.0, 0.0),
		Vector3.ZERO,
		1.4,
		0.30
	)
	_expect_vec3(approach, Vector3(1.4, 2.0, 0.0), "Damage source approach offset changed")

	var progress := VexEnemyCombatRuntime.damage_pursuit_progress(
		8.5,
		10.0,
		0.20,
		1.0,
		3.0,
		0.5
	)
	_expect(is_equal_approx(float(progress.get("best_distance", INF)), 8.5), "Damage pursuit best distance did not improve")
	_expect(is_equal_approx(float(progress.get("stall_remaining", -1.0)), 3.0), "Damage pursuit progress did not reset stall timer")

	var stalled := VexEnemyCombatRuntime.damage_pursuit_progress(
		9.9,
		10.0,
		0.20,
		1.0,
		3.0,
		0.5
	)
	_expect(is_equal_approx(float(stalled.get("best_distance", INF)), 10.0), "Sub-threshold damage progress changed best distance")
	_expect(is_equal_approx(float(stalled.get("stall_remaining", -1.0)), 0.5), "Damage pursuit stall countdown changed")

	_expect(
		VexEnemyCombatRuntime.should_abandon_damage_pursuit(0.0, true, 0, 0),
		"Stalled empty damage path no longer abandons pursuit"
	)
	_expect(
		not VexEnemyCombatRuntime.should_abandon_damage_pursuit(0.1, true, 0, 0),
		"Active damage pursuit now abandons early"
	)
	_expect(
		VexEnemyCombatRuntime.can_attempt_damage_handoff(0.0, true, 9.65, 9.0, 0.65),
		"Damage handoff tolerance boundary changed"
	)
	_expect(
		not VexEnemyCombatRuntime.can_attempt_damage_handoff(0.1, true, 5.0, 9.0, 0.65),
		"Damage handoff ignored commit window"
	)
	_expect(
		VexEnemyCombatRuntime.should_check_close_combat_visibility(true, true, 9.65, 9.0, 0.65),
		"Close combat visibility boundary changed"
	)
	_expect(
		not VexEnemyCombatRuntime.should_check_close_combat_visibility(false, true, 5.0, 9.0, 0.65),
		"Non-close role now requests point-blank visibility refresh"
	)
