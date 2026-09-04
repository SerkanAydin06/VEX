#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ACTORS = ROOT / "scripts" / "actors"
SCENES = ROOT / "scenes" / "actors"


def read(path: Path) -> str:
    assert path.exists(), path
    return path.read_text(encoding="utf-8")


helper = read(ACTORS / "enemy_projectile_fire_runtime.gd")
ravager = read(ACTORS / "ravager.gd")
cinder = read(ACTORS / "cinder_spitter.gd")
veilmaw = read(ACTORS / "veilmaw.gd")
voidweaver = read(ACTORS / "voidweaver.gd")

ravager_scene = read(SCENES / "ravager.tscn")
cinder_scene = read(SCENES / "cinder_spitter.tscn")
veilmaw_scene = read(SCENES / "veilmaw.tscn")
voidweaver_scene = read(SCENES / "voidweaver.tscn")

# Özel projectile imzaları ortak launch/lead hesabını tek helper'da paylaşır.
for token in [
    "EnemyCombatRuntime.calculate_intercept_time",
    'projectile.set("speed", projectile_speed)',
    'projectile.call("launch", shot_direction, source, maxi(1, damage))',
]:
    assert token in helper, token

# Ravager: tek, uzun menzilli ve normal projectile'dan daha hızlı precision shot.
assert "precision_projectile_speed_scale := 1.18" in ravager
assert "ProjectileFireRuntime.fire(" in ravager
assert re.search(r"^attack_range = 20\.0$", ravager_scene, re.M)
assert re.search(r"^projectile_lead_factor = 0\.95$", ravager_scene, re.M)

# Cinder Spitter: tek attack komutunda iki düşük hasarlı projectile'lık kısa seri.
assert "burst_shot_count := 2" in cinder
assert "burst_interval := 0.12" in cinder
assert "burst_damage_scale := 0.60" in cinder
assert "timer.timeout.connect(_fire_burst_followup.bind(combat_generation))" in cinder
assert re.search(r"^attack_range = 14\.0$", cinder_scene, re.M)

# Veilmaw: her atıştan sonra yeni görüş açısı arayan harrier.
assert "post_shot_reposition_duration := 0.65" in veilmaw
assert "_has_ranged_reposition_target = false" in veilmaw
assert "_reposition_for_clear_shot(delta)" in veilmaw
assert re.search(r"^attack_range = 12\.0$", veilmaw_scene, re.M)

# Voidweaver: merkez tam hasar + düşük hasarlı yan kollardan oluşan enerji fanı.
assert '"Üçlü:3"' in voidweaver
assert "weave_projectile_count := 3" in voidweaver
assert "weave_half_angle_degrees := 5.0" in voidweaver
assert "weave_side_damage_scale := 0.45" in voidweaver
assert "lerpf(" in voidweaver
assert re.search(r"^attack_range = 13\.5$", voidweaver_scene, re.M)
assert "accepts_weapon_hit" in voidweaver

print("ranged enemy identity audit passed")
