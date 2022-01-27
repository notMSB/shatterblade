extends Node2D

func _on_Button_pressed():
	get_parent().get_parent().choose(get_index())
