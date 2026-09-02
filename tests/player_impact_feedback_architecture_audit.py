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
    runtime = read("scripts/player/player_impact_feedback_runtime.gd")

    for contract, message in [
        (
            "var _impact_feedback_runtime := VexPlayerImpactFeedbackRuntime.new()",
            "Player impact feedback runtime helper oluşturmuyor",
        ),
        (
            "_impact_feedback_runtime.request_camera_shake(",
            "Camera shake isteği impact runtime'a delege edilmiyor",
        ),
        (
            "_impact_feedback_runtime.update_camera_shake(",
            "Camera shake tick impact runtime'a delege edilmiyor",
        ),
        (
            "_impact_feedback_runtime.clear_camera_shake()",
            "Camera shake clear impact runtime'a delege edilmiyor",
        ),
        (
            "_impact_feedback_runtime.begin_impact_shock(",
            "Impact shock timing/generation impact runtime'a delege edilmiyor",
        ),
        (
            "_impact_feedback_runtime.is_impact_shock_generation_current(",
            "Impact shock generation guard runtime'dan alınmıyor",
        ),
        ("CanvasLayer.new()", "Impact overlay scene side-effect Player'da kalmıyor"),
        ("ColorRect.new()", "Impact tint node üretimi Player'da kalmıyor"),
        ("create_tween()", "Impact Tween scene side-effect Player'da kalmıyor"),
    ]:
        require(player, contract, message)

    for contract, message in [
        ("var _impact_shake_remaining :=", "Shake remaining state yeniden player.gd içine taşınmış"),
        ("var _impact_shake_duration :=", "Shake duration state yeniden player.gd içine taşınmış"),
        ("var _impact_shake_strength :=", "Shake strength state yeniden player.gd içine taşınmış"),
        ("var _impact_shake_base_h_offset :=", "Shake base H offset yeniden player.gd içine taşınmış"),
        ("var _impact_shake_base_v_offset :=", "Shake base V offset yeniden player.gd içine taşınmış"),
        ("var _impact_shake_active :=", "Shake active state yeniden player.gd içine taşınmış"),
        ("var _impact_shock_generation :=", "Shock generation state yeniden player.gd içine taşınmış"),
        ("randf_range(-_impact_shake_strength", "Shake random offset hesabı yeniden player.gd içine taşınmış"),
    ]:
        forbid(player, contract, message)

    for contract, message in [
        ("class_name VexPlayerImpactFeedbackRuntime", "Impact feedback runtime class tanımı eksik"),
        ("var _shake_remaining :=", "Impact runtime shake remaining state'i sahiplenmiyor"),
        ("var _shake_duration :=", "Impact runtime shake duration state'i sahiplenmiyor"),
        ("var _shake_strength :=", "Impact runtime shake strength state'i sahiplenmiyor"),
        ("var _shake_base_offset :=", "Impact runtime base camera offset state'i sahiplenmiyor"),
        ("var _shock_generation :=", "Impact runtime shock generation state'i sahiplenmiyor"),
        ("func request_camera_shake(", "Impact runtime camera shake isteğini sahiplenmiyor"),
        ("func update_camera_shake(", "Impact runtime camera shake fade hesabını sahiplenmiyor"),
        ("func clear_camera_shake(", "Impact runtime camera shake clear hesabını sahiplenmiyor"),
        ("func begin_impact_shock(", "Impact runtime shock timing hesabını sahiplenmiyor"),
        ("func is_impact_shock_generation_current(", "Impact runtime generation guard sağlamıyor"),
        ("randf_range(-_shake_strength", "Impact runtime random shake offset üretmiyor"),
    ]:
        require(runtime, contract, message)

    for contract, message in [
        ("CanvasLayer", "Impact runtime scene node bağımlılığı taşıyor"),
        ("ColorRect", "Impact runtime UI node bağımlılığı taşıyor"),
        ("Tween", "Impact runtime Tween bağımlılığı taşıyor"),
        ("GameState", "Impact runtime GameState side-effect'i taşıyor"),
        ("SettingsManager", "Impact runtime SettingsManager bağımlılığı taşıyor"),
    ]:
        forbid(runtime, contract, message)

    for message in ERRORS:
        print("ERROR:", message)
    print(f"PLAYER IMPACT FEEDBACK ARCHITECTURE AUDIT: {len(ERRORS)} hata")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
