from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MISSION_SCRIPT = ROOT / "scripts/ui/terminal_menu.gd"
ARCHIVE_SCRIPT = ROOT / "scripts/ui/vex_archive_terminal.gd"
WEAPON_SCRIPT = ROOT / "scripts/ui/weapon_archive_terminal.gd"
HUB_SCRIPT = ROOT / "scripts/hub/hub_terminal.gd"
HUB_SCENE = ROOT / "scenes/hub/hub_terminal.tscn"


def test_terminal_ui_scenes_have_safe_editor_preview_mode() -> None:
    for path in [MISSION_SCRIPT, ARCHIVE_SCRIPT, WEAPON_SCRIPT]:
        script = path.read_text(encoding="utf-8")
        assert script.startswith("@tool\n")
        assert "if Engine.is_editor_hint():" in script
        assert "terminal_root.visible = get_tree().edited_scene_root == self" in script
        assert "terminal_root.visible = false" in script
        assert "if Engine.is_editor_hint() or not terminal_root.visible:" in script


def test_physical_terminal_uses_runtime_live_subviewport_content() -> None:
    script = HUB_SCRIPT.read_text(encoding="utf-8")

    assert not script.startswith("@tool\n")
    assert "WORLD_SCREEN_SIZE := Vector2i(640, 360)" in script
    assert "SubViewport.new()" in script
    assert "SubViewport.UPDATE_ALWAYS" in script
    assert "gui_disable_input = true" in script
    assert "screen_surface.texture = _world_screen_viewport.get_texture()" in script
    assert "_update_world_scan(delta)" in script

    for text in [
        "OPERASYON TERMİNALİ",
        "VEX ANA TERMİNALİ",
        "SİLAH ARŞİVİ",
        "YARATIKLAR // EVRENLER // KAYITLAR",
        "HASAR // RPM // MENZİL // SEKME",
    ]:
        assert text in script


def test_live_screen_does_not_change_authored_terminal_geometry() -> None:
    scene = HUB_SCENE.read_text(encoding="utf-8")

    assert "size = Vector3(1.3230512, 0.7523071, 0.02)" in scene
    assert "0, 1.2246144, -0.4089676)" in scene
    assert "-0.66510963, 0.8407265, -0.4089676)" in scene
    assert 'texture = ExtResource("2_screen")' in scene
