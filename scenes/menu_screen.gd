extends Control

@onready var new_game_button: Button = %NewGameButton
@onready var credits_button: Button = %CreditsButton
@onready var quit_button: Button = %QuitButton
@onready var title_label: Label = %TitleLabel
@onready var menu_buttons: Control = %MenuButtons
@onready var thanks_box: Control = %ThanksBox
@export var menu_camera: Camera3D
@onready var settings_button: Button = %SettingsButton
@onready var settings_box: Control = %SettingsBox
@onready var volume_slider: HSlider = %VolumeSlider
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var settings_back_button: Button = %SettingsBackButton
var camera_base_pos: Vector3

signal any_key_pressed

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	new_game_button.pressed.connect(_on_new_game)
	credits_button.pressed.connect(_on_credits)
	quit_button.pressed.connect(_on_quit)
	quit_button.visible = OS.get_name() != "Web"
	_flicker_title()
	if menu_camera:
		camera_base_pos = menu_camera.position
		_sway_camera()

	thanks_box.visible = false
	thanks_box.modulate.a = 0.0

	settings_box.visible = false
	settings_button.pressed.connect(_on_settings_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)
	volume_slider.value = Settings.master_volume
	volume_slider.value_changed.connect(_on_volume_changed)
	sensitivity_slider.value = Settings.mouse_sensitivity
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)

	if HorrorState.show_thanks_on_menu:
		HorrorState.show_thanks_on_menu = false
		menu_buttons.visible = false
		_show_thanks()
	else:
		menu_buttons.visible = true
		menu_buttons.modulate.a = 1.0

func _input(event: InputEvent) -> void:
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		any_key_pressed.emit()

func _show_thanks() -> void:
	thanks_box.visible = true
	thanks_box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(thanks_box, "modulate:a", 1.0, 1.5)
	await tw.finished
	await any_key_pressed
	var fo := create_tween()
	fo.tween_property(thanks_box, "modulate:a", 0.0, 1.0)
	await fo.finished
	thanks_box.visible = false
	menu_buttons.visible = true
	menu_buttons.modulate.a = 0.0
	var fi := create_tween()
	fi.tween_property(menu_buttons, "modulate:a", 1.0, 1.0)

func _flicker_title() -> void:
	while true:
		await get_tree().create_timer(randf_range(3.0, 8.0)).timeout
		var t := create_tween()
		t.tween_property(title_label, "modulate:a", 0.3, 0.05)
		t.tween_property(title_label, "modulate:a", 1.0, 0.05)
		t.tween_property(title_label, "modulate:a", 0.5, 0.04)
		t.tween_property(title_label, "modulate:a", 1.0, 0.08)

func _sway_camera() -> void:
	while true:
		var offset := Vector3(randf_range(-0.01, 0.01), randf_range(-0.005, 0.005), 0)
		var tw := create_tween()
		tw.tween_property(menu_camera, "position", camera_base_pos + offset, randf_range(2.0, 4.0))
		await tw.finished

func _on_new_game() -> void:
	GameFiles.reset()
	get_tree().call_group("fade_layer", "fade_to_black_and_load", "res://post_process/pp_stack.tscn")

func _on_credits() -> void: get_tree().change_scene_to_file("res://scenes/credits.tscn")
func _on_quit() -> void: get_tree().quit()

func _on_settings_pressed() -> void:
	menu_buttons.visible = false
	settings_box.visible = true

func _on_settings_back_pressed() -> void:
	Settings.save_settings()
	settings_box.visible = false
	menu_buttons.visible = true

func _on_volume_changed(v: float) -> void:
	Settings.master_volume = v
	Settings.apply_settings()

func _on_sensitivity_changed(v: float) -> void:
	Settings.mouse_sensitivity = v
