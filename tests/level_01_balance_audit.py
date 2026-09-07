from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "scenes" / "levels" / "level_01_first_fracture_content.tscn"
P01 = ROOT / "resources" / "weapons" / "p01.tres"
CINDER = ROOT / "scenes" / "actors" / "cinderhound.tscn"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _node_block(content: str, node_name: str) -> str:
    marker = f'[node name="{node_name}"'
    assert marker in content
    return content.split(marker, 1)[1].split("\n[node ", 1)[0]


def test_encounter_distribution_is_easy_9_normal_12_hard_13() -> None:
    content = _read(CONTENT)
    blocks = re.findall(
        r'\[node name="CinderHound_[^"]+".*?(?=\n\[node|\Z)',
        content,
        flags=re.DOTALL,
    )
    assert len(blocks) == 13
    base = sum("spawn_min_difficulty" not in block for block in blocks)
    normal_plus = sum("spawn_min_difficulty = 1" in block for block in blocks)
    hard_plus = sum("spawn_min_difficulty = 2" in block for block in blocks)
    assert (base, base + normal_plus, base + normal_plus + hard_plus) == (9, 12, 13)


def test_information_room_r17_is_not_a_combat_spawn() -> None:
    content = _read(CONTENT)
    assert "CinderHound_R17" not in content
    assert "BlueKey_R17" in content
    assert "Record_R17_SecurityCamera07" in content
    assert "CinderHound_R18_A" in content
    assert "spawn_min_difficulty = 1" in _node_block(content, "CinderHound_R18_A")


def test_normal_final_uses_three_staggered_hounds() -> None:
    content = _read(CONTENT)
    for name in ["CinderHound_R35_A", "CinderHound_R35_B", "CinderHound_R35_C"]:
        assert name in content
    assert "spawn_min_difficulty = 1" in _node_block(content, "CinderHound_R35_C")
    assert "detection_range = 13.0" in _node_block(content, "CinderHound_R35_A")
    assert "detection_range = 5.5" in _node_block(content, "CinderHound_R35_B")
    assert "detection_range = 3.4" in _node_block(content, "CinderHound_R35_C")
    assert "ally_alert_radius = 4.5" in _node_block(content, "CinderHound_R35_A")
    assert "ally_alert_radius = 3.0" in _node_block(content, "CinderHound_R35_B")
    assert "ally_alert_radius = 2.2" in _node_block(content, "CinderHound_R35_C")


def test_p01_pickup_sits_on_main_security_route_with_controlled_start_ammo() -> None:
    content = _read(CONTENT)
    block = _node_block(content, "P01SecurityLockerPickup")
    assert "0, 0.7, 47.8" in block
    assert 'pickup_type = "p01"' in block
    assert "amount = 24" in block
    assert "scale_amount_with_difficulty = false" in block


def test_side_rooms_reward_exploration_without_new_weapons() -> None:
    content = _read(CONTENT)
    for pickup_name in ["R06Bullets", "R10Health", "R20Armor", "R28Bullets"]:
        assert pickup_name in content
    for forbidden in ['pickup_type = "sg04"', 'pickup_type = "p07"', 'pickup_type = "p20"']:
        assert forbidden not in content


def test_main_resupply_windows_have_reduced_but_safe_budget() -> None:
    content = _read(CONTENT)
    expected = {
        "R13Bullets": 12,
        "R19Bullets": 10,
        "R23ResupplyBullets": 24,
        "R29SecretAmmo": 18,
        "R33Bullets": 12,
        "R35FinalBullets": 24,
        "R23ResupplyArmor": 16,
        "R29SecretArmor": 12,
        "R35FinalArmor": 15,
    }
    for node_name, amount in expected.items():
        assert f"amount = {amount}" in _node_block(content, node_name)


def test_balance_assumptions_match_live_p01_and_cinder_stats() -> None:
    p01 = _read(P01)
    cinder = _read(CINDER)
    # P-01 inherits WeaponDefinition defaults: 12-round mag, 18 damage.
    assert "magazine_size =" not in p01
    assert "damage_per_pellet =" not in p01
    # Cinder Hound remains 85 HP on authored base/Normal before difficulty multipliers.
    assert "maximum_health = 85" in cinder
    assert "difficulty_health_multipliers = PackedFloat32Array(0.75, 1, 1.2, 1.45)" in cinder
