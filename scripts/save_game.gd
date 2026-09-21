extends Node

const SAVE_PATH := "user://save.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"night": HorrorState.night,
		"dialogue_id": ChatProgress.current_dialogue_id,
		"node_id": ChatProgress.current_node_id,
		"log": ChatProgress.log,
		"finished": ChatProgress.finished,
		"node_started": ChatProgress.node_started,
		"session_ready": ChatProgress.session_ready,
		"can_sleep": HorrorState.can_sleep,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func load_game() -> void:
	if not has_save():
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	HorrorState.night = parsed.get("night", 1)
	HorrorState.can_sleep = parsed.get("can_sleep", false)
	ChatProgress.current_dialogue_id = parsed.get("dialogue_id", "")
	ChatProgress.current_node_id = parsed.get("node_id", "start")
	ChatProgress.log = parsed.get("log", [])
	ChatProgress.finished = parsed.get("finished", false)
	ChatProgress.node_started = parsed.get("node_started", false)
	ChatProgress.session_ready = parsed.get("session_ready", false)

func clear() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
