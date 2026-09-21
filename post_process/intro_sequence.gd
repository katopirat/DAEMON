extends Node

@export var first_message_delay := 10.0 
@export var rise_duration := 3.5
@export var sway_amount := 6.0

@onready var fade_rect: ColorRect = %FadeRect
@onready var night_card: Label = %NightCard

var player: CharacterBody3D
var intro_camera: Camera3D
var player_camera: Camera3D

var bed_transform: Transform3D 
var setup_done := false

func _ready() -> void:
	add_to_group("night_sequence")
	fade_rect.color.a = 1.0
	await get_tree().process_frame
	
	if _setup_nodes():
		bed_transform = intro_camera.global_transform
		setup_done = true
		
	begin_night(1)

func _setup_nodes() -> bool:
	var ps := get_tree().get_nodes_in_group("player")
	var cams := get_tree().get_nodes_in_group("intro_camera")
	if ps.is_empty() or cams.is_empty(): return false
		
	player = ps[0]
	intro_camera = cams[0]
	player_camera = _find_camera(player)
	return player_camera != null

func _run_intro(urgent: bool = false) -> void:
	if not setup_done: return

	intro_camera.global_transform = bed_transform
	player.is_focused = true
	_set_player_visuals(false)
	intro_camera.current = true

	if urgent:
		await get_tree().create_timer(0.15).timeout
		var jolt := create_tween()
		jolt.tween_property(fade_rect, "color:a", 0.0, 0.1)
		await jolt.finished
	else:
		await get_tree().create_timer(1.5).timeout
		var blink := create_tween()
		blink.tween_property(fade_rect, "color:a", 0.35, 0.5)
		blink.tween_interval(0.25)
		blink.tween_property(fade_rect, "color:a", 1.0, 0.3)
		blink.tween_interval(0.5)
		blink.tween_property(fade_rect, "color:a", 0.0, 1.8)
		await blink.finished
		await get_tree().create_timer(1.5).timeout

	var start_t := intro_camera.global_transform
	var end_t := player_camera.global_transform
	var start_rot := Quaternion(start_t.basis.orthonormalized())
	var end_rot := Quaternion(end_t.basis.orthonormalized())
	var d: float = rise_duration * (0.35 if urgent else 1.0)

	var rise := create_tween()
	rise.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	rise.tween_method(func(t: float):
		var pos: Vector3 = start_t.origin.lerp(end_t.origin, t)
		var rot: Quaternion = start_rot.slerp(end_rot, t)
		var sway := Quaternion(Vector3.FORWARD, deg_to_rad(sin(t * PI) * sway_amount))
		intro_camera.global_transform = Transform3D(Basis(rot * sway), pos)
	, 0.0, 1.0, d)
	await rise.finished

	player_camera.current = true
	_set_player_visuals(true)
	player.is_focused = false

func go_to_sleep() -> void:
	if not setup_done: return
	
	player.is_focused = true
	_set_player_visuals(false)
	
	intro_camera.global_transform = player_camera.global_transform
	intro_camera.current = true
	
	var start_t := player_camera.global_transform
	var end_t := bed_transform
	var start_rot := Quaternion(start_t.basis.orthonormalized())
	var end_rot := Quaternion(end_t.basis.orthonormalized())

	var fall := create_tween()
	fall.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fall.tween_method(func(t: float):
		var pos: Vector3 = start_t.origin.lerp(end_t.origin, t)
		var rot: Quaternion = start_rot.slerp(end_rot, t)
		var sway := Quaternion(Vector3.FORWARD, deg_to_rad(sin(t * PI) * sway_amount))
		intro_camera.global_transform = Transform3D(Basis(rot * sway), pos)
	, 0.0, 1.0, rise_duration)
	
	await fall.finished
	
	var blink := create_tween()
	blink.tween_property(fade_rect, "color:a", 1.0, 0.2)
	blink.tween_interval(0.3)
	blink.tween_property(fade_rect, "color:a", 0.3, 0.3) 
	blink.tween_interval(0.2)
	blink.tween_property(fade_rect, "color:a", 1.0, 1.0) 
	
	await blink.finished
	
	night_card.text = "NIGHT %d" % (HorrorState.night + 1)
	night_card.visible = true
	night_card.modulate.a = 0.0
	var card_tw := create_tween()
	card_tw.tween_property(night_card, "modulate:a", 1.0, 0.6)
	card_tw.tween_interval(1.2)
	card_tw.tween_property(night_card, "modulate:a", 0.0, 0.6)
	await card_tw.finished
	night_card.visible = false
	
	await get_tree().create_timer(3.5).timeout
	HorrorState.start_next_night()

func begin_night(n: int) -> void:
	if n == 3: _dim_room_lights()
	await _run_intro(n == 3)
	await get_tree().create_timer(first_message_delay).timeout
	match n:
		1:
			ChatProgress.queue_session("session_1")
			Notifications.post("chat", "jake", "sent you a message")
		2:
			ChatProgress.queue_session("session_2")
			Notifications.post("chat", "jake", "sent you a message")

func _find_camera(node: Node) -> Camera3D:
	for c in node.get_children():
		if c is Camera3D: return c
		var f := _find_camera(c)
		if f: return f
	return null

func _set_player_visuals(state: bool) -> void: _apply_visibility(player, state)

func _apply_visibility(node: Node, state: bool) -> void:
	for c in node.get_children():
		if c is MeshInstance3D: c.visible = state
		_apply_visibility(c, state)

func _dim_room_lights() -> void:
	for l in get_tree().get_nodes_in_group("room_lights"): l.light_energy *= 0.4
