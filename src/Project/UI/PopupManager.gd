extends Node2D

export (PackedScene) var Pop

signal done

const RESET = .5

var popupQueue = []
var downtime = 0

func _process(delta):
	if downtime > 0: downtime -= delta
	elif popupQueue.size() > 0: load_popup()
	else: emit_signal("done")

func make_popup(text, color, up = true):
	var bar = get_node_or_null("../HPBar")
	if !bar or (bar and bar.value > 0): popupQueue.append([text, color, up])

func load_popup():
	var popup = Pop.instance()
	add_child(popup)
	popup.set_text(popupQueue[0][0], popupQueue[0][1], popupQueue[0][2])
	popupQueue.pop_front()
	downtime = RESET
