from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "scripts/actors/enemy_base.gd"
COMBATANT = ROOT / "scripts/actors/enemy_combatant_base.gd"
LUNGE = ROOT / "scripts/actors/enemy_lunge_base.gd"
AUDIT = ROOT / "tests/enemy_common_runtime_stats_architecture_audit.py"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def replace_function(text: str, name: str, replacement: str, label: str) -> str:
    pattern = rf"func {re.escape(name)}\(\) -> void:\n.*?(?=\n\nfunc |\Z)"
    updated, count = re.subn(pattern, replacement.rstrip(), text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one function, found {count}")
    return updated


base = BASE.read_text(encoding="utf-8")
combatant = COMBATANT.read_text(encoding="utf-8")
lunge = LUNGE.read_text(encoding="utf-8")

anchor = '''func _scene_difficulty_multiplier(values: PackedFloat32Array) -> float:
\treturn VexEnemyRuntimeUtils.difficulty_multiplier(values, GameState.active_difficulty)


func _horizontal_distance(first: Vector3, second: Vector3) -> float:
'''
replacement = '''func _scene_difficulty_multiplier(values: PackedFloat32Array) -> float:
\treturn VexEnemyRuntimeUtils.difficulty_multiplier(values, GameState.active_difficulty)


func _configure_common_runtime_stats(
\tmaximum_health_value: int,
\tattack_damage_value: int,
\tmove_speed_value: float,
\tchase_speed_value: float,
\tdetection_range_value: float,
\tpursuit_range_value: float,
\tattack_cooldown_value: float,
\tattack_windup_value: float
) -> float:
\t_runtime_maximum_health = maximum_health_value
\t_runtime_attack_damage = attack_damage_value
\t_runtime_move_speed = move_speed_value
\t_runtime_chase_speed = chase_speed_value
\t_runtime_detection_range = detection_range_value
\t_runtime_pursuit_range = pursuit_range_value
\t_runtime_attack_cooldown = attack_cooldown_value
\t_runtime_attack_windup = attack_windup_value
\tif not apply_difficulty_scaling:
\t\treturn 1.0

\tvar health_scale := _scene_difficulty_multiplier(difficulty_health_multipliers)
\tvar damage_scale := _scene_difficulty_multiplier(difficulty_damage_multipliers)
\tvar speed_scale := _scene_difficulty_multiplier(difficulty_speed_multipliers)
\tvar detection_scale := _scene_difficulty_multiplier(difficulty_detection_multipliers)
\tvar cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)
\tvar windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)
\t_runtime_maximum_health = maxi(1, int(round(float(maximum_health_value) * health_scale)))
\t_runtime_attack_damage = maxi(1, int(round(float(attack_damage_value) * damage_scale)))
\t_runtime_move_speed = maxf(0.0, move_speed_value * speed_scale)
\t_runtime_chase_speed = maxf(0.0, chase_speed_value * speed_scale)
\t_runtime_detection_range = maxf(0.0, detection_range_value * detection_scale)
\t_runtime_pursuit_range = maxf(0.0, pursuit_range_value * detection_scale)
\t_runtime_attack_cooldown = maxf(0.01, attack_cooldown_value * cooldown_scale)
\t_runtime_attack_windup = maxf(0.0, attack_windup_value * windup_scale)
\treturn speed_scale


func _horizontal_distance(first: Vector3, second: Vector3) -> float:
'''
base = replace_once(base, anchor, replacement, "base runtime stats insertion")

combatant_replacement = '''func _configure_runtime_stats() -> void:
\t_configure_common_runtime_stats(
\t\tmaximum_health,
\t\tattack_damage,
\t\tmove_speed,
\t\tchase_speed if chase_speed > 0.0 else move_speed,
\t\tdetection_range,
\t\tpursuit_range,
\t\tattack_cooldown,
\t\tattack_windup
\t)'''
combatant = replace_function(
    combatant,
    "_configure_runtime_stats",
    combatant_replacement,
    "combatant runtime stats replacement",
)

lunge_replacement = '''func _configure_runtime_stats() -> void:
\tvar speed_scale := _configure_common_runtime_stats(
\t\tmaximum_health,
\t\tattack_damage,
\t\tmove_speed,
\t\tchase_speed,
\t\tdetection_range,
\t\tpursuit_range,
\t\tattack_cooldown,
\t\tattack_windup
\t)
\t_runtime_attack_lunge_speed = maxf(0.0, attack_lunge_speed * speed_scale)'''
lunge = replace_function(
    lunge,
    "_configure_runtime_stats",
    lunge_replacement,
    "lunge runtime stats replacement",
)

BASE.write_text(base, encoding="utf-8")
COMBATANT.write_text(combatant, encoding="utf-8")
LUNGE.write_text(lunge, encoding="utf-8")

AUDIT.write_text('''from pathlib import Path

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
''', encoding="utf-8")

print("enemy common runtime stats patch applied")
