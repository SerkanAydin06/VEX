#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
FAILURES: list[str] = []


def fail(message: str) -> None:
    FAILURES.append(message)


def read(rel: str) -> str:
    path = ROOT / rel
    if not path.exists():
        fail(f"Eksik dosya: {rel}")
        return ""
    return path.read_text(encoding="utf-8")


def vec3(text: str) -> tuple[float, float, float]:
    vals = [float(v.strip()) for v in text.split(",")]
    return vals[0], vals[1], vals[2]


def transform_translation(text: str) -> tuple[float, float, float]:
    vals = [float(v.strip()) for v in text.split(",")]
    return vals[9], vals[10], vals[11]


def node_block(scene: str, name: str) -> str:
    match = re.search(
        rf'\[node name="{re.escape(name)}"[^\n]*\]\n(.*?)(?=\n\[node|\Z)',
        scene,
        re.S,
    )
    if not match:
        fail(f"Node bulunamadı: {name}")
        return ""
    return match.group(1)


def check_paths() -> None:
    text_extensions = {".tscn", ".tres", ".gd", ".godot", ".gdshader", ".cfg"}
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix not in text_extensions:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for match in re.finditer(r'res://[^"\'\s\)\]]+', text):
            resource = match.group(0).rstrip(";,")
            # Runtime formatlanan yollar statik dosya yolu değildir. Örn:
            # res://scenes/actors/%s.tscn % enemy_name
            if any(token in resource for token in ("%", "{", "}")):
                continue
            if not (ROOT / resource.removeprefix("res://")).exists():
                fail(f"Kırık res:// referansı: {path.relative_to(ROOT)} -> {resource}")


def check_canonical_names() -> None:
    scan_roots = [ROOT / "scenes", ROOT / "scripts", ROOT / "resources" ]
    legacy_ignore = {
        ROOT / "resources/materials/door_blue.tres",
        ROOT / "resources/materials/ceiling_panel.tres",
        ROOT / "resources/materials/floor_plate.tres",
        ROOT / "resources/materials/floor_plate_level01.tres",
        ROOT / "resources/materials/ceiling_panel_level01.tres",
    }
    versioned_path = re.compile(r'res://assets/[^"\n]*(?:_v\d+|/HellMagma/|/Ravager/|/BadRedViper/)')
    for scan_root in scan_roots:
        for path in scan_root.rglob("*"):
            if not path.is_file() or path.suffix not in {".tscn", ".tres", ".gd"}:
                continue
            if path in legacy_ignore:
                continue
            text = path.read_text(encoding="utf-8")
            hit = versioned_path.search(text)
            if hit:
                fail(f"Standart dışı aktif asset yolu: {path.relative_to(ROOT)} -> {hit.group(0)}")


def check_level(
    rel: str,
    floor_count: int,
    white_count: int,
    red_count: int,
    expected_floor_size: tuple[float, float, float],
) -> None:
    text = read(rel)
    if not text:
        return
    floor_matches = list(re.finditer(
        r'\[node name="Floor_[^"]+" parent="Geometry"[^\n]*\]\n(.*?)(?=\n\[node|\Z)',
        text,
        re.S,
    ))
    ceiling_matches = list(re.finditer(
        r'\[node name="Ceiling_[^"]+" parent="Geometry"[^\n]*\]\n(.*?)(?=\n\[node|\Z)',
        text,
        re.S,
    ))
    if len(floor_matches) != floor_count:
        fail(f"{rel}: zemin modülü sayısı {len(floor_matches)}, beklenen {floor_count}")
    if len(ceiling_matches) != floor_count:
        fail(f"{rel}: tavan modülü sayısı {len(ceiling_matches)}, beklenen {floor_count}")

    for label, matches, expected_y in (("zemin", floor_matches, -0.2), ("tavan", ceiling_matches, 7.2)):
        for match in matches:
            block = match.group(1)
            size_m = re.search(r'piece_size = Vector3\(([^)]*)\)', block)
            trans_m = re.search(r'transform = Transform3D\(([^\n]+)\)', block)
            if not size_m or not trans_m:
                fail(f"{rel}: {label} modülü eksik boyut/transform")
                continue
            size = vec3(size_m.group(1))
            position = transform_translation(trans_m.group(1))
            if any(abs(a - b) > 1e-4 for a, b in zip(size, expected_floor_size)):
                fail(f"{rel}: {label} boyutu standart dışı: {size}")
            if abs(position[1] - expected_y) > 1e-4:
                fail(f"{rel}: {label} Y standart dışı: {position[1]}")
            if "cast_shadow = false" not in block:
                fail(f"{rel}: {label} gereksiz gölge üretiyor")

    for match in re.finditer(
        r'\[node name="([^"]+)" parent="Geometry"[^\n]*\]\n(.*?)(?=\n\[node|\Z)',
        text,
        re.S,
    ):
        name, block = match.group(1), match.group(2)
        if name.startswith(("Floor_", "Ceiling_")):
            continue
        size_m = re.search(r'piece_size = Vector3\(([^)]*)\)', block)
        if not size_m:
            continue
        size = vec3(size_m.group(1))
        if abs(size[1] - 7.0) > 1e-4 and abs(size[1] - 2.52) > 1e-4:
            fail(f"{rel}: duvar yüksekliği standart dışı {name}: {size[1]}")

    if 'res://resources/materials/floor_standard.tres' not in text:
        fail(f"{rel}: ortak zemin materyali kullanılmıyor")
    if 'res://resources/materials/ceiling_standard.tres' not in text:
        fail(f"{rel}: ortak tavan materyali kullanılmıyor")
    if 'res://scenes/props/door_side_slide.tscn' not in text:
        fail(f"{rel}: standart yana açılan kapı kullanılmıyor")

    whites = len(re.findall(r'instance=ExtResource\("26_room_light"\)', text))
    reds = len(re.findall(r'instance=ExtResource\("19_lamp_red"\)', text))
    if whites != white_count:
        fail(f"{rel}: beyaz ışık sayısı {whites}, beklenen {white_count}")
    if reds != red_count:
        fail(f"{rel}: kırmızı ışık sayısı {reds}, beklenen {red_count}")

    for match in re.finditer(r'\[node name="CeilingWhite_[^\n]+\]\nposition = Vector3\(([^)]*)\)', text):
        if abs(vec3(match.group(1))[1] - 6.82) > 1e-4:
            fail(f"{rel}: beyaz ışık yüksekliği 6.82 değil")
    for match in re.finditer(r'instance=ExtResource\("19_lamp_red"\)\]\ntransform = Transform3D\(([^\n]+)\)', text):
        if abs(transform_translation(match.group(1))[1] - 5.5) > 1e-4:
            fail(f"{rel}: kırmızı ışık yüksekliği 5.5 değil")

    for name in re.findall(r'\[node name="([^"]*TopFill)" parent="Geometry"', text):
        block = node_block(text, name)
        size_m = re.search(r'piece_size = Vector3\(([^)]*)\)', block)
        if not size_m:
            continue
        sx, sy, sz = vec3(size_m.group(1))
        if abs(sy - 2.52) > 1e-4 or not (abs(sx - 4.6) < 1e-4 or abs(sz - 4.6) < 1e-4):
            fail(f"{rel}: kapı üst dolgusu 4.60×2.52 standardında değil: {name}")

    for match in re.finditer(r'\[node name="ExitSign[^"]*"[^\n]*\]\n(.*?)(?=\n\[node|\Z)', text, re.S):
        trans_m = re.search(r'transform = Transform3D\(([^\n]+)\)', match.group(1))
        if trans_m and abs(transform_translation(trans_m.group(1))[1] - 4.85) > 1e-4:
            fail(f"{rel}: EXIT tabelası 4.85m standardında değil")


def check_level_02_specific() -> None:
    text = read("scenes/levels/level_02.tscn")
    if 'instance=ExtResource("27_hellmagma")' not in text:
        fail("VEX-02 içinde HellMagma yok")
    if 'instance=ExtResource("28_voidweaver")' not in text:
        fail("VEX-02 içinde Voidweaver yok")
    for d, expected in {
        "D01": (-18.0, -20.0),
        "D02": (30.0, -20.0),
        "D03": (6.0, 0.0),
        "D04": (24.0, 25.0),
        "D05": (42.0, 30.0),
    }.items():
        block = node_block(text, f"{d}_Door")
        trans_m = re.search(r'transform = Transform3D\(([^\n]+)\)', block)
        if not trans_m:
            continue
        x, y, z = transform_translation(trans_m.group(1))
        if abs(x - expected[0]) > 1e-4 or abs(z - expected[1]) > 1e-4 or abs(y - 2.24) > 1e-4:
            fail(f"VEX-02 {d} kapı merkezi standart dışı: {(x, y, z)}")

    root_props = scene_root_property_names(text, "Node3D")
    if "automap_world_min" not in root_props or "automap_world_max" not in root_props:
        fail("VEX-02 automap sınırları level sahnesinde Inspector ayarı olarak saklanmıyor")
    if "automap_world_min = Vector2(-54, -35)" not in text or "automap_world_max = Vector2(54, 35)" not in text:
        fail("VEX-02 automap sınırları 12×10m modüler haritaya göre güncel değil")



def check_bastion_7() -> None:
    rel = "scenes/hub/bastion_7.tscn"
    text = read(rel)
    if not text:
        return

    floors = re.findall(r'\[node name="Floor_[^"]+" parent="Geometry"[^\n]*\]', text)
    ceilings = re.findall(r'\[node name="Ceiling_[^"]+" parent="Geometry"[^\n]*\]', text)
    if len(floors) != 14 or len(ceilings) != 14:
        fail(f"{rel}: hub modül sayısı yanlış: floor={len(floors)} ceiling={len(ceilings)}")

    for prefix, expected_y in (("Floor_", -0.2), ("Ceiling_", 7.2)):
        for match in re.finditer(
            rf'\[node name="{prefix}[^"]+" parent="Geometry"[^\n]*\]\n(.*?)(?=\n\[node|\Z)',
            text,
            re.S,
        ):
            block = match.group(1)
            size_m = re.search(r'piece_size = Vector3\(([^)]*)\)', block)
            pos_m = re.search(r'position = Vector3\(([^)]*)\)', block)
            if not size_m or not pos_m:
                fail(f"{rel}: hub zemin/tavan boyut veya pozisyon eksik")
                continue
            if vec3(size_m.group(1)) != (12.0, 0.4, 10.0):
                fail(f"{rel}: hub modül boyutu 12x0.4x10 değil")
            if abs(vec3(pos_m.group(1))[1] - expected_y) > 1e-4:
                fail(f"{rel}: hub {prefix} Y standardı yanlış")
            if "cast_shadow = false" not in block:
                fail(f"{rel}: hub zemin/tavan gölgesi kapalı değil")

    if len(re.findall(r'instance=ExtResource\("8_door"\)', text)) != 7:
        fail("Bastion-7 kapı sayısı 7 değil")
    if len(re.findall(r'instance=ExtResource\("9_white"\)', text)) != 12:
        fail("Bastion-7 aktif beyaz ışık sayısı 12 değil")
    if len(re.findall(r'instance=ExtResource\("10_red"\)', text)) != 14:
        fail("Bastion-7 kapı kırmızı ışık sayısı 14 değil")

    for locked_door in ["FiringRangeDoor", "ResearchDoor", "WorkshopDoor", "EngineeringDoor"]:
        block = node_block(text, locked_door)
        if "permanently_locked = true" not in block:
            fail(f"Bastion-7 {locked_door} kalıcı kilitli değil")

    if 'next_level_path = "res://scenes/hub/bastion_7.tscn"' not in read("scenes/levels/level_01.tscn"):
        fail("VEX-01 tamamlanınca Bastion-7'ye dönmüyor")
    if 'next_level_path = "res://scenes/hub/bastion_7.tscn"' not in read("scenes/levels/level_02.tscn"):
        fail("VEX-02 tamamlanınca Bastion-7'ye dönmüyor")

    game_state = read("scripts/autoload/game_state.gd")
    for required in [
        'const BASTION_7_PATH := "res://scenes/hub/bastion_7.tscn"',
        "func select_hub_mission(mission_path: String, mission_label: String)",
        "func deploy_selected_hub_mission()",
        "func _register_campaign_completion(current_scene: Node)",
    ]:
        if required not in game_state:
            fail(f"Bastion-7 campaign akışı eksik: {required}")


def check_lighting() -> None:
    scene = read("scenes/world/ceiling_light_white_horror.tscn")
    if "LightBeam" in scene:
        fail("Beyaz ışık sahnesinde görünür ışık hüzmesi geri gelmiş")
    required = [
        "light_energy = 2.6",
        "spot_range = 7.4",
        "spot_angle = 18.0",
        "light_specular = 0.0",
        "shadow_enabled = false",
    ]
    for item in required:
        if item not in scene:
            fail(f"Beyaz ışık profili eksik: {item}")

    light_script = read("scripts/world/room_ceiling_light.gd")
    if "@export var shadow_enabled := false:" not in light_script:
        fail("Beyaz oda ışığı script varsayılanında gölge kapalı değil")

    spawn_profiles = {
        "scenes/levels/level_01.tscn": [
            "CeilingWhite_Room_16",
            "CeilingWhite_SpawnFill_A",
            "CeilingWhite_SpawnFill_B",
        ],
        "scenes/levels/level_02.tscn": [
            "CeilingWhite_C4_R3",
            "CeilingWhite_SpawnFill_A",
            "CeilingWhite_SpawnFill_B",
        ],
        "scenes/hub/bastion_7.tscn": [
            "CeilingWhite_OperatorPlatform",
            "CeilingWhite_SpawnFill_A",
            "CeilingWhite_SpawnFill_B",
        ],
    }
    for scene_path, light_names in spawn_profiles.items():
        spawn_scene = read(scene_path)
        for light_name in light_names:
            block = node_block(spawn_scene, light_name)
            for setting in [
                "light_energy = 3.8",
                "light_range = 9.2",
                "cone_angle = 42.0",
                "shadow_enabled = false",
            ]:
                if setting not in block:
                    fail(f"{scene_path}: {light_name} başlangıç tam ışık standardı eksik: {setting}")


def check_enemies() -> None:
    for name in ["redviper", "badredviper", "ravager", "hellmagma", "voidweaver"]:
        text = read(f"scenes/actors/{name}.tscn")
        if "billboard = 2" not in text:
            fail(f"{name}: Fixed-Y billboard standardı eksik")
        if "texture_filter = 3" not in text:
            fail(f"{name}: Linear Mipmap standardı eksik")
    sheet_paths = {
        "redviper": "res://assets/enemies/redviper/redviper_spritesheet.png",
        "badredviper": "res://assets/enemies/badredviper/badredviper_spritesheet.png",
        "ravager": "res://assets/enemies/ravager/ravager_spritesheet.png",
        "hellmagma": "res://assets/enemies/hellmagma/hellmagma_spritesheet.png",
        "voidweaver": "res://assets/enemies/voidweaver/voidweaver_spritesheet.png",
    }
    for enemy_name, sheet_path in sheet_paths.items():
        if sheet_path not in read(f"scenes/actors/{enemy_name}.tscn"):
            fail(f"{enemy_name}: spritesheet yolu standart değil")


def import_param(rel: str, key: str) -> str | None:
    text = read(rel)
    if not text:
        return None
    match = re.search(rf"^{re.escape(key)}=(.+)$", text, re.M)
    return match.group(1).strip() if match else None


def check_enemy_texture_imports() -> None:
    main_sheets = [
        "assets/enemies/redviper/redviper_spritesheet.png.import",
        "assets/enemies/badredviper/badredviper_spritesheet.png.import",
        "assets/enemies/ravager/ravager_spritesheet.png.import",
        "assets/enemies/hellmagma/hellmagma_spritesheet.png.import",
        "assets/enemies/voidweaver/voidweaver_spritesheet.png.import",
    ]
    for rel in main_sheets:
        if import_param(rel, "compress/mode") != "2":
            fail(f"{rel}: ana enemy spritesheet VRAM compression standardında değil")
        if import_param(rel, "mipmaps/generate") != "true":
            fail(f"{rel}: mipmap kapalı")
        if import_param(rel, "detect_3d/compress_to") != "0":
            fail(f"{rel}: 3D texture import standardı yanlış")

    effect_sheets = [
        "assets/enemies/ravager/ravager_projectile_sheet.png.import",
        "assets/enemies/ravager/ravager_impact_sheet.png.import",
        "assets/enemies/hellmagma/hellmagma_projectile_sheet.png.import",
        "assets/enemies/hellmagma/hellmagma_impact_sheet.png.import",
        "assets/enemies/voidweaver/voidweaver_projectile_sheet.png.import",
        "assets/enemies/voidweaver/voidweaver_impact_sheet.png.import",
    ]
    for rel in effect_sheets:
        if (ROOT / rel).exists() and import_param(rel, "mipmaps/generate") != "true":
            fail(f"{rel}: projectile/impact mipmap kapalı")


def check_documented_standards() -> None:
    text = read("STANDART.txt")
    required = [
        "Hellmagma\t : Position Y = -0.1",
        "Ravager\t\t : Position Y = -0.25",
        "Voidweaver       : Position Y = -0.02",
        "SAHNE OTORİTESİ",
        "Scriptler @export konfigürasyon değişkenlerini runtime sırasında değiştirmez.",
    ]
    for item in required:
        if item not in text:
            fail(f"STANDART.txt güncel değil: {item}")


def check_project_settings() -> None:
    text = read("project.godot")
    if 'limits/opengl/max_lights_per_object=16' not in text:
        fail("Compatibility renderer için max_lights_per_object=16 eksik")



def exported_variables(script_text: str) -> list[str]:
    return re.findall(r'@export[^\n]*\bvar\s+(\w+)', script_text)


def scene_root_property_names(scene_text: str, root_type: str) -> set[str]:
    match = re.search(
        rf'\[node name="[^"]+" type="{re.escape(root_type)}"[^\n]*\]\n(.*?)(?=\n\[node|\Z)',
        scene_text,
        re.S,
    )
    if not match:
        return set()
    return set(re.findall(r'^([A-Za-z_]\w*)\s*=', match.group(1), re.M))



def scene_named_node_property_names(scene_text: str, node_name: str) -> set[str]:
    match = re.search(
        rf'\[node name="{re.escape(node_name)}"[^\n]*\]\n(.*?)(?=\n\[node|\Z)',
        scene_text,
        re.S,
    )
    if not match:
        return set()
    return set(re.findall(r'^([A-Za-z_]\w*)\s*=', match.group(1), re.M))


def resource_property_names(resource_text: str) -> set[str]:
    match = re.search(r'\[resource\]\n(.*)\Z', resource_text, re.S)
    if not match:
        return set()
    return set(re.findall(r'^([A-Za-z_]\w*)\s*=', match.group(1), re.M))

def _setter_ranges(lines: list[str], export_lines: dict[str, int]) -> dict[str, tuple[int, int]]:
    ranges: dict[str, tuple[int, int]] = {}
    for name, index in export_lines.items():
        if not lines[index].rstrip().endswith(":"):
            continue
        end = index + 1
        while end < len(lines):
            stripped = lines[end].strip()
            if stripped and not lines[end].startswith(("\t", " ")):
                break
            end += 1
        ranges[name] = (index + 1, end)
    return ranges


def check_exported_configuration_is_not_mutated() -> None:
    assignment_template = r'(?<![\w.])(?:self\.)?{name}\s*(?:\+=|-=|\*=|/=|=(?!=))'
    for path in (ROOT / "scripts").rglob("*.gd"):
        text = path.read_text(encoding="utf-8")
        lines = text.splitlines()
        export_lines: dict[str, int] = {}
        for index, line in enumerate(lines):
            match = re.search(r'@export[^\n]*\bvar\s+(\w+)', line)
            if match:
                export_lines[match.group(1)] = index
        setter_ranges = _setter_ranges(lines, export_lines)
        for name, declaration_index in export_lines.items():
            pattern = re.compile(assignment_template.format(name=re.escape(name)))
            for index, line in enumerate(lines):
                if index == declaration_index:
                    continue
                code = line.split("#", 1)[0]
                if not pattern.search(code):
                    continue
                allowed = setter_ranges.get(name)
                if allowed is not None and allowed[0] <= index < allowed[1]:
                    continue
                fail(
                    f"Sahne otoritesi ihlali: {path.relative_to(ROOT)}:{index + 1} "
                    f"export '{name}' runtime'da değiştiriliyor"
                )


def check_scene_authority() -> None:
    check_exported_configuration_is_not_mutated()

    for rel in [
        "scripts/actors/redviper.gd",
        "scripts/actors/ravager.gd",
        "scripts/props/pickup.gd",
    ]:
        text = read(rel)
        if "get_active_difficulty_profile" in text:
            fail(f"{rel}: zorluk tuning'i GameState profilinden kodla eziliyor")

    for rel in ["scripts/actors/redviper.gd", "scripts/actors/ravager.gd"]:
        text = read(rel)
        if "BURN_REMAINS_SCENE" in text:
            fail(f"{rel}: ölüm izi sahnesi hardcoded")
        if re.search(r'enemy_id\s*==', text):
            fail(f"{rel}: enemy_id üzerinden hardcoded görsel/tuning dalı var")

    enemy_scene_scripts = {
        "redviper": "scripts/actors/redviper.gd",
        "badredviper": "scripts/actors/redviper.gd",
        "ravager": "scripts/actors/ravager.gd",
        "hellmagma": "scripts/actors/ravager.gd",
        "voidweaver": "scripts/actors/ravager.gd",
    }
    for enemy_name, script_rel in enemy_scene_scripts.items():
        scene_rel = f"scenes/actors/{enemy_name}.tscn"
        scene_text = read(scene_rel)
        script_text = read(script_rel)
        root_props = scene_root_property_names(scene_text, "CharacterBody3D")
        for export_name in exported_variables(script_text):
            if export_name not in root_props:
                fail(f"{scene_rel}: Inspector ayarı sahnede açıkça saklanmıyor: {export_name}")
        for required in [
            "difficulty_health_multipliers",
            "difficulty_damage_multipliers",
            "difficulty_speed_multipliers",
            "difficulty_detection_multipliers",
            "difficulty_cooldown_multipliers",
            "difficulty_windup_multipliers",
            "floor_snap_max_correction",
            "burn_remains_scene",
        ]:
            if required not in root_props:
                fail(f"{scene_rel}: sahne-otoriteli enemy ayarı eksik: {required}")

    projectile_exports = exported_variables(read("scripts/actors/ravager_projectile.gd"))
    for projectile_name in ["ravager_projectile", "hellmagma_projectile", "voidweaver_projectile"]:
        scene_rel = f"scenes/actors/{projectile_name}.tscn"
        props = scene_root_property_names(read(scene_rel), "Area3D")
        for export_name in projectile_exports:
            if export_name not in props:
                fail(f"{scene_rel}: projectile Inspector ayarı sahnede saklanmıyor: {export_name}")

    scene_owned_props = {
        "scenes/props/pickup.tscn": ("scripts/props/pickup.gd", "Area3D"),
        "scenes/props/explosive_barrel.tscn": ("scripts/props/explosive_barrel.gd", "StaticBody3D"),
        "scenes/props/door_side_slide.tscn": ("scripts/props/door.gd", "Node3D"),
        "scenes/props/burn_remains.tscn": ("scripts/props/burn_remains.gd", "Node3D"),
        "scenes/props/finish_switch.tscn": ("scripts/props/finish_switch.gd", "Node3D"),
        "scenes/props/secret_trigger.tscn": ("scripts/props/secret_trigger.gd", "Area3D"),
        "scenes/levels/level_01.tscn": ("scripts/levels/level_01.gd", "Node3D"),
        "scenes/levels/level_02.tscn": ("scripts/levels/level_02.gd", "Node3D"),
        "scenes/hub/bastion_7.tscn": ("scripts/hub/bastion_7.gd", "Node3D"),
        "scenes/hub/hub_terminal.tscn": ("scripts/hub/hub_terminal.gd", "StaticBody3D"),
        "scenes/hub/hub_weapon_rack.tscn": ("scripts/hub/hub_weapon_rack.gd", "StaticBody3D"),
        "scenes/ui/hud.tscn": ("scripts/ui/hud.gd", "CanvasLayer"),
        "scenes/world/ceiling_light_white_horror.tscn": ("scripts/world/room_ceiling_light.gd", "Node3D"),
        "scenes/world/world_piece.tscn": ("scripts/world/world_piece.gd", "StaticBody3D"),
    }
    for scene_rel, (script_rel, root_type) in scene_owned_props.items():
        props = scene_root_property_names(read(scene_rel), root_type)
        for export_name in exported_variables(read(script_rel)):
            # visual_texture intentionally supports a null base-scene value.
            if export_name not in props:
                fail(f"{scene_rel}: Inspector ayarı sahnede saklanmıyor: {export_name}")

    hud_scene = read("scenes/ui/hud.tscn")
    automap_props = scene_named_node_property_names(hud_scene, "AutomapView")
    for export_name in exported_variables(read("scripts/ui/automap_view.gd")):
        if export_name not in automap_props:
            fail(f"scenes/ui/hud.tscn/AutomapView: Inspector ayarı sahnede saklanmıyor: {export_name}")
    automap_script = read("scripts/ui/automap_view.gd")
    for forbidden_override in [
        "mouse_filter = Control.MOUSE_FILTER_STOP",
        "focus_mode = Control.FOCUS_ALL",
        "clip_contents = true",
    ]:
        if forbidden_override in automap_script:
            fail(f"automap_view.gd: built-in sahne ayarı koddan eziliyor: {forbidden_override}")

    player_scene = read("scenes/player/player.tscn")
    player_props = scene_root_property_names(player_scene, "CharacterBody3D")
    for export_name in exported_variables(read("scripts/player/player.gd")):
        if export_name not in player_props:
            fail(f"scenes/player/player.tscn: player Inspector ayarı sahnede saklanmıyor: {export_name}")

    controller_props = scene_named_node_property_names(player_scene, "WeaponController")
    for export_name in exported_variables(read("scripts/player/weapon_controller.gd")):
        if export_name not in controller_props:
            fail(f"scenes/player/player.tscn/WeaponController: Inspector ayarı sahnede saklanmıyor: {export_name}")

    weapon_exports = exported_variables(read("scripts/player/weapon_definition.gd"))
    for weapon_rel in [
        "resources/weapons/pistol.tres",
        "resources/weapons/shotgun.tres",
        "resources/weapons/ak47.tres",
        "resources/weapons/mp90.tres",
    ]:
        props = resource_property_names(read(weapon_rel))
        for export_name in weapon_exports:
            if export_name not in props:
                fail(f"{weapon_rel}: weapon Inspector ayarı resource içinde açıkça saklanmıyor: {export_name}")

    owned_export_scripts = {
        "scripts/actors/redviper.gd",
        "scripts/actors/ravager.gd",
        "scripts/actors/ravager_projectile.gd",
        "scripts/levels/level_01.gd",
        "scripts/levels/level_02.gd",
        "scripts/hub/bastion_7.gd",
        "scripts/hub/hub_terminal.gd",
        "scripts/hub/hub_weapon_rack.gd",
        "scripts/player/player.gd",
        "scripts/player/weapon_controller.gd",
        "scripts/player/weapon_definition.gd",
        "scripts/props/burn_remains.gd",
        "scripts/props/door.gd",
        "scripts/props/explosive_barrel.gd",
        "scripts/props/finish_switch.gd",
        "scripts/props/pickup.gd",
        "scripts/props/secret_trigger.gd",
        "scripts/ui/automap_view.gd",
        "scripts/ui/hud.gd",
        "scripts/world/room_ceiling_light.gd",
        "scripts/world/world_piece.gd",
    }
    for script_path in (ROOT / "scripts").rglob("*.gd"):
        rel = script_path.relative_to(ROOT).as_posix()
        if exported_variables(script_path.read_text(encoding="utf-8")) and rel not in owned_export_scripts:
            fail(f"Sahne otoritesi haritasına eklenmemiş @export scripti: {rel}")

    pickup_script = read("scripts/props/pickup.gd")
    if "_apply_default_texture_for_type" in pickup_script:
        fail("pickup.gd: kod içi texture fallback sahne görselini ezebilir")
    if re.search(r'(?<!_)\bamount\s*(?:\+=|-=|=(?!=))', pickup_script):
        fail("pickup.gd: export amount runtime state olarak değiştiriliyor")

    barrel_script = read("scripts/props/explosive_barrel.gd")
    if re.search(r'(?<!_)\bhealth\s*-=', barrel_script):
        fail("explosive_barrel.gd: export health runtime'da azaltılıyor")

    door_script = read("scripts/props/door.gd")
    if re.search(r'(?<!_)\blocked\s*=\s*false', door_script):
        fail("door.gd: export locked runtime'da değiştiriliyor")
    if re.search(r'(?<!_)\bauto_close\s*=\s*false', door_script):
        fail("door.gd: export auto_close runtime'da değiştiriliyor")

def main() -> int:
    check_paths()
    check_canonical_names()
    check_level("scenes/levels/level_01.tscn", 18, 20, 38, (12.0, 0.4, 10.0))
    check_level("scenes/levels/level_02.tscn", 33, 35, 10, (12.0, 0.4, 10.0))
    check_level_02_specific()
    check_bastion_7()
    check_lighting()
    check_enemies()
    check_enemy_texture_imports()
    check_documented_standards()
    check_project_settings()
    check_scene_authority()

    if FAILURES:
        for item in FAILURES:
            print("HATA:", item)
        print(f"VEX statik denetimi başarısız: {len(FAILURES)} hata.")
        return 1
    print("VEX statik denetimi başarılı: Level 1/2, Bastion-7 hub, asset yolları, ışıklar, enemy/player/weapon/UI/world ayarları ve sahne otoritesi temiz.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
