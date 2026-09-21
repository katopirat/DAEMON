# chat_progress.gd
extends Node

signal session_queued

var current_dialogue_id := ""
var current_node_id := "start"
var log: Array = []
var finished := false
var node_started := false
var session_ready := false

func queue_session(dlg_id: String) -> void:
	current_dialogue_id = dlg_id
	current_node_id = "start"
	finished = false
	node_started = false
	session_ready = true
	session_queued.emit()
