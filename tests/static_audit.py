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
    required=['scenes/player/player.tscn','scenes/ui/hud.tscn','scenes/ui/main_menu.tscn','scenes/ui/pause_menu.tscn','scenes/levels/level_01.tscn','scenes/levels/level_02.tscn','scenes/levels/level_03.tscn','scenes/hub/bastion_7.tscn','scenes/world/korvath_rift.tscn','scenes/world/lore_terminal.tscn','resources/missions/vex03.tres','scenes/actors/veilmaw.tscn','scenes/actors/veilmaw_projectile.tscn']
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
    level_03=(ROOT/'scenes/levels/level_03.tscn').read_text(encoding='utf-8')
    for k in ['key_blue','key_red']:
        if k not in level_03: fail(f'scenes/levels/level_03.tscn: {k} yerleşimi yok')

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

def check_no_checkpoint_contract():
    t=(ROOT/'scripts/autoload/game_state.gd').read_text(encoding='utf-8')
    if 'const CHECKPOINTS_ENABLED := false' not in t:
        fail('Checkpoint sistemi kapalı değil')
    pause=(ROOT/'scripts/ui/pause_menu.gd').read_text(encoding='utf-8')
    if 'checkpoint_button.pressed.connect(GameState.restart_level)' not in pause:
        fail('Pause menüsü bölüm başı yeniden başlatma kullanmıyor')
    level_begin=t[t.find('func begin_level'):t.find('func _capture_level_start_state')]
    if 'save_checkpoint' in level_begin:
        fail('Bölüm başlangıcı checkpoint yazmaya çalışıyor')

def check_weapon_upgrades():
    controller=(ROOT/'scripts/player/weapon_controller.gd').read_text(encoding='utf-8')
    catalog=ROOT/'scripts/player/weapon_upgrade_catalog.gd'
    if not catalog.exists(): fail('Silah geliştirme kataloğu eksik'); return
    text=catalog.read_text(encoding='utf-8')
    for weapon in ['pistol','shotgun','ak47','mp90']:
        if f'&"{weapon}"' not in text: fail(f'Silah geliştirme yolu eksik: {weapon}')
    for contract in ['upgrade_levels', 'install_next_upgrade', 'get_weapon_upgrade_track']:
        if contract not in controller: fail(f'WeaponController geliştirme sözleşmesi eksik: {contract}')

def check_stale_files():
    tmp=list(ROOT.rglob('*.import*.tmp'))
    for p in tmp: warn(f'Temporary import dosyası: {p.relative_to(ROOT)}')
    todo=ROOT/'todo.md'
    if todo.exists() and 'TODO' in todo.read_text(encoding='utf-8').upper(): warn('todo.md hâlâ eski TODO maddeleri içeriyor; güncel yol haritası kullanın.')


def check_runtime_signal_contracts():
    game_state = (ROOT/'scripts/autoload/game_state.gd').read_text(encoding='utf-8')
    level_02 = (ROOT/'scripts/levels/level_02.gd').read_text(encoding='utf-8')
    weapon = (ROOT/'scripts/player/weapon_controller.gd').read_text(encoding='utf-8')
    if 'signal gunshot_emitted(position: Vector3, loudness: float, source: Node)' not in game_state:
        fail('GameState gunshot_emitted sinyali eksik')
    if 'GameState.gunshot_emitted.connect(_on_gunshot_emitted)' not in level_02:
        fail('VEX-02 gunshot sinyali bağlantısı eksik')
    if 'VexNoiseManager' in level_02:
        fail('VEX-02 eski VexNoiseManager referansını hâlâ kullanıyor')
    if 'GameState.emit_gunshot(' not in weapon:
        fail('WeaponController ateş sesi GameState.emit_gunshot() kullanmıyor')


def check_level_briefings():
    for name in ['level_01.gd', 'level_02.gd', 'level_03.gd']:
        text=(ROOT/'scripts/levels'/name).read_text(encoding='utf-8')
        for contract in ['briefing_story', 'briefing_objective', 'func _show_briefing()', 'HERHANGİ BİR TUŞA BAS — DEVAM ET', 'process_mode = Node.PROCESS_MODE_DISABLED']:
            if contract not in text:
                fail(f'{name}: tam ekran bölüm brifingi eksik: {contract}')


def check_level_02_progression():
    scene=(ROOT/'scenes/levels/level_02.tscn').read_text(encoding='utf-8')
    script=(ROOT/'scripts/levels/level_02.gd').read_text(encoding='utf-8')
    if '22.5, 0.7, -21.25' not in scene:
        fail('VEX-02 sarı kart güvenli doğu kanadı konumunda değil')
    if '0, 0.7, 5' in scene:
        fail('VEX-02 sarı kart eski duvar konumunda kalmış')
    expected=[
        'BATI KANADINI ARA // MAVİ ERİŞİM KARTINI BUL',
        'MAVİ ERİŞİM KARTI ALINDI // MERKEZE DÖN VE DOĞU KANADINI AÇ',
        'SARI ERİŞİM KARTI ALINDI // REAKTÖR BÖLME KAPISINI AÇ',
        'KIRMIZI ERİŞİM KARTI ALINDI // TAHLİYE ODASINI TEMİZLE VE SELİN\'İ KURTAR',
    ]
    for objective in expected:
        if objective not in scene and objective not in script:
            fail(f'Vex-02 ilerleme hedefi eksik: {objective}')
    gunshot=script[script.find('func _on_gunshot_emitted'):script.find('func _on_key_inventory_changed')]
    if 'set_objective' in gunshot:
        fail('VEX-02 alarmı kart ilerlemesini atlıyor')


def check_unique_progression_ids():
    for scene_name in ['level_01.tscn', 'level_02.tscn', 'level_03.tscn']:
        scene = ROOT/'scenes/levels'/scene_name
        text = scene.read_text(encoding='utf-8')
        for key, label in [('enemy_id', 'enemy'), ('pickup_id', 'pickup'), ('secret_id', 'secret')]:
            values = re.findall(rf'\b{re.escape(key)}\s*=\s*&"([^"]+)"', text)
            seen = set()
            for value in values:
                if value in seen:
                    fail(f'{scene_name}: duplicate {label} id: {value}')
                seen.add(value)


def check_level_03_contract():
    script=(ROOT/'scripts/levels/level_03.gd').read_text(encoding='utf-8')
    scene=(ROOT/'scenes/levels/level_03.tscn').read_text(encoding='utf-8')
    hub=(ROOT/'scenes/hub/bastion_7.tscn').read_text(encoding='utf-8')
    story=(ROOT/'HIKAYE_VEX_KAMPANYA.md').read_text(encoding='utf-8')
    required_scene=[
        'VEX-03 // KÜL MADENİ', 'Ceiling_L06_MaintenanceHall',
        'StairRamp', 'StairRampUpper', 'StairLanding', 'UpperDeck',
        'vex03_secret_maintenance_cache', 'vex03_secret_upper_archive',
        'vex03_korvath_warden', 'res://scenes/world/korvath_rift.tscn',
        'vex03_log_transfer_41', 'vex03_log_korvath', 'vex03_log_ece_signal',
    ]
    for contract in required_scene:
        if contract not in scene: fail(f'VEX-03 sahne sözleşmesi eksik: {contract}')
    if 'campaign_completion_stage = 3' not in scene:
        fail('VEX-03 campaign stage 3 değil')
    for path in ['assets/world/level03/korvath_rift.png']:
        exists(path)
    if 'res://scenes/levels/level_03.tscn' not in hub or 'ExtResource("15_mission03")' not in hub:
        fail('Bastion-7 VEX-03 görevini sunmuyor')
    if '## Bölüm 4 — VEX-03: Kül Madeni' not in story:
        fail('Kampanya hikâyesinde VEX-03 Kül Madeni bölümü eksik')
    if 'required_keys = Array[StringName]([&"blue", &"red"])' not in scene:
        fail('VEX-03 finish switch typed anahtar dizisi sahnede eksik')
    forbidden_runtime_builders=['_build_level_geometry', '_spawn_gameplay', '_spawn_enemy(', '_spawn_pickup(', 'WORLD_PIECE_SCENE']
    for contract in forbidden_runtime_builders:
        if contract in script:
            fail(f'VEX-03 editör görünürlüğünü bozan runtime üretim kaldı: {contract}')
    for node_group in ['Geometry/LowerLevel', 'Geometry/UpperLevel', 'Geometry/Stairs', 'Gameplay/Enemies', 'Gameplay/Pickups', 'Gameplay/Lighting']:
        if f'parent="{node_group}"' not in scene and f'name="{node_group.split("/")[-1]}" type="Node3D" parent="{node_group.rsplit("/", 1)[0]}"' not in scene:
            fail(f'VEX-03 editör sahne grubu eksik: {node_group}')
    counts={
        'enemy_id': len(re.findall(r'\benemy_id\s*=\s*&"', scene)),
        'pickup_id': len(re.findall(r'\bpickup_id\s*=\s*&"', scene)),
        'secret_id': len(re.findall(r'\bsecret_id\s*=\s*&"', scene)),
    }
    if counts['enemy_id'] != 16: fail(f'VEX-03 sahne düşman sayısı 16 değil: {counts["enemy_id"]}')
    if counts['pickup_id'] != 12: fail(f'VEX-03 sahne pickup sayısı 12 değil: {counts["pickup_id"]}')
    if counts['secret_id'] != 2: fail(f'VEX-03 sahne gizli alan sayısı 2 değil: {counts["secret_id"]}')
    lower_rooms=len(re.findall(r'name="Room_L\d\d_', scene))
    upper_rooms=len(re.findall(r'name="Room_U\d\d_', scene))
    room_lights=len(re.findall(r'name="Light_[LU]\d\d_', scene))
    alarm_lights=len(re.findall(r'parent="Gameplay/Lighting/AlarmLights" instance=ExtResource\("16_red_lamp"\)', scene))
    doors=len(re.findall(r'name="Door_[^"]+" parent="Gameplay/Doors"', scene))
    wall_pieces=len(re.findall(r'parent="Geometry/(?:LowerLevel|UpperLevel)/(?:LowerOuterWalls|LowerDoorFrames|UpperOuterWalls|UpperDoorFrames)', scene))
    if lower_rooms != 10: fail(f'VEX-03 alt kat modüler oda sayısı 10 değil: {lower_rooms}')
    if upper_rooms != 8: fail(f'VEX-03 üst kat modüler oda sayısı 8 değil: {upper_rooms}')
    if room_lights != 18: fail(f'VEX-03 oda başına beyaz ışık sayısı 18 değil: {room_lights}')
    if alarm_lights != 28: fail(f'VEX-03 kapı üstü kırmızı ışık sayısı 28 değil: {alarm_lights}')
    if doors != 14: fail(f'VEX-03 kapı sayısı 14 değil: {doors}')
    if wall_pieces < 40: fail(f'VEX-03 kapalı oda/koridor duvar modülü yetersiz: {wall_pieces}')
    top_fills=len(re.findall(r'name="[A-Z0-9]+_TopFill"', scene))
    if top_fills < doors: fail(f'VEX-03 kapı üstü duvar dolgusu sayısı yetersiz: {top_fills} / {doors}')
    required_door_headers={
        'AB_TopFill': 'Vector3(-12, 5.74, 15)',
        'BC_TopFill': 'Vector3(0, 5.74, 15)',
        'AE_TopFill': 'Vector3(-18, 5.74, 10)',
        'CH_TopFill': 'Vector3(6, 5.74, 10)',
        'GJ_TopFill': 'Vector3(0, 5.74, -5)',
        'HI_TopFill': 'Vector3(12, 5.74, 5)',
        'EF_TopFill': 'Vector3(-18, 5.74, 0)',
        'FG_TopFill': 'Vector3(-12, 5.74, -5)',
        'HJ_TopFill': 'Vector3(6, 5.74, 0)',
        'U21_TopFill': 'Vector3(12, 13.54, 5)',
        'U32_TopFill': 'Vector3(0, 13.54, 5)',
        'U34_TopFill': 'Vector3(-6, 13.54, 0)',
        'U56_TopFill': 'Vector3(12, 13.54, -5)',
        'U68_TopFill': 'Vector3(18, 13.54, -10)',
    }
    for header_name, header_position in required_door_headers.items():
        pattern=rf'\[node name="{re.escape(header_name)}"[^\n]*\]\nposition = {re.escape(header_position)}'
        if re.search(pattern, scene) is None:
            fail(f'VEX-03 kapı üstü duvarı konum standardı bozuk: {header_name}')
    lamp_positions=re.findall(r'\[node name="Door\d+_Lamp[AB]" parent="Gameplay/Lighting/AlarmLights"[^\n]*\]\nposition = Vector3\(([^)]+)\)', scene)
    lower_door_lamps=sum(1 for value in lamp_positions if ', 5.5,' in value)
    upper_door_lamps=sum(1 for value in lamp_positions if ', 13.3,' in value)
    if lower_door_lamps != 18 or upper_door_lamps != 10:
        fail(f'VEX-03 kırmızı lambalar kapı üstünde değil: {lower_door_lamps} alt / {upper_door_lamps} üst')
    for standard_contract in ['piece_size = Vector3(12, 0.4, 10)', 'piece_size = Vector3(0.4, 7, 2.78)', 'piece_size = Vector3(0.4, 2.52, 4.44)', 'piece_size = Vector3(4.44, 2.52, 0.4)', 'position = Vector3(-18, 6.82, 15)', 'light_energy = 3.8']:
        if standard_contract not in scene:
            fail(f'VEX-03 Level 1/2 ölçü standardı eksik: {standard_contract}')
    for revision_contract in [
        'position = Vector3(13, 7.6, 5)',
        'position = Vector3(-6, 15.0, 5)',
        'StairTread_L10', 'StairTread_U10', 'StairRiser_U10',
        'RailLowerLeft', 'RailUpperRight', 'LandingRearRail',
        'visibility_range_end = 11.0',
        'position = Vector3(6, 8.7, 9.68)',
        'position = Vector3(6, 0.48, 15)',
        'position = Vector3(18, 9.58, -17)',
    ]:
        if revision_contract not in scene:
            fail(f'VEX-03 R5 hizalama/merdiven sözleşmesi eksik: {revision_contract}')
    door_scene=(ROOT/'scenes/props/door_side_slide.tscn').read_text(encoding='utf-8')
    for frame_contract in ['FrameJambLeft', 'FrameJambRight', 'FrameHeader']:
        if frame_contract not in door_scene:
            fail(f'VEX kapı bindirme çerçevesi eksik: {frame_contract}')
    if 'no_depth_test = true' in scene:
        fail('VEX-03 duvar yazıları duvar arkasından çiziliyor')
    for visibility_contract in ['ambient_light_energy = 1.3', 'fog_density = 0.0014', 'adjustment_brightness = 1.32']:
        if visibility_contract not in scene:
            fail(f'VEX-03 görünürlük standardı eksik: {visibility_contract}')
    for removed_contract in ['CargoElevator_Main', 'cargo_elevator.tscn', 'VentLowCeiling', 'UpperServiceCeiling', 'CrouchInstructionLabel']:
        if removed_contract in scene:
            fail(f'VEX-03 kaldırılması gereken eski sistem hâlâ sahnede: {removed_contract}')
    if 'cargo_elevator' in script or 'yük asansörü' in script.lower():
        fail('VEX-03 scriptinde kaldırılan asansör akışı kaldı')
    if 'piece_size = Vector3(56, 0.4, 44)' in scene:
        fail('VEX-03 eski açık arena zemini hâlâ sahnede')


def main():
    check_paths(); check_import_uids(); check_inputmap(); check_core_scenes(); check_keys_and_pickups(); check_enemies(); check_player_contract(); check_no_checkpoint_contract(); check_weapon_upgrades(); check_runtime_signal_contracts(); check_level_briefings(); check_level_02_progression(); check_level_03_contract(); check_unique_progression_ids(); check_stale_files()
    for w in WARNINGS: print('WARNING:',w)
    for f in FAILURES: print('ERROR:',f)
    print(f'VEX VALIDATOR: {len(FAILURES)} gerçek hata, {len(WARNINGS)} uyarı')
    return 1 if FAILURES else 0

if __name__=='__main__': sys.exit(main())
