from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "project.godot"
MANAGER = ROOT / "scripts/autoload/archive_manager.gd"
DATABASE = ROOT / "scripts/data/vex_archive_database.gd"
ARCHIVE_SCRIPT = ROOT / "scripts/ui/vex_archive_terminal.gd"
ARCHIVE_SCENE = ROOT / "scenes/ui/vex_archive_terminal.tscn"
HUB_SCRIPT = ROOT / "scripts/hub/hub_terminal.gd"
HUB_SCENE = ROOT / "scenes/hub/hub_terminal.tscn"
BASTION = ROOT / "scenes/hub/bastion_7.tscn"


ACTIVE_ENEMIES = {
    "basalt_juggernaut",
    "cinderhound",
    "cinder_spitter",
    "furnice_carrier",
    "crucible_warden",
    "ravager",
    "briar_skulker",
    "gorehorn",
    "spore_matriarch",
    "vaskari_raptor",
    "vaskari_ravager",
    "coil_lancer",
    "vaskari_bulwark",
    "venom_marshall",
    "veilmaw",
    "husk_leech",
    "voidweaver",
    "rift_reaver",
}


def test_archive_manager_is_autoloaded_after_game_state_and_tracks_first_kill() -> None:
    project = PROJECT.read_text(encoding="utf-8")
    manager = MANAGER.read_text(encoding="utf-8")

    game_state_pos = project.index('GameState="*res://scripts/autoload/game_state.gd"')
    archive_pos = project.index('ArchiveManager="*res://scripts/autoload/archive_manager.gd"')
    assert game_state_pos < archive_pos

    assert "GameState.enemy_defeated.connect(_on_enemy_defeated)" in manager
    assert 'SAVE_PATH := "user://vex_archive.cfg"' in manager
    assert "func discover_enemy(enemy_id: StringName) -> bool" in manager
    assert "discovered_enemy_ids.append(enemy_id)" in manager
    assert "_save_archive()" in manager


def test_archive_database_matches_active_roster_and_five_realities() -> None:
    database = DATABASE.read_text(encoding="utf-8")

    assert database.count('"asset_folder":') == 18
    assert database.count('"enemy_ids":') == 5

    for enemy_id in ACTIVE_ENEMIES:
        assert f'"id": &"{enemy_id}"' in database

    for universe_id in ["korvath", "thornwild", "vaskari", "nhal", "aether"]:
        assert f'"id": &"{universe_id}"' in database

    # Planned creatures must not leak into the active archive roster.
    for planned in ["MURK STALKER", "SHADE ANCHOR", "RIFT SPINDLE", "PARALLAX DRONE", "LOOM HERALD"]:
        assert planned not in database


def test_main_terminal_has_six_gameplay_relevant_sections_and_real_sprite_previews() -> None:
    script = ARCHIVE_SCRIPT.read_text(encoding="utf-8")
    scene = ARCHIVE_SCENE.read_text(encoding="utf-8")

    for node in [
        "CreaturesTab",
        "UniversesTab",
        "RecordsTab",
        "ThreatTab",
        "RiftTab",
        "ProtocolsTab",
    ]:
        assert f'[node name="{node}" type="Button"' in scene

    assert "JSON.parse_string(FileAccess.get_file_as_string(manifest_path))" in script
    assert "AtlasTexture.new()" in script
    assert "ArchiveDB.enemy_sheet_path(entry)" in script
    assert "ArchiveManager.is_enemy_discovered" in script
    assert "GameState.campaign_stage" in script
    assert "_build_extraction_matrix" in script


def test_information_terminal_routes_to_archive_without_changing_deployment_terminal() -> None:
    hub_script = HUB_SCRIPT.read_text(encoding="utf-8")
    hub_scene = HUB_SCENE.read_text(encoding="utf-8")
    bastion = BASTION.read_text(encoding="utf-8")

    assert "if terminal_mode == TerminalMode.INFORMATION:" in hub_script
    assert "archive_terminal.open_terminal()" in hub_script
    assert 'path="res://scenes/ui/vex_archive_terminal.tscn"' in hub_scene
    assert '[node name="ArchiveTerminal" parent="." instance=ExtResource("6_archive")]' in hub_scene

    deployment = bastion.index('[node name="DeploymentTerminal"')
    center = bastion.index('[node name="CommandStatusTerminal"')
    deployment_block = bastion[deployment:center]
    center_block = bastion[center:center + 500]

    assert "terminal_mode = 1" in deployment_block
    assert "terminal_mode =" not in center_block
    assert 'return "VEX ANA TERMİNALİ"' in hub_script


def test_archive_ui_is_viewport_relative_and_terminal_colliders_remain_canonical() -> None:
    scene = ARCHIVE_SCENE.read_text(encoding="utf-8")
    hub_scene = HUB_SCENE.read_text(encoding="utf-8")

    assert "anchor_left = 0.035" in scene
    assert "anchor_top = 0.045" in scene
    assert "anchor_right = 0.965" in scene
    assert "anchor_bottom = 0.955" in scene
    assert '[node name="Body" type="HBoxContainer"' in scene

    assert "size = Vector3(1.3230512, 0.7523071, 0.02)" in hub_scene
    assert "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2246144, -0.4089676)" in hub_scene
    assert "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.66510963, 0.8407265, -0.4089676)" in hub_scene
