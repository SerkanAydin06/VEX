#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "scripts/autoload/enemy_performance_manager.gd").read_text(encoding="utf-8")

validity_guard = "if player_ref == null or not is_instance_valid(player_ref):"
type_guard = "if not (player_ref is Node3D):"
player_cast = "var player := player_ref as Node3D"
legacy_unsafe_cast = "var player := GameState.player as Node3D"

assert validity_guard in source
assert type_guard in source
assert player_cast in source
assert legacy_unsafe_cast not in source
assert source.index(validity_guard) < source.index(type_guard) < source.index(player_cast)

print("enemy performance scene-transition guard passed")
