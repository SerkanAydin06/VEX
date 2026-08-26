extends VexBaseLevel

func _on_key_inventory_changed(keys: Array[StringName]) -> void:
	var has_blue := keys.has(&"blue")
	var has_red := keys.has(&"red")
	if has_blue and has_red:
		GameState.set_objective("LEVEL01_OBJECTIVE_BOTH_KEYS")
	elif has_red:
		GameState.set_objective("LEVEL01_OBJECTIVE_RED_ONLY")
	elif has_blue:
		GameState.set_objective("LEVEL01_OBJECTIVE_BLUE_ONLY")
