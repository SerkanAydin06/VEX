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


def test_dashboard_controls_live_lighting_and_persistent_access() -> None:
    script = DASHBOARD_SCRIPT.read_text(encoding="utf-8")

    assert "BaseManager.LightingMode.STANDARD" in script
    assert "BaseManager.LightingMode.LOW_POWER" in script
    assert "BaseManager.LightingMode.EMERGENCY" in script
    assert 'GameState.save_current_safe_progress("base_dashboard_area")' in script
    assert 'GameState.save_current_safe_progress("base_dashboard_lighting")' in script
    assert "var previous_state := BaseManager.capture_state()" in script
    assert "BaseManager.restore_state(previous_state)" in script


def test_dashboard_reclaims_detail_space_only_for_base_section() -> None:
    script = DASHBOARD_SCRIPT.read_text(encoding="utf-8")

    assert 'find_child("BaseManagementTab", true, false)' in script
    assert 'find_child("IndexPanel", true, false)' in script
    assert 'find_child("DetailMargin", true, false)' in script
    assert "index_panel.visible = not active" in script
    assert "detail_margin.visible = not active" in script
    assert "visible = active" in script


def test_future_upgrade_backbone_is_visible_but_not_fake_gameplay() -> None:
    scene = DASHBOARD_SCENE.read_text(encoding="utf-8")
    script = DASHBOARD_SCRIPT.read_text(encoding="utf-8")

    for node in [
        "PowerGridUpgradeButton",
        "SecurityGridUpgradeButton",
        "ResearchInfrastructureUpgradeButton",
    ]:
        assert f'[node name="{node}" type="Button"' in scene

    assert 'button.disabled = true' in script
    assert '_t("YAKINDA", "FUTURE")' in script
    assert 'BaseManager.get_upgrade_level(upgrade_id)' in script


def test_dashboard_is_compact_and_wrap_safe_for_1280_layout() -> None:
    scene = DASHBOARD_SCENE.read_text(encoding="utf-8")

    assert "theme_override_font_sizes/font_size = 20" in scene
    assert scene.count("theme_override_font_sizes/font_size = 9") >= 12
    assert scene.count("autowrap_mode = 2") >= 15
    assert "custom_minimum_size = Vector2(0, 40)" in scene
    assert "custom_minimum_size = Vector2(0, 44)" in scene
