extends Node

var _errors: Array[String] = []


func _ready() -> void:
	_test_active_range()
	_test_initial_view()
	_test_crouch_detection()
	_test_crouched_target_height()
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
