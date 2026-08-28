from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

EXPECTED = {
    "ravager": (30.0, 38.0, 44.0),
    "veilmaw": (28.0, 36.0, 42.0),
    "voidweaver": (30.0, 38.0, 44.0),
    "hellmagma": (34.0, 44.0, 48.0),
    "furnice_carrier": (32.0, 40.0, 46.0),
    "crucible_warden": (34.0, 44.0, 48.0),
    "redviper": (30.0, 38.0, 44.0),
    "badredviper": (32.0, 42.0, 46.0),
    "cinderhound": (30.0, 42.0, 44.0),
}

def root_value(text: str, key: str) -> float:
    match = re.search(rf"(?m)^{re.escape(key)} = ([0-9.]+)$", text)
    if not match:
        raise AssertionError(f"missing {key}")
    return float(match.group(1))

for enemy, (min_detection, min_pursuit, min_dormant) in EXPECTED.items():
    path = ROOT / "scenes" / "actors" / f"{enemy}.tscn"
    text = path.read_text(encoding="utf-8")
    detection = root_value(text, "detection_range")
    pursuit = root_value(text, "pursuit_range")
    dormant = root_value(text, "dormant_distance")
    assert detection >= min_detection, (enemy, "detection", detection)
    assert pursuit >= min_pursuit, (enemy, "pursuit", pursuit)
    # Hard difficulty uses a 1.20 detection multiplier. Dormant mode must not
    # suppress line-of-sight before that maximum runtime detection radius.
    assert dormant > detection * 1.20, (enemy, "dormant", dormant, detection)

ravager_script = (ROOT / "scripts/actors/ravager.gd").read_text(encoding="utf-8")
redviper_script = (ROOT / "scripts/actors/redviper.gd").read_text(encoding="utf-8")
assert "var detection_range := 30.0" in ravager_script
assert "var pursuit_range := 38.0" in ravager_script
assert "var initial_view_angle := 240.0" in ravager_script
assert "var dormant_distance := 44.0" in ravager_script
assert "var detection_range := 30.0" in redviper_script
assert "var pursuit_range := 38.0" in redviper_script
assert "var dormant_distance := 44.0" in redviper_script

print("Enemy detection audit passed")


utils_script = (ROOT / "scripts/actors/enemy_runtime_utils.gd").read_text(encoding="utf-8")
for needle in [
    "static func has_visual_contact(",
    "target_center + side * lateral_span",
    "target_center - side * lateral_span",
    "static func investigation_probe(",
]:
    assert needle in utils_script, needle

for needle in [
    "search_probe_radius := 2.2",
    "alert_allies_on_detection := true",
    "VexEnemyRuntimeUtils.has_visual_contact(",
    "func _advance_search_probe()",
    "VexEnemyRuntimeUtils.investigation_probe(",
    "_begin_search()",
]:
    assert needle in ravager_script, needle

for needle in [
    "search_probe_radius := 2.0",
    "VexEnemyRuntimeUtils.has_visual_contact(",
    "func _investigate_last_seen(delta: float)",
    "VexEnemyRuntimeUtils.investigation_probe(",
    "_lost_sight_remaining = 0.0",
]:
    assert needle in redviper_script, needle

print("Enemy awareness/search contract passed")
