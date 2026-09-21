extends Node

signal file_changed
signal condition_changed

var stage := 0
var show_thanks_on_menu := false
var glitch_1_done := false
var known_files: Dictionary = {}
var photo_request_sent := false
var model_photographed := false
var can_sleep := false
var night := 1
var terminal_seen := false
var night3_print_active := false
var night4_room_triggered := false
var power_out := false

var game_hour := 23
var game_minute := 0
var finale_locked := false

const NIGHT_START_TIMES := {
	1: 23,
	2: 1,
	3: 3,
	4: 2,
	5: 4,
	6: 3,
}

const PRINT_TRIGGERS := {
	"session_1": {
		"node": "wait_print",
		"item": ["benchy","cube"],
		"on_start": {"delay": 7.0, "session": "session_1b"},
	},
	"session_2": {
		"node": "wait_print_2",
		"item": "project_final",
		"on_start": {"delay": 3.0, "session": "session_2_interim"},
		"on_finish": {"delay": 1.0, "session": "session_2b"},
	},
}

var active_print_trigger: Dictionary = {}

func _ready() -> void:
	var clock_timer := Timer.new()
	clock_timer.wait_time = 45.0
	clock_timer.timeout.connect(_tick_clock)
	add_child(clock_timer)
	clock_timer.start()

func _tick_clock() -> void:
	game_minute += 1
	if game_minute >= 60:
		game_minute = 0
		game_hour = (game_hour + 1) % 24

func advance_game_clock() -> void:
	game_hour = NIGHT_START_TIMES.get(night, 23)
	game_minute = randi_range(0, 40)

func advance_to(new_stage: int) -> void:
	if new_stage > stage:
		stage = new_stage
		_run_stage_effects()

func _run_stage_effects() -> void:
	if stage >= 1 and not glitch_1_done:
		_rename_file()
		glitch_1_done = true

func _rename_file() -> void:
	var dir := DirAccess.open("user://os_files/")
	if dir and dir.file_exists("notes.txt"):
		dir.rename("notes.txt", "who told you that.txt")
		file_changed.emit()

func check_and_update(path: String, current_files: Array) -> Array:
	if not known_files.has(path):
		known_files[path] = current_files.duplicate()
		return []
	var prev: Array = known_files[path]
	var flagged: Array = []
	for f in current_files:
		if not prev.has(f): flagged.append(f)
	known_files[path] = current_files.duplicate()
	if flagged.size() > 0: file_changed.emit()
	return flagged

func on_print_started(item_name: String) -> void:
	if night == 3 and item_name == "4471" and not night3_print_active:
		night3_print_active = true
		return
	if not active_print_trigger.is_empty(): return
	var trig = PRINT_TRIGGERS.get(ChatProgress.current_dialogue_id)
	if not trig or ChatProgress.current_node_id != trig.node: return
	var valid: Array = trig.item if trig.item is Array else [trig.item]
	if not valid.has(item_name): return
	active_print_trigger = trig
	if trig.has("on_start"): _fire_message(trig.on_start.delay, trig.on_start.session)

func on_print_finished(item_name: String) -> void:
	if night == 3 and item_name == "4471" and night3_print_active:
		night3_print_active = false
		_after_night3_print()
		return
	if active_print_trigger.is_empty(): return
	var valid: Array = active_print_trigger.item if active_print_trigger.item is Array else [active_print_trigger.item]
	if not valid.has(item_name): return
	var trig = active_print_trigger
	active_print_trigger = {}
	if trig.has("on_finish"): _fire_message(trig.on_finish.delay, trig.on_finish.session)

func on_print_cancelled(item_name: String) -> void:
	if night == 3 and item_name == "4471": night3_print_active = false

func _after_night3_print() -> void:
	await get_tree().create_timer(5.0).timeout
	ChatProgress.queue_session("session_3")
	Notifications.post("chat", "jake", "sent you a message")

func on_assembly_room_entered() -> void:
	if night == 4 and not night4_room_triggered:
		night4_room_triggered = true
		ChatProgress.queue_session("session_4a")
		Notifications.post("chat", "jake", "sent you a message")
		get_tree().call_group("printer", "queue_print", "arm")
		get_tree().call_group("printer", "start_print")

func _fire_message(delay: float, session_id: String) -> void:
	await get_tree().create_timer(delay).timeout
	ChatProgress.queue_session(session_id)
	Notifications.post("chat", "jake", "sent you a message")

func allow_sleep() -> void: can_sleep = true

func on_model_photographed() -> void:
	model_photographed = true
	condition_changed.emit()

func on_kill_attempted() -> void: pass

func _create_night2_files() -> void:
	var dir := DirAccess.open("user://os_files/")
	if not dir: return
	dir.make_dir_recursive("3d_models/jake")
	var f1 := FileAccess.open("user://os_files/3d_models/jake/project_final.stl", FileAccess.WRITE)
	if f1:
		f1.store_string("project_final")
		f1.close()
	var f2 := FileAccess.open("user://os_files/3d_models/jake/4471.stl", FileAccess.WRITE)
	if f2:
		f2.store_string("4471")
		f2.close()

func _dim_room_lights() -> void:
	for l in get_tree().get_nodes_in_group("room_lights"): l.light_energy *= 0.4

func _vanish_piece(p_name: String) -> void:
	for n in get_tree().get_nodes_in_group("printed_model"):
		if n.get_meta("piece_name", "") == p_name:
			n.queue_free()
			return

func start_next_night() -> void:
	can_sleep = false
	night += 1
	photo_request_sent = false
	model_photographed = false
	advance_game_clock()
	if night == 2: _create_night2_files()
	if night == 3:
		_dim_room_lights()
		get_tree().call_group("printer", "clear_printer")
		get_tree().call_group("printer", "queue_print", "4471")
		get_tree().call_group("printer", "start_print")
		get_tree().call_group("terminal_icon", "show")
	if night == 4:
		get_tree().call_group("assembly_room", "place_figure", "figure")
		_activate_figure_room_lights()
	SaveGame.save_game()
	get_tree().call_group("night_sequence", "begin_night", night)

func debug_reset_files() -> void:
	var dir := DirAccess.open("user://os_files/")
	if dir and dir.file_exists("who told you that.txt"):
		dir.rename("who told you that.txt", "notes.txt")
	glitch_1_done = false
	known_files.clear()

func _activate_figure_room_lights() -> void:
	for l in get_tree().get_nodes_in_group("figure_room_lights"): l.light_energy = 1.5
