#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENEMIES_DOC = ROOT / "Enemies_VEX.md"
STORY_DOC = ROOT / "Story_VEX.md"
ACTOR_SCENES = ROOT / "scenes" / "actors"

ACTIVE_BY_UNIVERSE = {
    "Korvath Ocağı": [
        ("Basalt Juggernaut", "basalt_juggernaut.tscn"),
        ("Cinder Hound", "cinderhound.tscn"),
        ("Cinder Spitter", "cinder_spitter.tscn"),
        ("Furnace Carrier", "furnice_carrier.tscn"),
        ("Crucible Warden", "crucible_warden.tscn"),
    ],
    "Thornwild Sürüsü": [
        ("Ravager", "ravager.tscn"),
        ("Briar Skulker", "briar_skulker.tscn"),
        ("Gorehorn", "gorehorn.tscn"),
        ("Spore Matriarch", "spore_matriarch.tscn"),
    ],
    "Vaskari Lejyonu": [
        ("Vaskari Raptor", "vaskari_raptor.tscn"),
        ("Vaskari Ravager", "vaskari_ravager.tscn"),
        ("Coil Lancer", "coil_lancer.tscn"),
        ("Vaskari Bulwark", "vaskari_bulwark.tscn"),
        ("Venom Marshall", "venom_marshall.tscn"),
    ],
    "Nhal Veil": [
        ("Veilmaw", "veilmaw.tscn"),
        ("Husk Leech", "husk_leech.tscn"),
    ],
    "Aether Loom": [
        ("Voidweaver", "voidweaver.tscn"),
        ("Rift Reaver", "rift_reaver.tscn"),
    ],
}

PLANNED = [
    "Murk Stalker",
    "Shade Anchor",
    "Rift Spindle",
    "Parallax Drone",
    "Loom Herald",
]


def read(path: Path) -> str:
    assert path.exists(), path
    return path.read_text(encoding="utf-8")


enemies_doc = read(ENEMIES_DOC)
story_doc = read(STORY_DOC)

active_count = sum(len(entries) for entries in ACTIVE_BY_UNIVERSE.values())
assert active_count == 18
assert "Güncel aktif roster: **18 yaratık**." in enemies_doc

for universe, entries in ACTIVE_BY_UNIVERSE.items():
    assert universe in enemies_doc, universe
    assert universe in story_doc, universe
    for display_name, scene_name in entries:
        assert display_name in enemies_doc, ("Enemies_VEX missing", display_name)
        assert display_name in story_doc, ("Story_VEX missing", display_name)
        assert (ACTOR_SCENES / scene_name).exists(), scene_name

for planned_name in PLANNED:
    assert planned_name in enemies_doc, planned_name

# Eski adlandırma ve artık uygulanmayan mekanik vaatleri geri dönmemeli.
for stale_text in [
    "VaskariRaptor",
    "Vaskari Lejyonu — Kızıl Hat",
    "Yön değiştiren mermiler",
]:
    assert stale_text not in enemies_doc, stale_text
    assert stale_text not in story_doc, stale_text

assert "**Müttefik buff'lamaz.**" in enemies_doc
assert "görünmezlik veya faza girip çıkma yeteneği yoktur" in enemies_doc
assert "Yakın dövüş sıçraması yoktur" in enemies_doc
assert "kendi bulunduğu noktada destek alanı kurar" in enemies_doc
assert "yaklaşık 5 saniye" in enemies_doc

# Güncel imza davranışları belgede gerçek gameplay ile aynı kalmalı.
for current_contract in [
    "her atıştan sonra kısa bir reposition penceresiyle",
    "üç kollu enerji örgüsü",
    "Phase noclip değildir",
    "güvenli nokta yoksa normal lunge'a devam eder",
    "Tasarımı tamamlanmadan ve nihai sprite/animasyon seti hazır olmadan aktif roster'a alınmamalıdır",
]:
    assert current_contract in enemies_doc, current_contract

# Aile renkleri: sprite PNG paleti görsel review gerektirir; burada sahnede açıkça
# tanımlı projectile/alan ışıklarının yanlış evren rengine kaymaması korunur.
PALETTE_CONTRACTS = {
    "basalt_juggernaut_projectile.tscn": "light_color = Color(1, 0.16, 0.03, 1)",
    "cinder_spitter_projectile.tscn": "light_color = Color(1, 0.24, 0.04, 1)",
    "briar_skulker_projectile.tscn": "light_color = Color(0.39, 1, 0.12, 1)",
    "spore_matriarch_projectile.tscn": "light_color = Color(0.22, 1, 0.18, 1)",
    "coil_lancer_projectile.tscn": "light_color = Color(0.58, 0.14, 1, 1)",
    "venom_marshall_projectile.tscn": "light_color = Color(0.70, 0.12, 1, 1)",
    "veilmaw_projectile.tscn": "light_color = Color(0.12, 0.42, 1, 1)",
    "husk_leech_projectile.tscn": "light_color = Color(0.34, 1, 0.16, 1)",
    "voidweaver_projectile.tscn": "light_color = Color(0.08, 0.86, 1, 1)",
}
for scene_name, expected_color in PALETTE_CONTRACTS.items():
    scene = read(ACTOR_SCENES / scene_name)
    assert expected_color in scene, (scene_name, expected_color)

# İsim standardı: oyuncuya dönük ad Furnace, geriye dönük dosya/ID ise furnice.
assert "oyuncuya dönük ad **Furnace Carrier**" in enemies_doc
assert "`furnice_carrier`" in enemies_doc
assert "Doğru ad **Venom Marshall**dır" in enemies_doc
assert "`Venom Marshal` kullanılmamalıdır" in enemies_doc

print("enemy design document audit passed")
