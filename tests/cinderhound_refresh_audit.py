#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import json
import re
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
SCENE = ROOT / "scenes/actors/cinderhound.tscn"
SHEET = ROOT / "assets/enemies/cinder_hound/cinder_hound_character_spritesheet.png"
MANIFEST = ROOT / "assets/enemies/cinder_hound/cinder_hound_character_spritesheet_manifest.json"
IMPORT = ROOT / "assets/enemies/cinder_hound/cinder_hound_character_spritesheet.png.import"
ALPHA_THRESHOLD = 16
ANIM_ROWS = ["idle", "walk", "attack", "death", "idle_back", "walk_back"]
TARGET_GAP = 0.008
FRAME_WIDTH = 768
FRAME_HEIGHT = 512
PIXEL_SIZE = 0.0025
SPRITE_Y = -0.02
CAPSULE_HEIGHT = 1.30
PROPERTIES = {
    "idle": "idle_frame_y_offsets",
    "walk": "walk_frame_y_offsets",
    "attack": "attack_frame_y_offsets",
    "death": "death_frame_y_offsets",
    "idle_back": "idle_back_frame_y_offsets",
    "walk_back": "walk_back_frame_y_offsets",
}


def paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    return a if pa <= pb and pa <= pc else b if pb <= pc else c


def decode_alpha(path: Path) -> tuple[int, int, list[bytes]]:
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    pos = 8
    idat = bytearray()
    width = height = bit_depth = color_type = interlace = 0
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind = data[pos + 4:pos + 8]
        payload = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(">IIBBBBB", payload)
        elif kind == b"IDAT":
            idat.extend(payload)
        elif kind == b"IEND":
            break
    channels = {2: 3, 4: 2, 6: 4}.get(color_type)
    assert bit_depth == 8 and interlace == 0 and channels is not None
    raw = zlib.decompress(bytes(idat))
    stride = width * channels
    cursor = 0
    previous = bytearray(stride)
    rows: list[bytes] = []
    for _ in range(height):
        filter_type = raw[cursor]
        cursor += 1
        encoded = raw[cursor:cursor + stride]
        cursor += stride
        row = bytearray(stride)
        for index, value in enumerate(encoded):
            left = row[index - channels] if index >= channels else 0
            up = previous[index]
            upper_left = previous[index - channels] if index >= channels else 0
            predictor = (
                0 if filter_type == 0 else
                left if filter_type == 1 else
                up if filter_type == 2 else
                (left + up) // 2 if filter_type == 3 else
                paeth(left, up, upper_left)
            )
            assert 0 <= filter_type <= 4
            row[index] = (value + predictor) & 0xFF
        rows.append(bytes(row))
        previous = row
    if color_type == 6:
        alpha = [bytes(row[3::4]) for row in rows]
    elif color_type == 4:
        alpha = [bytes(row[1::2]) for row in rows]
    else:
        alpha = [bytes([255]) * width for _ in rows]
    return width, height, alpha


def offsets(source: str, key: str) -> list[float]:
    match = re.search(rf"^{re.escape(key)} = PackedFloat32Array\(([^)]*)\)$", source, re.M)
    assert match is not None, key
    return [float(value.strip()) for value in match.group(1).split(",")]


manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
assert manifest["sheet_size"] == {"width": 3072, "height": 3072}
assert manifest["frame_size"] == {"width": 768, "height": 512}
assert manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in manifest["rows"]] == ANIM_ROWS
assert all(row["frame_count"] == 4 for row in manifest["rows"])

source = SCENE.read_text(encoding="utf-8")
regions = re.findall(r"region = Rect2\((\d+), (\d+), 768, 512\)", source)
assert len(regions) == 24, len(regions)
assert set(regions) == {(str(c * 768), str(r * 512)) for r in range(6) for c in range(4)}
assert re.search(r"^pixel_size = 0\.0025$", source, re.M)
assert re.search(r"^position = Vector3\(0, -0\.02, 0\)$", source, re.M)

metadata = IMPORT.read_text(encoding="utf-8")
assert 'uid="uid://bpyi287frth02"' in metadata
assert "compress/mode=2" in metadata
assert "mipmaps/generate=true" in metadata
assert "detect_3d/compress_to=0" in metadata

width, height, alpha = decode_alpha(SHEET)
assert (width, height) == (3072, 3072)
for row_index, animation in enumerate(ANIM_ROWS):
    authored = offsets(source, PROPERTIES[animation])
    assert len(authored) == 4
    adjusted = []
    for column in range(4):
        x = column * FRAME_WIDTH
        y = row_index * FRAME_HEIGHT
        bottom = None
        for local_y in range(FRAME_HEIGHT - 1, -1, -1):
            if max(alpha[y + local_y][x:x + FRAME_WIDTH]) > ALPHA_THRESHOLD:
                bottom = local_y
                break
        assert bottom is not None, (animation, column)
        raw_gap = SPRITE_Y + (FRAME_HEIGHT * 0.5 - (bottom + 1)) * PIXEL_SIZE + CAPSULE_HEIGHT * 0.5
        adjusted.append(raw_gap + authored[column])
    tolerance = max(0.0006, PIXEL_SIZE * 0.55)
    print(f"CINDER HOUND CONTACT {animation:9s} " + ",".join(f"{gap:+.4f}" for gap in adjusted))
    assert all(abs(gap - TARGET_GAP) <= tolerance for gap in adjusted), (animation, adjusted)

for token in [
    "maximum_health = 85",
    "attack_range = 1.5",
    "attack_damage = 16",
    "attack_windup = 0.32",
    "attack_lunge_speed = 13.0",
    "attack_lunge_acceleration = 62.0",
    "attack_lunge_duration = 0.32",
    "attack_lunge_stop_distance = 0.74",
]:
    assert token in source, token

print("cinder hound canonical spritesheet audit passed")
