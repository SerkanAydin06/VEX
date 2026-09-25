from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
PLAN = ROOT / "docs" / "levels" / "Level_01_First_Fracture.md"
CAMPAIGN = ROOT / "docs" / "Campaign_Level_Design_VEX.md"
ENEMIES = ROOT / "Enemies_VEX.md"


def _text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


# The plan was rewritten from an early production draft into the implemented
# canonical spec (docs/levels/Level_01_First_Fracture.md); these checks follow it.
def _section(plan: str, heading: str) -> str:
    start = plan.index(heading)
    next_heading = plan.find("\n## ", start + len(heading))
    return plan[start:] if next_heading < 0 else plan[start:next_heading]


def test_level_01_plan_exists_and_targets_first_fracture() -> None:
    plan = _text(PLAN)
    assert plan.startswith("# VEX — Bölüm 1: İlk Kırılma")
    goal = _section(plan, "## 1. Bölüm hedefi")
    assert "**18–20 dakika**" in goal
    assert "Evren odağı: **Korvath Ocağı**" in goal
    assert "Çıkış: **Bastion-7**" in goal


def test_all_existing_room_ids_are_accounted_for() -> None:
    # The 37-room skeleton is enforced against the structure scene by
    # static_audit/integrity_test; the plan must still declare it kept.
    plan = _text(PLAN)
    assert "37 odalık geometri ve kapı omurgası korunuyor" in plan


def test_level_01_uses_only_cinder_hound_as_active_enemy() -> None:
    plan = _text(PLAN)
    campaign = _text(CAMPAIGN)
    enemies = _text(ENEMIES)
    assert "Aktif düşman türü: yalnız **Cinder Hound**" in plan
    assert "Ravager ve Veilmaw bu bölümün kanonik içeriği değildir" in plan
    assert "**Yeni yaratık:** Cinder Hound" in campaign
    assert "Cinder Hound" in enemies


def test_p01_is_the_only_canonical_chapter_one_weapon_unlock() -> None:
    plan = _text(PLAN)
    campaign = _text(CAMPAIGN)
    assert "İlk kalıcı silah: **P-01 Taktik Tabanca**" in plan
    assert "SG-04, P-07, P-14, P-20, Gece Görüşü" in plan
    assert "| 1 | P-01 | Oynanabilir |" in campaign


def test_three_story_records_have_explicit_locations_and_roles() -> None:
    plan = _text(PLAN)
    records = _section(plan, "## 8. Kayıtlar ve kalıcı arşiv")
    for heading in [
        "### R03 — OLAY / Acil Test Emri / 04:17",
        "### R17 — PERSONEL / Güvenlik Kamerası 07",
        "### R29 — TEKNİK / Enerji Üretmiyoruz",
    ]:
        assert heading in records
    assert records.count("\n### R") == 3


def test_key_and_secret_route_preserve_existing_level_skeleton() -> None:
    plan = _text(PLAN)
    access = _section(plan, "## 9. Erişim akışı")
    assert "Mavi kart: **R17**" in access
    assert "Kırmızı kart: **R33**" in access
    assert "**R35 → R37**, mavi + kırmızı kart ister" in access
    assert "Secret: **R29 bakım/arşiv cebi**" in plan


def test_no_checkpoint_level_has_required_resupply_windows() -> None:
    plan = _text(PLAN)
    assert "Bölüm içinde checkpoint yoktur." in plan
    assert "**mid-level checkpoint oluşturmaz**" in plan
    resupply = _section(plan, "## 7. Kaynak ekonomisi")
    assert "- R23 — 24 mermi + 25 sağlık + 16 zırh" in resupply
    assert "- R35 — 24 mermi + 25 sağlık + 15 zırh" in resupply


def test_enemy_species_id_is_not_repurposed_for_tutorial_gates() -> None:
    plan = _text(PLAN)
    assert "Enemy species ID tutorial için değiştirilmez" in plan
    assert "kanonik `cinderhound` kimliğini kullanır" in plan


def test_scene_authority_is_preserved_for_level_placements() -> None:
    plan = _text(PLAN)
    assert "species sahnesi kaynak-of-truth olarak kalır" in plan
    assert "fiziksel terminalin konumu ve prop sunumu bölüm sahnesinde kalır" in plan


def test_level_end_routes_to_bastion() -> None:
    plan = _text(PLAN)
    assert "Bastion-7 koordinatına yönlendirilir" in plan
    assert "R37 Bastion-7'ye dönüyor" in plan


if __name__ == "__main__":
    # Betik olarak çalıştırıldığında (validate_local.ps1) test_ fonksiyonlarını
    # tanım sırasıyla çalıştır; pytest gerekmez.
    _audit_tests = [value for name, value in list(globals().items()) if name.startswith("test_") and callable(value)]
    for _audit_test in _audit_tests:
        _audit_test()
    print(f"{__file__.rsplit('/', 1)[-1]}: {len(_audit_tests)} test passed")
