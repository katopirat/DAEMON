extends AppWindow

const PROCS := [
	{"name": "explorer.exe", "cpu": 2},
	{"name": "thiscord.exe", "cpu": 4},
	{"name": "mail.exe", "cpu": 1},
]

@onready var output_label: RichTextLabel = %OutputLabel
@onready var output_scroll: ScrollContainer = %OutputScroll
@onready var input_line: TextEdit = %InputText

func _ready() -> void:
	super._ready()
	output_label.bbcode_enabled = true
	output_label.text = "DAEMON-OS [Version 4.71]\n(c) 1996-2026 Systems Corp. All rights reserved.\n\n"
	input_line.gui_input.connect(_on_in_gui)
	input_line.grab_focus()
	if HorrorState.night == 3 and not HorrorState.terminal_seen:
		HorrorState.terminal_seen = true
		input_line.text = "ps"
		input_line.set_caret_column(2)

func _on_in_gui(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ENTER:
		get_viewport().set_input_as_handled()
		_cmd(input_line.text)

func _cmd(c: String) -> void:
	var trm := c.strip_edges()
	output_label.text += "> " + trm + "\n"
	input_line.text = ""
	_rn_cmd(trm)
	output_label.text += "\n"
	_scr_btm()
	input_line.grab_focus()

func _rn_cmd(c: String) -> void:
	var pts := c.split(" ", false)
	if pts.is_empty(): return
	match pts[0]:
		"help": output_label.text += "Available commands: help, ps, kill <pid>, clear"
		"ps": _pr_ps()
		"clear": output_label.text = ""
		"kill":
			if pts.size() < 2: output_label.text += "usage: kill <pid>"
			else: _try_k(pts[1])
		_: output_label.text += "'" + c + "' is not recognized as an internal or external command."

func _pr_ps() -> void:
	output_label.text += "NAME              CPU\n"
	for p in PROCS: output_label.text += "%-17s %d%%\n" % [p.name, p.cpu]
	if HorrorState.night >= 3:
		output_label.text += "[color=#ff4444]4471              84%[/color]\n"

func _try_k(pid: String) -> void:
	if pid == "4471":
		HorrorState.on_kill_attempted()
		output_label.text += "Access denied."
	else:
		output_label.text += "No such process."

func _scr_btm() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	output_scroll.scroll_vertical = int(output_scroll.get_v_scroll_bar().max_value)
