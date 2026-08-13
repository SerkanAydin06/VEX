extends Node

const REQUIRED_RESOURCES := [
	"res://resources/materials/floor_standard.tres",
	"res://resources/materials/ceiling_standard.tres",
	"res://resources/materials/wall_panel.tres",
	"res://scenes/props/door_side_slide.tscn",
	"res://scenes/world/ceiling_light_white_horror.tscn",
	"res://scenes/actors/redviper.tscn",
	"res://scenes/actors/badredviper.tscn",
	"res://scenes/actors/ravager.tscn",
	"res://scenes/actors/hellmagma.tscn",
	"res://scenes/actors/voidweaver.tscn",
	"res://assets/enemies/redviper/redviper_spritesheet.png",
	"res://assets/enemies/badredviper/badredviper_spritesheet.png",
	"res://assets/enemies/ravager/ravager_spritesheet.png",
	"res://assets/enemies/hellmagma/hellmagma_spritesheet.png",
	"res://assets/enemies/voidweaver/voidweaver_spritesheet.png",
	"res://assets/enemies/ravager/ravager_projectile_sheet.png",
	"res://assets/enemies/ravager/ravager_impact_sheet.png",
	"res://assets/enemies/hellmagma/hellmagma_projectile_sheet.png",
	"res://assets/enemies/hellmagma/hellmagma_impact_sheet.png",
	"res://assets/enemies/voidweaver/voidweaver_projectile_sheet.png",
	"res://assets/enemies/voidweaver/voidweaver_impact_sheet.png",
]

var failures: Array[String] = []


func _ready() -> void:
	_check_required_resources()
	_check_level("res://scenes/levels/level_01.tscn", 18, 18, 38, 19)
	_check_level("res://scenes/levels/level_02.tscn", 33, 33, 10, 5)
	_check_enemy_visuals()
	_check_door()

	if failures.is_empty():
		print("VEX integrity test başarılı: modüler standart ve kaynak bağlantıları temiz.")
	else:
		for message in failures:
			push_error(message)
		push_error("VEX integrity test başarısız: %d hata." % failures.size())


func _check_required_resources() -> void:
	for path in REQUIRED_RESOURCES:
		if not ResourceLoader.exists(path):
			failures.append("Eksik kaynak: %s" % path)


func _check_level(path: String, room_count: int, white_light_count: int, red_light_count: int, door_count: int) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		failures.append("Bölüm yüklenemedi: %s" % path)
		return
	var level := packed.instantiate()
	if level == null:
		failures.append("Bölüm instantiate edilemedi: %s" % path)
		return
	add_child(level)

	var geometry := level.get_node_or_null("Geometry")
	if geometry == null:
		failures.append("Geometry eksik: %s" % path)
	else:
		var floors := 0
		var ceilings := 0
		for child in geometry.get_children():
			if child.name.begins_with("Floor_"):
				floors += 1
			elif child.name.begins_with("Ceiling_"):
				ceilings += 1
		if floors != room_count:
			failures.append("%s zemin modülü: %d / %d" % [path, floors, room_count])
		if ceilings != room_count:
			failures.append("%s tavan modülü: %d / %d" % [path, ceilings, room_count])

	var room_lights := level.get_node_or_null("RoomLights")
	if room_lights == null or room_lights.get_child_count() != white_light_count:
		failures.append("%s beyaz ışık sayısı yanlış." % path)
	var red_lights := level.get_node_or_null("Lights")
	if red_lights == null or red_lights.get_child_count() != red_light_count:
		failures.append("%s kırmızı ışık sayısı yanlış." % path)
	var doors := level.get_node_or_null("Doors")
	if doors == null or doors.get_child_count() != door_count:
		failures.append("%s kapı sayısı yanlış." % path)

	if path.ends_with("level_02.tscn"):
		if level.get_node_or_null("Enemies/HellMagma_19") == null:
			failures.append("VEX-02 HellMagma yerleşimi eksik.")
		if level.get_node_or_null("Enemies/Voidweaver_30") == null:
			failures.append("VEX-02 Voidweaver yerleşimi eksik.")

	level.queue_free()


func _check_enemy_visuals() -> void:
	for enemy_name in ["redviper", "badredviper", "ravager", "hellmagma", "voidweaver"]:
		var packed := load("res://scenes/actors/%s.tscn" % enemy_name) as PackedScene
		if packed == null:
			continue
		var enemy := packed.instantiate()
		var sprite := enemy.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
		if sprite == null:
			failures.append("%s AnimatedSprite3D eksik." % enemy_name)
		else:
			if int(sprite.billboard) != 2:
				failures.append("%s Fixed-Y billboard kullanmıyor." % enemy_name)
			if int(sprite.texture_filter) != 3:
				failures.append("%s Linear Mipmap kullanmıyor." % enemy_name)
		enemy.queue_free()


func _check_door() -> void:
	var packed := load("res://scenes/props/door_side_slide.tscn") as PackedScene
	if packed == null:
		return
	var door := packed.instantiate()
	var front := door.get_node_or_null("DoorPanel/FrontVisual") as Sprite3D
	if front == null or not front.flip_h:
		failures.append("DoorPanel/FrontVisual Flip H standardı eksik.")
	door.queue_free()
