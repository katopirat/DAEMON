
extends AppWindow

var file_path: String = ""
var direct_texture: Texture2D = null

@onready var image_rect: TextureRect = %ImageRect

func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(260, 260)
	size = custom_minimum_size
	image_rect.custom_minimum_size = Vector2(200, 200)
	image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if direct_texture:
		image_rect.texture = direct_texture
	elif file_path != "":
		var img := Image.new()
		img.load(file_path)
		image_rect.texture = ImageTexture.create_from_image(img)
