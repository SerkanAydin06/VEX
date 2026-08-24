class_name VexHubWeaponRack
extends StaticBody3D

@export_category("Silah Rafı")
@export var weapon_id: StringName = &"p01"
@export var display_name := "P-01 TAKTİK TABANCA"
@export var group_label := "ARMORY_GROUP_SIDEARM"
@export var weapon_texture: Texture2D
@export var fallback_visual_text := "P-01"
@export var locked_message := "GÖREVDE HENÜZ BULUNMADI"
@export_range(0.35, 1.5, 0.05) var visual_world_width := 1.2
@export var visual_local_position := Vector3(0.0, 0.0, 0.14)
@export var visual_rotation_degrees := Vector3.ZERO
@export var visual_flip_h := false
@export var auto_center_visible_pixels := true
@export var visual_pixel_offset := Vector2.ZERO

@export_category("Görsel")
@export var unlocked_color := Color(1, 1, 1, 1)
@export var locked_color := Color(0.0, 0.0, 0.0, 1.0)
@export var empty_slot_color := Color(0.0, 0.0, 0.0, 1.0)
@export var stored_label_color := Color(0.30, 1.0, 0.68, 1.0)
@export var carried_label_color := Color(1.0, 0.68, 0.24, 1.0)
@export var locked_label_color := Color(0.65, 0.22, 0.18, 1.0)

@onready var weapon_visual: Sprite3D = $WeaponVisual
@onready var empty_slot_visual: Sprite3D = $EmptySlotVisual
@onready var fallback_visual: Label3D = $FallbackVisual
@onready var empty_slot_label: Label3D = $EmptySlotLabel
@onready var name_label: Label3D = $NameLabel
@onready var group_name_label: Label3D = $GroupLabel

var _bound_controller: Node


func _ready() -> void:
	add_to_group("interactable")
	_apply_texture()
	if not GameState.player_registered.is_connected(_on_player_registered):
		GameState.player_registered.connect(_on_player_registered)
	if not SettingsManager.language_changed.is_connected(_on_language_changed):
		SettingsManager.language_changed.connect(_on_language_changed)
	call_deferred("_bind_player", GameState.player)


func get_interaction_text(player: Node) -> String:
	var owned := _is_owned(player)
	_refresh_visual(player)
	if not owned:
		return tr("RACK_INTERACT_LOCKED") % tr(display_name)
	if _is_carried(player):
		return tr("RACK_INTERACT_STORE") % tr(display_name)
	return tr("RACK_INTERACT_EQUIP") % tr(display_name)


func interact(player: Node) -> void:
	var controller := _get_weapon_controller(player)
	if controller == null or not _is_owned(player):
		GameState.notify(tr("RACK_LOCKED_MESSAGE") % [tr(display_name), tr(locked_message)])
		_refresh_visual(player)
		return
	var result: Dictionary = controller.call("toggle_armory_weapon", weapon_id) as Dictionary
	if not bool(result.get("success", false)):
		GameState.notify("RACK_BUSY")
		return
	if result.get("action", &"") == &"stored":
		GameState.notify(tr("RACK_STORED") % tr(display_name))
	else:
		var displaced_id := StringName(str(result.get("displaced_weapon_id", "")))
		if displaced_id == &"":
			GameState.notify(tr("RACK_EQUIPPED") % tr(display_name))
		else:
			var displaced_definition := controller.call("get_weapon_definition", displaced_id) as WeaponDefinition
			var displaced_name := str(displaced_id)
			if displaced_definition != null:
				displaced_name = tr(displaced_definition.display_name)
			GameState.notify(tr("RACK_SWAPPED") % [displaced_name, tr(display_name)])
	_refresh_visual(player)


func _get_weapon_controller(player: Node) -> Node:
	if player == null:
		return null
	return player.get_node_or_null("WeaponController")


func _is_owned(player: Node) -> bool:
	var controller := _get_weapon_controller(player)
	return controller != null and bool(controller.call("owns_weapon", weapon_id))


func _is_carried(player: Node) -> bool:
	var controller := _get_weapon_controller(player)
	return controller != null and bool(controller.call("is_weapon_carried", weapon_id))


func _apply_texture() -> void:
	weapon_visual.texture = weapon_texture
	empty_slot_visual.texture = weapon_texture
	weapon_visual.position = visual_local_position
	empty_slot_visual.position = visual_local_position - Vector3(0.0, 0.0, 0.04)
	weapon_visual.rotation_degrees = visual_rotation_degrees
	empty_slot_visual.rotation_degrees = visual_rotation_degrees
	weapon_visual.flip_h = visual_flip_h
	empty_slot_visual.flip_h = visual_flip_h
	weapon_visual.visible = false
	empty_slot_visual.visible = false
	fallback_visual.position = visual_local_position
	fallback_visual.rotation_degrees = visual_rotation_degrees
	fallback_visual.text = fallback_visual_text
	fallback_visual.visible = false
	empty_slot_label.position = visual_local_position - Vector3(0.0, 0.0, 0.04)
	empty_slot_label.rotation_degrees = visual_rotation_degrees
	empty_slot_label.text = "[ %s ]" % fallback_visual_text
	empty_slot_label.visible = false
	if weapon_texture == null:
		return
	var texture_size := weapon_texture.get_size()
	if texture_size.x > 0.0:
		var visual_pixel_size := visual_world_width / texture_size.x
		weapon_visual.pixel_size = visual_pixel_size
		empty_slot_visual.pixel_size = visual_pixel_size
		var centered_offset := _calculate_visual_pixel_offset(texture_size)
		weapon_visual.offset = centered_offset
		empty_slot_visual.offset = centered_offset


func _calculate_visual_pixel_offset(texture_size: Vector2) -> Vector2:
	var centered_offset := visual_pixel_offset
	if not auto_center_visible_pixels or weapon_texture == null:
		return centered_offset
	var source_image := weapon_texture.get_image()
	if source_image == null or source_image.is_empty():
		return centered_offset
	var used_rect := source_image.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return centered_offset
	var used_center := Vector2(used_rect.position) + Vector2(used_rect.size) * 0.5
	return centered_offset + texture_size * 0.5 - used_center


func _refresh_visual(player: Node) -> void:
	if not is_inside_tree():
		return
	var owned := _is_owned(player)
	var carried := _is_carried(player) if owned else false
	var show_stored_visual := owned and not carried
	weapon_visual.visible = weapon_texture != null and show_stored_visual
	empty_slot_visual.visible = weapon_texture != null and not show_stored_visual
	fallback_visual.visible = weapon_texture == null and show_stored_visual
	empty_slot_label.visible = weapon_texture == null and not show_stored_visual
	weapon_visual.modulate = unlocked_color if owned else locked_color
	empty_slot_visual.modulate = empty_slot_color if owned else locked_color
	empty_slot_label.modulate = empty_slot_color if owned else locked_color
	if not owned:
		name_label.modulate = locked_label_color
		name_label.text = "%s\n%s" % [tr(display_name), tr("UI_LOCKED")]
	elif carried:
		name_label.modulate = carried_label_color
		name_label.text = "%s\n%s" % [tr(display_name), tr("UI_CARRIED")]
	else:
		name_label.modulate = stored_label_color
		name_label.text = "%s\n%s" % [tr(display_name), tr("UI_STORED")]
	group_name_label.text = tr(group_label)


func _on_player_registered(player: Node) -> void:
	_bind_player(player)


func _bind_player(player: Node) -> void:
	var controller := _get_weapon_controller(player)
	if controller != null and controller != _bound_controller:
		_bound_controller = controller
		var refresh_callable := _on_loadout_changed.bind(player)
		if controller.has_signal("loadout_changed") and not controller.is_connected("loadout_changed", refresh_callable):
			controller.connect("loadout_changed", refresh_callable)
	_refresh_visual(player)


func _on_loadout_changed(player: Node) -> void:
	_refresh_visual(player)


func _on_language_changed(_locale: String) -> void:
	_refresh_visual(GameState.player)
