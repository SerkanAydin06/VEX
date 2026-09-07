class_name VexOneShotNotificationTrigger
extends Area3D

@export var message_key := ""
@export var objective_key := ""
@export var required_weapon_id: StringName = &""

var _consumed := false


func _ready() -> void:
	collision_layer = 0
	if collision_mask == 0:
		collision_mask = 2
	monitoring = true
	monitorable = false
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _consumed or body == null:
		return
	if required_weapon_id != &"" and not _player_owns_required_weapon(body):
		return
	_consumed = true
	if not message_key.is_empty():
		GameState.notify(message_key)
	if not objective_key.is_empty():
		GameState.set_objective(objective_key)
	set_deferred("monitoring", false)


func _player_owns_required_weapon(body: Node) -> bool:
	var weapon_controller := body.get_node_or_null("WeaponController") as VexWeaponController
	return weapon_controller != null and weapon_controller.owns_weapon(required_weapon_id)
