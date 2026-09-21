# chat_window.gd
extends AppWindow

const D_DIR := "res://dialogue/"
const R_SCN := preload("res://scenes/computer/message_row.tscn")

@export var av_jake: Texture2D
@export var av_pl: Texture2D
@export var n_jake := "jake"
@export var n_pl := "you"
@export var c_jake := Color(0.85, 0.45, 0.45)
@export var c_pl := Color(0.45, 0.65, 0.95)

@onready var m_scroll: ScrollContainer = %MessageScroll
@onready var m_list: VBoxContainer = %MessageList
@onready var resp_area: VBoxContainer = %ResponseArea
@onready var att_btn: Button = %AttachButton

var dlg: Dictionary = {}
var pnd_att_nxt := ""
var pnd_play := false

func _ready() -> void:
	super._ready()
	att_btn.visible = false
	att_btn.pressed.connect(_on_att)
	ChatProgress.session_queued.connect(_on_st_chg)
	HorrorState.condition_changed.connect(_on_st_chg)
	visibility_changed.connect(_on_vis_chg)
	if ChatProgress.session_ready: _ld_dlg(D_DIR + ChatProgress.current_dialogue_id + ".json")
	_rest_log()
	_res()

func _on_st_chg() -> void:
	_ld_dlg(D_DIR + ChatProgress.current_dialogue_id + ".json")
	if is_visible_in_tree(): _res()
	else: pnd_play = true

func _on_vis_chg() -> void:
	if is_visible_in_tree() and pnd_play:
		pnd_play = false
		_res()

func _on_cond_chg() -> void:
	if ChatProgress.finished: return
	var n: Dictionary = dlg.get(ChatProgress.current_node_id, {})
	if n.has("responses"): _shw_resps(n["responses"])

func _rest_log() -> void:
	for e in ChatProgress.log:
		if e.get("type", "text") == "image": _add_img(e.text, e.from)
		else: _add_r(e.text, e.from)

func _ld_dlg(p: String) -> void:
	var f := FileAccess.open(p, FileAccess.READ)
	if not f: return
	var txt := f.get_as_text()
	f.close()
	var prs = JSON.parse_string(txt)
	if typeof(prs) == TYPE_DICTIONARY: dlg = prs

func _res() -> void:
	if not ChatProgress.session_ready or ChatProgress.finished: return
	if not ChatProgress.node_started:
		_ply_nd(ChatProgress.current_node_id)
		return
	var n: Dictionary = dlg.get(ChatProgress.current_node_id, {})
	if n.has("responses"): _shw_resps(n["responses"])
	elif n.has("next"): _ply_nd(n["next"])

func _ply_nd(id: String) -> void:
	if not dlg.has(id): return
	var n: Dictionary = dlg[id]
	ChatProgress.current_node_id = id
	ChatProgress.node_started = true
	_clr_resps()
	var t_time: float = n.get("delay", 1.2)
	var typ := _add_r("...", "jake")
	await get_tree().create_timer(t_time).timeout
	typ.queue_free()
	var txt: String = n.get("text", "")
	_add_r(txt, "jake")
	_log_m("jake", txt)
	
	if n.has("responses"): _shw_resps(n["responses"])
	elif n.has("next"):
		await get_tree().create_timer(0.9).timeout
		_ply_nd(n["next"])
	else:
		ChatProgress.finished = true
		var o_end: String = n.get("on_end", "")
		if o_end != "" and HorrorState.has_method(o_end):
			HorrorState.call(o_end)

func _shw_resps(resps: Array) -> void:
	att_btn.visible = false
	for r in resps:
		if r.has("requires") and not HorrorState.get(r["requires"]): continue
		if r.get("type", "") == "attach":
			pnd_att_nxt = r.get("next", "")
			att_btn.visible = true
			continue
		var b := Button.new()
		b.text = r.get("text", "")
		b.pressed.connect(_on_r_chs.bind(r))
		resp_area.add_child(b)

func _on_r_chs(r: Dictionary) -> void:
	_clr_resps()
	var txt: String = r.get("text", "")
	_add_r(txt, "player")
	_log_m("player", txt)
	await get_tree().create_timer(0.6).timeout
	_ply_nd(r.get("next", ""))

func _clr_resps() -> void:
	att_btn.visible = false
	for c in resp_area.get_children(): c.queue_free()

func _on_att() -> void:
	get_parent().open_attach_picker(self)

func receive_attachment(p: String) -> void:
	att_btn.visible = false
	_clr_resps()
	_add_img(p, "player")
	_log_m("player", p, "image")
	await get_tree().create_timer(0.6).timeout
	_ply_nd(pnd_att_nxt)

func _log_m(f: String, t: String, typ: String = "text") -> void:
	ChatProgress.log.append({"from": f, "text": t, "type": typ})

func _add_r(t: String, f: String) -> Control:
	var r := R_SCN.instantiate()
	m_list.add_child(r)
	if f == "player": r.setup(n_pl, t, c_pl, av_pl, _nw())
	else: r.setup(n_jake, t, c_jake, av_jake, _nw())
	_scrl_btm.call_deferred()
	return r

func _add_img(p: String, f: String) -> Control:
	var r := R_SCN.instantiate()
	m_list.add_child(r)
	if f == "player": r.setup_image(n_pl, p, c_pl, av_pl, _nw())
	else: r.setup_image(n_jake, p, c_jake, av_jake, _nw())
	_scrl_btm.call_deferred()
	return r

func _nw() -> String:
	return "Today at %02d:%02d" % [HorrorState.game_hour, HorrorState.game_minute]

func _scrl_btm() -> void:
	await get_tree().process_frame
	m_scroll.scroll_vertical = int(m_scroll.get_v_scroll_bar().max_value)

func _on_new_sess() -> void:
	_ld_dlg(D_DIR + ChatProgress.current_dialogue_id + ".json")
	_res()
