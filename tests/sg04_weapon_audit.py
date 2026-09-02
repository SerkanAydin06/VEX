#!/usr/bin/env python3
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
ERRORS = []


def read(path: str) -> str:
    full = ROOT / path
    if not full.exists():
        ERRORS.append(f"Eksik SG04 dosyası: {path}")
        return ""
    return full.read_text(encoding="utf-8")


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        ERRORS.append(f"SG04 sözleşmesi eksik: {label}")


def animation_frame_counts(view: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    pattern = re.compile(
        r'\{\n"frames": \[(.*?)\],\n"loop": (?:true|false|0|1),\n"name": &"([^"]+)"',
        re.S,
    )
    for frames, name in pattern.findall(view):
        counts[name] = frames.count('"texture":')
    return counts


def main() -> int:
    assets = [
        "sg04_idle.png",
        *[f"sg04_fire_{i}.png" for i in range(1, 5)],
        *[f"sg04_reload_{i}.png" for i in range(1, 5)],
        "sg04_side.png",
        "sg04_zoom_idle.png",
        *[f"sg04_zoom_fire_{i}.png" for i in range(1, 5)],
    ]
    for name in assets:
        path = ROOT / "assets/weapons/sg04" / name
        if not path.exists():
            ERRORS.append(f"Eksik SG04 görseli: {name}")
        if not Path(str(path) + ".import").exists():
            ERRORS.append(f"Eksik SG04 import metadata: {name}.import")

    view = read("scenes/ui/weapons/sg04_view.tscn")
    weapon = read("resources/weapons/sg04.tres")
    controller = read("scripts/player/weapon_controller.gd")
    reload_runtime = read("scripts/player/weapon_reload_runtime.gd")
    hitscan = read("scripts/player/weapon_hitscan_runtime.gd")
    presenter = read("scripts/ui/hud_weapon_presenter.gd")
    hud = read("scripts/ui/hud.gd")
    player_scene = read("scenes/player/player.tscn")
    pickup_script = read("scripts/props/pickup.gd")
    player_script = read("scripts/player/player.gd")
    pickup_runtime = read("scripts/player/player_pickup_runtime.gd")
    level_test = read("scenes/levels/level_test.tscn")

    for name in assets:
        if name == "sg04_side.png":
            continue
        require(view, f"res://assets/weapons/sg04/{name}", f"view texture {name}")

    observed_frames = animation_frame_counts(view)
    expected_frames = {
        "idle": 1,
        "fire": 4,
        "reload": 4,
        "reload_shell": 3,
        "reload_finish": 1,
        "zoom": 1,
        "aim_fire": 4,
    }
    for animation, expected in expected_frames.items():
        observed = observed_frames.get(animation, 0)
        if observed != expected:
            ERRORS.append(f"SG04 {animation} frame sayısı {observed}; beklenen {expected}")

    # Visual tuning is intentionally user/scene authoritative. The audit only
    # verifies that tunable properties still exist; it does not freeze their values.
    require(view, "position = Vector2(", "HUD position tuning")
    require(view, "scale = Vector2(", "HUD scale tuning")
    require(view, 'autoplay = "idle"', "idle autoplay")
    if view.count('\"speed\": 5.5172414') < 3:
        ERRORS.append("SG04 2x reload SpriteFrames hızı üç reload animasyonuna uygulanmamış")

    for needle, label in [
        ('weapon_id = &"sg04"', "weapon id"),
        ('ammo_type = &"shells"', "shell ammo type"),
        ('world_pickup_texture = ExtResource("3_side")', "side pickup texture"),
        ('supports_ads_pose = true', "ADS desteği"),
        ('hud_preserve_authored_frame_motion = true', "authored frame motion"),
        ('hud_aim_fire_preserve_frame_motion = true', "ADS recoil frame motion"),
        ('magazine_size =', "magazine tuning"),
        ('reload_duration = 0.725', "2x reload hızı"),
        ('hud_crosshair_scale_multiplier = 2.0', "2x hip crosshair"),
        ('hud_ads_reticle_style = "ring"', "ADS halka reticle"),
        ('ads_spread_multiplier = 0.6', "ADS shotgun spread"),
        ('damage_falloff_start_distance = 8.0', "yakın tam hasar mesafesi"),
        ('damage_falloff_end_distance = 30.0', "falloff bitiş mesafesi"),
        ('damage_falloff_min_multiplier = 0.35', "uzak minimum pellet hasarı"),
        ('pellet_count =', "pellet tuning"),
    ]:
        require(weapon, needle, label)
    require(weapon, 'uid="uid://88g0maxqulm" path="res://assets/weapons/sg04/sg04_side.png"', "SG04 side UID/path")

    # Controller owns orchestration/interrupt state; reload runtime owns shell
    # timing, per-shell ammo transfer and reload HUD action sequencing.
    for needle, label in [
        ('if weapon.weapon_id == &"sg04":', "SG04 özel reload dalı"),
        ('VexWeaponReloadRuntime.reload_sg04_shells(', "shell reload runtime çağrısı"),
        ('func get_reload_animation_speed_multiplier(', "reload upgrade görsel hız senkronu"),
        ('func _interrupt_sg04_reload_and_fire()', "ateşle reload kesme"),
        ('_sg04_reload_fire_queued = true', "cooldown sırasında ateş tıklaması queue"),
        ('_play_hud_action(&"equip")', "reload görselini anında kesme"),
        ('_sg04_reload_generation += 1', "async reload iptal tokeni"),
        ('VexWeaponHitscanRuntime.shoot(', "hitscan runtime delegasyonu"),
    ]:
        require(controller, needle, label)
    for needle, label in [
        ('play_action.call(&"reload_shell")', "1-2-3 shell cycle aksiyonu"),
        ('play_action.call(&"reload_finish")', "4. kare final aksiyonu"),
        ('weapon.reload_duration * 0.75 * multiplier', "1-2-3 süre oranı"),
        ('weapon.reload_duration * 0.25 * multiplier', "4. kare süre oranı"),
        ('magazines[weapon.weapon_id] = current_magazine + 1', "her döngüde tek fişek yükleme"),
        ('reserve_ammo[weapon.ammo_type] = current_reserve - 1', "her döngüde tek rezerv azaltma"),
        ('RESULT_INTERRUPTED', "generation tabanlı async iptal sonucu"),
        ('int(get_generation.call()) != reload_generation', "generation guard"),
    ]:
        require(reload_runtime, needle, label)

    for needle, label in [
        ('spread_multiplier = weapon.ads_spread_multiplier', "silah-bazlı ADS spread"),
        ('static func _get_distance_damage_multiplier(', "mesafe hasar düşüşü"),
    ]:
        require(hitscan, needle, label)

    for needle, label in [
        ('&"reload_shell", &"reload_finish"', "presenter custom reload animasyonları"),
        ('playback_speed = _get_reload_animation_speed(weapon_id)', "presenter reload speed senkronu"),
        ('sprite.animation == &"reload_shell" and _is_weapon_reload_active(weapon_id)', "shell arası idle flash engeli"),
    ]:
        require(presenter, needle, label)
    require(hud, 'action in [&"reload", &"reload_shell"]', "SG04 shell reload ses yönlendirmesi")

    require(player_scene, 'path="res://resources/weapons/sg04.tres"', "Player weapon definitions içinde SG04")
    require(pickup_script, '"sg04"', "pickup enum içinde SG04")
    require(pickup_runtime, "const WORLD_WEAPON_PICKUPS", "ortak fiziksel pickup routing listesi")
    for weapon_id in ['&"sg04"', '&"sg09"', '&"sg15"']:
        require(pickup_runtime, weapon_id, f"world pickup routing {weapon_id}")
    require(pickup_runtime, '"equip_world_weapon",', "loadout grup displacement çağrısı")
    require(pickup_runtime, '"displaced_weapon_id"', "displaced weapon sonucu")
    require(player_script, 'func _apply_world_weapon_pickup_feedback(', "loadout pickup feedback facade")
    require(player_script, '"_spawn_dropped_weapon_pickup"', "yerinden çıkan shotgun pickup spawn")
    require(level_test, 'pickup_type = "sg04"', "Level Test SG04 pickup")
    require(level_test, 'uid="uid://88g0maxqulm" path="res://assets/weapons/sg04/sg04_side.png"', "Level Test SG04 side art")

    generic = 'res://assets/pickups/shotgun.png'
    for path in ROOT.rglob("*.tscn"):
        text = path.read_text(encoding="utf-8")
        if generic in text:
            ERRORS.append(f"Eski generic shotgun görseli hâlâ scene'de: {path.relative_to(ROOT)}")

    if ERRORS:
        print("SG04 WEAPON AUDIT FAILED:")
        for error in ERRORS:
            print(" -", error)
        return 1
    print("SG04 WEAPON AUDIT OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
