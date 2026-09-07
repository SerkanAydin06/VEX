from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SETTINGS = ROOT / "scripts" / "autoload" / "settings_manager.gd"
CHAPTER02 = ROOT / "translations" / "chapter02.csv"


def test_chapter02_translations_are_registered_without_truncating_settings_manager() -> None:
    settings = SETTINGS.read_text(encoding="utf-8")
    chapter02 = CHAPTER02.read_text(encoding="utf-8")

    assert '"res://translations/chapter02.tr.translation"' in settings
    assert '"res://translations/chapter02.en.translation"' in settings
    assert "CH02_NAME,BÖLÜM 02 // KÜL KORİDORU,CHAPTER 02 // ASH CORRIDOR" in chapter02

    # Chapter-specific localization must not replace existing settings behavior.
    for preserved_api in [
        "func save_settings() -> bool:",
        "func apply_settings() -> void:",
        "func apply_graphics_quality() -> void:",
        "func get_graphics_quality_profile(value: int = -1) -> Dictionary:",
        "func rebind_key(action: StringName, keycode: Key) -> bool:",
        "func reset_keybindings() -> void:",
        "func _ensure_default_gamepad_bindings() -> void:",
        "func set_difficulty(value: int) -> void:",
    ]:
        assert preserved_api in settings

    for preserved_setting in [
        'config.set_value("display", "vsync", vsync)',
        'config.set_value("display", "graphics_quality", graphics_quality)',
        'root_viewport.scaling_3d_scale = GRAPHICS_NATIVE_RENDER_SCALE',
        'TranslationServer.add_translation(translation)',
    ]:
        assert preserved_setting in settings
