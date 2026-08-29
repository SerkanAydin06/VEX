from pathlib import Path

ravager = Path("scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
warden = Path("scripts/actors/crucible_warden.gd").read_text(encoding="utf-8")
red = Path("scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")

assert "retaliation_target = (_source as Node3D).global_position" in ravager
assert "_last_seen_position = retaliation_target" in ravager
assert "func _furthest_walkable_point_toward" in ravager
assert "var candidate_path := graph.get_point_path(start_id, point_index)" in ravager
assert "remaining_distance := _horizontal_distance(approach_point, destination)" in ravager
assert "_is_center_segment_clear(waypoint, destination)" not in ravager
assert "_navigate_to(_player.global_position, delta)" in warden
assert "func _warden_cover_advance_target" not in warden
assert "retaliation_target = (_source as Node3D).global_position" in red
assert "_forced_damage_target = retaliation_target" in red
assert "_last_seen_position = retaliation_target" in red
print("Enemy reachable retaliation audit passed")
