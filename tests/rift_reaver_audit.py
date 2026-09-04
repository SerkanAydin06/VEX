#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import json
import re
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
ALPHA_THRESHOLD = 16
TARGET_GAP = 0.008
PIXEL_SIZE = 0.0041
CAPSULE_HEIGHT = 1.9


def read(relative: str) -> str:
    path = ROOT / relative
    assert path.exists(), path
    return path.read_text(encoding="utf-8")


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
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(
                ">IIBBBBB", payload
            )
        elif kind == b"IDAT":
            idat.extend(payload)
        elif kind == b"IEND":
            break

    channels = {4: 2, 6: 4}.get(color_type)
    assert bit_depth == 8 and interlace == 0 and channels is not None, (
        path, bit_depth, color_type, interlace
    )
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
            if filter_type == 0:
                predictor = 0
            elif filter_type == 1:
                predictor = left
            elif filter_type == 2:
                predictor = up
            elif filter_type == 3:
                predictor = (left + up) // 2
            else:
                p = left + up - upper_left
                pa, pb, pc = abs(p - left), abs(p - up), abs(p - upper_left)
                predictor = left if pa <= pb and pa <= pc else up if pb <= pc else upper_left
            assert 0 <= filter_type <= 4
            row[index] = (value + predictor) & 0xFF
        rows.append(bytes(row))
        previous = row

    alpha_index = 3 if color_type == 6 else 1
    return width, height, [bytes(row[alpha_index::channels]) for row in rows]


def bottom_pixel(alpha_rows: list[bytes], x: int, y: int, width: int, height: int) -> int:
    for local_y in range(height - 1, -1, -1):
        if max(alpha_rows[y + local_y][x:x + width]) > ALPHA_THRESHOLD:
            return local_y
    raise AssertionError((x, y, width, height, "empty frame"))


def packed_offsets(scene: str, property_name: str) -> list[float]:
    match = re.search(
        rf"^{re.escape(property_name)} = PackedFloat32Array\(([^)]*)\)$",
        scene,
        re.M,
    )
    assert match is not None, property_name
    return [float(value.strip()) for value in match.group(1).split(",")]


manifest = json.loads(read("assets/enemies/rift_reaver/rift_reaver_character_spritesheet_manifest.json"))
scene = read("scenes/actors/rift_reaver.tscn")
script = read("scripts/actors/rift_reaver.gd")
audio_runtime = read("scripts/actors/rift_reaver_audio_runtime.gd")
fx_runtime = read("scripts/effects/rift_reaver_fx.gd")
metadata = read("assets/enemies/rift_reaver/rift_reaver_character_spritesheet.png.import")
sheet_path = ROOT / "assets/enemies/rift_reaver/rift_reaver_character_spritesheet.png"

assert manifest["sheet_size"] == {"width": 1364, "height": 3072}
assert manifest["frame_size"] == {"width": 341, "height": 512}
assert manifest["grid"] == {"columns": 4, "rows": 6}
animations = [row["animation"] for row in manifest["rows"]]
assert animations == ["idle", "walk", "attack", "death", "idle_back", "walk_back"]
assert all(row["frame_count"] == 4 for row in manifest["rows"])

assert "class_name VexRiftReaver" in script
assert 'extends "res://scripts/actors/enemy_lunge_performance_base.gd"' in script
assert "@export" not in script
for token in [
    'preload("res://scripts/actors/rift_reaver_audio_runtime.gd")',
    'preload("res://scripts/effects/rift_reaver_fx.gd")',
    "RiftReaverAudio.attack_stream()",
    "RiftReaverAudio.hurt_stream()",
    "RiftReaverAudio.death_stream()",
    "RiftReaverFx.spawn_attack_start",
    "RiftReaverFx.spawn_wake",
    "RiftReaverFx.spawn_impact",
    "RiftReaverFx.spawn_hurt",
    "RiftReaverFx.spawn_death",
    "WAKE_INTERVAL := 0.045",
]:
    assert token in script, token

# Rift Reaver no longer loads Voidweaver's borrowed combat audio assets.
for borrowed_audio in [
    "void_weaver_attack.wav",
    "void_weaver_hurt.wav",
    "voidweaver_death.wav",
]:
    assert borrowed_audio not in scene, borrowed_audio
assert 'stream = ExtResource("3_attack")' not in scene
assert 'stream = ExtResource("4_hurt")' not in scene
assert 'stream = ExtResource("5_death")' not in scene

# Spatial mix remains scene/Inspector authored even though stream generation is runtime-owned.
for node_name, volume, max_distance in [
    ("AttackAudio", "-2.0", "18.0"),
    ("HurtAudio", "-2.5", "18.0"),
    ("DeathAudio", "-1.0", "20.0"),
]:
    block_match = re.search(
        rf'^\[node name="{node_name}" type="AudioStreamPlayer3D" parent="\."\]\n(.*?)(?=^\[|\Z)',
        scene,
        re.M | re.S,
    )
    assert block_match is not None, node_name
    block = block_match.group(1)
    assert f"volume_db = {volume}" in block, (node_name, volume)
    assert "pitch_scale = 0.92" in block, node_name
    assert f"max_distance = {max_distance}" in block, (node_name, max_distance)
    assert 'bus = &"SFX"' in block, node_name

# Unique Aether audio is deterministic PCM generated once and cached per sound kind.
for token in [
    "MIX_RATE := 22050",
    "ATTACK_DURATION := 0.34",
    "HURT_DURATION := 0.28",
    "DEATH_DURATION := 0.92",
    "AudioStreamWAV.new()",
    "AudioStreamWAV.FORMAT_16_BITS",
    "stream.mix_rate = MIX_RATE",
    "stream.data = pcm",
    "static var _attack_stream: AudioStreamWAV",
    "static var _hurt_stream: AudioStreamWAV",
    "static var _death_stream: AudioStreamWAV",
]:
    assert token in audio_runtime, token
assert "randf" not in audio_runtime
assert "randi" not in audio_runtime

# Transient Aether feedback stays runtime-owned and does not add persistent scene nodes.
for token in [
    "Sprite3D.new()",
    "OmniLight3D.new()",
    "SHADOW_CASTING_SETTING_OFF",
    "spawn_attack_start",
    "spawn_wake",
    "spawn_impact",
    "spawn_hurt",
    "spawn_death",
    "Color(0.24, 0.86, 1.0, 1.0)",
]:
    assert token in fx_runtime, token

for token in [
    'path="res://assets/enemies/rift_reaver/rift_reaver_character_spritesheet.png"',
    'enemy_id = &"rift_reaver"',
    "combat_role = 0",
    "maximum_health = 135",
    "move_speed = 3.4",
    "chase_speed = 6.6",
    "attack_range = 2.0",
    "attack_damage = 22",
    "attack_cooldown = 1.05",
    "attack_windup = 0.22",
    "attack_lunge_speed = 10.6",
    "billboard = 2",
    "render_priority = -2",
    "offset = Vector2(0, 16)",
    "corpse_visual_y = 0.0466",
    "back_corpse_visual_y = 0.0466",
    "burn_scorch_tint = Color(0.035, 0.15, 0.2, 0.95)",
    "burn_ember_tint = Color(0.12, 0.72, 0.92, 0.3)",
    "burn_ember_emission_energy = 0.18",
    "burn_smoke_enabled = false",
]:
    assert token in scene, token

regions = re.findall(r'region = Rect2\((\d+), (\d+), 341, 512\)', scene)
assert len(regions) == 24, len(regions)
assert set(regions) == {
    (str(column * 341), str(row * 512))
    for row in range(6)
    for column in range(4)
}
assert set(re.findall(r'"name": &"([^"]+)"', scene)) == set(animations)

assert "radius = 0.46" in scene
assert "height = 1.9" in scene
assert "compress/mode=2" in metadata
assert "mipmaps/generate=true" in metadata
assert "detect_3d/compress_to=0" in metadata

width, height, alpha_rows = decode_alpha(sheet_path)
assert (width, height) == (1364, 3072)
property_names = {
    "idle": "idle_frame_y_offsets",
    "walk": "walk_frame_y_offsets",
    "attack": "attack_frame_y_offsets",
    "death": "death_frame_y_offsets",
    "idle_back": "idle_back_frame_y_offsets",
    "walk_back": "walk_back_frame_y_offsets",
}
for row_index, animation in enumerate(animations):
    offsets = packed_offsets(scene, property_names[animation])
    assert len(offsets) == 4
    adjusted: list[float] = []
    for column, offset in enumerate(offsets):
        bottom = bottom_pixel(alpha_rows, column * 341, row_index * 512, 341, 512)
        raw_gap = (256 - (bottom + 1)) * PIXEL_SIZE + CAPSULE_HEIGHT * 0.5
        adjusted.append(raw_gap + offset)
    tolerance = max(0.0006, PIXEL_SIZE * 0.55)
    print(f"RIFT CONTACT {animation:10s} " + ",".join(f"{gap:+.4f}" for gap in adjusted))
    assert all(abs(gap - TARGET_GAP) <= tolerance for gap in adjusted), (animation, adjusted)

# Final death frame must retain the same 8 mm clearance after corpse tween.
final_death_bottom = bottom_pixel(alpha_rows, 3 * 341, 3 * 512, 341, 512)
corpse_base = 0.0466 + 0.02  # inherited corpse_floor_clearance default
final_corpse_gap = corpse_base + (256 - (final_death_bottom + 1)) * PIXEL_SIZE + CAPSULE_HEIGHT * 0.5
assert abs(final_corpse_gap - TARGET_GAP) <= max(0.0006, PIXEL_SIZE * 0.55), final_corpse_gap

print("rift reaver audit passed")
