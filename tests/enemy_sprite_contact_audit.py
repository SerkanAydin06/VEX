#!/usr/bin/env python3
"""Validate floor-contact offsets for grounded enemy sprites from scene-authored values."""
from __future__ import annotations

from pathlib import Path
import re
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
ACTORS = ROOT / "scenes" / "actors"
ALPHA_THRESHOLD = 16
TARGET_CONTACT_GAP = 0.008
CONTACT_PROPERTIES = {
    "2nd_attack": "second_attack_frame_y_offsets",
    "attack": "attack_frame_y_offsets",
    "attack_close": "attack_close_frame_y_offsets",
    "death": "death_frame_y_offsets",
    "hurt": "hurt_frame_y_offsets",
    "idle": "idle_frame_y_offsets",
    "idle_back": "idle_back_frame_y_offsets",
    "walk": "walk_frame_y_offsets",
    "walk_back": "walk_back_frame_y_offsets",
    "thermal_burst": "thermal_burst_frame_y_offsets",
    "heatwave": "heatwave_frame_y_offsets",
}

# Floating silhouettes intentionally live in dedicated audits instead of being
# forced into the common 8 mm floor-contact contract.
CREATURES = {
    "ravager": "ravager.tscn",
    "basalt_juggernaut": "basalt_juggernaut.tscn",
    "veilmaw": "veilmaw.tscn",
    "furnice_carrier": "furnice_carrier.tscn",
    "crucible_warden": "crucible_warden.tscn",
    "vaskari_raptor": "vaskari_raptor.tscn",
    "vaskari_ravager": "vaskari_ravager.tscn",
    "cinderhound": "cinderhound.tscn",
    "briar_skulker": "briar_skulker.tscn",
    "gorehorn": "gorehorn.tscn",
    "vaskari_bulwark": "vaskari_bulwark.tscn",
    "spore_matriarch": "spore_matriarch.tscn",
    "venom_marshall": "venom_marshall.tscn",
}


def paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    return a if pa <= pb and pa <= pc else b if pb <= pc else c


def decode_png_alpha(path: Path) -> tuple[int, int, list[bytes]]:
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    pos = 8
    idat = bytearray()
    width = height = bit_depth = color_type = interlace = 0
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        chunk_type = data[pos + 4:pos + 8]
        payload = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(">IIBBBBB", payload)
        elif chunk_type == b"IDAT":
            idat.extend(payload)
        elif chunk_type == b"IEND":
            break
    channels = {2: 3, 4: 2, 6: 4}.get(color_type)
    assert bit_depth == 8 and interlace == 0 and channels is not None, path
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
            assert 0 <= filter_type <= 4, (path, filter_type)
            row[index] = (value + predictor) & 0xFF
        rows.append(bytes(row))
        previous = row
    if color_type == 6:
        return width, height, [bytes(row[3::4]) for row in rows]
    if color_type == 4:
        return width, height, [bytes(row[1::2]) for row in rows]
    return width, height, [bytes([255]) * width for _ in rows]


def dictionary_blocks(source: str, marker: str) -> list[str]:
    start = source.index(marker) + len(marker)
    blocks: list[str] = []
    depth = 0
    block_start = -1
    in_string = False
    escaped = False
    for index in range(start, len(source)):
        char = source[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            if depth == 0:
                block_start = index
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0 and block_start >= 0:
                blocks.append(source[block_start:index + 1])
                block_start = -1
        elif char == "]" and depth == 0:
            break
    return blocks


def atlas_regions(source: str, sheet_id: str) -> dict[str, tuple[int, int, int, int]]:
    regions: dict[str, tuple[int, int, int, int]] = {}
    for match in re.finditer(
        r'^\[sub_resource type="AtlasTexture" id="([^"]+)"\]\n(.*?)(?=^\[|\Z)',
        source,
        re.M | re.S,
    ):
        body = match.group(2)
        if f'atlas = ExtResource("{sheet_id}")' not in body:
            continue
        region = re.search(r'^region = Rect2\((\d+), (\d+), (\d+), (\d+)\)$', body, re.M)
        assert region is not None, match.group(1)
        regions[match.group(1)] = tuple(map(int, region.groups()))
    return regions


def bottom_pixel(alpha_rows: list[bytes], region: tuple[int, int, int, int]) -> int:
    x, y, width, height = region
    for local_y in range(height - 1, -1, -1):
        if max(alpha_rows[y + local_y][x:x + width]) > ALPHA_THRESHOLD:
            return local_y
    raise AssertionError((region, "empty frame"))


def packed_float_array(source: str, property_name: str) -> list[float]:
    match = re.search(rf"^{re.escape(property_name)} = PackedFloat32Array\(([^)]*)\)$", source, re.M)
    assert match is not None, property_name
    return [float(value.strip()) for value in match.group(1).split(",")]


def animated_sprite_values(source: str) -> tuple[float, float]:
    match = re.search(
        r'^\[node name="AnimatedSprite3D" type="AnimatedSprite3D"[^\]]*\]\n(.*?)(?=^\[node |\Z)',
        source,
        re.M | re.S,
    )
    assert match is not None
    body = match.group(1)
    pixel = re.search(r'^pixel_size = (-?[0-9.eE+]+)$', body, re.M)
    assert pixel is not None
    position = re.search(r'^position = Vector3\([^,]+, ([^,]+), [^)]+\)$', body, re.M)
    if position:
        sprite_y = float(position.group(1))
    else:
        transform = re.search(r'^transform = Transform3D\(([^\n]+)\)$', body, re.M)
        sprite_y = float(transform.group(1).split(",")[-2].strip()) if transform else 0.0
    return float(pixel.group(1)), sprite_y


def capsule_height(source: str) -> float:
    match = re.search(
        r'^\[sub_resource type="CapsuleShape3D"[^\]]*\]\n(.*?)(?=^\[|\Z)',
        source,
        re.M | re.S,
    )
    assert match is not None
    height = re.search(r'^height = ([0-9.]+)$', match.group(1), re.M)
    assert height is not None
    return float(height.group(1))


failures: list[tuple[str, str, list[float]]] = []
for creature, scene_name in CREATURES.items():
    source = (ACTORS / scene_name).read_text(encoding="utf-8")
    sheet = re.search(
        r'^\[ext_resource type="Texture2D"[^\n]*path="(res://assets/enemies/[^"]+spritesheet\.png)" id="([^"]+)"\]$',
        source,
        re.M,
    )
    assert sheet is not None, creature
    sheet_path = ROOT / sheet.group(1).removeprefix("res://")
    width, height, alpha_rows = decode_png_alpha(sheet_path)
    regions = atlas_regions(source, sheet.group(2))
    assert regions, creature
    pixel_size, sprite_y = animated_sprite_values(source)
    body_height = capsule_height(source)

    measurements: dict[str, float] = {}
    for atlas_id, region in regions.items():
        x, y, frame_width, frame_height = region
        assert x + frame_width <= width and y + frame_height <= height, (creature, atlas_id)
        bottom = bottom_pixel(alpha_rows, region)
        alpha_bottom_y = sprite_y + (frame_height * 0.5 - (bottom + 1)) * pixel_size
        measurements[atlas_id] = alpha_bottom_y + body_height * 0.5

    print(f"CONTACT {creature}")
    used: set[str] = set()
    for animation in dictionary_blocks(source, "animations = ["):
        name_match = re.search(r'"name": &"([^"]+)"', animation)
        if name_match is None or name_match.group(1) not in CONTACT_PROPERTIES:
            continue
        animation_name = name_match.group(1)
        frame_ids = re.findall(r'"texture": SubResource\("([^"]+)"\)', animation)
        frame_ids = [frame_id for frame_id in frame_ids if frame_id in measurements]
        used.update(frame_ids)
        if not frame_ids:
            continue
        offsets = packed_float_array(source, CONTACT_PROPERTIES[animation_name])
        assert len(offsets) == len(frame_ids), (creature, animation_name)
        adjusted = [measurements[frame_id] + offset for frame_id, offset in zip(frame_ids, offsets)]
        tolerance = max(0.0006, pixel_size * 0.55)
        print(f"  {animation_name:12s} " + ",".join(f"{gap:+.4f}" for gap in adjusted))
        if not all(abs(gap - TARGET_CONTACT_GAP) <= tolerance for gap in adjusted):
            failures.append((creature, animation_name, adjusted))

    assert used == set(regions), (creature, "unreferenced atlas frames", set(regions) - used)

assert not failures, failures
print("enemy sprite contact audit passed")
