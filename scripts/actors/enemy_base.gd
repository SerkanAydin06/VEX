class_name VexEnemyBase
extends CharacterBody3D

# Yaratık adı taşımayan en alt seviye sözleşme.
# Kimlik/zorluk verileri ile her davranış ailesinin kullandığı saf yardımcılar
# burada tutulur. Hareket state machine'i bu sınıfta bulunmaz.
const EnemyCombatProfiles = preload("res://scripts/actors/enemy_combat_profiles.gd")
const EnemyNavigationRuntime = preload("res://scripts/actors/enemy_navigation_runtime.gd")

func get_behavior_family() -> StringName:
	return &"base"


func _scene_difficulty_multiplier(values: PackedFloat32Array) -> float:
	return VexEnemyRuntimeUtils.difficulty_multiplier(values, GameState.active_difficulty)


func _horizontal_distance(first: Vector3, second: Vector3) -> float:
	return VexEnemyRuntimeUtils.horizontal_distance(first, second)
