extends Node

signal posted(app_id: String, title: String, body: String, icon: Texture2D)

var icons: Dictionary = {}
var names: Dictionary = {}
var sound_player: AudioStreamPlayer

func _ready() -> void:
	sound_player = AudioStreamPlayer.new()
	sound_player.stream = preload("res://audio/notification.wav")
	add_child(sound_player)

func register_icon(app_id: String, icon: Texture2D) -> void: icons[app_id] = icon
func register_name(app_id: String, display_name: String) -> void: names[app_id] = display_name
func get_display_name(app_id: String) -> String: return names.get(app_id, app_id)

func post(app_id: String, title: String, body: String) -> void:
	sound_player.play()
	posted.emit(app_id, title, body, icons.get(app_id, null))
