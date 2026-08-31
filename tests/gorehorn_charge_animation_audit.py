#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SCENE = (ROOT / "scenes/actors/gorehorn.tscn").read_text(encoding="utf-8")
SCRIPT = (ROOT / "scripts/actors/gorehorn.gd").read_text(encoding="utf-8")


def animation_block(name: str) -> str:
    blocks = re.findall(r'\{\n"frames": \[.*?\n\}', SCENE, re.S)
    for block in blocks:
        if f'"name": &"{name}"' in block:
            return block
    raise AssertionError(f"animation not found: {name}")


attack = animation_block("attack")
death = animation_block("death")

assert '"loop": true' in attack, "Gorehorn attack must loop for the full charge run"
assert '"speed": 6.5' in attack
assert '"loop": false' in death, "Death animation must remain one-shot"
assert '_play_animation(&"attack")' in SCRIPT
assert 'while _is_current_charge_attack(attack_generation) and _charge_active:' in SCRIPT
assert '_play_animation(&"idle")' in SCRIPT

print("gorehorn charge animation audit passed")
