extends Area3D

@export var cam_tgt: Node3D
@export var comp: Node

var plyr: CharacterBody3D = null

func _ready() -> void:
	body_entered.connect(_on_b_ent)
	body_exited.connect(_on_b_ex)

func _on_b_ent(b: Node3D) -> void:
	if b.is_in_group("player"):
		plyr = b
		_upd_h()

func _on_b_ex(b: Node3D) -> void:
	if b == plyr:
		plyr = null
		get_tree().call_group("hint_display", "clear_hints", "chair")

func _upd_h() -> void:
	if HorrorState.power_out:
		get_tree().call_group("hint_display", "show_hints", "chair", [["e", "No power"]])
	else:
		get_tree().call_group("hint_display", "show_hints", "chair", [["e", "Sit down"]])

func _process(_d: float) -> void:
	if not plyr: return
	if plyr.is_sitting:
		get_tree().call_group("hint_display", "show_hints", "chair", [["esc", "Leave computer"]])
		return
	if HorrorState.finale_locked: return
	
	_upd_h()
	if Input.is_action_just_pressed("interact") and not HorrorState.power_out:
		plyr.sit_down(cam_tgt)
		comp.power_on()
		get_tree().call_group("hint_display", "clear_hints", "chair")
