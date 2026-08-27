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
    presenter = read("scripts/ui/hud_weapon_presenter.gd")
    hud = read("scripts/ui/hud.gd")
    player_scene = read("scenes/player/player.tscn")
    pickup_script = read("scripts/props/pickup.gd")
    player_script = read("scripts/player/player.gd")
    level_test = read("scenes/levels/level_test.tscn")
    rack = read("scenes/world/weapon_rack.tscn")

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

    for needle, label in [
        ('weapon_id = &"sg04"', "weapon id"),
        ('ammo_type = &"shells"', "shell ammo type"),
        ('world_pickup_texture = ExtResource("3_side")', "side pickup texture"),
        ('supports_ads_pose = true', "ADS desteği"),
        ('hud_preserve_authored_frame_motion = true', "authored frame motion"),
        ('hud_aim_fire_preserve_frame_motion = true', "ADS recoil frame motion"),
        ('magazine_size =', "magazine tuning"),
        ('reload_duration =', "reload duration tuning"),
        ('pellet_count =', "pellet tuning"),
    ]:
        require(weapon, needle, label)
    require(weapon, 'uid="uid://88g0maxqulm" path="res://assets/weapons/sg04/sg04_side.png"', "SG04 side UID/path")

    for needle, label in [
        ('if weapon.weapon_id == &"sg04":', "SG04 özel reload dalı"),
        ('await _reload_sg04_shells(weapon, magazine_size, magazine, reserve)', "shell reload çağrısı"),
        ('_play_hud_action(&"reload_shell")', "1-2-3 shell cycle aksiyonu"),
        ('_play_hud_action(&"reload_finish")', "4. kare final aksiyonu"),
        ('weapon.reload_duration * 0.75 * reload_time_multiplier', "1-2-3 süre oranı"),
        ('weapon.reload_duration * 0.25 * reload_time_multiplier', "4. kare süre oranı"),
        ('magazines[weapon.weapon_id] = current_magazine + 1', "her döngüde tek fişek yükleme"),
        ('reserve_ammo[weapon.ammo_type] = current_reserve - 1', "her döngüde tek rezerv azaltma"),
        ('func get_reload_animation_speed_multiplier(', "reload upgrade görsel hız senkronu"),
    ]:
        require(controller, needle, label)

    for needle, label in [
        ('&"reload_shell", &"reload_finish"', "presenter custom reload animasyonları"),
        ('playback_speed = _get_reload_animation_speed(weapon_id)', "presenter reload speed senkronu"),
        ('sprite.animation == &"reload_shell" and _is_weapon_reload_active(weapon_id)', "shell arası idle flash engeli"),
    ]:
        require(presenter, needle, label)
    require(hud, 'action in [&"reload", &"reload_shell"]', "SG04 shell reload ses yönlendirmesi")

    require(player_scene, 'path="res://resources/weapons/sg04.tres"', "Player weapon definitions içinde SG04")
    require(pickup_script, '"sg04"', "pickup enum içinde SG04")
    require(player_script, '&"sg04":', "player SG04 pickup handler")
    require(player_script, 'unlock_weapon", &"sg04"', "SG04 unlock çağrısı")
    require(level_test, 'pickup_type = "sg04"', "Level Test SG04 pickup")
    require(level_test, 'uid="uid://88g0maxqulm" path="res://assets/weapons/sg04/sg04_side.png"', "Level Test SG04 side art")
    require(rack, 'uid="uid://88g0maxqulm" path="res://assets/weapons/sg04/sg04_side.png"', "weapon rack SG04 side art")

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
