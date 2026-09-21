extends Node

const SOURCE_DIR := "res://os_files/"
const USER_DIR := "user://os_files/"

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(USER_DIR):
		_copy_tree(SOURCE_DIR, USER_DIR)

func _copy_tree(from: String, to: String) -> void:
	DirAccess.make_dir_recursive_absolute(to)
	var dir := DirAccess.open(from)
	if not dir: return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if dir.current_is_dir(): _copy_tree(from + fname + "/", to + fname + "/")
		elif not fname.ends_with(".import"): _copy_file(from + fname, to + fname)
		fname = dir.get_next()
	dir.list_dir_end()

func _copy_file(from: String, to: String) -> void:
	var src := FileAccess.open(from, FileAccess.READ)
	if not src: return
	var bytes := src.get_buffer(src.get_length())
	src.close()
	var dst := FileAccess.open(to, FileAccess.WRITE)
	if dst:
		dst.store_buffer(bytes)
		dst.close()

func reset() -> void:
	_delete_tree(USER_DIR)
	_copy_tree(SOURCE_DIR, USER_DIR)

func _delete_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir: return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if dir.current_is_dir(): _delete_tree(path + fname + "/")
		else: dir.remove(path + fname)
		fname = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
