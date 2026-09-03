from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = (ROOT / "scripts/actors/enemy_base.gd").read_text(encoding="utf-8")
COMBATANT = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
LUNGE = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")

assert BASE.count("func _configure_common_runtime_stats(") == 1
for family_source, family_name in [(COMBATANT, "combatant"), (LUNGE, "lunge")]:
    assert family_source.count("_configure_common_runtime_stats(") == 1, family_name
    assert "var health_scale :=" not in family_source, family_name
    assert "var damage_scale :=" not in family_source, family_name
    assert "var detection_scale :=" not in family_source, family_name
    assert "var cooldown_scale :=" not in family_source, family_name
    assert "var windup_scale :=" not in family_source, family_name

for multiplier in (
    "difficulty_health_multipliers",
    "difficulty_damage_multipliers",
    "difficulty_speed_multipliers",
    "difficulty_detection_multipliers",
    "difficulty_cooldown_multipliers",
    "difficulty_windup_multipliers",
):
    assert f"_scene_difficulty_multiplier({multiplier})" in BASE, multiplier

for runtime_field in (
    "_runtime_maximum_health",
    "_runtime_attack_damage",
    "_runtime_move_speed",
    "_runtime_chase_speed",
    "_runtime_detection_range",
    "_runtime_pursuit_range",
    "_runtime_attack_cooldown",
    "_runtime_attack_windup",
):
    assert runtime_field in BASE, runtime_field

# Family-specific semantics remain explicit at the call sites.
assert "chase_speed if chase_speed > 0.0 else move_speed" in COMBATANT
assert "var speed_scale := _configure_common_runtime_stats(" in LUNGE
assert "_runtime_attack_lunge_speed = maxf(0.0, attack_lunge_speed * speed_scale)" in LUNGE
assert "attack_lunge_speed" not in BASE

print("enemy common runtime stats architecture audit: OK")
