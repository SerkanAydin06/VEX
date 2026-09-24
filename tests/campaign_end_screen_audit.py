#!/usr/bin/env python3
"""Validate the one-time interim campaign end screen after the last playable chapter."""
from __future__ import annotations

import csv
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


game_state = read("scripts/autoload/game_state.gd")
base_level = read("scripts/levels/base_level.gd")
screen_scene = read("scenes/ui/campaign_end.tscn")
screen_script = read("scripts/ui/campaign_end.gd")

# Exactly one playable chapter (Inspector-authored) opens the interim end screen.
flagged = [
    path.name
    for path in sorted((ROOT / "scenes/levels").glob("level_0*.tscn"))
    if re.search(r"^shows_campaign_end_screen = true$", path.read_text(encoding="utf-8"), re.M)
]
assert flagged == ["level_03.tscn"], flagged
assert "@export var shows_campaign_end_screen := false" in base_level
assert "func get_shows_campaign_end_screen() -> bool:" in base_level

# Shown only on the first completion, before Bastion, and never leaked across runs.
assert 'const CAMPAIGN_END_PATH := "res://scenes/ui/campaign_end.tscn"' in game_state
complete = game_state[game_state.index("func complete_level("):game_state.index("func has_pending_next_level")]
assert "var previous_campaign_stage := campaign_stage" in complete
assert "campaign_stage > previous_campaign_stage" in complete
assert complete.index("var previous_campaign_stage") < complete.index("_register_campaign_completion(current_scene)")
cont = game_state[game_state.index("func continue_to_next_level("):game_state.index("func pending_next_is_hub")]
assert cont.index('"level_complete_retry"') < cont.index("if pending_campaign_end_screen:")
assert cont.index("if pending_campaign_end_screen:") < cont.index('pending_next_level_path = ""')
assert "pending_campaign_end_screen = false" in cont
reset = game_state[game_state.index("func _reset_level_counters("):]
assert "pending_campaign_end_screen = false" in reset

# Screen continues through GameState so the preserved Bastion boundary is used.
assert 'path="res://scripts/ui/campaign_end.gd"' in screen_scene
assert "GameState.continue_to_next_level()" in screen_script
assert "GameState.return_to_main_menu" in screen_script

keys: dict[str, list[str]] = {}
for csv_path in sorted((ROOT / "translations").glob("*.csv")):
    with csv_path.open(encoding="utf-8") as handle:
        for row in csv.reader(handle):
            if row:
                keys[row[0]] = row[1:]
for key in sorted(set(re.findall(r'^text = "([A-Z0-9_]+)"$', screen_scene, re.M))):
    assert key in keys, key
    assert all(value.strip() for value in keys[key][:2]), key

print("campaign end screen audit passed")
