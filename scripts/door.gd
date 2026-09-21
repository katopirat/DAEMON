extends Area3D

@export var door_pivot: Node3D
@export var open_angle := 90.0
@export var open_duration := 0.6
var stop_timer: SceneTreeTimer
@export var silences_printer := false
@export var silences_only_on_night := 0

@onready var door_sound: AudioStreamPlayer3D = $DoorSound

var player_nearby: CharacterBody3D = null
var is_open := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = body
		get_tree().call_group("hint_display", "show_hints", "door", [["e", "Open" if not is_open else "Close"]])

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null
		get_tree().call_group("hint_display", "clear_hints", "door")

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"): _toggle_door()

func _toggle_door() -> void:
	is_open = not is_open
	if is_open:
		_play_door_sound(0.20, 1.35)
		if silences_printer and (silences_only_on_night == 0 or HorrorState.night == silences_only_on_night):
			get_tree().call_group("printer", "silent_stop")
	else:
		_play_door_sound(2.94, 4.49)
	var tgt_angle := deg_to_rad(open_angle) if is_open else 0.0
	var tw := create_tween()
	tw.tween_property(door_pivot, "rotation:z", tgt_angle, open_duration)
	get_tree().call_group("hint_display", "show_hints", "door", [["e", "Close" if is_open else "Open"]])

func _play_door_sound(start: float, stop_at: float) -> void:
	if stop_timer:
		stop_timer.timeout.disconnect(door_sound.stop)
		stop_timer = null
	door_sound.play(start)
	stop_timer = get_tree().create_timer(stop_at - start)
	stop_timer.timeout.connect(door_sound.stop)
	
func force_open() -> void:
	is_open = true
	door_pivot.rotation.z = deg_to_rad(open_angle)
