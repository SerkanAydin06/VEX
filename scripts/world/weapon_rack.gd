@tool
extends StaticBody3D

@export_category("Silah Rafı")
@export_enum("Pistol", "Shotgun", "Ak47", "Mp90") var weapon_type: String = "Pistol":
	set(value):
		weapon_type = value
		update_texture()

@export var pistol_texture: Texture2D
@export var shotgun_texture: Texture2D
@export var ak47_texture: Texture2D
@export var mp90_texture: Texture2D

@export var locked_message := "GÖREVDE HENÜZ BULUNMADI"

@export_category("Görsel")
@export var unlocked_color := Color(1, 1, 1, 1)
@export var locked_color := Color(0.18, 0.20, 0.22, 0.45)
@export var active_label_color := Color(0.30, 1.0, 0.68, 1.0)
@export var locked_label_color := Color(0.65, 0.22, 0.18, 1.0)

func update_texture() -> void:
	var weapon_texture: Texture2D
	match weapon_type:
		"Pistol": weapon_texture = pistol_texture
		"Shotgun": weapon_texture = shotgun_texture
		"Ak47": weapon_texture = ak47_texture
		"Mp90": weapon_texture = mp90_texture

	for i in range(1, 7):
		var sprite := get_node_or_null("Weapon%d" % i) as Sprite3D
		if sprite: sprite.texture = weapon_texture
		

func interact(player: Node) -> void:
	var controller := _get_weapon_controller(player)
	if controller == null or not _is_unlocked(player):
		GameState.notify("%s // %s" % [weapon_type, locked_message])
		_refresh_visual(player)
		return
	#controller.call("switch_to", weapon_id)
	GameState.notify("CEPHANELİK // %s KUŞANILDI" % weapon_type)
	_refresh_visual(player)


func _get_weapon_controller(player: Node) -> Node:
	if player == null: return null
	return player.get_node_or_null("WeaponController")


func _is_unlocked(player: Node) -> bool:
	var controller := _get_weapon_controller(player)
	if controller == null: return false
	var unlocked: Array = controller.get("unlocked_weapons") as Array
	return unlocked.has(weapon_type)

func _refresh_visual(player: Node) -> void:
	if not is_inside_tree(): return
	var unlocked := _is_unlocked(player)
	#weapon_visual.modulate = unlocked_color if unlocked else locked_color

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_texture()
	add_to_group("interactable")
	call_deferred("_refresh_visual", GameState.player)
