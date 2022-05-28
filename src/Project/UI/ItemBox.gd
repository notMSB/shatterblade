extends Node2D

var moveType = 0 #default is a null type

func _on_Button_pressed():
	get_node("../../../").select_box(self) #great grandpa
