class_name VexMagmaMauler
extends "res://scripts/actors/enemy_lunge_performance_base.gd"

const MagmaMaulerSpriteRuntime = preload("res://scripts/actors/magma_mauler_sprite_runtime.gd")

# Magma Mauler ağır yakın dövüş/hamle ailesini kullanır. Görsel hacim ve yüzey
# ayrımı spritesheet'in kendisine işlenmiştir; standart AnimatedSprite3D render
# yolu korunur ve custom material/shader kullanılmaz.


func _ready() -> void:
	animated_sprite.sprite_frames = MagmaMaulerSpriteRuntime.get_sprite_frames()
	animated_sprite.animation = &"idle"
	super._ready()
