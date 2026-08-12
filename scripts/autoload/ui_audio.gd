extends Node

@onready var menu_button_audio: AudioStreamPlayer = $MenuButtonAudio


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_connect_existing_buttons")


func _connect_existing_buttons() -> void:
	for node in get_tree().root.find_children("*", "Button", true, false):
		_connect_button(node as Button)


func _on_node_added(node: Node) -> void:
	if node is Button:
		call_deferred("_connect_button", node as Button)


func _connect_button(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	if not button.button_down.is_connected(_play_menu_button):
		button.button_down.connect(_play_menu_button)


func _play_menu_button() -> void:
	if menu_button_audio.stream == null:
		return
	menu_button_audio.stop()
	menu_button_audio.play()
