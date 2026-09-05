import json
import re
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets/enemies/basalt_juggernaut"
SHEET = ASSET_DIR / "basalt_juggernaut_character_spritesheet.png"
MANIFEST = ASSET_DIR / "basalt_juggernaut_character_spritesheet_manifest.json"
SCENE = ROOT / "scenes/actors/basalt_juggernaut.tscn"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f"not a PNG: {path}"
    assert data[12:16] == b"IHDR", f"PNG IHDR missing: {path}"
    return struct.unpack(">II", data[16:24])


def packed_values(scene: str, key: str) -> list[float]:
    match = re.search(rf"(?m)^{re.escape(key)} = PackedFloat32Array\(([^)]*)\)$", scene)
    assert match, f"missing {key}"
    return [float(value.strip()) for value in match.group(1).split(",") if value.strip()]


assert SHEET.exists(), "new Basalt Juggernaut character sheet missing"
assert MANIFEST.exists(), "Basalt Juggernaut character sheet manifest missing"
assert png_size(SHEET) == (4096, 9216)

manifest = json.loads(read(MANIFEST))
assert manifest["frame_size"] == {"width": 1024, "height": 1536}
assert manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in manifest["rows"]] == [
    "idle",
    "walk",
    "attack",
    "death",
    "idle_back",
    "walk_back",
]
assert all(row["frame_count"] == 4 for row in manifest["rows"])

scene = read(SCENE)
assert 'path="res://assets/enemies/basalt_juggernaut/basalt_juggernaut_character_spritesheet.png"' in scene
assert "basalt_juggernaut_spritesheet.png" not in scene
assert "pixel_size = 0.0024515667" in scene
assert "projectile_spawn_height = 0.44" in scene

rows = {
    "idle": 0,
    "walk": 1,
    "attack": 2,
    "death": 3,
    "idle_back": 4,
    "walk_back": 5,
}
for animation, row_index in rows.items():
    for column in range(4):
        atlas_id = f"Atlas_{animation}{column + 1}"
        block = re.search(
            rf'\[sub_resource type="AtlasTexture" id="{re.escape(atlas_id)}"\](.*?)(?=\n\[)',
            scene,
            re.S,
        )
        assert block, f"missing atlas {atlas_id}"
        expected = f"region = Rect2({column * 1024}, {row_index * 1536}, 1024, 1536)"
        assert expected in block.group(1), f"wrong region for {atlas_id}"

expected_offsets = {
    "idle_frame_y_offsets": [0.078, 0.078, 0.078, 0.0731],
    "idle_back_frame_y_offsets": [0.0756, 0.078, 0.0756, 0.0756],
    "walk_frame_y_offsets": [0.1074, 0.0731, 0.1172, 0.0903],
    "walk_back_frame_y_offsets": [0.1172, 0.0805, 0.1172, 0.0805],
    "attack_frame_y_offsets": [0.0756, 0.0805, 0.0756, 0.078],
    "death_frame_y_offsets": [0.0535, 0.0216, 0.0952, 0.0633],
}
for key, expected in expected_offsets.items():
    actual = packed_values(scene, key)
    assert len(actual) == 4
    assert all(abs(a - b) <= 0.00005 for a, b in zip(actual, expected)), f"{key} mismatch"

# Attack frame 3 remains the authored projectile-release frame. Its duration
# stays extended, so the existing difficulty-aware release audit keeps firing
# while the bright central core is visible.
assert '"name": &"attack"' in scene
assert '"speed": 7.0' in scene
assert '"duration": 1.55' in scene

print("basalt juggernaut new spritesheet audit passed")
