# assembly_room.gd
extends Node3D

@export var fig_scn: PackedScene
@export var f_h_off := 0.0
@export var f_r_off := 0.0
@onready var knk_snd: AudioStreamPlayer3D = $KnockSound
@export var f_lgt: OmniLight3D
@export var f_l_norm := Color(1.0, 0.6, 0.3)
@export var f_l_dim := Color(0.7, 0.7, 0.7)
@export var flk_snd: AudioStreamPlayer3D

var fin_fig: Node3D = null
var f_skel: Skeleton3D = null
var hd_bone := -1
var f_state := 0

func _ready() -> void:
	add_to_group("assembly_room")
	knk_snd.add_to_group("world_audio")

func add_piece(p_name: String) -> void:
	var s := find_child(p_name, true, false)
	if not s: return
	for n in get_tree().get_nodes_in_group("printed_model"):
		if n.get_meta("piece_name", "") == p_name:
			n.get_parent().remove_child(n)
			add_child(n)
			n.position = s.position
			n.rotation = s.rotation
			if n is RigidBody3D:
				n.freeze = true
				n.remove_from_group("pickupable")
				n.remove_from_group("printed_model")
			return

func place_figure(p_name: String) -> void:
	var s := find_child(p_name, true, false)
	if not s or fin_fig or not fig_scn: return
	
	fin_fig = fig_scn.instantiate()
	add_child(fin_fig)
	fin_fig.position = s.position + Vector3(0, f_h_off, 0)
	fin_fig.rotation.y = s.rotation.y + deg_to_rad(f_r_off)
	
	f_skel = _find_skel(fin_fig)
	if f_skel:
		hd_bone = f_skel.find_bone("mixamorig_Head")
	start_knocking()

func _find_skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D: return n
	for c in n.get_children():
		var f := _find_skel(c)
		if f: return f
	return null

func start_knocking() -> void:
	while fin_fig and f_state < 2:
		await get_tree().create_timer(randf_range(20.0, 45.0)).timeout
		if fin_fig and f_state < 2:
			knk_snd.play()

func _process(_d: float) -> void:
	if not fin_fig or f_state >= 2: return
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty(): return
	var p: Node3D = ps[0]
	var d: float = p.global_position.distance_to(fin_fig.global_position)
	
	if d < 1.5:
		f_state = 2
		_vanish()
	elif d < 4.0 and f_state < 1:
		f_state = 1
		_turn_hd(p)

func _turn_hd(p: Node3D) -> void:
	if not f_skel or hd_bone == -1: return
	var to_p: Vector3 = (p.global_position - fin_fig.global_position).normalized()
	var tgt := Basis.looking_at(to_p, Vector3.UP)
	var cur := f_skel.get_bone_pose_rotation(hd_bone)
	var tw := create_tween()
	tw.tween_method(func(t: float):
		var b := Quaternion(cur).slerp(Quaternion(tgt), t)
		f_skel.set_bone_pose_rotation(hd_bone, b)
	, 0.0, 1.0, 0.8)

func _vanish() -> void:
	if f_lgt:
		f_lgt.light_color = f_l_norm
		if flk_snd: flk_snd.play()
		var f_cnt := 10
		for i in f_cnt:
			var prg: float = float(i) / float(f_cnt - 1)
			var on_t: float = lerp(0.5, 0.06, prg)
			var off_t: float = lerp(0.2, 0.04, prg)
			var inten: float = lerp(0.4, 2.5, prg)
			f_lgt.light_energy = inten
			f_lgt.visible = true
			await get_tree().create_timer(on_t).timeout
			f_lgt.visible = false
			if i == f_cnt - 1: fin_fig.visible = false
			await get_tree().create_timer(off_t).timeout
		f_lgt.light_color = f_l_dim
		f_lgt.light_energy = 0.3
		f_lgt.visible = true
	else:
		fin_fig.visible = false

func is_vanish_complete() -> bool:
	return f_state >= 2
