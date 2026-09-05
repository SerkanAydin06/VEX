#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

ACTIVE_ENEMY_SCENES = [
    "basalt_juggernaut.tscn",
    "furnice_carrier.tscn",
    "crucible_warden.tscn",
    "cinder_spitter.tscn",
    "cinderhound.tscn",
    "ravager.tscn",
    "spore_matriarch.tscn",
    "briar_skulker.tscn",
    "gorehorn.tscn",
    "vaskari_raptor.tscn",
    "vaskari_ravager.tscn",
    "vaskari_bulwark.tscn",
    "coil_lancer.tscn",
    "venom_marshall.tscn",
    "veilmaw.tscn",
    "husk_leech.tscn",
    "voidweaver.tscn",
    "rift_reaver.tscn",
]

MULTIPLIERS = {
    "difficulty_health_multipliers": "up",
    "difficulty_damage_multipliers": "up",
    "difficulty_speed_multipliers": "up",
    "difficulty_detection_multipliers": "up",
    "difficulty_cooldown_multipliers": "down",
    "difficulty_windup_multipliers": "down",
}

SANITY_RANGES = {
    "difficulty_health_multipliers": (0.50, 2.00),
    "difficulty_damage_multipliers": (0.50, 2.00),
    "difficulty_speed_multipliers": (0.70, 1.40),
    "difficulty_detection_multipliers": (0.70, 1.50),
    "difficulty_cooldown_multipliers": (0.50, 1.60),
    "difficulty_windup_multipliers": (0.50, 1.60),
}


def read(relative: str) -> str:
    path = ROOT / relative
    assert path.exists(), relative
    return path.read_text(encoding="utf-8")


def packed_array(source: str, property_name: str) -> list[float]:
    match = re.search(
        rf"^{re.escape(property_name)}\s*=\s*PackedFloat32Array\(([^)]*)\)$",
        source,
        re.M,
    )
    assert match is not None, property_name
    values = [float(value.strip()) for value in match.group(1).split(",")]
    assert len(values) == 4, (property_name, values)
    return values


def assert_profile(values: list[float], direction: str, name: str) -> None:
    assert abs(values[1] - 1.0) <= 1e-6, (name, "Normal must be 1.0", values)
    assert all(value > 0.0 for value in values), (name, "non-positive", values)
    if direction == "up":
        assert values == sorted(values), (name, "must rise with difficulty", values)
    else:
        assert values == sorted(values, reverse=True), (
            name,
            "must fall with difficulty",
            values,
        )
    minimum, maximum = SANITY_RANGES[name]
    assert all(minimum <= value <= maximum for value in values), (
        name,
        "outside sanity band",
        values,
    )


def enemy_blocks(level_source: str) -> list[str]:
    return re.findall(
        r'^\[node name="[^"]+"[^\n]*parent="Enemies"[^\n]*\]\n(.*?)(?=^\[node |\Z)',
        level_source,
        re.M | re.S,
    )


# Four difficulty indices are a stable save/runtime contract.
settings = read("scripts/autoload/settings_manager.gd")
for token in [
    "EASY,",
    "NORMAL,",
    "HARD,",
    "NIGHTMARE,",
    '@export_enum("Easy", "Normal", "Hard", "Nightmare")',
]:
    assert token in settings, token

# Campaign difficulty must survive New Game, save, and Continue.
game_state = read("scripts/autoload/game_state.gd")
for token in [
    "active_difficulty = SettingsManager.difficulty",
    '"difficulty": active_difficulty',
    'int(saved_run_state.get("difficulty", SettingsManager.difficulty))',
    "SettingsManager.Difficulty.EASY",
    "SettingsManager.Difficulty.NIGHTMARE",
]:
    assert token in game_state, token

# apply_difficulty_scaling=false must disable *all* multipliers, including
# special-ability scripts that call this shared helper directly.
enemy_base = read("scripts/actors/enemy_base.gd")
helper_match = re.search(
    r"func _scene_difficulty_multiplier\(values: PackedFloat32Array\) -> float:\n(.*?)(?=\n\nfunc )",
    enemy_base,
    re.S,
)
assert helper_match is not None
helper = helper_match.group(1)
assert "if not apply_difficulty_scaling:" in helper
assert "return 1.0" in helper
assert "VexEnemyRuntimeUtils.difficulty_multiplier" in helper

for property_name, direction in MULTIPLIERS.items():
    defaults = packed_array(enemy_base, property_name)
    assert_profile(defaults, direction, f"enemy_base:{property_name}")

# All active enemy scenes keep their difficulty profile in Inspector/scene data.
for scene_name in ACTIVE_ENEMY_SCENES:
    scene = read(f"scenes/actors/{scene_name}")
    assert "apply_difficulty_scaling = false" not in scene, scene_name
    for property_name, direction in MULTIPLIERS.items():
        values = packed_array(scene, property_name)
        assert_profile(values, direction, f"{scene_name}:{property_name}")

# Custom attacks use the same difficulty helper instead of raw difficulty math.
warden = read("scripts/actors/crucible_warden.gd")
furnace = read("scripts/actors/furnice_carrier.gd")
venom = read("scripts/actors/venom_marshall.gd")
for script_name, source in [
    ("crucible_warden.gd", warden),
    ("furnice_carrier.gd", furnace),
    ("venom_marshall.gd", venom),
]:
    assert "_scene_difficulty_multiplier(difficulty_windup_multipliers)" in source, script_name
    assert "_scene_difficulty_multiplier(difficulty_cooldown_multipliers)" in source, script_name
for script_name, source in [
    ("crucible_warden.gd", warden),
    ("furnice_carrier.gd", furnace),
]:
    assert "func _scaled_special_damage(" in source, script_name
    assert "if not apply_difficulty_scaling:" in source, script_name
    assert "_scene_difficulty_multiplier(difficulty_damage_multipliers)" in source, script_name

# Resource pickups get scarcer on higher difficulty, but Normal remains authored 1:1.
pickup = read("scripts/props/pickup.gd")
resource_values = packed_array(pickup, "difficulty_amount_multipliers")
assert abs(resource_values[1] - 1.0) <= 1e-6, resource_values
assert resource_values == sorted(resource_values, reverse=True), resource_values
assert all(0.40 <= value <= 1.60 for value in resource_values), resource_values
assert "if not scale_amount_with_difficulty:" in pickup

# Level-authored spawn tiers may only use 0..3 and must produce a monotonic roster.
for level_name in ["level_01.tscn", "level_02.tscn", "level_03.tscn"]:
    source = read(f"scenes/levels/{level_name}")
    blocks = enemy_blocks(source)
    assert blocks, level_name
    minimums: list[int] = []
    for block in blocks:
        match = re.search(r"^spawn_min_difficulty\s*=\s*(\d+)\s*$", block, re.M)
        value = int(match.group(1)) if match else 0
        assert 0 <= value <= 3, (level_name, value)
        minimums.append(value)
    counts = [sum(1 for value in minimums if value <= difficulty) for difficulty in range(4)]
    assert counts == sorted(counts), (level_name, counts)
    assert counts[0] > 0, (level_name, "no Easy enemies")
    print(f"DIFFICULTY SPAWNS {level_name}: Easy/Normal/Hard/Nightmare = {counts}")

print("enemy difficulty scaling audit passed")
