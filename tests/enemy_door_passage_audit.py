from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ravager = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
red = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")
nav = (ROOT / "scripts/actors/enemy_navigation_runtime.gd").read_text(encoding="utf-8")
door = (ROOT / "scripts/props/door.gd").read_text(encoding="utf-8")
warden = (ROOT / "scenes/actors/crucible_warden.tscn").read_text(encoding="utf-8")

assert "var _patrol_forward" not in ravager
assert "var _patrol_forward" not in red
assert "static func resolve_enemy_door_step(" in nav
assert 'get_nodes_in_group("enemy_navigation_door")' in nav
assert 'best_door.call("request_enemy_open")' in nav
for source, reach_contract in [
    (ravager, "waypoint_reach_distance"),
    (red, "investigation_reach_distance"),
]:
    assert "EnemyNavigationRuntime.resolve_enemy_door_step(" in source
    assert "navigation_clearance" in source
    assert reach_contract in source
    assert 'get_nodes_in_group("enemy_navigation_door")' not in source

for token in [
    "agent_clearance: float = 0.6",
    "agent_reach_distance: float = 0.55",
    "safe_clearance + 0.60",
    "enemy_portal_alignment_tolerance",
    "enemy_portal_commit_depth",
    "centered_inside_portal",
    "approach_distance <= alignment_tolerance",
    "maxf(agent_reach_distance, 0.1) + 0.05",
    "func request_enemy_open() -> void:",
]:
    assert token in door, token

assert "radius = 0.72" in warden
assert "navigation_clearance = 0.75" in warden
assert "waypoint_reach_distance := 0.65" in ravager
assert (ROOT / "tests/warden_door_runtime_test.gd").exists()
assert (ROOT / "tests/warden_door_runtime_test.tscn").exists()
print("enemy door passage audit passed")
