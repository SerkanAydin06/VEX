#!/usr/bin/env python3
"""Guard player-facing story content against drift from Story_VEX.md canon."""
from __future__ import annotations

import csv
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


archive = read("scripts/data/vex_archive_database.gd")
terminal = read("scripts/ui/vex_archive_terminal.gd")
bastion = read("scenes/hub/bastion_7.tscn")
survivor = read("scripts/hub/hub_survivor_presence.gd")
records = read("scripts/data/vex_field_record_database.gd")

# Retired prototype operations must not reach the in-game archive.
for retired in ["KÜL MADENİ", "Kül Madeni", "KIRIK OMURGA", "Kırık Omurga", "Ash Mine", "VEX-01 //", "VEX-02 //", "VEX-03 //"]:
    assert retired not in archive, retired
logs = archive[archive.index("const LOGS := ["):archive.index("const PROTOCOLS := [")]
for chapter, title in [(1, "İLK KIRILMA"), (2, "KÜL KORİDORU"), (3, "BASINÇ HATTI")]:
    assert f'"title_tr": "BÖLÜM 0{chapter} // {title}"' in logs, title

# Origin/extraction truths unlock at the chapter where the story reveals them.
expected_reveal = {"korvath": 4, "thornwild": 8, "vaskari": 15, "nhal": 18, "aether": 22}
for universe_id, stage in expected_reveal.items():
    block = archive[archive.index(f'"id": &"{universe_id}"'):]
    block = block[:block.index('"enemy_ids"')]
    assert f'"reveal_stage": {stage},' in block, universe_id
    for field in ["identity_provisional_tr", "identity_provisional_en", "extraction_provisional_tr", "extraction_provisional_en", "name_en"]:
        assert f'"{field}":' in block, (universe_id, field)
assert 'ArchiveDB.universe_story_text(universe, "extraction", GameState.campaign_stage)' in terminal
assert "ArchiveDB.enemy_lore(entry, GameState.campaign_stage)" in terminal
assert 'if GameState.campaign_stage >= int(entry.get("unlock_stage", 0)):' in terminal
protocols = archive[archive.index("const PROTOCOLS := ["):]
for family, stage in [("VASKARI", 11), ("AETHER", 23)]:
    block = protocols[:protocols.index(f'"title_tr": "{family} TEMASI')]
    assert block.rstrip().endswith(f'"unlock_stage": {stage},'), family

# Captain Leyla Sönmez runs Bastion-7 from the end of Chapter 1.
leyla = bastion[bastion.index('[node name="CptLeylaSonmez"'):]
leyla = leyla[:leyla.index("\n\n")]
assert "required_campaign_stage = 1" in leyla
assert 'staged_dialogue_keys = PackedStringArray("HUB_LEYLA_POST_CH01", "HUB_LEYLA_POST_CH02", "HUB_LEYLA_POST_CH03")' in leyla
assert "func get_dialogue_key(campaign_stage: int) -> String:" in survivor
selin = bastion[bastion.index('[node name="DrSelinErdem"'):]
assert "required_campaign_stage = 3" in selin[:selin.index("\n\n")]

keys: dict[str, list[str]] = {}
for csv_path in sorted((ROOT / "translations").glob("*.csv")):
    with csv_path.open(encoding="utf-8") as handle:
        for row in csv.reader(handle):
            if row:
                keys[row[0]] = row[1:]
for key in ["SURVIVOR_LEYLA_NAME", "SURVIVOR_LEYLA_ROLE", "HUB_LEYLA_POST_CH01", "HUB_LEYLA_POST_CH02", "HUB_LEYLA_POST_CH03"]:
    assert key in keys and all(value.strip() for value in keys[key][:2]), key

# Turkish record bodies use the Turkish project name.
for body in re.findall(r'"body_tr": "([^"]*)"', records):
    assert "Zero Source" not in body and "ZERO SOURCE" not in body

# Weapon docs match where the campaign actually hands out each sidearm.
weapons = read("Weapons_VEX.md")
assert "Level 1 gizli bakım deposundan" not in weapons
assert "Bölüm 3 — Basınç Hattı karanlık bakım cebinden" in weapons
assert 'pickup_type = "p07"' in read("scenes/levels/level_03_pressure_line_content.tscn")

print("story consistency audit passed")
