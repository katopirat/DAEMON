extends Node

var master_volume := 1.0
var mouse_sensitivity := 1.0

const S_PATH := "user://settings.cfg"

func _ready() -> void:
	load_settings()
	apply_settings()

func apply_settings() -> void:
	var m_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(m_bus, linear_to_db(master_volume))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.save(S_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(S_PATH)
	if err == OK:
		master_volume = cfg.get_value("audio", "master_volume", 1.0)
		mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", 1.0)
