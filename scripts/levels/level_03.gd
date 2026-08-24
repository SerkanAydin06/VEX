extends VexBaseLevel

var _alarm_triggered := false

func _on_key_inventory_changed(keys: Array[StringName]) -> void:
	if keys.has(&"red"):
		GameState.set_objective("LEVEL03_OBJECTIVE_RED")
	elif keys.has(&"blue"):
		GameState.set_objective("LEVEL03_OBJECTIVE_BLUE")

func _on_gunshot_emitted(_position: Vector3, _loudness: float, source: Node) -> void:
	if _alarm_triggered or source == null:
		return
	_alarm_triggered = true
	GameState.notify("LEVEL03_GUNSHOT_ALARM")
