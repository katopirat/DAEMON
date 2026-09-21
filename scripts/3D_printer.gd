extends Node3D

@export var head: Node3D
@export var x_rail: Node3D
@export var hotbed: Node3D
@export var print_start: Node3D
@export var spawn_pt: Node3D
@export var disp_lbl: Label3D
@export var items: Array[String] = []
@export var item_objs: Array[MeshInstance3D] = []
@export var item_durs: Array[float] = []
@onready var snd: AudioStreamPlayer3D = %PrinterSound

@export var h_min_x := -0.3
@export var h_max_x := 0.3
@export var r_min_z := -0.2
@export var r_max_z := 0.2
@export var h_spd := 0.15

const S_START := 3.0
const S_TRIM := 4.0

var q_item := ""
var snd_tw: Tween
var is_prt := false
var rdm_mov := false
var out_mesh: MeshInstance3D
var out_body: Node3D
var out_taken := false
var cur_h := 0.0
var hb_start_y := 0.0
var out_start_y := 0.0
var cur_item := ""
var hb_home_y := 0.0
var hb_home_set := false
var prt_tw: Tween

func _ready() -> void:
	add_to_group("printer")
	for o in item_objs: o.visible = false
	hb_home_y = hotbed.global_position.y
	hb_home_set = true
	_upd_disp()

func start_print() -> void:
	if is_prt: return
	if q_item == "":
		if disp_lbl: disp_lbl.text = "NOTHING TO PRINT"
		return
	if out_mesh and not out_taken:
		if disp_lbl: disp_lbl.text = "REMOVE PRINT FIRST"
		return
		
	var idx := items.find(q_item)
	if idx == -1: return

	cur_item = q_item
	q_item = ""
	HorrorState.on_print_started(cur_item)

	if hb_home_set: hotbed.global_position.y = hb_home_y

	is_prt = true
	_start_snd()
	rdm_mov = true
	out_taken = false
	_rdm_head()
	if disp_lbl: disp_lbl.text = "PRINTING..."

	var tpl: MeshInstance3D = item_objs[idx]
	var tpl_body := tpl.get_parent()
	var new_b := tpl_body.duplicate() as Node3D
	add_child(new_b)

	new_b.global_transform = tpl_body.global_transform
	new_b.global_position.x = print_start.global_position.x
	new_b.global_position.z = print_start.global_position.z

	if new_b is RigidBody3D: new_b.freeze = true

	out_body = new_b
	out_mesh = _find_mesh(new_b)
	out_mesh.visible = true
	
	var mat := out_mesh.get_surface_override_material(0) as ShaderMaterial
	if mat: out_mesh.set_surface_override_material(0, mat.duplicate())

	var y_diff: float = out_body.global_position.y - hotbed.global_position.y
	hb_start_y = print_start.global_position.y
	out_start_y = hb_start_y + y_diff

	var mv_tw := create_tween()
	mv_tw.set_parallel(true)
	mv_tw.tween_property(hotbed, "global_position:y", hb_start_y, 1.0)
	mv_tw.tween_property(out_body, "global_position:y", out_start_y, 1.0)
	await mv_tw.finished

	cur_h = _prep_obj(out_mesh)

	var dur: float = item_durs[idx] if idx < item_durs.size() else 10.0
	prt_tw = create_tween()
	prt_tw.tween_method(_upd_step, 0.0, 1.0, dur)
	prt_tw.finished.connect(_on_fin)

func _start_snd() -> void:
	snd.volume_db = -40.0
	_loop_snd()
	if snd_tw: snd_tw.kill()
	snd_tw = create_tween()
	snd_tw.tween_property(snd, "volume_db", 0.0, 1.5)

func _loop_snd() -> void:
	if not is_prt: return
	snd.play(S_START)
	var l: float = snd.stream.get_length()
	var d: float = l - S_TRIM - S_START
	await get_tree().create_timer(d).timeout
	_loop_snd()

func _find_mesh(n: Node) -> MeshInstance3D:
	for c in n.get_children():
		if c is MeshInstance3D: return c
	return null

func _upd_step(t: float) -> void:
	var off := cur_h * t
	hotbed.global_position.y = hb_start_y - off
	if out_body: out_body.global_position.y = out_start_y - off
	if disp_lbl: disp_lbl.text = str(int(t * 100)) + "%"

func _prep_obj(m: MeshInstance3D) -> float:
	m.visible = true
	var aabb: AABB = m.global_transform * m.mesh.get_aabb()
	var mat := m.get_surface_override_material(0) as ShaderMaterial
	if mat: mat.set_shader_parameter("nozzle_world_y", aabb.position.y)
	return aabb.size.y

func _on_fin() -> void:
	HorrorState.on_print_finished(cur_item)
	is_prt = false
	rdm_mov = false

	if snd_tw: snd_tw.kill()
	snd_tw = create_tween()
	snd_tw.tween_property(snd, "volume_db", -40.0, 1.5)
	snd_tw.tween_callback(snd.stop)

	if out_mesh:
		var mat := out_mesh.get_surface_override_material(0) as ShaderMaterial
		if mat: mat.set_shader_parameter("reveal_complete", true)
	_upd_disp()

func _rdm_head() -> void:
	while rdm_mov:
		var tx := randf_range(h_min_x, h_max_x)
		var tz := randf_range(r_min_z, r_max_z)
		var sx := head.position.x
		var sz := x_rail.position.z
		var dist := Vector2(tx - sx, tz - sz).length()
		var dur: float = dist / h_spd if h_spd > 0.0 else 0.3
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(head, "position:x", tx, dur)
		tw.tween_property(x_rail, "position:z", tz, dur)
		await tw.finished

func is_ready_to_take() -> bool:
	return not is_prt and out_mesh != null and not out_taken
	
func take_object() -> Node3D:
	if not is_ready_to_take(): return null
	var b := out_body
	if b:
		b.reparent(self)
		if spawn_pt: b.global_transform = spawn_pt.global_transform
		if b is RigidBody3D:
			b.freeze = false
			b.add_to_group("pickupable")
			b.add_to_group("printed_model")
		b.set_meta("piece_name", cur_item)
		_en_lights(b)
	out_taken = true
	return b

func _en_lights(n: Node) -> void:
	for c in n.get_children():
		if c is OmniLight3D: c.visible = true
		_en_lights(c)

func queue_print(item: String) -> void:
	q_item = item
	_upd_disp()

func _upd_disp() -> void:
	if is_prt or not disp_lbl: return
	disp_lbl.text = "NOTHING TO PRINT" if q_item == "" else "START PRINT"

func cancel_print() -> void:
	if not is_prt: return
	rdm_mov = false
	if snd_tw: snd_tw.kill()
	snd_tw = create_tween()
	snd_tw.tween_property(snd, "volume_db", -40.0, 0.5)
	snd_tw.tween_callback(snd.stop)
	is_prt = false
	if out_body: out_body.queue_free()
	out_mesh = null
	out_body = null
	HorrorState.on_print_cancelled(cur_item)
	_upd_disp()
	
func silent_stop() -> void:
	if not is_prt: return
	if prt_tw: prt_tw.kill()
	rdm_mov = false
	snd.stop()
	is_prt = false
	if out_body: out_body.queue_free()
	out_mesh = null
	out_body = null
	_upd_disp()

func clear_printer() -> void:
	if out_body: out_body.queue_free()
	out_mesh = null
	out_body = null
	out_taken = true
	q_item = ""
	is_prt = false
	_upd_disp()
