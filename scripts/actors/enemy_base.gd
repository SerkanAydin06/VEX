@tool
class_name VexEnemyBase
extends CharacterBody3D

# Yaratık adı taşımayan en alt seviye sözleşme.
# Kimlik/zorluk verileri ile her davranış ailesinin kullandığı saf yardımcılar
# burada tutulur. Hareket state machine'i bu sınıfta bulunmaz.
const EnemyCombatProfiles = preload("res://scripts/actors/enemy_combat_profiles.gd")
const EnemyNavigationRuntime = preload("res://scripts/actors/enemy_navigation_runtime.gd")

@export_category("01 - Kimlik, Can ve Zorluk")
@export var enemy_id: StringName = &"enemy"
@export_enum("Yakın", "Orta", "Uzak") var combat_role: int = EnemyCombatProfiles.Role.MID
@export_range(1, 1000, 1) var maximum_health := 75
@export_range(0, 3, 1) var spawn_min_difficulty := 0
@export var apply_difficulty_scaling := true

@export_category("01B - Zorluk Çarpanları (Sahne)")
@export var difficulty_health_multipliers := PackedFloat32Array([0.75, 1.0, 1.20, 1.45])
@export var difficulty_damage_multipliers := PackedFloat32Array([0.65, 1.0, 1.25, 1.55])
@export var difficulty_speed_multipliers := PackedFloat32Array([0.90, 1.0, 1.08, 1.15])
@export var difficulty_detection_multipliers := PackedFloat32Array([0.90, 1.0, 1.08, 1.20])
@export var difficulty_cooldown_multipliers := PackedFloat32Array([1.25, 1.0, 0.85, 0.70])
@export var difficulty_windup_multipliers := PackedFloat32Array([1.20, 1.0, 0.90, 0.75])


func get_behavior_family() -> StringName:
	return &"base"


func _scene_difficulty_multiplier(values: PackedFloat32Array) -> float:
	return VexEnemyRuntimeUtils.difficulty_multiplier(values, GameState.active_difficulty)


func _horizontal_distance(first: Vector3, second: Vector3) -> float:
	return VexEnemyRuntimeUtils.horizontal_distance(first, second)
