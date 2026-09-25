from pathlib import Path

from translation_text import assert_ui_text_in_translations


ROOT = Path(__file__).resolve().parents[1]
# Metinleri translations/*.csv'ye taşınmış betikler; yeni taşınan dosyayı buraya ekle.
MIGRATED_SCRIPTS = {
    "scripts/ui/vex_archive_terminal.gd": 100,
    "scripts/ui/weapon_archive_terminal.gd": 30,
    "scripts/ui/base_management_dashboard.gd": 25,
    "scripts/ui/field_record_archive_bridge.gd": 8,
}


def test_migrated_scripts_keep_ui_text_in_translations() -> None:
    for relative_path, min_keys in MIGRATED_SCRIPTS.items():
        script = (ROOT / relative_path).read_text(encoding="utf-8")
        try:
            assert_ui_text_in_translations(script, min_keys)
        except AssertionError as error:
            raise AssertionError(f"{relative_path}: {error}") from error


if __name__ == "__main__":
    # Betik olarak çalıştırıldığında (validate_local.ps1) test_ fonksiyonlarını
    # tanım sırasıyla çalıştır; pytest gerekmez.
    _audit_tests = [value for name, value in list(globals().items()) if name.startswith("test_") and callable(value)]
    for _audit_test in _audit_tests:
        _audit_test()
    print(f"{__file__.rsplit('/', 1)[-1]}: {len(_audit_tests)} test passed")
