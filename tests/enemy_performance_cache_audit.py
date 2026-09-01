from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANAGER = ROOT / "scripts" / "autoload" / "enemy_performance_manager.gd"


def main() -> int:
    text = MANAGER.read_text(encoding="utf-8")
    errors: list[str] = []

    required = [
        "_prune_stale_profiles(enemies)",
        "func _prune_stale_profiles(enemies: Array[Node]) -> void:",
        "for key: Variant in _profiles.keys():",
        "_profiles.erase(key)",
        "_profiles.erase(dead_key)",
    ]
    for token in required:
        if token not in text:
            errors.append(f"Enemy performance cache cleanup token missing: {token}")

    prune_call = text.find("_prune_stale_profiles(enemies)")
    player_guard = text.find("var player := GameState.player as Node3D")
    if prune_call < 0 or player_guard < 0 or prune_call > player_guard:
        errors.append("Stale profile pruning must run even when no player is registered.")

    dead_guard = text.find("if _is_enemy_dead(enemy):")
    ensure_profile = text.find("var profile := _ensure_profile(enemy, family)")
    if dead_guard < 0 or ensure_profile < 0 or dead_guard > ensure_profile:
        errors.append("Dead enemies must be handled before creating/recreating a performance profile.")

    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1

    print("Enemy performance cache audit passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
