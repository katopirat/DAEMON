extends Area3D

@export var cam_tgt: Node3D
@export var ptr: Node3D
@export var prt_btn: StaticBody3D

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
		if b.is_focused:
			b.stop_focusing()
			prt_btn.deactivate()
		plyr = null
		get_tree().call_group("hint_display", "clear_hints", "printer")

func _upd_h() -> void:
	if ptr.is_ready_to_take():
		get_tree().call_group("hint_display", "show_hints", "printer", [["e", "Take model"]])
	else:
		get_tree().call_group("hint_display", "show_hints", "printer", [["e", "Use 3D printer"]])

func _process(_d: float) -> void:
	if not plyr: return
	if not plyr.is_focused:
		_upd_h()
		if Input.is_action_just_pressed("interact"):
			if ptr.is_ready_to_take():
				ptr.take_object()
				get_tree().call_group("hint_display", "clear_hints", "printer")
			else:
				plyr.look_at_target(cam_tgt)
				prt_btn.activate()
				get_tree().call_group("hint_display", "clear_hints", "printer")
	else:
		if Input.is_action_just_pressed("escape"):
			plyr.stop_focusing()
			prt_btn.deactivate()
			_upd_h()
