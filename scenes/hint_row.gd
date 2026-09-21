extends HBoxContainer

@onready var key_icon: TextureRect = $KeyIcon
@onready var hint_text: Label = $HintText

func setup(icon: Texture2D, text: String) -> void:
	key_icon.texture = icon
	hint_text.text = text
