from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
profile = (ROOT / "scripts/actors/enemy_combat_profiles.gd").read_text(encoding="utf-8")
ravager = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
combat = (ROOT / "scripts/actors/enemy_combat_runtime.gd").read_text(encoding="utf-8")
red = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")

assert "func damage_pursuit_commit_time" not in profile
for source in (ravager, red):
    assert "var damage_pursuit_commit_time" in source
    assert "_forced_damage_commit_remaining" in source
    assert "_forced_damage_commit_remaining = damage_pursuit_commit_time" in source
    assert "_can_handoff_damage_pursuit_to_combat" in source
    assert "_check_line_of_sight()" in source

assert "EnemyCombatRuntime.can_attempt_damage_handoff(" in ravager
assert "EnemyCombatRuntime.should_check_close_combat_visibility(" in ravager
assert "attack_range + attack_range_tolerance" in ravager
assert "attack_range + attack_range_tolerance" in combat
assert "attack_range + attack_range_tolerance" in red
assert "_refresh_close_combat_visibility()" in ravager
assert "combat_role == EnemyCombatProfiles.Role.CLOSE" in red
# Başlamış saldırı hasar kaynağına yönelme davranışından önce çözülür.
assert ravager.index("if _attack_locked:") < ravager.index("if _has_forced_damage_target:")
assert red.index("if _attack_locked:") < red.index("if _has_forced_damage_target:")

ravager_damage = ravager[
    ravager.index("func take_damage("):ravager.index("func _on_noise_emitted(")
]
red_damage = red[
    red.index("func take_damage("):red.index("func _collision_floor_local_y(")
]
assert "_combat_interrupt_generation += 1" not in ravager_damage
assert "_attack_locked = false" not in ravager_damage
assert "_attack_generation += 1" not in red_damage
assert "_attack_locked = false" not in red_damage
assert "_attack_lunge_remaining = 0.0" not in red_damage

print("enemy attack handoff audit passed")
