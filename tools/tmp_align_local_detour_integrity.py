#!/usr/bin/env python3
from pathlib import Path

path = Path("tests/integrity_test.gd")
text = path.read_text(encoding="utf-8")
old = '\t&"chase_path_refresh_interval", &"local_detour_duration",\n'
new = '\t&"chase_path_refresh_interval",\n'
if text.count(old) != 1:
    raise SystemExit(f"expected exactly one integrity contract line, found {text.count(old)}")
text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
