extends Area3D

var plyr: CharacterBody3D = null
var zzz := false

func _ready() -> void:
	body_entered.connect(_on_b_ent)
	body_exited.connect(_on_b_ex)

func _on_b_ent(b: Node3D) -> void:
	if b.is_in_group("player"): plyr = b

func _on_b_ex(b: Node3D) -> void:
	if b == plyr:
		plyr = null
		get_tree().call_group("hint_display", "clear_hints", "bed")

func _process(_d: float) -> void:
	if not plyr or zzz: return
		
	if HorrorState.can_sleep:
		get_tree().call_group("hint_display", "show_hints", "bed", [["e", "Sleep"]])
		if Input.is_action_just_pressed("interact"): _sleep()
	else:
		get_tree().call_group("hint_display", "clear_hints", "bed")
		
func _sleep() -> void:
	zzz = true
	get_tree().call_group("hint_display", "clear_hints", "bed")
	get_tree().call_group("world_audio", "stop")
	get_tree().call_group("night_sequence", "go_to_sleep")
	await get_tree().create_timer(10.0).timeout
	zzz = false
