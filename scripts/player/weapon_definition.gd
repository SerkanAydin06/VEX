class_name WeaponDefinition
extends Resource

@export var weapon_id: StringName = &"pistol"
@export var display_name := "TABANCA"
@export var ammo_type: StringName = &"bullets"
@export_range(1, 100, 1) var magazine_size := 12
@export_range(1, 100, 1) var damage_per_pellet := 18
@export_range(1, 20, 1) var pellet_count := 1
@export_range(0.05, 2.0, 0.01) var fire_interval := 0.28
@export_range(0.1, 5.0, 0.05) var reload_duration := 1.1
@export_range(0.0, 20.0, 0.1) var spread_degrees := 1.0
@export_range(5.0, 200.0, 1.0) var maximum_range := 80.0
@export var automatic := false

@export_category("Sekme")
@export_range(0.0, 12.0, 0.05) var recoil_vertical_degrees := 1.0
@export_range(0.0, 6.0, 0.05) var recoil_horizontal_degrees := 0.2
@export_range(0.0, 20.0, 0.1) var recoil_max_vertical_degrees := 4.0
@export_range(0.0, 10.0, 0.1) var recoil_max_horizontal_degrees := 1.0
@export_range(0.1, 30.0, 0.1) var recoil_recovery_degrees_per_second := 7.0
