#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import csv, math, re, sys

ROOT = Path(__file__).resolve().parents[1]
FAILURES: list[str] = []
WARNINGS: list[str] = []

def fail(msg: str): FAILURES.append(msg)
def warn(msg: str): WARNINGS.append(msg)


def node_origin(scene_text: str, node_name: str):
    match = re.search(
        rf'^\[node name="{re.escape(node_name)}"[^\n]*\]\n(.*?)(?=\n\[node |\Z)',
        scene_text,
        re.M | re.S,
    )
    if match is None:
        return None
    transform = re.search(r'^transform = Transform3D\(([^\n]+)\)$', match.group(1), re.M)
    if transform is None:
        return (0.0, 0.0, 0.0)
    values = [float(value.strip()) for value in transform.group(1).split(',')]
    return tuple(values[-3:]) if len(values) == 12 else None


def approximately_equal_vector(actual, expected, tolerance: float = 0.00001) -> bool:
    return actual is not None and expected is not None and len(actual) == len(expected) and all(
        math.isclose(value, target, abs_tol=tolerance)
        for value, target in zip(actual, expected)
    )


def node_transform(scene_text: str, node_name: str):
    match = re.search(
        rf'^\[node name="{re.escape(node_name)}"[^\n]*\]\n(.*?)(?=\n\[node |\Z)',
        scene_text,
        re.M | re.S,
    )
    if match is None:
        return None
    transform = re.search(r'^transform = Transform3D\(([^\n]+)\)$', match.group(1), re.M)
    if transform is None:
        return (
            ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)),
            (0.0, 0.0, 0.0),
        )
    values = [float(value.strip()) for value in transform.group(1).split(',')]
    if len(values) != 12:
        return None
    return (
        (tuple(values[0:3]), tuple(values[3:6]), tuple(values[6:9])),
        tuple(values[9:12]),
    )


def transform_point(transform, point):
    basis, origin = transform
    return tuple(
        origin[row] + sum(basis[row][column] * point[column] for column in range(3))
        for row in range(3)
    )


def subresource_size(scene_text: str, resource_id: str):
    match = re.search(
        rf'^\[sub_resource [^\n]* id="{re.escape(resource_id)}"\]\n(.*?)(?=\n\[|\Z)',
        scene_text,
        re.M | re.S,
    )
    if match is None:
        return None
    size = re.search(r'^size = Vector[23]\(([^\n]+)\)$', match.group(1), re.M)
    if size is None:
        return None
    return tuple(float(value.strip()) for value in size.group(1).split(','))

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
            if r.startswith('res://translations/vex.') and r.endswith('.translation') and (ROOT/'translations/vex.csv').exists():
                continue
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
    required={'move_forward','move_backward','move_left','move_right','jump','sprint','crouch','aim','fire','interact','reload','pause','automap','night_vision','weapon_flashlight','weapon_1','weapon_2','weapon_3','weapon_4','weapon_5'}
    for name in required:
        if re.search(r'^'+re.escape(name)+r'=\{',t,re.M) is None: fail(f"InputMap eksik: {name}")
    settings=(ROOT/'scripts/autoload/settings_manager.gd').read_text(encoding='utf-8')
    controller=(ROOT/'scripts/player/weapon_controller.gd').read_text(encoding='utf-8')
    for contract in [
        '_ensure_required_input_actions()',
        'InputMap.add_action(&"weapon_flashlight")',
        'flashlight_key.physical_keycode = KEY_F',
    ]:
        if contract not in settings:
            fail(f'Eksik weapon_flashlight runtime fallback sözleşmesi: {contract}')
    if 'InputMap.has_action(&"weapon_flashlight")' not in controller:
        fail('WeaponController eksik InputMap action durumunu güvenli kontrol etmiyor')

def check_core_scenes():
    required=['scenes/player/player.tscn','scenes/ui/hud.tscn','scenes/ui/main_menu.tscn','scenes/ui/pause_menu.tscn','scenes/ui/terminal_menu.tscn','scripts/ui/terminal_menu.gd','scenes/levels/level_01.tscn','scenes/levels/level_02.tscn','scenes/levels/level_03.tscn','scenes/hub/bastion_7.tscn','scenes/hub/hub_terminal.tscn','scenes/hub/armory_category_rack.tscn','scenes/hub/hub_weapon_rack.tscn','scripts/hub/hub_terminal.gd','scripts/hub/armory_category_rack.gd','scenes/world/korvath_rift.tscn','scenes/world/lore_terminal.tscn','scenes/world/u_staircase.tscn','scenes/world/door_status_light.tscn','scripts/world/door_status_light.gd','scenes/world/room_name_display.tscn','scripts/world/room_name_display.gd','assets/ui/bastion_terminal_screen_idle.png','assets/world/bastion7/bastion_terminal_controls.png','assets/ui/bastion_facility_network.png','resources/missions/vex03.tres','scenes/actors/veilmaw.tscn','scenes/actors/veilmaw_projectile.tscn']
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
    runtime=(ROOT/'scripts/actors/enemy_runtime_utils.gd').read_text(encoding='utf-8')
    ravager=(ROOT/'scripts/actors/ravager.gd').read_text(encoding='utf-8')
    redviper=(ROOT/'scripts/actors/redviper.gd').read_text(encoding='utf-8')
    if 'static func has_clear_acoustic_path(' not in runtime:
        fail('Düşman ses oklüzyon helperı eksik')
    for enemy_name, source in [('ravager', ravager), ('redviper', redviper)]:
        if source.count('VexEnemyRuntimeUtils.has_clear_acoustic_path(') < 2:
            fail(f'{enemy_name}: kapalı duvar/kapı ses ve ally alert oklüzyonu eksik')

def check_player_contract():
    t=(ROOT/'scripts/player/player.gd').read_text(encoding='utf-8')
    required=['Input.is_action_just_pressed("jump")','Input.is_action_pressed("sprint")','event.is_action_pressed("crouch")','func _try_jump()','jump_stamina_cost','_can_stand_up']
    for s in required:
        if s not in t: fail(f'Player movement sözleşmesi eksik: {s}')
    if '@export_range(1, 500, 1) var maximum_health := 100' not in t:
        fail('Player maksimum can varsayılanı 100 değil veya export aralığı dışında')
    player_scene=(ROOT/'scenes/player/player.tscn').read_text(encoding='utf-8')
    if 'maximum_health = 100' not in player_scene:
        fail('Player maksimum can temel tuning değeri sahnede 100 olarak tanımlı değil')

def check_no_checkpoint_contract():
    t=(ROOT/'scripts/autoload/game_state.gd').read_text(encoding='utf-8')
    for contract in ['const CAMPAIGN_SAVE_ENABLED := true', 'const CHECKPOINTS_ENABLED := false', 'func save_campaign_progress(', 'func save_current_safe_progress(', 'func _sanitize_campaign_player_state(', 'func _load_campaign_save(']:
        if contract not in t: fail(f'Campaign save / checkpointsiz ilerleme sözleşmesi eksik: {contract}')
    if 'safe.erase("position")' not in t or 'safe["keys"] = []' not in t:
        fail('Campaign save bölüm içi pozisyon/anahtar checkpoint verisini temizlemiyor')
    if 'save_campaign_progress(current_level_path, {}, "new_game")' not in t:
        fail('Yeni oyun ilk görev girişinde campaign boundary kaydı oluşturmuyor')
    main_menu=(ROOT/'scripts/ui/main_menu.gd').read_text(encoding='utf-8')
    if 'continue_button.visible = true' not in main_menu or 'continue_button.disabled = not GameState.has_save()' not in main_menu:
        fail('Continue butonu campaign save durumuna bağlı değil')
    if 'continue_button.visible = GameState.checkpoints_enabled()' in main_menu:
        fail('Continue görünürlüğü hâlâ checkpoint bayrağına bağlı')
    main_menu_scene=(ROOT/'scenes/ui/main_menu.tscn').read_text(encoding='utf-8')
    if main_menu_scene.count('custom_minimum_size = Vector2(0, 54)') < 5:
        fail('Ana menü dikey buton boyut standardı eksik')
    menu_buttons_block=main_menu_scene.split('[node name="MenuButtons"', 1)[-1].split('\n[node ', 1)[0]
    for compact_contract in ['type="VBoxContainer"', 'custom_minimum_size = Vector2(350, 0)', 'size_flags_horizontal = 0', 'size_flags_vertical = 0', 'theme_override_constants/separation = 8']:
        if compact_contract not in menu_buttons_block:
            fail(f'Ana menü sahne otoriteli orantılı dikey buton sözleşmesi eksik: {compact_contract}')
    for visual_contract in [
        '[node name="LeftShade" type="ColorRect" parent="."',
        'offset_right = 650.0\noffset_bottom = 1080.0',
        'offset_left = 54.0\noffset_top = 80.0\noffset_right = 630.0\noffset_bottom = 287.0',
        'offset_left = 70.0\noffset_top = 338.0\noffset_right = 460.0\noffset_bottom = 760.0',
        'content_margin_left = 0.0',
    ]:
        if visual_contract not in main_menu_scene:
            fail(f'Ana menü ilk kompozisyonunun orantılı sahne tasarımı eksik: {visual_contract}')
    if 'GradientTexture_left_vignette' in main_menu_scene:
        fail('Ana menüde reddedilen gradient/yatay komuta tasarımı kaldı')
    for runtime_layout_write in ['menu_buttons.custom_minimum_size =', 'menu_buttons.size =', 'new_game_button.custom_minimum_size =']:
        if runtime_layout_write in main_menu:
            fail(f'Ana menü scripti sahne buton genişliğini runtime eziliyor: {runtime_layout_write}')
    if 'anchors_preset = 3' not in main_menu_scene or 'offset_left = -536.0' not in main_menu_scene or 'offset_bottom = -104.0' not in main_menu_scene:
        fail('Ana menü aktif operasyon paneli bottom-right anchor standardı eksik')
    for script_contract in ['@onready var menu_buttons: VBoxContainer', 'main_shell.position.x -= 46.0']:
        if script_contract not in main_menu:
            fail(f'Ana menü ilk dikey kompozisyon runtime bağlantısı eksik: {script_contract}')
    pause=(ROOT/'scripts/ui/pause_menu.gd').read_text(encoding='utf-8')
    if 'restart_level_button.pressed.connect(GameState.restart_level)' not in pause:
        fail('Pause menüsü bölüm başı yeniden başlatma kullanmıyor')

def check_weapon_upgrades():
    controller=(ROOT/'scripts/player/weapon_controller.gd').read_text(encoding='utf-8')
    catalog=ROOT/'scripts/player/weapon_upgrade_catalog.gd'
    if not catalog.exists(): fail('Silah geliştirme kataloğu eksik'); return
    text=catalog.read_text(encoding='utf-8')
    for weapon in ['p01','sg04','vx47','mp90']:
        if f'&"{weapon}"' not in text: fail(f'Silah geliştirme yolu eksik: {weapon}')
    for contract in ['upgrade_levels', 'install_next_upgrade', 'get_weapon_upgrade_track']:
        if contract not in controller: fail(f'WeaponController geliştirme sözleşmesi eksik: {contract}')

def check_armory_loadout_contract():
    definition=(ROOT/'scripts/player/weapon_definition.gd').read_text(encoding='utf-8')
    controller=(ROOT/'scripts/player/weapon_controller.gd').read_text(encoding='utf-8')
    rack=(ROOT/'scripts/hub/hub_weapon_rack.gd').read_text(encoding='utf-8')
    rack_scene=(ROOT/'scenes/hub/hub_weapon_rack.tscn').read_text(encoding='utf-8')
    category_scene=(ROOT/'scenes/hub/armory_category_rack.tscn').read_text(encoding='utf-8')
    category_script=(ROOT/'scripts/hub/armory_category_rack.gd').read_text(encoding='utf-8')
    hub=(ROOT/'scenes/hub/bastion_7.tscn').read_text(encoding='utf-8')
    for contract in ['loadout_group', 'loadout_slot', 'loadout_group_label']:
        if contract not in definition: fail(f'Silah tanımında Inspector teçhizat alanı eksik: {contract}')
    for contract in ['var acquired_weapons: Array[StringName]', 'func toggle_armory_weapon', 'func switch_to_loadout_slot', 'func _make_room_for_loadout_group', 'func has_carried_weapon', 'weapons_per_loadout_group', '"acquired_weapons": acquired_weapons.duplicate()', 'signal loadout_changed']:
        if contract not in controller: fail(f'Cephanelik taşıma/saklama sözleşmesi eksik: {contract}')
    game_state=(ROOT/'scripts/autoload/game_state.gd').read_text(encoding='utf-8')
    for contract in ['HUB_LOADOUT_REQUIRED', 'HUB_OBJECTIVE_VISIT_ARMORY', 'has_carried_weapon']:
        if contract not in game_state: fail(f'Silahsız operasyona çıkış engeli eksik: {contract}')
    player_scene=(ROOT/'scenes/player/player.tscn').read_text(encoding='utf-8')
    if 'weapons_per_loadout_group = 1' not in player_scene:
        fail('Oyuncu sahnesinde grup başına silah sınırı Inspector üzerinden 1 değil')
    for contract in ['RACK_INTERACT_STORE', 'RACK_STORED', 'RACK_SWAPPED', 'UI_CARRIED', 'UI_STORED']:
        if contract not in rack: fail(f'Silah rafı durum sözleşmesi eksik: {contract}')
    for contract in ['GroupLabel', 'FallbackVisual', 'EmptySlotVisual', 'EmptySlotLabel', 'size = Vector3(1.62, 0.72, 0.44)', 'position = Vector3(0, 0, 0.14)', 'billboard = 0', 'position = Vector3(0, -0.27, 0.17)', 'visible = false', 'locked_color = Color(0, 0, 0, 1)', 'empty_slot_color = Color(0, 0, 0, 1)', 'modulate = Color(0, 0, 0, 1)', 'auto_center_visible_pixels = true', 'visual_pixel_offset = Vector2(0, 0)']:
        if contract not in rack_scene: fail(f'Silah rafı ön yüz/görsel sözleşmesi eksik: {contract}')
    if rack_scene.count('texture_filter = 2') != 2 or 'texture_filter = 3' in rack_scene:
        fail('Silah rafı Sprite3D görselleri renk saçılmasını önleyen mipmapsiz lineer filtreyi kullanmıyor')
    for removed_contract in ['RackPanel', 'Material_rack', 'BoxMesh_rack']:
        if removed_contract in rack_scene: fail(f'Arka dolabı kapatan gereksiz siyah raf paneli kaldırılmamış: {removed_contract}')
    for contract in ['show_stored_visual', 'fallback_visual.visible', 'empty_slot_visual.visible', 'empty_slot_label.visible', 'empty_slot_color', 'weapon_texture == null', 'func _calculate_visual_pixel_offset', 'source_image.get_used_rect()', 'weapon_visual.offset = centered_offset', 'empty_slot_visual.offset = centered_offset', 'empty_slot_label.modulate = empty_slot_color']:
        if contract not in rack: fail(f'Silah rafı saklanan görsel fallback sözleşmesi eksik: {contract}')
    for contract in ['ArmoryCategoryRack', 'CategoryLabel', 'BackgroundPanel', 'FrameLeft', 'FrameRight', 'FrameTop', 'FrameBottom', 'DividerVerticalTop', 'DividerVerticalBottom', 'DividerHorizontal', 'TopLight01', 'TopLight02', 'TopLight03', 'TopLight04', 'type="SpotLight3D"', 'rotation_degrees = Vector3(-90, 0, 0)', 'size = Vector3(3.56, 1.72, 0.16)', 'size = Vector3(0.08, 1.72, 0.42)', 'size = Vector3(3.72, 0.14, 0.42)', 'size = Vector3(0.05, 0.835, 0.4)', 'size = Vector3(3.56, 0.05, 0.4)', 'position = Vector3(-1.82, 0, 0.11)', 'position = Vector3(1.82, 0, 0.11)', 'position = Vector3(0, 0.93, 0.11)', 'position = Vector3(0, -0.93, 0.11)', 'position = Vector3(0, 0.4425, 0.105)', 'position = Vector3(0, -0.4425, 0.105)', 'position = Vector3(-0.92, 0.75, 0.12)', 'position = Vector3(0.92, 0.75, 0.12)', 'position = Vector3(-0.92, -0.09, 0.12)', 'position = Vector3(0.92, -0.09, 0.12)', 'spot_range = 1.05', 'spot_angle = 48.0', 'size = Vector2(3.56, 1.72)', 'armory_perforated_metal_v2.png', 'armory_frame_metal_v2.png']:
        if contract not in category_scene: fail(f'Dört yuvalı kategori rafı sahne sözleşmesi eksik: {contract}')
    for removed_geometry in ['size = Vector3(0.16, 2, 0.56)', 'size = Vector3(0.1, 1.72, 0.5)', 'size = Vector3(3.56, 0.1, 0.5)', 'position = Vector3(-1.86, 0, 0.15)', 'position = Vector3(1.86, 0, 0.15)']:
        if removed_geometry in category_scene: fail(f'Kategori rafındaki kalın/çakışan eski geometri kaldırılmamış: {removed_geometry}')
    for removed_contract in ['Mount01L', 'Mount04R', 'TaskStrip01', 'TaskStrip04', 'Bay01Panel', 'Bay04Panel', 'Bay01Label', 'Bay04Label', 'armory_weapon_bay_v2.png', 'TopFluorescentHousing', 'TopFluorescentEmitter', 'armory_fluorescent_diffuser_v1.png', 'Material_lamp', 'Mesh_lamp_housing', 'Mesh_lamp_emitter']:
        if removed_contract in category_scene: fail(f'Kategori rafındaki gereksiz görsel parça kaldırılmamış: {removed_contract}')
    expected_light_positions=['position = Vector3(-0.92, 0.75, 0.12)', 'position = Vector3(0.92, 0.75, 0.12)', 'position = Vector3(-0.92, -0.09, 0.12)', 'position = Vector3(0.92, -0.09, 0.12)']
    if any(category_scene.count(position) != 1 for position in expected_light_positions):
        fail('Her 2x2 silah hücresinin üzerinde tam bir ışık bulunmalı')
    for contract in ['category_label_key', 'top_light_color', 'top_light_energy', 'top_light_range', '_apply_scene_settings']:
        if contract not in category_script: fail(f'Kategori rafı Inspector sözleşmesi eksik: {contract}')
    if 'bay_codes' in category_script or 'bay_codes =' in hub:
        fail('Kaldırılan model-kod etiketlerinin Inspector kalıntısı temizlenmemiş')
    for contract in ['ArmoryCategoryVisuals', 'PistolCategoryRack', 'ShotgunCategoryRack', 'RifleCategoryRack', 'SmgCategoryRack', 'LaserCategoryRack', 'PistolRack', 'ShotgunRack', 'RifleRack', 'SmgRack', 'LaserRack', 'ARMORY_GROUP_SHOTGUN', 'ARMORY_GROUP_RIFLE', 'ARMORY_GROUP_SMG', 'ARMORY_GROUP_LASER']:
        if contract not in hub: fail(f'Bastion-7 profesyonel cephanelik sahne sözleşmesi eksik: {contract}')
    if len(re.findall(r'^\[node name="ArmoryCategoryVisuals" type="Node3D" parent="Props"[^\n]*\]$', hub, re.M)) != 1:
        fail('Bastion-7 ArmoryCategoryVisuals düğümü sahnede tam bir kez bulunmalı')
    for removed_2d_contract in ['name="LockerWall"', 'armory_locker_wall.png', 'ExtResource("19_armory_wall")']:
        if removed_2d_contract in hub: fail(f'Bastion-7 eski 2B cephanelik görselini hâlâ kullanıyor: {removed_2d_contract}')
    armory_block=hub.split('[node name="ArmoryRacks"', 1)[-1].split('[node name="Player"', 1)[0]
    if armory_block.count('instance=ExtResource("12_rack")') != 20: fail('Bastion-7 cephanelik silah yuvası sayısı 20 değil')
    if 'visible = false' in armory_block: fail('Bastion-7 cephanelik raflarından biri sahnede gizli')
    for position_contract in ['-16, 1.1, -14.35)', '-12, 1.1, -14.35)', '-8, 1.1, -14.35)', '-15.5, 1.1, -5.65)', '-8.5, 1.1, -5.65)', '-0.92, 0.42, -0.15)', '0.92, 0.42, -0.15)', '-0.92, -0.42, -0.15)', '0.92, -0.42, -0.15)']:
        if position_contract not in armory_block: fail(f'Cephanelik 2x2 erişim yuvası hizası eksik: {position_contract}')
    for centered_slot in ['-0.92, 0.42, -0.15', '0.92, 0.42, -0.15', '-0.92, -0.42, -0.15', '0.92, -0.42, -0.15']:
        count=len(re.findall(rf', {re.escape(centered_slot)}\)$', armory_block, re.M))
        if count != 5:
            fail(f'Yirmi raf yuvasının merkez/derinlik sözleşmesi bozuk: {centered_slot}')
    for fixed_contract in ['visual_world_width = 0.78', 'visual_world_width = 1.18', 'visual_world_width = 1.08', 'visual_world_width = 1.16']:
        if fixed_contract not in armory_block: fail(f'Cephanelik sabit silah görsel ayarı eksik: {fixed_contract}')
    p01_block=armory_block.split('[node name="P01Slot"', 1)[-1].split('[node name="P07Slot"', 1)[0]
    if 'weapon_texture = ExtResource("19_p01_side")' not in p01_block or 'visual_flip_h = true' in p01_block:
        fail('P-01 rafında doğru yönlü sağ-namlu görsel ayarı eksik')
    if 'visual_flip_h' not in rack or 'weapon_visual.flip_h = visual_flip_h' not in rack or 'empty_slot_visual.flip_h = visual_flip_h' not in rack:
        fail('Silah rafında Inspector yatay çevirme sözleşmesi eksik')
    if 'rotation_degrees = Vector3(0, 90, 0)' in armory_block or '-17.5, 1.1' in armory_block:
        fail('Firing range geçişinin önündeki eski yan raf kaldırılmamış')
    planned_weapon_ids=['p07','p14','p20','sg09','sg15','sg21','vx58','vx72','vx90','mp96','mp110','mp120','lx01','lx07','lx13','lx20']
    for weapon_id in planned_weapon_ids:
        if f'weapon_id = &"{weapon_id}"' not in armory_block: fail(f'Planlanan silah raf yuvası eksik: {weapon_id}')
    if 'target_position = Vector3(0, 0, -3.4)' not in player_scene:
        fail('Cephanelik üst yuvaları için Inspector etkileşim mesafesi 3.4 değil')
    for removed_table in ['name="Table"', 'name="Table2"', 'name="Table3"', 'name="Table4"', 'ExtResource("10_87vc6")']:
        if removed_table in hub: fail(f'Bastion-7 cephanelik önündeki masa kaldırılmamış: {removed_table}')
    expected_groups={
        'p01.tres': ('&"sidearm"', 'loadout_slot = 1'),
        'sg04.tres': ('&"sg04"', 'loadout_slot = 2'),
        'vx47.tres': ('&"rifle"', 'loadout_slot = 3'),
        'mp90.tres': ('&"smg"', 'loadout_slot = 4'),
    }
    for resource_name, contracts in expected_groups.items():
        resource=(ROOT/'resources/weapons'/resource_name).read_text(encoding='utf-8')
        if f'loadout_group = {contracts[0]}' not in resource or contracts[1] not in resource:
            fail(f'{resource_name} cephanelik grup/yuva ayarı yanlış')


def check_p01_visual_contract():
    frame_names=[
        'p01_idle.png', 'p01_side.png',
        'p01_fire_1.png', 'p01_fire_2.png', 'p01_fire_3.png', 'p01_fire_4.png',
        'p01_aim_fire_1.png', 'p01_aim_fire_2.png', 'p01_aim_fire_3.png', 'p01_aim_fire_4.png',
        'p01_reload_1.png', 'p01_reload_2.png', 'p01_reload_3.png', 'p01_reload_4.png',
        'p01_zoom.png',
    ]
    for frame_name in frame_names:
        exists(f'assets/weapons/p01/{frame_name}')
    side_path=ROOT/'assets/weapons/p01/p01_side.png'
    side_bytes=side_path.read_bytes() if side_path.exists() else b''
    if len(side_bytes) < 26 or side_bytes[25] not in (4, 6):
        fail('P-01 yandan görünüşünde gerçek PNG alfa kanalı yok')
    p01_view_path=ROOT/'scenes/ui/weapons/p01_view.tscn'
    sg04_view_path=ROOT/'scenes/ui/weapons/sg04_view.tscn'
    presenter_path=ROOT/'scripts/ui/hud_weapon_presenter.gd'
    for path in [p01_view_path, sg04_view_path, presenter_path]:
        if not path.exists():
            fail(f'Data-driven HUD silah sunumu eksik: {path.relative_to(ROOT)}')
            return
    p01_view=p01_view_path.read_text(encoding='utf-8')
    presenter=presenter_path.read_text(encoding='utf-8')
    definition=(ROOT/'scripts/player/weapon_definition.gd').read_text(encoding='utf-8')
    p01_resource=(ROOT/'resources/weapons/p01.tres').read_text(encoding='utf-8')
    hud_scene=(ROOT/'scenes/ui/hud.tscn').read_text(encoding='utf-8')
    hud_script=(ROOT/'scripts/ui/hud.gd').read_text(encoding='utf-8')
    hub_scene=(ROOT/'scenes/hub/bastion_7.tscn').read_text(encoding='utf-8')
    for frame_name in frame_names:
        if frame_name == 'p01_side.png':
            continue
        if f'res://assets/weapons/p01/{frame_name}' not in p01_view:
            fail(f'P-01 HUD karesi weapon view sahnesine bağlı değil: {frame_name}')
    for contract in ['"name": &"zoom"', '"name": &"aim_fire"', 'position = Vector2(1060, 772)', 'scale = Vector2(0.6, 0.6)']:
        if contract not in p01_view:
            fail(f'P-01 weapon view poz/animasyon sözleşmesi eksik: {contract}')
    for contract in ['hud_view_scene: PackedScene', 'hud_auto_lower_enabled', 'hud_lower_after_seconds', 'hud_zoom_offset', 'hud_aim_fire_offset', 'hud_lowered_offset']:
        if contract not in definition:
            fail(f'WeaponDefinition sunum verisi eksik: {contract}')
    for contract in ['hud_view_scene = ExtResource("2_view")', 'supports_ads_pose = true',  'hud_zoom_offset = Vector2(-176, 0)']:
        if contract not in p01_resource:
            fail(f'P-01 data-driven sunum resource sözleşmesi eksik: {contract}')
    for contract in ['class_name VexHudWeaponPresenter', 'definition.hud_view_scene.instantiate()', 'definition.supports_ads_pose', 'definition.supports_lowered_pose', 'requested_animation = &"aim_fire"', 'sprite.animation_changed.connect(animation_callable)', 'player.is_aiming']:
        if contract not in presenter:
            fail(f'HUD weapon presenter sözleşmesi eksik: {contract}')
    if presenter.count('if weapon_id == &"":') < 2 or 'if weapon_id == &"" or _weapon_sprites.has(weapon_id)' not in presenter:
        fail('HUD presenter boş/silahsız weapon ID durumunu sessizce ele almıyor')
    if 'PistolSprite' in hud_scene or 'ShotgunSprite' in hud_scene or 'p01_auto_lower_enabled' in hud_script:
        fail('HUD ana sahnesi/scripti hâlâ silaha özel P-01/SG-04 görsel implementasyonu taşıyor')
    for weapon in ['p01','sg04','vx47','mp90']:
        resource=(ROOT/f'resources/weapons/{weapon}.tres').read_text(encoding='utf-8')
        if 'hud_view_scene = ExtResource("2_view")' not in resource:
            fail(f'{weapon}: HUD sunumu WeaponDefinition üzerinden bağlı değil')
    for contract in ['res://assets/weapons/p01/p01_side.png', 'weapon_texture = ExtResource("19_p01_side")', 'visual_world_width = 0.78']:
        if contract not in hub_scene:
            fail(f'P-01 yandan cephanelik görünüşü eksik: {contract}')


def check_p14_playable_contract():
    asset_dir=ROOT/'assets/weapons/p14'
    frame_names=[
        'p14_idle.png', 'p14_side.png', 'p14_zoom.png',
        *[f'p14_fire_{index}.png' for index in range(1, 5)],
        *[f'p14_aim_fire_{index}.png' for index in range(1, 5)],
        *[f'p14_reload_{index}.png' for index in range(1, 5)],
    ]
    for frame_name in frame_names:
        path=asset_dir/frame_name
        if not path.exists():
            fail(f'P-14 görsel karesi eksik: {frame_name}')
            continue
        data=path.read_bytes()
        if len(data) < 26 or data[:8] != b'\x89PNG\r\n\x1a\n' or data[25] not in (4, 6):
            fail(f'P-14 görseli gerçek PNG alfa taşımıyor: {frame_name}')

    view_path=ROOT/'scenes/ui/weapons/p14_view.tscn'
    resource_path=ROOT/'resources/weapons/p14.tres'
    if not view_path.exists() or not resource_path.exists():
        fail('P-14 HUD sahnesi veya WeaponDefinition kaynağı eksik')
        return
    view=view_path.read_text(encoding='utf-8')
    resource=resource_path.read_text(encoding='utf-8')
    for frame_name in frame_names:
        if frame_name == 'p14_side.png':
            continue
        if f'res://assets/weapons/p14/{frame_name}' not in view:
            fail(f'P-14 HUD karesi weapon view sahnesine bağlı değil: {frame_name}')
    for contract in [
        '"name": &"idle"', '"name": &"fire"', '"name": &"aim_fire"',
        '"name": &"reload"', '"name": &"zoom"',
        'position = Vector2(1060, 772)', 'scale = Vector2(0.6, 0.6)',
    ]:
        if contract not in view:
            fail(f'P-14 HUD poz/animasyon sözleşmesi eksik: {contract}')
    for contract in [
        'weapon_id = &"p14"', 'loadout_group = &"sidearm"',
        'world_pickup_texture = ExtResource("3_side")', 'supports_ads_pose = true',
        'supports_flashlight = true', 'gunshot_noise_multiplier = 0.45',
        'magazine_size = 14', 'damage_per_pellet = 22',
        'fire_interval = 0.25', 'reload_duration = 1.15',
        'spread_degrees = 0.45', 'maximum_range = 100.0',
    ]:
        if contract not in resource:
            fail(f'P-14 WeaponDefinition sözleşmesi eksik: {contract}')

    player_scene=(ROOT/'scenes/player/player.tscn').read_text(encoding='utf-8')
    player_script=(ROOT/'scripts/player/player.gd').read_text(encoding='utf-8')
    controller=(ROOT/'scripts/player/weapon_controller.gd').read_text(encoding='utf-8')
    pickup=(ROOT/'scripts/props/pickup.gd').read_text(encoding='utf-8')
    hub=(ROOT/'scenes/hub/bastion_7.tscn').read_text(encoding='utf-8')
    upgrades=(ROOT/'scripts/player/weapon_upgrade_catalog.gd').read_text(encoding='utf-8')
    for contract in ['res://resources/weapons/p14.tres', 'ExtResource("3_p14")']:
        if contract not in player_scene:
            fail(f'Player P-14 bağlantısı eksik: {contract}')
    for contract in ['func equip_world_weapon(', 'displaced_weapon_id', 'weapon.gunshot_noise_multiplier']:
        if contract not in controller:
            fail(f'P-14/controller runtime sözleşmesi eksik: {contract}')
    for contract in ['_collect_sidearm_pickup', '_spawn_dropped_sidearm_pickup', 'pickup.persist_collection = false', 'pickup.amount = 0']:
        if contract not in player_script:
            fail(f'Tek-tabanca dünya drop sözleşmesi eksik: {contract}')
    for contract in ['"p01", "p07", "p14", "p20"', '@export var persist_collection := true']:
        if contract not in pickup:
            fail(f'Pickup tabanca/drop sözleşmesi eksik: {contract}')
    for contract in ['res://assets/weapons/p14/p14_side.png', 'weapon_texture = ExtResource("20_p14_side")']:
        if contract not in hub:
            fail(f'Bastion P-14 raf görseli eksik: {contract}')
    for contract in ['&"p14": [', 'UPGRADE_VARIABLE_SIGHT', 'UPGRADE_SILENT_BAFFLE', 'UPGRADE_NEEDLE_ROUNDS']:
        if contract not in upgrades:
            fail(f'P-14 geliştirme sözleşmesi eksik: {contract}')


def check_p20_playable_contract():
    asset_dir=ROOT/'assets/weapons/p20'
    frame_names=[
        'p20_idle.png', 'p20_side.png', 'p20_zoom.png',
        *[f'p20_fire_{index}.png' for index in range(1, 5)],
        *[f'p20_aim_fire_{index}.png' for index in range(1, 5)],
        *[f'p20_reload_{index}.png' for index in range(1, 5)],
    ]
    for frame_name in frame_names:
        path=asset_dir/frame_name
        if not path.exists():
            fail(f'P-20 görsel karesi eksik: {frame_name}')
            continue
        data=path.read_bytes()
        if len(data) < 26 or data[:8] != b'\x89PNG\r\n\x1a\n' or data[25] not in (4, 6):
            fail(f'P-20 görseli gerçek PNG alfa taşımıyor: {frame_name}')

    view_path=ROOT/'scenes/ui/weapons/p20_view.tscn'
    resource_path=ROOT/'resources/weapons/p20.tres'
    if not view_path.exists() or not resource_path.exists():
        fail('P-20 HUD sahnesi veya WeaponDefinition kaynağı eksik')
        return
    view=view_path.read_text(encoding='utf-8')
    resource=resource_path.read_text(encoding='utf-8')
    for frame_name in frame_names:
        if frame_name == 'p20_side.png':
            continue
        if f'res://assets/weapons/p20/{frame_name}' not in view:
            fail(f'P-20 HUD karesi weapon view sahnesine bağlı değil: {frame_name}')
    for contract in [
        '"name": &"idle"', '"name": &"fire"', '"name": &"aim_fire"',
        '"name": &"reload"', '"name": &"zoom"',
        'position = Vector2(1060, 772)', 'scale = Vector2(0.6, 0.6)',
    ]:
        if contract not in view:
            fail(f'P-20 HUD poz/animasyon sözleşmesi eksik: {contract}')
    for contract in [
        'weapon_id = &"p20"', 'ammo_type = &"magnum_ammo"',
        'loadout_group = &"sidearm"', 'world_pickup_texture = ExtResource("3_side")',
        'supports_ads_pose = true', 'supports_flashlight = true',
        'penetration_power = 0.5', 'magazine_size = 8',
        'damage_per_pellet = 42', 'headshot_multiplier = 2.1',
        'fire_interval = 0.45', 'reload_duration = 1.35',
        'spread_degrees = 0.7', 'maximum_range = 85.0',
        'reserve_ammo_capacity = 40',
    ]:
        if contract not in resource:
            fail(f'P-20 WeaponDefinition sözleşmesi eksik: {contract}')

    player_scene=(ROOT/'scenes/player/player.tscn').read_text(encoding='utf-8')
    player_script=(ROOT/'scripts/player/player.gd').read_text(encoding='utf-8')
    controller=(ROOT/'scripts/player/weapon_controller.gd').read_text(encoding='utf-8')
    pickup=(ROOT/'scripts/props/pickup.gd').read_text(encoding='utf-8')
    level=(ROOT/'scenes/levels/level_01.tscn').read_text(encoding='utf-8')
    hub=(ROOT/'scenes/hub/bastion_7.tscn').read_text(encoding='utf-8')
    upgrades=(ROOT/'scripts/player/weapon_upgrade_catalog.gd').read_text(encoding='utf-8')
    translations=(ROOT/'translations/vex.csv').read_text(encoding='utf-8')
    for contract in ['res://resources/weapons/p20.tres', 'ExtResource("3_p20")']:
        if contract not in player_scene:
            fail(f'Player P-20 bağlantısı eksik: {contract}')
    for contract in ['penetration_power', 'extra_target_count', 'target_limit', 'damage_target == null']:
        if contract not in controller:
            fail(f'P-20 hedef delme runtime sözleşmesi eksik: {contract}')
    for contract in ['&"p20"', '&"magnum_ammo"', 'PICKUP_P20_ACTIVE', '_spawn_dropped_sidearm_pickup']:
        if contract not in player_script:
            fail(f'Player P-20 pickup/swap sözleşmesi eksik: {contract}')
    for contract in ['"p20"', '"magnum_ammo"']:
        if contract not in pickup:
            fail(f'Pickup P-20/magnum tür sözleşmesi eksik: {contract}')
    for contract in ['name="P20MagnumTestPickup"', 'pickup_type = "p20"', 'level01_start_p20_magnum_test']:
        if contract not in level:
            fail(f'Level 1 P-20 test pickup sözleşmesi eksik: {contract}')
    for contract in ['res://assets/weapons/p20/p20_side.png', 'weapon_texture = ExtResource("20_p20_side")']:
        if contract not in hub:
            fail(f'Bastion P-20 raf görseli eksik: {contract}')
    for contract in ['&"p20": [', 'UPGRADE_INERTIAL_PISTON', 'UPGRADE_OVERPRESSURE_CORE', 'UPGRADE_RUPTURE_ROUND', '"penetration": 0.0']:
        if contract not in upgrades:
            fail(f'P-20 geliştirme sözleşmesi eksik: {contract}')
    for contract in ['HUD_AMMO_MAGNUM', 'PICKUP_P20_ACTIVE', 'AMMO_MAGNUM', 'UPGRADE_INERTIAL_PISTON', 'UPGRADE_OVERPRESSURE_CORE', 'UPGRADE_RUPTURE_ROUND']:
        if contract not in translations:
            fail(f'P-20 localization sözleşmesi eksik: {contract}')


def check_bastion_door_wall_contract():
    hub=(ROOT/'scenes/hub/bastion_7.tscn').read_text(encoding='utf-8')
    door=(ROOT/'scenes/props/door_side_slide.tscn').read_text(encoding='utf-8')
    door_script=(ROOT/'scripts/props/door.gd').read_text(encoding='utf-8')
    if 'ArmoryStatusTerminal' in hub or 'ARMORY_TERMINAL_INFO' in hub:
        fail('İşlevsiz ArmoryStatusTerminal Bastion-7 sahnesinden kaldırılmamış')
    if 'res://scenes/props/door_side_slide.tscn' not in hub:
        fail('Bastion-7 canonical kapı sahnesini kullanmıyor')
    if (ROOT/'scenes/props/door_side_slide_bastion.tscn').exists():
        fail('Eski ayrı Bastion kapı prefabı hâlâ mevcut')
    for level in ROOT.glob('scenes/levels/level_0[123].tscn'):
        lt=level.read_text(encoding='utf-8')
        if 'door_side_slide_bastion.tscn' in lt:
            fail(f'{level.name}: eski Bastion kapı prefabı referansı kaldı')
    for contract in [
        'size = Vector3(0.42, 4.48, 0.24)',
        'size = Vector3(0.42, 0.24, 4.92)',
        'position = Vector3(0, 0, -2.34)',
        'position = Vector3(0, 0, 2.34)',
        'position = Vector3(0, 2.36, 0)',
        '[node name="FrameCollision" type="StaticBody3D" parent="."]',
        '[node name="JambLeft" type="CollisionShape3D" parent="FrameCollision"]',
        '[node name="JambRight" type="CollisionShape3D" parent="FrameCollision"]',
        '[node name="Header" type="CollisionShape3D" parent="FrameCollision"]',
        'size = Vector3(0.37, 0.03, 1.96)',
        'position = Vector3(0, -2.225, -3.44)',
        'position = Vector3(0, -2.225, 3.44)',
        'size = Vector3(0.2, 4.48, 2.22)',
        'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -1.11)',
        'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1.11)',
        'opening_offset_left = Vector3(0, 0, -2.12)',
        'opening_offset_right = Vector3(0, 0, 2.12)',
    ]:
        if contract not in door:
            fail(f'Bastion kapı kasa/cep ölçü sözleşmesi eksik: {contract}')
    for contract, expected_count in {
        'size = Vector3(0.42, 4.48, 0.24)': 2,
        'size = Vector3(0.42, 0.24, 4.92)': 2,
        'position = Vector3(0, 0, -2.34)': 2,
        'position = Vector3(0, 0, 2.34)': 2,
        'position = Vector3(0, 2.36, 0)': 2,
    }.items():
        if door.count(contract) != expected_count:
            fail(f'Kapı kasası mesh/collision birebir eşleşmiyor: {contract}')
    for contract in [
        '@export var opening_offset_left := Vector3(0.0, 0.0, -2.12)',
        '@export var opening_offset_right := Vector3(0.0, 0.0, 2.12)',
    ]:
        if contract not in door_script:
            fail(f'Kapı açık konumunda 10 cm görünür kanat payı eksik: {contract}')
    for contract in [
        '[node name="PerceptionBlocker" type="StaticBody3D" parent="."]',
        'size = Vector3(0.24, 4.48, 4.44)',
        '[node name="DoorShadowBlocker" type="MeshInstance3D" parent="."]',
        'cast_shadow = 3',
    ]:
        if contract not in door:
            fail(f'Kapalı kapı görüş/ışık engelleme sözleşmesi eksik: {contract}')
    for contract in [
        'perception_blocker.collision_layer = 1 if fully_closed else 0',
        'shadow_blocker.visible = fully_closed',
    ]:
        if contract not in door_script:
            fail(f'Kapı blocker durum senkronu eksik: {contract}')
    geometry=hub.split('[node name="Geometry"', 1)[-1].split('[node name="Doors"', 1)[0]
    exact_counts={
        'piece_size = Vector3(0.4, 7, 2.54)': 10,
        'piece_size = Vector3(0.4, 2.28, 4.92)': 5,
        'piece_size = Vector3(4.92, 2.28, 0.4)': 1,
        ', 5.86, ': 6,
        'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -4.13, 3.5, 25)': 1,
        'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 4.13, 3.5, 25)': 1,
    }
    for contract, expected_count in exact_counts.items():
        actual_count=geometry.count(contract)
        if actual_count != expected_count:
            fail(f'Bastion duvar/kapı uç uca birleşim sayısı bozuk: {contract} -> {actual_count}/{expected_count}')
    for obsolete in [
        'piece_size = Vector3(0.4, 7, 2.78)',
        'floor_trim_',
        'piece_size = Vector3(0.4, 2.52, 4.44)',
        'piece_size = Vector3(4.44, 2.52, 0.4)',
        ', 5.74, ', '-13.61', '-6.39', '6.39', '13.61',
    ]:
        if obsolete in geometry:
            fail(f'Bastion geometrisinde bindirme yapan eski ölçü kaldı: {obsolete}')


def check_bastion_room_display_contract():
    hub=(ROOT/'scenes/hub/bastion_7.tscn').read_text(encoding='utf-8')
    display=(ROOT/'scenes/world/room_name_display.tscn').read_text(encoding='utf-8')
    display_script=(ROOT/'scripts/world/room_name_display.gd').read_text(encoding='utf-8')
    standard=(ROOT/'STANDART.txt').read_text(encoding='utf-8')
    if hub.count('instance=ExtResource("25_room_display")') != 6:
        fail('Bastion-7 oda adı ekranı sayısı 6 değil')
    if '[node name="RoomDisplays" type="Node3D" parent="."' not in hub:
        fail('Bastion-7 RoomDisplays root kategorisi eksik')
    for obsolete in ['[node name="Signage"', 'Panel_ArmoryDoor', 'Sign_ArmoryDoor', 'BoxMesh_door_sign_']:
        if obsolete in hub:
            fail(f'Bastion-7 eski çakışan oda tabelası yapısı kaldı: {obsolete}')
    for room_name in ['ARMORY', 'FIRING RANGE', 'RESEARCH LAB', 'WEAPON WORKSHOP', 'ENGINEERING BAY', 'OPERATOR PLATFORM']:
        if f'room_name = "{room_name}"' not in hub:
            fail(f'Bastion-7 dijital oda ekranı metni eksik: {room_name}')
    lamp_transforms=re.findall(r'^transform = Transform3D\(([^\n]+)\)$', hub.split('[node name="DoorLights"', 1)[-1].split('[node name="RoomDisplays"', 1)[0], re.M)
    lamp_positions=[tuple(float(value.strip()) for value in transform.split(',')[-3:]) for transform in lamp_transforms]
    if len(lamp_positions) != 12 or any(not math.isclose(y, 6.05, abs_tol=0.00001) for _x, y, _z in lamp_positions):
        fail('Bastion-7 kapı durum lambaları oda ekranından ayrı Y=6.05 hizasında değil')
    display_positions=[]
    room_block=hub.split('[node name="RoomDisplays"', 1)[-1].split('[node name="Props"', 1)[0]
    for match in re.finditer(r'^transform = Transform3D\(([^\n]+)\)$', room_block, re.M):
        values=[float(value.strip()) for value in match.group(1).split(',')]
        if len(values) == 12:
            display_positions.append(values[-2])
    if len(display_positions) != 6 or any(not math.isclose(y, 5.25, abs_tol=0.00001) for y in display_positions):
        fail('Bastion-7 oda ekranları canonical Y=5.25 hizasında değil')
    for contract in [
        'size = Vector3(4.2, 0.72, 0.12)', 'name="Screen" type="MeshInstance3D"',
        'font = ExtResource("2_font")', 'name="RoomName" type="Label3D"',
        'emission_enabled = true', 'Material_accent',
    ]:
        if contract not in display:
            fail(f'Canonical dijital oda ekranı görsel sözleşmesi eksik: {contract}')
    for contract in ['@tool', '@export var room_name', '@export var header_text', 'room_label.text = room_name']:
        if contract not in display_script:
            fail(f'Canonical dijital oda ekranı Inspector sözleşmesi eksik: {contract}')
    for contract in ['res://scenes/world/room_name_display.tscn', 'Bastion ekran root merkezi Y = 5.25 m', 'durum ışığı root merkezi Y = 6.05 m']:
        if contract not in standard:
            fail(f'STANDART dijital oda ekranı kuralı eksik: {contract}')


def check_professional_terminal_contract():
    terminal_scene=(ROOT/'scenes/hub/hub_terminal.tscn').read_text(encoding='utf-8')
    terminal_script=(ROOT/'scripts/hub/hub_terminal.gd').read_text(encoding='utf-8')
    menu_scene=(ROOT/'scenes/ui/terminal_menu.tscn').read_text(encoding='utf-8')
    menu_script=(ROOT/'scripts/ui/terminal_menu.gd').read_text(encoding='utf-8')
    mission_script=(ROOT/'scripts/data/mission_definition.gd').read_text(encoding='utf-8')
    hub_script=(ROOT/'scripts/hub/bastion_7.gd').read_text(encoding='utf-8')
    translations=(ROOT/'translations/vex.csv').read_text(encoding='utf-8')
    standard=(ROOT/'STANDART.txt').read_text(encoding='utf-8')
    screen_path=ROOT/'assets/ui/bastion_terminal_screen_idle.png'
    controls_path=ROOT/'assets/world/bastion7/bastion_terminal_controls.png'
    network_path=ROOT/'assets/ui/bastion_facility_network.png'

    for contract in [
        '[node name="HubTerminal" type="Node3D"',
        'res://assets/ui/bastion_terminal_screen_idle.png',
        'res://assets/world/bastion7/bastion_terminal_controls.png',
        '[node name="Plinth" type="MeshInstance3D" parent="Visuals"',
        '[node name="GroundToe" type="MeshInstance3D" parent="Visuals"',
        '[node name="Support" type="MeshInstance3D" parent="Visuals"',
        '[node name="ScreenSurface" type="Sprite3D" parent="Visuals/ScreenAssembly"',
        '[node name="TopRail" type="MeshInstance3D" parent="Visuals/ScreenAssembly"',
        '[node name="BottomRail" type="MeshInstance3D" parent="Visuals/ScreenAssembly"',
        '[node name="LeftRail" type="MeshInstance3D" parent="Visuals/ScreenAssembly"',
        '[node name="RightRail" type="MeshInstance3D" parent="Visuals/ScreenAssembly"',
        '[node name="DeckAssembly" type="Node3D" parent="Visuals"',
        '[node name="ControlSurface" type="MeshInstance3D" parent="Visuals/DeckAssembly"',
        '[node name="PhysicalBody" type="Node3D" parent="."',
        '[node name="SolidCollider" type="StaticBody3D" parent="PhysicalBody"',
        '[node name="ScreenInteraction" type="StaticBody3D" parent="."',
        '[node name="ScreenInteractionShape" type="CollisionShape3D" parent="ScreenInteraction"',
        'res://scenes/ui/terminal_menu.tscn',
        'instance=ExtResource("5_menu")',
    ]:
        if contract not in terminal_scene:
            fail(f'Gelişmiş 3B Bastion terminali fiziksel/görsel sözleşmesi eksik: {contract}')

    solid_block=terminal_scene.split('[node name="SolidCollider"', 1)[-1].split('\n[node ', 1)[0]
    screen_interaction_block=terminal_scene.split('[node name="ScreenInteraction"', 1)[-1].split('\n[node ', 1)[0]
    if 'collision_layer = 1' not in solid_block:
        fail('Bastion terminal fiziksel gövdesi world layer 1 üzerinde değil')
    if 'collision_layer = 8' not in screen_interaction_block:
        fail('Bastion terminal ekran etkileşimi layer 8 üzerinde değil')
    deck_transform=node_transform(terminal_scene, 'DeckAssembly')
    if deck_transform is None or not math.isclose(deck_transform[0][1][2], 0.20791216, abs_tol=0.00001) or not math.isclose(deck_transform[0][2][1], -0.20791216, abs_tol=0.00001):
        fail('Bastion terminal kumanda deck eğimi sahnede tanımlı değil')

    centered_nodes=['Plinth', 'GroundToe', 'Support', 'ScreenAssembly', 'Housing', 'ScreenSurface', 'TopRail', 'BottomRail', 'DeckAssembly', 'DeckShell', 'ControlSurface']
    for node_name in centered_nodes:
        origin=node_origin(terminal_scene, node_name)
        if origin is None or not math.isclose(origin[0], 0.0, abs_tol=0.00001):
            fail(f'Bastion terminal merkez simetrisi bozuk: {node_name}')

    rail_h_size=subresource_size(terminal_scene, 'BoxMesh_screen_rail_h')
    rail_v_size=subresource_size(terminal_scene, 'BoxMesh_screen_rail_v')
    screen_origin=node_origin(terminal_scene, 'ScreenSurface')
    top_origin=node_origin(terminal_scene, 'TopRail')
    bottom_origin=node_origin(terminal_scene, 'BottomRail')
    left_origin=node_origin(terminal_scene, 'LeftRail')
    right_origin=node_origin(terminal_scene, 'RightRail')
    if None in [rail_h_size, rail_v_size, screen_origin, top_origin, bottom_origin, left_origin, right_origin]:
        fail('Bastion terminal ekran çerçevesi geometri verisi okunamadı')
    else:
        expected_rail_x=(rail_h_size[0] - rail_v_size[0]) / 2.0
        expected_top_y=screen_origin[1] + (rail_v_size[1] + rail_h_size[1]) / 2.0
        expected_bottom_y=screen_origin[1] - (rail_v_size[1] + rail_h_size[1]) / 2.0
        if not approximately_equal_vector(left_origin, (-expected_rail_x, screen_origin[1], top_origin[2])) or not approximately_equal_vector(right_origin, (expected_rail_x, screen_origin[1], top_origin[2])):
            fail('Bastion terminal dikey ekran rayları simetrik ve uç uca hizalı değil')
        if not approximately_equal_vector(top_origin, (0.0, expected_top_y, top_origin[2])) or not approximately_equal_vector(bottom_origin, (0.0, expected_bottom_y, top_origin[2])):
            fail('Bastion terminal yatay ekran rayları simetrik ve uç uca hizalı değil')

    plinth_size=subresource_size(terminal_scene, 'BoxMesh_plinth')
    support_size=subresource_size(terminal_scene, 'BoxMesh_support')
    plinth_origin=node_origin(terminal_scene, 'Plinth')
    support_origin=node_origin(terminal_scene, 'Support')
    if None in [plinth_size, support_size, plinth_origin, support_origin] or not math.isclose(plinth_origin[1] + plinth_size[1] / 2.0, support_origin[1] - support_size[1] / 2.0, abs_tol=0.00001):
        fail('Bastion terminal plinth ile ekran desteği uç uca birleşmiyor')

    deck_size=subresource_size(terminal_scene, 'BoxMesh_deck')
    controls_size=subresource_size(terminal_scene, 'PlaneMesh_controls')
    deck_shell_origin=node_origin(terminal_scene, 'DeckShell')
    if deck_size is None or controls_size is None or not approximately_equal_vector((deck_size[0], deck_size[2]), controls_size):
        fail('Bastion terminal deck kabuğu ile kontrol yüzeyi aynı ayak izine sahip değil')
    if None not in [deck_transform, deck_shell_origin, deck_size, plinth_origin, plinth_size]:
        deck_contact=transform_point(deck_transform, (deck_shell_origin[0], deck_shell_origin[1] + deck_size[1] / 2.0, deck_shell_origin[2] + deck_size[2] / 2.0))
        plinth_front=plinth_origin[2] - plinth_size[2] / 2.0
        if not math.isclose(deck_contact[2], plinth_front, abs_tol=0.00001):
            fail('Bastion terminal deck arka üst kenarı plinth ön yüzüne temas etmiyor')

    for mesh_id, shape_id in [
        ('BoxMesh_plinth', 'BoxShape_plinth'),
        ('BoxMesh_toe', 'BoxShape_toe'),
        ('BoxMesh_support', 'BoxShape_support'),
        ('BoxMesh_deck', 'BoxShape_deck'),
        ('BoxMesh_screen_back', 'BoxShape_screen_back'),
        ('BoxMesh_screen_rail_h', 'BoxShape_screen_rail_h'),
        ('BoxMesh_screen_rail_v', 'BoxShape_screen_rail_v'),
    ]:
        if not approximately_equal_vector(subresource_size(terminal_scene, mesh_id), subresource_size(terminal_scene, shape_id)):
            fail(f'Bastion terminal collision ölçüsü görünür mesh ile eşleşmiyor: {shape_id}')

    for visual_name, collision_name in [
        ('Plinth', 'PlinthShape'),
        ('GroundToe', 'GroundToeShape'),
        ('Support', 'SupportShape'),
    ]:
        if not approximately_equal_vector(node_origin(terminal_scene, collision_name), node_origin(terminal_scene, visual_name)):
            fail(f'Bastion terminal collision transformu görünür mesh ile eşleşmiyor: {collision_name}')
    if deck_transform is not None and deck_shell_origin is not None:
        expected_deck_shape=transform_point(deck_transform, deck_shell_origin)
        if not approximately_equal_vector(node_origin(terminal_scene, 'DeckShape'), expected_deck_shape):
            fail('Bastion terminal deck collision transformu görünür deck ile eşleşmiyor')

    screen_assembly_transform=node_transform(terminal_scene, 'ScreenAssembly')
    for visual_name, collision_name in [
        ('Housing', 'ScreenHousingShape'),
        ('TopRail', 'TopRailShape'),
        ('BottomRail', 'BottomRailShape'),
        ('LeftRail', 'LeftRailShape'),
        ('RightRail', 'RightRailShape'),
    ]:
        visual_origin=node_origin(terminal_scene, visual_name)
        expected_collision=transform_point(screen_assembly_transform, visual_origin) if screen_assembly_transform is not None and visual_origin is not None else None
        if not approximately_equal_vector(node_origin(terminal_scene, collision_name), expected_collision):
            fail(f'Bastion terminal ekran collision transformu görünür mesh ile eşleşmiyor: {collision_name}')

    interaction_size=subresource_size(terminal_scene, 'BoxShape_screen_interaction')
    interaction_origin=node_origin(terminal_scene, 'ScreenInteraction')
    screen_world_origin=transform_point(screen_assembly_transform, screen_origin) if screen_assembly_transform is not None and screen_origin is not None else None
    if rail_h_size is not None and rail_v_size is not None:
        expected_interaction_size=(rail_h_size[0] - 2.0 * rail_v_size[0], rail_v_size[1], 0.02)
        if not approximately_equal_vector(interaction_size, expected_interaction_size):
            fail('Bastion terminal ekran etkileşim alanı gerçek çerçeve açıklığını kaplamıyor')
    if screen_world_origin is None or interaction_origin is None or not approximately_equal_vector(interaction_origin[:2], screen_world_origin[:2]) or interaction_origin[2] >= screen_world_origin[2]:
        fail('Bastion terminal ekran etkileşim alanı görünür ekranla hizalı değil')

    for generated_node in ['MeshInstance3D.new(', 'BoxMesh.new(', 'CollisionShape3D.new(']:
        if generated_node in terminal_script:
            fail(f'Bastion terminal scripti runtime geometri üretiyor: {generated_node}')
    for retired_contract in ['FrontVisual', '_refresh_screen', 'screen_label']:
        if retired_contract in terminal_scene or retired_contract in terminal_script:
            fail(f'Bastion terminalinde eski düz/dinamik ekran sözleşmesi kalmış: {retired_contract}')

    interact_block=terminal_script.split('func interact(', 1)[-1].split('\nfunc ', 1)[0]
    if 'terminal_menu.open_terminal(' not in interact_block:
        fail('Bastion terminal etkileşimi tam ekran terminal menüsünü açmıyor')
    if 'deploy_selected_hub_mission' in interact_block or 'select_hub_mission' in interact_block:
        fail('Bastion terminali hâlâ tek etkileşimde görev seçiyor/deploy ediyor')
    for contract in ['@onready var terminal_menu: VexTerminalMenu', 'TERMINAL_INTERACT_OPEN', 'func _get_mission_definitions() -> Array:']:
        if contract not in terminal_script:
            fail(f'Bastion terminal menü bağlantısı eksik: {contract}')
    if 'func get_mission_definitions() -> Array[VexMissionDefinition]:' not in hub_script:
        fail('Bastion sahnesi görev resource listesini terminale veri odaklı sunmuyor')

    for contract in [
        '[node name="TerminalRoot" type="Control" parent="."]',
        '[node name="Mission01Button" type="Button"',
        '[node name="Mission02Button" type="Button"',
        '[node name="Mission03Button" type="Button"',
        '[node name="FacilityPreview" type="TextureRect"',
        '[node name="SelectButton" type="Button"',
        '[node name="DeployButton" type="Button"',
        'res://assets/ui/automap_console_frame.png',
    ]:
        if contract not in menu_scene:
            fail(f'Terminal görev/tesis menüsü sahne sözleşmesi eksik: {contract}')
    for contract in [
        'enum FacilityStatus', 'GameState.campaign_stage >= definition.campaign_stage',
        'definition.campaign_stage == GameState.campaign_stage + 1',
        'definition.terminal_preview', 'GameState.select_hub_mission(',
        'GameState.deploy_selected_hub_mission()', 'get_tree().paused = true',
    ]:
        if contract not in menu_script:
            fail(f'Terminal görev/tesis menüsü ilerleme sözleşmesi eksik: {contract}')

    for contract in ['@export var terminal_code', '@export var facility_type', '@export var terminal_preview: Texture2D']:
        if contract not in mission_script:
            fail(f'MissionDefinition terminal sunum verisi eksik: {contract}')
    preview_regions=['Rect2(14, 8, 530, 925)', 'Rect2(571, 8, 530, 925)', 'Rect2(1128, 8, 530, 925)']
    for index, mission_name in enumerate(['vex01.tres', 'vex02.tres', 'vex03.tres']):
        mission=(ROOT/'resources/missions'/mission_name).read_text(encoding='utf-8')
        for contract in ['res://assets/ui/bastion_facility_network.png', 'terminal_preview = SubResource("AtlasTexture_terminal_preview")', preview_regions[index]]:
            if contract not in mission:
                fail(f'{mission_name}: terminal tesis görseli/data sözleşmesi eksik: {contract}')

    for key in [
        'TERMINAL_INTERACT_OPEN', 'TERMINAL_MENU_TITLE', 'TERMINAL_MENU_CLEARED_COUNT',
        'TERMINAL_STATUS_CLEARED', 'TERMINAL_STATUS_ACTIVE', 'TERMINAL_STATUS_LOCKED',
        'TERMINAL_MENU_SELECT', 'TERMINAL_MENU_DEPLOY', 'TERMINAL_FACILITY_ASH_MINE',
    ]:
        if re.search(rf'^{re.escape(key)},', translations, re.M) is None:
            fail(f'Terminal menü localization anahtarı eksik: {key}')

    for label, path in [('sabit ekran', screen_path), ('kumanda yüzeyi', controls_path)]:
        if path.exists():
            png=path.read_bytes()
            if len(png) < 26 or png[:8] != b'\x89PNG\r\n\x1a\n':
                fail(f'Bastion terminal {label} görseli geçerli PNG değil')
                continue
            width=int.from_bytes(png[16:20], 'big')
            height=int.from_bytes(png[20:24], 'big')
            if width < 1600 or height < 900:
                fail(f'Bastion terminal {label} çözünürlüğü yetersiz: {width}x{height}')
            if not math.isclose(width / height, 16 / 9, abs_tol=0.03):
                fail(f'Bastion terminal {label} 16:9 oranından fazla sapıyor: {width}x{height}')
    if network_path.exists():
        png=network_path.read_bytes()
        if len(png) < 26 or png[:8] != b'\x89PNG\r\n\x1a\n':
            fail('Bastion tesis ağı görseli geçerli PNG değil')
        else:
            width=int.from_bytes(png[16:20], 'big')
            height=int.from_bytes(png[20:24], 'big')
            if width < 1500 or height < 800:
                fail(f'Bastion tesis ağı görsel çözünürlüğü yetersiz: {width}x{height}')

    for contract in [
        'res://scenes/ui/terminal_menu.tscn', 'res://assets/ui/bastion_terminal_screen_idle.png',
        'res://assets/world/bastion7/bastion_terminal_controls.png',
        '`ScreenInteraction` layer 8', 'TEMİZLENDİ / SIRADAKİ HEDEF / KİLİTLİ',
        '`terminal_code`, `facility_type` ve `terminal_preview`',
        'X=0 merkez eksenine göre simetriktir',
        'aynı ölçü ve dünya transformuna sahiptir',
        'gerçek ekran açıklığını kaplar',
    ]:
        if contract not in standard:
            fail(f'STANDART profesyonel terminal kuralı eksik: {contract}')

def check_stale_files():
    tmp=list(ROOT.rglob('*.import*.tmp'))
    for p in tmp: warn(f'Temporary import dosyası: {p.relative_to(ROOT)}')
    todo=ROOT/'todo.md'
    if todo.exists() and 'TODO' in todo.read_text(encoding='utf-8').upper(): warn('todo.md hâlâ eski TODO maddeleri içeriyor; güncel yol haritası kullanın.')


def check_world_visual_standard():
    scanned=[ROOT/'scripts/world/world_piece.gd', ROOT/'scenes/world/world_piece.tscn', ROOT/'scenes/world/u_staircase.tscn']
    scanned.extend(ROOT.glob('scenes/levels/level_0[123].tscn'))
    scanned.append(ROOT/'scenes/hub/bastion_7.tscn')
    for path in scanned:
        text=path.read_text(encoding='utf-8')
        if 'floor_trim' in text or 'BaseTrim' in text:
            fail(f'Süpürgelik sistemi tamamen kaldırılmamış: {path.relative_to(ROOT)}')

    red_scene=(ROOT/'scenes/world/wall_lamp_red.tscn').read_text(encoding='utf-8')
    green_scene_path=ROOT/'scenes/world/wall_lamp_green.tscn'
    green_texture_path=ROOT/'assets/world/wall_lamp_green.png'
    if not green_scene_path.exists() or not green_texture_path.exists():
        fail('Yeşil kapı durum lambası sahnesi veya görseli eksik')
        return
    green_scene=green_scene_path.read_text(encoding='utf-8')
    for contract in ['pixel_size = 0.00175', 'light_energy = 0.58', 'spot_range = 3.2', 'spot_angle = 48.0']:
        if contract not in red_scene or contract not in green_scene:
            fail(f'Kırmızı/yeşil kapı lambası ölçü sözleşmesi uyuşmuyor: {contract}')
    for contract in ['shadow_enabled = false', 'light_specular = 0.0', 'light_volumetric_fog_energy = 0.0']:
        if contract not in red_scene or contract not in green_scene:
            fail(f'Kapı durum lambası düşük maliyetli dekor profilini kullanmıyor: {contract}')
    ceiling=(ROOT/'scenes/world/ceiling_light_white_horror.tscn').read_text(encoding='utf-8')
    if 'shadow_enabled = true' not in ceiling:
        fail('Ana tavan ışığında gölge kapalı; ışık kapalı kapıdan sızabilir')
    ceiling_script=(ROOT/'scripts/world/room_ceiling_light.gd').read_text(encoding='utf-8')
    if '@export var shadow_enabled := true:' not in ceiling_script:
        fail('Tavan ışığı runtime varsayılanında gölge kapalı')
    fill_path=ROOT/'scenes/world/ceiling_light_white_fill.tscn'
    large_path=ROOT/'scenes/world/ceiling_light_white_large.tscn'
    if not fill_path.exists() or not large_path.exists():
        fail('Canonical beyaz ışık profil sahneleri eksik: fill/large')
    else:
        fill_scene=fill_path.read_text(encoding='utf-8')
        large_scene=large_path.read_text(encoding='utf-8')
        for contract in ['ceiling_light_white_horror.tscn', 'light_energy = 3.8', 'light_range = 9.2', 'cone_angle = 42.0', 'cone_attenuation = 1.6', 'distance_attenuation = 0.3', 'shadow_enabled = false', 'light_specular = 0.0']:
            if contract not in fill_scene:
                fail(f'FULL/SPAWN beyaz ışık profili bozuk: {contract}')
        for contract in ['ceiling_light_white_horror.tscn', 'light_energy = 8.0', 'light_range = 20.0', 'cone_angle = 80.0', 'cone_attenuation = 4.0', 'distance_attenuation = 0.0', 'shadow_enabled = true']:
            if contract not in large_scene:
                fail(f'LARGE VOLUME beyaz ışık profili bozuk: {contract}')
    world_piece_scene=(ROOT/'scenes/world/world_piece.tscn').read_text(encoding='utf-8')
    world_piece_script=(ROOT/'scripts/world/world_piece.gd').read_text(encoding='utf-8')
    if 'cast_shadow = true' not in world_piece_scene or 'cast_shadow = 1' not in world_piece_scene or '@export var cast_shadow := true' not in world_piece_script:
        fail('Canonical world_piece gölge standardı açık değil')

    wall_shader_path=ROOT/'resources/shaders/world_wall_surface.gdshader'
    wall_material_path=ROOT/'resources/materials/wall_panel.tres'
    planar_shader_path=ROOT/'resources/shaders/world_planar_surface.gdshader'
    if not wall_shader_path.exists() or not wall_material_path.exists() or not planar_shader_path.exists():
        fail('World-space yüzey shader veya materyali eksik')
    else:
        wall_shader=wall_shader_path.read_text(encoding='utf-8')
        wall_material=wall_material_path.read_text(encoding='utf-8')
        planar_shader=planar_shader_path.read_text(encoding='utf-8')
        for contract in ['filter_linear_mipmap_anisotropic', 'MODEL_NORMAL_MATRIX', 'dominant_axis', 'world_position', 'SPECULAR = specular_value']:
            if contract not in wall_shader:
                fail(f'Duvar world projection shader sözleşmesi eksik: {contract}')
        for contract in ['world_wall_surface.gdshader', 'shader_parameter/tile_size_m = 4.0', 'shader_parameter/roughness_value = 0.86', 'shader_parameter/specular_value = 0.28']:
            if contract not in wall_material:
                fail(f'Duvar world-grid materyal sözleşmesi eksik: {contract}')
        for contract in ['filter_linear_mipmap_anisotropic', 'world_position.xz', 'SPECULAR = specular_value']:
            if contract not in planar_shader:
                fail(f'Zemin/tavan world planar shader sözleşmesi eksik: {contract}')
        for material_name, specular in [('floor_standard.tres', '0.3'), ('ceiling_standard.tres', '0.24')]:
            material=(ROOT/'resources/materials'/material_name).read_text(encoding='utf-8')
            if f'shader_parameter/specular_value = {specular}' not in material:
                fail(f'{material_name} kontrollü specular sözleşmesi bozuk')

    player_scene=(ROOT/'scenes/player/player.tscn').read_text(encoding='utf-8')
    flashlight_match=re.search(r'^\[node name="WeaponFlashlight"[^\n]*\]\n(.*?)(?=\n\[node |\Z)', player_scene, re.M | re.S)
    if flashlight_match is None:
        fail('Oyuncu feneri sahnede bulunamadı')
    else:
        for contract in ['position = Vector3(0.12, -0.12, -0.08)', 'light_specular = 0.3', 'light_volumetric_fog_energy = 0.0', 'shadow_enabled = true', 'shadow_bias = 0.08', 'shadow_normal_bias = 0.9', 'shadow_blur = 1.2', 'shadow_opacity = 0.9']:
            if contract not in flashlight_match.group(1):
                fail(f'Oyuncu feneri kalite/gölge sözleşmesi eksik: {contract}')
    project_settings=(ROOT/'project.godot').read_text(encoding='utf-8')
    if 'lights_and_shadows/positional_shadow/atlas_16_bits=false' not in project_settings:
        fail('Uzun menzilli fener için 32-bit positional shadow atlas sözleşmesi eksik')

    standard=(ROOT/'STANDART.txt').read_text(encoding='utf-8')
    for contract in [
        'Beyaz ışık gölge : profile göre bütçeli',
        'SHADOW CONTRACT:',
        'Kapı durum ışıkları (kırmızı/yeşil) dekoratif profildir: shadow KAPALI',
        'Canonical world_piece cast_shadow AÇIK',
        "Level 1/2/3 instance'ları shadow_enabled=false veya cast_shadow=false/0 ile bu standardı EZEMEZ",
        'world_wall_surface.gdshader',
        'Aynı düzlemdeki iki world_piece yüzeyi alan boyunca üst üste binmez',
    ]:
        if contract not in standard:
            fail(f'STANDART.txt görsel/performance contract eksik: {contract}')

    # First-person weapon sprites are CanvasItem assets rendered with the base
    # texture level. Generating unused mip chains costs GPU memory without
    # improving their presentation, so the import and scene filter must agree.
    for weapon_view_path in sorted((ROOT/'scenes/ui/weapons').glob('*_view.tscn')):
        weapon_view=weapon_view_path.read_text(encoding='utf-8')
        if 'texture_filter = 2' not in weapon_view:
            fail(f'{weapon_view_path.name}: HUD silahı mipmapsiz lineer filtreyi kullanmıyor')
        for texture_relative in sorted(set(re.findall(r'path="res://(assets/weapons/[^\"]+\.png)"', weapon_view))):
            import_path=ROOT/f'{texture_relative}.import'
            if not import_path.exists():
                fail(f'{texture_relative}: HUD silah texture import dosyası eksik')
                continue
            import_text=import_path.read_text(encoding='utf-8')
            if 'mipmaps/generate=false' not in import_text:
                fail(f'{texture_relative}: sabit ölçekli HUD texture için gereksiz mipmap açık')

    light_profile_contracts={
        'level_01.tscn': ('26_room_light', 36, '36_room_fill', 1, None, 0),
        'level_02.tscn': ('26_room_light', 32, '36_room_fill', 1, None, 0),
        'level_03.tscn': ('15_room_light', 17, None, 0, None, 0),
    }
    forbidden_instance_keys=['light_energy', 'light_range', 'cone_angle', 'cone_attenuation', 'distance_attenuation', 'shadow_enabled']
    for filename, (normal_id, normal_count, fill_id, fill_count, large_id, large_count) in light_profile_contracts.items():
        level_scene=(ROOT/'scenes/levels'/filename).read_text(encoding='utf-8')
        if re.search(r'^shadow_enabled\s*=\s*false$', level_scene, re.M):
            fail(f'{filename} canonical shadow standardını shadow_enabled=false ile eziyor')
        if re.search(r'^cast_shadow\s*=\s*(?:false|0)$', level_scene, re.M):
            fail(f'{filename} canonical world_piece shadow standardını cast_shadow=false/0 ile eziyor')
        if level_scene.count(f'instance=ExtResource("{normal_id}")') != normal_count:
            fail(f'{filename} NORMAL ROOM ışık sayısı standardı bozuk')
        if fill_id is not None and level_scene.count(f'instance=ExtResource("{fill_id}")') != fill_count:
            fail(f'{filename} FULL/SPAWN ışık sayısı standardı bozuk')
        if large_id is not None and level_scene.count(f'instance=ExtResource("{large_id}")') != large_count:
            fail(f'{filename} LARGE VOLUME ışık sayısı standardı bozuk')
        profile_ids=[profile_id for profile_id in [normal_id, fill_id, large_id] if profile_id is not None]
        for profile_id in profile_ids:
            for match in re.finditer(rf'\[node name="([^"]+)"[^\n]*instance=ExtResource\("{re.escape(profile_id)}"\)\]\n(.*?)(?=\n\[node |\Z)', level_scene, re.S):
                node_name, body=match.groups()
                for key in forbidden_instance_keys:
                    if re.search(rf'^{key} = ', body, re.M):
                        fail(f'{filename}:{node_name} canonical ışık profilini instance override ile eziyor: {key}')
    hub_scene=(ROOT/'scenes/hub/bastion_7.tscn').read_text(encoding='utf-8')
    if hub_scene.count('instance=ExtResource("9_white")') != 8 or hub_scene.count('instance=ExtResource("23_white_large")') != 1:
        fail('Bastion-7 beyaz ışık profilleri 8 NORMAL + 1 LARGE standardında değil')
    for profile_id in ['9_white', '23_white_large']:
        for match in re.finditer(rf'\[node name="([^"]+)"[^\n]*instance=ExtResource\("{profile_id}"\)\]\n(.*?)(?=\n\[node |\Z)', hub_scene, re.S):
            node_name, body=match.groups()
            for key in forbidden_instance_keys:
                if re.search(rf'^{key} = ', body, re.M):
                    fail(f'bastion_7.tscn:{node_name} canonical ışık profilini instance override ile eziyor: {key}')
    png=green_texture_path.read_bytes()
    if len(png) < 26 or png[:8] != b'\x89PNG\r\n\x1a\n' or int.from_bytes(png[16:20], 'big') != 768 or int.from_bytes(png[20:24], 'big') != 320 or png[25] not in (4, 6):
        fail('Yeşil kapı lambası 768x320 gerçek alfa kanallı PNG değil')

    mappings=[
        ('level_01.tscn', '19_lamp_red', '30_lamp_green', 4, 20, {'Lamp_25_27_1','Lamp_25_27_2','Lamp_35_37_1','Lamp_35_37_2'}),
        ('level_02.tscn', '19_lamp_red', '30_lamp_green', 8, 2, {f'D0{i}_Lamp{j}' for i in range(1,5) for j in (1,2)}),
        ('level_03.tscn', '16_red_lamp', '35_green_lamp', 4, 24, {f'Door{i:02d}_Lamp{x}' for i in (6,10) for x in ('A','B')}),
    ]
    for filename, red_id, green_id, red_count, green_count, expected_red_names in mappings:
        scene=(ROOT/'scenes/levels'/filename).read_text(encoding='utf-8')
        actual_red=set(re.findall(rf'^\[node name="([^"]+)"[^\n]*instance=ExtResource\("{red_id}"\)', scene, re.M))
        actual_green=re.findall(rf'^\[node name="([^"]+)"[^\n]*instance=ExtResource\("{green_id}"\)', scene, re.M)
        if actual_red != expected_red_names or len(actual_red) != red_count or len(actual_green) != green_count:
            fail(f'{filename} kapı ışığı kuralı bozuk: kırmızı {len(actual_red)}/{red_count}, yeşil {len(actual_green)}/{green_count}')


def check_coplanar_world_piece_overlaps():
    scenes=[
        ROOT/'scenes/levels/level_01.tscn',
        ROOT/'scenes/levels/level_02.tscn',
        ROOT/'scenes/levels/level_03.tscn',
        ROOT/'scenes/hub/bastion_7.tscn',
    ]
    for path in scenes:
        scene=path.read_text(encoding='utf-8')
        world_piece_ids=set(re.findall(
            r'^\[ext_resource[^\n]*path="res://scenes/world/world_piece\.tscn"[^\n]*id="([^"]+)"\]$',
            scene,
            re.M,
        ))
        pieces=[]
        for match in re.finditer(r'^\[node name="([^"]+)"[^\n]*instance=ExtResource\("([^"]+)"\)\]\n(.*?)(?=\n\[node |\Z)', scene, re.M | re.S):
            node_name, resource_id, body=match.groups()
            if resource_id not in world_piece_ids:
                continue
            size_match=re.search(r'^piece_size = Vector3\(([^\n]+)\)$', body, re.M)
            if size_match is None:
                continue
            size=tuple(float(value.strip()) for value in size_match.group(1).split(','))
            transform_match=re.search(r'^transform = Transform3D\(([^\n]+)\)$', body, re.M)
            if transform_match is None:
                transform=(((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)), (0.0, 0.0, 0.0))
            else:
                values=[float(value.strip()) for value in transform_match.group(1).split(',')]
                if len(values) != 12:
                    fail(f'{path.name}:{node_name} Transform3D parse edilemedi')
                    continue
                transform=((tuple(values[0:3]), tuple(values[3:6]), tuple(values[6:9])), tuple(values[9:12]))
            corners=[]
            for x in (-size[0] * 0.5, size[0] * 0.5):
                for y in (-size[1] * 0.5, size[1] * 0.5):
                    for z in (-size[2] * 0.5, size[2] * 0.5):
                        corners.append(transform_point(transform, (x, y, z)))
            lower=tuple(min(point[axis] for point in corners) for axis in range(3))
            upper=tuple(max(point[axis] for point in corners) for axis in range(3))
            spans=tuple(upper[axis] - lower[axis] for axis in range(3))
            thin_axis=min(range(3), key=lambda axis: spans[axis])
            if spans[thin_axis] <= 0.41:
                pieces.append((node_name, lower, upper, thin_axis))

        overlaps=[]
        for index, first in enumerate(pieces):
            first_name, first_lower, first_upper, first_axis=first
            for second_name, second_lower, second_upper, second_axis in pieces[index + 1:]:
                if first_axis != second_axis:
                    continue
                first_center=(first_lower[first_axis] + first_upper[first_axis]) * 0.5
                second_center=(second_lower[second_axis] + second_upper[second_axis]) * 0.5
                if not math.isclose(first_center, second_center, abs_tol=0.001):
                    continue
                surface_axes=[axis for axis in range(3) if axis != first_axis]
                surface_overlap=[
                    min(first_upper[axis], second_upper[axis]) - max(first_lower[axis], second_lower[axis])
                    for axis in surface_axes
                ]
                if all(value > 0.01 for value in surface_overlap):
                    overlaps.append(f'{first_name} <-> {second_name}')
        if overlaps:
            preview=', '.join(overlaps[:6])
            suffix=f' (+{len(overlaps) - 6})' if len(overlaps) > 6 else ''
            fail(f'{path.name} aynı düzlemde çakışan world_piece içeriyor: {preview}{suffix}')


def check_door_frame_wall_alignment():
    scene_paths=[
        ROOT/'scenes/levels/level_01.tscn',
        ROOT/'scenes/levels/level_02.tscn',
        ROOT/'scenes/levels/level_03.tscn',
        ROOT/'scenes/hub/bastion_7.tscn',
    ]
    expected_door_count=61
    checked_door_count=0

    def parse_transform(body: str):
        match=re.search(r'^transform = Transform3D\(([^\n]+)\)$', body, re.M)
        if match is None:
            return (
                ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)),
                (0.0, 0.0, 0.0),
            )
        values=[float(value.strip()) for value in match.group(1).split(',')]
        if len(values) != 12:
            return None
        axes=(tuple(values[0:3]), tuple(values[3:6]), tuple(values[6:9]))
        return axes, tuple(values[9:12])

    def add_vector(first, second):
        return tuple(first[index] + second[index] for index in range(3))

    def scale_vector(vector, scalar):
        return tuple(component * scalar for component in vector)

    def dot(first, second):
        return sum(first[index] * second[index] for index in range(3))

    def piece_bounds_in_door_space(piece, door_transform):
        piece_axes, piece_origin=piece['transform']
        door_axes, door_origin=door_transform
        corners=[]
        for x in (-piece['size'][0] * 0.5, piece['size'][0] * 0.5):
            for y in (-piece['size'][1] * 0.5, piece['size'][1] * 0.5):
                for z in (-piece['size'][2] * 0.5, piece['size'][2] * 0.5):
                    world=piece_origin
                    world=add_vector(world, scale_vector(piece_axes[0], x))
                    world=add_vector(world, scale_vector(piece_axes[1], y))
                    world=add_vector(world, scale_vector(piece_axes[2], z))
                    relative=tuple(world[index] - door_origin[index] for index in range(3))
                    corners.append(tuple(dot(relative, door_axes[axis]) for axis in range(3)))
        lower=tuple(min(corner[axis] for corner in corners) for axis in range(3))
        upper=tuple(max(corner[axis] for corner in corners) for axis in range(3))
        return lower, upper

    for path in scene_paths:
        scene=path.read_text(encoding='utf-8')
        ext_resources={
            match.group(2): match.group(1)
            for match in re.finditer(r'^\[ext_resource[^\n]*path="([^"]+)"[^\n]*id="([^"]+)"\]$', scene, re.M)
        }
        door_ids={resource_id for resource_id, resource_path in ext_resources.items() if resource_path == 'res://scenes/props/door_side_slide.tscn'}
        piece_ids={resource_id for resource_id, resource_path in ext_resources.items() if resource_path == 'res://scenes/world/world_piece.tscn'}
        doors=[]
        pieces=[]
        for match in re.finditer(r'^\[node name="([^"]+)"([^\n]*)\]\n(.*?)(?=\n\[node |\Z)', scene, re.M | re.S):
            node_name, header, body=match.groups()
            instance_match=re.search(r'instance=ExtResource\("([^"]+)"\)', header)
            if instance_match is None:
                continue
            resource_id=instance_match.group(1)
            transform=parse_transform(body)
            if transform is None:
                fail(f'{path.name}:{node_name} kapı bağlantısı Transform3D parse edilemedi')
                continue
            if resource_id in door_ids:
                doors.append({'name': node_name, 'transform': transform})
            elif resource_id in piece_ids:
                size_match=re.search(r'^piece_size = Vector3\(([^\n]+)\)$', body, re.M)
                if size_match is not None:
                    size=tuple(float(value.strip()) for value in size_match.group(1).split(','))
                    pieces.append({'name': node_name, 'transform': transform, 'size': size})

        checked_door_count += len(doors)
        for door in doors:
            negative_sides=[]
            positive_sides=[]
            top_fills=[]
            for piece in pieces:
                lower, upper=piece_bounds_in_door_space(piece, door['transform'])
                spans=tuple(upper[axis] - lower[axis] for axis in range(3))
                if abs((lower[0] + upper[0]) * 0.5) > 0.06 or spans[0] > 0.45:
                    continue
                if lower[1] < -2.20 and upper[1] > 4.70:
                    if upper[2] <= 0.0:
                        negative_sides.append((abs(upper[2] + 2.46), piece['name'], lower, upper))
                    if lower[2] >= 0.0:
                        positive_sides.append((abs(lower[2] - 2.46), piece['name'], lower, upper))
                if lower[1] >= 2.40 and upper[1] > 4.70 and lower[2] < 0.0 < upper[2]:
                    error=abs(lower[1] - 2.48) + abs(lower[2] + 2.46) + abs(upper[2] - 2.46)
                    top_fills.append((error, piece['name'], lower, upper))

            negative=min(negative_sides, default=None, key=lambda item: item[0])
            positive=min(positive_sides, default=None, key=lambda item: item[0])
            top=min(top_fills, default=None, key=lambda item: item[0])
            errors=[]
            if negative is None or not math.isclose(negative[3][2], -2.46, abs_tol=0.002):
                errors.append('sol yan duvar/jamb dış yüzü')
            if positive is None or not math.isclose(positive[2][2], 2.46, abs_tol=0.002):
                errors.append('sağ yan duvar/jamb dış yüzü')
            if top is None:
                errors.append('üst dolgu/header')
            else:
                top_lower, top_upper=top[2], top[3]
                if not math.isclose(top_lower[1], 2.48, abs_tol=0.002):
                    errors.append('üst dolgu alt yüzü')
                if not math.isclose(top_lower[2], -2.46, abs_tol=0.002) or not math.isclose(top_upper[2], 2.46, abs_tol=0.002):
                    errors.append('üst dolgu genişliği')
            if errors:
                fail(f'{path.name}:{door["name"]} kapı kasası/duvar uç uca değil: {", ".join(errors)}')

    if checked_door_count != expected_door_count:
        fail(f'Kapı kasası/duvar hizası denetlenen kapı sayısı yanlış: {checked_door_count}/{expected_door_count}')

    door_scene=(ROOT/'scenes/props/door_side_slide.tscn').read_text(encoding='utf-8')
    for contract, expected_count in {
        'size = Vector3(0.2, 4.48, 2.22)': 2,
        '1.0183498': 4,
        'size = Vector3(0.24, 4.48, 4.44)': 2,
    }.items():
        if door_scene.count(contract) != expected_count:
            fail(f'Canonical kapı kanadı/görsel/blocker uç uca ölçüsü bozuk: {contract}')
    for obsolete in ['1.05505', '0.011767507', ', 0, 0, -1.12)', ', 0, 0, 1.12)', 'Vector3(0.24, 4.48, 4.48)']:
        if obsolete in door_scene:
            fail(f'Canonical kapıda eski bindirme/boşluk değeri kaldı: {obsolete}')
    standard=(ROOT/'STANDART.txt').read_text(encoding='utf-8')
    for contract in [
        'Kapalı kanat merkezleri        : Z -1.11 / +1.11 m',
        'Yatay yan duvar parçası : 3.34 x 7.00 x 0.40 m',
        'Yatay top-fill          : 4.92 x 2.28 x 0.40 m',
        'Yan duvarların iç kenarları Z/X -2.46 ve +2.46',
        'Kapı prefabı bulunmayan açık geçitlerde 4.44 m net açıklık',
    ]:
        if contract not in standard:
            fail(f'STANDART kapı kasası/duvar hizası kuralı eksik: {contract}')


def check_runtime_signal_contracts():
    game_state = (ROOT/'scripts/autoload/game_state.gd').read_text(encoding='utf-8')
    level_02 = (ROOT/'scripts/levels/level_02.gd').read_text(encoding='utf-8')
    base_level = (ROOT/'scripts/levels/base_level.gd').read_text(encoding='utf-8')
    weapon = (ROOT/'scripts/player/weapon_controller.gd').read_text(encoding='utf-8')
    if 'signal gunshot_emitted(position: Vector3, loudness: float, source: Node)' not in game_state:
        fail('GameState gunshot_emitted sinyali eksik')
    if 'GameState.gunshot_emitted.connect(_on_gunshot_emitted)' not in base_level:
        fail('VEX-02 gunshot sinyali bağlantısı eksik')
    if 'VexNoiseManager' in level_02:
        fail('VEX-02 eski VexNoiseManager referansını hâlâ kullanıyor')
    if 'GameState.emit_gunshot(' not in weapon:
        fail('WeaponController ateş sesi GameState.emit_gunshot() kullanmıyor')


def check_level_briefings():
    base=(ROOT/'scripts/levels/base_level.gd').read_text(encoding='utf-8')
    for contract in ['class_name VexBaseLevel', 'briefing_story', 'briefing_objective', 'func _show_briefing()', 'BRIEFING_CONTINUE', 'process_mode = Node.PROCESS_MODE_DISABLED', 'func get_automap_config()']:
        if contract not in base: fail(f'BaseLevel ortak bölüm sözleşmesi eksik: {contract}')
    for name in ['level_01.gd', 'level_02.gd', 'level_03.gd']:
        text=(ROOT/'scripts/levels'/name).read_text(encoding='utf-8')
        if 'extends VexBaseLevel' not in text: fail(f'{name}: VexBaseLevel kullanmıyor')



def check_level_01_layout_contract():
    scene=(ROOT/'scenes/levels/level_01.tscn').read_text(encoding='utf-8')
    for contract in [
        'map_revision = "VEX01-R28-37ROOM-13STEP"',
        'automap_columns = 5', 'automap_rows = 13',
        'automap_world_min = Vector2(-30, -65)', 'automap_world_max = Vector2(30, 65)',
        'automap_start_cell = Vector2i(2, 12)', 'automap_exit_cell = Vector2i(2, 0)',
    ]:
        if contract not in scene:
            fail(f'VEX-01 37 oda/13 basamak harita sözleşmesi eksik: {contract}')

    floor_matches=re.findall(
        r'^\[node name="Floor_R(\d{2})"[^\n]*\]\ntransform = Transform3D\([^\n]+, ([^,]+), -0\.2, ([^)]+)\)',
        scene, re.M
    )
    if len(floor_matches) != 37:
        fail(f'VEX-01 oda zemin sayısı 37 değil: {len(floor_matches)}')
    else:
        row_counts={}
        x_by_z={}
        for _room_id, x_text, z_text in floor_matches:
            x=round(float(x_text.strip()), 3)
            z=round(float(z_text.strip()), 3)
            row_counts[z]=row_counts.get(z,0)+1
            x_by_z.setdefault(z,[]).append(x)
        expected_counts=[1,3,5,3,1,3,5,3,1,3,5,3,1]
        actual=[row_counts.get(float(60-10*step),0) for step in range(13)]
        if actual != expected_counts:
            fail(f'VEX-01 basamak oda dağılımı bozuk: {actual} / {expected_counts}')
        expected_x={1:[0.0],3:[-12.0,0.0,12.0],5:[-24.0,-12.0,0.0,12.0,24.0]}
        for step,count in enumerate(expected_counts):
            z=float(60-10*step)
            if sorted(x_by_z.get(z,[])) != expected_x[count]:
                fail(f'VEX-01 basamak {step+1} oda merkezleri standarda uymuyor')

    if scene.count('name="Ceiling_R') != 37:
        fail('VEX-01 tavan sayısı 37 oda ile eşleşmiyor')
    door_names=set(re.findall(r'^\[node name="(Door_\d{2}_\d{2})"[^\n]*parent="Doors"', scene, re.M))
    expected_edges={
        (1,3),(2,3),(2,6),(3,4),(3,7),(4,8),(5,6),(6,10),(7,11),(8,9),(8,12),(11,13),
        (13,15),(14,15),(14,18),(15,16),(15,19),(16,20),(17,18),(18,22),(19,23),(20,21),(20,24),(23,25),
        (25,27),(26,27),(26,30),(27,28),(27,31),(28,32),(29,30),(30,34),(31,35),(32,33),(32,36),(35,37),
    }
    expected_names={f'Door_{a:02d}_{b:02d}' for a,b in expected_edges}
    if door_names != expected_names:
        fail(f'VEX-01 seçici oda bağlantı grafiği bozuk: {len(door_names)}/{len(expected_names)} kapı')
    if scene.count('parent="Doors" instance=ExtResource("8_door")') != 36:
        fail('VEX-01 bağlantı ağacı 36 kapı olmalı')
    for contract in [
        '[node name="Door_25_27" parent="Doors" instance=ExtResource("8_door")]',
        'required_key = &"blue"',
        '[node name="Door_35_37" parent="Doors" instance=ExtResource("8_door")]',
        'required_keys = Array[StringName]([&"blue", &"red"])',
        'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 60)',
        'transform = Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 5.72, 1.6, -60)',
    ]:
        if contract not in scene:
            fail(f'VEX-01 ilerleme/başlangıç/çıkış sözleşmesi eksik: {contract}')

def check_level_02_progression():
    scene=(ROOT/'scenes/levels/level_02.tscn').read_text(encoding='utf-8')
    script=(ROOT/'scripts/levels/level_02.gd').read_text(encoding='utf-8')
    if '22.5, 0.7, -21.25' not in scene:
        fail('VEX-02 sarı kart güvenli doğu kanadı konumunda değil')
    if '0, 0.7, 5' in scene:
        fail('VEX-02 sarı kart eski duvar konumunda kalmış')
    expected=[
        'LEVEL02_OBJECTIVE_START',
        'LEVEL02_OBJECTIVE_BLUE',
        'LEVEL02_OBJECTIVE_YELLOW',
        'LEVEL02_OBJECTIVE_RED',
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
    stair_path=ROOT/'scenes/world/u_staircase.tscn'
    stair=stair_path.read_text(encoding='utf-8') if stair_path.exists() else ''
    hub=(ROOT/'scenes/hub/bastion_7.tscn').read_text(encoding='utf-8')
    story_path=ROOT/'Story_VEX.md'
    if not story_path.exists():
        fail('Kampanya hikâye dosyası eksik: Story_VEX.md')
        story=''
    else:
        story=story_path.read_text(encoding='utf-8')
    required_scene=[
        'LEVEL03_NAME', 'Ceiling_L06_MaintenanceHall',
        'Stairs', 'res://scenes/world/u_staircase.tscn', 'UpperDeck',
        'vex03_secret_maintenance_cache', 'vex03_secret_upper_archive',
        'vex03_korvath_warden', 'res://scenes/world/korvath_rift.tscn',
        'vex03_log_transfer_41', 'vex03_log_korvath', 'vex03_log_ece_signal',
    ]
    for contract in required_scene:
        if contract not in scene: fail(f'VEX-03 sahne sözleşmesi eksik: {contract}')
    for contract in [
        'SmoothRampCollision', 'LowerRamp', 'Landing', 'UpperRamp',
        'StairLowerSmoothRamp', 'StairLandingCollision', 'StairUpperSmoothRamp',
        'StairTread_L01', 'StairTread_L13', 'StairTread_U01', 'StairTread_U13',
        'StairSafety_L01', 'StairSafety_L13', 'StairSafety_U01', 'StairSafety_U13',
        'RailLowerLeft', 'RailLowerRight', 'RailUpperLeft', 'RailUpperRight',
        'LandingRailNorthConnector', 'LandingRailSouthConnector', 'LandingRailEast',
        'material_override = ExtResource("3_stair_safety")',
    ]:
        if contract not in stair:
            fail(f'VEX-03 yeni U-merdiven fizik/görsel sözleşmesi eksik: {contract}')
    if stair.count('collision_layer = 1') != 1:
        fail('VEX-03 smooth merdiven collision gövdesi layer 1 üzerinde değil')
    if stair.count('parent="Collision/SmoothRampCollision"') != 3:
        fail('VEX-03 merdiven collision alt rampa + sahanlık + üst rampa olarak 3 yüzey kullanmıyor')
    if stair.count('name="StairTread_L') != 13 or stair.count('name="StairTread_U') != 13:
        fail('VEX-03 merdiven 13 + 13 temiz görsel basamak kullanmıyor')
    if stair.count('material_override = ExtResource("3_stair_safety")') != 26:
        fail('VEX-03 sarı/turuncu basamak güvenlik şeritleri eksik')
    for rail_name in ['RailLowerLeft', 'RailLowerRight', 'RailUpperLeft', 'RailUpperRight']:
        if stair.count(f'name="{rail_name}"') != 1:
            fail(f'VEX-03 {rail_name} tek parça sürekli korkuluk değil')
    if re.search(r'name="Rail(?:Lower|Upper)(?:Left|Right)_\d+', stair):
        fail('VEX-03 segment segment merdiven korkuluğu geri gelmiş')
    if scene.count('instance=ExtResource("33_staircase")') != 1 or '[node name="Collision" type="Node3D" parent="Geometry/Stairs"' in scene:
        fail('VEX-03 tekrar kullanılabilir U-merdiven sahnesini tek instance olarak kullanmıyor')
    if re.search(r'^cast_shadow\s*=\s*(?:false|0)$', stair, re.M):
        fail('Tekrar kullanılabilir U-merdiven sahnesinde gölgesi kapalı parça kaldı')
    for forbidden_stair_contract in ['LowerShape_00', 'UpperShape_00', 'StairSolidL00', 'StairSolidU00', 'StepCollisionLower', 'StepCollisionUpper']:
        if forbidden_stair_contract in scene:
            fail(f'VEX-03 eski basamak collision sistemi geri gelmiş: {forbidden_stair_contract}')
    player_script=(ROOT/'scripts/player/player.gd').read_text(encoding='utf-8')
    player_scene=(ROOT/'scenes/player/player.tscn').read_text(encoding='utf-8')
    for stair_move_contract in ['max_stair_step_height := 0.30', 'func _try_step_up(', 'test_move(global_transform, horizontal_motion)', 'apply_floor_snap()']:
        if stair_move_contract not in player_script:
            fail(f'Oyuncu stair-step hareket desteği eksik: {stair_move_contract}')
    if 'floor_snap_length = 0.4' not in player_scene:
        fail('Oyuncu stair floor snap uzunluğu 0.4 değil')
    if 'campaign_completion_stage = 3' not in scene:
        fail('VEX-03 campaign stage 3 değil')
    for path in ['assets/world/level03/korvath_rift.png']:
        exists(path)
    mission03=(ROOT/'resources/missions/vex03.tres').read_text(encoding='utf-8')
    if 'scene_path = "res://scenes/levels/level_03.tscn"' not in mission03 or 'ExtResource("15_mission03")' not in hub:
        fail('Bastion-7 VEX-03 görevini sunmuyor')
    if '## Bölüm 4 — VEX-03: Kül Madeni' not in story:
        fail('Kampanya hikâyesinde VEX-03 Kül Madeni bölümü eksik')
    finish_switch_scene=(ROOT/'scenes/props/finish_switch.tscn').read_text(encoding='utf-8')
    if 'required_keys = Array[StringName]([&"blue", &"red"])' not in finish_switch_scene:
        fail('VEX-03 finish switch prefab typed anahtar dizisi eksik')
    forbidden_runtime_builders=['_build_level_geometry', '_spawn_gameplay', '_spawn_enemy(', '_spawn_pickup(', 'WORLD_PIECE_SCENE']
    for contract in forbidden_runtime_builders:
        if contract in script:
            fail(f'VEX-03 editör görünürlüğünü bozan runtime üretim kaldı: {contract}')
    for node_group in ['Geometry/LowerLevel', 'Geometry/UpperLevel']:
        if f'parent="{node_group}"' not in scene and f'name="{node_group.split("/")[-1]}" type="Node3D" parent="{node_group.rsplit("/", 1)[0]}"' not in scene:
            fail(f'VEX-03 editör sahne grubu eksik: {node_group}')
    for root_group in ['Doors', 'Enemies', 'Pickups', 'Props', 'RoomLights', 'Lights']:
        if re.search(rf'^\[node name="{root_group}" type="Node3D" parent="\."', scene, re.M) is None:
            fail(f'VEX-03 Level 1/2 root sahne standardı eksik: {root_group}')
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
    status_lights=len(re.findall(r'parent="Lights"[^\n]*instance=ExtResource\("(?:16_red_lamp|35_green_lamp)"\)', scene))
    red_lights=len(re.findall(r'parent="Lights"[^\n]*instance=ExtResource\("16_red_lamp"\)', scene))
    green_lights=len(re.findall(r'parent="Lights"[^\n]*instance=ExtResource\("35_green_lamp"\)', scene))
    doors=len(re.findall(r'name="Door_[^"]+" parent="Doors"', scene))
    wall_pieces=len(re.findall(r'parent="Geometry/(?:LowerLevel|UpperLevel)/(?:LowerOuterWalls|LowerDoorFrames|UpperOuterWalls|UpperDoorFrames)', scene))
    if lower_rooms != 10: fail(f'VEX-03 alt kat modüler oda sayısı 10 değil: {lower_rooms}')
    if upper_rooms != 8: fail(f'VEX-03 üst kat modüler oda sayısı 8 değil: {upper_rooms}')
    if room_lights != 17: fail(f'VEX-03 bilinçli beyaz ışık sayısı 17 değil: {room_lights}')
    if status_lights != 28 or red_lights != 4 or green_lights != 24:
        fail(f'VEX-03 kapı durum ışıkları 4 kırmızı / 24 yeşil değil: {red_lights} / {green_lights}')
    if doors != 14: fail(f'VEX-03 kapı sayısı 14 değil: {doors}')
    if wall_pieces < 40: fail(f'VEX-03 kapalı oda/koridor duvar modülü yetersiz: {wall_pieces}')
    top_fills=len(re.findall(r'name="[A-Z0-9]+_TopFill"', scene))
    if top_fills < doors: fail(f'VEX-03 kapı üstü duvar dolgusu sayısı yetersiz: {top_fills} / {doors}')
    required_door_headers={
        'AB_TopFill': 'Vector3(-12, 5.86, 15)',
        'BC_TopFill': 'Vector3(0, 5.86, 15)',
        'AE_TopFill': 'Vector3(-18, 5.86, 10)',
        'CH_TopFill': 'Vector3(6, 5.86, 10)',
        'GJ_TopFill': 'Vector3(0, 5.86, -5)',
        'HI_TopFill': 'Vector3(12, 5.86, 5)',
        'EF_TopFill': 'Vector3(-18, 5.86, 0)',
        'FG_TopFill': 'Vector3(-12, 5.86, -5)',
        'HJ_TopFill': 'Vector3(6, 5.86, 0)',
        'U21_TopFill': 'Vector3(12, 13.66, 5)',
        'U32_TopFill': 'Vector3(0, 13.66, 5)',
        'U34_TopFill': 'Vector3(-6, 13.66, 0)',
        'U56_TopFill': 'Vector3(12, 13.66, -5)',
        'U68_TopFill': 'Vector3(18, 13.66, -10)',
    }
    for header_name, header_position in required_door_headers.items():
        coordinates=header_position.removeprefix('Vector3(').removesuffix(')')
        pattern=rf'\[node name="{re.escape(header_name)}"[^\n]*\]\ntransform = Transform3D\([^\n]*, {re.escape(coordinates)}\)'
        if re.search(pattern, scene) is None:
            fail(f'VEX-03 kapı üstü duvarı konum standardı bozuk: {header_name}')
    lamp_transforms=re.findall(r'\[node name="Door\d+_Lamp[AB]" parent="Lights"[^\n]*\]\ntransform = Transform3D\(([^\n]+)\)', scene)
    lamp_positions=[tuple(value.strip() for value in transform.split(',')[-3:]) for transform in lamp_transforms]
    lower_door_lamps=sum(1 for _x, y, _z in lamp_positions if y == '5.5')
    upper_door_lamps=sum(1 for _x, y, _z in lamp_positions if y == '13.3')
    if lower_door_lamps != 18 or upper_door_lamps != 10:
        fail(f'VEX-03 durum lambaları kapı üstünde değil: {lower_door_lamps} alt / {upper_door_lamps} üst')
    for standard_contract in ['piece_size = Vector3(12, 0.4, 10)', 'piece_size = Vector3(0.4, 7, 2.54)', 'piece_size = Vector3(0.4, 2.28, 4.92)', 'piece_size = Vector3(4.44, 2.28, 0.4)', 'piece_size = Vector3(9.425, 0.4, 10)', ', 5.0143)', '-18, 6.82, 15)']:
        if standard_contract not in scene:
            fail(f'VEX-03 Level 1/2 ölçü standardı eksik: {standard_contract}')
    if 'map_revision = "VEX03-R11-REUSABLE-U-STAIR"' not in scene:
        fail('VEX-03 tekrar kullanılabilir merdiven revizyonu güncel değil')
    if not approximately_equal_vector(node_origin(scene, 'Stairs'), (13.6, 0.0, 3.25)):
        fail('VEX-03 U-merdiven instance yerleşim ankrajı bozuk')
    expected_stair_origins={
        'StairTread_L01': (0.269231, 0.26, 0.0),
        'StairTread_L13': (6.730769, 3.86, 0.0),
        'StairTread_U01': (6.746153, 4.16, 3.5),
        'StairTread_U13': (0.653846, 7.76, 3.5),
        'LowerRamp': (3.508667, 1.849965, 0.0),
        'UpperRamp': (3.609728, 5.770875, 3.5),
        'RailLowerLeft': (3.5, 2.87, -1.02),
        'RailLowerRight': (3.5, 2.87, 1.02),
        'RailUpperLeft': (3.7, 6.77, 2.48),
        'RailUpperRight': (3.7, 6.77, 4.52),
    }
    for node_name, expected_origin in expected_stair_origins.items():
        if not approximately_equal_vector(node_origin(stair, node_name), expected_origin):
            fail(f'VEX-03 tekrar kullanılabilir merdiven hizası bozuk: {node_name}')
    for size_contract in ['piece_size = Vector3(0.07, 0.92, 0.07)', 'piece_size = Vector3(0.07, 0.07, 5.54)']:
        if size_contract not in stair:
            fail(f'VEX-03 U-merdiven korkuluk ölçüsü eksik: {size_contract}')
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


def check_localization_contract():
    project=(ROOT/'project.godot').read_text(encoding='utf-8')
    settings_scene=ROOT/'scenes/autoload/settings_manager.tscn'
    settings_script=(ROOT/'scripts/autoload/settings_manager.gd').read_text(encoding='utf-8')
    panel=(ROOT/'scripts/ui/settings_panel.gd').read_text(encoding='utf-8')
    csv_path=ROOT/'translations/vex.csv'
    for contract in [
        'SettingsManager="*res://scenes/autoload/settings_manager.tscn"',
        '[internationalization]',
        'locale/fallback="tr"',
        'res://translations/vex.en.translation',
        'res://translations/vex.tr.translation',
    ]:
        if contract not in project:
            fail(f'Yerelleştirme project.godot sözleşmesi eksik: {contract}')
    if not settings_scene.exists():
        fail('Sahne tabanlı SettingsManager eksik')
    for contract in [
        'signal language_changed', '@export var supported_locales', 'TranslationServer.set_locale',
        'difficulty_health_multipliers', 'var field_of_view := 78.0', 'var head_bob := true',
        'var controller_look_sensitivity := 2.6', 'controller_look_sensitivity_min', 'controller_look_sensitivity_max', 'func rebind_key(', 'func reset_keybindings()',
        'func _ensure_default_gamepad_bindings()', 'func _store_keybindings(', 'func _load_keybindings(',
    ]:
        if contract not in settings_script:
            fail(f'SettingsManager sahne/dil/input sözleşmesi eksik: {contract}')
    for contract in [
        '@export_enum("Performance", "Balanced", "High") var default_graphics_quality: int',
        '@export_enum("Easy", "Normal", "Hard", "Nightmare") var default_difficulty: int',
        'func _apply_language(notify_listeners: bool)',
    ]:
        if contract not in settings_script:
            fail(f'SettingsManager @export_enum int tür sözleşmesi eksik: {contract}')
    for contract in [
        '%LanguageOption', 'SettingsManager.set_language', 'SettingsManager.supported_resolutions',
        '%FovSlider', '%HeadBobCheck', '%ControllerSensitivitySlider', '%KeyBindingsButton', 'SettingsManager.set_field_of_view',
        'SettingsManager.set_head_bob', 'SettingsManager.set_controller_look_sensitivity',
    ]:
        if contract not in panel:
            fail(f'Ayar paneli dil/sahne/input sözleşmesi eksik: {contract}')
    for required_path in ['scripts/ui/keybind_panel.gd', 'scenes/ui/keybind_panel.tscn']:
        exists(required_path)
    panel_scene=(ROOT/'scenes/ui/settings_panel.tscn').read_text(encoding='utf-8')
    if 'custom_minimum_size = Vector2(820, 780)' not in panel_scene or '[node name="SettingsScroll" type="ScrollContainer"' not in panel_scene or panel_scene.count('custom_minimum_size = Vector2(250, 0)') < 15:
        fail('Ayar panelinin düşük çözünürlükte kaydırılabilir boyut/etiket sütunu sözleşmesi eksik')
    if 'tooltip_text =' in panel_scene:
        fail('Ayar panelinde gereksiz tooltip açıklaması kaldı')
    if panel_scene.count('scrollable = false') < 7:
        fail('Ayar sliderlarında mouse-wheel değer değiştirme kapatılmamış')
    if 'theme_override_constants/scrollbar_h_separation = 18' not in panel_scene:
        fail('Ayar paneli scrollbar içerik boşluğu standardı eksik')
    keybind_scene=(ROOT/'scenes/ui/keybind_panel.tscn').read_text(encoding='utf-8')
    keybind_script=(ROOT/'scripts/ui/keybind_panel.gd').read_text(encoding='utf-8')
    if 'custom_minimum_size = Vector2(0, 480)' not in keybind_scene:
        fail('Tuş atama paneli dikey boyut düzeltmesi eksik')
    for contract in ['func _input(event: InputEvent)', 'func is_waiting_for_key() -> bool', '_capture_key_event']:
        if contract not in keybind_script:
            fail(f'Tuş atama Tab yakalama sözleşmesi eksik: {contract}')
    automap_block=project.split('automap={', 1)[1].split('\n}', 1)[0] if 'automap={' in project else ''
    if 'keycode":4194306' not in automap_block or 'keycode":4194308' in automap_block:
        fail('Automap varsayılan klavye tuşu Tab değil')
    if 'SETTINGS_SCHEMA_VERSION := 2' not in settings_script or 'code == KEY_BACKSPACE' not in settings_script or 'code = KEY_TAB' not in settings_script:
        fail('Eski Backspace automap ayar migration sözleşmesi eksik')
    if not csv_path.exists():
        fail('Türkçe/İngilizce çeviri tablosu eksik')
        return
    with csv_path.open(encoding='utf-8', newline='') as handle:
        rows=list(csv.DictReader(handle))
    if not rows or set(rows[0].keys()) != {'keys', 'tr', 'en'}:
        fail('Çeviri CSV başlıkları keys,tr,en olmalı')
    semantic_keys={
        'LEVEL01_NAME','LEVEL01_OBJECTIVE_START','LEVEL01_BRIEFING_STORY','LEVEL01_BRIEFING_OBJECTIVE','LEVEL01_MAP_TITLE',
        'LEVEL02_NAME','LEVEL02_OBJECTIVE_START','LEVEL02_BRIEFING_STORY','LEVEL02_BRIEFING_OBJECTIVE','LEVEL02_MAP_TITLE',
        'LEVEL03_NAME','LEVEL03_OBJECTIVE_START','LEVEL03_BRIEFING_STORY','LEVEL03_BRIEFING_OBJECTIVE','LEVEL03_MAP_TITLE',
        'HUB_DISPLAY_NAME','HUB_ARRIVAL_SAFE_ZONE','HUB_MAP_TITLE','HUD_SLOT_05','SETTINGS_FOV','SETTINGS_HEAD_BOB','SETTINGS_CONTROLLER_SENSITIVITY',
        'WEAPON_P20_NAME','HUD_AMMO_MAGNUM','PICKUP_P20_ACTIVE','AMMO_MAGNUM',
        'UPGRADE_INERTIAL_PISTON','UPGRADE_OVERPRESSURE_CORE','UPGRADE_RUPTURE_ROUND'
    }
    csv_keys={row['keys'] for row in rows}
    for key in semantic_keys:
        if key not in csv_keys:
            fail(f'Semantic localization key eksik: {key}')
    keys=[row['keys'] for row in rows]
    if len(keys) != len(set(keys)):
        fail('Çeviri CSV içinde yinelenen anahtar var')
    for row in rows:
        if not row['keys'] or not row['tr'] or not row['en']:
            fail(f'Çeviri CSV boş alan içeriyor: {row}')
            break
        tr_formats=re.findall(r'%(?:\d+\$)?[sdf%]', row['tr'])
        en_formats=re.findall(r'%(?:\d+\$)?[sdf%]', row['en'])
        if tr_formats != en_formats:
            fail(f'Çeviri format parametreleri uyuşmuyor: {row["keys"]} -> {tr_formats} / {en_formats}')
    translated_sources=set(keys)
    player_text_fields='display_name|required_key_label|objective_on_unlock|log_title|log_body|info_message|locked_message|briefing|completion_message'
    for resource in list((ROOT/'scenes').rglob('*.tscn')) + list((ROOT/'resources').rglob('*.tres')):
        text=resource.read_text(encoding='utf-8')
        for match in re.finditer(rf'^(?:{player_text_fields}) = "([^"\n]*)"', text, re.M):
            source=match.group(1)
            if source and any(character.isalpha() for character in source) and source not in translated_sources:
                fail(f'Çeviri tablosunda Inspector oyuncu metni eksik: {resource.relative_to(ROOT)} -> {source}')



def check_brightness_scene_authority():
    settings_script=(ROOT/'scripts/autoload/settings_manager.gd').read_text(encoding='utf-8')
    settings_scene=(ROOT/'scenes/autoload/settings_manager.tscn').read_text(encoding='utf-8')
    standard=(ROOT/'STANDART.txt').read_text(encoding='utf-8')
    for contract in [
        'brightness_multiplier_min', 'brightness_multiplier_max',
        'func _get_brightness_multiplier()', 'func _capture_scene_brightness_baseline(environment: Environment)',
        'vex_scene_brightness_baseline', 'vex_scene_adjustment_enabled',
        'environment.adjustment_brightness = scene_brightness * multiplier',
    ]:
        if contract not in settings_script:
            fail(f'Brightness scene-authority sözleşmesi eksik: {contract}')
    for forbidden in [
        'environment.tonemap_exposure =',
        'environment.ambient_light_energy =',
        'environment.fog_light_energy =',
        'post_brightness_min', 'post_brightness_max',
        'exposure_min', 'exposure_max',
        'ambient_energy_min', 'ambient_energy_max',
        'fog_energy_min', 'fog_energy_max',
    ]:
        if forbidden in settings_script:
            fail(f'Brightness sistemi scene atmosferini ezmemeli / eski mapping kaldı: {forbidden}')
    for contract in ['brightness_multiplier_min = 0.42', 'brightness_multiplier_max = 2.15']:
        if contract not in settings_scene:
            fail(f'SettingsManager scene brightness multiplier ayarı eksik: {contract}')
    for forbidden in ['post_brightness_min =', 'exposure_min =', 'ambient_energy_min =', 'fog_energy_min =']:
        if forbidden in settings_scene:
            fail(f'SettingsManager scene içinde eski absolute brightness mapping kaldı: {forbidden}')
    for relative in [
        'scenes/levels/level_01.tscn', 'scenes/levels/level_02.tscn', 'scenes/levels/level_03.tscn', 'scenes/hub/bastion_7.tscn'
    ]:
        scene=(ROOT/relative).read_text(encoding='utf-8')
        if 'groups=["brightness_environment"]' not in scene:
            fail(f'{relative}: brightness_environment grubu eksik')
        for contract in ['ambient_light_energy =', 'fog_light_energy =', 'adjustment_brightness =']:
            if contract not in scene:
                fail(f'{relative}: scene brightness baseline değeri eksik: {contract}')
    for contract in [
        'ambient_light_energy, fog_light_energy ve tonemap_exposure',
        'adjustment_brightness sahnedeki değer baseline kabul edilir',
        'default_brightness değerinde kullanıcı çarpanı tam 1.0',
    ]:
        if contract not in standard:
            fail(f'STANDART brightness scene-authority kuralı eksik: {contract}')


def main():
    check_paths(); check_import_uids(); check_inputmap(); check_core_scenes(); check_keys_and_pickups(); check_enemies(); check_player_contract(); check_no_checkpoint_contract(); check_weapon_upgrades(); check_armory_loadout_contract(); check_p01_visual_contract(); check_p14_playable_contract(); check_p20_playable_contract(); check_bastion_door_wall_contract(); check_bastion_room_display_contract(); check_professional_terminal_contract(); check_world_visual_standard(); check_coplanar_world_piece_overlaps(); check_door_frame_wall_alignment(); check_runtime_signal_contracts(); check_level_briefings(); check_level_01_layout_contract(); check_level_02_progression(); check_level_03_contract(); check_unique_progression_ids(); check_localization_contract(); check_brightness_scene_authority(); check_stale_files()
    for w in WARNINGS: print('WARNING:',w)
    for f in FAILURES: print('ERROR:',f)
    print(f'VEX VALIDATOR: {len(FAILURES)} gerçek hata, {len(WARNINGS)} uyarı')
    return 1 if FAILURES else 0

if __name__=='__main__': sys.exit(main())
