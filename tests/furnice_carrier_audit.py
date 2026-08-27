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
    body_manifest_path = "assets/enemies/furnice_carrier/furnice_carrier_body_manifest.json"
    effects_manifest_path = "assets/enemies/furnice_carrier/furnice_carrier_effects_manifest.json"
    body_sheet = "assets/enemies/furnice_carrier/furnice_carrier_body_spritesheet.png"
    effects_sheet = "assets/enemies/furnice_carrier/furnice_carrier_effects_spritesheet.png"

    for path in [body_sheet, effects_sheet, f"{body_sheet}.import", f"{effects_sheet}.import"]:
        if not (ROOT / path).exists():
            fail(f"Eksik Furnice asseti: {path}")

    try:
        body_manifest = json.loads(read(body_manifest_path))
        if (body_manifest.get("frame_width"), body_manifest.get("frame_height"), body_manifest.get("columns")) != (512, 341, 4):
            fail("Furnice body sheet grid'i 512x341 / 4 kolon değil")
        body_rows = {row.get("animation"): row.get("row_index") for row in body_manifest.get("rows", [])}
        expected_body_rows = {
            "idle": 0,
            "idle_back": 1,
            "walk": 2,
            "walk_back": 3,
            "attack": 4,
            "thermal_burst": 5,
            "death": 6,
        }
        if body_rows != expected_body_rows:
            fail(f"Furnice body animasyon satırları bozuk: {body_rows}")
    except json.JSONDecodeError as exc:
        fail(f"Furnice body manifest JSON bozuk: {exc}")

    try:
        effects_manifest = json.loads(read(effects_manifest_path))
        if (effects_manifest.get("frame_width"), effects_manifest.get("frame_height"), effects_manifest.get("columns")) != (512, 512, 4):
            fail("Furnice effects sheet grid'i 512x512 / 4 kolon değil")
        effect_rows = {row.get("animation"): row.get("row_index") for row in effects_manifest.get("rows", [])}
        expected_effect_rows = {"projectile": 0, "impact": 1, "shockwave": 2, "decal": 3}
        if effect_rows != expected_effect_rows:
            fail(f"Furnice effect animasyon satırları bozuk: {effect_rows}")
    except json.JSONDecodeError as exc:
        fail(f"Furnice effects manifest JSON bozuk: {exc}")

    carrier_script_path = "scripts/actors/furnice_carrier.gd"
    projectile_script_path = "scripts/actors/furnice_carrier_projectile.gd"
    decal_script_path = "scripts/effects/furnice_carrier_decal.gd"
    shockwave_script_path = "scripts/effects/furnice_carrier_shockwave.gd"
    carrier_scene_path = "scenes/actors/furnice_carrier.tscn"
    projectile_scene_path = "scenes/actors/furnice_carrier_projectile.tscn"
    decal_scene_path = "scenes/effects/furnice_carrier_decal.tscn"
    shockwave_scene_path = "scenes/effects/furnice_carrier_shockwave.tscn"

    carrier_script = read(carrier_script_path)
    projectile_script = read(projectile_script_path)
    decal_script = read(decal_script_path)
    shockwave_script = read(shockwave_script_path)
    carrier_scene = read(carrier_scene_path)
    projectile_scene = read(projectile_scene_path)
    decal_scene = read(decal_scene_path)
    shockwave_scene = read(shockwave_scene_path)

    for path, text in [
        (carrier_scene_path, carrier_scene),
        (projectile_scene_path, projectile_scene),
        (decal_scene_path, decal_scene),
        (shockwave_scene_path, shockwave_scene),
    ]:
        check_res_paths(path, text)

    for needle, label in [
        ('close_attack_threshold := 6.0', "6 m saldırı eşiği"),
        ('var thermal_burst_ready := Time.get_ticks_msec() >= _thermal_burst_ready_at_msec', "thermal ayrı cooldown takibi"),
        ('var use_thermal_burst := distance_to_player <= close_attack_threshold and thermal_burst_ready', "yakında ve hazırsa thermal seçim"),
        ('_thermal_burst_ready_at_msec = Time.get_ticks_msec()', "thermal cooldown yeniden kurma"),
        ('projectile_attack_cooldown * cooldown_scale', "thermal aralarında projectile saldırı ritmi"),
        ('_fire_furnice_projectile()', "projectile saldırısı"),
        ('_emit_thermal_burst()', "thermal saldırısı"),
        ('projectile_muzzle_sprite_offset_pixels := Vector2(0.0, -139.0)', "furnace ağzı sprite-pixel anchor"),
        ('camera.global_transform.basis.x', "billboard kamera-sağ muzzle ekseni"),
        ('animated_sprite.global_position', "muzzle sprite merkezi tabanı"),
        ('func _projectile_muzzle_world_position()', "sprite-pixel muzzle dönüşümü"),
        ('projectile.call("launch", shot_direction, self, _runtime_attack_damage, decal_damage)', "projectile direct + decal damage aktarımı"),
    ]:
        require(carrier_script, needle, label)

    for needle, label in [
        ('speed := 14.0', "projectile 14 m/s"),
        ('var _direct_damage := 18', "projectile 18 direct hasar defaultu"),
        ('_spawn_decal_below(impact_position)', "impact sonrası decal"),
        ('decal.call("configure", _decal_tick_damage, _source)', "decal hasar aktarımı"),
    ]:
        require(projectile_script, needle, label)

    for needle, label in [
        ('hazard_radius := 2.0', "2 m decal radius"),
        ('lifetime := 6.0', "6 sn decal lifetime"),
        ('damage_tick_interval := 0.5', "decal tick interval"),
        ('overlaps_body(player)', "decal içindeyken hasar"),
    ]:
        require(decal_script, needle, label)

    for needle, label in [
        ('burst_radius := 6.0', "6 m thermal radius"),
        ('burst_damage := 22', "thermal hasar"),
        ('damage_time_ratio := 0.82', "thermal görsel ulaşınca hasar timing"),
        ('visual_end_scale := 1.20', "thermal görsel telegraph taşması"),
        ('_apply_damage_once()', "thermal tek vuruş"),
        ('_has_clear_path_to_player(player)', "thermal occlusion"),
    ]:
        require(shockwave_script, needle, label)

    for animation in ["idle", "idle_back", "walk", "walk_back", "attack", "thermal_burst", "death"]:
        require(carrier_scene, f'&"{animation}"', f"body animation {animation}")
    require(carrier_scene, 'enemy_id = &"furnice_carrier"', "canonical enemy id")
    require(carrier_scene, 'attack_damage = 18', "scene direct hasar")
    require(carrier_scene, 'projectile_scene = ExtResource("3_projectile")', "scene projectile bağlantısı")
    require(carrier_scene, 'thermal_burst_scene = ExtResource("4_shockwave")', "scene thermal bağlantısı")
    if '[node name="ProjectileMuzzle"' in carrier_scene:
        fail("Eski world-space ProjectileMuzzle marker sahnede kalmış")

    require(projectile_scene, 'decal_scene = ExtResource("3_decal")', "projectile decal scene bağlantısı")
    require(projectile_scene, 'region = Rect2(0, 0, 512, 512)', "projectile effect row")
    require(projectile_scene, 'region = Rect2(0, 512, 512, 512)', "impact effect row")
    require(decal_scene, 'region = Rect2(0, 1536, 512, 512)', "decal effect row")
    require(shockwave_scene, 'region = Rect2(0, 1024, 512, 512)', "shockwave effect row")
    require(shockwave_scene, 'damage_time_ratio = 0.82', "shockwave scene damage timing")
    require(shockwave_scene, 'visual_end_scale = 1.2', "shockwave scene visual taşma")
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
