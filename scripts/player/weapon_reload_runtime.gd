class_name VexWeaponReloadRuntime
extends RefCounted

const RESULT_COMPLETED: StringName = &"completed"
const RESULT_INTERRUPTED: StringName = &"interrupted"
const RESULT_INVALID: StringName = &"invalid"


static func reload_magazine(
	owner: Node,
	player: VexPlayer,
	weapon: WeaponDefinition,
	magazines: Dictionary,
	reserve_ammo: Dictionary,
	get_magazine_size: Callable,
	reload_time_multiplier: float
) -> bool:
	if owner == null or weapon == null:
		return false
	await owner.get_tree().create_timer(
		weapon.reload_duration * maxf(0.01, reload_time_multiplier),
		false
	).timeout
	if not owner.is_inside_tree() or player == null or player.is_dead:
		return false

	# Reload sürerken ammo pickup veya kapasite upgrade'i oluşmuş olabilir.
	# Başlangıç snapshot'ını değil, bitiş anındaki canlı state'i kullan.
	var live_magazine := int(magazines.get(weapon.weapon_id, 0))
	var live_reserve := int(reserve_ammo.get(weapon.ammo_type, 0))
	var live_magazine_size := maxi(0, int(get_magazine_size.call()))
	var required := maxi(0, live_magazine_size - live_magazine)
	var loaded := mini(required, live_reserve)
	magazines[weapon.weapon_id] = live_magazine + loaded
	reserve_ammo[weapon.ammo_type] = live_reserve - loaded
	return true


static func reload_sg04_shells(
	owner: Node,
	player: VexPlayer,
	weapon: WeaponDefinition,
	magazines: Dictionary,
	reserve_ammo: Dictionary,
	magazine_size: int,
	starting_magazine: int,
	starting_reserve: int,
	reload_time_multiplier: float,
	reload_generation: int,
	get_generation: Callable,
	play_action: Callable,
	broadcast_state: Callable
) -> StringName:
	if owner == null or weapon == null:
		return RESULT_INVALID
	var rounds_to_load := mini(magazine_size - starting_magazine, starting_reserve)
	var multiplier := maxf(0.01, reload_time_multiplier)
	# SG04 reload art has four equal-duration authored frames. Frames 1-2-3 are
	# one shell insertion cycle; frame 4 is the single final close/ready pose.
	var shell_cycle_duration := weapon.reload_duration * 0.75 * multiplier
	var finish_duration := weapon.reload_duration * 0.25 * multiplier

	for _round_index: int in range(rounds_to_load):
		play_action.call(&"reload_shell")
		await owner.get_tree().create_timer(shell_cycle_duration, false).timeout
		if int(get_generation.call()) != reload_generation:
			return RESULT_INTERRUPTED
		if not owner.is_inside_tree() or player == null or player.is_dead:
			return RESULT_INVALID

		var current_magazine := int(magazines.get(weapon.weapon_id, 0))
		var current_reserve := int(reserve_ammo.get(weapon.ammo_type, 0))
		if current_magazine >= magazine_size or current_reserve <= 0:
			break
		magazines[weapon.weapon_id] = current_magazine + 1
		reserve_ammo[weapon.ammo_type] = current_reserve - 1
		broadcast_state.call()

	if not owner.is_inside_tree() or player == null or player.is_dead:
		return RESULT_INVALID
	play_action.call(&"reload_finish")
	await owner.get_tree().create_timer(finish_duration, false).timeout
	if int(get_generation.call()) != reload_generation:
		return RESULT_INTERRUPTED
	if not owner.is_inside_tree() or player == null or player.is_dead:
		return RESULT_INVALID
	return RESULT_COMPLETED
