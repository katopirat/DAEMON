extends Area3D

var trig := false

func _ready() -> void:
	body_entered.connect(_on_b_ent)

func _on_b_ent(b: Node3D) -> void:
	if not b.is_in_group("player") or trig or HorrorState.night < 4: return
	var rms := get_tree().get_nodes_in_group("assembly_room")
	if rms.is_empty() or not rms[0].is_vanish_complete(): return
	trig = true
	get_tree().call_group("finale_sequence", "trigger_window_sighting")
