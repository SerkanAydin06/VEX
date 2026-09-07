from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/ui/terminal_menu.gd"
SCENE = ROOT / "scenes/ui/terminal_menu.tscn"
BASTION = ROOT / "scenes/hub/bastion_7.tscn"


def test_operations_terminal_uses_single_deploy_action_with_confirmation() -> None:
    script = SCRIPT.read_text(encoding="utf-8")
    scene = SCENE.read_text(encoding="utf-8")

    assert "SelectButton" not in scene
    assert "select_button" not in script
    assert "func _select_current_operation" not in script

    assert 'deploy_button.pressed.connect(_request_deploy_current_operation)' in script
    assert "func _request_deploy_current_operation" in script
    assert "func _confirm_deploy_current_operation" in script
    assert "confirmation_overlay.visible = true" in script
    assert "GameState.select_hub_mission(definition.scene_path, definition.display_name)" in script
    assert "GameState.deploy_selected_hub_mission()" in script

    request_pos = script.index("func _request_deploy_current_operation")
    confirm_pos = script.index("func _confirm_deploy_current_operation")
    first_persist_pos = script.index(
        "GameState.select_hub_mission(definition.scene_path, definition.display_name)"
    )
    assert request_pos < confirm_pos <= first_persist_pos


def test_terminal_layout_is_viewport_relative_and_has_confirmation_layer() -> None:
    scene = SCENE.read_text(encoding="utf-8")

    assert '[node name="ScreenShell" type="PanelContainer" parent="TerminalRoot"]' in scene
    assert "anchor_left = 0.045" in scene
    assert "anchor_top = 0.06" in scene
    assert "anchor_right = 0.955" in scene
    assert "anchor_bottom = 0.94" in scene
    assert '[node name="Body" type="HBoxContainer"' in scene
    assert '[node name="ConfirmationOverlay" type="Control" parent="TerminalRoot"]' in scene
    assert 'unique_name_in_owner = true\nvisible = false' in scene

    # The old fixed 1920x1080 console framing should not return.
    assert "offset_left = 226.0" not in scene
    assert "offset_right = 1694.0" not in scene
    assert "automap_console_frame.png" not in scene


def test_bastion_keeps_spawn_terminal_as_deployment_and_center_terminal_separate() -> None:
    bastion = BASTION.read_text(encoding="utf-8")

    deployment = bastion.index('[node name="DeploymentTerminal"')
    center = bastion.index('[node name="CommandStatusTerminal"')
    assert deployment < center

    deployment_block = bastion[deployment:center]
    assert "terminal_mode = 1" in deployment_block
    assert 'display_name = "OPERASYON TERMİNALİ"' in deployment_block

    # CommandStatusTerminal intentionally has no terminal_mode override, so the
    # hub-terminal scene default INFORMATION mode remains authoritative.
    center_block = bastion[center:center + 500]
    assert "terminal_mode =" not in center_block
