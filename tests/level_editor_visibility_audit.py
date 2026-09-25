from pathlib import Path
import re


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
    text = path.read_text(encoding="utf-8")
    # Godot 4.7 writes unique_id attributes into node headers on save; the
    # contracts below describe node identity, not editor bookkeeping ids.
    return re.sub(r" unique_id=\d+", "", text) if path.suffix == ".tscn" else text


def test_base_level_is_tool_compatible_without_changing_runtime_contract() -> None:
    base = _read(BASE_SCRIPT)
    assert base.startswith("@tool\nclass_name VexBaseLevel\nextends Node3D")
    ready_start = base.index("func _ready() -> void:")
    next_func = base.index("\n\nfunc _on_level_ready", ready_start)
    ready_block = base[ready_start:next_func]
    assert "if Engine.is_editor_hint():" in ready_block
    assert ready_block.index("return") < ready_block.index("SettingsManager.apply_brightness()")
    assert "GameState.begin_level" in ready_block
    assert "SettingsManager.apply_brightness()" in ready_block
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
    base = _read(BASE_SCRIPT)
    enter_block = base[base.index("func _enter_tree() -> void:"):base.index("func _ready() -> void:")]
    ready_block = base[base.index("func _ready() -> void:"):base.index("_sync_current_level_path()")]
    assert "if Engine.is_editor_hint():" in enter_block
    assert "_install_authored_structure()" in enter_block
    assert "if Engine.is_editor_hint():" in ready_block
    assert "_install_editor_structure_preview()" in ready_block
    assert ready_block.index("_install_editor_structure_preview()") < ready_block.index("return")
    for spec in LEVELS:
        script = _read(spec["script"])
        assert script.startswith("@tool\nextends VexBaseLevel")
        assert "func _get_structure_source_path() -> String:" in script
        assert "func _get_structure_node_names() -> Array:" in script
        # Level scripts no longer override the lifecycle; VexBaseLevel owns it.
        assert "func _enter_tree() -> void:" not in script


def test_runtime_door_configuration_is_never_executed_by_editor_preview() -> None:
    base = _read(BASE_SCRIPT)
    assert 'if node_name == &"Doors" and not Engine.is_editor_hint():' in base
    assert "_configure_authored_doors(structure_node)" in base
    for spec in LEVELS:
        script = _read(spec["script"])
        if spec["configures_doors"]:
            assert "func _configure_authored_doors(doors_root: Node) -> void:" in script
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


if __name__ == "__main__":
    # Betik olarak çalıştırıldığında (validate_local.ps1) test_ fonksiyonlarını
    # tanım sırasıyla çalıştır; pytest gerekmez.
    _audit_tests = [value for name, value in list(globals().items()) if name.startswith("test_") and callable(value)]
    for _audit_test in _audit_tests:
        _audit_test()
    print(f"{__file__.rsplit('/', 1)[-1]}: {len(_audit_tests)} test passed")
