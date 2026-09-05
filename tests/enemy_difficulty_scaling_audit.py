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
    # .tscn stores `property = PackedFloat32Array(...)`, while GDScript
    # defaults use `@export var property := PackedFloat32Array(...)`.
    match = re.search(
        rf"^(?:@export\s+var\s+)?{re.escape(property_name)}\s*(?::=|=)\s*PackedFloat32Array\(([^)]*)\)$",
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
    "func get_difficulty_profile(",
]:
    assert token in settings, token

# Campaign difficulty must survive New Game, save, and Continue, and the public
# GameState profile accessor must resolve the selected campaign difficulty.
game_state = read("scripts/autoload/game_state.gd")
for token in [
    "active_difficulty = SettingsManager.difficulty",
    '"difficulty": active_difficulty',
    'int(saved_run_state.get("difficulty", SettingsManager.difficulty))',
    "SettingsManager.Difficulty.EASY",
    "SettingsManager.Difficulty.NIGHTMARE",
    "SettingsManager.get_difficulty_profile(active_difficulty)",
]:
    assert token in game_state, token

# apply_difficulty_scaling=false must disable *all* difficulty multipliers,
# including special-ability scripts that call this shared helper directly.
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

# Ally damage support is independent from the difficulty toggle. Special attack
# helpers scale by difficulty first (when enabled), then use this shared support
# helper so Venom Marshall affects every attack channel consistently.
support_match = re.search(
    r"func _apply_active_damage_support\(damage_value: int\) -> int:\n(.*?)(?=\n\nfunc )",
    enemy_base,
    re.S,
)
assert support_match is not None
support_helper = support_match.group(1)
assert 'get_node_or_null("VenomMarshallBuffStatus")' in support_helper
assert 'has_method("get_damage_multiplier")' in support_helper
assert 'call("get_damage_multiplier")' in support_helper

# SettingsManager exposes the canonical baseline profile to UI/game-state APIs,
# while actor scenes may deliberately override it. Base enemy defaults must stay
# identical to that global baseline so a new enemy does not silently start on a
# different curve.
for property_name, direction in MULTIPLIERS.items():
    settings_values = packed_array(settings, property_name)
    defaults = packed_array(enemy_base, property_name)
    assert_profile(settings_values, direction, f"settings:{property_name}")
    assert_profile(defaults, direction, f"enemy_base:{property_name}")
    assert defaults == settings_values, (
        property_name,
        "enemy base/global profile drift",
        defaults,
        settings_values,
    )

# All active enemy scenes keep their difficulty profile in Inspector/scene data.
# Per-creature overrides are allowed, but each authored curve must stay ordered
# and within broad safety bands. Enemy group membership must remain runtime-only:
# difficulty-filtered scene instances must never be counted by BaseLevel/HUD.
for scene_name in ACTIVE_ENEMY_SCENES:
    scene = read(f"scenes/actors/{scene_name}")
    assert "apply_difficulty_scaling = false" not in scene, scene_name
    assert re.search(
        r'^\[node name="[^"]+" type="CharacterBody3D"[^\n]*\]$',
        scene,
        re.M,
    ), scene_name
    assert not re.search(
        r'^\[node name="[^"]+" type="CharacterBody3D"[^\n]*groups=\[[^\]]*"enemy"',
        scene,
        re.M,
    ), (scene_name, "enemy group must be assigned after difficulty gate")
    for property_name, direction in MULTIPLIERS.items():
        values = packed_array(scene, property_name)
        assert_profile(values, direction, f"{scene_name}:{property_name}")

# Both behavior families must difficulty-filter before joining the enemy group.
# BaseLevel can then count only the active roster when its parent _ready runs.
combatant = read("scripts/actors/enemy_combatant_base.gd")
lunge = read("scripts/actors/enemy_lunge_base.gd")
for script_name, source in [
    ("enemy_combatant_base.gd", combatant),
    ("enemy_lunge_base.gd", lunge),
]:
    gate_index = source.index("if GameState.active_difficulty < spawn_min_difficulty:")
    group_index = source.index('add_to_group("enemy")')
    assert gate_index < group_index, (script_name, "enemy group added before difficulty gate")
    between = source[gate_index:group_index]
    assert "queue_free()" in between and "return" in between, script_name

base_level = read("scripts/levels/base_level.gd")
assert 'GameState.begin_level(get_tree().get_nodes_in_group("enemy").size()' in base_level

# Custom attacks use the same difficulty helper instead of raw difficulty math.
warden = read("scripts/actors/crucible_warden.gd")
furnace = read("scripts/actors/furnice_carrier.gd")
venom = read("scripts/actors/venom_marshall.gd")
hybrid = read("scripts/actors/enemy_hybrid_base.gd")
gorehorn = read("scripts/actors/gorehorn.gd")
for script_name, source in [
    ("crucible_warden.gd", warden),
    ("furnice_carrier.gd", furnace),
    ("venom_marshall.gd", venom),
    ("enemy_hybrid_base.gd", hybrid),
]:
    assert "_scene_difficulty_multiplier(difficulty_windup_multipliers)" in source, script_name
    assert "_scene_difficulty_multiplier(difficulty_cooldown_multipliers)" in source, script_name
for script_name, source, function_name in [
    ("crucible_warden.gd", warden, "_scaled_special_damage"),
    ("furnice_carrier.gd", furnace, "_scaled_special_damage"),
    ("enemy_hybrid_base.gd", hybrid, "_scaled_hybrid_damage"),
]:
    assert f"func {function_name}(" in source, script_name
    assert "if apply_difficulty_scaling:" in source, script_name
    assert "_scene_difficulty_multiplier(difficulty_damage_multipliers)" in source, script_name
    assert "return _apply_active_damage_support(scaled_damage)" in source, script_name

# Gorehorn's custom charge must remain on the lunge family's already-scaled
# runtime damage/windup/cooldown/speed values rather than bypassing difficulty.
for token in [
    "create_timer(_runtime_attack_windup)",
    'take_damage", _runtime_attack_damage',
    "_runtime_attack_cooldown",
    "_runtime_attack_lunge_speed",
]:
    assert token in gorehorn, token
assert "attack_lunge_speed * speed_scale" in lunge
assert "_runtime_attack_lunge_speed =" in lunge

# Resource pickups get scarcer on higher difficulty. Their authored baseline is
# mirrored by SettingsManager's public difficulty profile and must not drift.
pickup = read("scripts/props/pickup.gd")
resource_values = packed_array(pickup, "difficulty_amount_multipliers")
settings_resource_values = packed_array(settings, "difficulty_resource_multipliers")
assert abs(resource_values[1] - 1.0) <= 1e-6, resource_values
assert resource_values == sorted(resource_values, reverse=True), resource_values
assert all(0.40 <= value <= 1.60 for value in resource_values), resource_values
assert resource_values == settings_resource_values, (
    "pickup/global resource profile drift",
    resource_values,
    settings_resource_values,
)
assert "if not scale_amount_with_difficulty:" in pickup

# Level-authored spawn tiers may only use 0..3 and must produce a monotonic roster.
# Every placed enemy needs a unique explicit ID for defeat tracking. Any enemy
# required by a finish switch must exist and be available even on Easy, otherwise
# the campaign can become impossible to complete on lower difficulties.
for level_name in ["level_01.tscn", "level_02.tscn", "level_03.tscn"]:
    source = read(f"scenes/levels/{level_name}")
    blocks = enemy_blocks(source)
    assert blocks, level_name
    minimums: list[int] = []
    enemy_minimum_by_id: dict[str, int] = {}
    for block in blocks:
        id_match = re.search(r'^enemy_id\s*=\s*&"([^"]+)"\s*$', block, re.M)
        assert id_match is not None, (level_name, "enemy without explicit enemy_id")
        enemy_id = id_match.group(1)
        assert enemy_id not in enemy_minimum_by_id, (level_name, "duplicate enemy_id", enemy_id)

        match = re.search(r"^spawn_min_difficulty\s*=\s*(\d+)\s*$", block, re.M)
        value = int(match.group(1)) if match else 0
        assert 0 <= value <= 3, (level_name, value)
        minimums.append(value)
        enemy_minimum_by_id[enemy_id] = value

    required_enemy_ids = re.findall(
        r'^required_enemy_id\s*=\s*&"([^"]+)"\s*$',
        source,
        re.M,
    )
    for required_enemy_id in required_enemy_ids:
        if not required_enemy_id:
            continue
        assert required_enemy_id in enemy_minimum_by_id, (
            level_name,
            "finish switch references missing enemy",
            required_enemy_id,
        )
        assert enemy_minimum_by_id[required_enemy_id] == 0, (
            level_name,
            "finish-required enemy is difficulty gated",
            required_enemy_id,
            enemy_minimum_by_id[required_enemy_id],
        )

    counts = [sum(1 for value in minimums if value <= difficulty) for difficulty in range(4)]
    assert counts == sorted(counts), (level_name, counts)
    assert counts[0] > 0, (level_name, "no Easy enemies")
    print(f"DIFFICULTY SPAWNS {level_name}: Easy/Normal/Hard/Nightmare = {counts}")

print("enemy difficulty scaling audit passed")
