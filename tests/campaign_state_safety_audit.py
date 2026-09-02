from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

game_state = (ROOT / "scripts/autoload/game_state.gd").read_text(encoding="utf-8")
main_menu = (ROOT / "scripts/ui/main_menu.gd").read_text(encoding="utf-8")
settings_panel = (ROOT / "scripts/ui/settings_panel.gd").read_text(encoding="utf-8")
level_complete = (ROOT / "scripts/ui/level_complete.gd").read_text(encoding="utf-8")
weapon_controller = (ROOT / "scripts/player/weapon_controller.gd").read_text(encoding="utf-8")
weapon_persistence = (ROOT / "scripts/player/weapon_persistence_runtime.gd").read_text(encoding="utf-8")
weapon_reload = (ROOT / "scripts/player/weapon_reload_runtime.gd").read_text(encoding="utf-8")


def function_block(source: str, name: str, next_name: str) -> str:
    start = source.index(f"func {name}(")
    end = source.index(f"func {next_name}(", start)
    return source[start:end]


# Continue must never silently become New Game: invalid primary+backup saves
# stay on disk until the player explicitly chooses a new campaign.
continue_block = function_block(game_state, "continue_game", "get_continue_failure_message")
assert "func continue_game() -> bool:" in continue_block
assert "start_new_game()" not in continue_block
assert "if not _load_campaign_save():" in continue_block
assert "return false" in continue_block
assert "return true" in continue_block
assert "continue_button.pressed.connect(_on_continue_pressed)" in main_menu
assert "GameState.get_continue_failure_message()" in main_menu

# Mission deployment must persist its boundary before leaving Bastion. A failed
# disk write rolls the in-memory mission selection/path back and stays in hub.
deploy_block = function_block(game_state, "deploy_selected_hub_mission", "_register_campaign_completion")
assert "if not save_campaign_progress(current_level_path, carry_state, \"mission_deploy\")" in deploy_block
assert "current_level_path = previous_current_level_path" in deploy_block
assert "hub_selected_mission_path = previous_mission_path" in deploy_block
assert "notification_requested.emit(get_save_failure_message())" in deploy_block
assert deploy_block.index("save_campaign_progress") < deploy_block.index("_reset_level_counters()")
assert deploy_block.index("save_campaign_progress") < deploy_block.index("change_scene_to_file")

# Level completion may show its report after a failed write, but advancing is
# blocked until the same safe boundary can be written successfully.
continue_next_block = function_block(game_state, "continue_to_next_level", "pending_next_is_hub")
assert "func continue_to_next_level() -> bool:" in continue_next_block
assert "if last_campaign_save_failed:" in continue_next_block
assert '"level_complete_retry"' in continue_next_block
assert "return false" in continue_next_block
assert "GameState.last_campaign_save_failed" in level_complete
assert "GameState.get_save_failure_message()" in level_complete
assert "replay_button.pressed.connect(_on_continue_pressed)" in level_complete

# Difficulty is a campaign-start choice. Pause-menu settings cannot create a
# visual SettingsManager value that disagrees with GameState.active_difficulty.
assert "difficulty_option.disabled = _is_difficulty_locked()" in settings_panel
assert "current_scene.scene_file_path != GameState.MAIN_MENU_PATH" in settings_panel
assert "not _is_difficulty_locked()" in settings_panel

# Restored weapon dictionaries are treated as untrusted persistence data. The
# controller orchestrates restore, while the persistence helper owns canonical
# ids, legacy ammo migration and numeric clamping.
restore_block = function_block(weapon_controller, "restore_state", "_migrate_legacy_ammo_dictionary")
assert "_sanitize_restored_weapon_state()" in restore_block
assert "VexWeaponPersistenceRuntime.sanitize_restored_weapon_state(" in weapon_controller
assert "static func sanitize_restored_weapon_state(" in weapon_persistence
sanitize_start = weapon_persistence.index("static func sanitize_restored_weapon_state(")
sanitize_block = weapon_persistence[sanitize_start:]
assert "maximum_upgrade_level" in sanitize_block
assert "maximum_magazine" in sanitize_block
assert "get_reserve_ammo_capacity(weapon_definitions, definition.ammo_type)" in sanitize_block
assert sanitize_block.count("clampi(") >= 3
assert "static func canonical_weapon_id(" in weapon_persistence
assert "static func migrate_legacy_ammo_dictionary(" in weapon_persistence

# Gameplay reload timers remain pause-aware after async timing moved out of the
# controller. SceneTree.create_timer(..., false) must live in the reload helper.
assert "VexWeaponReloadRuntime.reload_magazine(" in weapon_controller
assert "VexWeaponReloadRuntime.reload_sg04_shells(" in weapon_controller
assert "create_timer(" not in weapon_controller
assert "weapon.reload_duration * maxf(0.01, reload_time_multiplier)" in weapon_reload
assert "create_timer(shell_cycle_duration, false)" in weapon_reload
assert "create_timer(finish_duration, false)" in weapon_reload

print("campaign state safety audit passed")
