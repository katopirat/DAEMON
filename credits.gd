extends Control

@onready var scroll: ScrollContainer = %CreditsScroll
@onready var back_button: Button = $Button
@export var scroll_speed := 25.0
var auto_scrolling := true
var current_scroll := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	back_button.pressed.connect(_on_back_pressed)

func _process(delta: float) -> void:
	if auto_scrolling:
		current_scroll += scroll_speed * delta
		scroll.scroll_vertical = int(current_scroll)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length() > 5):
		auto_scrolling = false

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_stack.tscn")
