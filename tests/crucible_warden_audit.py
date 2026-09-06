#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []


def fail(message: str) -> None:
    ERRORS.append(message)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        fail(f"Eksik Crucible Warden dosyası: {relative}")
        return ""
    return path.read_text(encoding="utf-8")


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"Crucible Warden sözleşmesi eksik: {label}")


def check_res_paths(relative: str, text: str) -> None:
    for resource in re.findall(r'res://[^"\'\s\)\]]+', text):
        resource = resource.rstrip(";,")
        if not (ROOT / resource.removeprefix("res://")).exists():
            fail(f"Kırık Crucible Warden res:// referansı: {relative} -> {resource}")


def main() -> int:
    character_manifest_path = "assets/enemies/crucible_warden/crucible_warden_character_spritesheet_manifest.json"
    effects_manifest_path = "assets/enemies/crucible_warden/crucible_warden_effects_spritesheet_manifest.json"
    character_sheet = "assets/enemies/crucible_warden/crucible_warden_character_spritesheet.png"
    effects_sheet = "assets/enemies/crucible_warden/crucible_warden_effects_spritesheet.png"
    for path in [
        character_sheet,
        effects_sheet,
        f"{character_sheet}.import",
        f"{effects_sheet}.import",
    ]:
        if not (ROOT / path).exists():
            fail(f"Eksik Crucible Warden asseti: {path}")

    try:
        character = json.loads(read(character_manifest_path))
        if character.get("sheet_size") != {"width": 2048, "height": 5376}:
            fail("Crucible Warden character sheet 2048x5376 değil")
        if character.get("frame_size") != {"width": 512, "height": 768}:
            fail("Crucible Warden character frame ölçüsü 512x768 değil")
        if character.get("grid") != {"columns": 4, "rows": 7}:
            fail("Crucible Warden character grid'i 4x7 değil")
        rows = {row.get("animation"): row.get("row_index") for row in character.get("rows", [])}
        expected = {
            "idle": 0,
            "walk": 1,
            "attack": 2,
            "heatwave": 3,
            "death": 4,
            "idle_back": 5,
            "walk_back": 6,
        }
        if rows != expected:
            fail(f"Crucible Warden character animasyon satırları bozuk: {rows}")
    except json.JSONDecodeError as exc:
        fail(f"Crucible Warden character manifest JSON bozuk: {exc}")

    try:
        effects = json.loads(read(effects_manifest_path))
        if effects.get("sheet_size") != {"width": 1024, "height": 512}:
            fail("Crucible Warden effects sheet 1024x512 değil")
        if effects.get("frame_size") != {"width": 256, "height": 256}:
            fail("Crucible Warden effect frame ölçüsü 256x256 değil")
        if effects.get("grid") != {"columns": 4, "rows": 2}:
            fail("Crucible Warden effects grid'i 4x2 değil")
        effect_rows = {row.get("animation"): row.get("row_index") for row in effects.get("rows", [])}
        if effect_rows != {"heatwave_projectile": 0, "decal": 1}:
            fail(f"Crucible Warden effect satırları bozuk: {effect_rows}")
    except json.JSONDecodeError as exc:
        fail(f"Crucible Warden effects manifest JSON bozuk: {exc}")

    warden_script_path = "scripts/actors/crucible_warden.gd"
    settings_script_path = "scripts/actors/warden_ability_settings.gd"
    projectile_script_path = "scripts/actors/crucible_warden_heatwave_projectile.gd"
    slam_script_path = "scripts/effects/crucible_warden_ground_slam.gd"
    warden_scene_path = "scenes/actors/crucible_warden.tscn"
    projectile_scene_path = "scenes/actors/crucible_warden_heatwave_projectile.tscn"
    slam_scene_path = "scenes/effects/crucible_warden_ground_slam.tscn"

    warden_script = read(warden_script_path)
    settings_script = read(settings_script_path)
    projectile_script = read(projectile_script_path)
    slam_script = read(slam_script_path)
    warden_scene = read(warden_scene_path)
    projectile_scene = read(projectile_scene_path)
    slam_scene = read(slam_scene_path)

    for path, text in [
        (warden_script_path, warden_script),
        (settings_script_path, settings_script),
        (projectile_script_path, projectile_script),
        (slam_script_path, slam_script),
        (warden_scene_path, warden_scene),
        (projectile_scene_path, projectile_scene),
        (slam_scene_path, slam_scene),
    ]:
        check_res_paths(path, text)

    for needle, label in [
        ('extends "res://scripts/actors/enemy_combatant_base.gd"', "standart combatant tabanı"),
        ("if heatwave_ready:", "Heatwave önceliği"),
        ("_close_for_heatwave(_ability.heatwave_approach_speed_multiplier)", "Heatwave için oyuncuya kadar kapanma"),
        ("var _ability: VexWardenAbilitySettings", "tip güvenli Warden ayar kaynağı"),
        ("_begin_heatwave_attack()", "Heatwave saldırı coroutine"),
        ("_begin_ground_slam_attack()", "Ground Slam saldırı coroutine"),
        ("var angular_step := TAU / float(projectile_count)", "360 derece eşit yayılım"),
        ("apply_heatwave_projectile_hit(", "tek burst hasar dedupe"),
        ("_last_heatwave_player_hit_generation", "Heatwave tek vuruş koruması"),
    ]:
        require(warden_script, needle, label)

    for needle, label in [
        ("ground_slam_trigger_range := 5.2", "Ground Slam yakın menzil seçimi"),
        ("ground_slam_radius := 4.6", "Ground Slam AoE radius"),
        ("ground_slam_damage := 42", "Ground Slam yüksek hasar"),
        ("heatwave_trigger_range := 1.65", "Heatwave point-blank menzil"),
        ("heatwave_projectile_count := 12", "12 yönlü radyal Heatwave"),
    ]:
        require(settings_script, needle, label)

    for needle, label in [
        ("damage_radius := 4.6", "Ground Slam effect radius"),
        ("damage := 42", "Ground Slam effect damage"),
        ("VexEnemyRuntimeUtils.horizontal_distance", "Ground Slam mesafe kontrolü"),
        ("_has_clear_path_to_player(player)", "Ground Slam duvar arkasına hasar vermeme"),
        ("@onready var decal_visual: AnimatedSprite3D = $DecalVisual", "Ground Slam canonical decal görseli"),
        ("visual_reference_radius := 4.6", "Ground Slam decal ölçek referansı"),
        ('tween.parallel().tween_property(\n\t\tdecal_visual,', "Ground Slam decal büyüme tween'i"),
    ]:
        require(slam_script, needle, label)

    for needle, label in [
        ("speed := 8.5", "Heatwave projectile hız"),
        ("lifetime := 1.45", "Heatwave projectile yaşam süresi"),
        ("PhysicsRayQueryParameters3D.create", "yüksek hız ray collision"),
        ('add_to_group("projectile")', "projectile temizleme grubu"),
        ('damage_source.has_method("apply_heatwave_projectile_hit")', "Warden burst dedupe callback"),
    ]:
        require(projectile_script, needle, label)

    for animation in ["idle", "walk", "attack", "heatwave", "death", "idle_back", "walk_back"]:
        require(warden_scene, f'&"{animation}"', f"character animation {animation}")
    require(warden_scene, 'enemy_id = &"crucible_warden"', "canonical enemy id")
    require(warden_scene, 'region = Rect2(0, 2304, 512, 768)', "character heatwave row başlangıcı")
    require(warden_scene, 'region = Rect2(1536, 2304, 512, 768)', "character heatwave row son frame")
    require(warden_scene, "pixel_size = 0.0042666667", "canonical character world scale")
    require(warden_scene, '[node name="HeatwaveOrigin" type="Marker3D" parent="."', "Heatwave merkez marker")

    for x in [0, 256, 512, 768]:
        require(projectile_scene, f"region = Rect2({x}, 0, 256, 256)", f"Heatwave projectile frame x={x}")
    require(projectile_scene, "pixel_size = 0.0056", "Heatwave world-space visual size")
    require(projectile_scene, "collision_mask = 3", "Heatwave dünya + oyuncu collision")

    require(slam_scene, '[node name="DecalVisual" type="AnimatedSprite3D" parent="."]', "Ground Slam decal node")
    require(slam_scene, 'region = Rect2(0, 256, 256, 256)', "Ground Slam decal ilk frame")
    require(slam_scene, 'region = Rect2(768, 256, 256, 256)', "Ground Slam decal son frame")
    require(slam_scene, "pixel_size = 0.0359375", "Ground Slam decal 4.6m radius görsel ölçeği")
    require(slam_scene, '[node name="Ring" type="MeshInstance3D" parent="."]', "Ground Slam procedural halka")
    require(slam_scene, '[node name="ImpactLight" type="OmniLight3D" parent="."]', "Ground Slam impact ışığı")

    if ERRORS:
        print("Crucible Warden audit FAILED:")
        for error in ERRORS:
            print(f" - {error}")
        return 1
    print("Crucible Warden audit OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
