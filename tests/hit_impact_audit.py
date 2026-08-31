#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []


def read(path):
    full = ROOT / path
    if not full.exists():
        errors.append(f"Eksik impact V1 dosyası: {path}")
        return ""
    return full.read_text(encoding="utf-8")


effect = read("scripts/effects/hit_impact_v1.gd")
controller = read("scripts/player/weapon_controller.gd")
door = read("scripts/props/door.gd")

for needle in [
    "class_name VexHitImpactV1",
    'WORLD_TEXTURE_PATH := "res://assets/impacts/impact_world_v1.png"',
    'FLESH_TEXTURE_PATH := "res://assets/impacts/impact_flesh_v1.png"',
    "func spawn_world(",
    "surface: Object = null",
    "func _world_impact_anchor(",
    'current.has_method("resolve_bullet_impact_anchor")',
    '"resolve_bullet_impact_anchor",',
    "_world_surface_offset(anchor, normal)",
    'current.has_method("resolve_bullet_impact_offset")',
    '"resolve_bullet_impact_offset",',
    "func _world_surface_offset(",
    "MOVING_SURFACE_OFFSET := 0.065",
    "current is AnimatableBody3D",
    "func spawn_flesh(",
    "func _sample_enemy_hit_color(",
    "func _sample_sprite_image_at_hit(",
    "func _build_flesh_fragment_burst(",
    "func _build_fragment_layer(",
    "func _build_droplet_layer(",
    'particles.name = "OrganicSpray"',
    "fragment_mesh := SphereMesh.new()",
    "PhysicsShapeQueryParameters3D.new()",
    'get_nodes_in_group("enemy")',
    "texture.get_image()",
    "GPUParticles3D.new()",
    "MAX_WORLD_IMPACTS := 72",
    "MAX_FLESH_IMPACTS := 24",
    "ResourceLoader.exists(path)",
]:
    if needle not in effect:
        errors.append(f"Impact effect sözleşmesi eksik: {needle}")


for needle in [
    "func resolve_bullet_impact_anchor(",
    "if surface == perception_blocker:",
    "return _bullet_impact_panel_for_position(hit_position)",
    "func resolve_bullet_impact_offset(",
    "BULLET_IMPACT_FACE_OFFSET := 0.052",
    "BULLET_IMPACT_EDGE_OFFSET := 0.004",
    "anchor.global_transform.basis.inverse() * hit_normal.normalized()",
    "if abs_x >= abs_y and abs_x >= abs_z:",
    "func _bullet_impact_panel_for_position(",
    "left_distance := absf(local_hit.z - door_panel.position.z)",
    "right_distance := absf(local_hit.z - door_panel_right.position.z)",
]:
    if needle not in door:
        errors.append(f"Door impact anchor sözleşmesi eksik: {needle}")

for forbidden in [
    "func _build_flesh_visual(",
    'splash.name = "FleshSplash"',
    "material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED",
    "BoxMesh.new()",
]:
    if forbidden in effect:
        errors.append(f"Enemy impact artık kalıcı/billboard görsel üretmemeli: {forbidden}")

for needle in [
    'preload("res://scripts/effects/hit_impact_v1.gd")',
    "MAX_WORLD_IMPACTS_PER_TRIGGER := 4",
    'result.get("normal", -direction)',
    "pending_hit_normals",
    "HIT_IMPACT_V1.spawn_world(",
    "direction,\n\t\t\t\t\t\tcollider",
    "direction,\n\t\t\t\t\tcollider",
    "HIT_IMPACT_V1.spawn_flesh(",
    'damage_target.is_in_group("enemy")',
]:
    if needle not in controller:
        errors.append(f"WeaponController impact sözleşmesi eksik: {needle}")

if errors:
    print("HIT IMPACT V1 AUDIT FAILED:")
    for error in errors:
        print(" -", error)
    sys.exit(1)
print("HIT IMPACT V1 AUDIT OK")
