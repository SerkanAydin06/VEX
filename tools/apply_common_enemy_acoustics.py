from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PARENT_PATH = ROOT / "scripts/actors/enemy_base.gd"
COMBATANT_PATH = ROOT / "scripts/actors/enemy_combatant_base.gd"
LUNGE_PATH = ROOT / "scripts/actors/enemy_lunge_base.gd"
AUDIT_PATH = ROOT / "tests/enemy_perception_architecture_audit.py"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


parent = PARENT_PATH.read_text(encoding="utf-8")
parent_anchor = "\n\nfunc _trigger_damage_shake(\n"
parent_helpers = '''\n\nfunc _can_hear_noise_event(\n\tnoise_position: Vector3,\n\tloudness: float,\n\tsource: Node,\n\thearing_radius_value: float,\n\thearing_loudness_scale_value: float\n) -> bool:\n\tif source == self:\n\t\treturn false\n\tif not EnemyPerceptionRuntime.should_hear_noise(\n\t\tglobal_position,\n\t\tnoise_position,\n\t\thearing_radius_value,\n\t\tloudness,\n\t\thearing_loudness_scale_value\n\t):\n\t\treturn false\n\tvar hearing_origin := global_position + Vector3.UP * acoustic_probe_height\n\tvar hearing_target := noise_position + Vector3.UP * acoustic_probe_height\n\treturn VexEnemyRuntimeUtils.has_clear_acoustic_path(\n\t\tget_world_3d(),\n\t\thearing_origin,\n\t\thearing_target,\n\t\tacoustic_collision_mask\n\t)\n\n\nfunc _broadcast_ally_alert(\n\tsuspected_position: Vector3,\n\tally_alert_radius_value: float,\n\tuse_horizontal_range: bool\n) -> void:\n\tfor node: Node in get_tree().get_nodes_in_group("enemy"):\n\t\tif node == self or not is_instance_valid(node):\n\t\t\tcontinue\n\t\tif not (node is Node3D) or not node.has_method("receive_ally_alert"):\n\t\t\tcontinue\n\n\t\tvar ally := node as Node3D\n\t\tvar within_range := (\n\t\t\tglobal_position.distance_to(ally.global_position) <= ally_alert_radius_value\n\t\t)\n\t\tif use_horizontal_range:\n\t\t\twithin_range = EnemyPerceptionRuntime.is_within_horizontal_range(\n\t\t\t\tglobal_position,\n\t\t\t\tally.global_position,\n\t\t\t\tally_alert_radius_value\n\t\t\t)\n\t\tif not within_range:\n\t\t\tcontinue\n\t\tif not VexEnemyRuntimeUtils.has_clear_acoustic_path(\n\t\t\tget_world_3d(),\n\t\t\tglobal_position + Vector3.UP * acoustic_probe_height,\n\t\t\tally.global_position + Vector3.UP * acoustic_probe_height,\n\t\t\tacoustic_collision_mask\n\t\t):\n\t\t\tcontinue\n\t\tally.call("receive_ally_alert", suspected_position)\n'''
if "func _can_hear_noise_event(" not in parent:
    parent = replace_once(parent, parent_anchor, parent_helpers + parent_anchor, "parent helper insertion")
PARENT_PATH.write_text(parent, encoding="utf-8")


combatant = COMBATANT_PATH.read_text(encoding="utf-8")
combatant_noise_old = '''func _on_noise_emitted(noise_position: Vector3, loudness: float, source: Node) -> void:\n\tif state == State.DEAD or source == self:\n\t\treturn\n\tif not VexEnemyPerceptionRuntime.should_hear_noise(\n\t\tglobal_position,\n\t\tnoise_position,\n\t\thearing_radius,\n\t\tloudness,\n\t\thearing_loudness_scale\n\t):\n\t\treturn\n\tvar hearing_origin := global_position + Vector3.UP * acoustic_probe_height\n\tvar hearing_target := noise_position + Vector3.UP * acoustic_probe_height\n\tif not VexEnemyRuntimeUtils.has_clear_acoustic_path(\n\t\tget_world_3d(), hearing_origin, hearing_target, acoustic_collision_mask\n\t):\n\t\treturn\n'''
combatant_noise_new = '''func _on_noise_emitted(noise_position: Vector3, loudness: float, source: Node) -> void:\n\tif state == State.DEAD:\n\t\treturn\n\tif not _can_hear_noise_event(\n\t\tnoise_position,\n\t\tloudness,\n\t\tsource,\n\t\thearing_radius,\n\t\thearing_loudness_scale\n\t):\n\t\treturn\n'''
if combatant_noise_old in combatant:
    combatant = replace_once(
        combatant, combatant_noise_old, combatant_noise_new, "combatant noise handler"
    )
elif "_can_hear_noise_event(" not in combatant:
    raise SystemExit("combatant noise handler: expected old or patched form")

combatant_alert_old = '''func _alert_nearby_allies(suspected_position: Vector3) -> void:\n\tfor node: Node in get_tree().get_nodes_in_group("enemy"):\n\t\tif node == self or not (node is Node3D):\n\t\t\tcontinue\n\t\tif not node.has_method("receive_ally_alert"):\n\t\t\tcontinue\n\n\t\tvar ally := node as Node3D\n\t\tif not VexEnemyPerceptionRuntime.is_within_horizontal_range(\n\t\t\tglobal_position,\n\t\t\tally.global_position,\n\t\t\tally_alert_radius\n\t\t):\n\t\t\tcontinue\n\t\tif not VexEnemyRuntimeUtils.has_clear_acoustic_path(\n\t\t\tget_world_3d(),\n\t\t\tglobal_position + Vector3.UP * acoustic_probe_height,\n\t\t\tally.global_position + Vector3.UP * acoustic_probe_height,\n\t\t\tacoustic_collision_mask\n\t\t):\n\t\t\tcontinue\n\t\tally.call("receive_ally_alert", suspected_position)\n'''
combatant_alert_new = '''func _alert_nearby_allies(suspected_position: Vector3) -> void:\n\t_broadcast_ally_alert(suspected_position, ally_alert_radius, true)\n'''
if combatant_alert_old in combatant:
    combatant = replace_once(
        combatant, combatant_alert_old, combatant_alert_new, "combatant ally broadcast"
    )
elif combatant_alert_new not in combatant:
    raise SystemExit("combatant ally broadcast: expected old or patched form")
COMBATANT_PATH.write_text(combatant, encoding="utf-8")


lunge = LUNGE_PATH.read_text(encoding="utf-8")
lunge_noise_old = '''func _on_noise_emitted(noise_position: Vector3, loudness: float, source: Node) -> void:\n\tif _dead or source == self:\n\t\treturn\n\tif not VexEnemyPerceptionRuntime.should_hear_noise(\n\t\tglobal_position,\n\t\tnoise_position,\n\t\thearing_radius,\n\t\tloudness,\n\t\thearing_loudness_scale\n\t):\n\t\treturn\n\tvar hearing_origin := global_position + Vector3.UP * acoustic_probe_height\n\tvar hearing_target := noise_position + Vector3.UP * acoustic_probe_height\n\tif not VexEnemyRuntimeUtils.has_clear_acoustic_path(\n\t\tget_world_3d(), hearing_origin, hearing_target, acoustic_collision_mask\n\t):\n\t\treturn\n'''
lunge_noise_new = '''func _on_noise_emitted(noise_position: Vector3, loudness: float, source: Node) -> void:\n\tif _dead:\n\t\treturn\n\tif not _can_hear_noise_event(\n\t\tnoise_position,\n\t\tloudness,\n\t\tsource,\n\t\thearing_radius,\n\t\thearing_loudness_scale\n\t):\n\t\treturn\n'''
if lunge_noise_old in lunge:
    lunge = replace_once(lunge, lunge_noise_old, lunge_noise_new, "lunge noise handler")
elif "_can_hear_noise_event(" not in lunge:
    raise SystemExit("lunge noise handler: expected old or patched form")

lunge_alert_old = '''func _alert_nearby_allies(suspected_position: Vector3) -> void:\n\tfor node: Node in get_tree().get_nodes_in_group("enemy"):\n\t\tif node == self or not is_instance_valid(node):\n\t\t\tcontinue\n\t\tif not (node is Node3D) or not node.has_method("receive_ally_alert"):\n\t\t\tcontinue\n\t\tvar ally := node as Node3D\n\t\tif global_position.distance_to(ally.global_position) > ally_alert_radius:\n\t\t\tcontinue\n\t\tif not VexEnemyRuntimeUtils.has_clear_acoustic_path(\n\t\t\tget_world_3d(),\n\t\t\tglobal_position + Vector3.UP * acoustic_probe_height,\n\t\t\tally.global_position + Vector3.UP * acoustic_probe_height,\n\t\t\tacoustic_collision_mask\n\t\t):\n\t\t\tcontinue\n\t\tally.call("receive_ally_alert", suspected_position)\n'''
lunge_alert_new = '''func _alert_nearby_allies(suspected_position: Vector3) -> void:\n\t_broadcast_ally_alert(suspected_position, ally_alert_radius, false)\n'''
if lunge_alert_old in lunge:
    lunge = replace_once(lunge, lunge_alert_old, lunge_alert_new, "lunge ally broadcast")
elif lunge_alert_new not in lunge:
    raise SystemExit("lunge ally broadcast: expected old or patched form")
LUNGE_PATH.write_text(lunge, encoding="utf-8")


audit = AUDIT_PATH.read_text(encoding="utf-8")
audit = audit.replace('    "VexEnemyPerceptionRuntime.should_hear_noise(",\n', '')
audit = audit.replace('    "VexEnemyPerceptionRuntime.is_within_horizontal_range(",\n', '')

audit_anchor = '''if "EnemyPerceptionRuntime.is_player_inside_initial_view(" not in parent:\n    errors.append("Parent initial-view perception delegation eksik")\n'''
audit_parent_contract = '''if "EnemyPerceptionRuntime.is_player_inside_initial_view(" not in parent:\n    errors.append("Parent initial-view perception delegation eksik")\n\nfor contract in [\n    "EnemyPerceptionRuntime.should_hear_noise(",\n    "EnemyPerceptionRuntime.is_within_horizontal_range(",\n    'get_tree().get_nodes_in_group("enemy")',\n    "VexEnemyRuntimeUtils.has_clear_acoustic_path(",\n    'ally.call("receive_ally_alert", suspected_position)',\n]:\n    if contract not in parent:\n        errors.append(f"Parent acoustic helper contract eksik: {contract}")\n'''
if "Parent acoustic helper contract eksik" not in audit:
    audit = replace_once(
        audit, audit_anchor, audit_parent_contract, "audit parent acoustic contract"
    )

audit_lunge_var_old = 'lunge_noise_handler = function_body(lunge, "_on_noise_emitted(")\n'
audit_lunge_var_new = '''lunge_noise_handler = function_body(lunge, "_on_noise_emitted(")\nlunge_ally_broadcast = function_body(lunge, "_alert_nearby_allies(")\n'''
if "lunge_ally_broadcast =" not in audit:
    audit = replace_once(audit, audit_lunge_var_old, audit_lunge_var_new, "audit lunge broadcast body")

audit_base_var_old = 'ally_broadcast = function_body(base, "_alert_nearby_allies(")\n'
audit_base_var_new = '''ally_broadcast = function_body(base, "_alert_nearby_allies(")\nparent_hearing = function_body(parent, "_can_hear_noise_event(")\nparent_ally_broadcast = function_body(parent, "_broadcast_ally_alert(")\n'''
if "parent_hearing =" not in audit:
    audit = replace_once(audit, audit_base_var_old, audit_base_var_new, "audit parent helper bodies")

audit_handler_anchor = '''if "loudness >= loud_noise_alert_threshold" in noise_handler:\n    errors.append("Noise ally-alert threshold kararı hâlâ combatant base içinde")\n'''
audit_handler_checks = '''if "loudness >= loud_noise_alert_threshold" in noise_handler:\n    errors.append("Noise ally-alert threshold kararı hâlâ combatant base içinde")\nif "_can_hear_noise_event(" not in noise_handler:\n    errors.append("Combatant ortak hearing helper kullanmıyor")\nif "_can_hear_noise_event(" not in lunge_noise_handler:\n    errors.append("Lunge ortak hearing helper kullanmıyor")\nif "VexEnemyRuntimeUtils.has_clear_acoustic_path(" in noise_handler:\n    errors.append("Combatant acoustic raycast yeniden child handler'a taşınmış")\nif "VexEnemyRuntimeUtils.has_clear_acoustic_path(" in lunge_noise_handler:\n    errors.append("Lunge acoustic raycast yeniden child handler'a taşınmış")\nif "_broadcast_ally_alert(suspected_position, ally_alert_radius, true)" not in ally_broadcast:\n    errors.append("Combatant yatay ally-alert wrapper sözleşmesi yanlış")\nif "_broadcast_ally_alert(suspected_position, ally_alert_radius, false)" not in lunge_ally_broadcast:\n    errors.append("Lunge 3B ally-alert wrapper sözleşmesi yanlış")\nif "EnemyPerceptionRuntime.should_hear_noise(" not in parent_hearing:\n    errors.append("Parent hearing helper perception runtime'a delege etmiyor")\nif "use_horizontal_range" not in parent_ally_broadcast:\n    errors.append("Parent ally-alert helper aile menzil geometrisini korumuyor")\n'''
if "Combatant ortak hearing helper kullanmıyor" not in audit:
    audit = replace_once(
        audit, audit_handler_anchor, audit_handler_checks, "audit helper delegation checks"
    )

old_side_effect_block = '''# Scene/world side effects remain orchestrator-owned.\nfor contract in [\n    'GameState.noise_emitted.is_connected(_on_noise_emitted)',\n    'get_tree().get_nodes_in_group("enemy")',\n    "VexEnemyRuntimeUtils.has_clear_acoustic_path(",\n    'ally.call("receive_ally_alert", suspected_position)',\n]:\n    if contract not in base:\n        errors.append(f"Combatant side-effect ownership kayboldu: {contract}")\n'''
new_side_effect_block = '''# Scene/world side effects remain actor-layer owned; shared side effects live in the parent actor.\nif 'GameState.noise_emitted.is_connected(_on_noise_emitted)' not in base:\n    errors.append("Combatant noise signal ownership kayboldu")\nfor contract in [\n    'get_tree().get_nodes_in_group("enemy")',\n    "VexEnemyRuntimeUtils.has_clear_acoustic_path(",\n    'ally.call("receive_ally_alert", suspected_position)',\n]:\n    if contract not in parent:\n        errors.append(f"Parent acoustic side-effect ownership kayboldu: {contract}")\n'''
if old_side_effect_block in audit:
    audit = replace_once(
        audit, old_side_effect_block, new_side_effect_block, "audit side-effect ownership"
    )
elif "Parent acoustic side-effect ownership kayboldu" not in audit:
    raise SystemExit("audit side-effect ownership: expected old or patched form")

AUDIT_PATH.write_text(audit, encoding="utf-8")

print("common enemy acoustic helpers applied")
