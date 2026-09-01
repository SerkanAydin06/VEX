#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import json
import re
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
SCENE = ROOT / "scenes/actors/vaskari_bulwark.tscn"
SCRIPT = ROOT / "scripts/actors/vaskari_bulwark.gd"
SHEET = ROOT / "assets/enemies/vaskari_bulwark/vaskari_bulwark_character_spritesheet.png"
MANIFEST = ROOT / "assets/enemies/vaskari_bulwark/vaskari_bulwark_character_spritesheet_manifest.json"
IMPORT = ROOT / "assets/enemies/vaskari_bulwark/vaskari_bulwark_character_spritesheet.png.import"
LUNGE_BASE = ROOT / "scripts/actors/enemy_lunge_base.gd"
ANIM_ROWS = ["idle", "walk", "attack", "death", "idle_back", "walk_back"]
ALPHA_THRESHOLD = 16
TARGET_CONTACT_GAP = 0.008


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
    assert bit_depth == 8 and interlace == 0 and channels is not None, (bit_depth, color_type, interlace)
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


def node_body(source: str, name: str) -> str:
    match = re.search(
        rf'^\[node name="{re.escape(name)}"[^\n]*\]\n(.*?)(?=^\[node |\Z)',
        source,
        re.M | re.S,
    )
    assert match is not None, name
    return match.group(1)


def property_float(source: str, key: str) -> float:
    match = re.search(rf"^{re.escape(key)} = (-?[0-9.]+)$", source, re.M)
    assert match is not None, key
    return float(match.group(1))


manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
assert manifest["sheet_size"] == {"width": 2048, "height": 3072}
assert manifest["frame_size"] == {"width": 512, "height": 512}
assert manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in manifest["rows"]] == ANIM_ROWS
assert all(row["frame_count"] == 4 for row in manifest["rows"])

script = SCRIPT.read_text(encoding="utf-8")
assert "class_name VexVaskariBulwark" in script
assert 'extends "res://scripts/actors/enemy_lunge_base.gd"' in script

scene = SCENE.read_text(encoding="utf-8")
assert 'enemy_id = &"vaskari_bulwark"' in scene
assert "combat_role = 0" in scene
assert "maximum_health = 300" in scene
assert "attack_damage = 30" in scene
assert "attack_range = 2.15" in scene
assert "attack_cooldown = 1.55" in scene
assert "attack_windup = 0.40" in scene
assert "attack_lunge_speed = 6.0" in scene
assert '&"hurt"' not in scene

regions = re.findall(r'region = Rect2\((\d+), (\d+), 512, 512\)', scene)
assert len(regions) == 24, len(regions)
assert set(regions) == {(str(c * 512), str(r * 512)) for r in range(6) for c in range(4)}
assert set(re.findall(r'"name": &"([^"]+)"', scene)) == set(ANIM_ROWS)

import_text = IMPORT.read_text(encoding="utf-8")
assert 'uid="uid://brcm2knf8hn6k"' in import_text
assert "compress/mode=2" in import_text
assert "mipmaps/generate=true" in import_text
assert '"vram_texture": true' in import_text

lunge_base = LUNGE_BASE.read_text(encoding="utf-8")
clearance_match = re.search(r"var corpse_floor_clearance := ([0-9.]+)", lunge_base)
assert clearance_match is not None
corpse_floor_clearance = float(clearance_match.group(1))
assert "animated_sprite.position.y = corpse_visual_y + corpse_floor_clearance" in lunge_base

width, height, alpha = decode_alpha(SHEET)
assert (width, height) == (2048, 3072)
sprite = node_body(scene, "AnimatedSprite3D")
pixel_match = re.search(r'^pixel_size = ([0-9.]+)$', sprite, re.M)
assert pixel_match is not None
pixel_size = float(pixel_match.group(1))
position_match = re.search(r'^position = Vector3\([^,]+, ([^,]+), [^)]+\)$', sprite, re.M)
sprite_y = float(position_match.group(1)) if position_match else 0.0
capsule_height = property_float(scene, "height")
corpse_visual_y = property_float(scene, "corpse_visual_y")
print(f"VASKARI SCALE pixel_size={pixel_size:.6f} sprite_y={sprite_y:+.4f} capsule={capsule_height:.3f}")

final_death_bottom_pixel: int | None = None
for row_index, animation in enumerate(ANIM_ROWS):
    gaps: list[float] = []
    for column in range(4):
        x0 = column * 512
        y0 = row_index * 512
        min_x = min_y = None
        max_x = max_y = None
        for local_y in range(512):
            row = alpha[y0 + local_y][x0:x0 + 512]
            for local_x, value in enumerate(row):
                if value <= ALPHA_THRESHOLD:
                    continue
                min_x = local_x if min_x is None else min(min_x, local_x)
                max_x = local_x if max_x is None else max(max_x, local_x)
                min_y = local_y if min_y is None else min(min_y, local_y)
                max_y = local_y if max_y is None else max(max_y, local_y)
        assert min_x is not None and min_y is not None and max_x is not None and max_y is not None
        if animation == "death" and column == 3:
            final_death_bottom_pixel = max_y
        bbox_w = max_x - min_x + 1
        bbox_h = max_y - min_y + 1
        bottom_local = sprite_y + (256.0 - (max_y + 1)) * pixel_size
        gap = bottom_local + capsule_height * 0.5
        gaps.append(gap)
        print(
            f"VASKARI BBOX {animation:9s} frame={column + 1} "
            f"px=({bbox_w}x{bbox_h}) x={min_x}:{max_x} y={min_y}:{max_y} "
            f"world=({bbox_w * pixel_size:.3f}x{bbox_h * pixel_size:.3f}) "
            f"raw_gap={gap:+.4f}"
        )
    print(f"VASKARI CONTACT {animation:9s} " + ",".join(f"{gap:+.4f}" for gap in gaps))

assert final_death_bottom_pixel is not None
final_death_local_bottom = (256.0 - (final_death_bottom_pixel + 1)) * pixel_size
corpse_gap = (
    corpse_visual_y
    + corpse_floor_clearance
    + final_death_local_bottom
    + capsule_height * 0.5
)
tolerance = max(0.0006, pixel_size * 0.55)
print(f"VASKARI CORPSE final_gap={corpse_gap:+.4f}")
assert abs(corpse_gap - TARGET_CONTACT_GAP) <= tolerance, (
    "Vaskari final corpse floor gap",
    corpse_gap,
    TARGET_CONTACT_GAP,
)

print("vaskari bulwark audit passed")
