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
    interaction = read("scripts/player/player_interaction_runtime.gd")
    pickup_runtime = read("scripts/player/player_pickup_runtime.gd")
    pickup = read("scripts/props/pickup.gd")

    for contract, message in [
        ("class_name VexPlayerInteractionRuntime", "Interaction runtime class_name eksik"),
        ("extends RefCounted", "Interaction runtime RefCounted değil"),
        ("func resolve_interactable(", "Interaction target çözümü runtime'da değil"),
        ("func try_interact(", "Interaction çağrısı runtime'da değil"),
        ("func get_interaction_prompt(", "Interaction prompt runtime'da değil"),
    ]:
        require(interaction, contract, message)

    for forbidden, message in [
        ("GameState", "Interaction runtime GameState'e bağımlı"),
        ("Input.", "Interaction runtime Input'a bağımlı"),
        ("get_tree()", "Interaction runtime SceneTree'ye bağımlı"),
    ]:
        forbid(interaction, forbidden, message)

    for contract, message in [
        ("class_name VexPlayerPickupRuntime", "Pickup runtime class_name eksik"),
        ("extends RefCounted", "Pickup runtime RefCounted değil"),
        ("func collect_pickup(", "Pickup routing runtime'da değil"),
        ("func restore_state(", "Pickup ownership restore runtime'da değil"),
        ("func has_key(", "Key ownership runtime'da değil"),
        ("func owns_night_vision(", "Night vision ownership runtime'da değil"),
        ("weapon_controller.call(\"add_ammo\"", "Ammo pickup WeaponController'a runtime üzerinden gitmiyor"),
        ("weapon_controller.call(\"equip_world_weapon\"", "World weapon pickup runtime üzerinden gitmiyor"),
        ("weapon_controller.call(\"unlock_weapon\"", "Direct weapon pickup runtime üzerinden gitmiyor"),
        ("survivability.collect_health(amount)", "Health pickup survivability runtime'a delege edilmiyor"),
        ("survivability.collect_armor(amount)", "Armor pickup survivability runtime'a delege edilmiyor"),
    ]:
        require(pickup_runtime, contract, message)

    for forbidden, message in [
        ("GameState", "Pickup runtime GameState side effect'i yapıyor"),
        ('tr("', "Pickup runtime çeviri/UI sahipliği almış"),
        ("instantiate", "Pickup runtime scene spawn ediyor"),
        ("get_tree()", "Pickup runtime SceneTree'ye bağımlı"),
    ]:
        forbid(pickup_runtime, forbidden, message)

    for contract, message in [
        ("_interaction_runtime := VexPlayerInteractionRuntime.new()", "Player interaction runtime oluşturmuyor"),
        ("_pickup_runtime := VexPlayerPickupRuntime.new()", "Player pickup runtime oluşturmuyor"),
        ("_interaction_runtime.try_interact(", "Player interact çağrısını runtime'a devretmiyor"),
        ("_interaction_runtime.get_interaction_prompt(", "Player prompt çağrısını runtime'a devretmiyor"),
        ("_pickup_runtime.collect_pickup(", "Player pickup routing'i runtime'a devretmiyor"),
        ("func _apply_pickup_feedback(", "Player pickup UI/scene side effect facade'ı eksik"),
        ("GameState.notify_pickup(", "Pickup bildirimleri Player'da kalmıyor"),
        ("DROPPED_WEAPON_PICKUP_SCENE.instantiate()", "Dropped weapon scene spawn Player'da kalmıyor"),
        ("_pickup_runtime.restore_state(", "Player save restore pickup runtime kullanmıyor"),
    ]:
        require(player, contract, message)

    for forbidden, message in [
        ("func _resolve_interactable(", "Legacy interaction çözümü hâlâ Player'da"),
        ("func _collect_loadout_weapon_pickup(", "Legacy world pickup orchestration hâlâ Player'da"),
        ('weapon_controller.call("add_ammo", pickup_type, amount)', "Ammo pickup routing hâlâ Player'da"),
    ]:
        forbid(player, forbidden, message)

    connect_contract = "body_entered.connect(_on_body_entered)"
    visual_guard = "if visual == null or visual_pivot == null:"
    require(pickup, connect_contract, "Pickup body_entered bağlantısı eksik")
    require(pickup, visual_guard, "Pickup visual fail-safe guard eksik")
    if connect_contract in pickup and visual_guard in pickup:
        if pickup.index(connect_contract) > pickup.index(visual_guard):
            ERRORS.append("Pickup body_entered bağlantısı visual guard'dan sonra; görselsiz pickup toplanamaz")
    require(pickup, "if visual != null:\n\t\tvisual.visible = false", "Görselsiz pickup collection visual guard'ı eksik")

    for message in ERRORS:
        print("ERROR:", message)
    print(f"PLAYER INTERACTION PICKUP ARCHITECTURE AUDIT: {len(ERRORS)} hata")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
