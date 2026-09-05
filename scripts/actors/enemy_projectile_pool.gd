class_name VexEnemyProjectilePool
extends RefCounted

# Aynı projectile sahnesini sürekli instantiate/free etmek yerine impact görseli,
# ışığı ve sesiyle birlikte yeniden kullanır. Sahne değişince eski örnekler doğal
# olarak geçersizleşir ve bir sonraki acquire sırasında temizlenir.
const MAX_POOLED_PER_SCENE := 24
const IN_POOL_META := &"vex_projectile_in_pool"

static var _buckets: Dictionary = {}


static func acquire(projectile_scene: PackedScene, parent: Node) -> Node3D:
	if projectile_scene == null or parent == null or not is_instance_valid(parent):
		return null
	var key := _scene_key(projectile_scene)
	var bucket: Array = _buckets.get(key, [])
	while not bucket.is_empty():
		var candidate: Variant = bucket.pop_back()
		if not (candidate is Node3D):
			continue
		var node := candidate as Node3D
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if node.get_parent() != parent:
			node.queue_free()
			continue
		node.set_meta(IN_POOL_META, false)
		_buckets[key] = bucket
		if node.has_method("activate_from_pool"):
			node.call("activate_from_pool")
		return node
	_buckets[key] = bucket

	var instance := projectile_scene.instantiate()
	if not (instance is Node3D):
		if instance != null:
			instance.queue_free()
		return null
	var projectile := instance as Node3D
	projectile.set_meta("vex_projectile_pool_key", key)
	projectile.set_meta(IN_POOL_META, false)
	# add_child() _ready() çağırır; yeni mermi kendi _ready() akışında bir kez
	# aktive olur. activate_from_pool() yalnız geri dönüştürülen örnekler içindir.
	parent.add_child(projectile)
	return projectile


static func recycle(projectile: Node3D) -> void:
	if projectile == null or not is_instance_valid(projectile) or projectile.is_queued_for_deletion():
		return
	if not projectile.has_meta("vex_projectile_pool_key"):
		projectile.queue_free()
		return
	if bool(projectile.get_meta(IN_POOL_META, false)):
		return
	var key := String(projectile.get_meta("vex_projectile_pool_key"))
	var bucket: Array = _buckets.get(key, [])
	if bucket.size() >= MAX_POOLED_PER_SCENE:
		projectile.queue_free()
		return
	# Meta önce işaretlenir; deactivate sırasında veya aynı karede ikinci bir
	# recycle çağrısı oluşsa bile aynı Node bucket'a iki kez giremez.
	projectile.set_meta(IN_POOL_META, true)
	if projectile.has_method("deactivate_for_pool"):
		projectile.call("deactivate_for_pool")
	bucket.append(projectile)
	_buckets[key] = bucket


static func _scene_key(projectile_scene: PackedScene) -> String:
	if not projectile_scene.resource_path.is_empty():
		return projectile_scene.resource_path
	return "instance:%d" % projectile_scene.get_instance_id()
