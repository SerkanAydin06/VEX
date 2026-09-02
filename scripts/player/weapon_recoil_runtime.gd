class_name VexWeaponRecoilRuntime
extends RefCounted

var burst_shots := 0
var burst_reset_remaining := 0.0


func tick(delta: float) -> void:
	burst_reset_remaining = maxf(0.0, burst_reset_remaining - delta)
	if burst_reset_remaining <= 0.0:
		burst_shots = 0


func reset_burst() -> void:
	burst_shots = 0
	burst_reset_remaining = 0.0


func apply(
	player: VexPlayer,
	weapon: WeaponDefinition,
	modifiers: Dictionary,
	tuning: Dictionary
) -> void:
	if player == null or not is_instance_valid(player) or weapon == null:
		return

	burst_shots += 1
	burst_reset_remaining = maxf(
		float(tuning.get("burst_reset_min_time", 0.0)),
		weapon.fire_interval
		* float(modifiers.get("fire_rate", 1.0))
		* float(tuning.get("burst_reset_fire_interval_multiplier", 0.0))
	)

	var vertical_multiplier := 1.0
	var horizontal_multiplier := 1.0
	if weapon.automatic:
		vertical_multiplier = minf(
			float(tuning.get("automatic_vertical_max_multiplier", 1.0)),
			float(tuning.get("automatic_vertical_base_multiplier", 1.0))
			+ float(burst_shots) * float(tuning.get("automatic_vertical_per_shot", 0.0))
		)
		horizontal_multiplier = minf(
			float(tuning.get("automatic_horizontal_max_multiplier", 1.0)),
			float(tuning.get("automatic_horizontal_base_multiplier", 1.0))
			+ float(burst_shots) * float(tuning.get("automatic_horizontal_per_shot", 0.0))
		)

	var player_recoil_multiplier := player.get_weapon_recoil_multiplier()
	var recoil_multiplier := float(modifiers.get("recoil", 1.0))
	var vertical_kick := (
		float(weapon.recoil_vertical_degrees)
		* recoil_multiplier
		* vertical_multiplier
		* player_recoil_multiplier
	)
	var horizontal_extent := (
		float(weapon.recoil_horizontal_degrees)
		* recoil_multiplier
		* horizontal_multiplier
		* player_recoil_multiplier
	)
	var horizontal_kick := randf_range(-horizontal_extent, horizontal_extent)

	player.apply_weapon_recoil(
		vertical_kick,
		horizontal_kick,
		weapon.recoil_max_vertical_degrees,
		weapon.recoil_max_horizontal_degrees,
		weapon.recoil_recovery_degrees_per_second
		* float(modifiers.get("recoil_recovery", 1.0))
	)
