#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SCENES = ROOT / "scenes" / "actors"
ACTORS = ROOT / "scripts" / "actors"
PLAYER = ROOT / "scripts" / "player" / "player.gd"


def read(path: Path) -> str:
    assert path.exists(), path
    return path.read_text(encoding="utf-8")


def root_block(scene_name: str) -> str:
    source = read(SCENES / scene_name)
    match = re.search(
        r'^\[node name="[^"]+" type="CharacterBody3D"[^\n]*\]\n(.*?)(?=^\[node |\Z)',
        source,
        re.M | re.S,
    )
    assert match is not None, scene_name
    return match.group(1)


def number(block: str, key: str, default: float | None = None) -> float:
    match = re.search(rf"^{re.escape(key)} = (-?[0-9.eE+-]+)$", block, re.M)
    if match is None:
        assert default is not None, (key, "missing")
        return float(default)
    return float(match.group(1))


player = read(PLAYER)
assert re.search(r"@export_range\(1, 500, 1\) var maximum_health := 100", player)

# Basalt Juggernaut: yüksek can ve sert tek vuruş korunur; karşılığında hareket,
# hazırlık ve mermi hızı normal ranged birimlerden ağır/okunabilir kalmalıdır.
basalt = root_block("basalt_juggernaut.tscn")
assert number(basalt, "maximum_health") >= 220
assert number(basalt, "attack_damage") >= 26
assert number(basalt, "attack_range") >= 14.0
assert number(basalt, "move_speed") <= 2.6
assert number(basalt, "attack_cooldown") >= 1.35
assert number(basalt, "attack_windup") >= 0.38
basalt_projectile = read(SCENES / "basalt_juggernaut_projectile.tscn")
assert "radius = 0.24" in basalt_projectile
basalt_speed = float(re.search(r"(?m)^speed = ([0-9.]+)$", basalt_projectile).group(1))
assert 14.0 <= basalt_speed <= 17.0, basalt_speed

# Vaskari yakın dövüş hiyerarşisi: Raptor takip/tempo birimi, Ravager daha ağır
# darbe ve daha büyük gövde, Bulwark ise en yavaş ve en dayanıklı ön hattır.
raptor = root_block("vaskari_raptor.tscn")
ravager = root_block("vaskari_ravager.tscn")
bulwark = root_block("vaskari_bulwark.tscn")
assert number(raptor, "chase_speed") > number(ravager, "chase_speed")
assert number(raptor, "attack_cooldown") < number(ravager, "attack_cooldown")
assert number(ravager, "maximum_health") > number(raptor, "maximum_health")
assert number(ravager, "attack_damage") > number(raptor, "attack_damage")
assert number(ravager, "attack_lunge_speed") > number(raptor, "attack_lunge_speed")
assert number(bulwark, "maximum_health") > number(ravager, "maximum_health")
assert number(bulwark, "chase_speed") < number(ravager, "chase_speed")
assert number(bulwark, "attack_cooldown") > number(ravager, "attack_cooldown")

# Cinder Hound süratli temas baskısıdır; tanklaşarak Vaskari ön hattının rolünü
# çalmamalı ve tek vuruşu ağır elite seviyesine çıkmamalıdır.
cinderhound = root_block("cinderhound.tscn")
assert number(cinderhound, "maximum_health") < 100
assert number(cinderhound, "chase_speed") >= 7.0
assert number(cinderhound, "attack_damage") <= 18
assert number(cinderhound, "attack_lunge_stop_distance") <= 0.80

# Ranged imza yetenekleri burst/shotgun gücünü kontrol altında tutarken kendi
# okunabilir rollerini korur. Bu değerler scene-owned ability Resource'lardadır.
cinder_settings = read(ACTORS / "cinder_spitter_ability_settings.gd")
assert "burst_shot_count := 2" in cinder_settings
burst_scale = float(re.search(r"burst_damage_scale := ([0-9.]+)", cinder_settings).group(1))
assert 2.0 * burst_scale <= 1.25

ravager_settings = read(ACTORS / "ravager_ability_settings.gd")
precision_scale = float(
    re.search(r"precision_projectile_speed_scale := ([0-9.]+)", ravager_settings).group(1)
)
assert 1.0 < precision_scale <= 1.25

void_settings = read(ACTORS / "voidweaver_ability_settings.gd")
assert "weave_projectile_count := 3" in void_settings
weave_angle = float(re.search(r"weave_half_angle_degrees := ([0-9.]+)", void_settings).group(1))
weave_side_scale = float(re.search(r"weave_side_damage_scale := ([0-9.]+)", void_settings).group(1))
assert weave_angle >= 6.5
assert weave_side_scale <= 0.50
void_scene = read(SCENES / "voidweaver.tscn")
assert "weave_half_angle_degrees = 7.0" in void_scene
assert 'special_ability_settings = SubResource("Resource_voidweaver_ability")' in void_scene

# Utility/control ranged birimleri doğrudan DPS ile ana damage dealer'ları
# geçmemeli; tehditleri görüş bozma, alan kontrolü veya takım desteğinden gelir.
husk = root_block("husk_leech.tscn")
venom = root_block("venom_marshall.tscn")
spore = root_block("spore_matriarch.tscn")
assert number(husk, "attack_damage") <= 14
assert number(husk, "attack_cooldown") >= 1.8
assert number(venom, "attack_damage") <= 18
assert number(venom, "attack_cooldown") >= 2.0
assert number(spore, "attack_cooldown") >= 3.0

print("enemy balance identity audit passed")
