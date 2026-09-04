class_name VexRiftReaver
extends "res://scripts/actors/enemy_lunge_performance_base.gd"

const RiftReaverAudio = preload("res://scripts/actors/rift_reaver_audio_runtime.gd")
const RiftReaverFx = preload("res://scripts/effects/rift_reaver_fx.gd")
const WAKE_INTERVAL := 0.045

var _wake_remaining := 0.0
var _rift_attack_active := false
var _rift_impact_emitted := false


func _ready() -> void:
	super._ready()
	if is_queued_for_deletion():
		return
	attack_audio.stream = RiftReaverAudio.attack_stream()
	hurt_audio.stream = RiftReaverAudio.hurt_stream()
	death_audio.stream = RiftReaverAudio.death_stream()


func _physics_process(delta: float) -> void:
	var was_attack_locked := _attack_locked
	super._physics_process(delta)
	if Engine.is_editor_hint() or _dead:
		_rift_attack_active = false
		return

	if not was_attack_locked and _attack_locked:
		_rift_attack_active = true
		_rift_impact_emitted = false
		_wake_remaining = 0.0
		RiftReaverFx.spawn_attack_start(self, animated_sprite)

	if _rift_attack_active and _attack_locked and _attack_lunge_remaining > 0.0:
		_wake_remaining -= delta
		if _wake_remaining <= 0.0:
			RiftReaverFx.spawn_wake(self, animated_sprite)
			_wake_remaining = WAKE_INTERVAL

	if (
		_rift_attack_active
		and not _rift_impact_emitted
		and _attack_locked
		and _attack_lunge_remaining <= 0.0
	):
		_rift_impact_emitted = true
		RiftReaverFx.spawn_impact(self, animated_sprite)

	if was_attack_locked and not _attack_locked:
		_rift_attack_active = false
		_wake_remaining = 0.0


func take_damage(
	amount: int,
	hit_position := Vector3.ZERO,
	source: Node = null
) -> void:
	var was_dead := _dead
	super.take_damage(amount, hit_position, source)
	if not was_dead and not _dead:
		RiftReaverFx.spawn_hurt(self, animated_sprite)


func _die() -> void:
	if _dead:
		return
	RiftReaverFx.spawn_death(self, animated_sprite)
	super._die()
