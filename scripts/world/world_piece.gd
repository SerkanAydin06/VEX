@tool
class_name VexWorldPiece
extends StaticBody3D

@export_category("Sahne Düzeni")
@export var piece_size := Vector3(4.0, 3.0, 0.3):
	set(value):
		piece_size = Vector3(maxf(value.x, 0.05), maxf(value.y, 0.05), maxf(value.z, 0.05))
		_apply_configuration()
@export var surface_material: Material:
	set(value):
		surface_material = value
		_apply_configuration()
@export var cast_shadow := true:
	set(value):
		cast_shadow = value
		_apply_configuration()
@export var occlusion_enabled := true:
	set(value):
		occlusion_enabled = value
		_apply_configuration()

@export_category("Zemin Birleşim Profili")
@export var floor_trim_enabled := true:
	set(value):
		floor_trim_enabled = value
		_apply_configuration()
@export_range(0.16, 0.6, 0.01) var floor_trim_height := 0.34:
	set(value):
		floor_trim_height = value
		_apply_configuration()
@export_range(0.04, 0.4, 0.01) var floor_trim_depth := 0.18:
	set(value):
		floor_trim_depth = value
		_apply_configuration()
@export_range(-0.15, 0.2, 0.01) var floor_trim_vertical_offset := 0.06:
	set(value):
		floor_trim_vertical_offset = value
		_apply_configuration()

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _last_size := Vector3.ZERO
var _last_material: Material = null


func _ready() -> void:
	_apply_configuration()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and (_last_size != piece_size or _last_material != surface_material):
		_apply_configuration()


func _apply_configuration() -> void:
	if not is_inside_tree():
		return
	var target_mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	var target_collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if target_mesh != null:
		var box_mesh := target_mesh.mesh as BoxMesh
		if box_mesh != null:
			box_mesh.size = piece_size
		target_mesh.material_override = surface_material
		target_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if target_collision != null:
		var box_shape := target_collision.shape as BoxShape3D
		if box_shape != null:
			box_shape.size = piece_size
	_apply_floor_trim()
	_apply_occluder()
	_last_size = piece_size
	_last_material = surface_material


func _apply_floor_trim() -> void:
	var target_trim := get_node_or_null("BaseTrim") as MeshInstance3D
	if target_trim == null:
		return

	var shortest_horizontal_side := minf(piece_size.x, piece_size.z)
	var is_wall_like := piece_size.y >= 1.0 and shortest_horizontal_side <= 1.2
	target_trim.visible = floor_trim_enabled and is_wall_like
	if not target_trim.visible:
		return

	var trim_mesh := target_trim.mesh as BoxMesh
	if trim_mesh == null:
		return

	var runs_along_x := piece_size.x >= piece_size.z
	if runs_along_x:
		trim_mesh.size = Vector3(
			piece_size.x + 0.08,
			floor_trim_height,
			piece_size.z + floor_trim_depth
		)
	else:
		trim_mesh.size = Vector3(
			piece_size.x + floor_trim_depth,
			floor_trim_height,
			piece_size.z + 0.08
		)

	target_trim.position = Vector3(
		0.0,
		-piece_size.y * 0.5 + floor_trim_height * 0.5 + floor_trim_vertical_offset,
		0.0
	)
	target_trim.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if cast_shadow
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)


func _apply_occluder() -> void:
	var target_occluder := get_node_or_null("OccluderInstance3D") as OccluderInstance3D
	if target_occluder == null:
		return

	# Zemin ve tavan gibi büyük yatay parçalar CPU oklüzyon tamponuna gereksiz
	# yük bindirir. Yalnız duvar profilleri görüş kapatıcı olarak kullanılır.
	var shortest_horizontal_side := minf(piece_size.x, piece_size.z)
	var is_wall_like := piece_size.y >= 1.0 and shortest_horizontal_side <= 1.2
	target_occluder.visible = occlusion_enabled and is_wall_like

	var box_occluder := target_occluder.occluder as BoxOccluder3D
	if box_occluder != null:
		box_occluder.size = piece_size
