from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE_PATH = ROOT / "scripts/actors/enemy_base.gd"
COMBATANT_PATH = ROOT / "scripts/actors/enemy_combatant_base.gd"
LUNGE_PATH = ROOT / "scripts/actors/enemy_lunge_base.gd"

base = BASE_PATH.read_text(encoding="utf-8")
combatant = COMBATANT_PATH.read_text(encoding="utf-8")
lunge = LUNGE_PATH.read_text(encoding="utf-8")

old_block = '''func _collision_floor_local_y() -> float:\n\treturn VexEnemyRuntimeUtils.collision_floor_local_y(collision_shape)\n\n\nfunc _snap_body_to_floor(max_correction: float) -> void:\n\tif not is_inside_tree() or collision_shape == null or collision_shape.shape == null:\n\t\treturn\n\tvar ray_origin := global_position + Vector3.UP * floor_snap_ray_start_height\n\tvar ray_end := global_position + Vector3.DOWN * (max_correction + floor_snap_ray_extra_depth)\n\tvar query := PhysicsRayQueryParameters3D.create(\n\t\tray_origin,\n\t\tray_end,\n\t\tfloor_collision_mask,\n\t\t[get_rid()]\n\t)\n\tquery.collide_with_areas = false\n\tvar hit := get_world_3d().direct_space_state.intersect_ray(query)\n\tif hit.is_empty():\n\t\treturn\n\tvar target_root_y := float(hit["position"].y) - _collision_floor_local_y()\n\tif absf(target_root_y - global_position.y) > max_correction:\n\t\treturn\n\tglobal_position.y = target_root_y\n\tvelocity.y = floor_stick_velocity\n'''

for name, source in (("combatant", combatant), ("lunge", lunge)):
    assert source.count(old_block) == 1, f"{name}: expected one duplicated floor-contact helper block"
assert old_block not in base, "base already contains child-signature floor-contact helper block"

combatant = combatant.replace(old_block, "", 1)
lunge = lunge.replace(old_block, "", 1)

old_call = "_snap_body_to_floor(floor_snap_max_correction)"
new_call = "_snap_body_to_floor(floor_snap_max_correction, floor_stick_velocity)"
assert combatant.count(old_call) == 1, "combatant: unexpected snap call count"
assert lunge.count(old_call) == 3, "lunge: unexpected snap call count"
combatant = combatant.replace(old_call, new_call)
lunge = lunge.replace(old_call, new_call)

anchor = '''func _apply_gravity(delta: float, floor_stick_velocity_value: float) -> void:\n\tif not is_on_floor():\n\t\tvelocity.y -= _gravity * delta\n\telse:\n\t\tvelocity.y = floor_stick_velocity_value\n'''
assert base.count(anchor) == 1, "base: gravity anchor changed"

shared_block = '''\n\nfunc _collision_floor_local_y() -> float:\n\treturn VexEnemyRuntimeUtils.collision_floor_local_y(collision_shape)\n\n\nfunc _snap_body_to_floor(\n\tmax_correction: float,\n\tfloor_stick_velocity_value: float\n) -> void:\n\tif not is_inside_tree() or collision_shape == null or collision_shape.shape == null:\n\t\treturn\n\tvar ray_origin := global_position + Vector3.UP * floor_snap_ray_start_height\n\tvar ray_end := global_position + Vector3.DOWN * (max_correction + floor_snap_ray_extra_depth)\n\tvar query := PhysicsRayQueryParameters3D.create(\n\t\tray_origin,\n\t\tray_end,\n\t\tfloor_collision_mask,\n\t\t[get_rid()]\n\t)\n\tquery.collide_with_areas = false\n\tvar hit := get_world_3d().direct_space_state.intersect_ray(query)\n\tif hit.is_empty():\n\t\treturn\n\tvar target_root_y := float(hit["position"].y) - _collision_floor_local_y()\n\tif absf(target_root_y - global_position.y) > max_correction:\n\t\treturn\n\tglobal_position.y = target_root_y\n\tvelocity.y = floor_stick_velocity_value\n'''
base = base.replace(anchor, anchor + shared_block, 1)

BASE_PATH.write_text(base, encoding="utf-8")
COMBATANT_PATH.write_text(combatant, encoding="utf-8")
LUNGE_PATH.write_text(lunge, encoding="utf-8")

print("enemy floor contact patch applied")
