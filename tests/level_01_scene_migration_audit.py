from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
LEVEL_SCENE = ROOT / "scenes" / "levels" / "level_01.tscn"
STRUCTURE_SOURCE = ROOT / "scenes" / "levels" / "level_01_structure_source.tscn"
CONTENT = ROOT / "scenes" / "levels" / "level_01_first_fracture_content.tscn"
ENVIRONMENT = ROOT / "scenes" / "levels" / "level_01_environment_story.tscn"
LEVEL_SCRIPT = ROOT / "scripts" / "levels" / "level_01.gd"
ENVIRONMENT_SCRIPT = ROOT / "scripts" / "levels" / "level_01_environment_story.gd"
TRAINING = ROOT / "scenes" / "levels" / "level_01_training_overlay.tscn"
RECORD_SCRIPT = ROOT / "scripts" / "props" / "field_record_terminal.gd"
CH01_TRANSLATIONS = ROOT / "translations" / "chapter01.csv"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_level01_main_scene_exposes_canonical_layers_in_editor() -> None:
    scene = _read(LEVEL_SCENE)
    assert '[node name="Level01_FirstFracture" type="Node3D"' in scene
    assert 'map_revision = "VEX01-FIRST-FRACTURE-R37-ENV01"' in scene
    assert 'level_display_name = "CH01_NAME"' in scene
    assert 'first_objective = "CH01_OBJECTIVE_START"' in scene
    assert 'briefing_story = "CH01_BRIEFING_STORY"' in scene
    assert 'briefing_objective = "CH01_BRIEFING_OBJECTIVE"' in scene
    assert 'automap_title = "CH01_MAP_TITLE"' in scene
    assert "LEVEL01_NAME" not in scene
    assert 'path="res://scenes/levels/level_01_environment_story.tscn"' in scene
    assert 'path="res://scenes/levels/level_01_first_fracture_content.tscn"' in scene
    assert '[node name="Level01EnvironmentStory" parent="." instance=ExtResource("6_environment")]' in scene
    assert '[node name="Level01FirstFractureContent" parent="." instance=ExtResource("7_content")]' in scene
    assert '[editable path="Level01EnvironmentStory"]' in scene
    assert '[editable path="Level01FirstFractureContent"]' in scene
    assert '[node name="Player"' in scene
    assert '[node name="HUD"' in scene
    for forbidden in [
        'res://scenes/actors/ravager.tscn',
        'res://scenes/actors/veilmaw.tscn',
        '[node name="Enemies"',
        '[node name="Pickups"',
        '[node name="Triggers"',
    ]:
        assert forbidden not in scene


def test_level01_tool_script_previews_only_safe_structure_roots() -> None:
    script = _read(LEVEL_SCRIPT)
    assert script.startswith("@tool\nextends VexBaseLevel")
    assert 'func _enter_tree() -> void:' in script
    enter_block = script[script.index("func _enter_tree() -> void:"):script.index("func _ready() -> void:")]
    assert 'if Engine.is_editor_hint():' in enter_block
    assert '_install_authored_structure()' in enter_block
    ready_block = script[script.index("func _ready() -> void:"):script.index("func _install_editor_structure_preview")]
    assert 'if Engine.is_editor_hint():' in ready_block
    assert '_install_editor_structure_preview()' in ready_block
    assert 'super._ready()' in ready_block
    assert 'STRUCTURE_SOURCE_PATH := "res://scenes/levels/level_01_structure_source.tscn"' in script
    structure_block = script[script.index("const STRUCTURE_NODE_NAMES"):script.index("const TRAINING_OVERLAY_SCENE")]
    for structural_name in [
        '&"WorldEnvironment"', '&"Geometry"', '&"Doors"',
        '&"RoomLights"', '&"Lights"', '&"Props"',
    ]:
        assert structural_name in structure_block
    for forbidden in ['&"Enemies"', '&"Pickups"', '&"Triggers"']:
        assert forbidden not in structure_block
    assert 'if get_node_or_null("Geometry") != null:' in script
    assert 'structure_node.owner = null' in script
    assert 'if node_name == &"Doors" and not Engine.is_editor_hint():' in script
    assert '_configure_authored_doors(structure_node)' in script
    assert "FIRST_FRACTURE_CONTENT_SCENE" not in script
    assert "ENVIRONMENT_STORY_SCENE" not in script


def test_runtime_door_flow_resets_legacy_state_and_applies_only_canonical_gates() -> None:
    script = _read(LEVEL_SCRIPT)
    assert 'doors_root.get_node_or_null("Door_25_27")' in script
    assert 'doors_root.get_node_or_null("Door_35_37")' in script
    assert '"CH01_DOOR_BLUE_ACCESS"' in script
    assert '"CH01_DOOR_FINAL_AIRLOCK"' in script
    assert '[&"blue"]' in script
    assert '[&"blue", &"red"]' in script
    assert "_reset_authored_door" in script
    assert 'door.required_enemy_ids = []' in script
    assert 'door.objective_on_combat_clear = ""' in script
    assert 'door.permanently_locked = false' in script
    assert 'GameState.set_objective("CH01_OBJECTIVE_BOTH_KEYS")' in script
    assert 'GameState.set_objective("CH01_OBJECTIVE_RED_ONLY")' in script
    assert 'GameState.set_objective("CH01_OBJECTIVE_BLUE_ONLY")' in script


def test_chapter01_translation_catalog_covers_active_level_and_door_keys() -> None:
    translations = _read(CH01_TRANSLATIONS)
    for key in [
        "CH01_NAME",
        "CH01_OBJECTIVE_START",
        "CH01_BRIEFING_STORY",
        "CH01_BRIEFING_OBJECTIVE",
        "CH01_MAP_TITLE",
        "CH01_OBJECTIVE_RED_ONLY",
        "CH01_OBJECTIVE_BLUE_ONLY",
        "CH01_OBJECTIVE_BOTH_KEYS",
        "CH01_OBJECTIVE_DEEPER",
        "CH01_OBJECTIVE_FINAL",
        "CH01_DOOR_BLUE_ACCESS",
        "CH01_DOOR_FINAL_AIRLOCK",
        "CH01_BLUE_ACCESS",
        "CH01_DUAL_ACCESS",
        "CH01_MISSION_BRIEF",
        "CH01_COMPLETE",
    ]:
        assert f"{key}," in translations
    assert "BÖLÜM 01 // İLK KIRILMA" in translations
    assert "CHAPTER 01 // FIRST FRACTURE" in translations


def test_structure_source_preserves_the_authored_37_room_spine() -> None:
    structure = _read(STRUCTURE_SOURCE)
    for room_number in range(1, 38):
        assert f'Floor_R{room_number:02d}' in structure
        assert f'Ceiling_R{room_number:02d}' in structure
    assert 'Door_01_03' in structure
    assert 'Door_25_27' in structure
    assert 'Door_35_37' in structure
    assert 'CeilingWhite_Room_37' in structure


def test_first_fracture_content_uses_only_cinder_hounds() -> None:
    content = _read(CONTENT)
    assert "res://scenes/actors/cinderhound.tscn" in content
    assert "res://scenes/actors/ravager.tscn" not in content
    assert "res://scenes/actors/veilmaw.tscn" not in content
    assert content.count('instance=ExtResource("1_hound")') == 13
    assert "enemy_id =" not in content


def test_difficulty_distribution_is_nine_twelve_thirteen() -> None:
    content = _read(CONTENT)
    hound_blocks = re.findall(
        r'\[node name="CinderHound_[^"]+".*?(?=\n\[node|\Z)',
        content,
        flags=re.DOTALL,
    )
    assert len(hound_blocks) == 13
    base = sum("spawn_min_difficulty" not in block for block in hound_blocks)
    normal_plus = sum("spawn_min_difficulty = 1" in block for block in hound_blocks)
    hard_plus = sum("spawn_min_difficulty = 2" in block for block in hound_blocks)
    assert base == 9
    assert base + normal_plus == 12
    assert base + normal_plus + hard_plus == 13


def test_p01_is_the_only_weapon_acquisition() -> None:
    content = _read(CONTENT)
    assert "res://assets/weapons/p01/p01_side.png" in content
    assert 'pickup_type = "p01"' in content
    assert 'pickup_id = &"level01_p01_security_locker"' in content
    for forbidden in [
        'pickup_type = "sg04"', 'pickup_type = "p07"', 'pickup_type = "p14"',
        'pickup_type = "p20"', 'pickup_type = "night_vision"', 'pickup_type = "shells"',
    ]:
        assert forbidden not in content


def test_access_cards_records_secret_and_resupply_are_scene_authored() -> None:
    content = _read(CONTENT)
    assert "BlueKey_R17" in content
    assert "RedKey_R33" in content
    assert "R23ResupplyHealth" in content
    assert "R35FinalBullets" in content
    assert "SecretMaintenanceTrigger" in content
    record_ids = re.findall(r'^record_id = &"([^"]+)"$', content, flags=re.MULTILINE)
    assert record_ids == [
        "vex01_emergency_test_order_0417",
        "vex01_security_camera_07",
        "vex01_we_do_not_produce_energy",
    ]


def test_finish_returns_to_bastion_without_enemy_id_gate() -> None:
    content = _read(CONTENT)
    finish_block = content.split('[node name="FinishSwitch"', 1)[1]
    assert "required_enemy_id" not in finish_block
    assert 'next_level_path = "res://scenes/hub/bastion_7.tscn"' in finish_block


def test_environment_story_is_collision_free_and_scene_authored() -> None:
    environment = _read(ENVIRONMENT)
    assert environment.count('instance=ExtResource("2_display")') == 6
    for room_code in ["R03 // SEC", "R17 // Q-CAM", "R23 // MED", "R29 // MNT", "R35 // EVAC", "R37 // NET"]:
        assert room_code in environment
    assert 'FinalBreachCore' in environment
    for forbidden in ['StaticBody3D', 'CollisionShape3D', 'Area3D']:
        assert forbidden not in environment


def test_environment_runtime_keeps_visual_tuning_in_inspector() -> None:
    script = _read(ENVIRONMENT_SCRIPT)
    assert '@export var disabled_structure_light_paths: Array[NodePath]' in script
    assert '@export_range(0.1, 6.0, 0.1) var breach_pulse_speed' in script
    assert '@export_range(0.0, 0.18, 0.005) var breach_scale_pulse' in script
    assert '@export_range(0.0, 0.6, 0.01) var breach_light_pulse' in script


def test_first_campaign_stage_starts_unarmed_until_r03_pickup() -> None:
    script = _read(LEVEL_SCRIPT)
    assert "if GameState.campaign_stage != 0:" in script
    assert 'var level_player := get_node_or_null("Player") as Node' in script
    assert 'level_player.get_node_or_null("WeaponController")' in script
    assert "weapon_controller.unlocked_weapons.clear()" in script
    assert "weapon_controller.acquired_weapons.clear()" in script
    assert 'weapon_controller.current_weapon_id = &""' in script
    assert 'weapon_controller.magazines[&"p01"] = 0' in script


def test_tutorial_and_record_reader_contracts_remain_intact() -> None:
    training = _read(TRAINING)
    record_script = _read(RECORD_SCRIPT)
    assert "ravager" not in training.lower()
    assert "gate_enemy_ids = Array[StringName]([])" in training
    assert training.count('parent="." instance=ExtResource("2_tutorial")') == 5
    assert "@export var record_id" in record_script
    assert "func get_interaction_text" in record_script
    assert "func interact" in record_script
