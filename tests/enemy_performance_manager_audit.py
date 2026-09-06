#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANAGER = ROOT / "scripts/autoload/enemy_performance_manager.gd"

source = MANAGER.read_text(encoding="utf-8")

assert 'const VISUAL_PROCESS_MODE_META := &"vex_perf_visual_process_mode"' in source
assert "enemy.set_meta(VISUAL_PROCESS_MODE_META, int(sprite.process_mode))" in source
assert "sprite.process_mode = Node.PROCESS_MODE_DISABLED" in source
assert "sprite.process_mode = previous_mode as Node.ProcessMode" in source
assert "sprite.process_mode = previous_mode\n" not in source

print("Enemy performance manager enum restore audit passed")
