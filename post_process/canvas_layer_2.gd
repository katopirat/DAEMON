extends CanvasLayer

@onready var lbl: Label = %WorldNotify
@onready var icn: TextureRect = %WorldNotifyIcon
@onready var pnl: Control = lbl.get_parent().get_parent()

func _ready() -> void:
	pnl.modulate.a = 0.0
	Notifications.posted.connect(_on_notif)

func _on_notif(app: String, t: String, _b: String, i: Texture2D) -> void:
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty() or ps[0].is_sitting: return

	icn.texture = i
	icn.visible = i != null
	lbl.text = "%s — %s" % [Notifications.get_display_name(app), t]

	pnl.visible = true
	var tw := create_tween()
	tw.tween_property(pnl, "modulate:a", 1.0, 0.4)
	tw.tween_interval(8.0)
	tw.tween_property(pnl, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func(): pnl.visible = false)
