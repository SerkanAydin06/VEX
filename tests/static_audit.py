#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import csv, re, sys

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
    required={'move_forward','move_backward','move_left','move_right','jump','sprint','crouch','aim','fire','interact','reload','pause','automap','night_vision','weapon_1','weapon_2','weapon_3','weapon_4','weapon_5'}
    for name in required:
        if re.search(r'^'+re.escape(name)+r'=\{',t,re.M) is None: fail(f"InputMap eksik: {name}")

def check_core_scenes():
    required=['scenes/player/player.tscn','scenes/ui/hud.tscn','scenes/ui/main_menu.tscn','scenes/ui/pause_menu.tscn','scenes/levels/level_01.tscn','scenes/levels/level_02.tscn','scenes/levels/level_03.tscn','scenes/hub/bastion_7.tscn','scenes/hub/armory_category_rack.tscn','scenes/hub/hub_weapon_rack.tscn','scripts/hub/armory_category_rack.gd','scenes/world/korvath_rift.tscn','scenes/world/lore_terminal.tscn','resources/missions/vex03.tres','scenes/actors/veilmaw.tscn','scenes/actors/veilmaw_projectile.tscn']
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
    if main_menu_scene.count('custom_minimum_size = Vector2(0, 60)') < 5:
        fail('Ana menü buton kompakt boyut standardı eksik')
    if 'anchors_preset = 8' not in main_menu_scene or 'offset_bottom = -104.0' not in main_menu_scene:
        fail('Ana menü aktif operasyon paneli bottom-right anchor standardı eksik')
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
        'p01_zoom.png', 'p01_lowered.png',
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
    for contract in ['"name": &"zoom"', '"name": &"aim_fire"', '"name": &"lowered"', 'position = Vector2(1060, 772)', 'scale = Vector2(0.6, 0.6)']:
        if contract not in p01_view:
            fail(f'P-01 weapon view poz/animasyon sözleşmesi eksik: {contract}')
    for contract in ['hud_view_scene: PackedScene', 'hud_auto_lower_enabled', 'hud_lower_after_seconds', 'hud_zoom_offset', 'hud_aim_fire_offset', 'hud_lowered_offset']:
        if contract not in definition:
            fail(f'WeaponDefinition sunum verisi eksik: {contract}')
    for contract in ['hud_view_scene = ExtResource("2_view")', 'supports_ads_pose = true', 'supports_lowered_pose = true', 'hud_zoom_offset = Vector2(-176, 0)', 'hud_lowered_offset = Vector2(160, 0)']:
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
        'size = Vector3(0.37, 0.03, 1.96)',
        'position = Vector3(0, -2.225, -3.44)',
        'position = Vector3(0, -2.225, 3.44)',
        'opening_offset_left = Vector3(0, 0, -2.1)',
        'opening_offset_right = Vector3(0, 0, 2.1)',
    ]:
        if contract not in door:
            fail(f'Bastion kapı kasa/cep ölçü sözleşmesi eksik: {contract}')
    for contract in [
        '@export var opening_offset_left := Vector3(0.0, 0.0, -2.1)',
        '@export var opening_offset_right := Vector3(0.0, 0.0, 2.1)',
    ]:
        if contract not in door_script:
            fail(f'Kapı açık konumunda 10 cm görünür kanat payı eksik: {contract}')
    for contract in [
        '[node name="PerceptionBlocker" type="StaticBody3D" parent="."]',
        'size = Vector3(0.24, 4.48, 4.48)',
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

def check_stale_files():
    tmp=list(ROOT.rglob('*.import*.tmp'))
    for p in tmp: warn(f'Temporary import dosyası: {p.relative_to(ROOT)}')
    todo=ROOT/'todo.md'
    if todo.exists() and 'TODO' in todo.read_text(encoding='utf-8').upper(): warn('todo.md hâlâ eski TODO maddeleri içeriyor; güncel yol haritası kullanın.')


def check_world_visual_standard():
    scanned=[ROOT/'scripts/world/world_piece.gd', ROOT/'scenes/world/world_piece.tscn']
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
    if 'shadow_enabled = true' not in red_scene or 'shadow_enabled = true' not in green_scene:
        fail('Kapı durum lambalarında gölge kapalı; ışık kapalı kapıdan sızabilir')
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
        for contract in ['ceiling_light_white_horror.tscn', 'light_energy = 3.8', 'light_range = 9.2', 'cone_angle = 42.0', 'cone_attenuation = 1.6', 'distance_attenuation = 0.3', 'shadow_enabled = true']:
            if contract not in fill_scene:
                fail(f'FULL/SPAWN beyaz ışık profili bozuk: {contract}')
        for contract in ['ceiling_light_white_horror.tscn', 'light_energy = 8.0', 'light_range = 20.0', 'cone_angle = 80.0', 'cone_attenuation = 4.0', 'distance_attenuation = 0.0', 'shadow_enabled = true']:
            if contract not in large_scene:
                fail(f'LARGE VOLUME beyaz ışık profili bozuk: {contract}')
    world_piece_scene=(ROOT/'scenes/world/world_piece.tscn').read_text(encoding='utf-8')
    world_piece_script=(ROOT/'scripts/world/world_piece.gd').read_text(encoding='utf-8')
    if 'cast_shadow = true' not in world_piece_scene or 'cast_shadow = 1' not in world_piece_scene or '@export var cast_shadow := true' not in world_piece_script:
        fail('Canonical world_piece gölge standardı açık değil')
    standard=(ROOT/'STANDART.txt').read_text(encoding='utf-8')
    for contract in [
        'Beyaz ışık gölge : AÇIK',
        'SHADOW CONTRACT:',
        'Kapı durum ışıkları (kırmızı/yeşil) de shadow AÇIK',
        'Canonical world_piece cast_shadow AÇIK',
        "Level 1/2/3 instance'ları shadow_enabled=false veya cast_shadow=false/0 ile bu standardı EZEMEZ",
    ]:
        if contract not in standard:
            fail(f'STANDART.txt shadow contract eksik: {contract}')

    light_profile_contracts={
        'level_01.tscn': ('26_room_light', 17, '36_room_fill', 3, None, 0),
        'level_02.tscn': ('26_room_light', 32, '36_room_fill', 3, None, 0),
        'level_03.tscn': ('15_room_light', 16, None, 0, '36_room_large', 1),
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
    png=green_texture_path.read_bytes()
    if len(png) < 26 or png[:8] != b'\x89PNG\r\n\x1a\n' or int.from_bytes(png[16:20], 'big') != 768 or int.from_bytes(png[20:24], 'big') != 320 or png[25] not in (4, 6):
        fail('Yeşil kapı lambası 768x320 gerçek alfa kanallı PNG değil')

    mappings=[
        ('level_01.tscn', '19_lamp_red', '30_lamp_green', 4, 34, {'Lamp_5_6_1','Lamp_5_6_2','Lamp_3_6_1','Lamp_3_6_2'}),
        ('level_02.tscn', '19_lamp_red', '30_lamp_green', 8, 2, {f'D0{i}_Lamp{j}' for i in range(1,5) for j in (1,2)}),
        ('level_03.tscn', '16_red_lamp', '35_green_lamp', 4, 24, {f'Door{i:02d}_Lamp{x}' for i in (6,10) for x in ('A','B')}),
    ]
    for filename, red_id, green_id, red_count, green_count, expected_red_names in mappings:
        scene=(ROOT/'scenes/levels'/filename).read_text(encoding='utf-8')
        actual_red=set(re.findall(rf'^\[node name="([^"]+)"[^\n]*instance=ExtResource\("{red_id}"\)', scene, re.M))
        actual_green=re.findall(rf'^\[node name="([^"]+)"[^\n]*instance=ExtResource\("{green_id}"\)', scene, re.M)
        if actual_red != expected_red_names or len(actual_red) != red_count or len(actual_green) != green_count:
            fail(f'{filename} kapı ışığı kuralı bozuk: kırmızı {len(actual_red)}/{red_count}, yeşil {len(actual_green)}/{green_count}')


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
    hub=(ROOT/'scenes/hub/bastion_7.tscn').read_text(encoding='utf-8')
    story_path=ROOT/'HIKAYE_VEX.md'
    if not story_path.exists():
        fail('Kampanya hikâye dosyası eksik: HIKAYE_VEX.md')
        story=''
    else:
        story=story_path.read_text(encoding='utf-8')
    required_scene=[
        'LEVEL03_NAME', 'Ceiling_L06_MaintenanceHall',
        'Stairs', 'StairLanding', 'UpperDeck',
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
        'material_override = ExtResource("34_stair_safety")',
    ]:
        if contract not in scene:
            fail(f'VEX-03 yeni U-merdiven fizik/görsel sözleşmesi eksik: {contract}')
    if scene.count('collision_layer = 1') < 1:
        fail('VEX-03 smooth merdiven collision gövdesi layer 1 üzerinde değil')
    if scene.count('parent="Geometry/Stairs/Collision/SmoothRampCollision"') != 3:
        fail('VEX-03 merdiven collision alt rampa + sahanlık + üst rampa olarak 3 yüzey kullanmıyor')
    if scene.count('name="StairTread_L') != 13 or scene.count('name="StairTread_U') != 13:
        fail('VEX-03 merdiven 13 + 13 temiz görsel basamak kullanmıyor')
    if scene.count('material_override = ExtResource("34_stair_safety")') < 26:
        fail('VEX-03 sarı/turuncu basamak güvenlik şeritleri eksik')
    for rail_name in ['RailLowerLeft', 'RailLowerRight', 'RailUpperLeft', 'RailUpperRight']:
        if scene.count(f'name="{rail_name}"') != 1:
            fail(f'VEX-03 {rail_name} tek parça sürekli korkuluk değil')
    if re.search(r'name="Rail(?:Lower|Upper)(?:Left|Right)_\d+', scene):
        fail('VEX-03 segment segment merdiven korkuluğu geri gelmiş')
    if 'level03_stair_module.tscn' in scene:
        fail('VEX-03 merdiven sahne üzerinden düzenlenebilir olmalı; ayrı scene instance kaldı')
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
    status_lights=len(re.findall(r'parent="Gameplay/Lighting/DoorStatusLights"[^\n]*instance=ExtResource\("(?:16_red_lamp|35_green_lamp)"\)', scene))
    red_lights=len(re.findall(r'parent="Gameplay/Lighting/DoorStatusLights"[^\n]*instance=ExtResource\("16_red_lamp"\)', scene))
    green_lights=len(re.findall(r'parent="Gameplay/Lighting/DoorStatusLights"[^\n]*instance=ExtResource\("35_green_lamp"\)', scene))
    doors=len(re.findall(r'name="Door_[^"]+" parent="Gameplay/Doors"', scene))
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
    lamp_transforms=re.findall(r'\[node name="Door\d+_Lamp[AB]" parent="Gameplay/Lighting/DoorStatusLights"[^\n]*\]\ntransform = Transform3D\(([^\n]+)\)', scene)
    lamp_positions=[tuple(value.strip() for value in transform.split(',')[-3:]) for transform in lamp_transforms]
    lower_door_lamps=sum(1 for _x, y, _z in lamp_positions if y == '5.5')
    upper_door_lamps=sum(1 for _x, y, _z in lamp_positions if y == '13.3')
    if lower_door_lamps != 18 or upper_door_lamps != 10:
        fail(f'VEX-03 durum lambaları kapı üstünde değil: {lower_door_lamps} alt / {upper_door_lamps} üst')
    for standard_contract in ['piece_size = Vector3(12, 0.4, 10)', 'piece_size = Vector3(0.4, 7, 2.54)', 'piece_size = Vector3(0.4, 2.28, 4.92)', 'piece_size = Vector3(4.92, 2.28, 0.4)', '-18, 6.82, 15)']:
        if standard_contract not in scene:
            fail(f'VEX-03 Level 1/2 ölçü standardı eksik: {standard_contract}')
    for revision_contract in [
        'map_revision = "VEX03-R10-LEFT-ENTRY-U-STAIR"',
        'position = Vector3(13.869231, 0.260000, 3.250)',
        'position = Vector3(20.330769, 3.860000, 3.250)',
        'position = Vector3(20.346154, 4.160000, 6.750)',
        'position = Vector3(14.253846, 7.760000, 6.750)',
        'position = Vector3(17.108667, 1.849965, 3.25)',
        'rotation = Vector3(0, 0, 0.504464)',
        'position = Vector3(17.209729, 5.770875, 6.75)',
        'rotation = Vector3(0, 0, -0.527514)',
        'position = Vector3(17.10, 2.87, 2.230)',
        'position = Vector3(17.10, 2.87, 4.270)',
        'position = Vector3(17.30, 6.77, 5.730)',
        'position = Vector3(17.30, 6.77, 7.770)',
        'piece_size = Vector3(0.07, 0.92, 0.07)',
        'piece_size = Vector3(0.07, 0.07, 5.54)',
    ]:
        if revision_contract not in scene:
            fail(f'VEX-03 yeni yön/flush/korkuluk sözleşmesi eksik: {revision_contract}')
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
        'HUB_DISPLAY_NAME','HUB_ARRIVAL_SAFE_ZONE','HUB_MAP_TITLE','HUD_SLOT_05','SETTINGS_FOV','SETTINGS_HEAD_BOB','SETTINGS_CONTROLLER_SENSITIVITY'
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
    check_paths(); check_import_uids(); check_inputmap(); check_core_scenes(); check_keys_and_pickups(); check_enemies(); check_player_contract(); check_no_checkpoint_contract(); check_weapon_upgrades(); check_armory_loadout_contract(); check_p01_visual_contract(); check_bastion_door_wall_contract(); check_world_visual_standard(); check_runtime_signal_contracts(); check_level_briefings(); check_level_02_progression(); check_level_03_contract(); check_unique_progression_ids(); check_localization_contract(); check_brightness_scene_authority(); check_stale_files()
    for w in WARNINGS: print('WARNING:',w)
    for f in FAILURES: print('ERROR:',f)
    print(f'VEX VALIDATOR: {len(FAILURES)} gerçek hata, {len(WARNINGS)} uyarı')
    return 1 if FAILURES else 0

if __name__=='__main__': sys.exit(main())
