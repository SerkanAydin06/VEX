#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

def read(path):
    full = ROOT / path
    if not full.exists():
        errors.append(f"Eksik impact V1 dosyası: {path}")
        return ""
    return full.read_text(encoding="utf-8")

effect = read("scripts/effects/hit_impact_v1.gd")
controller = read("scripts/player/weapon_controller.gd")

for needle in [
    "class_name VexHitImpactV1",
    "impact_world_v1.png",
    "impact_flesh_v1.png",
    "func spawn_world(",
    "func spawn_flesh(",
    "GPUParticles3D.new()",
    "MAX_WORLD_IMPACTS := 72",
    "MAX_FLESH_IMPACTS := 24",
    "ResourceLoader.exists(path)",
]:
    if needle not in effect:
        errors.append(f"Impact effect sözleşmesi eksik: {needle}")

for needle in [
    'preload("res://scripts/effects/hit_impact_v1.gd")',
    "MAX_WORLD_IMPACTS_PER_TRIGGER := 4",
    'result.get("normal", -direction)',
    "pending_hit_normals",
    "HIT_IMPACT_V1.spawn_world(",
    "HIT_IMPACT_V1.spawn_flesh(",
    'damage_target.is_in_group("enemy")',
]:
    if needle not in controller:
        errors.append(f"WeaponController impact sözleşmesi eksik: {needle}")

if errors:
    print("HIT IMPACT V1 AUDIT FAILED:")
    for error in errors:
        print(" -", error)
    sys.exit(1)
print("HIT IMPACT V1 AUDIT OK")
