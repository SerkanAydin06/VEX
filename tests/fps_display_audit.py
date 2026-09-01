#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    path = ROOT / relative
    assert path.exists(), path
    return path.read_text(encoding="utf-8")


project = read("project.godot")
overlay = read("scripts/autoload/fps_display.gd")
settings_script = read("scripts/ui/settings_panel.gd")
settings_scene = read("scenes/ui/settings_panel.tscn")

assert 'FpsDisplay="*res://scripts/autoload/fps_display.gd"' in project
assert 'const SAMPLE_INTERVAL := 0.25' in overlay
assert 'Engine.get_frames_per_second()' in overlay
assert 'SettingsManager.vsync' in overlay
assert '" • VSYNC"' in overlay
assert 'enabled and _has_gameplay_player()' in overlay
assert 'GameState.player != null' in overlay
assert 'config.set_value("display", "show_fps", enabled)' in overlay
assert 'config.get_value("display", "show_fps", false)' in overlay
assert 'func set_enabled(value: bool)' in overlay
assert 'layer = 120' in overlay

assert '@onready var fps_check: CheckButton = %FpsCheck' in settings_script
assert 'fps_check.toggled.connect(_on_fps_toggled)' in settings_script
assert 'fps_check.button_pressed = FpsDisplay.enabled' in settings_script
assert 'FpsDisplay.set_enabled(value)' in settings_script
assert 'func _update_toggle_labels()' in settings_script
assert 'fullscreen_check.text = _toggle_text(fullscreen_check.button_pressed)' in settings_script
assert 'vsync_check.text = _toggle_text(vsync_check.button_pressed)' in settings_script
assert 'fps_check.text = _toggle_text(fps_check.button_pressed)' in settings_script
assert 'shake_check.text = _toggle_text(shake_check.button_pressed)' in settings_script
assert 'head_bob_check.text = _toggle_text(head_bob_check.button_pressed)' in settings_script
assert 'return "KAPALI" if TranslationServer.get_locale().begins_with("tr") else "OFF"' in settings_script

assert '[node name="FpsLabel" type="Label"' in settings_scene
assert 'text = "FPS"' in settings_scene
assert '[node name="FpsCheck" type="CheckButton"' in settings_scene
assert 'unique_name_in_owner = true' in settings_scene

print("fps display and toggle label audit passed")
