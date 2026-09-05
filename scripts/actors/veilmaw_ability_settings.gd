@tool
class_name VexVeilmawAbilitySettings
extends VexEnemyAbilitySettings

@export_category("01 - Ateş Et / Konum Değiştir")
## Atıştan sonra yeni bir görüş açısı aramak için ayrılan saldırı toparlanma süresidir.
@export_range(0.2, 1.2, 0.05) var post_shot_reposition_duration := 0.65
