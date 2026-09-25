class_name VexMissionDefinition
extends Resource

# Varsayılanlar bilerek boş: her görev kaynağı kimliğini, sahnesini ve aşamasını
# açıkça yazmalı (Godot varsayılana eşit değerleri kaynağa kaydetmez).
@export var mission_id: StringName = &""
@export var display_name := ""
@export_multiline var briefing := ""
@export_multiline var completion_message := ""
@export var scene_path := ""
@export var campaign_stage := 0

@export_category("Terminal Presentation")
@export var terminal_code := ""
@export var facility_type := ""
@export var terminal_preview: Texture2D
