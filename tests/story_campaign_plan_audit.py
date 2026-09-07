from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
STORY = ROOT / "Story_VEX.md"
ENEMIES = ROOT / "Enemies_VEX.md"


ACTIVE_ENEMIES = [
    "Basalt Juggernaut",
    "Cinder Hound",
    "Cinder Spitter",
    "Furnace Carrier",
    "Crucible Warden",
    "Ravager",
    "Briar Skulker",
    "Gorehorn",
    "Spore Matriarch",
    "Vaskari Raptor",
    "Vaskari Ravager",
    "Coil Lancer",
    "Vaskari Bulwark",
    "Venom Marshall",
    "Veilmaw",
    "Husk Leech",
    "Voidweaver",
    "Rift Reaver",
]

PLANNED_ENEMIES = [
    "Murk Stalker",
    "Shade Anchor",
    "Rift Spindle",
    "Parallax Drone",
    "Loom Herald",
]


def test_campaign_has_seventeen_numbered_chapters_and_keeps_established_operations() -> None:
    story = STORY.read_text(encoding="utf-8")
    chapter_numbers = [
        int(value)
        for value in re.findall(r"^### Bölüm (\d+) —", story, flags=re.MULTILINE)
    ]

    assert "# Kampanya yapısı — 17 bölüm" in story
    assert chapter_numbers == list(range(1, 18))
    assert "### Bölüm 1 — VEX-01: İlk Kırılma" in story
    assert "### Bölüm 3 — VEX-02: Kırık Omurga" in story
    assert "### Bölüm 4 — VEX-03: Kül Madeni" in story


def test_each_canon_reality_gets_dedicated_campaign_space_before_convergence() -> None:
    story = STORY.read_text(encoding="utf-8")

    expected_focus = {
        "Korvath Ocağı": ["Bölüm 4", "Bölüm 5"],
        "Thornwild Sürüsü": ["Bölüm 6", "Bölüm 7"],
        "Vaskari Lejyonu": ["Bölüm 8", "Bölüm 9"],
        "Nhal Veil": ["Bölüm 10", "Bölüm 11"],
        "Aether Loom": ["Bölüm 12", "Bölüm 13"],
    }
    for universe, chapters in expected_focus.items():
        assert universe in story
        for chapter in chapters:
            assert chapter in story

    assert "### Bölüm 14 — Çöküş Bölgesi" in story
    assert "Farklı evrenlerin yaratıkları tek bir ittifak ordusu değildir." in story


def test_all_eighteen_active_enemies_have_campaign_story_placement() -> None:
    story = STORY.read_text(encoding="utf-8")
    enemies = ENEMIES.read_text(encoding="utf-8")

    assert "Güncel aktif roster: **18 yaratık**." in enemies
    assert "# 18 aktif yaratığın hikâye kullanım matrisi" in story
    for enemy_name in ACTIVE_ENEMIES:
        assert enemy_name in enemies
        assert f"| {enemy_name} |" in story


def test_planned_enemies_are_not_required_by_the_main_campaign() -> None:
    story = STORY.read_text(encoding="utf-8")
    enemies = ENEMIES.read_text(encoding="utf-8")

    assert "bu 17 bölümlük ana planın zorunlu parçası değildir" in story
    for enemy_name in PLANNED_ENEMIES:
        assert enemy_name in enemies
        assert enemy_name in story


def test_story_does_not_recanonize_unimplemented_human_combat_roster() -> None:
    story = STORY.read_text(encoding="utf-8")

    assert "insan asker/dron fraksiyonu bulunmadığı için" in story
    assert "insan askerleri, paralı birlikler, dron ordusu veya Vardar savaş zırhı" in story
    assert "Finalin başarısı Vardar'ın can barını sıfırlamak değil" in story


def test_bastion_story_progression_matches_current_base_management_gates() -> None:
    story = STORY.read_text(encoding="utf-8")

    for percentage in ["%25", "%50", "%75", "%100"]:
        assert percentage in story
    assert "VEX-01 tamamlandı" in story
    assert "Atış Poligonu ve Araştırma Laboratuvarı erişimi açılabilir" in story
    assert "VEX-02 tamamlandı" in story
    assert "Silah Atölyesi ve Mühendislik Bölmesi erişimi açılabilir" in story
    assert "VEX-03 tamamlandı" in story
