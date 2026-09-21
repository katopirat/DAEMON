extends Panel

const S_APPS := [
	{"name": "My Computer", "id": "documents"},
	{"name": "Settings", "id": "settings"},
	{"name": "Thiscord", "id": "chat"},
	{"name": "Mail", "id": "mail"},
	{"name": "readme.txt", "id": "readme"},
]

@onready var window_buttons: HBoxContainer = %WindowButtons
@onready var start_button: Button = %StartButton
@onready var start_menu: PanelContainer = %StartMenu
@onready var start_menu_list: VBoxContainer = %StartMenuList
@onready var clock_label: Label = %ClockLabel

func _ready() -> void:
	start_button.pressed.connect(_tog_start)
	await get_tree().process_frame
	_bld_start()
	var tmr := Timer.new()
	tmr.wait_time = 1.0
	tmr.timeout.connect(_upd_clk)
	add_child(tmr)
	tmr.start()
	_upd_clk()

func register_window(win: AppWindow) -> void:
	var btn := Button.new()
	btn.icon = win.window_icon
	btn.text = ""
	btn.custom_minimum_size = Vector2(32, 28)
	btn.pressed.connect(func(): win.focus_window())
	window_buttons.add_child(btn)
	win.tree_exiting.connect(btn.queue_free)

func _bld_start() -> void:
	for app in S_APPS:
		var btn := Button.new()
		btn.text = app.name
		btn.flat = true
		btn.icon = Notifications.icons.get(app.id, null)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_app_prs.bind(app.id))
		start_menu_list.add_child(btn)

func _on_app_prs(app_id: String) -> void:
	start_menu.visible = false
	get_parent()._on_icon_clicked(app_id)

func _tog_start() -> void: start_menu.visible = not start_menu.visible

func _upd_clk() -> void:
	clock_label.text = "%02d:%02d" % [HorrorState.game_hour, HorrorState.game_minute]
