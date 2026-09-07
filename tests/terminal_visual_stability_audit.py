from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_SCRIPT = ROOT / "scripts/ui/vex_archive_terminal.gd"
ARCHIVE_SCENE = ROOT / "scenes/ui/vex_archive_terminal.tscn"
HUB_SCRIPT = ROOT / "scripts/hub/hub_terminal.gd"


def test_archive_section_switch_casts_int_back_to_enum() -> None:
    script = ARCHIVE_SCRIPT.read_text(encoding="utf-8")
    assert "func _select_section(section: int) -> void:" in script
    assert "_current_section = section as Section" in script


def test_archive_columns_fit_1280_and_dynamic_labels_wrap() -> None:
    scene = ARCHIVE_SCENE.read_text(encoding="utf-8")
    script = ARCHIVE_SCRIPT.read_text(encoding="utf-8")

    assert "custom_minimum_size = Vector2(220, 0)" in scene
    assert "custom_minimum_size = Vector2(340, 0)" in scene
    assert scene.count("size_flags_horizontal = 0") >= 2
    assert '[node name="IndexPanel" type="PanelContainer"' in scene
    assert "custom_minimum_size = Vector2(452, 0)" not in scene
    assert "custom_minimum_size = Vector2(240, 230)" in scene
    assert "custom_minimum_size = Vector2(330, 0)" in scene

    assert "button.custom_minimum_size = Vector2(0.0, 68.0)" in script
    assert "button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART" in script
    assert "button.clip_text = false" in script
    assert "button.size_flags_horizontal = Control.SIZE_EXPAND_FILL" in script
    assert '"GERÇEKLİK %02d\\n// SINIFLANDIRILMAMIŞ"' in script
    assert '"REALITY %02d\\n// UNCLASSIFIED"' in script


def test_archive_detail_labels_wrap_instead_of_being_clipped() -> None:
    scene = ARCHIVE_SCENE.read_text(encoding="utf-8")

    for node_name in ("SectionTitle", "DetailEyebrow", "DetailTitle", "DetailMeta", "ClassificationLabel"):
        node_header = f'[node name="{node_name}"'
        assert node_header in scene

    assert scene.count("autowrap_mode = 2") >= 7
    assert "max_lines_visible =" not in scene
    assert "clip_text = true" not in scene


def test_archive_header_uses_compact_two_line_summary() -> None:
    scene = ARCHIVE_SCENE.read_text(encoding="utf-8")
    script = ARCHIVE_SCRIPT.read_text(encoding="utf-8")

    assert "custom_minimum_size = Vector2(140, 58)" in scene
    assert "custom_minimum_size = Vector2(330, 0)" in scene
    assert '"XENOARŞİV %d / %d  //  EVREN %d / %d\\nAĞ AŞAMASI %02d"' in script
    assert '"XENOARCHIVE %d / %d  //  REALITIES %d / %d\\nNETWORK STAGE %02d"' in script


def test_physical_terminal_screen_has_subtle_runtime_signal_motion() -> None:
    script = HUB_SCRIPT.read_text(encoding="utf-8")

    assert '@export var screen_motion_enabled := true' in script
    assert "func _process(delta: float) -> void:" in script
    assert "var signal :=" not in script
    assert "var signal_amount :=" in script
    assert "screen_surface.position = _screen_base_position + Vector3" in script
    assert "screen_surface.pixel_size = _screen_base_pixel_size * scale_pulse" in script
    assert "screen_surface.modulate = Color(brightness, cyan_bias, 1.0, 1.0)" in script
