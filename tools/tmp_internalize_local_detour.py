#!/usr/bin/env python3
from pathlib import Path

combatant_path = Path("scripts/actors/enemy_combatant_base.gd")
combatant = combatant_path.read_text(encoding="utf-8")
replacements = {
    "@export_range(0.0, 3.0, 0.05) var local_detour_duration := 0.90":
        "var local_detour_duration := 0.90",
    "@export_range(0.5, 4.0, 0.05) var local_detour_clearance_multiplier := 1.45":
        "var local_detour_clearance_multiplier := 1.45",
    "@export_range(0.1, 3.0, 0.05) var local_detour_min_step := 0.90":
        "var local_detour_min_step := 0.90",
    "@export var local_detour_lateral_multipliers := PackedFloat32Array([1.0, 1.8, 2.8, 4.0])":
        "var local_detour_lateral_multipliers := PackedFloat32Array([1.0, 1.8, 2.8, 4.0])",
    "@export var local_detour_forward_multipliers := PackedFloat32Array([0.0, 0.75, 1.5])":
        "var local_detour_forward_multipliers := PackedFloat32Array([0.0, 0.75, 1.5])",
}
for old, new in replacements.items():
    count = combatant.count(old)
    if count != 1:
        raise SystemExit(f"expected one match for {old!r}, found {count}")
    combatant = combatant.replace(old, new, 1)
combatant_path.write_text(combatant, encoding="utf-8")

audit_path = Path("tests/enemy_role_ai_audit.py")
audit = audit_path.read_text(encoding="utf-8")
old_export_block = '''for setting in [
    "ranged_visibility_sampling_enabled", "cover_reposition_enabled",
    "ranged_cover_visibility_threshold", "ranged_cover_reposition_distance",
    "attack_preferred_distance", "attack_minimum_distance",
    "attack_recovery_strafe_scale", "attack_retreat_speed_scale",
    "chase_path_refresh_interval", "local_detour_duration",
]:
    assert re.search(rf"@export[^\\n]*\\bvar {setting}\\b", ravager), setting
'''
new_export_block = '''for setting in [
    "ranged_visibility_sampling_enabled", "cover_reposition_enabled",
    "ranged_cover_visibility_threshold", "ranged_cover_reposition_distance",
    "attack_preferred_distance", "attack_minimum_distance",
    "attack_recovery_strafe_scale", "attack_retreat_speed_scale",
    "chase_path_refresh_interval",
]:
    assert re.search(rf"@export[^\\n]*\\bvar {setting}\\b", ravager), setting

for setting in [
    "local_detour_duration", "local_detour_clearance_multiplier",
    "local_detour_min_step", "local_detour_lateral_multipliers",
    "local_detour_forward_multipliers",
]:
    assert re.search(rf"^var {setting}\\b", ravager, re.M), setting
    assert not re.search(rf"@export[^\\n]*\\bvar {setting}\\b", ravager), setting
'''
count = audit.count(old_export_block)
if count != 1:
    raise SystemExit(f"expected one enemy_role_ai export block, found {count}")
audit_path.write_text(audit.replace(old_export_block, new_export_block, 1), encoding="utf-8")
