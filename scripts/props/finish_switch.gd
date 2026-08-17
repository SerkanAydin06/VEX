class_name VexFinishSwitch
extends Node3D

@export_category("Bitiş Kontrolü")
@export var display_name := "TAHLİYE KONTROLÜ"
@export var required_keys: Array[StringName] = [&"blue", &"red"]
@export var required_enemy_id: StringName = &""
@export_file("*.tscn") var next_level_path := ""

@export_category("Finish Switch Görseli")
@export var visual_world_size := Vector2(0.90, 1.30)
@export var activated_modulate := Color(0.55, 0.65, 0.55, 1.0)

@onready var finish_switch_visual: Sprite3D = $PanelBody/FinishSwitchVisual

var _used := false


func _ready() -> void:
	add_to_group("interactable")
	_setup_finish_switch_visual()


func get_interaction_text(player: Node) -> String:
	if _used:
		return ""
	if not _player_has_all_keys(player):
		return "[E] %s — %d ANAHTAR GEREKLİ" % [display_name, required_keys.size()]
	if required_enemy_id != &"" and not GameState.was_enemy_defeated(required_enemy_id):
		return "[E] %s — NİHAİ MUHAFIZ AKTİF" % display_name
	return "[E] BÖLÜM ÇIKIŞINI ETKİNLEŞTİR"


func interact(player: Node) -> void:
	if _used:
		return
	if not _player_has_all_keys(player):
		GameState.notify("TAHLİYE KİLİTLİ — MAVİ VE KIRMIZI ANAHTAR GEREKLİ")
		return
	if required_enemy_id != &"" and not GameState.was_enemy_defeated(required_enemy_id):
		GameState.notify("TAHLİYE KİLİTLİ — NİHAİ MUHAFIZI İMHA ET")
		GameState.set_objective("NİHAİ MUHAFIZI İMHA ET VE ŞALTERE DÖN")
		return

	_used = true
	finish_switch_visual.modulate = activated_modulate
	GameState.notify("BÖLÜM ÇIKIŞI ETKİNLEŞTİRİLDİ")
	GameState.call_deferred("complete_level", next_level_path)


func _player_has_all_keys(player: Node) -> bool:
	if player == null or not player.has_method("has_key"):
		return false
	for key_id: StringName in required_keys:
		if not bool(player.call("has_key", key_id)):
			return false
	return true


func _setup_finish_switch_visual() -> void:
	var texture := finish_switch_visual.texture
	if texture == null:
		push_warning(
			"finish_switch görseli bulunamadı: "
			+ "res://assets/world/finish_switch.png"
		)
		return

	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var pixel_for_width := visual_world_size.x / texture_size.x
	var pixel_for_height := visual_world_size.y / texture_size.y
	finish_switch_visual.pixel_size = minf(pixel_for_width, pixel_for_height)
