class_name VexLevel03ExtractionSwitch
extends VexFinishSwitch

@export var rescue_terminal_path: NodePath
@export var rescue_required_message_key := "CH03_FINISH_REQUIRES_RESCUE"
@export var rescue_required_objective_key := "CH03_OBJECTIVE_RESCUE"


func _ready() -> void:
	super._ready()
	# Level 3 uses its own authored VEX evacuation console. The inherited
	# finish-switch Sprite3D remains available to the shared interaction code but
	# is never rendered, so the old placeholder switch art cannot bleed through.
	if finish_switch_visual != null:
		finish_switch_visual.visible = false


func get_interaction_text(player: Node) -> String:
	if not _is_survivor_rescued():
		return tr(rescue_required_message_key)
	return super.get_interaction_text(player)


func interact(player: Node) -> void:
	if not _is_survivor_rescued():
		GameState.notify(rescue_required_message_key)
		GameState.set_objective(rescue_required_objective_key)
		return
	super.interact(player)


func _is_survivor_rescued() -> bool:
	if String(rescue_terminal_path).is_empty():
		return false
	var rescue_terminal := get_node_or_null(rescue_terminal_path) as VexSurvivorRescueTerminal
	return rescue_terminal != null and rescue_terminal.rescued
