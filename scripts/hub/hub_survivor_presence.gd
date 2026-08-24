class_name VexHubSurvivorPresence
extends StaticBody3D

@export_range(0, 100, 1) var required_campaign_stage := 0
@export var display_name_key := ""
@export var role_key := ""
@export var dialogue_key := ""
@export_range(0, 100, 1) var advanced_dialogue_stage := 100
@export var advanced_dialogue_key := ""

@onready var collision_shape: CollisionShape3D = %CollisionShape3D
@onready var name_label: Label3D = %NameLabel
@onready var role_label: Label3D = %RoleLabel

func _ready() -> void:
	add_to_group("interactable")
	_refresh_presence()
	if not SettingsManager.language_changed.is_connected(_on_language_changed):
		SettingsManager.language_changed.connect(_on_language_changed)

func _refresh_presence() -> void:
	var active := GameState.campaign_stage >= required_campaign_stage
	visible = active
	collision_shape.set_deferred("disabled", not active)
	set_process_unhandled_input(active)
	if active:
		_refresh_text()

func _refresh_text() -> void:
	name_label.text = tr(display_name_key)
	role_label.text = tr(role_key)

func _on_language_changed(_locale: String) -> void:
	if visible:
		_refresh_text()

func get_interaction_text(_player: Node) -> String:
	if not visible:
		return ""
	return tr("HUB_TALK_TO") % tr(display_name_key)

func interact(_player: Node) -> void:
	if not visible:
		return
	var key := dialogue_key
	if GameState.campaign_stage >= advanced_dialogue_stage and not advanced_dialogue_key.is_empty():
		key = advanced_dialogue_key
	if not key.is_empty():
		GameState.notify(tr(key))
