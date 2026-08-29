class_name VexEnemyNavigationRuntime
extends RefCounted

# Shared runtime navigation for every enemy family. It samples the real physics
# world, so no creature-specific waypoint graph is required during active chase.

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
    floor_ray_extra_depth: float
) -> Vector3:
    var flat_anchor: Vector3 = anchor
    flat_anchor.y = host.global_position.y
    var best_target: Vector3 = host.global_position
    var best_distance := 0.0
    for _attempt: int in range(12):
        var angle: float = randf_range(0.0, TAU)
        var distance: float = randf_range(radius * 0.35, radius)
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
