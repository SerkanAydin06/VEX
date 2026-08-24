@tool
class_name VexWorldPiece
extends StaticBody3D

@export_category("Sahne Düzeni")
@export var piece_size := Vector3(4.0, 3.0, 0.3)
@export var surface_material: Material
@export var cast_shadow := true
@export var occlusion_enabled := true

var _last_configuration: Array = []


func _ready() -> void:
    _apply_configuration()
    set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
    if not Engine.is_editor_hint():
        return
    var configuration := _configuration_snapshot()
    if configuration != _last_configuration:
        _apply_configuration()


func _configuration_snapshot() -> Array:
    return [
        piece_size,
        surface_material,
        cast_shadow,
        occlusion_enabled,
    ]


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
        target_mesh.cast_shadow = (
            GeometryInstance3D.SHADOW_CASTING_SETTING_ON
            if cast_shadow
            else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        )

    if target_collision != null:
        var box_shape := target_collision.shape as BoxShape3D
        if box_shape != null:
            box_shape.size = piece_size

    _apply_occluder()
    _last_configuration = _configuration_snapshot()


func _apply_occluder() -> void:
    var target_occluder := get_node_or_null("OccluderInstance3D") as OccluderInstance3D
    if target_occluder == null:
        return

    target_occluder.visible = occlusion_enabled
    var box_occluder := target_occluder.occluder as BoxOccluder3D
    if box_occluder != null:
        box_occluder.size = piece_size
