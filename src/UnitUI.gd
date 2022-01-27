extends Node2D

func _on_Button_pressed():
	$"../../../".target_chosen(get_index())
