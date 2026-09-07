from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
SHELL = ROOT / "scenes" / "levels" / "level_02.tscn"
STRUCTURE = ROOT / "scenes" / "levels" / "level_02_structure_source.tscn"
CONTENT = ROOT / "scenes" / "levels" / "level_02_ash_corridor_content.tscn"
ENVIRONMENT = ROOT / "scenes" / "levels" / "level_02_environment_story.tscn"
SCRIPT = ROOT / "scripts" / "levels" / "level_02.gd"
RECORD_DB = ROOT / "scripts" / "data" / "vex_field_record_database.gd"
MISSION = ROOT / "resources" / "missions" / "vex02.tres"
TRANSLATIONS = ROOT / "translations" / "chapter02.csv"
SETTINGS = ROOT / "scripts" / "autoload" / "settings_manager.gd"
PLAN = ROOT / "docs" / "Campaign_Level_Design_VEX.md"
DOC = ROOT / "docs" / "levels" / "Level_02_Ash_Corridor.md"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_level02_shell_is_small_canonical_and_legacy_gameplay_stays_in_structure_source() -> None:
    shell = _read(SHELL)
    structure = _read(STRUCTURE)
    script = _read(SCRIPT)

    assert '[node name="Level02_AshCorridor" type="Node3D"]' in shell
    assert 'level_display_name = "CH02_NAME"' in shell
    assert 'campaign_completion_stage = 2' in shell
    assert 'total_secrets = 1' in shell
    assert "ravager.tscn" not in shell.lower()
    assert "vaskari" not in shell.lower()
    assert "basalt_juggernaut" not in shell.lower()
    assert "voidweaver" not in shell.lower()

    # The authored old map remains available as a source, but its gameplay roots
    # are intentionally not transferred into the active chapter shell.
    assert '[node name="Geometry" type="Node3D" parent="."]' in structure
    assert '[node name="Doors" type="Node3D" parent="."]' in structure
    assert '[node name="Enemies" type="Node3D" parent="."]' in structure
    assert 'STRUCTURE_SOURCE_PATH := "res://scenes/levels/level_02_structure_source.tscn"' in script
    for allowed in [
        '&"WorldEnvironment"', '&"Geometry"', '&"EnemyNavigation"', '&"Doors"',
        '&"RoomLights"', '&"Lights"', '&"Props"',
    ]:
        assert allowed in script
    structure_names_block = script[script.index("const STRUCTURE_NODE_NAMES"):script.index("const ASH_CORRIDOR_CONTENT_SCENE")]
    for forbidden in ['&"Enemies"', '&"Pickups"', '&"Triggers"']:
        assert forbidden not in structure_names_block


def test_active_content_uses_only_hounds_and_spitters_with_expected_difficulty_counts() -> None:
    content = _read(CONTENT)

    assert 'path="res://scenes/actors/cinderhound.tscn"' in content
    assert 'path="res://scenes/actors/cinder_spitter.tscn"' in content
    for forbidden in ["ravager.tscn", "vaskari", "basalt_juggernaut", "voidweaver"]:
        assert forbidden not in content.lower()

    enemy_nodes = re.findall(r'^\[node name="(Cinder(?:Hound|Spitter)_[^"]+)" parent="Enemies"', content, re.MULTILINE)
    assert len(enemy_nodes) == 20

    # Nodes without spawn_min_difficulty are Easy baseline; tier additions are
    # authored explicitly as 4 Normal, 3 Hard and 2 Nightmare additions.
    assert content.count("spawn_min_difficulty = 1") == 4
    assert content.count("spawn_min_difficulty = 2") == 3
    assert content.count("spawn_min_difficulty = 3") == 2
    assert len(enemy_nodes) - 4 - 3 - 2 == 11

    hounds = len(re.findall(r'^\[node name="CinderHound_', content, re.MULTILINE))
    spitters = len(re.findall(r'^\[node name="CinderSpitter_', content, re.MULTILINE))
    assert hounds == 12
    assert spitters == 8


def test_sg04_is_chapter02_weapon_and_live_species_tuning_is_not_reauthored() -> None:
    content = _read(CONTENT)
    plan = _read(PLAN)

    assert "## BÖLÜM 2 — KÜL KORİDORU" in plan
    chapter2 = plan[plan.index("## BÖLÜM 2 — KÜL KORİDORU"):plan.index("## BÖLÜM 3 — BASINÇ HATTI")]
    assert "**Yeni yaratık:** Cinder Spitter" in chapter2
    assert "**Yeni silah:** SG-04 Breacher" in chapter2

    assert '[node name="SG04BreacherPickup"' in content
    assert 'pickup_type = "sg04"' in content
    assert 'amount = 12' in content
    # Encounter staging may tune perception, but actor health/damage/speed remain
    # scene-authoritative in the Cinder Hound / Spitter scenes.
    for forbidden in ["maximum_health =", "attack_damage =", "move_speed =", "chase_speed ="]:
        assert forbidden not in content


def test_power_chain_reuses_key_state_but_is_presented_as_relay_fuses() -> None:
    content = _read(CONTENT)
    script = _read(SCRIPT)
    translations = _read(TRANSLATIONS)

    for node_name, pickup_type, display_key in [
        ("BlueLineFuse", "key_blue", "CH02_BLUE_FUSE"),
        ("YellowRelayFuse", "key_yellow", "CH02_YELLOW_FUSE"),
        ("RedOutputFuse", "key_red", "CH02_RED_FUSE"),
    ]:
        assert f'[node name="{node_name}"' in content
        assert f'pickup_type = "{pickup_type}"' in content
        assert f'display_name = "{display_key}"' in content
        assert display_key in translations
        assert display_key in script

    assert 'required_keys = Array[StringName]([&"blue", &"yellow", &"red"])' in content
    assert 'display_name = "CH02_FINISH_CONTROL"' in content


def test_chapter02_three_records_match_campaign_plan_and_persistent_database() -> None:
    content = _read(CONTENT)
    db = _read(RECORD_DB)
    plan = _read(PLAN)

    ids = [
        "vex02_kor_thermal_source_signature",
        "vex02_relay_technician_last_shift",
        "vex02_pressure_deviation_insignificant",
    ]
    for record_id in ids:
        assert f'&"{record_id}"' in content
        assert f'&"{record_id}"' in db
    assert db.count('"chapter": 2') == 3
    for order in [4, 5, 6]:
        assert f'"order": {order}' in db

    chapter2 = plan[plan.index("## BÖLÜM 2 — KÜL KORİDORU"):plan.index("## BÖLÜM 3 — BASINÇ HATTI")]
    for title in [
        "KOR-TERMAL Kaynak İmzası",
        "Röle Teknisyeni / Son Vardiya",
        "Basınç Sapması Önemsizdir",
    ]:
        assert title in chapter2
    assert "KOR-TERMAL KAYNAK İMZASI" in db
    assert "RÖLE TEKNİSYENİ / SON VARDİYA" in db
    assert "BASINÇ SAPMASI ÖNEMSİZDİR" in db


def test_environment_story_is_visual_only_and_marks_relay_route() -> None:
    environment = _read(ENVIRONMENT)

    assert "RoomCodes" in environment
    assert "ThermalConduits" in environment
    assert "StoryLights" in environment
    for forbidden in ["CollisionShape3D", "StaticBody3D", "Area3D", "CharacterBody3D"]:
        assert forbidden not in environment


def test_mission_and_translation_catalog_use_ash_corridor_keys() -> None:
    mission = _read(MISSION)
    translations = _read(TRANSLATIONS)
    settings = _read(SETTINGS)

    assert 'display_name = "CH02_NAME"' in mission
    assert 'briefing = "CH02_MISSION_BRIEF"' in mission
    assert 'completion_message = "CH02_COMPLETE"' in mission
    assert 'scene_path = "res://scenes/levels/level_02.tscn"' in mission
    for key in [
        "CH02_NAME", "CH02_BRIEFING_STORY", "CH02_BRIEFING_OBJECTIVE",
        "CH02_MISSION_BRIEF", "CH02_COMPLETE", "CH02_FINISH_CONTROL",
    ]:
        assert key in translations
    assert '"res://translations/chapter02.tr.translation"' in settings
    assert '"res://translations/chapter02.en.translation"' in settings


def test_bypass_coupler_is_documented_as_planned_not_fake_gameplay() -> None:
    plan = _read(PLAN)
    doc = _read(DOC)
    content = _read(CONTENT)

    chapter2 = plan[plan.index("## BÖLÜM 2 — KÜL KORİDORU"):plan.index("## BÖLÜM 3 — BASINÇ HATTI")]
    assert "Güç Bypass Kuplörü (planlandı)" in chapter2
    assert "runtime sistemi henüz aktif değil" in doc
    assert 'pickup_type = "power_bypass"' not in content
