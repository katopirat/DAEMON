extends MeshInstance3D

var float_offset := 0.0
var base_y := 0.0

func _ready() -> void:
	base_y = position.y
	float_offset = randf() * TAU

func _process(delta: float) -> void:
	float_offset += delta * 0.4
	position.y = base_y + sin(float_offset) * 0.12
