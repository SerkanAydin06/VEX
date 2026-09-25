"""Denetimler için ortak yardımcı: betikteki tr("ANAHTAR") çağrılarını çeviri metinleriyle genişletir.

Metinler koddan translations/*.csv'ye taşındıkça eski metin sözleşmeleri (ör. '"KAYITLAR"' in script)
geçerli kalsın diye kullanılır. Değerler CSV'deki kaçışlı hâliyle (\\n) GDScript kaynağıyla aynıdır.
"""
import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TRANSLATION_FILES = sorted((ROOT / "translations").glob("*.csv"))


def load_translations() -> dict[str, tuple[str, str]]:
    rows: dict[str, tuple[str, str]] = {}
    for path in TRANSLATION_FILES:
        with path.open(encoding="utf-8", newline="") as handle:
            for row in csv.reader(handle):
                if len(row) >= 3 and row[0] != "keys":
                    rows[row[0]] = (row[1], row[2])
    return rows


def with_translations(script: str) -> str:
    """Betik metnine, kullandığı her tr("KEY") için '"tr"' ve '"en"' satırlarını ekler."""
    translations = load_translations()
    extra = []
    for key in dict.fromkeys(re.findall(r'\btr\("([A-Z0-9_]+)"\)', script)):
        assert key in translations, f"missing translation key: {key}"
        turkish, english = translations[key]
        extra.append(f'"{turkish}"\n"{english}"')
    return script + "\n# --- translations ---\n" + "\n".join(extra)


def assert_ui_text_in_translations(script: str, min_keys: int) -> None:
    """Betikte gömülü _t("tr", "en") kalmadığını ve her tr() anahtarının iki dilde dolu olduğunu doğrular."""
    translations = load_translations()
    assert "func _t(" not in script
    assert re.search(r"(?<![\w.])_t\(", script) is None
    # Oyuncu metnini dile göre seçen kalıplar (veri soneki "_tr"/"_en" seçimi hariç).
    assert re.search(r'"[^"_][^"]*" if [^\n]*begins_with\("tr"\)', script) is None
    assert re.search(r"if (?:not )?(?:is_)?turkish\b", script) is None
    assert re.search(r'if TranslationServer\.get_locale\(\)\.begins_with\("tr"\):', script) is None
    keys = set(re.findall(r'\btr\("([A-Z0-9_]+)"\)', script))
    assert len(keys) >= min_keys, len(keys)
    missing = sorted(key for key in keys if key not in translations)
    assert not missing, missing
    for key in keys:
        turkish, english = translations[key]
        assert turkish and english, key
        assert turkish.count("%") == english.count("%"), key
