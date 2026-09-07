from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GAME_STATE = ROOT / "scripts" / "autoload" / "game_state.gd"
CINDER_HOUND = ROOT / "scripts" / "actors" / "cinderhound.gd"
COMBATANT = ROOT / "scripts" / "actors" / "enemy_combatant_base.gd"


def test_every_physical_death_counts_while_species_ids_stay_deduplicated() -> None:
    game_state = GAME_STATE.read_text(encoding="utf-8")
    start = game_state.index("func register_enemy_defeated")
    end = game_state.index("\n\nfunc was_enemy_defeated", start)
    block = game_state[start:end]

    assert 'if enemy_id != &"" and not defeated_enemy_ids.has(enemy_id):' in block
    assert "defeated_enemy_ids.append(enemy_id)" in block
    assert "kills += 1" in block
    assert "enemy_defeated.emit(enemy_id)" in block
    assert "defeated_enemy_ids.has(enemy_id):\n\t\treturn" not in block


def test_old_cinder_hound_double_count_workaround_is_removed() -> None:
    cinder_hound = CINDER_HOUND.read_text(encoding="utf-8")

    assert "class_name VexCinderHound" in cinder_hound
    assert "func _die()" not in cinder_hound
    assert "GameState.register_enemy_defeated()" not in cinder_hound


def test_combatant_death_path_registers_once_after_dead_guard() -> None:
    combatant = COMBATANT.read_text(encoding="utf-8")

    assert "if state == State.DEAD or amount <= 0:" in combatant
    death_start = combatant.index("func _die() -> void:")
    death_end = combatant.index("\n\nfunc _restore_defeated_state", death_start)
    death_block = combatant[death_start:death_end]
    assert "state = State.DEAD" in death_block
    assert death_block.count("GameState.register_enemy_defeated(enemy_id)") == 1
