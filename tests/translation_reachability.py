"""Oyuncunun gerçekten görebileceği kaynak metnini toplar (denetim yardımcısı).

- tests/ altındaki deneme sahneleri sayılmaz.
- level_0N_structure_source.tscn içinden yalnız VexBaseLevel'in kurduğu kökler
  (level_0N.gd STRUCTURE_NODE_NAMES) sayılır; kök düğümün kendi alanları kurulmaz.
- Kurulan kapılarda _reset_authored_door'un sildiği alanlar ve
  _configure_access_door'un üzerine yazdığı display_name sayılmaz.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_SUFFIXES = {".gd", ".tscn", ".tres", ".cfg", ".godot"}
SKIPPED_DIRS = {".godot", ".git", "assets", "build", "tests"}
RESET_DOOR_FIELDS = {"required_key_label", "objective_on_unlock", "objective_on_combat_clear"}


def _level_installation(level_script: Path) -> tuple[set[str], set[str]]:
    script = level_script.read_text(encoding="utf-8")
    block = re.search(r"STRUCTURE_NODE_NAMES := \[(.*?)\]", script, re.S)
    roots = set(re.findall(r'&"([^"]+)"', block.group(1))) if block else set()
    configured = set(re.findall(r'doors_root\.get_node_or_null\("([^"]+)"\)', script))
    return roots, configured


def _structure_live_text(path: Path, roots: set[str], configured_doors: set[str]) -> str:
    live = []
    include = False
    door_name = ""
    for line in path.read_text(encoding="utf-8").splitlines():
        header = re.match(r'\[node name="([^"]+)"(?:[^\]]*?parent="([^"]*)")?', line)
        if header:
            name, parent = header.group(1), header.group(2)
            top = name if parent == "." else (parent.split("/")[0] if parent else "")
            include = parent is not None and top in roots
            door_name = name if parent == "Doors" else ""
            continue
        if line.startswith("["):
            include = False
            continue
        if not include:
            continue
        field = line.split(" = ", 1)[0]
        if door_name and field in RESET_DOOR_FIELDS:
            continue
        if door_name in configured_doors and field == "display_name":
            continue
        live.append(line)
    return "\n".join(live)


def live_source_files() -> list[tuple[Path, str]]:
    """Her kaynak dosya için oyuna gerçekten giren metni döndürür."""
    files = []
    for path in sorted(ROOT.rglob("*")):
        if path.suffix not in SOURCE_SUFFIXES or not path.is_file():
            continue
        if SKIPPED_DIRS.intersection(path.relative_to(ROOT).parts):
            continue
        match = re.fullmatch(r"(level_\d\d)_structure_source\.tscn", path.name)
        if match:
            roots, configured = _level_installation(ROOT / "scripts/levels" / f"{match.group(1)}.gd")
            files.append((path, _structure_live_text(path, roots, configured)))
            continue
        files.append((path, path.read_text(encoding="utf-8", errors="ignore")))
    return files


def live_source_text() -> str:
    return "\n".join(text for _path, text in live_source_files())
