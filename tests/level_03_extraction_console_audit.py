from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCENE = ROOT / "scenes" / "levels" / "level_03_extraction_switch.tscn"
SCRIPT = ROOT / "scripts" / "levels" / "level_03_extraction_switch.gd"
BASE_SCENE = ROOT / "scenes" / "props" / "finish_switch.tscn"
BASE_SCRIPT = ROOT / "scripts" / "props" / "finish_switch.gd"
LEVEL01 = ROOT / "scenes" / "levels" / "level_01_first_fracture_content.tscn"
LEVEL02 = ROOT / "scenes" / "levels" / "level_02_ash_corridor_content.tscn"
LEVEL03 = ROOT / "scenes" / "levels" / "level_03_pressure_line_content.tscn"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_all_active_chapter_end_controls_use_shared_vex_console() -> None:
    base = _read(BASE_SCENE)
    scene = _read(SCENE)
    level01 = _read(LEVEL01)
    level02 = _read(LEVEL02)
    level03 = _read(LEVEL03)

    assert 'path="res://assets/world/finish_switch.png"' not in base
    assert "Sprite3D" not in base
    assert '[node name="VisualConsole" type="Node3D" parent="."]' in base

    for node_name in [
        "BackPlate",
        "LeftRail",
        "RightRail",
        "InnerFrame",
        "HeaderPlate",
        "ScreenFrame",
        "Screen",
        "LowerConsole",
        "StatusRotor",
        "ReadyCore",
        "LeverPivot",
        "ScreenGlow",
        "AccentGlow",
    ]:
        assert f'[node name="{node_name}"' in base

    assert 'path="res://scenes/props/finish_switch.tscn"' in level01
    assert 'path="res://scenes/props/finish_switch.tscn"' in level02
    assert 'path="res://scenes/levels/level_03_extraction_switch.tscn"' in level03
    assert 'path="res://scenes/props/finish_switch.tscn"' in scene


def test_finish_console_has_idle_motion_and_activation_motion() -> None:
    script = _read(BASE_SCRIPT)

    assert "func _process(delta: float)" in script
    assert "_status_rotor.rotation.z +=" in script
    assert "_ready_core.scale =" in script
    assert "_screen_glow.light_energy =" in script
    assert "func _play_activation_visual()" in script
    assert '"rotation_degrees:x", 48.0' in script
    assert '_status_rotor.rotation_degrees.z + 180.0' in script
    assert "LINK ACTIVE" in script
    assert "EXTRACTION CONFIRMED" in script


def test_level03_keeps_rescue_gate_without_duplicate_visual_console() -> None:
    scene = _read(SCENE)
    script = _read(SCRIPT)

    assert scene.startswith("[gd_scene load_steps=3 format=3]")
    assert 'script = ExtResource("2_script")' in scene
    assert "VisualConsole" not in scene
    assert "StaticBody3D" not in scene
    assert "CollisionShape3D" not in scene
    assert "finish_switch_visual" not in script
    assert "_set_visual_access_state(false)" in script
    assert "rescue_terminal_path" in script
    assert "_is_survivor_rescued" in script


def test_console_visual_language_is_detailed_and_not_placeholder_scale() -> None:
    base = _read(BASE_SCENE)

    assert "Material_dark" in base
    assert "Material_frame" in base
    assert "Material_screen" in base
    assert "Material_accent" in base
    assert "Material_ready" in base
    assert "Material_warning" in base
    assert base.count("emission_enabled = true") >= 4
    assert 'size = Vector3(1.62, 2.1, 0.4)' in base
    assert 'font_size = 30' in base
    assert 'font_size = 22' in base
    assert 'font_size = 18' in base
    assert 'font_size = 17' in base
