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
        fail(f"Eksik Furnice dosyası: {relative}")
        return ""
    return path.read_text(encoding="utf-8")


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"Furnice sözleşmesi eksik: {label}")


def check_res_paths(relative: str, text: str) -> None:
    for resource in re.findall(r'res://[^"\'\s\)\]]+', text):
        resource = resource.rstrip(";,")
        if not (ROOT / resource.removeprefix("res://")).exists():
            fail(f"Kırık Furnice res:// referansı: {relative} -> {resource}")


def main() -> int:
    character_manifest_path = "assets/enemies/furnice_carrier/furnace_carrier_character_spritesheet_manifest.json"
    effects_manifest_path = "assets/enemies/furnice_carrier/furnace_carrier_effects_spritesheet_manifest.json"
    character_sheet = "assets/enemies/furnice_carrier/furnace_carrier_character_spritesheet.png"
    effects_sheet = "assets/enemies/furnice_carrier/furnace_carrier_effects_spritesheet.png"

    for path in [character_sheet, effects_sheet, f"{character_sheet}.import", f"{effects_sheet}.import"]:
        if not (ROOT / path).exists():
            fail(f"Eksik Furnice asseti: {path}")

    try:
        character = json.loads(read(character_manifest_path))
        if character.get("sheet_size") != {"width": 3072, "height": 3584}:
            fail("Furnace Carrier character sheet 3072x3584 değil")
        if character.get("frame_size") != {"width": 768, "height": 512}:
            fail("Furnace Carrier character frame ölçüsü 768x512 değil")
        if character.get("grid") != {"columns": 4, "rows": 7}:
            fail("Furnace Carrier character grid'i 4x7 değil")
        rows = {row.get("animation"): row.get("row_index") for row in character.get("rows", [])}
        expected_rows = {
            "idle": 0,
            "walk": 1,
            "attack": 2,
            "thermal_burst": 3,
            "death": 4,
            "idle_back": 5,
            "walk_back": 6,
        }
        if rows != expected_rows:
            fail(f"Furnace Carrier character animasyon satırları bozuk: {rows}")
    except json.JSONDecodeError as exc:
        fail(f"Furnace Carrier character manifest JSON bozuk: {exc}")

    try:
        effects = json.loads(read(effects_manifest_path))
        if effects.get("sheet_size") != {"width": 1024, "height": 1024}:
            fail("Furnace Carrier effects sheet 1024x1024 değil")
        if effects.get("frame_size") != {"width": 256, "height": 256}:
            fail("Furnace Carrier effect frame ölçüsü 256x256 değil")
        if effects.get("grid") != {"columns": 4, "rows": 4}:
            fail("Furnace Carrier effects grid'i 4x4 değil")
        effect_rows = {row.get("animation"): row.get("row_index") for row in effects.get("rows", [])}
        expected_effect_rows = {"projectile": 0, "impact": 1, "shockwave": 2, "decal": 3}
        if effect_rows != expected_effect_rows:
            fail(f"Furnace Carrier effect animasyon satırları bozuk: {effect_rows}")
    except json.JSONDecodeError as exc:
        fail(f"Furnace Carrier effects manifest JSON bozuk: {exc}")

    carrier_script_path = "scripts/actors/furnice_carrier.gd"
    settings_script_path = "scripts/actors/furnice_carrier_ability_settings.gd"
    projectile_script_path = "scripts/actors/furnice_carrier_projectile.gd"
    decal_script_path = "scripts/effects/furnice_carrier_decal.gd"
    shockwave_script_path = "scripts/effects/furnice_carrier_shockwave.gd"
    carrier_scene_path = "scenes/actors/furnice_carrier.tscn"
    projectile_scene_path = "scenes/actors/furnice_carrier_projectile.tscn"
    decal_scene_path = "scenes/effects/furnice_carrier_decal.tscn"
    shockwave_scene_path = "scenes/effects/furnice_carrier_shockwave.tscn"

    carrier_script = read(carrier_script_path)
    settings_script = read(settings_script_path)
    projectile_script = read(projectile_script_path)
    decal_script = read(decal_script_path)
    shockwave_script = read(shockwave_script_path)
    carrier_scene = read(carrier_scene_path)
    projectile_scene = read(projectile_scene_path)
    decal_scene = read(decal_scene_path)
    shockwave_scene = read(shockwave_scene_path)

    for path, text in [
        (settings_script_path, settings_script),
        (carrier_scene_path, carrier_scene),
        (projectile_scene_path, projectile_scene),
        (decal_scene_path, decal_scene),
        (shockwave_scene_path, shockwave_scene),
    ]:
        check_res_paths(path, text)

    for needle, label in [
        ('var _ability: VexFurniceCarrierAbilitySettings', "tip güvenli Furnice ayar kaynağı"),
        ('_fire_furnice_projectile()', "projectile saldırısı"),
        ('_emit_thermal_burst()', "thermal saldırısı"),
        ('_ability.projectile_muzzle_sprite_offset_pixels', "furnace ağzı sprite-pixel anchor kullanımı"),
        ('camera.global_transform.basis.x', "billboard kamera-sağ muzzle ekseni"),
        ('animated_sprite.global_position', "muzzle sprite merkezi tabanı"),
        ('func _projectile_muzzle_world_position()', "sprite-pixel muzzle dönüşümü"),
    ]:
        require(carrier_script, needle, label)

    for needle, label in [
        ('close_attack_threshold := 6.0', "6 m saldırı eşiği"),
        ('projectile_muzzle_sprite_offset_pixels := Vector2(0.0, -208.5)', "canonical 768x512 furnace ağzı anchor"),
        ('thermal_burst_damage := 22', "thermal temel hasarı"),
    ]:
        require(settings_script, needle, label)

    for needle, label in [
        ('speed := 14.0', "projectile 14 m/s"),
        ('var _direct_damage := 18', "projectile 18 direct hasar defaultu"),
        ('_spawn_decal_below(impact_position)', "impact sonrası decal"),
        ('decal.call("configure", _decal_tick_damage, damage_source)', "decal hasar aktarımı"),
    ]:
        require(projectile_script, needle, label)

    for needle, label in [
        ('hazard_radius := 2.0', "2 m decal radius"),
        ('lifetime := 6.0', "6 sn decal lifetime"),
        ('damage_tick_interval := 0.5', "decal tick interval"),
    ]:
        require(decal_script, needle, label)

    for needle, label in [
        ('burst_radius := 6.0', "6 m thermal radius"),
        ('burst_damage := 22', "thermal hasar"),
        ('damage_time_ratio := 0.82', "thermal görsel ulaşınca hasar timing"),
        ('_apply_damage_once()', "thermal tek vuruş"),
        ('_has_clear_path_to_player(player)', "thermal occlusion"),
    ]:
        require(shockwave_script, needle, label)

    for animation in ["idle", "walk", "attack", "thermal_burst", "death", "idle_back", "walk_back"]:
        require(carrier_scene, f'&"{animation}"', f"body animation {animation}")
    require(carrier_scene, 'enemy_id = &"furnice_carrier"', "canonical enemy id")
    require(carrier_scene, 'path="res://assets/enemies/furnice_carrier/furnace_carrier_character_spritesheet.png"', "canonical character texture path")
    require(carrier_scene, 'region = Rect2(0, 1024, 768, 512)', "attack canonical row")
    require(carrier_scene, 'region = Rect2(0, 1536, 768, 512)', "thermal canonical row")
    require(carrier_scene, 'region = Rect2(0, 2560, 768, 512)', "idle_back canonical row")
    require(carrier_scene, "pixel_size = 0.0053333333", "canonical character world scale")
    if '[node name="ProjectileMuzzle"' in carrier_scene:
        fail("Eski world-space ProjectileMuzzle marker sahnede kalmış")

    require(projectile_scene, 'path="res://assets/enemies/furnice_carrier/furnace_carrier_effects_spritesheet.png"', "canonical effect texture path")
    require(projectile_scene, 'region = Rect2(0, 0, 256, 256)', "projectile effect row")
    require(projectile_scene, 'region = Rect2(0, 256, 256, 256)', "impact effect row")
    require(projectile_scene, 'pixel_size = 0.0036', "projectile world-space size")
    require(projectile_scene, 'pixel_size = 0.0068', "impact world-space size")
    require(decal_scene, 'region = Rect2(0, 768, 256, 256)', "decal effect row")
    require(decal_scene, 'pixel_size = 0.015625', "decal world-space size")
    require(shockwave_scene, 'region = Rect2(0, 512, 256, 256)', "shockwave effect row")
    require(shockwave_scene, 'pixel_size = 0.046875', "shockwave world-space size")
    require(shockwave_scene, 'damage_time_ratio = 0.82', "shockwave scene damage timing")
    require(shockwave_scene, 'scale = Vector3(1, 3, 1)', "source-art zemin ekseni telafisi")

    if ERRORS:
        print("Furnice Carrier audit FAILED:")
        for error in ERRORS:
            print(f" - {error}")
        return 1
    print("Furnice Carrier audit OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
