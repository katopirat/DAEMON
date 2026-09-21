extends CharacterBody3D

const SPEED = 2
const JUMP_VELOCITY = 3
const CITLIVOST = 0.003
@onready var kamera_pivot = $CameraPivot
@onready var footstep_sound: AudioStreamPlayer3D = %FootstepSound
@export var footstep_clips: Array[AudioStream] = []
const FOOTSTEP_INTERVAL := 0.45
var footstep_timer := 0.0
var last_footstep_index := -1
@onready var camera: Camera3D = $CameraPivot/Camera3D

const BOB_FREQUENCY := 2.4
const BOB_AMPLITUDE := 0.032
const BOB_SMOOTHING := 8.0
var target_rotation_y := 0.0
var target_pivot_x := 0.0
const LOOK_SMOOTHING := 20.0
var bob_time := 0.0
var camera_base_y := 0.0

var is_sitting := false
var is_focused := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")
	camera_base_y = camera.position.y

func _physics_process(delta: float) -> void:
	if is_sitting:
		if Input.is_action_just_pressed("escape"): stand_up()
		return
	if is_focused: return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	move_and_slide()
	_handle_footsteps(delta)
	_update_head_bob(delta)
	rotation.y = lerp_angle(rotation.y, target_rotation_y, delta * LOOK_SMOOTHING)
	kamera_pivot.rotation.x = lerp_angle(kamera_pivot.rotation.x, target_pivot_x, delta * LOOK_SMOOTHING)

func _input(event): _handle_look_input(event)

func _handle_look_input(event):
	if is_sitting: return
	if event is InputEventMouseMotion:
		if _is_holding_object() and Input.is_action_pressed("rotate"):
			get_tree().call_group("object_holder", "rotate_held_object", event.relative)
		else:
			target_rotation_y -= event.relative.x * CITLIVOST * Settings.mouse_sensitivity
			target_pivot_x -= event.relative.y * CITLIVOST * Settings.mouse_sensitivity
			target_pivot_x = clamp(target_pivot_x, deg_to_rad(-80), deg_to_rad(80))
	if Input.is_action_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_focused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _is_holding_object() -> bool:
	var holders = get_tree().get_nodes_in_group("object_holder")
	return holders.size() > 0 and holders[0].is_holding()

func sit_down(target: Node3D) -> void:
	camera.position.y = camera_base_y
	is_sitting = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "global_position", target.global_position, 0.6)
	tw.tween_property(self, "global_rotation:y", target.global_rotation.y, 0.6)
	tw.tween_property(kamera_pivot, "rotation:x", target.rotation.x, 0.6)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group("crosshair_display", "hide_crosshair")

func stand_up() -> void:
	is_sitting = false
	get_tree().call_group("hint_display", "clear_hints", "chair")
	get_tree().call_group("os_display", "hide_desktop")
	get_tree().call_group("crosshair_display", "show_crosshair")
	
func look_at_target(target: Node3D) -> void:
	is_focused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "global_position", target.global_position, 0.4)
	tw.tween_property(self, "global_rotation:y", target.global_rotation.y, 0.4)
	tw.tween_property(kamera_pivot, "rotation:x", target.rotation.x, 0.4)

func stop_focusing() -> void:
	is_focused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _handle_footsteps(delta: float) -> void:
	if is_sitting or is_focused: return
	var moving := Vector2(velocity.x, velocity.z).length() > 0.5
	if moving and is_on_floor():
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			_play_random_footstep()
			footstep_timer = FOOTSTEP_INTERVAL
	else:
		footstep_timer = 0.0

func _play_random_footstep() -> void:
	if footstep_clips.is_empty(): return
	var idx := randi_range(0, footstep_clips.size() - 1)
	if footstep_clips.size() > 1:
		while idx == last_footstep_index:
			idx = randi_range(0, footstep_clips.size() - 1)
	last_footstep_index = idx
	footstep_sound.stream = footstep_clips[idx]
	footstep_sound.pitch_scale = randf_range(0.9, 1.1)
	footstep_sound.play()

func _update_head_bob(delta: float) -> void:
	if is_sitting or is_focused:
		camera.position.y = lerp(camera.position.y, camera_base_y, delta * BOB_SMOOTHING)
		return
	var moving := Vector2(velocity.x, velocity.z).length() > 0.5 and is_on_floor()
	if moving:
		bob_time += delta * BOB_FREQUENCY * (1.0 + Vector2(velocity.x, velocity.z).length() / SPEED)
		var target_y: float = camera_base_y + sin(bob_time) * BOB_AMPLITUDE
		camera.position.y = lerp(camera.position.y, target_y, delta * BOB_SMOOTHING)
	else:
		bob_time = 0.0
		camera.position.y = lerp(camera.position.y, camera_base_y, delta * BOB_SMOOTHING)
