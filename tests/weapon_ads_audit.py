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
    definition = read("scripts/player/weapon_definition.gd")
    player = read("scripts/player/player.gd")
    controller = read("scripts/player/weapon_controller.gd")

    require(
        definition,
        '@export_range(20.0, 100.0, 1.0) var ads_fov := 50.0',
        "WeaponDefinition silah-bazlı ads_fov taşımıyor",
    )

    if 'var ads_fov := 50.0' in player:
        ERRORS.append("Player hâlâ global/sabit ads_fov otoritesi taşıyor")
    for contract, message in [
        ('current_weapon = weapon_controller.call("get_current_weapon") as WeaponDefinition', "Player mevcut silah tanımını ADS için okumuyor"),
        ("current_weapon != null and current_weapon.supports_ads_pose", "Player ADS desteğini silah verisinden doğrulamıyor"),
        ('is_aiming = supports_ads and Input.is_action_pressed("aim")', "ADS durumu desteklemeyen silahlarda engellenmiyor"),
        ("current_weapon.ads_fov if is_aiming else _default_fov", "Kamera FOV'u mevcut silahın ads_fov değerini kullanmıyor"),
        ("Vector2.ZERO", "ADS sırasında HUD nişangahı optik merkezde sabitlenmiyor"),
        ("if is_aiming", "ADS HUD recoil ayrımı eksik"),
        ('GameState.hud.call("set_weapon_recoil_offset", hud_recoil)', "HUD recoil/optik merkez senkronu eksik"),
    ]:
        require(player, contract, message)

    for contract, message in [
        ("var uses_ads_optical_center := _player.is_aiming and weapon.supports_ads_pose", "Hitscan ADS optik-merkez koşulu eksik"),
        ("not uses_ads_optical_center", "Hip-fire/ADS hedef ayrımı eksik"),
        ('GameState.hud.has_method("get_crosshair_screen_position")', "Hip-fire HUD crosshair hedeflemesi kaybolmuş"),
        ("camera.get_viewport().get_visible_rect().size * 0.5", "ADS için kamera ekran merkezi hesaplanmıyor"),
    ]:
        require(controller, contract, message)

    expected_fov = {
        "p01": 56.0,
        "p07": 53.0,
        "p14": 47.0,
        "p20": 51.0,
    }
    observed: list[float] = []
    for weapon_id, fov in expected_fov.items():
        weapon = read(f"resources/weapons/{weapon_id}.tres")
        require(weapon, "supports_ads_pose = true", f"{weapon_id} ADS pose desteğini kaybetmiş")
        require(weapon, f"ads_fov = {fov:.1f}", f"{weapon_id} ads_fov beklenen {fov:.1f} değil")
        observed.append(fov)

    if len(set(observed)) != len(observed):
        ERRORS.append("Tabanca ADS FOV değerleri birbirinden ayrışmıyor")
    if not expected_fov["p14"] < expected_fov["p20"] < expected_fov["p07"] < expected_fov["p01"]:
        ERRORS.append("Tabanca zoom hiyerarşisi precision -> heavy -> tactical -> standard sırasını korumuyor")

    for message in ERRORS:
        print("ERROR:", message)
    print(f"WEAPON ADS VALIDATOR: {len(ERRORS)} hata")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
