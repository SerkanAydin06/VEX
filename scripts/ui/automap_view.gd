class_name VexAutomapView
extends Control

signal discovery_changed(visited_count: int, total_count: int)

@export_category("01 - Görünüm")
@export_range(12.0, 120.0, 1.0) var map_padding := 34.0
@export_range(0.0, 16.0, 0.5) var room_gap := 4.0
@export_range(8.0, 30.0, 1.0) var room_number_size := 15.0
@export_range(8.0, 36.0, 1.0) var marker_size := 15.0
@export_range(1.0, 6.0, 0.25) var wall_width := 2.0
@export_range(1.0, 8.0, 0.25) var door_width := 4.0
@export_range(0.5, 4.0, 0.1) var door_half_world_length := 2.1

@export_category("02 - Yakınlaştırma ve Kaydırma")
@export_range(0.5, 2.0, 0.05) var default_zoom := 1.0
@export_range(0.5, 2.0, 0.05) var minimum_zoom := 0.75
@export_range(1.0, 5.0, 0.1) var maximum_zoom := 2.8
@export_range(0.05, 0.5, 0.01) var zoom_step := 0.16
@export_range(0.03, 0.5, 0.01) var redraw_interval := 0.05

@export_category("03 - Renkler")
@export var background_color := Color(0.002, 0.015, 0.022, 0.72)
@export var grid_color := Color(0.05, 0.38, 0.48, 0.13)
@export var undiscovered_fill_color := Color(0.003, 0.012, 0.017, 0.94)
@export var undiscovered_edge_color := Color(0.10, 0.28, 0.33, 0.34)
@export var discovered_fill_color := Color(0.025, 0.22, 0.27, 0.78)
@export var discovered_edge_color := Color(0.20, 0.91, 1.0, 0.95)
@export var fog_boundary_color := Color(0.10, 0.52, 0.62, 0.52)
@export var player_color := Color(1.0, 0.38, 0.13, 1.0)
@export var player_glow_color := Color(1.0, 0.20, 0.05, 0.26)
@export var normal_door_color := Color(1.0, 0.66, 0.22, 1.0)
@export var open_door_color := Color(0.18, 1.0, 0.61, 1.0)
@export var blue_lock_color := Color(0.20, 0.58, 1.0, 1.0)
@export var red_lock_color := Color(1.0, 0.18, 0.12, 1.0)
@export var start_color := Color(0.30, 0.98, 0.78, 0.95)
@export var exit_color := Color(1.0, 0.24, 0.12, 0.98)

var _columns := 1
var _rows := 1
var _world_min := Vector2.ZERO
var _world_max := Vector2.ONE
var _walkable_cells: Dictionary = {}
var _walkable_order: Array[Vector2i] = []
var _visited_cells: Dictionary = {}
var _doors: Array[Node3D] = []
var _start_cell := Vector2i(-1, -1)
var _exit_cell := Vector2i(-1, -1)
var _merge_adjacent_cells := false
var _show_room_numbers := true
var _configured := false
var _title := "TESİS HARİTASI"

var _player_world_position := Vector2.ZERO
var _player_rotation_y := 0.0
var _has_player := false
var _zoom := 1.0
var _pan := Vector2.ZERO
var _dragging := false
var _last_pointer_position := Vector2.ZERO
var _pulse_time := 0.0
var _redraw_remaining := 0.0


func _ready() -> void:
	_zoom = clampf(default_zoom, minimum_zoom, maximum_zoom)
	set_process(true)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_pulse_time += delta
	_redraw_remaining -= delta
	if _redraw_remaining <= 0.0:
		_redraw_remaining = redraw_interval
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_clamp_pan()
		queue_redraw()


func configure(config: Dictionary, level_root: Node) -> void:
	_configured = false
	_walkable_cells.clear()
	_walkable_order.clear()
	_visited_cells.clear()
	_doors.clear()
	_has_player = false

	_title = str(config.get("title", "TESİS HARİTASI"))
	_columns = maxi(1, int(config.get("columns", 1)))
	_rows = maxi(1, int(config.get("rows", 1)))
	_world_min = config.get("world_min", Vector2.ZERO) as Vector2
	_world_max = config.get("world_max", Vector2.ONE) as Vector2
	_merge_adjacent_cells = bool(config.get("merge_adjacent_cells", false))
	_show_room_numbers = bool(config.get("show_room_numbers", true))

	var start_value: Variant = config.get("start_cell", Vector2i(-1, -1))
	if start_value is Vector2i:
		_start_cell = start_value as Vector2i
	var exit_value: Variant = config.get("exit_cell", Vector2i(-1, -1))
	if exit_value is Vector2i:
		_exit_cell = exit_value as Vector2i

	var cells_value: Variant = config.get("walkable_cells", [])
	if cells_value is Array:
		for cell_value: Variant in cells_value as Array:
			if not (cell_value is Vector2i):
				continue
			var cell := cell_value as Vector2i
			if not _cell_is_inside_grid(cell) or _walkable_cells.has(cell):
				continue
			_walkable_cells[cell] = true
			_walkable_order.append(cell)

	_cache_doors(level_root)
	_configured = not _walkable_order.is_empty() and _world_bounds_are_valid()
	reset_view(false)
	discovery_changed.emit(0, _walkable_order.size())
	queue_redraw()


func get_map_title() -> String:
	return _title


func get_discovery_counts() -> Vector2i:
	return Vector2i(_visited_cells.size(), _walkable_order.size())


func set_map_active(active: bool) -> void:
	_dragging = false
	if active:
		grab_focus()
		queue_redraw()


func update_player(player: Node3D) -> void:
	if not _configured or player == null or not is_instance_valid(player):
		return
	_player_world_position = Vector2(player.global_position.x, player.global_position.z)
	_player_rotation_y = player.global_rotation.y
	_has_player = true
	var player_cell := _resolve_player_cell(_player_world_position)
	if player_cell != Vector2i(-1, -1) and not _visited_cells.has(player_cell):
		_visited_cells[player_cell] = true
		discovery_changed.emit(_visited_cells.size(), _walkable_order.size())
		queue_redraw()


func reset_view(focus_on_player := false) -> void:
	_zoom = clampf(default_zoom, minimum_zoom, maximum_zoom)
	_pan = Vector2.ZERO
	if focus_on_player and _has_player:
		focus_player()
	else:
		queue_redraw()


func focus_player() -> void:
	if not _configured or not _has_player:
		_pan = Vector2.ZERO
		queue_redraw()
		return
	var raw_player_position := _world_to_raw_screen(_player_world_position)
	var view_center := size * 0.5
	_pan = -(raw_player_position - view_center) * _zoom
	_clamp_pan()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_WHEEL_UP and button_event.pressed:
			_zoom_at(button_event.position, _zoom + zoom_step)
			accept_event()
			return
		if button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and button_event.pressed:
			_zoom_at(button_event.position, _zoom - zoom_step)
			accept_event()
			return
		if button_event.button_index == MOUSE_BUTTON_RIGHT and button_event.pressed:
			reset_view(true)
			accept_event()
			return
		if button_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			_dragging = button_event.pressed
			_last_pointer_position = button_event.position
			if button_event.double_click and button_event.button_index == MOUSE_BUTTON_LEFT:
				focus_player()
			accept_event()
			return
	if event is InputEventMouseMotion and _dragging:
		var motion_event := event as InputEventMouseMotion
		var pointer_delta := motion_event.position - _last_pointer_position
		_last_pointer_position = motion_event.position
		_pan += pointer_delta
		_clamp_pan()
		queue_redraw()
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), background_color, true)
	_draw_background_grid()
	if not _configured:
		_draw_unavailable_message()
		return
	_draw_cells()
	_draw_points_of_interest()
	_draw_doors()
	_draw_orientation_indicator()
	_draw_player_marker()
	draw_rect(
		Rect2(Vector2(1.0, 1.0), size - Vector2(2.0, 2.0)),
		Color(0.10, 0.75, 0.90, 0.44),
		false,
		1.0
	)


func _draw_background_grid() -> void:
	var grid_step := 54.0
	var grid_offset := Vector2(fposmod(_pan.x, grid_step), fposmod(_pan.y, grid_step))
	var x := grid_offset.x
	while x < size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), grid_color, 1.0)
		x += grid_step
	var y := grid_offset.y
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), grid_color, 1.0)
		y += grid_step


func _draw_unavailable_message() -> void:
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(0.0, size.y * 0.5),
		"HARİTA VERİSİ BULUNAMADI",
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		20,
		Color(1.0, 0.28, 0.18, 0.9)
	)


func _draw_cells() -> void:
	for cell: Vector2i in _walkable_order:
		var discovered := _visited_cells.has(cell)
		var cell_rect := _cell_screen_rect(cell)
		if _merge_adjacent_cells:
			_draw_merged_cell(cell, cell_rect, discovered)
		else:
			_draw_room_cell(cell, cell_rect, discovered)


func _draw_room_cell(cell: Vector2i, source_rect: Rect2, discovered: bool) -> void:
	var scaled_gap := minf(room_gap * _zoom, minf(source_rect.size.x, source_rect.size.y) * 0.18)
	var cell_rect := source_rect.grow(-scaled_gap)
	var fill := discovered_fill_color if discovered else undiscovered_fill_color
	var edge := discovered_edge_color if discovered else undiscovered_edge_color
	draw_rect(cell_rect, fill, true)
	draw_rect(cell_rect, edge, false, wall_width)
	if discovered and _show_room_numbers and cell_rect.size.x >= 34.0 and cell_rect.size.y >= 28.0:
		var room_number := cell.y * _columns + cell.x + 1
		var font := ThemeDB.fallback_font
		draw_string(
			font,
			Vector2(cell_rect.position.x, cell_rect.get_center().y + room_number_size * 0.34),
			"%02d" % room_number,
			HORIZONTAL_ALIGNMENT_CENTER,
			cell_rect.size.x,
			int(room_number_size),
			Color(0.52, 0.92, 1.0, 0.82)
		)


func _draw_merged_cell(cell: Vector2i, cell_rect: Rect2, discovered: bool) -> void:
	var fill := discovered_fill_color if discovered else undiscovered_fill_color
	draw_rect(cell_rect.grow(0.5), fill, true)
	var directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for direction: Vector2i in directions:
		var neighbor := cell + direction
		var start := Vector2.ZERO
		var finish := Vector2.ZERO
		if direction == Vector2i.LEFT:
			start = cell_rect.position
			finish = cell_rect.position + Vector2(0.0, cell_rect.size.y)
		elif direction == Vector2i.RIGHT:
			start = cell_rect.position + Vector2(cell_rect.size.x, 0.0)
			finish = cell_rect.end
		elif direction == Vector2i.UP:
			start = cell_rect.position
			finish = cell_rect.position + Vector2(cell_rect.size.x, 0.0)
		else:
			start = cell_rect.position + Vector2(0.0, cell_rect.size.y)
			finish = cell_rect.end

		if not _walkable_cells.has(neighbor):
			var outer_edge := discovered_edge_color if discovered else undiscovered_edge_color
			draw_line(start, finish, outer_edge, wall_width)
		elif discovered != _visited_cells.has(neighbor):
			draw_line(start, finish, fog_boundary_color, 1.0)


func _draw_points_of_interest() -> void:
	if _walkable_cells.has(_start_cell) and _visited_cells.has(_start_cell):
		var start_center := _cell_screen_rect(_start_cell).get_center()
		draw_circle(start_center, 6.5, Color(0.0, 0.0, 0.0, 0.72))
		draw_circle(start_center, 4.2, start_color)
	if _walkable_cells.has(_exit_cell) and _visited_cells.has(_exit_cell):
		var exit_center := _cell_screen_rect(_exit_cell).get_center()
		var radius := 8.0
		var diamond := PackedVector2Array([
			exit_center + Vector2(0.0, -radius),
			exit_center + Vector2(radius, 0.0),
			exit_center + Vector2(0.0, radius),
			exit_center + Vector2(-radius, 0.0),
		])
		draw_colored_polygon(diamond, exit_color)
		draw_polyline(
			PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]),
			Color(1.0, 0.76, 0.60, 1.0),
			1.5
		)


func _draw_doors() -> void:
	for door: Node3D in _doors:
		if not is_instance_valid(door) or not _door_is_discovered(door):
			continue
		var center_world := Vector2(door.global_position.x, door.global_position.z)
		var width_axis_3d := door.global_transform.basis.z.normalized()
		var width_axis := Vector2(width_axis_3d.x, width_axis_3d.z).normalized()
		if width_axis.length_squared() <= 0.001:
			width_axis = Vector2.DOWN
		var start := _world_to_screen(center_world - width_axis * door_half_world_length)
		var finish := _world_to_screen(center_world + width_axis * door_half_world_length)
		var color := _get_door_color(door)
		draw_line(start, finish, Color(0.0, 0.0, 0.0, 0.92), door_width + 3.0)
		draw_line(start, finish, color, door_width)
		draw_circle((start + finish) * 0.5, door_width * 0.72, color)


func _draw_orientation_indicator() -> void:
	var indicator_position := Vector2(size.x - 42.0, 38.0)
	draw_line(indicator_position + Vector2(0.0, 15.0), indicator_position + Vector2(0.0, -8.0), discovered_edge_color, 2.0)
	draw_colored_polygon(
		PackedVector2Array([
			indicator_position + Vector2(0.0, -15.0),
			indicator_position + Vector2(-5.0, -5.0),
			indicator_position + Vector2(5.0, -5.0),
		]),
		discovered_edge_color
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(indicator_position.x - 12.0, indicator_position.y + 33.0),
		"N",
		HORIZONTAL_ALIGNMENT_CENTER,
		24.0,
		14,
		discovered_edge_color
	)


func _draw_player_marker() -> void:
	if not _has_player:
		return
	var center := _world_to_screen(_player_world_position)
	var pulse := 1.0 + sin(_pulse_time * 4.2) * 0.12
	var radius := marker_size * pulse
	draw_circle(center, radius * 1.65, player_glow_color)
	var forward := Vector2.UP.rotated(-_player_rotation_y)
	var right := forward.rotated(PI * 0.5)
	var points := PackedVector2Array([
		center + forward * radius * 1.35,
		center - forward * radius * 0.72 + right * radius * 0.74,
		center - forward * radius * 0.42,
		center - forward * radius * 0.72 - right * radius * 0.74,
	])
	draw_colored_polygon(points, player_color)
	draw_polyline(
		PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]),
		Color(1.0, 0.88, 0.72, 1.0),
		1.5
	)


func _cache_doors(level_root: Node) -> void:
	if level_root == null:
		return
	var doors_root := level_root.get_node_or_null("Doors")
	if doors_root == null:
		return
	for child: Node in doors_root.get_children():
		if child is Node3D:
			_doors.append(child as Node3D)


func _get_door_color(door: Node3D) -> Color:
	if bool(door.get("locked")):
		var required_keys_value: Variant = door.get("required_keys")
		if required_keys_value is Array:
			for key_value: Variant in required_keys_value as Array:
				if StringName(str(key_value)) == &"red":
					return red_lock_color
		if StringName(str(door.get("required_key"))) == &"red":
			return red_lock_color
		return blue_lock_color
	if bool(door.get("is_open")):
		return open_door_color
	return normal_door_color


func _door_is_discovered(door: Node3D) -> bool:
	var center := Vector2(door.global_position.x, door.global_position.z)
	var normal_axis_3d := door.global_transform.basis.x.normalized()
	var normal_axis := Vector2(normal_axis_3d.x, normal_axis_3d.z).normalized()
	if normal_axis.length_squared() <= 0.001:
		normal_axis = Vector2.RIGHT
	var world_cell_size := Vector2(
		(_world_max.x - _world_min.x) / float(_columns),
		(_world_max.y - _world_min.y) / float(_rows)
	)
	var sample_distance := minf(world_cell_size.x, world_cell_size.y) * 0.18
	var first_cell := _world_to_cell(center - normal_axis * sample_distance)
	var second_cell := _world_to_cell(center + normal_axis * sample_distance)
	return _visited_cells.has(first_cell) or _visited_cells.has(second_cell)


func _resolve_player_cell(world_position: Vector2) -> Vector2i:
	var direct_cell := _world_to_cell(world_position)
	if _walkable_cells.has(direct_cell):
		return direct_cell
	var nearest_cell := Vector2i(-1, -1)
	var nearest_distance := INF
	for cell: Vector2i in _walkable_order:
		var cell_center := _cell_center_world(cell)
		var distance := cell_center.distance_squared_to(world_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_cell = cell
	return nearest_cell


func _world_to_cell(world_position: Vector2) -> Vector2i:
	var normalized := Vector2(
		inverse_lerp(_world_min.x, _world_max.x, world_position.x),
		inverse_lerp(_world_min.y, _world_max.y, world_position.y)
	)
	return Vector2i(
		clampi(int(floor(normalized.x * float(_columns))), 0, _columns - 1),
		clampi(int(floor(normalized.y * float(_rows))), 0, _rows - 1)
	)


func _cell_center_world(cell: Vector2i) -> Vector2:
	return Vector2(
		lerpf(_world_min.x, _world_max.x, (float(cell.x) + 0.5) / float(_columns)),
		lerpf(_world_min.y, _world_max.y, (float(cell.y) + 0.5) / float(_rows))
	)


func _cell_screen_rect(cell: Vector2i) -> Rect2:
	var geometry := _get_base_geometry()
	var cell_size: Vector2 = geometry["cell_size"]
	var raw_origin: Vector2 = geometry["origin"] + Vector2(cell) * cell_size
	var screen_origin := _apply_view_transform(raw_origin)
	return Rect2(screen_origin, cell_size * _zoom)


func _world_to_screen(world_position: Vector2) -> Vector2:
	return _apply_view_transform(_world_to_raw_screen(world_position))


func _world_to_raw_screen(world_position: Vector2) -> Vector2:
	var geometry := _get_base_geometry()
	var normalized := Vector2(
		clampf(inverse_lerp(_world_min.x, _world_max.x, world_position.x), 0.0, 1.0),
		clampf(inverse_lerp(_world_min.y, _world_max.y, world_position.y), 0.0, 1.0)
	)
	return geometry["origin"] + normalized * (geometry["map_size"] as Vector2)


func _apply_view_transform(raw_position: Vector2) -> Vector2:
	var view_center := size * 0.5
	return view_center + (raw_position - view_center) * _zoom + _pan


func _get_base_geometry() -> Dictionary:
	var available_size := Vector2(
		maxf(size.x - map_padding * 2.0, 1.0),
		maxf(size.y - map_padding * 2.0, 1.0)
	)
	var world_span := Vector2(
		maxf(_world_max.x - _world_min.x, 0.001),
		maxf(_world_max.y - _world_min.y, 0.001)
	)
	var fit_scale := minf(available_size.x / world_span.x, available_size.y / world_span.y)
	var map_size := world_span * fit_scale
	return {
		"origin": (size - map_size) * 0.5,
		"map_size": map_size,
		"cell_size": map_size / Vector2(float(_columns), float(_rows)),
	}


func _zoom_at(pointer_position: Vector2, requested_zoom: float) -> void:
	var new_zoom := clampf(requested_zoom, minimum_zoom, maximum_zoom)
	if is_equal_approx(new_zoom, _zoom):
		return
	var view_center := size * 0.5
	var zoom_ratio := new_zoom / _zoom
	_pan = pointer_position - view_center - (pointer_position - view_center - _pan) * zoom_ratio
	_zoom = new_zoom
	_clamp_pan()
	queue_redraw()


func _clamp_pan() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var geometry := _get_base_geometry()
	var scaled_map_size: Vector2 = (geometry["map_size"] as Vector2) * _zoom
	var pan_limit := Vector2(
		maxf(scaled_map_size.x * 0.5, size.x * 0.18),
		maxf(scaled_map_size.y * 0.5, size.y * 0.18)
	)
	_pan.x = clampf(_pan.x, -pan_limit.x, pan_limit.x)
	_pan.y = clampf(_pan.y, -pan_limit.y, pan_limit.y)


func _cell_is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < _columns and cell.y >= 0 and cell.y < _rows


func _world_bounds_are_valid() -> bool:
	return _world_max.x > _world_min.x and _world_max.y > _world_min.y
