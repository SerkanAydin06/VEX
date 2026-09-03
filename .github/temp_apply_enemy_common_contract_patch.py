from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "scripts/actors/enemy_base.gd"
COMBATANT = ROOT / "scripts/actors/enemy_combatant_base.gd"
LUNGE = ROOT / "scripts/actors/enemy_lunge_base.gd"
AUDIT = ROOT / "tests/enemy_common_contract_architecture_audit.py"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


base = BASE.read_text(encoding="utf-8")
combatant = COMBATANT.read_text(encoding="utf-8")
lunge = LUNGE.read_text(encoding="utf-8")

base_anchor = '''const EnemyPerceptionRuntime = preload("res://scripts/actors/enemy_perception_runtime.gd")

@export_category("01B - Zorluk Çarpanları (Sahne)")
'''
base_identity = '''const EnemyPerceptionRuntime = preload("res://scripts/actors/enemy_perception_runtime.gd")

@export_category("01A - Ortak Kimlik ve Zorluk")
## Kayıt ve yenilgi takibinde kullanılan benzersiz yaratık kimliğidir.
@export var enemy_id: StringName = &"enemy"
## Yaratığın doğabileceği en düşük zorluk seviyesidir; 0 tüm seviyelerdir.
@export_range(0, 3, 1) var spawn_min_difficulty := 0
## Açıksa sahnedeki zorluk çarpanları cana, hasara, hıza, algılamaya ve saldırı sürelerine uygulanır.
@export var apply_difficulty_scaling := true

@export_category("01B - Zorluk Çarpanları (Sahne)")
'''
base = replace_once(base, base_anchor, base_identity, "base identity insertion")

base_node_anchor = '''# arama yoklama çapraz ağırlık ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
var search_probe_diagonal_weight := 0.85

# Combatant ve Lunge ailelerinin birebir ortak runtime state'i burada tek kez tanımlanır.
'''
base_node_block = '''# arama yoklama çapraz ağırlık ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
var search_probe_diagonal_weight := 0.85

# Combatant ve Lunge sahne köklerinin ortak zorunlu node sözleşmesi.
# Node adları iki davranış ailesinde de aynıdır; tek kaynaktan çözülür.
@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var attack_audio: AudioStreamPlayer3D = $AttackAudio
@onready var hurt_audio: AudioStreamPlayer3D = $HurtAudio
@onready var death_audio: AudioStreamPlayer3D = $DeathAudio
@onready var ground_shadow: Sprite3D = get_node_or_null("GroundShadow") as Sprite3D

# Combatant ve Lunge ailelerinin birebir ortak runtime state'i burada tek kez tanımlanır.
'''
base = replace_once(base, base_node_anchor, base_node_block, "base node contract insertion")

combat_identity = '''## Kayıt ve yenilgi takibinde kullanılan benzersiz yaratık kimliğidir.
@export var enemy_id: StringName = &"enemy"
'''
combat_spawn_scaling = '''## Yaratığın doğabileceği en düşük zorluk seviyesidir; 0 tüm seviyelerdir.
@export_range(0, 3, 1) var spawn_min_difficulty := 0
## Açıksa sahnedeki zorluk çarpanları cana, hasara, hıza, algılamaya ve saldırı sürelerine uygulanır.
@export var apply_difficulty_scaling := true
'''
combat_nodes = '''@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var attack_audio: AudioStreamPlayer3D = $AttackAudio
@onready var hurt_audio: AudioStreamPlayer3D = $HurtAudio
@onready var death_audio: AudioStreamPlayer3D = $DeathAudio
@onready var ground_shadow: Sprite3D = get_node_or_null("GroundShadow") as Sprite3D

'''
combatant = replace_once(combatant, combat_identity, "", "combatant enemy_id removal")
combatant = replace_once(combatant, combat_spawn_scaling, "", "combatant spawn/scaling removal")
combatant = replace_once(combatant, combat_nodes, "", "combatant node contract removal")

lunge_identity = combat_identity
lunge_spawn_scaling = combat_spawn_scaling
lunge_nodes = '''@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var hurt_audio: AudioStreamPlayer3D = $HurtAudio
@onready var death_audio: AudioStreamPlayer3D = $DeathAudio
@onready var attack_audio: AudioStreamPlayer3D = $AttackAudio
@onready var ground_shadow: Sprite3D = get_node_or_null("GroundShadow") as Sprite3D

'''
lunge = replace_once(lunge, lunge_identity, "", "lunge enemy_id removal")
lunge = replace_once(lunge, lunge_spawn_scaling, "", "lunge spawn/scaling removal")
lunge = replace_once(lunge, lunge_nodes, "", "lunge node contract removal")

BASE.write_text(base, encoding="utf-8")
COMBATANT.write_text(combatant, encoding="utf-8")
LUNGE.write_text(lunge, encoding="utf-8")

AUDIT.write_text('''from pathlib import Path

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
''', encoding="utf-8")

print("enemy common contract patch applied")
