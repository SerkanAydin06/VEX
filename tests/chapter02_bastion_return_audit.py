from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BASTION = ROOT / "scenes" / "hub" / "bastion_7.tscn"
PLAN = ROOT / "docs" / "Campaign_Level_Design_VEX.md"
CH02_TRANSLATIONS = ROOT / "translations" / "chapter02.csv"
MAIN_TRANSLATIONS = ROOT / "translations" / "vex.csv"


def _node_block(scene: str, node_name: str) -> str:
    marker = f'[node name="{node_name}"'
    start = scene.index(marker)
    next_node = scene.find("\n[node ", start + len(marker))
    return scene[start:] if next_node < 0 else scene[start:next_node]


def _chapter_block(plan: str, chapter: int) -> str:
    marker = f"## BÖLÜM {chapter} — "
    start = plan.index(marker)
    next_marker = f"## BÖLÜM {chapter + 1} — "
    end = plan.find(next_marker, start)
    return plan[start:] if end < 0 else plan[start:end]


def test_selin_does_not_appear_after_chapter02_and_first_unlocks_after_chapter03() -> None:
    bastion = BASTION.read_text(encoding="utf-8")
    selin = _node_block(bastion, "DrSelinErdem")

    assert "required_campaign_stage = 3" in selin
    assert "required_campaign_stage = 2" not in selin
    assert 'dialogue_key = "HUB_SELIN_POST_CH03"' in selin
    assert "SURVIVOR_SELIN_DIALOGUE_STAGE2" not in selin
    assert "SURVIVOR_SELIN_DIALOGUE_STAGE3" not in selin


def test_campaign_plan_introduces_selin_in_chapter03_not_chapter02() -> None:
    plan = PLAN.read_text(encoding="utf-8")
    chapter02 = _chapter_block(plan, 2)
    chapter03 = _chapter_block(plan, 3)

    assert "Dr. Selin Erdem" not in chapter02
    assert "**NPC:** Dr. Selin Erdem" in chapter03
    assert "kurtarma ve tahliye hattı" in chapter03


def test_post_rescue_selin_dialogue_matches_pressure_line_canon() -> None:
    translations = CH02_TRANSLATIONS.read_text(encoding="utf-8")

    assert "HUB_SELIN_POST_CH03" in translations
    assert "Basınç Hattı kayıtları akışın rastgele olmadığını gösteriyor" in translations
    assert "Pressure Line records show the flow was not random" in translations


def test_chapter02_bastion_arrival_message_does_not_claim_selin_rescue() -> None:
    translations = MAIN_TRANSLATIONS.read_text(encoding="utf-8")
    row = next(
        line for line in translations.splitlines()
        if line.startswith("HUB_VEX02_COMPLETE,")
    )

    upper = row.upper()
    assert "SELİN" not in upper
    assert "SELIN" not in upper
    assert "VEX-02" in row


def test_firing_range_authored_ceiling_survives_survivor_progression_edits() -> None:
    bastion = BASTION.read_text(encoding="utf-8")
    ceiling = _node_block(bastion, "Ceiling_FiringRange")

    assert 'unique_id=724834527 instance=ExtResource("2_piece")' in ceiling
    assert "-24, 7.2, -10" in ceiling
    assert "piece_size = Vector3(12, 0.4, 10)" in ceiling
    assert 'surface_material = ExtResource("5_ceiling")' in ceiling
    assert "occlusion_enabled = false" in ceiling
