@tool
class_name VexBurnRemains
extends Node3D

@export_category("Zemin İzi")
@export_range(0.4, 3.0, 0.05) var scorch_size := 1.0:
	set(value):
		scorch_size = value
		_apply_visuals()
@export var scorch_tint := Color(0.46, 0.05, 0.05, 0.92):
	set(value):
		scorch_tint = value
		_apply_visuals()
@export var ember_tint := Color(0.72, 0.10, 0.10, 0.36):
	set(value):
		ember_tint = value
		_apply_visuals()
@export_range(0.0, 2.0, 0.05) var ember_emission_energy := 0.16:
	set(value):
		ember_emission_energy = value
		_apply_visuals()
@export_range(0.0, 20.0, 0.1) var smoke_duration := 8.0
@export_range(0.0, 1.0, 0.01) var smoke_alpha := 0.14:
	set(value):
		smoke_alpha = value
		_apply_visuals()
@export_range(0.0, 0.1, 0.001) var ground_offset := 0.02:
	set(value):
		ground_offset = value
		_apply_visuals()
@export var smoke_enabled := false:
	set(value):
		smoke_enabled = value
		_apply_visuals()
@export_range(1, 6, 1) var smoke_wisp_count := 2:
	set(value):
		smoke_wisp_count = value
		_rebuild_smoke_wisps()
		_apply_visuals()

static var _shared_scorch_texture: Texture2D = null
static var _shared_core_texture: Texture2D = null
static var _shared_smoke_texture: Texture2D = null

var _smoke_stop_at := -1.0
var _scorch: MeshInstance3D = null
var _embers: MeshInstance3D = null
var _smoke_wisps: Array[Sprite3D] = []


func _ready() -> void:
	_ensure_nodes()
	_apply_visuals()
	if Engine.is_editor_hint():
		return
	_smoke_stop_at = Time.get_ticks_msec() * 0.001 + smoke_duration
	for wisp in _smoke_wisps:
		_run_smoke_cycle(wisp)


func _ensure_nodes() -> void:
	if _scorch == null:
		_scorch = get_node_or_null("Scorch") as MeshInstance3D
	if _scorch == null:
		_scorch = MeshInstance3D.new()
		_scorch.name = "Scorch"
		add_child(_scorch)
	if _embers == null:
		_embers = get_node_or_null("Embers") as MeshInstance3D
	if _embers == null:
		_embers = MeshInstance3D.new()
		_embers.name = "Embers"
		add_child(_embers)
	_rebuild_smoke_wisps()


func _rebuild_smoke_wisps() -> void:
	for wisp in _smoke_wisps:
		if is_instance_valid(wisp):
			wisp.queue_free()
	_smoke_wisps.clear()
	for child in get_children():
		if child is Sprite3D and String(child.name).begins_with("SmokeWisp"):
			child.queue_free()
	for index in smoke_wisp_count:
		var wisp := Sprite3D.new()
		wisp.name = "SmokeWisp%d" % (index + 1)
		wisp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wisp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		wisp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		wisp.no_depth_test = false
		wisp.pixel_size = 0.018
		add_child(wisp)
		_smoke_wisps.append(wisp)


func _apply_visuals() -> void:
	_ensure_nodes()
	if _shared_scorch_texture == null:
		_shared_scorch_texture = _create_splat_texture(196, 0.0)
	if _shared_core_texture == null:
		_shared_core_texture = _create_splat_texture(128, 0.22)
	if _shared_smoke_texture == null:
		_shared_smoke_texture = _create_smoke_texture()

	var scorch_mesh := QuadMesh.new()
	scorch_mesh.size = Vector2(1.45 * scorch_size, 1.45 * scorch_size)
	_scorch.mesh = scorch_mesh
	_scorch.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_scorch.position.y = ground_offset
	var scorch_material := StandardMaterial3D.new()
	scorch_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	scorch_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	scorch_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	scorch_material.albedo_texture = _shared_scorch_texture
	scorch_material.albedo_color = scorch_tint
	scorch_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	scorch_material.disable_receive_shadows = true
	_scorch.material_override = scorch_material

	var ember_mesh := QuadMesh.new()
	ember_mesh.size = Vector2(0.92 * scorch_size, 0.92 * scorch_size)
	_embers.mesh = ember_mesh
	_embers.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_embers.position = Vector3(0.03 * scorch_size, ground_offset + 0.0025, -0.02 * scorch_size)
	var ember_material := StandardMaterial3D.new()
	ember_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ember_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ember_material.albedo_texture = _shared_core_texture
	ember_material.albedo_color = ember_tint
	ember_material.emission_enabled = ember_emission_energy > 0.001
	ember_material.emission = ember_tint
	ember_material.emission_energy_multiplier = ember_emission_energy
	ember_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ember_material.disable_receive_shadows = true
	_embers.material_override = ember_material

	for wisp in _smoke_wisps:
		wisp.texture = _shared_smoke_texture
		wisp.modulate = Color(0.18, 0.18, 0.18, 0.0)
		wisp.visible = smoke_enabled and smoke_alpha > 0.0


func _run_smoke_cycle(wisp: Sprite3D) -> void:
	if not is_instance_valid(wisp):
		return
	if not smoke_enabled or smoke_alpha <= 0.0:
		wisp.visible = false
		return
	if smoke_duration > 0.0 and Time.get_ticks_msec() * 0.001 >= _smoke_stop_at:
		wisp.visible = false
		return
	wisp.visible = true
	var start_position := Vector3(
		randf_range(-0.10, 0.10) * scorch_size,
		ground_offset + randf_range(0.06, 0.12),
		randf_range(-0.10, 0.10) * scorch_size
	)
	var end_position := start_position + Vector3(
		randf_range(-0.05, 0.05),
		randf_range(0.18, 0.28),
		randf_range(-0.05, 0.05)
	)
	var start_scale := randf_range(0.30, 0.42) * scorch_size
	var end_scale := start_scale * randf_range(1.25, 1.55)
	var duration := randf_range(1.15, 1.85)
	wisp.position = start_position
	wisp.scale = Vector3.ONE * start_scale
	wisp.modulate = Color(0.20, 0.20, 0.20, 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(wisp, "position", end_position, duration)
	tween.tween_property(wisp, "scale", Vector3.ONE * end_scale, duration)
	tween.tween_property(wisp, "modulate", Color(0.20, 0.20, 0.20, smoke_alpha), duration * 0.35)
	var fade_track := tween.tween_property(wisp, "modulate", Color(0.20, 0.20, 0.20, 0.0), duration * 0.65)
	fade_track.set_delay(duration * 0.35)
	await tween.finished
	if not is_inside_tree():
		return
	await get_tree().create_timer(randf_range(0.12, 0.38)).timeout
	if not is_inside_tree():
		return
	_run_smoke_cycle(wisp)


static func _create_splat_texture(size: int, shrink: float) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var blobs := [
		{"center": Vector2(0.48, 0.50), "radius": 0.29},
		{"center": Vector2(0.33, 0.46), "radius": 0.20},
		{"center": Vector2(0.61, 0.40), "radius": 0.16},
		{"center": Vector2(0.56, 0.63), "radius": 0.18},
		{"center": Vector2(0.39, 0.66), "radius": 0.14},
	]
	for y in size:
		for x in size:
			var uv := Vector2((x + 0.5) / float(size), (y + 0.5) / float(size))
			var alpha := 0.0
			for blob in blobs:
				var center: Vector2 = blob["center"]
				var radius: float = maxf(0.02, float(blob["radius"]) - shrink)
				var distance := uv.distance_to(center)
				if distance >= radius:
					continue
				alpha += pow(1.0 - distance / radius, 1.45) * 0.85
			alpha = clampf(alpha, 0.0, 1.0)
			if alpha <= 0.01:
				continue
			# birkaç aşağı sarkan damla
			if uv.y > 0.68 and absf(uv.x - 0.42) < 0.02:
				alpha = maxf(alpha, clampf(1.0 - absf(uv.y - 0.82) / 0.18, 0.0, 1.0) * 0.55)
			if uv.y > 0.64 and absf(uv.x - 0.57) < 0.018:
				alpha = maxf(alpha, clampf(1.0 - absf(uv.y - 0.76) / 0.12, 0.0, 1.0) * 0.45)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)


static func _create_smoke_texture() -> Texture2D:
	var size := 96
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var blobs := [
		{"center": Vector2(35, 44), "radius": 22.0},
		{"center": Vector2(57, 36), "radius": 18.0},
		{"center": Vector2(49, 60), "radius": 20.0},
	]
	for y in size:
		for x in size:
			var alpha := 0.0
			for blob in blobs:
				var center: Vector2 = blob["center"]
				var radius: float = blob["radius"]
				var distance := Vector2(x, y).distance_to(center)
				if distance >= radius:
					continue
				alpha += pow(1.0 - distance / radius, 1.8) * 0.55
			alpha = clampf(alpha, 0.0, 1.0)
			if alpha <= 0.0:
				continue
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)
