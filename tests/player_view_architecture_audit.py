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


def forbid(text: str, contract: str, message: str) -> None:
    if contract in text:
        ERRORS.append(message)


def main() -> int:
    player = read("scripts/player/player.gd")
    runtime = read("scripts/player/player_view_runtime.gd")

    for contract, message in [
        ("var _view_runtime := VexPlayerViewRuntime.new()", "Player view runtime helper oluşturmuyor"),
        ("_view_runtime.apply_mouse_look(", "Mouse look view runtime'a delege edilmiyor"),
        ("_view_runtime.apply_controller_look(", "Controller look view runtime'a delege edilmiyor"),
        ("_view_runtime.apply_recoil(", "Weapon recoil view runtime'a delege edilmiyor"),
        ("_view_runtime.update_recoil(", "Recoil recovery view runtime'a delege edilmiyor"),
        ("_view_runtime.update_aiming(", "ADS/FOV geçişi view runtime'a delege edilmiyor"),
        ("_view_runtime.update_view_bob(", "Head bob/footstep view runtime'a delege edilmiyor"),
        ("_view_runtime.get_hud_recoil(is_aiming)", "HUD recoil offset view runtime'dan alınmıyor"),
        ("@export_range(1.0, 500.0, 0.5) var ads_transition_speed", "ADS transition tuning Player Inspector authority'de değil"),
        ("@export_range(0.0, 1.0, 0.01) var ads_spread_multiplier", "ADS spread tuning Player Inspector authority'de değil"),
        ("@export_range(0.05, 1.0, 0.01) var ads_recoil_multiplier", "ADS recoil tuning Player Inspector authority'de değil"),
        ("@export_range(30.0, 89.0, 1.0) var pitch_limit_degrees", "Pitch tuning Player Inspector authority'de değil"),
        ("@export_range(0.0, 1.0, 0.01) var recoil_yaw_recovery_multiplier", "Recoil recovery tuning Player Inspector authority'de değil"),
        ("@export_range(0.0, 0.2, 0.001) var bob_horizontal_amplitude", "Head bob tuning Player Inspector authority'de değil"),
        ("@export_range(0.05, 2.0, 0.01) var walk_footstep_interval", "Footstep tuning Player Inspector authority'de değil"),
    ]:
        require(player, contract, message)

    for contract, message in [
        ("var _pitch :=", "Pitch runtime state yeniden player.gd içine taşınmış"),
        ("var _bob_time :=", "Bob runtime state yeniden player.gd içine taşınmış"),
        ("var _footstep_remaining :=", "Footstep timer yeniden player.gd içine taşınmış"),
        ("var _camera_rest_position :=", "Camera rest runtime state yeniden player.gd içine taşınmış"),
        ("var _recoil_pitch_degrees :=", "Recoil pitch state yeniden player.gd içine taşınmış"),
        ("var _recoil_yaw_degrees :=", "Recoil yaw state yeniden player.gd içine taşınmış"),
        ("var _recoil_recovery_degrees_per_second :=", "Recoil recovery state yeniden player.gd içine taşınmış"),
        ("target_fov = clampf(", "ADS target FOV hesabı yeniden player.gd içine taşınmış"),
        ("camera.fov = move_toward(", "ADS FOV transition hesabı yeniden player.gd içine taşınmış"),
    ]:
        forbid(player, contract, message)

    for contract, message in [
        ("class_name VexPlayerViewRuntime", "VexPlayerViewRuntime class tanımı eksik"),
        ("func configure_bob(", "View runtime bob tuning configure etmiyor"),
        ("func apply_mouse_look(", "View runtime mouse look hesabını sahiplenmiyor"),
        ("func apply_controller_look(", "View runtime controller look hesabını sahiplenmiyor"),
        ("func apply_recoil(", "View runtime recoil state'i sahiplenmiyor"),
        ("func update_recoil(", "View runtime recoil recovery hesabını sahiplenmiyor"),
        ("func get_view_rotation(", "View runtime nihai view rotation üretmiyor"),
        ("func update_aiming(", "View runtime ADS/FOV transition hesabını sahiplenmiyor"),
        ("default_fov * ads_fov_multiplier", "View runtime ADS multiplier hesabını taşımıyor"),
        ("move_toward(", "View runtime FOV transition üretmiyor"),
        ("func update_view_bob(", "View runtime head bob/footstep state'i sahiplenmiyor"),
    ]:
        require(runtime, contract, message)

    for message in ERRORS:
        print("ERROR:", message)
    print(f"PLAYER VIEW ARCHITECTURE AUDIT: {len(ERRORS)} hata")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
