extends VexBaseLevel

var _alarm_triggered := false

func _on_gunshot_emitted(_position: Vector3, _loudness: float, source: Node) -> void:
	if _alarm_triggered or source == null:
		return
	_alarm_triggered = true
	GameState.notify("LEVEL02_GUNSHOT_ALARM")

func _on_key_inventory_changed(keys: Array[StringName]) -> void:
	if keys.has(&"red"):
		GameState.set_objective("LEVEL02_OBJECTIVE_RED")
	elif keys.has(&"yellow"):
		GameState.set_objective("LEVEL02_OBJECTIVE_YELLOW")
	elif keys.has(&"blue"):
		GameState.set_objective("LEVEL02_OBJECTIVE_BLUE")
