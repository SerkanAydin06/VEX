from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
profile = (ROOT / "scripts/actors/enemy_combat_profiles.gd").read_text(encoding="utf-8")
ravager = (ROOT / "scripts/actors/ravager.gd").read_text(encoding="utf-8")
red = (ROOT / "scripts/actors/redviper.gd").read_text(encoding="utf-8")

assert "func damage_pursuit_commit_time" not in profile
for source in (ravager, red):
    assert "var damage_pursuit_commit_time" in source
    assert "_forced_damage_commit_remaining" in source
    assert "_forced_damage_commit_remaining = damage_pursuit_commit_time" in source
    assert "_can_handoff_damage_pursuit_to_combat" in source
    assert "attack_range + attack_range_tolerance" in source
    assert "_check_line_of_sight()" in source

assert "_refresh_close_combat_visibility()" in ravager
assert "combat_role == EnemyCombatProfiles.Role.CLOSE" in red
assert ravager.index("if _has_forced_damage_target:") < ravager.index("if _attack_locked:")
assert red.index("if _has_forced_damage_target:") < red.index("if _attack_locked:")

print("enemy attack handoff audit passed")
