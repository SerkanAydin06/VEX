class_name VexKorvathRift
extends Node3D

@export_category("Yarık Tehlikesi")
@export_range(1, 50, 1) var pulse_damage := 9
@export_range(0.2, 4.0, 0.1) var damage_interval := 1.15
@export_range(0.0, 0.2, 0.005) var pulse_scale := 0.045

@onready var visual: Sprite3D = $Visual
@onready var rift_light: OmniLight3D = $RiftLight

var _bodies: Array[Node3D] = []
var _damage_clock := 0.0
var _elapsed := 0.0


func _ready() -> void:
	$HeatZone.body_entered.connect(_on_body_entered)
	$HeatZone.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_elapsed += delta
	var wave := sin(_elapsed * 2.1)
	visual.scale = Vector3.ONE * (1.0 + wave * pulse_scale)
	rift_light.light_energy = 4.2 + wave * 1.25

	_damage_clock -= delta
	if _damage_clock > 0.0 or _bodies.is_empty():
		return
	_damage_clock = damage_interval
	for body in _bodies.duplicate():
		if not is_instance_valid(body):
			_bodies.erase(body)
			continue
		if body.has_method("take_damage"):
			body.call("take_damage", pulse_damage)
			GameState.notify(tr("RIFT_HEAT_DAMAGE") % pulse_damage)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not _bodies.has(body):
		_bodies.append(body)
		_damage_clock = 0.15


func _on_body_exited(body: Node3D) -> void:
	_bodies.erase(body)
