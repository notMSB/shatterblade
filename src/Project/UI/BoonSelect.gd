extends Node2D

var clickCost = null

func _on_Button_pressed():
	get_node("../../").select_pressed(self)
