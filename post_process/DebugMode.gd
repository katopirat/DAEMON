extends Node

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_F1:
			_skip_to_night(1)
		KEY_F2:
			_skip_to_night(2)
		KEY_F3:
			_skip_to_night(3)
		KEY_F4:
			_skip_to_night(4)
		KEY_F9:
			GameFiles.reset()
			print("DEBUG: soubory resetovány")

func _skip_to_night(target: int) -> void:
	HorrorState.night = target - 1
	HorrorState.start_next_night()
	print("DEBUG: jsi na noci ", HorrorState.night)
