from pathlib import Path

path = Path("scripts/actors/ravager.gd")
s = path.read_text(encoding="utf-8")


def replace_once(old: str, new: str, label: str) -> None:
    global s
    if old not in s:
        raise SystemExit(f"{label} not found")
    s = s.replace(old, new, 1)


replace_once(
    '''var _ranged_reposition_target := Vector3.ZERO
var _has_ranged_reposition_target := false
var _ranged_reposition_remaining := 0.0
''',
    '''var _ranged_reposition_target := Vector3.ZERO
var _has_ranged_reposition_target := false
var _ranged_reposition_remaining := 0.0
var _local_detour_side := 0.0
var _local_detour_remaining := 0.0
''',
    "detour state insertion anchor",
)

replace_once(
    '''\t_damage_reaction_remaining = maxf(0.0, _damage_reaction_remaining - delta)
\t_ranged_reposition_remaining = maxf(0.0, _ranged_reposition_remaining - delta)
''',
    '''\t_damage_reaction_remaining = maxf(0.0, _damage_reaction_remaining - delta)
\t_ranged_reposition_remaining = maxf(0.0, _ranged_reposition_remaining - delta)
\t_local_detour_remaining = maxf(0.0, _local_detour_remaining - delta)
''',
    "physics timer anchor",
)

replace_once(
    '''\t\t_path_refresh_remaining = 0.0
\t\t_ranged_reposition_remaining = 0.0
\t\t_has_ranged_reposition_target = false
\t\t_clear_path()
''',
    '''\t\t_path_refresh_remaining = 0.0
\t\t_ranged_reposition_remaining = 0.0
\t\t_has_ranged_reposition_target = false
\t\t_local_detour_remaining = 0.0
\t\t_local_detour_side = 0.0
\t\t_clear_path()
''',
    "damage detour reset anchor",
)

replace_once(
    '''\t\tif _has_last_seen_position:
\t\t\tstate = State.CHASE
\t\t\tif _horizontal_distance(global_position, _last_seen_position) <= waypoint_reach_distance:
\t\t\t\t_begin_search()
\t\t\telse:
\t\t\t\t_navigate_to(_last_seen_position, delta)
\t\t\treturn
''',
    '''\t\tif _has_last_seen_position:
\t\t\tstate = State.CHASE
\t\t\t# İnce duvarın öbür tarafındaki hedef yakın görünse bile fiziksel olarak
\t\t\t# ulaşılmış sayılmaz. Duvar varsa chase devam eder.
\t\t\tif _has_reached_walkable_target(_last_seen_position, waypoint_reach_distance):
\t\t\t\t_begin_search()
\t\t\telse:
\t\t\t\t_navigate_to(_last_seen_position, delta)
\t\t\treturn
''',
    "alerted reached block",
)

replace_once(
    '''\tif (
\t\tnot _has_search_probe
\t\tor _horizontal_distance(global_position, _search_probe_target) <= waypoint_reach_distance
\t):
''',
    '''\tif (
\t\tnot _has_search_probe
\t\tor _has_reached_walkable_target(_search_probe_target, waypoint_reach_distance)
\t):
''',
    "search probe reached block",
)

replace_once(
    '''\twhile (
\t\t_path_index < _current_path.size()
\t\tand _horizontal_distance(global_position, _current_path[_path_index]) <= waypoint_reach_distance
\t):
\t\t_path_index += 1
''',
    '''\twhile (
\t\t_path_index < _current_path.size()
\t\tand _has_reached_walkable_target(
\t\t\t_current_path[_path_index],
\t\t\twaypoint_reach_distance
\t\t)
\t):
\t\t_path_index += 1
''',
    "path waypoint reached loop",
)

replace_once(
    '''\t_current_path = graph.get_point_path(start_id, target_id)
\tif _current_path.is_empty():
\t\t# Oyuncunun son görüldüğü nokta duvara çok yakınsa düşmanın gövdesi
\t\t# hedef noktasına sığmayabilir. Duvarın yanlış tarafında beklemek yerine,
\t\t# hedefle aynı açık alanda bulunan en yakın ulaşılabilir rota noktasına git.
\t\t_current_path = _find_investigation_path(graph, start_id, destination)
\tif _current_path.size() > 1:
''',
    '''\t_current_path = graph.get_point_path(start_id, target_id)
\tif _current_path.is_empty():
\t\t# Önce sahne waypoint ağını dene.
\t\t_current_path = _find_investigation_path(graph, start_id, destination)
\tif _current_path.is_empty():
\t\t# Waypoint bulunmayan test/level sahnelerinde boş rota ile donmak yerine
\t\t# yerel sağ/sol detour üret ve köşeyi adım adım ara.
\t\t_current_path = _build_local_detour_path(destination)
\tif _current_path.size() > 1:
''',
    "rebuild fallback block",
)

helper = '''

func _build_local_detour_path(destination: Vector3) -> PackedVector3Array:
\tvar toward_target := destination - global_position
\ttoward_target.y = 0.0
\tif toward_target.length_squared() <= 0.001:
\t\treturn PackedVector3Array()

\tvar forward := toward_target.normalized()
\tvar side := Vector3(-forward.z, 0.0, forward.x)
\tvar base_step := maxf(navigation_clearance * 1.45, 0.90)
\tvar lateral_steps := PackedFloat32Array([
\t\tbase_step,
\t\tbase_step * 1.8,
\t\tbase_step * 2.8,
\t\tbase_step * 4.0,
\t])
\tvar forward_steps := PackedFloat32Array([0.0, base_step * 0.75, base_step * 1.5])
\tvar side_signs := PackedFloat32Array([-1.0, 1.0])
\tif _local_detour_remaining > 0.0 and absf(_local_detour_side) > 0.5:
\t\tside_signs = PackedFloat32Array([_local_detour_side, -_local_detour_side])

\tvar best_path := PackedVector3Array()
\tvar best_score := -INF
\tvar best_side := 0.0
\tvar current_remaining := _horizontal_distance(global_position, destination)

\tfor side_sign: float in side_signs:
\t\tfor lateral_distance: float in lateral_steps:
\t\t\tfor forward_distance: float in forward_steps:
\t\t\t\tvar candidate := (
\t\t\t\t\tglobal_position
\t\t\t\t\t+ side * side_sign * lateral_distance
\t\t\t\t\t+ forward * forward_distance
\t\t\t\t)
\t\t\t\tcandidate.y = global_position.y
\t\t\t\tif not _has_navigation_floor(candidate):
\t\t\t\t\tcontinue
\t\t\t\tif not _is_walk_segment_clear(global_position, candidate):
\t\t\t\t\tcontinue

\t\t\t\tvar approach_point := _furthest_walkable_point_toward(candidate, destination)
\t\t\t\tvar remaining := _horizontal_distance(approach_point, destination)
\t\t\t\tvar progress := current_remaining - remaining
\t\t\t\tvar direct_open := _is_walk_segment_clear(candidate, destination)
\t\t\t\tvar score := -remaining + progress * 1.5 - lateral_distance * 0.08
\t\t\t\tif direct_open:
\t\t\t\t\tscore += 8.0
\t\t\t\tif _local_detour_remaining > 0.0 and side_sign == _local_detour_side:
\t\t\t\t\tscore += 0.45

\t\t\t\tif score <= best_score:
\t\t\t\t\tcontinue
\t\t\t\tbest_score = score
\t\t\t\tbest_side = side_sign
\t\t\t\tbest_path = PackedVector3Array([global_position, candidate])
\t\t\t\tif (
\t\t\t\t\t_horizontal_distance(candidate, approach_point)
\t\t\t\t\t> waypoint_reach_distance * 0.35
\t\t\t\t):
\t\t\t\t\tbest_path.append(approach_point)

\tif not best_path.is_empty():
\t\t_local_detour_side = best_side
\t\t_local_detour_remaining = 0.90
\treturn best_path


func _has_navigation_floor(position: Vector3) -> bool:
\tvar ray_start := position + Vector3.UP * maxf(floor_snap_ray_start_height, 0.65)
\tvar ray_end := position + Vector3.DOWN * maxf(floor_snap_ray_extra_depth, 2.0)
\tvar query := PhysicsRayQueryParameters3D.create(
\t\tray_start,
\t\tray_end,
\t\tfloor_collision_mask,
\t\t[get_rid()]
\t)
\tquery.collide_with_areas = false
\treturn not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _has_reached_walkable_target(target: Vector3, reach_distance: float) -> bool:
\tif _horizontal_distance(global_position, target) > reach_distance:
\t\treturn false

\tvar direction := target - global_position
\tdirection.y = 0.0
\tif direction.length_squared() <= 0.000001:
\t\treturn true
\tvar perpendicular := Vector3(-direction.z, 0.0, direction.x).normalized()
\tperpendicular *= navigation_clearance
\tvar offsets: Array[Vector3] = [Vector3.ZERO, perpendicular, -perpendicular]
\tvar space_state := get_world_3d().direct_space_state
\tfor offset: Vector3 in offsets:
\t\tvar ray_start := global_position + offset
\t\tvar ray_end := target + offset
\t\tray_start.y = global_position.y
\t\tray_end.y = global_position.y
\t\tvar query := PhysicsRayQueryParameters3D.create(
\t\t\tray_start,
\t\t\tray_end,
\t\t\tnavigation_collision_mask,
\t\t\t[get_rid()]
\t\t)
\t\tquery.collide_with_areas = false
\t\tif not space_state.intersect_ray(query).is_empty():
\t\t\treturn false
\treturn true
'''

marker = "\n\nfunc _build_astar_graph() -> AStar3D:\n"
if marker not in s:
    raise SystemExit("helper insertion marker not found")
s = s.replace(marker, helper + marker, 1)

replace_once(
    '''\tif direction.length_squared() < 0.05:
\t\t_stop_horizontal_motion()
\t\treturn
''',
    '''\tif (
\t\tdirection.length_squared() < 0.05
\t\tand _has_reached_walkable_target(target, sqrt(0.05))
\t):
\t\t_stop_horizontal_motion()
\t\treturn
''',
    "move close-stop block",
)

old = '''\t\tnot _has_ranged_reposition_target
\t\tor _ranged_reposition_remaining <= 0.0
\t\tor _horizontal_distance(global_position, _ranged_reposition_target) <= waypoint_reach_distance
\t):
'''
new = '''\t\tnot _has_ranged_reposition_target
\t\tor _ranged_reposition_remaining <= 0.0
\t\tor _has_reached_walkable_target(_ranged_reposition_target, waypoint_reach_distance)
\t):
'''
if old in s:
    s = s.replace(old, new, 1)

path.write_text(s, encoding="utf-8")
