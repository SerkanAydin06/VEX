@tool
class_name VexCinderSpitterAbilitySettings
extends VexEnemyAbilitySettings

@export_category("01 - Kısa Seri")
## Tek saldırı komutunda çıkarılan sıcak projectile sayısıdır.
@export_range(1, 3, 1) var burst_shot_count := 2
## Seri içindeki projectile'lar arasındaki süredir.
@export_range(0.05, 0.35, 0.01) var burst_interval := 0.12
## Her seri projectile'ının normal saldırı hasarından aldığı paydır.
@export_range(0.25, 1.0, 0.05) var burst_damage_scale := 0.60
