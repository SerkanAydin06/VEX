#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PARENT = ROOT / "scripts" / "actors" / "enemy_base.gd"
BASE = ROOT / "scripts" / "actors" / "enemy_combatant_base.gd"
LUNGE = ROOT / "scripts" / "actors" / "enemy_lunge_base.gd"
RUNTIME = ROOT / "scripts" / "actors" / "enemy_perception_runtime.gd"

errors: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"Eksik dosya: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


def function_body(source: str, name: str) -> str:
    marker = f"func {name}"
    start = source.find(marker)
    if start < 0:
        errors.append(f"Eksik fonksiyon: {name}")
        return ""
    next_func = source.find("\n\nfunc ", start + len(marker))
    return source[start:] if next_func < 0 else source[start:next_func]


parent = read(PARENT)
base = read(BASE)
lunge = read(LUNGE)
runtime = read(RUNTIME)

for contract in [
    "VexEnemyPerceptionRuntime.active_detection_range(",
    "VexEnemyPerceptionRuntime.passes_crouch_detection(",
    "VexEnemyPerceptionRuntime.has_visual_contact(",
    "VexEnemyPerceptionRuntime.ranged_visibility_ratio_from(",
    "VexEnemyPerceptionRuntime.is_player_collider(",
    "VexEnemyPerceptionRuntime.should_broadcast_noise_alert(",
    "VexEnemyPerceptionRuntime.should_accept_ally_alert(",
    "VexEnemyPerceptionRuntime.ally_alert_facing_direction(",
    "VexEnemyPerceptionRuntime.should_skip_idle_sight(",
    "VexEnemyPerceptionRuntime.sight_interval(",
    "VexEnemyPerceptionRuntime.is_sight_check_due(",
    "VexEnemyPerceptionRuntime.next_sight_check_remaining(",
]:
    if contract not in base:
        errors.append(f"Combatant perception delegation eksik: {contract}")

for contract in [
    "VexEnemyPerceptionRuntime.active_detection_range(",
    "VexEnemyPerceptionRuntime.passes_crouch_detection(",
    "VexEnemyPerceptionRuntime.has_visual_contact(",
    "VexEnemyPerceptionRuntime.should_broadcast_noise_alert(",
]:
    if contract not in lunge:
        errors.append(f"Lunge perception delegation eksik: {contract}")

if "EnemyPerceptionRuntime.is_player_inside_initial_view(" not in parent:
    errors.append("Parent initial-view perception delegation eksik")

for contract in [
    "EnemyPerceptionRuntime.should_hear_noise(",
    "EnemyPerceptionRuntime.is_within_horizontal_range(",
    'get_tree().get_nodes_in_group("enemy")',
    "VexEnemyRuntimeUtils.has_clear_acoustic_path(",
    'ally.call("receive_ally_alert", suspected_position)',
]:
    if contract not in parent:
        errors.append(f"Parent acoustic helper contract eksik: {contract}")

for contract in [
    "class_name VexEnemyPerceptionRuntime",
    "func active_detection_range(",
    "func is_player_inside_initial_view(",
    "func passes_crouch_detection(",
    "VexEnemyRuntimeUtils.has_visual_contact(",
    "func ranged_visibility_ratio_from(",
    "PhysicsRayQueryParameters3D.create(",
    "var visible_samples := 0",
    "func is_player_collider(",
    "func horizontal_distance(",
    "func effective_hearing_range(",
    "func should_hear_noise(",
    "func should_broadcast_noise_alert(",
    "func should_accept_ally_alert(",
    "func ally_alert_facing_direction(",
    "func should_skip_idle_sight(",
    "func sight_interval(",
    "func is_sight_check_due(",
    "func next_sight_check_remaining(",
]:
    if contract not in runtime:
        errors.append(f"Perception runtime contract eksik: {contract}")

lunge_line_of_sight = function_body(lunge, "_check_line_of_sight(")
lunge_noise_handler = function_body(lunge, "_on_noise_emitted(")
lunge_ally_broadcast = function_body(lunge, "_alert_nearby_allies(")

for source_name, source in [("combatant", base), ("lunge", lunge)]:
    if "_get_crouched_sight_target_height" in source:
        errors.append(f"Ölü crouched target-height wrapper geri dönmüş: {source_name}")
    if "VexEnemyPerceptionRuntime.crouched_sight_target_height(" in source:
        errors.append(f"Kullanılmayan crouched target-height delegation geri dönmüş: {source_name}")

can_see = function_body(base, "_can_see_player(")
initial_view = function_body(parent, "_is_player_inside_initial_view(")
line_of_sight = function_body(base, "_check_line_of_sight(")
ranged_ratio = function_body(base, "_ranged_visibility_ratio_from(")
player_collider = function_body(base, "_is_player_collider(")
noise_handler = function_body(base, "_on_noise_emitted(")
ally_receiver = function_body(base, "receive_ally_alert(")
ally_broadcast = function_body(base, "_alert_nearby_allies(")
parent_hearing = function_body(parent, "_can_hear_noise_event(")
parent_ally_broadcast = function_body(parent, "_broadcast_ally_alert(")
perception_update = function_body(base, "_update_perception(")

if "randf()" in can_see:
    errors.append("Crouch detection RNG hâlâ combatant base içinde")
if "cos(deg_to_rad" in initial_view:
    errors.append("Initial view cone hesabı hâlâ enemy base içinde")
if "VexEnemyRuntimeUtils.has_visual_contact(" in line_of_sight:
    errors.append("Visual contact çözümü hâlâ combatant base içinde")
if "visible_samples" in ranged_ratio or "PhysicsRayQueryParameters3D.create(" in ranged_ratio:
    errors.append("Ranged visibility sampling hâlâ combatant base içinde")
if "while current != null" in player_collider:
    errors.append("Player collider ancestry çözümü hâlâ combatant base içinde")

if "VexEnemyRuntimeUtils.has_visual_contact(" in lunge_line_of_sight:
    errors.append("Visual contact çözümü hâlâ lunge base içinde")
if "randf()" in lunge_line_of_sight:
    errors.append("Crouch detection RNG hâlâ lunge base içinde")
if "hearing_radius * maxf(" in lunge_noise_handler:
    errors.append("Hearing effective-range hesabı hâlâ lunge base içinde")
if "loudness >= loud_noise_alert_threshold" in lunge_noise_handler:
    errors.append("Noise ally-alert threshold kararı hâlâ lunge base içinde")

if "hearing_radius * maxf(" in noise_handler:
    errors.append("Hearing effective-range hesabı hâlâ combatant base içinde")
if "loudness >= loud_noise_alert_threshold" in noise_handler:
    errors.append("Noise ally-alert threshold kararı hâlâ combatant base içinde")
if "_can_hear_noise_event(" not in noise_handler:
    errors.append("Combatant ortak hearing helper kullanmıyor")
if "_can_hear_noise_event(" not in lunge_noise_handler:
    errors.append("Lunge ortak hearing helper kullanmıyor")
if "VexEnemyRuntimeUtils.has_clear_acoustic_path(" in noise_handler:
    errors.append("Combatant acoustic raycast yeniden child handler'a taşınmış")
if "VexEnemyRuntimeUtils.has_clear_acoustic_path(" in lunge_noise_handler:
    errors.append("Lunge acoustic raycast yeniden child handler'a taşınmış")
if "_broadcast_ally_alert(suspected_position, ally_alert_radius, true)" not in ally_broadcast:
    errors.append("Combatant yatay ally-alert wrapper sözleşmesi yanlış")
if "_broadcast_ally_alert(suspected_position, ally_alert_radius, false)" not in lunge_ally_broadcast:
    errors.append("Lunge 3B ally-alert wrapper sözleşmesi yanlış")
if "EnemyPerceptionRuntime.should_hear_noise(" not in parent_hearing:
    errors.append("Parent hearing helper perception runtime'a delege etmiyor")
if "use_horizontal_range" not in parent_ally_broadcast:
    errors.append("Parent ally-alert helper aile menzil geometrisini korumuyor")
if "state == State.DEAD or _player_visible or not receive_ally_alerts" in ally_receiver:
    errors.append("Ally alert kabul kararı hâlâ combatant base içinde")
if "alert_direction.normalized()" in ally_receiver:
    errors.append("Ally alert facing hesabı hâlâ combatant base içinde")
if "_horizontal_distance(global_position, ally.global_position) > ally_alert_radius" in ally_broadcast:
    errors.append("Ally alert yatay menzil hesabı hâlâ combatant base içinde")
if "player_distance > distant_think_distance" in perception_update:
    errors.append("Sight interval tier hesabı hâlâ combatant base içinde")
if "player_distance > _runtime_detection_range + idle_detection_margin" in perception_update:
    errors.append("Idle sight skip kararı hâlâ combatant base içinde")
if "_sight_check_remaining -= delta" in perception_update:
    errors.append("Sight timer countdown hesabı hâlâ combatant base içinde")

# Scene/world side effects remain actor-layer owned; shared side effects live in the parent actor.
if 'GameState.noise_emitted.is_connected(_on_noise_emitted)' not in base:
    errors.append("Combatant noise signal ownership kayboldu")
for contract in [
    'get_tree().get_nodes_in_group("enemy")',
    "VexEnemyRuntimeUtils.has_clear_acoustic_path(",
    'ally.call("receive_ally_alert", suspected_position)',
]:
    if contract not in parent:
        errors.append(f"Parent acoustic side-effect ownership kayboldu: {contract}")

for forbidden in [
    "GameState",
    'get_nodes_in_group("enemy")',
    'ally.call("receive_ally_alert"',
]:
    if forbidden in runtime:
        errors.append(f"Perception runtime scene side-effect aldı: {forbidden}")

if errors:
    for error in errors:
        print(f"ERROR: {error}")
    raise SystemExit(1)

print("enemy perception architecture audit passed")
