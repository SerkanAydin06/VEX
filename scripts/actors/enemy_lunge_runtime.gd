class_name VexEnemyLungeRuntime
extends RefCounted

const MODE_BRAKE := 0
const MODE_STOP := 1
const MODE_MOVE := 2


static func initial_attack_lunge_duration(
	attack_lunge_duration: float,
	runtime_attack_windup: float
) -> float:
	return maxf(0.0, minf(attack_lunge_duration, runtime_attack_windup))


static func attack_lunge_plan(
	enemy_position: Vector3,
	player_position: Vector3,
	player_valid: bool,
	lunge_remaining: float,
	runtime_lunge_speed: float,
	stop_distance: float,
	delta: float
) -> Dictionary:
	if lunge_remaining <= 0.0 or runtime_lunge_speed <= 0.0 or not player_valid:
		return {
			"mode": MODE_BRAKE,
			"remaining": 0.0,
			"facing_direction": Vector3.ZERO,
			"desired_velocity": Vector3.ZERO,
		}

	var remaining := maxf(0.0, lunge_remaining - delta)
	var direction := player_position - enemy_position
	direction.y = 0.0
	var distance := direction.length()
	if distance <= stop_distance or distance <= 0.001:
		return {
			"mode": MODE_STOP,
			"remaining": remaining,
			"facing_direction": Vector3.ZERO,
			"desired_velocity": Vector3.ZERO,
		}

	var facing_direction := direction / distance
	return {
		"mode": MODE_MOVE,
		"remaining": remaining,
		"facing_direction": facing_direction,
		"desired_velocity": facing_direction * runtime_lunge_speed,
	}
