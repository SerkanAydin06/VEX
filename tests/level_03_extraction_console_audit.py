from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCENE = ROOT / "scenes" / "levels" / "level_03_extraction_switch.tscn"
SCRIPT = ROOT / "scripts" / "levels" / "level_03_extraction_switch.gd"
BASE_SCENE = ROOT / "scenes" / "props" / "finish_switch.tscn"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_level03_uses_authored_vex_console_instead_of_legacy_sprite_art() -> None:
    scene = _read(SCENE)
    script = _read(SCRIPT)
    base = _read(BASE_SCENE)

    # Shared finish-switch keeps the collision/interaction contract and legacy
    # sprite for other levels; Level 3 replaces only its rendered presentation.
    assert 'path="res://scenes/props/finish_switch.tscn"' in scene
    assert 'path="res://assets/world/finish_switch.png"' in base
    assert 'finish_switch_visual.visible = false' in script

    assert '[node name="VisualConsole" type="Node3D" parent="."]' in scene
    for node_name in [
        "BackPlate",
        "LeftRib",
        "RightRib",
        "InnerFrame",
        "ScreenBezel",
        "Screen",
        "LowerConsole",
        "WarningStrip",
        "ControlRed",
        "ControlAmber",
        "ControlReady",
        "ScreenGlow",
        "WarningGlow",
    ]:
        assert f'[node name="{node_name}"' in scene

    # New console is scene/Inspector authoritative and does not add a second
    # collision body that could interfere with the inherited interaction ray.
    assert "CollisionShape3D" not in scene
    assert "StaticBody3D" not in scene


def test_console_visual_language_matches_vex_industrial_control_theme() -> None:
    scene = _read(SCENE)

    assert 'text = "VEX // EVAC CONTROL"' in scene
    assert 'text = "PRESSURE LINE // LINK NODE"' in scene
    assert 'text = "AUTHORIZED EXTRACTION CHANNEL"' in scene
    assert 'text = "MANUAL LINK // STANDBY"' in scene
    assert "Material_panel_dark" in scene
    assert "Material_frame" in scene
    assert "Material_screen" in scene
    assert "Material_warning" in scene
    assert "Material_ready" in scene
    assert scene.count("emission_enabled = true") >= 4
