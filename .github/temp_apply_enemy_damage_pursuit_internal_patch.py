from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
BASE_PATH = ROOT / "scripts/actors/enemy_base.gd"
COMBATANT_PATH = ROOT / "scripts/actors/enemy_combatant_base.gd"
LUNGE_PATH = ROOT / "scripts/actors/enemy_lunge_base.gd"
AUDIT_PATH = ROOT / "tests/enemy_script_architecture_audit.py"

# These two values are identical implementation thresholds in both families and
# are not authored by any scene/resource. damage_pursuit_commit_time is NOT in
# this list because Gorehorn deliberately overrides it in its scene.
SHARED_INTERNAL_TARGETS = (
    "damage_pursuit_min_progress",
    "damage_pursuit_stall_timeout",
)

serialized_paths = [
    path
    for serialized_root in (ROOT / "scenes", ROOT / "resources")
    if serialized_root.exists()
    for path in serialized_root.rglob("*")
    if path.suffix in {".tscn", ".tres"}
]
serialized_override_paths: dict[str, list[Path]] = {
    target: [] for target in SHARED_INTERNAL_TARGETS
}
commit_time_overrides: list[Path] = []
for path in serialized_paths:
    text = path.read_text(encoding="utf-8", errors="ignore")
    for target in SHARED_INTERNAL_TARGETS:
        if re.search(rf"(?m)^\s*{re.escape(target)}\s*=", text):
            serialized_override_paths[target].append(path)
    if re.search(r"(?m)^\s*damage_pursuit_commit_time\s*=", text):
        commit_time_overrides.append(path)

for target, paths in serialized_override_paths.items():
    assert not paths, (
        f"serialized override blocks internalization: {target} -> "
        + ", ".join(str(path.relative_to(ROOT)) for path in paths)
    )
assert commit_time_overrides, "damage_pursuit_commit_time must remain authored because a scene overrides it"
assert any(path.relative_to(ROOT).as_posix() == "scenes/actors/gorehorn.tscn" for path in commit_time_overrides), (
    "expected Gorehorn damage_pursuit_commit_time override is missing"
)

base = BASE_PATH.read_text(encoding="utf-8")
combatant = COMBATANT_PATH.read_text(encoding="utf-8")
lunge = LUNGE_PATH.read_text(encoding="utf-8")
audit = AUDIT_PATH.read_text(encoding="utf-8")

combatant_replacements = {
    '''## Yaratığın hasar takip en düşük ilerleme ayarını belirler.\n@export_range(0.01, 1.0, 0.01) var damage_pursuit_min_progress := 0.20\n''': "",
    '''## hasar takip tıkanma timeout değeridir (saniye).\n@export_range(0.1, 10.0, 0.1) var damage_pursuit_stall_timeout := 3.0\n''': "",
}
lunge_replacements = {
    '''## Yaratığın hasar takip en düşük ilerleme ayarını belirler.\n@export_range(0.01, 1.0, 0.01) var damage_pursuit_min_progress := 0.20\n''': "",
    '''## hasar takip tıkanma timeout değeridir (saniye).\n@export_range(0.1, 10.0, 0.1) var damage_pursuit_stall_timeout := 3.0\n''': "",
}

for old, new in combatant_replacements.items():
    assert combatant.count(old) == 1, f"combatant declaration changed: {old.splitlines()[-1]}"
    combatant = combatant.replace(old, new, 1)
for old, new in lunge_replacements.items():
    assert lunge.count(old) == 1, f"lunge declaration changed: {old.splitlines()[-1]}"
    lunge = lunge.replace(old, new, 1)

anchor = '''# arama yoklama çapraz ağırlık ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.\nvar search_probe_diagonal_weight := 0.85\n'''
assert base.count(anchor) == 1, "enemy_base internal tuning anchor changed"
shared_block = '''# Hasar takibinde ilerleme sayılacak en düşük yatay kazanım.\nvar damage_pursuit_min_progress := 0.20\n# Hasar takibinde rota ilerlemezse hedefi bırakmadan önceki teknik tıkanma süresi.\nvar damage_pursuit_stall_timeout := 3.0\n'''
assert "var damage_pursuit_min_progress" not in base
assert "var damage_pursuit_stall_timeout" not in base
base = base.replace(anchor, anchor + shared_block, 1)

for target in SHARED_INTERNAL_TARGETS:
    assert not re.search(rf"@export[^\n]*\bvar {re.escape(target)}\b", combatant)
    assert not re.search(rf"@export[^\n]*\bvar {re.escape(target)}\b", lunge)
    assert not re.search(rf"(?m)^var {re.escape(target)}\b", combatant)
    assert not re.search(rf"(?m)^var {re.escape(target)}\b", lunge)
    assert re.search(rf"(?m)^var {re.escape(target)}\b", base)

# Commit time stays family-authored because Gorehorn serializes a special value.
for source in (combatant, lunge):
    assert re.search(r"@export[^\n]*\bvar damage_pursuit_commit_time\b", source)

old_audit_list = '''    "crouched_target_height_scale", "crouched_target_min_height",\n    "search_probe_diagonal_weight",\n]'''
new_audit_list = '''    "crouched_target_height_scale", "crouched_target_min_height",\n    "search_probe_diagonal_weight",\n    "damage_pursuit_min_progress", "damage_pursuit_stall_timeout",\n]'''
assert audit.count(old_audit_list) == 1, "shared internal tuning audit list changed"
audit = audit.replace(old_audit_list, new_audit_list, 1)

commit_guard_anchor = '''for tuning_name in family_internal_tuning:\n    assert not re.search(rf"@export[^\\n]*\\bvar {re.escape(tuning_name)}\\b", combatant_base + "\\n" + lunge_base), tuning_name\n'''
commit_guard = '''\n# Damage pursuit commit time remains family-authored because Gorehorn serializes\n# a deliberate scene override. Do not accidentally internalize this property.\nfor source in (combatant_base, lunge_base):\n    assert re.search(r"@export[^\\n]*\\bvar damage_pursuit_commit_time\\b", source)\n'''
assert audit.count(commit_guard_anchor) == 1, "family tuning audit anchor changed"
audit = audit.replace(commit_guard_anchor, commit_guard_anchor + commit_guard, 1)

BASE_PATH.write_text(base, encoding="utf-8")
COMBATANT_PATH.write_text(combatant, encoding="utf-8")
LUNGE_PATH.write_text(lunge, encoding="utf-8")
AUDIT_PATH.write_text(audit, encoding="utf-8")
print("centralized non-authored damage pursuit progress/stall tuning; preserved authored commit time")
