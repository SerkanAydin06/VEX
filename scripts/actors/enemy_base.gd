class_name VexEnemyBase
extends CharacterBody3D

# Yaratık adı taşımayan en alt seviye sözleşme.
# Kimlik/zorluk verileri ile her davranış ailesinin kullandığı saf yardımcılar
# burada tutulur. Hareket state machine'i bu sınıfta bulunmaz.
const EnemyCombatProfiles = preload("res://scripts/actors/enemy_combat_profiles.gd")
const EnemyNavigationRuntime = preload("res://scripts/actors/enemy_navigation_runtime.gd")

var _damage_shake_remaining := 0.0
var _damage_shake_duration := 0.0
var _damage_shake_amount_pixels := 0.0
var _damage_shake_phase := 0.0
var _damage_shake_origin_offset := Vector2.ZERO
var _damage_shake_active := false


func get_behavior_family() -> StringName:
	return &"base"


func _scene_difficulty_multiplier(values: PackedFloat32Array) -> float:
	return VexEnemyRuntimeUtils.difficulty_multiplier(values, GameState.active_difficulty)


func _horizontal_distance(first: Vector3, second: Vector3) -> float:
	return VexEnemyRuntimeUtils.horizontal_distance(first, second)


func _trigger_damage_shake(
	visual: SpriteBase3D,
	duration: float,
	amount_pixels: float
) -> void:
	if visual == null or not is_instance_valid(visual):
		return
	if duration <= 0.0 or amount_pixels <= 0.0:
		_clear_damage_shake(visual)
		return
	if not _damage_shake_active:
		_damage_shake_origin_offset = visual.offset
	_damage_shake_active = true
	_damage_shake_duration = duration
	_damage_shake_remaining = duration
	_damage_shake_amount_pixels = amount_pixels


func _update_damage_shake(
	visual: SpriteBase3D,
	delta: float,
	frequency: float
) -> void:
	if not _damage_shake_active:
		return
	if visual == null or not is_instance_valid(visual):
		_damage_shake_active = false
		return
	_damage_shake_remaining = maxf(0.0, _damage_shake_remaining - delta)
	if _damage_shake_remaining <= 0.0:
		_clear_damage_shake(visual)
		return
	_damage_shake_phase += delta * maxf(frequency, 1.0) * TAU
	var envelope := _damage_shake_remaining / maxf(_damage_shake_duration, 0.001)
	var shake := Vector2(
		sin(_damage_shake_phase),
		sin(_damage_shake_phase * 1.73 + 0.65) * 0.28
	)
	visual.offset = (
		_damage_shake_origin_offset
		+ shake * _damage_shake_amount_pixels * envelope
	)


func _clear_damage_shake(visual: SpriteBase3D) -> void:
	if _damage_shake_active and visual != null and is_instance_valid(visual):
		visual.offset = _damage_shake_origin_offset
	_damage_shake_remaining = 0.0
	_damage_shake_duration = 0.0
	_damage_shake_amount_pixels = 0.0
	_damage_shake_phase = 0.0
	_damage_shake_active = false
