from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
COMBATANT_PATH = ROOT / "scripts/actors/enemy_combatant_base.gd"
LUNGE_PATH = ROOT / "scripts/actors/enemy_lunge_base.gd"

TARGETS = (
    "damage_pursuit_min_progress",
    "damage_pursuit_stall_timeout",
    "damage_pursuit_commit_time",
)

serialized_paths = [
    path
    for serialized_root in (ROOT / "scenes", ROOT / "resources")
    if serialized_root.exists()
    for path in serialized_root.rglob("*")
    if path.suffix in {".tscn", ".tres"}
]
for path in serialized_paths:
    text = path.read_text(encoding="utf-8", errors="ignore")
    for target in TARGETS:
        assert not re.search(rf"(?m)^\s*{re.escape(target)}\s*=", text), (
            f"serialized override blocks internalization: {path.relative_to(ROOT)} -> {target}"
        )

combatant = COMBATANT_PATH.read_text(encoding="utf-8")
lunge = LUNGE_PATH.read_text(encoding="utf-8")

combatant_replacements = {
    '''## Yaratığın hasar takip en düşük ilerleme ayarını belirler.\n@export_range(0.01, 1.0, 0.01) var damage_pursuit_min_progress := 0.20''':
    '''# Hasar takibinde ilerleme sayılacak en düşük yatay kazanım.\nvar damage_pursuit_min_progress := 0.20''',
    '''## hasar takip tıkanma timeout değeridir (saniye).\n@export_range(0.1, 10.0, 0.1) var damage_pursuit_stall_timeout := 3.0''':
    '''# Hasar takibinde rota ilerlemezse hedefi bırakmadan önceki teknik tıkanma süresi.\nvar damage_pursuit_stall_timeout := 3.0''',
    '''## hasar takip kararlılık süre değeridir (saniye).\n@export_range(0.0, 2.0, 0.01) var damage_pursuit_commit_time := 0.16''':
    '''# Combatant ailesinin yeni hasar takip hedefine kısa süre bağlı kalma eşiği.\nvar damage_pursuit_commit_time := 0.16''',
}
lunge_replacements = {
    '''## Yaratığın hasar takip en düşük ilerleme ayarını belirler.\n@export_range(0.01, 1.0, 0.01) var damage_pursuit_min_progress := 0.20''':
    '''# Hasar takibinde ilerleme sayılacak en düşük yatay kazanım.\nvar damage_pursuit_min_progress := 0.20''',
    '''## hasar takip tıkanma timeout değeridir (saniye).\n@export_range(0.1, 10.0, 0.1) var damage_pursuit_stall_timeout := 3.0''':
    '''# Hasar takibinde rota ilerlemezse hedefi bırakmadan önceki teknik tıkanma süresi.\nvar damage_pursuit_stall_timeout := 3.0''',
    '''## hasar takip kararlılık süre değeridir (saniye).\n@export_range(0.0, 2.0, 0.01) var damage_pursuit_commit_time := 0.12''':
    '''# Lunge ailesinin yeni hasar takip hedefine kısa süre bağlı kalma eşiği.\nvar damage_pursuit_commit_time := 0.12''',
}

for old, new in combatant_replacements.items():
    assert combatant.count(old) == 1, f"combatant declaration changed: {old.splitlines()[-1]}"
    combatant = combatant.replace(old, new, 1)
for old, new in lunge_replacements.items():
    assert lunge.count(old) == 1, f"lunge declaration changed: {old.splitlines()[-1]}"
    lunge = lunge.replace(old, new, 1)

for target in TARGETS:
    assert not re.search(rf"@export[^\n]*\bvar {re.escape(target)}\b", combatant)
    assert not re.search(rf"@export[^\n]*\bvar {re.escape(target)}\b", lunge)
    assert re.search(rf"(?m)^var {re.escape(target)}\b", combatant)
    assert re.search(rf"(?m)^var {re.escape(target)}\b", lunge)

COMBATANT_PATH.write_text(combatant, encoding="utf-8")
LUNGE_PATH.write_text(lunge, encoding="utf-8")
print(f"internalized {len(TARGETS)} damage pursuit tuning values across both enemy families")
