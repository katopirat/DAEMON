extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("crosshair_display")

func _draw() -> void:
	draw_circle(size / 2, 2.0, Color(1, 1, 1, 0.6))

func hide_crosshair() -> void: visible = false
func show_crosshair() -> void: visible = true
