class_name VexHuskLeechProjectile
extends "res://scripts/actors/ravager_projectile.gd"

const VenomOverlay = preload("res://scripts/effects/husk_leech_venom_overlay.gd")

@export_category("04 - Husk Leech Zehir Görüşü")
@export_range(0.5, 6.0, 0.1) var venom_overlay_duration := 2.8
@export_range(0.2, 1.0, 0.05) var venom_overlay_peak_alpha := 0.95


func _resolve_damage_target(collider: Object) -> Node:
	var target := super._resolve_damage_target(collider)
	if target != null and target.is_in_group("player"):
		VenomOverlay.apply_to(target, venom_overlay_duration, venom_overlay_peak_alpha)
	return target
