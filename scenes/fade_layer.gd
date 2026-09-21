extends CanvasLayer

@onready var fade_rect: ColorRect = %FadeRect
@onready var loading_label: Label = %LoadingLabel

func fade_to_black_and_load(path: String) -> void:
	if loading_label:
		loading_label.text = "loading..."
		loading_label.visible = true
		loading_label.modulate.a = 0.0
	fade_rect.color.a = 0.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 0.5)
	if loading_label: tw.parallel().tween_property(loading_label, "modulate:a", 1.0, 0.5)
	await tw.finished
	await get_tree().process_frame
	get_tree().change_scene_to_file(path)

func fade_to_black_and_call(target: Object, method: String) -> void:
	fade_rect.color.a = 0.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 1.0)
	await tw.finished
	target.call(method)
	await get_tree().create_timer(1.0).timeout
	var fo := create_tween()
	fo.tween_property(fade_rect, "color:a", 0.0, 1.5)

func quick_blink() -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 0.08)
	tw.tween_interval(0.05)
	tw.tween_property(fade_rect, "color:a", 0.0, 0.15)

func fade_to_thanks() -> void:
	fade_rect.color.a = 0.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, 2.0)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/thanks_screen.tscn")
