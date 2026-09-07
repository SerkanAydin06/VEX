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

EXPECTED_CHAPTERS = [
    "İlk Kırılma",
    "Kül Koridoru",
    "Basınç Hattı",
    "Erimiş Damar",
    "Sönen Çekirdek",
    "Yeşil Karantina",
    "Diken İzleri",
    "Boynuz Geçidi",
    "Spor Bahçesi",
    "Köklerin Hafızası",
    "Mor Cephe",
    "Kırıcı Hat",
    "Mızrak Menzili",
    "Kalkan Duvarı",
    "Zehirli Emir",
    "Sessiz Gökyüzü",
    "Perde Altında",
    "Kör Nokta",
    "Av Yolları",
    "Sesi Olmayan Dünya",
    "Cam Deniz",
    "Örüntü Hatası",
    "Faz Yarığı",
    "Kırık Geometri",
    "Dokuma Merkezi",
    "Kesişim Hattı",
    "Bastion Kuşatması",
    "Sıfır Kaynak",
    "Nexus Eşiği",
    "Sessiz Merkez",
]


def test_campaign_has_thirty_numbered_field_chapters() -> None:
    story = STORY.read_text(encoding="utf-8")
    matches = re.findall(r"^## Bölüm (\d+) — (.+)$", story, flags=re.MULTILINE)

    assert "30 bölümlük ana kampanya planı" in story
    assert "Güncel ana kampanya: **30 bölüm**." in story
    assert [int(number) for number, _ in matches] == list(range(1, 31))
    assert [title for _, title in matches] == EXPECTED_CHAPTERS
    assert "Bastion-7 numaralı bir bölüm değildir" in story


def test_player_facing_campaign_no_longer_uses_vex_numbered_operation_titles() -> None:
    story = STORY.read_text(encoding="utf-8")

    assert "Oyuncuya dönük bölüm adlandırmasında **VEX-01 / VEX-02 / VEX-03 dizilimi kullanılmaz**" in story
    assert "## Bölüm 1 — VEX-01" not in story
    assert "## Bölüm 2 — VEX-02" not in story
    assert "## Bölüm 3 — VEX-03" not in story


def test_first_twenty_five_chapters_use_five_chapter_reality_blocks() -> None:
    story = STORY.read_text(encoding="utf-8")

    expected_blocks = {
        "1-5": "Korvath Ocağı",
        "6-10": "Thornwild Sürüsü",
        "11-15": "Vaskari Lejyonu",
        "16-20": "Nhal Veil",
        "21-25": "Aether Loom",
        "26-30": "Yakınsama / Nexus",
    }
    for chapter_range, reality in expected_blocks.items():
        assert f"| {chapter_range} | {reality} |" in story

    assert "İlk 25 bölümde" in story
    assert "ilk bölümlerde karışık evren spawn'ları kullanılmaz" in story
    assert "Bu, kampanyadaki ilk gerçek karma evren bölümüdür" in story


def test_active_enemy_introductions_are_gradual_and_complete() -> None:
    story = STORY.read_text(encoding="utf-8")
    enemies = ENEMIES.read_text(encoding="utf-8")

    expected_intro = {
        "Cinder Hound": "1",
        "Cinder Spitter": "2",
        "Basalt Juggernaut": "3",
        "Furnace Carrier": "4",
        "Crucible Warden": "5",
        "Ravager": "6",
        "Briar Skulker": "7",
        "Gorehorn": "8",
        "Spore Matriarch": "9",
        "Vaskari Raptor": "11",
        "Vaskari Ravager": "12",
        "Coil Lancer": "13",
        "Vaskari Bulwark": "14",
        "Venom Marshall": "15",
        "Veilmaw": "16",
        "Husk Leech": "18",
        "Voidweaver": "21",
        "Rift Reaver": "23",
    }

    assert "Güncel aktif roster: **18 yaratık**." in enemies
    assert "# 18 aktif yaratığın kademeli tanıtım matrisi" in story
    for enemy_name in ACTIVE_ENEMIES:
        assert enemy_name in enemies
        assert enemy_name in expected_intro
        assert f"| {enemy_name} |" in story
        row = next(line for line in story.splitlines() if line.startswith(f"| {enemy_name} |"))
        assert f"| {expected_intro[enemy_name]} |" in row


def test_planned_enemies_remain_optional_and_outside_active_roster() -> None:
    story = STORY.read_text(encoding="utf-8")
    enemies = ENEMIES.read_text(encoding="utf-8")

    assert "bu 30 bölümlük ana kampanyanın zorunlu parçası değildir" in story
    for enemy_name in PLANNED_ENEMIES:
        assert enemy_name in enemies
        assert enemy_name in story


def test_story_preserves_non_alliance_rule_for_mixed_final_encounters() -> None:
    story = STORY.read_text(encoding="utf-8")

    assert "tek bir ortak “xeno ordusu” gibi anlatılmaz" in story
    assert "Bu ortak ittifak anlamına gelmez" in story
    assert "Karma encounter, evrenlerin ittifak kurduğu anlamına gelmez" in story


def test_story_keeps_gameplay_source_of_truth_and_avoids_unimplemented_final_boss_requirement() -> None:
    story = STORY.read_text(encoding="utf-8")

    assert "`Enemies_VEX.md` ile `scenes/actors/*.tscn` ve ilgili scriptler kaynak-of-truth'tur" in story
    assert "uygulanmış ayrı bir insan boss sistemi olmadığı sürece" in story
    assert "finalin başarısı Vardar'ın can barını sıfırlamak değildir" in story
    assert "oyunda olmayan invisibility, sınırsız teleport, ally buff" in story


def test_core_story_reveal_ladder_is_present() -> None:
    story = STORY.read_text(encoding="utf-8")

    required_reveals = [
        "Korvath yalnızca **birinci kaynaktır**",
        "onu daha verimli sömürmek için davranışını modellemiştir",
        "Harici uygarlık tepkisi projenin stratejik değerini değiştirmez",
        "Kendi bağlantılarını dengeleyen bir ağ hâline gelmiştir",
        "Merkezin eski proje adı: **NEXUS**",
        "**Ters Akış Protokolü**",
        "Ana ağı susturduk",
    ]
    for reveal in required_reveals:
        assert reveal in story
