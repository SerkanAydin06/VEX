class_name VexEnemyCombatProfiles
extends RefCounted

# Combat role is the only tactical classification used by the shared enemy AI.
# Creature identity never decides navigation or spacing behavior.
enum Role {
    CLOSE,
    MID,
    LONG,
}


static func preferred_distance(role: int, attack_range: float) -> float:
    match role:
        Role.CLOSE:
            return maxf(0.75, minf(1.40, attack_range * 0.78))
        Role.MID:
            return maxf(2.50, attack_range * 0.62)
        Role.LONG:
            return maxf(5.00, attack_range * 0.78)
        _:
            return maxf(0.75, attack_range * 0.62)


static func minimum_distance(role: int, attack_range: float) -> float:
    var preferred: float = preferred_distance(role, attack_range)
    match role:
        Role.CLOSE:
            return 0.0
        Role.MID:
            return preferred * 0.52
        Role.LONG:
            return preferred * 0.68
        _:
            return 0.0


static func cover_visibility_threshold(role: int) -> float:
    match role:
        Role.MID:
            return 0.45
        Role.LONG:
            return 0.65
        _:
            return 0.0


static func uses_multi_sample_visibility(role: int) -> bool:
    return role == Role.MID or role == Role.LONG


static func uses_cover_reposition(role: int, has_projectile: bool) -> bool:
    return has_projectile and (role == Role.MID or role == Role.LONG)


static func cover_reposition_distance(role: int) -> float:
    return 3.0 if role == Role.LONG else 2.15


static func recovery_strafe_scale(role: int) -> float:
    match role:
        Role.MID:
            return 0.72
        Role.LONG:
            return 1.0
        _:
            return 0.0


static func retreat_scale(role: int) -> float:
    match role:
        Role.MID:
            return 0.58
        Role.LONG:
            return 0.92
        _:
            return 0.0


static func idle_wander_radius(role: int) -> float:
    match role:
        Role.CLOSE:
            return 2.8
        Role.MID:
            return 2.0
        Role.LONG:
            return 1.35
        _:
            return 2.0


static func idle_pause_min(role: int) -> float:
    return 0.35 if role == Role.CLOSE else 0.55


static func idle_pause_max(role: int) -> float:
    return 1.20 if role == Role.LONG else 0.95


static func path_refresh_interval(role: int) -> float:
    match role:
        Role.CLOSE:
            return 0.30
        Role.MID:
            return 0.36
        Role.LONG:
            return 0.44
        _:
            return 0.36


static func path_target_change_distance(role: int) -> float:
    match role:
        Role.CLOSE:
            return 1.20
        Role.MID:
            return 1.65
        Role.LONG:
            return 2.20
        _:
            return 1.50


static func grid_step(role: int) -> float:
    match role:
        Role.CLOSE:
            return 0.78
        Role.MID:
            return 0.92
        Role.LONG:
            return 1.08
        _:
            return 0.92


static func grid_max_nodes(role: int) -> int:
    match role:
        Role.CLOSE:
            return 2600
        Role.MID:
            return 2300
        Role.LONG:
            return 2000
        _:
            return 2200


static func grid_search_margin(role: int) -> float:
    match role:
        Role.CLOSE:
            return 18.0
        Role.MID:
            return 15.0
        Role.LONG:
            return 13.0
        _:
            return 15.0
