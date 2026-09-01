class_name VexEnemySpriteVisualProfile
extends Resource

@export_category("Hacim")
@export_range(0.0, 4.0, 0.05) var normal_strength := 1.35
@export_range(0.0, 1.0, 0.01) var cavity_strength := 0.24
@export_range(0.0, 1.0, 0.01) var edge_darkening := 0.12

@export_category("Işık")
@export_range(0.0, 1.0, 0.01) var roughness := 0.72
@export_range(0.0, 1.0, 0.01) var specular := 0.34
@export_range(0.0, 1.0, 0.01) var rim_strength := 0.24
@export_range(0.0, 1.0, 0.01) var rim_tint := 0.65
@export_range(0.0, 1.0, 0.01) var ambient_lift := 0.08

@export_category("Yüzey")
@export_range(0.0, 2.0, 0.05) var contrast := 1.08
@export_range(0.0, 2.0, 0.05) var saturation := 1.02
@export_range(0.0, 1.0, 0.01) var bright_emission_strength := 0.0
@export_range(0.0, 1.0, 0.01) var bright_emission_threshold := 0.78
@export var emission_tint := Color(1.0, 0.82, 0.62, 1.0)
