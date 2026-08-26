#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []


def fail(message: str) -> None:
    ERRORS.append(message)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        fail(f"Eksik dosya: {relative}")
        return ""
    return path.read_text(encoding="utf-8")


def check_res_paths(relative: str, text: str) -> None:
    for resource in re.findall(r'res://[^"\'\s\)\]]+', text):
        resource = resource.rstrip(";,")
        if any(character in resource for character in "%{}"):
            continue
        if not (ROOT / resource.removeprefix("res://")).exists():
            fail(f"Kırık res:// referansı: {relative} -> {resource}")


def main() -> int:
    scene_path = "scenes/levels/level_test.tscn"
    support_paths = [
        "scenes/levels/test_support/test_room.tscn",
        "scenes/levels/test_support/test_open_wall_vertical.tscn",
        "scenes/levels/test_support/test_open_wall_horizontal.tscn",
        "scenes/levels/test_support/test_door_wall_vertical.tscn",
        "scenes/levels/test_support/test_solid_wall_horizontal.tscn",
        "scenes/levels/test_support/test_outer_wall_vertical.tscn",
        "scenes/levels/test_support/test_outer_wall_horizontal.tscn",
    ]
    scene = read(scene_path)
    support = {path: read(path) for path in support_paths}
    controller = read("scripts/levels/level_test.gd")

    for path, text in [(scene_path, scene), *support.items()]:
        check_res_paths(path, text)

    for contract in [
        'map_revision = "VEX-TEST-R02-5X5-25ROOM"',
        "automap_columns = 5",
        "automap_rows = 5",
        "automap_world_min = Vector2(-30, -25)",
        "automap_world_max = Vector2(30, 25)",
        "automap_start_cell = Vector2i(0, 4)",
        "automap_merge_adjacent_cells = false",
    ]:
        if contract not in scene:
            fail(f"Level Test harita sözleşmesi eksik: {contract}")

    room_names = re.findall(
        r'^\[node name="(Room_C[0-4]_R[0-4])" parent="Geometry" instance=ExtResource\("2_room"\)\]$',
        scene,
        re.M,
    )
    expected_rooms = {f"Room_C{x}_R{z}" for z in range(5) for x in range(5)}
    if len(room_names) != 25 or set(room_names) != expected_rooms:
        fail(f"Level Test oda grid'i 5x5 / 25 oda değil: {len(room_names)}")

    exterior_nodes = re.findall(
        r'^\[node name="(Outer_[^"]+)" parent="Geometry" instance=ExtResource\("(7_outer_v|8_outer_h)"\)\]$',
        scene,
        re.M,
    )
    expected_exterior = {
        ("Outer_West", "7_outer_v"),
        ("Outer_East", "7_outer_v"),
        ("Outer_North", "8_outer_h"),
        ("Outer_South", "8_outer_h"),
    }
    if set(exterior_nodes) != expected_exterior or len(exterior_nodes) != 4:
        fail(f"Level Test dış kabuğu dört tek-parça cephe değil: {exterior_nodes}")
    for obsolete in ["Outer_West_R", "Outer_East_R"]:
        if obsolete in scene:
            fail(f"Level Test eski segmentli dış cepheyi hâlâ içeriyor: {obsolete}")
    for contract in [
        '[node name="Outer_West" parent="Geometry" instance=ExtResource("7_outer_v")]',
        'position = Vector3(-30, 0, 0)',
        '[node name="Outer_East" parent="Geometry" instance=ExtResource("7_outer_v")]',
        'position = Vector3(30, 0, 0)',
        '[node name="Outer_North" parent="Geometry" instance=ExtResource("8_outer_h")]',
        'position = Vector3(0, 0, -25)',
        '[node name="Outer_South" parent="Geometry" instance=ExtResource("8_outer_h")]',
        'position = Vector3(0, 0, 25)',
    ]:
        if contract not in scene:
            fail(f"Level Test dış cephe konumu eksik: {contract}")

    door_nodes = re.findall(
        r'^\[node name="([^"]+)" parent="Doors" instance=ExtResource\("11_door"\)\]$',
        scene,
        re.M,
    )
    if door_nodes != ["StartRoomDoor"]:
        fail(f"Level Test tam olarak tek başlangıç kapısı taşımıyor: {door_nodes}")
    for contract in [
        '[node name="StartDoorWall" parent="Geometry" instance=ExtResource("5_door_wall")]',
        '[node name="StartRoom_NorthSolid" parent="Geometry" instance=ExtResource("6_solid_h")]',
        'position = Vector3(-18, 2.24, 20)',
        'automatic_open = false',
        'auto_close = false',
    ]:
        if contract not in scene:
            fail(f"Level Test başlangıç odası kapı sözleşmesi eksik: {contract}")

    open_vertical = re.findall(r'^\[node name="OpenV_[^"]+" parent="Geometry" instance=ExtResource\("3_open_v"\)\]$', scene, re.M)
    open_horizontal = re.findall(r'^\[node name="OpenH_[^"]+" parent="Geometry" instance=ExtResource\("4_open_h"\)\]$', scene, re.M)
    if len(open_vertical) != 19:
        fail(f"Level Test dikey kapısız geçit sayısı 19 değil: {len(open_vertical)}")
    if len(open_horizontal) != 19:
        fail(f"Level Test yatay kapısız geçit sayısı 19 değil: {len(open_horizontal)}")

    lights = re.findall(
        r'^\[node name="CeilingWhite_C[0-4]_R[0-4]" parent="RoomLights" instance=ExtResource\("(20_room_light|21_spawn_light)"\)\]$',
        scene,
        re.M,
    )
    if len(lights) != 25 or lights.count("21_spawn_light") != 1 or lights.count("20_room_light") != 24:
        fail(
            "Level Test ışık sözleşmesi bozuk: "
            f"toplam={len(lights)}, spawn={lights.count('21_spawn_light')}, normal={lights.count('20_room_light')}"
        )

    if '[node name="Player" parent="." instance=ExtResource("9_player")]' not in scene:
        fail("Level Test oyuncu instance'ı eksik")
    if '[node name="HUD" parent="." instance=ExtResource("10_hud")]' not in scene:
        fail("Level Test HUD instance'ı eksik")

    weapon_files = sorted(path.stem for path in (ROOT / "resources/weapons").glob("*.tres"))
    weapon_types = set(re.findall(r'^pickup_type = "([a-z0-9_]+)"$', scene, re.M)) & set(weapon_files)
    weapon_nodes = re.findall(r'^\[node name="Weapon_[^"]+" parent="Pickups" instance=ExtResource\("12_pickup"\)\]$', scene, re.M)
    if weapon_types != set(weapon_files):
        missing = sorted(set(weapon_files) - weapon_types)
        extra = sorted(weapon_types - set(weapon_files))
        fail(f"Level Test tüm güncel silahları içermiyor: eksik={missing}, fazla={extra}")
    if len(weapon_nodes) != len(weapon_files):
        fail(f"Level Test silah pickup sayısı yanlış: {len(weapon_nodes)}/{len(weapon_files)}")
    if scene.count("persist_collection = false") < len(weapon_files):
        fail("Level Test silah pickup'ları sahne yeniden yüklenince resetlenmiyor")

    actor_files = sorted(
        path.name
        for path in (ROOT / "scenes/actors").glob("*.tscn")
        if "_projectile" not in path.stem
    )
    for actor_file in actor_files:
        reference = f'path="res://scenes/actors/{actor_file}"'
        if reference not in scene:
            fail(f"Level Test güncel düşman sahnesini içermiyor: {actor_file}")
    enemy_nodes = re.findall(r'^\[node name="[^"]+" parent="Enemies" instance=ExtResource\("[^"]+"\)\]$', scene, re.M)
    enemy_ids = re.findall(r'^enemy_id = &"(level_test_[^"]+)"$', scene, re.M)
    if len(enemy_nodes) != len(actor_files):
        fail(f"Level Test düşman instance sayısı yanlış: {len(enemy_nodes)}/{len(actor_files)}")
    if len(enemy_ids) != len(actor_files) or len(set(enemy_ids)) != len(enemy_ids):
        fail("Level Test düşman ID'leri eksik veya benzersiz değil")
    if scene.count("spawn_min_difficulty = 0") != len(actor_files):
        fail("Level Test düşmanlarının tamamı Easy dahil tüm zorluklarda spawn olmuyor")

    room = support[support_paths[0]]
    for contract in [
        "piece_size = Vector3(12, 0.4, 10)",
        'surface_material = ExtResource("2_floor")',
        'surface_material = ExtResource("3_ceiling")',
    ]:
        if contract not in room:
            fail(f"Level Test oda modülü canonical değil: {contract}")

    open_v = support[support_paths[1]]
    for contract in ["piece_size = Vector3(0.4, 7, 2.78)", "piece_size = Vector3(0.4, 2.52, 4.44)"]:
        if contract not in open_v:
            fail(f"Level Test dikey açık geçit ölçüsü bozuk: {contract}")

    open_h = support[support_paths[2]]
    for contract in ["piece_size = Vector3(3.58, 7, 0.4)", "piece_size = Vector3(4.44, 2.52, 0.4)"]:
        if contract not in open_h:
            fail(f"Level Test yatay açık geçit ölçüsü bozuk: {contract}")

    door_wall = support[support_paths[3]]
    for contract in [
        "piece_size = Vector3(0.4, 7, 2.54)",
        "piece_size = Vector3(0.4, 2.28, 4.92)",
        "position = Vector3(0, 5.86, 0)",
    ]:
        if contract not in door_wall:
            fail(f"Level Test canonical kapı duvarı ölçüsü bozuk: {contract}")

    solid_h = support[support_paths[4]]
    for contract in [
        '[node name="TestSolidWallHorizontal" type="Node3D"]',
        '[node name="Wall" parent="." instance=ExtResource("1_piece")]',
        "position = Vector3(0, 3.5, 0)",
        "piece_size = Vector3(11.6, 7, 0.4)",
    ]:
        if contract not in solid_h:
            fail(f"Level Test solid duvar standardı bozuk: {contract}")

    outer_v = support[support_paths[5]]
    for contract in [
        '[node name="TestOuterWallVertical" type="Node3D"]',
        '[node name="Wall" parent="." instance=ExtResource("1_piece")]',
        "position = Vector3(0, 3.5, 0)",
        "piece_size = Vector3(0.4, 7, 50)",
    ]:
        if contract not in outer_v:
            fail(f"Level Test batı/doğu dış duvar standardı bozuk: {contract}")

    outer_h = support[support_paths[6]]
    for contract in [
        '[node name="TestOuterWallHorizontal" type="Node3D"]',
        '[node name="Wall" parent="." instance=ExtResource("1_piece")]',
        "position = Vector3(0, 3.5, 0)",
        "piece_size = Vector3(59.6, 7, 0.4)",
    ]:
        if contract not in outer_h:
            fail(f"Level Test kuzey/güney dış duvar standardı bozuk: {contract}")

    if "extends VexBaseLevel" not in controller:
        fail("Level Test VexBaseLevel standardını kullanmıyor")

    for message in ERRORS:
        print("ERROR:", message)
    print(f"LEVEL TEST VALIDATOR: {len(ERRORS)} hata")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
