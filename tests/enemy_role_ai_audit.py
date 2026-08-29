from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
profile = (ROOT / "scripts/actors/enemy_combat_profiles.gd").read_text(encoding="utf-8")
nav = (ROOT / "scripts/actors/enemy_navigation_runtime.gd").read_text(encoding="utf-8")
ravager = (ROOT / "scripts/actors/ravager.gd").read_text(encoding="utf-8")
red = (ROOT / "scripts/actors/redviper.gd").read_text(encoding="utf-8")
warden = (ROOT / "scripts/actors/crucible_warden.gd").read_text(encoding="utf-8")

for token in [
    "enum Role", "CLOSE", "MID", "LONG", "preferred_distance", "grid_step",
    "grid_max_nodes", "grid_search_margin", "idle_wander_radius",
]:
    assert token in profile, token
for token in [
    "func build_shortest_path", "func has_reached_walkable_target",
    "func choose_idle_wander_target", "func has_walk_segment_clear",
]:
    assert token in nav, token

for source in [ravager, red]:
    assert "combat_role" in source
    assert "_forced_damage_target" in source
    assert "_has_forced_damage_target" in source
    assert "EnemyNavigationRuntime" in source
    assert "EnemyCombatProfiles" in source

assert ravager.index("if _has_forced_damage_target:") < ravager.index("if _attack_locked:")
assert red.index("if _has_forced_damage_target:") < red.index("if _attack_locked:")
assert "func _update_behavior" not in warden
assert "_navigate_to(_player.global_position, delta)" in warden  # only visible close-for-heatwave path
assert "patrol_offset if _patrol_forward" not in ravager
assert "patrol_offset if _patrol_forward" not in red
assert "_retaliation_approach_position" not in red

expected_roles = {
    "ravager": 2,
    "veilmaw": 1,
    "voidweaver": 1,
    "hellmagma": 1,
    "furnice_carrier": 2,
    "crucible_warden": 0,
    "redviper": 0,
    "badredviper": 0,
    "cinderhound": 0,
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

print("enemy role AI audit passed")
