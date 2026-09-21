# documents_window.gd
extends AppWindow

const ROOT_DIR := "user://os_files/"

@export var icon_folder: Texture2D
@export var icon_txt: Texture2D
@export var icon_stl: Texture2D
@export var icon_unknown: Texture2D
@export var icon_image: Texture2D

@onready var file_list: ItemList = %FileList
@onready var path_edit: LineEdit = %PathEdit
@onready var up_button: Button = %UpButton
@onready var attach_banner: Label = %AttachBanner
@onready var attach_banner_panel: Control = attach_banner.get_parent()

var current_dir := ROOT_DIR
var entries: Array = []
var attach_mode := false
var attach_requester: Node = null

func _ready() -> void:
	super._ready()
	attach_banner_panel.visible = false
	file_list.item_activated.connect(_on_item_activated)
	up_button.pressed.connect(_go_up)
	path_edit.text_submitted.connect(_on_path_submitted)
	_navigate_to(ROOT_DIR)

func _navigate_to(path: String) -> void:
	if not path.ends_with("/"): path += "/"
	var norm := path.simplify_path()
	if not norm.ends_with("/"): norm += "/"
	var root_norm := ROOT_DIR.simplify_path()
	if not root_norm.ends_with("/"): root_norm += "/"
	if not norm.begins_with(root_norm):
		path_edit.text = current_dir
		return

	var dir := DirAccess.open(norm)
	if not dir:
		path_edit.text = current_dir
		return
	current_dir = norm
	path_edit.text = current_dir
	file_list.clear()
	entries.clear()

	var folders: Array[String] = []
	var files: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if dir.current_is_dir(): folders.append(fname)
		elif not fname.ends_with(".import"): files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()

	folders.sort()
	files.sort()

	for f in folders:
		entries.append({"name": f, "is_dir": true})
		file_list.add_item(f, icon_folder)

	var flagged: Array = HorrorState.check_and_update(current_dir, files)
	for f in files:
		entries.append({"name": f, "is_dir": false})
		var idx := file_list.add_item(f, _get_icon(f))
		if flagged.has(f): file_list.set_item_custom_fg_color(idx, Color(0.9, 0.25, 0.25))

func _get_icon(fname: String) -> Texture2D:
	match fname.get_extension().to_lower():
		"txt": return icon_txt
		"stl": return icon_stl
		"png", "jpg", "jpeg": return icon_image
		_: return icon_unknown

func _go_up() -> void:
	if current_dir.trim_suffix("/") == ROOT_DIR.trim_suffix("/"): return
	_navigate_to(current_dir.trim_suffix("/").get_base_dir())

func _on_path_submitted(p: String) -> void: _navigate_to(p)

func _on_item_activated(index: int) -> void:
	var entry = entries[index]
	if entry.is_dir:
		_navigate_to(current_dir + str(entry.name))
		return
	var path: String = current_dir + str(entry.name)
	if attach_mode:
		_handle_attach_selection(str(entry.name), path)
		return
		
	var ext: String = str(entry.name).get_extension().to_lower()
	if ext == "stl": get_parent().open_printer_app(str(entry.name), path)
	elif ext in ["png", "jpg", "jpeg"]: get_parent().open_image_viewer(str(entry.name), path)
	else: get_parent().open_text_reader(str(entry.name), _read_file(path))

func _read_file(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f: return "[Soubor nelze otevřít]"
	var txt := f.get_as_text()
	f.close()
	return txt

func enable_attach_mode(req: Node) -> void:
	attach_mode = true
	attach_requester = req
	attach_banner.text = "Choose a photo to send"
	attach_banner_panel.visible = true

func _handle_attach_selection(fname: String, path: String) -> void:
	var ext: String = fname.get_extension().to_lower()
	if ext in ["png", "jpg", "jpeg"]:
		if attach_requester and attach_requester.has_method("receive_attachment"):
			attach_requester.receive_attachment(path)
		queue_free()
	else:
		attach_banner.text = "Invalid format — choose an image file"
		attach_banner.modulate = Color(1.0, 0.35, 0.35)
		var tw := create_tween()
		tw.tween_interval(1.5)
		tw.tween_callback(func():
			attach_banner.text = "Choose a photo to send"
			attach_banner.modulate = Color.WHITE
		)
