#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/enemies/venom_marshall"
ACTOR = ROOT / "scenes/actors/venom_marshall.tscn"
NORMAL_PROJECTILE = ROOT / "scenes/actors/venom_marshall_projectile.tscn"
BUFF_PROJECTILE = ROOT / "scenes/actors/venom_marshall_buff_projectile.tscn"
ACTOR_SCRIPT = ROOT / "scripts/actors/venom_marshall.gd"
BUFF_SCRIPT = ROOT / "scripts/actors/venom_marshall_buff_projectile.gd"
BUFF_STATUS = ROOT / "scripts/actors/venom_marshall_buff_status.gd"
LEVEL_TEST = ROOT / "scenes/levels/level_test.tscn"
TARGET_GAP = 0.008
ALPHA_THRESHOLD = 16
PIXEL_SIZE = 0.0042
SPRITE_Y = 0.0
CAPSULE_HEIGHT = 1.9

ANIMATIONS = [
    ("idle", 0, "idle_frame_y_offsets"),
    ("walk", 1, "walk_frame_y_offsets"),
    ("attack", 2, "attack_frame_y_offsets"),
    ("2nd_attack", 3, "second_attack_frame_y_offsets"),
    ("death", 4, "death_frame_y_offsets"),
    ("idle_back", 5, "idle_back_frame_y_offsets"),
    ("walk_back", 6, "walk_back_frame_y_offsets"),
]


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
                0 if filter_type == 0 else
                left if filter_type == 1 else
                up if filter_type == 2 else
                (left + up) // 2 if filter_type == 3 else
                paeth(left, up, upper_left)
            )
            assert 0 <= filter_type <= 4, filter_type
            row[index] = (value + predictor) & 0xFF
        rows.append(bytes(row))
        previous = row
    if color_type == 6:
        alpha_rows = [bytes(row[3::4]) for row in rows]
    elif color_type == 4:
        alpha_rows = [bytes(row[1::2]) for row in rows]
    else:
        alpha_rows = [bytes([255]) * width for _ in rows]
    return width, height, alpha_rows


def bottom_pixel(alpha_rows: list[bytes], x: int, y: int) -> int:
    for local_y in range(511, -1, -1):
        if max(alpha_rows[y + local_y][x : x + 341]) > ALPHA_THRESHOLD:
            return local_y
    raise AssertionError((x, y, "empty frame"))


def packed_array(source: str, property_name: str) -> list[float]:
    match = re.search(
        rf"^{re.escape(property_name)} = PackedFloat32Array\(([^)]*)\)$",
        source,
        re.M,
    )
    assert match is not None, property_name
    return [float(value.strip()) for value in match.group(1).split(",")]


for path in [ACTOR, NORMAL_PROJECTILE, BUFF_PROJECTILE, ACTOR_SCRIPT, BUFF_SCRIPT, BUFF_STATUS]:
    assert path.exists(), path

character_manifest = json.loads(
    (ASSET / "venom_marshall_character_spritesheet_manifest.json").read_text(encoding="utf-8")
)
effects_manifest = json.loads(
    (ASSET / "venom_marshall_effects_spritesheet_manifest.json").read_text(encoding="utf-8")
)
assert character_manifest["sheet_size"] == {"width": 1364, "height": 3584}
assert character_manifest["frame_size"] == {"width": 341, "height": 512}
assert character_manifest["grid"] == {"columns": 4, "rows": 7}
assert [row["animation"] for row in character_manifest["rows"]] == [
    "idle", "walk", "attack", "2nd_attack", "death", "idle_back", "walk_back"
]
assert effects_manifest["sheet_size"] == {"width": 2048, "height": 1536}
assert effects_manifest["frame_size"] == {"width": 512, "height": 512}
assert effects_manifest["grid"] == {"columns": 4, "rows": 3}
assert [row["animation"] for row in effects_manifest["rows"]] == [
    "projectile", "2nd_projectile", "impact"
]

actor = ACTOR.read_text(encoding="utf-8")
actor_script = ACTOR_SCRIPT.read_text(encoding="utf-8")
normal_projectile = NORMAL_PROJECTILE.read_text(encoding="utf-8")
buff_projectile = BUFF_PROJECTILE.read_text(encoding="utf-8")
buff_script = BUFF_SCRIPT.read_text(encoding="utf-8")
buff_status = BUFF_STATUS.read_text(encoding="utf-8")
level_test = LEVEL_TEST.read_text(encoding="utf-8")

assert 'extends "res://scripts/actors/enemy_combatant_performance_base.gd"' in actor_script
for contract in [
    'enemy_id = &"venom_marshall"',
    "combat_role = 1",
    "maximum_health = 120",
    "attack_damage = 11",
    "attack_range = 19.0",
    "attack_cooldown = 1.55",
    'projectile_scene = ExtResource("3_projectile")',
    'buff_projectile_scene = ExtResource("4_buff_projectile")',
    "support_search_radius = 16.0",
    "support_minimum_allies = 2",
    "emergency_heal_ratio = 0.65",
    "buff_skill_cooldown = 11.0",
    "pixel_size = 0.0042",
    "billboard = 2",
    "shaded = true",
    "cast_shadow = 0",
]:
    assert contract in actor, contract

sprite_block = re.search(
    r'^\[node name="AnimatedSprite3D".*?(?=^\[node |\Z)', actor, re.M | re.S
).group(0)
assert "material_override" not in sprite_block

regions = re.findall(r"region = Rect2\((\d+), (\d+), (\d+), (\d+)\)", actor)
assert len(regions) == 28, len(regions)
expected_regions = [
    (str(column * 341), str(row * 512), "341", "512")
    for row in range(7)
    for column in range(4)
]
assert regions == expected_regions, regions

for contract in [
    '"name": &"projectile"',
    '"name": &"impact"',
    'path="res://assets/enemies/venom_marshall/venom_marshall_effects_spritesheet.png"',
]:
    assert contract in normal_projectile, contract
for contract in [
    '"name": &"2nd_projectile"',
    '"name": &"impact"',
    "field_radius = 6.5",
    "field_duration = 8.0",
    "heal_ratio = 0.3",
    "damage_multiplier = 1.25",
    "speed_multiplier = 1.2",
    "buff_grace_duration = 1.25",
]:
    assert contract in buff_projectile, contract

for contract in [
    'animated_sprite.play(attack_animation)',
    '&"2nd_attack"',
    "support_minimum_allies",
    "emergency_heal_ratio",
    "EnemyProjectilePool.acquire",
    'projectile.call("launch_toward", target_position, self)',
]:
    assert contract in actor_script, contract
for contract in [
    "get_overlapping_bodies()",
    'target.add_child' if False else 'enemy.add_child(status)',
    '"refresh_buff"',
    "EnemyProjectilePool.recycle(self)",
    "cylinder.radius = field_radius",
]:
    assert contract in buff_script, contract
for contract in [
    '"_runtime_attack_damage"',
    '"_runtime_move_speed"',
    '"_runtime_chase_speed"',
    'remove_meta("vex_venom_marshall_buffed")',
]:
    assert contract in buff_status, contract

assert level_test.count('path="res://scenes/actors/venom_marshall.tscn"') == 1
assert level_test.count('enemy_id = &"level_test_venom_marshall"') == 1

width, height, alpha_rows = decode_png_alpha(
    ASSET / "venom_marshall_character_spritesheet.png"
)
assert (width, height) == (1364, 3584)
contact_failures: list[tuple[str, list[float]]] = []
for animation, row, property_name in ANIMATIONS:
    offsets = packed_array(actor, property_name)
    assert len(offsets) == 4, (animation, offsets)
    adjusted: list[float] = []
    raw_gaps: list[float] = []
    for column in range(4):
        bottom = bottom_pixel(alpha_rows, column * 341, row * 512)
        raw_gap = (
            SPRITE_Y
            + (512 * 0.5 - (bottom + 1)) * PIXEL_SIZE
            + CAPSULE_HEIGHT * 0.5
        )
        raw_gaps.append(raw_gap)
        adjusted.append(raw_gap + offsets[column])
    tolerance = max(0.0006, PIXEL_SIZE * 0.55)
    print(
        f"VENOM CONTACT {animation:10s} raw="
        + ",".join(f"{gap:+.4f}" for gap in raw_gaps)
        + " offset="
        + ",".join(f"{offset:+.4f}" for offset in offsets)
        + " adjusted="
        + ",".join(f"{gap:+.4f}" for gap in adjusted)
    )
    if not all(abs(gap - TARGET_GAP) <= tolerance for gap in adjusted):
        contact_failures.append((animation, adjusted))

assert not contact_failures, contact_failures
print("Venom Marshall integration audit passed")
