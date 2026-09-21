extends Button

signal icon_clicked(icon_name: String)

@export var icon_name: String = ""

@onready var icon_rect: TextureRect = $Content/Icon
@onready var caption: Label = $Content/Caption
@onready var notification_dot: Control = get_node_or_null("NotificationDot")

func _ready() -> void:
	pressed.connect(_on_pressed)
	Notifications.register_icon(icon_name, icon_rect.texture)
	Notifications.register_name(icon_name, caption.text)
	Notifications.posted.connect(_on_notification_posted)
	if icon_name == "documents":
		HorrorState.file_changed.connect(_show_notification)

func _on_notification_posted(app_id: String, _t: String, _b: String, _i: Texture2D) -> void:
	if app_id == icon_name: _show_notification()

func _on_pressed() -> void:
	clear_notification()
	icon_clicked.emit(icon_name)

func _show_notification() -> void:
	if notification_dot: notification_dot.visible = true

func clear_notification() -> void:
	if notification_dot: notification_dot.visible = false

func mark_as_new() -> void:
	if notification_dot: notification_dot.visible = true
