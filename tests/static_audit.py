#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import csv
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
FAILURES: list[str] = []
WARNINGS: list[str] = []


def fail(message: str) -> None:
    FAILURES.append(message)


def warn(message: str) -> None:
    WARNINGS.append(message)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        fail(f"Eksik dosya: {relative}")
        return ""
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        fail(f"UTF-8 okunamıyor: {relative}")
        return ""


def exists(relative: str) -> bool:
    path = ROOT / relative
    if not path.exists():
        fail(f"Eksik dosya: {relative}")
        return False
    return True


def text_files():
    supported = {".tscn", ".tres", ".gd", ".godot", ".cfg", ".gdshader"}
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix not in supported:
            continue
        try:
            yield path, path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue


def node_count(text: str, parent: str, name_prefix: str | None = None) -> int:
    pattern = rf'^\[node name="([^"]+)"[^\n]*parent="{re.escape(parent)}"'
    names = re.findall(pattern, text, re.M)
    if name_prefix is None:
        return len(names)
    return sum(name.startswith(name_prefix) for name in names)


def top_level_named_count(text: str, prefix: str) -> int:
    return len(re.findall(rf'^\[node name="{re.escape(prefix)}[^\"]*"[^\n]*parent="Geometry"', text, re.M))


def check_res_paths() -> None:
    for path, text in text_files():
        for match in re.finditer(r'res://[^"\'\s\)\]]+', text):
            resource = match.group(0).rstrip(";,")
            if any(character in resource for character in "%{}"):
                continue
            relative = resource.removeprefix("res://")
            if relative.startswith("translations/vex.") and relative.endswith(".translation"):
                if (ROOT / "translations/vex.csv").exists():
                    continue
            if not (ROOT / relative).exists():
                fail(f"Kırık res:// referansı: {path.relative_to(ROOT)} -> {resource}")


def check_core_files() -> None:
    required = [
        "project.godot", "README.md", "STANDART.txt", "Story_VEX.md",
        "scenes/player/player.tscn", "scripts/player/player.gd",
        "scripts/player/weapon_controller.gd", "scripts/autoload/game_state.gd",
        "scripts/autoload/settings_manager.gd", "scripts/levels/base_level.gd",
        "scripts/levels/level_01.gd", "scenes/levels/level_01.tscn",
        "scenes/levels/level_02.tscn", "scenes/levels/level_03.tscn",
        "scenes/levels/tutorial_trigger.tscn", "scripts/levels/tutorial_trigger.gd",
        "scenes/levels/level_01_training_overlay.tscn",
        "scripts/levels/level_01_training_flow.gd",
        "scenes/props/door_side_slide.tscn", "scripts/props/door.gd",
        "scenes/world/door_status_light.tscn", "scripts/world/door_status_light.gd",
        "scenes/hub/bastion_7.tscn", "translations/vex.csv",
        "tests/integrity_test.gd", "tests/integrity_test.tscn",
        "tests/fixtures/save_invalid_version.cfg",
        "tests/fixtures/save_valid_backup.cfg",
        ".github/workflows/validate.yml",
    ]
    for relative in required:
        exists(relative)


def check_input_map() -> None:
    project = read("project.godot")
    required = {
        "move_forward", "move_backward", "move_left", "move_right", "jump",
        "sprint", "crouch", "aim", "fire", "interact", "reload", "pause",
        "automap", "night_vision", "weapon_flashlight", "weapon_1", "weapon_2",
        "weapon_3", "weapon_4", "weapon_5",
    }
    for action in required:
        if re.search(rf'^{re.escape(action)}=\{{', project, re.M) is None:
            fail(f"InputMap eksik: {action}")


def check_level_01() -> None:
    scene = read("scenes/levels/level_01.tscn")
    script = read("scripts/levels/level_01.gd")
    overlay = read("scenes/levels/level_01_training_overlay.tscn")
    flow = read("scripts/levels/level_01_training_flow.gd")
    for contract in [
        'map_revision = "VEX01-R28-37ROOM-13STEP"', "automap_columns = 5",
        "automap_rows = 13", "automap_start_cell = Vector2i(2, 12)",
        "automap_exit_cell = Vector2i(2, 0)",
    ]:
        if contract not in scene:
            fail(f"VEX-01 harita sözleşmesi eksik: {contract}")
    floors = top_level_named_count(scene, "Floor_R")
    ceilings = top_level_named_count(scene, "Ceiling_R")
    room_lights = node_count(scene, "RoomLights", "CeilingWhite_Room_")
    doors = node_count(scene, "Doors", "Door_")
    static_lights = node_count(scene, "Lights", "Lamp_")
    if floors != 37 or ceilings != 37:
        fail(f"VEX-01 oda modülü 37/37 değil: floor={floors}, ceiling={ceilings}")
    if room_lights != 37:
        fail(f"VEX-01 beyaz oda ışığı 37 değil: {room_lights}")
    if doors != 36:
        fail(f"VEX-01 seçici bağlantı kapısı 36 değil: {doors}")
    if static_lights != 24:
        fail(f"VEX-01 statik kapı ışığı sayısı 24 değil: {static_lights}")
    expected_edges = {
        (1, 3), (2, 3), (2, 6), (3, 4), (3, 7), (4, 8), (5, 6), (6, 10),
        (7, 11), (8, 9), (8, 12), (11, 13), (13, 15), (14, 15), (14, 18),
        (15, 16), (15, 19), (16, 20), (17, 18), (18, 22), (19, 23), (20, 21),
        (20, 24), (23, 25), (25, 27), (26, 27), (26, 30), (27, 28), (27, 31),
        (28, 32), (29, 30), (30, 34), (31, 35), (32, 33), (32, 36), (35, 37),
    }
    actual_names = set(re.findall(r'^\[node name="(Door_\d{2}_\d{2})"[^\n]*parent="Doors"', scene, re.M))
    expected_names = {f"Door_{left:02d}_{right:02d}" for left, right in expected_edges}
    if actual_names != expected_names:
        fail(f"VEX-01 bağlantı grafiği bozuk: {len(actual_names)}/{len(expected_names)} kapı")
    for contract in [
        'locked = true\nrequired_key = &"blue"',
        'required_keys = Array[StringName]([&"blue", &"red"])',
        'required_enemy_id = &"ravager_19"',
    ]:
        if contract not in scene:
            fail(f"VEX-01 progression sözleşmesi eksik: {contract}")
    if 'TRAINING_OVERLAY_SCENE := preload("res://scenes/levels/level_01_training_overlay.tscn")' not in script:
        fail("VEX-01 eğitim overlay sahnesini yüklemiyor")
    if "add_child(_training_overlay)" not in script:
        fail("VEX-01 eğitim overlay sahnesini oyun ağacına eklemiyor")
    tutorial_nodes = re.findall(r'^\[node name="Tutorial[^\"]*"[^\n]*instance=ExtResource\("2_tutorial"\)', overlay, re.M)
    if len(tutorial_nodes) != 9:
        fail(f"VEX-01 eğitim tetikleyici sayısı 9 değil: {len(tutorial_nodes)}")
    for key in [
        "LEVEL01_TUTORIAL_MOVE_HINT", "LEVEL01_TUTORIAL_INTERACT_HINT",
        "LEVEL01_TUTORIAL_FIRE_HINT", "LEVEL01_TUTORIAL_RELOAD_HINT",
        "LEVEL01_TUTORIAL_STRAFE_HINT", "LEVEL01_TUTORIAL_BARREL_HINT",
        "LEVEL01_TUTORIAL_RESOURCE_HINT", "LEVEL01_TUTORIAL_FINAL_HINT",
        "LEVEL01_TUTORIAL_COMPLETE_HINT",
    ]:
        if key not in overlay:
            fail(f"VEX-01 tutorial overlay eksik mesaj: {key}")
    if 'gate_enemy_ids = Array[StringName]([&"ravager_01", &"ravager_07"])' not in overlay:
        fail("VEX-01 Easy-safe combat gate düşmanları yanlış")
    for gate in ["Door_03_07", "Door_13_15"]:
        if gate not in overlay:
            fail(f"VEX-01 combat gate overlay bağlantısı eksik: {gate}")
    if overlay.count('instance=ExtResource("3_status")') != 4:
        fail("VEX-01 iki combat gate için dört dinamik durum ışığı kullanmıyor")
    if 'instance=ExtResource("4_barrel")' not in overlay:
        fail("VEX-01 çevresel eğitim için sahne-authored patlayıcı varil eksik")
    blocks = re.findall(
        r'^\[node name="[^\"]+"[^\n]*parent="Enemies"[^\n]*\]\n(.*?)(?=\n\[node |\Z)',
        scene, re.M | re.S,
    )
    for enemy_id in ["ravager_01", "ravager_07"]:
        target = next((block for block in blocks if f'enemy_id = &"{enemy_id}"' in block), None)
        if target is None:
            fail(f"VEX-01 combat gate düşmanı yok: {enemy_id}")
            continue
        spawn_match = re.search(r'^spawn_min_difficulty = (\d+)', target, re.M)
        spawn_min = int(spawn_match.group(1)) if spawn_match else 0
        if spawn_min != 0:
            fail(f"VEX-01 combat gate düşmanı Easy'de spawn olmuyor: {enemy_id} / min={spawn_min}")
    if "door._combat_lock_was_active = door._has_active_combat_lock()" not in flow:
        fail("VEX-01 training flow kapı combat cache'ini bağlandıktan sonra yenilemiyor")


def check_automap() -> None:
    automap = read("scripts/ui/automap_view.gd")
    base = read("scripts/levels/base_level.gd")
    for contract in [
        "var room_number := _walkable_order.find(cell) + 1",
        'door.has_method("is_access_locked")', 'door.call("is_access_locked")',
    ]:
        if contract not in automap:
            fail(f"Automap güncel runtime sözleşmesi eksik: {contract}")
    for contract in [
        "var ordered_cells: Array[Vector2i] = automap_walkable_cells.duplicate()",
        "if start_index >= 0 and exit_index >= 0 and start_index > exit_index:",
        "ordered_cells.reverse()", '"walkable_cells": ordered_cells',
    ]:
        if contract not in base:
            fail(f"BaseLevel automap sıralama sözleşmesi eksik: {contract}")


def check_level_02() -> None:
    scene = read("scenes/levels/level_02.tscn")
    if top_level_named_count(scene, "Floor_") != 33:
        fail("VEX-02 zemin modülü 33 değil")
    if top_level_named_count(scene, "Ceiling_") != 33:
        fail("VEX-02 tavan modülü 33 değil")
    if node_count(scene, "RoomLights") != 33:
        fail("VEX-02 beyaz ışık sayısı 33 değil")
    if node_count(scene, "Doors") != 5:
        fail("VEX-02 kapı sayısı 5 değil")
    for contract in ["key_blue", "key_red", "key_yellow", "BasaltJuggernaut_19", "Voidweaver_30"]:
        if contract not in scene:
            fail(f"VEX-02 progression/içerik sözleşmesi eksik: {contract}")


def check_level_03() -> None:
    scene = read("scenes/levels/level_03.tscn")
    script = read("scripts/levels/level_03.gd")
    for contract in [
        "Stairs", "UpperDeck", "KorvathWarden", "RiftIsolationSwitch",
        "BluePowerCard", "EceTanEmergencySignal", "vex03_secret_maintenance_cache",
        "vex03_secret_upper_archive", "vex03_korvath_warden",
    ]:
        if contract not in scene:
            fail(f"VEX-03 temel sözleşme eksik: {contract}")
    if node_count(scene, "Enemies") != 16:
        fail("VEX-03 düşman düğümü 16 değil")
    if node_count(scene, "Pickups") != 12:
        fail("VEX-03 pickup düğümü 12 değil")
    if node_count(scene, "Doors") != 14:
        fail("VEX-03 kapı düğümü 14 değil")
    if node_count(scene, "RoomLights") != 17:
        fail("VEX-03 beyaz ışık düğümü 17 değil")
    for forbidden in ["_build_level_geometry", "_spawn_gameplay", "_spawn_enemy(", "_spawn_pickup("]:
        if forbidden in script:
            fail(f"VEX-03 runtime gameplay üretimi geri gelmiş: {forbidden}")


def check_bastion() -> None:
    hub = read("scenes/hub/bastion_7.tscn")
    for contract in [
        "DeploymentTerminal", "CommandStatusTerminal", "ArmoryRacks",
        "PistolCategoryRack", "ShotgunCategoryRack", "RifleCategoryRack",
        "SmgCategoryRack", "LaserCategoryRack",
    ]:
        if contract not in hub:
            fail(f"Bastion-7 temel bileşeni eksik: {contract}")
    if node_count(hub, "Doors") != 6:
        fail("Bastion-7 kapı sayısı 6 değil")
    if node_count(hub, "RoomLights") != 9:
        fail("Bastion-7 beyaz ışık sayısı 9 değil")
    if node_count(hub, "DoorLights") != 12:
        fail("Bastion-7 kapı durum ışığı sayısı 12 değil")
    if node_count(hub, "RoomDisplays") != 6:
        fail("Bastion-7 oda ekranı sayısı 6 değil")
    if "MissionTerminal" in hub:
        fail("Bastion-7 kaldırılmış MissionTerminal içeriyor")


def check_door_contract() -> None:
    scene = read("scenes/props/door_side_slide.tscn")
    script = read("scripts/props/door.gd")
    for contract in [
        "size = Vector3(0.2, 4.48, 2.22)",
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -1.11)",
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1.11)",
        "size = Vector3(0.24, 4.48, 4.44)",
        '[node name="SafetySensor"', '[node name="PerceptionBlocker"',
        '[node name="DoorShadowBlocker"',
    ]:
        if contract not in scene:
            fail(f"Canonical kapı sahnesi sözleşmesi eksik: {contract}")
    for contract in [
        "required_enemy_ids", "objective_on_combat_clear", "_has_active_combat_lock",
        "lock_state_changed", "_is_doorway_blocked",
    ]:
        if contract not in script:
            fail(f"Canonical kapı davranışı eksik: {contract}")


def check_weapons() -> None:
    weapon_ids = ["p01", "p07", "p14", "p20", "sg04", "sg09", "sg15", "vx47", "mp90"]
    for weapon_id in weapon_ids:
        exists(f"resources/weapons/{weapon_id}.tres")
        exists(f"scenes/ui/weapons/{weapon_id}_view.tscn")
    p20 = read("resources/weapons/p20.tres")
    for contract in [
        'weapon_id = &"p20"', 'ammo_type = &"bullets"',
        'hud_ammo_label_key = "HUD_AMMO_PISTOL"', "penetration_power = 0.5",
        "magazine_size = 8", "damage_per_pellet = 42", "reserve_ammo_capacity = 180",
    ]:
        if contract not in p20:
            fail(f"P-20 güncel silah sözleşmesi eksik: {contract}")
    for obsolete in ['ammo_type = &"magnum_ammo"', "reserve_ammo_capacity = 40"]:
        if obsolete in p20:
            fail(f"P-20 eski Magnum mühimmat sözleşmesini kullanıyor: {obsolete}")
    controller = read("scripts/player/weapon_controller.gd")
    for contract in ["penetration_power", "target_limit", "_migrate_legacy_ammo_dictionary", "legacy_magnum_count"]:
        if contract not in controller:
            fail(f"WeaponController P-20/save migration sözleşmesi eksik: {contract}")

    sg09 = read("resources/weapons/sg09.tres")
    for contract in [
        'weapon_id = &"sg09"', 'ammo_type = &"shells"',
        'loadout_group = &"shotgun"', 'loadout_slot = 2',
        'supports_ads_pose = true', 'supports_flashlight = true',
        'magazine_size = 8', 'damage_per_pellet = 10', 'pellet_count = 8',
        'fire_interval = 0.38', 'reload_duration = 1.6',
        'spread_degrees = 4.8', 'maximum_range = 50.0',
        'automatic = false',
    ]:
        if contract not in sg09:
            fail(f"SG-09 silah sözleşmesi eksik: {contract}")
    if 'loadout_group = &"shotgun"' not in read("resources/weapons/sg04.tres"):
        fail("SG-04, SG-09 ve SG-15 aynı shotgun loadout grubunu paylaşmıyor")
    sg09_view = read("scenes/ui/weapons/sg09_view.tscn")
    for contract in [
        'name": &"idle"', 'name": &"fire"', 'name": &"aim_fire"',
        'name": &"reload"', 'name": &"zoom"',
        'sg09_zoom.png', 'sg09_reload_4.png', 'sg09_aim_fire_4.png',
    ]:
        if contract not in sg09_view:
            fail(f"SG-09 HUD animasyon sözleşmesi eksik: {contract}")
    player_scene = read("scenes/player/player.tscn")
    if 'res://resources/weapons/sg09.tres' not in player_scene:
        fail("Player WeaponController SG-09 tanımını kaydetmiyor")
    level_test = read("scenes/levels/level_test.tscn")
    if 'pickup_type = "sg09"' not in level_test:
        fail("Level Test SG-09 pickup içermiyor")
    bastion = read("scenes/hub/bastion_7.tscn")
    if 'weapon_texture = ExtResource("20_sg09_side")' not in bastion:
        fail("Bastion SG-09 rafı authored side görselini kullanmıyor")

    sg15 = read("resources/weapons/sg15.tres")
    for contract in [
        'weapon_id = &"sg15"', 'ammo_type = &"shells"',
        'loadout_group = &"shotgun"', 'loadout_slot = 2',
        'supports_ads_pose = true', 'uses_heat = true',
        'heat_per_shot = 14.0', 'heat_capacity = 100.0',
        'heat_cooling_per_second = 32.0',
        'magazine_size = 12', 'damage_per_pellet = 8', 'pellet_count = 7',
        'fire_interval = 0.18', 'reload_duration = 2.0',
        'spread_degrees = 6.2', 'maximum_range = 42.0',
        'automatic = true',
    ]:
        if contract not in sg15:
            fail(f"SG-15 silah sözleşmesi eksik: {contract}")
    sg15_view = read("scenes/ui/weapons/sg15_view.tscn")
    for contract in [
        'name": &"idle"', 'name": &"fire"', 'name": &"aim_fire"',
        'name": &"reload"', 'name": &"zoom"',
        'sg15_idle.png', 'sg15_fire_3.png', 'sg15_aim_fire_4.png',
        'sg15_reload_4.png', 'sg15_zoom_idle.png',
    ]:
        if contract not in sg15_view:
            fail(f"SG-15 HUD animasyon sözleşmesi eksik: {contract}")
    if 'sg15_3.png' in sg15_view:
        fail("SG-15 HUD sahnesi yanlış adlandırılmış sg15_3.png dosyasını kullanıyor")
    if 'res://resources/weapons/sg15.tres' not in player_scene:
        fail("Player WeaponController SG-15 tanımını kaydetmiyor")
    if 'pickup_type = "sg15"' not in level_test:
        fail("Level Test SG-15 pickup içermiyor")
    if 'weapon_texture = ExtResource("20_sg15_side")' not in bastion:
        fail("Bastion SG-15 rafı authored side görselini kullanmıyor")
    pickup_script = read("scripts/props/pickup.gd")
    player_script = read("scripts/player/player.gd")
    if '"sg04", "sg09", "sg15", "vx47"' not in pickup_script:
        fail("Pickup tipi SG-09/SG-15'i silah olarak tanımıyor")
    for contract in [
        '&"p01", &"p07", &"p14", &"p20", &"sg04", &"sg09", &"sg15":',
        "func _collect_loadout_weapon_pickup(",
        '"equip_world_weapon"',
        '"_spawn_dropped_weapon_pickup"',
        'displaced_weapon_id',
    ]:
        if contract not in player_script:
            fail(f"Player fiziksel loadout silah swap sözleşmesi eksik: {contract}")
    for obsolete in [
        'unlock_weapon", &"sg04"',
        'unlock_weapon", &"sg09"',
        'unlock_weapon", &"sg15"',
        "func _collect_sidearm_pickup(",
        '"_spawn_dropped_sidearm_pickup"',
    ]:
        if obsolete in player_script:
            fail(f"Shotgun pickup eski kaybolan-silah akışını kullanıyor: {obsolete}")


def check_unique_progression_ids() -> None:
    for scene_name in ["level_01.tscn", "level_02.tscn", "level_03.tscn"]:
        text = read(f"scenes/levels/{scene_name}")
        for key in ["enemy_id", "pickup_id", "secret_id"]:
            values = re.findall(rf'\b{key}\s*=\s*&"([^"]+)"', text)
            duplicates = sorted({value for value in values if values.count(value) > 1})
            if duplicates:
                fail(f"{scene_name}: duplicate {key}: {', '.join(duplicates)}")


def check_localization() -> None:
    csv_path = ROOT / "translations/vex.csv"
    if not csv_path.exists():
        fail("Çeviri CSV eksik")
        return
    with csv_path.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    if not rows or set(rows[0].keys()) != {"keys", "tr", "en"}:
        fail("Çeviri CSV başlıkları keys,tr,en olmalı")
        return
    keys = [row["keys"] for row in rows]
    if len(keys) != len(set(keys)):
        fail("Çeviri CSV yinelenen anahtar içeriyor")
    for row in rows:
        if not row["keys"] or not row["tr"] or not row["en"]:
            fail(f"Çeviri CSV boş alan içeriyor: {row.get('keys', '<boş>')}")
            break
    required = {
        "LEVEL01_NAME", "LEVEL01_OBJECTIVE_START", "LEVEL01_MAP_TITLE",
        "LEVEL01_TUTORIAL_MOVE_HINT", "LEVEL01_TUTORIAL_INTERACT_HINT",
        "LEVEL01_TUTORIAL_FIRE_HINT", "LEVEL01_TUTORIAL_RELOAD_HINT",
        "LEVEL01_TUTORIAL_STRAFE_HINT", "LEVEL01_TUTORIAL_BARREL_HINT",
        "LEVEL01_TUTORIAL_RESOURCE_HINT", "LEVEL01_TUTORIAL_FINAL_HINT",
        "LEVEL01_TUTORIAL_COMPLETE_HINT", "LEVEL01_DOOR_FIRE_TRAINING",
        "LEVEL01_DOOR_PROTOCOL_ENTRY", "WEAPON_P20_NAME", "WEAPON_SG09_NAME", "HUD_AMMO_PISTOL",
        "UPGRADE_AEGIS_GAS_DRIVE", "UPGRADE_SMART_CADDY", "UPGRADE_FLECHETTE_LOAD",
        "WEAPON_SG15_NAME", "WEAPON_OVERHEATED",
        "UPGRADE_TEMPEST_DRUM", "UPGRADE_THERMAL_JACKET", "UPGRADE_CYCLONE_BOLT",
        "DOOR_COMBAT_LOCKED", "DOOR_COMBAT_CLEARED",
    }
    missing = sorted(required - set(keys))
    if missing:
        fail(f"Çeviri anahtarları eksik: {', '.join(missing)}")


def check_scene_authority() -> None:
    for level_name in ["level_01.gd", "level_02.gd", "level_03.gd"]:
        script = read(f"scripts/levels/{level_name}")
        for forbidden in ["BoxMesh.new()", "CollisionShape3D.new()", "_build_level_geometry"]:
            if forbidden in script:
                fail(f"{level_name}: gameplay geometrisi runtime üretiliyor: {forbidden}")
    overlay = read("scenes/levels/level_01_training_overlay.tscn")
    if "trigger_size = Vector3" not in overlay:
        fail("VEX-01 tutorial trigger tuning değerleri sahnede tutulmuyor")
    if "TrainingBarrel" not in overlay:
        fail("VEX-01 tutorial oynanış prop'u sahnede tutulmuyor")


def check_save_recovery_and_runtime_ci() -> None:
    game_state = read("scripts/autoload/game_state.gd")
    for contract in [
        "_load_campaign_save_from_paths(SAVE_PATH, SAVE_BACKUP_PATH)",
        "func _read_valid_campaign_save(path: String) -> Dictionary:",
        "loaded_state = _read_valid_campaign_save(backup_path)",
        "if version < 3 or version > SAVE_VERSION:",
        "if _loaded_save_from_backup:",
    ]:
        if contract not in game_state:
            fail(f"Save recovery sözleşmesi eksik: {contract}")
    integrity = read("tests/integrity_test.gd")
    for contract in [
        "_check_save_recovery_contract()",
        "INVALID_SAVE_FIXTURE",
        "VALID_BACKUP_FIXTURE",
        "get_tree().quit(0)",
        "get_tree().quit(1)",
    ]:
        if contract not in integrity:
            fail(f"Godot integrity runner sözleşmesi eksik: {contract}")
    workflow = read(".github/workflows/validate.yml")
    for contract in [
        "Godot_v4.7-stable_linux.x86_64.zip",
        "godot --headless --editor --path . --quit",
        "godot --headless --path . tests/integrity_test.tscn",
        "godot --headless --path . tests/warden_door_runtime_test.tscn",
        '--export-release "Windows Desktop"',
        "actions/checkout@v7",
        "actions/setup-python@v7",
    ]:
        if contract not in workflow:
            fail(f"Headless Godot CI sözleşmesi eksik: {contract}")


def check_repository_hygiene() -> None:
    obsolete_paths = [
        "scenes/world/weapon_rack.tscn",
        "scripts/world/weapon_rack.gd",
        "assets/world/bastion7/bastion_terminal_front.png",
        "assets/world/metal_board.png",
        "assets/world/weapon_rack_panel.png",
        "assets/pickups/pistol.png",
        "assets/pickups/shotgun.png",
        "assets/weapons/shotgun_idle.png",
        "assets/weapons/shotgun_fire.png",
        "assets/weapons/shotgun_reload_1.png",
        "assets/weapons/shotgun_reload_2.png",
        ".github/emp01",
        ".github/enemy_detection.patch",
        ".github/enemy_detection_no_workflow.patch",
        ".github/enemy_movement.patch.gz.b64",
        ".github/enemy_movement.patch.part1",
        ".github/enemy_movement.patch.part2",
        ".github/workflows/export_enemy_detection_sources.yml",
        ".github/workflows/export_enemy_movement_sources.yml",
    ]
    for relative in obsolete_paths:
        if (ROOT / relative).exists():
            fail(f"Kaldırılmış eski içerik yeniden eklenmiş: {relative}")
    project_text = "\n".join(text for _path, text in text_files())
    for png_path in sorted((ROOT / "assets").rglob("*.png")):
        relative = png_path.relative_to(ROOT).as_posix()
        if f"res://{relative}" not in project_text:
            fail(f"Referanssız PNG asset: {relative}")
    for import_path in sorted((ROOT / "assets").rglob("*.png.import")):
        source_path = Path(str(import_path)[:-7])
        if not source_path.exists():
            fail(f"Kaynak PNG'si olmayan import metadata: {import_path.relative_to(ROOT)}")
    gitignore = read(".gitignore")
    if "build/" not in gitignore:
        fail("Export build klasörü .gitignore içinde değil")
    export = read("export_presets.cfg")
    if 'export_path="./build/windows/VEX.exe"' not in export:
        fail("Windows export çıktısı build/windows altında değil")
    for excluded in ["tests/*", "scenes/levels/level_test.tscn", "scenes/levels/test_support/*"]:
        if excluded not in export:
            fail(f"Geliştirme içeriği release export filtresinden çıkarılmıyor: {excluded}")


def check_stale_contracts() -> None:
    project_text = "\n".join(text for _path, text in text_files())
    for token in ["door_side_slide_bastion.tscn", "CargoElevator_Main"]:
        if token in project_text:
            fail(f"Kaldırılmış sözleşme/dosya referansı hâlâ mevcut: {token}")


def main() -> int:
    checks = [
        check_core_files, check_res_paths, check_input_map, check_level_01,
        check_automap, check_level_02, check_level_03, check_bastion,
        check_door_contract, check_weapons, check_unique_progression_ids,
        check_localization, check_scene_authority,
        check_save_recovery_and_runtime_ci, check_repository_hygiene,
        check_stale_contracts,
    ]
    for check in checks:
        check()
    for message in WARNINGS:
        print("WARNING:", message)
    for message in FAILURES:
        print("ERROR:", message)
    print(f"VEX VALIDATOR: {len(FAILURES)} gerçek hata, {len(WARNINGS)} uyarı")
    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
