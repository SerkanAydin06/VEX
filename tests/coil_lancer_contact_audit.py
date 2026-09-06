#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
SCENE = ROOT / "scenes/actors/coil_lancer.tscn"
SHEET = ROOT / "assets/enemies/coil_lancer/coil_lancer_character_spritesheet.png"
ALPHA_THRESHOLD = 16
TARGET_GAP = 0.008
SPRITE_Y = 0.0
PIXEL_SIZE = 0.0026
CAPSULE_HEIGHT = 1.90
FRAME_WIDTH = 512
FRAME_HEIGHT = 768
ANIM_ROWS = {"idle": 0, "walk": 1, "attack": 2, "death": 3, "idle_back": 4, "walk_back": 5}
PROPERTIES = {
    "idle": "idle_frame_y_offsets", "walk": "walk_frame_y_offsets",
    "attack": "attack_frame_y_offsets", "death": "death_frame_y_offsets",
    "idle_back": "idle_back_frame_y_offsets", "walk_back": "walk_back_frame_y_offsets",
}


def paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    return a if pa <= pb and pa <= pc else b if pb <= pc else c


def decode_alpha(path: Path) -> tuple[int, int, list[bytes]]:
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    pos = 8
    idat = bytearray()
    width = height = bit_depth = color_type = interlace = 0
    while pos < len(data):
        length = int.from_bytes(data[pos:pos + 4], "big")
        kind = data[pos + 4:pos + 8]
        payload = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height = int.from_bytes(payload[0:4], "big"), int.from_bytes(payload[4:8], "big")
            bit_depth, color_type, interlace = payload[8], payload[9], payload[12]
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
        filter_type = raw[cursor]; cursor += 1
        encoded = raw[cursor:cursor + stride]; cursor += stride
        row = bytearray(stride)
        for index, value in enumerate(encoded):
            left = row[index - channels] if index >= channels else 0
            up = previous[index]
            upper_left = previous[index - channels] if index >= channels else 0
            predictor = 0 if filter_type == 0 else left if filter_type == 1 else up if filter_type == 2 else (left + up) // 2 if filter_type == 3 else paeth(left, up, upper_left)
            row[index] = (value + predictor) & 0xFF
        rows.append(bytes(row)); previous = row
    if color_type == 6:
        return width, height, [bytes(row[3::4]) for row in rows]
    if color_type == 4:
        return width, height, [bytes(row[1::2]) for row in rows]
    return width, height, [bytes([255]) * width for _ in rows]


def offsets(source: str, property_name: str) -> list[float]:
    match = re.search(rf"^{property_name} = PackedFloat32Array\(([^)]*)\)$", source, re.M)
    assert match is not None, property_name
    return [float(value.strip()) for value in match.group(1).split(",")]


source = SCENE.read_text(encoding="utf-8")
assert "pixel_size = 0.0026" in source
width, height, alpha = decode_alpha(SHEET)
assert (width, height) == (2048, 4608)
failures = []
for animation, row_index in ANIM_ROWS.items():
    raw_gaps = []
    for column in range(4):
        x = column * FRAME_WIDTH
        y = row_index * FRAME_HEIGHT
        bottom = None
        for local_y in range(FRAME_HEIGHT - 1, -1, -1):
            if max(alpha[y + local_y][x:x + FRAME_WIDTH]) > ALPHA_THRESHOLD:
                bottom = local_y
                break
        assert bottom is not None, (animation, column)
        alpha_bottom_y = SPRITE_Y + (FRAME_HEIGHT * 0.5 - (bottom + 1)) * PIXEL_SIZE
        raw_gaps.append(alpha_bottom_y + CAPSULE_HEIGHT * 0.5)
    authored = offsets(source, PROPERTIES[animation])
    adjusted = [gap + offset for gap, offset in zip(raw_gaps, authored)]
    tolerance = max(0.0006, PIXEL_SIZE * 0.55)
    print(f"COIL LANCER CONTACT {animation:9s} adjusted=" + ",".join(f"{value:+.4f}" for value in adjusted))
    if not all(abs(value - TARGET_GAP) <= tolerance for value in adjusted):
        failures.append((animation, raw_gaps, adjusted))

assert not failures, failures
print("coil lancer contact audit passed")
