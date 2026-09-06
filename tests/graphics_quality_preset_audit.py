from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SETTINGS_PATH = ROOT / "scripts" / "autoload" / "settings_manager.gd"
PROJECT_PATH = ROOT / "project.godot"


def require(text: str, snippet: str, message: str) -> None:
    if snippet not in text:
        raise AssertionError(message)


def main() -> None:
    settings = SETTINGS_PATH.read_text(encoding="utf-8")
    project = PROJECT_PATH.read_text(encoding="utf-8")

    require(
        project,
        'renderer/rendering_method="gl_compatibility"',
        "VEX graphics preset audit expects the Compatibility renderer.",
    )
    require(
        project,
        'gl_compatibility/driver.windows="opengl3_angle"',
        "VEX Windows renderer should remain ANGLE/OpenGL Compatibility.",
    )

    require(
        settings,
        "const GRAPHICS_NATIVE_RENDER_SCALE := 1.0",
        "Compatibility presets must keep the 3D render buffer at native scale.",
    )
    for stale_scale in (
        "performance_render_scale := 0.75",
        "balanced_render_scale := 0.85",
    ):
        if stale_scale in settings:
            raise AssertionError(f"Stale undersampling preset remains: {stale_scale}")

    required_profile_defaults = (
        "performance_shadow_atlas_size := 1024",
        "balanced_shadow_atlas_size := 2048",
        "high_shadow_atlas_size := 2048",
        "performance_shadow_atlas_16_bits := true",
        "balanced_shadow_atlas_16_bits := true",
        "high_shadow_atlas_16_bits := false",
        "performance_mesh_lod_threshold := 2.0",
        "balanced_mesh_lod_threshold := 1.35",
        "high_mesh_lod_threshold := 1.0",
    )
    for snippet in required_profile_defaults:
        require(settings, snippet, f"Missing graphics profile default: {snippet}")

    required_runtime_application = (
        "root_viewport.scaling_3d_scale = GRAPHICS_NATIVE_RENDER_SCALE",
        'root_viewport.positional_shadow_atlas_size = int(profile["shadow_atlas_size"])',
        'root_viewport.positional_shadow_atlas_16_bits = bool(profile["shadow_atlas_16_bits"])',
        'root_viewport.mesh_lod_threshold = float(profile["mesh_lod_threshold"])',
        "func get_graphics_quality_profile(value: int = -1) -> Dictionary:",
    )
    for snippet in required_runtime_application:
        require(settings, snippet, f"Graphics preset runtime application is incomplete: {snippet}")

    set_quality_start = settings.index("func set_graphics_quality(value: int) -> void:")
    set_quality_end = settings.index("\n\nfunc apply_graphics_quality()", set_quality_start)
    set_quality_body = settings[set_quality_start:set_quality_end]
    require(
        set_quality_body,
        "settings_applied.emit()",
        "Changing graphics quality must notify runtime listeners.",
    )

    print("graphics_quality_preset_audit: OK")


if __name__ == "__main__":
    main()
