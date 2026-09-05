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
        "04 - İşitme / Stealth",
        "05 - Görüş Örnekleme",
        "06 - Saldırı",
        "07 - Yol Bulma",
        "08 - Cover Yeniden Konumlanma",
        "09 - Performans",
        "10 - Görsel ve Animasyon",
        "11 - Ölüm Sonrası İz",
        "12 - Özel Yetenekler",
    ],
    "enemy_lunge_base.gd": [
        "01 - Kimlik, Can ve Zorluk",
        "02 - Hareket ve Sabit Bekleme",
        "03 - Algılama ve Takip",
        "04 - İşitme / Stealth",
        "05 - Saldırı",
        "06 - Yol Bulma",
        "07 - Performans",
        "08 - Görsel ve Animasyon",
        "09 - Ölüm Sonrası İz",
        "10 - Özel Yetenekler",
    ],
}

SPECIAL_RESOURCE_SCHEMAS = {
    "ravager_ability_settings.gd": [
        "01 - Avcı Atışı",
    ],
    "cinder_spitter_ability_settings.gd": [
        "01 - Kısa Seri",
    ],
    "veilmaw_ability_settings.gd": [
        "01 - Ateş Et / Konum Değiştir",
    ],
    "voidweaver_ability_settings.gd": [
        "01 - Enerji Örgüsü",
    ],
    "warden_ability_settings.gd": [
        "01 - Ground Slam",
        "02 - Heatwave",
        "03 - Zırhlı Zayıf Nokta",
    ],
    "furnice_carrier_ability_settings.gd": [
        "01 - Saldırı Seçimi",
        "02 - Thermal Burst",
    ],
    "enemy_hybrid_ability_settings.gd": [
        "01 - Yakın Saldırı Seçimi",
        "02 - Yakın Saldırı Görsel Hizası",
    ],
    "gorehorn_charge_settings.gd": [
        "01 - Boynuz Şarjı",
        "02 - Darbe Perdesi",
    ],
    "venom_marshall_ability_settings.gd": [
        "01 - Alan Desteği",
        "02 - Görsel Hizalama",
    ],
    "rift_reaver_phase_settings.gd": [
        "01 - Rift Phase",
    ],
    "husk_leech_projectile.gd": [
        "01 - Husk Leech Zehir Görüşü",
    ],
}

DOCUMENTED_EXPORT_FILES = [
    "enemy_base.gd",
    *SCHEMAS,
    *SPECIAL_RESOURCE_SCHEMAS,
]

PRIMARY_CREATURE_SCRIPTS = [
    "ravager.gd",
    "basalt_juggernaut.gd",
    "veilmaw.gd",
    "voidweaver.gd",
    "cinder_spitter.gd",
    "coil_lancer.gd",
    "spore_matriarch.gd",
    "furnice_carrier.gd",
    "crucible_warden.gd",
    "vaskari_raptor.gd",
    "vaskari_ravager.gd",
    "cinderhound.gd",
    "vaskari_bulwark.gd",
    "gorehorn.gd",
    "briar_skulker.gd",
    "venom_marshall.gd",
    "husk_leech.gd",
    "rift_reaver.gd",
]


def read(name: str) -> str:
    path = ACTORS / name
    assert path.exists(), path
    return path.read_text(encoding="utf-8")


def categories(source: str) -> list[str]:
    return re.findall(r'@export_category\("([^"]+)"\)', source)


def assert_sequential(category_names: list[str], filename: str) -> None:
    numbers: list[int] = []
    for category in category_names:
        match = re.match(r"^(\d{2}) - ", category)
        assert match is not None, (filename, "numarasız Inspector kategorisi", category)
        numbers.append(int(match.group(1)))
    assert numbers == list(range(1, len(numbers) + 1)), (
        filename,
        "Inspector kategorileri 01, 02, 03... sırasını izlemiyor",
        numbers,
    )


enemy_base = read("enemy_base.gd")
assert categories(enemy_base) == [
    "01 - Kimlik ve Zorluk",
], "enemy_base ortak kimlik/zorluk sözleşmesini tek 01 kategorisinde sahiplenmeli"

for filename, expected_categories in {**SCHEMAS, **SPECIAL_RESOURCE_SCHEMAS}.items():
    observed = categories(read(filename))
    assert observed == expected_categories, (filename, observed)
    assert_sequential(observed, filename)

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

# Yaratığa özgü tuning doğrudan derived creature scriptine export edilmez.
# Böylece inherited Inspector sırası bozulmaz; özel tuning scene-owned Resource'a gider.
for filename in PRIMARY_CREATURE_SCRIPTS:
    source = read(filename)
    assert "@export" not in source, (filename, "creature scriptinde doğrudan export bulundu")

hybrid_script = read("enemy_hybrid_base.gd")
assert "@export" not in hybrid_script
assert not hybrid_script.startswith("@tool\n")
assert not read("briar_skulker.gd").startswith("@tool\n")
assert not read("gorehorn.gd").startswith("@tool\n")

for filename, type_name in {
    "ravager.gd": "VexRavagerAbilitySettings",
    "cinder_spitter.gd": "VexCinderSpitterAbilitySettings",
    "veilmaw.gd": "VexVeilmawAbilitySettings",
    "voidweaver.gd": "VexVoidweaverAbilitySettings",
    "crucible_warden.gd": "VexWardenAbilitySettings",
    "furnice_carrier.gd": "VexFurniceCarrierAbilitySettings",
    "venom_marshall.gd": "VexVenomMarshallAbilitySettings",
}.items():
    assert f"var _ability: {type_name}" in read(filename), (filename, type_name)

scene_contracts = {
    "ravager.tscn": 'special_ability_settings = SubResource("Resource_ravager_ability")',
    "cinder_spitter.tscn": 'special_ability_settings = SubResource("Resource_cinder_spitter_ability")',
    "veilmaw.tscn": 'special_ability_settings = SubResource("Resource_veilmaw_ability")',
    "voidweaver.tscn": 'special_ability_settings = SubResource("Resource_voidweaver_ability")',
    "crucible_warden.tscn": 'special_ability_settings = SubResource("Resource_warden_ability")',
    "furnice_carrier.tscn": 'special_ability_settings = SubResource("Resource_furnice_ability")',
    "briar_skulker.tscn": 'special_ability_settings = SubResource("Resource_hybrid_settings")',
    "gorehorn.tscn": 'special_ability_settings = SubResource("Resource_gorehorn_charge")',
    "venom_marshall.tscn": 'special_ability_settings = SubResource("Resource_venom_marshall_ability")',
    "rift_reaver.tscn": 'special_ability_settings = SubResource("Resource_rift_phase")',
}
for scene_name, contract in scene_contracts.items():
    scene = (ROOT / "scenes/actors" / scene_name).read_text(encoding="utf-8")
    assert contract in scene, (scene_name, contract)

for scene_name, settings_path in {
    "ravager.tscn": "ravager_ability_settings.gd",
    "cinder_spitter.tscn": "cinder_spitter_ability_settings.gd",
    "veilmaw.tscn": "veilmaw_ability_settings.gd",
    "voidweaver.tscn": "voidweaver_ability_settings.gd",
    "venom_marshall.tscn": "venom_marshall_ability_settings.gd",
    "rift_reaver.tscn": "rift_reaver_phase_settings.gd",
}.items():
    scene = (ROOT / "scenes/actors" / scene_name).read_text(encoding="utf-8")
    assert f'path="res://scripts/actors/{settings_path}"' in scene, (scene_name, settings_path)

venom_scene = (ROOT / "scenes/actors/venom_marshall.tscn").read_text(encoding="utf-8")
for contract in [
    "buff_cast_range = 7.0",
    "buff_cooldown = 11.5",
    "buff_windup = 0.65",
    "buff_recovery = 0.8",
    "buff_refresh_window = 1.2",
]:
    assert contract in venom_scene, contract

print("enemy Inspector documentation audit passed")
