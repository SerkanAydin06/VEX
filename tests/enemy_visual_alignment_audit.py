from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SCENES = (
    "cinderhound.tscn",
    "gorehorn.tscn",
    "rift_reaver.tscn",
    "vaskari_raptor.tscn",
)
NUMBER = r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:e[-+]?\d+)?"


def _scalar(text: str, name: str, default: float | None = None) -> float:
    match = re.search(rf"(?m)^{re.escape(name)} = ({NUMBER})$", text)
    if match:
        return float(match.group(1))
    if default is not None:
        return default
    raise AssertionError(f"{name} missing")


def _final_death_offset(text: str) -> float:
    match = re.search(
        r"(?m)^death_frame_y_offsets = PackedFloat32Array\(([^)]*)\)$",
        text,
    )
    assert match, "death_frame_y_offsets missing"
    values = [float(value.strip()) for value in match.group(1).split(",") if value.strip()]
    assert values, "death_frame_y_offsets empty"
    return values[-1]


def _visual_base_y(text: str) -> float:
    match = re.search(
        r'\[node name="AnimatedSprite3D"[^\]]*\]\n(.*?)(?=\n\[node|\Z)',
        text,
        re.S,
    )
    assert match, "AnimatedSprite3D node missing"
    block = match.group(1)

    position = re.search(
        rf"(?m)^position = Vector3\(({NUMBER}),\s*({NUMBER}),\s*({NUMBER})\)$",
        block,
    )
    if position:
        return float(position.group(2))

    transform = re.search(r"(?m)^transform = Transform3D\(([^)]*)\)$", block)
    if transform:
        values = [float(value.strip()) for value in transform.group(1).split(",")]
        assert len(values) == 12, "unexpected Transform3D layout"
        return values[10]

    return 0.0


for scene_name in SCENES:
    text = (ROOT / "scenes/actors" / scene_name).read_text(encoding="utf-8")
    corpse_y = _scalar(text, "corpse_visual_y")
    clearance = _scalar(text, "corpse_floor_clearance", 0.02)
    expected_final_y = _visual_base_y(text) + _final_death_offset(text)
    actual_final_y = corpse_y + clearance
    assert abs(actual_final_y - expected_final_y) <= 0.0005, (
        f"{scene_name}: corpse jump detected "
        f"(expected y={expected_final_y:.6f}, actual y={actual_final_y:.6f})"
    )

print("enemy visual alignment audit passed")
