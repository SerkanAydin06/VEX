from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "scenes" / "levels" / "level_01_first_fracture_content.tscn"
LEVEL_SCRIPT = ROOT / "scripts" / "levels" / "level_01.gd"
TRAINING = ROOT / "scenes" / "levels" / "level_01_training_overlay.tscn"
RECORD_SCRIPT = ROOT / "scripts" / "props" / "field_record_terminal.gd"
CINDER_SCRIPT = ROOT / "scripts" / "actors" / "cinderhound.gd"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


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
        'pickup_type = "sg04"',
        'pickup_type = "p07"',
        'pickup_type = "p14"',
        'pickup_type = "p20"',
        'pickup_type = "night_vision"',
        'pickup_type = "shells"',
        "ammo_shells.png",
    ]:
        assert forbidden not in content


def test_access_cards_secret_and_resupply_windows_are_present() -> None:
    content = _read(CONTENT)
    assert "BlueKey_R17" in content
    assert 'pickup_type = "key_blue"' in content
    assert "RedKey_R33" in content
    assert 'pickup_type = "key_red"' in content
    assert "R23ResupplyHealth" in content
    assert "R23ResupplyArmor" in content
    assert "R23ResupplyBullets" in content
    assert "R35FinalHealth" in content
    assert "R35FinalArmor" in content
    assert "R35FinalBullets" in content
    assert "SecretMaintenanceTrigger" in content
    assert 'secret_id = &"level01_maintenance_cache"' in content


def test_three_canonical_story_records_are_scene_authored() -> None:
    content = _read(CONTENT)
    record_ids = re.findall(r'^record_id = &"([^"]+)"$', content, flags=re.MULTILINE)
    assert record_ids == [
        "vex01_emergency_test_order_0417",
        "vex01_security_camera_07",
        "vex01_we_do_not_produce_energy",
    ]
    assert "ACİL TEST EMRİ / 04:17" in content
    assert "GÜVENLİK KAMERASI 07" in content
    assert "ENERJİ ÜRETMİYORUZ" in content
    assert "Enerji üretmiyoruz. Bir yerden çekiyoruz." in content


def test_finish_has_no_enemy_id_gate_and_returns_to_bastion() -> None:
    content = _read(CONTENT)
    finish_block = content.split('[node name="FinishSwitch"', 1)[1]
    assert "required_enemy_id" not in finish_block
    assert 'next_level_path = "res://scenes/hub/bastion_7.tscn"' in finish_block


def test_level_installs_canonical_content_before_base_level_counting() -> None:
    script = _read(LEVEL_SCRIPT)
    install_call = script.index("\t_install_first_fracture_content()")
    base_ready_call = script.index("\tsuper._ready()")
    assert install_call < base_ready_call
    assert 'for legacy_container_name in [&"Enemies", &"Pickups", &"Triggers"]' in script
    assert 'preload("res://scenes/levels/level_01_first_fracture_content.tscn")' in script
    assert 'map_revision = "VEX01-FIRST-FRACTURE-R37"' in script


def test_first_campaign_stage_starts_unarmed_until_r03_pickup() -> None:
    script = _read(LEVEL_SCRIPT)
    assert "if GameState.campaign_stage != 0 or player == null:" in script
    assert "weapon_controller.unlocked_weapons.clear()" in script
    assert "weapon_controller.acquired_weapons.clear()" in script
    assert 'weapon_controller.current_weapon_id = &""' in script
    assert 'weapon_controller.magazines[&"p01"] = 0' in script
    assert 'weapon_controller.reserve_ammo[&"bullets"] = 0' in script


def test_tutorial_is_short_and_has_no_enemy_id_combat_gate() -> None:
    training = _read(TRAINING)
    assert "ravager" not in training.lower()
    assert "gate_enemy_ids = Array[StringName]([])" in training
    assert "gate_door_paths = Array[NodePath]([])" in training
    assert training.count('parent="." instance=ExtResource("2_tutorial")') == 5
    for removed_step in ["TutorialStrafe", "TutorialBarrel", "TutorialResource", "TutorialFinal"]:
        assert removed_step not in training


def test_record_terminal_keeps_lore_in_scene_and_ui_as_runtime_helper() -> None:
    script = _read(RECORD_SCRIPT)
    assert "@export var record_id" in script
    assert "@export_multiline var body_tr" in script
    assert "@export_multiline var body_en" in script
    assert "func get_interaction_text" in script
    assert "func interact" in script
    assert "get_tree().paused = true" in script
    assert "CanvasLayer.new()" in script


def test_cinderhound_keeps_species_id_and_counts_physical_duplicates() -> None:
    script = _read(CINDER_SCRIPT)
    assert "enemy_id =" not in script
    assert "GameState.was_enemy_defeated(enemy_id)" in script
    assert "super._die()" in script
    assert "GameState.register_enemy_defeated()" in script
