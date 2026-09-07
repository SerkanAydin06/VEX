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

    # Shared finish-switch keeps the interaction body and legacy sprite for other
    # levels; Level 3 replaces its rendered presentation only for this instance.
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

    # Do not add a competing StaticBody3D. Instead override the inherited
    # CollisionShape3D so aiming at the tall authored console still hits the
    # interaction body.
    assert "StaticBody3D" not in scene
    assert '[sub_resource type="BoxShape3D" id="Shape_console_interaction"]' in scene
    assert 'size = Vector3(1.62, 2.08, 0.34)' in scene
    assert '[node name="CollisionShape3D" parent="PanelBody"]' in scene
    assert 'position = Vector3(0, 1.06, 0.12)' in scene
    assert 'shape = SubResource("Shape_console_interaction")' in scene
    assert scene.startswith("[gd_scene load_steps=23 format=3]")


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
