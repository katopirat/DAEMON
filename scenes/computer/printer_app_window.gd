extends AppWindow

var file_name: String = ""
var file_path: String = ""

@onready var file_name_label: Label = %FileNameLabel
@onready var send_button: Button = %SendButton
@onready var status_label: Label = %StatusLabel
@onready var progress_bar: ProgressBar = %ProgressBar

func _ready() -> void:
	super._ready()
	file_name_label.text = file_name
	status_label.text = ""
	progress_bar.visible = false
	progress_bar.value = 0
	send_button.pressed.connect(_on_snd)

func _on_snd() -> void:
	var m_name := _rd_mdl()
	if m_name == "":
		status_label.text = "Invalid file."
		return
	send_button.disabled = true
	status_label.text = "Sending..."
	progress_bar.visible = true
	var tw := create_tween()
	tw.tween_property(progress_bar, "value", 100, randf_range(1, 3))
	await tw.finished
	get_tree().call_group("printer", "queue_print", m_name)
	status_label.text = "Sent. Go to the printer to start the print."
	progress_bar.visible = false

func _rd_mdl() -> String:
	var f := FileAccess.open(file_path, FileAccess.READ)
	if not f: return ""
	var txt := f.get_as_text().strip_edges()
	f.close()
	return txt
