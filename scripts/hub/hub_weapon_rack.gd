class_name VexHubWeaponRack
extends StaticBody3D

@export_category("Silah Rafı")
@export var weapon_id: StringName = &"pistol"
@export var display_name := "P9 SIDEARM"
@export var weapon_texture: Texture2D
@export var locked_message := "GÖREVDE HENÜZ BULUNMADI"
@export_range(0.4, 3.0, 0.05) var visual_world_width := 1.55

@export_category("Görsel")
@export var unlocked_color := Color(1, 1, 1, 1)
@export var locked_color := Color(0.18, 0.20, 0.22, 0.45)
@export var active_label_color := Color(0.30, 1.0, 0.68, 1.0)
@export var locked_label_color := Color(0.65, 0.22, 0.18, 1.0)

@onready var weapon_visual: Sprite3D = $WeaponVisual
@onready var name_label: Label3D = $NameLabel


func _ready() -> void:
	add_to_group("interactable")
	_apply_texture()
	call_deferred("_refresh_visual", GameState.player)


func get_interaction_text(player: Node) -> String:
	var unlocked := _is_unlocked(player)
	_refresh_visual(player)
	if not unlocked:
		return "[E] %s — KİLİTLİ" % display_name
	return "[E] %s KUŞAN" % display_name


func interact(player: Node) -> void:
	var controller := _get_weapon_controller(player)
	if controller == null or not _is_unlocked(player):
		GameState.notify("%s // %s" % [display_name, locked_message])
		_refresh_visual(player)
		return
	controller.call("switch_to", weapon_id)
	GameState.notify("CEPHANELİK // %s KUŞANILDI" % display_name)
	_refresh_visual(player)


func _get_weapon_controller(player: Node) -> Node:
	if player == null:
		return null
	return player.get_node_or_null("WeaponController")


func _is_unlocked(player: Node) -> bool:
	var controller := _get_weapon_controller(player)
	if controller == null:
		return false
	var unlocked: Array = controller.get("unlocked_weapons") as Array
	return unlocked.has(weapon_id)


func _apply_texture() -> void:
	weapon_visual.texture = weapon_texture
	weapon_visual.visible = weapon_texture != null
	if weapon_texture == null:
		return
	var texture_size := weapon_texture.get_size()
	if texture_size.x > 0.0:
		weapon_visual.pixel_size = visual_world_width / texture_size.x


func _refresh_visual(player: Node) -> void:
	if not is_inside_tree():
		return
	var unlocked := _is_unlocked(player)
	weapon_visual.modulate = unlocked_color if unlocked else locked_color
	name_label.modulate = active_label_color if unlocked else locked_label_color
	name_label.text = "%s\n%s" % [display_name, "READY" if unlocked else "LOCKED"]
