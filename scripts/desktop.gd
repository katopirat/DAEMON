extends Control

const TEXT_READER_WINDOW := preload("res://scenes/computer/readme_window.tscn")
const PRINTER_APP_WINDOW := preload("res://scenes/computer/printer_app_window.tscn")
const SETTINGS_WINDOW := preload("res://scenes/computer/settings_window.tscn")
const DOCUMENTS_WINDOW := preload("res://scenes/computer/documents_window.tscn")
const CHAT_WINDOW := preload("res://scenes/computer/chat_window.tscn")
const MAIL_WINDOW := preload("res://scenes/computer/mail_window..tscn")
const IMAGE_VIEWER_WINDOW := preload("res://scenes/computer/image_viewer_window.tscn")
const TERMINAL_WINDOW := preload("res://scenes/computer/terminal_window.tscn")

@onready var background: TextureRect = $Background
@onready var taskbar: Panel = $Taskbar
@onready var toast: PanelContainer = %Toast
@onready var toast_title: Label = %ToastTitle
@onready var toast_body: Label = %ToastBody
@onready var toast_icon: TextureRect = %ToastIcon

func _ready() -> void:
	add_to_group("os_display")
	visible = false
	toast.visible = false
	Notifications.posted.connect(_on_notification)
	for c in get_children():
		if c is Button and c.has_signal("icon_clicked"):
			c.icon_clicked.connect(_on_icon_clicked)

func open_app(scene: PackedScene, params: Dictionary = {}) -> Control:
	var win = scene.instantiate()
	for k in params: win.set(k, params[k])
	add_child(win)
	win.position = Vector2(80, 50)
	taskbar.register_window(win)
	return win

func open_text_reader(file_name: String, content: String) -> void:
	open_app(TEXT_READER_WINDOW, {"file_name": file_name, "file_content": content})

func open_printer_app(file_name: String, file_path: String) -> void:
	open_app(PRINTER_APP_WINDOW, {"file_name": file_name, "file_path": file_path})

func _on_icon_clicked(icon_name: String) -> void:
	match icon_name:
		"readme": open_text_reader("readme.txt", "hello there")
		"settings": open_app(SETTINGS_WINDOW)
		"documents": open_app(DOCUMENTS_WINDOW)
		"chat": open_app(CHAT_WINDOW)
		"mail": open_app(MAIL_WINDOW)
		"terminal": open_app(TERMINAL_WINDOW)
		_: pass

func set_wallpaper(texture: Texture2D) -> void: background.texture = texture
func show_desktop() -> void: visible = true
func hide_desktop() -> void: visible = false
	
func _on_notification(app_id: String, title: String, body: String, icon: Texture2D) -> void:
	toast_icon.texture = icon
	toast_icon.visible = icon != null
	toast_title.text = title
	toast_body.text = body
	toast.visible = true
	toast.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.3)
	tw.tween_interval(5.0)
	tw.tween_property(toast, "modulate:a", 0.0, 0.5)
	tw.finished.connect(func(): toast.visible = false)

func open_attach_picker(requester: Node) -> void:
	var win := open_app(DOCUMENTS_WINDOW)
	win.enable_attach_mode(requester)

func open_image_viewer(file_name: String, path: String) -> void:
	var win := open_app(IMAGE_VIEWER_WINDOW, {"file_path": path})
	win.title_label.text = file_name

func open_avatar_preview(texture: Texture2D) -> void:
	open_app(IMAGE_VIEWER_WINDOW, {"direct_texture": texture})
