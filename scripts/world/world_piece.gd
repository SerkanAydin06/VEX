@tool
class_name VexWorldPiece
extends StaticBody3D

@export_category("Sahne Düzeni")
@export var piece_size := Vector3(4.0, 3.0, 0.3)
@export var surface_material: Material
@export var cast_shadow := true
@export var occlusion_enabled := true

@export_category("BaseTrim — Tamamen Sahne Ayarı")
@export var floor_trim_enabled := false
@export var floor_trim_size := Vector3(3.96, 0.28, 0.32)
@export var floor_trim_position := Vector3(0.0, -1.33, 0.0)

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
        floor_trim_enabled,
        floor_trim_size,
        floor_trim_position,
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

    _apply_floor_trim()
    _apply_occluder()
    _last_configuration = _configuration_snapshot()


func _apply_floor_trim() -> void:
    var target_trim := get_node_or_null("BaseTrim") as MeshInstance3D
    if target_trim == null:
        return

    target_trim.visible = floor_trim_enabled
    if not floor_trim_enabled:
        return

    var trim_mesh := target_trim.mesh as BoxMesh
    if trim_mesh != null:
        trim_mesh.size = floor_trim_size
    target_trim.position = floor_trim_position
    target_trim.cast_shadow = (
        GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        if cast_shadow
        else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    )


func _apply_occluder() -> void:
    var target_occluder := get_node_or_null("OccluderInstance3D") as OccluderInstance3D
    if target_occluder == null:
        return

    target_occluder.visible = occlusion_enabled
    var box_occluder := target_occluder.occluder as BoxOccluder3D
    if box_occluder != null:
        box_occluder.size = piece_size
