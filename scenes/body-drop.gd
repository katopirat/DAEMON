extends Node3D

@export var p_scns: Dictionary = {}
@export var spc := 0.35

var pl_cnt := 0

func _ready() -> void:
	add_to_group("assembly_room")

func add_piece(p_name: String) -> void:
	if not p_scns.has(p_name): return
	var scn: PackedScene = p_scns[p_name]
	if not scn: return
	var p := scn.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_position = global_position + Vector3(pl_cnt * spc, 0, 0)
	if p is RigidBody3D:
		p.freeze = true
		p.remove_from_group("pickupable")
		p.remove_from_group("printed_model")
	pl_cnt += 1
