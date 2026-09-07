from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_SCENE = ROOT / "scenes/ui/vex_archive_terminal.tscn"
DASHBOARD_SCENE = ROOT / "scenes/ui/base_management_dashboard.tscn"
DASHBOARD_SCRIPT = ROOT / "scripts/ui/base_management_dashboard.gd"
BASE_MANAGER = ROOT / "scripts/autoload/base_manager.gd"


def test_main_terminal_instances_scene_authored_base_dashboard() -> None:
    archive = ARCHIVE_SCENE.read_text(encoding="utf-8")
    dashboard = DASHBOARD_SCENE.read_text(encoding="utf-8")

    assert 'path="res://scenes/ui/base_management_dashboard.tscn"' in archive
    assert '[node name="BaseManagementDashboard" parent="ArchiveRoot/ScreenShell/Margin/VBox/Body/DetailPanel"' in archive
    assert 'script = ExtResource("1_script")' in dashboard
    assert '[node name="FacilityGrid" type="GridContainer"' in dashboard
    assert "columns = 3" in dashboard


def test_facility_schematic_matches_bastion_management_areas() -> None:
    scene = DASHBOARD_SCENE.read_text(encoding="utf-8")
    script = DASHBOARD_SCRIPT.read_text(encoding="utf-8")
    manager = BASE_MANAGER.read_text(encoding="utf-8")

    for node in [
        "FiringRangeAreaButton",
        "ArmoryAreaButton",
        "ResearchAreaButton",
        "CommandAreaButton",
        "WorkshopAreaButton",
        "SouthCorridorAreaButton",
        "EngineeringAreaButton",
        "OperatorAreaButton",
    ]:
        assert f'[node name="{node}" type="Button"' in scene

    for area_id in ["firing_range", "research_lab", "weapon_workshop", "engineering_bay"]:
        assert f'&"{area_id}"' in script
        assert f'"id": &"{area_id}"' in manager

    firing_start = manager.index('"id": &"firing_range"')
    firing_block = manager[firing_start:firing_start + 500]
    assert '"required_stage": 1' in firing_block


def test_dashboard_has_four_campaign_gated_lighting_tiers() -> None:
    scene = DASHBOARD_SCENE.read_text(encoding="utf-8")
    script = DASHBOARD_SCRIPT.read_text(encoding="utf-8")
    manager = BASE_MANAGER.read_text(encoding="utf-8")

    for node in ["Lighting25Button", "Lighting50Button", "Lighting75Button", "Lighting100Button"]:
        assert f'[node name="{node}" type="Button"' in scene

    for mode in ["LEVEL_25", "LEVEL_50", "LEVEL_75", "LEVEL_100"]:
        assert f"LightingMode.{mode}" in script
        assert mode in manager

    for multiplier in ["0.25", "0.50", "0.75", "1.0"]:
        assert f'"energy_multiplier": {multiplier}' in manager

    assert manager.count('"required_stage": 0') >= 1
    assert manager.count('"required_stage": 1') >= 3
    assert manager.count('"required_stage": 2') >= 3
    assert manager.count('"required_stage": 3') >= 2
    assert "func can_use_lighting_mode(mode: int, campaign_stage: int) -> bool:" in manager
    assert "BaseManager.can_use_lighting_mode(mode, GameState.campaign_stage)" in script
    assert "BaseManager.set_lighting_mode(mode, GameState.campaign_stage)" in script


def test_dashboard_persists_access_and_lighting_with_rollback() -> None:
    script = DASHBOARD_SCRIPT.read_text(encoding="utf-8")

    assert 'GameState.save_current_safe_progress("base_dashboard_area")' in script
    assert 'GameState.save_current_safe_progress("base_dashboard_lighting")' in script
    assert "var previous_state := BaseManager.capture_state()" in script
    assert "BaseManager.restore_state(previous_state)" in script


def test_dashboard_does_not_shadow_node_ready_signal() -> None:
    script = DASHBOARD_SCRIPT.read_text(encoding="utf-8")

    assert "var ready :=" not in script
    assert "var activation_available :=" in script


def test_dashboard_reclaims_detail_space_only_for_base_section() -> None:
    script = DASHBOARD_SCRIPT.read_text(encoding="utf-8")

    assert 'find_child("BaseManagementTab", true, false)' in script
    assert 'find_child("IndexPanel", true, false)' in script
    assert 'find_child("DetailMargin", true, false)' in script
    assert "index_panel.visible = not dashboard_active" in script
    assert "detail_margin.visible = not dashboard_active" in script
    assert "visible = dashboard_active" in script


def test_future_upgrade_backbone_is_progression_gated_but_not_fake_gameplay() -> None:
    scene = DASHBOARD_SCENE.read_text(encoding="utf-8")
    script = DASHBOARD_SCRIPT.read_text(encoding="utf-8")
    manager = BASE_MANAGER.read_text(encoding="utf-8")

    for node in [
        "PowerGridUpgradeButton",
        "SecurityGridUpgradeButton",
        "ResearchInfrastructureUpgradeButton",
    ]:
        assert f'[node name="{node}" type="Button"' in scene

    assert '"required_stage": 1' in manager
    assert '"required_stage": 2' in manager
    assert '"required_stage": 3' in manager
    assert "BaseManager.is_upgrade_available(upgrade_id, GameState.campaign_stage)" in script
    assert 'button.disabled = true' in script
    assert '_t("YAKINDA", "FUTURE")' in script
    assert 'BaseManager.get_upgrade_level(upgrade_id)' in script


def test_dashboard_is_compact_and_wrap_safe_for_1280_layout() -> None:
    scene = DASHBOARD_SCENE.read_text(encoding="utf-8")

    assert "theme_override_font_sizes/font_size = 20" in scene
    assert scene.count("theme_override_font_sizes/font_size = 9") >= 11
    assert scene.count("theme_override_font_sizes/font_size = 8") >= 5
    assert scene.count("autowrap_mode = 2") >= 16
    assert "custom_minimum_size = Vector2(0, 40)" in scene
    assert "custom_minimum_size = Vector2(0, 44)" in scene
