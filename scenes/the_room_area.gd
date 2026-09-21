extends Area3D

func _ready() -> void:
	body_entered.connect(_on_b_ent)

func _on_b_ent(b: Node3D) -> void:
	if b.is_in_group("player"): HorrorState.on_assembly_room_entered()
