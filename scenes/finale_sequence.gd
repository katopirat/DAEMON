extends Node

@export var window_spot: Node3D
@export var figure_scene: PackedScene
@export var black_room_spawn: Node3D
@export var figure_height_offset := 0.0
@export var figure_rotation_offset := 0.0
@export var desk_figure_stand_spot: Node3D
@export var ending_music: AudioStreamPlayer
@export var sit_sound: AudioStreamPlayer3D
@export var big_screen: Node3D
@export var big_screen_mesh: Node3D
@export var voice_line: AudioStreamPlayer

var window_shown := false
var jumpscare_done := false
var finale_started := false
var seated_figure: Node3D = null
var idle_loop_active := false
var idle_loop_forward := true

func _ready() -> void:
	add_to_group("finale_sequence")

func trigger_window_sighting() -> void:
	if HorrorState.night < 4 or window_shown or finale_started: return
	window_shown = true
	if not window_spot or not figure_scene: return
	var ghost := figure_scene.instantiate()
	get_tree().current_scene.add_child(ghost)
	ghost.global_position = window_spot.global_position + Vector3(0, figure_height_offset, 0)
	ghost.global_rotation.y = window_spot.global_rotation.y + deg_to_rad(figure_rotation_offset)
	await get_tree().create_timer(4.0).timeout
	get_tree().call_group("fade_layer", "quick_blink")
	await get_tree().create_timer(0.1).timeout
	ghost.queue_free()
	await get_tree().create_timer(8.0).timeout
	_trigger_jumpscare()

func _trigger_jumpscare() -> void:
	if HorrorState.night < 4 or jumpscare_done or finale_started: return
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty(): return
	var p: Node3D = ps[0]
	var behind: Vector3 = p.global_position + p.global_transform.basis.z * 1.2

	var ss := p.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p.global_position, behind)
	var r := ss.intersect_ray(q)
	if r: behind = r.position - p.global_transform.basis.z * 0.3

	var ghost := figure_scene.instantiate()
	get_tree().current_scene.add_child(ghost)
	ghost.global_position = behind + Vector3(0, figure_height_offset, 0)
	ghost.look_at(p.global_position, Vector3.UP)
	ghost.rotate_y(deg_to_rad(figure_rotation_offset))
	_wait_for_look_at_ghost(p, ghost)
	
func _is_or_child_of(node: Node, ancestor: Node) -> bool:
	var cur := node
	while cur:
		if cur == ancestor: return true
		cur = cur.get_parent()
	return false

func _wait_for_look_at_ghost(p: Node3D, ghost: Node3D) -> void:
	while is_instance_valid(ghost):
		var cam: Camera3D = p.camera
		if cam:
			var ss := cam.get_world_3d().direct_space_state
			var frm := cam.global_position
			var to := cam.global_position - cam.global_transform.basis.z * 3.0
			var q := PhysicsRayQueryParameters3D.create(frm, to)
			var r := ss.intersect_ray(q)
			if r and _is_or_child_of(r.collider, ghost):
				jumpscare_done = true
				var snd: AudioStreamPlayer3D = ghost.find_child("ScareSound", true, false)
				if snd: snd.play()
				await get_tree().create_timer(0.3).timeout
				_start_fall_sequence(p, ghost)
				return
		await get_tree().process_frame

func _start_fall_sequence(player, ghost: Node3D) -> void:
	HorrorState.finale_locked = true
	finale_started = true
	player.is_focused = true
	var pivot: Node3D = player.kamera_pivot
	var start_y: float = player.global_position.y
	var start_pitch: float = pivot.rotation.x

	var fall := create_tween()
	fall.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fall.tween_method(func(t: float):
		player.global_position.y = start_y - 0.6 * t
		pivot.rotation.x = lerp(start_pitch, deg_to_rad(-80.0), t)
		pivot.rotation.z = sin(t * PI * 3.0) * deg_to_rad(2.0) * (1.0 - t)
	, 0.0, 1.0, 1.6)
	await fall.finished

	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(ghost): ghost.queue_free()
	get_tree().call_group("fade_layer", "fade_to_black_and_call", self, "_enter_black_room")

func _enter_black_room() -> void:
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty(): return
	ps[0].global_transform = black_room_spawn.global_transform
	ps[0].is_focused = false
	if ending_music: ending_music.play()
	await get_tree().create_timer(3.0).timeout
	_spawn_desk_figure_dormant()
	_wait_for_look_at_screen(ps[0])

func _spawn_desk_figure_dormant() -> void:
	if not figure_scene or not desk_figure_stand_spot: return
	seated_figure = figure_scene.instantiate()
	get_tree().current_scene.add_child(seated_figure)
	seated_figure.global_position = desk_figure_stand_spot.global_position + Vector3(0, figure_height_offset, 0)
	seated_figure.global_rotation.y = desk_figure_stand_spot.global_rotation.y + deg_to_rad(figure_rotation_offset)

func _wait_for_look_at_screen(p: Node3D) -> void:
	var trig := false
	while not trig:
		var cam: Camera3D = p.camera
		if cam and big_screen:
			var ss := cam.get_world_3d().direct_space_state
			var frm := cam.global_position
			var to := cam.global_position - cam.global_transform.basis.z * 10.0
			var q := PhysicsRayQueryParameters3D.create(frm, to)
			var r := ss.intersect_ray(q)
			if r and _is_or_child_of(r.collider, big_screen):
				trig = true
				_play_sit_animation()
				if sit_sound: sit_sound.play()
				await get_tree().create_timer(1.0).timeout
				_light_up_screen()
				return
		await get_tree().process_frame

func _light_up_screen() -> void:
	if big_screen_mesh:
		var tween := create_tween()
		tween.tween_method(big_screen_mesh.set_brightness, 0.0, 1.0, 0.5)
	await get_tree().create_timer(7.0).timeout
	if voice_line:
		voice_line.play()
		await voice_line.finished
	await get_tree().create_timer(5.0).timeout
	_play_stand_up_animation()

func _play_sit_animation() -> void:
	var anim := _find_animation_player(seated_figure)
	if not anim: return
	var lst := anim.get_animation_list()
	if lst.size() > 0:
		anim.play(lst[0])
		await anim.animation_finished
		_start_idle_loop(anim, lst[0])

func _start_idle_loop(anim: AnimationPlayer, aname: String) -> void:
	idle_loop_active = true
	idle_loop_forward = true
	_idle_loop_tick(anim, aname)

func _idle_loop_tick(anim: AnimationPlayer, aname: String) -> void:
	while idle_loop_active and is_instance_valid(anim):
		if idle_loop_forward:
			anim.speed_scale = 1.0
			anim.play(aname)
			anim.seek(5.5, true)
			while anim.current_animation_position < 10.0 and idle_loop_active:
				await get_tree().process_frame
			anim.pause()
			idle_loop_forward = false
		else:
			anim.speed_scale = -1.0
			anim.play(aname)
			anim.seek(10.0, true)
			while anim.current_animation_position > 5.5 and idle_loop_active:
				await get_tree().process_frame
			anim.pause()
			idle_loop_forward = true

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for c in node.get_children():
		var f := _find_animation_player(c)
		if f: return f
	return null

func _play_stand_up_animation() -> void:
	idle_loop_active = false
	var anim := _find_animation_player(seated_figure)
	if anim == null:
		_finish_ending()
		return
	var anim_list := anim.get_animation_list()
	if anim_list.is_empty():
		_finish_ending()
		return
	var anim_name: String = anim_list[0]
	var anim_length: float = anim.get_animation(anim_name).length
	var fade_start_time: float = max(anim_length - 0.5, 0.0)

	anim.speed_scale = -1.0
	anim.play(anim_name)
	anim.seek(anim_length, true)

	var faded := false
	while anim.is_playing():
		if not faded and anim.current_animation_position <= fade_start_time:
			faded = true
			if big_screen_mesh:
				var fade_tween := create_tween()
				fade_tween.tween_method(big_screen_mesh.set_brightness, 1.0, 0.0, 0.5)
		await get_tree().process_frame

	if not faded and big_screen_mesh:
		big_screen_mesh.set_brightness(0.0)

	await get_tree().create_timer(5.0).timeout
	_finish_ending()

func _finish_ending() -> void:
	HorrorState.show_thanks_on_menu = true
	get_tree().call_group("fade_layer", "fade_to_black_and_load", "res://scenes/menu_stack.tscn")
