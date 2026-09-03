#!/usr/bin/env python3
from pathlib import Path

combatant_path = Path("scripts/actors/enemy_combatant_base.gd")
combatant = combatant_path.read_text(encoding="utf-8")
combatant_replacements = {
    "@export_range(0.15, 2.0, 0.05) var ranged_cover_reposition_refresh := 0.55":
        "var ranged_cover_reposition_refresh := 0.55",
    "@export_range(1, 12, 1) var search_path_attempts := 4":
        "var search_path_attempts := 4",
}
for old, new in combatant_replacements.items():
    count = combatant.count(old)
    if count != 1:
        raise SystemExit(f"combatant expected one match for {old!r}, found {count}")
    combatant = combatant.replace(old, new, 1)
combatant_path.write_text(combatant, encoding="utf-8")

lunge_path = Path("scripts/actors/enemy_lunge_base.gd")
lunge = lunge_path.read_text(encoding="utf-8")
patrol_block = (
    "## devriye ulaşma mesafe değeridir (metre).\n"
    "@export_range(0.1, 1.5, 0.05) var patrol_reach_distance := 0.35\n"
)
if lunge.count(patrol_block) != 1:
    raise SystemExit(f"lunge expected one patrol_reach_distance block, found {lunge.count(patrol_block)}")
lunge = lunge.replace(patrol_block, "", 1)
old_detour = "@export_range(0.0, 3.0, 0.05) var detour_duration := 0.55"
if lunge.count(old_detour) != 1:
    raise SystemExit(f"lunge expected one detour_duration declaration, found {lunge.count(old_detour)}")
lunge = lunge.replace(old_detour, "var detour_duration := 0.55", 1)
lunge_path.write_text(lunge, encoding="utf-8")

audit_path = Path("tests/enemy_role_ai_audit.py")
audit = audit_path.read_text(encoding="utf-8")
old_block = '''for setting in [
    "local_detour_duration", "local_detour_clearance_multiplier",
    "local_detour_min_step", "local_detour_lateral_multipliers",
    "local_detour_forward_multipliers",
]:
    assert re.search(rf"^var {setting}\\b", ravager, re.M), setting
    assert not re.search(rf"@export[^\\n]*\\bvar {setting}\\b", ravager), setting
'''
new_block = '''for setting in [
    "local_detour_duration", "local_detour_clearance_multiplier",
    "local_detour_min_step", "local_detour_lateral_multipliers",
    "local_detour_forward_multipliers", "ranged_cover_reposition_refresh",
    "search_path_attempts",
]:
    assert re.search(rf"^var {setting}\\b", ravager, re.M), setting
    assert not re.search(rf"@export[^\\n]*\\bvar {setting}\\b", ravager), setting

assert re.search(r"^var detour_duration\\b", red, re.M)
assert not re.search(r"@export[^\\n]*\\bvar detour_duration\\b", red)
assert "patrol_reach_distance" not in red
'''
if audit.count(old_block) != 1:
    raise SystemExit(f"expected one enemy_role internal block, found {audit.count(old_block)}")
audit = audit.replace(old_block, new_block, 1)
audit_path.write_text(audit, encoding="utf-8")
