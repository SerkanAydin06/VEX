from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, text: str) -> None:
    (ROOT / path).write_text(text, encoding="utf-8")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f"missing block: {label}")
    return text.replace(old, new, 1)


ravager_path = "scripts/actors/ravager.gd"
ravager = read(ravager_path)
ravager = replace_once(ravager, "var _patrol_forward := true\n", "", "ravager unused patrol flag")
ravager = replace_once(
    ravager,
    'var route: Variant = node.call("get_enemy_navigation_step", global_position, target_position)\n',
    'var route: Variant = node.call(\n\t\t\t"get_enemy_navigation_step",\n\t\t\tglobal_position,\n\t\t\ttarget_position,\n\t\t\tnavigation_clearance\n\t\t)\n',
    "ravager door clearance call",
)
write(ravager_path, ravager)

red_path = "scripts/actors/redviper.gd"
red = read(red_path)
red = replace_once(red, "var _patrol_forward := true\n", "", "redviper unused patrol flag")
red = replace_once(
    red,
    'var route: Variant = node.call("get_enemy_navigation_step", global_position, target_position)\n',
    'var route: Variant = node.call(\n\t\t\t"get_enemy_navigation_step",\n\t\t\tglobal_position,\n\t\t\ttarget_position,\n\t\t\tnavigation_clearance\n\t\t)\n',
    "redviper door clearance call",
)
write(red_path, red)

door_path = "scripts/props/door.gd"
door = read(door_path)
door = replace_once(
    door,
    '@export_range(0.5, 2.5, 0.05) var enemy_portal_offset := 1.15\n@export_range(2.0, 24.0, 0.5) var enemy_portal_consider_distance := 14.0\n',
    '@export_range(0.5, 2.5, 0.05) var enemy_portal_offset := 1.15\n@export_range(0.15, 1.0, 0.05) var enemy_portal_alignment_tolerance := 0.45\n@export_range(0.15, 1.0, 0.05) var enemy_portal_commit_depth := 0.45\n@export_range(2.0, 24.0, 0.5) var enemy_portal_consider_distance := 14.0\n',
    "door portal tuning exports",
)
old_func = '''func get_enemy_navigation_step(from_position: Vector3, target_position: Vector3) -> Dictionary:\n\tif not allow_enemy_open or is_access_locked():\n\t\treturn {}\n\n\tvar from_local := to_local(from_position)\n\tvar target_local := to_local(target_position)\n\tvar plane_epsilon := 0.30\n\t# Kapı yalnız hedef gerçekten öbür taraftaysa rota portalı olur. Aynı taraftaki\n\t# kapılara sırf yakın oldukları için sapmak istemiyoruz.\n\tif (\n\t\tabsf(from_local.x) > plane_epsilon\n\t\tand absf(target_local.x) > plane_epsilon\n\t\tand signf(from_local.x) == signf(target_local.x)\n\t):\n\t\treturn {}\n\n\tvar horizontal_to_door := Vector2(\n\t\tfrom_position.x - global_position.x,\n\t\tfrom_position.z - global_position.z\n\t).length()\n\tif horizontal_to_door > enemy_portal_consider_distance:\n\t\treturn {}\n\n\tvar from_side := 1.0 if from_local.x >= 0.0 else -1.0\n\tvar near_point := to_global(Vector3(from_side * enemy_portal_offset, 0.0, 0.0))\n\tvar far_point := to_global(Vector3(-from_side * enemy_portal_offset, 0.0, 0.0))\n\tnear_point.y = from_position.y\n\tfar_point.y = from_position.y\n\n\tvar approach_distance := Vector2(\n\t\tfrom_position.x - near_point.x,\n\t\tfrom_position.z - near_point.z\n\t).length()\n\tvar route_point := near_point\n\t# Panel tamamen açılmadan öbür tarafa hedef verme; aksi halde melee AI açılan\n\t# panelin gövdesine çarpıp tangent detour ile kapı ağzından kaçabiliyor.\n\tif _state == DoorState.OPEN and approach_distance <= enemy_portal_offset * 1.35:\n\t\troute_point = far_point\n\n\tvar score := from_position.distance_to(near_point) + far_point.distance_to(target_position)\n\treturn {"valid": true, "point": route_point, "score": score}\n'''
new_func = '''func get_enemy_navigation_step(\n\tfrom_position: Vector3,\n\ttarget_position: Vector3,\n\tagent_clearance: float = 0.6\n) -> Dictionary:\n\tif not allow_enemy_open or is_access_locked():\n\t\treturn {}\n\n\tvar from_local := to_local(from_position)\n\tvar target_local := to_local(target_position)\n\tvar plane_epsilon := 0.30\n\t# Kapı yalnız hedef gerçekten öbür taraftaysa rota portalı olur. Aynı taraftaki\n\t# kapılara sırf yakın oldukları için sapmak istemiyoruz.\n\tif (\n\t\tabsf(from_local.x) > plane_epsilon\n\t\tand absf(target_local.x) > plane_epsilon\n\t\tand signf(from_local.x) == signf(target_local.x)\n\t):\n\t\treturn {}\n\n\tvar horizontal_to_door := Vector2(\n\t\tfrom_position.x - global_position.x,\n\t\tfrom_position.z - global_position.z\n\t).length()\n\tif horizontal_to_door > enemy_portal_consider_distance:\n\t\treturn {}\n\n\tvar safe_clearance := maxf(agent_clearance, 0.1)\n\t# Büyük gövdeler kapı düzlemine gelmeden önce merkez hatta otursun. Warden gibi\n\t# geniş kapsüllerde eski sabit 1.15 m yaklaşma noktası çok erken çapraz geçişe\n\t# izin veriyor ve jamb kenarında tekrar tekrar rota yenilenmesine yol açıyordu.\n\tvar portal_offset := maxf(enemy_portal_offset, safe_clearance + 0.60)\n\tvar target_side := 1.0 if target_local.x >= 0.0 else -1.0\n\tvar from_side := 1.0 if from_local.x >= 0.0 else -1.0\n\t# Gövde kapı düzleminin tam merkezindeyken taraf işareti kareden kareye\n\t# değişmesin; hedefin ters tarafını giriş tarafı kabul ederek geçişi koru.\n\tif absf(from_local.x) <= plane_epsilon and absf(target_local.x) > plane_epsilon:\n\t\tfrom_side = -target_side\n\n\tvar near_point := to_global(Vector3(from_side * portal_offset, 0.0, 0.0))\n\tvar far_point := to_global(Vector3(-from_side * portal_offset, 0.0, 0.0))\n\tnear_point.y = from_position.y\n\tfar_point.y = from_position.y\n\n\tvar approach_distance := Vector2(\n\t\tfrom_position.x - near_point.x,\n\t\tfrom_position.z - near_point.z\n\t).length()\n\tvar alignment_tolerance := maxf(\n\t\tenemy_portal_alignment_tolerance,\n\t\tminf(safe_clearance * 0.55, 0.65)\n\t)\n\tvar center_band := maxf(0.55, safe_clearance * 0.85)\n\tvar centered_inside_portal := (\n\t\tabsf(from_local.x) <= enemy_portal_commit_depth\n\t\tand absf(from_local.z) <= center_band\n\t)\n\tvar route_point := near_point\n\t# Önce yakın taraftaki merkez noktasına kesin hizalan. Yalnız kapı tamamen açık\n\t# ve gövde merkeze yeterince oturmuşsa karşı tarafa commit et. Kapı düzlemine\n\t# zaten merkezden girmiş bir gövdeyi ise geriye çekme.\n\tif (\n\t\t_state == DoorState.OPEN\n\t\tand (approach_distance <= alignment_tolerance or centered_inside_portal)\n\t):\n\t\troute_point = far_point\n\n\tvar score := from_position.distance_to(near_point) + far_point.distance_to(target_position)\n\treturn {"valid": true, "point": route_point, "score": score}\n'''
door = replace_once(door, old_func, new_func, "door navigation portal function")
write(door_path, door)

# Permanent contract test: warnings stay clean and all enemy families pass their
# actual body clearance into the door portal alignment logic.
test = '''from pathlib import Path\n\nROOT = Path(__file__).resolve().parents[1]\nravager = (ROOT / "scripts/actors/ravager.gd").read_text(encoding="utf-8")\nred = (ROOT / "scripts/actors/redviper.gd").read_text(encoding="utf-8")\ndoor = (ROOT / "scripts/props/door.gd").read_text(encoding="utf-8")\nwarden = (ROOT / "scenes/actors/crucible_warden.tscn").read_text(encoding="utf-8")\n\nassert "var _patrol_forward" not in ravager\nassert "var _patrol_forward" not in red\nfor source in (ravager, red):\n    assert '"get_enemy_navigation_step",' in source\n    assert "navigation_clearance" in source\n\nfor token in [\n    "agent_clearance: float = 0.6",\n    "safe_clearance + 0.60",\n    "enemy_portal_alignment_tolerance",\n    "enemy_portal_commit_depth",\n    "centered_inside_portal",\n    "approach_distance <= alignment_tolerance",\n]:\n    assert token in door, token\n\nassert "radius = 0.72" in warden\nassert "navigation_clearance = 0.75" in warden\nprint("enemy door passage audit passed")\n'''
(ROOT / "tests/enemy_door_passage_audit.py").write_text(test, encoding="utf-8")

print("enemy door passage fix applied")
