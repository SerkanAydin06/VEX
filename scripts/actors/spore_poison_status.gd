class_name VexSporePoisonStatus
extends Node

const OVERLAY_LAYER := 118
const OVERLAY_COLOR := Color(0.12, 0.48, 0.10, 0.18)

var _target: Node = null
var _source: Node = null
var _remaining := 0.0
var _tick_remaining := 0.0
var _tick_interval := 0.75
var _tick_damage := 3
var _pulse_time := 0.0
var _overlay_layer: CanvasLayer = null
var _overlay_rect: ColorRect = null


func _ready() -> void:
	_target = get_parent()
	set_process(true)
	if _target != null and _target.is_in_group("player"):
		_ensure_overlay()


func refresh_poison(
	duration: float,
	tick_damage: int,
	tick_interval: float,
	source: Node
) -> void:
	_target = get_parent()
	var was_active := _remaining > 0.0
	var safe_duration := maxf(0.05, duration)
	var safe_interval := maxf(0.10, tick_interval)
	var safe_damage := maxi(1, tick_damage)
	_remaining = maxf(_remaining, safe_duration)
	if was_active:
		_tick_damage = maxi(_tick_damage, safe_damage)
		_tick_interval = minf(_tick_interval, safe_interval)
		_tick_remaining = minf(_tick_remaining, _tick_interval)
	else:
		_tick_damage = safe_damage
		_tick_interval = safe_interval
		_tick_remaining = _tick_interval
	_source = source if is_instance_valid(source) else null
	if _target != null and _target.is_in_group("player"):
		_ensure_overlay()


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or not _target.has_method("take_damage"):
		queue_free()
		return

	_remaining = maxf(0.0, _remaining - delta)
	_pulse_time += delta * 4.6
	_update_overlay()

	if _remaining <= 0.0:
		queue_free()
		return

	_tick_remaining -= delta
	if _tick_remaining > 0.0:
		return
	_tick_remaining += _tick_interval
	var hit_position := Vector3.ZERO
	if _target is Node3D:
		hit_position = (_target as Node3D).global_position
	var damage_source: Node = null
	if is_instance_valid(_source):
		damage_source = _source
	else:
		_source = null
	_target.call("take_damage", _tick_damage, hit_position, damage_source)


func get_remaining_time() -> float:
	return _remaining


func get_tick_damage() -> int:
	return _tick_damage


func _ensure_overlay() -> void:
	if (
		_overlay_layer != null
		and is_instance_valid(_overlay_layer)
		and _overlay_rect != null
		and is_instance_valid(_overlay_rect)
	):
		return
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "SporePoisonOverlay"
	_overlay_layer.layer = OVERLAY_LAYER
	_overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay_layer)

	_overlay_rect = ColorRect.new()
	_overlay_rect.name = "SporePoisonTint"
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_rect.color = OVERLAY_COLOR
	_overlay_layer.add_child(_overlay_rect)
	_overlay_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _update_overlay() -> void:
	if _overlay_rect == null or not is_instance_valid(_overlay_rect):
		return
	var pulse := 0.72 + (sin(_pulse_time) * 0.5 + 0.5) * 0.28
	var ending_fade := clampf(_remaining / 0.55, 0.0, 1.0)
	_overlay_rect.modulate = Color(1.0, 1.0, 1.0, pulse * ending_fade)
