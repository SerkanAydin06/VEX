from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SETTINGS = ROOT / "scripts" / "autoload" / "settings_manager.gd"
MISSIONS = [
    (ROOT / "resources" / "missions" / "vex01.tres", "vex01", 1, "BÖLÜM-01", "res://scenes/levels/level_01.tscn"),
    (ROOT / "resources" / "missions" / "vex02.tres", "vex02", 2, "BÖLÜM-02", "res://scenes/levels/level_02.tscn"),
    (ROOT / "resources" / "missions" / "vex03.tres", "vex03", 3, "BÖLÜM-03", "res://scenes/levels/level_03.tscn"),
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_chapter02_and_chapter03_translation_imports_match_settings_manager() -> None:
    settings = _read(SETTINGS)
    for chapter in ["chapter02", "chapter03"]:
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


def test_first_three_mission_resources_use_explicit_campaign_metadata() -> None:
    for mission_path, mission_id, stage, terminal_code, scene_path in MISSIONS:
        mission = _read(mission_path)
        assert f'mission_id = &"{mission_id}"' in mission
        assert f'scene_path = "{scene_path}"' in mission
        assert f'campaign_stage = {stage}' in mission
        assert f'terminal_code = "{terminal_code}"' in mission
        assert "display_name = " in mission
        assert "briefing = " in mission
        assert "completion_message = " in mission
        assert "facility_type = " in mission


def test_first_three_level_scenes_keep_matching_completion_stages() -> None:
    for _, _, stage, _, scene_path in MISSIONS:
        scene = _read(ROOT / scene_path.removeprefix("res://"))
        assert f"campaign_completion_stage = {stage}" in scene
