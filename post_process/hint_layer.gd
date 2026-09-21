extends CanvasLayer

const ROW_SCENE := preload("res://scenes/hint_row.tscn")

@export var key_e: Texture2D
@export var key_mouse_right: Texture2D
@export var key_tab: Texture2D
@export var key_c: Texture2D
@export var key_esc: Texture2D
@export var key_mouse_left: Texture2D
@onready var hint_box: VBoxContainer = %HintBox

var icons: Dictionary = {}
var active_sources: Dictionary = {}

func _ready() -> void:
	add_to_group("hint_display")
	icons = {
		"e": key_e,
		"mouse_right": key_mouse_right,
		"tab": key_tab,
		"c": key_c,
		"esc": key_esc,
		"mouse_left": key_mouse_left,
	}

func show_hints(source_id: String, hints: Array) -> void:
	active_sources[source_id] = hints
	_rebuild()

func clear_hints(source_id: String) -> void:
	if active_sources.has(source_id):
		active_sources.erase(source_id)
		_rebuild()

func _rebuild() -> void:
	for c in hint_box.get_children(): c.queue_free()
	for s_id in active_sources:
		for h in active_sources[s_id]:
			var row := ROW_SCENE.instantiate()
			hint_box.add_child(row)
			row.setup(icons.get(h[0], null), h[1])
