extends AppWindow

var file_name: String = "readme.txt"
var file_content: String = "hello there"

@onready var content_label: Label = %ContentLabel

func _ready() -> void:
	super._ready()
	t_lbl.text = file_name
	content_label.text = file_content
