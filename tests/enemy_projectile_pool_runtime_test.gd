extends Node

const EnemyProjectilePool = preload("res://scripts/actors/enemy_projectile_pool.gd")
const PROJECTILE_SCENE := preload("res://scenes/actors/ravager_projectile.tscn")


func _ready() -> void:
	var first := EnemyProjectilePool.acquire(PROJECTILE_SCENE, self)
	assert(first != null)
	assert(not bool(first.get_meta("vex_projectile_in_pool", false)))

	# Aynı projectile'ın iki farklı callback tarafından aynı karede recycle
	# edilmesini taklit et. Bucket aynı Node'u yalnız bir kez tutmalıdır.
	EnemyProjectilePool.recycle(first)
	assert(bool(first.get_meta("vex_projectile_in_pool", false)))
	EnemyProjectilePool.recycle(first)
	assert(bool(first.get_meta("vex_projectile_in_pool", false)))

	var reused := EnemyProjectilePool.acquire(PROJECTILE_SCENE, self)
	assert(reused == first)
	assert(not bool(reused.get_meta("vex_projectile_in_pool", false)))

	# Double-recycle guard yoksa bucket'ta kalan ikinci aynı referans burada tekrar
	# döner ve iki aktif atış tek Node'u paylaşır. İkinci acquire farklı olmalıdır.
	var second := EnemyProjectilePool.acquire(PROJECTILE_SCENE, self)
	assert(second != null)
	assert(second != reused)

	EnemyProjectilePool.recycle(reused)
	EnemyProjectilePool.recycle(second)

	# Sahne değişimiyle aynı failure mode'u doğrudan taklit et: pooled projectile
	# current scene child'ı olduğu için dışarıdan free olabilir ama statik bucket
	# eski Object referansını tutar. Bir sonraki acquire freed referansa `is`/cast
	# uygulamadan onu atlamalı ve geçerli bir projectile döndürmelidir.
	var stale := EnemyProjectilePool.acquire(PROJECTILE_SCENE, self)
	assert(stale != null)
	EnemyProjectilePool.recycle(stale)
	stale.queue_free()
	for _frame: int in range(3):
		await get_tree().process_frame

	var after_stale_free := EnemyProjectilePool.acquire(PROJECTILE_SCENE, self)
	assert(after_stale_free != null)
	assert(is_instance_valid(after_stale_free))
	assert(not after_stale_free.is_queued_for_deletion())
	EnemyProjectilePool.recycle(after_stale_free)

	# Pooled Node'lar current scene altında tutulur. Test çıkışında fixture'ları
	# serbest bırak; eski lifetime timer'ları lifecycle generation ile etkisizdir.
	for child: Node in get_children():
		child.queue_free()
	for _frame: int in range(3):
		await get_tree().process_frame

	print("Enemy projectile pool runtime test passed")
	get_tree().quit(0)
