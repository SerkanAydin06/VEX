from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = (ROOT / "scripts/actors/enemy_base.gd").read_text(encoding="utf-8")
COMBATANT = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
LUNGE = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")

COMMON_EXPORTS = (
    '@export var enemy_id: StringName = &"enemy"',
    '@export_range(0, 3, 1) var spawn_min_difficulty := 0',
    '@export var apply_difficulty_scaling := true',
)
COMMON_NODES = (
    '@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D',
    '@onready var collision_shape: CollisionShape3D = $CollisionShape3D',
    '@onready var attack_audio: AudioStreamPlayer3D = $AttackAudio',
    '@onready var hurt_audio: AudioStreamPlayer3D = $HurtAudio',
    '@onready var death_audio: AudioStreamPlayer3D = $DeathAudio',
    '@onready var ground_shadow: Sprite3D = get_node_or_null("GroundShadow") as Sprite3D',
)

for declaration in COMMON_EXPORTS + COMMON_NODES:
    assert BASE.count(declaration) == 1, f"common declaration must live once in enemy_base.gd: {declaration}"
    assert declaration not in COMBATANT, f"combatant duplicated parent contract: {declaration}"
    assert declaration not in LUNGE, f"lunge duplicated parent contract: {declaration}"

assert 'extends "res://scripts/actors/enemy_base.gd"' in COMBATANT
assert 'extends "res://scripts/actors/enemy_base.gd"' in LUNGE

# Family-owned defaults must remain family-owned; this package must not flatten tuning.
assert '@export_enum("Yakın", "Orta", "Uzak") var combat_role: int = EnemyCombatProfiles.Role.MID' in COMBATANT
assert '@export_range(1, 1000, 1) var maximum_health := 75' in COMBATANT
assert '@export_enum("Yakın", "Orta", "Uzak") var combat_role: int = EnemyCombatProfiles.Role.CLOSE' in LUNGE
assert '@export_range(1, 1000, 1) var maximum_health := 90' in LUNGE
assert '@export_range(0.5, 10.0, 0.1) var move_speed := 2.7' in COMBATANT
assert '@export_range(0.5, 10.0, 0.1) var move_speed := 2.35' in LUNGE
assert '@export_range(30.0, 360.0, 5.0) var initial_view_angle := 240.0' in COMBATANT
assert '@export_range(30.0, 360.0, 5.0) var initial_view_angle := 360.0' in LUNGE

print("enemy common contract architecture audit: OK")
