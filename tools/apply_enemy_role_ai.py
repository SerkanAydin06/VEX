from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, text: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f"missing block: {label}")
    return text.replace(old, new, 1)


def sub_once(text: str, pattern: str, replacement: str, label: str, flags: int = re.S) -> str:
    result, count = re.subn(pattern, replacement, text, count=1, flags=flags)
    if count != 1:
        raise RuntimeError(f"regex mismatch {label}: {count}")
    return result


PROFILE_SCRIPT = r'''class_name VexEnemyCombatProfiles
extends RefCounted

# Combat role is the only tactical classification used by the shared enemy AI.
# Creature identity never decides navigation or spacing behavior.
enum Role {
    CLOSE,
    MID,
    LONG,
}


static func preferred_distance(role: int, attack_range: float) -> float:
    match role:
        Role.CLOSE:
            return maxf(0.75, minf(1.40, attack_range * 0.78))
        Role.MID:
            return maxf(2.50, attack_range * 0.62)
        Role.LONG:
            return maxf(5.00, attack_range * 0.78)
        _:
            return maxf(0.75, attack_range * 0.62)


static func minimum_distance(role: int, attack_range: float) -> float:
    var preferred: float = preferred_distance(role, attack_range)
    match role:
        Role.CLOSE:
            return 0.0
        Role.MID:
            return preferred * 0.52
        Role.LONG:
            return preferred * 0.68
        _:
            return 0.0


static func cover_visibility_threshold(role: int) -> float:
    match role:
        Role.MID:
            return 0.45
        Role.LONG:
            return 0.65
        _:
            return 0.0


static func uses_multi_sample_visibility(role: int) -> bool:
    return role == Role.MID or role == Role.LONG


static func uses_cover_reposition(role: int, has_projectile: bool) -> bool:
    return has_projectile and (role == Role.MID or role == Role.LONG)


static func cover_reposition_distance(role: int) -> float:
    return 3.0 if role == Role.LONG else 2.15


static func recovery_strafe_scale(role: int) -> float:
    match role:
        Role.MID:
            return 0.72
        Role.LONG:
            return 1.0
        _:
            return 0.0


static func retreat_scale(role: int) -> float:
    match role:
        Role.MID:
            return 0.58
        Role.LONG:
            return 0.92
        _:
            return 0.0


static func idle_wander_radius(role: int) -> float:
    match role:
        Role.CLOSE:
            return 2.8
        Role.MID:
            return 2.0
        Role.LONG:
            return 1.35
        _:
            return 2.0


static func idle_pause_min(role: int) -> float:
    return 0.35 if role == Role.CLOSE else 0.55


static func idle_pause_max(role: int) -> float:
    return 1.20 if role == Role.LONG else 0.95


static func path_refresh_interval(role: int) -> float:
    match role:
        Role.CLOSE:
            return 0.30
        Role.MID:
            return 0.36
        Role.LONG:
            return 0.44
        _:
            return 0.36


static func path_target_change_distance(role: int) -> float:
    match role:
        Role.CLOSE:
            return 1.20
        Role.MID:
            return 1.65
        Role.LONG:
            return 2.20
        _:
            return 1.50


static func grid_step(role: int) -> float:
    match role:
        Role.CLOSE:
            return 0.78
        Role.MID:
            return 0.92
        Role.LONG:
            return 1.08
        _:
            return 0.92


static func grid_max_nodes(role: int) -> int:
    match role:
        Role.CLOSE:
            return 2600
        Role.MID:
            return 2300
        Role.LONG:
            return 2000
        _:
            return 2200


static func grid_search_margin(role: int) -> float:
    match role:
        Role.CLOSE:
            return 18.0
        Role.MID:
            return 15.0
        Role.LONG:
            return 13.0
        _:
            return 15.0
'''


NAV_SCRIPT = r'''class_name VexEnemyNavigationRuntime
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
'''


# ---------------------------------------------------------------------------
# Ravager-family shared behavior
# ---------------------------------------------------------------------------
ravager = read("scripts/actors/ravager.gd")
ravager = replace_once(
    ravager,
    "class_name VexRavager\nextends CharacterBody3D\n",
    "class_name VexRavager\nextends CharacterBody3D\n\nconst EnemyCombatProfiles = preload(\"res://scripts/actors/enemy_combat_profiles.gd\")\nconst EnemyNavigationRuntime = preload(\"res://scripts/actors/enemy_navigation_runtime.gd\")\n",
    "ravager preloads",
)
ravager = replace_once(
    ravager,
    '@export var enemy_id: StringName = &"ravager"\n',
    '@export var enemy_id: StringName = &"ravager"\n@export_enum("Yakın", "Orta", "Uzak") var combat_role: int = EnemyCombatProfiles.Role.MID\n',
    "ravager role export",
)
ravager = ravager.replace('@export_category("02 - Hareket ve Devriye")', '@export_category("02 - Hareket ve Boşta Gezinme")', 1)
ravager = replace_once(
    ravager,
    '@export_range(0.5, 10.0, 0.1) var move_speed := 2.7\n',
    '@export_range(0.5, 10.0, 0.1) var move_speed := 2.7\n@export_range(0.0, 16.0, 0.1) var chase_speed := 0.0\n',
    "ravager chase speed",
)
ravager = replace_once(
    ravager,
    'var _spawn_position := Vector3.ZERO\nvar _patrol_forward := true\n',
    'var _spawn_position := Vector3.ZERO\nvar _idle_anchor_position := Vector3.ZERO\nvar _idle_wander_target := Vector3.ZERO\nvar _has_idle_wander_target := false\nvar _idle_wander_pause_remaining := 0.0\nvar _patrol_forward := true\n',
    "ravager idle state",
)
ravager = replace_once(
    ravager,
    'var _damage_reaction_remaining := 0.0\n',
    'var _damage_reaction_remaining := 0.0\nvar _forced_damage_target := Vector3.ZERO\nvar _has_forced_damage_target := false\nvar _forced_damage_best_distance := INF\nvar _forced_damage_stall_remaining := 0.0\nvar _combat_interrupt_generation := 0\n',
    "ravager damage pursuit state",
)
ravager = replace_once(
    ravager,
    'var _runtime_move_speed := 0.5\n',
    'var _runtime_move_speed := 0.5\nvar _runtime_chase_speed := 0.5\n',
    "ravager runtime chase",
)
ravager = replace_once(
    ravager,
    '\t_spawn_position = global_position\n',
    '\t_spawn_position = global_position\n\t_idle_anchor_position = global_position\n',
    "ravager idle anchor ready",
)
ravager = sub_once(
    ravager,
    r'\n\tvar initial_patrol_direction := patrol_offset\n.*?\n\tif GameState\.was_enemy_defeated',
    '\n\tif GameState.was_enemy_defeated',
    "remove fixed patrol facing",
)
ravager = replace_once(
    ravager,
    '\t_runtime_move_speed = move_speed\n',
    '\t_runtime_move_speed = move_speed\n\t_runtime_chase_speed = chase_speed if chase_speed > 0.0 else move_speed\n',
    "ravager base chase runtime",
)
ravager = replace_once(
    ravager,
    '\t_runtime_move_speed = maxf(0.0, move_speed * speed_scale)\n',
    '\t_runtime_move_speed = maxf(0.0, move_speed * speed_scale)\n\t_runtime_chase_speed = maxf(0.0, (chase_speed if chase_speed > 0.0 else move_speed) * speed_scale)\n',
    "ravager scaled chase runtime",
)

ravager_damage_block = r'''\thealth -= amount
\t_exit_dormant_mode\(\)
\tif aggro_on_damage:
.*?
\tif health <= 0:'''
ravager_damage_replacement = '''\thealth -= amount
\t_exit_dormant_mode()
\t# Damage pursuit is mandatory and has higher priority than sight/range/attack state.
\t_alerted = true
\t_combat_interrupt_generation += 1
\t_attack_locked = false
\t_attack_windup_active = false
\tstate = State.CHASE
\t_damage_reaction_remaining = damage_reaction_duration
\t_seconds_without_sight = 0.0
\t_search_remaining = 0.0
\t_sight_check_remaining = 0.0
\tvar retaliation_target := Vector3.ZERO
\tvar has_retaliation_target := false
\tif _source is Node3D:
\t\tretaliation_target = (_source as Node3D).global_position
\t\thas_retaliation_target = true
\telif _player != null and is_instance_valid(_player):
\t\tretaliation_target = _player.global_position
\t\thas_retaliation_target = true
\tif has_retaliation_target:
\t\tretaliation_target.y = global_position.y
\t\t_forced_damage_target = retaliation_target
\t\t_has_forced_damage_target = true
\t\t_forced_damage_best_distance = _horizontal_distance(global_position, retaliation_target)
\t\t_forced_damage_stall_remaining = 3.0
\t\t_last_seen_position = retaliation_target
\t\t_has_last_seen_position = true
\t_path_refresh_remaining = 0.0
\t_ranged_reposition_remaining = 0.0
\t_has_ranged_reposition_target = false
\t_local_detour_remaining = 0.0
\t_local_detour_side = 0.0
\t_clear_path()
\tif _has_last_seen_position:
\t\t_face_toward_position(_last_seen_position)
\tif alert_allies_on_damage:
\t\t_alert_nearby_allies(_last_seen_position if _has_last_seen_position else global_position)

\tif health <= 0:'''
ravager = sub_once(ravager, ravager_damage_block, ravager_damage_replacement, "ravager immediate damage pursuit")

ravager = replace_once(
    ravager,
    'func _update_behavior(delta: float) -> void:\n',
    '''func _update_behavior(delta: float) -> void:
\t# A hit immediately overrides normal combat. Reach the exact source position,
\t# or the closest reachable point, before resuming normal role tactics.
\tif _has_forced_damage_target:
\t\tvar forced_distance := _horizontal_distance(global_position, _forced_damage_target)
\t\tif forced_distance < _forced_damage_best_distance - 0.20:
\t\t\t_forced_damage_best_distance = forced_distance
\t\t\t_forced_damage_stall_remaining = 3.0
\t\telse:
\t\t\t_forced_damage_stall_remaining = maxf(0.0, _forced_damage_stall_remaining - delta)
\t\tif _has_reached_walkable_target(_forced_damage_target, waypoint_reach_distance):
\t\t\t_has_forced_damage_target = false
\t\t\t_damage_reaction_remaining = 0.0
\t\t\t_last_seen_position = _forced_damage_target
\t\t\t_has_last_seen_position = true
\t\t\t_begin_search()
\t\t\treturn
\t\tstate = State.CHASE
\t\t_navigate_to(_forced_damage_target, delta)
\t\tif (
\t\t\t_forced_damage_stall_remaining <= 0.0
\t\t\tand (_current_path.is_empty() or _path_index >= _current_path.size())
\t\t):
\t\t\t_has_forced_damage_target = false
\t\t\t_damage_reaction_remaining = 0.0
\t\t\t_last_seen_position = _forced_damage_target
\t\t\t_has_last_seen_position = true
\t\t\t_begin_search()
\t\treturn
''',
    "ravager forced branch",
)

ravager = ravager.replace('_last_visibility_ratio < ranged_cover_visibility_threshold', '_last_visibility_ratio < _cover_visibility_threshold()')
ravager = ravager.replace('if ratio >= ranged_cover_visibility_threshold:', 'if ratio >= _cover_visibility_threshold():')
ravager = replace_once(
    ravager,
    '\t\tvar radius := ranged_cover_reposition_distance\n',
    '\t\tvar radius := EnemyCombatProfiles.cover_reposition_distance(combat_role)\n',
    "role cover distance",
)

ravager = sub_once(
    ravager,
    r'func _patrol\(delta: float\) -> void:\n.*?\n\n\nfunc _return_to_patrol',
    '''func _patrol(delta: float) -> void:
\tstate = State.PATROL
\tif _idle_wander_pause_remaining > 0.0:
\t\t_idle_wander_pause_remaining = maxf(0.0, _idle_wander_pause_remaining - delta)
\t\t_stop_horizontal_motion()
\t\t_facing_direction = _facing_direction.rotated(Vector3.UP, delta * 0.28).normalized()
\t\trotation.y = atan2(-_facing_direction.x, -_facing_direction.z)
\t\treturn

\tif (
\t\tnot _has_idle_wander_target
\t\tor _has_reached_walkable_target(_idle_wander_target, waypoint_reach_distance)
\t):
\t\tvar radius := EnemyCombatProfiles.idle_wander_radius(combat_role)
\t\t_idle_wander_target = EnemyNavigationRuntime.choose_idle_wander_target(
\t\t\tself,
\t\t\t_idle_anchor_position,
\t\t\tradius,
\t\t\tnavigation_collision_mask,
\t\t\tfloor_collision_mask,
\t\t\tnavigation_clearance,
\t\t\tfloor_snap_ray_start_height,
\t\t\tfloor_snap_ray_extra_depth
\t\t)
\t\t_has_idle_wander_target = _horizontal_distance(global_position, _idle_wander_target) > 0.25
\t\tif not _has_idle_wander_target:
\t\t\t_idle_wander_pause_remaining = randf_range(
\t\t\t\tEnemyCombatProfiles.idle_pause_min(combat_role),
\t\t\t\tEnemyCombatProfiles.idle_pause_max(combat_role)
\t\t\t)
\t\t\t_stop_horizontal_motion()
\t\t\treturn
\t\t_clear_path()
\t\t_path_refresh_remaining = 0.0

\t_navigate_to(_idle_wander_target, delta)
\tif _has_reached_walkable_target(_idle_wander_target, waypoint_reach_distance):
\t\t_has_idle_wander_target = false
\t\t_idle_wander_pause_remaining = randf_range(
\t\t\tEnemyCombatProfiles.idle_pause_min(combat_role),
\t\t\tEnemyCombatProfiles.idle_pause_max(combat_role)
\t\t)


func _return_to_patrol''',
    "ravager random idle wander",
)
ravager = sub_once(
    ravager,
    r'func _return_to_patrol\(delta: float\) -> void:\n.*?\n\n\nfunc _begin_search',
    '''func _return_to_patrol(_delta: float) -> void:
\t# No fixed patrol route: after combat the current position becomes the new
\t# local idle anchor and the creature resumes contextual wandering there.
\t_idle_anchor_position = global_position
\t_has_idle_wander_target = false
\t_idle_wander_pause_remaining = randf_range(
\t\tEnemyCombatProfiles.idle_pause_min(combat_role),
\t\tEnemyCombatProfiles.idle_pause_max(combat_role)
\t)
\tstate = State.PATROL
\t_clear_path()
\t_stop_horizontal_motion()


func _begin_search''',
    "ravager no return route",
)
ravager = sub_once(
    ravager,
    r'func _give_up_chase\(\) -> void:\n.*?\n\n\nfunc _navigate_to',
    '''func _give_up_chase() -> void:
\t_alerted = false
\t_player_visible = false
\t_seconds_without_sight = 0.0
\t_search_remaining = 0.0
\t_has_last_seen_position = false
\t_has_forced_damage_target = false
\t_reset_search_probe()
\t_idle_anchor_position = global_position
\t_has_idle_wander_target = false
\t_idle_wander_pause_remaining = randf_range(
\t\tEnemyCombatProfiles.idle_pause_min(combat_role),
\t\tEnemyCombatProfiles.idle_pause_max(combat_role)
\t)
\tstate = State.PATROL
\t_clear_path()
\t_stop_horizontal_motion()


func _navigate_to''',
    "ravager give up to local idle",
)
ravager = replace_once(
    ravager,
    '''\tvar target_changed := (
\t\tnot _has_path_target
\t\tor _horizontal_distance(_path_target, destination) > path_target_change_distance
\t)
\tvar refresh_interval := path_refresh_interval
''',
    '''\tvar role_target_change := EnemyCombatProfiles.path_target_change_distance(combat_role)
\tvar target_changed := (
\t\tnot _has_path_target
\t\tor _horizontal_distance(_path_target, destination) > role_target_change
\t)
\tvar refresh_interval := (
\t\tEnemyCombatProfiles.path_refresh_interval(combat_role)
\t\tif state == State.CHASE
\t\telse path_refresh_interval
\t)
''',
    "ravager role path refresh",
)
ravager = sub_once(
    ravager,
    r'func _build_runtime_shortest_path\(destination: Vector3\) -> PackedVector3Array:\n.*?\n\n\nfunc _build_local_detour_path',
    '''func _build_runtime_shortest_path(destination: Vector3) -> PackedVector3Array:
\treturn EnemyNavigationRuntime.build_shortest_path(
\t\tself,
\t\tdestination,
\t\tnavigation_collision_mask,
\t\tfloor_collision_mask,
\t\tnavigation_clearance,
\t\tfloor_snap_ray_start_height,
\t\tfloor_snap_ray_extra_depth,
\t\tEnemyCombatProfiles.grid_step(combat_role),
\t\tEnemyCombatProfiles.grid_max_nodes(combat_role),
\t\tEnemyCombatProfiles.grid_search_margin(combat_role)
\t)


func _build_local_detour_path''',
    "shared runtime navigation",
)
ravager = sub_once(
    ravager,
    r'func _uses_ranged_tactics\(\) -> bool:\n.*?\n\n\nfunc _damage_source_approach_position',
    '''func _uses_ranged_tactics() -> bool:
\treturn EnemyCombatProfiles.uses_multi_sample_visibility(combat_role)


func _uses_cover_reposition_tactics() -> bool:
\treturn EnemyCombatProfiles.uses_cover_reposition(
\t\tcombat_role,
\t\tprojectile_scene != null
\t)


func _cover_visibility_threshold() -> float:
\treturn EnemyCombatProfiles.cover_visibility_threshold(combat_role)


func _damage_source_approach_position''',
    "role tactic selectors",
)
ravager = sub_once(
    ravager,
    r'func _move_during_attack_recovery\(target: Vector3, delta: float\) -> void:\n.*?\n\n\nfunc _stop_horizontal_motion',
    '''func _move_during_attack_recovery(target: Vector3, delta: float) -> void:
\tvar direction_to_target := target - global_position
\tdirection_to_target.y = 0.0
\tvar distance_to_target := direction_to_target.length()
\tif distance_to_target <= 0.001:
\t\t_stop_horizontal_motion()
\t\treturn

\tvar forward_direction := direction_to_target / distance_to_target
\tvar right_direction := forward_direction.cross(Vector3.UP).normalized()
\tvar preferred_distance := EnemyCombatProfiles.preferred_distance(combat_role, attack_range)
\tvar minimum_distance := EnemyCombatProfiles.minimum_distance(combat_role, attack_range)
\tvar speed_scale := _runtime_move_speed / maxf(move_speed, 0.001)
\tvar desired_velocity := Vector3.ZERO

\tvar strafe_scale := EnemyCombatProfiles.recovery_strafe_scale(combat_role)
\tif strafe_scale > 0.0 and attack_strafe_speed > 0.0:
\t\tdesired_velocity += (
\t\t\tright_direction
\t\t\t* attack_strafe_speed
\t\t\t* _attack_strafe_direction
\t\t\t* speed_scale
\t\t\t* strafe_scale
\t\t)

\tif combat_role == EnemyCombatProfiles.Role.CLOSE:
\t\tif distance_to_target > preferred_distance:
\t\t\tdesired_velocity = forward_direction * _runtime_chase_speed
\telif distance_to_target > preferred_distance + 0.35:
\t\tvar approach_speed := maxf(attack_approach_speed * speed_scale, _runtime_move_speed * 0.45)
\t\tdesired_velocity += forward_direction * approach_speed
\telif distance_to_target < minimum_distance:
\t\tdesired_velocity -= (
\t\t\tforward_direction
\t\t\t* _runtime_move_speed
\t\t\t* EnemyCombatProfiles.retreat_scale(combat_role)
\t\t)

\tvar maximum_speed := _runtime_chase_speed if combat_role == EnemyCombatProfiles.Role.CLOSE else _runtime_move_speed
\tif desired_velocity.length() > maximum_speed:
\t\tdesired_velocity = desired_velocity.normalized() * maximum_speed

\t_facing_direction = forward_direction
\trotation.y = atan2(-_facing_direction.x, -_facing_direction.z)
\tif desired_velocity.length_squared() <= 0.001:
\t\t_stop_horizontal_motion()
\t\treturn

\tvelocity.x = move_toward(velocity.x, desired_velocity.x, delta * movement_acceleration)
\tvelocity.z = move_toward(velocity.z, desired_velocity.z, delta * movement_acceleration)
\tif animated_sprite.animation != &"hurt":
\t\t_play_directional_animation(&"walk", &"walk_back")


func _stop_horizontal_motion''',
    "role attack recovery",
)
ravager = replace_once(
    ravager,
    '''\tdirection = direction.normalized()
\t_facing_direction = direction
\tvelocity.x = move_toward(
\t\tvelocity.x,
\t\tdirection.x * _runtime_move_speed,
\t\tdelta * movement_acceleration
\t)
\tvelocity.z = move_toward(
\t\tvelocity.z,
\t\tdirection.z * _runtime_move_speed,
\t\tdelta * movement_acceleration
\t)
''',
    '''\tdirection = direction.normalized()
\t_facing_direction = direction
\tvar travel_speed := (
\t\t_runtime_chase_speed
\t\tif state == State.CHASE or state == State.SEARCH
\t\telse _runtime_move_speed
\t)
\tvelocity.x = move_toward(
\t\tvelocity.x,
\t\tdirection.x * travel_speed,
\t\tdelta * movement_acceleration
\t)
\tvelocity.z = move_toward(
\t\tvelocity.z,
\t\tdirection.z * travel_speed,
\t\tdelta * movement_acceleration
\t)
''',
    "ravager role travel speed",
)

# Attack coroutines are invalidated immediately by incoming damage.
ravager = replace_once(
    ravager,
    'func _attempt_attack() -> void:\n\tif _attack_locked:\n\t\treturn\n\t_attack_locked = true\n',
    'func _attempt_attack() -> void:\n\tif _attack_locked:\n\t\treturn\n\tvar combat_generation := _combat_interrupt_generation\n\t_attack_locked = true\n',
    "ravager attack generation capture",
)
ravager = ravager.replace(
    'if not is_inside_tree() or state == State.DEAD:\n\t\treturn\n',
    'if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:\n\t\treturn\n',
    2,
)

# ---------------------------------------------------------------------------
# RedViper-family: same role model and same global runtime navigation.
# ---------------------------------------------------------------------------
red = read("scripts/actors/redviper.gd")
red = replace_once(
    red,
    '@tool\nclass_name VexRedViper\nextends CharacterBody3D\n',
    '@tool\nclass_name VexRedViper\nextends CharacterBody3D\n\nconst EnemyCombatProfiles = preload("res://scripts/actors/enemy_combat_profiles.gd")\nconst EnemyNavigationRuntime = preload("res://scripts/actors/enemy_navigation_runtime.gd")\n',
    "redviper preloads",
)
red = replace_once(
    red,
    '@export var enemy_id: StringName = &"redviper"\n',
    '@export var enemy_id: StringName = &"redviper"\n@export_enum("Yakın", "Orta", "Uzak") var combat_role: int = EnemyCombatProfiles.Role.CLOSE\n',
    "redviper role export",
)
red = red.replace('@export_category("02 - Hareket ve Devriye")', '@export_category("02 - Hareket ve Boşta Gezinme")', 1)
red = replace_once(
    red,
    '@export_range(0.0, 3.0, 0.05) var detour_duration := 0.55\n',
    '@export_range(0.0, 3.0, 0.05) var detour_duration := 0.55\n@export_range(0.3, 1.2, 0.05) var navigation_clearance := 0.55\n@export_flags_3d_physics var navigation_collision_mask := 1 | 8\n',
    "redviper navigation exports",
)
red = replace_once(
    red,
    'var _spawn_position := Vector3.ZERO\nvar _patrol_forward := true\n',
    'var _spawn_position := Vector3.ZERO\nvar _idle_anchor_position := Vector3.ZERO\nvar _idle_wander_target := Vector3.ZERO\nvar _has_idle_wander_target := false\nvar _patrol_forward := true\n',
    "redviper idle state",
)
red = replace_once(
    red,
    'var _damage_reaction_remaining := 0.0\n',
    'var _damage_reaction_remaining := 0.0\nvar _forced_damage_target := Vector3.ZERO\nvar _has_forced_damage_target := false\nvar _forced_damage_best_distance := INF\nvar _forced_damage_stall_remaining := 0.0\n',
    "redviper forced damage",
)
red = replace_once(
    red,
    'var _movement_target := Vector3.ZERO\n',
    'var _movement_target := Vector3.ZERO\nvar _navigation_path := PackedVector3Array()\nvar _navigation_path_index := 0\nvar _navigation_target := Vector3.ZERO\nvar _has_navigation_target := false\nvar _navigation_refresh_remaining := 0.0\n',
    "redviper path state",
)
red = replace_once(
    red,
    '\t_spawn_position = global_position\n',
    '\t_spawn_position = global_position\n\t_idle_anchor_position = global_position\n',
    "redviper idle anchor ready",
)
red = replace_once(
    red,
    '\t_damage_reaction_remaining = maxf(0.0, _damage_reaction_remaining - delta)\n',
    '\t_damage_reaction_remaining = maxf(0.0, _damage_reaction_remaining - delta)\n\t_navigation_refresh_remaining = maxf(0.0, _navigation_refresh_remaining - delta)\n',
    "redviper nav refresh tick",
)
red = replace_once(
    red,
    '''\t_apply_gravity(delta)
\t_detour_remaining = maxf(0.0, _detour_remaining - delta)
\t# Saldırı hazırlığında oyuncuyu kısa bir ileri hamleyle takip et. Böylece
''',
    '''\t_apply_gravity(delta)
\t_detour_remaining = maxf(0.0, _detour_remaining - delta)

\t# Damage direction has absolute priority, even over an attack windup.
\tif _has_forced_damage_target:
\t\tvar forced_distance := _horizontal_distance(global_position, _forced_damage_target)
\t\tif forced_distance < _forced_damage_best_distance - 0.20:
\t\t\t_forced_damage_best_distance = forced_distance
\t\t\t_forced_damage_stall_remaining = 3.0
\t\telse:
\t\t\t_forced_damage_stall_remaining = maxf(0.0, _forced_damage_stall_remaining - delta)
\t\tif EnemyNavigationRuntime.has_reached_walkable_target(
\t\t\tself,
\t\t\t_forced_damage_target,
\t\t\tinvestigation_reach_distance,
\t\t\tnavigation_collision_mask,
\t\t\tfloor_collision_mask,
\t\t\tnavigation_clearance,
\t\t\tfloor_snap_ray_start_height,
\t\t\tfloor_snap_ray_extra_depth
\t\t):
\t\t\t_has_forced_damage_target = false
\t\t\t_damage_reaction_remaining = 0.0
\t\t\t_last_seen_position = _forced_damage_target
\t\t\t_search_remaining = search_duration
\t\t\t_reset_search_probe()
\t\telse:
\t\t\t_chase_position(delta, _forced_damage_target)
\t\t\tmove_and_slide()
\t\t\t_update_chase_detour()
\t\t\tif (
\t\t\t\t_forced_damage_stall_remaining <= 0.0
\t\t\t\tand (_navigation_path.is_empty() or _navigation_path_index >= _navigation_path.size())
\t\t\t):
\t\t\t\t_has_forced_damage_target = false
\t\t\t\t_damage_reaction_remaining = 0.0
\t\t\t\t_last_seen_position = _forced_damage_target
\t\t\t\t_search_remaining = search_duration
\t\t\t\t_reset_search_probe()
\t\t\treturn

\t# Saldırı hazırlığında oyuncuyu kısa bir ileri hamleyle takip et. Böylece
''',
    "redviper forced branch",
)

# When aggro fully ends, settle around the current area instead of walking back to spawn.
red = replace_once(
    red,
    '''\t\tif _aggro:
\t\t\t_aggro = false
\t\t\t_cached_player_visible = false
\t\t\t_sight_check_remaining = 0.0
\t\t\t_lost_sight_remaining = 0.0
\t\t\t_search_remaining = 0.0
\t\t\t_reset_search_probe()
''',
    '''\t\tif _aggro:
\t\t\t_aggro = false
\t\t\t_cached_player_visible = false
\t\t\t_sight_check_remaining = 0.0
\t\t\t_lost_sight_remaining = 0.0
\t\t\t_search_remaining = 0.0
\t\t\t_reset_search_probe()
\t\t\t_idle_anchor_position = global_position
\t\t\t_has_idle_wander_target = false
\t\t\t_reset_navigation_path()
''',
    "redviper local idle after chase",
)

red = sub_once(
    red,
    r'\n\tif _wait_remaining > 0\.0:\n.*?\n\n\nfunc _chase_position',
    '''
\t_idle_wander(delta)
\treturn


func _idle_wander(delta: float) -> void:
\tif _wait_remaining > 0.0:
\t\t_wait_remaining = maxf(_wait_remaining - delta, 0.0)
\t\tvelocity.x = move_toward(velocity.x, 0.0, delta * braking_acceleration)
\t\tvelocity.z = move_toward(velocity.z, 0.0, delta * braking_acceleration)
\t\t_facing_direction = _facing_direction.rotated(Vector3.UP, delta * 0.32).normalized()
\t\trotation.y = atan2(-_facing_direction.x, -_facing_direction.z)
\t\t_play_animation(&"idle")
\t\tmove_and_slide()
\t\treturn

\tif (
\t\tnot _has_idle_wander_target
\t\tor EnemyNavigationRuntime.has_reached_walkable_target(
\t\t\tself,
\t\t\t_idle_wander_target,
\t\t\tpatrol_reach_distance,
\t\t\tnavigation_collision_mask,
\t\t\tfloor_collision_mask,
\t\t\tnavigation_clearance,
\t\t\tfloor_snap_ray_start_height,
\t\t\tfloor_snap_ray_extra_depth
\t\t)
\t):
\t\t_idle_wander_target = EnemyNavigationRuntime.choose_idle_wander_target(
\t\t\tself,
\t\t\t_idle_anchor_position,
\t\t\tEnemyCombatProfiles.idle_wander_radius(combat_role),
\t\t\tnavigation_collision_mask,
\t\t\tfloor_collision_mask,
\t\t\tnavigation_clearance,
\t\t\tfloor_snap_ray_start_height,
\t\t\tfloor_snap_ray_extra_depth
\t\t)
\t\t_has_idle_wander_target = _horizontal_distance(global_position, _idle_wander_target) > 0.25
\t\tif not _has_idle_wander_target:
\t\t\t_wait_remaining = randf_range(
\t\t\t\tEnemyCombatProfiles.idle_pause_min(combat_role),
\t\t\t\tEnemyCombatProfiles.idle_pause_max(combat_role)
\t\t\t)
\t\t\tvelocity.x = 0.0
\t\t\tvelocity.z = 0.0
\t\t\t_play_animation(&"idle")
\t\t\tmove_and_slide()
\t\t\treturn
\t\t_reset_navigation_path()

\t_chase_position(delta, _idle_wander_target, false)
\tmove_and_slide()
\t_update_chase_detour()


func _chase_position''',
    "redviper random idle wander",
)

red = sub_once(
    red,
    r'func _chase_position\(delta: float, target_position: Vector3\) -> void:\n.*?\n\n\nfunc _update_chase_detour',
    '''func _chase_position(delta: float, target_position: Vector3, use_chase_speed: bool = true) -> void:
\tvar resolved_target := _resolve_enemy_door_step(target_position)
\tresolved_target.y = global_position.y
\t_movement_target = resolved_target

\tvar target_change_distance := EnemyCombatProfiles.path_target_change_distance(combat_role)
\tvar target_changed := (
\t\tnot _has_navigation_target
\t\tor _horizontal_distance(_navigation_target, resolved_target) > target_change_distance
\t)
\tif _navigation_refresh_remaining <= 0.0 or target_changed:
\t\t_navigation_path = EnemyNavigationRuntime.build_shortest_path(
\t\t\tself,
\t\t\tresolved_target,
\t\t\tnavigation_collision_mask,
\t\t\tfloor_collision_mask,
\t\t\tnavigation_clearance,
\t\t\tfloor_snap_ray_start_height,
\t\t\tfloor_snap_ray_extra_depth,
\t\t\tEnemyCombatProfiles.grid_step(combat_role),
\t\t\tEnemyCombatProfiles.grid_max_nodes(combat_role),
\t\t\tEnemyCombatProfiles.grid_search_margin(combat_role)
\t\t)
\t\t_navigation_path_index = 1 if _navigation_path.size() > 1 else 0
\t\t_navigation_target = resolved_target
\t\t_has_navigation_target = true
\t\t_navigation_refresh_remaining = EnemyCombatProfiles.path_refresh_interval(combat_role)

\twhile (
\t\t_navigation_path_index < _navigation_path.size()
\t\tand EnemyNavigationRuntime.has_reached_walkable_target(
\t\t\tself,
\t\t\t_navigation_path[_navigation_path_index],
\t\t\tinvestigation_reach_distance,
\t\t\tnavigation_collision_mask,
\t\t\tfloor_collision_mask,
\t\t\tnavigation_clearance,
\t\t\tfloor_snap_ray_start_height,
\t\t\tfloor_snap_ray_extra_depth
\t\t)
\t):
\t\t_navigation_path_index += 1

\tvar movement_point := resolved_target
\tif _navigation_path_index < _navigation_path.size():
\t\tmovement_point = _navigation_path[_navigation_path_index]

\tvar direction: Vector3 = movement_point - global_position
\tdirection.y = 0.0
\tif direction.length_squared() <= 0.001:
\t\tvelocity.x = 0.0
\t\tvelocity.z = 0.0
\t\t_play_animation(&"idle")
\t\treturn
\tdirection = direction.normalized()

\t# Collision tangent is now only a fallback when the shared global path is
\t# temporarily obstructed by a moving body/door.
\tif _detour_remaining > 0.0 and _detour_direction.length_squared() > 0.001:
\t\tdirection = _detour_direction

\t_facing_direction = direction
\tvar desired_speed := _runtime_chase_speed if use_chase_speed else _runtime_move_speed
\tvelocity.x = move_toward(
\t\tvelocity.x,
\t\tdirection.x * desired_speed,
\t\tdelta * movement_acceleration
\t)
\tvelocity.z = move_toward(
\t\tvelocity.z,
\t\tdirection.z * desired_speed,
\t\tdelta * movement_acceleration
\t)
\trotation.y = atan2(-direction.x, -direction.z)
\t_play_animation(&"walk")


func _reset_navigation_path() -> void:
\t_navigation_path = PackedVector3Array()
\t_navigation_path_index = 0
\t_has_navigation_target = false
\t_navigation_refresh_remaining = 0.0


func _update_chase_detour''',
    "redviper shared global navigation",
)

red_damage_pattern = r'''\thealth -= amount
\t_exit_dormant_mode\(\)
\tif health <= 0:
\t\t_die\(\)
\t\treturn

\t# Hasar tepkisi tamamen sahne ayarlarından yönetilir\.
\tif aggro_on_damage:
.*?
\tif hurt_audio\.stream != null and not hurt_audio\.playing:'''
red_damage_replacement = '''\thealth -= amount
\t_exit_dormant_mode()
\tif health <= 0:
\t\t_die()
\t\treturn

\t# Any damage immediately interrupts the current attack and forces pursuit of
\t# the exact source position, independent of sight cone or normal ranges.
\tif _player == null or not is_instance_valid(_player):
\t\t_player = GameState.player as Node3D
\t_attack_generation += 1
\t_attack_locked = false
\t_attack_lunge_remaining = 0.0
\t_aggro = true
\t_damage_reaction_remaining = damage_reaction_duration
\tvar retaliation_target := Vector3.ZERO
\tvar has_retaliation_target := false
\tif _source is Node3D:
\t\tretaliation_target = (_source as Node3D).global_position
\t\thas_retaliation_target = true
\telif _player != null and is_instance_valid(_player):
\t\tretaliation_target = _player.global_position
\t\thas_retaliation_target = true
\tif has_retaliation_target:
\t\tretaliation_target.y = global_position.y
\t\t_forced_damage_target = retaliation_target
\t\t_has_forced_damage_target = true
\t\t_forced_damage_best_distance = _horizontal_distance(global_position, retaliation_target)
\t\t_forced_damage_stall_remaining = 3.0
\t\t_last_seen_position = retaliation_target
\t_lost_sight_remaining = lost_sight_timeout
\t_search_remaining = search_duration
\t_cached_player_visible = false
\t_sight_check_remaining = 0.0
\t_detour_remaining = 0.0
\t_reset_search_probe()
\t_reset_navigation_path()
\tif has_retaliation_target:
\t\t_face_position(retaliation_target)
\tif alert_allies_on_damage:
\t\t_alert_nearby_allies(retaliation_target if has_retaliation_target else global_position)

\tif hurt_audio.stream != null and not hurt_audio.playing:'''
red = sub_once(red, red_damage_pattern, red_damage_replacement, "redviper immediate damage pursuit")
red = sub_once(
    red,
    r'\nfunc _retaliation_approach_position\(source_position: Vector3\) -> Vector3:\n.*?\n\n\nfunc _collision_floor_local_y',
    '\nfunc _collision_floor_local_y',
    "remove obsolete redviper near-side retaliation",
)

# ---------------------------------------------------------------------------
# Warden: no omniscient creature-specific chase override. Its special attacks
# remain, while shared CLOSE-role AI owns perception/navigation.
# ---------------------------------------------------------------------------
warden = read("scripts/actors/crucible_warden.gd")
warden = sub_once(
    warden,
    r'\nfunc _update_behavior\(delta: float\) -> void:\n.*?\n\n\nfunc _attempt_attack',
    '\nfunc _attempt_attack',
    "remove warden live-position override",
)
for function_name in ["_begin_ground_slam_attack", "_begin_heatwave_attack"]:
    marker = f"func {function_name}() -> void:\n"
    warden = replace_once(
        warden,
        marker,
        marker + "\tvar combat_generation := _combat_interrupt_generation\n",
        f"{function_name} generation capture",
    )
# Each Warden special has two post-await validity checks.
warden = warden.replace(
    'if not is_inside_tree() or state == State.DEAD:\n\t\treturn\n',
    'if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:\n\t\treturn\n',
    4,
)

# Furnice Carrier attack coroutine also obeys immediate damage interruption.
furnice = read("scripts/actors/furnice_carrier.gd")
furnice = replace_once(
    furnice,
    'func _attempt_attack() -> void:\n\tif _attack_locked or _player == null or not is_instance_valid(_player):\n\t\treturn\n',
    'func _attempt_attack() -> void:\n\tif _attack_locked or _player == null or not is_instance_valid(_player):\n\t\treturn\n\tvar combat_generation := _combat_interrupt_generation\n',
    "furnice generation capture",
)
furnice = furnice.replace(
    'if not is_inside_tree() or state == State.DEAD:\n\t\treturn\n',
    'if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:\n\t\treturn\n',
    2,
)

# ---------------------------------------------------------------------------
# Scene role assignment and duplicate root-property cleanup.
# ---------------------------------------------------------------------------
ROLE_VALUES = {
    "ravager": (2, 30.0, 38.0, 44.0),
    "veilmaw": (1, 28.0, 36.0, 42.0),
    "voidweaver": (1, 30.0, 38.0, 44.0),
    "hellmagma": (1, 34.0, 44.0, 48.0),
    "furnice_carrier": (2, 32.0, 40.0, 46.0),
    "crucible_warden": (0, 34.0, 44.0, 48.0),
    "redviper": (0, 30.0, 38.0, 44.0),
    "badredviper": (0, 32.0, 42.0, 46.0),
    "cinderhound": (0, 30.0, 42.0, 44.0),
}


def set_root_property(text: str, key: str, value: str) -> str:
    root_match = re.search(r'^\[node name="[^"]+" type="CharacterBody3D"[^\n]*\]\n', text, re.M)
    if root_match is None:
        raise RuntimeError(f"CharacterBody root missing for {key}")
    block_start = root_match.end()
    next_node = re.search(r'^\[node ', text[block_start:], re.M)
    block_end = block_start + (next_node.start() if next_node else len(text) - block_start)
    block = text[block_start:block_end]
    lines = block.splitlines()
    output = []
    inserted = False
    for line in lines:
        if re.match(rf'^{re.escape(key)}\s*=', line):
            if not inserted:
                output.append(f"{key} = {value}")
                inserted = True
            continue
        output.append(line)
        if not inserted and key == "combat_role" and line.startswith("script = "):
            output.append(f"{key} = {value}")
            inserted = True
    if not inserted:
        output.insert(0, f"{key} = {value}")
    new_block = "\n".join(output)
    if block.endswith("\n"):
        new_block += "\n"
    return text[:block_start] + new_block + text[block_end:]


def dedupe_root_assignments(text: str) -> str:
    root_match = re.search(r'^\[node name="[^"]+" type="CharacterBody3D"[^\n]*\]\n', text, re.M)
    if root_match is None:
        return text
    block_start = root_match.end()
    next_node = re.search(r'^\[node ', text[block_start:], re.M)
    block_end = block_start + (next_node.start() if next_node else len(text) - block_start)
    block = text[block_start:block_end]
    lines = block.splitlines()
    last_index = {}
    for index, line in enumerate(lines):
        match = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=', line)
        if match:
            last_index[match.group(1)] = index
    filtered = []
    for index, line in enumerate(lines):
        match = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=', line)
        if match and last_index.get(match.group(1)) != index:
            continue
        filtered.append(line)
    new_block = "\n".join(filtered)
    if block.endswith("\n"):
        new_block += "\n"
    return text[:block_start] + new_block + text[block_end:]

for enemy_name, (role, detection, pursuit, dormant) in ROLE_VALUES.items():
    scene_path = f"scenes/actors/{enemy_name}.tscn"
    scene = read(scene_path)
    scene = set_root_property(scene, "combat_role", str(role))
    scene = set_root_property(scene, "detection_range", f"{detection:.1f}")
    scene = set_root_property(scene, "pursuit_range", f"{pursuit:.1f}")
    scene = set_root_property(scene, "dormant_distance", f"{dormant:.1f}")
    scene = dedupe_root_assignments(scene)
    write(scene_path, scene)

# Enemy detection audit must reject duplicate root values instead of silently
# reading the first one.
audit = read("tests/enemy_detection_audit.py")
audit = sub_once(
    audit,
    r'def root_value\(text: str, key: str\) -> float:\n.*?\n\nfor enemy,',
    '''def root_value(text: str, key: str) -> float:
    matches = re.findall(rf"(?m)^{re.escape(key)} = ([0-9.]+)$", text)
    if len(matches) != 1:
        raise AssertionError(f"{key} must appear exactly once, got {len(matches)}")
    return float(matches[0])

for enemy,''',
    "strict actor root audit",
)

ROLE_AUDIT = r'''from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
profile = (ROOT / "scripts/actors/enemy_combat_profiles.gd").read_text(encoding="utf-8")
nav = (ROOT / "scripts/actors/enemy_navigation_runtime.gd").read_text(encoding="utf-8")
ravager = (ROOT / "scripts/actors/ravager.gd").read_text(encoding="utf-8")
red = (ROOT / "scripts/actors/redviper.gd").read_text(encoding="utf-8")
warden = (ROOT / "scripts/actors/crucible_warden.gd").read_text(encoding="utf-8")

for token in [
    "enum Role", "CLOSE", "MID", "LONG", "preferred_distance", "grid_step",
    "grid_max_nodes", "grid_search_margin", "idle_wander_radius",
]:
    assert token in profile, token
for token in [
    "func build_shortest_path", "func has_reached_walkable_target",
    "func choose_idle_wander_target", "func has_walk_segment_clear",
]:
    assert token in nav, token

for source in [ravager, red]:
    assert "combat_role" in source
    assert "_forced_damage_target" in source
    assert "_has_forced_damage_target" in source
    assert "EnemyNavigationRuntime" in source
    assert "EnemyCombatProfiles" in source

assert ravager.index("if _has_forced_damage_target:") < ravager.index("if _attack_locked:")
assert red.index("if _has_forced_damage_target:") < red.index("if _attack_locked:")
assert "func _update_behavior" not in warden
assert "_navigate_to(_player.global_position, delta)" in warden  # only visible close-for-heatwave path
assert "patrol_offset if _patrol_forward" not in ravager
assert "patrol_offset if _patrol_forward" not in red
assert "_retaliation_approach_position" not in red

expected_roles = {
    "ravager": 2,
    "veilmaw": 1,
    "voidweaver": 1,
    "hellmagma": 1,
    "furnice_carrier": 2,
    "crucible_warden": 0,
    "redviper": 0,
    "badredviper": 0,
    "cinderhound": 0,
}
for enemy, role in expected_roles.items():
    text = (ROOT / "scenes" / "actors" / f"{enemy}.tscn").read_text(encoding="utf-8")
    assert re.findall(r"(?m)^combat_role = (\d+)$", text) == [str(role)], enemy
    root = re.search(
        r'^\[node name="[^"]+" type="CharacterBody3D"[^\n]*\]\n(.*?)(?=^\[node |\Z)',
        text,
        re.M | re.S,
    )
    assert root is not None, enemy
    keys = re.findall(r"(?m)^([A-Za-z_][A-Za-z0-9_]*)\s*=", root.group(1))
    duplicates = sorted({key for key in keys if keys.count(key) > 1})
    assert not duplicates, (enemy, duplicates)

print("enemy role AI audit passed")
'''

write("scripts/actors/enemy_combat_profiles.gd", PROFILE_SCRIPT)
write("scripts/actors/enemy_navigation_runtime.gd", NAV_SCRIPT)
write("scripts/actors/ravager.gd", ravager)
write("scripts/actors/redviper.gd", red)
write("scripts/actors/crucible_warden.gd", warden)
write("scripts/actors/furnice_carrier.gd", furnice)
write("tests/enemy_detection_audit.py", audit)
write("tests/enemy_role_ai_audit.py", ROLE_AUDIT)

print("enemy role AI migration applied")
