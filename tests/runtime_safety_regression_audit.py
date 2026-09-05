from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
settings = (ROOT / "scripts/autoload/settings_manager.gd").read_text(encoding="utf-8")
pool = (ROOT / "scripts/actors/enemy_projectile_pool.gd").read_text(encoding="utf-8")
performance = (ROOT / "scripts/autoload/enemy_performance_manager.gd").read_text(encoding="utf-8")
validator = (ROOT / "validate_local.ps1").read_text(encoding="utf-8")

# Bozuk/eski ayar dosyaları desteklenmeyen çözünürlüğü runtime'a taşıyamaz.
assert "resolution = _validated_resolution(config.get_value(" in settings
assert "func _validated_resolution(value: Variant) -> Vector2i:" in settings
assert "typeof(value) == TYPE_VECTOR2I" in settings
assert "supported_resolutions.has(default_resolution)" in settings

# Silinmek üzere olan projectile tekrar pool bucket'ına giremez.
assert (
    "if projectile == null or not is_instance_valid(projectile) "
    "or projectile.is_queued_for_deletion():"
) in pool

# Performance manager başka sistemlerin animation speed / physics ownership'ini ezmez.
assert "visual_speed_scale" not in performance
assert "sprite.speed_scale = 0.0" not in performance
assert "VISUAL_PROCESS_MODE_META" in performance
assert "sprite.process_mode = Node.PROCESS_MODE_DISABLED" in performance
assert "func _restore_visual_processing(" in performance
assert "if enemy.is_physics_processing():" in performance
assert performance.index("if enemy.is_physics_processing():") < performance.index(
    'enemy.set_meta("vex_perf_physics_slept", true)'
)

# Yerel doğrulama README'de belirtilen Python major/minor sürümünü gerçekten zorunlu tutar.
assert "VEX requires Python 3.12.x" in validator
assert "^Python 3\\.12" in validator

print("runtime safety regression audit passed")
