#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    path = ROOT / relative
    assert path.exists(), path
    return path.read_text(encoding="utf-8")


shader = read("shaders/enemy_sprite_lit.gdshader")
controller = read("scripts/actors/enemy_lit_animated_sprite_3d.gd")
profile_script = read("scripts/actors/enemy_sprite_visual_profile.gd")
gorehorn_profile = read("resources/enemies/gorehorn_visual_profile.tres")
gorehorn = read("scripts/actors/gorehorn.gd")
scene = read("scenes/actors/gorehorn.tscn")

assert "shader_type spatial" in shader
assert "NORMAL_MAP" in shader
assert "ROUGHNESS" in shader
assert "SPECULAR" in shader
assert "RIM = rim_strength" in shader
assert "AO =" in shader
assert "EMISSION =" in shader
assert "uniform vec4 uv_rect" in shader
assert "MODELVIEW_MATRIX" in shader
assert "camera_right" in shader
assert "discard" in shader

assert "class_name VexEnemySpriteLightingController" in controller
assert "frame_texture is AtlasTexture" in controller
assert 'set_shader_parameter(&"uv_rect"' in controller
assert "frame_changed.connect(_sync_frame_texture)" in controller
assert "animation_changed.connect(_sync_frame_texture)" in controller

assert "class_name VexEnemySpriteVisualProfile" in profile_script
assert "normal_strength" in gorehorn_profile
assert "cavity_strength" in gorehorn_profile
assert "rim_strength" in gorehorn_profile
assert "specular" in gorehorn_profile

assert 'preload("res://scripts/actors/enemy_lit_animated_sprite_3d.gd")' in gorehorn
assert 'preload("res://resources/enemies/gorehorn_visual_profile.tres")' in gorehorn
assert "super._ready()" in gorehorn
assert 'get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D' in gorehorn
assert "SpriteLighting" in gorehorn

# Pilot must not reduce sprite resolution or alter the authored animation sheet.
assert "pixel_size = 0.0052" in scene
assert "gorehorn_character_spritesheet.png" in scene
assert "341, 512" in scene
assert "pixel_size" not in shader

print("gorehorn visual pilot audit passed")
