#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import json
import math
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
TARGET_CONTACT_GAP = 0.008
CAPSULE_HEIGHT = 1.30
CORPSE_FLOOR_CLEARANCE = 0.02


def paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    return a if pa <= pb and pa <= pc else b if pb <= pc else c


def decode_rgba_alpha(path: Path) -> tuple[int, int, list[bytes]]:
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
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
    channels = {2: 3, 4: 2, 6: 4}[color_type]
    assert bit_depth == 8 and interlace == 0
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
            predictor = 0 if filter_type == 0 else left if filter_type == 1 else up if filter_type == 2 else (left + up) // 2 if filter_type == 3 else paeth(left, up, upper_left)
            row[index] = (value + predictor) & 0xFF
        rows.append(bytes(row))
        previous = row
    if color_type == 6:
        return width, height, [bytes(row[3::4]) for row in rows]
    if color_type == 4:
        return width, height, [bytes(row[1::2]) for row in rows]
    return width, height, [bytes([255]) * width for _ in rows]


def scene_float(source: str, key: str, default: float | None = None) -> float:
    match = re.search(rf"^{re.escape(key)} = (-?[0-9.]+)$", source, re.M)
    if match:
        return float(match.group(1))
    assert default is not None, key
    return default


def sprite_y(source: str) -> float:
    body = re.search(r'^\[node name="AnimatedSprite3D"[^\n]*\]\n(.*?)(?=^\[node |\Z)', source, re.M | re.S)
    assert body is not None
    pos = re.search(r'^position = Vector3\([^,]+, ([^,]+), [^)]+\)$', body.group(1), re.M)
    if pos:
        return float(pos.group(1))
    transform = re.search(r'^transform = Transform3D\(([^\n]+)\)$', body.group(1), re.M)
    if transform:
        return float(transform.group(1).split(",")[-2].strip())
    return 0.0


manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
assert manifest["sheet_size"] == {"width": 2048, "height": 2046}
assert manifest["frame_size"] == {"width": 512, "height": 341}
assert manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in manifest["rows"]] == ANIM_ROWS
assert all(row["frame_count"] == 4 for row in manifest["rows"])

source = SCENE.read_text(encoding="utf-8")
regions = re.findall(r'region = Rect2\((\d+), (\d+), 512, 341\)', source)
assert len(regions) == 24, len(regions)
assert set(regions) == {(str(c * 512), str(r * 341)) for r in range(6) for c in range(4)}
assert re.search(r'region = Rect2\([^\n]*, 341, 512\)', source) is None
assert 'path="res://assets/enemies/cinder_hound/cinder_hound_character_spritesheet.png"' in source

import_text = IMPORT.read_text(encoding="utf-8")
assert 'uid="uid://bpyi287frth02"' in import_text
assert "compress/mode=2" in import_text
assert "mipmaps/generate=true" in import_text

width, height, alpha = decode_rgba_alpha(SHEET)
assert (width, height) == (2048, 2046)
pixel_size = scene_float(source, "pixel_size")
base_y = sprite_y(source)
corpse_visual_y = scene_float(source, "corpse_visual_y")
assert math.isclose(pixel_size, 0.00375, abs_tol=0.000001)
assert math.isclose(base_y, -0.02, abs_tol=0.000001)
assert math.isclose(corpse_visual_y, -0.0339, abs_tol=0.000001)
assert math.isclose(scene_float(source, "attack_range"), 1.5, abs_tol=0.000001)
assert math.isclose(scene_float(source, "attack_windup"), 0.32, abs_tol=0.000001)
assert math.isclose(scene_float(source, "attack_range_tolerance"), 0.18, abs_tol=0.000001)
assert math.isclose(scene_float(source, "attack_lunge_speed"), 13.0, abs_tol=0.000001)
assert math.isclose(scene_float(source, "attack_lunge_acceleration"), 62.0, abs_tol=0.000001)
assert math.isclose(scene_float(source, "attack_lunge_duration"), 0.32, abs_tol=0.000001)
assert math.isclose(scene_float(source, "attack_lunge_stop_distance"), 0.74, abs_tol=0.000001)
print(f"CINDER HOUND SCALE pixel_size={pixel_size:.6f} sprite_y={base_y:+.4f}")

death_final_max_y = None
for row_index, animation in enumerate(ANIM_ROWS):
    for column in range(4):
        x0 = column * 512
        y0 = row_index * 341
        min_x = min_y = None
        max_x = max_y = None
        for local_y in range(341):
            row = alpha[y0 + local_y][x0:x0 + 512]
            for local_x, value in enumerate(row):
                if value <= ALPHA_THRESHOLD:
                    continue
                min_x = local_x if min_x is None else min(min_x, local_x)
                max_x = local_x if max_x is None else max(max_x, local_x)
                min_y = local_y if min_y is None else min(min_y, local_y)
                max_y = local_y if max_y is None else max(max_y, local_y)
        assert min_x is not None and min_y is not None and max_x is not None and max_y is not None
        bbox_w = max_x - min_x + 1
        bbox_h = max_y - min_y + 1
        bottom_world = base_y + (341 * 0.5 - (max_y + 1)) * pixel_size
        if animation == "death" and column == 3:
            death_final_max_y = max_y
        print(
            f"CINDER HOUND BBOX {animation:9s} frame={column + 1} "
            f"px=({bbox_w}x{bbox_h}) x={min_x}:{max_x} y={min_y}:{max_y} "
            f"world=({bbox_w * pixel_size:.3f}x{bbox_h * pixel_size:.3f}) "
            f"bottom_local={bottom_world:+.4f}"
        )

assert death_final_max_y is not None
final_bottom_from_origin = (341 * 0.5 - (death_final_max_y + 1)) * pixel_size
final_corpse_gap = (
    corpse_visual_y
    + CORPSE_FLOOR_CLEARANCE
    + final_bottom_from_origin
    + CAPSULE_HEIGHT * 0.5
)
assert math.isclose(final_corpse_gap, TARGET_CONTACT_GAP, abs_tol=0.0006), final_corpse_gap
print(f"CINDER HOUND CORPSE final_gap={final_corpse_gap:+.4f}")
print("cinder hound refresh audit passed")
