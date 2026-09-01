class_name VexEnemyPerformanceRuntime
extends RefCounted

# Kalabalık savaşlarda pahalı sorguların aynı fizik karesine yığılmasını önler.
# Yakın düşmanlar daha yüksek öncelik alır; görsel kalite veya hareket fiziği
# bu bütçeler tarafından düşürülmez.
const NEAR_PRIORITY_DISTANCE := 14.0
const MID_DISTANCE := 28.0
const PATH_RETRY_DELAY := 0.05
const COVER_RETRY_DELAY := 0.10

const FAR_SIGHT_CLAIMS_PER_FRAME := 3
const NEAR_SIGHT_CLAIMS_PER_FRAME := 7
const FAR_PATH_CLAIMS_PER_FRAME := 1
const NEAR_PATH_CLAIMS_PER_FRAME := 2
const FAR_COVER_CLAIMS_PER_FRAME := 1
const NEAR_COVER_CLAIMS_PER_FRAME := 2

static var _budget_frame := -1
static var _sight_claims := 0
static var _path_claims := 0
static var _cover_claims := 0

static var _door_scene_id := -1
static var _door_nodes: Array[Node] = []


static func _roll_budget_frame() -> void:
	var physics_frame := Engine.get_physics_frames()
	if physics_frame == _budget_frame:
		return
	_budget_frame = physics_frame
	_sight_claims = 0
	_path_claims = 0
	_cover_claims = 0


static func try_claim_sight(near_priority: bool) -> bool:
	_roll_budget_frame()
	var limit := (
		NEAR_SIGHT_CLAIMS_PER_FRAME
		if near_priority
		else FAR_SIGHT_CLAIMS_PER_FRAME
	)
	if _sight_claims >= limit:
		return false
	_sight_claims += 1
	return true


static func try_claim_path(near_priority: bool) -> bool:
	_roll_budget_frame()
	var limit := (
		NEAR_PATH_CLAIMS_PER_FRAME
		if near_priority
		else FAR_PATH_CLAIMS_PER_FRAME
	)
	if _path_claims >= limit:
		return false
	_path_claims += 1
	return true


static func try_claim_cover(near_priority: bool) -> bool:
	_roll_budget_frame()
	var limit := (
		NEAR_COVER_CLAIMS_PER_FRAME
		if near_priority
		else FAR_COVER_CLAIMS_PER_FRAME
	)
	if _cover_claims >= limit:
		return false
	_cover_claims += 1
	return true


static func is_near_player(host: Node3D, player: Node3D) -> bool:
	if host == null or player == null or not is_instance_valid(player):
		return false
	var offset := player.global_position - host.global_position
	offset.y = 0.0
	return offset.length_squared() <= NEAR_PRIORITY_DISTANCE * NEAR_PRIORITY_DISTANCE


static func resolve_enemy_door_step_cached(
	host: Node3D,
	target_position: Vector3,
	navigation_clearance: float,
	reach_distance: float
) -> Vector3:
	if host == null or not host.is_inside_tree():
		return target_position
	_refresh_door_cache_if_needed(host)

	var best_point := target_position
	var best_score := INF
	var best_door: Node = null
	for node: Node in _door_nodes:
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("get_enemy_navigation_step"):
			continue
		var route: Variant = node.call(
			"get_enemy_navigation_step",
			host.global_position,
			target_position,
			navigation_clearance,
			reach_distance
		)
		if not (route is Dictionary):
			continue
		var data := route as Dictionary
		if not bool(data.get("valid", false)):
			continue
		var point: Variant = data.get("point", target_position)
		if typeof(point) != TYPE_VECTOR3:
			continue
		var score := float(data.get("score", INF))
		if score < best_score:
			best_score = score
			best_point = point
			best_door = node
	if best_door != null and best_door.has_method("request_enemy_open"):
		best_door.call("request_enemy_open")
	return best_point


static func _refresh_door_cache_if_needed(host: Node3D) -> void:
	var current_scene := host.get_tree().current_scene
	var scene_id := current_scene.get_instance_id() if current_scene != null else 0
	var needs_refresh := scene_id != _door_scene_id
	if not needs_refresh:
		for node: Node in _door_nodes:
			if node == null or not is_instance_valid(node):
				needs_refresh = true
				break
	if not needs_refresh:
		return

	_door_scene_id = scene_id
	_door_nodes.clear()
	for node: Node in host.get_tree().get_nodes_in_group("enemy_navigation_door"):
		if node != null and is_instance_valid(node):
			_door_nodes.append(node)
