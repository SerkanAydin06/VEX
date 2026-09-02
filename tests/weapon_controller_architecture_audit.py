from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
controller = (ROOT / "scripts/player/weapon_controller.gd").read_text(encoding="utf-8")
hitscan = (ROOT / "scripts/player/weapon_hitscan_runtime.gd").read_text(encoding="utf-8")
persistence = (ROOT / "scripts/player/weapon_persistence_runtime.gd").read_text(encoding="utf-8")

# WeaponController remains the gameplay-facing orchestrator, but raycast combat
# resolution and persistence normalization must not grow back into it.
assert "class_name VexWeaponController" in controller
assert "VexWeaponHitscanRuntime.shoot(" in controller
assert "VexWeaponPersistenceRuntime.canonical_weapon_id(" in controller
assert "VexWeaponPersistenceRuntime.migrate_legacy_ammo_dictionary(" in controller
assert "VexWeaponPersistenceRuntime.sanitize_restored_weapon_state(" in controller
assert "PhysicsRayQueryParameters3D.create(" not in controller
assert "HIT_IMPACT_V1" not in controller
assert "func _get_distance_damage_multiplier(" not in controller
assert "func _resolve_damage_target(" not in controller
assert len(controller.splitlines()) < 850

assert "class_name VexWeaponHitscanRuntime" in hitscan
assert "static func shoot(" in hitscan
assert "PhysicsRayQueryParameters3D.create(" in hitscan
assert "penetration_power" in hitscan
assert "pending_damage" in hitscan
assert "GameState.confirm_headshot()" in hitscan
assert "GameState.confirm_hit()" in hitscan
assert "HIT_IMPACT_V1.spawn_world(" in hitscan
assert "HIT_IMPACT_V1.spawn_flesh(" in hitscan

assert "class_name VexWeaponPersistenceRuntime" in persistence
assert "static func canonical_weapon_id(" in persistence
assert "static func canonicalize_weapon_dictionary(" in persistence
assert "static func migrate_legacy_ammo_dictionary(" in persistence
assert "static func sanitize_restored_weapon_state(" in persistence
assert persistence.count("clampi(") >= 4

print("weapon controller architecture audit passed")
