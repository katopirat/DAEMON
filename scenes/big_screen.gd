extends MeshInstance3D

@export var scr_vp: SubViewport

var scr_mat: StandardMaterial3D

func _ready() -> void:
	call_deferred("_set_tex")

func _set_tex() -> void:
	scr_mat = StandardMaterial3D.new()
	scr_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	scr_mat.albedo_texture = scr_vp.get_texture()
	scr_mat.emission_enabled = true
	scr_mat.emission_texture = scr_vp.get_texture()
	scr_mat.emission_energy_multiplier = 0.0
	scr_mat.albedo_color = Color(0, 0, 0)
	set_surface_override_material(0, scr_mat)

func set_brightness(v: float) -> void:
	if scr_mat: scr_mat.albedo_color = Color(v, v, v)
