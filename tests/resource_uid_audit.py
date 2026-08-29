#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return ""


def canonical_uids() -> dict[str, str]:
    result: dict[str, str] = {}
    for uid_path in ROOT.rglob("*.uid"):
        value = read(uid_path).strip()
        if value.startswith("uid://"):
            result[uid_path.relative_to(ROOT).as_posix()[:-4]] = value
    for import_path in ROOT.rglob("*.import"):
        match = re.search(r'^uid="(uid://[^"]+)"', read(import_path), re.M)
        if match:
            result[import_path.relative_to(ROOT).as_posix()[:-7]] = match.group(1)
    for pattern in ("*.tscn", "*.tres"):
        for resource_path in ROOT.rglob(pattern):
            match = re.search(r'^\[(?:gd_scene|gd_resource)[^\]]*\buid="(uid://[^"]+)"', read(resource_path), re.M)
            if match:
                result[resource_path.relative_to(ROOT).as_posix()] = match.group(1)
    return result


def main() -> int:
    canonical = canonical_uids()
    for script_path in ROOT.rglob("*.gd"):
        relative = script_path.relative_to(ROOT).as_posix()
        if relative.startswith(".godot/"):
            continue
        if not (ROOT / f"{relative}.uid").exists():
            ERRORS.append(f"GDScript UID eşlikçisi eksik: {relative}.uid")
    for extension in ("*.png", "*.wav", "*.mp3", "*.ttf"):
        for asset_path in ROOT.rglob(extension):
            relative = asset_path.relative_to(ROOT).as_posix()
            if not (ROOT / f"{relative}.import").exists():
                ERRORS.append(f"Import metadata eksik: {relative}.import")
    header_pattern = re.compile(r'^\[ext_resource[^\]]*\]', re.M)
    for pattern in ("*.tscn", "*.tres"):
        for source_path in ROOT.rglob(pattern):
            source = read(source_path)
            for header in header_pattern.findall(source):
                path_match = re.search(r'\bpath="res://([^"]+)"', header)
                uid_match = re.search(r'\buid="(uid://[^"]+)"', header)
                if path_match is None or uid_match is None:
                    continue
                target = path_match.group(1)
                expected = canonical.get(target)
                if expected is not None and uid_match.group(1) != expected:
                    ERRORS.append(
                        f"UID uyumsuzluğu: {source_path.relative_to(ROOT)} -> "
                        f"{target}: {uid_match.group(1)} != {expected}"
                    )
    for message in ERRORS:
        print("ERROR:", message)
    print(f"RESOURCE UID VALIDATOR: {len(ERRORS)} hata")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
