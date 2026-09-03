#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ACTORS = ROOT / "scripts" / "actors"

SCHEMAS = {
    "enemy_combatant_base.gd": [
        "01 - Kimlik, Can ve Zorluk",
        "02 - Hareket ve Sabit Bekleme",
        "03 - Algılama ve Takip",
        "03B - İşitme / Stealth",
        "03C - Görüş Örnekleme",
        "04 - Saldırı",
        "05 - Yol Bulma",
        "05B - Cover Yeniden Konumlanma",
        "06 - Performans",
        "07 - Görsel ve Animasyon",
        "08 - Ölüm Sonrası İz",
        "09 - Özel Yetenekler",
    ],
    "enemy_lunge_base.gd": [
        "01 - Kimlik, Can ve Zorluk",
        "02 - Hareket ve Sabit Bekleme",
        "03 - Algılama ve Takip",
        "03B - İşitme / Stealth",
        "03C - Görüş ve Arama Örnekleme",
        "04 - Saldırı",
        "05 - Yol Bulma",
        "06 - Performans",
        "07 - Görsel ve Animasyon",
        "08 - Ölüm Sonrası İz",
        "09 - Özel Yetenekler",
    ],
}

DOCUMENTED_EXPORT_FILES = [
    "enemy_base.gd",
    *SCHEMAS,
    "warden_ability_settings.gd",
    "furnice_carrier_ability_settings.gd",
    "enemy_hybrid_ability_settings.gd",
    "gorehorn_charge_settings.gd",
]


def read(name: str) -> str:
    path = ACTORS / name
    assert path.exists(), path
    return path.read_text(encoding="utf-8")


enemy_base = read("enemy_base.gd")
assert re.findall(r'@export_category\("([^"]+)"\)', enemy_base) == [
    "01B - Zorluk Çarpanları (Sahne)"
], "enemy_base yalnız ortak zorluk tuning kategorisini sahiplenmeli"

for filename, expected_categories in SCHEMAS.items():
    source = read(filename)
    categories = re.findall(r'@export_category\("([^"]+)"\)', source)
    assert categories == expected_categories, (filename, categories)

for filename in DOCUMENTED_EXPORT_FILES:
    lines = read(filename).splitlines()
    for index, line in enumerate(lines):
        if not line.startswith("@export") or " var " not in line:
            continue
        assert index > 0 and lines[index - 1].startswith("## "), (
            filename,
            index + 1,
            "Türkçe Inspector açıklaması eksik",
            line,
        )
        description = lines[index - 1].removeprefix("## ").strip()
        assert len(description) >= 20, (filename, index + 1, "açıklama çok kısa")

warden_script = read("crucible_warden.gd")
furnice_script = read("furnice_carrier.gd")
assert "@export" not in warden_script
assert "@export" not in furnice_script
hybrid_script = read("enemy_hybrid_base.gd")
briar_script = read("briar_skulker.gd")
gorehorn_script = read("gorehorn.gd")
assert "@export" not in hybrid_script
assert "@export" not in briar_script
assert "@export" not in gorehorn_script
assert not hybrid_script.startswith("@tool\n")
assert not briar_script.startswith("@tool\n")
assert not gorehorn_script.startswith("@tool\n")
assert "var _ability: VexWardenAbilitySettings" in warden_script
assert "var _ability: VexFurniceCarrierAbilitySettings" in furnice_script

warden_scene = (ROOT / "scenes/actors/crucible_warden.tscn").read_text(encoding="utf-8")
furnice_scene = (ROOT / "scenes/actors/furnice_carrier.tscn").read_text(encoding="utf-8")
assert 'special_ability_settings = SubResource("Resource_warden_ability")' in warden_scene
assert 'special_ability_settings = SubResource("Resource_furnice_ability")' in furnice_scene
briar_scene = (ROOT / "scenes/actors/briar_skulker.tscn").read_text(encoding="utf-8")
assert 'special_ability_settings = SubResource("Resource_hybrid_settings")' in briar_scene

print("enemy Inspector documentation audit passed")
