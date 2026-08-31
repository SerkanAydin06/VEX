#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import math
import re

ROOT = Path(__file__).resolve().parents[1]
SCENES = ROOT / "scenes"
ACTORS = SCENES / "actors"

CREATURE_CAPSULES = {
    "ravager": (0.42, 1.80),
    "basalt_juggernaut": (1.00, 3.60),
    "veilmaw": (0.45, 1.90),
    "voidweaver": (0.45, 1.90),
    "furnice_carrier": (0.58, 1.50),
    "crucible_warden": (0.72, 2.40),
    "cinder_spitter": (0.44, 1.75),
    "coil_lancer": (0.46, 1.90),
    "redviper": (0.42, 1.80),
    "badredviper": (0.82, 3.10),
    "cinderhound": (0.44, 1.45),
    "briar_skulker": (0.38, 1.60),
    "gorehorn": (0.72, 2.40),
}


def node_body(source: str, node_name: str) -> str:
    match = re.search(
        rf'^\[node name="{re.escape(node_name)}"[^\n]*\]\n(.*?)(?=^\[node |\Z)',
        source,
        re.M | re.S,
    )
    assert match is not None, node_name
    return match.group(1)


def transform_y(body: str) -> float:
    transform = re.search(r'^transform = Transform3D\(([^\n]+)\)$', body, re.M)
    if transform is not None:
        return float(transform.group(1).split(",")[-2].strip())
    position = re.search(r'^position = Vector3\(([^\n]+)\)$', body, re.M)
    if position is not None:
        return float(position.group(1).split(",")[1].strip())
    return 0.0


for creature, (expected_radius, expected_height) in CREATURE_CAPSULES.items():
    scene_path = ACTORS / f"{creature}.tscn"
    assert scene_path.exists(), scene_path
    source = scene_path.read_text(encoding="utf-8")

    root = re.search(
        r'^\[node name="[^"]+" type="CharacterBody3D"[^\n]*\]\n(.*?)(?=^\[node |\Z)',
        source,
        re.M | re.S,
    )
    assert root is not None, creature
    root_body = root.group(1)
    assert re.search(r'^collision_layer = 4$', root_body, re.M), creature
    assert re.search(r'^collision_mask = 15$', root_body, re.M), creature
    assert re.search(r'^floor_snap_length = 0\.3$', root_body, re.M), creature
    assert re.search(r'^safe_margin = 0\.06$', root_body, re.M), creature

    capsule = re.search(
        r'\[sub_resource type="CapsuleShape3D"[^\n]*\]\n(.*?)(?=\n\[|\Z)',
        source,
        re.S,
    )
    assert capsule is not None, creature
    capsule_body = capsule.group(1)
    radius = float(re.search(r'^radius = ([0-9.]+)$', capsule_body, re.M).group(1))
    height = float(re.search(r'^height = ([0-9.]+)$', capsule_body, re.M).group(1))
    assert math.isclose(radius, expected_radius, abs_tol=0.0001), (creature, radius)
    assert math.isclose(height, expected_height, abs_tol=0.0001), (creature, height)
    assert height >= radius * 2.0, (creature, "geçersiz kapsül oranı")

    collision = node_body(source, "CollisionShape3D")
    assert 'shape = SubResource("' in collision, creature
    assert math.isclose(transform_y(collision), 0.0, abs_tol=0.0001), (
        creature,
        "CollisionShape kök/pivot merkezinde değil",
    )

    sprite = node_body(source, "AnimatedSprite3D")
    assert re.search(r'^billboard = 2$', sprite, re.M), (creature, "karakter Y-billboard değil")
    assert re.search(r'^cast_shadow = 0$', sprite, re.M), creature

    shadow = node_body(source, "GroundShadow")
    assert re.search(r'^billboard = 2$', shadow, re.M), (creature, "gölge Y-billboard değil")
    assert re.search(r'^cast_shadow = 0$', shadow, re.M), creature
    assert re.search(r'^render_priority = -2$', shadow, re.M), creature
    assert re.search(r'^offset = Vector2\(0, 16\)$', shadow, re.M), (
        creature,
        "GroundShadow ayaklardan görüş yönüne ayrılmıyor",
    )
    shadow_alpha = re.search(
        r'^modulate = Color\(1, 1, 1, ([0-9.]+)\)$', shadow, re.M
    )
    assert shadow_alpha is not None, creature
    assert 0.48 <= float(shadow_alpha.group(1)) <= 0.56, (
        creature,
        "GroundShadow opaklığı ayak siluetini bozuyor",
    )
    floor_gap = transform_y(shadow) + height * 0.5
    assert math.isclose(floor_gap, 0.02, abs_tol=0.001), (
        creature,
        "GroundShadow zemin payı",
        floor_gap,
    )

for scene_path in SCENES.rglob("*.tscn"):
    source = scene_path.read_text(encoding="utf-8")
    for match in re.finditer(
        r'^\[node name="([^"]*)" type="CollisionShape3D"[^\n]*\]\n(.*?)(?=^\[node |\Z)',
        source,
        re.M | re.S,
    ):
        assert re.search(r'^shape = (?:SubResource|ExtResource)\("', match.group(2), re.M), (
            scene_path.relative_to(ROOT),
            match.group(1),
            "CollisionShape3D shape kaynağı eksik",
        )

print("enemy scene physics audit passed")
