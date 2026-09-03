#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ACTORS = ROOT / "scripts" / "actors"
SCENES = ROOT / "scenes" / "actors"

FAMILIES = {
    "enemy_combatant_performance_base.gd": [
        "ravager",
        "basalt_juggernaut",
        "veilmaw",
        "voidweaver",
        "cinder_spitter",
        "coil_lancer",
        "spore_matriarch",
    ],
    # Özel büyük saldırı state machine'leri core combatant'ta kalır; global
    # EnemyPerformance manager mesafe/crowd LOD'unu bunlara da uygular.
    "enemy_combatant_base.gd": [
        "furnice_carrier",
        "crucible_warden",
    ],
    "enemy_lunge_performance_base.gd": [
        "redviper",
        "badredviper",
        "cinderhound",
        "vaskari_bulwark",
    ],
    # Gorehorn özel charge physics override'ını korur; global manager charge'ı
    # lunge ailesi olarak normalize eder.
    "enemy_lunge_base.gd": [
        "gorehorn",
    ],
    "enemy_hybrid_base.gd": [
        "briar_skulker",
    ],
}

CHARACTER_CONTRACTS = {
    "ravager": {"combat_role": "2", "attack_range": "20.0", "attack_preferred_distance": "8.0"},
    "basalt_juggernaut": {"combat_role": "1", "maximum_health": "240", "attack_range": "15.0"},
    "veilmaw": {"combat_role": "1", "move_speed": "2.55", "attack_preferred_distance": "7.5"},
    "voidweaver": {"combat_role": "1", "maximum_health": "120", "attack_preferred_distance": "8.5"},
    "furnice_carrier": {"combat_role": "2", "maximum_health": "130", "attack_range": "22.0"},
    "crucible_warden": {"combat_role": "0", "maximum_health": "260", "attack_preferred_distance": "1.4"},
    "cinder_spitter": {"combat_role": "1", "maximum_health": "95", "attack_range": "14.0"},
    "coil_lancer": {"combat_role": "2", "maximum_health": "105", "attack_range": "22.0"},
    "spore_matriarch": {"combat_role": "1", "maximum_health": "165", "attack_range": "18.0"},
    "redviper": {"combat_role": "0", "maximum_health": "140", "chase_speed": "6.4"},
    "badredviper": {"combat_role": "0", "maximum_health": "190", "attack_damage": "28"},
    "cinderhound": {"combat_role": "0", "chase_speed": "7.2", "attack_windup": "0.18"},
    "gorehorn": {"combat_role": "0", "maximum_health": "180", "attack_range": "12.0"},
    "vaskari_bulwark": {"combat_role": "0", "maximum_health": "300", "attack_damage": "30"},
    "briar_skulker": {"combat_role": "1", "maximum_health": "110", "attack_range": "14.0"},
}


def read(path: Path) -> str:
    assert path.exists(), path
    return path.read_text(encoding="utf-8")


enemy_base = read(ACTORS / "enemy_base.gd")
combatant_base = read(ACTORS / "enemy_combatant_base.gd")
combatant_performance = read(ACTORS / "enemy_combatant_performance_base.gd")
lunge_base = read(ACTORS / "enemy_lunge_base.gd")
lunge_performance = read(ACTORS / "enemy_lunge_performance_base.gd")
hybrid_base = read(ACTORS / "enemy_hybrid_base.gd")

assert "class_name VexEnemyBase" in enemy_base
assert "extends CharacterBody3D" in enemy_base
assert 'extends "res://scripts/actors/enemy_base.gd"' in combatant_base
assert 'extends "res://scripts/actors/enemy_base.gd"' in lunge_base
assert 'extends "res://scripts/actors/enemy_combatant_base.gd"' in combatant_performance
assert 'extends "res://scripts/actors/enemy_lunge_base.gd"' in lunge_performance
assert 'extends "res://scripts/actors/enemy_combatant_performance_base.gd"' in hybrid_base
assert not enemy_base.startswith("@tool\n"), "runtime enemy tabanı editörde çalışmamalı"
assert not combatant_base.startswith("@tool\n"), "runtime combatant AI editörde çalışmamalı"
assert not combatant_performance.startswith("@tool\n"), "performance combatant editörde çalışmamalı"
assert not lunge_base.startswith("@tool\n"), "runtime lunge AI editörde çalışmamalı"
assert not lunge_performance.startswith("@tool\n"), "performance lunge editörde çalışmamalı"
assert not hybrid_base.startswith("@tool\n"), "runtime hybrid AI editörde çalışmamalı"
assert 'return &"combatant"' in combatant_base
assert 'return &"lunge"' in lunge_base
assert 'return &"hybrid"' in hybrid_base
assert "@export" not in combatant_performance, "performance wrapper Inspector şemasını değiştirmemeli"
assert "@export" not in lunge_performance, "performance wrapper Inspector şemasını değiştirmemeli"
assert "@export" not in hybrid_base, "hybrid aile Inspector sırasını bozmamalı"

for subclass_setting in [
    "enemy_id",
    "combat_role",
    "maximum_health",
    "spawn_min_difficulty",
    "apply_difficulty_scaling",
]:
    assert not re.search(rf"@export[^\n]*\bvar {subclass_setting}\b", enemy_base), subclass_setting
    assert re.search(rf"@export[^\n]*\bvar {subclass_setting}\b", combatant_base), subclass_setting
    assert re.search(rf"@export[^\n]*\bvar {subclass_setting}\b", lunge_base), subclass_setting

for shared_difficulty_setting in [
    "difficulty_health_multipliers",
    "difficulty_damage_multipliers",
    "difficulty_speed_multipliers",
    "difficulty_detection_multipliers",
    "difficulty_cooldown_multipliers",
    "difficulty_windup_multipliers",
]:
    assert re.search(
        rf"@export[^\n]*\bvar {shared_difficulty_setting}\b",
        enemy_base,
    ), shared_difficulty_setting
    assert not re.search(
        rf"@export[^\n]*\bvar {shared_difficulty_setting}\b",
        combatant_base,
    ), shared_difficulty_setting
    assert not re.search(
        rf"@export[^\n]*\bvar {shared_difficulty_setting}\b",
        lunge_base,
    ), shared_difficulty_setting

assert enemy_base.count('@export_category("01B - Zorluk Çarpanları (Sahne)")') == 1

shared_runtime_state = [
    "health",
    "_spawn_position",
    "_facing_direction",
    "_attack_locked",
    "_gravity",
    "_player",
    "_sight_check_remaining",
    "_last_seen_position",
    "_search_remaining",
    "_search_probe_index",
    "_search_probe_target",
    "_has_search_probe",
    "_damage_reaction_remaining",
    "_forced_damage_target",
    "_has_forced_damage_target",
    "_forced_damage_best_distance",
    "_forced_damage_stall_remaining",
    "_forced_damage_commit_remaining",
    "_runtime_maximum_health",
    "_runtime_attack_damage",
    "_runtime_move_speed",
    "_runtime_chase_speed",
    "_runtime_detection_range",
    "_runtime_pursuit_range",
    "_runtime_attack_cooldown",
    "_runtime_attack_windup",
    "_dormant_active",
    "_burn_remains",
    "_visual_base_y",
]
for state_name in shared_runtime_state:
    pattern = rf"^var {re.escape(state_name)}(?:\b|:)"
    assert re.search(pattern, enemy_base, re.M), state_name
    assert not re.search(pattern, combatant_base, re.M), ("combatant duplicate", state_name)
    assert not re.search(pattern, lunge_base, re.M), ("lunge duplicate", state_name)

creature_script_paths = {
    enemy: f"res://scripts/actors/{enemy}.gd"
    for enemies in FAMILIES.values()
    for enemy in enemies
}
creature_filenames = set(creature_script_paths.values())

for family_script, enemies in FAMILIES.items():
    expected_extends = f'extends "res://scripts/actors/{family_script}"'
    for enemy in enemies:
        script_path = ACTORS / f"{enemy}.gd"
        script = read(script_path)
        assert not script.startswith("@tool\n"), (
            enemy,
            "runtime yaratık scripti GameState'e editörde erişmemeli",
        )
        assert expected_extends in script, (enemy, family_script)

        extends_match = re.search(r'^extends "([^"]+)"$', script, re.M)
        assert extends_match is not None, enemy
        assert extends_match.group(1) not in creature_filenames, (
            enemy,
            "creature-to-creature inheritance",
            extends_match.group(1),
        )

        scene = read(SCENES / f"{enemy}.tscn")
        own_script = creature_script_paths[enemy]
        assert re.search(
            rf'\[ext_resource type="Script"[^\n]*path="{re.escape(own_script)}"[^\n]*\]',
            scene,
        ), (enemy, own_script)

        root = re.search(
            r'^\[node name="[^"]+" type="CharacterBody3D"[^\n]*\]\n(.*?)(?=^\[node |\Z)',
            scene,
            re.M | re.S,
        )
        assert root is not None, enemy
        root_text = root.group(1)
        assert re.search(rf'^enemy_id = &"{enemy}"$', root_text, re.M), (enemy, "enemy_id")
        for key, expected in CHARACTER_CONTRACTS[enemy].items():
            assert re.search(
                rf"^{re.escape(key)} = {re.escape(expected)}$",
                root_text,
                re.M,
            ), (enemy, key, expected)

for base_name, base_source in [
    ("enemy_base", enemy_base),
    ("enemy_combatant_base", combatant_base),
    ("enemy_combatant_performance_base", combatant_performance),
    ("enemy_lunge_base", lunge_base),
    ("enemy_lunge_performance_base", lunge_performance),
    ("enemy_hybrid_base", hybrid_base),
]:
    assert not re.search(r'class_name Vex(?:Ravager|RedViper)\b', base_source), base_name

print("enemy script architecture audit passed")