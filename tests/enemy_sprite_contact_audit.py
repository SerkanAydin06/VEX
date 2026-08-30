#!/usr/bin/env python3
"""Measure every enemy animation frame against its scene-authored floor plane.

The decoder deliberately uses only the Python standard library so this audit can
run in the same lightweight CI job as the other repository audits.
"""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
ACTORS = ROOT / "scenes" / "actors"
ALPHA_THRESHOLD = 16
TARGET_CONTACT_GAP = 0.008
CONTACT_PROPERTIES = {
    "attack": "attack_frame_y_offsets",
    "attack_close": "attack_close_frame_y_offsets",
    "death": "death_frame_y_offsets",
    "hurt": "hurt_frame_y_offsets",
    "idle": "idle_frame_y_offsets",
    "idle_back": "idle_back_frame_y_offsets",
    "idle_side": "idle_side_frame_y_offsets",
    "idle_front_side": "idle_front_side_frame_y_offsets",
    "walk": "walk_frame_y_offsets",
    "walk_back": "walk_back_frame_y_offsets",
    "walk_side": "walk_side_frame_y_offsets",
    "walk_front_side": "walk_front_side_frame_y_offsets",
    "thermal_burst": "thermal_burst_frame_y_offsets",
    "heatwave": "heatwave_frame_y_offsets",
}


@dataclass(frozen=True)
class CreatureSpec:
    scene: str
    sprite_y: float
    pixel_size: float
    capsule_height: float


CREATURES = {
    "ravager": CreatureSpec("ravager.tscn", -0.15, 0.003525, 1.80),
    "hellmagma": CreatureSpec("hellmagma.tscn", -0.10, 0.0073547, 3.60),
    "veilmaw": CreatureSpec("veilmaw.tscn", 0.0, 0.0041, 1.90),
    "voidweaver": CreatureSpec("voidweaver.tscn", 0.0, 0.0041, 1.90),
    "furnice_carrier": CreatureSpec("furnice_carrier.tscn", 0.44470531, 0.008, 1.50),
    "crucible_warden": CreatureSpec("crucible_warden.tscn", 0.44, 0.0064, 2.40),
    "redviper": CreatureSpec("redviper.tscn", 0.0000225, 0.003515713, 1.80),
    "badredviper": CreatureSpec("badredviper.tscn", 0.1333, 0.0065753907, 3.10),
    "cinderhound": CreatureSpec("cinderhound.tscn", 0.1454, 0.0034, 1.45),
    "briar_skulker": CreatureSpec("briar_skulker.tscn", 0.0, 0.003125, 1.60),
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
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        chunk_type = data[pos + 4 : pos + 8]
        payload = data[pos + 8 : pos + 8 + length]
        pos += 12 + length
        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(
                ">IIBBBBB", payload
            )
        elif chunk_type == b"IDAT":
            idat.extend(payload)
        elif chunk_type == b"IEND":
            break

    channels = {2: 3, 4: 2, 6: 4}.get(color_type)
    assert bit_depth == 8 and interlace == 0 and channels is not None, (
        path,
        bit_depth,
        color_type,
        interlace,
    )
    raw = zlib.decompress(bytes(idat))
    stride = width * channels
    rows: list[bytes] = []
    cursor = 0
    previous = bytearray(stride)
    for _ in range(height):
        filter_type = raw[cursor]
        cursor += 1
        encoded = raw[cursor : cursor + stride]
        cursor += stride
        row = bytearray(stride)
        for index, value in enumerate(encoded):
            left = row[index - channels] if index >= channels else 0
            up = previous[index]
            upper_left = previous[index - channels] if index >= channels else 0
            predictor = (
                0
                if filter_type == 0
                else left
                if filter_type == 1
                else up
                if filter_type == 2
                else (left + up) // 2
                if filter_type == 3
                else paeth(left, up, upper_left)
            )
            assert 0 <= filter_type <= 4, (path, filter_type)
            row[index] = (value + predictor) & 0xFF
        rows.append(bytes(row))
        previous = row

    alpha_rows: list[bytes] = []
    if color_type == 6:
        alpha_rows = [bytes(row[3::4]) for row in rows]
    elif color_type == 4:
        alpha_rows = [bytes(row[1::2]) for row in rows]
    else:
        alpha_rows = [bytes([255]) * width for _ in rows]
    return width, height, alpha_rows


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
                blocks.append(source[block_start : index + 1])
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
        region = re.search(
            r'^region = Rect2\((\d+), (\d+), (\d+), (\d+)\)$', body, re.M
        )
        assert region is not None, match.group(1)
        regions[match.group(1)] = tuple(map(int, region.groups()))
    return regions


def bottom_pixel(
    alpha_rows: list[bytes], region: tuple[int, int, int, int]
) -> int | None:
    x, y, width, height = region
    for local_y in range(height - 1, -1, -1):
        if max(alpha_rows[y + local_y][x : x + width]) > ALPHA_THRESHOLD:
            return local_y
    return None


def frame_gap(spec: CreatureSpec, region_height: int, bottom: int) -> float:
    alpha_bottom_y = spec.sprite_y + (region_height * 0.5 - (bottom + 1)) * spec.pixel_size
    return alpha_bottom_y + spec.capsule_height * 0.5


def packed_float_array(source: str, property_name: str) -> list[float]:
    match = re.search(
        rf"^{re.escape(property_name)} = PackedFloat32Array\(([^)]*)\)$",
        source,
        re.M,
    )
    assert match is not None, property_name
    return [float(value.strip()) for value in match.group(1).split(",")]


contact_failures: list[tuple[str, str, list[float], float]] = []

for creature, spec in CREATURES.items():
    scene_path = ACTORS / spec.scene
    source = scene_path.read_text(encoding="utf-8")
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

    measurements: dict[str, float] = {}
    for atlas_id, region in regions.items():
        x, y, frame_width, frame_height = region
        assert x + frame_width <= width and y + frame_height <= height, (creature, atlas_id)
        bottom = bottom_pixel(alpha_rows, region)
        assert bottom is not None, (creature, atlas_id, "empty frame")
        measurements[atlas_id] = frame_gap(spec, frame_height, bottom)

    print(f"CONTACT {creature}")
    used: set[str] = set()
    for animation in dictionary_blocks(source, "animations = ["):
        name_match = re.search(r'"name": &"([^"]+)"', animation)
        if name_match is None:
            continue
        frame_ids = re.findall(r'"texture": SubResource\("([^"]+)"\)', animation)
        gaps = [measurements[frame_id] for frame_id in frame_ids if frame_id in measurements]
        used.update(frame_id for frame_id in frame_ids if frame_id in measurements)
        if not gaps:
            continue
        property_name = CONTACT_PROPERTIES[name_match.group(1)]
        offsets = packed_float_array(source, property_name)
        assert len(offsets) == len(gaps), (creature, name_match.group(1), offsets, gaps)
        adjusted_gaps = [gap + offset for gap, offset in zip(gaps, offsets)]
        tolerance = max(0.0006, spec.pixel_size * 0.55)
        print(
            f"  {name_match.group(1):12s} gap="
            + ",".join(f"{gap:+.4f}" for gap in gaps)
            + " authored_offset="
            + ",".join(f"{offset:+.4f}" for offset in offsets)
            + " adjusted="
            + ",".join(f"{gap:+.4f}" for gap in adjusted_gaps)
        )
        if not all(
            abs(adjusted_gap - TARGET_CONTACT_GAP) <= tolerance
            for adjusted_gap in adjusted_gaps
        ):
            contact_failures.append(
                (creature, name_match.group(1), adjusted_gaps, TARGET_CONTACT_GAP)
            )
    assert used == set(regions), (creature, "unreferenced atlas frames", set(regions) - used)

assert not contact_failures, contact_failures
print("enemy sprite contact audit passed")
