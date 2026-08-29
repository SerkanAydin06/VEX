from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise RuntimeError(f"pattern not found in {path}: {old[:120]!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


profile = ROOT / "scripts/actors/enemy_combat_profiles.gd"
replace_once(
    profile,
    "\n\nstatic func path_refresh_interval(role: int) -> float:\n",
    """\n\nstatic func damage_pursuit_commit_time(role: int) -> float:\n    # Hasar alınan anda her rol önce kaynağa doğru fiziksel olarak tepki verir.\n    # Bu kısa commit süresi, hedef zaten menzilde olsa bile 'hasarı aldım ve\n    # anında yöneldim' hissini korur; sonrasında saldırı menziline girilmişse\n    # combat devralır ve gövde gövdeye sonsuza dek yürünmez.\n    match role:\n        Role.CLOSE:\n            return 0.12\n        Role.MID:\n            return 0.16\n        Role.LONG:\n            return 0.20\n        _:\n            return 0.16\n\n\nstatic func path_refresh_interval(role: int) -> float:\n""",
)

ravager = ROOT / "scripts/actors/ravager.gd"
replace_once(
    ravager,
    "var _forced_damage_stall_remaining := 0.0\nvar _combat_interrupt_generation := 0\n",
    "var _forced_damage_stall_remaining := 0.0\nvar _forced_damage_commit_remaining := 0.0\nvar _combat_interrupt_generation := 0\n",
)
replace_once(
    ravager,
    "\t_damage_reaction_remaining = maxf(0.0, _damage_reaction_remaining - delta)\n\t_ranged_reposition_remaining = maxf(0.0, _ranged_reposition_remaining - delta)\n",
    "\t_damage_reaction_remaining = maxf(0.0, _damage_reaction_remaining - delta)\n\t_forced_damage_commit_remaining = maxf(0.0, _forced_damage_commit_remaining - delta)\n\t_ranged_reposition_remaining = maxf(0.0, _ranged_reposition_remaining - delta)\n",
)
replace_once(
    ravager,
    "\t\t_forced_damage_stall_remaining = 3.0\n\t\t_last_seen_position = retaliation_target\n",
    "\t\t_forced_damage_stall_remaining = 3.0\n\t\t_forced_damage_commit_remaining = EnemyCombatProfiles.damage_pursuit_commit_time(combat_role)\n\t\t_last_seen_position = retaliation_target\n",
)
old_forced_ravager = '''\tif _has_forced_damage_target:\n\t\tvar forced_distance := _horizontal_distance(global_position, _forced_damage_target)\n\t\tif forced_distance < _forced_damage_best_distance - 0.20:\n\t\t\t_forced_damage_best_distance = forced_distance\n\t\t\t_forced_damage_stall_remaining = 3.0\n\t\telse:\n\t\t\t_forced_damage_stall_remaining = maxf(0.0, _forced_damage_stall_remaining - delta)\n\t\tif _has_reached_walkable_target(_forced_damage_target, waypoint_reach_distance):\n\t\t\t_has_forced_damage_target = false\n\t\t\t_damage_reaction_remaining = 0.0\n\t\t\t_last_seen_position = _forced_damage_target\n\t\t\t_has_last_seen_position = true\n\t\t\t_begin_search()\n\t\t\treturn\n\t\tstate = State.CHASE\n\t\t_navigate_to(_forced_damage_target, delta)\n\t\tif (\n\t\t\t_forced_damage_stall_remaining <= 0.0\n\t\t\tand (_current_path.is_empty() or _path_index >= _current_path.size())\n\t\t):\n\t\t\t_has_forced_damage_target = false\n\t\t\t_damage_reaction_remaining = 0.0\n\t\t\t_last_seen_position = _forced_damage_target\n\t\t\t_has_last_seen_position = true\n\t\t\t_begin_search()\n\t\treturn\n'''
new_forced_ravager = '''\tif _has_forced_damage_target:\n\t\t# Hasar geldiği anda önce kaynağa yönel; fakat oyuncu artık gerçekten\n\t\t# saldırı menzilindeyse ve arada duvar yoksa exact eski koordinata\n\t\t# ulaşmaya çalışıp gövdenin içine yürümek yerine combat'a teslim et.\n\t\tif _can_handoff_damage_pursuit_to_combat():\n\t\t\t_has_forced_damage_target = false\n\t\t\t_damage_reaction_remaining = 0.0\n\t\t\t_forced_damage_stall_remaining = 0.0\n\t\t\t_clear_path()\n\t\telse:\n\t\t\tvar forced_distance := _horizontal_distance(global_position, _forced_damage_target)\n\t\t\tif forced_distance < _forced_damage_best_distance - 0.20:\n\t\t\t\t_forced_damage_best_distance = forced_distance\n\t\t\t\t_forced_damage_stall_remaining = 3.0\n\t\t\telse:\n\t\t\t\t_forced_damage_stall_remaining = maxf(0.0, _forced_damage_stall_remaining - delta)\n\t\t\tif _has_reached_walkable_target(_forced_damage_target, waypoint_reach_distance):\n\t\t\t\t_has_forced_damage_target = false\n\t\t\t\t_damage_reaction_remaining = 0.0\n\t\t\t\t_last_seen_position = _forced_damage_target\n\t\t\t\t_has_last_seen_position = true\n\t\t\t\t_begin_search()\n\t\t\t\treturn\n\t\t\tstate = State.CHASE\n\t\t\t_navigate_to(_forced_damage_target, delta)\n\t\t\tif (\n\t\t\t\t_forced_damage_stall_remaining <= 0.0\n\t\t\t\tand (_current_path.is_empty() or _path_index >= _current_path.size())\n\t\t\t):\n\t\t\t\t_has_forced_damage_target = false\n\t\t\t\t_damage_reaction_remaining = 0.0\n\t\t\t\t_last_seen_position = _forced_damage_target\n\t\t\t\t_has_last_seen_position = true\n\t\t\t\t_begin_search()\n\t\t\treturn\n'''
replace_once(ravager, old_forced_ravager, new_forced_ravager)
replace_once(
    ravager,
    "\tif (\n\t\t_player_visible\n\t\tand _has_last_seen_position\n",
    '''\t# CLOSE rolünde point-blank saldırı kararı cache'lenmiş görüş sonucunu\n\t# beklemez. Oyuncu menzildeyse LOS'u bu fizik karesinde doğrula.\n\t_refresh_close_combat_visibility()\n\n\tif (\n\t\t_player_visible\n\t\tand _has_last_seen_position\n''',
)
replace_once(
    ravager,
    "\n\nfunc is_pursuing_player() -> bool:\n",
    '''\n\nfunc _refresh_close_combat_visibility() -> void:\n\tif combat_role != EnemyCombatProfiles.Role.CLOSE:\n\t\treturn\n\tif _player == null or not is_instance_valid(_player):\n\t\treturn\n\tif _horizontal_distance(global_position, _player.global_position) > attack_range + attack_range_tolerance:\n\t\treturn\n\tif not _check_line_of_sight():\n\t\treturn\n\t_player_visible = true\n\t_alerted = true\n\t_seconds_without_sight = 0.0\n\t_last_seen_position = _player.global_position\n\t_last_seen_position.y = global_position.y\n\t_has_last_seen_position = true\n\n\nfunc _can_handoff_damage_pursuit_to_combat() -> bool:\n\tif _forced_damage_commit_remaining > 0.0:\n\t\treturn false\n\tif _player == null or not is_instance_valid(_player):\n\t\treturn false\n\tif _horizontal_distance(global_position, _player.global_position) > attack_range + attack_range_tolerance:\n\t\treturn false\n\tif not _check_line_of_sight():\n\t\treturn false\n\t_player_visible = true\n\t_alerted = true\n\t_seconds_without_sight = 0.0\n\t_last_seen_position = _player.global_position\n\t_last_seen_position.y = global_position.y\n\t_has_last_seen_position = true\n\treturn true\n\n\nfunc is_pursuing_player() -> bool:\n''',
)

red = ROOT / "scripts/actors/redviper.gd"
replace_once(
    red,
    "var _forced_damage_stall_remaining := 0.0\nvar _last_seen_position := Vector3.ZERO\n",
    "var _forced_damage_stall_remaining := 0.0\nvar _forced_damage_commit_remaining := 0.0\nvar _last_seen_position := Vector3.ZERO\n",
)
replace_once(
    red,
    "\t_damage_reaction_remaining = maxf(0.0, _damage_reaction_remaining - delta)\n\t_navigation_refresh_remaining = maxf(0.0, _navigation_refresh_remaining - delta)\n",
    "\t_damage_reaction_remaining = maxf(0.0, _damage_reaction_remaining - delta)\n\t_forced_damage_commit_remaining = maxf(0.0, _forced_damage_commit_remaining - delta)\n\t_navigation_refresh_remaining = maxf(0.0, _navigation_refresh_remaining - delta)\n",
)
replace_once(
    red,
    "\t\t_forced_damage_stall_remaining = 3.0\n\t\t_last_seen_position = retaliation_target\n",
    "\t\t_forced_damage_stall_remaining = 3.0\n\t\t_forced_damage_commit_remaining = EnemyCombatProfiles.damage_pursuit_commit_time(combat_role)\n\t\t_last_seen_position = retaliation_target\n",
)
old_forced_red = '''\tif _has_forced_damage_target:\n\t\tvar forced_distance := _horizontal_distance(global_position, _forced_damage_target)\n\t\tif forced_distance < _forced_damage_best_distance - 0.20:\n\t\t\t_forced_damage_best_distance = forced_distance\n\t\t\t_forced_damage_stall_remaining = 3.0\n\t\telse:\n\t\t\t_forced_damage_stall_remaining = maxf(0.0, _forced_damage_stall_remaining - delta)\n\t\tif EnemyNavigationRuntime.has_reached_walkable_target(\n\t\t\tself,\n\t\t\t_forced_damage_target,\n\t\t\tinvestigation_reach_distance,\n\t\t\tnavigation_collision_mask,\n\t\t\tfloor_collision_mask,\n\t\t\tnavigation_clearance,\n\t\t\tfloor_snap_ray_start_height,\n\t\t\tfloor_snap_ray_extra_depth\n\t\t):\n\t\t\t_has_forced_damage_target = false\n\t\t\t_damage_reaction_remaining = 0.0\n\t\t\t_last_seen_position = _forced_damage_target\n\t\t\t_search_remaining = search_duration\n\t\t\t_reset_search_probe()\n\t\telse:\n\t\t\t_chase_position(delta, _forced_damage_target)\n\t\t\tmove_and_slide()\n\t\t\t_update_chase_detour()\n\t\t\tif (\n\t\t\t\t_forced_damage_stall_remaining <= 0.0\n\t\t\t\tand (_navigation_path.is_empty() or _navigation_path_index >= _navigation_path.size())\n\t\t\t):\n\t\t\t\t_has_forced_damage_target = false\n\t\t\t\t_damage_reaction_remaining = 0.0\n\t\t\t\t_last_seen_position = _forced_damage_target\n\t\t\t\t_search_remaining = search_duration\n\t\t\t\t_reset_search_probe()\n\t\t\treturn\n'''
new_forced_red = '''\tif _has_forced_damage_target:\n\t\tif _can_handoff_damage_pursuit_to_combat():\n\t\t\t_has_forced_damage_target = false\n\t\t\t_damage_reaction_remaining = 0.0\n\t\t\t_forced_damage_stall_remaining = 0.0\n\t\t\t_reset_navigation_path()\n\t\telse:\n\t\t\tvar forced_distance := _horizontal_distance(global_position, _forced_damage_target)\n\t\t\tif forced_distance < _forced_damage_best_distance - 0.20:\n\t\t\t\t_forced_damage_best_distance = forced_distance\n\t\t\t\t_forced_damage_stall_remaining = 3.0\n\t\t\telse:\n\t\t\t\t_forced_damage_stall_remaining = maxf(0.0, _forced_damage_stall_remaining - delta)\n\t\t\tif EnemyNavigationRuntime.has_reached_walkable_target(\n\t\t\t\tself,\n\t\t\t\t_forced_damage_target,\n\t\t\t\tinvestigation_reach_distance,\n\t\t\t\tnavigation_collision_mask,\n\t\t\t\tfloor_collision_mask,\n\t\t\t\tnavigation_clearance,\n\t\t\t\tfloor_snap_ray_start_height,\n\t\t\t\tfloor_snap_ray_extra_depth\n\t\t\t):\n\t\t\t\t_has_forced_damage_target = false\n\t\t\t\t_damage_reaction_remaining = 0.0\n\t\t\t\t_last_seen_position = _forced_damage_target\n\t\t\t\t_search_remaining = search_duration\n\t\t\t\t_reset_search_probe()\n\t\t\telse:\n\t\t\t\t_chase_position(delta, _forced_damage_target)\n\t\t\t\tmove_and_slide()\n\t\t\t\t_update_chase_detour()\n\t\t\t\tif (\n\t\t\t\t\t_forced_damage_stall_remaining <= 0.0\n\t\t\t\t\tand (_navigation_path.is_empty() or _navigation_path_index >= _navigation_path.size())\n\t\t\t\t):\n\t\t\t\t\t_has_forced_damage_target = false\n\t\t\t\t\t_damage_reaction_remaining = 0.0\n\t\t\t\t\t_last_seen_position = _forced_damage_target\n\t\t\t\t\t_search_remaining = search_duration\n\t\t\t\t\t_reset_search_probe()\n\t\t\treturn\n'''
replace_once(red, old_forced_red, new_forced_red)
replace_once(
    red,
    '''\t\tvar can_see_player := _get_cached_player_visibility(\n\t\t\tdelta,\n\t\t\tplayer_distance,\n\t\t\tactive_sight_range\n\t\t)\n''',
    '''\t\tvar can_see_player := _get_cached_player_visibility(\n\t\t\tdelta,\n\t\t\tplayer_distance,\n\t\t\tactive_sight_range\n\t\t)\n\t\t# Yakın dövüşçü oyuncunun dibindeyken cache yüzünden saldırı kaçıramaz.\n\t\tif (\n\t\t\tcombat_role == EnemyCombatProfiles.Role.CLOSE\n\t\t\tand player_distance <= attack_range + attack_range_tolerance\n\t\t):\n\t\t\tcan_see_player = _check_line_of_sight()\n\t\t\t_cached_player_visible = can_see_player\n\t\t\tif can_see_player:\n\t\t\t\t_sight_check_remaining = near_sight_interval\n''',
)
replace_once(
    red,
    "\n\nfunc _update_attack_lunge(delta: float) -> void:\n",
    '''\n\nfunc _can_handoff_damage_pursuit_to_combat() -> bool:\n\tif _forced_damage_commit_remaining > 0.0:\n\t\treturn false\n\tif _player == null or not is_instance_valid(_player):\n\t\treturn false\n\tif _horizontal_distance(global_position, _player.global_position) > attack_range + attack_range_tolerance:\n\t\treturn false\n\tif not _check_line_of_sight():\n\t\treturn false\n\t_aggro = true\n\t_cached_player_visible = true\n\t_sight_check_remaining = near_sight_interval\n\t_last_seen_position = _player.global_position\n\t_last_seen_position.y = global_position.y\n\t_lost_sight_remaining = lost_sight_timeout\n\t_search_remaining = search_duration\n\treturn true\n\n\nfunc _update_attack_lunge(delta: float) -> void:\n''',
)

print("enemy attack handoff fix applied")
