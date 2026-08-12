extends Control

@onready var time_value: Label = %TimeValue
@onready var kills_value: Label = %KillsValue
@onready var secrets_value: Label = %SecretsValue
@onready var difficulty_value: Label = %DifficultyValue
@onready var rating_value: Label = %RatingValue
@onready var replay_button: Button = %ReplayButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var quit_button: Button = %QuitButton
@onready var subtitle_label: Label = $ResultPanel/Margin/VBox/Subtitle


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	var summary := GameState.last_level_summary
	var elapsed_msec := int(summary.get("elapsed_msec", 0))
	var kills := int(summary.get("kills", 0))
	var total_enemies := maxi(1, int(summary.get("total_enemies", 1)))
	var secrets := int(summary.get("secrets", 0))
	var total_secrets := maxi(0, int(summary.get("total_secrets", 0)))
	time_value.text = _format_time(elapsed_msec)
	kills_value.text = "%d / %d" % [kills, total_enemies]
	secrets_value.text = "%d / %d" % [secrets, total_secrets]
	difficulty_value.text = str(summary.get("difficulty", "NORMAL"))
	subtitle_label.text = str(summary.get("level_label", "VEX"))
	var completion := float(kills) / float(total_enemies)
	if total_secrets > 0:
		completion = (completion + float(secrets) / float(total_secrets)) * 0.5
	rating_value.text = _get_rating(completion)
	if GameState.has_pending_next_level():
		replay_button.text = "SONRAKİ BÖLÜM"
		replay_button.pressed.connect(GameState.continue_to_next_level)
	else:
		replay_button.text = "BÖLÜMÜ TEKRAR OYNA"
		replay_button.pressed.connect(GameState.restart_level)
	main_menu_button.pressed.connect(GameState.return_to_main_menu)
	quit_button.pressed.connect(get_tree().quit)
	replay_button.grab_focus()


func _format_time(milliseconds: int) -> String:
	var total_seconds := int(floor(float(milliseconds) / 1000.0))
	var minutes := int(floor(float(total_seconds) / 60.0))
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _get_rating(completion: float) -> String:
	if completion >= 0.999:
		return "S // TAM TEMİZLİK"
	if completion >= 0.75:
		return "A // ÜSTÜN BAŞARI"
	if completion >= 0.5:
		return "B // GÖREV TAMAMLANDI"
	return "C // HAYATTA KALDI"
