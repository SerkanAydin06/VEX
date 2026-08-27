#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import math
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


def _quoted(header: str, key: str) -> str | None:
    match = re.search(rf'\b{re.escape(key)}="([^"]*)"', header)
    return match.group(1) if match else None


def _instance_id(header: str) -> str | None:
    match = re.search(r'\binstance=ExtResource\("([^"]+)"\)', header)
    return match.group(1) if match else None


def parse_nodes(text: str) -> list[dict[str, str | None]]:
    matches = list(re.finditer(r'^\[node (?P<header>[^\]]+)\]$', text, re.M))
    nodes: list[dict[str, str | None]] = []
    for index, match in enumerate(matches):
        body_start = match.end()
        body_end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        header = match.group("header")
        nodes.append(
            {
                "name": _quoted(header, "name"),
                "parent": _quoted(header, "parent"),
                "type": _quoted(header, "type"),
                "instance": _instance_id(header),
                "header": header,
                "body": text[body_start:body_end],
            }
        )
    return nodes


def parse_ext_resources(text: str) -> dict[str, str]:
    resources: dict[str, str] = {}
    for match in re.finditer(r'^\[ext_resource (?P<header>[^\]]+)\]$', text, re.M):
        header = match.group("header")
        resource_id = _quoted(header, "id")
        path = _quoted(header, "path")
        if resource_id and path:
            resources[resource_id] = path
    return resources


def find_node(
    nodes: list[dict[str, str | None]],
    name: str,
    *,
    parent: str | None = None,
    instance: str | None = None,
    node_type: str | None = None,
) -> dict[str, str | None] | None:
    for node in nodes:
        if node["name"] != name:
            continue
        if parent is not None and node["parent"] != parent:
            continue
        if instance is not None and node["instance"] != instance:
            continue
        if node_type is not None and node["type"] != node_type:
            continue
        return node
    return None


def node_property(node: dict[str, str | None], key: str) -> str | None:
    body = str(node.get("body") or "")
    match = re.search(rf'^{re.escape(key)}\s*=\s*(.+)$', body, re.M)
    return match.group(1).strip() if match else None


def bool_property(node: dict[str, str | None], key: str, default: bool) -> bool:
    raw = node_property(node, key)
    if raw is None:
        return default
    return raw == "true"


def int_property(node: dict[str, str | None], key: str, default: int) -> int:
    raw = node_property(node, key)
    if raw is None:
        return default
    try:
        return int(raw)
    except ValueError:
        return default


def node_translation(node: dict[str, str | None]) -> tuple[float, float, float] | None:
    body = str(node.get("body") or "")
    position = re.search(r'^position\s*=\s*Vector3\(([^)]*)\)$', body, re.M)
    if position:
        values = [float(value.strip()) for value in position.group(1).split(",")]
        if len(values) == 3:
            return values[0], values[1], values[2]
    transform = re.search(r'^transform\s*=\s*Transform3D\(([^)]*)\)$', body, re.M)
    if transform:
        values = [float(value.strip()) for value in transform.group(1).split(",")]
        if len(values) == 12:
            return values[9], values[10], values[11]
    return None


def close_vec3(
    actual: tuple[float, float, float] | None,
    expected: tuple[float, float, float],
    tolerance: float = 0.001,
) -> bool:
    return actual is not None and all(
        math.isclose(actual[index], expected[index], abs_tol=tolerance)
        for index in range(3)
    )


def require_node_translation(
    node: dict[str, str | None] | None,
    expected: tuple[float, float, float],
    message: str,
) -> None:
    if node is None or not close_vec3(node_translation(node), expected):
        fail(message)


def has_translation(nodes: list[dict[str, str | None]], expected: tuple[float, float, float]) -> bool:
    return any(close_vec3(node_translation(node), expected) for node in nodes)


def require_support_node(
    nodes: list[dict[str, str | None]],
    name: str,
    *,
    parent: str | None = None,
    instance: str | None = None,
    node_type: str | None = None,
    message: str,
) -> dict[str, str | None] | None:
    node = find_node(nodes, name, parent=parent, instance=instance, node_type=node_type)
    if node is None:
        fail(message)
    return node


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
    nodes = parse_nodes(scene)
    ext_resources = parse_ext_resources(scene)

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

    rooms = [
        node
        for node in nodes
        if node["parent"] == "Geometry"
        and node["instance"] == "2_room"
        and node["name"] is not None
        and re.fullmatch(r"Room_C[0-4]_R[0-4]", str(node["name"]))
    ]
    room_names = {str(node["name"]) for node in rooms}
    expected_rooms = {f"Room_C{x}_R{z}" for z in range(5) for x in range(5)}
    if len(rooms) != 25 or room_names != expected_rooms:
        fail(f"Level Test oda grid'i 5x5 / 25 oda değil: {len(rooms)}")

    expected_exterior = {
        "Outer_West": ("7_outer_v", (-30.0, 0.0, 0.0)),
        "Outer_East": ("7_outer_v", (30.0, 0.0, 0.0)),
        "Outer_North": ("8_outer_h", (0.0, 0.0, -25.0)),
        "Outer_South": ("8_outer_h", (0.0, 0.0, 25.0)),
    }
    exterior_nodes = [
        node
        for node in nodes
        if node["parent"] == "Geometry" and str(node["name"] or "").startswith("Outer_")
    ]
    observed_exterior = {(str(node["name"]), str(node["instance"])) for node in exterior_nodes}
    expected_exterior_pairs = {(name, data[0]) for name, data in expected_exterior.items()}
    if observed_exterior != expected_exterior_pairs or len(exterior_nodes) != 4:
        fail(f"Level Test dış kabuğu dört tek-parça cephe değil: {sorted(observed_exterior)}")
    for name, (instance, expected_position) in expected_exterior.items():
        node = find_node(nodes, name, parent="Geometry", instance=instance)
        require_node_translation(node, expected_position, f"Level Test dış cephe konumu bozuk: {name}")
    for obsolete in ["Outer_West_R", "Outer_East_R"]:
        if obsolete in scene:
            fail(f"Level Test eski segmentli dış cepheyi hâlâ içeriyor: {obsolete}")

    if find_node(nodes, "StartDoorWall", parent="Geometry", instance="5_door_wall") is None:
        fail("Level Test başlangıç odası kapı duvarı eksik")
    if find_node(nodes, "StartRoom_NorthSolid", parent="Geometry", instance="6_solid_h") is None:
        fail("Level Test başlangıç odası kuzey solid duvarı eksik")
    start_door = find_node(nodes, "StartRoomDoor", parent="Doors", instance="11_door")
    door_nodes = [node for node in nodes if node["parent"] == "Doors" and node["instance"] == "11_door"]
    if len(door_nodes) != 1 or start_door is None:
        fail(f"Level Test tam olarak tek başlangıç kapısı taşımıyor: {[node['name'] for node in door_nodes]}")
    require_node_translation(start_door, (-18.0, 2.24, 20.0), "Level Test başlangıç kapısı konumu bozuk")
    if start_door is not None:
        # Godot default değerleri .tscn'den silebilir. door.gd default automatic_open=false'tur.
        if bool_property(start_door, "automatic_open", False):
            fail("Level Test başlangıç kapısı otomatik açılmamalı")
        if bool_property(start_door, "auto_close", True):
            fail("Level Test başlangıç kapısı otomatik kapanmamalı")

    open_vertical = [
        node for node in nodes
        if node["parent"] == "Geometry"
        and node["instance"] == "3_open_v"
        and str(node["name"] or "").startswith("OpenV_")
    ]
    open_horizontal = [
        node for node in nodes
        if node["parent"] == "Geometry"
        and node["instance"] == "4_open_h"
        and str(node["name"] or "").startswith("OpenH_")
    ]
    if len(open_vertical) != 19:
        fail(f"Level Test dikey kapısız geçit sayısı 19 değil: {len(open_vertical)}")
    if len(open_horizontal) != 19:
        fail(f"Level Test yatay kapısız geçit sayısı 19 değil: {len(open_horizontal)}")

    lights = [
        node
        for node in nodes
        if node["parent"] == "RoomLights"
        and node["instance"] in {"20_room_light", "21_spawn_light"}
        and node["name"] is not None
        and re.fullmatch(r"CeilingWhite_C[0-4]_R[0-4]", str(node["name"]))
    ]
    light_instances = [str(node["instance"]) for node in lights]
    if len(lights) != 25 or light_instances.count("21_spawn_light") != 1 or light_instances.count("20_room_light") != 24:
        fail(
            "Level Test ışık sözleşmesi bozuk: "
            f"toplam={len(lights)}, spawn={light_instances.count('21_spawn_light')}, normal={light_instances.count('20_room_light')}"
        )

    if find_node(nodes, "Player", parent=".", instance="9_player") is None:
        fail("Level Test oyuncu instance'ı eksik")
    if find_node(nodes, "HUD", parent=".", instance="10_hud") is None:
        fail("Level Test HUD instance'ı eksik")

    weapon_files = sorted(path.stem for path in (ROOT / "resources/weapons").glob("*.tres"))
    weapon_nodes = [
        node for node in nodes
        if node["parent"] == "Pickups"
        and node["instance"] == "12_pickup"
        and str(node["name"] or "").startswith("Weapon_")
    ]
    weapon_types: set[str] = set()
    for node in weapon_nodes:
        raw_type = node_property(node, "pickup_type")
        if raw_type is not None:
            weapon_types.add(raw_type.strip('"'))
        if bool_property(node, "persist_collection", True):
            fail(f"Level Test silah pickup'ı sahne yeniden yüklenince resetlenmiyor: {node['name']}")
    if weapon_types != set(weapon_files):
        missing = sorted(set(weapon_files) - weapon_types)
        extra = sorted(weapon_types - set(weapon_files))
        fail(f"Level Test tüm güncel silahları içermiyor: eksik={missing}, fazla={extra}")
    if len(weapon_nodes) != len(weapon_files):
        fail(f"Level Test silah pickup sayısı yanlış: {len(weapon_nodes)}/{len(weapon_files)}")

    actor_files = sorted(
        path.name
        for path in (ROOT / "scenes/actors").glob("*.tscn")
        if "_projectile" not in path.stem
    )
    for actor_file in actor_files:
        reference = f'path="res://scenes/actors/{actor_file}"'
        if reference not in scene:
            fail(f"Level Test güncel düşman sahnesini içermiyor: {actor_file}")

    enemy_nodes = [node for node in nodes if node["parent"] == "Enemies" and node["instance"] is not None]
    enemy_ids: list[str] = []
    for node in enemy_nodes:
        raw_id = node_property(node, "enemy_id")
        if raw_id is not None:
            match = re.fullmatch(r'&"(level_test_[^"]+)"', raw_id)
            if match:
                enemy_ids.append(match.group(1))

        # Eksik değer, actor scriptlerinin canonical default'u olan Easy (0) demektir.
        # Instance açıkça farklı bir değer yazıyorsa onu esas al.
        spawn_min = int_property(node, "spawn_min_difficulty", 0)
        if spawn_min != 0:
            fail(f"Level Test düşmanı Easy'de spawn olmuyor: {node['name']} -> {spawn_min}")

        resource_path = ext_resources.get(str(node["instance"]))
        if resource_path and resource_path.startswith("res://scenes/actors/"):
            actor_text = read(resource_path.removeprefix("res://"))
            actor_spawn_match = re.search(r'^spawn_min_difficulty\s*=\s*(\d+)$', actor_text, re.M)
            if node_property(node, "spawn_min_difficulty") is None and actor_spawn_match and int(actor_spawn_match.group(1)) != 0:
                fail(f"Level Test düşman sahnesi Easy default taşımıyor: {node['name']}")

    if len(enemy_nodes) != len(actor_files):
        fail(f"Level Test düşman instance sayısı yanlış: {len(enemy_nodes)}/{len(actor_files)}")
    if len(enemy_ids) != len(actor_files) or len(set(enemy_ids)) != len(enemy_ids):
        fail("Level Test düşman ID'leri eksik veya benzersiz değil")

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
    ]:
        if contract not in door_wall:
            fail(f"Level Test canonical kapı duvarı ölçüsü bozuk: {contract}")
    if not has_translation(parse_nodes(door_wall), (0.0, 5.86, 0.0)):
        fail("Level Test canonical kapı duvarı üst parça konumu bozuk")

    solid_h = support[support_paths[4]]
    solid_nodes = parse_nodes(solid_h)
    require_support_node(
        solid_nodes,
        "TestSolidWallHorizontal",
        node_type="Node3D",
        message="Level Test solid duvar root standardı bozuk",
    )
    solid_wall = require_support_node(
        solid_nodes,
        "Wall",
        parent=".",
        instance="1_piece",
        message="Level Test solid duvar parçası eksik",
    )
    require_node_translation(solid_wall, (0.0, 3.5, 0.0), "Level Test solid duvar parça konumu bozuk")
    if "piece_size = Vector3(11.6, 7, 0.4)" not in solid_h:
        fail("Level Test solid duvar ölçüsü bozuk")

    outer_v = support[support_paths[5]]
    outer_v_nodes = parse_nodes(outer_v)
    require_support_node(
        outer_v_nodes,
        "TestOuterWallVertical",
        node_type="Node3D",
        message="Level Test batı/doğu dış duvar root standardı bozuk",
    )
    outer_v_wall = require_support_node(
        outer_v_nodes,
        "Wall",
        parent=".",
        instance="1_piece",
        message="Level Test batı/doğu dış duvar parçası eksik",
    )
    require_node_translation(outer_v_wall, (0.0, 3.5, 0.0), "Level Test batı/doğu dış duvar parça konumu bozuk")
    if "piece_size = Vector3(0.4, 7, 50)" not in outer_v:
        fail("Level Test batı/doğu dış duvar ölçüsü bozuk")

    outer_h = support[support_paths[6]]
    outer_h_nodes = parse_nodes(outer_h)
    require_support_node(
        outer_h_nodes,
        "TestOuterWallHorizontal",
        node_type="Node3D",
        message="Level Test kuzey/güney dış duvar root standardı bozuk",
    )
    outer_h_wall = require_support_node(
        outer_h_nodes,
        "Wall",
        parent=".",
        instance="1_piece",
        message="Level Test kuzey/güney dış duvar parçası eksik",
    )
    require_node_translation(outer_h_wall, (0.0, 3.5, 0.0), "Level Test kuzey/güney dış duvar parça konumu bozuk")
    if "piece_size = Vector3(59.6, 7, 0.4)" not in outer_h:
        fail("Level Test kuzey/güney dış duvar ölçüsü bozuk")

    if "extends VexBaseLevel" not in controller:
        fail("Level Test VexBaseLevel standardını kullanmıyor")

    for message in ERRORS:
        print("ERROR:", message)
    print(f"LEVEL TEST VALIDATOR: {len(ERRORS)} hata")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
