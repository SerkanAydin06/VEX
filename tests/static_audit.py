#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
FAILURES: list[str] = []
WARNINGS: list[str] = []

def fail(msg: str): FAILURES.append(msg)
def warn(msg: str): WARNINGS.append(msg)

def exists(rel: str):
    p=ROOT/rel
    if not p.exists(): fail(f"Eksik dosya: {rel}"); return False
    return True

def text_files():
    for p in ROOT.rglob('*'):
        if p.is_file() and p.suffix in {'.tscn','.tres','.gd','.godot','.cfg','.gdshader'}:
            try: yield p,p.read_text(encoding='utf-8')
            except UnicodeDecodeError: pass

def check_paths():
    for p,txt in text_files():
        for m in re.finditer(r'res://[^"\'\s\)\]]+',txt):
            r=m.group(0).rstrip(';,')
            if any(x in r for x in ('%','{','}')): continue
            if not (ROOT/r.removeprefix('res://')).exists(): fail(f"Kırık res:// referansı: {p.relative_to(ROOT)} -> {r}")

def check_import_uids():
    uid_by_source={}
    for imp in ROOT.rglob('*.import'):
        try:t=imp.read_text(encoding='utf-8')
        except:continue
        sm=re.search(r'^source_file="([^"]+)"',t,re.M); um=re.search(r'^uid="([^"]+)"',t,re.M)
        if sm and um: uid_by_source[sm.group(1)]=um.group(1)
    for p,txt in text_files():
        for m in re.finditer(r'\[ext_resource type="([^"]+)" uid="([^"]+)" path="(res://[^"]+)"',txt):
            actual=uid_by_source.get(m.group(3))
            if actual and actual!=m.group(2): fail(f"Geçersiz import UID: {p.relative_to(ROOT)} -> {m.group(3)} (scene={m.group(2)}, import={actual})")

def check_inputmap():
    p=ROOT/'project.godot'; t=p.read_text(encoding='utf-8') if p.exists() else ''
    required={'move_forward','move_backward','move_left','move_right','jump','sprint','crouch','aim','fire','interact','reload','pause','automap','night_vision'}
    for name in required:
        if re.search(r'^'+re.escape(name)+r'=\{',t,re.M) is None: fail(f"InputMap eksik: {name}")

def check_core_scenes():
    required=['scenes/player/player.tscn','scenes/ui/hud.tscn','scenes/ui/main_menu.tscn','scenes/ui/pause_menu.tscn','scenes/levels/level_01.tscn','scenes/levels/level_02.tscn','scenes/hub/bastion_7.tscn','scenes/actors/veilmaw.tscn','scenes/actors/veilmaw_projectile.tscn']
    for r in required: exists(r)

def check_keys_and_pickups():
    for r in ['assets/pickups/key_blue.png','assets/pickups/key_red.png','assets/pickups/key_yellow.png']:
        exists(r)
    pickup=(ROOT/'scripts/props/pickup.gd').read_text(encoding='utf-8')
    for k in ['key_blue','key_red','key_yellow']:
        if k not in pickup: fail(f"Pickup tipi eksik: {k}")
    for scene in ['scenes/levels/level_01.tscn','scenes/levels/level_02.tscn']:
        t=(ROOT/scene).read_text(encoding='utf-8')
        for k in ['key_blue','key_red']:
            if k not in t: fail(f"{scene}: {k} yerleşimi yok")
        if scene.endswith('level_02.tscn') and 'key_yellow' not in t: fail(f"{scene}: yellow key yerleşimi yok")

def check_enemies():
    for e in ['ravager','redviper','badredviper','hellmagma','voidweaver','veilmaw']:
        exists(f'scenes/actors/{e}.tscn')
        if e != 'voidweaver': exists(f'scripts/actors/{e}.gd')
    it=(ROOT/'tests/integrity_test.gd').read_text(encoding='utf-8')
    if 'veilmaw' not in it: fail('Integrity test Veilmaw kapsamıyor')

def check_player_contract():
    t=(ROOT/'scripts/player/player.gd').read_text(encoding='utf-8')
    required=['Input.is_action_just_pressed("jump")','Input.is_action_pressed("sprint")','event.is_action_pressed("crouch")','func _try_jump()','jump_stamina_cost','_can_stand_up']
    for s in required:
        if s not in t: fail(f'Player movement sözleşmesi eksik: {s}')

def check_checkpoint_contract():
    t=(ROOT/'scripts/autoload/game_state.gd').read_text(encoding='utf-8')
    for s in ['const CHECKPOINTS_ENABLED := true','func restart_checkpoint()','state["current_level_path"]','call_deferred("save_checkpoint")']:
        if s not in t: fail(f'Checkpoint sözleşmesi eksik: {s}')

def check_stale_files():
    tmp=list(ROOT.rglob('*.import*.tmp'))
    for p in tmp: warn(f'Temporary import dosyası: {p.relative_to(ROOT)}')
    todo=ROOT/'todo.md'
    if todo.exists() and 'TODO' in todo.read_text(encoding='utf-8').upper(): warn('todo.md hâlâ eski TODO maddeleri içeriyor; güncel yol haritası kullanın.')

def main():
    check_paths(); check_import_uids(); check_inputmap(); check_core_scenes(); check_keys_and_pickups(); check_enemies(); check_player_contract(); check_checkpoint_contract(); check_stale_files()
    for w in WARNINGS: print('WARNING:',w)
    for f in FAILURES: print('ERROR:',f)
    print(f'VEX VALIDATOR: {len(FAILURES)} gerçek hata, {len(WARNINGS)} uyarı')
    return 1 if FAILURES else 0

if __name__=='__main__': sys.exit(main())
