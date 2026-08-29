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
print("enemy detection role audit contract updated")
