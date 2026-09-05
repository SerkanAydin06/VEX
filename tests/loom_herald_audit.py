import json
import re
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets/enemies/loom_herald"
ACTOR_SCENE = ROOT / "scenes/actors/loom_herald.tscn"
PROJECTILE_SCENE = ROOT / "scenes/actors/loom_herald_projectile.tscn"
ACTOR_SCRIPT = ROOT / "scripts/actors/loom_herald.gd"
ABILITY_SCRIPT = ROOT / "scripts/actors/loom_herald_ability_settings.gd"
LEVEL_SCRIPT = ROOT / "scripts/levels/level_03.gd"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f"not a PNG: {path}"
    assert data[12:16] == b"IHDR", f"PNG IHDR missing: {path}"
    return struct.unpack(">II", data[16:24])


def packed_float_values(scene: str, key: str) -> list[float]:
    match = re.search(
        rf"(?m)^{re.escape(key)} = PackedFloat32Array\(([^)]*)\)$",
        scene,
    )
    assert match, f"missing {key}"
    return [float(value.strip()) for value in match.group(1).split(",") if value.strip()]


character_png = ASSET_DIR / "loom_herald_character_spritesheet.png"
effects_png = ASSET_DIR / "loom_herald_effects_spritesheet.png"
character_manifest_path = ASSET_DIR / "loom_herald_character_spritesheet_manifest.json"
effects_manifest_path = ASSET_DIR / "loom_herald_effects_spritesheet_manifest.json"

for required in (
    character_png,
    effects_png,
    character_manifest_path,
    effects_manifest_path,
    ACTOR_SCENE,
    PROJECTILE_SCENE,
    ACTOR_SCRIPT,
    ABILITY_SCRIPT,
):
    assert required.exists(), f"Loom Herald integration file missing: {required.relative_to(ROOT)}"

assert png_size(character_png) == (1364, 3072)
assert png_size(effects_png) == (2048, 1024)

character_manifest = json.loads(read(character_manifest_path))
effects_manifest = json.loads(read(effects_manifest_path))
assert character_manifest["frame_size"] == {"width": 341, "height": 512}
assert character_manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in character_manifest["rows"]] == [
    "idle",
    "walk",
    "attack",
    "death",
    "idle_back",
    "walk_back",
]
assert all(row["frame_count"] == 4 for row in character_manifest["rows"])
assert effects_manifest["frame_size"] == {"width": 512, "height": 512}
assert effects_manifest["grid"] == {"columns": 4, "rows": 2}
assert [row["animation"] for row in effects_manifest["rows"]] == ["projectile", "impact"]

actor_scene = read(ACTOR_SCENE)
actor_script = read(ACTOR_SCRIPT)
ability_script = read(ABILITY_SCRIPT)
projectile_scene = read(PROJECTILE_SCENE)
level_script = read(LEVEL_SCRIPT)

assert 'path="res://assets/enemies/loom_herald/loom_herald_character_spritesheet.png"' in actor_scene
assert 'path="res://scenes/actors/loom_herald_projectile.tscn"' in actor_scene
assert 'enemy_id = &"loom_herald"' in actor_scene
assert "projectile_spawn_height = 0.78" in actor_scene
assert "position = Vector3(0, 0.45, 0)" in actor_scene
assert "pixel_size = 0.0041" in actor_scene
assert '[node name="WeaponHurtbox" type="Area3D" parent="."]' in actor_scene

# Loom Herald is intentionally hovering. Do not normalize away the authored
# vertical bob in source art with per-frame ground offsets.
for key in (
    "idle_frame_y_offsets",
    "idle_back_frame_y_offsets",
    "walk_frame_y_offsets",
    "walk_back_frame_y_offsets",
    "attack_frame_y_offsets",
    "death_frame_y_offsets",
):
    values = packed_float_values(actor_scene, key)
    assert values == [0.0, 0.0, 0.0, 0.0], f"{key} must preserve Loom hover motion"

# Character atlas must map the exact 4x6 source grid without scaling/reordering.
for row_index, animation in enumerate(("idle", "walk", "attack", "death", "idle_back", "walk_back")):
    for column in range(4):
        atlas_id = f"Atlas_{animation}_{column + 1}"
        expected_region = f"region = Rect2({column * 341}, {row_index * 512}, 341, 512)"
        block = re.search(
            rf'\[sub_resource type="AtlasTexture" id="{re.escape(atlas_id)}"\](.*?)(?=\n\[)',
            actor_scene,
            re.S,
        )
        assert block, f"missing atlas {atlas_id}"
        assert expected_region in block.group(1), f"wrong region for {atlas_id}"

assert 'extends "res://scripts/actors/enemy_combatant_performance_base.gd"' in actor_script
assert "func accepts_weapon_hit" in actor_script
assert "collider == _weapon_hurtbox" in actor_script
assert "for shot_index: int in range(2):" in actor_script
assert "side_sign * _ability.emitter_half_span" in actor_script
assert "side_sign * _ability.volley_half_angle_degrees" in actor_script
assert "ProjectileFireRuntime.fire(" in actor_script

assert "var emitter_half_span := 0.36" in ability_script
assert "var volley_half_angle_degrees := 2.5" in ability_script
assert "var projectile_damage_scale := 0.65" in ability_script

assert 'path="res://assets/enemies/loom_herald/loom_herald_effects_spritesheet.png"' in projectile_scene
assert 'path="res://scripts/actors/ravager_projectile.gd"' in projectile_scene
for column in range(4):
    assert f"region = Rect2({column * 512}, 0, 512, 512)" in projectile_scene
    assert f"region = Rect2({column * 512}, 512, 512, 512)" in projectile_scene
assert "speed = 13.5" in projectile_scene
assert "radius = 0.18" in projectile_scene

# Level 3 spawns Loom before VexBaseLevel performs its enemy count, and derives
# placement from the scene-authored U01 marker instead of a hard-coded XYZ.
assert 'preload("res://scenes/actors/loom_herald.tscn")' in level_script
assert 'LOOM_HERALD_ENEMY_ID := &"vex03_upper_loom_herald"' in level_script
assert '"Geometry/UpperLevel/Room_U01_StairLanding"' in level_script
assert 'get_node_or_null("Enemies")' in level_script
assert "loom_herald.set(\"enemy_id\", LOOM_HERALD_ENEMY_ID)" in level_script
ready_block = re.search(r"func _ready\(\) -> void:\n(.*?)(?=\n\nfunc )", level_script, re.S)
assert ready_block, "Level 3 _ready missing"
assert ready_block.group(1).find("_spawn_loom_herald()") < ready_block.group(1).find("super._ready()"), (
    "Loom Herald must spawn before base level enemy counting"
)

print("loom herald audit passed")
