import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def assignment(text: str, key: str) -> float:
    match = re.search(rf"(?m)^{re.escape(key)}\s*=\s*([0-9.]+)\s*$", text)
    if match is None:
        match = re.search(rf"(?m)\b{re.escape(key)}\s*:=\s*([0-9.]+)\s*$", text)
    assert match is not None, f"missing numeric assignment: {key}"
    return float(match.group(1))


def animation_timing(scene: str, animation_name: str) -> tuple[float, list[float]]:
    blocks = re.finditer(
        r'\{\n"frames": \[(.*?)\],\n"loop": .*?\n"name": &"([^"]+)",\n"speed": ([0-9.]+)\n\}',
        scene,
        re.S,
    )
    for match in blocks:
        if match.group(2) != animation_name:
            continue
        durations = [float(value) for value in re.findall(r'"duration": ([0-9.]+)', match.group(1))]
        assert durations, f"animation has no frame durations: {animation_name}"
        return float(match.group(3)), durations
    raise AssertionError(f"missing animation: {animation_name}")


def default_windup_multipliers() -> list[float]:
    base = read("scripts/actors/enemy_base.gd")
    match = re.search(
        r"difficulty_windup_multipliers\s*:=\s*PackedFloat32Array\(\[([^\]]+)\]\)",
        base,
    )
    assert match is not None, "missing default difficulty windup multipliers"
    return [float(value.strip()) for value in match.group(1).split(",")]


def scene_windup_multipliers(scene: str) -> list[float]:
    match = re.search(r"difficulty_windup_multipliers\s*=\s*PackedFloat32Array\(([^)]+)\)", scene)
    if match is None:
        return default_windup_multipliers()
    return [float(value.strip()) for value in match.group(1).split(",")]


def assert_release_window(
    scene_path: str,
    animation_name: str,
    release_frame: int,
    windup: float,
) -> None:
    scene = read(scene_path)
    speed, durations = animation_timing(scene, animation_name)
    assert 0 <= release_frame < len(durations), f"invalid release frame: {scene_path}:{animation_name}"

    start = sum(durations[:release_frame]) / speed
    end = (sum(durations[:release_frame]) + durations[release_frame]) / speed
    multipliers = scene_windup_multipliers(scene)
    earliest_fire = windup * min(multipliers)
    latest_fire = windup * max(multipliers)
    epsilon = 0.002

    assert start <= earliest_fire + epsilon, (
        f"release frame starts too late: {scene_path}:{animation_name} "
        f"start={start:.4f}, earliest_fire={earliest_fire:.4f}"
    )
    assert end + epsilon >= latest_fire, (
        f"release frame ends too early: {scene_path}:{animation_name} "
        f"end={end:.4f}, latest_fire={latest_fire:.4f}"
    )


GENERIC_CASES = [
    ("scenes/actors/basalt_juggernaut.tscn", "attack", 2),
    ("scenes/actors/briar_skulker.tscn", "attack", 2),
    ("scenes/actors/cinder_spitter.tscn", "attack", 2),
    ("scenes/actors/coil_lancer.tscn", "attack", 2),
    ("scenes/actors/ravager.tscn", "attack", 2),
    ("scenes/actors/husk_leech.tscn", "attack", 2),
    ("scenes/actors/veilmaw.tscn", "attack", 2),
    ("scenes/actors/voidweaver.tscn", "attack", 2),
    ("scenes/actors/venom_marshall.tscn", "attack", 2),
    ("scenes/actors/spore_matriarch.tscn", "attack", 3),
]

for scene_path, animation_name, release_frame in GENERIC_CASES:
    scene = read(scene_path)
    assert_release_window(scene_path, animation_name, release_frame, assignment(scene, "attack_windup"))

furnice_settings = read("scripts/actors/furnice_carrier_ability_settings.gd")
assert_release_window(
    "scenes/actors/furnice_carrier.tscn",
    "attack",
    1,
    assignment(furnice_settings, "projectile_attack_windup"),
)
assert_release_window(
    "scenes/actors/furnice_carrier.tscn",
    "thermal_burst",
    2,
    assignment(furnice_settings, "thermal_burst_windup"),
)

warden_settings = read("scripts/actors/warden_ability_settings.gd")
assert_release_window(
    "scenes/actors/crucible_warden.tscn",
    "attack",
    2,
    assignment(warden_settings, "ground_slam_windup"),
)
assert_release_window(
    "scenes/actors/crucible_warden.tscn",
    "heatwave",
    2,
    assignment(warden_settings, "heatwave_windup"),
)

venom_scene = read("scenes/actors/venom_marshall.tscn")
assert_release_window(
    "scenes/actors/venom_marshall.tscn",
    "2nd_attack",
    2,
    assignment(venom_scene, "buff_windup"),
)

# Standard performance-lunge enemies synchronize their actual hit windup to
# the midpoint of authored attack frame 3 at runtime. This keeps the visual
# contact frame stable while difficulty still changes the real windup length.
lunge_performance = read("scripts/actors/enemy_lunge_performance_base.gd")
assert "func _attack_playback_scale_for_runtime_windup() -> float:" in lunge_performance
assert 'frames.get_frame_duration(&"attack", 2) * 0.5' in lunge_performance
assert "authored_release_time / maxf(_runtime_attack_windup, 0.001)" in lunge_performance
assert "func _play_animation(animation_name: StringName) -> void:" in lunge_performance
assert 'animated_sprite.play(&"attack", _attack_playback_scale_for_runtime_windup())' in lunge_performance

lunge_base = read("scripts/actors/enemy_lunge_base.gd")
assert "await get_tree().create_timer(_runtime_attack_windup).timeout" in lunge_base

PERFORMANCE_LUNGE_SCRIPTS = (
    "scripts/actors/cinderhound.gd",
    "scripts/actors/rift_reaver.gd",
    "scripts/actors/vaskari_bulwark.gd",
    "scripts/actors/vaskari_raptor.gd",
    "scripts/actors/vaskari_ravager.gd",
)
for script_path in PERFORMANCE_LUNGE_SCRIPTS:
    script = read(script_path)
    assert 'extends "res://scripts/actors/enemy_lunge_performance_base.gd"' in script, (
        f"{script_path}: standard melee release synchronization no longer applies"
    )

# Hybrid close attacks have one damage resolve. Briar's authored close-contact
# pose is frame 2, so keep its midpoint on the difficulty-scaled melee windup.
hybrid_base = read("scripts/actors/enemy_hybrid_base.gd")
assert "func _melee_attack_playback_scale(animation_name: StringName, runtime_windup: float) -> float:" in hybrid_base
assert "frames.get_frame_duration(animation_name, 1) * 0.5" in hybrid_base
assert "authored_release_time / maxf(runtime_windup, 0.001)" in hybrid_base
assert "_melee_attack_playback_scale(attack_animation, runtime_windup)" in hybrid_base
assert "await get_tree().create_timer(runtime_windup).timeout" in hybrid_base

briar_script = read("scripts/actors/briar_skulker.gd")
assert 'extends "res://scripts/actors/enemy_hybrid_base.gd"' in briar_script

print("enemy attack release timing audit passed")
