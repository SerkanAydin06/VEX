#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        ERRORS.append(f"Eksik dosya: {relative}")
        return ""
    return path.read_text(encoding="utf-8")


def require(text: str, contract: str, message: str) -> None:
    if contract not in text:
        ERRORS.append(message)


def main() -> int:
    resource = read("resources/weapons/sg15.tres")
    view = read("scenes/ui/weapons/sg15_view.tscn")
    definition = read("scripts/player/weapon_definition.gd")
    controller = read("scripts/player/weapon_controller.gd")
    upgrades = read("scripts/player/weapon_upgrade_catalog.gd")
    player_scene = read("scenes/player/player.tscn")
    player_script = read("scripts/player/player.gd")
    pickup_script = read("scripts/props/pickup.gd")
    level_test = read("scenes/levels/level_test.tscn")
    bastion = read("scenes/hub/bastion_7.tscn")
    localization = read("translations/vex.csv")
    hud_script = read("scripts/ui/hud.gd")
    hud_scene = read("scenes/ui/hud.tscn")
    game_state = read("scripts/autoload/game_state.gd")

    for contract in [
        'weapon_id = &"sg15"',
        'display_name = "WEAPON_SG15_NAME"',
        'ammo_type = &"shells"',
        'loadout_group = &"shotgun"',
        'loadout_slot = 2',
        'supports_ads_pose = true',
        'uses_heat = true',
        'heat_per_shot = 14.0',
        'heat_capacity = 100.0',
        'heat_unlock_ratio = 0.65',
        'heat_cooling_per_second = 32.0',
        'magazine_size = 12',
        'damage_per_pellet = 8',
        'pellet_count = 7',
        'fire_interval = 0.18',
        'reload_duration = 2.0',
        'spread_degrees = 6.2',
        'maximum_range = 42.0',
        'reserve_ammo_capacity = 60',
        'automatic = true',
    ]:
        require(resource, contract, f"SG-15 resource sözleşmesi eksik: {contract}")

    required_frames = [
        "sg15_idle.png",
        "sg15_fire_1.png", "sg15_fire_2.png", "sg15_fire_3.png", "sg15_fire_4.png",
        "sg15_aim_fire_1.png", "sg15_aim_fire_2.png", "sg15_aim_fire_3.png", "sg15_aim_fire_4.png",
        "sg15_reload_1.png", "sg15_reload_2.png", "sg15_reload_3.png", "sg15_reload_4.png",
        "sg15_zoom_idle.png",
    ]
    for filename in required_frames:
        require(view, filename, f"SG-15 HUD karesi sahneye bağlı değil: {filename}")
        asset_path = ROOT / "assets" / "weapons" / "sg15" / filename
        if not asset_path.exists():
            ERRORS.append(f"SG-15 görseli eksik: {asset_path.relative_to(ROOT)}")
    if (ROOT / "assets/weapons/sg15/sg15_3.png").exists():
        ERRORS.append("Yanlış adlandırılmış sg15_3.png kaldırılmamış")
    for animation in ["aim_fire", "equip", "fire", "idle", "reload", "zoom"]:
        require(view, f'"name": &"{animation}"', f"SG-15 animasyonu eksik: {animation}")

    for contract in [
        "heat_per_shot", "heat_capacity", "heat_unlock_ratio",
        "heat_cooldown_delay", "heat_cooling_per_second",
    ]:
        require(definition, contract, f"WeaponDefinition ısı alanı eksik: {contract}")
    for contract in [
        "weapon_heat", "weapon_overheated", "_heat_cooldown_remaining",
        "_effective_heat_capacity", "_update_weapon_heat", "heat_unlock_ratio",
        "WEAPON_OVERHEATED", "WEAPON_COOLED",
    ]:
        require(controller, contract, f"WeaponController ısı davranışı eksik: {contract}")
    for text, contract, message in [
        (game_state, "signal weapon_heat_changed", "GameState ısı sinyali eksik"),
        (hud_script, "_on_weapon_heat_changed", "HUD ısı sinyalini işlemiyor"),
        (hud_scene, '[node name="HeatPanel"', "HUD HeatPanel sahne düğümü eksik"),
        (hud_scene, '[node name="HeatMeter"', "HUD HeatMeter sahne düğümü eksik"),
    ]:
        require(text, contract, message)

    for contract in [
        '&"sg15"', '&"tempest_drum"', '&"thermal_jacket"', '&"cyclone_bolt"',
        '"heat_capacity": 1.40', '"heat_cooling": 1.25',
    ]:
        require(upgrades, contract, f"SG-15 geliştirme sözleşmesi eksik: {contract}")

    for text, contract, message in [
        (player_scene, "res://resources/weapons/sg15.tres", "Player SG-15 resource'unu yüklemiyor"),
        (player_script, '&"sg09", &"sg15":', "Player SG-15 pickup swap akışını tanımıyor"),
        (pickup_script, '"sg09", "sg15", "vx47"', "Pickup SG-15'i silah olarak tanımıyor"),
        (level_test, 'pickup_type = "sg15"', "Level Test SG-15 pickup içermiyor"),
        (bastion, 'weapon_texture = ExtResource("20_sg15_side")', "Bastion SG-15 raf görseli eksik"),
    ]:
        require(text, contract, message)

    for key in [
        "WEAPON_SG15_NAME", "WEAPON_OVERHEATED", "WEAPON_COOLED",
        "HUD_WEAPON_HEAT", "HUD_HEAT_OVERHEATED", "UPGRADE_TEMPEST_DRUM",
        "UPGRADE_THERMAL_JACKET", "UPGRADE_CYCLONE_BOLT",
    ]:
        require(localization, key, f"SG-15 çeviri anahtarı eksik: {key}")

    for message in ERRORS:
        print("ERROR:", message)
    print(f"SG15 WEAPON VALIDATOR: {len(ERRORS)} hata")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
