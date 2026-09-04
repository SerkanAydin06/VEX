#!/usr/bin/env python3
"""Validate Voidweaver's floating silhouette, hitscan hurtbox, and hover baseline."""
from __future__ import annotations

from pathlib import Path
import re
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
ACTOR_SCENE = ROOT / "scenes" / "actors" / "voidweaver.tscn"
ACTOR_SCRIPT = ROOT / "scripts" / "actors" / "voidweaver.gd"
HITSCAN_RUNTIME = ROOT / "scripts" / "player" / "weapon_hitscan_runtime.gd"
GROUND_CONTACT_AUDIT = ROOT / "tests" / "enemy_sprite_contact_audit.py"

ALPHA_THRESHOLD = 16
TARGET_HOVER_GAP = 0.475
SPRITE_BASE_Y = 0.45
PIXEL_SIZE = 0.0041
CAPSULE_HEIGHT = 1.9
TOLERANCE = max(0.0006, PIXEL_SIZE * 0.55)

CONTACT_PROPERTIES = {
    "attack": "attack_frame_y_offsets",
    "death": "death_frame_y_offsets",
    "idle": "idle_frame_y_offsets",
    "idle_back": "idle_back_frame_y_offsets",
    "walk": "walk_frame_y_offsets",
    "walk_back": "walk_back_frame_y_offsets",
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


def bottom_pixel(alpha_rows: list[bytes], region: tuple[int, int, int, int]) -> int:
    x, y, width, height = region
    for local_y in range(height - 1, -1, -1):
        if max(alpha_rows[y + local_y][x : x + width]) > ALPHA_THRESHOLD:
            return local_y
    raise AssertionError((region, "empty frame"))


def packed_float_array(source: str, property_name: str) -> list[float]:
    match = re.search(
        rf"^{re.escape(property_name)} = PackedFloat32Array\(([^)]*)\)$",
        source,
        re.M,
    )
    assert match is not None, property_name
    return [float(value.strip()) for value in match.group(1).split(",")]


def node_block(source: str, node_name: str) -> str:
    match = re.search(
        rf'^\[node name="{re.escape(node_name)}"[^\]]*\]\n(.*?)(?=^\[node |\Z)',
        source,
        re.M | re.S,
    )
    assert match is not None, node_name
    return match.group(1)


def main() -> None:
    actor = ACTOR_SCENE.read_text(encoding="utf-8")
    actor_script = ACTOR_SCRIPT.read_text(encoding="utf-8")
    hitscan = HITSCAN_RUNTIME.read_text(encoding="utf-8")
    floor_audit = GROUND_CONTACT_AUDIT.read_text(encoding="utf-8")

    # Ground movement stays on the root capsule; only weapon damage follows the
    # floating silhouette. This avoids breaking floor snap/navigation.
    assert re.search(r'^radius = 0\.45$', actor, re.M)
    assert re.search(r'^height = 1\.9$', actor, re.M)
    root_collision = node_block(actor, "CollisionShape3D")
    assert "position =" not in root_collision and "transform =" not in root_collision

    assert '[sub_resource type="BoxShape3D" id="BoxShape_weapon_hurtbox"]' in actor
    assert re.search(r'^size = Vector3\(1, 2\.05, 1\)$', actor, re.M)
    hurtbox = node_block(actor, "WeaponHurtbox")
    assert re.search(r'^position = Vector3\(0, 0\.55, 0\)$', hurtbox, re.M)
    assert re.search(r'^collision_layer = 4$', hurtbox, re.M)
    assert re.search(r'^collision_mask = 0$', hurtbox, re.M)
    assert re.search(r'^monitoring = false$', hurtbox, re.M)
    hurtbox_shape = re.search(
        r'^\[node name="CollisionShape3D" type="CollisionShape3D" parent="WeaponHurtbox"\]\n(.*?)(?=^\[node |\Z)',
        actor,
        re.M | re.S,
    )
    assert hurtbox_shape is not None
    assert 'shape = SubResource("BoxShape_weapon_hurtbox")' in hurtbox_shape.group(1)

    assert re.search(r'^headshot_reference_height = 1\.7$', actor, re.M)
    assert re.search(r'^corpse_visual_y = 0\.53$', actor, re.M)
    assert re.search(r'^back_corpse_visual_y = 0\.53$', actor, re.M)
    assert "func accepts_weapon_hit(" in actor_script
    assert "collider == _weapon_hurtbox" in actor_script
    assert "state != State.DEAD" in actor_script
    assert 'has_method("accepts_weapon_hit")' in hitscan
    assert 'damage_target.call("accepts_weapon_hit", collider, hit_position)' in hitscan

    # Floating enemies must not be held to the generic 8 mm ground-contact rule.
    assert '"voidweaver": CreatureSpec(' not in floor_audit

    sheet = re.search(
        r'^\[ext_resource type="Texture2D"[^\n]*path="(res://assets/enemies/voidweaver/[^"]+spritesheet\.png)" id="([^"]+)"\]$',
        actor,
        re.M,
    )
    assert sheet is not None
    sheet_path = ROOT / sheet.group(1).removeprefix("res://")
    width, height, alpha_rows = decode_png_alpha(sheet_path)
    assert (width, height) == (1364, 3072)
    regions = atlas_regions(actor, sheet.group(2))
    assert len(regions) == 24

    measurements: dict[str, float] = {}
    for atlas_id, region in regions.items():
        bottom = bottom_pixel(alpha_rows, region)
        measurements[atlas_id] = (
            SPRITE_BASE_Y
            + (region[3] * 0.5 - (bottom + 1)) * PIXEL_SIZE
            + CAPSULE_HEIGHT * 0.5
        )

    used: set[str] = set()
    for animation in dictionary_blocks(actor, "animations = ["):
        name_match = re.search(r'"name": &"([^"]+)"', animation)
        if name_match is None or name_match.group(1) not in CONTACT_PROPERTIES:
            continue
        animation_name = name_match.group(1)
        frame_ids = re.findall(r'"texture": SubResource\("([^"]+)"\)', animation)
        used.update(frame_ids)
        offsets = packed_float_array(actor, CONTACT_PROPERTIES[animation_name])
        assert len(frame_ids) == 4 and len(offsets) == 4, animation_name
        adjusted = [measurements[frame_id] + offset for frame_id, offset in zip(frame_ids, offsets)]
        print(
            f"HOVER {animation_name:10s} "
            + ",".join(f"{gap:.4f}" for gap in adjusted)
        )
        assert all(abs(gap - TARGET_HOVER_GAP) <= TOLERANCE for gap in adjusted), (
            animation_name,
            adjusted,
            TARGET_HOVER_GAP,
        )

    assert used == set(regions), ("unreferenced atlas frames", set(regions) - used)
    print("voidweaver hover audit passed")


if __name__ == "__main__":
    main()
