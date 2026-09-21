extends CanvasLayer

@onready var flash_rect: ColorRect = %FlashRect
@onready var shutter_sound: AudioStreamPlayer = %ShutterSound

func _ready() -> void: add_to_group("photo_flash")

func flash() -> void:
	shutter_sound.play()
	flash_rect.color.a = 0.9
	var tw := create_tween()
	tw.tween_property(flash_rect, "color:a", 0.0, 0.4)
