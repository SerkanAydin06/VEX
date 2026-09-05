import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEVEL_SCRIPT = ROOT / "scripts/levels/level_test.gd"
LEVEL_SCENE = ROOT / "scenes/levels/level_test.tscn"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


level_script = read(LEVEL_SCRIPT)
level_scene = read(LEVEL_SCENE)

assert 'preload("res://scenes/actors/loom_herald.tscn")' in level_script
assert 'LOOM_HERALD_TEST_ID := &"level_test_loom_herald"' in level_script
assert 'get_node_or_null("Geometry/Room_C0_R2")' in level_script
assert 'get_node_or_null("Enemies")' in level_script
assert 'loom_herald.name = "LoomHerald"' in level_script
assert 'loom_herald.set("enemy_id", LOOM_HERALD_TEST_ID)' in level_script
assert 'LOOM_HERALD_ROOT_CLEARANCE := 0.98' in level_script

ready_block = re.search(r"func _ready\(\) -> void:\n(.*?)(?=\n\nfunc )", level_script, re.S)
assert ready_block, "test level _ready missing"
assert ready_block.group(1).find("_spawn_loom_herald()") < ready_block.group(1).find("super._ready()"), (
    "Loom Herald must spawn before VexBaseLevel enemy counting"
)

# C0_R2 is intentionally left free by the static enemy layout and is used as
# the scene-authoritative room transform for Loom Herald.
assert '[node name="Room_C0_R2" parent="Geometry"' in level_scene
assert 'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -24, 0, 0)' in level_scene
assert not re.search(
    r'\[node name="[^"]+" parent="Enemies"[^\n]*\]\n'
    r'transform = Transform3D\([^\n]*, -24, [^,\n]+, 0\)',
    level_scene,
), "Room_C0_R2 is no longer free for Loom Herald"

print("loom herald test level audit passed")
