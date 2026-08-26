@tool
class_name VexTutorialTrigger
extends Area3D

@export_category("Öğretici Mesajı")
@export var trigger_id: StringName = &"tutorial"
@export var objective_key := ""
@export var notification_key := ""
@export var one_shot := true

@export_category("Tetikleme Alanı")
@export var trigger_size := Vector3(11.0, 3.0, 3.0):
	set(value):
		trigger_size = value
		_apply_shape()

var _activated := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_apply_shape()
	if Engine.is_editor_hint():
		return
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if one_shot and _activated:
		return
	if body != GameState.player and not body.is_in_group("player"):
		return
	_activated = true
	if not objective_key.is_empty():
		GameState.set_objective(objective_key)
	if not notification_key.is_empty():
		GameState.notify(notification_key)
	if one_shot:
		set_deferred("monitoring", false)


func _apply_shape() -> void:
	if not is_inside_tree():
		return
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		return
	var box := collision.shape as BoxShape3D
	if box == null:
		return
	box.size = Vector3(
		maxf(trigger_size.x, 0.1),
		maxf(trigger_size.y, 0.1),
		maxf(trigger_size.z, 0.1)
	)
