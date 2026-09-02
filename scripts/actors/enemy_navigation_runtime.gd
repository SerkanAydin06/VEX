class_name VexEnemyNavigationRuntime
extends RefCounted

# Shared runtime navigation for every enemy family. It samples the real physics
# world, so no creature-specific waypoint graph is required during active chase.

static func resolve_enemy_door_step(
    host: Node3D,
    target_position: Vector3,
    navigation_clearance: float,
    reach_distance: float
) -> Vector3:
    if host == null or not host.is_inside_tree():
        return target_position
    var best_point := target_position
    var best_score := INF
    var best_door: Node = null
    for node: Node in host.get_tree().get_nodes_in_group("enemy_navigation_door"):
        if not node.has_method("get_enemy_navigation_step"):
            continue
        var route: Variant = node.call(
            "get_enemy_navigation_step",
            host.global_position,
            target_position,
            navigation_clearance,
            reach_distance
        )
        if not (route is Dictionary):
            continue
        var data := route as Dictionary
        if not bool(data.get("valid", false)):
            continue
        var point: Variant = data.get("point", target_position)
        if typeof(point) != TYPE_VECTOR3:
            continue
        var score := float(data.get("score", INF))
        if score < best_score:
            best_score = score
            best_point = point
            best_door = node
    if best_door != null and best_door.has_method("request_enemy_open"):
        best_door.call("request_enemy_open")
    return best_point


static func build_shortest_path(
    host: CharacterBody3D,
    destination: Vector3,
    navigation_collision_mask: int,
    floor_collision_mask: int,
    navigation_clearance: float,
    floor_ray_start_height: float,
    floor_ray_extra_depth: float,
    requested_grid_step: float,
    max_nodes: int,
    search_margin: float
) -> PackedVector3Array:
    if host == null or host.get_world_3d() == null:
        return PackedVector3Array()

    var start: Vector3 = host.global_position
    start.y = host.global_position.y
    var target: Vector3 = destination
    target.y = host.global_position.y

    if has_walk_segment_clear(
        host,
        start,
        target,
        navigation_collision_mask,
        floor_collision_mask,
        navigation_clearance,
        floor_ray_start_height,
        floor_ray_extra_depth
    ):
        return PackedVector3Array([start, target])

    var step: float = maxf(requested_grid_step, navigation_clearance * 1.20)
    var delta: Vector3 = target - start
    var goal_cell := Vector2i(roundi(delta.x / step), roundi(delta.z / step))
    if goal_cell == Vector2i.ZERO:
        return PackedVector3Array()

    var margin_cells: int = maxi(4, ceili(search_margin / step))
    var min_cell_x: int = mini(0, goal_cell.x) - margin_cells
    var max_cell_x: int = maxi(0, goal_cell.x) + margin_cells
    var min_cell_y: int = mini(0, goal_cell.y) - margin_cells
    var max_cell_y: int = maxi(0, goal_cell.y) + margin_cells

    var start_cell := Vector2i.ZERO
    var open_heap: Array[Dictionary] = []
    var came_from: Dictionary = {}
    var g_score: Dictionary = {start_cell: 0.0}
    var closed: Dictionary = {}
    var initial_heuristic: float = Vector2(float(goal_cell.x), float(goal_cell.y)).length()
    _heap_push(open_heap, start_cell, initial_heuristic)

    var best_cell: Vector2i = start_cell
    var best_distance: float = _horizontal_distance(start, target)
    var found_cell: Vector2i = start_cell
    var found_destination := false
    var explored := 0
    var neighbor_steps: Array[Vector2i] = [
        Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
        Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
    ]

    while not open_heap.is_empty() and explored < max_nodes:
        var entry: Dictionary = _heap_pop(open_heap)
        var current_cell: Vector2i = entry.get("cell", Vector2i.ZERO)
        if closed.has(current_cell):
            continue
        closed[current_cell] = true
        explored += 1

        var current_world: Vector3 = _grid_world(start, current_cell, step)
        var remaining: float = _horizontal_distance(current_world, target)
        if remaining < best_distance:
            best_distance = remaining
            best_cell = current_cell

        if (
            remaining <= maxf(step * 3.0, 4.0)
            and has_walk_segment_clear(
                host,
                current_world,
                target,
                navigation_collision_mask,
                floor_collision_mask,
                navigation_clearance,
                floor_ray_start_height,
                floor_ray_extra_depth
            )
        ):
            found_cell = current_cell
            found_destination = true
            break

        var current_g: float = float(g_score.get(current_cell, INF))
        for neighbor_step: Vector2i in neighbor_steps:
            var next_cell: Vector2i = current_cell + neighbor_step
            if (
                next_cell.x < min_cell_x
                or next_cell.x > max_cell_x
                or next_cell.y < min_cell_y
                or next_cell.y > max_cell_y
                or closed.has(next_cell)
            ):
                continue

            var next_world: Vector3 = _grid_world(start, next_cell, step)
            if not _has_floor(
                host,
                next_world,
                floor_collision_mask,
                floor_ray_start_height,
                floor_ray_extra_depth
            ):
                continue
            if not _segment_collision_clear(
                host,
                current_world,
                next_world,
                navigation_collision_mask,
                navigation_clearance
            ):
                continue

            var diagonal: bool = neighbor_step.x != 0 and neighbor_step.y != 0
            var travel_cost: float = 1.41421356 if diagonal else 1.0
            var tentative_g: float = current_g + travel_cost
            if tentative_g >= float(g_score.get(next_cell, INF)):
                continue

            came_from[next_cell] = current_cell
            g_score[next_cell] = tentative_g
            var heuristic: float = Vector2(
                float(goal_cell.x - next_cell.x),
                float(goal_cell.y - next_cell.y)
            ).length()
            _heap_push(open_heap, next_cell, tentative_g + heuristic)

    if not found_destination:
        if best_distance >= _horizontal_distance(start, target) - step * 0.5:
            return PackedVector3Array()
        found_cell = best_cell

    var cell_path: Array[Vector2i] = []
    var cursor: Vector2i = found_cell
    cell_path.push_front(cursor)
    while cursor != start_cell:
        if not came_from.has(cursor):
            return PackedVector3Array()
        cursor = came_from[cursor]
        cell_path.push_front(cursor)

    var world_path := PackedVector3Array([start])
    for path_cell: Vector2i in cell_path:
        if path_cell == start_cell:
            continue
        world_path.append(_grid_world(start, path_cell, step))
    if found_destination:
        world_path.append(target)

    return _simplify_path(
        host,
        world_path,
        navigation_collision_mask,
        floor_collision_mask,
        navigation_clearance,
        floor_ray_start_height,
        floor_ray_extra_depth
    )


static func has_walk_segment_clear(
    host: CharacterBody3D,
    from_position: Vector3,
    to_position: Vector3,
    navigation_collision_mask: int,
    floor_collision_mask: int,
    navigation_clearance: float,
    floor_ray_start_height: float,
    floor_ray_extra_depth: float
) -> bool:
    if not _segment_collision_clear(
        host,
        from_position,
        to_position,
        navigation_collision_mask,
        navigation_clearance
    ):
        return false

    var horizontal: Vector3 = to_position - from_position
    horizontal.y = 0.0
    var distance: float = horizontal.length()
    if distance <= 0.05:
        return true
    var floor_samples: int = maxi(1, ceili(distance / maxf(1.35, navigation_clearance * 1.8)))
    for sample_index: int in range(1, floor_samples + 1):
        var ratio: float = float(sample_index) / float(floor_samples)
        var probe_position: Vector3 = from_position.lerp(to_position, ratio)
        probe_position.y = host.global_position.y
        if not _has_floor(
            host,
            probe_position,
            floor_collision_mask,
            floor_ray_start_height,
            floor_ray_extra_depth
        ):
            return false
    return true


static func has_reached_walkable_target(
    host: CharacterBody3D,
    target: Vector3,
    reach_distance: float,
    navigation_collision_mask: int,
    floor_collision_mask: int,
    navigation_clearance: float,
    floor_ray_start_height: float,
    floor_ray_extra_depth: float
) -> bool:
    if _horizontal_distance(host.global_position, target) > reach_distance:
        return false
    return has_walk_segment_clear(
        host,
        host.global_position,
        target,
        navigation_collision_mask,
        floor_collision_mask,
        navigation_clearance,
        floor_ray_start_height,
        floor_ray_extra_depth
    )


static func choose_idle_wander_target(
    host: CharacterBody3D,
    anchor: Vector3,
    radius: float,
    navigation_collision_mask: int,
    floor_collision_mask: int,
    navigation_clearance: float,
    floor_ray_start_height: float,
    floor_ray_extra_depth: float,
    attempt_count: int = 12,
    minimum_radius_ratio: float = 0.35
) -> Vector3:
    var flat_anchor: Vector3 = anchor
    flat_anchor.y = host.global_position.y
    var best_target: Vector3 = host.global_position
    var best_distance := 0.0
    for _attempt: int in range(maxi(1, attempt_count)):
        var angle: float = randf_range(0.0, TAU)
        var clamped_minimum_ratio := clampf(minimum_radius_ratio, 0.0, 1.0)
        var distance: float = randf_range(radius * clamped_minimum_ratio, radius)
        var candidate := flat_anchor + Vector3(cos(angle), 0.0, sin(angle)) * distance
        candidate.y = host.global_position.y
        if not _has_floor(
            host,
            candidate,
            floor_collision_mask,
            floor_ray_start_height,
            floor_ray_extra_depth
        ):
            continue
        if not has_walk_segment_clear(
            host,
            host.global_position,
            candidate,
            navigation_collision_mask,
            floor_collision_mask,
            navigation_clearance,
            floor_ray_start_height,
            floor_ray_extra_depth
        ):
            continue
        var candidate_distance: float = _horizontal_distance(host.global_position, candidate)
        if candidate_distance > best_distance:
            best_distance = candidate_distance
            best_target = candidate
    return best_target


static func _segment_collision_clear(
    host: CharacterBody3D,
    from_position: Vector3,
    to_position: Vector3,
    navigation_collision_mask: int,
    navigation_clearance: float
) -> bool:
    var direction: Vector3 = to_position - from_position
    direction.y = 0.0
    if direction.length_squared() <= 0.01:
        return true
    var perpendicular := Vector3(-direction.z, 0.0, direction.x).normalized()
    perpendicular *= navigation_clearance
    var offsets: Array[Vector3] = [Vector3.ZERO, perpendicular, -perpendicular]
    var space_state := host.get_world_3d().direct_space_state
    for offset: Vector3 in offsets:
        var ray_start: Vector3 = from_position + offset
        var ray_end: Vector3 = to_position + offset
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


static func _has_floor(
    host: CharacterBody3D,
    probe_position: Vector3,
    floor_collision_mask: int,
    floor_ray_start_height: float,
    floor_ray_extra_depth: float
) -> bool:
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


static func _grid_world(origin: Vector3, cell: Vector2i, step: float) -> Vector3:
    return Vector3(
        origin.x + float(cell.x) * step,
        origin.y,
        origin.z + float(cell.y) * step
    )


static func _heap_push(heap: Array[Dictionary], cell: Vector2i, priority: float) -> void:
    var entry: Dictionary = {"cell": cell, "priority": priority}
    heap.append(entry)
    var index: int = heap.size() - 1
    while index > 0:
        var parent: int = floori(float(index - 1) / 2.0)
        if float(heap[parent].get("priority", INF)) <= priority:
            break
        heap[index] = heap[parent]
        index = parent
    heap[index] = entry


static func _heap_pop(heap: Array[Dictionary]) -> Dictionary:
    var root: Dictionary = heap[0]
    var last: Dictionary = heap.pop_back() as Dictionary
    if heap.is_empty():
        return root
    heap[0] = last
    var index := 0
    while true:
        var left: int = index * 2 + 1
        if left >= heap.size():
            break
        var right: int = left + 1
        var smallest: int = left
        if (
            right < heap.size()
            and float(heap[right].get("priority", INF))
            < float(heap[left].get("priority", INF))
        ):
            smallest = right
        if float(heap[index].get("priority", INF)) <= float(heap[smallest].get("priority", INF)):
            break
        var swap: Dictionary = heap[index]
        heap[index] = heap[smallest]
        heap[smallest] = swap
        index = smallest
    return root


static func _simplify_path(
    host: CharacterBody3D,
    path: PackedVector3Array,
    navigation_collision_mask: int,
    floor_collision_mask: int,
    navigation_clearance: float,
    floor_ray_start_height: float,
    floor_ray_extra_depth: float
) -> PackedVector3Array:
    if path.size() <= 2:
        return path
    var simplified := PackedVector3Array([path[0]])
    var anchor_index := 0
    while anchor_index < path.size() - 1:
        var next_index: int = path.size() - 1
        while (
            next_index > anchor_index + 1
            and not has_walk_segment_clear(
                host,
                path[anchor_index],
                path[next_index],
                navigation_collision_mask,
                floor_collision_mask,
                navigation_clearance,
                floor_ray_start_height,
                floor_ray_extra_depth
            )
        ):
            next_index -= 1
        simplified.append(path[next_index])
        anchor_index = next_index
    return simplified


static func _horizontal_distance(first: Vector3, second: Vector3) -> float:
    var difference: Vector3 = first - second
    difference.y = 0.0
    return difference.length()



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


static func should_refresh_path(
    has_navigation_target: bool,
    navigation_refresh_remaining: float,
    navigation_target: Vector3,
    resolved_target: Vector3,
    target_change_distance: float
) -> bool:
    if not has_navigation_target or navigation_refresh_remaining <= 0.0:
        return true
    return _horizontal_distance(navigation_target, resolved_target) > target_change_distance


static func active_movement_direction(
    current_position: Vector3,
    movement_point: Vector3,
    detour_remaining: float,
    detour_direction: Vector3
) -> Vector3:
    var direction := movement_point - current_position
    direction.y = 0.0
    if direction.length_squared() <= 0.001:
        return Vector3.ZERO
    direction = direction.normalized()
    if detour_remaining > 0.0 and detour_direction.length_squared() > 0.001:
        return detour_direction
    return direction


static func movement_speed(
    use_chase_speed: bool,
    runtime_move_speed: float,
    runtime_chase_speed: float
) -> float:
    return runtime_chase_speed if use_chase_speed else runtime_move_speed


static func detour_direction_from_collision_normal(
    collision_normal: Vector3,
    current_position: Vector3,
    movement_target: Vector3,
    wall_normal_y_threshold: float
) -> Vector3:
    var normal := collision_normal
    if absf(normal.y) >= wall_normal_y_threshold:
        return Vector3.ZERO
    normal.y = 0.0
    if normal.length_squared() <= 0.001:
        return Vector3.ZERO
    normal = normal.normalized()
    var tangent_a := Vector3(-normal.z, 0.0, normal.x)
    var tangent_b: Vector3 = -tangent_a
    var target_direction := movement_target - current_position
    target_direction.y = 0.0
    if target_direction.length_squared() > 0.001:
        target_direction = target_direction.normalized()
    return (
        tangent_a
        if tangent_a.dot(target_direction) >= tangent_b.dot(target_direction)
        else tangent_b
    )
