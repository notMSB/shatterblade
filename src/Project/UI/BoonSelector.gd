extends Node2D

func _on_Choice_item_selected(index):
	$"../../../".set_boon(get_index(), index) #Puzzle Node

func _on_Level_item_selected(index):
	$"../../../".set_boon_level(get_index(), index) #Puzzle Node
