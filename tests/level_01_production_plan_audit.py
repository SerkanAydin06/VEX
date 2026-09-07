from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
PLAN = ROOT / "docs" / "levels" / "Level_01_First_Fracture.md"
CAMPAIGN = ROOT / "docs" / "Campaign_Level_Design_VEX.md"
ENEMIES = ROOT / "Enemies_VEX.md"


def _text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_level_01_plan_exists_and_targets_first_fracture() -> None:
    plan = _text(PLAN)
    assert "# VEX — Bölüm 1 Üretim Planı: İlk Kırılma" in plan
    assert "**18–20 dakika**" in plan
    assert "Ana gerçeklik: **Korvath Ocağı**" in plan


def test_all_existing_room_ids_are_accounted_for() -> None:
    plan = _text(PLAN)
    room_table_match = re.search(
        r"## 6\. Oda oda üretim tablosu\n(.*?)(?:\n## 7\.)",
        plan,
        flags=re.DOTALL,
    )
    assert room_table_match is not None
    room_table = room_table_match.group(1)
    for room_number in range(1, 38):
        room_id = f"R{room_number:02d}"
        assert f"**{room_id}**" in room_table, room_id


def test_level_01_uses_only_cinder_hound_as_active_enemy() -> None:
    plan = _text(PLAN)
    campaign = _text(CAMPAIGN)
    enemies = _text(ENEMIES)

    assert "tek aktif düşman türü **Cinder Hound**" in plan
    assert "**Yeni yaratık:** Cinder Hound" in campaign
    assert "Cinder Hound" in enemies

    migration = plan.split("## 14. Mevcut prototipten migration listesi", 1)[1]
    assert "Ravager encounter'ları" in migration
    assert "Veilmaw encounter'ı" in migration
    assert "Bölüm 1'den çıkarılacak" in migration


def test_p01_is_the_only_canonical_chapter_one_weapon_unlock() -> None:
    plan = _text(PLAN)
    campaign = _text(CAMPAIGN)

    assert "İlk kalıcı silah edinimi **P-01 Taktik Tabanca**" in plan
    assert "P-01 fiziksel güvenlik dolabından alınır" in plan
    assert "| 1 | P-01 | Oynanabilir |" in campaign
    assert "SG-04/P-07/P-20/Gece Görüşü Bölüm 1 kanonik pickup'ı değil" in plan
    assert "Burada **P-07 verilmez**" in plan


def test_three_story_records_have_explicit_locations_and_roles() -> None:
    plan = _text(PLAN)
    expected = {
        "Acil Test Emri / 04:17": "R03",
        "Güvenlik Kamerası 07": "R17",
        "Enerji Üretmiyoruz": "R29",
    }
    for title, room_id in expected.items():
        assert title in plan
        assert room_id in plan

    record_section = plan.split("## 8. Üç ana kayıt", 1)[1].split("## 9.", 1)[0]
    assert record_section.count("### Kayıt ") == 3


def test_key_and_secret_route_preserve_existing_level_skeleton() -> None:
    plan = _text(PLAN)
    assert "**mavi erişim kartı**" in plan
    assert "**Mavi kart**, **Kayıt 2" in plan
    assert "**Kırmızı kart**" in plan
    assert "**R29** | **Gizli Araştırma Arşivi**" in plan
    assert "R17 mavi kart mantığı" in plan
    assert "R33 kırmızı kart mantığı" in plan
    assert "R29 secret alanı" in plan
    assert "R37 final/finish konumu" in plan


def test_no_checkpoint_level_has_required_resupply_windows() -> None:
    plan = _text(PLAN)
    assert "mid-level checkpoint yoktur" in plan
    assert "R23 **ara ikmal odasıdır**" in plan
    assert "R35 öncesinde final ikmali" in plan
    assert "Oyuncunun kritik mühimmatı yalnız secret'a bağlı olmamalıdır" in plan


def test_enemy_species_id_is_not_repurposed_for_tutorial_gates() -> None:
    plan = _text(PLAN)
    assert "species `enemy_id`" in plan
    assert "`cinderhound` kanonik kalıyor" in plan
    assert "Encounter/gate takibi gerekiyorsa ayrı node adı, encounter id veya gate trigger" in plan


def test_scene_authority_is_preserved_for_level_placements() -> None:
    plan = _text(PLAN)
    assert "sahne/Inspector-authoritative kapı ve pickup yerleşimleri" in plan
    assert "düşman/pickup pozisyonları `level_01.gd` içine sabit Vector3 listeleri" in plan


def test_level_end_routes_to_bastion() -> None:
    plan = _text(PLAN)
    assert "**BASTION-7 KOORDİNATI ALINDI**" in plan
    assert "Sonraki sahne Bastion-7 olmalıdır" in plan
