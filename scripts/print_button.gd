extends StaticBody3D

@export var printer: Node3D
@export var hover_offset := 0.001
@export var press_offset := 0.006
@onready var click_sound: AudioStreamPlayer3D = %ClickSound
var s_tmr: SceneTreeTimer

var b_pos: Vector3
var b_dir: Vector3
var act := false
var hov := false
var prs := false
var w_md := false
var tw: Tween

func _ready() -> void:
	b_pos = position
	b_dir = transform.basis.z.normalized()

func activate() -> void: act = true

func deactivate() -> void:
	act = false
	prs = false
	hov = false
	w_md = false
	if tw: tw.kill()
	position = b_pos

func _process(_d: float) -> void:
	if not act: return
	var is_h := _chk_hov()
	var md := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if md and not w_md and is_h:
		_press()
		if printer: printer.start_print()
	elif not md and prs:
		_rel(is_h)
	w_md = md

	if is_h != hov and not prs:
		hov = is_h
		_anim(hover_offset if is_h else 0.0, false)

func _press() -> void:
	_ply_clk(0.04, 0.14)
	prs = true
	_anim(press_offset, true)

func _rel(still_h: bool) -> void:
	_ply_clk(0.23, -1.0)
	prs = false
	hov = still_h
	_anim(hover_offset if still_h else 0.0, false)

func _anim(tgt: float, dn: bool) -> void:
	if tw: tw.kill()
	tw = create_tween()
	if dn:
		tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position", b_pos + b_dir * tgt, 0.08)
	else:
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position", b_pos + b_dir * tgt, 0.25)

func _chk_hov() -> bool:
	var cam := get_viewport().get_camera_3d()
	if not cam: return false
	var m_pos := get_viewport().get_mouse_position()
	var frm := cam.project_ray_origin(m_pos)
	var to := frm + cam.project_ray_normal(m_pos) * 10.0
	var ss := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(frm, to)
	var r := ss.intersect_ray(q)
	return r.has("collider") and r["collider"] == self

func _ply_clk(start: float, stop: float) -> void:
	if s_tmr:
		s_tmr.timeout.disconnect(click_sound.stop)
		s_tmr = null
	click_sound.play(start)
	if stop > 0.0:
		s_tmr = get_tree().create_timer(stop - start)
		s_tmr.timeout.connect(click_sound.stop)
