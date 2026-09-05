class_name VexRiftReaver
extends "res://scripts/actors/enemy_lunge_performance_base.gd"

const RiftReaverAudio = preload("res://scripts/actors/rift_reaver_audio_runtime.gd")
const RiftReaverFx = preload("res://scripts/effects/rift_reaver_fx.gd")
const RiftReaverPhaseRuntime = preload("res://scripts/actors/rift_reaver_phase_runtime.gd")
const WAKE_INTERVAL := 0.045

var _wake_remaining := 0.0
var _rift_attack_active := false
var _rift_impact_emitted := false
var _phase_side := 1.0


func _ready() -> void:
	super._ready()
	if is_queued_for_deletion():
		return
	attack_audio.stream = RiftReaverAudio.attack_stream()
	hurt_audio.stream = RiftReaverAudio.hurt_stream()
	death_audio.stream = RiftReaverAudio.death_stream()


func _physics_process(delta: float) -> void:
	# Cooldown timer'ı fizik kareleri arasında bitebilir. Önceki saldırının
	# recovery phase'ini parent yeni bir saldırı kararı vermeden önce çöz.
	if (
		not Engine.is_editor_hint()
		and not _dead
		and _rift_attack_active
		and not _attack_locked
	):
		_finish_rift_attack_cycle()

	var was_attack_locked := _attack_locked
	super._physics_process(delta)
	if Engine.is_editor_hint() or _dead:
		_rift_attack_active = false
		return

	if not was_attack_locked and _attack_locked:
		_rift_attack_active = true
		_rift_impact_emitted = false
		_wake_remaining = 0.0
		_try_phase_step(false)
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

	# Parent bir future değişiklikte saldırı kilidini kendi physics çağrısı içinde
	# kapatırsa da recovery phase aynı karede kaybolmasın.
	if _rift_attack_active and not _attack_locked:
		_finish_rift_attack_cycle()


func _finish_rift_attack_cycle() -> void:
	_try_phase_step(true)
	_phase_side *= -1.0
	_rift_attack_active = false
	_wake_remaining = 0.0


func _try_phase_step(recovery: bool) -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var settings := special_ability_settings as VexRiftReaverPhaseSettings
	if settings == null or not settings.enabled:
		return false
	var result := RiftReaverPhaseRuntime.find_destination(
		self,
		_player,
		settings,
		recovery,
		_phase_side,
		floor_collision_mask,
		_collision_floor_local_y(),
		sight_collision_mask,
		sight_origin_height,
		sight_target_height
	)
	if result.is_empty():
		return false

	RiftReaverFx.spawn_phase_departure(self, animated_sprite)
	var destination: Vector3 = result.get("position", global_position)
	global_position = destination
	_phase_side = float(result.get("side", _phase_side))
	velocity.x = 0.0
	velocity.z = 0.0
	velocity.y = floor_stick_velocity
	_reset_navigation_path()
	_face_player()
	RiftReaverFx.spawn_phase_arrival(self, animated_sprite)
	return true


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
