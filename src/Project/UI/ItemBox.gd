extends Node2D

var type = 0 #default is basic type

func _on_Button_pressed():
	get_node("../../../").select_box(self) #great grandpa
