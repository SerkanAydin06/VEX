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

    script = read("scripts/levels/level_02.gd")
    if '"world_min": Vector2(-54.0, -35.0)' not in script or '"world_max": Vector2(54.0, 35.0)' not in script:
        fail("VEX-02 automap sınırları 12×10m modüler haritaya göre güncel değil")


def check_lighting() -> None:
    scene = read("scenes/world/ceiling_light_white_horror.tscn")
    if "LightBeam" in scene:
        fail("Beyaz ışık sahnesinde görünür ışık hüzmesi geri gelmiş")
    required = [
        "light_energy = 2.6",
        "spot_range = 7.4",
        "spot_angle = 18.0",
        "light_specular = 0.0",
        "shadow_enabled = true",
    ]
    for item in required:
        if item not in scene:
            fail(f"Beyaz ışık profili eksik: {item}")


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
    ]
    for item in required:
        if item not in text:
            fail(f"STANDART.txt güncel değil: {item}")


def check_project_settings() -> None:
    text = read("project.godot")
    if 'limits/opengl/max_lights_per_object=16' not in text:
        fail("Compatibility renderer için max_lights_per_object=16 eksik")


def main() -> int:
    check_paths()
    check_canonical_names()
    check_level("scenes/levels/level_01.tscn", 18, 18, 38, (12.0, 0.4, 10.0))
    check_level("scenes/levels/level_02.tscn", 33, 33, 10, (12.0, 0.4, 10.0))
    check_level_02_specific()
    check_lighting()
    check_enemies()
    check_enemy_texture_imports()
    check_documented_standards()
    check_project_settings()

    if FAILURES:
        for item in FAILURES:
            print("HATA:", item)
        print(f"VEX statik denetimi başarısız: {len(FAILURES)} hata.")
        return 1
    print("VEX statik denetimi başarılı: Bölüm 1 ve Bölüm 2 modüler standardı, asset yolları, ışıklar ve yeni düşmanlar temiz.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
