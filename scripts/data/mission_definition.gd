class_name VexMissionDefinition
extends Resource

@export var mission_id: StringName = &"vex01"
@export var display_name := "VEX-01 // KARANTİNA TESİSİ"
@export_multiline var briefing := "BASTION-7: İç hatta ilerle. Güvenlik erişimini yeniden kur ve tahliye yolunu aç."
@export_multiline var completion_message := "OPERASYON TAMAMLANDI. KAYIT BASTION-7'YE AKTARILDI."
@export var scene_path := "res://scenes/levels/level_01.tscn"
@export var campaign_stage := 1

@export_category("Terminal Presentation")
@export var terminal_code := "VEX-01"
@export var facility_type := "TERMINAL_FACILITY_QUARANTINE"
@export var terminal_preview: Texture2D
