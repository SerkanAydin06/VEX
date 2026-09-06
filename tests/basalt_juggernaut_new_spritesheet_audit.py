import json
import re
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets/enemies/basalt_juggernaut"
CHARACTER = ASSET_DIR / "basalt_juggernaut_character_spritesheet.png"
CHARACTER_MANIFEST = ASSET_DIR / "basalt_juggernaut_character_spritesheet_manifest.json"
CHARACTER_IMPORT = ASSET_DIR / "basalt_juggernaut_character_spritesheet.png.import"
EFFECTS = ASSET_DIR / "basalt_juggernaut_effects_spritesheet.png"
EFFECTS_MANIFEST = ASSET_DIR / "basalt_juggernaut_effects_spritesheet_manifest.json"
EFFECTS_IMPORT = ASSET_DIR / "basalt_juggernaut_effects_spritesheet.png.import"
SCENE = ROOT / "scenes/actors/basalt_juggernaut.tscn"
PROJECTILE = ROOT / "scenes/actors/basalt_juggernaut_projectile.tscn"

ANIMATIONS = ["idle", "walk", "attack", "death", "idle_back", "walk_back"]
EXPECTED_OFFSETS = {
    "idle_frame_y_offsets": [0.0731, 0.0731, 0.0731, 0.0682],
    "idle_back_frame_y_offsets": [0.0731, 0.0731, 0.0731, 0.0731],
    "walk_frame_y_offsets": [0.1025, 0.0682, 0.1124, 0.0878],
    "walk_back_frame_y_offsets": [0.1124, 0.078, 0.1124, 0.078],
    "attack_frame_y_offsets": [0.0731, 0.078, 0.0731, 0.0731],
    "death_frame_y_offsets": [0.0486, 0.0192, 0.0927, 0.0584],
}


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    assert data[12:16] == b"IHDR", path
    return struct.unpack(">II", data[16:24])


def packed_values(scene: str, key: str) -> list[float]:
    match = re.search(rf"(?m)^{re.escape(key)} = PackedFloat32Array\(([^)]*)\)$", scene)
    assert match, key
    return [float(value.strip()) for value in match.group(1).split(",")]


character_manifest = json.loads(read(CHARACTER_MANIFEST))
effects_manifest = json.loads(read(EFFECTS_MANIFEST))
scene = read(SCENE)
projectile = read(PROJECTILE)

assert png_size(CHARACTER) == (2048, 4608)
assert character_manifest["sheet_size"] == {"width": 2048, "height": 4608}
assert character_manifest["frame_size"] == {"width": 512, "height": 768}
assert character_manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in character_manifest["rows"]] == ANIMATIONS
assert all(row["frame_count"] == 4 for row in character_manifest["rows"])

assert png_size(EFFECTS) == (1024, 512)
assert effects_manifest["sheet_size"] == {"width": 1024, "height": 512}
assert effects_manifest["frame_size"] == {"width": 256, "height": 256}
assert effects_manifest["grid"] == {"columns": 4, "rows": 2}
assert [row["animation"] for row in effects_manifest["rows"]] == ["projectile", "impact"]

assert 'uid="uid://cjkcxynu3uhrh"' in scene
assert 'path="res://assets/enemies/basalt_juggernaut/basalt_juggernaut_character_spritesheet.png"' in scene
regions = re.findall(r"region = Rect2\((\d+), (\d+), 512, 768\)", scene)
assert len(regions) == 24, len(regions)
assert set(regions) == {(str(c * 512), str(r * 768)) for r in range(6) for c in range(4)}
assert re.search(r"^pixel_size = 0\.0049031334$", scene, re.M)
assert re.search(r"^projectile_spawn_height = 0\.44$", scene, re.M)
assert re.search(r"^projectile_spawn_forward_offset = 0\.24$", scene, re.M)
assert '"speed": 7.0' in scene
assert '"duration": 1.55' in scene

for key, expected in EXPECTED_OFFSETS.items():
    actual = packed_values(scene, key)
    assert len(actual) == 4
    assert all(abs(a - b) <= 0.00005 for a, b in zip(actual, expected)), (key, actual)

assert 'uid="uid://b3kjj7fhvogrk"' in projectile
assert 'path="res://assets/enemies/basalt_juggernaut/basalt_juggernaut_effects_spritesheet.png"' in projectile
effect_regions = re.findall(r"region = Rect2\((\d+), (\d+), 256, 256\)", projectile)
assert len(effect_regions) == 8, len(effect_regions)
assert set(effect_regions) == {(str(c * 256), str(r * 256)) for r in range(2) for c in range(4)}
assert re.search(r"^speed = 16\.0$", projectile, re.M)
assert re.search(r"^pixel_size = 0\.0041$", projectile, re.M)
assert re.search(r"^pixel_size = 0\.0045$", projectile, re.M)

for import_path, uid in [
    (CHARACTER_IMPORT, "uid://cjkcxynu3uhrh"),
    (EFFECTS_IMPORT, "uid://b3kjj7fhvogrk"),
]:
    metadata = read(import_path)
    assert f'uid="{uid}"' in metadata
    assert "compress/mode=2" in metadata
    assert "mipmaps/generate=true" in metadata
    assert "detect_3d/compress_to=0" in metadata

print("basalt juggernaut canonical spritesheet audit passed")
