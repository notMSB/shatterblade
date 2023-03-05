extends Node2D

func _on_Choice_item_selected(index):
	$"../../../".set_enemy(get_index(), $Choice.get_item_text(index)) #Puzzle Node
