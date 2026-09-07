from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
THEME = ROOT / "resources" / "ui" / "vex_theme.tres"
MAIN = ROOT / "scenes" / "ui" / "main_menu.tscn"
PAUSE = ROOT / "scenes" / "ui" / "pause_menu.tscn"
SETTINGS = ROOT / "scenes" / "ui" / "settings_panel.tscn"
KEYBIND = ROOT / "scenes" / "ui" / "keybind_panel.tscn"
KEYBIND_SCRIPT = ROOT / "scripts" / "ui" / "keybind_panel.gd"
COMPLETE = ROOT / "scenes" / "ui" / "level_complete.tscn"
TERMINAL = ROOT / "scenes" / "ui" / "terminal_menu.tscn"
ARCHIVE = ROOT / "scenes" / "ui" / "vex_archive_terminal.tscn"
WEAPON_ARCHIVE = ROOT / "scenes" / "ui" / "weapon_archive_terminal.tscn"
BASE_DASHBOARD = ROOT / "scenes" / "ui" / "base_management_dashboard.tscn"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_shared_theme_is_compact_without_double_panel_padding() -> None:
    theme = _read(THEME)
    assert "default_font_size = 19" in theme
    assert "Button/font_sizes/font_size = 20" in theme
    assert "CheckButton/font_sizes/font_size = 18" in theme
    assert "OptionButton/font_sizes/font_size = 18" in theme
    assert "content_margin_left = 16.0" in theme
    assert "content_margin_top = 10.0" in theme
    assert "content_margin_left = 8.0\ncontent_margin_top = 8.0" in theme
    assert "content_margin_left = 30.0" not in theme
    assert "content_margin_top = 26.0" not in theme


def test_main_menu_uses_compact_buttons_and_modals() -> None:
    scene = _read(MAIN)
    assert "offset_left = 70.0\noffset_top = 326.0\noffset_right = 430.0\noffset_bottom = 708.0" in scene
    assert scene.count("custom_minimum_size = Vector2(0, 46)") >= 7
    assert "theme_override_font_sizes/font_size = 30\ntext = \"VOID EXTERMINATION\"" in scene
    assert "offset_left = 650.0\noffset_top = 280.0\noffset_right = 1270.0\noffset_bottom = 800.0" in scene
    assert "offset_left = 690.0\noffset_top = 370.0\noffset_right = 1230.0\noffset_bottom = 680.0" in scene
    assert "custom_minimum_size = Vector2(220, 64)" not in scene
    assert "theme_override_font_sizes/font_size = 42" not in scene


def test_pause_menu_does_not_use_oversized_panel_or_buttons() -> None:
    scene = _read(PAUSE)
    assert "offset_left = 680.0\noffset_top = 280.0\noffset_right = 1240.0\noffset_bottom = 800.0" in scene
    assert scene.count("custom_minimum_size = Vector2(0, 48)") == 4
    assert "theme_override_font_sizes/font_size = 34" in scene
    assert "custom_minimum_size = Vector2(0, 68)" not in scene
    assert "theme_override_font_sizes/font_size = 46" not in scene


def test_settings_controls_fit_without_ellipsis_or_giant_rows() -> None:
    scene = _read(SETTINGS)
    assert "custom_minimum_size = Vector2(760, 720)" in scene
    assert scene.count("custom_minimum_size = Vector2(320, 46)") == 4
    assert scene.count("custom_minimum_size = Vector2(240, 32)") >= 6
    assert scene.count("custom_minimum_size = Vector2(235, 0)") >= 10
    assert scene.count("autowrap_mode = 2") >= 10
    assert "text_overrun_behavior = 3" not in scene
    assert "theme_override_font_sizes/font_size = 32" in scene
    assert "custom_minimum_size = Vector2(360, 56)" not in scene


def test_keybind_rows_remain_dense_and_complete() -> None:
    scene = _read(KEYBIND)
    script = _read(KEYBIND_SCRIPT)
    assert "theme_override_font_sizes/font_size = 26" in scene
    assert "custom_minimum_size = Vector2(0, 420)" in scene
    assert "row.custom_minimum_size = Vector2(0.0, 40.0)" in script
    assert "button.custom_minimum_size = Vector2(160.0, 38.0)" in script
    assert '&"weapon_flashlight": "KEYBIND_WEAPON_FLASHLIGHT"' in script
    assert "label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART" in script


def test_level_complete_report_is_balanced_and_not_full_height() -> None:
    scene = _read(COMPLETE)
    assert "offset_left = 580.0\noffset_top = 220.0\noffset_right = 1340.0\noffset_bottom = 930.0" in scene
    assert "theme_override_font_sizes/font_size = 36" in scene
    assert scene.count("custom_minimum_size = Vector2(0, 48)") == 3
    assert "theme_override_font_sizes/font_size = 48" not in scene
    assert "custom_minimum_size = Vector2(0, 60)" not in scene


def test_mission_terminal_uses_reasonable_three_line_button_height() -> None:
    scene = _read(TERMINAL)
    assert scene.count("custom_minimum_size = Vector2(0, 78)") == 3
    assert "custom_minimum_size = Vector2(620, 290)" in scene
    assert "custom_minimum_size = Vector2(250, 50)" in scene
    assert "custom_minimum_size = Vector2(0, 96)" not in scene
    assert "custom_minimum_size = Vector2(700, 340)" not in scene
    assert scene.count("autowrap_mode = 2") >= 10


def test_archive_surfaces_are_already_dense_and_scroll_based() -> None:
    archive = _read(ARCHIVE)
    weapon = _read(WEAPON_ARCHIVE)
    dashboard = _read(BASE_DASHBOARD)

    assert archive.count("custom_minimum_size = Vector2(0, 50)") >= 7
    assert "theme_override_font_sizes/font_size = 29" in archive
    assert '[node name="EntryScroll" type="ScrollContainer"' in archive
    assert '[node name="DetailBody" type="RichTextLabel"' in archive

    assert weapon.count("custom_minimum_size = Vector2(0, 44)") >= 5
    assert "theme_override_font_sizes/font_size = 22" in weapon
    assert '[node name="WeaponScroll" type="ScrollContainer"' in weapon
    assert '[node name="DetailBody" type="RichTextLabel"' in weapon

    assert "theme_override_font_sizes/font_size = 20" in dashboard
    assert "custom_minimum_size = Vector2(0, 44)" in dashboard
    assert "custom_minimum_size = Vector2(0, 40)" in dashboard
    assert "autowrap_mode = 2" in dashboard
