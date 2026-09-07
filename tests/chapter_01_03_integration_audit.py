from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SETTINGS = ROOT / "scripts" / "autoload" / "settings_manager.gd"
MAIN_MENU = ROOT / "scripts" / "ui" / "main_menu.gd"
BASTION = ROOT / "scripts" / "hub" / "bastion_7.gd"
MISSIONS = [
    (ROOT / "resources" / "missions" / "vex01.tres", "vex01", 1, "BÖLÜM-01", "res://scenes/levels/level_01.tscn", "CH01"),
    (ROOT / "resources" / "missions" / "vex02.tres", "vex02", 2, "BÖLÜM-02", "res://scenes/levels/level_02.tscn", "CH02"),
    (ROOT / "resources" / "missions" / "vex03.tres", "vex03", 3, "BÖLÜM-03", "res://scenes/levels/level_03.tscn", "CH03"),
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_chapter01_through_chapter03_translation_imports_match_settings_manager() -> None:
    settings = _read(SETTINGS)
    for chapter in ["chapter01", "chapter02", "chapter03"]:
        csv_path = ROOT / "translations" / f"{chapter}.csv"
        import_path = ROOT / "translations" / f"{chapter}.csv.import"
        assert csv_path.exists()
        assert import_path.exists()
        import_text = _read(import_path)
        tr_path = f"res://translations/{chapter}.tr.translation"
        en_path = f"res://translations/{chapter}.en.translation"
        assert f'source_file="res://translations/{chapter}.csv"' in import_text
        assert tr_path in import_text
        assert en_path in import_text
        assert f'"{tr_path}"' in settings
        assert f'"{en_path}"' in settings


def test_first_three_mission_resources_use_explicit_canonical_metadata() -> None:
    for mission_path, mission_id, stage, terminal_code, scene_path, prefix in MISSIONS:
        mission = _read(mission_path)
        assert f'mission_id = &"{mission_id}"' in mission
        assert f'scene_path = "{scene_path}"' in mission
        assert f'campaign_stage = {stage}' in mission
        assert f'terminal_code = "{terminal_code}"' in mission
        assert f'display_name = "{prefix}_NAME"' in mission
        assert f'briefing = "{prefix}_MISSION_BRIEF"' in mission
        assert f'completion_message = "{prefix}_COMPLETE"' in mission
        assert f'facility_type = "{prefix}_NAME"' in mission


def test_first_three_level_scenes_keep_matching_completion_stages_and_names() -> None:
    for _, _, stage, _, scene_path, prefix in MISSIONS:
        scene = _read(ROOT / scene_path.removeprefix("res://"))
        assert f"campaign_completion_stage = {stage}" in scene
        assert f'level_display_name = "{prefix}_NAME"' in scene


def test_main_menu_uses_current_playable_summary_and_canonical_chapter_one_text() -> None:
    menu = _read(MAIN_MENU)
    chapter01 = _read(ROOT / "translations" / "chapter01.csv")
    assert 'var campaign_level_count := 3' in menu
    assert 'var campaign_secret_count := 3' in menu
    assert 'tr("CAMPAIGN_PROTOCOL_TITLE")' in menu
    assert 'tr("CAMPAIGN_ARCHIVE_BODY")' in menu
    assert 'tr("CAMPAIGN_NEW_GAME_CONFIRM")' in menu
    assert 'tr("CH01_NAME")' in menu
    for key in ["CAMPAIGN_PROTOCOL_TITLE", "CAMPAIGN_ARCHIVE_BODY", "CAMPAIGN_NEW_GAME_CONFIRM"]:
        assert key in chapter01


def test_bastion_return_messages_follow_current_chapter_names() -> None:
    bastion = _read(BASTION)
    chapter01 = _read(ROOT / "translations" / "chapter01.csv")
    chapter02 = _read(ROOT / "translations" / "chapter02.csv")
    chapter03 = _read(ROOT / "translations" / "chapter03.csv")
    assert 'tr("CH01_HUB_RETURN")' in bastion
    assert 'tr("CH02_HUB_RETURN")' in bastion
    assert 'tr("CH03_HUB_RETURN")' in bastion
    assert "HUB_VEX01_COMPLETE" not in bastion
    assert "HUB_VEX02_COMPLETE" not in bastion
    assert "HUB_VEX03_COMPLETE" not in bastion
    assert "CH01_HUB_RETURN" in chapter01
    assert "CH02_HUB_RETURN" in chapter02
    assert "CH03_HUB_RETURN" in chapter03
