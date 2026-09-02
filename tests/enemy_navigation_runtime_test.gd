extends Node

var _errors: Array[String] = []


func _ready() -> void:
	var host := CharacterBody3D.new()
	host.name = "NavigationTestHost"
	add_child(host)

	var floor_body := StaticBody3D.new()
	var floor_shape_node := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(40.0, 0.2, 40.0)
	floor_shape_node.shape = floor_shape
	floor_body.add_child(floor_shape_node)
	floor_body.position = Vector3(0.0, -0.15, 0.0)
	add_child(floor_body)

	await get_tree().physics_frame
	await get_tree().physics_frame

	_test_graph_helpers()
	_test_clearance_helpers(host)
	_test_investigation_helpers(host)
	_test_local_detour(host)
	_test_path_motion_helpers()

	if _errors.is_empty():
		print("ENEMY NAVIGATION RUNTIME TEST: OK")
		get_tree().quit(0)
		return
	for error: String in _errors:
		push_error(error)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _test_graph_helpers() -> void:
	var points: Array[Vector3] = [
		Vector3(2.0, 0.0, 0.0),
		Vector3(1.0, 0.0, 0.0),
		Vector3(3.0, 0.0, 0.0),
	]
	var nearest := VexEnemyNavigationRuntime.nearest_waypoint_indices(
		points,
		Vector3.ZERO,
		INF,
		2
	)
	_expect(nearest.size() == 2, "Nearest waypoint count changed")
	if nearest.size() == 2:
		_expect(nearest[0] == 1 and nearest[1] == 0, "Nearest waypoint ordering changed")

	var edges: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 2)]
	var graph := VexEnemyNavigationRuntime.build_astar_graph(points, edges)
	_expect(graph.get_point_count() == 3, "AStar graph point count changed")
	_expect(graph.are_points_connected(0, 1), "AStar graph edge 0-1 missing")
	_expect(graph.are_points_connected(1, 2), "AStar graph edge 1-2 missing")


func _test_clearance_helpers(host: CharacterBody3D) -> void:
	_expect(
		VexEnemyNavigationRuntime.has_navigation_floor(
			host, Vector3.ZERO, 1, 0.65, 2.0
		),
		"Navigation floor probe no longer sees clear floor"
	)
	_expect(
		VexEnemyNavigationRuntime.has_clearance_segment(
			host,
			Vector3.ZERO,
			Vector3(3.0, 0.0, 0.0),
			1,
			0.7
		),
		"Clear horizontal segment became blocked"
	)
	_expect(
		VexEnemyNavigationRuntime.has_reached_clearance_target(
			host,
			Vector3(0.25, 0.0, 0.0),
			0.65,
			1,
			0.7
		),
		"Nearby clear target is no longer reached"
	)
	_expect(
		VexEnemyNavigationRuntime.is_center_segment_clear(
			host,
			Vector3.ZERO,
			Vector3(3.0, 0.0, 0.0),
			1
		),
		"Clear center segment became blocked"
	)
	var furthest := VexEnemyNavigationRuntime.furthest_clearance_point_toward(
		host,
		Vector3.ZERO,
		Vector3(4.0, 0.0, 0.0),
		1,
		0.7
	)
	_expect(
		furthest.distance_to(Vector3(4.0, 0.0, 0.0)) <= 0.01,
		"Unobstructed furthest point no longer reaches destination"
	)


func _test_investigation_helpers(host: CharacterBody3D) -> void:
	var points: Array[Vector3] = [
		Vector3(1.0, 0.0, 0.0),
		Vector3(2.0, 0.0, 0.0),
	]
	var edges: Array[Vector2i] = [Vector2i(0, 1)]
	var graph := VexEnemyNavigationRuntime.build_astar_graph(points, edges)
	var start_id := 2
	graph.add_point(start_id, host.global_position)
	VexEnemyNavigationRuntime.connect_endpoint_to_graph(
		host,
		graph,
		start_id,
		host.global_position,
		points,
		10.0,
		4,
		2,
		1,
		0.7
	)
	var path := VexEnemyNavigationRuntime.find_investigation_path(
		host,
		graph,
		start_id,
		Vector3(4.0, 0.0, 0.0),
		points,
		8,
		2.2,
		0.65,
		1,
		0.7
	)
	_expect(not path.is_empty(), "Investigation path became empty in open space")
	if not path.is_empty():
		_expect(
			path[path.size() - 1].distance_to(Vector3(4.0, 0.0, 0.0)) <= 0.05,
			"Investigation path no longer approaches open destination"
		)


func _test_local_detour(host: CharacterBody3D) -> void:
	var result := VexEnemyNavigationRuntime.build_local_detour_path(
		host,
		Vector3(5.0, 0.0, 0.0),
		0.7,
		1.45,
		0.90,
		PackedFloat32Array([1.0, 1.8]),
		PackedFloat32Array([0.0, 0.75]),
		1.5,
		0.08,
		8.0,
		0.45,
		0.0,
		0.0,
		0.90,
		0.65,
		1,
		1,
		0.65,
		2.0
	)
	var path: PackedVector3Array = result.get("path", PackedVector3Array())
	_expect(not path.is_empty(), "Local detour helper produced no open-space candidate")
	if not path.is_empty():
		_expect(absf(float(result.get("side", 0.0))) > 0.5, "Local detour side selection missing")


func _test_path_motion_helpers() -> void:
	_expect(
		VexEnemyNavigationRuntime.should_refresh_path(
			false, 1.0, Vector3.ZERO, Vector3.ZERO, 1.2
		),
		"Missing navigation target no longer refreshes path"
	)
	_expect(
		not VexEnemyNavigationRuntime.should_refresh_path(
			true, 0.2, Vector3.ZERO, Vector3(0.5, 5.0, 0.0), 1.2
		),
		"Small horizontal target change refreshes path early"
	)
	_expect(
		VexEnemyNavigationRuntime.should_refresh_path(
			true, 0.2, Vector3.ZERO, Vector3(2.0, 0.0, 0.0), 1.2
		),
		"Large target change no longer refreshes path"
	)
	_expect(
		VexEnemyNavigationRuntime.should_refresh_path(
			true, 0.0, Vector3.ZERO, Vector3.ZERO, 1.2
		),
		"Expired refresh timer no longer rebuilds path"
	)

	var direct := VexEnemyNavigationRuntime.active_movement_direction(
		Vector3.ZERO, Vector3(4.0, 9.0, 0.0), 0.0, Vector3.ZERO
	)
	_expect(direct.is_equal_approx(Vector3.RIGHT), "Direct movement direction changed")
	var detour := VexEnemyNavigationRuntime.active_movement_direction(
		Vector3.ZERO, Vector3(4.0, 0.0, 0.0), 0.5, Vector3(0.0, 0.0, 1.0)
	)
	_expect(detour.is_equal_approx(Vector3(0.0, 0.0, 1.0)), "Active detour direction ignored")
	_expect(
		is_zero_approx(
			VexEnemyNavigationRuntime.active_movement_direction(
				Vector3.ZERO, Vector3(0.01, 5.0, 0.01), 0.0, Vector3.ZERO
			).length()
		),
		"Near-zero movement target no longer stops"
	)
	_expect(
		is_equal_approx(VexEnemyNavigationRuntime.movement_speed(true, 2.0, 5.0), 5.0),
		"Chase movement speed selection changed"
	)
	_expect(
		is_equal_approx(VexEnemyNavigationRuntime.movement_speed(false, 2.0, 5.0), 2.0),
		"Normal movement speed selection changed"
	)

	var tangent := VexEnemyNavigationRuntime.detour_direction_from_collision_normal(
		Vector3.RIGHT, Vector3.ZERO, Vector3(0.0, 0.0, 5.0), 0.55
	)
	_expect(tangent.is_equal_approx(Vector3(0.0, 0.0, 1.0)), "Detour tangent selection changed")
	var floor_normal := VexEnemyNavigationRuntime.detour_direction_from_collision_normal(
		Vector3.UP, Vector3.ZERO, Vector3(0.0, 0.0, 5.0), 0.55
	)
	_expect(floor_normal.is_equal_approx(Vector3.ZERO), "Floor-like collision now creates detour")
