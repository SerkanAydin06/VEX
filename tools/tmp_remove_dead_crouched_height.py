#!/usr/bin/env python3
from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file_path = Path(path)
    text = file_path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected exactly one match, found {count}")
    file_path.write_text(text.replace(old, new, 1), encoding="utf-8")


replace_once(
    "scripts/actors/enemy_base.gd",
    "# çömelmiş hedef yükseklik çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.\n"
    "var crouched_target_height_scale := 0.50\n"
    "# çömelmiş hedef en düşük yükseklik değeridir (metre).\n"
    "var crouched_target_min_height := -0.20\n",
    "",
)

replace_once(
    "scripts/actors/enemy_combatant_base.gd",
    "func _get_crouched_sight_target_height() -> float:\n"
    "\treturn VexEnemyPerceptionRuntime.crouched_sight_target_height(\n"
    "\t\t_player,\n"
    "\t\tsight_target_height,\n"
    "\t\tcrouched_target_height_scale,\n"
    "\t\tcrouched_target_min_height\n"
    "\t)\n\n",
    "",
)

replace_once(
    "scripts/actors/enemy_lunge_base.gd",
    "\nfunc _get_crouched_sight_target_height() -> float:\n"
    "\treturn VexEnemyPerceptionRuntime.crouched_sight_target_height(\n"
    "\t\t_player,\n"
    "\t\tsight_target_height,\n"
    "\t\tcrouched_target_height_scale,\n"
    "\t\tcrouched_target_min_height\n"
    "\t)\n\n",
    "",
)

perception_path = Path("tests/enemy_perception_architecture_audit.py")
perception = perception_path.read_text(encoding="utf-8")
call_contract = '    "VexEnemyPerceptionRuntime.crouched_sight_target_height(",\n'
if perception.count(call_contract) != 2:
    raise SystemExit(f"perception audit: expected 2 wrapper delegation contracts, found {perception.count(call_contract)}")
perception = perception.replace(call_contract, "")
replace_target = 'lunge_crouched_height = function_body(lunge, "_get_crouched_sight_target_height(")\n'
if perception.count(replace_target) != 1:
    raise SystemExit("perception audit: lunge crouched wrapper probe mismatch")
perception = perception.replace(replace_target, "")
legacy_check = (
    "if 'get_node_or_null(\"CollisionShape3D\")' in lunge_crouched_height:\n"
    "    errors.append(\"Crouched target-height çözümü hâlâ lunge base içinde\")\n"
)
if perception.count(legacy_check) != 1:
    raise SystemExit("perception audit: legacy crouched wrapper check mismatch")
perception = perception.replace(legacy_check, "")
anchor = 'lunge_noise_handler = function_body(lunge, "_on_noise_emitted(")\n\n'
if perception.count(anchor) != 1:
    raise SystemExit("perception audit: insertion anchor mismatch")
perception = perception.replace(
    anchor,
    anchor
    + 'for source_name, source in [("combatant", base), ("lunge", lunge)]:\n'
    + '    if "_get_crouched_sight_target_height" in source:\n'
    + '        errors.append(f"Ölü crouched target-height wrapper geri dönmüş: {source_name}")\n'
    + '    if "VexEnemyPerceptionRuntime.crouched_sight_target_height(" in source:\n'
    + '        errors.append(f"Kullanılmayan crouched target-height delegation geri dönmüş: {source_name}")\n\n',
    1,
)
perception_path.write_text(perception, encoding="utf-8")

replace_once(
    "tests/enemy_script_architecture_audit.py",
    '    "crouched_target_height_scale", "crouched_target_min_height",\n',
    "",
)

replace_once(
    "tests/enemy_role_ai_audit.py",
    '    "crouched_target_height_scale", "search_probe_diagonal_weight",\n',
    '    "search_probe_diagonal_weight",\n',
)
