extends AppWindow

const W_DIR := "res://assets/Wallpapers/"

@onready var wallpaper_option: OptionButton = %WallpaperOption
var w_paths: Array[String] = []

func _ready() -> void:
	super._ready()
	_ld_wp()
	wallpaper_option.item_selected.connect(_on_wp_sel)

func _ld_wp() -> void:
	var dir := DirAccess.open(W_DIR)
	if not dir: return
	dir.list_dir_begin()
	var f_name := dir.get_next()
	while f_name != "":
		if not dir.current_is_dir() and (f_name.ends_with(".png") or f_name.ends_with(".jpg")):
			w_paths.append(W_DIR + f_name)
			wallpaper_option.add_item(f_name.get_basename())
		f_name = dir.get_next()
	dir.list_dir_end()

func _on_wp_sel(idx: int) -> void:
	var tex := load(w_paths[idx]) as Texture2D
	get_parent().set_wallpaper(tex)
