class_name VexPlayerInteractionRuntime
extends RefCounted


func resolve_interactable(collider: Object) -> Node:
	if collider is Node and collider.has_method("interact"):
		return collider as Node
	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent != null and parent.has_method("interact"):
			return parent
	return null


func try_interact(collider: Object, actor: Node) -> bool:
	var target := resolve_interactable(collider)
	if target == null or not target.has_method("interact"):
		return false
	target.call("interact", actor)
	return true


func get_interaction_prompt(collider: Object, actor: Node) -> String:
	var target := resolve_interactable(collider)
	if target == null or not target.has_method("get_interaction_text"):
		return ""
	return str(target.call("get_interaction_text", actor))
