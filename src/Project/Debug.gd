extends Node2D

func _on_Party_pressed():
	return get_tree().change_scene("res://src/Project/Units/Party.tscn")

func _on_Inventory_pressed():
	return get_tree().change_scene("res://src/Project/UI/Inventory.tscn")

func _on_Battle_pressed():
	return get_tree().change_scene("res://src/Project/Battle.tscn")

func _on_Map_pressed():
	return get_tree().change_scene("res://src/Project/Map.tscn")
