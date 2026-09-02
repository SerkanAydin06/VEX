from pathlib import Path

RUNTIME_APPEND = r'''


static func has_navigation_floor(
    host: CharacterBody3D,
    probe_position: Vector3,
    floor_collision_mask: int,
    floor_ray_start_height: float,
    floor_ray_extra_depth: float
) -> bool:
    if host == null or host.get_world_3d() == null:
        return false
    var ray_start := probe_position + Vector3.UP * maxf(floor_ray_start_height, 0.65)
    var ray_end := probe_position + Vector3.DOWN * maxf(floor_ray_extra_depth, 2.0)
    var query := PhysicsRayQueryParameters3D.create(
        ray_start,
        ray_end,
        floor_collision_mask,
        [host.get_rid()]
    )
    query.collide_with_areas = false
    return not host.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


static func has_clearance_segment(
    host: CharacterBody3D,
    from_position: Vector3,
    to_position: Vector3,
    navigation_collision_mask: int,
    navigation_clearance: float
) -> bool:
    if host == null or host.get_world_3d() == null:
        return false
    var direction := to_position - from_position
    direction.y = 0.0
    if direction.length_squared() <= 0.01:
        return true
    var perpendicular := Vector3(-direction.z, 0.0, direction.x).normalized()
    perpendicular *= navigation_clearance
    var offsets: Array[Vector3] = [Vector3.ZERO, perpendicular, -perpendicular]
    var space_state := host.get_world_3d().direct_space_state
    for offset: Vector3 in offsets:
        var ray_start := from_position + offset
        var ray_end := to_position + offset
        var query := PhysicsRayQueryParameters3D.create(
            ray_start,
            ray_end,
            navigation_collision_mask,
            [host.get_rid()]
        )
        if not space_state.intersect_ray(query).is_empty():
            return false
    return true


static func has_reached_clearance_target(
    host: CharacterBody3D,
    target: Vector3,
    reach_distance: float,
    navigation_collision_mask: int,
    navigation_clearance: float
) -> bool:
    if host == null or host.get_world_3d() == null:
        return false
    if _horizontal_distance(host.global_position, target) > reach_distance:
        return false
    var direction := target - host.global_position
    direction.y = 0.0
    if direction.length_squared() <= 0.000001:
        return true
    var perpendicular := Vector3(-direction.z, 0.0, direction.x).normalized()
    perpendicular *= navigation_clearance
    var offsets: Array[Vector3] = [Vector3.ZERO, perpendicular, -perpendicular]
    var space_state := host.get_world_3d().direct_space_state
    for offset: Vector3 in offsets:
        var ray_start := host.global_position + offset
        var ray_end := target + offset
        ray_start.y = host.global_position.y
        ray_end.y = host.global_position.y
        var query := PhysicsRayQueryParameters3D.create(
            ray_start,
            ray_end,
            navigation_collision_mask,
            [host.get_rid()]
        )
        query.collide_with_areas = false
        if not space_state.intersect_ray(query).is_empty():
            return false
    return true


static func is_center_segment_clear(
    host: CharacterBody3D,
    from_position: Vector3,
    to_position: Vector3,
    navigation_collision_mask: int
) -> bool:
    if host == null or host.get_world_3d() == null:
        return false
    var direction := to_position - from_position
    direction.y = 0.0
    if direction.length_squared() <= 0.01:
        return true
    var ray_start := from_position
    var ray_end := to_position
    ray_start.y = host.global_position.y
    ray_end.y = host.global_position.y
    var query := PhysicsRayQueryParameters3D.create(
        ray_start,
        ray_end,
        navigation_collision_mask,
        [host.get_rid()]
    )
    return host.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


static func build_astar_graph(
    navigation_points: Array[Vector3],
    valid_edges: Array[Vector2i]
) -> AStar3D:
    var graph := AStar3D.new()
    for point_index: int in range(navigation_points.size()):
        graph.add_point(point_index, navigation_points[point_index])
    for edge: Vector2i in valid_edges:
        graph.connect_points(edge.x, edge.y, true)
    return graph


static func nearest_waypoint_indices(
    navigation_points: Array[Vector3],
    endpoint: Vector3,
    maximum_distance: float,
    maximum_count: int
) -> Array[int]:
    var indices: Array[int] = []
    var distances: Array[float] = []
    for point_index: int in range(navigation_points.size()):
        var distance := _horizontal_distance(endpoint, navigation_points[point_index])
        if distance > maximum_distance:
            continue
        var insert_at := distances.size()
        while insert_at > 0 and distance < distances[insert_at - 1]:
            insert_at -= 1
        distances.insert(insert_at, distance)
        indices.insert(insert_at, point_index)
        if indices.size() > maximum_count:
            indices.pop_back()
            distances.pop_back()
    return indices


static func connect_endpoint_to_graph(
    host: CharacterBody3D,
    graph: AStar3D,
    endpoint_id: int,
    endpoint: Vector3,
    navigation_points: Array[Vector3],
    maximum_distance: float,
    candidate_count: int,
    connection_limit: int,
    navigation_collision_mask: int,
    navigation_clearance: float
) -> void:
    var nearby_indices := nearest_waypoint_indices(
        navigation_points,
        endpoint,
        maximum_distance,
        candidate_count
    )
    var connected_count := 0
    for point_index: int in nearby_indices:
        if has_clearance_segment(
            host,
            endpoint,
            navigation_points[point_index],
            navigation_collision_mask,
            navigation_clearance
        ):
            graph.connect_points(endpoint_id, point_index, true)
            connected_count += 1
            if connected_count >= connection_limit:
                break


static func furthest_clearance_point_toward(
    host: CharacterBody3D,
    from_position: Vector3,
    destination: Vector3,
    navigation_collision_mask: int,
    navigation_clearance: float
) -> Vector3:
    var start := from_position
    start.y = host.global_position.y
    var target := destination
    target.y = host.global_position.y
    if has_clearance_segment(
        host, start, target, navigation_collision_mask, navigation_clearance
    ):
        return target
    var low := 0.0
    var high := 1.0
    for _step: int in range(8):
        var middle := (low + high) * 0.5
        var probe := start.lerp(target, middle)
        probe.y = host.global_position.y
        if has_clearance_segment(
            host, start, probe, navigation_collision_mask, navigation_clearance
        ):
            low = middle
        else:
            high = middle
    var result := start.lerp(target, low)
    result.y = host.global_position.y
    return result


static func find_investigation_path(
    host: CharacterBody3D,
    graph: AStar3D,
    start_id: int,
    destination: Vector3,
    navigation_points: Array[Vector3],
    investigation_candidate_count: int,
    search_probe_radius: float,
    waypoint_reach_distance: float,
    navigation_collision_mask: int,
    navigation_clearance: float
) -> PackedVector3Array:
    var nearby_indices := nearest_waypoint_indices(
        navigation_points,
        destination,
        INF,
        navigation_points.size()
    )
    var best_path := PackedVector3Array()
    var best_remaining_distance := INF
    var reachable_candidates := 0
    for point_index: int in nearby_indices:
        var candidate_path := graph.get_point_path(start_id, point_index)
        if candidate_path.is_empty():
            continue
        reachable_candidates += 1
        var waypoint := navigation_points[point_index]
        var approach_point := furthest_clearance_point_toward(
            host,
            waypoint,
            destination,
            navigation_collision_mask,
            navigation_clearance
        )
        var remaining_distance := _horizontal_distance(approach_point, destination)
        if remaining_distance < best_remaining_distance:
            best_remaining_distance = remaining_distance
            best_path = candidate_path.duplicate()
            if (
                best_path.is_empty()
                or _horizontal_distance(best_path[best_path.size() - 1], approach_point)
                > waypoint_reach_distance * 0.25
            ):
                best_path.append(approach_point)
        if best_remaining_distance <= waypoint_reach_distance * 0.25:
            break
        if (
            reachable_candidates >= investigation_candidate_count
            and best_remaining_distance <= search_probe_radius * 1.5
        ):
            break
    return best_path


static func build_local_detour_path(
    host: CharacterBody3D,
    destination: Vector3,
    navigation_clearance: float,
    local_detour_clearance_multiplier: float,
    local_detour_min_step: float,
    local_detour_lateral_multipliers: PackedFloat32Array,
    local_detour_forward_multipliers: PackedFloat32Array,
    local_detour_progress_weight: float,
    local_detour_distance_penalty: float,
    local_detour_direct_path_bonus: float,
    local_detour_persistence_bonus: float,
    local_detour_side: float,
    local_detour_remaining: float,
    local_detour_duration: float,
    waypoint_reach_distance: float,
    navigation_collision_mask: int,
    floor_collision_mask: int,
    floor_ray_start_height: float,
    floor_ray_extra_depth: float
) -> Dictionary:
    var toward_target := destination - host.global_position
    toward_target.y = 0.0
    if toward_target.length_squared() <= 0.001:
        return {
            "path": PackedVector3Array(),
            "side": local_detour_side,
            "remaining": local_detour_remaining,
        }
    var forward := toward_target.normalized()
    var side := Vector3(-forward.z, 0.0, forward.x)
    var base_step := maxf(
        navigation_clearance * local_detour_clearance_multiplier,
        local_detour_min_step
    )
    var lateral_steps := PackedFloat32Array()
    for multiplier: float in local_detour_lateral_multipliers:
        lateral_steps.append(base_step * multiplier)
    var forward_steps := PackedFloat32Array()
    for multiplier: float in local_detour_forward_multipliers:
        forward_steps.append(base_step * multiplier)
    var side_signs := PackedFloat32Array([-1.0, 1.0])
    if local_detour_remaining > 0.0 and absf(local_detour_side) > 0.5:
        side_signs = PackedFloat32Array([local_detour_side, -local_detour_side])
    var best_path := PackedVector3Array()
    var best_score := -INF
    var best_side := 0.0
    var current_remaining := _horizontal_distance(host.global_position, destination)
    for side_sign: float in side_signs:
        for lateral_distance: float in lateral_steps:
            for forward_distance: float in forward_steps:
                var candidate := (
                    host.global_position
                    + side * side_sign * lateral_distance
                    + forward * forward_distance
                )
                candidate.y = host.global_position.y
                if not has_navigation_floor(
                    host,
                    candidate,
                    floor_collision_mask,
                    floor_ray_start_height,
                    floor_ray_extra_depth
                ):
                    continue
                if not has_clearance_segment(
                    host,
                    host.global_position,
                    candidate,
                    navigation_collision_mask,
                    navigation_clearance
                ):
                    continue
                var approach_point := furthest_clearance_point_toward(
                    host,
                    candidate,
                    destination,
                    navigation_collision_mask,
                    navigation_clearance
                )
                var remaining := _horizontal_distance(approach_point, destination)
                var progress := current_remaining - remaining
                var direct_open := has_clearance_segment(
                    host,
                    candidate,
                    destination,
                    navigation_collision_mask,
                    navigation_clearance
                )
                var score := (
                    -remaining
                    + progress * local_detour_progress_weight
                    - lateral_distance * local_detour_distance_penalty
                )
                if direct_open:
                    score += local_detour_direct_path_bonus
                if local_detour_remaining > 0.0 and side_sign == local_detour_side:
                    score += local_detour_persistence_bonus
                if score <= best_score:
                    continue
                best_score = score
                best_side = side_sign
                best_path = PackedVector3Array([host.global_position, candidate])
                if (
                    _horizontal_distance(candidate, approach_point)
                    > waypoint_reach_distance * 0.35
                ):
                    best_path.append(approach_point)
    return {
        "path": best_path,
        "side": best_side if not best_path.is_empty() else local_detour_side,
        "remaining": local_detour_duration if not best_path.is_empty() else local_detour_remaining,
    }
'''


def replace_function(source: str, name: str, replacement: str) -> str:
    marker = f"func {name}"
    start = source.find(marker)
    if start < 0:
        raise SystemExit(f"Missing function: {name}")
    next_func = source.find("\n\nfunc ", start + len(marker))
    end = len(source) if next_func < 0 else next_func + 2
    return source[:start] + replacement.rstrip() + "\n\n" + source[end:]


runtime_path = Path("scripts/actors/enemy_navigation_runtime.gd")
runtime = runtime_path.read_text(encoding="utf-8")
if "static func has_navigation_floor(" not in runtime:
    runtime += RUNTIME_APPEND
    runtime_path.write_text(runtime, encoding="utf-8")

base_path = Path("scripts/actors/enemy_combatant_base.gd")
text = base_path.read_text(encoding="utf-8")

text = replace_function(text, "_build_local_detour_path(", '''func _build_local_detour_path(destination: Vector3) -> PackedVector3Array:
	var result := EnemyNavigationRuntime.build_local_detour_path(
		self,
		destination,
		navigation_clearance,
		local_detour_clearance_multiplier,
		local_detour_min_step,
		local_detour_lateral_multipliers,
		local_detour_forward_multipliers,
		local_detour_progress_weight,
		local_detour_distance_penalty,
		local_detour_direct_path_bonus,
		local_detour_persistence_bonus,
		_local_detour_side,
		_local_detour_remaining,
		local_detour_duration,
		waypoint_reach_distance,
		navigation_collision_mask,
		floor_collision_mask,
		floor_snap_ray_start_height,
		floor_snap_ray_extra_depth
	)
	var path: PackedVector3Array = result.get("path", PackedVector3Array())
	if not path.is_empty():
		_local_detour_side = float(result.get("side", _local_detour_side))
		_local_detour_remaining = float(result.get("remaining", local_detour_duration))
	return path''')

text = replace_function(text, "_has_navigation_floor(", '''func _has_navigation_floor(probe_position: Vector3) -> bool:
	return EnemyNavigationRuntime.has_navigation_floor(
		self,
		probe_position,
		floor_collision_mask,
		floor_snap_ray_start_height,
		floor_snap_ray_extra_depth
	)''')

text = replace_function(text, "_has_reached_walkable_target(", '''func _has_reached_walkable_target(target: Vector3, reach_distance: float) -> bool:
	return EnemyNavigationRuntime.has_reached_clearance_target(
		self,
		target,
		reach_distance,
		navigation_collision_mask,
		navigation_clearance
	)''')

text = replace_function(text, "_build_astar_graph(", '''func _build_astar_graph() -> AStar3D:
	return EnemyNavigationRuntime.build_astar_graph(
		_navigation_points,
		_valid_edges
	)''')

text = replace_function(text, "_find_investigation_path(", '''func _find_investigation_path(
	graph: AStar3D,
	start_id: int,
	destination: Vector3
) -> PackedVector3Array:
	return EnemyNavigationRuntime.find_investigation_path(
		self,
		graph,
		start_id,
		destination,
		_navigation_points,
		investigation_candidate_count,
		search_probe_radius,
		waypoint_reach_distance,
		navigation_collision_mask,
		navigation_clearance
	)''')

text = replace_function(text, "_furthest_walkable_point_toward(", '''func _furthest_walkable_point_toward(from_position: Vector3, destination: Vector3) -> Vector3:
	return EnemyNavigationRuntime.furthest_clearance_point_toward(
		self,
		from_position,
		destination,
		navigation_collision_mask,
		navigation_clearance
	)''')

text = replace_function(text, "_connect_endpoint_to_graph(", '''func _connect_endpoint_to_graph(graph: AStar3D, endpoint_id: int, endpoint: Vector3) -> void:
	EnemyNavigationRuntime.connect_endpoint_to_graph(
		self,
		graph,
		endpoint_id,
		endpoint,
		_navigation_points,
		waypoint_link_distance * endpoint_link_distance_multiplier,
		endpoint_candidate_count,
		endpoint_connection_limit,
		navigation_collision_mask,
		navigation_clearance
	)''')

text = replace_function(text, "_nearest_waypoint_indices(", '''func _nearest_waypoint_indices(
	endpoint: Vector3,
	maximum_distance: float,
	maximum_count: int
) -> Array[int]:
	return EnemyNavigationRuntime.nearest_waypoint_indices(
		_navigation_points,
		endpoint,
		maximum_distance,
		maximum_count
	)''')

text = replace_function(text, "_is_walk_segment_clear(", '''func _is_walk_segment_clear(from_position: Vector3, to_position: Vector3) -> bool:
	return EnemyNavigationRuntime.has_clearance_segment(
		self,
		from_position,
		to_position,
		navigation_collision_mask,
		navigation_clearance
	)''')

text = replace_function(text, "_is_center_segment_clear(", '''func _is_center_segment_clear(from_position: Vector3, to_position: Vector3) -> bool:
	return EnemyNavigationRuntime.is_center_segment_clear(
		self,
		from_position,
		to_position,
		navigation_collision_mask
	)''')

base_path.write_text(text, encoding="utf-8")
