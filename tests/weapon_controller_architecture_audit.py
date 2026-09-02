from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
controller = (ROOT / "scripts/player/weapon_controller.gd").read_text(encoding="utf-8")
hitscan = (ROOT / "scripts/player/weapon_hitscan_runtime.gd").read_text(encoding="utf-8")
persistence = (ROOT / "scripts/player/weapon_persistence_runtime.gd").read_text(encoding="utf-8")
heat = (ROOT / "scripts/player/weapon_heat_runtime.gd").read_text(encoding="utf-8")
flashlight = (ROOT / "scripts/player/weapon_flashlight_runtime.gd").read_text(encoding="utf-8")
reload_runtime = (ROOT / "scripts/player/weapon_reload_runtime.gd").read_text(encoding="utf-8")

# WeaponController remains the gameplay-facing orchestrator, but raycast combat,
# persistence normalization, heat transitions, flashlight-node application and
# async reload timing/ammo transfer must not grow back into it.
assert "class_name VexWeaponController" in controller
assert "VexWeaponHitscanRuntime.shoot(" in controller
assert "VexWeaponPersistenceRuntime.canonical_weapon_id(" in controller
assert "VexWeaponPersistenceRuntime.migrate_legacy_ammo_dictionary(" in controller
assert "VexWeaponPersistenceRuntime.sanitize_restored_weapon_state(" in controller
assert "VexWeaponHeatRuntime.update(" in controller
assert "VexWeaponHeatRuntime.can_fire(" in controller
assert "VexWeaponHeatRuntime.register_shot(" in controller
assert "VexWeaponFlashlightRuntime.sync(" in controller
assert "VexWeaponFlashlightRuntime.is_active(" in controller
assert "VexWeaponReloadRuntime.reload_magazine(" in controller
assert "VexWeaponReloadRuntime.reload_sg04_shells(" in controller
assert "PhysicsRayQueryParameters3D.create(" not in controller
assert "HIT_IMPACT_V1" not in controller
assert "func _get_distance_damage_multiplier(" not in controller
assert "func _resolve_damage_target(" not in controller
assert "heat_cooling_per_second *" not in controller
assert "light_energy = weapon.flashlight_energy" not in controller
assert "spot_range = weapon.flashlight_range" not in controller
assert "create_timer(" not in controller
assert "func _reload_sg04_shells(" not in controller
assert len(controller.splitlines()) < 720

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

assert "class_name VexWeaponHeatRuntime" in heat
assert "static func initialize_weapon_state(" in heat
assert "static func effective_capacity(" in heat
assert "static func publish_current(" in heat
assert "static func update(" in heat
assert "static func can_fire(" in heat
assert "static func register_shot(" in heat
assert "heat_cooling_per_second" in heat
assert "heat_unlock_ratio" in heat
assert "heat_cooldown_delay" in heat

assert "class_name VexWeaponFlashlightRuntime" in flashlight
assert "static func initialize_light(" in flashlight
assert "static func sync(" in flashlight
assert "static func is_active(" in flashlight
assert "light.light_energy" in flashlight
assert "light.spot_range" in flashlight
assert "light.spot_angle" in flashlight

assert "class_name VexWeaponReloadRuntime" in reload_runtime
assert "static func reload_magazine(" in reload_runtime
assert "static func reload_sg04_shells(" in reload_runtime
assert "create_timer(" in reload_runtime
assert "false" in reload_runtime
assert "live_magazine" in reload_runtime
assert "live_reserve" in reload_runtime
assert "reload_shell" in reload_runtime
assert "reload_finish" in reload_runtime
assert "RESULT_INTERRUPTED" in reload_runtime

print("weapon controller architecture audit passed")
