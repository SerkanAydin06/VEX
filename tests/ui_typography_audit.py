#!/usr/bin/env python3
"""Check professional VEX text hierarchy without relying on a running Godot editor."""

from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
FONT_ROOT = ROOT / "resources/ui/fonts"
SCENE_ROOT = ROOT / "scenes/ui"


def test_shared_font_families_and_theme() -> None:
    for name, weight, family in [
        ("vex_body_font.tres", 400, "Segoe UI"),
        ("vex_heading_font.tres", 600, "Segoe UI"),
        ("vex_mono_font.tres", 400, "Consolas"),
    ]:
        source = (FONT_ROOT / name).read_text(encoding="utf-8")
        assert '[gd_resource type="SystemFont"' in source, name
        assert f"font_weight = {weight}" in source, name
        assert family in source, name

    theme = (ROOT / "resources/ui/vex_theme.tres").read_text(encoding="utf-8")
    for contract in [
        'default_font = ExtResource("1_body_font")',
        'Button/fonts/font = ExtResource("2_heading_font")',
        'Label/fonts/font = ExtResource("1_body_font")',
        'RichTextLabel/fonts/normal_font = ExtResource("1_body_font")',
        'RichTextLabel/fonts/bold_font = ExtResource("2_heading_font")',
        'RichTextLabel/fonts/mono_font = ExtResource("3_mono_font")',
        'LineEdit/fonts/font = ExtResource("1_body_font")',
        'TextEdit/fonts/font = ExtResource("1_body_font")',
    ]:
        assert contract in theme, f"Missing typography theme contract: {contract}"
    assert "default_font = ExtResource(\"1_ui_font\")" not in theme


def test_ui_scenes_do_not_return_to_micro_fonts() -> None:
    for scene in SCENE_ROOT.glob("*.tscn"):
        source = scene.read_text(encoding="utf-8")
        sizes = [
            int(v) for v in re.findall(
                r"theme_override_font_sizes/(?:normal_)?font_size = (\d+)", source
            )
        ]
        too_small = [size for size in sizes if size < 12]
        assert not too_small, f"{scene.name} has unreadable text sizes: {too_small}"
    base = (SCENE_ROOT / "base_management_dashboard.tscn").read_text(encoding="utf-8")
    assert base.count("theme_override_font_sizes/font_size = 12") >= 25
    assert "custom_minimum_size = Vector2(0, 52)" in base
    assert "custom_minimum_size = Vector2(0, 58)" in base


def test_tactical_mono_and_title_fonts_are_intentional() -> None:
    scenes = {
        "main_menu.tscn": 'theme_override_fonts/font = ExtResource("90_heading")',
        "hud.tscn": 'theme_override_fonts/font = ExtResource("90_heading")',
        "terminal_menu.tscn": 'theme_override_fonts/font = ExtResource("90_heading")',
        "vex_archive_terminal.tscn": 'theme_override_fonts/font = ExtResource("90_heading")',
        "weapon_archive_terminal.tscn": 'theme_override_fonts/font = ExtResource("90_heading")',
        "base_management_dashboard.tscn": 'theme_override_fonts/font = ExtResource("90_heading")',
    }
    for filename, contract in scenes.items():
        source = (SCENE_ROOT / filename).read_text(encoding="utf-8")
        assert contract in source, filename
        assert "vex_mono_bold.ttf" not in source, filename


def test_runtime_reader_uses_shared_theme() -> None:
    reader = (ROOT / "scripts/props/field_record_terminal.gd").read_text(encoding="utf-8")
    assert "panel.theme = READER_THEME" in reader
    assert '_reader_title.add_theme_font_override("font", READER_HEADING)' in reader
    assert '_reader_category.add_theme_font_override("font", READER_MONO)' in reader
    hub = (ROOT / "scripts/hub/hub_terminal.gd").read_text(encoding="utf-8")
    assert 'SCREEN_HEADING_FONT if node_name == "TitleLabel" else SCREEN_FONT' in hub


def test_world_labels_have_authored_fonts() -> None:
    for filename in [
        "scenes/hub/armory_category_rack.tscn",
        "scenes/hub/hub_weapon_rack.tscn",
        "scenes/hub/hub_survivor_presence.tscn",
        "scenes/hub/hub_terminal.tscn",
        "scenes/props/finish_switch.tscn",
        "scenes/props/survivor_rescue_terminal.tscn",
        "scenes/world/room_name_display.tscn",
        "scenes/world/exit_sign.tscn",
    ]:
        content = (ROOT / filename).read_text(encoding="utf-8")
        for block in re.split(r"(?=^\[node name=)", content, flags=re.MULTILINE):
            header = block.split("\n", 1)[0]
            if 'type="Label3D"' not in header:
                continue
            assert re.search(r'^font = ExtResource\("[^"]+"\)$', block, flags=re.MULTILINE), (
                f"Missing 3D label font in {filename}: {header}"
            )


if __name__ == "__main__":
    tests = [
        fn for name, fn in list(globals().items())
        if name.startswith("test_") and callable(fn)
    ]
    for test in tests:
        test()
    print(f"{Path(__file__).name}: {len(tests)} tests passed")
