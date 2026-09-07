from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "project.godot"
BASE_MANAGER = ROOT / "scripts/autoload/base_manager.gd"
GAME_STATE = ROOT / "scripts/autoload/game_state.gd"
BASTION_SCRIPT = ROOT / "scripts/hub/bastion_7.gd"
BASTION_SCENE = ROOT / "scenes/hub/bastion_7.tscn"
DOOR_SCRIPT = ROOT / "scripts/props/door.gd"
ARCHIVE_SCRIPT = ROOT / "scripts/ui/vex_archive_terminal.gd"
ARCHIVE_SCENE = ROOT / "scenes/ui/vex_archive_terminal.tscn"


def test_base_manager_is_campaign_state_autoload() -> None:
    project = PROJECT.read_text(encoding="utf-8")
    manager = BASE_MANAGER.read_text(encoding="utf-8")
    game_state = GAME_STATE.read_text(encoding="utf-8")

    assert 'BaseManager="*res://scripts/autoload/base_manager.gd"' in project
    assert project.index('GameState="*res://scripts/autoload/game_state.gd"') < project.index(
        'BaseManager="*res://scripts/autoload/base_manager.gd"'
    )
    assert "func capture_state() -> Dictionary:" in manager
    assert "func restore_state(state: Dictionary) -> void:" in manager
    assert "func reset_campaign_state(" in manager
    assert "SAVE_VERSION := 6" in game_state
    assert '"base_state": BaseManager.capture_state()' in game_state
    assert 'BaseManager.restore_state(saved_run_state.get("base_state", {}) as Dictionary)' in game_state
    assert "BaseManager.reset_campaign_state()" in game_state
    assert "if version < 6:" in game_state


def test_base_manager_defines_real_bastion_restricted_areas() -> None:
    manager = BASE_MANAGER.read_text(encoding="utf-8")
    bastion_scene = BASTION_SCENE.read_text(encoding="utf-8")

    expected = {
        "firing_range": ("FiringRangeDoor", 0),
        "research_lab": ("ResearchDoor", 1),
        "weapon_workshop": ("WorkshopDoor", 2),
        "engineering_bay": ("EngineeringDoor", 2),
    }
    for area_id, (door_name, required_stage) in expected.items():
        assert f'"id": &"{area_id}"' in manager
        assert f'"door_node": &"{door_name}"' in manager
        assert f'"required_stage": {required_stage}' in manager
        assert f'[node name="{door_name}" parent="Doors"' in bastion_scene

    assert "func unlock_area(area_id: StringName, campaign_stage: int) -> bool:" in manager
    assert "area_access_changed.emit(area_id, true)" in manager


def test_bastion_applies_access_without_replacing_authored_doors() -> None:
    bastion = BASTION_SCRIPT.read_text(encoding="utf-8")
    door = DOOR_SCRIPT.read_text(encoding="utf-8")

    assert "@onready var doors: Node3D = $Doors" in bastion
    assert "BaseManager.area_access_changed.connect(_on_base_area_access_changed)" in bastion
    assert 'door.call("set_facility_access_unlocked", unlocked)' in bastion
    assert "func set_facility_access_unlocked(unlocked: bool) -> void:" in door
    assert "permanently_locked = not unlocked" in door
    assert "_emit_lock_state()" in door


def test_lighting_profiles_preserve_scene_authored_fixture_defaults() -> None:
    manager = BASE_MANAGER.read_text(encoding="utf-8")
    bastion = BASTION_SCRIPT.read_text(encoding="utf-8")

    for mode in ["STANDARD", "LOW_POWER", "EMERGENCY"]:
        assert mode in manager
    assert '"energy_multiplier": 1.0' in manager
    assert '"energy_multiplier": 0.48' in manager
    assert '"energy_multiplier": 0.28' in manager

    assert "_cache_room_light_defaults()" in bastion
    assert '"energy": fixture.light_energy' in bastion
    assert '"color": fixture.light_color' in bastion
    assert '"fixture_modulate": fixture.fixture_modulate' in bastion
    assert "fixture.light_energy = float(defaults.get(" in bastion
    assert "* energy_multiplier" in bastion
    assert "authored_color.lerp(tint, tint_strength)" in bastion


def test_main_terminal_exposes_base_management_actions_and_future_upgrades() -> None:
    manager = BASE_MANAGER.read_text(encoding="utf-8")
    script = ARCHIVE_SCRIPT.read_text(encoding="utf-8")
    scene = ARCHIVE_SCENE.read_text(encoding="utf-8")

    assert "BASE_MANAGEMENT," in script
    assert '[node name="BaseManagementTab" type="Button"' in scene
    assert '[node name="BaseActionRow" type="HBoxContainer"' in scene
    assert '[node name="BaseActionButton" type="Button"' in scene
    assert "BaseManager.unlock_area(area_id, GameState.campaign_stage)" in script
    assert "BaseManager.set_lighting_mode(" in script
    assert 'GameState.save_current_safe_progress("base_management")' in script

    for upgrade_id in ["power_grid", "security_grid", "research_infrastructure"]:
        assert f'"id": &"{upgrade_id}"' in manager
    assert "func set_upgrade_level(upgrade_id: StringName, level: int) -> bool:" in manager
    assert '"GELİŞTİRME YAKINDA"' in script
