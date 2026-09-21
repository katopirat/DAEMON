extends Camera3D

const PK_RNG := 3.0
const H_DIST := 1.5
const H_FRC := 12.0
const R_SENS := 0.15
const COL_MRG := 0.2
const MIN_H_DIST := 0.3
const PHO_RNG := 3.0
const PK_LYR := 5
const PHO_PATH := "user://os_files/photos/model_photo.png"

var held: RigidBody3D = null
var p_ang_vel := Vector3.ZERO
var shw_pho_h := false
var shw_pk_h := false

func _ready() -> void:
	add_to_group("object_holder")

func _physics_process(_d: float) -> void:
	if held:
		var tgt_d := _get_clamp_d()
		var tgt_p = global_position - global_transform.basis.z * tgt_d
		var to_tgt = tgt_p - held.global_position
		held.linear_velocity = to_tgt * H_FRC
		held.angular_velocity = p_ang_vel
		p_ang_vel = Vector3.ZERO

func _process(_d: float) -> void:
	if Input.is_action_just_pressed("pick_up"): _try_pk()
	elif Input.is_action_just_released("pick_up"): _drp()
	
	if Input.is_action_just_pressed("photo"): _try_pho()
	_upd_pho_h()
	_upd_pk_h()

func _upd_pho_h() -> void:
	var can_pho := _is_lk_mdl()
	if can_pho and not shw_pho_h:
		shw_pho_h = true
		get_tree().call_group("hint_display", "show_hints", "photo", [["c", "Take photo"]])
	elif not can_pho and shw_pho_h:
		shw_pho_h = false
		get_tree().call_group("hint_display", "clear_hints", "photo")

func _upd_pk_h() -> void:
	if held:
		if shw_pk_h:
			shw_pk_h = false
			get_tree().call_group("hint_display", "clear_hints", "pickup_prompt")
		return
	var can_pk := _is_lk_pk()
	if can_pk and not shw_pk_h:
		shw_pk_h = true
		get_tree().call_group("hint_display", "show_hints", "pickup_prompt", [["mouse_left", "Grab"]])
	elif not can_pk and shw_pk_h:
		shw_pk_h = false
		get_tree().call_group("hint_display", "clear_hints", "pickup_prompt")

func _is_lk_pk() -> bool:
	var ss := get_world_3d().direct_space_state
	var frm := global_position
	var to := global_position - global_transform.basis.z * PK_RNG
	var q := PhysicsRayQueryParameters3D.create(frm, to)
	var r := ss.intersect_ray(q)
	return r and r.collider is RigidBody3D and r.collider.is_in_group("pickupable")

func _is_lk_mdl() -> bool:
	var tgt: Node = held
	if not tgt:
		var ss := get_world_3d().direct_space_state
		var frm := global_position
		var to := global_position - global_transform.basis.z * PHO_RNG
		var q := PhysicsRayQueryParameters3D.create(frm, to)
		var r := ss.intersect_ray(q)
		if r: tgt = r.collider
	return tgt and tgt.is_in_group("printed_model")

func _get_clamp_d() -> float:
	var ss := get_world_3d().direct_space_state
	var frm := global_position
	var to := global_position - global_transform.basis.z * H_DIST
	var q := PhysicsRayQueryParameters3D.create(frm, to)
	q.exclude = [held.get_rid()]
	var r := ss.intersect_ray(q)
	if r:
		var hd := global_position.distance_to(r.position)
		return max(hd - COL_MRG, MIN_H_DIST)
	return H_DIST

func _try_pk() -> void:
	var ss := get_world_3d().direct_space_state
	var frm := global_position
	var to := global_position - global_transform.basis.z * PK_RNG
	var q := PhysicsRayQueryParameters3D.create(frm, to)
	var r := ss.intersect_ray(q)
	if r and r.collider is RigidBody3D and r.collider.is_in_group("pickupable"):
		held = r.collider
		held.gravity_scale = 0.0
		var ps := get_tree().get_nodes_in_group("player")
		if not ps.is_empty(): ps[0].set_collision_mask_value(PK_LYR, false)
		get_tree().call_group("hint_display", "show_hints", "pickup", [["tab", "Rotate"]])

func _drp() -> void:
	if held:
		held.gravity_scale = 1.0
		held.linear_velocity = Vector3.ZERO
		held.angular_velocity = Vector3.ZERO
		var ps := get_tree().get_nodes_in_group("player")
		if not ps.is_empty(): ps[0].set_collision_mask_value(PK_LYR, true)
		held = null
		get_tree().call_group("hint_display", "clear_hints", "pickup")

func is_holding() -> bool:
	return held != null

func rotate_held_object(md: Vector2) -> void:
	if not held: return
	var y_ax = global_transform.basis.y.normalized()
	var p_ax = global_transform.basis.x.normalized()
	p_ang_vel += y_ax * (-md.x * R_SENS) + p_ax * (-md.y * R_SENS)

func roll_held_object(amt: float) -> void:
	if held:
		held.global_rotate(-global_transform.basis.z.normalized(), amt)
		held.angular_velocity = Vector3.ZERO

func _try_pho() -> void:
	if _is_lk_mdl():
		get_tree().call_group("photo_flash", "flash")
		_cap_pho()
		HorrorState.on_model_photographed()

func _cap_pho() -> void:
	await RenderingServer.frame_post_draw
	var i := get_viewport().get_texture().get_image()
	i.save_png(PHO_PATH)
