from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ravager = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
redviper = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")
warden = (ROOT / "scripts/actors/crucible_warden.gd").read_text(encoding="utf-8")
nav = (ROOT / "scripts/actors/enemy_navigation_runtime.gd").read_text(encoding="utf-8")
profile = (ROOT / "scripts/actors/enemy_combat_profiles.gd").read_text(encoding="utf-8")

for token in [
    "static func build_shortest_path(",
    "static func has_walk_segment_clear(",
    "static func has_reached_walkable_target(",
    "func _heap_push(",
    "func _heap_pop(",
    "func _simplify_path(",
]:
    assert token in nav, token

for source in (ravager, redviper):
    assert "EnemyNavigationRuntime.build_shortest_path(" in source
    assert "var runtime_grid_step" in source
    assert "var runtime_grid_max_nodes" in source
    assert "var runtime_grid_search_margin" in source
    assert "runtime_grid_step," in source
    assert "runtime_grid_max_nodes," in source
    assert "runtime_grid_search_margin\n" in source

for token in ["CLOSE", "MID", "LONG"]:
    assert token in profile, token
for obsolete in ["grid_step", "grid_max_nodes", "grid_search_margin"]:
    assert obsolete not in profile, obsolete

assert "func _refresh_warden_collision_detour" not in warden
assert "var _warden_detour_direction" not in warden
assert "func _update_behavior" not in warden
print("enemy shared runtime global path audit passed")
