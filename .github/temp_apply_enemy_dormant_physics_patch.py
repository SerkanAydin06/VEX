from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE_PATH = ROOT / "scripts/actors/enemy_base.gd"
COMBATANT_PATH = ROOT / "scripts/actors/enemy_combatant_base.gd"
LUNGE_PATH = ROOT / "scripts/actors/enemy_lunge_base.gd"

base = BASE_PATH.read_text(encoding="utf-8")
combatant = COMBATANT_PATH.read_text(encoding="utf-8")
lunge = LUNGE_PATH.read_text(encoding="utf-8")

combatant_block = '''func _apply_dormant_physics(delta: float) -> void:\n\t# Uzak ve alarma geçmemiş düşman zemindeyken CharacterBody çözümü, rota ve\n\t# algı çalıştırmaz. Havada doğmuşsa güvenli biçimde zemine oturmaya devam eder.\n\tif is_on_floor():\n\t\tvelocity.y = floor_stick_velocity\n\t\treturn\n\t_apply_gravity(delta, floor_stick_velocity)\n\tmove_and_slide()\n'''
lunge_block = '''func _apply_dormant_physics(delta: float) -> void:\n\tif is_on_floor():\n\t\tvelocity.y = floor_stick_velocity\n\t\treturn\n\t_apply_gravity(delta, floor_stick_velocity)\n\tmove_and_slide()\n'''

assert combatant.count(combatant_block) == 1, "combatant dormant physics block changed"
assert lunge.count(lunge_block) == 1, "lunge dormant physics block changed"
assert "func _apply_dormant_physics(" not in base, "base already owns dormant physics"

combatant = combatant.replace(combatant_block, "", 1)
lunge = lunge.replace(lunge_block, "", 1)

old_call = "_apply_dormant_physics(delta)"
new_call = "_apply_dormant_physics(delta, floor_stick_velocity)"
assert combatant.count(old_call) == 1, "combatant dormant physics call count changed"
assert lunge.count(old_call) == 1, "lunge dormant physics call count changed"
combatant = combatant.replace(old_call, new_call)
lunge = lunge.replace(old_call, new_call)

anchor = '''func _apply_gravity(delta: float, floor_stick_velocity_value: float) -> void:\n\tif not is_on_floor():\n\t\tvelocity.y -= _gravity * delta\n\telse:\n\t\tvelocity.y = floor_stick_velocity_value\n'''
assert base.count(anchor) == 1, "base gravity anchor changed"

shared = '''\n\nfunc _apply_dormant_physics(\n\tdelta: float,\n\tfloor_stick_velocity_value: float\n) -> void:\n\t# Uzak ve alarma geçmemiş düşman zemindeyken CharacterBody çözümü, rota ve\n\t# algı çalıştırmaz. Havada doğmuşsa güvenli biçimde zemine oturmaya devam eder.\n\tif is_on_floor():\n\t\tvelocity.y = floor_stick_velocity_value\n\t\treturn\n\t_apply_gravity(delta, floor_stick_velocity_value)\n\tmove_and_slide()\n'''
base = base.replace(anchor, anchor + shared, 1)

BASE_PATH.write_text(base, encoding="utf-8")
COMBATANT_PATH.write_text(combatant, encoding="utf-8")
LUNGE_PATH.write_text(lunge, encoding="utf-8")
print("enemy dormant physics patch applied")
