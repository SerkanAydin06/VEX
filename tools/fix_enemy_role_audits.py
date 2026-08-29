from pathlib import Path

path = Path("tests/enemy_detection_audit.py")
text = path.read_text(encoding="utf-8")
replacements = {
    '    "_damage_source_approach_position(source_node.global_position)",\n': '    "_has_forced_damage_target",\n    "EnemyCombatProfiles",\n',
    '    "_last_visibility_ratio < ranged_cover_visibility_threshold",\n': '    "_last_visibility_ratio < _cover_visibility_threshold()",\n',
}
for old, new in replacements.items():
    if old in text:
        text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")

runtime_audit = Path("tests/enemy_runtime_global_path_audit.py")
runtime_audit.write_text('''from pathlib import Path\n\nROOT = Path(__file__).resolve().parents[1]\nr = (ROOT / "scripts/actors/ravager.gd").read_text(encoding="utf-8")\nred = (ROOT / "scripts/actors/redviper.gd").read_text(encoding="utf-8")\nw = (ROOT / "scripts/actors/crucible_warden.gd").read_text(encoding="utf-8")\nnav = (ROOT / "scripts/actors/enemy_navigation_runtime.gd").read_text(encoding="utf-8")\n\nfor token in [\n    "func build_shortest_path(",\n    "func has_walk_segment_clear(",\n    "func has_reached_walkable_target(",\n    "func choose_idle_wander_target(",\n    "_heap_push",\n    "_heap_pop",\n    "_simplify_path",\n]:\n    assert token in nav, token\n\nfor source_name, source in (("ravager", r), ("redviper", red)):\n    assert "EnemyNavigationRuntime" in source, source_name\n    assert "build_shortest_path(" in source, source_name\n\nassert "func _refresh_warden_collision_detour" not in w\nassert "var _warden_detour_direction" not in w\nassert "func _update_behavior" not in w\nprint("enemy shared global path audit passed")\n''', encoding="utf-8")

print("enemy role audits updated")
