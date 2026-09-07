from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BASE_SCRIPT = ROOT / "scripts" / "levels" / "base_level.gd"

LEVELS = [
    {
        "scene": ROOT / "scenes" / "levels" / "level_01.tscn",
        "script": ROOT / "scripts" / "levels" / "level_01.gd",
        "environment_path": "res://scenes/levels/level_01_environment_story.tscn",
        "content_path": "res://scenes/levels/level_01_first_fracture_content.tscn",
        "environment_node": "Level01EnvironmentStory",
        "content_node": "Level01FirstFractureContent",
        "configures_doors": True,
    },
    {
        "scene": ROOT / "scenes" / "levels" / "level_02.tscn",
        "script": ROOT / "scripts" / "levels" / "level_02.gd",
        "environment_path": "res://scenes/levels/level_02_environment_story.tscn",
        "content_path": "res://scenes/levels/level_02_ash_corridor_content.tscn",
        "environment_node": "Level02EnvironmentStory",
        "content_node": "Level02AshCorridorContent",
        "configures_doors": True,
    },
    {
        "scene": ROOT / "scenes" / "levels" / "level_03.tscn",
        "script": ROOT / "scripts" / "levels" / "level_03.gd",
        "environment_path": "res://scenes/levels/level_03_environment_story.tscn",
        "content_path": "res://scenes/levels/level_03_pressure_line_content.tscn",
        "environment_node": "Level03EnvironmentStory",
        "content_node": "Level03PressureLineContent",
        "configures_doors": True,
    },
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_base_level_is_tool_compatible_without_changing_runtime_contract() -> None:
    base = _read(BASE_SCRIPT)
    assert base.startswith("@tool\nclass_name VexBaseLevel\nextends Node3D")
    assert "GameState.begin_level" in base
    assert "SettingsManager.apply_brightness()" in base
    assert "func get_campaign_completion_stage() -> int:" in base


def test_main_level_scenes_expose_editable_canonical_layers() -> None:
    for spec in LEVELS:
        scene = _read(spec["scene"])
        assert spec["environment_path"] in scene
        assert spec["content_path"] in scene
        assert f'[node name="{spec["environment_node"]}" parent="." instance=' in scene
        assert f'[node name="{spec["content_node"]}" parent="." instance=' in scene
        assert f'[editable path="{spec["environment_node"]}"]' in scene
        assert f'[editable path="{spec["content_node"]}"]' in scene


def test_level_scripts_preview_structure_in_editor_without_running_base_level() -> None:
    for spec in LEVELS:
        script = _read(spec["script"])
        assert script.startswith("@tool\nextends VexBaseLevel")
        assert "func _enter_tree() -> void:" in script
        assert "func _ready() -> void:" in script
        enter_start = script.index("func _enter_tree() -> void:")
        ready_start = script.index("func _ready() -> void:")
        preview_start = script.index("func _install_editor_structure_preview")
        enter_block = script[enter_start:ready_start]
        ready_block = script[ready_start:preview_start]
        assert "if Engine.is_editor_hint():" in enter_block
        assert "_install_authored_structure()" in enter_block
        assert "if Engine.is_editor_hint():" in ready_block
        assert "_install_editor_structure_preview()" in ready_block
        assert "super._ready()" in ready_block
        assert ready_block.index("return") < ready_block.index("super._ready()")


def test_runtime_door_configuration_is_never_executed_by_editor_preview() -> None:
    for spec in LEVELS:
        script = _read(spec["script"])
        if spec["configures_doors"]:
            assert 'if node_name == &"Doors" and not Engine.is_editor_hint():' in script
            assert "_configure_authored_doors(structure_node)" in script
        else:
            assert "_configure_authored_doors" not in script


def test_structure_filter_never_includes_legacy_gameplay_roots() -> None:
    forbidden = ['&"Enemies"', '&"Pickups"', '&"Triggers"', '&"Objectives"', '&"Secrets"', '&"LoreTerminals"']
    for spec in LEVELS:
        script = _read(spec["script"])
        start = script.index("const STRUCTURE_NODE_NAMES")
        next_const = script.find("\nconst ", start + 1)
        next_var = script.find("\nvar ", start + 1)
        candidates = [value for value in [next_const, next_var] if value >= 0]
        end = min(candidates) if candidates else len(script)
        block = script[start:end]
        for name in forbidden:
            assert name not in block
