extends VexBaseLevel

func _on_key_inventory_changed(keys: Array[StringName]) -> void:
	if keys.has(&"red"):
		GameState.set_objective("LEVEL01_OBJECTIVE_RED")
	elif keys.has(&"blue"):
		GameState.set_objective("LEVEL01_OBJECTIVE_BLUE")
