#!/usr/bin/env python3
"""Prevent Godot MISSING_TOOL warnings in script inheritance chains."""

from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
CLASS_NAME = re.compile(r"(?m)^class_name\s+([A-Za-z_][A-Za-z0-9_]*)\b")
BASE_CLASS = re.compile(r"(?m)^extends\s+([A-Za-z_][A-Za-z0-9_]*)\b")
BASE_PATH = re.compile(r'(?m)^extends\s+"res://([^"]+\.gd)"')
TOOL = re.compile(r"(?m)^@tool\s*$")


def test_tool_script_inheritance() -> None:
    scripts = {
        file.relative_to(ROOT).as_posix(): file.read_text(encoding="utf-8")
        for file in ROOT.rglob("*.gd")
        if ".godot" not in file.parts
    }
    declared_classes = {}
    for path, source in scripts.items():
        match = CLASS_NAME.search(source)
        if match:
            declared_classes[match.group(1)] = path

    violations = []
    for path, source in scripts.items():
        parent_match = BASE_CLASS.search(source)
        parent = declared_classes.get(parent_match.group(1)) if parent_match else None
        path_match = BASE_PATH.search(source)
        if path_match:
            parent = path_match.group(1)

        if parent in scripts and TOOL.search(scripts[parent]) and not TOOL.search(source):
            violations.append(f"{path} inherits @tool script {parent} without @tool")

    assert not violations, "\n".join(violations)
    assert TOOL.search(scripts["scripts/levels/base_level.gd"])
    assert TOOL.search(scripts["scripts/levels/level_test.gd"])


if __name__ == "__main__":
    test_tool_script_inheritance()
    print("tool inheritance audit passed")
