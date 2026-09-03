from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGETS = [
    ROOT / "scripts/actors/enemy_combatant_base.gd",
    ROOT / "scripts/actors/enemy_lunge_base.gd",
]


def remove_local_function(source: str, signature: str) -> str:
    lines = source.splitlines(keepends=True)
    start = next((i for i, line in enumerate(lines) if line.startswith(signature)), None)
    if start is None:
        return source
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("func ")), len(lines))
    del lines[start:end]
    return "".join(lines)


for path in TARGETS:
    text = path.read_text(encoding="utf-8")
    text = remove_local_function(text, "func _reset_search_probe() -> void:")
    text = remove_local_function(text, "func _apply_gravity(delta: float) -> void:")
    text = text.replace(
        "_apply_gravity(delta)",
        "_apply_gravity(delta, floor_stick_velocity)",
    )
    path.write_text(text, encoding="utf-8")


audit_path = ROOT / "tests/enemy_common_helper_architecture_audit.py"
audit_path.write_text(
    '''from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = (ROOT / "scripts/actors/enemy_base.gd").read_text(encoding="utf-8")
COMBATANT = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
LUNGE = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")

errors: list[str] = []

if "func _reset_search_probe() -> void:" not in BASE:
    errors.append("enemy_base.gd must own _reset_search_probe")
if "func _apply_gravity(delta: float, floor_stick_velocity_value: float) -> void:" not in BASE:
    errors.append("enemy_base.gd must own parameterized _apply_gravity")

for name, source in (("combatant", COMBATANT), ("lunge", LUNGE)):
    if "func _reset_search_probe() -> void:" in source:
        errors.append(f"{name} must not redeclare _reset_search_probe")
    if "func _apply_gravity(delta: float) -> void:" in source:
        errors.append(f"{name} must not redeclare _apply_gravity")
    if source.count("_apply_gravity(delta, floor_stick_velocity)") < 2:
        errors.append(f"{name} must route gravity through the shared parent helper")

if errors:
    raise SystemExit("\\n".join(errors))

print("Enemy common helper architecture audit passed")
''',
    encoding="utf-8",
)
