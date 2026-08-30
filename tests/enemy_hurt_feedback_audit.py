#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
base = (ROOT / "scripts/actors/enemy_base.gd").read_text(encoding="utf-8")
combatant = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
lunge = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")

for needle in [
    "func _trigger_damage_shake(",
    "func _update_damage_shake(",
    "func _clear_damage_shake(",
    "_damage_shake_origin_offset",
    "visual.offset =",
]:
    assert needle in base, needle

for source in (combatant, lunge):
    for needle in [
        "var hurt_shake_enabled := true",
        "var hurt_shake_duration :=",
        "var hurt_shake_amount_pixels :=",
        "var hurt_shake_frequency :=",
        "_update_damage_shake(animated_sprite, delta, hurt_shake_frequency)",
        "_trigger_damage_shake(",
        "_clear_damage_shake(animated_sprite)",
    ]:
        assert needle in source, needle
    for forbidden in [
        'play(&"hurt")',
        '_play_animation(&"hurt")',
        "hurt_reaction_duration",
        "hurt_stops_movement",
        "hurt_flash_duration",
        "hurt_frame_y_offsets",
        "_hurt_anim_locked",
        "_hurt_reaction_locked",
    ]:
        assert forbidden not in source, forbidden

for scene_path in sorted((ROOT / "scenes/actors").glob("*.tscn")):
    if "projectile" in scene_path.name:
        continue
    scene = scene_path.read_text(encoding="utf-8")
    assert '"name": &"hurt"' not in scene, scene_path
    assert "hurt_frame_y_offsets =" not in scene, scene_path
    assert "hurt_reaction_duration =" not in scene, scene_path
    assert "hurt_flash_duration =" not in scene, scene_path

print("enemy hurt feedback audit passed")
