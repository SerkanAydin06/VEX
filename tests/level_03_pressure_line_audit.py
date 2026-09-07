from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
SHELL = ROOT / "scenes" / "levels" / "level_03.tscn"
STRUCTURE = ROOT / "scenes" / "levels" / "level_03_structure_source.tscn"
CONTENT = ROOT / "scenes" / "levels" / "level_03_pressure_line_content.tscn"
ENVIRONMENT = ROOT / "scenes" / "levels" / "level_03_environment_story.tscn"
LEVEL_SCRIPT = ROOT / "scripts" / "levels" / "level_03.gd"
RESCUE_SCRIPT = ROOT / "scripts" / "props" / "survivor_rescue_terminal.gd"
EXTRACTION_SCRIPT = ROOT / "scripts" / "levels" / "level_03_extraction_switch.gd"
RECORD_DB = ROOT / "scripts" / "data" / "vex_field_record_database.gd"
MISSION = ROOT / "resources" / "missions" / "vex03.tres"
TRANSLATIONS = ROOT / "translations" / "chapter03.csv"
BASTION = ROOT / "scenes" / "hub" / "bastion_7.tscn"
PLAN = ROOT / "docs" / "Campaign_Level_Design_VEX.md"
DOC = ROOT / "docs" / "levels" / "Level_03_Pressure_Line.md"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_level03_shell_is_canonical_and_legacy_gameplay_is_structure_only() -> None:
    shell = _read(SHELL)
    structure = _read(STRUCTURE)
    script = _read(LEVEL_SCRIPT)

    assert '[node name="Level03_PressureLine" type="Node3D"]' in shell
    assert 'level_display_name = "CH03_NAME"' in shell
    assert 'campaign_completion_stage = 3' in shell
    assert 'total_secrets = 1' in shell
    for forbidden in ["ravager.tscn", "vaskari", "voidweaver", "loom_herald", "basalt_juggernaut"]:
        assert forbidden not in shell.lower()

    assert '[node name="Geometry" type="Node3D" parent="."]' in structure
    assert '[node name="Doors" type="Node3D" parent="."]' in structure
    assert '[node name="Enemies" type="Node3D" parent="."]' in structure
    assert 'STRUCTURE_SOURCE_PATH := "res://scenes/levels/level_03_structure_source.tscn"' in script
    structure_block = script[script.index("const STRUCTURE_NODE_NAMES"):script.index("const PRESSURE_LINE_CONTENT_SCENE")]
    for allowed in ['&"WorldEnvironment"', '&"Geometry"', '&"Doors"', '&"Props"', '&"RoomLights"', '&"Lights"']:
        assert allowed in structure_block
    for forbidden in ['&"Enemies"', '&"Pickups"', '&"Objectives"', '&"Secrets"', '&"LoreTerminals"']:
        assert forbidden not in structure_block
    assert "LOOM_HERALD_SCENE" not in script
    assert "_spawn_loom_herald" not in script


def test_active_enemy_family_is_only_korvath_and_scales_by_encounter_count() -> None:
    content = _read(CONTENT)

    assert 'path="res://scenes/actors/cinderhound.tscn"' in content
    assert 'path="res://scenes/actors/cinder_spitter.tscn"' in content
    assert 'path="res://scenes/actors/basalt_juggernaut.tscn"' in content
    for forbidden in ["ravager.tscn", "vaskari", "voidweaver", "loom_herald"]:
        assert forbidden not in content.lower()

    enemy_nodes = re.findall(
        r'^\[node name="((?:CinderHound|CinderSpitter|BasaltJuggernaut)_[^"]+)" parent="Enemies"',
        content,
        re.MULTILINE,
    )
    assert len(enemy_nodes) == 22
    assert content.count("spawn_min_difficulty = 1") == 4
    assert content.count("spawn_min_difficulty = 2") == 4
    assert content.count("spawn_min_difficulty = 3") == 3
    assert len(enemy_nodes) - 4 - 4 - 3 == 11

    assert len(re.findall(r'^\[node name="CinderHound_', content, re.MULTILINE)) == 11
    assert len(re.findall(r'^\[node name="CinderSpitter_', content, re.MULTILINE)) == 7
    assert len(re.findall(r'^\[node name="BasaltJuggernaut_', content, re.MULTILINE)) == 4


def test_juggernaut_species_stats_remain_actor_authoritative() -> None:
    content = _read(CONTENT)
    actor = _read(ROOT / "scenes" / "actors" / "basalt_juggernaut.tscn")

    assert "maximum_health = 240" in actor
    assert "attack_damage = 28" in actor
    for forbidden in ["maximum_health =", "attack_damage =", "move_speed =", "attack_cooldown ="]:
        assert forbidden not in content
    assert "520" not in content


def test_p07_is_the_chapter03_weapon_and_is_found_early() -> None:
    content = _read(CONTENT)
    plan = _read(PLAN)
    weapon = _read(ROOT / "resources" / "weapons" / "p07.tres")

    chapter3 = plan[plan.index("## BÖLÜM 3 — BASINÇ HATTI"):plan.index("## BÖLÜM 4 — ERİMİŞ DAMAR")]
    assert "**Yeni silah:** P-07 Sentinel" in chapter3
    assert "**Yeni yaratık:** Basalt Juggernaut" in chapter3
    assert '[node name="P07SentinelPickup"' in content
    assert 'pickup_type = "p07"' in content
    assert 'amount = 32' in content
    assert 'magazine_size = 16' in weapon
    assert 'damage_per_pellet = 17' in weapon
    assert 'supports_flashlight = true' in weapon


def test_three_stage_access_chain_is_blue_yellow_red() -> None:
    content = _read(CONTENT)
    script = _read(LEVEL_SCRIPT)

    expected = [
        ("BlueMaintenanceAuthorization", "key_blue", "CH03_BLUE_AUTH"),
        ("YellowArchiveAuthorization", "key_yellow", "CH03_YELLOW_AUTH"),
        ("RedReactorAuthorization", "key_red", "CH03_RED_AUTH"),
    ]
    for node_name, pickup_type, display_key in expected:
        assert f'[node name="{node_name}"' in content
        assert f'pickup_type = "{pickup_type}"' in content
        assert f'display_name = "{display_key}"' in content
        assert display_key in script

    assert 'doors_root.get_node_or_null("Door_StairAccess")' in script
    assert 'doors_root.get_node_or_null("Door_StairSecurity")' in script
    assert 'doors_root.get_node_or_null("Door_CoreAuthorization")' in script
    assert '&"blue"' in script
    assert '&"yellow"' in script
    assert '&"red"' in script
    assert "_reset_authored_door" in script
    assert "required_enemy_ids = []" in script


def test_chapter03_records_are_persistent_and_match_canon() -> None:
    content = _read(CONTENT)
    db = _read(RECORD_DB)
    plan = _read(PLAN)

    expected = [
        ("vex03_regulated_geothermal_flow", 7, "L03", "DÜZENLENMİŞ JEOTERMAL AKIŞ"),
        ("vex03_selin_erdem_objection_draft", 8, "U06", "SELİN ERDEM / İTİRAZ TASLAĞI"),
        ("vex03_report_7c_classified", 9, "U04", "RAPOR 7-C SINIFLANDIRILDI"),
    ]
    for record_id, order, room, title in expected:
        assert f'&"{record_id}"' in content
        assert f'&"{record_id}"' in db
        assert f'"order": {order}' in db
        assert f'"room": "{room}"' in db
        assert title in db
    assert db.count('"chapter": 3') == 3

    chapter3 = plan[plan.index("## BÖLÜM 3 — BASINÇ HATTI"):plan.index("## BÖLÜM 4 — ERİMİŞ DAMAR")]
    for title in ["Düzenlenmiş Jeotermal Akış", "Selin Erdem / İtiraz Taslağı", "Rapor 7-C Sınıflandırıldı"]:
        assert title in chapter3


def test_selin_rescue_is_a_real_gate_before_level_completion() -> None:
    content = _read(CONTENT)
    rescue = _read(RESCUE_SCRIPT)
    extraction = _read(EXTRACTION_SCRIPT)

    assert '[node name="SelinStabilizationUnit"' in content
    assert 'rescue_terminal_path = NodePath("../../SurvivorRescue/SelinStabilizationUnit")' in content
    assert 'class_name VexSurvivorRescueTerminal' in rescue
    assert 'var rescued := false' in rescue
    assert 'rescued = true' in rescue
    assert 'GameState.set_objective(objective_after_rescue)' in rescue

    assert 'extends VexFinishSwitch' in extraction
    assert 'if not _is_survivor_rescued()' in extraction
    assert 'return tr(rescue_required_message_key)' in extraction
    assert 'super.interact(player)' in extraction
    assert 'GameState.call_deferred("complete_level"' not in rescue


def test_environment_story_is_collisionless() -> None:
    environment = _read(ENVIRONMENT)
    assert "PressurePipes" in environment
    assert "P07LockerLight" in environment
    assert "SelinMedicalLight" in environment
    for forbidden in ["CollisionShape3D", "StaticBody3D", "Area3D", "CharacterBody3D"]:
        assert forbidden not in environment


def test_mission_translation_and_bastion_return_match_chapter03() -> None:
    mission = _read(MISSION)
    translations = _read(TRANSLATIONS)
    bastion = _read(BASTION)
    doc = _read(DOC)

    assert 'display_name = "CH03_NAME"' in mission
    assert 'briefing = "CH03_MISSION_BRIEF"' in mission
    assert 'completion_message = "CH03_COMPLETE"' in mission
    assert 'terminal_code = "BÖLÜM-03"' in mission
    for key in [
        "CH03_NAME", "CH03_BRIEFING_STORY", "CH03_MISSION_BRIEF", "CH03_COMPLETE",
        "CH03_RESCUE_INTERACT", "CH03_FINISH_REQUIRES_RESCUE", "HUB_SELIN_POST_CH03",
    ]:
        assert key in translations

    selin_start = bastion.index('[node name="DrSelinErdem"')
    selin_end = bastion.index('\n[node name="Player"', selin_start)
    selin_block = bastion[selin_start:selin_end]
    assert "required_campaign_stage = 3" in selin_block
    assert 'dialogue_key = "HUB_SELIN_POST_CH03"' in selin_block
    assert "19–22 dakika" in doc
