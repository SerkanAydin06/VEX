from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GAME_STATE = ROOT / "scripts" / "autoload" / "game_state.gd"
BASTION_SCENE = ROOT / "scenes" / "hub" / "bastion_7.tscn"
BASTION_SCRIPT = ROOT / "scripts" / "hub" / "bastion_7.gd"
HUB_TERMINAL = ROOT / "scripts" / "hub" / "hub_terminal.gd"
TERMINAL_MENU = ROOT / "scripts" / "ui" / "terminal_menu.gd"
LEVEL_COMPLETE = ROOT / "scripts" / "ui" / "level_complete.gd"
LEVEL01_CONTENT = ROOT / "scenes" / "levels" / "level_01_first_fracture_content.tscn"
LEVEL02_CONTENT = ROOT / "scenes" / "levels" / "level_02_ash_corridor_content.tscn"
LEVEL03_CONTENT = ROOT / "scenes" / "levels" / "level_03_pressure_line_content.tscn"
LEVEL03_FINISH = ROOT / "scripts" / "levels" / "level_03_extraction_switch.gd"
LEVEL03_RESCUE = ROOT / "scripts" / "props" / "survivor_rescue_terminal.gd"

MISSIONS = [
    ROOT / "resources" / "missions" / "vex01.tres",
    ROOT / "resources" / "missions" / "vex02.tres",
    ROOT / "resources" / "missions" / "vex03.tres",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_first_three_missions_form_strict_stage_order_in_bastion() -> None:
    bastion = _read(BASTION_SCENE)
    stages = []
    for index, mission_path in enumerate(MISSIONS, start=1):
        mission = _read(mission_path)
        assert f"campaign_stage = {index}" in mission
        assert f'scene_path = "res://scenes/levels/level_0{index}.tscn"' in mission
        stages.append(index)
    assert stages == [1, 2, 3]
    assert 'mission_definitions = Array[ExtResource("2_qiqtu")]([ExtResource("13_mission01"), ExtResource("14_mission02"), ExtResource("15_mission03")])' in bastion
    assert '[node name="DeploymentTerminal"' in bastion
    assert "terminal_mode = 1" in bastion


def test_all_three_level_finishes_return_to_bastion() -> None:
    for content_path in [LEVEL01_CONTENT, LEVEL02_CONTENT, LEVEL03_CONTENT]:
        content = _read(content_path)
        assert 'next_level_path = "res://scenes/hub/bastion_7.tscn"' in content


def test_completion_registers_campaign_stage_before_persisting_bastion_boundary() -> None:
    game_state = _read(GAME_STATE)
    start = game_state.index("func complete_level(")
    end = game_state.index("func has_pending_next_level", start)
    block = game_state[start:end]
    assert "_register_campaign_completion(current_scene)" in block
    assert 'save_campaign_progress(next_level_path, pending_player_restore_state, "level_complete")' in block
    assert block.index("_register_campaign_completion(current_scene)") < block.index("save_campaign_progress(")
    assert 'carry_state["keys"] = []' in block
    assert 'carry_state.erase("position")' in block
    assert 'carry_state.erase("rotation_y")' in block


def test_hub_deploy_writes_safe_mission_boundary_before_scene_change() -> None:
    game_state = _read(GAME_STATE)
    start = game_state.index("func deploy_selected_hub_mission()")
    end = game_state.index("func _register_campaign_completion", start)
    block = game_state[start:end]
    assert 'save_campaign_progress(current_level_path, carry_state, "mission_deploy")' in block
    assert "get_tree().change_scene_to_file(current_level_path)" in block
    assert block.index("save_campaign_progress(") < block.index("get_tree().change_scene_to_file")
    assert 'hub_selected_mission_path = ""' in block
    assert 'hub_selected_mission_label = ""' in block
    assert 'carry_state["keys"] = []' in block


def test_continue_uses_saved_safe_boundary_and_never_mid_level_checkpoint() -> None:
    game_state = _read(GAME_STATE)
    assert "const CHECKPOINTS_ENABLED := false" in game_state
    continue_start = game_state.index("func continue_game()")
    continue_end = game_state.index("func get_continue_failure_message", continue_start)
    continue_block = game_state[continue_start:continue_end]
    assert 'current_level_path = str(saved_run_state.get("current_level_path", LEVEL_01_PATH))' in continue_block
    assert 'pending_player_restore_state = (saved_run_state.get("resume_player_state", {}) as Dictionary).duplicate(true)' in continue_block
    assert "get_tree().change_scene_to_file(current_level_path)" in continue_block
    assert 'func save_checkpoint(_reason: String = "checkpoint") -> bool:' in game_state
    assert "# Kept for API compatibility only. Mid-level checkpoint saves are disabled." in game_state


def test_terminal_stage_logic_exposes_only_the_next_operation_for_deploy() -> None:
    terminal = _read(TERMINAL_MENU)
    assert "if GameState.campaign_stage >= definition.campaign_stage:" in terminal
    assert "if definition.campaign_stage == GameState.campaign_stage + 1:" in terminal
    assert "var is_active := selected_status == FacilityStatus.ACTIVE" in terminal
    assert "deploy_button.visible = _allow_deploy and is_active" in terminal
    assert "if _get_status(_selected_index) != FacilityStatus.ACTIVE:" in terminal
    # Once Chapter 3 is complete there is no active authored operation. The
    # terminal must enter its network-idle/all-cleared state, not preselect CH03.
    selection_start = terminal.index("func _get_initial_selection_index()")
    selection_end = terminal.index("func _get_mission_buttons", selection_start)
    selection_block = terminal[selection_start:selection_end]
    assert "return -1" in selection_block
    assert "return _mission_definitions.size() - 1" not in selection_block


def test_level03_evacuation_requires_selins_rescue_in_same_mission_run() -> None:
    content = _read(LEVEL03_CONTENT)
    finish = _read(LEVEL03_FINISH)
    rescue = _read(LEVEL03_RESCUE)
    assert 'rescue_terminal_path = NodePath("../../SurvivorRescue/SelinStabilizationUnit")' in content
    assert "if not _is_survivor_rescued():" in finish
    assert "return rescue_terminal != null and rescue_terminal.rescued" in finish
    assert "var rescued := false" in rescue
    assert "rescued = true" in rescue
    assert 'GameState.set_objective(objective_after_rescue)' in rescue


def test_bastion_return_feedback_matches_completed_stage_and_selins_presence() -> None:
    bastion_script = _read(BASTION_SCRIPT)
    bastion_scene = _read(BASTION_SCENE)
    assert 'if GameState.campaign_stage >= 3:' in bastion_script
    assert 'GameState.notify(tr("CH03_HUB_RETURN"))' in bastion_script
    assert 'elif GameState.campaign_stage >= 2:' in bastion_script
    assert 'GameState.notify(tr("CH02_HUB_RETURN"))' in bastion_script
    assert 'elif GameState.campaign_stage >= 1:' in bastion_script
    assert 'GameState.notify(tr("CH01_HUB_RETURN"))' in bastion_script
    assert '[node name="DrSelinErdem"' in bastion_scene
    assert "required_campaign_stage = 3" in bastion_scene
    assert 'dialogue_key = "HUB_SELIN_POST_CH03"' in bastion_scene


def test_bastion_world_terminal_uses_chapter_labels_not_retired_vex_numbers() -> None:
    terminal = _read(HUB_TERMINAL)
    assert 'line_1 = "BÖLÜM 01 // BÖLÜM 02 // BÖLÜM 03" if turkish else "CHAPTER 01 // CHAPTER 02 // CHAPTER 03"' in terminal
    assert 'line_1 = "VEX-01 // VEX-02 // VEX-03"' not in terminal


def test_level_complete_retries_failed_boundary_save_before_leaving_summary() -> None:
    complete = _read(LEVEL_COMPLETE)
    game_state = _read(GAME_STATE)
    assert "if GameState.last_campaign_save_failed:" in complete
    assert "if GameState.continue_to_next_level():" in complete
    continue_start = game_state.index("func continue_to_next_level()")
    continue_end = game_state.index("func pending_next_is_hub", continue_start)
    block = game_state[continue_start:continue_end]
    assert "if last_campaign_save_failed:" in block
    assert '"level_complete_retry"' in block
    assert "return false" in block


def test_bastion_safe_zone_autosaves_base_and_loadout_changes() -> None:
    bastion = _read(BASTION_SCRIPT)
    assert "var _safe_save_queued := false" in bastion
    assert "BaseManager.base_state_changed.connect(_on_base_state_changed)" in bastion
    assert "GameState.weapon_changed.connect(_on_hub_weapon_changed)" in bastion
    assert "GameState.ammo_changed.connect(_on_hub_ammo_changed)" in bastion
    assert "GameState.player_stats_changed.connect(_on_hub_player_stats_changed)" in bastion
    assert 'call_deferred("_flush_hub_safe_save")' in bastion
    assert 'GameState.save_current_safe_progress("bastion_state_changed")' in bastion
    assert 'call_deferred("_save_hub_safe_point", "bastion_arrival")' in bastion
