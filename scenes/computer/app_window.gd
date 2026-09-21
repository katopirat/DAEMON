# app_window.gd
extends Panel
class_name AppWindow

@export var window_icon: Texture2D
@export var active_style: StyleBoxTexture
@export var inactive_style: StyleBoxTexture

@onready var t_bar: HBoxContainer = $TitleBar
@onready var t_lbl: Label = $TitleBar.get_child(0) as Label
@onready var cl_btn: Button = $TitleBar/CloseButton
@onready var res_hndl: Control = $ResizeHandle

var drag := false
var drag_off := Vector2.ZERO
var resz := false
var resz_st_sz := Vector2.ZERO
var resz_st_m := Vector2.ZERO

func _ready() -> void:
	cl_btn.pressed.connect(queue_free)
	t_bar.gui_input.connect(_on_tbar_in)
	t_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	res_hndl.gui_input.connect(_on_resz_in)
	res_hndl.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	
	set_active(true)

func _on_tbar_in(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		drag = e.pressed
		if drag:
			focus_window()
			drag_off = get_parent().get_local_mouse_position() - position
	elif e is InputEventMouseMotion and drag:
		var n_pos: Vector2 = get_parent().get_local_mouse_position() - drag_off
		var m_pos: Vector2 = get_parent().size - size
		n_pos.x = clamp(n_pos.x, 0, max(m_pos.x, 0))
		n_pos.y = clamp(n_pos.y, 0, max(m_pos.y, 0))
		position = n_pos

func _on_resz_in(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		resz = e.pressed
		if resz:
			resz_st_sz = size
			resz_st_m = get_global_mouse_position()
			
	elif e is InputEventMouseMotion and resz:
		var d: Vector2 = get_global_mouse_position() - resz_st_m
		var n_sz: Vector2 = resz_st_sz + d
		var m_sz: Vector2 = custom_minimum_size if custom_minimum_size != Vector2.ZERO else Vector2(160, 100)
		n_sz.x = max(n_sz.x, m_sz.x)
		n_sz.y = max(n_sz.y, m_sz.y)
		var mx_sz: Vector2 = get_parent().size - position
		n_sz.x = min(n_sz.x, mx_sz.x)
		n_sz.y = min(n_sz.y, mx_sz.y)
		size = n_sz

func focus_window() -> void:
	move_to_front()
	set_active(true)
	for s in get_parent().get_children():
		if s != self and s is AppWindow:
			s.set_active(false)

func set_active(act: bool) -> void:
	if act and active_style:
		add_theme_stylebox_override("panel", active_style)
	elif not act and inactive_style:
		add_theme_stylebox_override("panel", inactive_style)
