from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLAYER_SCENE = ROOT / "scenes/player/player.tscn"
BASTION_SCENE = ROOT / "scenes/hub/bastion_7.tscn"
HUB_TERMINAL_SCENE = ROOT / "scenes/hub/hub_terminal.tscn"
HUB_TERMINAL_SCRIPT = ROOT / "scripts/hub/hub_terminal.gd"
ARCHIVE_SCENE = ROOT / "scenes/ui/weapon_archive_terminal.tscn"
ARCHIVE_SCRIPT = ROOT / "scripts/ui/weapon_archive_terminal.gd"


def test_weapon_archive_reads_live_player_weapon_definitions() -> None:
    player_scene = PLAYER_SCENE.read_text(encoding="utf-8")
    script = ARCHIVE_SCRIPT.read_text(encoding="utf-8")

    active_ids = ["p01", "p07", "p14", "p20", "sg04", "sg09", "sg15", "vx47", "mp90"]
    for weapon_id in active_ids:
        assert f'resources/weapons/{weapon_id}.tres' in player_scene
    assert "_weapon_controller.weapon_definitions" in script
    assert "WeaponDefinition" in script


def test_weapon_archive_exposes_detailed_live_stats_and_upgrades() -> None:
    script = ARCHIVE_SCRIPT.read_text(encoding="utf-8")

    required_live_fields = [
        "damage_per_pellet",
        "pellet_count",
        "fire_interval",
        "magazine_size",
        "reserve_ammo_capacity",
        "reload_duration",
        "maximum_range",
        "spread_degrees",
        "ads_spread_multiplier",
        "headshot_multiplier",
        "recoil_vertical_degrees",
        "recoil_horizontal_degrees",
        "penetration_power",
        "gunshot_noise_multiplier",
        "supports_flashlight",
        "uses_heat",
    ]
    for field in required_live_fields:
        assert f"definition.{field}" in script

    assert "VexWeaponUpgradeCatalog.get_modifiers" in script
    assert "get_weapon_upgrade_level" in script
    assert "VexWeaponUpgradeCatalog.get_track" in script
    assert "theoretical_dps" in script


def test_weapon_archive_categories_and_layout_fit_compact_viewports() -> None:
    scene = ARCHIVE_SCENE.read_text(encoding="utf-8")
    script = ARCHIVE_SCRIPT.read_text(encoding="utf-8")

    for node_name in ["SidearmTab", "ShotgunTab", "RifleTab", "SmgTab", "LaserTab"]:
        assert f'[node name="{node_name}"' in scene

    # The shell uses nearly the full viewport and all three columns leave
    # substantially more room for the detail pane at 1280x720.
    assert "anchor_left = 0.02" in scene
    assert "anchor_top = 0.025" in scene
    assert "anchor_right = 0.98" in scene
    assert "anchor_bottom = 0.975" in scene
    assert "custom_minimum_size = Vector2(160, 0)" in scene
    assert "custom_minimum_size = Vector2(245, 0)" in scene
    assert "custom_minimum_size = Vector2(180, 170)" in scene
    assert "custom_minimum_size = Vector2(0, 170)" in scene

    # Long labels wrap instead of forcing their parent wider.
    assert 'text = "SİLAH ARŞİV TERMİNALİ"\nautowrap_mode = 2' in scene
    assert 'text = "ARMORY RECORD STATUS"\nhorizontal_alignment = 2\nautowrap_mode = 2' in scene
    assert "theme_override_font_sizes/normal_font_size = 12" in scene
    assert "autowrap_mode = TextServer.AUTOWRAP_WORD_SMART" in script


def test_weapon_archive_vertical_budget_is_compact() -> None:
    scene = ARCHIVE_SCENE.read_text(encoding="utf-8")

    assert "custom_minimum_size = Vector2(0, 54)" in scene
    assert scene.count("custom_minimum_size = Vector2(0, 44)") == 5
    assert "custom_minimum_size = Vector2(0, 40)" in scene
    assert "custom_minimum_size = Vector2(160, 40)" in scene
    assert "theme_override_constants/margin_top = 10" in scene
    assert "theme_override_constants/margin_bottom = 10" in scene


def test_shared_terminal_routes_weapon_archive_without_changing_old_modes() -> None:
    script = HUB_TERMINAL_SCRIPT.read_text(encoding="utf-8")
    scene = HUB_TERMINAL_SCENE.read_text(encoding="utf-8")

    assert "MISSION_CONTROL,\n\tDEPLOYMENT,\n\tINFORMATION,\n\tWEAPON_ARCHIVE," in script
    assert '"Mission Control", "Deployment", "Information", "Weapon Archive"' in script
    assert "terminal_mode == TerminalMode.INFORMATION" in script
    assert "terminal_mode == TerminalMode.WEAPON_ARCHIVE" in script
    assert "weapon_archive_terminal.open_terminal()" in script
    assert 'path="res://scenes/ui/weapon_archive_terminal.tscn"' in scene
    assert '[node name="WeaponArchiveTerminal" parent="."' in scene


def test_weapon_archive_terminal_is_centered_between_two_armory_racks() -> None:
    scene = BASTION_SCENE.read_text(encoding="utf-8")

    assert "-15.5, 1.1, -5.65" in scene
    assert "-8.5, 1.1, -5.65" in scene
    assert '[node name="ArmoryWeaponArchiveTerminal" parent="Systems" instance=ExtResource("11_terminal")]' in scene
    assert "-12, 0.65, -5.65" in scene
    assert "terminal_mode = 3" in scene


def test_shared_terminal_physical_colliders_remain_canonical() -> None:
    scene = HUB_TERMINAL_SCENE.read_text(encoding="utf-8")

    assert "size = Vector3(1.3230512, 0.7523071, 0.02)" in scene
    assert "0, 1.2246144, -0.4089676)" in scene
    assert "-0.66510963, 0.8407265, -0.4089676)" in scene
