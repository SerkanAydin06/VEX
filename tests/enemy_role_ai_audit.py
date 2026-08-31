from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
profile = (ROOT / "scripts/actors/enemy_combat_profiles.gd").read_text(encoding="utf-8")
nav = (ROOT / "scripts/actors/enemy_navigation_runtime.gd").read_text(encoding="utf-8")
enemy_base = (ROOT / "scripts/actors/enemy_base.gd").read_text(encoding="utf-8")
ravager = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
red = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")
warden = (ROOT / "scripts/actors/crucible_warden.gd").read_text(encoding="utf-8")

for token in [
    "enum Role", "CLOSE", "MID", "LONG",
]:
    assert token in profile, token
for obsolete in [
    "preferred_distance", "minimum_distance", "cover_visibility_threshold",
    "idle_wander_radius", "path_refresh_interval", "grid_step",
    "grid_max_nodes", "grid_search_margin",
]:
    assert obsolete not in profile, obsolete
for token in [
    "func build_shortest_path", "func has_reached_walkable_target",
    "func has_walk_segment_clear",
]:
    assert token in nav, token

assert "combat_role" in ravager
assert "combat_role" in red
assert "EnemyNavigationRuntime" in enemy_base
assert "EnemyCombatProfiles" in enemy_base
for source in [ravager, red]:
    assert "_forced_damage_target" in source
    assert "_has_forced_damage_target" in source

common_inspector_settings = [
    "path_target_change_distance", "runtime_grid_step", "runtime_grid_max_nodes",
    "runtime_grid_search_margin", "sight_collision_mask", "aggro_on_damage",
    "damage_pursuit_min_progress", "damage_pursuit_stall_timeout",
    "damage_pursuit_commit_time", "acoustic_collision_mask", "acoustic_probe_height",
    "loud_noise_alert_threshold", "headshot_reference_height",
    "visibility_vertical_span_scale", "visibility_lateral_span_scale",
    "crouched_target_height_scale", "search_probe_diagonal_weight",
]
for source_name, source in [("ravager", ravager), ("redviper", red)]:
    for setting in common_inspector_settings:
        assert re.search(rf"@export[^\n]*\bvar {setting}\b", source), (source_name, setting)

for setting in [
    "ranged_visibility_sampling_enabled", "cover_reposition_enabled",
    "ranged_cover_visibility_threshold", "ranged_cover_reposition_distance",
    "attack_preferred_distance", "attack_minimum_distance",
    "attack_recovery_strafe_scale", "attack_retreat_speed_scale",
    "chase_path_refresh_interval", "local_detour_duration",
    "cover_visibility_score_weight",
]:
    assert re.search(rf"@export[^\n]*\bvar {setting}\b", ravager), setting

for obsolete_call in re.findall(r"EnemyCombatProfiles\.([A-Za-z_][A-Za-z0-9_]*)", ravager + red):
    assert obsolete_call == "Role", obsolete_call

assert ravager.index("if _attack_locked:") < ravager.index("if _has_forced_damage_target:")
assert red.index("if _attack_locked:") < red.index("if _has_forced_damage_target:")
assert "func _update_behavior" not in warden
assert "_navigate_to(_player.global_position, delta)" in warden
assert "patrol_offset if _patrol_forward" not in ravager
assert "patrol_offset if _patrol_forward" not in red
assert "_retaliation_approach_position" not in red

expected_roles = {
    "ravager": 2,
    "veilmaw": 1,
    "voidweaver": 1,
    "basalt_juggernaut": 1,
    "furnice_carrier": 2,
    "crucible_warden": 0,
    "cinder_spitter": 1,
    "coil_lancer": 2,
    "redviper": 0,
    "badredviper": 0,
    "cinderhound": 0,
    "gorehorn": 0,
    "briar_skulker": 1,
}
role_scene_settings = {
    0: ["damage_pursuit_commit_time", "runtime_grid_step", "runtime_grid_max_nodes"],
    1: [
        "ranged_cover_visibility_threshold", "ranged_cover_reposition_distance",
        "attack_minimum_distance", "chase_path_refresh_interval", "runtime_grid_step",
        "runtime_grid_max_nodes", "runtime_grid_search_margin",
    ],
    2: [
        "damage_pursuit_commit_time", "ranged_cover_visibility_threshold",
        "ranged_cover_reposition_distance",
        "attack_minimum_distance", "attack_recovery_strafe_scale",
        "attack_retreat_speed_scale", "chase_path_refresh_interval",
        "path_target_change_distance", "runtime_grid_step", "runtime_grid_max_nodes",
        "runtime_grid_search_margin",
    ],
}
for enemy, role in expected_roles.items():
    text = (ROOT / "scenes" / "actors" / f"{enemy}.tscn").read_text(encoding="utf-8")
    assert re.findall(r"(?m)^combat_role = (\d+)$", text) == [str(role)], enemy
    root = re.search(
        r'^\[node name="[^"]+" type="CharacterBody3D"[^\n]*\]\n(.*?)(?=^\[node |\Z)',
        text,
        re.M | re.S,
    )
    assert root is not None, enemy
    keys = re.findall(r"(?m)^([A-Za-z_][A-Za-z0-9_]*)\s*=", root.group(1))
    duplicates = sorted({key for key in keys if keys.count(key) > 1})
    assert not duplicates, (enemy, duplicates)
    if enemy not in {"redviper", "badredviper", "cinderhound"}:
        for setting in role_scene_settings[role]:
            assert setting in keys, (enemy, setting)

print("enemy role AI audit passed")
