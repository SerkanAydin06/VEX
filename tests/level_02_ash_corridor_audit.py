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


def _node_block(scene: str, node_name: str) -> str:
    marker = f'[node name="{node_name}"'
    start = scene.index(marker)
    next_node = scene.find("\n[node ", start + len(marker))
    return scene[start:] if next_node < 0 else scene[start:next_node]


def _record_block(database: str, record_id: str) -> str:
    marker = f'"id": &"{record_id}"'
    start = database.index(marker)
    next_record = database.find('\n\t{\n\t\t"id":', start + len(marker))
    return database[start:] if next_record < 0 else database[start:next_record]


def test_level02_main_scene_exposes_canonical_layers_in_editor() -> None:
    shell = _read(SHELL)
    assert '[node name="Level02_AshCorridor" type="Node3D"]' in shell
    assert 'level_display_name = "CH02_NAME"' in shell
    assert 'campaign_completion_stage = 2' in shell
    assert 'path="res://scenes/levels/level_02_environment_story.tscn"' in shell
    assert 'path="res://scenes/levels/level_02_ash_corridor_content.tscn"' in shell
    assert '[node name="Level02EnvironmentStory" parent="." instance=ExtResource("6_environment")]' in shell
    assert '[node name="Level02AshCorridorContent" parent="." instance=ExtResource("7_content")]' in shell
    for forbidden in ["ravager.tscn", "vaskari", "basalt_juggernaut", "voidweaver"]:
        assert forbidden not in shell.lower()


def test_level02_tool_script_previews_only_safe_structure_roots() -> None:
    structure = _read(STRUCTURE)
    script = _read(SCRIPT)
    assert '[node name="Geometry" type="Node3D" parent="."]' in structure
    assert '[node name="Doors" type="Node3D" parent="."]' in structure
    assert '[node name="Enemies" type="Node3D" parent="."]' in structure
    assert script.startswith("@tool\nextends VexBaseLevel")
    assert 'if Engine.is_editor_hint():' in script
    assert 'STRUCTURE_SOURCE_PATH := "res://scenes/levels/level_02_structure_source.tscn"' in script
    structure_block = script[script.index("const STRUCTURE_NODE_NAMES"):script.index("var _alarm_triggered")]
    for allowed in [
        '&"WorldEnvironment"', '&"Geometry"', '&"EnemyNavigation"', '&"Doors"',
        '&"RoomLights"', '&"Lights"', '&"Props"',
    ]:
        assert allowed in structure_block
    for forbidden in ['&"Enemies"', '&"Pickups"', '&"Triggers"']:
        assert forbidden not in structure_block
    assert 'if get_node_or_null("Geometry") != null:' in script
    assert "ASH_CORRIDOR_CONTENT_SCENE" not in script
    assert "ENVIRONMENT_STORY_SCENE" not in script


def test_active_content_uses_only_hounds_and_spitters_with_expected_difficulty_counts() -> None:
    content = _read(CONTENT)
    assert 'path="res://scenes/actors/cinderhound.tscn"' in content
    assert 'path="res://scenes/actors/cinder_spitter.tscn"' in content
    for forbidden in ["ravager.tscn", "vaskari", "basalt_juggernaut", "voidweaver"]:
        assert forbidden not in content.lower()
    enemy_nodes = re.findall(r'^\[node name="(Cinder(?:Hound|Spitter)_[^"]+)" parent="Enemies"', content, re.MULTILINE)
    assert len(enemy_nodes) == 20
    assert content.count("spawn_min_difficulty = 1") == 4
    assert content.count("spawn_min_difficulty = 2") == 3
    assert content.count("spawn_min_difficulty = 3") == 2
    assert len(enemy_nodes) - 4 - 3 - 2 == 11
    assert len(re.findall(r'^\[node name="CinderHound_', content, re.MULTILINE)) == 12
    assert len(re.findall(r'^\[node name="CinderSpitter_', content, re.MULTILINE)) == 8


def test_sg04_and_power_fuse_chain_are_scene_authored() -> None:
    content = _read(CONTENT)
    script = _read(SCRIPT)
    translations = _read(TRANSLATIONS)
    assert '[node name="SG04BreacherPickup"' in content
    assert 'pickup_type = "sg04"' in content
    assert 'amount = 12' in content
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


def test_species_stats_remain_actor_authoritative() -> None:
    content = _read(CONTENT)
    for forbidden in ["maximum_health =", "attack_damage =", "move_speed =", "chase_speed ="]:
        assert forbidden not in content


def test_chapter02_records_match_campaign_and_persistent_database() -> None:
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
    chapter2 = plan[plan.index("## BÖLÜM 2 — KÜL KORİDORU"):plan.index("## BÖLÜM 3 — BASINÇ HATTI")]
    for title in ["KOR-TERMAL Kaynak İmzası", "Röle Teknisyeni / Son Vardiya", "Basınç Sapması Önemsizdir"]:
        assert title in chapter2


def test_kor_thermal_signature_is_at_final_r33_relay_console() -> None:
    content = _read(CONTENT)
    db = _read(RECORD_DB)
    doc = _read(DOC)
    node = _node_block(content, "Record_KorThermalSourceSignature")
    assert 'record_id = &"vex02_kor_thermal_source_signature"' in node
    assert '50.2, 0.85, 28.8' in node
    record = _record_block(db, "vex02_kor_thermal_source_signature")
    assert '"room": "R33"' in record
    assert "### R33 — TEKNİK / KOR-TERMAL Kaynak İmzası" in doc


def test_environment_story_is_visual_only_and_marks_relay_route() -> None:
    environment = _read(ENVIRONMENT)
    assert "RoomCodes" in environment
    assert "ThermalConduits" in environment
    assert "StoryLights" in environment
    assert 'room_name = "R33 // RELAY"' in environment
    assert 'room_name = "R27 // BYPASS"' in environment
    for forbidden in ["CollisionShape3D", "StaticBody3D", "Area3D", "CharacterBody3D"]:
        assert forbidden not in environment


def test_mission_translation_catalog_and_planned_bypass_remain_consistent() -> None:
    mission = _read(MISSION)
    translations = _read(TRANSLATIONS)
    settings = _read(SETTINGS)
    plan = _read(PLAN)
    doc = _read(DOC)
    content = _read(CONTENT)
    assert 'display_name = "CH02_NAME"' in mission
    assert 'briefing = "CH02_MISSION_BRIEF"' in mission
    assert 'completion_message = "CH02_COMPLETE"' in mission
    assert '"res://translations/chapter02.tr.translation"' in settings
    assert '"res://translations/chapter02.en.translation"' in settings
    assert "CH02_FINISH_CONTROL" in translations
    chapter2 = plan[plan.index("## BÖLÜM 2 — KÜL KORİDORU"):plan.index("## BÖLÜM 3 — BASINÇ HATTI")]
    assert "Güç Bypass Kuplörü (planlandı)" in chapter2
    assert "runtime sistemi henüz aktif değil" in doc
    assert 'pickup_type = "power_bypass"' not in content
