from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_SCRIPT = ROOT / "scripts/ui/vex_archive_terminal.gd"
ARCHIVE_SCENE = ROOT / "scenes/ui/vex_archive_terminal.tscn"
HUB_SCRIPT = ROOT / "scripts/hub/hub_terminal.gd"


def test_archive_section_switch_casts_int_back_to_enum() -> None:
    script = ARCHIVE_SCRIPT.read_text(encoding="utf-8")
    assert "func _select_section(section: int) -> void:" in script
    assert "_current_section = section as Section" in script


def test_archive_columns_stay_fixed_when_dynamic_labels_change() -> None:
    scene = ARCHIVE_SCENE.read_text(encoding="utf-8")
    script = ARCHIVE_SCRIPT.read_text(encoding="utf-8")

    assert "custom_minimum_size = Vector2(238, 0)" in scene
    assert "custom_minimum_size = Vector2(390, 0)" in scene
    assert scene.count("size_flags_horizontal = 0") >= 2
    assert '[node name="IndexPanel" type="PanelContainer"' in scene
    assert "custom_minimum_size = Vector2(362, 0)" in scene
    assert "button.clip_text = true" in script
    assert "button.size_flags_horizontal = Control.SIZE_EXPAND_FILL" in script


def test_physical_terminal_screen_has_subtle_runtime_signal_motion() -> None:
    script = HUB_SCRIPT.read_text(encoding="utf-8")

    assert '@export var screen_motion_enabled := true' in script
    assert "func _process(delta: float) -> void:" in script
    assert "screen_surface.position = _screen_base_position + Vector3" in script
    assert "screen_surface.pixel_size = _screen_base_pixel_size * scale_pulse" in script
    assert "screen_surface.modulate = Color(brightness, cyan_bias, 1.0, 1.0)" in script
