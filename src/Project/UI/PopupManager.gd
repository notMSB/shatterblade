extends Node2D

export (PackedScene) var Pop

signal done

var popupQueue = []
var pause = false

func make_popup(text, color, up = true):
	var bar = get_node_or_null("../HPBar")
	if !bar or (bar and bar.value > 0): 
		popupQueue.append([text, color, up])
		if !popupQueue.empty() and !pause: 
			load_popup()

func unpause():
	if !popupQueue.empty(): 
		load_popup()
	else:
		emit_signal("done")
		pause = false

func load_popup():
	var popup = Pop.instance()
	add_child(popup)
	popup.set_text(popupQueue[0][0], popupQueue[0][1], popupQueue[0][2])
	popupQueue.pop_front()
	pause = true
