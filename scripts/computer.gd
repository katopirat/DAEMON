extends Node3D

@export var screen_mesh: MeshInstance3D
var is_on := false
var pulsing := false

func _ready() -> void:
	Notifications.posted.connect(_on_notification)

func power_on() -> void:
	pulsing = false
	await get_tree().create_timer(1).timeout
	get_tree().call_group("os_display", "show_desktop")
	if is_on: return
	is_on = true
	var mat := screen_mesh.get_surface_override_material(0)
	var tw := create_tween()
	tw.tween_property(mat, "emission_energy_multiplier", 2.5, 0.8)

func _on_notification(app_id: String, _t: String, _b: String, _i: Texture2D) -> void:
	if app_id == "chat" and not is_on and not pulsing:
		_pulse_loop()

func _pulse_loop() -> void:
	pulsing = true
	var mat := screen_mesh.get_surface_override_material(0)
	if not mat: return
	while pulsing and not is_on:
		var tw := create_tween()
		tw.tween_property(mat, "emission_energy_multiplier", 1.0, 1.0)
		tw.tween_property(mat, "emission_energy_multiplier", 0.15, 1.0)
		await tw.finished
