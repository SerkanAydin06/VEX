from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ravager = (ROOT / "scripts/actors/ravager.gd").read_text(encoding="utf-8")
red = (ROOT / "scripts/actors/redviper.gd").read_text(encoding="utf-8")
door = (ROOT / "scripts/props/door.gd").read_text(encoding="utf-8")
warden = (ROOT / "scenes/actors/crucible_warden.tscn").read_text(encoding="utf-8")

assert "var _patrol_forward" not in ravager
assert "var _patrol_forward" not in red
for source in (ravager, red):
    assert '"get_enemy_navigation_step",' in source
    assert "navigation_clearance" in source

for token in [
    "agent_clearance: float = 0.6",
    "safe_clearance + 0.60",
    "enemy_portal_alignment_tolerance",
    "enemy_portal_commit_depth",
    "centered_inside_portal",
    "approach_distance <= alignment_tolerance",
]:
    assert token in door, token

assert "radius = 0.72" in warden
assert "navigation_clearance = 0.75" in warden
print("enemy door passage audit passed")
