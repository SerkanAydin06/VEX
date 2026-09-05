#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SCENES = ROOT / "scenes" / "actors"
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


def resource_block(scene_name: str, resource_id: str) -> str:
    source = read(SCENES / scene_name)
    match = re.search(
        rf'^\[sub_resource type="Resource" id="{re.escape(resource_id)}"\]\n(.*?)(?=^\[|\Z)',
        source,
        re.M | re.S,
    )
    assert match is not None, (scene_name, resource_id)
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
basalt_speed_match = re.search(r"(?m)^speed = ([0-9.]+)$", basalt_projectile)
assert basalt_speed_match is not None
basalt_speed = float(basalt_speed_match.group(1))
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

# Ranged imza yeteneklerinin gerçek tuning kaynağı scene-owned Resource'dur.
# Script varsayılanları değil, Inspector'da serialize edilen değerler denetlenir.
cinder_ability = resource_block("cinder_spitter.tscn", "Resource_cinder_spitter_ability")
burst_count = int(number(cinder_ability, "burst_shot_count"))
burst_interval = number(cinder_ability, "burst_interval")
burst_scale = number(cinder_ability, "burst_damage_scale")
assert burst_count == 2
assert 0.08 <= burst_interval <= 0.18
assert float(burst_count) * burst_scale <= 1.25

ravager_ability = resource_block("ravager.tscn", "Resource_ravager_ability")
precision_scale = number(ravager_ability, "precision_projectile_speed_scale")
assert 1.0 < precision_scale <= 1.25

veilmaw_ability = resource_block("veilmaw.tscn", "Resource_veilmaw_ability")
reposition_duration = number(veilmaw_ability, "post_shot_reposition_duration")
assert 0.45 <= reposition_duration <= 0.85

void_ability = resource_block("voidweaver.tscn", "Resource_voidweaver_ability")
weave_count = int(number(void_ability, "weave_projectile_count"))
weave_angle = number(void_ability, "weave_half_angle_degrees")
weave_side_scale = number(void_ability, "weave_side_damage_scale")
assert weave_count == 3
assert weave_angle >= 6.5
assert weave_side_scale <= 0.50

for scene_name, resource_id in {
    "ravager.tscn": "Resource_ravager_ability",
    "cinder_spitter.tscn": "Resource_cinder_spitter_ability",
    "veilmaw.tscn": "Resource_veilmaw_ability",
    "voidweaver.tscn": "Resource_voidweaver_ability",
}.items():
    scene = read(SCENES / scene_name)
    assert f'special_ability_settings = SubResource("{resource_id}")' in scene, scene_name

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
