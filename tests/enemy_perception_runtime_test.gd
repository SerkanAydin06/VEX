extends Node

var _errors: Array[String] = []


func _ready() -> void:
	_test_active_range()
	_test_initial_view()
	_test_crouch_detection()
	_test_crouched_target_height()
	_test_hearing()
	_test_ally_alert_decisions()
	_test_sight_scheduling()
	if _errors.is_empty():
		print("ENEMY PERCEPTION RUNTIME TEST: OK")
		get_tree().quit(0)
		return
	for error: String in _errors:
		push_error(error)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _test_active_range() -> void:
	_expect(
		is_equal_approx(
			VexEnemyPerceptionRuntime.active_detection_range(
				false, 30.0, 38.0, 0.0, 80.0
			),
			30.0
		),
		"Unalerted detection range changed"
	)
	_expect(
		is_equal_approx(
			VexEnemyPerceptionRuntime.active_detection_range(
				true, 30.0, 38.0, 0.0, 80.0
			),
			38.0
		),
		"Alerted pursuit range changed"
	)
	_expect(
		is_equal_approx(
			VexEnemyPerceptionRuntime.active_detection_range(
				false, 30.0, 38.0, 1.0, 80.0
			),
			80.0
		),
		"Damage reaction range no longer expands perception"
	)


func _test_initial_view() -> void:
	var origin := Vector3.ZERO
	var facing := Vector3.FORWARD
	_expect(
		VexEnemyPerceptionRuntime.is_player_inside_initial_view(
			origin, facing, Vector3(0.0, 0.0, -5.0), 120.0
		),
		"Player directly in front is outside initial view"
	)
	_expect(
		not VexEnemyPerceptionRuntime.is_player_inside_initial_view(
			origin, facing, Vector3(0.0, 0.0, 5.0), 120.0
		),
		"Player directly behind is inside narrow initial view"
	)
	_expect(
		VexEnemyPerceptionRuntime.is_player_inside_initial_view(
			origin, facing, Vector3(0.0, 0.0, 5.0), 360.0
		),
		"360 degree initial view does not include rear target"
	)


func _test_crouch_detection() -> void:
	_expect(
		VexEnemyPerceptionRuntime.passes_crouch_detection(
			true, true, 20.0, 3.0, 0.0
		),
		"Alerted enemy lost crouching target"
	)
	_expect(
		VexEnemyPerceptionRuntime.passes_crouch_detection(
			false, true, 2.0, 3.0, 0.0
		),
		"Guaranteed close crouch detection changed"
	)
	_expect(
		not VexEnemyPerceptionRuntime.passes_crouch_detection(
			false, true, 20.0, 3.0, 0.0
		),
		"Zero crouch detection chance can still detect at long range"
	)
	_expect(
		VexEnemyPerceptionRuntime.passes_crouch_detection(
			false, true, 20.0, 3.0, 1.0
		),
		"Full crouch detection chance can fail at long range"
	)


func _test_crouched_target_height() -> void:
	var player := Node3D.new()
	var shape_node := CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.35
	shape_node.shape = capsule
	shape_node.position.y = 0.9
	player.add_child(shape_node)
	add_child(player)
	var height := VexEnemyPerceptionRuntime.crouched_sight_target_height(
		player,
		0.45,
		0.50,
		-0.20
	)
	_expect(
		is_equal_approx(height, 0.45),
		"Crouched sight target clamp changed"
	)
	player.queue_free()


func _test_hearing() -> void:
	_expect(
		is_equal_approx(
			VexEnemyPerceptionRuntime.effective_hearing_range(14.0, 0.5, 1.0),
			7.0
		),
		"Hearing loudness scaling changed"
	)
	_expect(
		is_equal_approx(
			VexEnemyPerceptionRuntime.effective_hearing_range(14.0, 0.0, 1.0),
			1.4
		),
		"Minimum hearing loudness floor changed"
	)
	_expect(
		VexEnemyPerceptionRuntime.should_hear_noise(
			Vector3.ZERO,
			Vector3(6.0, 100.0, 0.0),
			14.0,
			0.5,
			1.0
		),
		"Horizontal hearing range no longer ignores vertical offset"
	)
	_expect(
		not VexEnemyPerceptionRuntime.should_hear_noise(
			Vector3.ZERO,
			Vector3(8.0, 0.0, 0.0),
			14.0,
			0.5,
			1.0
		),
		"Noise outside effective hearing range is accepted"
	)
	_expect(
		VexEnemyPerceptionRuntime.should_broadcast_noise_alert(0.9, 0.9),
		"Noise at ally alert threshold no longer broadcasts"
	)
	_expect(
		not VexEnemyPerceptionRuntime.should_broadcast_noise_alert(0.89, 0.9),
		"Quiet noise now broadcasts ally alert"
	)


func _test_ally_alert_decisions() -> void:
	_expect(
		VexEnemyPerceptionRuntime.should_accept_ally_alert(false, false, true),
		"Valid ally alert is rejected"
	)
	_expect(
		not VexEnemyPerceptionRuntime.should_accept_ally_alert(true, false, true),
		"Dead enemy accepts ally alert"
	)
	_expect(
		not VexEnemyPerceptionRuntime.should_accept_ally_alert(false, true, true),
		"Visible player can be overwritten by ally alert"
	)
	_expect(
		not VexEnemyPerceptionRuntime.should_accept_ally_alert(false, false, false),
		"Enemy with ally alerts disabled accepts alert"
	)
	var facing := VexEnemyPerceptionRuntime.ally_alert_facing_direction(
		Vector3.ZERO,
		Vector3(3.0, 50.0, 0.0),
		Vector3.FORWARD
	)
	_expect(facing.is_equal_approx(Vector3.RIGHT), "Ally alert facing direction changed")
	var unchanged := VexEnemyPerceptionRuntime.ally_alert_facing_direction(
		Vector3.ZERO,
		Vector3.ZERO,
		Vector3.FORWARD
	)
	_expect(unchanged.is_equal_approx(Vector3.FORWARD), "Zero-distance ally alert changes facing")


func _test_sight_scheduling() -> void:
	_expect(
		VexEnemyPerceptionRuntime.should_skip_idle_sight(false, 37.0, 30.0, 6.0),
		"Far unaware enemy no longer skips expensive sight check"
	)
	_expect(
		not VexEnemyPerceptionRuntime.should_skip_idle_sight(true, 50.0, 30.0, 6.0),
		"Alerted enemy incorrectly skips sight checks"
	)
	_expect(
		is_equal_approx(
			VexEnemyPerceptionRuntime.sight_interval(
				10.0, false, 30.0, 24.0, 0.12, 0.18, 0.2, 0.32
			),
			0.12
		),
		"Near sight interval changed"
	)
	_expect(
		is_equal_approx(
			VexEnemyPerceptionRuntime.sight_interval(
				32.0, true, 30.0, 40.0, 0.12, 0.18, 0.2, 0.32
			),
			0.18
		),
		"Medium sight interval changed"
	)
	_expect(
		is_equal_approx(
			VexEnemyPerceptionRuntime.sight_interval(
				50.0, true, 30.0, 24.0, 0.12, 0.18, 0.2, 0.32
			),
			0.2
		),
		"Distant alerted sight interval changed"
	)
	_expect(
		is_equal_approx(
			VexEnemyPerceptionRuntime.sight_interval(
				50.0, false, 30.0, 24.0, 0.12, 0.18, 0.2, 0.32
			),
			0.32
		),
		"Distant idle sight interval changed"
	)
	_expect(
		VexEnemyPerceptionRuntime.is_sight_check_due(0.05, 0.10),
		"Elapsed sight timer is not due"
	)
	_expect(
		not VexEnemyPerceptionRuntime.is_sight_check_due(0.20, 0.05),
		"Active sight timer becomes due too early"
	)
	_expect(
		is_equal_approx(
			VexEnemyPerceptionRuntime.next_sight_check_remaining(0.05, 0.10, 0.18),
			0.18
		),
		"Elapsed sight timer no longer resets to interval"
	)
	_expect(
		is_equal_approx(
			VexEnemyPerceptionRuntime.next_sight_check_remaining(0.20, 0.05, 0.18),
			0.15
		),
		"Sight timer countdown changed"
	)
