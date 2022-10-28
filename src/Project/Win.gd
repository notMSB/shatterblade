extends Node2D

func _on_RestartButton_pressed():
	global.storedParty.clear()
	global.itemDict.clear()
	return get_tree().change_scene("res://src/Project/Game.tscn")
