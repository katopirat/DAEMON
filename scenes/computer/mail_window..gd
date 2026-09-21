extends AppWindow

const FOLDERS := [
	{"name": "Inbox", "path": "res://mail/inbox.json"},
	{"name": "Spam", "path": "res://mail/spam.json"},
]

@export var icon_folder: Texture2D

@onready var folder_list: ItemList = %FolderList
@onready var mail_tree: Tree = %MailTree
@onready var from_label: Label = %FromLabel
@onready var subject_label: Label = %SubjectLabel
@onready var body_label: Label = %BodyLabel

var current_emails: Array = []

func _ready() -> void:
	super._ready()
	for f in FOLDERS: folder_list.add_item(f.name, icon_folder)
	folder_list.item_selected.connect(_on_folder_selected)
	mail_tree.item_selected.connect(_on_email_selected)
	_setup_tree()
	folder_list.select(0)
	_on_folder_selected(0)

func _setup_tree() -> void:
	mail_tree.columns = 2
	mail_tree.set_column_titles_visible(true)
	mail_tree.set_column_title(0, "From")
	mail_tree.set_column_title(1, "Subject")
	mail_tree.set_column_expand(0, true)
	mail_tree.set_column_expand(1, true)
	mail_tree.hide_root = true

func _on_folder_selected(index: int) -> void: _load_folder(FOLDERS[index].path)

func _load_folder(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f: return
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_ARRAY: return
	current_emails = parsed
	_populate_tree()
	_clear_reader()

func _populate_tree() -> void:
	mail_tree.clear()
	var root := mail_tree.create_item()
	for i in current_emails.size():
		var email = current_emails[i]
		var item := mail_tree.create_item(root)
		item.set_text(0, email.get("from", ""))
		item.set_text(1, email.get("subject", ""))
		item.set_metadata(0, i)

func _on_email_selected() -> void:
	var item := mail_tree.get_selected()
	if not item: return
	var idx = item.get_metadata(0)
	var email = current_emails[idx]
	from_label.text = "From: " + email.get("from", "")
	subject_label.text = email.get("subject", "")
	body_label.text = email.get("body", "")

func _clear_reader() -> void:
	from_label.text = ""
	subject_label.text = ""
	body_label.text = ""
