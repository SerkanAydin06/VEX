#!/usr/bin/env python3
"""VEX kaynak paketi için Godot çalıştırmadan uygulanabilen bütünlük denetimi."""

from __future__ import annotations

import math
import re
import struct
import sys
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".gdshader", ".cfg"}


def main() -> int:
    failures: list[str] = []
    source_files = [
        path for path in ROOT.rglob("*")
        if path.is_file() and path.suffix in SOURCE_SUFFIXES
    ]
    _check_resource_paths(source_files, failures)
    _check_uids(failures)
    _check_import_sources(failures)
    _check_duplicate_properties(failures)
    _check_level_counts(failures)
    _check_required_strings(failures)
    _check_enemy_visual_grade(failures)
    _check_enemy_scene_settings(failures)
    _check_balance_matrix(failures)
    _check_performance_package(failures)

    if failures:
        for failure in failures:
            print(f"HATA: {failure}", file=sys.stderr)
        print(f"VEX statik denetimi başarısız: {len(failures)} hata.", file=sys.stderr)
        return 1

    print(
        "VEX statik denetimi başarılı: "
        f"{len(source_files)} kaynak dosyası, referanslar, UID'ler ve bölüm sayıları temiz."
    )
    print(
        "Denge matrisi doğrulandı: "
        "VEX-01=11/18/23/28, VEX-02=14/20/26/31 "
        "(Kolay/Normal/Zor/Kâbus)."
    )
    print(
        "Görsel/fizik standardı doğrulandı: 96 düşman karesi, ortak zemin çizgisi, "
        "karanlık palet, Ravager/RedViper 1,80 m insan ölçeği ve "
        "HellMagma kapı payı temiz."
    )
    print(
        "Uzak saldırı hareketi doğrulandı: Ravager sağ namlu çıkışı ve "
        "Ravager/HellMagma atış sonrası yaklaşma-yan hareket ayarları temiz."
    )
    print(
        "Performans Paketi 1 doğrulandı: oklüzyon, ışık LOD'u, düşman uyku "
        "mesafeleri, aralıklı görüş ve 3B kalite profilleri temiz."
    )
    return 0


def _check_resource_paths(source_files: list[Path], failures: list[str]) -> None:
    pattern = re.compile(r"[\"']res://([^\"']+)[\"']")
    for source_file in source_files:
        text = source_file.read_text(encoding="utf-8")
        for relative_path in pattern.findall(text):
            if "*" in relative_path or relative_path.endswith(".*"):
                continue
            if not (ROOT / relative_path).exists():
                failures.append(
                    f"Eksik res:// yolu: {relative_path} ({source_file.relative_to(ROOT)})"
                )


def _check_uids(failures: list[str]) -> None:
    uid_by_path: dict[str, str] = {}
    text_files = [
        path for path in ROOT.rglob("*")
        if path.is_file() and path.suffix in SOURCE_SUFFIXES | {".import"}
    ]
    for path in text_files:
        text = path.read_text(encoding="utf-8")
        header = re.search(
            r'^\[(?:gd_scene|gd_resource)[^\]]*\buid="([^"]+)"',
            text,
            re.MULTILINE,
        )
        if header:
            uid_by_path[path.relative_to(ROOT).as_posix()] = header.group(1)
        if path.suffix == ".import":
            imported = re.search(r'^uid="([^"]+)"', text, re.MULTILINE)
            if imported:
                uid_by_path[path.with_suffix("").relative_to(ROOT).as_posix()] = imported.group(1)

    ext_pattern = re.compile(
        r'^\[ext_resource[^\]]*\buid="([^"]+)"[^\]]*'
        r'\bpath="res://([^"]+)"',
        re.MULTILINE,
    )
    for path in text_files:
        text = path.read_text(encoding="utf-8")
        for declared_uid, resource_path in ext_pattern.findall(text):
            actual_uid = uid_by_path.get(resource_path)
            if actual_uid and actual_uid != declared_uid:
                failures.append(
                    f"UID uyuşmazlığı: {resource_path} ({path.relative_to(ROOT)})"
                )


def _check_import_sources(failures: list[str]) -> None:
    for import_file in ROOT.rglob("*.import"):
        text = import_file.read_text(encoding="utf-8")
        match = re.search(r'^source_file="res://([^"]+)"', text, re.MULTILINE)
        if not match or not (ROOT / match.group(1)).exists():
            failures.append(f"Sahipsiz import: {import_file.relative_to(ROOT)}")


def _check_duplicate_properties(failures: list[str]) -> None:
    property_pattern = re.compile(r"^([A-Za-z_][A-Za-z0-9_\-/]*)\s*=")
    for path in [*ROOT.rglob("*.tscn"), *ROOT.rglob("*.tres")]:
        section = "<root>"
        seen: set[str] = set()
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if line.startswith("["):
                section = line
                seen.clear()
                continue
            match = property_pattern.match(line)
            if not match:
                continue
            key = match.group(1)
            if key in seen:
                failures.append(
                    f"Yinelenen özellik: {path.relative_to(ROOT)}:{line_number} {section} {key}"
                )
            seen.add(key)


def _check_level_counts(failures: list[str]) -> None:
    expected = {
        "scenes/levels/level_01.tscn": {
            'instance=ExtResource("2_piece")': 71,
            'instance=ExtResource("8_door")': 19,
            'instance=ExtResource("9_pickup")': 22,
            'instance=ExtResource("10_barrel")': 4,
            'instance=ExtResource("19_lamp_red")': 38,
            'groups=["enemy_navigation_waypoint"]': 18,
            'instance=ExtResource("25_hellmagma")': 1,
        },
        "scenes/levels/level_02.tscn": {
            'instance=ExtResource("2_piece")': 195,
            'instance=ExtResource("8_door")': 5,
            'instance=ExtResource("9_pickup")': 24,
            'instance=ExtResource("10_barrel")': 6,
            'instance=ExtResource("19_lamp_red")': 10,
            'groups=["enemy_navigation_waypoint"]': 33,
        },
    }
    for relative_path, counts in expected.items():
        text = (ROOT / relative_path).read_text(encoding="utf-8")
        for token, expected_count in counts.items():
            actual_count = text.count(token)
            if actual_count != expected_count:
                failures.append(
                    f"İçerik sayısı yanlış: {relative_path} {token} "
                    f"beklenen={expected_count} gerçek={actual_count}"
                )


def _check_required_strings(failures: list[str]) -> None:
    level_01 = (ROOT / "scenes/levels/level_01.tscn").read_text(encoding="utf-8")
    level_01_script = (ROOT / "scripts/levels/level_01.gd").read_text(encoding="utf-8")
    level_02_script = (ROOT / "scripts/levels/level_02.gd").read_text(encoding="utf-8")
    hud_script = (ROOT / "scripts/ui/hud.gd").read_text(encoding="utf-8")
    automap_script = (ROOT / "scripts/ui/automap_view.gd").read_text(encoding="utf-8")
    hud_scene = (ROOT / "scenes/ui/hud.tscn").read_text(encoding="utf-8")
    ravager_script = (ROOT / "scripts/actors/ravager.gd").read_text(encoding="utf-8")
    ravager_scene = (ROOT / "scenes/actors/ravager.tscn").read_text(encoding="utf-8")
    hellmagma_script = (ROOT / "scripts/actors/hellmagma.gd").read_text(
        encoding="utf-8"
    )
    hellmagma_scene = (ROOT / "scenes/actors/hellmagma.tscn").read_text(
        encoding="utf-8"
    )
    redviper_script = (ROOT / "scripts/actors/redviper.gd").read_text(encoding="utf-8")
    redviper_scene = (ROOT / "scenes/actors/redviper.tscn").read_text(encoding="utf-8")
    badredviper_script = (ROOT / "scripts/actors/badredviper.gd").read_text(encoding="utf-8")
    badredviper_scene = (ROOT / "scenes/actors/badredviper.tscn").read_text(encoding="utf-8")
    pickup_scene = (ROOT / "scenes/props/pickup.tscn").read_text(encoding="utf-8")
    project_config = (ROOT / "project.godot").read_text(encoding="utf-8")
    finish_script = (ROOT / "scripts/props/finish_switch.gd").read_text(encoding="utf-8")
    all_sources = "\n".join(
        path.read_text(encoding="utf-8")
        for path in ROOT.rglob("*")
        if path.is_file() and path.suffix in SOURCE_SUFFIXES
    )
    if 'next_level_path = "res://scenes/levels/level_02.tscn"' not in level_01:
        failures.append("VEX-01 → VEX-02 geçiş yolu eksik.")
    if 'call_deferred("complete_level", next_level_path)' not in finish_script:
        failures.append("FinishSwitch geçiş yolunu GameState'e aktarmıyor.")
    if 'config/version="3.1.1"' not in project_config:
        failures.append("Proje sürümü 3.1.1 değil.")
    if "billboard = 2" not in pickup_scene:
        failures.append("Pickup sabit-Y billboard modunda değil.")
    legacy_map_tokens = (
        "texture_path",
        "texture_region",
        "content_rect",
        "grid_x_edges",
        "grid_y_edges",
        "_map_pixel_to_local",
        "_world_axis_to_map_pixel",
    )
    for legacy_token in legacy_map_tokens:
        if legacy_token in level_01_script or legacy_token in level_02_script or legacy_token in hud_script:
            failures.append(f"Eski PNG harita hizalama kalıntısı bulundu: {legacy_token}")

    required_automap_functions = (
        "configure",
        "update_player",
        "focus_player",
        "_draw_cells",
        "_draw_doors",
        "_draw_player_marker",
        "_zoom_at",
    )
    for required_function in required_automap_functions:
        if f"func {required_function}" not in automap_script:
            failures.append(f"Profesyonel harita işlevi eksik: {required_function}")

    if 'path="res://assets/ui/automap_console_frame_v2.png"' not in hud_scene:
        failures.append("Yeni harita konsol görseli HUD sahnesine bağlı değil.")
    if 'path="res://scripts/ui/automap_view.gd"' not in hud_scene:
        failures.append("Canlı harita çizim scripti HUD sahnesine bağlı değil.")
    for obsolete_hud_node in ('name="MapTexture"', 'name="MapMarker"'):
        if obsolete_hud_node in hud_scene:
            failures.append(f"Eski harita düğümü HUD içinde kalmış: {obsolete_hud_node}")

    _check_automap_data(level_01_script, level_02_script, failures)

    if "class_name VexRavager" not in ravager_script:
        failures.append("Ravager sınıf adı VexRavager değil.")
    if '[node name="Ravager" type="CharacterBody3D"]' not in ravager_scene:
        failures.append("Ravager sahnesinin kök düğüm adı yanlış.")
    if 'enemy_id = &"ravager"' not in ravager_scene:
        failures.append("Ravager temel enemy_id değeri yanlış.")

    ravager_asset_root = ROOT / "assets/enemies/Ravager"
    expected_ravager_assets = [
        ravager_asset_root / f"ravager_{group}_{frame}.png"
        for group in (
            "attack",
            "death",
            "idle",
            "idle_back",
            "walk",
            "walk_back",
        )
        for frame in range(1, 5)
    ]
    for asset_path in expected_ravager_assets:
        if not asset_path.exists():
            failures.append(
                "Ravager görseli eksik: "
                + asset_path.relative_to(ROOT).as_posix()
            )
            continue
        relative_asset = asset_path.relative_to(ROOT).as_posix()
        if f'path="res://{relative_asset}"' not in ravager_scene:
            failures.append("Ravager sahnesine bağlanmamış görsel: " + relative_asset)
        png_header = asset_path.read_bytes()[:26]
        if len(png_header) < 26 or png_header[:8] != b"\x89PNG\r\n\x1a\n":
            failures.append("Ravager görsel biçimi PNG değil: " + relative_asset)
            continue
        width, height = struct.unpack(">II", png_header[16:24])
        color_type = png_header[25]
        if (width, height) != (543, 543):
            failures.append(
                f"Ravager görsel boyutu yanlış: {relative_asset} "
                f"{width}x{height}"
            )
        if color_type not in (4, 6):
            failures.append("Ravager görselinde alfa kanalı yok: " + relative_asset)
    allowed_ravager_assets = {
        *expected_ravager_assets,
        ravager_asset_root / "ravager_projectile.png",
        ravager_asset_root / "ravager_impact.png",
    }
    unexpected_ravager_assets = sorted(
        path.relative_to(ROOT).as_posix()
        for path in ravager_asset_root.glob("ravager_*.png")
        if path not in allowed_ravager_assets
    )
    if unexpected_ravager_assets:
        failures.append(
            "Ravager klasöründe eski/standart dışı görsel kaldı: "
            + ", ".join(unexpected_ravager_assets)
        )
    if ravager_scene.count('"texture": ExtResource("6_death1")') != 2:
        failures.append("Ravager hurt animasyonu death_1 karesini kullanmıyor.")
    if '"name": &"death_back"' in ravager_scene:
        failures.append("Ravager paketinde olmayan death_back animasyonu tanımlanmış.")
    if "modulate =" in _read_named_node_block(ravager_scene, "AnimatedSprite3D"):
        failures.append("Ravager üzerinde eski renk filtresi kalmış.")
    for required_visual_setting in (
        "radius = 0.42",
        "height = 1.8",
        "pixel_size = 0.003315",
        "projectile_spawn_height = 0.31",
        "corpse_visual_y = -0.1",
        'name="GroundShadow"',
        "shaded = true",
    ):
        if required_visual_setting not in ravager_scene:
            failures.append(
                "Ravager yeni görsel sahne ayarı eksik: "
                + required_visual_setting
            )

    if "class_name VexHellMagma" not in hellmagma_script:
        failures.append("HellMagma sınıf adı VexHellMagma değil.")
    if 'extends "res://scripts/actors/ravager.gd"' not in hellmagma_script:
        failures.append(
            "HellMagma, Ravager uzak saldırı yapay zekâsını miras almıyor."
        )
    if '[node name="HellMagma" type="CharacterBody3D"]' not in hellmagma_scene:
        failures.append("HellMagma sahnesinin kök düğüm adı yanlış.")
    if 'enemy_id = &"hellmagma"' not in hellmagma_scene:
        failures.append("HellMagma temel enemy_id değeri yanlış.")
    if 'name="HellMagma_TestStartRoom"' not in level_01:
        failures.append("HellMagma başlangıç odası test yerleşimi eksik.")
    if 'name="HellMagmaTestBullets"' not in level_01:
        failures.append("HellMagma başlangıç odası test mühimmatı eksik.")
    if "class_name VexBadRedViper" not in badredviper_script:
        failures.append("BadRedViper sınıf adı VexBadRedViper değil.")
    if 'extends "res://scripts/actors/redviper.gd"' not in badredviper_script:
        failures.append("BadRedViper, RedViper yapay zekâsını miras almıyor.")
    if '[node name="BadRedViper" type="CharacterBody3D"]' not in badredviper_scene:
        failures.append("BadRedViper sahnesinin kök düğüm adı yanlış.")
    if 'enemy_id = &"badredviper"' not in badredviper_scene:
        failures.append("BadRedViper temel enemy_id değeri yanlış.")
    if 'animation_name == &"walk" and _has_animation(&"walk_back")' not in redviper_script:
        failures.append("Ortak RedViper yapay zekâsı walk_back animasyonunu seçmiyor.")

    redviper_asset_root = ROOT / "assets/enemies/redviper"
    expected_redviper_assets = [
        redviper_asset_root / f"redviper_{group}_{frame}.png"
        for group in (
            "attack",
            "death",
            "idle",
            "idle_back",
            "walk",
            "walk_back",
        )
        for frame in range(1, 5)
    ]
    for asset_path in expected_redviper_assets:
        if not asset_path.exists():
            failures.append(
                "RedViper görseli eksik: "
                + asset_path.relative_to(ROOT).as_posix()
            )
            continue
        relative_asset = asset_path.relative_to(ROOT).as_posix()
        if f'path="res://{relative_asset}"' not in redviper_scene:
            failures.append("RedViper sahnesine bağlanmamış görsel: " + relative_asset)
        png_header = asset_path.read_bytes()[:26]
        if len(png_header) < 26 or png_header[:8] != b"\x89PNG\r\n\x1a\n":
            failures.append("RedViper görsel biçimi PNG değil: " + relative_asset)
            continue
        width, height = struct.unpack(">II", png_header[16:24])
        color_type = png_header[25]
        if (width, height) != (543, 543):
            failures.append(
                f"RedViper görsel boyutu yanlış: {relative_asset} "
                f"{width}x{height}"
            )
        if color_type not in (4, 6):
            failures.append("RedViper görselinde alfa kanalı yok: " + relative_asset)
    unexpected_redviper_assets = sorted(
        path.relative_to(ROOT).as_posix()
        for path in redviper_asset_root.glob("redviper_*.png")
        if path not in set(expected_redviper_assets)
    )
    if unexpected_redviper_assets:
        failures.append(
            "RedViper klasöründe eski/standart dışı görsel kaldı: "
            + ", ".join(unexpected_redviper_assets)
        )
    if redviper_scene.count('"texture": ExtResource("9_death1")') != 2:
        failures.append("RedViper hurt animasyonu death_1 karesini kullanmıyor.")
    legacy_redviper_effect = "tele" + "port"
    legacy_redviper_attack = "redviper_" + "at" + "ak_"
    legacy_redviper_hurt = "redviper_" + "hurt"
    for obsolete_redviper_token in (
        legacy_redviper_attack,
        legacy_redviper_hurt,
        "redviper_" + legacy_redviper_effect + "_",
    ):
        if obsolete_redviper_token in redviper_scene:
            failures.append(
                "RedViper sahnesinde eski görsel/animasyon kalıntısı var: "
                + obsolete_redviper_token
            )
    if "modulate =" in _read_named_node_block(redviper_scene, "AnimatedSprite3D"):
        failures.append("RedViper üzerinde eski renk filtresi kalmış.")
    for required_visual_setting in (
        "radius = 0.42",
        "height = 1.8",
        "pixel_size = 0.003315",
        "texture_filter = 1",
        "corpse_visual_y = 0.4032",
        'name="GroundShadow"',
        "shaded = true",
    ):
        if required_visual_setting not in redviper_scene:
            failures.append(
                "RedViper yeni görsel sahne ayarı eksik: "
                + required_visual_setting
            )
    if (
        legacy_redviper_effect in redviper_scene.lower()
        or legacy_redviper_effect in redviper_script.lower()
    ):
        failures.append("RedViper eski doğma efekti tamamen kaldırılmamış.")
    if "spawn_animation" in redviper_scene or "spawn_animation" in redviper_script:
        failures.append("RedViper kullanılmayan doğma animasyonu kodu tamamen kaldırılmamış.")

    badredviper_asset_root = ROOT / "assets/enemies/badredviper"
    expected_badredviper_assets = [
        badredviper_asset_root / f"badredviper_{group}_{frame}.png"
        for group in ("attack", "death", "idle", "idle_back", "walk", "walk_back")
        for frame in range(1, 5)
    ]
    for asset_path in expected_badredviper_assets:
        if not asset_path.exists():
            failures.append(
                "BadRedViper görseli eksik: "
                + asset_path.relative_to(ROOT).as_posix()
            )
            continue
        relative_asset = asset_path.relative_to(ROOT).as_posix()
        if f'path="res://{relative_asset}"' not in badredviper_scene:
            failures.append("BadRedViper sahnesine bağlanmamış görsel: " + relative_asset)
        import_text = asset_path.with_suffix(".png.import").read_text(encoding="utf-8")
        if "compress/mode=2" not in import_text or "mipmaps/generate=true" not in import_text:
            failures.append("BadRedViper import performans ayarı eksik: " + relative_asset)
    if "badredviper_hurt" in badredviper_scene:
        failures.append("BadRedViper için gereksiz ayrı hurt görseli tanımlanmış.")
    if badredviper_scene.count('"texture": ExtResource("9_death1")') != 2:
        failures.append("BadRedViper hurt animasyonu death_1 karesini kullanmıyor.")
    for required_visual_setting in (
        "radius = 0.82",
        "height = 3.1",
        "pixel_size = 0.0062",
        "corpse_visual_y = 1.1865",
        'name="GroundShadow"',
        "shaded = true",
    ):
        if required_visual_setting not in badredviper_scene:
            failures.append(
                "BadRedViper görsel sahne ayarı eksik: "
                + required_visual_setting
            )

    hellmagma_asset_root = ROOT / "assets/enemies/HellMagma"
    expected_hellmagma_assets = [
        hellmagma_asset_root / f"HellMagma_{group}_{frame}.png"
        for group in (
            "attack",
            "death",
            "idle",
            "idle_back",
            "walk",
            "walk_back",
        )
        for frame in range(1, 5)
    ]
    for asset_path in expected_hellmagma_assets:
        if not asset_path.exists():
            failures.append(
                "HellMagma görseli eksik: "
                + asset_path.relative_to(ROOT).as_posix()
            )
            continue
        relative_asset = asset_path.relative_to(ROOT).as_posix()
        if f'path="res://{relative_asset}"' not in hellmagma_scene:
            failures.append(
                "HellMagma sahnesine bağlanmamış görsel: " + relative_asset
            )
        png_header = asset_path.read_bytes()[:26]
        if len(png_header) < 26 or png_header[:8] != b"\x89PNG\r\n\x1a\n":
            failures.append("HellMagma görsel biçimi PNG değil: " + relative_asset)
            continue
        width, height = struct.unpack(">II", png_header[16:24])
        color_type = png_header[25]
        if (width, height) != (543, 543):
            failures.append(
                f"HellMagma görsel boyutu yanlış: {relative_asset} "
                f"{width}x{height}"
            )
        if color_type not in (4, 6):
            failures.append(
                "HellMagma görselinde alfa kanalı yok: " + relative_asset
            )
    if hellmagma_scene.count('"texture": ExtResource("6_death1")') != 2:
        failures.append("HellMagma hurt animasyonu death_1 karesini kullanmıyor.")
    for required_visual_setting in (
        "radius = 1.0",
        "height = 3.6",
        "pixel_size = 0.0073547",
        "corpse_visual_y = 0.2",
        'name="GroundShadow"',
        "shaded = true",
    ):
        if required_visual_setting not in hellmagma_scene:
            failures.append(
                "HellMagma görsel sahne ayarı eksik: "
                + required_visual_setting
            )
    legacy_actor_path = "enemy_" + "drone"
    legacy_actor_class = "vexenemy" + "drone"
    legacy_projectile_path = "enemy_" + "projectile"
    legacy_projectile_class = "vexenemy" + "projectile"
    for legacy_token in (
        legacy_actor_path,
        legacy_actor_class,
        legacy_projectile_path,
        legacy_projectile_class,
    ):
        if legacy_token in all_sources.lower():
            failures.append("Eski Ravager adlandırması kaynaklarda kalmış.")
        legacy_paths = [
            path.relative_to(ROOT).as_posix()
            for path in ROOT.rglob("*")
            if legacy_token in path.relative_to(ROOT).as_posix().lower()
        ]
        if legacy_paths:
            failures.append(
                "Eski Ravager dosya yolu kalmış: " + ", ".join(legacy_paths)
            )
    if list((ROOT / "assets/enemies").glob("ravager_*.png")):
        failures.append("Ravager görselleri assets/enemies/Ravager klasörü dışında kalmış.")
    for obsolete_map_asset in (
        "assets/ui/map_level_01.png",
        "assets/ui/map_level_02.png",
        "assets/ui/player_marker.png",
    ):
        if (ROOT / obsolete_map_asset).exists():
            failures.append(f"Eski statik harita varlığı silinmemiş: {obsolete_map_asset}")
    forbidden_name = "final_" + "switch"
    if forbidden_name in all_sources.lower():
        failures.append("Eski bitiş nesnesi adı kaynaklarda kalmış.")


def _check_enemy_visual_grade(failures: list[str]) -> None:
    """96 düşman karesinin karanlık paletini ve ortak taban çizgisini doğrula."""
    visual_sets = {
        "Ravager": (ROOT / "assets/enemies/Ravager", "ravager"),
        "RedViper": (ROOT / "assets/enemies/redviper", "redviper"),
        "BadRedViper": (ROOT / "assets/enemies/badredviper", "badredviper"),
        "HellMagma": (ROOT / "assets/enemies/HellMagma", "HellMagma"),
    }
    groups = ("attack", "death", "idle", "idle_back", "walk", "walk_back")

    for label, (asset_root, prefix) in visual_sets.items():
        luminance_histogram = [0] * 256
        meaningful_pixel_count = 0
        for group in groups:
            for frame in range(1, 5):
                asset_path = asset_root / f"{prefix}_{group}_{frame}.png"
                if not asset_path.exists():
                    continue
                try:
                    width, height, pixels = _decode_rgba_png(asset_path)
                except (ValueError, zlib.error) as error:
                    failures.append(
                        f"{label} görseli çözümlenemiyor: "
                        f"{asset_path.relative_to(ROOT)} ({error})"
                    )
                    continue
                if (width, height) != (543, 543):
                    continue

                frame_bottom = -1
                for pixel_offset in range(0, len(pixels), 4):
                    alpha = pixels[pixel_offset + 3]
                    if alpha <= 16:
                        continue
                    frame_bottom = max(frame_bottom, pixel_offset // 4 // width)
                    red = pixels[pixel_offset]
                    green = pixels[pixel_offset + 1]
                    blue = pixels[pixel_offset + 2]
                    # Rec.709 katsayılarının 8 bit tamsayı yaklaşımı.
                    luminance = (54 * red + 183 * green + 19 * blue + 128) // 256
                    luminance_histogram[luminance] += 1
                    meaningful_pixel_count += 1

                if frame_bottom != 542:
                    failures.append(
                        f"{label} karesi ortak zemin çizgisinde değil: "
                        f"{asset_path.relative_to(ROOT)} alt={frame_bottom}"
                    )

        if meaningful_pixel_count == 0:
            failures.append(f"{label} parlaklık ölçümü için görünür piksel içermiyor.")
            continue
        percentile_90 = _histogram_percentile(luminance_histogram, 0.90)
        percentile_99 = _histogram_percentile(luminance_histogram, 0.99)
        if not 100 <= percentile_90 <= 138:
            failures.append(
                f"{label} karanlık oyun parlaklık standardı dışında: "
                f"P90={percentile_90}/255"
            )
        if not 165 <= percentile_99 <= 210:
            failures.append(
                f"{label} vurgu parlaklığı standardı dışında: "
                f"P99={percentile_99}/255"
            )


def _decode_rgba_png(path: Path) -> tuple[int, int, bytes]:
    """Harici paket olmadan 8 bit, titreşimsiz RGBA PNG piksel verisini aç."""
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("PNG imzası geçersiz")

    width = height = bit_depth = color_type = interlace = -1
    compressed = bytearray()
    offset = 8
    while offset + 12 <= len(data):
        chunk_length = struct.unpack(">I", data[offset:offset + 4])[0]
        chunk_type = data[offset + 4:offset + 8]
        chunk_data = data[offset + 8:offset + 8 + chunk_length]
        offset += 12 + chunk_length
        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type, _compression, _filter, interlace = (
                struct.unpack(">IIBBBBB", chunk_data)
            )
        elif chunk_type == b"IDAT":
            compressed.extend(chunk_data)
        elif chunk_type == b"IEND":
            break

    if bit_depth != 8 or color_type != 6 or interlace != 0:
        raise ValueError(
            f"desteklenmeyen PNG biçimi depth={bit_depth} type={color_type} interlace={interlace}"
        )

    bytes_per_pixel = 4
    stride = width * bytes_per_pixel
    filtered = zlib.decompress(bytes(compressed))
    if len(filtered) != height * (stride + 1):
        raise ValueError("PNG tarama satırı uzunluğu geçersiz")

    result = bytearray(height * stride)
    previous = bytearray(stride)
    source_offset = 0
    target_offset = 0
    for _row in range(height):
        filter_type = filtered[source_offset]
        source_offset += 1
        current = bytearray(filtered[source_offset:source_offset + stride])
        source_offset += stride
        for index in range(stride):
            left = current[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
            above = previous[index]
            upper_left = previous[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
            if filter_type == 1:
                current[index] = (current[index] + left) & 0xFF
            elif filter_type == 2:
                current[index] = (current[index] + above) & 0xFF
            elif filter_type == 3:
                current[index] = (current[index] + ((left + above) // 2)) & 0xFF
            elif filter_type == 4:
                current[index] = (
                    current[index] + _paeth_predictor(left, above, upper_left)
                ) & 0xFF
            elif filter_type != 0:
                raise ValueError(f"bilinmeyen PNG filtresi: {filter_type}")
        result[target_offset:target_offset + stride] = current
        target_offset += stride
        previous = current
    return width, height, bytes(result)


def _paeth_predictor(left: int, above: int, upper_left: int) -> int:
    prediction = left + above - upper_left
    left_distance = abs(prediction - left)
    above_distance = abs(prediction - above)
    upper_left_distance = abs(prediction - upper_left)
    if left_distance <= above_distance and left_distance <= upper_left_distance:
        return left
    if above_distance <= upper_left_distance:
        return above
    return upper_left


def _histogram_percentile(histogram: list[int], fraction: float) -> int:
    target = max(1, math.ceil(sum(histogram) * fraction))
    running = 0
    for value, count in enumerate(histogram):
        running += count
        if running >= target:
            return value
    return len(histogram) - 1


def _check_automap_data(
    level_01_script: str,
    level_02_script: str,
    failures: list[str],
) -> None:
    for label, script, expected_cells, expected_revision, start_cell in (
        ("VEX-01", level_01_script, 18, "VEX01-R26-PRO-AUTOMAP", (0, 5)),
        ("VEX-02", level_02_script, 33, "VEX02-R46-PRO-AUTOMAP", (4, 3)),
    ):
        cell_block = re.search(
            r"const AUTOMAP_WALKABLE_CELLS[^=]*=\s*\[(.*?)\]",
            script,
            re.DOTALL,
        )
        cell_matches = re.findall(r"Vector2i\((\d+),\s*(\d+)\)", cell_block.group(1)) if cell_block else []
        cells = {(int(x), int(y)) for x, y in cell_matches}
        cell_count = len(cell_matches)
        if cell_count != expected_cells:
            failures.append(
                f"{label} yürünebilir hücre sayısı yanlış: "
                f"beklenen={expected_cells} gerçek={cell_count}"
            )
        if expected_revision not in script:
            failures.append(f"{label} profesyonel harita revizyonu eksik.")
        if len(cells) != cell_count:
            failures.append(f"{label} haritasında yinelenen yürünebilir hücre var.")
        if start_cell in cells:
            visited = {start_cell}
            pending = [start_cell]
            while pending:
                x, y = pending.pop()
                for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if neighbor in cells and neighbor not in visited:
                        visited.add(neighbor)
                        pending.append(neighbor)
            if len(visited) != len(cells):
                failures.append(
                    f"{label} hücre planı kesintili: {len(visited)}/{len(cells)} hücre bağlı."
                )
        else:
            failures.append(f"{label} başlangıç hücresi yürünebilir değil: {start_cell}")

    connection_block = re.search(
        r"const AUTOMAP_DOOR_CONNECTIONS[^=]*=\s*\[(.*?)\]\s*\n\n",
        level_01_script,
        re.DOTALL,
    )
    connections: list[tuple[tuple[int, int], tuple[int, int]]] = []
    if connection_block:
        for match in re.finditer(
            r'"from":\s*Vector2i\((\d+),\s*(\d+)\).*?'
            r'"to":\s*Vector2i\((\d+),\s*(\d+)\)',
            connection_block.group(1),
        ):
            connections.append(
                ((int(match.group(1)), int(match.group(2))),
                 (int(match.group(3)), int(match.group(4))))
            )
    if len(connections) != 19:
        failures.append(
            f"VEX-01 kapı grafiği 19 bağlantı içermeli; gerçek={len(connections)}"
        )
    else:
        adjacency: dict[tuple[int, int], set[tuple[int, int]]] = {
            (x, y): set() for y in range(6) for x in range(3)
        }
        for first, second in connections:
            if first not in adjacency or second not in adjacency:
                failures.append(f"VEX-01 kapı grafiğinde ızgara dışı hücre var: {first} → {second}")
                continue
            if abs(first[0] - second[0]) + abs(first[1] - second[1]) != 1:
                failures.append(f"VEX-01 kapısı komşu olmayan odaları bağlıyor: {first} → {second}")
            adjacency[first].add(second)
            adjacency[second].add(first)
        visited = {(0, 5)}
        pending = [(0, 5)]
        while pending:
            current = pending.pop()
            for neighbor in adjacency[current] - visited:
                visited.add(neighbor)
                pending.append(neighbor)
        if len(visited) != 18:
            failures.append(f"VEX-01 kapı grafiği bütün 18 odaya ulaşmıyor: {len(visited)}/18")


def _check_enemy_scene_settings(failures: list[str]) -> None:
    common_properties = (
        "enemy_id",
        "maximum_health",
        "spawn_min_difficulty",
        "apply_difficulty_scaling",
        "move_speed",
        "movement_acceleration",
        "braking_acceleration",
        "gravity_scale",
        "floor_stick_velocity",
        "patrol_offset",
        "detection_range",
        "pursuit_range",
        "initial_view_angle",
        "lost_sight_timeout",
        "search_duration",
        "ally_alert_radius",
        "sight_origin_height",
        "sight_target_height",
        "attack_damage",
        "attack_range",
        "attack_cooldown",
        "attack_windup",
        "attack_range_tolerance",
        "back_view_threshold",
        "hurt_reaction_duration",
        "corpse_visual_y",
    )
    enemy_files = {
        "Ravager": (
            ROOT / "scripts/actors/ravager.gd",
            ROOT / "scenes/actors/ravager.tscn",
        ),
        "HellMagma": (
            ROOT / "scripts/actors/ravager.gd",
            ROOT / "scenes/actors/hellmagma.tscn",
        ),
        "RedViper": (
            ROOT / "scripts/actors/redviper.gd",
            ROOT / "scenes/actors/redviper.tscn",
        ),
        "BadRedViper": (
            ROOT / "scripts/actors/redviper.gd",
            ROOT / "scenes/actors/badredviper.tscn",
        ),
    }
    geometry_standard = {
        "Ravager": {"pixel_size": 0.003315, "radius": 0.42, "height": 1.8},
        "RedViper": {"pixel_size": 0.003315, "radius": 0.42, "height": 1.8},
        "BadRedViper": {"pixel_size": 0.0062, "radius": 0.82, "height": 3.1},
        "HellMagma": {"pixel_size": 0.0073547, "radius": 1.0, "height": 3.6},
    }

    for label, (script_path, scene_path) in enemy_files.items():
        script = script_path.read_text(encoding="utf-8")
        scene = scene_path.read_text(encoding="utf-8")
        root_properties = _read_root_node_properties(scene_path)
        exported_properties = re.findall(
            r"^@export[^\n]*\bvar\s+([A-Za-z_][A-Za-z0-9_]*)\b",
            script,
            re.MULTILINE,
        )
        for property_name in exported_properties:
            if not re.search(
                rf"^{re.escape(property_name)}\s*=",
                scene,
                re.MULTILINE,
            ):
                failures.append(
                    f"{label} export değeri temel sahnede kayıtlı değil: "
                    f"{property_name}"
                )
        for property_name in common_properties:
            export_pattern = re.compile(
                rf"^@export[^\n]*\bvar\s+{re.escape(property_name)}\b",
                re.MULTILINE,
            )
            if not export_pattern.search(script):
                failures.append(
                    f"{label} ortak Inspector alanı eksik: {property_name}"
                )
            scene_pattern = re.compile(
                rf"^{re.escape(property_name)}\s*=",
                re.MULTILINE,
            )
            if not scene_pattern.search(scene):
                failures.append(
                    f"{label} temel sahne değeri kayıtlı değil: {property_name}"
                )
        if re.search(r"animated_sprite\.pixel_size\s*=(?!=)", script):
            failures.append(f"{label} Pixel Size değerini script ezmemeli.")
        if re.search(r"animated_sprite\.sprite_frames\s*=(?!=)", script):
            failures.append(f"{label} SpriteFrames kaynağını script ezmemeli.")
        mutated_scene_value = re.search(
            r"^\s*(?:maximum_health|attack_damage|move_speed|detection_range|"
            r"pursuit_range|attack_cooldown|attack_windup)\s*=",
            script,
            re.MULTILINE,
        )
        if mutated_scene_value:
            failures.append(
                f"{label} Inspector temel değerini çalışma anında değiştiriyor: "
                f"{mutated_scene_value.group(0).strip()}"
            )

        sprite_block = _read_named_node_block(scene, "AnimatedSprite3D")
        collision_block = _read_named_node_block(scene, "CollisionShape3D")
        shadow_block = _read_named_node_block(scene, "GroundShadow")
        sprite_properties = dict(re.findall(
            r"^([A-Za-z_][A-Za-z0-9_]*) = (.+)$",
            sprite_block,
            re.MULTILINE,
        ))
        collision_properties = dict(re.findall(
            r"^([A-Za-z_][A-Za-z0-9_]*) = (.+)$",
            collision_block,
            re.MULTILINE,
        ))
        shadow_properties = dict(re.findall(
            r"^([A-Za-z_][A-Za-z0-9_]*) = (.+)$",
            shadow_block,
            re.MULTILINE,
        ))
        capsule_match = re.search(
            r'^\[sub_resource type="CapsuleShape3D"[^\]]*\]\n(.*?)(?=^\[)',
            scene,
            re.MULTILINE | re.DOTALL,
        )
        capsule_properties = dict(re.findall(
            r"^([A-Za-z_][A-Za-z0-9_]*) = (.+)$",
            capsule_match.group(1) if capsule_match else "",
            re.MULTILINE,
        ))
        expected_geometry = geometry_standard[label]
        pixel_size = float(sprite_properties.get("pixel_size", "0"))
        radius = float(capsule_properties.get("radius", "0"))
        capsule_height = float(capsule_properties.get("height", "0"))
        if not math.isclose(pixel_size, expected_geometry["pixel_size"], abs_tol=0.000001):
            failures.append(f"{label} görsel boyut sınıfı yanlış: Pixel Size={pixel_size}")
        if not math.isclose(radius, expected_geometry["radius"], abs_tol=0.0001):
            failures.append(f"{label} çarpışma yarıçapı boyut sınıfıyla eşleşmiyor.")
        if not math.isclose(capsule_height, expected_geometry["height"], abs_tol=0.0001):
            failures.append(f"{label} çarpışma yüksekliği boyut sınıfıyla eşleşmiyor.")
        if root_properties.get("collision_layer") != "4" or root_properties.get("collision_mask") != "11":
            failures.append(f"{label} duvar/kapı çarpışma katmanı standardı dışında.")
        if sprite_properties.get("shaded") != "true":
            failures.append(f"{label} karanlık sahne ışıklandırmasına bağlı değil.")
        if sprite_properties.get("cast_shadow") != "0":
            failures.append(f"{label} pahalı dinamik billboard gölgesini kapatmıyor.")
        if not shadow_block or "contact_shadow.png" not in scene:
            failures.append(f"{label} zemin temas gölgesi eksik.")
        if shadow_properties.get("cast_shadow") != "0":
            failures.append(f"{label} temas gölgesi kendi gölgesini üretmemeli.")

        sprite_position = _transform_position(sprite_properties.get("transform", ""))
        collision_position = _transform_position(collision_properties.get("transform", ""))
        shadow_position = _transform_position(shadow_properties.get("transform", ""))
        sprite_y = sprite_position[1] if sprite_position else 0.0
        collision_y = collision_position[1] if collision_position else 0.0
        shadow_y = shadow_position[1] if shadow_position else float("inf")
        sprite_floor = sprite_y - 543.0 * pixel_size * 0.5
        collision_floor = collision_y - capsule_height * 0.5
        if not math.isclose(sprite_floor, collision_floor, abs_tol=0.01):
            failures.append(
                f"{label} sprite/hitbox zemin hizası farklı: "
                f"sprite={sprite_floor:.4f} hitbox={collision_floor:.4f}"
            )
        if not 0.005 <= shadow_y - collision_floor <= 0.035:
            failures.append(f"{label} temas gölgesi zeminden kopuk veya zemine gömülü.")
        corpse_y = float(root_properties.get("corpse_visual_y", "999"))
        if not math.isclose(corpse_y, sprite_y, abs_tol=0.001):
            failures.append(f"{label} ölüm karesi zemin hizasını değiştiriyor.")
        if "navigation_clearance" in root_properties:
            clearance = float(root_properties["navigation_clearance"])
            if clearance < radius:
                failures.append(f"{label} rota açıklığı çarpışma yarıçapından küçük.")

    if not (
        geometry_standard["Ravager"]["pixel_size"]
        == geometry_standard["RedViper"]["pixel_size"]
        < geometry_standard["BadRedViper"]["pixel_size"]
        < geometry_standard["HellMagma"]["pixel_size"]
    ):
        failures.append("Düşman insan/orta/büyük görsel boyut sırası bozuk.")
    for human_scale_enemy in ("Ravager", "RedViper"):
        canvas_height = 543.0 * geometry_standard[human_scale_enemy]["pixel_size"]
        if not math.isclose(canvas_height, 1.8, abs_tol=0.001):
            failures.append(
                f"{human_scale_enemy} 543×543 tuvali 1,80 m insan boyunda değil."
            )

    door_script = (ROOT / "scripts/props/door.gd").read_text(encoding="utf-8")
    door_scene = (ROOT / "scenes/props/door.tscn").read_text(encoding="utf-8")
    opening_match = re.search(r"var opening_height := ([0-9.]+)", door_script)
    opening_height = float(opening_match.group(1)) if opening_match else 0.0
    tallest_visual = 543.0 * geometry_standard["HellMagma"]["pixel_size"]
    tallest_capsule = geometry_standard["HellMagma"]["height"]
    if opening_height < tallest_visual + 0.15 or opening_height < tallest_capsule + 0.4:
        failures.append(
            "Kapı açılma yüksekliği HellMagma için güvenli görsel/hitbox payı bırakmıyor."
        )
    panel_size_match = re.search(
        r'\[sub_resource type="BoxShape3D" id="BoxShape_door"\]\n'
        r"size = Vector3\(([0-9.]+), ([0-9.]+), ([0-9.]+)\)",
        door_scene,
    )
    panel_width = float(panel_size_match.group(3)) if panel_size_match else 0.0
    if panel_width < geometry_standard["HellMagma"]["radius"] * 2.0 + 1.5:
        failures.append("Kapı yatay açıklığı HellMagma için güvenli yan pay bırakmıyor.")
    if "collision_mask = 6" not in door_scene:
        failures.append("Kapı güvenlik sensörü oyuncu ve düşman katmanlarını izlemiyor.")

    redviper_script = enemy_files["RedViper"][0].read_text(encoding="utf-8")
    redviper_scene = enemy_files["RedViper"][1].read_text(encoding="utf-8")
    forbidden_redviper_code = {
        r"animated_sprite\.pixel_size\s*=(?!=)": "RedViper Pixel Size script tarafından eziliyor.",
        r"animated_sprite\.sprite_frames\s*=(?!=)": "RedViper SpriteFrames script tarafından eziliyor.",
        r"SpriteFrames\.new\(\)": "RedViper animasyonları çalışma anında yeniden üretiliyor.",
        r"\b_setup_sprite_frames\b": "Eski RedViper kare kurucusu scriptte kalmış.",
        r"animated_sprite\.modulate\s*=\s*Color\.WHITE": "RedViper sahne rengi beyazla eziliyor.",
    }
    for pattern, message in forbidden_redviper_code.items():
        if re.search(pattern, redviper_script):
            failures.append(message)

    required_melee_tracking_code = {
        "func _update_attack_lunge": "RedViper saldırı hamlesi işlevi eksik.",
        "direction.x * _runtime_chase_speed": "RedViper takipte ayrı takip hızını kullanmıyor.",
        "direction.x * _runtime_attack_lunge_speed": "RedViper saldırı sırasında hedefi takip etmiyor.",
        "<= attack_range + attack_range_tolerance": "RedViper darbe menzili toleransı uygulanmıyor.",
        "if _hurt_anim_locked and hurt_stops_movement": (
            "RedViper hasar reaksiyonu hareketten ayrı yönetilmiyor."
        ),
        "if _dead or _attack_locked": (
            "RedViper saldırısı hasar animasyonuyla kesilebiliyor."
        ),
    }
    for token, message in required_melee_tracking_code.items():
        if token not in redviper_script:
            failures.append(message)

    player_script = (ROOT / "scripts/player/player.gd").read_text(encoding="utf-8")
    sprint_match = re.search(
        r"^@export[^\n]*\bvar\s+sprint_speed\s*:=\s*([0-9.]+)",
        player_script,
        re.MULTILINE,
    )
    player_sprint_speed = float(sprint_match.group(1)) if sprint_match else 8.0

    for label in ("RedViper", "BadRedViper"):
        scene_text = enemy_files[label][1].read_text(encoding="utf-8")
        scene_properties = _read_root_node_properties(enemy_files[label][1])
        chase_match = re.search(r"^chase_speed\s*=\s*([0-9.]+)", scene_text, re.MULTILINE)
        lunge_match = re.search(r"^attack_lunge_speed\s*=\s*([0-9.]+)", scene_text, re.MULTILINE)
        range_match = re.search(
            r"^attack_range\s*=\s*([0-9.]+)", scene_text, re.MULTILINE
        )
        hurt_stop_match = re.search(
            r"^hurt_stops_movement\s*=\s*(\w+)", scene_text, re.MULTILINE
        )
        if not chase_match or float(chase_match.group(1)) < 5.4:
            failures.append(f"{label} varsayılan takip hızı hareketli oyuncu için yetersiz.")
        if not lunge_match or float(lunge_match.group(1)) <= player_sprint_speed:
            failures.append(f"{label} saldırı hamlesi oyuncu koşu hızını aşmıyor.")
        if not range_match or float(range_match.group(1)) < 2.0:
            failures.append(
                f"{label} saldırı başlatma menzili baskı kurmak için yetersiz."
            )
        if not hurt_stop_match or hurt_stop_match.group(1) != "false":
            failures.append(f"{label} seri ateş altında hareket etmeye devam etmiyor.")

        # Saldırı tam menzil sınırında başlarken oyuncunun düz geriye tam hız
        # koştuğu en olumsuz durumu 120 Hz'de örnekle. Darbe anında oyuncu
        # menzil toleransının dışına çıkabiliyorsa eski "sadece sabit durunca
        # vuruyor" sorunu geri dönmüş demektir.
        separation = float(scene_properties.get("attack_range", "0"))
        hit_limit = separation + float(
            scene_properties.get("attack_range_tolerance", "0")
        )
        attacker_speed = float(scene_properties.get("chase_speed", "0"))
        lunge_speed = float(scene_properties.get("attack_lunge_speed", "0"))
        lunge_acceleration = float(
            scene_properties.get("attack_lunge_acceleration", "0")
        )
        windup_remaining = float(scene_properties.get("attack_windup", "0"))
        lunge_remaining = float(
            scene_properties.get("attack_lunge_duration", "0")
        )
        while windup_remaining > 0.0:
            delta = min(1.0 / 120.0, windup_remaining)
            if lunge_remaining > 0.0:
                attacker_speed = min(
                    lunge_speed,
                    attacker_speed + lunge_acceleration * delta,
                )
                lunge_remaining = max(0.0, lunge_remaining - delta)
            else:
                attacker_speed = 0.0
            separation += (player_sprint_speed - attacker_speed) * delta
            windup_remaining -= delta
        if separation > hit_limit:
            failures.append(
                f"{label} geri koşan oyuncuya darbe ulaştıramıyor: "
                f"mesafe={separation:.2f} sınır={hit_limit:.2f}"
            )

    ravager_script = enemy_files["Ravager"][0].read_text(encoding="utf-8")
    required_ranged_pressure_code = {
        "if _attack_locked:\n\t\tstate = State.ATTACK": (
            "Ravager başlamış atışa bağlı kalmıyor."
        ),
        "func _calculate_intercept_time": (
            "Ravager hareketli hedef kesişim süresini hesaplamıyor."
        ),
        "target_velocity * travel_time * projectile_lead_factor": (
            "Ravager hareketli hedefe önleme yapmıyor."
        ),
        "<= attack_range + attack_range_tolerance": (
            "Ravager atış hazırlığı menzil toleransı uygulamıyor."
        ),
        "func _move_during_attack_recovery": (
            "Ravager/HellMagma atış sonrası hareket davranışı eksik."
        ),
        "elif _attack_windup_active:": (
            "Ravager/HellMagma saldırı hazırlığı ve hareket evrelerini ayırmıyor."
        ),
        "+ spawn_right * projectile_spawn_side_offset": (
            "Ravager mermi çıkışında yaratığa göre yatay namlu payını uygulamıyor."
        ),
    }
    for token, message in required_ranged_pressure_code.items():
        if token not in ravager_script:
            failures.append(message)
    if (
        "static var _shared_navigation_caches: Dictionary" not in ravager_script
        or 'var cache_key := "%.3f|%.3f|%d"' not in ravager_script
    ):
        failures.append(
            "Ravager/HellMagma rota önbelleği gövde açıklığına göre ayrılmıyor."
        )

    ravager_properties = _read_root_node_properties(enemy_files["Ravager"][1])
    projectile_properties = _read_root_node_properties(
        ROOT / "scenes/actors/ravager_projectile.tscn"
    )
    attack_range = float(ravager_properties.get("attack_range", "0"))
    attack_tolerance = float(
        ravager_properties.get("attack_range_tolerance", "0")
    )
    attack_windup = float(ravager_properties.get("attack_windup", "99"))
    lead_factor = float(ravager_properties.get("projectile_lead_factor", "0"))
    max_lead_time = float(
        ravager_properties.get("projectile_max_lead_time", "0")
    )
    projectile_speed = float(projectile_properties.get("speed", "0"))
    projectile_scene = (
        ROOT / "scenes/actors/ravager_projectile.tscn"
    ).read_text(encoding="utf-8")
    radius_match = re.search(
        r"^radius\s*=\s*([0-9.]+)", projectile_scene, re.MULTILINE
    )
    projectile_radius = float(radius_match.group(1)) if radius_match else 0.0
    if attack_range < 12.0:
        failures.append(
            "Ravager menzili oyuncuya düzenli atış fırsatı vermek için yetersiz."
        )
    if attack_windup * player_sprint_speed > attack_tolerance:
        failures.append(
            "Ravager atışı oyuncunun düz geri koşmasıyla hazırlık sırasında iptal oluyor."
        )
    if lead_factor < 0.9 or max_lead_time < 1.6:
        failures.append("Ravager hareketli hedef önleme ayarları yetersiz.")
    ravager_side_offset = float(
        ravager_properties.get("projectile_spawn_side_offset", "0")
    )
    ravager_approach_speed = float(
        ravager_properties.get("attack_approach_speed", "0")
    )
    ravager_strafe_speed = float(
        ravager_properties.get("attack_strafe_speed", "0")
    )
    if ravager_side_offset < 0.38:
        failures.append("Ravager mermi çıkışı kendi sağındaki namluya hizalı değil.")
    if ravager_approach_speed <= 0.0 or ravager_strafe_speed <= 0.0:
        failures.append("Ravager atışlar arasında yeniden konumlanmıyor.")
    if projectile_speed < 16.0 or projectile_radius < 0.35:
        failures.append("Ravager mermisi hareketli hedef için fazla yavaş veya küçük.")
    if projectile_speed <= player_sprint_speed:
        failures.append("Ravager mermisi koşan oyuncuyu yakalayamıyor.")
    else:
        distance_at_fire = attack_range + player_sprint_speed * attack_windup
        intercept_time = distance_at_fire / (
            projectile_speed - player_sprint_speed
        )
        predicted_lead = (
            player_sprint_speed
            * min(intercept_time, max_lead_time)
            * lead_factor
        )
        required_lead = player_sprint_speed * intercept_time
        player_radius = 0.34
        if required_lead - predicted_lead > projectile_radius + player_radius:
            failures.append(
                "Ravager mermisi düz geriye koşan oyuncunun gerisinde kalıyor."
            )

    for animation_name in (
        "idle",
        "idle_back",
        "walk",
        "walk_back",
        "attack",
        "hurt",
        "death",
    ):
        if f'"name": &"{animation_name}"' not in redviper_scene:
            failures.append(
                f"RedViper animasyonu sahne kaynağında eksik: {animation_name}"
            )

    badredviper_scene = enemy_files["BadRedViper"][1].read_text(encoding="utf-8")
    for animation_name in (
        "idle",
        "idle_back",
        "walk",
        "walk_back",
        "attack",
        "hurt",
        "death",
    ):
        if f'"name": &"{animation_name}"' not in badredviper_scene:
            failures.append(
                f"BadRedViper animasyonu sahne kaynağında eksik: {animation_name}"
            )

    hellmagma_scene = enemy_files["HellMagma"][1].read_text(encoding="utf-8")
    for animation_name in (
        "idle",
        "idle_back",
        "walk",
        "walk_back",
        "attack",
        "hurt",
        "death",
    ):
        if f'"name": &"{animation_name}"' not in hellmagma_scene:
            failures.append(
                f"HellMagma animasyonu sahne kaynağında eksik: {animation_name}"
            )
    hellmagma_properties = _read_root_node_properties(
        enemy_files["HellMagma"][1]
    )
    ravager_properties = _read_root_node_properties(enemy_files["Ravager"][1])
    for property_name in (
        "maximum_health",
        "attack_damage",
        "attack_range",
        "move_speed",
    ):
        if float(hellmagma_properties.get(property_name, "0")) <= float(
            ravager_properties.get(property_name, "0")
        ):
            failures.append(
                f"HellMagma {property_name} değeri Ravager'dan güçlü değil."
            )
    hellmagma_projectile_path = ROOT / "scenes/actors/hellmagma_projectile.tscn"
    hellmagma_projectile = _read_root_node_properties(hellmagma_projectile_path)
    for property_name in ("speed", "lifetime", "impact_surface_offset"):
        if property_name not in hellmagma_projectile:
            failures.append(
                f"HellMagma mermi Inspector ayarı kayıtlı değil: {property_name}"
            )
    hellmagma_projectile_text = hellmagma_projectile_path.read_text(encoding="utf-8")
    hellmagma_radius_match = re.search(
        r"^radius\s*=\s*([0-9.]+)",
        hellmagma_projectile_text,
        re.MULTILINE,
    )
    hellmagma_projectile_speed = float(hellmagma_projectile.get("speed", "0"))
    hellmagma_projectile_radius = (
        float(hellmagma_radius_match.group(1)) if hellmagma_radius_match else 0.0
    )
    if hellmagma_projectile_speed <= projectile_speed:
        failures.append("HellMagma mermisi Ravager mermisinden hızlı değil.")
    if hellmagma_projectile_radius <= projectile_radius:
        failures.append("HellMagma mermisi Ravager mermisinden büyük değil.")
    hellmagma_windup = float(hellmagma_properties.get("attack_windup", "99"))
    hellmagma_tolerance = float(
        hellmagma_properties.get("attack_range_tolerance", "0")
    )
    if hellmagma_windup * player_sprint_speed > hellmagma_tolerance:
        failures.append(
            "HellMagma atışı oyuncunun geri koşmasıyla hazırlık sırasında iptal oluyor."
        )
    if float(hellmagma_properties.get("projectile_lead_factor", "0")) < 1.0:
        failures.append("HellMagma hareketli hedefe tam önleme uygulamıyor.")
    hellmagma_approach_speed = float(
        hellmagma_properties.get("attack_approach_speed", "0")
    )
    hellmagma_strafe_speed = float(
        hellmagma_properties.get("attack_strafe_speed", "0")
    )
    hellmagma_preferred_distance = float(
        hellmagma_properties.get("attack_preferred_distance", "99")
    )
    if hellmagma_approach_speed < 2.4:
        failures.append("HellMagma atışlar arasında oyuncuya yeterince yaklaşmıyor.")
    if hellmagma_strafe_speed < 1.0:
        failures.append("HellMagma atışlar arasında yan hareket yapmıyor.")
    if hellmagma_preferred_distance >= float(
        hellmagma_properties.get("attack_range", "0")
    ):
        failures.append("HellMagma tercih mesafesi atış menzilinden küçük değil.")


def _check_performance_package(failures: list[str]) -> None:
    """Kapalı alan görünürlüğü, ışık LOD'u ve çalışma zamanı bütçesini doğrula."""
    project_config = (ROOT / "project.godot").read_text(encoding="utf-8")
    if "occlusion_culling/use_occlusion_culling=true" not in project_config:
        failures.append("Proje oklüzyon ayarı etkin değil.")

    world_scene = (ROOT / "scenes/world/world_piece.tscn").read_text(
        encoding="utf-8"
    )
    world_script = (ROOT / "scripts/world/world_piece.gd").read_text(
        encoding="utf-8"
    )
    for token in (
        '[sub_resource type="BoxOccluder3D"',
        '[node name="OccluderInstance3D" type="OccluderInstance3D"',
        "target_occluder.visible = occlusion_enabled and is_wall_like",
        "box_occluder.size = piece_size",
    ):
        if token not in world_scene and token not in world_script:
            failures.append("WorldPiece oklüzyon standardı eksik: " + token)

    door_scene = (ROOT / "scenes/props/door.tscn").read_text(encoding="utf-8")
    door_script = (ROOT / "scripts/props/door.gd").read_text(encoding="utf-8")
    if '[node name="DoorOccluder" type="OccluderInstance3D"' not in door_scene:
        failures.append("Kapalı kapı oklüderi eksik.")
    if "door_occluder.visible = _state == DoorState.CLOSED" not in door_script:
        failures.append("Kapı oklüderi kapı durumuyla eşzamanlanmıyor.")

    light_scenes = {
        "Kırmızı duvar lambası": ROOT / "scenes/world/wall_lamp_red.tscn",
        "Ravager mermisi": ROOT / "scenes/actors/ravager_projectile.tscn",
        "HellMagma mermisi": ROOT / "scenes/actors/hellmagma_projectile.tscn",
        "Varil patlaması": ROOT / "scenes/props/explosive_barrel.tscn",
    }
    for label, scene_path in light_scenes.items():
        scene = scene_path.read_text(encoding="utf-8")
        if "distance_fade_enabled = true" not in scene:
            failures.append(f"{label} uzaklık LOD'u etkin değil.")
    for projectile_path in (
        ROOT / "scenes/actors/ravager_projectile.tscn",
        ROOT / "scenes/actors/hellmagma_projectile.tscn",
    ):
        light_block = _read_named_node_block(
            projectile_path.read_text(encoding="utf-8"), "Light"
        )
        if "shadow_enabled = false" not in light_block:
            failures.append(
                f"Mermi ışığı dinamik gölge üretiyor: {projectile_path.relative_to(ROOT)}"
            )

    enemy_scenes = {
        "Ravager": ROOT / "scenes/actors/ravager.tscn",
        "HellMagma": ROOT / "scenes/actors/hellmagma.tscn",
        "RedViper": ROOT / "scenes/actors/redviper.tscn",
        "BadRedViper": ROOT / "scenes/actors/badredviper.tscn",
    }
    for label, scene_path in enemy_scenes.items():
        properties = _read_root_node_properties(scene_path)
        dormant_distance = float(properties.get("dormant_distance", "0"))
        pursuit_range = float(properties.get("pursuit_range", "999"))
        if dormant_distance <= pursuit_range:
            failures.append(
                f"{label} uyku mesafesi takip menzilinden büyük değil."
            )
        if float(properties.get("near_sight_interval", "0")) <= 0.0:
            failures.append(f"{label} aralıklı görüş ayarı geçersiz.")

    ravager_script = (ROOT / "scripts/actors/ravager.gd").read_text(
        encoding="utf-8"
    )
    redviper_script = (ROOT / "scripts/actors/redviper.gd").read_text(
        encoding="utf-8"
    )
    for label, script in (("Ravager", ravager_script), ("Viper", redviper_script)):
        for function_name in (
            "_should_use_dormant_mode",
            "_enter_dormant_mode",
            "_apply_dormant_physics",
        ):
            if f"func {function_name}" not in script:
                failures.append(f"{label} performans işlevi eksik: {function_name}")
    if "func _get_cached_player_visibility" not in redviper_script:
        failures.append("Viper görüş ışını önbelleği eksik.")

    settings_script = (ROOT / "scripts/autoload/settings_manager.gd").read_text(
        encoding="utf-8"
    )
    settings_panel = (ROOT / "scenes/ui/settings_panel.tscn").read_text(
        encoding="utf-8"
    )
    for token in (
        "enum GraphicsQuality",
        "root_viewport.scaling_3d_scale = get_graphics_quality_scale()",
        "return 0.75",
        "return 0.85",
        "return 1.0",
    ):
        if token not in settings_script:
            failures.append("3B kalite profili eksik: " + token)
    if 'name="GraphicsQualityOption"' not in settings_panel:
        failures.append("Ayarlar sahnesinde 3B kalite seçimi eksik.")

    hud_script = (ROOT / "scripts/ui/hud.gd").read_text(encoding="utf-8")
    if "world_ui_sample_interval" not in hud_script or "_update_world_ui_sample" not in hud_script:
        failures.append("HUD dünya sorguları performans aralığıyla örneklenmiyor.")


def _check_balance_matrix(failures: list[str]) -> None:
    """İki bölümün düşman rolü, zorluk ve mühimmat bütçesini doğrula."""
    role_scenes = {
        "ravager": ROOT / "scenes/actors/ravager.tscn",
        "hellmagma": ROOT / "scenes/actors/hellmagma.tscn",
        "redviper": ROOT / "scenes/actors/redviper.tscn",
        "badredviper": ROOT / "scenes/actors/badredviper.tscn",
    }
    expected_role_stats = {
        "ravager": {"maximum_health": 75, "attack_damage": 14},
        "hellmagma": {"maximum_health": 240, "attack_damage": 28},
        "redviper": {"maximum_health": 140, "attack_damage": 22},
        "badredviper": {"maximum_health": 190, "attack_damage": 28},
    }
    role_properties: dict[str, dict[str, str]] = {}
    for role, scene_path in role_scenes.items():
        properties = _read_root_node_properties(scene_path)
        role_properties[role] = properties
        for property_name, expected_value in expected_role_stats[role].items():
            actual_value = int(float(properties.get(property_name, "-1")))
            if actual_value != expected_value:
                failures.append(
                    f"{role} rol dengesi yanlış: {property_name} "
                    f"beklenen={expected_value} gerçek={actual_value}"
                )

    red_chase = float(role_properties["redviper"].get("chase_speed", "0"))
    bad_chase = float(role_properties["badredviper"].get("chase_speed", "0"))
    red_lunge = float(role_properties["redviper"].get("attack_lunge_speed", "0"))
    bad_lunge = float(role_properties["badredviper"].get("attack_lunge_speed", "0"))
    if bad_chase <= red_chase or bad_lunge <= red_lunge:
        failures.append("BadRedViper elit takip ve hamle hızları RedViper'dan yüksek olmalı.")

    expected_distributions = {
        "scenes/levels/level_01.tscn": [
            {"ravager": 10, "hellmagma": 1, "redviper": 0, "badredviper": 0},
            {"ravager": 16, "hellmagma": 1, "redviper": 1, "badredviper": 0},
            {"ravager": 20, "hellmagma": 1, "redviper": 2, "badredviper": 0},
            {"ravager": 24, "hellmagma": 1, "redviper": 3, "badredviper": 0},
        ],
        "scenes/levels/level_02.tscn": [
            {"ravager": 11, "hellmagma": 0, "redviper": 2, "badredviper": 1},
            {"ravager": 15, "hellmagma": 0, "redviper": 3, "badredviper": 2},
            {"ravager": 20, "hellmagma": 0, "redviper": 3, "badredviper": 3},
            {"ravager": 24, "hellmagma": 0, "redviper": 3, "badredviper": 4},
        ],
    }
    expected_profiles = (
        {
            "health_multiplier": 0.75,
            "damage_multiplier": 0.65,
            "speed_multiplier": 0.90,
            "resource_multiplier": 1.35,
        },
        {
            "health_multiplier": 1.0,
            "damage_multiplier": 1.0,
            "speed_multiplier": 1.0,
            "resource_multiplier": 1.0,
        },
        {
            "health_multiplier": 1.20,
            "damage_multiplier": 1.25,
            "speed_multiplier": 1.08,
            "resource_multiplier": 0.80,
        },
        {
            "health_multiplier": 1.45,
            "damage_multiplier": 1.55,
            "speed_multiplier": 1.15,
            "resource_multiplier": 0.60,
        },
    )
    actual_profiles = _read_difficulty_profiles()
    if len(actual_profiles) != 4:
        failures.append("Dört zorluk profilinin denge değerleri okunamadı.")
        actual_profiles = list(expected_profiles)
    else:
        for difficulty, expected_profile in enumerate(expected_profiles):
            for key, expected_value in expected_profile.items():
                actual_value = actual_profiles[difficulty].get(key, -1.0)
                if not math.isclose(actual_value, expected_value, abs_tol=0.0001):
                    failures.append(
                        f"Zorluk profili yanlış: zorluk={difficulty} {key} "
                        f"beklenen={expected_value} gerçek={actual_value}"
                    )
    health_multipliers = tuple(
        profile["health_multiplier"] for profile in expected_profiles
    )
    resource_multipliers = tuple(
        profile["resource_multiplier"] for profile in expected_profiles
    )
    minimum_core_damage_ratios = {
        "scenes/levels/level_01.tscn": (2.0, 2.0, 1.45, 0.85),
        # VEX-02 Zor/Kâbus, bölümdeki AK-47 ve MP90 kaynaklarını kullanmayı
        # teşvik eder; yalnız tabanca + pompalı bütçesi yine de güvenli tabanın
        # altına düşmemelidir.
        "scenes/levels/level_02.tscn": (2.0, 2.0, 1.17, 0.68),
    }

    for relative_path, expected_by_difficulty in expected_distributions.items():
        enemy_nodes = _read_instanced_nodes(relative_path, "Enemies")
        pickup_nodes = _read_instanced_nodes(relative_path, "Pickups")
        _validate_level_spawn_geometry(relative_path, enemy_nodes, failures)
        for difficulty, expected in enumerate(expected_by_difficulty):
            composition = {role: 0 for role in role_scenes}
            enemy_health_pool = 0
            for enemy in enemy_nodes:
                minimum_difficulty = int(enemy["properties"].get("spawn_min_difficulty", "0"))
                if minimum_difficulty > difficulty:
                    continue
                role = Path(enemy["resource_path"]).stem
                if role not in composition:
                    failures.append(
                        f"Bilinmeyen düşman sahnesi: {relative_path} > {enemy['name']}"
                    )
                    continue
                composition[role] += 1
                base_health = int(float(
                    enemy["properties"].get(
                        "maximum_health",
                        role_properties[role].get("maximum_health", "0"),
                    )
                ))
                enemy_health_pool += _round_positive(
                    base_health * health_multipliers[difficulty]
                )

            if composition != expected:
                failures.append(
                    f"Düşman dağılımı yanlış: {relative_path} zorluk={difficulty} "
                    f"beklenen={expected} gerçek={composition}"
                )

            pickup_amounts = _active_pickup_amounts(
                pickup_nodes,
                difficulty,
                resource_multipliers[difficulty],
            )
            shotgun_bonus = pickup_amounts.get("shotgun", 0)
            if shotgun_bonus < 8:
                failures.append(
                    f"Pompalı başlangıç desteği yetersiz: {relative_path} "
                    f"zorluk={difficulty} fişek={shotgun_bonus}"
                )

            pistol_rounds = 60 + pickup_amounts.get("bullets", 0)
            shotgun_rounds = 6 + shotgun_bonus + pickup_amounts.get("shells", 0)
            core_damage_budget = pistol_rounds * 18 + shotgun_rounds * (8 * 11)
            core_ratio = (
                float(core_damage_budget) / float(enemy_health_pool)
                if enemy_health_pool > 0 else 0.0
            )
            required_ratio = minimum_core_damage_ratios[relative_path][difficulty]
            if core_ratio < required_ratio:
                failures.append(
                    f"Temel mühimmat bütçesi düşük: {relative_path} zorluk={difficulty} "
                    f"oran={core_ratio:.2f} alt_sınır={required_ratio:.2f}"
                )

            if relative_path.endswith("level_02.tscn") and difficulty == 3:
                ak_rounds = (
                    30
                    + pickup_amounts.get("ak47", 0)
                    + pickup_amounts.get("rifle_ammo", 0)
                )
                mp90_rounds = (
                    50
                    + pickup_amounts.get("mp90", 0)
                    + pickup_amounts.get("mp90_ammo", 0)
                )
                full_damage_budget = (
                    core_damage_budget
                    + ak_rounds * 14
                    + mp90_rounds * 10
                )
                full_ratio = float(full_damage_budget) / float(enemy_health_pool)
                if full_ratio < 1.35:
                    failures.append(
                        "VEX-02 Kâbus tam keşif mühimmat bütçesi yetersiz: "
                        f"oran={full_ratio:.2f}"
                    )

    level_02_text = (ROOT / "scenes/levels/level_02.tscn").read_text(encoding="utf-8")
    if 'required_enemy_id = &"v2_badredviper_final_guard"' not in level_02_text:
        failures.append("VEX-02 final BadRedViper muhafız bağlantısı eksik.")
    if 'enemy_id = &"v2_ravager_final_guard"' in level_02_text:
        failures.append("VEX-02 eski Ravager final muhafız kimliği kalmış.")


def _read_root_node_properties(scene_path: Path) -> dict[str, str]:
    text = scene_path.read_text(encoding="utf-8")
    root_match = re.search(
        r'^\[node name="[^"]+" type="[^"]+"\]\n(.*?)(?=^\[node|\Z)',
        text,
        re.MULTILINE | re.DOTALL,
    )
    if root_match is None:
        return {}
    return dict(re.findall(r"^([A-Za-z_][A-Za-z0-9_]*) = (.+)$", root_match.group(1), re.MULTILINE))


def _read_named_node_block(scene_text: str, node_name: str) -> str:
    node_match = re.search(
        rf'^\[node name="{re.escape(node_name)}"[^\]]*\]\n(.*?)(?=^\[node|\Z)',
        scene_text,
        re.MULTILINE | re.DOTALL,
    )
    return node_match.group(1) if node_match is not None else ""


def _read_instanced_nodes(relative_path: str, parent_name: str) -> list[dict[str, object]]:
    text = (ROOT / relative_path).read_text(encoding="utf-8")
    resources = {
        resource_id: resource_path
        for resource_path, resource_id in re.findall(
            r'^\[ext_resource[^\]]*\bpath="([^"]+)"[^\]]*\bid="([^"]+)"\]',
            text,
            re.MULTILINE,
        )
    }
    nodes: list[dict[str, object]] = []
    for section in re.finditer(
        r'^\[node ([^\]]+)\]\n(.*?)(?=^\[|\Z)',
        text,
        re.MULTILINE | re.DOTALL,
    ):
        header = section.group(1)
        name_match = re.search(r'\bname="([^"]+)"', header)
        parent_match = re.search(r'\bparent="([^"]+)"', header)
        instance_match = re.search(r'\binstance=ExtResource\("([^"]+)"\)', header)
        if (
            name_match is None
            or parent_match is None
            or instance_match is None
            or parent_match.group(1) != parent_name
        ):
            continue
        resource_id = instance_match.group(1)
        nodes.append({
            "name": name_match.group(1),
            "resource_path": resources.get(resource_id, ""),
            "properties": dict(re.findall(
                r"^([A-Za-z_][A-Za-z0-9_]*) = (.+)$",
                section.group(2),
                re.MULTILINE,
            )),
        })
    return nodes


def _active_pickup_amounts(
    pickup_nodes: list[dict[str, object]],
    difficulty: int,
    resource_multiplier: float,
) -> dict[str, int]:
    totals: dict[str, int] = {}
    unscaled_types = {
        "shotgun", "ak47", "mp90", "night_vision", "key_blue", "key_red",
    }
    for pickup in pickup_nodes:
        properties = pickup["properties"]
        maximum_difficulty = int(properties.get("spawn_max_difficulty", "3"))
        if maximum_difficulty < difficulty:
            continue
        pickup_type = properties.get("pickup_type", '"health"').strip('"')
        amount = int(properties.get("amount", "25"))
        scales = properties.get("scale_amount_with_difficulty", "true") != "false"
        if scales and pickup_type not in unscaled_types:
            amount = max(1, _round_positive(amount * resource_multiplier))
        totals[pickup_type] = totals.get(pickup_type, 0) + amount
    return totals


def _round_positive(value: float) -> int:
    return int(math.floor(value + 0.5))


def _read_difficulty_profiles() -> list[dict[str, float]]:
    text = (ROOT / "scripts/autoload/settings_manager.gd").read_text(encoding="utf-8")
    function_match = re.search(
        r"^func get_difficulty_profile\(.*?\n(.*?)(?=^func |\Z)",
        text,
        re.MULTILINE | re.DOTALL,
    )
    if function_match is None:
        return []
    function_body = function_match.group(1)
    labels = ("Difficulty.EASY", "_", "Difficulty.HARD", "Difficulty.NIGHTMARE")
    profiles: list[dict[str, float]] = []
    for label in labels:
        label_pattern = re.escape(label)
        block_match = re.search(
            rf"^\s*{label_pattern}:\s*\n\s*return\s*\{{(.*?)^\s*\}}",
            function_body,
            re.MULTILINE | re.DOTALL,
        )
        if block_match is None:
            return []
        profiles.append({
            key: float(value)
            for key, value in re.findall(
                r'"([A-Za-z_][A-Za-z0-9_]*)":\s*([0-9.]+)',
                block_match.group(1),
            )
        })
    return profiles


def _validate_level_spawn_geometry(
    relative_path: str,
    enemy_nodes: list[dict[str, object]],
    failures: list[str],
) -> None:
    level_name = Path(relative_path).stem
    script_path = ROOT / "scripts/levels" / f"{level_name}.gd"
    script = script_path.read_text(encoding="utf-8")
    columns_match = re.search(r'"columns":\s*(\d+)', script)
    rows_match = re.search(r'"rows":\s*(\d+)', script)
    minimum_match = re.search(
        r'"world_min":\s*Vector2\(([-0-9.]+),\s*([-0-9.]+)\)',
        script,
    )
    maximum_match = re.search(
        r'"world_max":\s*Vector2\(([-0-9.]+),\s*([-0-9.]+)\)',
        script,
    )
    cell_block = re.search(
        r"const AUTOMAP_WALKABLE_CELLS[^=]*=\s*\[(.*?)\]",
        script,
        re.DOTALL,
    )
    if not all((columns_match, rows_match, minimum_match, maximum_match, cell_block)):
        failures.append(f"Düşman konum denetimi için harita verisi eksik: {relative_path}")
        return

    columns = int(columns_match.group(1))
    rows = int(rows_match.group(1))
    world_min = (float(minimum_match.group(1)), float(minimum_match.group(2)))
    world_max = (float(maximum_match.group(1)), float(maximum_match.group(2)))
    walkable_cells = {
        (int(x), int(y))
        for x, y in re.findall(r"Vector2i\((\d+),\s*(\d+)\)", cell_block.group(1))
    }
    positions: list[tuple[str, float, float]] = []
    for enemy in enemy_nodes:
        position = _transform_position(enemy["properties"].get("transform", ""))
        if position is None:
            failures.append(f"Düşman konumu okunamadı: {relative_path} > {enemy['name']}")
            continue
        x, _y, z = position
        if not (world_min[0] <= x < world_max[0] and world_min[1] <= z < world_max[1]):
            failures.append(f"Düşman harita sınırı dışında: {relative_path} > {enemy['name']}")
            continue
        column = int((x - world_min[0]) / (world_max[0] - world_min[0]) * columns)
        row = int((z - world_min[1]) / (world_max[1] - world_min[1]) * rows)
        if (column, row) not in walkable_cells:
            failures.append(
                f"Düşman yürünebilir hücre dışında: {relative_path} > "
                f"{enemy['name']} hücre=({column}, {row})"
            )
        positions.append((str(enemy["name"]), x, z))

    for first_index, first in enumerate(positions):
        for second in positions[first_index + 1:]:
            if math.hypot(first[1] - second[1], first[2] - second[2]) < 1.8:
                failures.append(
                    f"Düşman başlangıç çarpışması riski: {relative_path} > "
                    f"{first[0]} / {second[0]}"
                )

    player_nodes = [
        node for node in _read_instanced_nodes(relative_path, ".")
        if Path(str(node["resource_path"])).stem == "player"
    ]
    if len(player_nodes) != 1:
        failures.append(f"Oyuncu başlangıcı tekil değil: {relative_path}")
        return
    player_position = _transform_position(player_nodes[0]["properties"].get("transform", ""))
    if player_position is None:
        failures.append(f"Oyuncu başlangıç konumu okunamadı: {relative_path}")
        return
    for enemy_name, x, z in positions:
        distance = math.hypot(x - player_position[0], z - player_position[2])
        if distance < 5.0:
            failures.append(
                f"Düşman oyuncu başlangıcına fazla yakın: {relative_path} > "
                f"{enemy_name} mesafe={distance:.2f}"
            )


def _transform_position(value: object) -> tuple[float, float, float] | None:
    transform_match = re.search(r"Transform3D\((.*)\)", str(value))
    if transform_match is None:
        return None
    numbers = re.findall(
        r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:e[-+]?\d+)?",
        transform_match.group(1),
        re.IGNORECASE,
    )
    if len(numbers) != 12:
        return None
    return float(numbers[9]), float(numbers[10]), float(numbers[11])


if __name__ == "__main__":
    raise SystemExit(main())
