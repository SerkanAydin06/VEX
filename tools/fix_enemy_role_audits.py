from pathlib import Path

path = Path("tests/enemy_detection_audit.py")
text = path.read_text(encoding="utf-8")
old = '    "_damage_source_approach_position(source_node.global_position)",\n'
if old in text:
    text = text.replace(old, '    "_has_forced_damage_target",\n    "EnemyCombatProfiles",\n', 1)
path.write_text(text, encoding="utf-8")
print("enemy detection role audit contract updated")
