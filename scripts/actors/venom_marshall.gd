class_name VexVenomMarshall
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

var _ability: VexVenomMarshallAbilitySettings
var _buff_cooldown_remaining := 0.0


func get_behavior_family() -> StringName:
	return &"support_ranged"


func _ready() -> void:
	_ability = special_ability_settings as VexVenomMarshallAbilitySettings
	if _ability == null:
		_ability = VexVenomMarshallAbilitySettings.new()
		special_ability_settings = _ability
		push_warning("Venom Marshall özel yetenek ayarları eksikti; güvenli varsayılanlar kullanılıyor.")
	super._ready()


func _physics_process(delta: float) -> void:
	_buff_cooldown_remaining = maxf(0.0, _buff_cooldown_remaining - delta)
	super._physics_process(delta)


func _attempt_attack() -> void:
	if _attack_locked:
		return
	if (
		_buff_cooldown_remaining <= 0.0
		and _ability.buff_projectile_scene != null
		and _has_buff_candidate_in_self_field()
	):
		_begin_buff_attack()
		return
	super._attempt_attack()


func _has_buff_candidate_in_self_field() -> bool:
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if node == self or not (node is Node3D):
			continue
		var ally := node as Node3D
		if not _is_buff_candidate(ally):
			continue
		if _horizontal_distance(global_position, ally.global_position) <= _ability.buff_cast_range:
			return true
	return false


func _is_buff_candidate(ally: Node3D) -> bool:
	if not ally.has_method("take_damage"):
		return false
	var current_health := int(ally.get("health"))
	var maximum := int(ally.get("_runtime_maximum_health"))
	if current_health <= 0 or maximum <= 0:
		return false
	if current_health < maximum:
		return true
	var status := ally.get_node_or_null("VenomMarshallBuffStatus")
	if status == null:
		return true
	return float(status.call("get_remaining_time")) <= _ability.buff_refresh_window


func _begin_buff_attack() -> void:
	var combat_generation := _combat_interrupt_generation
	_attack_locked = true
	_attack_windup_active = true
	_stop_horizontal_motion()
	animated_sprite.flip_h = false
	if _has_animation(&"2nd_attack"):
		animated_sprite.play(&"2nd_attack")
		_apply_frame_ground_offset()
	if attack_audio.stream != null:
		attack_audio.stop()
		attack_audio.play()
	var windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)
	var cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)
	var runtime_windup := maxf(0.05, _ability.buff_windup * windup_scale)
	await get_tree().create_timer(runtime_windup).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return
	_deploy_buff_field()
	_buff_cooldown_remaining = maxf(runtime_windup, _ability.buff_cooldown * cooldown_scale)
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")
	var runtime_recovery := maxf(0.0, _ability.buff_recovery * cooldown_scale)
	if runtime_recovery > 0.0:
		await get_tree().create_timer(runtime_recovery).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return
	_attack_locked = false
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")


func _deploy_buff_field() -> void:
	var projectile_parent := get_tree().current_scene
	if projectile_parent == null:
		return
	var projectile := EnemyProjectilePool.acquire(_ability.buff_projectile_scene, projectile_parent) as Node3D
	if projectile == null:
		return
	projectile.global_position = global_position
	projectile.call("deploy_at", global_position, self)


func _frame_offsets_for_animation(animation_name: StringName) -> PackedFloat32Array:
	if animation_name == &"2nd_attack":
		return _ability.second_attack_frame_y_offsets if _ability != null else PackedFloat32Array()
	return super._frame_offsets_for_animation(animation_name)
