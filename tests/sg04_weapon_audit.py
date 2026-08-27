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


def count_animation_frames(view: str, animation: str) -> int:
    match = re.search(
        rf'"frames": \[(.*?)\],\n"loop": (?:true|false),\n"name": &"{re.escape(animation)}"',
        view,
        re.S,
    )
    return match.group(1).count('"texture":') if match else 0


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
    player_scene = read("scenes/player/player.tscn")
    pickup_script = read("scripts/props/pickup.gd")
    player_script = read("scripts/player/player.gd")
    level_test = read("scenes/levels/level_test.tscn")
    rack = read("scenes/world/weapon_rack.tscn")

    for name in assets:
        if name == "sg04_side.png":
            continue
        require(view, f"res://assets/weapons/sg04/{name}", f"view texture {name}")

    expected_frames = {"idle": 1, "fire": 4, "reload": 4, "zoom": 1, "aim_fire": 4}
    for animation, expected in expected_frames.items():
        observed = count_animation_frames(view, animation)
        if observed != expected:
            ERRORS.append(f"SG04 {animation} frame sayısı {observed}; beklenen {expected}")
    require(view, "position = Vector2(960, 780)", "HUD base position")
    require(view, "scale = Vector2(0.6, 0.6)", "HUD base scale")
    require(view, 'animation = &"idle"', "editor idle başlangıcı")
    require(view, 'autoplay = "idle"', "idle autoplay")

    for needle, label in [
        ('weapon_id = &"sg04"', "weapon id"),
        ('world_pickup_texture = ExtResource("3_side")', "side pickup texture"),
        ('supports_ads_pose = true', "ADS desteği"),
        ('ads_fov_multiplier = 0.74', "ADS FOV"),
        ('hud_preserve_authored_frame_motion = true', "authored frame motion"),
        ('hud_zoom_offset = Vector2(5, -354)', "iron sight merkez hizası"),
        ('hud_ads_reticle_style = "small_cross"', "iron sight reticle"),
        ('hud_aim_fire_preserve_frame_motion = true', "ADS recoil frame motion"),
        ('magazine_size = 6', "6 shell magazine"),
        ('damage_per_pellet = 11', "pellet damage"),
        ('pellet_count = 8', "pellet count"),
        ('fire_interval = 0.82', "fire interval"),
        ('reload_duration = 1.45', "reload duration"),
        ('spread_degrees = 5.5', "hip spread"),
        ('maximum_range = 48.0', "range"),
    ]:
        require(weapon, needle, label)
    require(weapon, 'uid="uid://88g0maxqulm" path="res://assets/weapons/sg04/sg04_side.png"', "SG04 side UID/path")

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
