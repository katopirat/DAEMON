extends Node

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		get_tree().call_group("player", "_handle_look_input", event)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			get_tree().call_group("object_holder", "roll_held_object", 0.2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			get_tree().call_group("object_holder", "roll_held_object", -0.2)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F10:
		HorrorState.debug_reset_files()
