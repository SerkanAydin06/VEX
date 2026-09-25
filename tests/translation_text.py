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
