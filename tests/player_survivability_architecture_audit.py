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
    runtime = read("scripts/player/player_survivability_runtime.gd")

    for contract, message in [
        ("class_name VexPlayerSurvivabilityRuntime", "Survivability helper class_name eksik"),
        ("extends RefCounted", "Survivability helper saf RefCounted değil"),
        ("func initialize(", "Survivability initialize API eksik"),
        ("func sync_state(", "Survivability compatibility sync API eksik"),
        ("func restore_state(", "Survivability restore API eksik"),
        ("func collect_health(", "Health pickup clamp helper'a taşınmamış"),
        ("func collect_armor(", "Armor pickup clamp helper'a taşınmamış"),
        ("func apply_damage(", "Damage çözümü survivability helper'da değil"),
        ("func update(delta: float)", "Hurt feedback cooldown update helper'da değil"),
        ("func force_dead()", "Death state helper API eksik"),
        ("_armor_absorption_ratio", "Armor absorption state helper'da değil"),
        ("_hurt_audio_cooldown_remaining", "Hurt cooldown state helper'da değil"),
    ]:
        require(runtime, contract, message)

    for forbidden, message in [
        ("Input.", "Survivability helper Input'a bağımlı"),
        ("AudioStream", "Survivability helper audio Node tipine bağımlı"),
        ("GameState", "Survivability helper GameState'e bağımlı"),
        ("Node3D", "Survivability helper 3D Node'a bağımlı"),
        ("get_tree()", "Survivability helper SceneTree'ye bağımlı"),
    ]:
        forbid(runtime, forbidden, message)

    for contract, message in [
        ('@export_range(1, 500, 1) var maximum_health := 100', "Player maximum_health Inspector authority kaybolmuş"),
        ('@export_range(1, 500, 1) var maximum_armor := 100', "Player maximum_armor Inspector authority kaybolmuş"),
        ('@export_range(0, 500, 1) var initial_armor := 0', "Player initial_armor Inspector authority kaybolmuş"),
        ('@export_range(0.0, 1.0, 0.01) var armor_absorption_ratio := 0.60', "Player armor absorption tuning Inspector authority kaybolmuş"),
        ('@export_range(0.0, 5.0, 0.05) var hurt_audio_cooldown := 0.90', "Player hurt cooldown tuning Inspector authority kaybolmuş"),
        ("var health := 0", "Player public health compatibility alanı kaybolmuş"),
        ("var armor := 0", "Player public armor compatibility alanı kaybolmuş"),
        ("var is_dead := false", "Player public is_dead compatibility alanı kaybolmuş"),
        ("_survivability_runtime := VexPlayerSurvivabilityRuntime.new()", "Player survivability helper oluşturmuyor"),
        ("_survivability_runtime.sync_state(health, armor, is_dead)", "Player public survivability facade helper'a senkron olmuyor"),
        ("health = _survivability_runtime.get_health()", "Player helper health state'ini facade'a geri taşımıyor"),
        ("armor = _survivability_runtime.get_armor()", "Player helper armor state'ini facade'a geri taşımıyor"),
        ("is_dead = _survivability_runtime.get_is_dead()", "Player helper dead state'ini facade'a geri taşımıyor"),
        ("_survivability_runtime.collect_health(amount)", "Player health pickup'ı helper'a devretmiyor"),
        ("_survivability_runtime.collect_armor(amount)", "Player armor pickup'ı helper'a devretmiyor"),
        ("_survivability_runtime.apply_damage(", "Player damage çözümünü helper'a devretmiyor"),
        ("_survivability_runtime.restore_state(", "Player save restore survivability helper kullanmıyor"),
        ("_survivability_runtime.force_dead()", "Player death state helper ile senkron değil"),
        ("GameState.report_damage(health_damage)", "Player damage GameState raporlamasını kaybetmiş"),
        ("hurt_audio.play()", "Player hurt audio side effect sahipliğini kaybetmiş"),
        ("GameState.report_player_death()", "Player death side effect sahipliğini kaybetmiş"),
    ]:
        require(player, contract, message)

    for forbidden, message in [
        ("_hurt_audio_cooldown_remaining", "Hurt cooldown state hâlâ Player'da tutuluyor"),
        ("int(round(float(amount) * armor_absorption_ratio))", "Armor absorption hesabı hâlâ Player'da"),
    ]:
        forbid(player, forbidden, message)

    for message in ERRORS:
        print("ERROR:", message)
    print(f"PLAYER SURVIVABILITY ARCHITECTURE AUDIT: {len(ERRORS)} hata")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
