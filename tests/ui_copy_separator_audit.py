#!/usr/bin/env python3
"""Catch mechanical slash separators in player-visible VEX copy."""

from __future__ import annotations

import csv
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
TRANSLATIONS = [
    ROOT / "translations" / "vex.csv",
    ROOT / "translations" / "chapter01.csv",
    ROOT / "translations" / "chapter02.csv",
    ROOT / "translations" / "chapter03.csv",
]


def test_localized_copy_has_clear_typographic_hierarchy() -> None:
    for path in TRANSLATIONS:
        with path.open(encoding="utf-8", newline="") as source:
            for row in csv.reader(source):
                assert len(row) == 3, f"{path}: broken TR/EN CSV row: {row!r}"
                key, turkish, english = row
                if key == "keys":
                    continue
                assert "//" not in turkish and "//" not in english, (
                    f"{path.name}: {key} still uses a slash separator"
                )
                assert turkish.strip() and english.strip(), f"{path.name}: empty translation {key}"


def test_playable_scenes_have_no_visible_slash_dividers() -> None:
    for path in (ROOT / "scenes").rglob("*.tscn"):
        for index, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            # Paths and Godot UIDs use ://; only user-visible slash dividers are prohibited.
            if " // " in line or "\\n// " in line:
                raise AssertionError(f"{path.relative_to(ROOT)}:{index}: {line.strip()}")


def test_runtime_copy_has_no_visible_slash_dividers() -> None:
    for path in (ROOT / "scripts").rglob("*.gd"):
        for index, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            if line.lstrip().startswith("#"):
                continue
            if " // " in line or "\\n// " in line:
                raise AssertionError(f"{path.relative_to(ROOT)}:{index}: {line.strip()}")


def test_chapter_headers_remain_canonical() -> None:
    expected = (
        ("chapter01.csv", "CH01_NAME", "BÖLÜM 01 — İLK KIRILMA", "CHAPTER 01 — FIRST FRACTURE"),
        ("chapter02.csv", "CH02_NAME", "BÖLÜM 02 — KÜL KORİDORU", "CHAPTER 02 — ASH CORRIDOR"),
        ("chapter03.csv", "CH03_NAME", "BÖLÜM 03 — BASINÇ HATTI", "CHAPTER 03 — PRESSURE LINE"),
    )
    for filename, key, turkish, english in expected:
        with (ROOT / "translations" / filename).open(encoding="utf-8", newline="") as source:
            rows = {row[0]: row[1:] for row in csv.reader(source)}
        assert rows[key] == [turkish, english], (filename, key, rows.get(key))


if __name__ == "__main__":
    tests = [
        value for name, value in list(globals().items())
        if name.startswith("test_") and callable(value)
    ]
    for test in tests:
        test()
    print(f"{Path(__file__).name}: {len(tests)} tests passed")
