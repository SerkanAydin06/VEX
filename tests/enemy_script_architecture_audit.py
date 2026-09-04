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
        "husk_leech",
        "venom_marshall",
    ],
    # Özel büyük saldırı state machine'leri core combatant'ta kalır; global
    # EnemyPerformance manager mesafe/crowd LOD'unu bunlara da uygular.
    "enemy_combatant_base.gd": [
        "furnice_carrier",
        "crucible_warden",
    ],
    "enemy_lunge_performance_base.gd": [
        "vaskari_raptor",
        "vaskari_ravager",
        "cinderhound",
        "vaskari_bulwark",
        "rift_reaver",
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

SCENE_FILE_OVERRIDES = {
    "vaskari_raptor": "vaskari_raptor.tscn",
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
    "husk_leech": {"combat_role": "1", "maximum_health": "90", "attack_range": "16.0"},
    "venom_marshall": {"combat_role": "1", "maximum_health": "155", "attack_range": "20.0"},
    "vaskari_raptor": {"combat_role": "0", "maximum_health": "140", "chase_speed": "6.4"},
    "vaskari_ravager": {"combat_role": "0", "maximum_health": "190", "attack_damage": "28"},
    "cinderhound": {"combat_role": "0", "chase_speed": "7.2", "attack_windup": "0.18"},
    "gorehorn": {"combat_role": "0", "maximum_health": "180", "attack_range": "12.0"},
    "vaskari_bulwark": {"combat_role": "0", "maximum_health": "300", "attack_damage": "30"},
    "rift_reaver": {"combat_role": "0", "maximum_health": "135", "attack_damage": "22"},
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

for shared_contract_setting in [
    "enemy_id",
    "spawn_min_difficulty",
    "apply_difficulty_scaling",
]:
    assert re.search(rf"@export[^\n]*\bvar {shared_contract_setting}\b", enemy_base), shared_contract_setting
    assert not re.search(rf"@export[^\n]*\bvar {shared_contract_setting}\b", combatant_base), shared_contract_setting
    assert not re.search(rf"@export[^\n]*\bvar {shared_contract_setting}\b", lunge_base), shared_contract_setting

for family_setting in [
    "combat_role",
    "maximum_health",
]:
    assert not re.search(rf"@export[^\n]*\bvar {family_setting}\b", enemy_base), family_setting
    assert re.search(rf"@export[^\n]*\bvar {family_setting}\b", combatant_base), family_setting
    assert re.search(rf"@export[^\n]*\bvar {family_setting}\b", lunge_base), family_setting

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

assert enemy_base.count('@export_category("01 - Kimlik ve Zorluk")') == 1
assert "01A -" not in enemy_base
assert "01B -" not in enemy_base

# Frame callback ailede kalır: base sınıfın aileye özgü _apply_frame_ground_offset
# hook'unu doğrudan çağırması Godot runtime class-resolution'ını bozar.
assert not re.search(r"(?m)^func _on_visual_frame_changed\b", enemy_base)
assert re.search(r"(?m)^func _on_visual_frame_changed\b", combatant_base)
assert re.search(r"(?m)^func _on_visual_frame_changed\b", lunge_base)

for shared_animation_helper in ["_has_animation", "_get_animation_duration"]:
    needle = f"func {shared_animation_helper}("
    assert needle in enemy_base, shared_animation_helper
    assert needle not in combatant_base, ("combatant duplicate", shared_animation_helper)
    assert needle not in lunge_base, ("lunge duplicate", shared_animation_helper)

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

shared_internal_tuning = [
    "floor_collision_mask", "floor_snap_max_correction",
    "floor_snap_ray_start_height", "floor_snap_ray_extra_depth",
    "acoustic_collision_mask", "acoustic_probe_height",
    "visibility_vertical_span_scale", "visibility_vertical_span_min",
    "visibility_vertical_span_max", "visibility_lateral_span_scale",
    "visibility_lateral_span_min", "visibility_lateral_span_max",
    "visibility_shoulder_height_ratio", "visibility_lower_body_ratio",
    "search_probe_diagonal_weight",
    "damage_pursuit_min_progress", "damage_pursuit_stall_timeout",
]
for tuning_name in shared_internal_tuning:
    pattern = rf"^var {re.escape(tuning_name)}(?:\b|:)"
    assert re.search(pattern, enemy_base, re.M), tuning_name
    assert not re.search(pattern, combatant_base, re.M), ("combatant duplicate", tuning_name)
    assert not re.search(pattern, lunge_base, re.M), ("lunge duplicate", tuning_name)
    assert not re.search(rf"@export[^\n]*\bvar {re.escape(tuning_name)}\b", enemy_base), tuning_name

family_internal_tuning = [
    "wall_normal_y_threshold", "local_detour_progress_weight",
    "local_detour_distance_penalty", "local_detour_direct_path_bonus",
    "local_detour_persistence_bonus", "cover_diagonal_distance_scale",
    "cover_forward_distance_scale", "cover_visibility_score_weight",
    "cover_distance_score_penalty", "cover_threshold_score_bonus",
    "cover_failed_retry_interval",
]
for tuning_name in family_internal_tuning:
    assert not re.search(rf"@export[^\n]*\bvar {re.escape(tuning_name)}\b", combatant_base + "\n" + lunge_base), tuning_name

# Damage pursuit commit time remains family-authored because Gorehorn serializes
# a deliberate scene override. Do not accidentally internalize this property.
for source in (combatant_base, lunge_base):
    assert re.search(r"@export[^\n]*\bvar damage_pursuit_commit_time\b", source)

serialized_text = "\n".join(
    path.read_text(encoding="utf-8", errors="ignore")
    for serialized_root in [ROOT / "scenes", ROOT / "resources"]
    if serialized_root.exists()
    for path in serialized_root.rglob("*")
    if path.suffix in {".tscn", ".tres"}
)
for tuning_name in shared_internal_tuning + family_internal_tuning:
    assert not re.search(rf"(?m)^\s*{re.escape(tuning_name)}\s*=", serialized_text), tuning_name

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

        scene_filename = SCENE_FILE_OVERRIDES.get(enemy, f"{enemy}.tscn")
        scene = read(SCENES / scene_filename)
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
    assert not re.search(r'class_name Vex(?:Ravager|VaskariRaptor|VaskariRavager)\b', base_source), base_name

print("enemy script architecture audit passed")
