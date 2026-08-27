#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
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


def number(text: str, pattern: str, message: str) -> float | None:
    match = re.search(pattern, text, re.M)
    if not match:
        ERRORS.append(message)
        return None
    return float(match.group(1))


def main() -> int:
    script = read("scripts/player/player.gd")
    scene = read("scenes/player/player.tscn")

    for contract, message in [
        ('@export_range(0.0, 1.8, 0.01) var crouch_view_pivot_height', "Crouch kamera yüksekliği 1 metrenin altına inemiyor"),
        ('if is_crouching:\n\t\t# Crouch + jump önce ayağa kalkma isteğidir.', "Jump crouch durumunu özel ele almıyor"),
        ('if _can_stand_up():\n\t\t\t_set_crouching(false)\n\t\treturn', "Crouch + jump güvenli şekilde ayağa kalkmıyor"),
    ]:
        require(script, contract, message)

    standing_height = number(scene, r'^height\s*=\s*([0-9.]+)$', "Player standing capsule yüksekliği bulunamadı")
    crouch_height = number(scene, r'^crouch_capsule_height\s*=\s*([0-9.]+)$', "Player crouch capsule yüksekliği scene-authority değil")
    crouch_view = number(scene, r'^crouch_view_pivot_height\s*=\s*([0-9.]+)$', "Player crouch göz yüksekliği scene-authority değil")
    standing_view = number(scene, r'Transform3D\([^\n]*, 0, ([0-9.]+), 0\)', "Player ayakta ViewPivot yüksekliği bulunamadı")

    if standing_height is not None and abs(standing_height - 1.8) > 0.001:
        ERRORS.append(f"Player standing capsule 1.80 m değil: {standing_height:.2f}")
    if crouch_height is not None and abs(crouch_height - 1.1) > 0.001:
        ERRORS.append(f"Player crouch capsule 1.10 m değil: {crouch_height:.2f}")
    if crouch_view is not None and abs(crouch_view - 0.05) > 0.001:
        ERRORS.append(f"Player crouch ViewPivot 0.05 değil: {crouch_view:.2f}")

    if None not in (standing_height, crouch_height, crouch_view, standing_view):
        floor_relative_origin = standing_height / 2.0
        standing_eye = floor_relative_origin + standing_view
        crouch_eye = floor_relative_origin + crouch_view
        if abs(standing_eye - 1.52) > 0.01:
            ERRORS.append(f"Ayakta göz yüksekliği beklenen 1.52 m değil: {standing_eye:.2f}")
        if abs(crouch_eye - 0.95) > 0.01:
            ERRORS.append(f"Crouch göz yüksekliği beklenen 0.95 m değil: {crouch_eye:.2f}")
        if standing_eye - crouch_eye < 0.50:
            ERRORS.append("Crouch kamera düşüşü yeterince belirgin değil")

    for message in ERRORS:
        print("ERROR:", message)
    print(f"PLAYER MOVEMENT VALIDATOR: {len(ERRORS)} hata")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
