from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLAYER_SCENE = ROOT / "scenes" / "player" / "player.tscn"
WEAPON_CONTROLLER = ROOT / "scripts" / "player" / "weapon_controller.gd"
LEVEL01_SCRIPT = ROOT / "scripts" / "levels" / "level_01.gd"
LEVEL01_CONTENT = ROOT / "scenes" / "levels" / "level_01_first_fracture_content.tscn"
LEVEL02_CONTENT = ROOT / "scenes" / "levels" / "level_02_ash_corridor_content.tscn"
LEVEL03_CONTENT = ROOT / "scenes" / "levels" / "level_03_pressure_line_content.tscn"
HUB_RACK = ROOT / "scripts" / "hub" / "hub_weapon_rack.gd"
GAME_STATE = ROOT / "scripts" / "autoload" / "game_state.gd"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_player_has_compatibility_p01_default_but_chapter1_removes_it_for_fresh_campaign() -> None:
    player = _read(PLAYER_SCENE)
    level01 = _read(LEVEL01_SCRIPT)
    assert 'initial_unlocked_weapons: Array[StringName] = [&"p01"]' not in player  # value lives in controller script
    controller = _read(WEAPON_CONTROLLER)
    assert 'initial_unlocked_weapons: Array[StringName] = [&"p01"]' in controller
    assert 'initial_weapon_id: StringName = &"p01"' in controller
    assert "if GameState.campaign_stage != 0:" in level01
    assert "weapon_controller.unlocked_weapons.clear()" in level01
    assert "weapon_controller.acquired_weapons.clear()" in level01
    assert 'weapon_controller.current_weapon_id = &""' in level01
    assert 'weapon_controller.magazines[&"p01"] = 0' in level01
    assert 'weapon_controller.reserve_ammo[&"bullets"] = 0' in level01


def test_first_three_campaign_weapon_discoveries_are_authored_in_order() -> None:
    chapter01 = _read(LEVEL01_CONTENT)
    chapter02 = _read(LEVEL02_CONTENT)
    chapter03 = _read(LEVEL03_CONTENT)
    assert '[node name="P01SecurityLockerPickup"' in chapter01
    assert 'pickup_type = "p01"' in chapter01
    assert '[node name="SG04BreacherPickup"' in chapter02
    assert 'pickup_type = "sg04"' in chapter02
    assert '[node name="P07SentinelPickup"' in chapter03
    assert 'pickup_type = "p07"' in chapter03


def test_weapon_state_persists_owned_and_carried_weapons_separately() -> None:
    controller = _read(WEAPON_CONTROLLER)
    assert 'var unlocked_weapons: Array[StringName] = []' in controller
    assert 'var acquired_weapons: Array[StringName] = []' in controller
    capture_start = controller.index("func capture_state()")
    capture_end = controller.index("func restore_state", capture_start)
    capture_block = controller[capture_start:capture_end]
    assert '"unlocked_weapons": unlocked_weapons.duplicate()' in capture_block
    assert '"acquired_weapons": acquired_weapons.duplicate()' in capture_block
    restore_block = controller[capture_end:]
    assert 'state.get("acquired_weapons", stored_weapons)' in restore_block
    assert "acquired_weapons.append(stored_weapon_id)" in restore_block
    assert "unlocked_weapons.append(stored_weapon_id)" in restore_block


def test_armory_never_grants_an_unowned_weapon_and_loadout_changes_are_safe_saved() -> None:
    rack = _read(HUB_RACK)
    controller = _read(WEAPON_CONTROLLER)
    assert 'return controller != null and bool(controller.call("owns_weapon", weapon_id))' in rack
    assert "if controller == null or not _is_owned(player):" in rack
    assert 'GameState.call_deferred("save_current_safe_progress", "armory_loadout")' in controller
    assert "if is_reloading or not owns_weapon(weapon_id)" in controller


def test_deploy_requires_at_least_one_carried_weapon() -> None:
    game_state = _read(GAME_STATE)
    start = game_state.index("func deploy_selected_hub_mission()")
    end = game_state.index("func _register_campaign_completion", start)
    block = game_state[start:end]
    assert 'weapon_controller.has_method("has_carried_weapon")' in block
    assert 'not bool(weapon_controller.call("has_carried_weapon"))' in block
    assert 'notify("HUB_LOADOUT_REQUIRED")' in block
    assert 'set_objective("HUB_OBJECTIVE_VISIT_ARMORY")' in block
