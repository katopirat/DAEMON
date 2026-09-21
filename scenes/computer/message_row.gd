extends HBoxContainer

@onready var avatar: TextureRect = $Avatar
@onready var username: Label = $Content/Header/Username
@onready var timestamp: Label = $Content/Header/Timestamp
@onready var message_text: RichTextLabel = $Content/MessageText
@onready var image_content: TextureRect = $Content/ImageContent

func _ready() -> void:
	avatar.mouse_filter = Control.MOUSE_FILTER_STOP
	avatar.gui_input.connect(_on_avatar_input)

func _on_avatar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_tree().call_group("os_display", "open_avatar_preview", avatar.texture)

func setup(display_name: String, text: String, color: Color, icon: Texture2D, time: String) -> void:
	username.text = display_name
	username.add_theme_color_override("font_color", color)
	message_text.text = text
	message_text.visible = true
	image_content.visible = false
	timestamp.text = time
	if icon: avatar.texture = icon

func setup_image(display_name: String, image_path: String, color: Color, icon: Texture2D, time: String) -> void:
	username.text = display_name
	username.add_theme_color_override("font_color", color)
	message_text.visible = false
	timestamp.text = time
	var img := Image.new()
	img.load(image_path)
	image_content.texture = ImageTexture.create_from_image(img)
	image_content.visible = true
	if icon: avatar.texture = icon
