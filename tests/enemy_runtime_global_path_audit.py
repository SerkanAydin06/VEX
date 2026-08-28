from pathlib import Path

r = Path("scripts/actors/ravager.gd").read_text(encoding="utf-8")
w = Path("scripts/actors/crucible_warden.gd").read_text(encoding="utf-8")

for token in [
    "func _build_runtime_shortest_path(destination: Vector3)",
    "runtime_grid_max_nodes",
    "runtime_grid_search_margin",
    "_runtime_grid_heap_push",
    "_runtime_grid_heap_pop",
    "_simplify_runtime_grid_path",
    "if state == State.CHASE:",
    "_current_path = _build_runtime_shortest_path(destination)",
]:
    assert token in r, token

assert "func _refresh_warden_collision_detour" not in w
assert "var _warden_detour_direction" not in w
assert "_navigate_to(_player.global_position, delta)" in w
print("enemy runtime global path audit passed")
