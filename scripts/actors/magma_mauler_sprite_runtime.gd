class_name VexMagmaMaulerSpriteRuntime
extends RefCounted

const Chunk00 = preload("res://assets/enemies/magma_mauler/data/magma_mauler_chunk_00.gd")
const Chunk01 = preload("res://assets/enemies/magma_mauler/data/magma_mauler_chunk_01.gd")
const Chunk02 = preload("res://assets/enemies/magma_mauler/data/magma_mauler_chunk_02.gd")
const Chunk03 = preload("res://assets/enemies/magma_mauler/data/magma_mauler_chunk_03.gd")
const Chunk04 = preload("res://assets/enemies/magma_mauler/data/magma_mauler_chunk_04.gd")
const Chunk05 = preload("res://assets/enemies/magma_mauler/data/magma_mauler_chunk_05.gd")
const Chunk06 = preload("res://assets/enemies/magma_mauler/data/magma_mauler_chunk_06.gd")
const Chunk07 = preload("res://assets/enemies/magma_mauler/data/magma_mauler_chunk_07.gd")
const Chunk08 = preload("res://assets/enemies/magma_mauler/data/magma_mauler_chunk_08.gd")
const Chunk09 = preload("res://assets/enemies/magma_mauler/data/magma_mauler_chunk_09.gd")
const Chunk10 = preload("res://assets/enemies/magma_mauler/data/magma_mauler_chunk_10.gd")
const Chunk11 = preload("res://assets/enemies/magma_mauler/data/magma_mauler_chunk_11.gd")

const FRAME_SIZE := Vector2i(341, 512)
const FRAME_COUNT := 4

static var _cached_frames: SpriteFrames = null


static func get_sprite_frames() -> SpriteFrames:
	if _cached_frames != null:
		return _cached_frames

	var encoded := PackedStringArray([
		Chunk00.DATA, Chunk01.DATA, Chunk02.DATA, Chunk03.DATA,
		Chunk04.DATA, Chunk05.DATA, Chunk06.DATA, Chunk07.DATA,
		Chunk08.DATA, Chunk09.DATA, Chunk10.DATA, Chunk11.DATA,
	]).join("")
	var png_bytes := Marshalls.base64_to_raw(encoded)
	var image := Image.new()
	var error := image.load_png_from_buffer(png_bytes)
	if error != OK:
		push_error("Magma Mauler spritesheet decode edilemedi: %s" % error_string(error))
		_cached_frames = SpriteFrames.new()
		return _cached_frames

	# Runtime texture da diskten import edilen düşman sheet'leri gibi uzakta
	# titreşim üretmesin; mipmap yalnız bir kez, ilk Magma Mauler'da oluşturulur.
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_cached_frames = _build_frames(texture)
	return _cached_frames


static func _build_frames(texture: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	_add_animation(frames, texture, &"idle", 0, 3.0, true)
	_add_animation(frames, texture, &"walk", 1, 5.2, true)
	_add_animation(frames, texture, &"attack", 2, 6.5, false)
	_add_animation(frames, texture, &"death", 3, 4.5, false)
	_add_animation(frames, texture, &"idle_back", 4, 3.0, true)
	_add_animation(frames, texture, &"walk_back", 5, 5.2, true)
	return frames


static func _add_animation(
	frames: SpriteFrames,
	texture: Texture2D,
	animation_name: StringName,
	row: int,
	fps: float,
	looped: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, looped)
	for column: int in range(FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			column * FRAME_SIZE.x,
			row * FRAME_SIZE.y,
			FRAME_SIZE.x,
			FRAME_SIZE.y
		)
		atlas.filter_clip = true
		frames.add_frame(animation_name, atlas)
