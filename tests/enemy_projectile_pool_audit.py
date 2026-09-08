#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    path = ROOT / relative
    assert path.exists(), relative
    return path.read_text(encoding="utf-8")


pool = read("scripts/actors/enemy_projectile_pool.gd")
performance_base = read("scripts/actors/enemy_combatant_performance_base.gd")
fire_runtime = read("scripts/actors/enemy_projectile_fire_runtime.gd")
shared_projectile = read("scripts/actors/ravager_projectile.gd")
spore = read("scripts/actors/spore_matriarch_projectile.gd")
venom_field = read("scripts/actors/venom_marshall_buff_projectile.gd")
warden = read("scripts/actors/crucible_warden.gd")
warden_heatwave = read("scripts/actors/crucible_warden_heatwave_projectile.gd")
ravager = read("scripts/actors/ravager.gd")
cinder = read("scripts/actors/cinder_spitter.gd")
voidweaver = read("scripts/actors/voidweaver.gd")
pool_runtime_test = read("tests/enemy_projectile_pool_runtime_test.gd")
assert (ROOT / "tests/enemy_projectile_pool_runtime_test.tscn").exists()
assert (ROOT / "tests/enemy_projectile_pool_runtime_test.gd.uid").exists()

# Pool ownership: pooled instances remain parented to the current scene, are
# reactivated on acquire, deactivated on recycle and capped per projectile scene.
# recycle() itself is idempotent so one Node can never appear twice in a bucket.
for token in [
    "const MAX_POOLED_PER_SCENE := 24",
    'const IN_POOL_META := &"vex_projectile_in_pool"',
    "static var _buckets: Dictionary = {}",
    "static func acquire(projectile_scene: PackedScene, parent: Node) -> Node3D:",
    "if not is_instance_valid(candidate):",
    "if not (candidate is Node3D):",
    "node.set_meta(IN_POOL_META, false)",
    'node.call("activate_from_pool")',
    'projectile.set_meta("vex_projectile_pool_key", key)',
    "projectile.set_meta(IN_POOL_META, false)",
    "parent.add_child(projectile)",
    "static func recycle(projectile: Node3D) -> void:",
    "if bool(projectile.get_meta(IN_POOL_META, false)):",
    "if bucket.size() >= MAX_POOLED_PER_SCENE:",
    "projectile.set_meta(IN_POOL_META, true)",
    'projectile.call("deactivate_for_pool")',
    "bucket.append(projectile)",
]:
    assert token in pool, token

# Scene changes free pooled current-scene children while the static bucket can
# still retain the stale Object reference. Godot errors if `is Node3D` is used
# on that freed instance, so validity MUST be checked before any type/cast access.
validity_check = pool.index("if not is_instance_valid(candidate):")
type_check = pool.index("if not (candidate is Node3D):")
assert validity_check < type_check, "freed pooled instances must be validated before `is`"

# The normal performance enemy path must acquire from the pool instead of
# allocating a fresh projectile for every shot.
for token in [
    'const EnemyProjectilePool = preload("res://scripts/actors/enemy_projectile_pool.gd")',
    "func _fire_projectile() -> void:",
    "var projectile := EnemyProjectilePool.acquire(",
    'projectile.call("launch", shot_direction, self, _runtime_attack_damage)',
]:
    assert token in performance_base, token
assert "projectile_scene.instantiate()" not in performance_base, (
    "performance projectile path must not allocate directly"
)

# Ravager, Cinder Spitter and Voidweaver override the normal fire function for
# precision/burst/weave behavior. Their shared helper must therefore pool too.
for source_name, source in [
    ("ravager.gd", ravager),
    ("cinder_spitter.gd", cinder),
    ("voidweaver.gd", voidweaver),
]:
    assert 'enemy_projectile_fire_runtime.gd' in source, source_name
    assert "ProjectileFireRuntime.fire(" in source, source_name

for token in [
    'const EnemyProjectilePool = preload("res://scripts/actors/enemy_projectile_pool.gd")',
    'const BASE_SPEED_META := &"vex_projectile_base_speed"',
    "var projectile := EnemyProjectilePool.acquire(",
    "if not projectile.has_method(\"launch\"):",
    "projectile.queue_free()",
    "if not projectile.has_meta(BASE_SPEED_META):",
    "projectile.set_meta(BASE_SPEED_META",
    "var base_projectile_speed :=",
    "var projectile_speed := base_projectile_speed * maxf(speed_scale, 0.1)",
]:
    assert token in fire_runtime, token
assert "projectile_scene.instantiate()" not in fire_runtime, (
    "custom fire helper must not bypass the pool"
)
assert "EnemyProjectilePool.recycle(projectile)\n\t\treturn null" not in fire_runtime, (
    "invalid projectile scenes must not be returned to the pool"
)

# Shared projectile has asynchronous impact/lifetime waits. Generation guards
# prevent an old callback from recycling the same Node after it has been acquired
# for a newer shot.
for token in [
    "var _lifecycle_generation := 0",
    "func activate_from_pool() -> void:",
    "_lifecycle_generation += 1",
    "func deactivate_for_pool() -> void:",
    "var generation := _lifecycle_generation",
    "generation != _lifecycle_generation",
    "func _expire_later(generation: int) -> void:",
    "if is_inside_tree() and _active and generation == _lifecycle_generation:",
    "source = null",
    "set_process(false)",
    "set_physics_process(false)",
]:
    assert token in shared_projectile, token

# Warden Heatwave is a 12-projectile burst and must reuse the same pool rather
# than causing a 12-node allocation spike every cast. Its impact tween is async,
# so it needs the same generation protection as the shared projectile family.
for token in [
    'const EnemyProjectilePool = preload("res://scripts/actors/enemy_projectile_pool.gd")',
    "var projectile := EnemyProjectilePool.acquire(",
    'projectile.set("speed", _ability.heatwave_projectile_speed)',
    'projectile.set("lifetime", _ability.heatwave_projectile_lifetime)',
    'projectile.call(',
]:
    assert token in warden, token
assert "_ability.heatwave_projectile_scene.instantiate()" not in warden, (
    "Warden Heatwave must not allocate each radial projectile"
)

for token in [
    'const EnemyProjectilePool = preload("res://scripts/actors/enemy_projectile_pool.gd")',
    "var _lifecycle_generation := 0",
    "func activate_from_pool() -> void:",
    "func deactivate_for_pool() -> void:",
    "_remaining_lifetime = lifetime",
    "_source = null",
    "set_physics_process(false)",
    'set_deferred("monitoring", false)',
    'collision_shape.set_deferred("disabled", true)',
    "var generation := _lifecycle_generation",
    "generation == _lifecycle_generation",
    "func _recycle_or_free() -> void:",
    "EnemyProjectilePool.recycle(self)",
]:
    assert token in warden_heatwave, token

# Stateful field projectiles have no long async impact coroutine; recycle must
# still fully disable processing, monitoring, collision and source references.
for source_name, source in [
    ("spore_matriarch_projectile.gd", spore),
    ("venom_marshall_buff_projectile.gd", venom_field),
]:
    for token in [
        "func activate_from_pool() -> void:",
        "func deactivate_for_pool() -> void:",
        "source = null",
        "set_process(false)",
        "set_physics_process(false)",
        "monitoring = false",
        "monitorable = false",
        "collision_mask = 0",
        'field_collision.set_deferred("disabled", true)',
        "visible = false",
    ]:
        assert token in source, (source_name, token)

# Runtime fixture proves both pool corruption cases directly: duplicate recycle
# must not return one Node twice, and a pooled Node freed by scene ownership must
# be skipped safely on the next acquire rather than reaching `is Node3D`.
for token in [
    "EnemyProjectilePool.recycle(first)",
    'first.get_meta("vex_projectile_in_pool", false)',
    "var reused := EnemyProjectilePool.acquire(PROJECTILE_SCENE, self)",
    "assert(reused == first)",
    "var second := EnemyProjectilePool.acquire(PROJECTILE_SCENE, self)",
    "assert(second != reused)",
    "var stale := EnemyProjectilePool.acquire(PROJECTILE_SCENE, self)",
    "EnemyProjectilePool.recycle(stale)",
    "stale.queue_free()",
    "var after_stale_free := EnemyProjectilePool.acquire(PROJECTILE_SCENE, self)",
    "assert(is_instance_valid(after_stale_free))",
]:
    assert token in pool_runtime_test, token

print("enemy projectile pool audit passed")
