import re
from pathlib import Path

from translation_text import load_translations


ROOT = Path(__file__).resolve().parents[1]
SOURCE_SUFFIXES = {".gd", ".tscn", ".tres", ".cfg", ".godot"}
SKIPPED_DIRS = {".godot", ".git", "assets", "build"}
# Planlı içerik için bilerek tutulan anahtarlar (Weapons_VEX.md / Bölüm 2 bypass kuplörü).
RESERVED_KEYS = {"HUD_SLOT_05", "HUD_AMMO_MAGNUM", "CH02_BYPASS_RESERVED"}


def _source_text() -> str:
    parts = []
    for path in ROOT.rglob("*"):
        if path.suffix not in SOURCE_SUFFIXES or not path.is_file():
            continue
        if SKIPPED_DIRS.intersection(path.relative_to(ROOT).parts):
            continue
        parts.append(path.read_text(encoding="utf-8", errors="ignore"))
    return "\n".join(parts)


def test_every_translation_row_is_referenced_by_game_content() -> None:
    source = _source_text()
    identifiers = set(re.findall(r"[A-Z][A-Z0-9_]+", source))
    unused = sorted(
        key
        for key in load_translations()
        if key not in RESERVED_KEYS
        and (key not in identifiers if re.fullmatch(r"[A-Z][A-Z0-9_]+", key) else key not in source)
    )
    assert not unused, f"kullanılmayan çeviri satırları: {unused}"


def test_translation_keys_are_identifiers_not_text() -> None:
    bad = sorted(key for key in load_translations() if not re.fullmatch(r"[A-Z][A-Z0-9_]*", key))
    assert not bad, f"anahtar olarak metin kullanan satırlar: {bad}"


TRANSLATED_FIELD = re.compile(
    r"^(display_name|[a-z_]*message|objective[a-z_]*|required_key_label|log_title|room_name|header_text)"
    r' = "([^"]+)"$'
)
# Dilden bağımsız tabela kodları (ör. "R03 // SEC", "VEX // 01") çeviri anahtarı gerektirmez.
SIGNAGE_CODE = re.compile(r"[A-Z0-9-]+ // [A-Z0-9-]+")


def test_scene_text_fields_use_translation_keys() -> None:
    keys = set(load_translations())
    bad = []
    for path in sorted((ROOT / "scenes").rglob("*.tscn")) + sorted((ROOT / "resources").rglob("*.tres")):
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            match = TRANSLATED_FIELD.match(line.strip())
            if match is None:
                continue
            value = match.group(2)
            if value in keys or value.startswith(("res://", "uid://")) or SIGNAGE_CODE.fullmatch(value):
                continue
            bad.append(f"{path.relative_to(ROOT)}:{number}: {match.group(1)} = {value!r}")
    assert not bad, "çeviri anahtarı yerine düz metin: " + "; ".join(bad)


if __name__ == "__main__":
    # Betik olarak çalıştırıldığında (validate_local.ps1) test_ fonksiyonlarını
    # tanım sırasıyla çalıştır; pytest gerekmez.
    _audit_tests = [value for name, value in list(globals().items()) if name.startswith("test_") and callable(value)]
    for _audit_test in _audit_tests:
        _audit_test()
    print(f"{__file__.rsplit('/', 1)[-1]}: {len(_audit_tests)} test passed")
