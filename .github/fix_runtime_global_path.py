from pathlib import Path

ravager_path = Path("scripts/actors/ravager.gd")
r = ravager_path.read_text(encoding="utf-8")

export_anchor = """@export_range(1, 64, 1) var investigation_candidate_count := 18\n@export_flags_3d_physics var navigation_collision_mask := 1 | 8\n"""
export_replacement = """@export_range(1, 64, 1) var investigation_candidate_count := 18\n@export_range(0.6, 2.0, 0.05) var runtime_grid_step := 1.0\n@export_range(200, 6000, 100) var runtime_grid_max_nodes := 1800\n@export_range(4.0, 30.0, 0.5) var runtime_grid_search_margin := 12.0\n@export_flags_3d_physics var navigation_collision_mask := 1 | 8\n"""
if export_anchor not in r:
    raise SystemExit("navigation export anchor not found")
r = r.replace(export_anchor, export_replacement, 1)

rebuild_anchor = """\t_path_target = destination\n\t_has_path_target = true\n\n\t# Ortak AStar ağı da harita başına bir kez oluşturulur. Rota ararken yalnızca\n"""
rebuild_replacement = """\t_path_target = destination\n\t_has_path_target = true\n\n\t# Aktif takipte elle yerleştirilmiş waypoint'lere bağlı kalma. Fizik dünyasını\n\t# grid olarak arayıp hedefe giden en kısa yürünebilir rotayı çıkar. Böylece\n\t# düşman, ateşin geldiği nokta duvar arkasındaysa haritanın hangi tarafından\n\t# dolaşması gerektiğini yerel sağ/sol tahmin yerine A* ile seçer.\n\tif state == State.CHASE:\n\t\t_current_path = _build_runtime_shortest_path(destination)\n\t\tif _current_path.size() > 1:\n\t\t\t_path_index = 1\n\t\t\treturn\n\n\t# Ortak AStar ağı da harita başına bir kez oluşturulur. Rota ararken yalnızca\n"""
if rebuild_anchor not in r:
    raise SystemExit("rebuild path anchor not found")
r = r.replace(rebuild_anchor, rebuild_replacement, 1)

function_anchor = """func _build_local_detour_path(destination: Vector3) -> PackedVector3Array:\n"""
functions = r'''func _build_runtime_shortest_path(destination: Vector3) -> PackedVector3Array:
	var start := global_position
	start.y = global_position.y
	var target := destination
	target.y = global_position.y
	if _is_walk_segment_clear(start, target):
		return PackedVector3Array([start, target])

	var step := maxf(runtime_grid_step, navigation_clearance * 1.20)
	var delta := target - start
	var goal_cell := Vector2i(
		roundi(delta.x / step),
		roundi(delta.z / step)
	)
	if goal_cell == Vector2i.ZERO:
		return PackedVector3Array()

	var margin_cells := maxi(4, ceili(runtime_grid_search_margin / step))
	var min_cell_x := mini(0, goal_cell.x) - margin_cells
	var max_cell_x := maxi(0, goal_cell.x) + margin_cells
	var min_cell_y := mini(0, goal_cell.y) - margin_cells
	var max_cell_y := maxi(0, goal_cell.y) + margin_cells

	var start_cell := Vector2i.ZERO
	var open_heap: Array[Dictionary] = []
	var came_from: Dictionary = {}
	var g_score: Dictionary = {start_cell: 0.0}
	var closed: Dictionary = {}
	var goal_distance_cells := Vector2(float(goal_cell.x), float(goal_cell.y)).length()
	_runtime_grid_heap_push(open_heap, start_cell, goal_distance_cells)

	var best_cell := start_cell
	var best_distance := _horizontal_distance(start, target)
	var found_cell := start_cell
	var found_destination := false
	var explored := 0
	var neighbor_steps: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(-1, -1),
	]

	while not open_heap.is_empty() and explored < runtime_grid_max_nodes:
		var entry := _runtime_grid_heap_pop(open_heap)
		var current_cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		if closed.has(current_cell):
			continue
		closed[current_cell] = true
		explored += 1

		var current_world := _runtime_grid_world(start, current_cell, step)
		var remaining := _horizontal_distance(current_world, target)
		if remaining < best_distance:
			best_distance = remaining
			best_cell = current_cell

		# Hedefe birkaç hücre kala artık grid merkezine zorlamadan gerçek dünya
		# koordinatına doğrudan bağlan. Bu, duvar kenarında oyuncu merkezine yakın
		# ama geçerli bir son yaklaşma üretir.
		if (
			remaining <= maxf(step * 3.0, 4.0)
			and _is_walk_segment_clear(current_world, target)
		):
			found_cell = current_cell
			found_destination = true
			break

		var current_g := float(g_score.get(current_cell, INF))
		for neighbor_step: Vector2i in neighbor_steps:
			var next_cell := current_cell + neighbor_step
			if (
				next_cell.x < min_cell_x
				or next_cell.x > max_cell_x
				or next_cell.y < min_cell_y
				or next_cell.y > max_cell_y
				or closed.has(next_cell)
			):
				continue

			var next_world := _runtime_grid_world(start, next_cell, step)
			if not _has_navigation_floor(next_world):
				continue
			if not _is_walk_segment_clear(current_world, next_world):
				continue

			var diagonal := neighbor_step.x != 0 and neighbor_step.y != 0
			var travel_cost := 1.41421356 if diagonal else 1.0
			var tentative_g := current_g + travel_cost
			if tentative_g >= float(g_score.get(next_cell, INF)):
				continue

			came_from[next_cell] = current_cell
			g_score[next_cell] = tentative_g
			var heuristic := Vector2(
				float(goal_cell.x - next_cell.x),
				float(goal_cell.y - next_cell.y)
			).length()
			_runtime_grid_heap_push(open_heap, next_cell, tentative_g + heuristic)

	if not found_destination:
		# Arama bütçesi hedefin tamamına yetmediyse bile, başlangıçtan anlamlı
		# biçimde daha yakın olan en iyi erişilebilir hücreye ilerle; donma yok.
		if best_distance >= _horizontal_distance(start, target) - step * 0.5:
			return PackedVector3Array()
		found_cell = best_cell

	var cell_path: Array[Vector2i] = []
	var cursor := found_cell
	cell_path.push_front(cursor)
	while cursor != start_cell:
		if not came_from.has(cursor):
			return PackedVector3Array()
		cursor = came_from[cursor]
		cell_path.push_front(cursor)

	var world_path := PackedVector3Array()
	world_path.append(start)
	for path_cell: Vector2i in cell_path:
		if path_cell == start_cell:
			continue
		world_path.append(_runtime_grid_world(start, path_cell, step))
	if found_destination:
		world_path.append(target)
	return _simplify_runtime_grid_path(world_path)


func _runtime_grid_world(origin: Vector3, cell: Vector2i, step: float) -> Vector3:
	return Vector3(
		origin.x + float(cell.x) * step,
		global_position.y,
		origin.z + float(cell.y) * step
	)


func _runtime_grid_heap_push(
	heap: Array[Dictionary],
	cell: Vector2i,
	priority: float
) -> void:
	var entry := {"cell": cell, "priority": priority}
	heap.append(entry)
	var index := heap.size() - 1
	while index > 0:
		var parent := (index - 1) / 2
		if float(heap[parent].get("priority", INF)) <= priority:
			break
		heap[index] = heap[parent]
		index = parent
	heap[index] = entry


func _runtime_grid_heap_pop(heap: Array[Dictionary]) -> Dictionary:
	var root := heap[0]
	var last := heap.pop_back()
	if heap.is_empty():
		return root

	heap[0] = last
	var index := 0
	while true:
		var left := index * 2 + 1
		if left >= heap.size():
			break
		var right := left + 1
		var smallest := left
		if (
			right < heap.size()
			and float(heap[right].get("priority", INF))
			< float(heap[left].get("priority", INF))
		):
			smallest = right
		if (
			float(heap[index].get("priority", INF))
			<= float(heap[smallest].get("priority", INF))
		):
			break
		var swap := heap[index]
		heap[index] = heap[smallest]
		heap[smallest] = swap
		index = smallest
	return root


func _simplify_runtime_grid_path(path: PackedVector3Array) -> PackedVector3Array:
	if path.size() <= 2:
		return path
	var simplified := PackedVector3Array([path[0]])
	var anchor_index := 0
	while anchor_index < path.size() - 1:
		var next_index := path.size() - 1
		while (
			next_index > anchor_index + 1
			and not _is_walk_segment_clear(path[anchor_index], path[next_index])
		):
			next_index -= 1
		simplified.append(path[next_index])
		anchor_index = next_index
	return simplified


'''
if function_anchor not in r:
    raise SystemExit("local detour function anchor not found")
r = r.replace(function_anchor, functions + function_anchor, 1)
ravager_path.write_text(r, encoding="utf-8")

warden_path = Path("scripts/actors/crucible_warden.gd")
w = warden_path.read_text(encoding="utf-8")
start_marker = "var _last_heatwave_player_hit_generation := -1\nvar _warden_detour_direction := Vector3.ZERO"
end_marker = "func _update_behavior(delta: float) -> void:"
if start_marker not in w or end_marker not in w:
    raise SystemExit("warden detour override block not found")
start_index = w.index(start_marker)
end_index = w.index(end_marker, start_index)
w = (
    w[:start_index]
    + "var _last_heatwave_player_hit_generation := -1\n\n\n"
    + w[end_index:]
)
warden_path.write_text(w, encoding="utf-8")

test_path = Path("tests/enemy_runtime_global_path_audit.py")
test_path.write_text(
    '''from pathlib import Path\n\nr = Path("scripts/actors/ravager.gd").read_text(encoding="utf-8")\nw = Path("scripts/actors/crucible_warden.gd").read_text(encoding="utf-8")\n\nfor token in [\n    "func _build_runtime_shortest_path(destination: Vector3)",\n    "runtime_grid_max_nodes",\n    "runtime_grid_search_margin",\n    "_runtime_grid_heap_push",\n    "_runtime_grid_heap_pop",\n    "_simplify_runtime_grid_path",\n    "if state == State.CHASE:",\n    "_current_path = _build_runtime_shortest_path(destination)",\n]:\n    assert token in r, token\n\nassert "func _refresh_warden_collision_detour" not in w\nassert "var _warden_detour_direction" not in w\nassert "_navigate_to(_player.global_position, delta)" in w\nprint("enemy runtime global path audit passed")\n''',
    encoding="utf-8",
)
