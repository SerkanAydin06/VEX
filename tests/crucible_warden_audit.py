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
    manifest_path = "assets/enemies/crucible_warden/spritesheet_manifest.json"
    character_sheet = "assets/enemies/crucible_warden/crucible_warden_character_spritesheet.png"
    effects_sheet = "assets/enemies/crucible_warden/crucible_warden_effects_spritesheet.png"
    for path in [character_sheet, effects_sheet]:
        if not (ROOT / path).exists():
            fail(f"Eksik Crucible Warden asseti: {path}")

    try:
        manifest = json.loads(read(manifest_path))
        character = manifest.get("character_spritesheet", {})
        effects = manifest.get("effects_spritesheet", {})
        if character.get("frame_size") != {"width": 341, "height": 512}:
            fail("Crucible Warden character frame ölçüsü 341x512 değil")
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
        if effects.get("frame_size") != {"width": 512, "height": 512}:
            fail("Crucible Warden heatwave frame ölçüsü 512x512 değil")
        if effects.get("grid") != {"columns": 4, "rows": 1}:
            fail("Crucible Warden effects grid'i 4x1 değil")
        effect_rows = {row.get("animation"): row.get("row_index") for row in effects.get("rows", [])}
        if effect_rows != {"heatwave_projectile": 0}:
            fail(f"Crucible Warden heatwave satırı bozuk: {effect_rows}")
    except json.JSONDecodeError as exc:
        fail(f"Crucible Warden manifest JSON bozuk: {exc}")

    warden_script_path = "scripts/actors/crucible_warden.gd"
    projectile_script_path = "scripts/actors/crucible_warden_heatwave_projectile.gd"
    slam_script_path = "scripts/effects/crucible_warden_ground_slam.gd"
    warden_scene_path = "scenes/actors/crucible_warden.tscn"
    projectile_scene_path = "scenes/actors/crucible_warden_heatwave_projectile.tscn"
    slam_scene_path = "scenes/effects/crucible_warden_ground_slam.tscn"

    warden_script = read(warden_script_path)
    projectile_script = read(projectile_script_path)
    slam_script = read(slam_script_path)
    warden_scene = read(warden_scene_path)
    projectile_scene = read(projectile_scene_path)
    slam_scene = read(slam_scene_path)

    for path, text in [
        (warden_script_path, warden_script),
        (projectile_script_path, projectile_script),
        (slam_script_path, slam_script),
        (warden_scene_path, warden_scene),
        (projectile_scene_path, projectile_scene),
        (slam_scene_path, slam_scene),
    ]:
        check_res_paths(path, text)

    for needle, label in [
        ('extends "res://scripts/actors/enemy_combatant_base.gd"', "standart combatant tabanı"),
        ("ground_slam_trigger_range := 5.2", "Ground Slam yakın menzil seçimi"),
        ("ground_slam_radius := 4.6", "Ground Slam AoE radius"),
        ("ground_slam_damage := 42", "Ground Slam yüksek hasar"),
        ("heatwave_trigger_range := 1.65", "Heatwave point-blank menzil"),
        ("heatwave_projectile_count := 12", "12 yönlü radyal Heatwave"),
        ("if heatwave_ready:", "Heatwave önceliği"),
        ("_close_for_heatwave(heatwave_approach_speed_multiplier)", "Heatwave için oyuncuya kadar kapanma"),
        ("heatwave_approach_stall_timeout := 0.90", "Heatwave yaklaşma tıkanma süresi"),
        ("heatwave_approach_min_progress := 0.12", "Heatwave yaklaşma ilerleme eşiği"),
        ("ground_effect_fallback_drop := 0.90", "Ground Slam zemin fallback mesafesi Inspector ayarı"),
        ("ground_slam_noise_loudness := 1.50", "Ground Slam ses yayılımı Inspector ayarı"),
        ("heatwave_cooldown_hold_ratio := 0.85", "Heatwave cooldown bekleme mesafesi Inspector ayarı"),
        ("heatwave_cooldown_approach_speed_multiplier := 0.90", "Heatwave cooldown yaklaşma hızı Inspector ayarı"),
        ("heatwave_noise_loudness := 1.25", "Heatwave ses yayılımı Inspector ayarı"),
        ("heatwave_randomize_rotation := true", "Heatwave rotasyon rastgeleliği Inspector ayarı"),
        ("func _is_heatwave_approach_stalled(", "Heatwave yaklaşma watchdog"),
        ("_has_heatwave_approach_anchor", "gerçek gövde hareketiyle tıkanma ayrımı"),
        ("moved_since_anchor", "köşe dolaşırken yanlış stall önleme"),
        ("_reset_heatwave_approach_progress(distance_to_player)", "tıkanma sonrası watchdog reset"),
        ("_path_refresh_remaining = 0.0", "tıkanma sonrası rota yenileme"),
        ("and _check_line_of_sight()", "Slam fallback görüş doğrulaması"),
        ("func _stop_horizontal_motion() -> void:", "yaklaşma sırasında fren override"),
        ("state == State.ATTACK", "yalnız saldırı durumunda fren istisnası"),
        ("var should_keep_closing :=", "Heatwave yaklaşma kararının açık takibi"),
        ("super._stop_horizontal_motion()", "diğer durumlarda canonical fren"),
        ("_begin_heatwave_attack()", "Heatwave saldırı coroutine"),
        ("_begin_ground_slam_attack()", "Ground Slam saldırı coroutine"),
        ("var angular_step := TAU / float(projectile_count)", "360 derece eşit yayılım"),
        ("apply_heatwave_projectile_hit(", "tek burst hasar dedupe"),
        ("_last_heatwave_player_hit_generation", "Heatwave tek vuruş koruması"),
        ("headshot_local_height := 1.15", "elit gövdeye uygun zayıf nokta"),
    ]:
        require(warden_script, needle, label)

    for needle, label in [
        ("damage_radius := 4.6", "Ground Slam effect radius"),
        ("damage := 42", "Ground Slam effect damage"),
        ("VexEnemyRuntimeUtils.horizontal_distance", "Ground Slam mesafe kontrolü"),
        ("_has_clear_path_to_player(player)", "Ground Slam duvar arkasına hasar vermeme"),
        ("SettingsManager.screen_shake", "accessibility screen shake ayarı"),
        ("camera.h_offset", "yatay kamera sarsıntısı"),
        ("camera.v_offset", "dikey kamera sarsıntısı"),
        ("impact_light_range_multiplier := 1.15", "impact ışık menzil çarpanı Inspector ayarı"),
        ("occlusion_origin_height := 0.25", "occlusion başlangıç yüksekliği Inspector ayarı"),
        ("occlusion_target_height := 0.35", "occlusion hedef yüksekliği Inspector ayarı"),
        ("shake_minimum_proximity_scale := 0.30", "uzak kamera sarsıntı ölçeği Inspector ayarı"),
    ]:
        require(slam_script, needle, label)

    for needle, label in [
        ("speed := 8.5", "Heatwave projectile hız"),
        ("lifetime := 1.45", "Heatwave projectile yaşam süresi"),
        ("PhysicsRayQueryParameters3D.create", "yüksek hız ray collision"),
        ('add_to_group("projectile")', "projectile temizleme grubu"),
        ('_source.has_method("apply_heatwave_projectile_hit")', "Warden burst dedupe callback"),
        ("_burst_id", "Heatwave burst kimliği"),
    ]:
        require(projectile_script, needle, label)

    for animation in ["idle", "walk", "attack", "heatwave", "death", "idle_back", "walk_back", "hurt"]:
        require(warden_scene, f'&"{animation}"', f"character animation {animation}")
    require(warden_scene, 'enemy_id = &"crucible_warden"', "canonical enemy id")
    require(warden_scene, "heatwave_approach_stall_timeout = 0.9", "yaklaşma tıkanma scene tuning")
    require(warden_scene, "heatwave_approach_min_progress = 0.12", "yaklaşma ilerleme scene tuning")
    require(warden_scene, 'ground_slam_scene = ExtResource("3_slam")', "Ground Slam scene bağlantısı")
    require(
        warden_scene,
        'heatwave_projectile_scene = ExtResource("4_heatwave_projectile")',
        "Heatwave projectile scene bağlantısı",
    )
    require(warden_scene, 'region = Rect2(0, 1536, 341, 512)', "character heatwave row başlangıcı")
    require(warden_scene, 'region = Rect2(1023, 1536, 341, 512)', "character heatwave row son frame")
    require(warden_scene, '[node name="HeatwaveOrigin" type="Marker3D" parent="."', "Heatwave merkez marker")

    for x in [0, 512, 1024, 1536]:
        require(
            projectile_scene,
            f"region = Rect2({x}, 0, 512, 512)",
            f"Heatwave projectile frame x={x}",
        )
    require(projectile_scene, '"loop": true', "Heatwave 4-frame loop")
    require(projectile_scene, "collision_mask = 3", "Heatwave dünya + oyuncu collision")
    require(projectile_scene, '[node name="HeatLight" type="OmniLight3D" parent="."]', "Heatwave ışık")

    require(slam_scene, '[node name="Ring" type="MeshInstance3D" parent="."]', "Ground Slam görsel halka/disk")
    require(slam_scene, '[node name="ImpactLight" type="OmniLight3D" parent="."]', "Ground Slam impact ışığı")
    require(slam_scene, "shadow_enabled = false", "Ground Slam ucuz geçici ışık")
    require(slam_scene, "impact_light_range_multiplier = 1.15", "Ground Slam Inspector scene ayarı")

    if ERRORS:
        print("Crucible Warden audit FAILED:")
        for error in ERRORS:
            print(f" - {error}")
        return 1
    print("Crucible Warden audit OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
