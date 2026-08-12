class_name VexSecretTrigger
extends Area3D

@export var secret_id: StringName = &"secret"

var _found := false


func _ready() -> void:
	if GameState.was_secret_found(secret_id):
		queue_free.call_deferred()
		return
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _found or not body.is_in_group("player"):
		return
	_found = true
	set_deferred("monitoring", false)
	GameState.register_secret_found(secret_id)
	queue_free.call_deferred()
