from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
PLAN = ROOT / "docs" / "Campaign_Level_Design_VEX.md"
STORY = ROOT / "Story_VEX.md"
WEAPONS = ROOT / "Weapons_VEX.md"


CHAPTERS = [
    "İLK KIRILMA",
    "KÜL KORİDORU",
    "BASINÇ HATTI",
    "ERİMİŞ DAMAR",
    "SÖNEN ÇEKİRDEK",
    "YEŞİL KARANTİNA",
    "DİKEN İZLERİ",
    "BOYNUZ GEÇİDİ",
    "SPOR BAHÇESİ",
    "KÖKLERİN HAFIZASI",
    "MOR CEPHE",
    "KIRICI HAT",
    "MIZRAK MENZİLİ",
    "KALKAN DUVARI",
    "ZEHİRLİ EMİR",
    "SESSİZ GÖKYÜZÜ",
    "PERDE ALTINDA",
    "KÖR NOKTA",
    "AV YOLLARI",
    "SESİ OLMAYAN DÜNYA",
    "CAM DENİZ",
    "ÖRÜNTÜ HATASI",
    "FAZ YARIĞI",
    "KIRIK GEOMETRİ",
    "DOKUMA MERKEZİ",
    "KESİŞİM HATTI",
    "BASTION KUŞATMASI",
    "SIFIR KAYNAK",
    "NEXUS EŞİĞİ",
    "SESSİZ MERKEZ",
]

WEAPON_SCHEDULE = {
    1: "P-01",
    2: "SG-04",
    3: "P-07",
    4: "VX-47",
    6: "MP-90",
    7: "SG-09",
    9: "P-14",
    10: "VX-58",
    11: "P-20",
    13: "SG-15",
    14: "MP-96",
    15: "VX-72",
    17: "MP-110",
    20: "VX-90",
    21: "LX-01",
    22: "SG-21",
    23: "LX-07",
    24: "MP-120",
    25: "LX-13",
    28: "LX-20",
}


EXPECTED_TOOLS = [
    "FieldLink Veri Modülü",
    "Güç Bypass Kuplörü",
    "Bakım Multi-Tool",
    "Xeno Numune Kiti",
    "Hareket Sensörü",
    "Vaskari Sinyal Çözücü",
    "Gece Görüş Modülü",
    "Toksik Maruziyet Monitörü",
    "Faz Tarayıcı",
    "Faz Sabitleyici",
    "Taşınabilir Yarık Ankrajı",
]


def _chapter_block(plan: str, chapter_number: int) -> str:
    marker = f"## BÖLÜM {chapter_number} — "
    start = plan.index(marker)
    if chapter_number == 30:
        return plan[start:]
    next_marker = f"## BÖLÜM {chapter_number + 1} — "
    return plan[start:plan.index(next_marker, start)]


def test_plan_has_all_thirty_chapters_in_order() -> None:
    plan = PLAN.read_text(encoding="utf-8")
    found = re.findall(r"^## BÖLÜM (\d+) — (.+)$", plan, flags=re.MULTILINE)
    assert len(found) == 30
    assert [int(number) for number, _ in found] == list(range(1, 31))
    assert [name.strip() for _, name in found] == CHAPTERS


def test_every_chapter_has_minimum_duration_and_three_records() -> None:
    plan = PLAN.read_text(encoding="utf-8")
    for chapter_number in range(1, 31):
        block = _chapter_block(plan, chapter_number)
        duration_match = re.search(r"\*\*Hedef süre:\*\* (\d+)[–-](\d+) dk", block)
        assert duration_match is not None, chapter_number
        minimum = int(duration_match.group(1))
        maximum = int(duration_match.group(2))
        assert minimum >= 18, chapter_number
        assert maximum >= 20, chapter_number
        records_match = re.search(
            r"### Kayıtlar\n(.*?)(?:\n### |\n---|\Z)",
            block,
            flags=re.DOTALL,
        )
        assert records_match is not None, chapter_number
        numbered_records = re.findall(r"^\d+\. \*\*", records_match.group(1), flags=re.MULTILINE)
        assert len(numbered_records) == 3, chapter_number


def test_first_twenty_five_chapters_keep_reality_blocks_separate() -> None:
    plan = PLAN.read_text(encoding="utf-8")
    assert "İlk 25 bölümde farklı evren aileleri ana encounter içinde karıştırılmaz." in plan
    assert "İlk karma evren operasyonu:** Evet" in _chapter_block(plan, 26)
    for chapter_number in range(1, 26):
        assert "İlk karma evren operasyonu:** Evet" not in _chapter_block(plan, chapter_number)


def test_twenty_weapon_acquisition_schedule_is_explicit() -> None:
    plan = PLAN.read_text(encoding="utf-8")
    assert len(WEAPON_SCHEDULE) == 20
    for chapter_number, weapon_name in WEAPON_SCHEDULE.items():
        assert f"| {chapter_number} | {weapon_name} |" in plan
    assert "| 28 | LX-20 | Planlandı |" in plan


def test_equipment_progression_and_existing_night_vision_are_distinguished() -> None:
    plan = PLAN.read_text(encoding="utf-8")
    for tool_name in EXPECTED_TOOLS:
        assert tool_name in plan
    assert "Gece görüşü:** gerçek pickup" in plan
    assert "runtime sistemleri uygulanmadan aktif kabul edilmez" in plan


def test_discovery_cards_are_not_confused_with_platform_achievements() -> None:
    plan = PLAN.read_text(encoding="utf-8")
    assert "Bu sistem gerçek platform achievement'ı değildir." in plan
    assert "YENİ XENO KAYDI" in plan
    assert "SİLAH ARŞİVİ GÜNCELLENDİ" in plan
    assert "SAHA EKİPMANI KAZANILDI" in plan
    assert "KAYIT ÇÖZÜLDÜ" in plan
    assert "GERÇEKLİK PROFİLİ GÜNCELLENDİ" in plan


def test_story_and_weapon_sources_remain_canonical() -> None:
    plan = PLAN.read_text(encoding="utf-8")
    story = STORY.read_text(encoding="utf-8")
    weapons = WEAPONS.read_text(encoding="utf-8")
    assert "Güncel ana kampanya: **30 bölüm**." in story
    assert "**Planlanan toplam:** 20 silah" in weapons
    assert "Story_VEX.md" in plan
    assert "Weapons_VEX.md" in plan
